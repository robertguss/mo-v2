# Staged revision passed: loading and preparation have separate clocks

**Three fresh no-retry trials passed, preserving 300 acknowledged jobs.** Loading
and interface validation complete first; the 200ms preparation/activation budget
starts afterward. Service work continues during staging. Held and natively
sleeping preparations time out independently, newer code activates before old
preparation returns, and late results cannot take authority. Libraries stay
mapped while referenced and genuinely unload after their native calls return.

Robert explicitly approved this revised boundary on 6 October 2026 (D120,
separate staging from timed preparation), after the original end-to-end deadline
experiment failed. This is same-author implementation and verification, not
independent acceptance. ROB-1328. The original specification, failed checks,
reports and evidence remain unchanged under the parent directory. That earlier
criterion still failed; this result applies to the newly approved boundary.

## What changed

Each attempt records request time separately. During staging, preparation start
and deadline are null. The updater loads and validates outside the service lock,
then registers its candidate, arms the deadline and calls native preparation.
The independent watchdog only expires armed deadlines. Existing token/version
checks, readiness validation, job-version pinning and reference ownership remain.

A plain `state` command reads service state without touching the loader mutex.
`snapshot` additionally reads the OS image inventory, so it may wait for loading.
This lets tests observe continued work while a constructor is deliberately slow.
No new dependency or compiler infrastructure was added; implementation derives
from the retained original Rust host and tiny C module.

## Observations

V2 has an injected 400ms constructor delay. In every trial four v1 jobs completed
while staging was still in progress, with preparation start/deadline null. Five
TCP connections remain open throughout each trial; all new artifacts are compiled
after the original service starts. There are exactly eight update attempts per
trial, with no retries: held v2, normal v3, sleeping v4, normal v5, readiness-invalid
v6, missing file, wrong ABI, missing symbol.

| Trial | Slow-v2 staging | Held preparation timeout | Native-sleep timeout | Completed jobs |
| --- | ---: | ---: | ---: | ---: |
| 1 | 1,394.941ms | 200.971ms | 200.984ms | 100 |
| 2 | 574.601ms | 201.092ms | 200.255ms | 100 |
| 3 | 583.273ms | 201.112ms | 200.083ms | 100 |

Staging includes the deliberate 400ms delay plus loading and scheduling; these
are observed elapsed times, not a bound or attribution of OS overhead. The v3/v5
successful preparation/activation intervals were 0.006–0.058ms after staging.
The v4 call sleeps natively for 800ms without host callbacks during the sleep.
Two 300ms intervals without client polling per trial confirm autonomous timeout.

After held/sleeping timeout, each candidate remains in the real loader inventory
and cannot be retired while executing. A newer candidate successfully activates
before the old one returns. On return, the original terminal result is unchanged,
the result is marked discarded, the destructor runs exactly once, and the old
image disappears. The actual FIFO ledger preserves IDs, payloads, admission
versions and both calculation steps. Wrong readiness refuses; invalid staging
never arms a preparation clock or changes authoritative work/version.

## Controls and retained attempts

Six actual mutated hosts compiled and failed for the intended observable defect:

| Mutation | Check that rejected it |
| --- | --- |
| Arm deadline at request admission | Preparation clock already armed during staging |
| Disable watchdog | Held preparation not expired |
| Permit stale publication | Newer active version overwritten |
| Force unload while preparation executes | Candidate image disappears prematurely |
| Accept wrong readiness | Invalid readiness becomes active |
| Call native preparation with service mutex held | Client read times out from deadlock |

`run-01` contains all three passing full trials. `controls-02` is the complete
six-control result. The first control runner completed the early-clock control,
then stopped because rustfmt had changed the watchdog mutation's source layout.
`evidence/mutate-01.py` and `controls-01/runner-error.json` preserve that runner;
only its source-match anchor was corrected. Runtime code, behavioral assertions
and thresholds were not altered. No partial runner result is counted as a pass.
All failure paths retain cleanup exit codes. Forced unload is detected while the
native call is held, before releasing it into unmapped code; cleanup kills it.

## Reproduce

On macOS with rustc, clang and Python, from repository root, using unused paths:

```sh
python3 experiments/07-stalled-native/staged/check.py /tmp/mo-staged-run
python3 experiments/07-stalled-native/staged/mutate.py /tmp/mo-staged-controls
```

Fresh compilation is part of each trial. Raw traces are gzip-compressed JSON;
commands, artifacts, fingerprints, environment and outcomes are retained.
`evidence/MANIFEST.json` fingerprints this revision; the original experiment's
manifest is verified separately and remains unchanged.

## Limits and delivery

The 200ms budget covers native preparation and activation **after staging**, not
the entire update. Loading latency is separately measured and unbounded here.
A stuck OS loader/constructor may prevent additional loading and image snapshots;
ordinary service work does not acquire that loader mutex. A permanently hung
native preparation loses authority but retains its thread/code indefinitely.
No arbitrary native-code preemption or guaranteed reclamation is demonstrated.

This remains a trusted synchronous C ABI on macOS, excluding escaped pointers,
retained callbacks, TLS, module-owned background threads and malicious code.
No queue-representation migration, crash/external-effect recovery, exhaustive
thread-schedule proof or production availability SLA. Tests used the explicit
200ms deadline plus 750ms timeout-observation tolerance, not a hard real-time OS.

Delivered on the existing review branch; no merge, deployment or next experiment.
