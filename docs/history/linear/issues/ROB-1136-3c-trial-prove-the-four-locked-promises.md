# ROB-1136: 3c trial: prove the four locked promises

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1136/3c-trial-prove-the-four-locked-promises
> Status at export: Done
> Created: 2026-10-02
> Updated: 2026-10-07
> Completed: 2026-10-02
> Comments: 6

---

## Description

## Reconciled current status — 7 October 2026

Completed historical trial: all four promises were accepted and merged with the report at [e6a895c](<https://github.com/robertguss/mo-v2/commit/e6a895c8ce2887d9bee6986819a779f8f74b5541>). No proof interval or builder ownership is active. The clock, dispatch, permitted-file and binding-document sections below describe the completed trial, not authorization for new work.

Earlier records follow, preserved as history.

## Current work

**All four exact promises technically accepted.** Candidate baf1d52649bc7a50ff7df19d0368d182efdb3fbd. Independent Lead and fresh Tester each passed all10 frozen checks, recording before sharing; Oracle final proof review found no P1/P2. No unfinished proofs or nonstandard axioms. Stopped early07:14:34 UTC; no new interval. Branch ownership returned to Lead. [Plain-English result](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RESULT.md>). Proof and combined report branch rob-1137-final-report are merged and pushed to main at [e6a895c](<https://github.com/robertguss/mo-v2/commit/e6a895c8ce2887d9bee6986819a779f8f74b5541>), following Robert’s approval. Fresh fetch verified the exact tip. No PR/deployment.

Branch: `rob-1136-trial-proofs-high`. Expected starting plan: `ad9302cd4aacaf08ca0d82a01c3aaadca92c9201`. Amended acceptance baseline: `787e0427244837fd0f44b76c4a648d07938c3bcc`. Full brief is the plan commit body. Operational prerequisite ROB-1132 is merged and Done. Grok47 readiness thread ownership revoked; no proof work occurred there. D103 (Amp trial workflow), D104 (AFK delegation), D105 (delegated high-mode fallback) record authority and history.

## Acceptance and scope

Prove all four frozen promises for every well-formed trial program and valid start: finishing, same answer, no visible changes to held lists at recorded moments, no leaks. Trial excludes calls/recursion; this is not full 3c. Only `experiments/03c-checker/trial/lean/Proofs.lean` bodies/imports and new `lean/Proofs/` files may be changed by Builder. Frozen semantics, statements, predictions, checks, dependencies and docs cannot change. Lean core 4.34.0 only; all forbidden constructs/options in brief remain prohibited. Frozen acceptance precedes proof work; no replacement tests.

Verify: `lake build Trial Checks Promises Proofs Acceptance` inside trial/lean. Successful build alone is not acceptance. Lead and fresh Tester independently execute applicable locked checks against the same candidate, record findings before sharing, then Oracle reviews. Checks 9–10 only after proof. Partial promises require existing partial-work acceptance; helper lemmas are not completed promises.

## Clock, stops and delivery

Lead owns two-hour elapsed intervals. Initial setup is not proof time. No reset on restart. Builder checks UTC deadline and submits original report/checkpoint; later intervals start automatically on Lead continuation unless hard stop. Preserve working and waiting time separately in Lead-owned phase-2/CLOCK.md, original Builder reports and independently checked claims.

Stop on complete candidate, deadline/report, valid concrete counterexample, evidenced spec defect, integrity/path/branch violation, or setup blocker. Difficulty remains unfinished, not proof that a promise is false. Push only proof paths to owned branch, after fetch/expected-tip check, fast-forward only. Lead owns Linear/reports and coordination. No Builder PRs, merges, deployments, releases or child threads. Done means accepted and merged, not a checkpoint.

Binding current documents: [https://github.com/robertguss/mo-v2/tree/787e0427244837fd0f44b76c4a648d07938c3bcc/experiments/03c-checker/trial](<https://github.com/robertguss/mo-v2/tree/787e0427244837fd0f44b76c4a648d07938c3bcc/experiments/03c-checker/trial>) . Historical setup/recovery and prior plans remain in comments and decision register.

## Comments

### 2026-10-02 02:13 UTC, Robert Guss

[lead] Approved plan published. Branch rob-1136-trial-proofs; initial plan SHA [82d106149b626e23e14b884bb00e99d01e643d96](https://github.com/robertguss/mo-v2/commit/82d106149b626e23e14b884bb00e99d01e643d96); amended lock baseline [58436a595bb9de7b550d183495f35b93b9629b38](https://github.com/robertguss/mo-v2/commit/58436a595bb9de7b550d183495f35b93b9629b38). Oracle approved operational diff and brief. Builder gets sole proof-branch write ownership upon dispatch. Readiness only first, no clock yet. Linear outage delayed dispatch until reset; no proof work ran during outage.

### 2026-10-02 02:28 UTC, Robert Guss

[lead] Replacement plan: [ad9302cd4aacaf08ca0d82a01c3aaadca92c9201](https://github.com/robertguss/mo-v2/commit/ad9302cd4aacaf08ca0d82a01c3aaadca92c9201), branch rob-1136-trial-proofs-high; lock baseline [787e0427244837fd0f44b76c4a648d07938c3bcc](https://github.com/robertguss/mo-v2/commit/787e0427244837fd0f44b76c4a648d07938c3bcc). Oracle approved fallback and exact operational diff. Old thread revoked; new Builder receives single-writer ownership on dispatch. Ready check first, no proof clock until Lead start.

### 2026-10-02 02:36 UTC, Robert Guss

[lead] Interval 1 authorized: 2026-10-02T02:35:00Z through 04:35:00Z. Readiness independently built by Builder with all25 hashes and expected four sorryAx; Lead had verified same baseline toolchain. [Builder](https://ampcode.com/threads/T-01a0fa71-4bff-779d-9439-83059a968a65). No earlier proof interval; setup, rate-limit wait and recovery are not proof time. Branch single-writer owner is Builder. Lead keeps separate CLOCK evidence, no writes to Builder branch during ownership.

### 2026-10-02 04:52 UTC, Robert Guss

[lead] Checkpoint 1 retained, not completed acceptance: 8c57ccbd4f41dea91f2cda903d9377362f37270a. Separate Lead/Tester runs agreed 0/4 proven, four unfinished bodies, no demonstrated blocker; 25 locks, proof paths, 48-job clean partial build, exact types, kernel and frozen examples passed. Oracle full-diff review found no P1/P2. Same-scope interval 2 authorized 04:49–06:49 UTC, focusing on evaluator induction/liveness/pending/reservations/snapshots. Evidence and original reports: https://github.com/robertguss/mo-v2/tree/d4acb3119a668a20cba5587b3d45d354ea4e897b/experiments/03c-checker/trial/phase-2 . Pushed branches only, no merge/PR/deploy.

### 2026-10-02 07:09 UTC, Robert Guss

[lead] Checkpoint2 review complete: 0/4 promises proven. Lead and fresh Tester independently executed locked partial checks on 38c4b7accc32cea8a3714eeb93c5917b4431ab8c; both recorded before sharing. Oracle found no P1/P2. Interval3 authorized07:06–09:06 UTC for complete nonempty-match composition then structural induction. No new scientific scope or weakened checks. Evidence commit66b311e46071e47543b8887fc5490a15f9c1c941: https://github.com/robertguss/mo-v2/tree/66b311e46071e47543b8887fc5490a15f9c1c941/experiments/03c-checker/trial/phase-2 . Branches pushed, not merged.

### 2026-10-02 15:12 UTC, Robert Guss

[lead] Merged and pushed to main after Robert’s explicit approval in [Lead thread](https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7). Fast-forward integration tip: [e6a895c](https://github.com/robertguss/mo-v2/commit/e6a895c8ce2887d9bee6986819a779f8f74b5541); no separate merge commit or PR. Fresh fetch verified origin/main equals that exact accepted report tip; worktree clean. Accepted proof [baf1d52](https://github.com/robertguss/mo-v2/commit/baf1d52649bc7a50ff7df19d0368d182efdb3fbd) is an ancestor; proof/lock/acceptance bytes are unchanged. Existing independent Lead and [Tester](https://ampcode.com/threads/T-01a0fb79-1151-70bb-8f33-f47c48f26fbd) runs passed all ten checks; clean build 77 jobs, no warnings, standard axioms only, frozen examples identical, unsafe controls fail. [Builder](https://ampcode.com/threads/T-01a0fa71-4bff-779d-9439-83059a968a65). Oracle final proof and reporting reviews had no P1/P2; no unresolved finding. This merge did not rerun or change those checks. No deployment/release, no new scientific scope. Done now means confirmed merged delivery.
