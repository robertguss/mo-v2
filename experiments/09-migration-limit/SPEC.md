# Experiment 9: bounded retained migration workers

Authorized in D123 / ROB-1330. Same-author verification. This is a separate
extension of experiment 8; all previous specifications and evidence remain intact.

## Question and fixed boundary

Can a fixed admission cap contain host-owned migration resources when trusted
native migration functions never return, while the old service keeps working?

At most **two updater threads/handles** may be outstanding, including staging,
native migration and final disposal. Admission checks and reserves under the
service mutex before spawning/loading. Finished threads are joined/reaped before
reuse; watchdog timeout alone never releases a slot. At capacity respond
`resource_limit` without creating an attempt or loading a candidate. The existing
32-attempt, eight-module and 256-job experimental ledger bounds remain separate.

A native migration gets the existing 200ms deadline after staging. Loading and
native destruction remain unbounded. Timeout restores old queue availability,
fences publication and pins code until native return. Two permanent hangs exhaust
updates until process replacement; no graceful reclamation is claimed. Ordinary
jobs, connection use and state observation must continue. Shutdown must report
busy, not pretend it freed executing code.

## Evidence fixed before implementation

Three fresh-process, no-retry trials with five persistent TCP clients each:

1. Observe baseline OS thread count after all connections are handled. Successful,
   corrupt, incompatible and held-then-returning attempts release their slots.
   Exercise several successful updates with native queue migration and code
   retirement. After return/reaping, OS thread count returns to baseline.
2. Fill both slots with separately compiled C functions that record entry then
   loop forever in native `nanosleep`, with no cooperative release path. Exercise
   nonempty queued work, timeout independently of client polling, and process work
   between the two stalls. For each, observe 200–950ms terminal time (the same
   scheduler allowance as experiment 8), unchanged active version and safe code
   retention. External `ps -M` thread count is baseline plus two after both stalls.
3. Four clients concurrently issue 20 requests each for another candidate.
   Every response is resource_limit. Attempt ledger, constructor log, loaded
   images and external thread count remain unchanged. Neither permanent native
   function returns; both executing libraries remain mapped and cannot retire.
4. Process at least 80 further concurrent jobs with the same clients after
   saturation. Exact acknowledgement/completion/payload/FIFO/admission-version
   ledgers and native two-call results must agree; no reconnect or server restart.
5. Shutdown reports busy. Kill and reap the disposable process in bounded test
   cleanup; explicitly report process teardown, not safe in-process unloading.
   Force one test failure after both hangs and prove cleanup still reaps it.

Compile real incorrect host variants and require intended failures for: no cap,
timeout releases capacity, never reap returning workers, unsafe retirement of
executing migration code, and failure to resume work at timeout. Preserve each
failure and do not weaken expectations to get a pass. Also run the unchanged
experiment-8 trial against the new host to check retained migration behavior.

## Limits

macOS, trusted fixture C ABI, fixed clients/work/queue sizes. Source inspection
establishes that fixture loops have no return/release path; finite observations
cannot prove an arbitrary program never returns. Each stuck worker retains a
thread stack, code owner and at most eight copied rows (256 row bytes), plus
fixture/library/runtime overhead. This does not bound arbitrary native allocation,
thread creation, destructors, external effects, crashes or loader latency. It is
not process isolation, preemption, a permanent Mo policy or a production SLA.
