# Both million-element resource obligations passed under the approved amendment

**Resource execution is complete; final acceptance/integration review remains.**
The exact [timing freeze](FREEZE.md) was committed and pushed at
[f1e5f58](https://github.com/robertguss/mo-v2/commit/f1e5f58e0a6809be7ba7fb94e0c2ee7be5f93656)
before a single full attempt. Robert approved the 1,800-second sum guard and
unchanged 600-second discard guard. No repair, extension or workload retry occurred.
The old 900-second failures and both OOM attempts remain unchanged; these new
results are not retroactive passes under the old contract.

| Workload | Inclusive seconds | Approved guard | Committed transitions | Result |
| --- | ---: | ---: | ---: | --- |
| Million-element non-tail sum | **995.820047738** | 1,800 | 18,000,014 | Passed; answer `1000000` |
| Million-element discarded list | **82.833321094** | 600 | 2,000,003 | Passed; answer `0` |

Discard started only after the complete sum pass. Both runs verified deepest
full observation, resumed completion, both destruction calls, drop, teardown,
normal native exit and the final resource predicate. Both report evaluation
cell counts `[0, 0, 1000000]` and zero remaining owned cells. Sum reached 1,000,001
explicit frames; discard reached a 1,000,000-cell cleanup chain. Each child had
an eight-MiB stack. The outer runner exited zero after both results and the final
preservation check. The supervised service is stopped.

## Separate timings explain why total elapsed is not evaluator time

The native process's exclusive wall categories are:

| Native category | Sum seconds | Discard seconds |
| --- | ---: | ---: |
| Begin/evaluation, excluding collector callbacks | **151.630702** | **5.051399** |
| Observation generation | 8.052957 | 0.195775 |
| Collector/bookkeeping | 84.082296 | 12.516791 |
| Serialization/transport, including blocked writes | **732.507400** | **60.845473** |
| Candidate cleanup/drop | 2.331025 | 0.006980 |
| Frontend | 0.031841 | 0.000803 |
| Source approval wait | 0.001387 | 0.000773 |
| Native measured interval | **978.637608** | **78.617993** |

Evaluation includes candidate-produced callback metadata, instrumentation and
descheduling; it is not pure language-evaluation CPU. Transport includes waiting
for Python to consume output, not just serialization CPU. Native process CPU
(user + system) was 336.476900 / 28.113455 seconds, combining candidate, collector
and transport work. Native elapsed excludes process startup/exit and sidecar
persistence, which remain included in the parent watchdog.

The parent separately measured predicate checking at **736.799036 / 48.440326
seconds**, JSON decoding at **147.438894 / 16.697183**, retention/hash at
**61.845064 / 7.302972**, and read/wait/framing at **45.705287 / 6.016086**.
Launch/request, reply writes, finalization and residual orchestration account
for the rest. Each ledger reconciles exactly in integer nanoseconds.

**Native and parent run concurrently: never add these process totals.**
The parent ledger ends before summary persistence. Its finalization remainder
was 653,251 / 608,271 ns; both remain within the inclusive watchdog. The resource
rows retain real pre-finalization elapsed snapshots (995.531388022 / 82.771581032
seconds), and saved summaries explicitly label their pre-write snapshots. The
outer [runner report](evidence/result/report.json) retains authoritative elapsed
through persistence and recheck; the table above uses those final values.

This is one instrumented run per workload, not a latency distribution,
uninstrumented benchmark, speed target or universal performance bound.

## Memory stayed within the authorized larger orb

The workload cgroup cap stayed **42 GiB**, with a 64-GiB filesystem and about
45.8 billion disk bytes still free after execution. Cgroup max/oom/oom_kill
counters remained zero. Native peak RSS was **8,137,444 KiB (7.76 GiB)** for sum
and **1,722,020 KiB (1.64 GiB)** for discard. Python's process-lifetime high-water
mark was **11,860,312 KiB (11.31 GiB)**: discard inherits the earlier peak, so it
is not a discard-only memory measurement. The cgroup lifetime peak was about
34.08 GiB including page cache and prior workloads, not isolated native RSS.

The four-GiB provisioning floor is not a four-GiB memory cap or demonstrated
consumption bound. These finite successes do not prove universal memory or
host-stack independence. Sparse shell status reads are disclosed observer work;
no separate sampler, build, packaging or heavy validation ran concurrently in
this orb. Hosted Buildkite used other machines.

## Complete retained evidence was independently reconciled and restored

| Retained stream | Decoded bytes | Complete records | Compressed bytes |
| --- | ---: | ---: | ---: |
| Sum | 11,774,430,901 | 18,000,024 | 1,053,258,693 |
| Discard | 1,364,452,360 | 2,000,013 | 165,395,184 |

Bounded post-run inspection checked gzip EOF/CRC, hashed every decoded byte and
counted records without retaining the whole stream. Both pipeline exits were
`0 0`; both hashes match the timed runner and neither stream has a partial tail.
Final small records include drop and teardown. This is independent byte-level
inspection, not another semantic replay; semantic verification happened during
the timed run. [Methods](evidence/result/METHODS.md) and
[post-run reconciliation](evidence/result/POSTMORTEM.json) give exact hashes,
checks and limitations.

The lossless result package preserves **42 originals in 75 volumes /
778,153,600 bytes**, with complete archive readback, original rehashing and full
restored-file verification. Index SHA256:
`be284615351fb98945d8f8858ec7e1b48674eb0dfd52edb3d35becbc15dd317e`.
Originals remain at `/home/user/rob1333-stage-b-timing-approved-01`; no private
files, installed runtimes or build/cache files are included. Supervisor restart
attempts after successful exit were refused by the exclusive start marker before
any second workload could run; the journal is preserved.

Restore from `experiments/13-source-acceptance`:

```sh
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-timing-01/evidence/result/public /home/user/NEW-timing-result-restored
```

All previous frozen identities and both old binaries remain unchanged. The new
timing lock is `9b7fdabe7734e78ec495da2dd2f5c1095a707a669cb6147cca7857ba0ecbe44c`.
`RESULT.sha256` seals this result without changing that freeze. The pre-run
[Buildkite 47](https://buildkite.com/robert-guss/mo-v2/builds/47) passed Rust/Lean;
it supplements rather than substitutes for the resource checks.

**Remaining delivery gate:** final Stage B acceptance/integration review and
reconciliation of PR #9 with this acceptance branch. PR #9 is still draft at its
older implementation head; neither it nor main was changed. ROB-1333 remains
Building, not Done. Both orbs remain unarchived. No private corpus rerun, new
evaluator control, merge or deployment is part of this result.
