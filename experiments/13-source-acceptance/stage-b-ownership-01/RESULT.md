# Approved ownership run: reached Finish, but failed inclusive resource timing

**Stopped at the first material failure. Stage B is not accepted.** The
million-element non-tail sum reports `passed: false` and
`TimeoutError: inclusive watchdog` at **900.516854128 seconds** under its unchanged
900-second inclusive limit. **Discard did not execute.** There was no candidate
or checker repair, deadline change or retry after this result. PR #9 remains
open/draft and is not ready to merge.

Robert approved the exact previously reviewed ownership implementation. Its
[freeze](FREEZE.md) was committed and pushed before execution at
[d24a106](https://github.com/robertguss/mo-v2/commit/d24a106a753be3a03558b674995eb10e7c210eae).
The two depth-64 semantic smokes completed correctly and rejected the unchanged
full-depth resource predicate as expected. The historical proposal README and
all its bytes remain unchanged; the freeze supersedes pending-adoption wording,
not prior measurements or limits. [Buildkite 43](https://buildkite.com/robert-guss/mo-v2/builds/43)
passed on that exact freeze commit, not as resource acceptance.

## The visible answer does not satisfy the remaining checks

The sum progressed beyond the deepest observation and reached the **18,000,014**
`Finish` commit. The final retained row is a **595,556,696-byte** full `advance`
record reporting `finished`, type `Int`, answer `1000000`. Its snapshot contains
the accumulated event and birth metadata. The failed summary records
18,000,020 phase entries; bounded byte inspection independently counts exactly
18,000,020 complete retained records.

The sequential checker returned from the preceding rows before processing this
final row, but retention/counters precede completion of the checks on their own
row. The evidence does not establish that final-observation verification
returned, nor pinpoint the interrupted instruction. No destruction or teardown
records were retained; normal native exit and the final verifier verdict are
not established. The final row's driver clock (881,225,491,814 ns) is not a
passing inclusive runtime. The reported 900.516854128 seconds is exception-path
elapsed time including context unwinding, not an expanded allowance.

## The larger environment avoided OOM, not timeout

The unchanged larger-orb workload cap is **42 GiB**, with 50,875,490,304 disk
bytes free at runner preflight. The verifier's peak RSS is **11,858,640 KiB**
(about 11.31 GiB). Native peak RSS is unavailable on the exceptional exit path.
The parent cgroup's lifetime peak is about 30.05 GiB, including page cache and
other workload processes, not isolated native RSS. Cgroup max/oom/oom_kill counters
remained zero. No universal memory bound or full-run performance claim follows.

The pinned Python, approved collector and all old locks remain unchanged. The
new lock SHA256 is `89e10c4cdd3007546960341a3862aa4366423eddaa5e48efabaf612b330105e4`.
Source checking, full observations, every-record verification, evidence writes,
cleanup and process exit remain timed, with the eight-MiB child stack and
four-GiB provisioning floor. No private corpus or evaluator controls were rerun.

No separate Python sampler or heavy local work ran concurrently. Sparse shell
progress reads are disclosed rather than claimed to be observer-free. After
the failed run, the supervisor attempted wrapper restarts; an exclusive start
marker rejected every attempt before another workload could launch. The full
journal is preserved and the service is stopped. Both orbs remain unarchived.

## Exact evidence remains reproducible

The retained gzip has a valid EOF/CRC, no partial tail, and **10,583,340,454
decoded bytes**. Its decoded SHA256 matches the runner's digest. A second bounded
inspection agrees on record count and retains only prefix/suffix samples of
the final two records; neither inspection is a semantic replay.

Read [methods and limitations](evidence/approved-01/METHODS.md),
[actual runner report](evidence/approved-01/report.json),
[postmortem](evidence/approved-01/POSTMORTEM.json), and
[preservation recheck](evidence/approved-01/preservation.json).

The lossless public package contains **47 originals in 59 volumes /
649,919,866 bytes**. Every archive was read back and every restored source hash
matches. Index SHA256:
`0fc12c55f18c3e965e83098e272aa33300ea41d8dee51d7669907bfeeddf98e6`.
Originals remain at `/home/user/rob1333-stage-b-ownership-approved-01`; private
data, installed runtimes and build/cache files are excluded. Restore from
`experiments/13-source-acceptance`:

```sh
python3 stage-b-adaptation-01/package_continuation.py --restore stage-b-ownership-01/evidence/approved-01/public /home/user/NEW-ownership-attempt-restored
```

The restored `command.txt` records the original resource invocation. Reproduce
byte inspection without executing a candidate, using the restored scripts:

```sh
gzip -dc ORIGINAL_ROWS.gz 2> NEW_GZIP_STDERR | python3 RESTORED/inspect_tail.py > NEW_INSPECTION.json
printf '%s\n' "${PIPESTATUS[*]}"
gzip -dc ORIGINAL_ROWS.gz 2> NEW_BOUNDARY_STDERR | python3 RESTORED/inspect_boundary.py > NEW_BOUNDARY.json
printf '%s\n' "${PIPESTATUS[*]}"
```

Both pipelines must report `0 0`. `RESULT.sha256` seals the delivered result and
package without rewriting the proposal's original `PACKAGE.sha256` or freeze.
All prior timeouts and both OOM attempts remain preserved. The next useful
investigation is the remaining full-observation/verification/cleanup path and
its required history serialization, without weakening checks or deadlines.
No additional optimization, resource attempt, acceptance, merge or deployment
is part of this result.
