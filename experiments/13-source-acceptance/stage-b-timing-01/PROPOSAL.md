# Timing amendment 01: separate execution from checking overhead

**Proposed contract; no implementation, freeze or new resource execution.**
On 9 October 2026, Robert agreed with the recommendation to separate interpreter
performance from verification overhead while retaining every correctness check
and an explicit overall guard in the
[continuation thread](https://ampcode.com/threads/T-01a120a8-5f89-72d7-a894-b48b82ed155c).
That agreement approves the direction, not a numerical replacement deadline.
The proposed **1,800-second sum / 600-second discard** guards below still require
approval. No old frozen file, executable or failed result changes here.

## Why change the reporting contract

[D162](../STAGE_B_PREPARATION.md#the-new-projections) chose 900 seconds from
checking-equipment projections, not a native interpreter benchmark or product
SLA. The [ownership-approved sum](../stage-b-ownership-01/RESULT.md) reached
Finish but failed the inclusive watchdog at 900.516854128 seconds. Completed
final verification, cleanup and normal exit were not established; discard was
not run. That remains a failed attempt under its original contract.

[Terminal profiling](../stage-b-terminal-profile-01/README.md) measured 26.689126
seconds for selected decode/schema/history-hash operations on the retained final
record. These isolated measurements omit other work and do not determine how
much longer the failed attempt needed. They cannot justify a precise new bound.

The native driver's elapsed clock includes collection and blocked writes while
the parent verifies records. Process CPU includes both candidate and collector.
Neither is evaluator-only time; subtracting a separately measured Python replay
from that clock would not recover it.

## Proposed guard remains inclusive; performance becomes measured attribution

Use 1,800 seconds for the million-element non-tail sum and retain 600 seconds
for million-element discard. The sum proposal doubles the operational allowance
to leave room for the complete checking pipeline and timing instrumentation.
It is a budget choice, not an extrapolated passing time, performance target,
universal bound or promise that this attempt will pass. Retaining discard's
existing guard does not assert its workload will fit: discard remains unrun.

The guard must include launch, source checking, execution, observations, every
record's checking, retained evidence, cleanup, process exit and timed-result
finalization. Do not pause it during verification, start a fresh allowance at
Finish, or move required work to an untimed subprocess. Subsequent independent
archive packaging and postmortem inspection remain outside the workload clock.

All required work must finish within the guard for an amended resource pass.
A timeout is an incomplete/failed resource attempt under this new contract,
not proof of incorrect Mo semantics or slow evaluator execution. A semantic
rejection remains a rejection even if it is fast. No separate evaluator speed
threshold is proposed. A future speed requirement needs its own agreed workload,
measurement method and threshold; this amendment must not invent one implicitly.

Only a passing sum permits discard. Stop at the first material failure; preserve
it without silently repairing, extending the guard or retrying. Old failures
are neither relabelled nor compared as though they used this amended contract.

## Native and parent measurements describe concurrent work

Instrument a separately versioned collector and runner; do not modify candidate
or runtime code or overwrite either pinned native binary. Keep semantic wire
records unchanged. A separately validated timing sidecar can hold the native
measurements without teaching the frozen semantic decoder new record types.
Its exact schema and persistence path must be defined before implementation is
frozen. Missing or inconsistent timing evidence must prevent an amended pass.

Use monotonic wall clocks and exclusive nested accounting within each process:

| Native category | Boundary and limitation |
| --- | --- |
| Frontend | Candidate source checking, separate from evaluation. |
| Begin/evaluation | Candidate begin/advance calls, excluding time inside collector callbacks. Includes candidate-generated metadata and instrumentation overhead attributed to these scopes; not an unobserved evaluator benchmark. |
| Cleanup/drop | Candidate destruction and drop, excluding nested collector work. |
| Observation | Candidate observation/export/output generation, including serialization of its histories; separate from evaluation even though candidate code produces it. |
| Collector/bookkeeping | Validation, comparisons, native observation bookkeeping and other measured driver work not in another category. |
| Serialization/transport | Outer-record serialization, pipe writes and flushes, including backpressure. |
| Approval wait | Waiting for the parent source-check response, excluding nested transport work. |

Collector callbacks are nested inside advance; observation and transport are
nested inside callbacks. Counting all inclusive spans as independent work would
double-count them. Validate that exclusive categories reconcile to the native
measurement interval. Report its exact start/end boundaries and any process
startup/exit work outside it; do not call it complete process elapsed time.
Wall attribution includes descheduling and is not per-category CPU accounting.

The parent separately reports launch/request writes, native read/wait/framing,
retention and stream hashing, JSON decode, semantic/source predicates, reply
writes, exit/evidence finalization, and any residual orchestration time. Those
categories must reconcile to its explicitly defined measurement interval, with
the authoritative inclusive watchdog interval reported separately if boundaries
differ. Normal-path process CPU/RSS can supplement these measurements but cannot
be relabelled evaluator-only CPU/RSS.

**Do not add native and parent wall totals:** the processes overlap. Parent
verification can increase native transport wait. Report both breakdowns next to
the inclusive elapsed time, not as additive components of one elapsed duration.
Instrumentation itself has cost; record it and avoid claims about the same run
without observers. Do not add an external sampling process to the timed attempt.

## Correctness and physical obligations stay intact

Retain the approved ownership verifier, strict decoder, recursive JSON
validation, source/path checks, exact full deepest and terminal observations,
periodic summaries, every-record predictions, history checks, ownership and
physical cell checks, resume/completion, destruction, repeated destruction,
teardown and normal process exit. No caching a prior verdict, dropping history,
sampling records, weakening JSON validation or changing observation requests.

Retain depth 1,000,000, the 100,000,000-transition cap, eight-MiB child stack,
four-GiB provisioning floor, exact answers, evaluation cell counts, zero
remaining owned cells and the non-tail-sum explicit-frame requirement. Use the
already authorized 42-GiB workload cgroup and 64-GiB filesystem, recording actual
limits and free disk before execution. This proposal requests no further memory,
disk, swap or stack change. Keep the exact CPython 3.14.7 runtime with JIT off.

The old envelope helper clamps a copy of elapsed time when delegating to an
older 600-second predicate. The new version must not present a fabricated or
clamped elapsed value as an observation. Keep the unchanged non-time predicate
logic and check the amended guard explicitly, preserving real elapsed values
and old helpers byte-for-byte. Review that separation before freezing it.

## Validation and freeze precede any full attempt

After guard approval, implement only measurement and explicit envelope
selection. Validate full bounded sum/discard streams against the approved
collector/verifier, including deepest/resumed/completed and both destruction
boundaries. Compare all semantic rows/results, accounting explicitly for
already-nondeterministic clocks and physical addresses; timing does not excuse
semantic differences. Retained-stream replays alone cannot validate a newly
instrumented native collector.

Exercise nested attribution, blocked output and parent verification delays,
malformed/missing sidecars, abnormal native exit, watchdog expiry, and both sides
of the amended envelope boundary. Slow verification must remain inside the
overall guard but outside native evaluation accounting. Record instrumentation
overhead on bounded workloads without claiming a full-size bound. These timing
and protocol probes are not evaluator sabotage controls or resource acceptance.

Review and freeze the exact validated collector, runner, envelope predicate,
timing schema, executable fingerprint and all transitive previous identities
before the full run. Preserve old binaries and freezes. Use a fresh external
attempt directory and an exclusive launch marker that refuses supervisor
restarts. No concurrent builds, packaging or heavyweight profiling. Preserve
complete public evidence losslessly; do not retrieve or rerun private cases.

**Current delivery:** proposal only. The active frozen resource contract is
still 900/600 seconds. No measurement implementation, new binary, resource
result, acceptance, PR-branch update, merge or deployment is delivered here.
PR #9 remains draft/unready; ROB-1333 remains Building. Both orbs stay unarchived.
