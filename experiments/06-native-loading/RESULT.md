# Experiment 6: new native code loaded; old code retired

**Passed within the boundary below.** A running queue service loaded v2 that
was compiled after startup, kept all five client connections per trial, finished
old jobs using v1, and processed new jobs using v2. It refused premature
retirement and actually unloaded v1 once its last job finished. Final verification
is three fresh builds/processes, 83 jobs each: **249 acknowledged completions**,
with correct payload, FIFO order, version and both calculation steps.

Robert authorized execution and then said “dont worry about the separate checks,
just confirm it yourself.” These are **same-author implementation checks**, not
independent acceptance. ROB-1327; decisions D117 (execute native-loading experiment)
and D118 (allow self-verification here). Previous experimental locks are unchanged.

## What was tested

The Rust host owns the queue, client sockets and reference-counted code handles.
Each job owns its module from admission through both calls. Native code is in
separately compiled C dynamic libraries loaded with the OS loader. The host has
no compiled-in v1/v2 arithmetic. Payload 10 returns **12 under v1**, **118 under
v2**. Tests check intermediate values too, so combining one step of each version
fails. This C interface is an experimental choice, not Mo architecture.

The worker is deliberately held in a synchronous callback *from inside v1*, so
there is a real native return address into v1 during activation. Another old job
is queued. After v2 loads, new work is admitted while old work is held. A one-job
release advances to the queued old job, which must still use v1 and prevent
retirement. After both finish, explicit retirement removes the old owner and
calls dlclose. Both the library destructor and **absence from dyld's image
inventory** are checked before the process exits. Four existing producer sockets
then submit another 80 jobs successfully. No reconnection occurs.

Nonexistent and malformed artifacts, ABI 99, missing required symbol, same version
and older version are refused. A refused artifact cannot alter active version or
queued/accepted work. Duplicate submissions keep their original sequence;
conflicting payloads refuse. Shutdown refuses while accepted work remains, and
once shutdown is accepted further commands cannot admit work.

This reuses experiment 5's Rust FIFO, deduplication, mutex/condition-variable
worker pattern, line protocol and corrected Darwin accepted-socket behavior.
It does **not** combine native loading with representation migration or the
previous watchdog: the host-owned queue keeps one representation, and activation
switches the version used by future admissions immediately. Accepted queued work
pins its admission version, unlike experiment 5's representation-transition rule.

## Broken implementations caught

All six source-mutated hosts compiled. The unchanged behavioral assertions
rejected each for its intended observable defect (not a compilation error):

| Broken behavior | Observed rejection |
| --- | --- |
| Permit retirement with old references | Premature retirement response |
| Force dlclose while old native call is held | Old image vanished while executing |
| Never call dlclose | Old image still present after retirement |
| Reacquire active code for second job step | Mixed calculation result |
| Drop queued work on activation | Queued old job never starts; bounded timeout |
| Ignore ABI mismatch | Incompatible artifact accepted |

The force-unload control is detected while the worker is still held, before it
returns into unmapped memory; it is then killed by cleanup. We do not claim a
safe recovery from such a defect. Raw outcomes retain process exit codes. Failed
controls are cleaned up deliberately; they are not server crashes counted as passes.

## Attempts and reproducibility

- `run-01`: first check failed because macOS canonicalized `/var` to `/private/var`
  in its image inventory. `check-01.py` preserves the original harness. The only
  repair was resolving the temporary directory before passing paths to the host;
  the exact image-presence/absence requirement was retained. No runtime repair.
- `run-02`: three passing trials, original five controls in `controls-01`.
- `run-03`: three passing trials with an extra image-presence check immediately
  after blocked retirement; six controls passed in `controls-02`. `check-02.py`
  retains the prior checks. This strengthens the unloading check, not its expected
  outcome. `host-01.rs` retains this host revision.
- Review then added a shutdown admission guard: a concurrent command cannot
  enqueue after shutdown has been accepted. `run-04` and `controls-03` are the
  final-source verification. Earlier attempts are retained, not pooled to inflate
  the final trial count.

On macOS with rustc, clang and Python 3 installed, from repository root:

```sh
python3 experiments/06-native-loading/check.py /tmp/mo-native-fresh-run
python3 experiments/06-native-loading/mutate.py /tmp/mo-native-fresh-controls
```

Use unused output paths. Every run rebuilds into a fresh temporary directory,
compiles v2 only after server startup, records commands/responses and artifact
hashes, and bounds waits. No dependencies are installed. `evidence/tools.json`
records the tested tools; `evidence/MANIFEST.json` fingerprints retained files.
The spec's original five controls are preserved; the sixth forced-unload control
is additional verification. No TLA or universal lifetime proof is claimed.

## Limits

This demonstrates a small **trusted synchronous module interface on macOS**.
Correctness depends on native functions honoring that interface: no escaping
pointers, retained callbacks, module-owned threads, TLS or long-lived state.
ABI checks cannot validate arbitrary machine code or protect against constructors
that run during loading. Candidate files must be immutable under test control.
It does not test arbitrary native-code preemption, crash recovery, external
side effects, malicious clients, large loads or every thread schedule.

Loading and destructors run under the state mutex here. A slow or stuck library
can block service; this experiment establishes no bounded loading deadline or
availability SLA, and does not carry forward experiment 5's watchdog guarantee
into native loading. A future combined experiment would need to address that.
The finite ledger/capacity limits are experimental, not a production policy.

A successful dlclose alone is insufficient evidence of physical unloading;
Apple documents cases where images remain loaded. We checked real image removal
on this host, not all operating systems or library shapes. See Apple's
[dlclose reference](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dlclose.3.html).

Stop at a pushed reviewable branch. No merge, deployment or next milestone.
