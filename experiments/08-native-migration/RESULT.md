# Experiment 8 passed: new native code and real native queue migration

**Three final fresh-build trials preserved all 291 acknowledged jobs**, with five
persistent TCP clients per trial. The service changed a nonempty native array
queue into a native linked queue while old work remained inside old machine code.
New jobs used the new code; migrated queued jobs kept their admission code.
Corrupt and stalled migrations refused safely. After timeout, old queue processing
resumed before the expired native migration returned. A newer migration succeeded;
late old results could neither replace that queue nor take activation authority.

Robert authorized “sounds good. do it” (D122, combine native replacement and real
queue-state migration). ROB-1329. This is same-author implementation and
verification, not independent acceptance. Prior experiments/specifications/locks
and their failed attempts remain unchanged.

## What actually migrates

Queue allocation, storage, push, pop, export and free all execute in the loaded
native library. V1's C Queue contains eight contiguous rows. V2 and subsequent
candidates store allocated linked nodes with head/tail pointers. The Rust host
contains neither native representation. Source inspection establishes those
layouts; runtime traces record exported rows and module-reported layout, real
loaded images, separate artifact fingerprints and changed native arithmetic.

The host retains a sequence-to-code-owner map so queued jobs keep their original
code; it is not an alternate payload queue. Its accepted/completed ledger allows
observable preservation checks. Every job calls its pinned library twice:
payload 10 produces 12 under v1, 118 under later code. Intermediate results and
final values are checked along with FIFO, IDs, payload and admission version.

After loading/validation, the host snapshots canonical rows, freezes admission
and dequeue, and arms the 200ms migration deadline. Native migration builds a new
opaque queue outside the state lock using that private copy. The host compares
all candidate rows with the snapshot and verifies the old queue, authority token,
base version, freeze ownership and deadline. Queue and active code publish together
under the lock. The old queue is freed outside the lock through its own pinned
library. An already-running job can finish independently of queue migration.

On timeout, the watchdog removes only that attempt's authority/freeze and resumes
the old queue. The expired native computation retains its copied input and code
owner. When it returns, its candidate is freed through its own library before the
last code reference closes. No arbitrary native thread is killed or preempted.

## Final scenarios and observations

Each final trial (`evidence/run-03`) has 97 jobs and ten update attempts:
normal array-to-list migration; corrupt nonempty and empty migrations; held v4;
newer normal v5; native-sleep v6; newer normal v7; wrong ABI; missing symbol;
missing file. All candidate artifacts compile after v1 starts. No update retries.
Four producer connections submit 80 final jobs concurrently; the controller and
producer connections persist throughout.

| Trial | Jobs | Held-migration timeout | Native-sleep timeout |
| --- | ---: | ---: | ---: |
| 1 | 97 | 200.190ms | 200.766ms |
| 2 | 97 | 200.598ms | 200.566ms |
| 3 | 97 | 200.915ms | 200.850ms |

These clocks begin after staging, as in the approved experiment 7 revision.
Staging remains separately observed and unbounded. Two 300ms intervals without
client polling in every trial establish autonomous timeout. The native-sleep
migration spends 800ms in native sleep without intervening host callbacks.
Newer v5/v7 activates before its expired predecessor returns.

During a frozen migration, duplicates retain their original acknowledgment and
new submissions receive busy without being accepted. On timeout, another old job
actually dequeues while the expired migration is still held/sleeping; new old-code
work can also be admitted. This checks restored behavior beyond a status flag.
Corruption modifies an actual candidate payload (or inserts a bogus row for an
empty input); the unchanged old queue remains usable after rejection.

Retirement is refused while old work or native migration references code. Every
observed unload has both OS image removal and a destructor marker reporting zero
live native queue objects. The final active queue is also freed before shutdown
unloads v7. This is queue-object accounting, not a general native heap leak or
memory-safety proof. Native node freeing is inspected in the small C implementation.

## Six broken implementations caught

Every final source mutant compiled and failed the relevant observable assertion:

| Mutation | Rejection |
| --- | --- |
| Skip candidate validation | Corrupt migration activates |
| Allow expired candidate publication | Stale migration changes newer queue/version |
| Leave old queue frozen after timeout | Old queue does not resume |
| Force module unload while old job executes | Executing module disappears from loader |
| Rebind queued jobs to newly active code | Mixed/wrong native calculation |
| Skip native queue disposal | Nonzero live queue count at module unload |

Final controls are `controls-02`. The forced-unload case is detected while the
old job is held, before returning into removed code; cleanup kills the test
process. Crashes are not counted as successful behavior. Every failed process
has bounded teardown and retained exit status.

`controls-01` is a retained unsuccessful control run: its stale-publication mutant
also bypassed ordinary corruption checking, so it failed the corruption scenario
before reaching the intended stale-return check. The runner correctly rejected
that as insufficient. `evidence/mutate-01.py` retains the original runner; the
corrected mutant bypasses source validation only for expired publication. Expected
behavior did not change, and all six final controls reached their intended faults.

## Retained verification and reproduction

`run-01` passed the initial three trials. `check-01.py` retains that harness.
`run-02` passed three trials after adding observable dequeue progress while stale
migration still runs; `check-02.py` retains the checks used by final controls.
`run-03` adds final active-queue disposal at shutdown and supplies the final
291-job claim. No runtime implementation defect or repair occurred in these runs;
prior results are not pooled to inflate counts. All attempts remain in evidence.

On macOS with rustc, clang and Python, from repository root, using fresh paths:

```sh
python3 experiments/08-native-migration/check.py /tmp/mo-native-migration-run
python3 experiments/08-native-migration/mutate.py /tmp/mo-native-migration-controls
```

Each trial recompiles into a disposable directory. Rust and C warnings are errors.
The harness uses Python stdlib only. Traces are gzip-compressed JSON with commands,
responses, timestamps, artifact hashes and cleanup results. The manifest records
retained file fingerprints; prior experiment manifests were separately verified.

## Limits

This is a trusted synchronous C ABI and bounded eight-slot queue on macOS, not a
permanent Mo representation/backend design. It excludes escaping pointers, retained
callbacks, TLS, native background threads and malicious libraries. Small queue
operations/export/free are trusted to return. Staging/constructors and OS loading
are unbounded; a forever-hung migration loses authority but retains resources.
No arbitrary native-code preemption, crash recovery, external-effect transaction,
exhaustive thread-schedule proof or production availability SLA. Admission/dequeue
pause during migration is intentional; client connections stay usable and explicit
busy responses are part of the contract.

Stop at the pushed review branch. No merge, deployment or further experiment.
