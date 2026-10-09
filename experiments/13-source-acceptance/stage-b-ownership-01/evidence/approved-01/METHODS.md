# Approved ownership attempt: timeout at final full observation boundary

Robert approved adopting the exact ownership proposal and rerunning the two
resource obligations in the continuation thread. The 17-file implementation
freeze was committed and pushed before execution at
[d24a106](https://github.com/robertguss/mo-v2/commit/d24a106a753be3a03558b674995eb10e7c210eae).
`prepare.py` generated the lock exclusively, verified the unchanged proposal,
selected its ownership function/decoder explicitly, and ran the established two
depth-64 smokes. Both native processes exited 0, reached their deepest full
observation, completed and performed two destruction calls. Both correctly failed
the unchanged million-element depth predicate. Those smokes are not acceptance.

## One full attempt, no repair or retry

`execute.sh` launched the exact pinned CPython 3.14.7 with JIT disabled, tested
collector binary and new explicit-selection runner in a supervised orb service.
The exclusive `started-at.txt` prevents any second launch in this attempt.
`command.txt`, `pre-run-commit.txt` and the copied `million/LOCK.json` retain
execution identities. No rebuild or candidate/collector change was introduced.
The workload cgroup still provides 45,097,156,608 bytes (42 GiB); runner preflight
records 50,875,490,304 free disk bytes. The service's own memory.max/high were
unlimited below that parent cap. No cgroup, swap or clock limit was changed.
The eight-MiB child stack and four-GiB provisioning floor stayed unchanged.

The actual runner reports `passed: false`, `TimeoutError: inclusive watchdog`,
and **900.516854128 seconds**, under the unchanged inclusive 900-second limit.
This is the exception-path measured elapsed time, including context unwinding,
not a new time allowance or a measurement of the exact signal-delivery instant.
Shell exit was 1. There is no discard directory: discard did not execute.
Execution stopped at this first material failure; no repair or retry followed.
The service supervisor later attempted wrapper restarts; every attempt failed
at the exclusive start marker before Python/candidate execution. The full
service journal preserves this behavior. The service was explicitly stopped.

No Python sampler, build, packaging, heavy validation or semantic replay ran
alongside the timed workload. Sparse shell reads of log/size/time and cgroup
counters provided progress; this does not claim zero observer overhead. A
remote CI status query also occurred; CI did not execute in this orb.

## The final retained boundary reports an answer, not acceptance

The failed summary reports step counter **18,000,014** and 18,000,020 phase
entries. The byte inspection independently finds exactly 18,000,020 complete
records. The penultimate record is the `Finish` commit at step 18,000,014, with
driver elapsed_ns 877,563,337,817. The final record is a **595,556,696-byte**
`advance` record (excluding newline), with driver elapsed_ns 881,225,491,814,
reporting `finished`, type `Int`, answer `1000000`. Its snapshot includes the
full accumulated events and birth metadata. Those driver clocks are neither
the inclusive passing runtime nor the verifier's timeout instant.

The sequential orchestrator returned from the checks for preceding rows before
retaining/processing this final row; unlike the earlier attempt, execution
progressed beyond the deepest observation and reached the Finish commit. But
retention and phase counters precede completion of all checks on their row.
Without an instruction-level sample, this evidence does not identify the exact
interrupted statement or establish that final-advance checking returned. No
destruction, teardown or normal-exit records are retained. The final observation,
cleanup, normal process exit and passing final verifier verdict are not all
established under the clock. A visible answer cannot replace these obligations.

The Python verifier's reported peak RSS is **11,858,640 KiB** (about 11.31 GiB).
Native peak RSS is unavailable on the exceptional exit path. The parent cgroup
lifetime peak is 32,266,416,128 bytes (about 30.05 GiB), including page cache and
other workload processes; it is not isolated native/verifier RSS. Cgroup max,
oom, oom_kill and oom_group_kill remain zero before/after. The kernel-log window
is 13:45:45 through 14:01:35 UTC and contains no OOM message. This was a timing
failure, not observed cgroup OOM; no universal memory or scaling bound follows.

## Independent bounded inspection and preservation

GNU gzip plus `inspect_tail.py` exits 0/0, checks EOF/CRC, and recovers
**10,583,340,454 decoded bytes**, with no partial tail. Decoded SHA256
`2e811c2231678f636f7f46a6780a822e490b847367596b8c60c326d19657eb6e`
matches the runner's streamed digest. The original gzip is 959,475,914 bytes.
The bounded suffix contains no whole small record because the final record is
large; a second gzip pass through `inspect_boundary.py` retains only 4-KiB
prefix/suffix samples and lengths of the last two records. Both pipeline exits
are 0; both record counts agree. Small/multi-chunk/partial-tail synthetic probes
validated the boundary inspector. These inspections do not replay semantics.

The normal unprivileged service journal is incomplete; `service-journal-full`
was obtained with read-only sudo journal access. An initial unsupported dmesg
timestamp spelling was corrected to its accepted UTC date/time syntax before
capture. These auxiliary inspection adjustments changed no workload execution,
scientific bytes, expectation, criterion or result.

`postmortem.py` rechecks every frozen identity transitively and asserts agreement
with the runner's before/after identities, stream hash/counts and absence of
discard. The exact original request, logs, streams, reports, preparation and
inspection scripts remain external. The established public chunk-volume packager
reads every archive back and restores every logical file for a fresh hash check.
No private data, installed runtime or build/cache file is included. Old attempts
remain intact. PR #9 remains draft; no acceptance, merge or deployment follows.

The next useful investigation is the remaining full-observation/verification/
cleanup path and its required history serialization, without omitting checks or
loosening deadlines. This postmortem neither implements another optimization nor
authorizes another resource attempt.
