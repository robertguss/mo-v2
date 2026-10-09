# Stage B passes the approved, amended acceptance contract

The source-driven interpreter supports the approved functions/recursion stage.
Final source and evidence review found no material acceptance blocker. This is
finite experimental acceptance, not universal Rust safety, arbitrary-program
correctness, a four-GiB memory bound or a production performance promise.

This additive closeout supersedes preparation, pending-review and failed-resource
status in the historical reports below. Their exact bytes, locks and failures
remain unchanged. Acceptance uses the explicitly approved **1,800-second sum /
600-second discard amendment**, not a retroactive pass under 900 seconds.

## The applicable gates have evidence

| Gate | Reviewed result and source |
| --- | --- |
| Source-driven functions, recursion and resumable execution | [Adapted candidate](stage-b-adaptation-01/candidate/): original source passes the real frontend/checker into the stateful machine; explicit frames implement calls, resumes and iterative cleanup. No production fixture/reference dispatch or fake cell backend found. |
| Public native regression | [Collector report](stage-b-collector-01/evidence/public.json): 21 full public examples, 1,624 resumes, 1,624 destruction runs, 42 denials, 4,276 historical cases and four real summary runs; 7,591 runs pass. |
| Private execution | [Aggregate only](stage-b-adaptation-01/evidence/continuation/private-aggregate.json): all 524 cases, 35,030 resumes and 35,030 destruction runs pass; zero failed/unrun cases. Sources, seeds and raw private evidence remain outside this repository and were not retrieved or rerun for closeout. |
| Applicable compiled defect controls | [Completed predicate/source review](stage-b-adaptation-01/evidence/continuation/control-review.json): nine active classes, ten passing-baseline/rejected-mutant pairs. Two fixture-provenance routes account for the extra pair. Intended first failures, not unrelated later panics, establish rejection. The separate entry-allocation control remains inapplicable under D164. |
| Deferred diagnostic refusals | [Continuation report](stage-b-adaptation-01/evidence/continuation/controls-and-refusals.json): all sixteen pass. Its pending-review field describes the earlier checkpoint; the separate completed control review resolves it. |
| Million-element non-tail sum | [Timed result](stage-b-timing-01/RESULT.md): **995.820047738 seconds**, answer `1000000`, 18,000,014 transitions, 1,000,001 explicit frames; passes the approved 1,800-second guard. |
| Million-element discarded list | Same result: **82.833321094 seconds**, answer `0`, 2,000,003 transitions, a 1,000,000-cell cleanup chain; passes the unchanged 600-second guard. Started only after sum passed. |
| Full observation and cleanup | Both resource runs verify deepest full observation, resumed completion, both destruction calls, drop, teardown and native exit zero. Evaluation cell counts `[0, 0, 1000000]`; zero remaining owned cells; eight-MiB child stack. Final evidence closure and verifier cleanup remain timed. |
| Preserved results | [Methods](stage-b-timing-01/evidence/result/METHODS.md): 20,000,037 complete rows reconcile with decoded hashes and valid gzip EOF/CRC. All 42 result originals are losslessly packaged in 75 volumes / 778,153,600 bytes, with full readback and restored-file hashing. All 83 result-seal entries pass. |

## The version changes are explicit, not hidden repairs

The accepted candidate is the seven-file observation adaptation, not the earlier
final-03 baseline. [Revision-02's lock](stage-b-revision-02/LOCK.json) supersedes
its prepared/unfrozen README wording. The adapted candidate's
[continuation record](stage-b-adaptation-01/README.md) identifies its manifest
and runtime. Historical `candidate_byte_identical` fields can refer to the
preserved baseline; they do not assert that the adaptation never happened.

Subsequent changes were separately proposed, validated, approved and frozen:

- [Performance](stage-b-performance-01/README.md): release build and strict JSON
  verification work; no candidate change.
- [Collector](stage-b-collector-01/FREEZE.md): recursive JSON validation without
  retained decoded trees, byte-equality fast path with parsed equality fallback,
  and moved output values. 1,260,234 normalized native rows match; 2,548 synthetic
  protocol probes match. Synthetic probes are not evaluator sabotage controls.
- [Ownership lookup](stage-b-ownership-01/FREEZE.md): retain duplicate rejection,
  then use set membership for schema-validated integer reservations. Seven
  retained streams / 1,360,421 rows and 2,298 predicate comparisons match; other
  checks remain unchanged. This changes temporary-memory constants.
- [Timing](stage-b-timing-01/FREEZE.md): nested exclusive wall attribution plus
  the owner-approved operational guard. Six native pairs / 1,281,570 normalized
  rows match; 31 envelope assertions, 15 harness probes and five Rust tests pass.
  All non-time resource obligations remain. The freeze was pushed before the
  single full attempt; no repair, extension or retry followed.

Debug private/control execution, release collector validation and the final
instrumented resource execution use different, recorded executables. Continuity
rests on the unchanged adapted candidate, explicit versioned hosts/checkers and
their differential evidence, not on claiming one binary ran every campaign.

The larger orb was separately authorized and recorded before execution: a
42-GiB workload cap and 64-GiB filesystem, versus the earlier 13.75-GiB cap.
The old OOMs and 900-second timeouts remain failures. In the second OOM an external
Python sampler invoked the allocation that triggered the kernel kill; this
observer effect does not establish the exact failure point of an unmonitored
run. [Preserved postmortems](stage-b-resource-continuation-01/README.md) distinguish
retention from verification and incomplete progress from passing results.

## Review scope and limits

The final source review inspected frontend routing, saved execution frames,
left-to-right argument evaluation, staged allocation gates, actual runtime/cell
linkage and iterative/idempotent cleanup. Timing scopes only update their ledger;
the cleanup wrapper preserves ordinary candidate drops. Test-only `NoCells` is
not a production backend. The review found no production candidate unsafe code,
known-case dispatch or reference-prediction substitution. Source syntax parsing
can recurse; million-depth evaluation and cleanup use explicit state.

Two read-only, tool-assisted reviewers examined source and primary evidence;
the integrating agent checked their findings, reports and identities. This is
same-account review, **not independent scientific authorship**. D170 explicitly
dropped the Stage B builder/acceptance split. It does not inherit Stage A's
separate-author claim or prove universal equivalence of checker optimizations.

The final run had no OOM at 42 GiB. Native peak RSS was 7.76 / 1.64 GiB;
Python's 11.31-GiB lifetime peak is not a discard-only measurement. The four-GiB
provisioning floor is not a consumption cap. Instrumented native evaluation
scopes took 151.630702 / 5.051399 seconds; serialization/transport, including
blocked writes, took 732.507400 / 60.845473 seconds. Native and parent intervals
overlap and must not be added. These are single instrumented wall measurements,
not pure evaluator CPU, an uninstrumented benchmark or a latency distribution.

## Integration checkpoint

Robert authorized final acceptance review, updating PR #9 and merging only ready
work in the [continuation thread](https://ampcode.com/threads/T-01a120a8-5f89-72d7-a894-b48b82ed155c).
A fresh Rust 1.98.1 locked/offline release build matches the frozen timing binary
exactly: `5306bd3de522461be0e4789ba374ccc96c97cbdca7a22fa67dc69b12a0fee7b0`.
All five collector/protocol/timing tests pass. Transitive freeze verification
and the 83-entry result seal pass. CI now also builds/tests this final host,
beside the preserved baseline and observation adaptation.

This document is prepared before merge: exact-head hosted Rust/Lean checks and
PR integration remain delivery gates, not additional scientific experiments.
The [PR #9 timeline](https://github.com/robertguss/mo-v2/pull/9) records the actual
merge/check status; ROB-1333 is marked Done only after integration succeeds.
No private or million-element acceptance replay is needed for this closeout.
No release/deployment is included. Both retained orbs remain unarchived.
