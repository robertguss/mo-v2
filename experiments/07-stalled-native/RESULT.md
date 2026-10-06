# Experiment 7: preparation mechanism works; original full trial did not pass

**The original no-retry acceptance run failed.** A cold native-library load can
use the entire 200ms attempt budget before preparation starts. The service
correctly refuses that attempt, but the planned scenario requires a newer
candidate to activate before the old preparation returns. We have not established
that complete no-retry promise. The deadline and original checks were not changed.

A separately labelled diagnostic, which retries only attempts that timed out
before native entry, passed three trials with **288 acknowledged jobs**. Each
attempt still has the original 200ms deadline. Native preparation can stay held
or block in an 800ms native sleep while the service continues processing work;
the watchdog refuses the update, a newer candidate activates before the old one
returns, and its late result is discarded. The refused candidate stays mapped
until native execution ends, then its destructor runs and dyld no longer lists it.

Robert authorized “merge it and continue”. Experiment 6 was fast-forwarded into
main at a1c032fa7fa2b1061ce79f9fd13403061640bb5b and remote main verified. This
experiment is ROB-1328, under D119 (merge and continue with stalled native updates).
Same-author implementation and verification continue; no independent acceptance
claim. All earlier experiments and locks are unchanged.

## Changes and boundary

The host extends experiment 6's real native loader, FIFO queue and per-job module
ownership. A new native preparation entry point returns readiness value 42.
Preparation and loading run on an updater thread outside the service mutex;
a separate watchdog enforces attempt expiry. Each attempt has a never-reused ID,
base active version and immutable terminal outcome. Native return checks identity,
base version, readiness and deadline before acquiring activation authority.
Timeout removes that authority; it does not kill a thread or release its library.
A held candidate's callback can be explicitly released after timeout. The timed
native-sleep candidate makes no host calls during its 800ms sleep.

Jobs still pin their admission version through both native calculation steps.
TCP connections and the host-owned queue remain stable. This is native preparation,
not queue representation migration, a new compiler, or a permanent Mo ABI decision.
Rust, C, Python and OS loading APIs suffice; no new dependencies or v1 imports.

## Original attempts and repair

- `run-01`, original host (`evidence/host-01.rs`): failed when the newer candidate
  timed out before native entry. Its terminal timestamp was **222.214ms** after
  admission. Inspection also identified a lock-order defect: snapshot acquired
  the service mutex and then waited for the loader mutex. Slow loading could
  therefore delay watchdog/service access through snapshot.
- Fix: snapshot now obtains the loader mutex before acquiring service state;
  native loading never acquires service state while holding that loader mutex.
  Explicit retirement releases service state before running dlclose/destructors.
  This avoids waiting for loader activity with the service mutex held. It does
  not make arbitrary loader operations bounded.
- `run-02`, unchanged original checks: trial 1 passed all 96 jobs, but trial 2
  failed before held native preparation began. The cold candidate was refused at
  **200.869ms**, with entered=false and returned=true. Correct refusal is not
  counted as the required successful complete trial. Stop rather than enlarge
  the deadline or count a refused activation as a success.

These traces establish budget exhaustion during loading, not its OS-internal
cause. Code-signing or security scanning is a possible explanation, not a measured
finding. No loader/security bypass was used.

## Supplementary diagnostic, explicitly not acceptance

`probe.py` is separate from unchanged `check.py`. It permits at most three attempts
per artifact only when an attempt times out before native entry, waits for the
failed loader to return, and records every retry. Every individual attempt keeps
the same deadline and refusal requirements. It does not treat entered-then-stalled
preparation as a reason to retry within that helper.

The first diagnostic (`probe-01`) exposed a harness accounting defect: a destructor
from a previous safely refused load was mistaken for unloading the current held
attempt. The original diagnostic is retained as `evidence/probe-01.py`. The fixed
probe compares destructor counts against a per-attempt baseline and still requires
actual image presence while executing and absence after return.

Final diagnostic `probe-02`:

| Trial | Completed jobs | Cold-load retries | Held/native-sleep timeout times |
| --- | ---: | ---: | --- |
| 1 | 96 | 3 | 200.914ms / 200.196ms |
| 2 | 96 | 0 | 200.488ms / 201.021ms |
| 3 | 96 | 1 | 200.721ms / 200.822ms |

Five original TCP connections persist in each trial. Old work proceeds during
preparation; v3/v5 activate before the held/sleeping stale candidates return;
all completions match actual payload, sequence, admission version and both native
steps. Wrong readiness refuses. Old active versions retire after references end.
Each trial includes two 300ms intervals without client polling, demonstrating
that timeout recording does not depend on a client command. Timings are local
observations with the specified tolerance, not a production SLA.

Five actual source controls compiled and were rejected against this **diagnostic**
(`controls-02`); this does not make the original acceptance pass:

| Mutation | Failure observed |
| --- | --- |
| Disable watchdog | Held preparation stays pending |
| Remove stale/deadline authority checks | Old candidate overwrites newer activation |
| Force dlclose while candidate is executing | Candidate image disappears prematurely |
| Accept wrong readiness | Corrupt readiness activates |
| Call native preparation with service mutex held | Client read times out from deadlock |

The forced-unload control is detected before releasing the native return address;
cleanup kills the process. No crash is counted as passing behavior. All failure
paths retain exit codes and teardown results. Earlier `controls-01` is retained;
final control claims use the corrected diagnostic only.

## Reproduce and interpret

From repository root on macOS with rustc, clang and Python, using unused paths:

```sh
python3 experiments/07-stalled-native/check.py /tmp/mo-stalled-original
python3 experiments/07-stalled-native/probe.py /tmp/mo-stalled-diagnostic
python3 experiments/07-stalled-native/mutate.py /tmp/mo-stalled-controls
```

The first command is the original criterion and can fail on cold loading; that
failure must remain a failure. Later commands diagnose the narrower mechanism.
Every trial recompiles the host, starts v1, connects clients, then compiles the
new artifacts. Raw traces are losslessly gzip-compressed JSON, with build commands,
responses, timestamps, artifact hashes and outcomes. The manifest fingerprints
all retained files. Source revisions and original failures are preserved.

## Remaining decision and limits

Recommended next proposal: separate *loading/staging* from the timed *native
preparation/activation* attempt, or explicitly approve retrying safe load-time
refusals. Either changes the experiment's success conditions and needs an explicit
scope decision; neither is silently applied here. The original 200ms cold-load
success promise is not established.

This restricted trusted native ABI excludes arbitrary constructors/destructors,
escaping pointers, retained callbacks, TLS, module-owned background threads,
malicious code and arbitrary preemption. A forever-hung preparation loses authority
but retains its thread/library forever; eventual reclamation requires return.
Serialized loader/image-inspection operations may themselves block; they do not
hold service state while waiting, but a stuck OS loader can prevent other loads
and snapshots. No bounded loader operation, crash/external-effects guarantee,
full Rust scheduling proof or production readiness follows. Queue representation
migration remains a separate earlier experiment.

Stop at this pushed report for review. No merge of experiment 7, deployment,
changed acceptance criterion, or next milestone was performed.
