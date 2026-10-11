# ROB-1146: Park conditional and post-3c candidates

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1146/park-conditional-and-post-3c-candidates
> Status at export: Done
> Created: 2026-10-02
> Updated: 2026-10-07
> Completed: 2026-10-06
> Comments: 0

---

## Description

## Reconciled current status — 7 October 2026

Done covers only the merged finite Lean/Rust bridge at [a22831f](<https://github.com/robertguss/mo-v2/commit/a22831f823d2ac7ccbb8726a8d4418fbceb233e0>). Other parked candidates remain unapproved. Earlier In Review/not-merged wording below is historical; [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)’s broader source-driven prototype is separately scoped.

Earlier records follow, preserved as history.

## Merged — 6 October 2026

Robert instructed “merge it and then work on your rec”. Main fast-forwarded to a22831f823d2ac7ccbb8726a8d4418fbceb233e0; remote main verified. Frozen comparison checks and artifact manifest unchanged. Done covers the completed finite bridge; other parked candidates remain unapproved. Experiment 9 is still separately In Review.

## Finite bridge passed — In Review, 6 October 2026

The finite-model/Rust comparison passed at a22831f823d2ac7ccbb8726a8d4418fbceb233e0 on `codex/finite-rust-correspondence`, pushed and remote verified. [Report](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/RESULT.md>). All 4,276 cases (28 original + 4,248 generated), 27,721 snapshots and physical cell accounting matched; five compiled broken variants rejected. 304 evaluation cell creations, 89 in-place writes, 5,269 releases, with 9,617 initial fixture cells separately counted. Inputs/exporter/checks/expectations frozen at 77b208b before Rust implementation. Fresh disposable Lean rebuild reproduced expectations exactly; 270 original trial/helper file hashes unchanged. New code/checks are same-author verification, with unchanged independently authored historical model/predictions. Initial exporter setup error, Rust compile error and overly narrow control-runner assumption retained; no behavioral mismatch in the first compiled baseline run and no acceptance retuning. Finite i128 corpus and valid fixture inputs only; no universal refinement proof, arbitrary integer policy, calls/recursion, full3c or production runtime claim. Unrelated CLAUDE.md edit preserved. New branch not merged; experiment 9 also remains separately In Review.

The approved finite bridge is complete, ready for owner review. Other candidates listed below remain unapproved; completing this bridge does not execute or settle them. Return to remaining Needs Input discussion; no further experiment started. Earlier Building/proposal status below is historical.

## Authorized bounded comparison — 6 October 2026

Robert agreed to prioritize the finite-model/Rust bridge and answered yes to running the bounded experiment (D124). Building on `codex/finite-rust-correspondence`, from main; unmerged experiment 9 remains separately In Review. Existing Lean rules, proofs, checks and helper remain unchanged. Freeze schema/corpus/checks and Lean-generated expectations before Rust implementation. Continue earlier owner preference for self-verification, accurately labelled; generated expectations come from the existing accepted model. No full3c, calls/recursion, unrelated candidates or automatic merge. Stop on mismatch/ambiguous boundary, preserve evidence, then return to remaining Needs Input discussion. Earlier proposal status below is historical.

## Current status — 2026-10-06

Needs Input: a concrete next-candidate proposal and the conditions for the other parked candidates are recorded below. Scientific execution needs scoped approval and a new acceptance lock. No existing proof, rule, acceptance file or lock changed, and no experiment ran.

## Proposed finite-trial/Rust correspondence experiment

**Question.** Can an executable Rust backend reproduce the accepted finite trial's answers, retained-holder snapshots and logical list-cell allocation/reuse/free observations? The accepted Lean trial proves its model; it does not prove a Rust implementation follows that model.

**Scope and tools.** Use the accepted finite language only: numbers, lists, names, let/if/match and its existing operators. No calls, recursion, demand checker, concurrency or native code loader. Keep the [accepted Lean evaluator/rule](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RESULT.md>) and the 3b helper read-only. A new Rust adapter/interpreter may use the helper in an isolated experiment. Any mismatch with the frozen reuse rule is a result to explain, not permission to change that rule.

**Acceptance prepared separately.** Freeze the observable schema and independently generated expected cases before implementation. Begin with all 28 frozen examples and valid shared/unique starting memories. Add a finite corpus with expression depth at most three, at most three initial cells, two named roots and numeric inputs -1/0/1. State generation exclusions and actual case count; this is finite correspondence evidence, not a universal refinement proof.

Compare answers and every specified outside-holder/holding-name snapshot, logical cell creation/reuse/free totals and final reachability/counts. Normalize addresses through a consistent identity mapping across the entire trace; equal list values alone must not hide changed sharing or freed live cells. Count all logical cell creation from the beginning of backend evaluation, including preparation and later-freed cells. Initial fixture construction is reported separately. Count allocator bytes/events independently so Vec/number/bookkeeping allocation is not mislabeled as a list-cell allocation.

**Controls.** Shared mutation, early freeing of a held cell, retaining unreachable tails, always allocating replacements, and copying before the reported interval must each be distinguishable. A successful process exit cannot substitute for checking the report. Preserve failing cases, schemas, source identities and unchanged original fingerprints.

**Stop and recommendation.** Stop on a mismatch, ambiguous logical allocation boundary, extra proof assumptions, changed accepted bytes or a control the checks cannot detect. Report the gap without widening the language or weakening predictions. Recommend this finite bridge before a full compiler/backend correspondence claim; passing it neither proves calls/recursion nor satisfies full3c.

## Conditions for the other parked candidates

* Repeated-sharing tree measurement: propose only when the list result leaves a specific unanswered tree question; no such question is established here.
* Allocation budgets: require a named workload, resource definition and independent refusal/over-budget checks; no budget policy is selected.
* Trees/records: require separately specified meanings, preservation promises and acceptance beyond the finite list language.
* Runtime refusal before copying: require an approved promise identifying the refusal boundary and allowed prior effects; no runtime demand policy is inferred.

These remain candidates. This proposal does not create an execution queue or amend [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment)'s scientific gates.

---

Candidates, not approved builds: repeated-sharing tree case only if the list case leaves a specific question; allocation budgets; compiling onto the Rust helper and checking semantic correspondence/allocation counts; trees and records; runtime refusal before copying. Formulate one concrete question and evidence criteria before seeking approval.

Stop condition: produce a plain-English proposal naming claims, comparison tools and limits, acceptance evidence, and an execution stop rule; wait for Robert’s approval. No implementation is authorized by migration.

Source: [https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/PLAN.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/PLAN.md>)
