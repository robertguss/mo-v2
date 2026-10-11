# ROB-1330: Bound retained resources when native migrations never return

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1330/bound-retained-resources-when-native-migrations-never-return
> Status at export: Done
> Created: 2026-10-06
> Updated: 2026-10-08
> Completed: 2026-10-08
> Comments: 2

---

## Description

## Current status — merged and Done

8 October 2026 reconciliation: the experiment commit [87e3a9d](<https://github.com/robertguss/mo-v2/commit/87e3a9dc458f03de9c511511f8aa61f05a3d1be9>) is an ancestor of current origin/main, verified directly. Done is accurate for this bounded experiment; the earlier In Review/unmerged text below is historical and superseded. Its 270-job/240-refusal result does not establish arbitrary native-code resource safety or production availability. No new experiment or rerun occurred in this reconciliation.

## Historical pre-merge record

## Passed — In Review

Experiment 9 passed at 87e3a9dc458f03de9c511511f8aa61f05a3d1be9 on `codex/native-migration-resource-limit`; pushed branch verified. [Report](<https://github.com/robertguss/mo-v2/blob/87e3a9dc458f03de9c511511f8aa61f05a3d1be9/experiments/09-migration-limit/RESULT.md>). Three no-retry trials: 270 jobs, 240 excess updates explicitly refused, five persistent clients each; external thread count 8 baseline / 10 with two permanent native hangs. Returning workers reclaimed capacity; timed-out workers retained it. No new attempt or candidate load at capacity. Native code remained pinned, old queue resumed and ordinary work continued; permanent timeout times 200.124–201.215ms after staging. Five compiled broken-source controls caught; initial overly broad unsafe-retire control failed too early and is retained, corrected control targeted executing ownership without changing acceptance. Unchanged experiment-8 trial passed another 97 regression jobs. Forced-failure cleanup killed/reaped hung process; no in-process reclamation claim. Same-author verification. Prior manifests unchanged; unrelated CLAUDE.md edit excluded. Resource cap is host updater count under trusted ABI, not arbitrary heap/native preemption or production SLA. No merge or deployment.

Experiment 9 remains In Review and unmerged; no merge authorization is recorded. The eight-issue Needs Input inventory was historical: five now remain Needs Input, while [ROB-1142](https://linear.app/robert-guss/issue/ROB-1142/propose-the-number-representation-experiment)/1146 are Done and [ROB-1141](https://linear.app/robert-guss/issue/ROB-1141/propose-a-copy-feedback-experiment) is In Review. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) has separate conditional authorization. Earlier Building scope below is historical.

Authorized by Robert in D123 after merging ROB-1329. Experiment 9: cap outstanding updater threads at two before staging; timeout does not release capacity. Real non-returning native migrations retain code safely; excess updates explicitly refused without loading candidates. Returning attempts release capacity; ordinary jobs and persistent connections continue after timeout/at capacity. Same-author three-trial checks and compiled broken-source controls; external thread observations, exact work ledger and loader lifetime evidence. Keep claims to trusted fixture/host-owned resources, not arbitrary native heap or preemption. Preserve previous experiments. Branch-push delivery, no automatic merge. After completion discuss all Needs Input issues, no further experiment.

## Comments

### 2026-10-08 00:24 UTC, Robert Guss

Draft PR opened for owner review: [robertguss/mo-v2#2](https://github.com/robertguss/mo-v2/pull/2), from `codex/native-migration-resource-limit` at 87e3a9d into `main`. GitHub reports it mergeable and clean against current main (03705f1). The repo has no CI workflows, so no checks ran. Not merged; merging needs Robert's explicit approval.

### 2026-10-08 00:26 UTC, Robert Guss

Merged [robertguss/mo-v2#2](https://github.com/robertguss/mo-v2/pull/2) into main with a standard merge commit, with Robert's approval. The new main commit is `5fb2f1c0a2d98593213fcd976d114e59bbc51352`. The branch `codex/native-migration-resource-limit` was left in place. There was no CI on this merge; Buildkite CI is being set up separately.
