# Experiment 5: repeated concurrent state updates

ROB-1326. Robert authorized continuing with the recommended next experiment.
Lead selects these bounded experimental details. One local builder implements;
the lead fixes acceptance first. Experiment 4 and prior locks are untouched.

## Question and implementation boundary

Can a queue perform repeated representation changes during concurrent submissions
and autonomous processing, refuse stalled updates on an independent monotonic
deadline, and discard a late result even after a newer update has activated?

Use a stdlib-only Rust executable. An autonomous single FIFO worker completes
one actual stored job every 5 ms (minimum simulated work delay outside the state
lock). Multiple TCP clients run concurrently. Capacity is eight queued plus
in-flight jobs. At most 256 distinct jobs and 32 update attempts per process;
these are experiment bounds, not a production retention policy. IDs and payloads
are unsigned integers 1..1,000,000. Completion returns the actual stored payload.
No new code is loaded: both deque and ordered-map implementations are compiled in.

Initially epoch 0 uses a deque. Every successful update increases epoch by one
and toggles representation: even epochs deque, odd epochs ordered map. Map keys
encode FIFO sequence, not job ID. Distinct update attempts use increasing IDs
1..32, never reused even when an update fails. Only one pending update at a time.

Every update has a 200 ms deadline from its start, using Rust Instant. A separate
watchdog must refuse expired pending updates without waiting for the job worker
or migration computation to cooperate. Short state-lock critical sections are
allowed; no job delay, migration delay or injected hold may retain that lock.
Before commit, check attempt identity, base epoch, quiescence, candidate validity
and Instant strictly before deadline. The watchdog is not the only deadline gate.

The update stops starting new jobs, allows an already active job to finish, then
freezes admission and snapshots the FIFO for migration. Admission may continue
during draining, within capacity. Migration runs outside the state lock and
spends at least 20 ms there (simulated work). A successful activation swaps the
actual representation; a refusal keeps the current authoritative state intact
and resumes the worker. A late result cannot change queue, epoch, pending attempt,
or terminal outcome of any attempt. It may only record that its worker returned
and that the stale result was discarded. Each terminal outcome is immutable.

## TCP protocol and observability

Run `mo-concurrent-updates --listen 127.0.0.1:0`. Announce exactly
`LISTEN 127.0.0.1:<port>` on stdout and flush. Each client sends ASCII lines and
gets one JSON object line per command. Connections survive all updates. No reset
command: each test scenario starts a fresh process. The test harness is not a
hardened network API. Commands below are exact, space-separated decimal integers.

| Command | Response and behavior |
| --- | --- |
| submit ID PAYLOAD | New accepted job: `{"status":"accepted","seq":N}`; N is consecutive starting at 1 and assigned under the state lock. Same ID/payload: `duplicate` with original seq. Same ID/different payload: `{"status":"conflict"}`. These checks precede capacity/phase checks. Otherwise `busy` during copying or at capacity, `limit` at 256 accepted; no job or seq is consumed on refusal. |
| update normal | `{"status":"started","attempt":N}`; begin deadline/drain/migrate/validate/activate autonomously. |
| update hold | Same start response, but migration computation waits outside the lock until `release N`, even if its deadline expires. This is a test fault, not a hung state lock. |
| update corrupt | Same start response, but corrupt actual candidate payload/structure before validation; refuse with outcome invalid. An empty candidate must also fail. |
| release N | `{"status":"ok"}` for a held migration not yet released (including an expired one); otherwise `blocked`. Releasing never directly commits a candidate. |
| hold_work | `ok`; prevent an in-flight job from completing until release_work. The job worker can start one job into this hold when running. |
| release_work | `ok`; release that gate. |
| snapshot | Full snapshot below. |
| shutdown | `ok`, then stop server and wake held workers so the process can exit. |

While an update is pending, another update returns `busy`; at 32 attempts it
returns `limit`. Invalid commands return `{"status":"invalid"}`. Simple statuses
without specified extra fields have exactly the one status key.

Snapshots are coherent under the state lock and have exactly these fields:

* `status`: `ok`; `now_us`: monotonic microseconds since service origin.
* `epoch`: integer; `schema`: `deque` or `map`; `phase`: running, draining, copying.
* `pending`: active attempt ID or 0; `work_held`: boolean.
* `queue`: ordered rows `[seq,id,payload]`; `flight`: null or `[seq,id,payload,epoch]`.
* `accepted`: rows `[seq,id,payload]` in acceptance order, retained for deduplication.
* `completed`: rows `[seq,id,payload,epoch]` in completion order, retaining duplicates.
* `attempts`: in attempt-ID order, objects with exactly `id`, `mode`, `status`,
  `base_epoch`, `finished_epoch`, `started_us`, `deadline_us`, `finished_us`,
  `stage`, `worker_returned`, `late_discarded`.

Attempt status is pending, activated, timeout, or invalid. Stage is draining,
copying, or done; terminal statuses have stage done. `finished_us` and
`finished_epoch` are null while pending. For activated attempts, finished_epoch
is base_epoch+1; for refusal it is base_epoch. deadline_us=started_us+200000.
Time-out finished_us must be >= deadline_us. Successful finished_us must be
< deadline_us. `worker_returned` means migration finished its computation; it
may remain false after timeout until release. `late_discarded` becomes true only
when that late result has actually been rejected. A timeout during draining need
not launch a migration worker. Client-visible ledger values describe real events,
not values fabricated to satisfy checks.

## Assertions and measured bounds

Every acknowledged job remains exactly once in queue, flight or completed.
Completions preserve global sequence and actual payload, and each completion's
epoch is the one pinned when processing began. Activation requires no flight.
Each epoch increase corresponds to exactly one activated attempt; failed or late
attempts cannot increment or restore an epoch. Repeated retries do not duplicate
work. Corruption is rejected before corrupt data becomes authoritative.

The measured host budget allows **750 ms beyond the 200 ms deadline** for timeout
observation/recording; this is a fixed experimental tolerance, not a claimed
production bound. A successful update must still commit strictly before its own
deadline. Socket commands have a 2-second test timeout. Tests must demonstrate
timeout while a migration remains held, old-state processing after refusal,
new-update success before releasing the stale worker, and immutability after
that stale worker returns. Also timeout while an old job remains held in flight.

Run three concurrent trials: four producers, 40 unique jobs each, eight normal
updates, with one client connection retained per producer/controller. Retry busy
submissions with the same ID/payload. Record all acknowledgments and compare the
final completion ledger. Require each normal update to activate, all 160 jobs to
complete, and at least one successful activation strictly between first and last
completion. Measure request latency, busy replies, completion gaps and observed
copying intervals. Polling misses short phases; do not call sampled intervals
exact admission-pause durations. No broad real-time or memory-allocation claim.

## Small model: overlapping attempt lifetimes

`model/RepeatedUpdate.tla` abstracts only token fencing, not queues or wall time.
Variables: issued=0, pending=0, running={}, expired={}, committed=<<>>,
ignored={}, epoch=0 initially. IDs are 1,2. `vars` includes all seven.

Named zero-argument changing actions (names must survive TLC DOT):

* Begin1 / Begin2: pending=0 and issued respectively 0 / 1; increment issued,
  set pending to that new ID, add it to running.
* Timeout: pending !=0; add pending to expired, set pending=0; worker may remain.
* Return1 / Return2: that ID in running; remove it. If pending equals that ID,
  append it to committed, increment epoch, clear pending; otherwise add to ignored
  and change no other authority state.

Expose Init, Next, Spec, Safety, Termination. Spec includes weak fairness of
Timeout, and Termination says pending !=0 eventually reaches pending=0.
Safety checks types, epoch=Len(committed), increasing unique committed IDs, no
expired ID committed, pending (if nonzero) belongs to running and is not expired,
and issued bounds. Terminal states may stutter; deadlock checks disabled.
Root compares all model states/edges to its own fixed tiny transition oracle.
This is deliberately narrower than full Rust correspondence. Runtime scenarios
exercise the same stale-attempt hazard, not an exhaustive Rust schedule proof.

## Stop condition and controls

Freeze spec and lead checks before builder implementation. Retain every acceptance
attempt, timing data, model output and failure. Use disposable real-source mutants:
watchdog cannot enforce held-migration deadline; stale worker can publish;
duplicate completion; dropped queue on activation; corrupt candidate accepted.
All five must compile and be rejected for observable wrong behavior. The model's
stale-return mutant must produce an invariant counterexample. Root chooses exact
source sites after implementation without changing expected behavior.

Stop after model, runtime scenarios, three load trials and controls are reported,
or on a spec conflict/blocker. Defects may be repaired by builder, never by
retuning acceptance. No native loading, arbitrary user migrations, database or
external-effect recovery, multi-node upgrade, production deployment, next research
milestone or merge follows from this authorization.
