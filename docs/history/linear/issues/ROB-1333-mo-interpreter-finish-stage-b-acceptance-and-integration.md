# ROB-1333: Mo interpreter: finish Stage B acceptance and integration

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration
> Status at export: Done
> Created: 2026-10-07
> Updated: 2026-10-09
> Completed: 2026-10-09
> Comments: 64

---

## Description

## Current checkpoint — 9 October 2026: Stage B accepted, merged and complete

[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) **is Done.** Final source/evidence review found no material acceptance blocker. [robertguss/mo-v2#9](https://linear.app/robert-guss/review/accept-stage-b-interpreter-with-reviewed-resource-evidence-a4880103487e) merged into main at [a4056b8](<https://github.com/robertguss/mo-v2/commit/a4056b8341122622106fe60f834dbf8e2428295f>). The remote main tip was read back and its entire tree matches the reviewed closeout. There are no open PRs at closeout. This completes the Stage A+B interpreter milestone, not the entire Mo roadmap. [Final acceptance matrix, provenance and limits](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/STAGE_B_RESULT.md>).

**Acceptance:** the million-element sum passed in 995.820047738 seconds under the explicitly owner-approved 1,800-second guard, followed by discard in 82.833321094 seconds under 600 seconds. Both include full deepest observation, resumed completion, two destroys, drop/teardown and native exit zero, with zero owned cells remaining and an eight-MiB child stack. Final review reconciled the prior 7,591 native public runs, 524 private cases with 35,030 resumes and 35,030 destructions, nine active compiled control classes / ten intended rejections, and sixteen diagnostic refusals. No private or million-element rerun was needed for closeout.

**Integration:** fresh release build exactly matches the frozen executable; five collector/timing tests, transitive freeze checks and all 83 result-seal entries pass. Full local Rust and Lean suites exit zero. Hosted exact-head [acceptance build 49](<https://buildkite.com/robert-guss/mo-v2/builds/49>), [PR build 50](<https://buildkite.com/robert-guss/mo-v2/builds/50>), and post-merge [main build 51](<https://buildkite.com/robert-guss/mo-v2/builds/51>) passed Rust/frozen corpora and Lean/kernel checks. Socket checks passed too. CI now includes the final collector but does not replace scientific acceptance.

**Limits and preservation:** this is finite acceptance under the amended contract, not a retroactive 900-second pass, universal safety/performance proof or four-GiB memory bound. Final review is same-account tool-assisted review, not independent scientific authorship. Native and parent timing intervals overlap and must not be added. Historical OOMs/timeouts, approval records, frozen code and complete public evidence remain unchanged; the final 20,000,037 records and lossless archive restoration were verified. No release/deployment. Both orbs remain unarchived and no workload service is running. Earlier checkpoints are historical below.

## Historical checkpoint — 9 October 2026: both resource obligations passed; final acceptance/integration review remains

**The approved full resource attempt passed both workloads.** Sum completed in 995.820047738 seconds under the owner-approved 1,800-second guard; only that completed pass allowed discard, which completed in 82.833321094 seconds under its unchanged 600-second guard. Both verified deepest full observation, resumed completion, both destruction calls, drop/teardown, normal native exit and final resource predicates. Answers are 1000000 / 0; evaluation cell counts are \[0,0,1000000\], remaining owned cells zero. Sum reached 1,000,001 explicit frames; discard reached a 1,000,000-cell cleanup chain. Child stack stayed eight MiB. The outer runner exited 0; service stopped; no repair or workload retry occurred.

**Timing attribution:** instrumented native evaluation scopes took 151.630702 / 5.051399 seconds, while native serialization/transport took 732.507400 / 60.845473 seconds including blocked writes. Parent predicates took 736.799036 / 48.440326 seconds and JSON decode 147.438894 / 16.697183 seconds. These concurrent process wall totals must not be added. Evaluation includes candidate metadata, instrumentation and descheduling; it is not pure evaluator CPU or an uninstrumented speed bound. Both ledgers reconcile exactly and required finalization remains watchdog-covered.

**Memory and integrity:** unchanged 42-GiB workload cap; no OOM events. Native peak RSS: 7.76 GiB sum / 1.64 GiB discard. Python lifetime peak: 11.31 GiB, inherited by the discard report, not discard-only. Cgroup lifetime peak about 34.08 GiB includes cache/prior work. Bounded independent inspection matches both decoded hashes and all 20,000,037 complete records, valid gzip endings and no partial tails. All frozen candidate/runtime/checker identities and old binaries remain unchanged. Historical 900-second failures and OOMs are preserved, not reclassified under the new contract.

**Delivered:** [f80f0a3](<https://github.com/robertguss/mo-v2/commit/f80f0a322402731369825187913c4af01a0220da>) committed, pushed and remote-verified on the acceptance branch only. [Readable result, timing tables and reproduction](<https://github.com/robertguss/mo-v2/blob/f80f0a322402731369825187913c4af01a0220da/experiments/13-source-acceptance/stage-b-timing-01/RESULT.md>). All 42 result originals are preserved in 75 volumes / 778,153,600 bytes with complete archive readback and restored-file hashing; all 83 result-seal entries pass. The pre-run freeze was pushed before execution and Buildkite 47 passed. [Buildkite 48](<https://buildkite.com/robert-guss/mo-v2/builds/48>) passed Rust/frozen corpora and Lean/kernel checks, both exit 0, on the exact delivered head. It supplements, not substitutes for, the resource acceptance evidence.

**Remaining gate:** final Stage B acceptance/integration review and reconciliation of draft PR #9 with this acceptance branch. PR #9 is still at its older implementation head; neither it nor main changed. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) remains Building, not Done. No private corpus rerun, new evaluator controls, merge or deployment. Both orbs remain unarchived. Supervisor restart attempts after successful exit were blocked by the exclusive marker before any workload could execute again. Earlier checkpoints remain historical below.

## Historical checkpoint — 9 October 2026: approved timing freeze; full resource attempt running

Robert explicitly approved 1,800 seconds for sum, then the unchanged 600 seconds for discard only if sum passes, with implementation, bounded validation and freeze before full execution. The [exact timing freeze](<https://github.com/robertguss/mo-v2/blob/f1e5f58e0a6809be7ba7fb94e0c2ee7be5f93656/experiments/13-source-acceptance/stage-b-timing-01/FREEZE.md>) is committed, pushed and remotely verified at [f1e5f58](<https://github.com/robertguss/mo-v2/commit/f1e5f58e0a6809be7ba7fb94e0c2ee7be5f93656>) before launch. Previous freezes/failures remain unchanged; the proposal's pending status is historical.

Six baseline/instrumented public pairs match 1,281,570 normalized rows, independently checked by the unchanged approved verifier. Thirty-one envelope assertions, fifteen timing/watchdog probes and five Rust tests pass. Deliberately delayed source/commit verification appears in approval wait/transport rather than evaluation; both remain within the inclusive watchdog. At 40,003 sum elements the paired complete pipelines took 30.343345/31.916178 seconds (about 5.2% slower with instrumentation/runner changes), not a full-size prediction. All 129 public validation originals are preserved in twelve volumes / 102,743,383 bytes with full archive readback/restore hashing.

Candidate, runtime, strict decoder, ownership/history/source checks, full observations and all physical obligations remain unchanged. The new collector reports exclusive nested wall categories; native and parent totals overlap and are never added. Elapsed values are not clamped. Required verifier-state release, native exit and evidence finalization remain timed. Limits are operational cutoffs, not evaluator speed targets.

**Execution now running:** fresh external attempt, unchanged 42-GiB workload cap and 64-GiB filesystem; sum first, discard only if sum passes. Exclusive launch marker prevents supervisor retries. No separate sampler, concurrent builds or packaging. Stop at the first material failure without repair/retry. This checkpoint is not a result or Stage B acceptance. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) remains Building; PR #9 remains draft/unready. No private/control runs, PR-branch/main updates, merge or deployment. Both orbs stay unarchived.

## Historical checkpoint — 9 October 2026: timing separation agreed; numerical guards pending

Robert agreed to separate interpreter performance from verification overhead while retaining every correctness check and an explicit overall guard. The versioned [timing amendment proposal](<https://github.com/robertguss/mo-v2/blob/c38f48f4c0b6205cb464a9709433f6444798a466/experiments/13-source-acceptance/stage-b-timing-01/PROPOSAL.md>) is committed, pushed and remote-verified on the acceptance branch only at [c38f48f](<https://github.com/robertguss/mo-v2/commit/c38f48f4c0b6205cb464a9709433f6444798a466>). This is documentation, not an implemented or frozen amendment.

**Remaining owner decision:** proposed inclusive operational guards of 1,800 seconds for sum and 600 seconds for discard. These are budget choices, not measured performance bounds or promises of completion. No numerical replacement guard has been approved. The active frozen contract remains 900/600 seconds; the prior 900.516854128-second failure remains a failure and discard remains unrun.

The proposed accounting separates native evaluation from observation generation, collector work and blocked transport, and separately records Python verification/evidence cost. Nested callbacks must not be double-counted; concurrent native/parent wall totals must not be added. Candidate/runtime code, semantic observations, every-record/source/ownership/history checks, physical obligations and inclusive cleanup/exit remain required. No evaluator speed threshold is invented. After guard approval, instrument and validate bounded native runs, review/freeze exact identities, then run sum and only if passing run discard. Stop at the first material failure without silent repair/retry.

**Verification and delivery:** frozen ownership/transitive locks and pinned executable identities pass preservation checks; proposal links and whitespace checks pass. [Buildkite 46](<https://buildkite.com/robert-guss/mo-v2/builds/46>) passed Rust/frozen corpora and Lean/kernel checks, both exit 0, on the exact documentation head. No instrumentation, resource retry, optimization, private/control run, PR-branch update, merge or deployment occurred. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) remains Building; the only open PR, #9, remains draft/unready despite green checks and no conflicts. Both orbs remain unarchived. Prior checkpoints follow as history.

## Historical checkpoint — 9 October 2026: terminal-history profiling complete; resource gate unchanged

[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) **remains Building; Stage B is not accepted.** Robert requested profiling, then asked why the limit is 900 seconds. No candidate, private/control workload or resource retry ran. The previous 900.516854128-second failure remains; discard is still unrun and PR #9 is draft/unready.

**Measured:** the preserved million-element final record contains a 521,556,278-byte inner snapshot, 5,000,004 identity-history entries and 3,000,002 events, despite an empty graph. Isolated strict outer decode took 1.910726 seconds, inner decode 11.235943, schema 0.000042, canonical births hashing 9.478074 and events hashing 4.064341: 26.689126 seconds for these operations alone. These single-sample measurements omit native serialization, evidence writes, full verifier state checks, cleanup and exit; they are not a verdict or a measurement of how much longer the failed full run needed.

Three complete retained native sum replays (10,003/20,003/40,003 elements; 1,260,234 rows) match every prior reply digest and final result. At 40,003 elements, terminal checking spends 1.393 profiled seconds hashing histories; destroy and destroy-again spend about 94–95% of their profiled checker time decoding snapshots. Source inspection confirms full cumulative history is serialized at all three boundaries. This finished-empty-graph finding does not establish the cost of destroying a live million-cell list.

**Why 900:** STAGE_B_PREPARATION.md records D151's initial 600 seconds and D162's extension of sum to 900 because preparation projected about 12 minutes. Those rates measured checking equipment, not a native Mo interpreter. It is a bounded acceptance budget, not a language rule or product SLA. Recommendation: decide whether total-pipeline timing is the intended requirement; otherwise explicitly version separate evaluator/collector/verifier accounting while preserving every correctness check and a run guard. No budget or contract was revised here, and no replacement deadline is established by these measurements.

**Delivered:** [63f0f81](<https://github.com/robertguss/mo-v2/commit/63f0f812fe50430e9ab1487ca86307f06a987f02>) pushed and remotely verified on acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration)-stage-b-resolution only. [Methods and reproduction](<https://github.com/robertguss/mo-v2/blob/63f0f812fe50430e9ab1487ca86307f06a987f02/experiments/13-source-acceptance/stage-b-terminal-profile-01/README.md>). Thirty-six diagnostic originals are archived in one 59,396-byte volume with full readback/restore verification. Exact Python, candidate, collector, ownership freeze and every prior lock remain unchanged. [Buildkite 45](<https://buildkite.com/robert-guss/mo-v2/builds/45>) passed Rust/Lean on this exact head; CI is not resource acceptance. No optimization was adopted, PR branch/main changed, merge or deployment performed. Both orbs remain retained. All earlier decisions, failed attempts and adoption records follow unchanged as history.

## Historical checkpoint — 9 October 2026: ownership-approved sum reaches Finish but still times out

[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) **remains Building, not accepted or Done.** Robert approved the exact ownership replacement; its [freeze](<https://github.com/robertguss/mo-v2/commit/d24a106a753be3a03558b674995eb10e7c210eae>) was committed/pushed before execution. The million-element sum failed the unchanged inclusive watchdog at **900.516854128 seconds**. Execution stopped at this first material failure; **discard did not run**, and no repair or retry followed.

**Observed progress, not a pass:** the stream reached the 18,000,014-step Finish commit and retained a final 595,556,696-byte full advance record reporting finished / Int / 1000000. The sequential checker returned from preceding rows, but retention and phase counters precede completed checks on their own row. Completed final-observation verification, destruction, teardown, normal native exit and passing final verifier verdict are not all established. No destruction/teardown rows were retained. The final driver clock (881,225,491,814 ns) is not a passing inclusive runtime; no instruction sample identifies the interrupted statement.

**Environment and preservation:** unchanged 42-GiB workload cap, 50,875,490,304 disk bytes free at runner preflight; no cgroup OOM events. Verifier peak RSS 11,858,640 KiB; native peak unavailable on the exceptional exit path. Parent cgroup lifetime peak about 30.05 GiB includes cache/other workloads and is not isolated native RSS. Candidate, collector, exact Python and all prior locks remain unchanged. No private corpus or evaluator controls were rerun. The two depth-64 semantic smokes passed while correctly rejecting the full-depth resource predicate. Supervisor restart attempts were blocked by the exclusive start marker before any new workload; the service is stopped.

**Delivered:** [c8ac979](<https://github.com/robertguss/mo-v2/commit/c8ac979c709f37c3df74acc1b6d2e8194c88463b>) is pushed and remotely verified on acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration)-stage-b-resolution only. [Readable result/methods](<https://github.com/robertguss/mo-v2/blob/c8ac979c709f37c3df74acc1b6d2e8194c88463b/experiments/13-source-acceptance/stage-b-ownership-01/RESULT.md>). Independent bounded inspection confirms valid gzip, 10,583,340,454 decoded bytes, 18,000,020 complete records, no partial tail and exact runner-digest agreement. Forty-seven originals are preserved in 59 volumes / 649,919,866 bytes; full archive readback and restored-file hashing pass. Result seal: 75 entries pass; original proposal seal: 14 entries pass. All earlier timeout/OOM records remain intact.

**Delivery CI:** [Buildkite 44](<https://buildkite.com/robert-guss/mo-v2/builds/44>) passed on this exact pushed head: Rust builds/frozen corpora and Lean proofs/kernel re-check, both exit 0. CI does not satisfy the resource gate. [robertguss/mo-v2#9](https://linear.app/robert-guss/review/stage-b-interpreter-resource-acceptance-still-blocked-a4880103487e) remains the only open PR, OPEN DRAFT and not ready to merge; its implementation branch and main are unchanged. No merge/deployment occurred. Both orbs are retained unarchived; [active continuation](<https://ampcode.com/threads/T-01a120a8-5f89-72d7-a894-b48b82ed155c>).

**Recommended next investigation:** profile the remaining full-observation/verification/cleanup path and its required serialized history without skipping checks or loosening deadlines. This result does not implement another optimization or authorize an automatic retry. Passing sum and discard plus final acceptance/merge review remain outstanding.

## Historical checkpoint — 9 October 2026: ownership replacement approval and pre-run freeze

Robert replied “yes” to adopting this exact ownership-check replacement and running the million-element sum under the unchanged inclusive 900 seconds, then discard under 600 seconds only if sum passes. The [freeze](<https://github.com/robertguss/mo-v2/commit/d24a106a753be3a03558b674995eb10e7c210eae>) is committed, pushed and remote-verified before full execution. It pins 17 files and all prior locks transitively. Two depth-64 semantic smokes complete and correctly fail the unchanged full-depth resource predicate; these are not resource acceptance. The 42-GiB larger-orb environment and all scientific checks are retained; stop at the first material failure without silent repair/retry. Full execution is next at this checkpoint; the prior failures remain valid historical results. PR #9 remains draft/unready. No merge or deployment. [Active thread](<https://ampcode.com/threads/T-01a120a8-5f89-72d7-a894-b48b82ed155c>).

## Historical checkpoint — 9 October 2026: ownership-check proposal before adoption approval

**Stage B is still not accepted.** After Robert requested the recommended next work, the larger-orb timeout investigation demonstrated quadratic reservation-list lookup in the frozen ownership predicate. At the deepest million-cell sum state, the original code visits 500,000,500,000 successful search positions. Bounded profiling supports this bottleneck; no instruction-level sample proves the exact interrupted location of the earlier timeout.

**Separate proposal, not adopted:** keep duplicate-reservation rejection, then convert the reservation list to a set. For schema-validated natural integer IDs this preserves membership semantics. All other predicate logic, decoding, full observations and limits remain unchanged. Candidate, collector and all existing frozen files remain byte-identical. The temporary-memory constants change; no universal collision, memory or full-run timing bound is claimed.

**Validation:** seven complete retained native public streams / 1,360,421 rows match the frozen verifier and original summaries; 2,298 valid/malformed predicate comparisons match. At 40,003 cells, isolated ownership-check medians are 5.320152 versus 0.012559 seconds; complete replay is 33.668934 versus 28.422321 seconds (15.6% faster). These are diagnostic replays, not resource acceptance. No new native candidate execution, private corpus access, evaluator control or million-element retry occurred. Fifteen original evidence files are preserved in one 89,751-byte archive, with complete readback/restore/hash verification.

**Delivered:** [faee45c](<https://github.com/robertguss/mo-v2/commit/faee45c6055aad2a180f0545dd117ea08e649bed>) is pushed and remotely verified on acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration)-stage-b-resolution only. [Proposal, evidence and reproduction](<https://github.com/robertguss/mo-v2/blob/faee45c6055aad2a180f0545dd117ea08e649bed/experiments/13-source-acceptance/stage-b-ownership-01/README.md>). [Buildkite 42](<https://buildkite.com/robert-guss/mo-v2/builds/42>) passed Rust and Lean, both exit 0. This CI does not satisfy resource acceptance.

**Next gate:** Robert must approve this exact checker substitution before a new explicit-selection freeze and acceptance run. Proposed execution retains the 42-GiB larger orb, inclusive sum limit 900 seconds, then discard 600 seconds only if sum passes; stop at the first material failure. The earlier 900.001081354-second timeout and both OOM attempts remain preserved, and discard remains unrun. [robertguss/mo-v2#9](https://linear.app/robert-guss/review/stage-b-interpreter-resource-acceptance-still-blocked-a4880103487e) is still the only open PR, OPEN DRAFT, and not ready to merge despite green checks/no conflicts. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) remains Building; no merge/deployment or PR-branch update occurred. Both orbs remain unarchived. [Active continuation thread](<https://ampcode.com/threads/T-01a120a8-5f89-72d7-a894-b48b82ed155c>).

## Historical checkpoint — 9 October 2026: larger-orb resource timeout

**Delivery CI:** [Buildkite 41](<https://buildkite.com/robert-guss/mo-v2/builds/41>) passed on the exact pushed head 2dd464d (Rust builds/frozen corpora and Lean proofs/kernel re-check, both exit 0). This development CI does not satisfy either outstanding resource obligation or make PR #9 ready to merge.

[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) **remains Building, not accepted or Done.** The million-element non-tail sum failed the unchanged inclusive watchdog at **900.001081354 seconds** in the owner-authorized larger orb. The runner reported step counter **12,000,005** of 18,000,014 transitions and 12,000,010 phase entries. Those counters advance before all predicates finish; completed deepest-observation verification, completion and cleanup are not established. **Discard was not run.** Execution stopped at the first material failure, without repair or retry.

**Actual environment:** a1.3xlarge; workload cgroup **42 GiB** versus the earlier 13.75 GiB; about 43 GiB physical RAM; 64-GiB filesystem with 52,826,554,368 bytes free at runner preflight. Cgroup max/oom/oom_kill counters stayed zero. Verifier peak RSS was 11,873,660 KiB (11.32 GiB). The parent cgroup lifetime peak, including cache/other processes, was 27.91 GiB, not isolated native RSS. This run did not reproduce the OOM, but failed timing. No universal memory or scaling bound follows.

**Preserved second OOM:** after the approved collector optimization, the old orb's verifier was killed at 2026-10-09T12:23:46.802 UTC, exit 137, under 13.75 GiB. An external Python sampler invoked the OOM allocation; the kernel selected the verifier and killed its scope. This observer effect does not prove an unmonitored run would fail at precisely the same point. Independent bounded inspection agrees on 7,114,414,775 recovered bytes and 12,000,009 complete records, with 978,398,346 trailing partial-record bytes and no gzip EOF. Retention is not verification; no completed verdict or discard execution was established. The first OOM and initial debug-build timeout remain preserved too.

**Delivery:** [2dd464d](<https://github.com/robertguss/mo-v2/commit/2dd464d88959779d8bab33af491ac24a436748f1>) is pushed and remotely verified on acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration)-stage-b-resolution only. [Readable results, methods and reproduction](<https://github.com/robertguss/mo-v2/blob/2dd464d88959779d8bab33af491ac24a436748f1/experiments/13-source-acceptance/stage-b-resource-continuation-01/README.md>). Second-OOM package: 27 files/40 volumes/448,249,725 bytes. Larger-orb package: 22 files/40 volumes/447,286,604 bytes. All archives read back and every restored source hash matches. The larger run's closed gzip independently matches the runner's full decoded digest. PRE_RUN checks pass 51 entries; final PACKAGE checks pass 108. All original/revision-02/performance/collector identities and candidate bytes remain unchanged.

**Authorization and limits:** Robert requested the largest orb and continued work. That environment change was separately recorded and committed before execution; the old freeze was not rewritten. Exact transferred Python and both native binaries were hash-verified, without rebuilding. No private corpus/evidence was transferred or rerun; no evaluator controls or candidate/checker changes were introduced. Stage A remains merged and prior bounded/private/control results remain historical evidence, not a replacement for failed resource acceptance. Both orbs are retained unarchived. [Continuation thread](<https://ampcode.com/threads/T-01a120a8-5f89-72d7-a894-b48b82ed155c>).

**Remaining gates:** investigate the resource bottleneck without weakening frozen checks; obtain passing sum and discard results; then finish acceptance/merge review. [robertguss/mo-v2#9](https://linear.app/robert-guss/review/stage-b-interpreter-resource-acceptance-still-blocked-a4880103487e) remains OPEN DRAFT on implementation/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration)-stage-b at [d63c58b](<https://github.com/robertguss/mo-v2/commit/d63c58bcefd12f4dd589ee556b7df99b2d4959e6>). No merge or deployment occurred. Earlier checkpoint text below is historical, not a current execution instruction.

## Historical checkpoint — Stage A merged; Stage B acceptance in progress

8 October 2026. **Building: blocked on native linked memory growth, not Done.** Stage A is accepted and merged. Stage B functions/recursion are implemented, but complete Stage B acceptance and integration remain unfinished. The prior Done label followed package merges, not acceptance of the interpreter.

**Performance investigation — adoption approved:** [b8a6144](<https://github.com/robertguss/mo-v2/commit/b8a61443486db57c25551b24608acd20ab0e1acf>) is pushed and remote-verified on both the acceptance-resolution branch and PR #9. At 360,068 transitions, a release native run takes 27.193 seconds; the frozen verifier alone takes 25.473–26.506 seconds. Buffered record framing is validated. A separately versioned JSON-helper proposal reduces replay to 16.745 seconds (34–37%), matching 895 retained native streams and 15 first-rejection probes. Release tests pass: 54 candidate and three collector. Candidate source and all frozen files remain unchanged. This is finite comparison evidence, not a full-depth result or general equivalence proof.

**Current CI:** [Buildkite 39](<https://buildkite.com/robert-guss/mo-v2/builds/39>) passed on the exact pushed freeze/OOM-evidence head. Development CI does not satisfy the failed resource gate or make PR #9 ready to merge.

**Current result — OOM, not accepted:** Robert approved the performance freeze and both resource checks. The new million-element sum was killed by the kernel at the 13.75-GiB workload cgroup limit (exit 137), with native linked anonymous RSS about 12.16 GiB and Python about 1.32 GiB. Native RSS combines candidate, collector and runtime; its allocation source is not isolated. Last complete retained step: 11,997,679, below the required deepest pause 12,000,005. No completed verdict, deepest full observation, completion or cleanup is established. Discard was not run; no candidate repair, limit increase or retry followed. The unfinished log and separate postmortem are preserved, and all original/revision-02/performance fingerprints remain unchanged. [Freeze and OOM evidence, d63c58b](<https://github.com/robertguss/mo-v2/commit/d63c58bcefd12f4dd589ee556b7df99b2d4959e6>) is pushed and remote-verified on both branches. Its 27 original public files are preserved in 35 volumes / 420,173,743 bytes, with full restore/hash verification. PR #9 stays draft. Next investigation: native linked memory growth near maximum depth; snapshot construction is a hypothesis, not a confirmed cause. The proposal's 66 public evidence files are preserved in five volumes / 32,269,096 bytes with full restore/hash verification. [Readable proposal and reproduction](<https://github.com/robertguss/mo-v2/blob/b8a61443486db57c25551b24608acd20ab0e1acf/experiments/13-source-acceptance/stage-b-performance-01/README.md>).

**Current candidate:** [observation adaptation 01, f576abe](<https://github.com/robertguss/mo-v2/commit/f576abeb22a98cc44ae78d0e89dca74ab1d33957>), built against [frozen acceptance revision 02, a72083d](<https://github.com/robertguss/mo-v2/commit/a72083d8104d1ee5fe0a5081fca11c2f55a49add>). Branch acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-stage-b-resolution is pushed, not merged. Original candidate, locks and failed results are preserved.

**Passed for this revision:** 54 development tests, three collector tests, 21 public examples, 4,276 historical inputs, 1,624 resume runs, 1,624 destruction runs, 42 begin-allocation-denial checks, 891 small native destruction checks, and four real evaluator runs checking nine periodic summaries. [Exact result and limits](<https://github.com/robertguss/mo-v2/blob/f576abeb22a98cc44ae78d0e89dca74ab1d33957/experiments/13-source-acceptance/stage-b-adaptation-01/README.md>). Same-author implementation verification using already frozen checks; no universal Rust safety or scaling proof.

**Continuation verified:** the adapted candidate passed all 524 private cases (24 reserved, 500 generated), 35,030 resume runs and 35,030 destruction runs in 1,544.240 seconds. All nine applicable deliberate-bug control classes were caught in ten passing-baseline/rejected-mutant pairs, with the first failures replayed for intended-predicate evidence; all 16 deferred diagnostic refusals passed. Private contents and raw rows remain outside the public repository. Original locks and candidate are unchanged.

**Earlier blocker, preserved:** the initial million-element recursive sum failed the unchanged 900-second inclusive watchdog at 900.000636 seconds. The verifier reached approximately 6.65 million of 18 million transitions, before the required deepest pause; no earlier semantic rejection was recorded. Execution stopped at this first material discrepancy, leaving the million-element discard unrun. This end-to-end debug-build run does not isolate interpreter execution from collection/verification/retention cost. Investigate performance without relaxing the frozen rules; both resource obligations and final merge review remain unsatisfied. The entry-allocation control remains inapplicable. PR #9 is not ready to merge.

**PR delivery:** [robertguss/mo-v2#7](https://linear.app/robert-guss/review/record-the-stage-b-public-check-of-final-02-9a5765cd3b28), the historical failure-evidence PR, and [robertguss/mo-v2#8](https://linear.app/robert-guss/review/clarify-binding-view-creation-order-in-public-v21-9baa89e44c54), the binding-order clarification, are merged. Main [Buildkite 31](<https://buildkite.com/robert-guss/mo-v2/builds/31>) passed. [robertguss/mo-v2#9](https://linear.app/robert-guss/review/build-and-check-the-stage-b-interpreter-a4880103487e) remains draft pending the remaining acceptance and integration. Neither evidence-only merge accepts Stage B. The issue briefly returned to Done after the related PR merges; its actual status was corrected and read back as Building.

**Authorization:** D174, tracking reconciliation, continued Stage B work and conditional ready-PR merges, in [Robert's instruction](<https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55>). Private sources/seeds/raw rows stay outside the public repository; reports contain aggregates only. No release/deployment or copy-feedback participant trials. Stop condition: complete the remaining applicable checks and merge only the ready, verified work, or stop on a substantive acceptance/specification gap with precise evidence.

**Prior continuation delivery:** [continuation and integration, 526e78e](<https://github.com/robertguss/mo-v2/commit/526e78ec64da49da7f759d27f43f5ad6e7d3d0cb>) is pushed and remote-verified on both the acceptance-resolution branch and PR #9's implementation branch. [Readable current result](<https://github.com/robertguss/mo-v2/blob/526e78ec64da49da7f759d27f43f5ad6e7d3d0cb/experiments/13-source-acceptance/stage-b-adaptation-01/README.md>). Public evidence: 33,277 exact files in 162 volumes / 318,499,490 bytes; complete restore/hash/link verification and control-review replay pass. Only private aggregate totals are published. Frozen criteria and candidate source are unchanged by this continuation. [Buildkite 35](<https://buildkite.com/robert-guss/mo-v2/builds/35>) passed on this exact head; the resource failure still prevents merging PR #9.

## Historical record — superseded checkpoints below

## Historical checkpoint — Stage A merged; Stage B awaits authorization

8 October 2026. Robert authorized merging the reviewed Stage A checkpoint in [the parent discussion](<https://ampcode.com/threads/T-01a1165b-f05d-7209-98fb-f205021baff2>). The call-free implementation, native linker, reports and preserved non-private evidence are merged and pushed to main at [89d6e0a](<https://github.com/robertguss/mo-v2/commit/89d6e0a8d7bb0ddc7e4d3837c612d80e1de426cd>); the remote main tip was independently read back. [Readable result and limits](<https://github.com/robertguss/mo-v2/blob/89d6e0a8d7bb0ddc7e4d3837c612d80e1de426cd/experiments/13-source-acceptance/STAGE_A_RESULT.md>).

The entire experiment-13 tree is identical to the reviewed delivery. Integration only adds the documented native build and 41 builder development tests to existing Buildkite coverage, using pinned Rust 1.98.1. Local Rust checks passed; hosted Rust/Lean CI passed on the integration branch and again after the main push: [Buildkite build 10](<https://buildkite.com/robert-guss/mo-v2/builds/10>). Delivery/package fingerprints, 496 frozen files and five historical dependencies remain unchanged. This CI run is not a replacement acceptance campaign.

[ROB-1333](<https://linear.app/robert-guss/issue/ROB-1333>) is **Needs Input**, not Done: Stage A is merged, but the issue covers both stages. Stage B functions/recursion, private execution and streaming/resource work still require separate authorization. No release or deployment occurred. Both child threads remain stopped and unarchived. Earlier checkpoints below retain their historical status and evidence limits.

## Historical checkpoint — Stage A passed; awaiting merge approval

8 October 2026. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) is **In Review** for the call-free Stage A checkpoint. Exact final-08 source, native linker, readable reports and lossless non-private evidence are [pushed and remote-verified](<https://github.com/robertguss/mo-v2/commit/55b8096b2775a0348fd45c9e8bb63b0b3a3a18ef>) on `implementation/rob-1333-stage-a`, **not merged**. [Result, reproduction commands and limits](<https://github.com/robertguss/mo-v2/blob/55b8096b2775a0348fd45c9e8bb63b0b3a3a18ef/experiments/13-source-acceptance/STAGE_A_RESULT.md>).

Separate acceptance passed 4,276 historical cases / 53,796 actions, 58,634 resume checks, 58,634 destruction checks and 81,771 controlled-denial runs. All 21 applicable compiled controls had passing disabled baselines and were rejected for their intended defects. Parent review found no blocker: fresh native builds, 41 development tests, 25 native-linked spot checks and all 21 control pairs passed; control predicate evidence reproduced exactly. All 496 frozen files and five dependencies remain unchanged.

All 831,636 non-private evidence files are preserved in 51 lossless volumes. Full original-versus-restored hashing and link reconstruction passed; the parent independently decompressed/hashed every archived file and reconciled all nine sealed manifests. Earlier failures and public-wording qualifications are preserved, not erased. Private contents/seeds remain excluded from public delivery; the 524 private cases establish Stage A refusals only, not execution.

This is finite experimental evidence, not a universal safety or scaling claim. Denial coverage concerns observed frontend/execution attempts, not denial during destruction or arbitrary host OOM. Stage B functions/recursion, ten exact Stage B control paths, sixteen Stage B semantic expectations, private execution and streaming/resource work remain separately gated. No merge, release, deployment or new owner decision follows. Both child threads remain stopped and unarchived. Earlier status snapshots below are historical.

## Historical checkpoint — Stage A implementation dispatched after independent-check freeze

7 October 2026. The reviewed Stage A acceptance package is frozen and pushed on [the acceptance branch](<https://github.com/robertguss/mo-v2/commit/1f418931c6fef6dc14686aad4c9559e508951b7c>), not merged. Parent verified all 496 frozen Git blobs, five historical dependencies, and the exact nine-file public delivery. [Scientific lock and remaining gates](<https://github.com/robertguss/mo-v2/blob/1f418931c6fef6dc14686aad4c9559e508951b7c/experiments/13-source-acceptance/STAGE_A_LOCK.md>). These are preparation results, not passing Mo acceptance.

The [fresh builder](<https://ampcode.com/threads/T-01a1185b-f677-74ad-a1c9-769b73fe1411>) received only public v14 requirements/runtime in a no-project orb. Preflight verified an initially repository-free workspace, exact archive/content hashes and Rust 1.98.1 runtime compilation; recorded tool use showed no retrieval of excluded project or acceptance material. Same-account technical access remains available. Implementation was explicitly dispatched after that verification. The [separate acceptance author](<https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55>) remains stopped awaiting the candidate and will not implement Mo.

Authorization remains D153, the conditional review/freeze/Stage A sequence; D154, acceptance-owned external-memory reporting; and D155, procedural Stage A builder separation. Ordinary consistent repairs continue without repeated approvals. Substantive discrepancies and frozen-criterion changes stop the work. No candidate acceptance has run. Stage B, the unfinished large streaming adapter and actual resource workloads require separate preparation/review/authorization. No merge, release or deployment is authorized.

Stage A connects original source to call-free execution and the historical reference. Stage B adds functions/recursion only after review of Stage A evidence and separate authorization. Exact growing prototype integers and the presented language, ownership, failure, coverage and resource contracts remain approved; permanent Mo policy is not thereby settled. Arbitrary implementation-hour caps are deferred; effort is tracked, with no mandatory two-hour approval interruptions.

The all-issues reconciliation is recorded in [Start here](<https://linear.app/robert-guss/document/start-here-current-state-and-working-rules-29033acb30ab>); older audit-pending statements below are historical. Earlier checkpoints and drafts follow, preserved unchanged.

## Continue preparation without routine repair approval interruptions

Robert directed continued work without repeated approval questions for routine repairs. D145, bounded continuation without routine repair approvals, records this direction. Repair the acceptance-local decimal conversion guard consistently with exact prototype integers, preserve [v9 failure](<https://linear.app/robert-guss/document/rob-1333-v9-span-correction-verified-trace-projection-decimal-42c676770e1b>), validate and continue preparing the reviewable package. Scope changes, unresolved language choices, frozen-criterion changes and integrity issues still require escalation. Final package stop/approval and separate implementation boundary unchanged. Earlier defect-stop notes are historical.

## One draft prediction correction and preparation continuation approved

Robert approved correcting the mistaken comparison diagnostic span in a new version: \[\] is the invalid operand in main = \[\] == 1, at columns 8–10, not integer 1 at 14–15. D144, versioned draft operand-span correction, records the exact scope. Preserve [v8 original row/failure](<https://linear.app/robert-guss/document/rob-1333-v8-two-stage-repair-verified-draft-prediction-defect-stop-78668472e823>); derive the correction from the English operand rule, validate, and continue acceptance preparation under the existing deliverable-based stop. Other predictions/historical locks unchanged; no complete package or implementation authorization. Earlier status notes follow.

## Diagnostic phase order approved; reference repair may continue

Robert approved complete lexical/syntax validation before name/type checks, including duplicate match names. D143, syntax-before-name/type diagnostic order and repair continuation, records the boundary. Retain [v7 failed witness](<https://linear.app/robert-guss/document/rob-1333-v7-earliest-error-repair-verified-new-refusal-phase-stop-8ce62ffe648b>), repair the reference without changing expectations, and continue the reviewable acceptance package under D141’s deliverable-based stop. No final package approval, lock, physical-runtime acceptance or Mo implementation is claimed. Earlier status notes follow.

## Reference repair and preparation continuation approved

7 October: Robert approved keeping the earliest lexical/syntax error in source order, repairing the acceptance reference, and continuing preparation under D141’s deliverable-based stop. D142, earliest-error priority and reference-repair continuation, records this decision. Preserve [v6 failed checkpoint](<https://linear.app/robert-guss/document/rob-1333-v6-incomplete-acceptance-preparation-reference-defect-stop-f39348fa7b7e>) and expectations; validate repair and remaining preparation. No complete acceptance package, scientific lock or Mo implementation is authorized. Planning is acceptance preparation only. Earlier handoff/status notes follow.

## Acceptance thread restored; preparation authorization delivered

Robert approved restoring the existing [acceptance thread](<https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55>). Restoration and message delivery succeeded. The handoff carries D141, deliverable-based acceptance preparation: prepare concrete rules/examples/independent predictions/checks and validation for review, then stop before implementation. Earlier archive-related handoff failure is resolved. Planning denotes acceptance preparation only; no Mo builder, accepted scientific lock, participant trial, merge or deployment has started.

## Acceptance preparation authorized — deliverable-based stop

7 October: Robert approved preparation of the concrete rules, examples, independent expectations and checks for review, then a stop before Mo implementation. D141, deliverable-based acceptance preparation without mandatory interval approvals, records the boundary. No two-hour approval interruptions or eight-hour preparation cap is adopted. Report progress and stop early for choices changing approved scope; unresolved detailed rules remain proposed. [V5 plan](<https://linear.app/robert-guss/document/rob-1333-v5-approved-exact-prototype-integers-proposed-acceptance-5eece5c832ec>). Status Planning reflects acceptance preparation only, not builder authorization. Final package review/approval and lock remain required before implementation. Prior gates/status notes below are historical.

## Prototype number behavior approved — no implementation authorization

7 October: Robert approved exact, growing integers for this prototype, with Mo’s permanent number policy left open. D140, exact prototype integers, records this approval. No silent overflow/truncation/wrapping and no unlimited-resource or performance promise. Detailed failure/rule/resource choices, effort limits and executable acceptance authorization remain pending. [V4](<https://linear.app/robert-guss/document/rob-1333-v4-approved-feature-boundary-proposed-acceptance-details-ce2dfeb2db09>) incorporates the approved feature boundary; the acceptance author will reconcile the numeric approval without treating other proposals as accepted. Earlier draft/status notes follow.

## Limited feature scope approved — remaining acceptance gates pending

7 October: Robert approved integers/lists/local bindings/comparisons/branches/list matching, explicitly typed named functions and recursion, addition/subtraction only, mid-expression suspend/resume, and ordinary true/false literals. D139, limited first-language feature-scope approval, records the exact boundary. This supersedes v3’s exclusion of Boolean literals, not its other pending choices. No implementation or blanket v3 approval; numeric behavior, detailed rules, effort limits and exact acceptance authorization remain pending. The current proposal is [v3](<https://linear.app/robert-guss/document/rob-1333-v3-proposed-rules-and-acceptance-plan-after-fable-review-244d9ffcee25>), to be reconciled by its acceptance author. Historical drafts follow.

## Separate acceptance-plan thread started

Robert requested a new Amp thread for acceptance preparation. [Acceptance-plan revision thread](<https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55>) owns a v2 rules/acceptance-plan draft and will attach it to this issue for review. Fable remains a plan reviewer only. No Mo implementation, executable acceptance package, lock, trials or merge is started by this handoff. The scope/effort approvals remain pending.

## Review received — draft v1 is not ready for builder handover

7 October 2026. [Fable’s full review](<https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and#comment-df80ec4f>) supports the two-stage scope but identifies acceptance gaps. No owner approval, lock, implementation or status change follows from review. Draft v1 below remains a proposal, not frozen acceptance.

Carry forward into the next draft: one actual grammar/parser for corpus and handwritten source; explicit Stage A/B must-accept and must-refuse sets; fixture isolation; snapshots and operation records tied to actual cells; independently fixed mid-expression transitions; append-only resume evidence; frame-identified call entry/return accounting; exact program/literal/Boolean/arithmetic/namespace/span/output/failure/cleanup rules; independent predicted memory events, including the unique-versus-retained recursive increment distinction; arithmetic beyond 128 bits if exact integers are chosen; and a measurable effort convention.

Lead/Oracle qualifications to Fable’s proposed fixes:

* Cell identity must persist while the cell stays live; legitimately freed cells need not appear in the final state. Recycled addresses must not hide identity changes.
* Deep non-tail recursion is bounded evidence, not proof of no host-stack dependence. Fix a resource envelope and check explicit-frame execution.
* Deterministic public output/normalized traces can be compared across runs; raw physical addresses are separate evidence, not required byte-identical output. Resume checks must observe physical work as well as logical suffixes to detect hidden replay.
* Stage A’s existing frozen snapshot checks cannot be omitted silently. A change to the proposed compatibility obligation requires Robert’s explicit review; preserve historical checks regardless.
* Independent event prediction is a responsibility of separately authored acceptance. Another mandatory predictor session/model is not automatically authorized.
* A reporting point is not a spending cap. Replacing the 8-hour preparation stop or redefining effort units needs owner approval; hitting a cap must never justify weaker checks.

Owner clarification recorded 7 October: Fable reviews plans only, not acceptance authoring or execution. The prior Fable assignment was the agent’s mistaken interpretation and is corrected in the live register. Robert authorized a new Amp thread for separate acceptance preparation. D137, plan-only Fable review and separate Amp acceptance preparation, records the current arrangement. Immediate handoff is a revised rules/acceptance-plan draft only; executable checks, locks, implementation and trials wait for scope approval. Effort units and all proposed caps/intervals remain unapproved. No Fable execution session was launched.

---

# First executable Mo core — draft v1 for Fable review

**Status: proposal only.** Robert approved writing this draft in [the discussion](<https://ampcode.com/threads/T-01a1165b-f05d-7209-98fb-f205021baff2>), then having Fable review it. He has not approved the scope, syntax, numerical behavior, acceptance package, effort limits, implementation, merge or deployment. No builder starts from this issue. Existing experiments, requirements and locks remain unchanged.

## The capability Robert would get

An agent writes a small Mo source file using integers, Booleans, lists of integers, local bindings, branches, list matching, and named functions that may call themselves or each other. A command checks the file and runs it, returning/printing the answer or a source-located explanation of a mistake. Execution can suspend after a specified number of interpreter steps and resume without restarting or losing values.

Example outcome: a recursive program transforms \[3, -2, 8\] into \[4, -1, 9\]. If another holder retains the input, that holder must still read \[3, -2, 8\]. Successful runs must do real cell reuse where the approved rules permit it, rather than merely reporting fictional reuse events.

This is an experimental language implementation and execution engine, not yet a native compiler, concurrent service runtime, static in-place demand checker, or verified compiler. Its usefulness to agents remains an experimental question.

## Why build this now

The finite model and executable memory comparison provide a reference to connect to source. The calls draft provides four approved experimental constraints, with detailed rules still pending. The native-update line provides mechanisms for a later runtime milestone; it is not a prerequisite to reading and executing Mo source.

Recommendation: build one interpreter over a small checked intermediate representation (a structured program after names and types are checked). Add a compiler later only when its question and acceptance are specified. Do not create a second runtime implementation now or make completion of every parked experiment a prerequisite.

Stage A: source + checked program + existing memory fixtures → compare with finite Lean reference.
Stage B: same interpreter + calls/recursion + explicit execution state → compare with separately authored reference/checks.

Both stages belong to the first useful milestone. Stage A alone is a checkpoint, not delivery of the full capability above. After Stage A, report evidence and obtain Robert's Stage B go-ahead; passing checks does not authorize the next stage automatically.

## Stage A — connect source to the established finite core

Keep the finite core's integer arithmetic, comparisons, lists, names, let, if and list matching. Add a lexer/parser, source locations, lexical name resolution and type checking. Source must actually determine the program; it cannot select prewritten Rust examples.

Route each of the 4,276 frozen cases' expressions through the frontend while installing its original typed inputs and initial memory through a test-only host fixture. Physical sharing and outside holders cannot necessarily be expressed by list contents in a standalone source file. Do not invent public heap-address syntax, wrap expressions in a function, or count fixture construction as expression evaluation just to fit the corpus.

Retain comparison of answers, final memory, ordered creation/reuse/release records, rule logs and the existing exposed snapshots under one whole-run address correspondence. Preserve the original accounting boundary, including evaluation preparation and separately counted initial fixture construction. Actual allocation/drop and same-object reuse evidence must agree with reported events. The acceptance author defines and freezes the source serialization and comparison adapter before implementation; no per-snapshot relabeling or silently dropped fields.

Use the same extended interpreter for the final call-free regression check after Stage B. Add separately authored source examples with varied identifiers, shadowing, nesting and source errors; generated text for old fixtures alone cannot establish frontend correctness. Preserve the old interpreter as a versioned reference, rather than editing its checks to fit the new implementation.

## Stage B — functions and resumable recursion

Proposed scope: a finite table of uniquely named first-order functions, distinct parameters, explicit integer/Boolean/list parameter and result types, direct and mutual recursion. No closures, functions as values, general type inference or termination requirement.

Carry forward these owner-approved experimental constraints, without promoting them into permanent Mo rules:

* D127, call-local reservations: a callee cannot consume a cell its caller set aside.
* D128, unrestricted recursion with resumable bounded observations: report finished, failed or suspended; suspension retains execution state and is not an answer or proof of infinite execution.
* D129, continuous live-value protection: suspended caller values and completed arguments remain readable and unchanged while live.
* D130, allocation accounting from function entry: entry copying, descendant execution/argument preparation and transient creations count; explicit caller argument construction before entry remains visible globally but outside that callee's interval.

Propose explicit interpreter frames/continuations, not recursive host calls that overflow the Rust stack or lose resumability. An observation limit counts specified interpreter transitions; it is not a wall-clock SLA or a language rule requiring termination. Specify every transition and bookkeeping boundary before freezing expectations.

Proposed detailed rules, adapted from the existing calls draft: arguments evaluate left to right; completed arguments stay held; functions see parameters/local names, not caller locals; holders transfer into parameters and back with the result without hidden copies; unused parameters are released in declaration order; reservations remain call-local and branch-owned; suspended callers retain needed bindings, temporaries and reservations. No silent tail-call transformation or early branch cleanup.

Failure handling is not yet fully specified. Before implementation, define how source errors, invalid test fixtures, observation suspension, host resource failure and internal invariant failure are distinguished; which holders remain valid; and how destroying a finished/failed/suspended run releases its managed storage without touching independently retained host fixtures. Do not use 'suspended' to hide an implementation failure or promise arbitrary-resource execution.

Every retained reference to managed list storage must participate in ownership bookkeeping. Return a readable answer; a general host-handle API is excluded. Ordinary function identities/source locations suffice; code-version management is deferred.

## Proposed examples — not frozen predictions

The acceptance author turns these into exact programs, starting memories, observations and expectations, independently of implementation. This table illustrates the intended capability; it is not the acceptance suite.

| Case | Input or setup | Proposed observable result / distinction |
| -- | -- | -- |
| Recursive sum | \[3, -2, 8\] | 9; empty input gives 0; both branches exercised |
| Recursive increment | \[3, -2, 8\], unique and separately retained starts | \[4, -1, 9\]; retained original remains \[3, -2, 8\]; physical events derived separately for each start |
| Pending argument | choose(a,b) returns a; choose(xs, increment(xs)), xs=\[1,2\] | Answer \[1,2\]; first argument cannot change during evaluation of second |
| Suspended caller | increment xs, then use original xs | Original remains \[1,2\] throughout the call, not merely restored at return |
| Reservation across call | Caller matches unique \[1\], calls a helper constructing \[1\], then finishes its branch | Helper creates a cell; cannot steal caller reservation; check ownership/events, not just equal list contents |
| Transient allocation | Helper creates and discards one list cell | Creation still counted despite zero final heap growth |
| Entry versus caller construction | identity(\[1\]) versus outer calling identity(\[1\]) | Cell is global caller construction, outside identity's interval, but inside outer's interval |
| Mutual recursion | even/odd on 0, 1, 2, 7 | Correct true/false answers; function names resolved across the table |
| Resume terminating work | Recursive sum interrupted at several step boundaries | Same answer and event sequence as uninterrupted execution; counts neither reset nor repeat |
| Endless recursion | spin calls itself, with and without transient cell creation | Every finite observation stays suspended; prefixes distinguish zero creation from repeated creation; no divergence proof claimed |
| Wrong source | Unbound name, wrong argument count/type, duplicate function/parameter, bad return type, malformed syntax | Refusal identifies mistake class and relevant source span; no evaluation of statically refused source |

Adapt the existing calls draft's C1–C14 cases, including shared tails and a branch that never returns. Because this proposal has no demand annotations/checker, retain their execution and accounting questions, not invented mandatory checker verdicts. Any excluded case must be explained before acceptance approval. No Mo agent study or helpfulness claim follows merely from producing error messages.

## Independent acceptance and deliberately broken controls

Recommend a separate acceptance author, approved by Robert, owns the English rules, source/fixture corpus, reference expectations, checker code and fingerprints before the builder implements this milestone. The builder owns implementation only and cannot alter accepting checks, thresholds or predictions. Fable's proposal review is not acceptance authorship or execution unless separately assigned.

Keep the unchanged Lean reference for Stage A. For Stage B, use a separately authored simple immutable-value reference for answers and an independently derived ownership/event/state checker for memory and suspension. A Python answer reference alone cannot validate physical reuse, reservations or allocation intervals. Neither reference reads expected answers from the implementation. Check protected values at specified execution boundaries; an end-only comparison cannot detect temporary corruption.

Require valid-input, compiled broken controls for shared mutation, always-copying, incorrect name binding, consuming caller reservations, losing pending argument/caller holders, omitted entry/descendant/transient allocations, restarting on resume, misclassifying suspension as completion, and skipped return/branch cleanup. Controls must fail for the intended reason; a compilation error or unrelated crash does not count. Separate implementation mistakes from defects in the expectations. Preserve both; never change expectations solely because the implementation disagrees.

Final evidence: clean reproducible build, frozen fingerprints unchanged, all Stage A comparisons rerun on the final implementation, Stage B answers/events/ownership/resumption checks, exact refusals, control outcomes and every failed attempt. State authorship accurately; no claim that passing a finite corpus proves all programs safe.

## Proposed syntax and numeric compatibility

Neither is selected by this issue.

Recommend one minimal, explicitly provisional Ruby/Elixir-like surface spelling for the listed constructs. Parser tooling remains an implementation choice; a comparison of syntax variants is outside this milestone. Freeze an exact grammar and source-span/refusal policy for acceptance; this is an experiment notation, not a permanent syntax decision. Reopen it if representative agent repair tasks expose a concrete ambiguity or poor error location.

Recommend exact arbitrary-size integers for this prototype to preserve the finite Lean model's arithmetic meaning; no silent overflow or truncation. Experiment 10's checked i128 restriction was only a corpus accommodation and cannot become an implicit language default. Experiment 11's checked-i64/explicit-big recommendation remains an alternative for future policy selection. Numeric allocations and interpreter/frame allocations must be recorded separately from list-cell counts; zero list-cell creation does not mean zero total allocation or bounded memory.

Before execution approval, specify host resource exhaustion behavior and test arithmetic beyond the old corpus bounds with an independent reference. This provisional exact-integer choice is not approval of unconstrained resource growth, a performance guarantee or Mo's permanent number policy. Any later fixed-integer policy needs explicit review and a compatibility story rather than weakening this corpus silently.

## Proposed effort and scope limits

These are reviewable containment limits, not estimates or promises of completion:

* Preparation/acceptance: at most 8 active agent-hours to settle the exact draft and separately author/freeze checks.
* Stage A: at most 12 further active agent-hours, including builder fixes and separate acceptance execution.
* Stage B: at most 20 further active agent-hours, including implementation, fixes, separate acceptance and report.
* Total: 40 active agent-hours across all contributors, with a time ledger; human waiting excluded, overlapping worker time counted individually. Work beyond a stage or total cap needs a revised owner-approved brief. No automatic borrowing of unused stage time.
* Progress report every two active hours: work completed, checks run, failures, time used and unresolved specification defects. Cadence does not authorize another stage or a cap extension.
* One interpreter, one grammar, the types/constructs above, and fixed frozen corpus. No expansion to make this a general application platform.
* No separately billed model/API calls, top-ups, cloud resources or paid fallback. Review current approved subscription/tool access before execution; stop on unavailable authorized access.

Stop immediately for an ambiguous accepting rule, a concrete counterexample, changed fingerprint, invalid reference, inability to reproduce baseline, or unauthorized scope. Stop at the cap and deliver partial evidence; do not redefine the milestone as complete. Compiler/tool setup errors may be fixed and retained within the cap without changing acceptance. On behavioral failure retain the exact input, state and output; any repaired candidate is a new recorded run, not erasure of the failure.

## Delivery and explicit go/no-go boundaries

1. Fable reviews this draft; record disagreements and corrections here.
2. Robert approves or redirects scope, provisional grammar/numbers, acceptance arrangement and caps. The exact acceptance package/implementation brief is separately reviewed, approved and locked before builder work.
3. Stage A implementation and separate acceptance; stop and report. Robert decides whether Stage B proceeds under its frozen checks.
4. Stage B implementation and final acceptance; report both demonstrated results and remaining limitations.
5. Deliver on a dedicated branch with reproducible code/checks/raw evidence and a readable result indexed in Linear. Commit/push follow existing standing authorization and required review. In Review does not mean merged. Robert's merge approval remains separate; Done requires confirmed merge. No release or deployment.

Approval to prepare this draft grants only step 1's draft preparation, not steps 2–5.

## What remains outside this milestone

Native compilation, processes, supervisors, concurrency, live updates, code-version identities, network/file/program I/O other than returning/printing an answer, capabilities/effects, text/records/general collections, closures, general inference, static in-place demands and new Lean proofs. No performance superiority, arbitrary-native safety, production SLA, termination guarantee or agent benefit claim.

Hot updates and agent-first development remain project goals, not discarded requirements. This milestone supplies real Mo programs for later scoped experiments. Copy-feedback trials may be separately approved but neither start here nor gate this interpreter. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) and [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment) remain open; this proposal does not approve, replace or weaken full 3c's proof/checker stages or Koka comparison gates. It proposes an unproved executable extension, not a shortcut to those proofs.

## Alternatives and Fable's review questions

Call-free-only: cheapest frontend check, but too limited for recursive list programs; use as Stage A rather than endpoint. Native compiler first: closer to executable speed/loading, but adds translation/optimizer correctness and does not inherit model proofs. Runtime first: serves hot evolution sooner, but risks another Rust service prototype without any Mo source. Finish all parked research first: may clarify isolated policies, but postpones integrated evidence without a demonstrated dependency.

Please review: Can these checks pass while the advertised capability fails? Are both stages achievable within the proposed containment limits? Does the source-plus-fixture comparison preserve the original accounting boundary? Do the call examples distinguish wrong ownership/cleanup/resumption implementations? Are numeric behavior and failure cleanup precise enough to prepare acceptance? What must change before the builder starts? Review the proposal; do not implement or treat any recommendation as owner approval.

## Evidence and provenance

* [Accepted finite trial and limits](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RESULT.md>).
* [Finite Rust comparison: 4,276 cases, same-author new checks, independent historical model](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/RESULT.md>) and [frozen comparison scope](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/SPEC.md>).
* [Calls/recursion draft, partial approvals and pending details](<https://linear.app/robert-guss/document/full-3c-calls-and-recursion-specification-draft-5-october-73682eae811b>).
* [Integer-policy result, not an adopted default](<https://github.com/robertguss/mo-v2/blob/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3/experiments/11-integer-policies/RESULT.md>).
* [Native migration evidence and trusted/staged limits](<https://github.com/robertguss/mo-v2/blob/6de1d55f25a5451ef21b24afa6e8d92ee4dcc121/experiments/08-native-migration/RESULT.md>).
* [Owner discussion, Claude Fable's supplied advice, Oracle consultations and draft-only authorization](<https://ampcode.com/threads/T-01a1165b-f05d-7209-98fb-f205021baff2>).

The original all-issues audit is still unfinished. This draft neither certifies that every Linear record is current nor resolves the two existing In Review branches. Repository inspection found a later CLAUDE.md deletion on the copy-feedback branch; intent/authorization remains unestablished, and this proposal authorizes no restoration or merge.

## Comments

### 2026-10-07 13:19 UTC, Robert Guss

## Fable review of draft v1 — 7 October 2026

Review only. Nothing here is an approval, acceptance authorship, or an
instruction to a builder. I read this draft, the calls and recursion draft it
carries forward, the finite Rust comparison's frozen corpus and checker, the
trial's approved rule text, and the live register through D134.

**Short answer to "can these checks pass while the capability fails?": yes, in
at least eight ways as written.** None of them is exotic. Each is the kind of
shortcut a builder takes under a cap without meaning to cheat. The fixes are
rules the acceptance author must write before the lock, not more review layers.

### A. Loopholes: ways to pass the checks while failing the capability

**A1. The "parser" can be a token reader.** The 4,276 frozen cases are stored in
a prefix wire format (`match h t var xs nil cons add var h num 1 var t`). The
draft says the acceptance author freezes "the source serialization". If that
serialization is a near-verbatim respelling of the wire format, a trivial reader
passes Stage A without ever parsing the grammar agents will write in Stage B.
Rule to add: Stage A source text is produced by a pretty-printer into the _same
frozen grammar_ used by the Stage B examples, with precedence and brackets; the
acceptance checker compares the builder's parsed tree, dumped in a frozen
structural format, against the corpus tree. The hand-written Stage A examples
must go through the same parser entry point as the corpus text, with no second
mode.

**A2. A checker that accepts everything passes Stage A.** The corpus contains
only well-formed programs with valid starts. The draft mentions "source errors"
among extra examples but gives Stage A no must-refuse set. Experiment 1's lesson
applies directly. Rule to add: a Stage A must-refuse list drawn from the trial
rule's own well-formedness conditions, each with its refusal class: unbound
name; `if` condition not true-or-false; `match` names spelled alike (D89, the
trial rule that a match's two names differ); two inputs with one spelling (D97);
branches of different kinds; a list used where a number is expected. Plus the
mirror control: a checker that refuses everything must fail the must-accept set.

**A3. The fixture can leak information.** Stage A installs each case's initial
memory and outside holders "through a test-only host fixture". If the
interpreter can tell fixture-installed memory from program-built memory, or can
read the fixture's shape, it can behave differently on the corpus than on real
programs. Rule to add: the fixture writes cells and holders only, through the
same cell API the interpreter uses; the interpreter has no access to the fixture
after installation; Stage B must include at least one example whose starting
memory is built both by fixture and by source literals, with identical events
after the construction prefix. Keep experiment 10's "copy before evaluation,
hidden from the record" control.

**A4. Snapshots and events can come from a shadow model.** Experiment 10's
interpreter mirrored the Lean evaluator's snapshot schedule. A new interpreter
over a checked intermediate form with explicit frames will have a different
natural step structure. Under a cap, the easy way to match the Lean snapshot
sequence is to compute the answer one way and emit snapshots from a parallel
bookkeeping model. Experiment 10's physical-pointer check catches some of this
but not all. Rules to add: every reported snapshot is produced by reading the
interpreter's live memory at that moment; physical write and free events are
recorded inside the cell implementation, the only code that can mutate a cell,
and must match the logical record one for one; add a control, "report from a
shadow model while physically mutating a shared cell", that must fail. Also
decide, before the lock, which Stage A snapshot kinds are required to match
exactly and which the new interpreter may omit. Forcing the new design to
replicate the Lean evaluator's internal schedule is a design constraint the
draft does not intend.

**A5. Coarse steps make suspension tests vacuous.** D128, your approval of
unrestricted recursion with bounded, resumable observations, counts "specified
interpreter transitions". If the builder defines a transition as "one function
call", every suspension lands at a function boundary and the "pending argument"
and "suspended caller" examples never observe a mid-expression state. Rules to
add: the acceptance author, not the builder, fixes the transition granularity in
the English rules; the resume examples must suspend at every transition kind,
including between the first and second argument of `choose(xs, bump(xs))`, after
a cell is set aside but before the construction that might reuse it, and inside
a callee; add a control, "suspend only at call boundaries", that must fail one
of those.

**A6. Resume by replay.** A builder can implement resume as "run again from the
start with a larger budget" and hide it. The draft's "counts neither reset nor
repeat" control helps only if the check can see the join. Rules to add: the
event record is append-only and is read at each suspension; resumed execution
must produce exactly the remaining suffix; physical addresses of live cells
observed at suspension must be the same addresses in the final state. A replay
that reinstalls fixture memory changes addresses and fails this.

**A7. Deep recursion can be declared a "host resource failure".** The draft asks
for explicit frames, not host recursion, and separately allows a "host resource
failure" outcome. Without a must-finish depth, a builder can use host recursion,
overflow the Rust stack on long lists, and classify it as a legitimate failure.
Rule to add: at least one must-finish example with a recursion depth the
acceptance author fixes, large enough that host recursion cannot pass. A depth
of one million frames over a one-million-cell list is in the spirit of
experiment 3's sizes.

**A8. Per-call allocation accounting is unobservable as drafted.** D130, your
approval that a demanded call's allocation count starts at function entry after
explicit arguments, is carried forward, but this milestone has no demand
annotations and the draft never says the interpreter must report call
boundaries. Then the "transient allocation", "entry versus caller construction"
and nested-call examples cannot be checked at all. Rule to add: the ordered
record gains `enter` and `return` events with a frame identity, placed exactly
after the last explicit argument finishes and after callee cleanup, so the
acceptance checker can compute per-invocation counts externally. Add a control
that emits `enter` before the last argument finishes; it must fail the
entry-versus-caller example.

### B. Missing rules the acceptance author cannot write around

**B1. No predictor for Stage B counts.** For Stage A, Lean supplies the expected
events. For Stage B, the draft names "an independently derived
ownership/event/state checker" but not who produces the expected creation, reuse
and free counts for each example, or from what. A Python answer reference gives
answers only. Without predicted counts, "real cell reuse where the approved
rules permit it" cannot be enforced, and the always-copying control cannot fail.
Recommendation: reuse the trial's arrangement. A fresh session writes
predictions from the approved English rules alone, before encoding, and Robert
approves them. The sharpest single prediction to require: recursive increment on
a uniquely held list creates **zero** cells, because D127, call-local
reservations, lets the caller's branch reuse its own reserved cell after the
recursive call returns. Recursive increment on a retained list creates one cell
per element. These two numbers are the capability.

**B2. Program shape is undefined.** The trial runs one expression over declared
inputs. The draft forbids wrapping corpus expressions in a function, which is
right, but never says what a Stage B program is. Rule to add: a program is a
function table, possibly empty, plus one main expression, plus declared typed
inputs. A corpus case is then a program with an empty table, and Stage A and
Stage B run through one evaluator with no mode flag.

**B3. List literals are a new construct with memory consequences.** The examples
use `[3, -2, 8]`. The trial grammar has only `[]` and `[h | t]`. A literal must
be rewritten to nested cells, and the order in which those cells are built
decides which set-aside cell is reused under D87 and D88, the trial rules that a
new cell picks its set-aside cell after its parts are worked out, newest first.
Rule to add: freeze the rewrite of a literal into nested constructions as a
source-level rewrite before evaluation, so the predictor can apply the approved
rules; and forbid the frontend from pre-building any cell. A control, "frontend
pre-allocates literal lists at check time", must fail because those creations
would fall outside the evaluation record.

**B4. Booleans are underspecified.** The capability lists Booleans; the trial
has no Boolean literals or operators, and `==` is on numbers only under D80.
Decide now: `true` and `false` literals, whether `not`, `and`, `or` exist,
whether `==` applies to Booleans, and whether a top-level input may be Boolean.
The calls draft says top-level inputs stay number or list. The mutual-recursion
example says "true/false answers" while the calls draft's version returns 1
and 0. Pick one.

**B5. Arithmetic is wider than the trial, or it is not.** The draft says
"integer arithmetic". The trial has only add and subtract, so there is no
division and no divide-by-zero failure. Either keep add and subtract only, or
add multiply, divide and remainder with the failure class for division by zero
specified and experiment 11's sign conventions reused. Unary minus versus binary
minus in the grammar must be settled either way.

**B6. Function and local namespaces.** Can a parameter be spelled like a
function? Can a function be called before its definition in the table? Can two
functions differ only in case? State the rule; the must-refuse set needs it.

**B7. Refusal spans.** "Relevant source span" lets a builder report the whole
file. Rule to add: for each must-refuse example the acceptance fixes the exact
line and column range of the smallest construct that explains the mistake, and a
control that always reports the whole file must fail.

**B8. Answer format and determinism.** What is printed for a list, a Boolean, a
suspended run, a refusal? Freeze the output format; otherwise the checker
compares against nothing. Require two runs to be byte-identical, as experiment
10 did.

**B9. Failure classes and cleanup.** The draft admits these are not specified.
Before the lock: source refusal, invalid fixture, suspended, host resource
exhaustion, and internal invariant failure must be distinct outcomes; exhaustion
must never be reported as suspended; destroying a run in any state must release
its managed cells and must not touch fixture-retained cells, and the acceptance
should check that with the allocator counters experiment 10 already uses.

**B10. Big integers beyond 128 bits.** The draft recommends exact arbitrary-size
integers. If every test value fits in 128 bits, a checked `i128` implementation
passes. Add cases past 128 bits; experiment 11's 1,024-bit inputs are a ready
pattern. Numeric allocations stay separate from list-cell counts, as drafted.

**B11. Effort units are undefined.** "Active agent-hours" is not measurable for
an AI session unless defined. The trial used elapsed wall-clock intervals from
brief handover to stop report, excluding waits on Robert, recorded in a clock
file. Reuse that definition or the caps cannot bind.

### C. Scope: what is right, what is at risk, what is missing

**Right.** One interpreter over a checked intermediate form; Stage A anchored to
the only proven reference; calls and recursion in the first milestone; explicit
types with no inference; a separate acceptance author; no demand checker, no
native code, no processes, no live update. This matches the shape I recommended
and I have no disagreement with the stage order.

**At risk: resumable suspension is the largest engineering item in Stage B.** It
requires explicit frames and continuations, suspendable mid-expression, with the
event record and address stability of A5 and A6. It is justified: D128 requires
honest handling of endless recursion, and a suspendable interpreter with
explicit frames is exactly the substrate the live-update line will need for "a
safe boundary between operations". But it is where the 20-hour cap will bind
first. State now that a Stage B stop at the cap with suspension working only at
call boundaries is a reportable partial result, with the mid-expression cases
recorded as unmet, not a redefinition of the milestone.

**At risk: the 8-hour acceptance-preparation cap.** The acceptance author must
write the English rules for calls that the calls draft leaves open, the Stage A
and Stage B example corpus, the must-refuse sets with spans, the grammar, the
serializer and structural dump, the Stage B reference in another language, the
step-granularity rules, the predictions, and the controls. The trial's rule,
examples, interface, predictions and acceptance took several sessions for a
smaller language. A cap that binds on acceptance authoring produces thin checks,
which is the one failure the lock pattern exists to prevent. Recommendation: cap
the builder's stages, and let acceptance preparation stop and report without
penalty when it needs more time. If a number is wanted, double it and treat the
result as a reporting point, not a stop.

**Missing from the "outside this milestone" list, and should be added so nobody
infers them:** explanation quality of refusals beyond class and span; any agent
study; any performance figure; list literals beyond numbers; string or record
values; an answer-handle API; code identity beyond source location.

**Missing decision: who the acceptance author is.** D108 put all work in one
Codex session, and D118 allowed self-verification for the native-loading
experiments. The draft recommends a separate author "approved by Robert" without
naming the options. The realistic options are a fresh Codex session, a fresh
Claude session, or this reviewer, each in its own visible context and barred
from the implementation. This is Robert's decision and it changes the brief.

### D. Answers to the six review questions

1. **Can these checks pass while the capability fails?** Yes, by A1 through A8.
   With the rules in A and B added, I found no remaining way, which is a
   reading, not a proof.
2. **Are both stages achievable within the caps?** I cannot estimate agent hours
   reliably and will not pretend to. Stage A implementation within 12 hours is
   plausible because experiment 10's interpreter exists as a reference. Stage B
   within 20 is plausible for a call-boundary-only suspension and doubtful for
   mid-expression suspension. The 8-hour acceptance cap is the one I expect to
   bind, and that is the dangerous one.
3. **Does source plus fixture preserve the accounting boundary?** Mostly, with
   two holes: frontend pre-allocation of literals, B3, and the undefined
   position of parsing and checking relative to "evaluation preparation". State
   that parsing and checking happen before preparation and can create no cells.
4. **Do the call examples distinguish wrong implementations?** They distinguish
   ownership and cleanup only once exact predicted counts exist, B1, and
   `enter`/`return` events exist, A8. They distinguish resumption only with
   fixed step granularity, A5, address stability, A6, and a must-finish depth,
   A7.
5. **Are numeric behavior and failure cleanup precise enough?** Numbers: nearly,
   after B5 and B10. Failure and cleanup: no, B9, and the draft says so itself.
6. **What must change before a builder starts?** See E.

### E. What must change before a builder starts

1. Robert decides the acceptance author and the effort-unit definition, B11.
2. The acceptance author writes and Robert approves: the frozen grammar with
   precedence and literal rewrite, B3 and B5; the program shape, B2; the Boolean
   and namespace rules, B4 and B6; the failure classes and cleanup rules, B9;
   the step-granularity rules, A5; the `enter`/`return` event rules, A8; the
   output format, B8.
3. A separate predictor produces the Stage B expectations from those English
   rules alone, B1, including zero creations for recursive increment on a unique
   list.
4. The must-refuse sets with exact spans for both stages, A2 and B7, and the
   must-finish depth, A7.
5. The control list is extended with: shadow-model reporter, A4;
   call-boundary-only suspension, A5; replay on resume, A6; early `enter` event,
   A8; frontend pre-allocation, B3; whole-file span, B7; accept-everything and
   refuse-everything checkers, A2.
6. The caps are restated per C, and the suspension partial outcome is
   pre-declared.
7. Fingerprints for all of the above are recorded before the builder receives
   the brief, with the experiment 10 corpus and the Lean trial unchanged.

Nothing in this review changes an existing lock, approves scope, or assigns
work.


### 2026-10-07 13:46 UTC, Robert Guss

## v2 rules and separate acceptance PLAN ready for owner/Fable review

[Proposed/unapproved v2 document](https://linear.app/robert-guss/document/rob-1333-v2-proposed-rules-and-separate-acceptance-plan-unapproved-ec72e7c3afc4) is attached to this issue. This is draft preparation only under D137, separate Amp acceptance preparation with Fable restricted to plan review. Fable was not invoked. The issue description/live register and all historical sources/locks remain unchanged.

The draft supplies one common grammar and parsed structure, explicit Stage A/B acceptance/refusal categories and span examples, fixture isolation and physical event/state obligations, all frozen Stage A snapshots, fine-grained resumable transitions, live-lifetime identity continuity and normalized cross-run traces, frame-identified enter/return accounting, C1–C14 distinguishing predictions, literal construction order, types/namespaces/limited Boolean and arithmetic rules, >128-bit examples, failure/destruction rules, and a proposed bounded recursion envelope. Unique three-cell bump predicts 0 creates/3 writes; retained bump predicts 3 creates/0 writes. These are English-rule-derived proposals, not executed or frozen acceptance.

Owner choices remain: provisional syntax/Boolean/namespace/transition rules; exact versus fixed integer semantics; snapshot-compatibility obligation and recursion resource envelope; measurable contributor elapsed-time convention, hard caps versus reporting points and continuation policy; then authorization for exact acceptance preparation. The 8/12/20/40-hour numbers and two-hour approval intervals are unapproved. I recommend a hard preparation stop rather than silently adopting Fable’s reporting-only alternative; both are explicitly presented for Robert. A cap hit yields incomplete evidence, never weaker checks.

Read the current Linear sources/full Fable review and pinned repository sources; reread the saved document and repaired Linear table formatting so C2/C6 predictions remain visible. No Mo implementation, executable acceptance, lock, tests/trials, commit/push, merge or deployment. Repository worktree remains clean. Immediate handoff stop condition reached; parent notified separately. Robert can bring this document to Fable for plan review; no acceptance execution follows automatically.

### 2026-10-07 13:54 UTC, Robert Guss

## Fable review of v2 — 7 October 2026

Review only, under D137, which limits Fable to plan review. Nothing here
approves scope, assigns work, or changes a lock. I read the v2 document, the
updated issue description and 13:46 comment, the live register through D137, and
re-derived the C1 to C14 predictions and the bump counts by hand against the
trial rule and the four approved call constraints, D127 to D130.

### 1. The eight loopholes from the v1 review

All eight are closed **as plans**. Three of them depend on preparation outputs
that do not exist yet and must exist before a builder starts; those are listed
under blockers.

| v1 loophole                         | v2 answer                                                                                                                                              | Status                     |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------- |
| A1 token reader                     | One grammar; acceptance-owned structural decoder; pretty-print then reparse; precedence examples such as `9 - 4 - 2`                                   | Closed                     |
| A2 accept-everything checker        | Stage A and Stage B must-refuse sets; accept-all and refuse-all controls                                                                               | Closed                     |
| A3 fixture leak                     | Fixture installs through the primitive API, metadata discarded; cross-route pair; provenance-leak control                                              | Closed                     |
| A4 shadow model                     | Physical log inside the sole mutable cell implementation; snapshots read live storage; acceptance walks storage independently; shadow-reporter control | Closed                     |
| A5 coarse steps                     | Section 7 transition table; acceptance freezes exact traces; interrupt at every boundary; call-boundary-only control                                   | Closed, pending the traces |
| A6 replay on resume                 | Append-only record; suffix equality; lifetime identity and address continuity across joins; replay and reset controls                                  | Closed                     |
| A7 host recursion as "failure"      | Million-cell non-tail sum under an 8 MiB stack limit; stack overflow fails even if labelled                                                            | Closed, pending resources  |
| A8 unobservable per-call accounting | `enter` and `return` events with frame identity; acceptance computes counts from boundaries                                                            | Closed                     |

The B items are also answered: program shape, literal rewrite, Boolean policy,
add and subtract only, namespaces, spans with worked examples, output format,
failure classes, values past 128 bits, and an effort convention. I checked the
four span examples by column and they are right. I checked the bump counts and
C1 to C14 against the rules and found no error: unique bump is zero creates and
three writes, retained bump is three creates and zero writes.

### 2. Contradictions in v2

**C-a. One Release transition, two frozen snapshots.** Section 7 says a Release
transition gives up one holder and, if the count reaches zero, frees the cell in
the same committed step. The frozen corpus records those as two separate
snapshots: 7,078 `holderGivenUp` and 5,269 `cellFreed`. Section 5 requires every
snapshot kind to be retained and section 7 permits observation only at committed
states. As written, the projection cannot land on the state between give-up and
free. Fix: split Release into "give up one holder" and "free one zero-count
cell" as two transitions, or state explicitly that the projection samples one
committed state for both landmarks and that the free landmark's expected memory
is compared after the combined step. The first is cleaner and keeps "only
committed states" true.

**C-b. "New transitions may add states" against "exact transition traces".**
Section 5 allows extra states under a projection; section 7 freezes exact
traces. Both can hold only if the projection is written in terms of the section
7 transition kinds. The corpus has thirteen snapshot kinds and section 7 has
thirteen transition kinds, and a one-to-one reading is plausible: start, Leaf
for `holderMoved` and `newHolder`, Bind for `nameBound`, Choose branch for
`branchChosen`, Branch start for `branchStarts`, Match decompose for
`matchStep4Done`, Primitive result for `newCellBuilt`, Branch result for
`branchValueWorkedOut`, Handoff for `branchValueHandedOn`, Release for
`holderGivenUp` and `cellFreed` subject to C-a, and finish for `end`. The table
must be written down and run against all 27,721 snapshots by the acceptance
author before any builder starts, because if it does not fit, the compatibility
obligation changes and that is Robert's call. v2 already says stop and seek
review if infeasible; the correction is to make the check a preparation
deliverable rather than something discovered during the build.

**C-c. "There is no corpus parser" against the acceptance-owned structural
decoder.** Wording only. Say "no corpus reader in the implementation".

**C-d. "Orb resources."** D108 retired orbs. The envelope must name the actual
machine the run will use.

**C-e. The effort section restates my alternative as "reporting-only, no
preparation cap".** What I proposed was a hard cap on the builder's stages and a
reporting point rather than a stop for acceptance preparation. v2's
recommendation of a hard preparation stop with "deliver incomplete coverage and
request more time, never thin acceptance" is acceptable to me. Either is fine
provided the sentence "a cap hit never weakens checks" stays. This is Robert's
choice, Q4, and not a disagreement that matters.

### 3. Remaining ways the checks could pass while the capability fails

**R1. Overfitting to visible examples.** Every Stage B example, expected trace
and control is enumerated in advance. A builder who sees them can satisfy the
fourteen families and the extra nested cases while mishandling the fifteenth
shape nobody wrote. Stage A does not protect against this because it has no
calls. v2 has no held-out or generated Stage B layer. Fix: the acceptance author
keeps a held-out set of Stage B programs, not shown to the builder until the
candidate is delivered, and adds a generator of small call-bearing programs
checked only by generic predicates that need no predicted trace: answer equals
the immutable-value reference; outside holders and live caller values unchanged
at every committed state, which is D129; final memory exactly reachable with
correct counts at finish; physical and logical events match. Experiment 10's
safety predicate is already that shape. This closes the gap cheaply and is the
single most valuable addition to v2.

**R2. What the builder may see is unstated.** The trial kept the encoding worker
from seeing the predictions so a mismatch would be classified, not tuned away.
v2 does not say whether the builder receives the expected traces and counts.
Fix: the builder receives the English rules, the grammar, the public example
programs with their answers, and the refusal classes. The builder does not
receive the event and transition predictions, the span tables beyond the four
worked examples, the held-out set, or the control list. Record this in the
brief.

**R3. Builder-placed exhaustion injection.** "Injected resource exhaustion at
safe pre-operation checks" lets the builder pick injection points where cleanup
is trivially safe. Fix: the acceptance harness controls failure through an
allocator hook that fails the Nth managed allocation, with N chosen by
acceptance across transition kinds. v2 already disclaims operating-system
out-of-memory recovery, so this is about classification and cleanup only.

**R4. Expected binding and function identities read from the implementation.**
Section 2 says checked-tree inspection verifies binding identities. If the
expected identities come from the builder's dump, the check is circular. Fix:
acceptance computes expected resolution from the decoded tree and compares.

**R5. Stage A treatment of function declarations.** Section 3 says call-bearing
source "must not be silently accepted but unevaluated" at Stage A, but names no
refusal class. Fix: add a Stage A refusal class for declarations and calls, with
a span, so that the Stage A frontend is tested on refusing them rather than
ignoring them.

I found no other way, which is a reading and not a proof.

### 4. Blockers against optional improvements

**Blockers before the acceptance package is locked and a builder starts:**

1. Robert's choices Q1 to Q5 in section 12. These are owner decisions by
   definition. Where v2 recommends, I agree: trial-only arithmetic and Boolean
   forms, finite-list sugar, separate namespaces, exact integers for this
   prototype, full Stage A snapshot compatibility, a measurable elapsed-time
   convention with hard stage stops.
2. C-a, the Release transition split, decided in the English rules before
   predictions are written.
3. C-b, the landmark-to-transition table, written and run against all 27,721
   snapshots before the builder brief is issued.
4. R1, a held-out Stage B set and a generated-program layer under generic
   predicates.
5. R2, the builder's visibility rule recorded in the brief.
6. The resource envelope confirmed on the actual machine, C-d, since a failed
   million-depth run on an underprovisioned host is uninterpretable.

**Optional improvements, worth doing but not gating:**

- R3, acceptance-controlled allocator failure instead of builder-placed
  injection.
- R4, expected identities computed by acceptance.
- R5, a named Stage A refusal class for declarations and calls.
- A second reader predicts five of the C cases from the English rules alone.
  Disagreement between two readers is the cheapest detector of an ambiguous
  rule, and the trial found two such gaps that way.
- State in the capability sentence that `input` declarations are a test facility
  and a standalone program uses literals.
- Wording in C-c and C-e.

### 5. Answer to the question asked

Yes, v2 resolves the eight loopholes as plans. What remains is one real
contradiction, C-a, one preparation deliverable that must exist before a builder
starts, C-b, one genuine new gap, R1, and the owner choices v2 correctly leaves
to Robert. With items 1 to 6 settled, I would regard the plan as ready for
acceptance preparation to be authorized. That authorization is Robert's, not
mine.


### 2026-10-07 13:57 UTC, Robert Guss

## v3 draft incorporates Fable’s v2 blockers — still proposed/unapproved

[V3 rules and acceptance plan](https://linear.app/robert-guss/document/rob-1333-v3-proposed-rules-and-acceptance-plan-after-fable-review-244d9ffcee25) is attached separately; v2 is preserved. Read the full review comment 9719d936-9241-4312-a8ad-87ab879f2cb0.

Give up holder and Free cell are now separate proposed committed transitions. Reading the actual Lean evaluator also required exposing shared-match newHolder before holderGivenUp/matchStep4Done, and adding the post-preparation Start landmark. The thirteen-kind landmark table is written; validating every field across all 27,721 snapshots is explicitly a future acceptance-preparation deliverable BEFORE the builder brief, not a claimed run.

Added proposed held-out and generated Stage B layers (24 held-out cases and 500 generated small call-bearing cases, quantities unapproved), generic answer/protection/ownership/reachability/physical-event predicates, and a builder visibility boundary. The boundary honestly acknowledges that public v2 counts/control categories cannot be made unseen retroactively. Optional low-cost fixes: acceptance-derived resolution identities, named Stage A unsupported-form refusals, acceptance-controlled allocation failure, input declarations identified as fixtures, and wording corrections. No new reader/model layer.

All six blockers have explicit dispositions: owner choices remain pending; English split is drafted; table validation remains pending; private cases/generator are proposed but unwritten; visibility is specified; actual execution machine remains unconfirmed. Fable agreement is review, not owner semantic/effort approval. No decisions entered in the live register.

The resource envelope now requires Robert’s named actual machine; neither this orb nor his local machine is presumed. Machine inspection and later acceptance execution are separate. No executable checks, lock, implementation, test run, Fable invocation, push/merge/deployment. Saved v3 was reread for its transition table and new gates. Next blocking input: which machine should run the million-depth envelope?

### 2026-10-07 14:00 UTC, Robert Guss

Robert selected “this amp orb or a larger amp orb if you need the resources” in the acceptance thread. Updated v3 P4 with the exact environment choice and read-only inspection: this orb has a 14 GiB workload cgroup memory limit, about 16.27 GB system-available memory at inspection, 8 CPUs, and an 8 MiB process soft stack limit. Rust/Cargo 1.98.1 are available. Initial provisioning exceeds the proposed 4 GiB floor, so no larger orb is needed now. This is NOT a million-depth test result or approval of thresholds/rules/caps/acceptance execution. Recheck effective resources before any later authorized run. No executable acceptance, benchmark, lock, interpreter implementation, resizing or new thread. Parent notified to record the environment decision; live register untouched here.

### 2026-10-07 14:10 UTC, Robert Guss

## V4 scoped draft reconciliation saved — Boolean literals included

[V4: approved feature boundary, proposed acceptance details](https://linear.app/robert-guss/document/rob-1333-v4-approved-feature-boundary-proposed-acceptance-details-ce2dfeb2db09) reconciles D139, limited first-language feature-scope approval including ordinary true/false literals. V2/v3 remain preserved.

Proposed common grammar now includes true/false atoms; canonical parsed structure adds a distinct Bool node; literal execution is one Leaf with no managed-list-cell operations. Distinguishing examples cover both literal values, false versus true branch selection, binding, Bool results/parameters, whole-word identifiers, and refusals for Boolean arithmetic/equality, integer truthiness, Boolean list items and Boolean top-level inputs. No Boolean operators/equality/inputs were added to approved scope.

Historical Lean corpus/model/locks and all 27,721 snapshots remain unchanged: literals are additional source acceptance cases, not fabricated old-corpus coverage. Literal handling in the independent answer reference and generated layer is a future preparation deliverable. The Release split, landmark-validation, held-out/generated, visibility and resource gates remain intact.

The draft labels the feature boundary as approved while detailed grammar/type/name/ownership/transition/failure rules, integer policy, resource thresholds, effort caps and executable acceptance remain pending. D138, current acceptance orb/larger-orb fallback, remains target approval only. No numeric choice inferred; parent is discussing it next. Saved document reread for reconciliation consistency. No executable checks, lock, implementation, trial, new files or live-register/issue-description edits.

### 2026-10-07 14:14 UTC, Robert Guss

## V5 numeric reconciliation saved — exact prototype integers approved

[V5 draft](https://linear.app/robert-guss/document/rob-1333-v5-approved-exact-prototype-integers-proposed-acceptance-5eece5c832ec) incorporates D140, exact growing integers for this prototype only, verified against the live register/current issue note. Prior v2/v3/v4 remain unchanged.

Prototype numeric meaning is now approved, not an open recommendation: preserve mathematical answers without silent overflow/truncation/wrap. Permanent Mo numeric policy stays open; D139, limited first-language feature scope including Boolean literals, still limits arithmetic to addition/subtraction. No new operators, unlimited resources, arithmetic-latency bound or performance claim.

Wide-integer examples now illustrate the approved meaning but remain proposed acceptance cases, not executed/frozen expectations. Historical Lean/model/corpus/snapshot/lock and finite i128 accommodation records are unchanged. Detailed grammar/rules/representation, numeric resource/failure/cleanup handling, resource thresholds, effort units/caps/continuation and executable acceptance/lock/implementation/trials remain pending. Two-hour intervals have NOT been accepted.

Saved draft reread for numeric status consistency. No executable checks, lock, implementation, trial, resource workload, new files, push/merge/deployment or live-register/issue-description edits. Parent is handling preparation containment next; no competing owner question here.

### 2026-10-07 15:03 UTC, Robert Guss

Acceptance preparation stopped at D141’s reference-defect boundary (D141 authorizes deliverable-based preparation, not implementation). [V6 incomplete checkpoint](https://linear.app/robert-guss/document/rob-1333-v6-incomplete-acceptance-preparation-reference-defect-stop-f39348fa7b7e) preserves v5 and indexes the source/evidence archive attached to this issue, validated results, missing coverage and owner choices. No issue description or decision register edited.

Reference defect: v5 chooses the first lexical/syntax error in source order. `main = (1 2) @` should point to unexpected `2` at columns 11–12, but the eager reference lexer reports later `@` at 14–15; deleting `@` yields the earlier syntax error correctly. Witness saved, no repair after stop. Recommend retaining earliest-source priority rather than changing the rule to lexical-first; owner direction is needed before continuation.

Actually validated: unchanged 4,276-case corpus / all 27,721 snapshots and fields; 16 source accepts / 12 exact refusals / 21 public call cases; seven synthetic predicate-defect controls; 500 exploratory call compositions / 22,090 logical snapshots. These are preparation validations, not physical interpreter acceptance. Generated material is public exploratory evidence, not held out. Full transitions, private heldouts, candidate/physical adapter, resume/destroy/failure coverage and resource validation are still missing.

Review archive SHA-256: `0a4c54bd59423975024e774ca872727fec379cf92be629e0da7a23fe1426863f` (40,841 bytes), not a lock. Sources/evidence remain uncommitted on `acceptance/rob-1333-preparation`; no push/merge, lock, Mo implementation, Fable invocation, million-depth run or trials. Preparation cap/mandatory two-hour intervals were not adopted. Historical corpus/locks unchanged. This is an incomplete checkpoint, not a completed package or builder go-ahead.

### 2026-10-07 15:09 UTC, Robert Guss

[V7 repair/checkpoint saved](https://linear.app/robert-guss/document/rob-1333-v7-earliest-error-repair-verified-new-refusal-phase-stop-8ce62ffe648b). D142, earliest lexical/syntax priority and reference-repair continuation, is implemented in the acceptance reference: lazy token scanning prevents later lexical errors masking earlier syntax; EOF sentinel is distinguished from identifier EOF. Original `main = (1 2) @` now reports unexpected `2`, columns 11–12. All 14 independently expected mixed-error refusals plus two valid boundary cases pass. Unchanged reruns pass: 4,276 cases/27,721 snapshots, 16 source accepts/12 refusals/21 public call cases/seven synthetic controls, 500 exploratory call compositions/22,090 logical snapshots. V6 archive, original witness and public predictions byte-identical.

Continuing the proposed refusal set found a NEW priority-boundary/reference mismatch. `main = match [] do [] -> 0; [x | x] -> @ end` reports duplicate binder `x` at 34–35 during parsing, before the malformed body. V5’s proposed syntax-before-name-check ordering predicts lexical `@` at 40–41. D142 does not expressly classify duplicate binders as grammar versus name checking. Evidence/refusals-01/summary.json retains the exact first failure; other new table rows are unexecuted and not certified. Preparation stopped under D141’s new-defect boundary; no repair followed it.

One owner choice: complete lexical/syntax validation before duplicate match-binder checking (recommended, retaining v5 phase ordering), or explicitly treat binder distinctness as a grammar restriction and change that detailed priority interpretation. Final package remains incomplete: full transitions, private heldouts, resolution tables, candidate/physical adapter, pending-value expectations, resume/destroy/failure/resource coverage. New source/evidence archive attached, 63,887 bytes, SHA-256 `1069d24ac3a25cfbece1ad2f8e051d92a0b96d5654d6e8e574134c7c1351b3de`, not a lock. Local acceptance branch still uncommitted/unpushed; historical locks unchanged. No Mo implementation, Fable, trial, resource-envelope run, lock, merge or deployment.

### 2026-10-07 15:16 UTC, Robert Guss

[V8 checkpoint saved](https://linear.app/robert-guss/document/rob-1333-v8-two-stage-repair-verified-draft-prediction-defect-stop-78668472e823), exact source/evidence archive attached. D143, whole-file syntax before name/type checks, is repaired and verified: 24 independently stated phase-order cases pass, including malformed @ at 40–41 winning over duplicate binder and syntax-valid duplicate binders still refusing at 34–35. Duplicate input/parameter/function, annotation/type/body/argument mistakes paired with later lexical/syntax errors are covered. Unchanged D142 earliest-error suite (14 refusals/two accepts), historical corpus (4,276 cases/27,721 snapshots), public checks (16 accepts/12 refusals/21 call cases/seven synthetic controls), exploratory generated checks (500 cases/22,090 snapshots) pass.

Continuation exposed MY draft prediction error: `main = [] == 1` incorrectly annotates valid `1` at 14–15; integer-only equality independently identifies invalid `[]` at 8–10, which the reference correctly reports. Broader refusal run passed ten rows then stopped; remaining rows unexecuted. Original v7 row/predictions/archive and failure evidence preserved byte-identical. No correction followed this defect stop under D141, deliverable-based preparation with early defect stops. Recommend approving a versioned rule-derived correction to 8–10, retaining original error/evidence, and continuation; no semantic change is needed.

Package incomplete: full transitions/private heldouts/resolution/candidate physical adapter/pending acquisitions/resume-destroy-failure/resource coverage outstanding. Sources uncommitted/unpushed on existing acceptance branch; no Mo implementation, scientific lock, Fable, trial/resource-envelope run, merge/deployment/archive. Historical locks unchanged. Review archive (not lock) SHA256 `d6bc7f560b3f1133ffbe225b0d4f0bc7efd165ae398ed8b21d42f19537fd06c4`, 85,334 bytes.

### 2026-10-07 15:32 UTC, Robert Guss

[V9 checkpoint and source/evidence archive](https://linear.app/robert-guss/document/rob-1333-v9-span-correction-verified-trace-projection-decimal-42c676770e1b) saved; incomplete preparation, new reference-defect STOP. D144 (one approved operand-span correction) passes 12 comparison refusals/11 valid comparisons and all 24 broader refusal rows; original row/v8/failure preserved. Full frozen projection now passes: 4,276 cases, 53,796 predicted action boundaries → all 27,721 mandatory snapshots with every old field. Independent binding-value acquisition checks pass four hand schedules, 18 terminating public cases, 500 generated cases and four corrupt-first-acquisition controls.

New witness: 5,000 nines + 1 should yield 1 followed by 5,000 zeros, by decimal carry. The 1,000-digit control passes; the 5,000-digit case throws an unhandled Python 4,300-digit conversion-limit ValueError during parsing. This is an inherited reference restriction, not measured resource exhaustion or an approved language cap. Exact source/prediction/failed traceback retained. No repair or further validation after this stop.

Recommend owner approval to repair acceptance-local exact decimal input/output conversion without the inherited guard, retain the witness, validate carry/borrow/negative/output boundaries and resume D141 (deliverable-based preparation). Package still lacks private holdouts, pending/nonterminating predictions, canonical identity tables and physical/candidate/resume/destroy/failure adapters; no scientific lock or implementation readiness claimed. No register/description edits, Mo implementation, Fable invocation, resource trial, push/merge/deployment.

### 2026-10-07 16:09 UTC, Robert Guss

Acceptance preparation v10 review checkpoint saved: [rules, evidence, source export and explicit gaps](https://linear.app/robert-guss/document/rob-1333-v10-decimal-repair-verified-acceptance-preparation-review-ee15e34ec743). Under D145, bounded continuation without routine repair approvals, repaired acceptance-local decimal conversion with no Mo digit cap; 35 independently derived carry/borrow/sign/input/output cases pass at 1000/4299/4300/4301/5000 digits. Final unchanged reruns: earliest-error 14 refusals/2 accepts, phase-order 24, public 21 C-family cases, full-corpus 4276 cases/27721 exact snapshots from 53796 committed boundaries. Original v9 source/failure/predictions and historical locks remain unchanged. Additional structure/acquisition/control/private-generation/fixture/synthetic resume-destroy predicates are indexed. Native storage fresh-target cargo tests: 6 passed, including a compiled storage-replacement negative control; this is NOT a Mo evaluator control. Source/evidence export attached, SHA256 4ac412f32023800480716c8b5913c78aff45a48dd7a515b61f74623c4857a87e; private seed/cases/predictions excluded. Review stop, not accepted final executable acceptance: candidate bridge/native integration, encoding/wire checks, numeric/frame hooks, balanced coverage/heldouts and compiled Mo controls remain incomplete; actual resume/destroy/resource tests need a future candidate/authorization. Detailed semantics/formats/resource-stage limits remain proposed; no mandatory two-hour stops or adopted prep cap. No lock, Mo implementation, Fable invocation, participant/resource-envelope run, push/merge/deployment. Branch changes remain local/uncommitted. Register and issue description untouched.

### 2026-10-07 16:17 UTC, Robert Guss

Closeout resumed on acceptance/rob-1333-preparation versus unchanged origin/main baseline, then stopped at a substantive encoding-priority boundary before inventing an expectation. V5/v10 say invalid source encoding reports byte offsets; D142 (earliest lexical/syntax source error) and D143 (whole-file syntax before name/type) do not explicitly classify invalid encoding as part of that priority sequence versus a whole-file input prerequisite. Distinguishing source bytes: ASCII `main = (1 2) ` followed by 0xff; hex `6d61696e203d20283120322920ff`. Independently, unexpected second numeral is columns 11–12; invalid UTF-8 byte is zero-based half-open offsets 13–14. Inspected separately: strict Python UTF-8 decoding fails at 13–14; parsing the valid prefix reports syntax offsets 10–11 (= columns 11–12). No combined policy or accepted expectation implemented. Witness retained in experiments/13-source-acceptance/evidence/encoding-priority-01/counterexample.json; JSON validation passes. It is new local evidence, not included retroactively in unchanged v10 export. Specific owner choice: should invalid UTF-8 participate in earliest lexical/syntax source order (recommended: earlier unexpected 2 wins), or should whole-file valid encoding be a prerequisite (later invalid byte wins)? Recommendation preserves the approved earliest-source principle; alternative simplifies decoding but needs an explicit diagnostic-priority exception. This is a language diagnostic choice, not routine reference repair permission. Remaining bounded coverage/wire/fault/bridge closeout is not claimed complete; no targets expanded, semantics adopted, lock, builder, stage/resource execution, Fable, push/merge/deployment. Register and issue description untouched.

### 2026-10-07 18:03 UTC, Robert Guss

[V11 candidate-independent closeout saved for final review](https://linear.app/robert-guss/document/rob-1333-v11-candidate-independent-closeout-evidence-and-remaining-a7a30569a722), with attached exact source/evidence export (SHA256 e169c9957fbb2440092e74a298a90709102d90628150f5c10fcf9c17e23378b1, 2,170,046 bytes; private cases excluded). D146, invalid encoding in earliest-source ordering, reconciled: unexpected 2 at columns 11–12 wins over later ff at bytes 13–14; 12 encoding cases/nine public byte records/seven bad outputs pass. Existing bounded layer: 24 balanced private heldouts + 500 generated (404 distinct/96 repeats, retained honestly), unchanged fingerprint. Full frozen projection rerun passes 4,276 cases/27,721 snapshots/53,796 boundaries, no omitted fields. Decimal 35 cases pass beyond 4,300 digits. Native Rust storage tests 7/7 and formatting pass; actual Number/Frame denial gates and native full-state bridge are exercised with scripted records, NOT a compiled evaluator. Bridge rejects six controls; fault checks reject twelve; 31 compiled evaluator control obligations have named target predicates, while 163 preparation record controls are synthetic. Final public/refusal/phase/comparison/acquisition/control/observation/fixture/cleanup regressions pass. Routine sorting/helper-shadowing/type-equality defects and old failures retained; expectations not copied from observed output. Requirement→independent expectation→predicate→awaited candidate capability table and six substantive review topics consolidated: detailed language; ownership/transitions; observer/failure formats; coverage/privacy/duplicates; resource streaming/envelope; effort/caps/stages. Stop for review under D141, deliverable-based preparation, and D145, consistent routine repairs: candidate-linked execution, actual resume/destroy/failure, compiled evaluator mutants and actual machine/resource checks remain unrun. No accepted lock, Mo implementation, Fable invocation, stage/resource/trial, push/merge/deployment. Local acceptance branch remains uncommitted/unpushed versus origin/main; prior versions/historical locks unchanged. Register/issue description untouched; parent owns whole-project audit.

### 2026-10-07 18:54 UTC, Robert Guss

[FINAL consolidated review v12 published](https://linear.app/robert-guss/document/rob-1333-final-review-v12-reconciled-approvals-exact-brief-index-and-c681019c6c75). Exact FINAL archive attachment bb6f7033-a4cd-47d5-a63a-107d2e3cc6df, SHA256 6fd025a6174354bf162556f2567ba13c735f8a17483e475649ec6405dbd51c77, 2,183,211 bytes; supersedes intermediate v12 attachment 9ab94697. Includes exact proposed BUILDER_BRIEF.md (22,034 bytes; SHA256 abf61e6bea97f63eeca1680b26b8727fa88eaabac45b68ab524d327f8c998bb9), approved-versus-proposed D147–D152 reconciliation, candidate-independent acceptance index, inclusive resource timing/cleanup-count convention, public/private inventory and explicit unfinished executable gate. Hour caps removed from current recommendation; arbitrary implementation-hour caps deferred. Typed check_source distinguishes source refusal from frontend resource failure; host formats pre-run refused/failed/invalid-fixture, candidate public_output only handles Run. Number owned-read/copy routing is explicit but PROPOSED, existing expectations unchanged. Ready for document review, NOT freeze-ready executable acceptance or builder dispatch: sanitized runtime-only dependency, host same-store fixture install/rollback, interface/formatter/callback collector, span/birth/call/failure/cleanup schema extensions, native streaming cursors and clock/counter provenance remain acceptance-owned bounded preparation. Signatures do not deliver a usable dependency; no split/link changes silently made. Actual candidate physical resume/destroy/failure, compiled evaluator controls and resource checks also remain unrun. Byte comparison retained all 183 non-document files unchanged versus v11; previous versions/private fingerprints/historical locks preserved. Only README/PROTOCOL reconciled and BUILDER_BRIEF documentation added; no tests/code/expectation changes/new experiments/framework/lock/builder/Fable/stage/resource/push/merge/deployment/archive. Parent handles exact/conditional owner authorization; no separate approval question raised. Work remains local uncommitted acceptance branch versus unchanged origin/main; register/description untouched.

### 2026-10-07 20:07 UTC, Robert Guss

## Acceptance integration stopped on a concrete v12 interface discrepancy

D153 (exact v12 approval and conditional integration/review/freeze/isolation/Stage A) authorizes bounded integration but requires stopping for substantive contract discrepancies. This is not a routine reference-output correction.

**Missing information:** `begin(program, inputs, cells)` receives no outside roots; RuntimeCells exposes individual cells but no outside-root list. Candidate snapshots nevertheless require ordered `state.outside`. Source `input xs: ListInt; main = xs`, input xs=cell9, cells 9=(37,tail2,holders2), 2=(-4,nil,holders2) admits two valid outside lists `[9,2]` and `[2,9]`. Both fixtures pass unchanged Python validation and actual native installation. Runtime reads are identical; unchanged logical reference snapshots require different outside ordering. A compliant candidate cannot infer which list to report.

Qualification: all 4,276 historical fixtures were inspected; none contains multiple outside roots or outside-only cells. This is a discrepancy in the approved interface/valid-fixture contract, not a claimed historical regression. No API repair, new expected-output tuning, or criteria weakening was applied. Parent review must resolve evidence-field ownership versus an amended context interface. I recommend keeping external-root/full-native fields acceptance-owned with explicit candidate-report/readback obligations, rather than revealing fixture/outside provenance; that recommendation is not adopted.

**Saved review checkpoint:** [source, status, witness and validation archive](https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/06097edb-a7e3-41ee-bd2a-c55cdce6d3f1/43242061-91d1-434f-b712-08540db539f5), 27,578 bytes, SHA256 `8eda83d24c9cd35b32593313af9c52faa474473ed85a5a9767e3d08372475d4f`. This is an acceptance-review overlay on FINAL v12, NOT builder delivery or a replacement contract. Read `INTEGRATION.md`; exact witness is `evidence/integration-01/contract-witness.json`; native witness test is `cells/host.rs::approved_begin_omits_outside_order_required_by_snapshot`.

**Validated partial work:** `cargo test --locked --manifest-path cells/Cargo.toml`: 12 passed (seven unchanged original tests plus same-store install/rollback, gate/cursor/phase/lifetime checks and witness). `cargo test --locked --manifest-path driver/Cargo.toml`: one formatter test, four independently specified exact outputs. Public runtime operations compile; six forbidden-access probes reject Observer, fixture, constructor, private handle, event reader and deny control. Existing bridge regression: native stub and six rejection controls pass. Existing wire regression: 12 encoding cases, 9 outputs, 7 rejection controls pass. All detailed logs are in the archive.

**Incomplete:** generic collector compiles but is not callback-stub validated; fixture/name/type adapter, strict schema/birth/call/failure/cleanup normalization, incremental full-state bridge, process-inclusive timing/counter supervisor and sanitized delivery assembly remain unfinished. Internal collector timing is not the approved launch-through-cleanup watchdog. Actual candidate evaluation, physical resume/destroy/failure cuts, compiled evaluator controls and resource execution remain unrun.

**Isolation:** Rust API compile probes are not filesystem/context/tool isolation. A new same-account orb may still retrieve owner materials through Linear, read_thread, download or librarian routes. Proposed verification is a fingerprinted builder allowlist plus clean context/filesystem and actual denied-access checks for tool/account/network routes. Hard access restriction is not established; parent is investigating supported configuration. No plugin/security framework/account changes or relaxation of privacy criteria.

FINAL v12 archive/brief/protocol/index and private-corpus hashes remain unchanged; original archived files changed only in cells/Cargo.toml, cells/lib.rs and its dependency lock. Work remains local/uncommitted on acceptance/rob-1333-preparation; origin/main is unchanged. No scientific lock, builder, stage/resource run, push/merge/deploy. Effort checkpoint records one contributor from 19:52:44Z through 20:06:53Z = 849 seconds; publication/reporting continues until final stop, earlier preparation and initial unmeasured authorization read remain unknown. Thread stays unarchived.

### 2026-10-07 20:11 UTC, Robert Guss

Parent review of integration checkpoint: downloaded the exact review-only archive and verified SHA256 8eda83d24c9cd35b32593313af9c52faa474473ed85a5a9767e3d08372475d4f. Read INTEGRATION.md, witness, public capability and approved brief. Independently rebuilt/reran cargo test --locked for cells (12/12 pass, including missing-outside-order witness) and driver (1/1 formatter test passes). First targeted --exact invocation selected zero tests; the subsequent full suite executed the witness. No reference/private corpus transfer, expectation edits, freeze or builder start. The outside-order conflict is real: approved begin cannot distinguish two required reports. Recommend acceptance-owned external-root/full-native fields, retaining candidate execution reporting, physical comparisons and outside protection; exact amendment remains for Robert, not adopted. Separate isolation limitation: same-account tools retain retrieval paths; clean context plus prohibited-access instructions cannot be called verified hard isolation. Official tool/configuration inspection found no per-thread orb allowlist available through current tools. Oracle recommends clarifying procedural non-exposure versus unavailable retrieval paths, without inventing security machinery. These are substantive gates; no scope change recorded as approved. Integration remains incomplete/local/uncommitted, not freeze-ready.

### 2026-10-07 20:57 UTC, Robert Guss

Robert approved the external-memory reporting correction, recorded as D154 (acceptance-owned external-root and independently observed physical-memory reporting). The separate acceptance author may version the contract/interface and continue bounded integration, preserving candidate execution-state/readback duties and every existing independent physical/outside-protection check. Original v12 and counterexample retained. D153's conditional review/freeze/isolation/Stage A sequence remains; tool/Linear isolation is separately unresolved, not waived. No builder start or lock yet.

### 2026-10-07 21:19 UTC, Robert Guss

Robert approved procedural builder separation for Stage A, recorded as D155: fresh clean context/files, approved sanitized artifacts only, explicit prohibition on retrieving excluded acceptance material, and recorded tool-use checks. Same-account access remains technically available; no hard-isolation claim or security framework. Integration/review/freeze prerequisites and separate acceptance authorship remain. No Mo builder has started.

### 2026-10-07 21:37 UTC, Robert Guss

Stage A small-case acceptance integration delivered for parent review: [review index](https://linear.app/robert-guss/document/rob-1333-integration-v13-stage-a-small-case-review-sanitized-delivery-75b99e40ae59). Not a freeze or dispatch.

Final validation: native cells 13/13; driver 2/2; integration-05 has 23 native fixture-stub successes, 49 rejected controls, 545 unchanged reference comparisons. Unchanged historical regression: 4,276 cases / 27,721 snapshots / 53,796 transitions. Both parent findings were reproduced before repair, preserved, and rejected afterward: ignored frontend Number denial cannot become invalid-fixture; required arrays reject objects/strings. Parent independently confirmed these two repairs against the 27,636-byte integration.py snapshot; final SHA256 e67505cd6174ad469c85df87eca2bd58671597b8411d16e361adb854b0f932bb.

Sanitized public archive: 18,017 bytes, SHA256 80343fc7be0171f1ed133de786ea10f1b25e5dca70ebff24fe5defa54712ea2d, attachment 9b5373c8-8023-4be0-be02-abfce04a5eea. Clean Rust 1.98.1 build and all seven API probes passed their expected outcomes. Separate REVIEW-ONLY archive: 2,536,049 bytes, SHA256 65083e8e5738abd74b3c77124553efbac6dddde2b421aa51315dde47f9148763, attachment c5ad4306-e80f-41ed-8687-25e6c52f776f. Exact paths/source hashes and evidence index are in the document and archive manifest. Private corpus/seed excluded; fixed predictions and original v12 retained.

Remaining: parent exact review and scientific freeze; actual fresh-context/allowlisted delivery/prohibited-retrieval and recorded-tool-use checks under D155 (procedural Stage A separation, same-account access technically remains); future candidate linkage/source-routing inspection/real resume-destroy-failure cuts/compiled evaluator controls. **Large streaming adapter is still unimplemented**, not merely unrun: linked.py uses large=false and Verifier requires full small traces. Rust scheduling/cursors/cap tests are not a resource-readiness claim. Stage B/resource execution remains separately gated. No interpreter, freeze, dispatch, push, merge, deployment or archival.

Final measured contribution through 2026-10-07T21:36:48Z: resumed interval 2,333 seconds + prior 935 = 3,268 recorded seconds; earlier preparation unknown; stopped interval excluded. All builds/test/publication waits through that timestamp included; final notification-tool latency afterward unmeasured. Detached final ledger evidence/integration-delivery/effort-delivery.json supplements the archive checkpoint without changing either archive. Local acceptance/rob-1333-preparation remains uncommitted at unchanged origin/main baseline; parent checkout receives no edits. Stopping for parent review, unarchived.

### 2026-10-07 21:43 UTC, Robert Guss

Delivered documentation-only v14 amendment: [review index](https://linear.app/robert-guss/document/rob-1333-v14-public-handoff-amendment-exact-checked-dump-keys-no-291025dfded3). Exact normative checked-dump table now specifies node discriminator and every Program/expression/declaration/function/match-binder key set and omissions. Only BUILDER_HANDOFF.md changed; BUILDER_CHECKED_DUMP_V14.md added. All executable sources, checks and predictions unchanged; both v13 archives preserved.

Sanitized public v14 archive:19,610 bytes, SHA256 3327ee87f52316bec571f91c81b20f556f030614d41a681699a6cdc8f49c94de, attachment f67bfb70-96c8-4568-a10e-43d4438cf9bc. Nine source/doc files plus DELIVERY.sha256. Field-key table matched2,156 objects from existing21public examples; Eq/Lt checked directly against unchanged canonical source because absent in those examples. Clean runtime cargo +1.98.1 check --locked passes. No new acceptance campaign/check edits. Awaiting parent review, no freeze/dispatch. Large streaming and later candidate/resource gates unchanged. Cumulative measured effort3,432 seconds; earlier unknown, stopped periods excluded; final notification latency unmeasured.

### 2026-10-07 21:45 UTC, Robert Guss

Parent Stage A review complete for v13 executable package plus v14 public documentation amendment. Verified reviewer archive SHA256 65083e8e5738abd74b3c77124553efbac6dddde2b421aa51315dde47f9148763 and all489 listed hashes; original v12 differs only in the three reviewed cells crate files. Verified v14 public archive 3327ee87f52316bec571f91c81b20f556f030614d41a681699a6cdc8f49c94de and all nine public document/runtime fingerprints. Read exact supplemental execution/field contracts against unchanged reference and canonical structure. No unresolved Stage A review finding remains.

Fresh parent validation: cargo +1.98.1 test --locked storage13/13 and driver2/2; clean public runtime check; corpus_tracecheck4276 cases/27721 snapshots/53796 transitions;19 real native-stub runs and4 compiled bad-stub controls rejected. Independently reproduced and verified both repaired defects (ignored frontend denial and nonarray containers). Acceptance author's complete integration evidence reports23 stub successes/49 rejection controls/545 reference regressions; private524 rows remained acceptance-local and were not rerun by parent. These are preparation/stub checks, not Mo acceptance.

Proceed under D153 (conditional integration/review/freeze/Stage A authorization), D154 (acceptance-owned external-memory reporting), D155 (procedural builder separation). Freeze reviewed Stage A requirements/checks/interfaces before builder start; then verify clean public-only builder delivery. Stage B/resource adapter remains explicitly unfinished and needs separate preparation/review/authorization; no scalable or million-depth claim. No criterion weakened, no new owner decision inferred, no builder started yet.

### 2026-10-07 21:52 UTC, Robert Guss

Stage A scientific freeze completed and acceptance branch pushed, not merged. [Exact commit](https://github.com/robertguss/mo-v2/commit/1f418931c6fef6dc14686aad4c9559e508951b7c).

[Scientific lock](https://github.com/robertguss/mo-v2/blob/1f418931c6fef6dc14686aad4c9559e508951b7c/experiments/13-source-acceptance/STAGE_A_LOCK.json), SHA256 09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e. [Readable freeze scope](https://github.com/robertguss/mo-v2/blob/1f418931c6fef6dc14686aad4c9559e508951b7c/experiments/13-source-acceptance/STAGE_A_LOCK.md), SHA256 145a5eeb87a812615e86dbacf9ac7288fee0542b86b51faad252aa061c87a175. [Freeze verification](https://github.com/robertguss/mo-v2/blob/1f418931c6fef6dc14686aad4c9559e508951b7c/experiments/13-source-acceptance/evidence/stage-a-freeze/validation.json), SHA256 53b707581e11fd706865aa1e4ed97810d934564c4dba37706c3e0a94dbcdb517.

Verified 496 frozen-file hashes, five historical dependencies, all 489 archived v13 review fingerprints, four unchanged archives and nine exact current public content fingerprints. The reviewed v14 handoff replacement is explicit; prior manifests/evidence remain unchanged. The lock retains 31 fixed evaluator-control obligations and only the private corpus fingerprint/counts, not private contents or seed. Exact staged/indexed/committed inventory: 498 owned paths; compressed evidence included in privacy inspection; no private seed/fixed private sources, private data files, build caches, symlinks, credential-pattern matches or unrelated paths in publication. No executable edits or new campaign during freeze.

Only builder delivery remains rob-1333-stage-a-public-v14.tar.gz, 19,610 bytes, SHA256 3327ee87f52316bec571f91c81b20f556f030614d41a681699a6cdc8f49c94de, unchanged: five documents, four runtime files, DELIVERY.sha256. The acceptance branch/lock/review archives must not enter builder context.

Remote refs/heads/acceptance/rob-1333-preparation verified equal to the exact commit; origin/main remains at the [unchanged baseline](https://github.com/robertguss/mo-v2/commit/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3); local worktree clean. No merge, PR, deployment, Mo implementation, builder dispatch or archival.

Remaining: parent fresh-context/public-only delivery, prohibited-retrieval instructions and recorded-access verification under D155 (procedural Stage A separation; same-account retrieval remains technically available). Actual candidate linkage, source/allocation-routing review, original-source historical comparisons, small-case resume/destroy/failure cuts and evaluator controls remain unrun. Stage B and unfinished large streaming adapter/resource work stay separately gated; no scalability or million-depth claim.

Effort: freeze interval 21:45:30Z–21:51:59Z = 389 contributor seconds, including tool/verification/commit/push waits; cumulative measured 3,821 seconds. Earlier preparation unknown; stopped periods excluded. Final notification latency after this timestamp unmeasured. Acceptance thread remains stopped/unarchived for future candidate acceptance.

### 2026-10-07 22:01 UTC, Robert Guss

Builder preflight and recorded-access review passed; Stage A was explicitly dispatched to the fresh no-project thread. Before writing candidate code, the builder identified an omitted public definition of stage-unsupported spans and diagnostic precedence. It paused without selecting behavior or retrieving excluded material. Acceptance author is preparing only a faithful public clarification of the already-frozen contract, with original lock/checks/expectations unchanged; parent will review it before delivery. No new owner choice or candidate implementation is claimed.

### 2026-10-07 22:02 UTC, Robert Guss

Public Stage A diagnostic disclosure clarification v15 is ready for parent review; builder remains paused. No new policy or contradiction found. Documents first function declaration after input checks, declaration/call full spans including direct grouping, and exact fail-fast semantic traversal: calls refuse on encounter before callee/arguments, not through a global unsupported pre-scan.

Acceptance workspace addendum: experiments/13-source-acceptance/BUILDER_STAGE_A_DIAGNOSTICS_V15.md, SHA256 c0d44cf9869ad1a1b93dd5b5d74f21ca7ecde5e2a051d8ea585d794d3e8528fa. Public-only archive .amp/in/artifacts/rob-1333-stage-a-public-v15.tar.gz:21,271 bytes; SHA256 fa7969d102fb1607b81059522307982e5aa180ed509bbb4fc9ad3d588070a898. Its11regular members are the unchanged9v14content files, one new addendum and regenerated DELIVERY.sha256. No acceptance code, cases, span examples, predictions or private material added.

Public update metadata: experiments/13-source-acceptance/evidence/public-stage-a-v15/public-update.json, SHA256 7e778a732e2ed5923bc31b868b0920a2c9475904e904895f364506bd84829733. Separate review-only validation metadata: same directory summary.json, SHA256 29fffe04c64531cb0a1bcbb9dc17bcb3cdb2209ca50268761fa54c1f5e81abdd. Parent can download these exact files from the [acceptance thread](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55).

Validation: existing2StageA annotated refusal checks rerun and pass unchanged; traversal/precedence/grouping spans inspected directly against frozen requirements/source, no new language cases/campaign. All496locked files/five historical dependencies/four prior archives and original scientific lock unchanged. New documentation/metadata remain local and uncommitted pending parent review; no scientific re-freeze, Mo code, resource work or private transfer. Parent reviews and decides delivery/resume; no separate owner semantic choice required by this correction.

Recorded interval21:59:59Z–22:02:35Z=156contributor seconds; cumulative3977seconds. Earlier preparation unknown, stopped intervals excluded; final notification latency unmeasured.

### 2026-10-07 22:04 UTC, Robert Guss

Parent review of public clarification v15 passed. Full document compared with frozen parser/checker: input checks precede the first whole-declaration Stage A refusal; calls refuse on their whole grouped expression at semantic encounter, with no global call pre-scan. This discloses existing semantics, not a new owner decision or changed criteria.

Independently checked archive SHA256 fa7969d102fb1607b81059522307982e5aa180ed509bbb4fc9ad3d588070a898, all manifest entries, exactly one added public document and nine byte-identical original content files. Delivered only the 21,271-byte public archive to the existing builder; instructed it to verify/read and resume its existing Stage A authorization. No reference/prediction/private/reviewer material delivered. Builder resumption confirmation is pending; no candidate acceptance claimed.

Acceptance author asked to commit/push only the reviewed documentation amendment and separate metadata under the standing post-review instruction, preserving the original lock and files. Parent worktree remains clean. Stage B, resource workloads, merge/release/deployment remain unauthorized.

### 2026-10-07 22:05 UTC, Robert Guss

Reviewed public v15 clarification and its two separate metadata files are committed and pushed on acceptance/rob-1333-preparation: [commit](https://github.com/robertguss/mo-v2/commit/3ae95b6d8070c61fc954bee16ce5f7237dc30d3c). [Commit-pinned public clarification](https://github.com/robertguss/mo-v2/blob/3ae95b6d8070c61fc954bee16ce5f7237dc30d3c/experiments/13-source-acceptance/BUILDER_STAGE_A_DIAGNOSTICS_V15.md). Addendum SHA256 c0d44cf9869ad1a1b93dd5b5d74f21ca7ecde5e2a051d8ea585d794d3e8528fa.

Verified exact remote branch tip, clean worktree, precisely three reviewed additions, all496frozen hashes and five historical dependencies unchanged. Original scientific lock SHA256 remains 09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e; all prior archives and public v15 archive unchanged. git diff --cached --check passed. origin/main unchanged. No executable edits, new scientific checks, Mo implementation, merge, Stage B or resource run.

Parent completed independent review and public-only delivery/resumption; old metadata retains its pre-review checkpoint wording. Acceptance author remains available separately for the future candidate. Recorded66contributor seconds through22:05:02Z, cumulative4043seconds; earlier preparation unknown, stopped intervals excluded, final notification latency unmeasured.

### 2026-10-07 22:17 UTC, Robert Guss

Stage A paused on a public native-method contract omission, not a candidate acceptance failure. Builder preserved a partial implementation and reports check/test/clippy/fmt passing with 14 self-authored development tests; linked execution, ownership/reuse, runtime denial, resume and destroy are not verified. Parent downloaded the partial checkpoint and independently verified archive SHA256 e68b5c01dfff2029036b5c63e66ee7de1736adb77eecc858d8f36e2c8fa244ac and all seven content fingerprints. No candidate code imported into the parent repository or accepted.

Public RuntimeCells signatures omit exact detach/write/metadata/free effects and denial/event behavior. Parent inspected the frozen native implementation and asked the acceptance author for a separately versioned public normative method supplement, distinguishing enforced API preconditions from existing evaluator ownership obligations. Frozen criteria/lock, original archives and separation remain unchanged. Builder remains paused pending parent review and public-only delivery; no new owner choice identified so far.

Recorded builder contributor elapsed: 12m55s; current stopped interval began 2026-10-07T22:16:11Z. No Stage B/resource run, merge or deployment.

### 2026-10-07 22:21 UTC, Robert Guss

Public runtime-method supplement v16 is ready for parent review; builder remains paused. No new policy or conflict found. It documents all seven RuntimeCells operations, native preconditions versus evaluator obligations, exact field effects, counted events versus bookkeeping/attempt observations, controlled denial and closure behavior, Number-copy routing, allocation identity, and the existing stronger committed-action failure-preservation requirement. No candidate algorithm or host-OOM guarantee introduced.

Addendum: experiments/13-source-acceptance/BUILDER_RUNTIME_METHODS_V16.md, SHA256 e0e866953b4fbf3af4f5af6f238c7663902b70a4ca4f7976d1d39ad9c0221938.
Public archive: .amp/in/artifacts/rob-1333-stage-a-public-v16.tar.gz, 24,605 bytes, SHA256 52ee52f3304f80c23c7f7b60c323491e97cb9961d7a2eb44e2700832d18ddc1c. Exactly12 regular members: ten unchanged v15 content files, this one new document, regenerated DELIVERY.sha256. No host code, tests/cases, predictions, private data or review metadata added to builder delivery.
Public update metadata: experiments/13-source-acceptance/evidence/public-runtime-v16/public-update.json, SHA256 d9c2323a5203bbaa6e0b0bb6c2ede3dbfe6e164536911a12f8811f8731b1bbda.
Separate REVIEW-ONLY summary.json in that directory: SHA256 c2fe8fa2e9b076ff1663f63f884f8ec7f8e49dde3696d2f2c5c2765af1ea22bb. Download exact files from the acceptance thread for review; no direct builder delivery performed here.

Validation was source inspection plus fingerprint/member checks, not a new runtime campaign. Original scientific lock, all496 frozen files, five historical dependencies and five prior archives unchanged; all ten prior public content fingerprints match. No private files opened/transferred or candidate inspection. Three new document/metadata files remain local/uncommitted pending parent review; no Mo implementation, criteria edit, merge, Stage B or resource run.

Recorded interval22:17:23Z–22:20:42Z=199contributor seconds; cumulative4242seconds. Earlier preparation unknown, stopped periods excluded, final notification latency unmeasured.

### 2026-10-07 22:22 UTC, Robert Guss

Parent review of RuntimeCells clarification v16 passed. Compared all seven method contracts with frozen native/runtime code and existing public ownership/routing/failure requirements; no new policy or changed acceptance criteria found. In particular detach/metadata are bookkeeping, not counted writes; tail holder changes remain evaluator-owned; only create and Number/Frame gates have injected denial; no native multi-operation transaction replaces last-commit preservation.

Independently verified the public archive (24,605 bytes, SHA256 52ee52f3304f80c23c7f7b60c323491e97cb9961d7a2eb44e2700832d18ddc1c), exact twelve-file inventory, all eleven manifest entries and ten byte-identical prior content files. Only this public archive was delivered to the existing builder, with authorization to verify/read and resume existing Stage A scope. Builder confirmation pending; no linked candidate acceptance claimed.

Acceptance author asked to commit/push the three reviewed new document/metadata paths under the standing post-review instruction, preserving frozen files/lock and prior archives. Parent worktree clean. No Stage B/resource run, merge, release or deployment authorized.

### 2026-10-07 22:23 UTC, Robert Guss

Reviewed v16 method-contract supplement and its two metadata files are committed and pushed on acceptance/rob-1333-preparation: [commit](https://github.com/robertguss/mo-v2/commit/02b837fae7116fd721a9bcb7f197f41404d989af). [Commit-pinned public clarification](https://github.com/robertguss/mo-v2/blob/02b837fae7116fd721a9bcb7f197f41404d989af/experiments/13-source-acceptance/BUILDER_RUNTIME_METHODS_V16.md). Addendum SHA256 e0e866953b4fbf3af4f5af6f238c7663902b70a4ca4f7976d1d39ad9c0221938.

Verification: remote tip matches; clean worktree; exactly three reviewed named paths added. All 496 frozen hashes and five historical dependencies match. Scientific lock SHA256 remains 09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e. All six retained archives, including public v16, remain unchanged; v16 has exactly 12 regular members and 11 matching content hashes. git diff --cached --check passed. origin/main unchanged.

Parent performed review and public-only builder delivery/resumption; retained metadata describes its earlier review checkpoint. No executable changes, criterion changes, new campaign, Mo implementation, merge, deployment, Stage B or resource run. Acceptance context remains available and unarchived for the future candidate.

Recorded 28 contributor seconds through 22:22:52Z; cumulative 4,270 seconds. Earlier preparation unknown, stopped intervals excluded; final notification latency unmeasured.

### 2026-10-07 22:35 UTC, Robert Guss

First Stage A candidate received and dispatched for independent acceptance. Export mo_stage_a::StageA, crate mo-stage-a. Parent verified final-01 archive SHA256 22ab6d216977176e34859d5101f1783fa8523058baf46cdf1bf4175a1f4ec002 (24,780 bytes), exact eight-file inventory and all seven content hashes. Exact archive transferred to the separate acceptance author; not applied to parent local main or origin/main.

Builder reports check/test/clippy/fmt pass, 25 development tests including same-executor scalar/empty-list and simulated Number/Frame denial coverage. No native cell mock/constructor; native linked ownership/reuse/outside protection, cell denial and destruction remain independently unverified. Recorded post-v16 access audit found no excluded retrieval, provided-file mutation, new thread or Stage B/resource workload; procedural compliance, not technical isolation.

Acceptance author authorized under the existing Stage A scope to verify frozen hashes, link the exact candidate without editing accepting files, inspect source/allocation routing and run applicable existing small-case comparisons/cuts/controls. Stop at first material discrepancy and preserve evidence; do not repair candidate, change frozen criteria or reveal private material to builder. Builder remains stopped pending results. No acceptance pass, Stage B/resource authorization, merge or deployment.

Builder effort: 23m42s active including packaging/transfer; 11m59s clarification pauses excluded. Current candidate handoff UTC 2026-10-07T22:33:03Z.

### 2026-10-07 22:42 UTC, Robert Guss

First Stage A submission: stopped at the first material discrepancy; NOT accepted. No criteria or candidate edits.

Exact submitted archive: rob1333-stage-a-candidate-final-01.tar.gz, 24,780 bytes, SHA256 22ab6d216977176e34859d5101f1783fa8523058baf46cdf1bf4175a1f4ec002. Separate generic linkage built with Rust 1.98.1 against frozen native storage/driver. Submitted registry versions/checksums match the generated link lock.

Executed unchanged historical source comparison via candidate-runs/stage-a-01/run_historical.py: exit 1 on first case original-1, Leaf step 3, integration.Verifier.prefix assertion 'full committed execution/physical state'. Initial/frontend/fixture/begin and two commits passed; zero complete historical cases. Saved-state comparison differs only in control: candidate removes current child and places its value in parent operands before the child's callback. Physical graph, holder state, ready and event prefix agree at the rejected boundary. This is a candidate committed-state/reporting defect against the frozen boundary, not evidence of a bad final answer or memory corruption.

Offending candidate source: execution.rs:628-635 (produce), 859-861 (Leaf call), 316-345 (publication); lib.rs:48-52 (callback). Public-safe repair routing: align control/ready/site at the existing committed action boundary. Do not send the historical input, expected state, checker or host code to the builder.

Review evidence is local/uncommitted under experiments/13-source-acceptance/candidate-runs/stage-a-01/: RESULT.md (SHA256 11eb954d31f9dbf5b5cc6041b85fd7210b68829cd7e9fd12847566026c41f8a4), current-input.json, historical-command.txt, historical-0000/rows.jsonl, comparison.json, preservation.json; EVIDENCE.sha256 (6535c55d031ec90382c8cc35988683c7e3fd57cd32e35f30b08628dc0ba2c5f1) verifies all 24 files. The run was terminated at rejection; later completion/cleanup is not claimed.

Preservation: eight candidate files, all 496 frozen fingerprints, five historical dependencies and six prior archives pass. Scientific lock remains 09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e. Tracked worktree unchanged. Partial source routing review only. Remaining historical/frontend/numeric tests, substantive reuse/outside coverage, resume/destroy/failure cuts, full allocation/atomicity review and applicable evaluator controls remain unrun. Private corpus was not opened/run/transferred. No Stage B/resources, candidate repair, merge or deployment.

Effort recorded through 2026-10-07T22:42:17Z: 413 seconds this attempt including waits; 4,683 cumulative recorded contributor seconds; earlier unknown remains unknown. Later notification overhead is unmeasured. Parent review/repair routing is next; acceptance stays stopped and thread unarchived.

### 2026-10-07 22:44 UTC, Robert Guss

Parent verified the first Stage A rejection against preserved RESULT/comparison fingerprints, submitted source and existing public execution contract. Only committed control state differs at the rejected Leaf boundary: produce removes the current child and fills the parent before the child's callback. Native graph/holders/ready/event prefix agree there; no final-answer or physical-memory failure is established. Zero historical cases completed; later obligations remain unrun.

Routed a public-safe repair brief to the original builder, naming only its own produce/Leaf/publication/callback locations and BUILDER_EXECUTION.md:91–105. No acceptance input, expected state, private case, checker, host implementation or evidence bundle delivered. Authorized coherent boundary/resume repair and development verification under existing Stage A scope, with a separately numbered next archive. No new owner decision or modified criteria.

Acceptance author retains submission 01 and exact failed native-run/linkage evidence unchanged and waits for the next submission. No acceptance pass, Stage B/resource run, merge or deployment.

### 2026-10-07 22:49 UTC, Robert Guss

Submission final-02 verified and sent for independent frozen Stage A checking. Archive 26,454 bytes, SHA256 7332eaad9ade0984b68a97a97e638dd339e69660340b8b9fd99e61b3067644a4; exact eight files and seven content hashes pass. Parent diff confirms only execution.rs, HANDOFF and manifest changed from final-01. Producing context is retained through publication, with result transfer staged inside the next existing action; no added committed transition or native-operation change.

Recorded repair audit verifies two development boundary tests failed before the production fix, then all 27 development tests plus check/clippy/fmt passed. No excluded retrieval, supplied-file modification or scope breach recorded. These do not establish native acceptance.

Exact candidate delivered to acceptance author for separate stage-a-02 evidence, first checking original rejection and continuing applicable existing checks only if it passes. Preserve submission 01/failure evidence; frozen criteria remain unchanged. Builder stopped pending results. No candidate integrated into main, no Stage B/resource run or merge/deployment. Builder cumulative active effort 26m43s, stopped intervals excluded.

### 2026-10-07 22:54 UTC, Robert Guss

Stage A submission 02: original Leaf-control failure resolved, then stopped at first new discrepancy. NOT accepted; zero complete historical cases.

Verified exact archive rob1333-stage-a-candidate-final-02.tar.gz, 26,454 bytes, SHA256 7332eaad9ade0984b68a97a97e638dd339e69660340b8b9fd99e61b3067644a4. Separate native linkage built successfully with Rust 1.98.1, --locked --offline; submitted registry versions/checksums preserved.

Command: PYTHONDONTWRITEBYTECODE=1 python3 experiments/13-source-acceptance/candidate-runs/stage-a-02/run_historical.py. Exit 1, original-1, Choose branch step 4, 'birth coverage'. Steps 1–3 passed, including the previously failing Leaf. Candidate execution stopped immediately. Replay of eight saved records confirms all already-mappable execution/physical fields and extended event prefix agree at step 4; only branch birth prefix differs.

Candidate execution.rs:1005–1011 adds branch identity before returning Choose branch at 1021. Frozen finite_reference.py commits Choose branch at 217 and creates branch identity at 225; integration.py synchronizes that birth into the next existing commit. Public disclosure limitation: BUILDER_AMENDMENT_D154.md:29–37 says births appear when first exposed, but does not define exact match-branch creation timing. BUILDER_EXECUTION.md fixes selection/cleanup/decomposition order without explicitly locating birth. This is a frozen-check mismatch plus incomplete public timing disclosure, not an unambiguous violation of an expressly disclosed birth boundary. No evidence here of bad final answer or memory corruption. No criteria retuning or candidate repair.

Parent review can disclose the existing general rule only: match-branch identity is created after Choose branch, before branch-specific outer-holder cleanup; first exposed in the next existing cleanup action, or otherwise Branch start for empty match / Match decompose for nonempty match. No source, fixture, predicted rows or host implementation should go to builder. This account is not itself a delivered public amendment.

Local/uncommitted review evidence under experiments/13-source-acceptance/candidate-runs/stage-a-02/: RESULT.md SHA256 c10d371752c060edce436928dbdb0806ab4b304245475a7e4f4410f3c627583c; comparison.json c884104f9e89e5aa5f437197488233d25c71a5a57e04cb62ccb8db6510f1b3b0; EVIDENCE.sha256 2d7aadca4d0302e8bbdce72dd454ee8860f28d4fd12d42ae3658f3ea83b2a42b verifies 22/22 files, including exact command/input/output. Submission 01 archive and 24 evidence files unchanged. Scientific lock, 496 frozen files, five historical dependencies and six prior archives pass; tracked branch unchanged.

Remaining historical/frontend/numeric checks, final-answer comparison, substantive native reuse/outside protection, resume/destroy/failure cuts, complete routing/atomicity review and evaluator controls remain unrun. No private corpus access, Stage B/resources, merge or deployment. Effort: 335 seconds this interval through 22:54:23Z; cumulative known contributor time 5,018 seconds; earlier unknown remains unknown. Acceptance stopped/unarchived for parent review and public-safe clarification/repair routing.

### 2026-10-07 22:56 UTC, Robert Guss

Parent reviewed submission-02 result, candidate Choose code, frozen branch creation/provenance code and delivered public wording. Original Leaf control rejection is resolved (commits 1–3 pass). Next commit rejects branch-birth coverage; zero complete historical cases. This is a frozen-check mismatch WITH a public timing disclosure gap, not a clear violation of an expressly disclosed creation boundary. Other already-mappable execution/physical fields and extended event prefix reportedly agree; no final-answer/memory failure established.

Requested separately versioned public-only clarification of existing match-branch creation/first-publication timing, before routing a routine candidate repair. Frozen files/checks/predictions/lock and both submissions/evidence remain unchanged. No new policy selected, no owner approval requested, no acceptance inputs/expected rows/reference code sent to builder. Builder remains stopped pending reviewed clarification. No further candidate runs, Stage B/resources, merge or deployment authorized.

### 2026-10-07 22:58 UTC, Robert Guss

Public v17 match-branch timing clarification prepared for parent review; not yet delivered to builder or committed. No criteria/implementation changes or case campaign.

The supplement discloses existing frozen timing: Choose branch does not create/publish this Match's identity. Creation follows it and precedes branch-specific outer-holder cleanup; birth first appears in that cleanup's first existing Give up holder callback, or otherwise Branch start (empty) / Match decompose (nonempty, unique or shared). It retains Match-path origin, execution-ordered identities, branch-before-head-before-tail births, and committed-prefix/failure preservation, without adding transitions or prescribing an algorithm. Direct source review found no new policy or contradiction. This corrects incomplete public disclosure; it does not reclassify final-02 as violating an explicitly disclosed timing rule.

Public addendum: experiments/13-source-acceptance/BUILDER_MATCH_BIRTH_V17.md, 4,228 bytes, SHA256 41b286ba9654c1833ffcacc8aad8fb4ddf1aea8e7deef6cdae8966898bab78cf.
Public archive: .amp/in/artifacts/rob-1333-stage-a-public-v17.tar.gz, 26,074 bytes, SHA256 95570ef6a4003c1322005afd5492365de997c5e5742b5a0ea9c355b04b84ec08.
Exact inventory/update metadata (REVIEW ONLY, not archived): experiments/13-source-acceptance/evidence/public-match-birth-v17/public-update.json, SHA256 9f33acc318793a40955423e2bbf923ca6a442fc815213a0c57dda34d1a6b7375.
Separate source/validation map: same directory summary.json, SHA256 2efcc5ff3fb97e3c5936163e2a0eee4fe5511e2ab87e8e00712e6ae3a9b14a32.

Verified exact public archive membership: 11 unchanged v16 content files + this one document + regenerated DELIVERY.sha256 = 13 files; all 12 content fingerprints verified. No inputs, predictions, host/reference implementation, tests, private material or review metadata added. All 496 frozen files, five historical dependencies, six previous archives, both candidate submissions and their 46 evidence files preserved; scientific lock unchanged (09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e). Both runs still stopped/not accepted, zero complete historical cases; later obligations remain unrun. No candidate rerun/repair, Stage B/resources, merge or deployment.

Effort: 106 seconds through 22:57:48Z; cumulative recorded 5,124 seconds, earlier unknown remains unknown. Parent reviews public wording/archive and routes any builder delivery/consistent repair. This thread remains unarchived.

### 2026-10-07 22:59 UTC, Robert Guss

V17 parent review passed and public-only archive delivered to the existing builder. Independently verified 26,074-byte archive SHA256 95570ef6a4003c1322005afd5492365de997c5e5742b5a0ea9c355b04b84ec08, exact 13-member inventory, all twelve content fingerprints and eleven unchanged prior content files. Full timing supplement agrees with frozen branch creation, cleanup, binding order and existing prefix-preservation behavior; no criterion/policy change.

Builder authorized to verify/read and repair under existing Stage A scope, retaining the disclosure-gap classification. No acceptance inputs, reference rows/implementation, private material or review metadata delivered. Requested normal development verification and separately numbered candidate; no native acceptance pass claimed. Acceptance author asked to commit/push only three reviewed documentation/metadata additions, excluding unreviewed candidate-run artifacts and preserving all original evidence/lock. Commit confirmation and builder resumption pending. Stage B/resources and merge/deployment remain gated.

### 2026-10-07 23:01 UTC, Robert Guss

Reviewed v17 disclosure clarification committed and pushed on acceptance/rob-1333-preparation: [5ded95f](https://github.com/robertguss/mo-v2/commit/5ded95ff12c737a1c6d85409ed99534f05100b70). [Commit-pinned public clarification](https://github.com/robertguss/mo-v2/blob/5ded95ff12c737a1c6d85409ed99534f05100b70/experiments/13-source-acceptance/BUILDER_MATCH_BIRTH_V17.md).

Commit contains exactly three reviewed paths: BUILDER_MATCH_BIRTH_V17.md, evidence/public-match-birth-v17/public-update.json and summary.json. All committed bytes match reviewed fingerprints. Candidate-run files and submitted archives remain untracked/local and were not committed. Remote branch verified at this exact commit; remote main remains at the existing [baseline](https://github.com/robertguss/mo-v2/commit/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3). No merge or deployment.

After push, verified all 496 frozen Git blobs plus five historical dependencies against filesystem and original scientific lock. Lock SHA256 unchanged: 09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e. Both exact submissions and 46 run-evidence files unchanged. All seven retained archives checked, including public v17 unchanged at 95570ef6a4003c1322005afd5492365de997c5e5742b5a0ea9c355b04b84ec08 (26,074 bytes; thirteen members/twelve content hashes).

Parent reviewed and delivered only public v17, authorizing consistent repair. The public-disclosure-gap classification remains intact; neither submission is accepted and both retain zero complete historical cases. No candidate execution/repair or new campaign occurred here. Acceptance remains stopped/unarchived pending the next separately numbered submission; Stage B/resources unapproved. Additional delivery effort recorded: 80 seconds through 23:00:58Z; cumulative known 5,204 seconds, earlier unknown remains unknown.

### 2026-10-07 23:04 UTC, Robert Guss

Submission final-03 verified and transferred unchanged for separate stage-a-03 acceptance. Archive 28,515 bytes, SHA256 df35cb0a094d84f494d43c0f192c1aab0f7f158526bc708fb8bd44f7f8048718. Parent verified exact eight-member inventory, all seven content hashes and focused diff from final-02 (execution/HANDOFF/manifest only). Branch identity is now prepared after Choose, before next-action cleanup, without new native operation or committed transition. Prior mismatch remains classified as a public disclosure gap.

Builder recorded failed timing coverage before repair, then 29 development tests and check/clippy/fmt passing; round-trip tests also pass. Recorded activity review found no excluded retrieval, supplied-file changes or scope breach. Not native acceptance.

Acceptance resumes against unchanged frozen criteria, first verifying the earlier two failure boundaries, preserving all earlier submissions/runs and stopping at the next material discrepancy. Builder stopped pending results. No candidate code applied to main, no acceptance pass, Stage B/resource run, merge or deployment. Builder cumulative active effort 29m41s; 35m35s stopped excluded.

### 2026-10-07 23:08 UTC, Robert Guss

Stage A submission 03: both previously failing boundaries pass, then stopped at first new discrepancy. NOT accepted; zero complete historical cases.

Exact archive rob1333-stage-a-candidate-final-03.tar.gz, 28,515 bytes, SHA256 df35cb0a094d84f494d43c0f192c1aab0f7f158526bc708fb8bd44f7f8048718; manifest fc6e921f90110b1be73c6db11288bcc1e73e90d4a60b94c5208679598c2f0891. Eight files/seven hashes verified; separate native linkage builds locked/offline Rust 1.98.1 with submitted registry versions/checksums.

Command PYTHONDONTWRITEBYTECODE=1 python3 experiments/13-source-acceptance/candidate-runs/stage-a-03/run_historical.py exited 1 on original-1, step 5 Match decompose, 'full committed execution/physical state'. Steps 1–4 pass (including Leaf and Choose branch); Match decompose branch/head/tail birth registration passes too. Saved nine-row comparison isolates /control/0/scope: candidate extends the Match expression context with head/tail bindings; frozen projection retains that context's incoming enclosing environment. Current entered ownership/binding view and other normalized physical/execution fields, birth and event prefixes agree. No wrong final answer or memory corruption is established.

Offending candidate execution.rs:1060 extends scope; :372–391 reports that mutable scope; :619–628 initializes separate outer_scope. Frozen transition_reference.py:31–40,63–64 retains each expression's incoming environment; finite_reference.py:233–251 separately enters inner ownership scope and later evaluates the branch there. Classification: candidate control-scope reporting mismatch; public wording precision caveat. BUILDER_EXECUTION.md:91–97,107–113 already separates per-expression lexical control from entered ownership, but does not literally specify immutable incoming scope. Do not overstate that explicitness. Parent should review whether explanatory public-safe repair wording or a documentary clarification is appropriate. No new policy/checker change proposed; no case input/reference rows/host code to builder.

Local/uncommitted evidence under experiments/13-source-acceptance/candidate-runs/stage-a-03/: RESULT.md SHA256 985f6eb0ea126605fd48efc10e70aed1ac23e74287755acceb3729896fcee60a; comparison.json fb49203a58b6c73d13470cf0cff1210e8ac41a06470f908c16d90c281b498451; EVIDENCE.sha256 59004ccaa6df35937cdaf3cc0b684932f9d15655745bad71ecc9da44cdf96285 verifies 23/23 files. Exact input/request/command, failed output and traceback preserved; diagnostic saved-row replay only, no rerun. Both earlier submissions and 46 evidence files intact; 496 frozen files, five dependencies, seven archives and original lock unchanged. Tracked branch unchanged.

Remaining full routing/atomicity review, historical/frontend/numeric cases, final-answer comparison, substantive reuse/outside coverage, resume/destroy/denial cuts and evaluator controls remain unrun. No private corpus access, candidate repair, Stage B/resources, merge or deployment. Effort: 197 seconds through 23:07:28Z, cumulative recorded 5,401 seconds; earlier unknown remains unknown. Acceptance stopped/unarchived for parent review.

### 2026-10-07 23:09 UTC, Robert Guss

Submission-03 parent review: preserved RESULT/comparison fingerprints verified; only /control/0/scope differs, other normalized state agrees. Earlier Leaf/Choose/birth boundaries pass for this prefix; zero complete historical cases. No final-answer or memory failure established.

Routed a public-safe explanatory repair brief under existing Stage A authorization, not a new policy/document amendment. Existing BUILDER_EXECUTION.md distinguishes per-context lexical scope from entered ownership, but did not literally say incoming environment; that wording limitation was acknowledged. Explanation: each expression reports its incoming nearest-name lexical environment throughout its own evaluation; nested body/branch contexts enter with their own extended environment; Bind/Match decompose can separately update entered ownership. Name insertion order/shadowing and both views remain required.

Builder received only this public explanation and its own serializer/push_context/Match/Let locations, not reference code, inputs, expected rows or evidence bundle. Authorized coherent repair/development verification and separately numbered final-04. Acceptance author remains stopped, retaining all failed submissions/evidence and unchanged frozen checks. No Stage B/resources, merge or deployment.

### 2026-10-07 23:13 UTC, Robert Guss

Final-04 verified and dispatched for separate frozen stage-a-04 acceptance. Archive 30,073 bytes / SHA256 1069848d4cf78d66b6ff33646a5a8cab08558b7e52fee366b73ab06222d46a30; parent verified eight-file inventory, all seven content hashes, manifest and diff. Only execution.rs/HANDOFF/manifest differ; production projection now reads existing immutable outer_scope, preserving working scope/child entry/ownership/native operations/action and birth timing.

Recorded builder audit confirms two tests failed before repair; final check/test/clippy/fmt pass with 31 development tests and round-trip pass. No excluded retrieval, supplied-file changes, native store mock/constructor or scope breach recorded. Not native acceptance. Incoming-environment explanation remains clarification of imprecise wording, not changed criteria.

Exact archive sent to acceptance author to recheck prior failures and continue existing obligations, stopping at first discrepancy and preserving all previous submissions/runs. No accepting files changed, no candidate main integration or acceptance pass, Stage B/resources, merge or deployment. Builder stopped pending results; cumulative active effort 32m17s, stopped 42m05s excluded.

### 2026-10-07 23:17 UTC, Robert Guss

Stage A submission 04: four complete historical-case runs pass the frozen native-linked verifier, then STOP at first discrepancy in original-5. Overall NOT accepted.

Exact archive rob1333-stage-a-candidate-final-04.tar.gz, 30,073 bytes, SHA256 1069848d4cf78d66b6ff33646a5a8cab08558b7e52fee366b73ab06222d46a30; manifest c4226687438db5a9eb8a4c89cfdbf4c4330fb344ed64d8af713875564834ce66. Eight files/seven hashes verified; separate locked/offline Rust 1.98.1 native linkage preserves submitted registry versions/checksums.

Command PYTHONDONTWRITEBYTECODE=1 python3 experiments/13-source-acceptance/candidate-runs/stage-a-04/run_historical.py exits 1. First four historical inputs pass 20/20/9/20 committed steps, final answer/native readback, two destroy calls each, Drop and host teardown. Three perform real same-allocation native Write; all four have no outside roots. Earlier failure boundaries pass in this bounded coverage. This is not complete Stage A, resume/denial or outside-retention acceptance.

Fifth (externally retained) case passes steps 1–4, fails Match decompose step 5 at 'full committed execution/physical state'. Only normalized difference is /release: candidate publishes the scrutinee's future release as already active. All other execution/native/holder/control/birth/event fields agree. No early native release, outside corruption or wrong final answer is demonstrated.

Candidate execution.rs:1073–1078 queues ReleasePhase::Give before Match decompose at :1080–1090; serializer :414 reports every stack entry; actual holder decrement is later in release_action :738–769. Frozen finite_reference.py:243–249 commits decomposition before invoking release; transition_reference.py:42–46,70–73 reports the active chain. Classification: active-release reporting mismatch. Public BUILDER_EXECUTION.md:103–104 defines active chain and :27–30,37–39,72–75 separates actions, but does not explicitly spell out the enqueue-to-active publication boundary here. Keep that precision limitation in any public-safe repair explanation; no criteria retuning/new rule proposed. Do not send input, expected row or reference/host code to builder.

Local/uncommitted evidence root experiments/13-source-acceptance/candidate-runs/stage-a-04/: RESULT.md SHA256 66111f73d7169bc3e9c730461b3b545621da1281dde16d95bfd8980aa21bedbe; comparison.json 45b5478f53f76767308ba472a87d3a69823f3f6874df6b93642ddc33033b4706; EVIDENCE.sha256 ea2d2cac05a9f6284dc60056cd35d8a43b182b11c2cf26f55ce08d8ca8c2e060 verifies 39 files. Exact per-attempt inputs, five native output streams, failed command/traceback and summaries retained. Replay used saved rows only; no candidate rerun after stop. All prior submissions and 69 evidence files, 496 frozen files, five dependencies, seven archives and scientific lock preserved; tracked branch unchanged.

Remaining historical/frontend/numeric cases, full routing/atomicity review, completed shared/outside protection, nonterminal resume/destroy, denial cuts and evaluator controls remain unrun. No private corpus access, candidate repair, Stage B/resources, merge or deployment. Effort: 180 seconds through 23:16:25Z; cumulative recorded 5,581, earlier unknown unchanged. Stopped/unarchived for parent review.

### 2026-10-07 23:18 UTC, Robert Guss

Submission-04 parent review confirms bounded progress: four complete historical native-linked runs pass, including final/readback, repeated terminal destruction and three real same-allocation Writes. These fixtures have no outside roots. Fifth externally retained case stops at Match decompose on /release only; other compared execution/native fields agree. No actual early release, memory corruption or wrong final answer demonstrated; overall not accepted.

Verified RESULT/comparison hashes and candidate enqueue/serializer/release lifecycle against the existing public active-chain contract. Sent builder a public-safe explanation distinguishing scheduled work from active release, including current-frame visibility through Give/Free callbacks, tail activation and ancestor retention/unwind, without extra transitions or earlier native effects. Acknowledged exact publication wording was not fully explicit. Later lifecycle paths were inspected, not claimed executed/failed. No criterion change or acceptance inputs/reference rows/code delivered.

Authorized coherent final-05 repair/development checks under existing Stage A scope. Acceptance remains stopped preserving all prior runs/submissions; shared/outside completion, broader historical/front-end/numeric, routing/atomicity, nonterminal resume/destroy, denial cuts and evaluator controls remain unrun. No Stage B/resources, merge or deployment.

### 2026-10-07 23:25 UTC, Robert Guss

Final-05 verified and transferred unchanged for independent stage-a-05 native checks. Archive 31,827 bytes / SHA256 c6b8ac01150bdca10815e631e3af9d9be0f7d053eba50eee92a3ab65027ba9eb; parent verified inventory, seven hashes, manifest and focused diff. Repair distinguishes queued work from active release and retains callback frames until staged unwind. Native call order unchanged; destroy executable body unchanged (comment/development coverage only).

Recorded audit confirms three lifecycle assertions failed before repair; 34 development tests and check/clippy/fmt/round-trip checks pass. No excluded retrieval, supplied-file changes, native store mock/constructor or scope breach recorded. These are not independent acceptance. Final-04's four native passes remain version-specific partial evidence.

Acceptance rechecks earlier coverage and continues existing obligations with frozen checks unchanged, stopping at first discrepancy and retaining all versions/evidence. Builder stopped pending results. No candidate main integration, acceptance pass, Stage B/resources, merge or deployment. Builder cumulative active 37m29s; stopped 48m28s excluded.

### 2026-10-07 23:28 UTC, Robert Guss

Stage A final-05: 13 complete historical-case runs pass; stop at first discrepancy in original-14, Let Handoff step 38. Overall NOT accepted. Previous failure boundaries pass in observed coverage, including completed shared/outside execution.

Exact archive rob1333-stage-a-candidate-final-05.tar.gz, 31,827 bytes, SHA256 c6b8ac01150bdca10815e631e3af9d9be0f7d053eba50eee92a3ab65027ba9eb; manifest 63b1e307c8dacac36abe8256e11c853274fc505a60b75212800799899bf508bd. Eight files/seven hashes unchanged. Separate Rust 1.98.1 native linkage built --locked --offline; registry versions/checksums match submission.

Executed command: PYTHONDONTWRITEBYTECODE=1 python3 experiments/13-source-acceptance/candidate-runs/stage-a-05/run_historical.py (exit 1). Passing runs include correct final answers/native readback, two destroy calls each, Drop/teardown; two outside-root fixtures (retained head and retained tail), maximum observed active release chain length two, and native execution totals eight Writes/four Creates/six Frees. This is bounded native ownership/release/terminal-cleanup evidence, not full coverage. No nonterminal resume/destroy or denial cuts were reached.

Failed run passes steps 1–37; at step 38 only /state/bindings differs: candidate omits a moved-on local from the entered binding view. Native graph/holders, control, ready, release, births/events and all other fields agree. Not demonstrated live-holder loss or bad final answer.

Candidate execution.rs:1149 restores entered scope unconditionally at every Handoff; snapshot :356–375 uses that entered view plus still-holding bindings. Frozen finite_reference.py:194–208 (Let) and :218–224 (If) do not restore entered scope; Match finish_branch :140–150 does. Public BUILDER_EXECUTION.md:46–47,78,107–113 distinguishes Match restoration and entered ownership versus lexical control, but does not state verbatim that Let/If Handoff leave the view unchanged. Classification: candidate entered-binding reporting mismatch, with that public wording qualification. Parent can give public-safe explanation without historical input/reference rows/code; no new rule or criterion edit proposed.

Review evidence local/uncommitted under experiments/13-source-acceptance/candidate-runs/stage-a-05/: RESULT.md SHA256 30c1aa47d9a9f9d1a2946b4d01d9dd6f1f174238d37992e54271a5d4ba99ef9d; comparison.json c8a8ded92ff333e6c193307bce663750189edfc8d9ffbdadb5d0b20a8bcdfd10; EVIDENCE.sha256 805fa0a6865b5656b82e421ffce3694c74513bff1d577fcfc73af7ba0c86d1cc verifies 75 files. Fourteen exact per-attempt inputs/output streams and failed command/traceback retained; diagnostic replay of saved rows only. Prior submissions/runs 01–04 and 108 evidence files, original lock/496 files/five dependencies/seven archives unchanged; tracked branch unchanged.

Remaining corpus/frontend/numeric, full allocation routing/atomicity, broader shared/outside/release, nonterminal resume/destroy, denial cuts and evaluator controls unrun. No private corpus access, candidate repair, new campaign, Stage B/resource workload, merge or deployment. Effort: 160 seconds through 23:27:51Z, cumulative known 5,741 seconds; earlier unknown unchanged. Stopped/unarchived for parent review.

### 2026-10-07 23:29 UTC, Robert Guss

Parent reviewed final-05 result/comparison fingerprints and submitted Handoff path. Thirteen complete historical native runs pass including final/readback, repeated terminal destroy, two externally retained fixtures, release depth two and 8 Writes/4 Creates/6 Frees. These are bounded results for final-05, not full Stage A. Next case fails only entered /state/bindings at Let Handoff; no live-holder loss, memory corruption or wrong final answer established.

Public-safe final-06 repair brief sent under existing authorization: preserve the current entered binding view at Let/If Handoff; Match alone performs its specified outer restoration there. Explained separation from immutable control lexical scope, citing only public sections and candidate source. Acknowledged the public text did not state the Let/If behavior verbatim. No frozen criterion change or acceptance input/expected row/reference code delivered.

Builder authorized coherent repair and development checks; acceptance remains stopped preserving all candidates/runs. Remaining corpus, complete routing/atomicity, broader native coverage, nonterminal resume/destroy, denial cuts and evaluator controls remain unrun. No Stage B/resources, merge or deployment.

### 2026-10-07 23:35 UTC, Robert Guss

Final-06 verified and sent for independent stage-a-06 checking. Archive 33,246 bytes / SHA256 4e560790cde6482296b671f2f5fa87e4052e79187e740bf4234434a7dae62783; parent verified inventory, seven hashes and manifest. Only production change confines entered restoration to Match Handoff, preserving Let/If view; diff otherwise builder development tests/HANDOFF/manifest.

Recorded repair audit confirms two failures before production fix and 37 passing development tests plus check/clippy/fmt/round-trip. No excluded retrieval, supplied-file edits, native mock/constructor or scope breach recorded. Public wording qualification retained. These are not native acceptance; prior thirteen passes belong to final-05.

Separate acceptance rechecks prior coverage then continues existing obligations under unchanged frozen criteria, preserving all previous versions/evidence and stopping at first discrepancy. No main integration, acceptance pass, Stage B/resources, merge or deployment. Builder remains stopped pending results; cumulative active 41m52s, stopped 54m28s excluded.

### 2026-10-07 23:39 UTC, Robert Guss

Final-06 independent Stage A acceptance stopped, not accepted. Exact submission SHA256 4e560790cde6482296b671f2f5fa87e4052e79187e740bf4234434a7dae62783; unchanged frozen native driver linked and locked/offline Rust 1.98.1 build passed. Historical run completed 25 cases / 576 committed actions, including earlier failure boundaries, terminal readback, two destroys each, Drop/teardown. Bounded native totals: 18 Writes, 5 Creates, 11 Frees; two outside-root fixtures and active release depth two.

First discrepancy: original-26, step 6 Match decompose; only entered binding view differs. Candidate prematurely exposes newly created noHolder head/tail bindings on shared decomposition without tail-holder acquisition. Native memory, other normalized fields and birth/event prefixes agree. Candidate execution.rs:1080 unconditionally sets entered scope; frozen contract delays this path's entered view until Match complete after scrutinee release. Public execution text does not explicitly spell out this conditional timing, so classification retains a public disclosure limitation, not an unambiguous violation of a fully explicit public rule. Parent review/public-safe clarification route needed; no policy or expected-value change made.

Evidence remains acceptance-local and uncommitted under experiments/13-source-acceptance/candidate-runs/stage-a-06/: RESULT.md SHA256 e3127e8a3f7bceb645f603faa693cb8f6e0870c980757a12128cce15f3dce9f0; comparison.json 6121e95d6642de0d82facb85bf49f863d4d0f285fab1e0262103380fecf48d2b; EVIDENCE.sha256 e22b8cc7d83302cb48dd0eac193c56be245aedbc5f2d170f480fb6e7972b32ec (123 files). Exact command/input/output/source references retained. Unchanged scientific lock, 496 frozen files, five historical dependencies, seven prior archives, submissions 01–05 and 183 prior evidence files verified. No evidence sent to builder.

Remaining historical/frontend/numeric cases, complete allocation-routing/failure-atomicity review, nonterminal resume/destroy, denial cuts and compiled evaluator controls remain unrun. No private corpus access, candidate repair, Stage B/resources, merge or deployment. Tracked branch unchanged. Recorded effort this interval 208 seconds including build/tool waits; cumulative measured 5,949 seconds; earlier unknown preparation remains unknown. Acceptance remains stopped and unarchived. [Acceptance thread](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55).

### 2026-10-07 23:40 UTC, Robert Guss

Final-06 parent review confirms 25 complete native historical cases / 576 actions, including earlier failure boundaries, final/readback and terminal cleanup; bounded totals 18 Writes/5 Creates/11 Frees. Next rejection is solely entered /state/bindings during shared decomposition with no tail acquisition. Verified report/comparison hashes and conditional source behavior. Native fields/events agree; no memory loss/corruption or wrong final answer demonstrated.

Public-safe final-07 clarification/repair brief sent: unique decomposition enters inner view; shared decomposition enters it only for actual nonempty used-tail acquisition; shared no-acquisition keeps prior view through decomposition/release and enters at Match complete. Binder creation/birth timing stays unchanged. Public wording did not explicitly fix this conditional timing; retained that disclosure limitation. No criterion/policy change or acceptance inputs/expected rows/code delivered.

Builder continues routine Stage A repair; acceptance remains stopped preserving all submissions/evidence. Remaining cases, full routing/atomicity review, nonterminal resume/destroy, denial cuts and evaluator controls remain unrun. No Stage B/resources, merge or deployment.

### 2026-10-07 23:44 UTC, Robert Guss

Final-07 verified and transferred for separate stage-a-07 frozen native acceptance. Archive 35,180 bytes / SHA256 9fe792c138a6900a7c32f76ee36f051c08410163d693b0d7601b85f0918158cd; parent verified exact inventory, seven hashes and manifest. Reviewed bookkeeping extraction separately: recorded 37-test baseline before behavior change, then two red regression tests; final conditional decomposition/SharedComplete repair passes 39 development tests/check/clippy/fmt/round-trip. Native operation order unchanged; no excluded retrieval, supplied-file edits, native store mock/constructor or scope breach recorded.

Public conditional-timing disclosure qualification retained. Prior 25 cases/576 actions remain final-06 evidence only. Acceptance reruns prior coverage then existing obligations without modifying frozen checks, preserving all versions/evidence and stopping on first discrepancy. Builder stopped pending results; no main integration, acceptance pass, Stage B/resources, merge or deployment. Builder cumulative active 45m04s; stopped 60m54s excluded.

### 2026-10-07 23:51 UTC, Robert Guss

Final-07 independent Stage A acceptance: all 4,276 historical cases passed, then stopped on first follow-up source discrepancy; NOT accepted. Locked/offline Rust 1.98.1 native linkage build passed. Historical command exited 0: 53,796 committed actions, all previous failure boundaries, final readback/two destroys/Drop/teardown. Native execution totals: 89 Writes / 304 Creates / 5,269 Frees; 1,064 outside-root fixtures, maximum active release depth three. These are finite version-specific results, not complete acceptance.

26 additional applicable frozen refusal fixture runs passed; phase-14 then failed independent public bytes. Sole difference /span/end: candidate syntax refusal uses empty insertion span rather than the present unexpected token's width. Class/start agree. Candidate frontend.rs:482–495 creates zero-width spans for ordinary expect mismatches; parenthesized parser at 638–644 uses this helper. Public BUILDER_BRIEF.md:81–91 explicitly distinguishes unexpected-token and missing-token spans. Classification is candidate diagnostic mismatch; public text does not enumerate every parser recovery situation, so retain that narrower wording limitation. No candidate rerun after rejection, policy change or expectation amendment.

Exact archive SHA256 9fe792c138a6900a7c32f76ee36f051c08410163d693b0d7601b85f0918158cd. Acceptance-local evidence under experiments/13-source-acceptance/candidate-runs/stage-a-07/: RESULT.md SHA256 2b32ab11bdb65ac3e52ba563cc49915c0db7e21621dfba9946b889ea7899b1c1; comparison.json 95c1e24507f8c66361c7661d44826749e51cb556145b202f437b92ed1941ed04; EVIDENCE.sha256 491ac65fed9f1ec700b64c5f4d0924d53d4fe117bcadcdd739ec40a5a4b9242c (17,235 files). Exact requests/commands/stdout/stderr/linkage preserved. Lock/496 frozen files/five dependencies/seven prior archives/submissions 01–06/306 prior evidence files verified unchanged. New evidence local/uncommitted; tracked branch unchanged.

Remaining frontend/encoding/priority/wide-number/private cases, full allocation-routing and failure-atomicity review, nonterminal resume/destroy, denial cuts and compiled evaluator controls remain unrun. No private corpus access, candidate repair, Stage B/resources, merge or deployment. Parent will review before any public-safe builder brief. Recorded effort +392 seconds; cumulative measured 6,341 seconds, earlier unknown preparation still unknown. [Acceptance thread](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55) remains stopped/unarchived.

### 2026-10-07 23:52 UTC, Robert Guss

Final-07 milestone: all 4,276 historical native runs / 53,796 actions pass, with final/native readback, repeated terminal destruction, Drop/teardown. Version-specific totals 89 Writes/304 Creates/5,269 Frees; 1,064 outside-root fixtures; release depth three. Then 26 applicable frozen refusal runs pass before a syntax span rejection. Overall NOT accepted.

Parent verified report/comparison fingerprints and candidate expect/error path against public token-span rule. Present unexpected token is reported with empty width; class/start correct, end wrong. Routed final-08 repair using only candidate source/public unexpected-versus-missing distinction; no fixture, expected offsets/reference/host code delivered. Preserved qualification that prose does not enumerate every parser recovery situation. No criteria change.

Acceptance stopped with all evidence intact; builder continues routine repair. Remaining frontend/encoding/priority/wide-number/private, complete routing/atomicity, nonterminal resume/destroy, denial cuts and evaluator controls still pending. No Stage B/resources, main integration, merge or deployment.

### 2026-10-07 23:56 UTC, Robert Guss

Final-08 verified and transferred unchanged for separate stage-a-08 acceptance. Archive 36,392 bytes / SHA256 f79ea749d7a0ed2b7b1d94bd9daf1ebc6997845a1d2d3dcd4726128eb64f2eb8; parent verified exact inventory, seven hashes and manifest. Sole production change routes expect mismatch through existing error(), preserving present-token width, EOF empty range and classifications; execution/native code unchanged.

Recorded audit confirms existing builder-owned expectation corrected from public token-span rule before production change, not fitted to output; two new tests failed before repair. All 41 development tests/check/clippy/fmt/round-trip pass. No excluded retrieval, supplied-file mutation, native mock or scope breach recorded. Parser-recovery wording qualification retained.

Acceptance rechecks prior diagnostic failure and exact-revision historical coverage, then remaining authorized obligations with frozen checks unchanged and stop-on-discrepancy. Earlier full historical pass remains final-07 evidence. No main integration, full acceptance, Stage B/resources, merge or deployment. Builder stopped; cumulative active 47m10s, stopped 70m27s excluded.

### 2026-10-08 00:33 UTC, Robert Guss

Final-08 independent Stage A acceptance stopped on infrastructure, not a candidate discrepancy; acceptance remains incomplete.

Exact revision passed the prior diagnostic boundary and all 4,276 historical native cases / 53,796 committed actions (89 Writes, 304 Creates, 5,269 Frees; 1,064 outside fixtures; observed release depth up to 3). Additional passing evidence: 58 refusal/phase/priority/encoding runs, 2 accepted sources, 35 wide-decimal cases, 12 worked sources, 28 selfcheck sources and 524 private Stage A refusals. Private rows all use Stage B features: no private Stage B execution acceptance is claimed; raw private evidence remains outside checkout and no seed was read.

18,360 resume, 18,360 destruction and 23,863 controlled-denial runs passed. Complete resume/destroy cuts through historical index 1510; complete observed denial schedules through 1509, partial at 1510. Command PYTHONDONTWRITEBYTECODE=1 python3 experiments/13-source-acceptance/candidate-runs/stage-a-08/run_remaining_cuts.py exited 1: OSError Errno 31 Too many links at unchanged linked.py:45 destination.mkdir, after 64,998 direct non-symlink directories. First unexecuted request deny-1510-frame-010 was saved; candidate was never launched for it. No offending candidate line or new public contract issue is established.

Remaining: lifecycle/denial suffix, uncovered public-source cuts, full routing/atomicity audit and applicable compiled controls. Control copies were prepared separately but none executed; final control-only edit remains unbuilt. No controls count as accepted evidence. Recommend a separate sharded evidence destination, preserving the original and resuming first unexecuted request after parent review.

Evidence base experiments/13-source-acceptance/candidate-runs/stage-a-08/:
- RESULT.md SHA256 65b0dc92a6ee7d7cfbbd6ac808a759cf78efa14efd0c3ea51dced0b0101d9b5b
- EVIDENCE.sha256 SHA256 b74b5e1774283b685c2de0646220347a839cb3c181a2b949e0da5f0a8462965b; all 260,029 entries verified.
- preservation.json SHA256 f7566075c20cbca1fb3fbf04e6dbd8e161fa46d930f788db48c1996f9faffbdb
- remaining-cuts-summary.json SHA256 692f2e5297fef017b2bc4cfa18c9be6534b67a10ad04b84ecacae9db98e9da0f

Verified eight exact submissions, 17,541 prior evidence files, 496 frozen files, five historical dependencies and seven archives unchanged. Scientific lock SHA256 09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e. Tracked branch unchanged; new evidence is local/uncommitted. Recorded interval 2,149 seconds; cumulative measured effort 8,490 seconds, earlier unknown preparation remains unknown. No candidate repair, private builder delivery, Stage B/resource workload, merge or deployment.

[Acceptance thread](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55).

### 2026-10-08 00:35 UTC, Robert Guss

Final-08 remains incomplete, with no observed candidate discrepancy. Parent verified RESULT/remaining-summary hashes, orchestration and frozen linked.py ordering: Errno 31 occurs during evidence destination mkdir before Popen. Saved deny-1510-frame-010 was not executed. Authorized ordinary infrastructure continuation into a separately named sibling sharded evidence tree, preserving original files/manifests and unchanged candidate/frozen verifier. No new owner decision needed.

Continuation must reconcile full existing baseline-derived run schedule with successful per-run evidence, start at the saved unexecuted request, preserve stable run IDs/destination mapping and avoid omitted/double-counted cuts. Complete remaining historical/public-source cuts, full routing/atomicity review and applicable rebuilt compiled controls under existing Stage A scope; stop at first material discrepancy. No acceptance predicate change, candidate repair, new campaign, Stage B/resources or merge/deployment.

Verified report records final-08 historical 4,276/53,796 actions; 58 refusal/phase/priority/encoding + two accepted source runs; 35 wide-decimal, 12 worked and 28 selfcheck sources; 524 private Stage A refusals (not private execution coverage). Completed cuts: 18,360 resume, 18,360 destroy, 23,863 denial. Later obligations remain pending. Private raw evidence stays outside checkout and is not delivered to builder; builder stays stopped. All earlier evidence preserved.

### 2026-10-08 02:03 UTC, Robert Guss

Final-08 continuation completed: applicable frozen Stage A checks pass; parent review remains pending. No candidate discrepancy, criteria change, repair, Stage B/resource run, merge or deployment.

The recoverable filesystem limit was resolved solely with sibling evidence shards of at most 500 runs. Replayed every credited prior transcript and matched its request to the retained baseline-derived schedule. Started at the saved unexecuted denial. Reconciliation covers all 197,085 historical lifecycle/denial IDs: 60,583 already-passed runs skipped, 136,502 new passes, zero missing/duplicate/orphan destinations. Combined historical totals: 58,072 resume, 58,072 destruction and 80,941 controlled-denial runs. All 4,276 historical baseline cases / 53,796 actions remain passing for exact final-08; baseline native totals are 89 Writes, 304 Creates, 5,269 Frees, with 1,064 outside-root fixtures and observed release depth three.

135 retained public baselines add 562 resume, 562 destruction and 830 denial passes. Overall lifecycle totals: 58,634 resume, 58,634 destruction, 81,771 denials. Source/routing/atomicity review is recorded. 21 applicable real compiled evaluator controls each have a passing disabled-mutation baseline, reached-path marker and intended rejection evidence. Two controls hit named frozen Rust-driver guards. The repeated native free is blocked by UnknownCell; its duplicate claimed cleanup also fails the frozen destroy free-set/duplicate predicate on captured real rows. No second physical deallocation or stub-based evaluator result is claimed. Later fault-consequence stderr for two controls is preserved separately from their earlier decisive state rejection.

Deferred: 10 exact Stage B control paths, 16 Stage B semantic expectations, private execution, Stage B implementation/acceptance, large streaming/resource work. The 524 private Stage A refusals are not private execution coverage. Denial schedules exercise observed frontend/execution attempts, not denial during destruction or arbitrary host OOM.

Evidence base: experiments/13-source-acceptance/candidate-runs/stage-a-08-continuation/
- RESULT.md SHA256 31e74413f8c27b8adfb00cddf91defc9806ae59bdfc02f2c0b118c6f8b2325ab
- EVIDENCE.sha256 SHA256 6d77198eb2b7c1f5a564561bb83dd9f6c8289efd3b019264ead7390ed622cb3c; all 554,057 entries verified.
- reconciliation.json SHA256 23d7e1a2b82074af4876faa0a880070e2937318b149034c4dd0935ec4552be0c
- controls-reviewed.json SHA256 707e9f673ed79871cb11778cba2cef444fcc2b0319d3fa56c9ac46f8abe0f30a
- ROUTING_REVIEW.md SHA256 1d653e8e8b6e5b637226bfe97efa8d3285aea2441d564ba9566297ea77d82c44
- preservation.json SHA256 a9e82185e33a57159ad40f6a7b6b3710141afa9a36b2a6943ee17cfeeb01aadb

Verified all eight submissions, 277,570 prior evidence files, 2,097 separate private evidence files, 496 frozen files, five dependencies and seven archives unchanged. Scientific lock remains 09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e. Original saturated directory inventory and manifest unchanged. Candidate binary remains 41f444e2872ef417dd58fcb3d05920705b8c10ba1b45b1dc451287da8259feb9. New evidence is local/uncommitted; tracked branch unchanged; no builder delivery.

Measured continuation effort 5,099 seconds; cumulative recorded effort 13,589 seconds, excluding stopped intervals; older unknown preparation stays unknown. Final reporting after the recorded endpoint is unmeasured. [Acceptance thread](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55). Stopped for parent review; this does not authorize Stage B.

### 2026-10-08 02:19 UTC, Robert Guss

Parent review completed: final-08 passes applicable frozen Stage A checks; no blocking finding. The complete campaign remains separately authored and executed. Parent checked report fingerprints, all 496 frozen files/five dependencies, source/routing and orchestration, 219 reviewer-package members, control source mutations and raw failures. Fresh parent verification: locked native build, 41 builder development tests, 25 native-linked spot checks, and all 21 compiled control pairs; 21 baselines pass and all intended rejections plus exact predicate evidence reproduce. No accepting rule or submitted source changed.

Exact candidate and native linker are now pushed on [implementation/rob-1333-stage-a](https://github.com/robertguss/mo-v2/commit/26f7f53c0398c52e93250c6286dffc8ee70bed4f), not merged. Full lossless non-private evidence packaging is in progress; 831,636 files / 4,946,455,087 content bytes will be compressed with indexes and preservation checks, with private inputs/seeds excluded. Reports and final branch delivery update follow; Building remains until that closeout.

Limits retained: Stage A is call-free; 524 private rows establish only capability refusals; observed frontend/execution denials do not cover denial during destruction or arbitrary OOM. No Stage B, streaming/resource, merge, release or deployment authorization follows. No new owner decision is recorded.

### 2026-10-08 12:34 UTC, Robert Guss

Stage B acceptance package prepared for review (D157): draft PR https://github.com/robertguss/mo-v2/pull/4, head 6c8ce1ea6741d2a2e61b5a1e923e4e40dc2352a7, Buildkite build 14 green. Readable report: `experiments/13-source-acceptance/STAGE_B_PREPARATION.md`. Nothing frozen changed; no Stage B build, control execution, million-element run or private-corpus use.

Robert's decisions on the report's three open items, 8 Oct 2026: D159 (summary observations between boundaries, full detail at boundaries), D160 (cleanup chain in full at boundaries, length only in between), D161 (ask the acceptance machine for a yes/no on whether any reserved example allocates at invocation entry, reaching `omitted-entry-create`; if none does, add one public example that allocates at entry).

Waiting on: the D161 yes/no from the Amp acceptance orb (relayed by Robert), then Robert's approval to revise and freeze the package. Remains Needs Input.

### 2026-10-08 13:58 UTC, Robert Guss

8 Oct 2026, 9:58 AM ET: the Stage B acceptance preparation package (PR robertguss/mo-v2#4, head 1e5b04b, Buildkite build 17 green) is merged to main at 424d0f4 under D163. It includes D159 and D160 (observation schedule), D162 (recursive sum 900 s, discard 600 s; projections about 725 s and about 98 s) and D164 (omitted-entry-create not applicable under the frozen rules; 9 of 10 controls active). The D161 acceptance-orb check found 0/24 reserved and 0/500 generated cases that allocate at entry.

Before that, main was made green with experiment 12 excluded from CI (8d7f0d9, Buildkite build 16).

Still gated, each needing Robert's approval: a scientific freeze of the package, dispatch to a separate Stage B builder, private execution on the acceptance orb, the nine sabotage controls, and both million-element runs. Remains Needs Input.

### 2026-10-08 14:22 UTC, Robert Guss

8 Oct 2026, 10:22 AM ET. **D165 recorded** (Robert: “go”, 10:14 AM ET). It covers the scientific freeze of the Stage B acceptance package and dispatch of a separate Stage B builder.

**Freeze: not done yet.** The Stage A freeze at 1f41893 consisted of `STAGE_A_LOCK.json`, `STAGE_A_LOCK.md` and `evidence/stage-a-freeze/validation.json`. Mirroring it for Stage B needs two things:
1. A commit adding `STAGE_B_LOCK.json`, `STAGE_B_LOCK.md` and `evidence/stage-b-freeze/validation.json` against main 424d0f4, on a fresh acceptance branch with a draft PR, not merged.
2. A read-only check on the acceptance orb. It confirms the private corpus fingerprint is still 0f176c60…41f0 and that the freeze commit contains no matches to the private seed or private sources. The Stage A validation recorded both.

One discrepancy needs settling before the lock: `BUILDER_STAGE_B_V18.md` still states a single 600-second limit for both workloads, but D162 gives the recursive sum 900 s.

**Builder:** the existing Stage A builder, Amp thread [T-01a1185b-f677-74ad-a1c9-769b73fe1411](https://ampcode.com/threads/T-01a1185b-f677-74ad-a1c9-769b73fe1411). It runs in a no-project orb with public material only and has no repository checkout. It was unarchived and given **preflight only**, together with the public package `rob-1333-stage-b-public-v18.tar.gz` (28,229 bytes, SHA256 0e3080…b997).

Preflight passed at 10:19–10:21 AM ET:
- Archive, inventory and manifest verified.
- Final-08 Stage A source intact.
- Rust 1.98.1 checks pass, and 41 development tests pass.
- No excluded retrieval reported.

It raised five public-contract questions for an acceptance-side public clarification. No candidate code has been written. Implementation starts only after the freeze lands and an explicit dispatch is sent. The parent will publish its submissions on `implementation/rob-1333-stage-b` as a draft PR. The builder does not push or merge.

**Still gated on Robert:** private execution on the acceptance orb, the nine sabotage controls, both million-element runs, and any merge, release or deployment.

Note: this issue's status currently reads Done, set at 9:58 AM ET when PR #4 merged. Stage B is not built.

### 2026-10-08 14:48 UTC, Robert Guss

8 Oct 2026, 10:50 AM ET. **Stage B frozen and merged; builder dispatched.**

**Freeze.** PR robertguss/mo-v2#5 was merged under D166 at [62e0e4c](https://github.com/robertguss/mo-v2/commit/62e0e4c8e56b8e7a608b2b596da12503ac3f1bae). It was pinned to head 322509f, so the tree is identical to the reviewed head.
- Lock: `STAGE_B_LOCK.json`, SHA256 2df4234f…a5cbb.
- Builder delivery: public v19, SHA256 ac82bf2c…4bba, 31,048 bytes.
- CI: Buildkite build 19 passed on the PR head, and main build [20](https://buildkite.com/robert-guss/mo-v2/builds/20) passed on the merge commit.

**Acceptance-orb check.** Read-only, run in thread T-01a11697. It executed no cases and returned counts and hashes only. All checks passed:
- Corpus fingerprint 0f176c60…41f0, 1,003,653 bytes; seed file 50 bytes.
- 24 heldouts, 8 families, 500 generated rows, 404 distinct, 96 repeats.
- v19 holds exactly the 15 allowlisted members and its manifest verifies.
- Zero forbidden markers in v19.
- Zero private content (seed, case sources, expected outputs, embedded files) in v19 or in any file the commit adds or changes.

The details are in a comment on PR #5.

**Builder dispatched.** Amp thread T-01a1185b-f677-74ad-a1c9-769b73fe1411 received only public v19, which includes the preflight clarification. It acknowledged the dispatch at 10:47 AM ET and verified v19 (size, hash, 15 members, manifest, 12 files unchanged from v18). It read both new documents and is now implementing in a separate `stage-b` directory, with final-08 kept unchanged. It works with no repository access and does not push or merge. Its submissions will be published on `implementation/rob-1333-stage-b` as a draft PR.

**Still gated on Robert:** private execution on the acceptance orb, the nine sabotage controls, both million-element runs, and any merge of the builder's work, release or deployment.
