# Terminal-history profiling: the acceptance pipeline still does substantial work

**Diagnostic measurements only; no candidate execution or resource retry.**
Robert requested profiling after the ownership-approved sum timed out, then
asked why the acceptance limit is 900 seconds. The failed result, all frozen
checks and every deadline remain unchanged. This work neither implements an
optimization nor accepts Stage B. PR #9 remains draft and unready.

## Why the limit is 900 seconds

[Preparation, D162](../STAGE_B_PREPARATION.md#the-new-projections) records the
reason: D151 initially gave each workload 600 seconds; checking/writing the
sum's 18 million steps was projected at roughly 12 minutes, so its approved
budget became 15 minutes while discard stayed at 10 minutes. Those rates were
measured on the checking equipment, **not a Mo interpreter**. The 900-second
value is an experimental acceptance budget, not a language rule or product SLA.
It includes collection, verification, retained evidence, cleanup and exit.

Keeping that frozen budget makes successive attempts comparable. It does not
make 900 a scientifically special number or make a timeout proof of slow Mo
evaluation. Changing the budget or separating evaluation/verification timing
would be an explicit acceptance-contract revision, not an invisible retry fix.
No such revision is made here; all historical failures remain failures.

## The final full record contains history even after all cells are gone

The preserved million-element record is 595,556,697 bytes including newline.
Its inner snapshot is **521,556,278 bytes**, with **3,000,002 events** and
**5,000,004 births** (identity-history entries), but one binding, no control
frames, no graph cells and no cleanup events. It reports `finished`, not a
verified acceptance result.

The exact frozen CPython 3.14.7, JIT disabled, measured these operations once
on those retained bytes, without cProfile instrumentation:

| Operation | Seconds |
| --- | ---: |
| Strict outer JSON decode | 1.910726 |
| Strict inner snapshot decode | 11.235943 |
| Frozen snapshot schema | 0.000042 |
| Canonical hashing of births | 9.478074 |
| Canonical hashing of events | 4.064341 |
| Sum of measured operations | **26.689126** |

These operations omit native execution/serialization, gzip retention, full
verifier state/prediction comparisons, cleanup, normal exit and teardown. The
recomputed history digests cannot be compared to prior incremental state in
this isolated probe; they are measurements, not a verdict. Extraction/source
hashing, report writes and final disposal of the retained decoded trees are
outside these timers.
Peak process RSS was 3,765,532 KiB (about 3.59 GiB), not a new native/run memory
bound. One sample per operation is not a latency distribution.

Do not add these times to the failed run's driver clock: that clock and these
isolated, differently instrumented operations are not aligned measurements.
This does not establish the exact interrupted instruction, how much longer the
full run needed, or the budget needed for a passing attempt.

## Complete bounded replays isolate terminal versus cleanup checking

Three existing native public sum streams at 10,003, 20,003 and 40,003 elements
were replayed completely through the approved ownership verifier. **1,260,234
rows**, every reply digest and all final results match the earlier validated
replays and original summaries. No expectation comes from a new candidate run.
The bounded runs' resource-depth rejection remains expected; these are not
million-element resource acceptance results.

Boundary-only cProfile at 40,003 elements gives:

| Boundary | Outer decode, unprofiled seconds | Checker, profiled seconds | Dominant measured work |
| --- | ---: | ---: | --- |
| Terminal advance | 0.079248 | 1.924497 | History hashing 1.393 cumulative seconds; inner decode 0.415 |
| Destroy | 0.067103 | 0.478173 | Inner decode 0.451 cumulative seconds |
| Destroy again | 0.059485 | 0.532061 | Inner decode 0.504 cumulative seconds |

The full records are 23,078,390 / 23,078,314 / 23,078,289 bytes respectively:
destroy and repeated destroy still transport nearly the same history. The
semantic cleanup predicate itself is negligible at this finished, empty-graph
boundary. This does not generalize to destruction of a live million-cell list;
the full discard workload remains unrun.

cProfile changes execution cost; use its call attribution, not these timings
as acceptance measurements or direct comparisons to the unprofiled million
probe. Raw profile files and complete reports are retained. Recorded native
clock deltas come from the old streams and include backpressure and collection;
they do not isolate native serialization CPU time.

## Source explains the repeated history cost

The collector's `Collector::boundary` always requests a full observation at
advance, destroy and destroy-again. The adaptation candidate's
`Machine::snapshot` serializes the complete `events`, `births` and cleanup
history. `Machine::destroy` returns early on the second call, but the collector
still requests and emits another full snapshot. The ownership verifier's
`phase_advance` decodes, validates and hashes the histories; `_destroy` decodes
the whole snapshot again, though it does not repeat the history digest checks.

Owners are `stage-b-collector-01/driver/lib.rs`,
`stage-b-adaptation-01/candidate/execution.rs`,
`stage-b-ownership-01/stage_b_large.py`, `integration.py` and
`stage-b-performance-01/fast_json.py`. None was edited. This source inspection
identifies operations, not a native profiler sample of the failed full run.

## Reproduce without rerunning the candidate

`profile_terminal.py` verifies the ownership freeze transitively before and
after execution, including Python and both native binary identities. It also
checks bounded input hashes against the existing collector package index and
the million input against its committed postmortem. Temporary extracted bytes
are automatically removed and not republished as new evidence.

From the repository root, run sequentially with no competing heavy work:

```sh
PY=/home/user/.local/share/uv/python/cpython-3.14.7-linux-x86_64-gnu/bin/python3.14
$PY experiments/13-source-acceptance/stage-b-terminal-profile-01/profile_terminal.py bounded /home/user/RESTORED-COLLECTOR/rob1333-stage-b-collector-01 /home/user/NEW-bounded
$PY experiments/13-source-acceptance/stage-b-terminal-profile-01/profile_terminal.py terminal /home/user/RESTORED-ATTEMPT/rob1333-stage-b-ownership-approved-01 /home/user/NEW-terminal
```

Restore inputs using the commands in the collector and ownership result reports.
The terminal probe hashes the entire decoded stream and extracts its final
595,556,697 bytes at offset 9,987,783,757. Extraction has bounded buffers; the
measured standard decoder deliberately materializes the final observation,
as the unchanged checker does. No private files are accessed. Full resource
execution, prior incremental verification state and native cleanup are absent.

The new public evidence archive contains scripts, logs, raw profiles and results,
with complete readback and restored-file hash verification. Original large
inputs stay in their prior archives. See `evidence/package.log` and
`evidence/public/INDEX.json` for exact package counts and identities.

## Recommendation

Before spending more effort making the complete testing pipeline fit exactly
15 minutes, decide whether that total-pipeline deadline is the requirement you
want. If it is, measured targets are strict decoding/canonical history hashing
and repeated native history serialization; any replacement must preserve all
validation semantics and be separately reviewed before adoption. If the goal
is interpreter behavior/performance, a versioned contract can report evaluator,
collector and verifier costs separately while retaining every correctness
check and an explicit overall run guard. Measurements here do not specify a
defensible replacement deadline. No contract, code path or acceptance result
has been changed by this recommendation.
