# Experiment 9: retained migration resource limit

**Passed within the fixed experimental boundary.** Three fresh-process, no-retry
trials completed 270 jobs while refusing all 240 excess updates. Two native
migrations looped permanently; the host continued serving existing clients and
work without unloading either executing module. Same-author verification, not
independent acceptance. Tracked by ROB-1330; D123 authorized this experiment.

## What changed

The host adds 13 lines to experiment 8: reap only fully finished updater handles,
then refuse admission when two handles remain. The check/reservation and spawn
occur under the existing state mutex. No extra resource counter or scheduler.
Timeout cannot make an executing worker disappear from this budget. Staging and
native disposal are included because a handle is retained until the thread exits.
The C fixture adds constructor/entry markers and a non-returning nanosleep loop.
Earlier experiments are untouched.

This contains retained updater resources, at the cost of eventually refusing all
new updates. A returning worker releases capacity; a permanently stuck one does
not. The service still processes ordinary jobs after timeout restores its queue.

## Observed evidence

| Trial | Completed jobs | Excess updates refused | External threads, baseline → saturated | Permanent timeout times |
| -- | -- | -- | -- | -- |
| 1 | 90 | 80 | 8 → 10 | 200.695ms, 201.215ms |
| 2 | 90 | 80 | 8 → 10 | 200.366ms, 200.124ms |
| 3 | 90 | 80 | 8 → 10 | 200.454ms, 201.061ms |

Every trial used one process and five persistent TCP clients. Constructor logs,
dyld inventory and ten-attempt ledger stayed unchanged across four simultaneous
20-request refusal bursts. The refused v12 candidate was never loaded. Retained
module set was v9 (active), v10 and v11 (permanently executing); both stuck modules
refused retirement and had no unload markers. Native entry markers establish that
the C loops were entered after host callbacks returned. Their source has no return
or cooperative release path; finite observation is not a divergence proof.

Before saturation, successful, corrupt, ABI-incompatible and expired-then-returning
migrations exercised capacity reuse. Repeated successful updates retired obsolete
modules; external thread count returned to eight. Native array-to-linked migration
preserved old queued jobs and their code versions. Between permanent stalls, old
queued jobs completed; after saturation, 80 concurrent new jobs completed in each
trial. Full acknowledgement/completion ledgers checked payloads, ordering, pinned
versions and both native computation steps.

The unchanged experiment-8 `check.trial` also passed against the new host with its
original C fixture: another 97 regression jobs, corrupt/held/native-sleep migration,
late result disposal, code retirement and graceful shutdown. This is a single
regression trial, separately reported from the three resource-limit trials.

## Controls and retained failure

All five final compiled source mutations failed their intended checks:

- Remove the two-worker cap: excess update admitted.
- Ignore timed-out workers in capacity accounting: excess update admitted.
- Never reap completed workers: subsequent valid update refused.
- Force dlclose/retired response for an executing migration: retirement accepted.
- Leave the old queue frozen after timeout: old queue not resumed.

`evidence/controls-01` retains an invalid control attempt: the initial unsafe-retire
mutation also force-closed ordinary unused modules, causing a second dlclose during
normal v1 retirement and connection EOF before reaching the intended stalled case.
It was not counted as a successful control. `evidence/mutate-01.py` preserves that
runner. The final mutation targets only nonactive modules with outstanding owners,
performs a real unsafe dlclose, then acknowledges retirement; the unchanged
behavioral check rejects it. No host fix or acceptance expectation was changed.
All controls were rerun in `evidence/controls-02`.

A separate forced failure after both permanent native entries verified the harness
still killed and reaped the process. Normal resource trials also returned `busy`
for graceful shutdown, then used SIGKILL in bounded harness cleanup; each process
was gone afterward. This is process teardown, **not** in-process reclamation of
stuck native calls. Compressed traces retain commands, replies, external `ps -M`
output, build commands/results, artifact hashes and cleanup outcomes.

## Reproduce and inspect

Run from the repository root with macOS clang, rustc and Python; output directories
must be new (no automatic retries or overwriting failed evidence):

```sh
python3 experiments/09-migration-limit/check.py /tmp/mo-limit-new-run
python3 experiments/09-migration-limit/mutate.py /tmp/mo-limit-new-controls
```

- `SPEC.md`: criterion fixed before implementation.
- `evidence/run-01/`: three final trials, source hashes, final states and traces.
- `evidence/controls-01/`, `evidence/controls-02/`: all control attempts.
- `evidence/previous-check-01/`: unchanged experiment-8 regression trial.
- `evidence/verification.json`: counts, timings, controls, cleanup and tool versions.
- `evidence/MANIFEST.json`: SHA-256 identities for retained files.

## Limits and interpretation

The two-worker count covers host-created updater threads and handles, their pinned
code and bounded copied rows (at most eight four-u64 rows, 256 row bytes each), plus
stack/loader/runtime overhead. The fixture loops allocate nothing indefinitely.
No arbitrary native heap/thread bound follows; malicious code, native crashes,
external effects, blocking queue operations/destructors and loader progress remain
outside the guarantee. OS thread counts are sampled observations, with the admission
bound additionally supported by source inspection; no memory-byte ceiling was
measured. The existing finite job/attempt/module ledgers and fixed clients remain.

The 200ms preparation deadline begins after staging. This does not establish a
production latency SLA or preemption. At permanent saturation further updates need
process replacement; replacement/recovery was not implemented. No permanent Mo
architecture, deployment or new experiment is selected. Next owner discussion:
all current Mo v2 Needs Input proposals.
