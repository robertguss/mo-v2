# ROB-1328: Refuse stalled native preparation while preserving service and module lifetime

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1328/refuse-stalled-native-preparation-while-preserving-service-and-module
> Status at export: Done
> Created: 2026-10-06
> Updated: 2026-10-06
> Completed: 2026-10-06
> Comments: 0

---

## Description

## Merged and verified — Done

6 October 2026: Robert explicitly instructed “merge it”. Fast-forwarded main from a1c032fa7fa2b1061ce79f9fd13403061640bb5b to 3e8da6423a13386d81bb8e188fa2839ba4c03f88, pushed and fetched to verify remote main. Reviewed source and both original/staged evidence manifests unchanged. Original failed end-to-end result remains preserved alongside the approved passing staged revision. Same-author verification retained; no new tests needed for this content-preserving merge. Unrelated unstaged CLAUDE.md edit preserved. No deployment or next experiment authorized or started.

The following records the pre-merge results and approvals.

## Staged revision passed — In Review

Robert-approved D120 boundary (load first, then 200ms preparation/activation) implemented and pushed to `codex/stalled-native-updates` at 3e8da6423a13386d81bb8e188fa2839ba4c03f88; remote verified. [Report and evidence](<https://github.com/robertguss/mo-v2/blob/3e8da6423a13386d81bb8e188fa2839ba4c03f88/experiments/07-stalled-native/staged/RESULT.md>). Three fresh no-retry trials preserved 300 jobs and all five connections per trial. Deliberately slow 400ms-constructor staging measured 574.601–1394.941ms while old jobs completed; preparation timeouts measured 200.083–201.112ms after staging. Newer candidates activated before timed-out native calls returned; stale results discarded, real image removal only after return. Invalid staging never armed a clock. Six compiled source controls caught. First mutation runner's formatting-anchor failure retained and corrected without changing runtime/check assertions.

Same-author verification, not independent acceptance. Original failed end-to-end criterion and all previous files/manifests unchanged. Whole-update/loading latency remains unbounded; arbitrary stuck native preparation retains resources until return. Trusted synchronous ABI on macOS; no universal safety, arbitrary-code preemption or production SLA. No merge, deployment or further milestone. Unrelated CLAUDE.md edit preserved.

## Authorized staged revision — 6 October 2026

Robert approved “yes” to loading first and then starting the 200ms preparation deadline (D120, separate native staging from timed preparation). Implement in `experiments/07-stalled-native/staged/`, preserve the entire original failed experiment. Measure staging independently, test three no-retry trials and source controls, preserve safety/lifetime/refusal promises. Same-author verification, branch push, no merge/deployment. Older result/proposal below describes the original boundary.

## Result — original criterion failed; scope decision needed

Pushed and remote verified `codex/stalled-native-updates` at 78b3be720af76ad011557cd1b96b6b5c4861c727. [Full result and evidence](<https://github.com/robertguss/mo-v2/blob/78b3be720af76ad011557cd1b96b6b5c4861c727/experiments/07-stalled-native/RESULT.md>). Original no-retry check is unchanged and failed: cold native loading can exhaust the 200ms budget before preparation starts. Refusal was safe; that is not counted as successful activation. Fixed a discovered snapshot/loader lock-order defect; retained original source and both original runs (second run passed one full trial then failed the next).

A separately labelled retry-assisted diagnostic passed three trials / 288 jobs, independent held/native-sleep timeouts around 200–201ms, newer activation before stale native return, exact job preservation and real eventual unloading. Five compiled source controls were caught against that diagnostic. It is not original acceptance and not independently authored verification. Initial diagnostic destructor-accounting bug and all attempts retained. No deadline widened or original expected output changed.

## Proposed next scope for owner decision (not executed)

Recommend separate staging/loading from timed preparation: stage a separately compiled candidate asynchronously while service stays active; preserve the current attempt's 200ms preparation/activation budget after staging is ready. Measure/report staging latency separately, explicitly no arbitrary OS-loader hard bound. Keep stale-return fencing, old/native reference retention, incompatible-artifact rejection, job/version guarantees and five broken-source controls. Three fresh trials, no retry needed to claim the preparation phase passes; stage failures remain explicit. Alternative: approve safe retry semantics with the existing end-to-end deadline, or choose a larger measured end-to-end budget. All alter original success conditions; no choice is recorded as Robert's decision.

Experiment 6 is merged and Done at a1c032f under “merge it and continue”. Experiment 7 remains unmerged; Needs Input reflects this concrete scientific-boundary choice. No deployment/next milestone. Unrelated CLAUDE.md edit preserved.

Robert authorized “merge it and continue” after the recommendation to combine native loading with independent deadlines, late-result fencing, continued service and safe eventual unloading. Continue the current self-verification workflow; no separate builder. Prior experiments unchanged.

Bounded experimental choice: extend experiment 6 Rust host/C ABI with asynchronous native preparation, monotonic 200ms attempt deadline and independent watchdog. Trusted modules only. Exercise both a held native callback and native timed blocking that does not call back. Preserve admissions and old jobs, activate newer candidate while old preparation remains held, discard late candidate, keep code mapped until no native execution can reference it. Loader constructors/destructors and malicious native code are excluded; no arbitrary native preemption claim. Verify three trials and actual source controls; retain all failures. Stop at pushed branch and report; no automatic next merge/deployment.
