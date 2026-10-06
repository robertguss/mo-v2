# Experiment 4: bounded live state transition

ROB-1323. Owner authorized this first milestone and one local builder with
separate acceptance authorship. These are lead-selected experimental choices,
not permanent Mo language design decisions. The prior experiments are untouched.

## Question and boundary

Can a running queue switch from a deque representation (v1) to an ordered map
representation (v2), preserving accepted work and its open TCP connection, or
refuse the update without damaging the authoritative state?

Both versions are compiled into one stdlib-only Rust executable. Jobs have unique
integer IDs 1, 2, 3 and payload `id * 10`. Capacity is two outstanding jobs,
including the one in flight. Each ID may be acknowledged once per experiment;
completed IDs are retained for deduplication. This finite lifetime is a model
bound, not a production queue design. FIFO order and payloads must survive.
One update attempt is allowed per reset. No process crash durability, external
effects, native code loading, multithreaded access, distributed coordination,
actual automatic rollout or production safety is claimed.

## Public state and commands

The executable supports `--stdio` and `--listen 127.0.0.1:0`. In TCP mode it
prints `LISTEN 127.0.0.1:<port>` to stdout, flushes, accepts one client and serves
newline-terminated commands on that same connection until EOF. Each command
returns one JSON line `{"status":"...","state":{...}}`. No extra stdout in
stdio mode. Transport is a test harness, not a hardened network API.

The state has exactly these fields (arrays preserve order except accepted,
which is sorted):

| Field | Initial value | Meaning |
| --- | --- | --- |
| version | 1 | sole authoritative representation |
| phase | "running" | running, draining, copying, ready |
| queue | [] | pending FIFO IDs |
| flight | 0 | currently processing ID, zero means none |
| flight_version | 0 | version pinned when processing started |
| accepted | [] | acknowledged unique IDs |
| completed | [] | completed IDs, retaining multiplicity and order |
| completed_values | [] | actual payloads returned by completed jobs, in the same order |
| candidate | [] | IDs copied in FIFO order to inactive representation |
| corrupt | false | inactive representation has invalid payload/structure |
| remaining | 0 | update budget, in logical ticks |
| attempted | false | whether this lifetime has begun an update |
| outcome | "none" | none, pending, activated, refused |

Commands are exact lower-case ASCII strings. `enqueue 1`, `enqueue 2`, and
`enqueue 3` are valid enqueue commands. Other input returns `invalid` unchanged.
`snapshot` returns `ok` unchanged; `reset` returns `ok` with initial state.
Reset is harness-only, excluded from conservation and the modeled service.

For valid commands below, a false precondition returns `blocked` unchanged,
except enqueue's explicitly ordered decisions. Successful commands return `ok`.

| Command | Preconditions and effect |
| --- | --- |
| enqueue N | If accepted already: `duplicate`, unchanged. Otherwise if phase is copying/ready or capacity full: `busy`, unchanged. Otherwise append to queue and accepted set. |
| start | running, no flight, nonempty queue: move FIFO head to flight; pin current version. |
| finish | flight exists: append its ID to completed and its actual payload to completed_values, clear flight and flight_version. |
| begin | running, version 1, not attempted: draining, attempted=true, remaining=3, outcome=pending. |
| prepare | draining, no flight: copying, empty candidate. Freeze authoritative queue. |
| copy | copying and candidate shorter than queue: copy the next job and payload into candidate; phase remains copying. |
| corrupt | copying/ready and not corrupt: introduce an actual invalid candidate payload (or a hidden invalid entry for an empty candidate); set corrupt=true. Does not alter candidate's visible ID sequence. |
| validate | copying: if candidate exactly represents queue with correct order/payloads and no corruption, set ready; otherwise refuse. |
| activate | ready: revalidate candidate and require no flight; on valid candidate make v2 authoritative atomically, running, outcome=activated, remaining=0, empty candidate, corrupt=false. On corruption refuse. |
| fail | outcome pending: refuse. |
| tick | outcome pending: decrement remaining if >1; at 1 refuse. |

Refusal sets running, outcome=refused, remaining=0, candidate=[], corrupt=false.
It keeps version 1, authoritative queue, flight, accepted and completed intact.
`attempted` stays true. Resuming/finishing old work remains possible. A second
attempt and stale-snapshot rollback after activation are outside this experiment.
There is no automatic work processor: explicit start/finish commands control
interleavings. Other commands do not consume logical ticks. No response is an
acknowledgment unless its status is `ok` for enqueue; duplicate means the ID's
earlier acknowledgment remains in force.

## Model and correspondence

`model/LiveUpdate.tla` uses the same state field names, TLA sequences for arrays,
a set for accepted and strings for phase/outcome. `vars` lists all fields above.
Expose `Init`, `Next`, `Tick`, `Spec`, `Safety`, `Termination`. `Next` is a
disjunction of enabled state-changing commands. Individual zero-argument action
names must be `Enqueue1`, `Enqueue2`, `Enqueue3`, `Start`, `Finish`, `Begin`,
`Prepare`, `Copy`, `Corrupt`, `Validate`, `Activate`, `Fail`, `Tick` for DOT replay.
Blocked commands, snapshot and reset are absent from Next.

`Spec == Init /\ [][Next]_vars /\ WF_vars(Tick)` (or equivalent).
`Termination == (outcome = "pending") ~> (outcome # "pending")`.
Without weak fairness of budget ticks an environment can pause forever; no
unconditional liveness or wall-clock claim is permitted. Jobs need not finish:
draining can time out safely. Terminal states stutter; TLC deadlock checks off.

Safety includes type/range validity, capacity, unique completion, conservation
(accepted equals the disjoint union of queued, in-flight, completed IDs), pinned
flight version, no in-flight work during copying/ready, consistent outcome/version,
ready candidate equivalence unless corruption has just been injected, and the
bound on remaining. Preserve FIFO and payloads in the executable and compare the
model's observable state/edges with the separately authored transition oracle.

The model abstracts representation and payload integrity by candidate order and
the corruption flag. Its transition system is not a proof about compiled Rust,
the TCP stack, schedulers, allocation failure or unmodeled input/environment.

## Controls and stop

Root acceptance fixes five deliberately wrong public transition variants before
implementation: dropped work on activation, duplicate finish, activation while
old work is active, accepting a corrupt candidate, and activation after the
budget expires. Each must be rejected by the same state/transition expectations.
Root will additionally mutate actual builder source in disposable copies when
stable unambiguous sites exist, preserving and reporting which controls ran.

Stop after complete finite TLC exploration, executable checks, connection test,
negative controls and a report. If checks expose a defect, retain the failure
and let the builder repair implementation without changing expected behavior.
If obligations conflict or need weakening, stop and ask Robert. Do not silently
redefine correctness, retune outputs or claim a complete hot-reloading language.
