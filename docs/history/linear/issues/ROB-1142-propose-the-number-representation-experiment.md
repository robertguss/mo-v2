# ROB-1142: Propose the number-representation experiment

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1142/propose-the-number-representation-experiment
> Status at export: Done
> Created: 2026-10-02
> Updated: 2026-10-07
> Completed: 2026-10-06
> Comments: 0

---

## Description

## Reconciled current status — 7 October 2026

Completed and merged integer comparison; Mo’s permanent numeric policy remains open. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) separately uses owner-approved exact growing integers for the prototype only. Historical proposal wording about separate checks does not change the accurately reported same-author verification of this comparison.

Earlier records follow, preserved as history.

## Merged — 6 October 2026

6 October 2026. Robert instructed “merge it, then continue the next needs input discussion”. Integer comparison fast-forward merged to main at 03705f1dac1de8cbc9efedaf99ad4feeb62c17a3; pushed remote main verified. All six frozen-check fingerprints and 55 artifact fingerprints unchanged. Existing results retained; no new test execution was needed for the content-preserving merge. ROB-1142 is Done for the comparison, not a choice of Mo numeric default. Unrelated CLAUDE.md edit preserved. Experiment 9 remains separately In Review.

## Completed comparison — In Review, 6 October 2026

Integer comparison passed at 03705f1dac1de8cbc9efedaf99ad4feeb62c17a3 on `codex/integer-policy-comparison`, pushed and remote verified. [Report](<https://github.com/robertguss/mo-v2/blob/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3/experiments/11-integer-policies/RESULT.md>). Both builds passed 12,563 frozen cases; four real compiled broken variants caught; 627 checked measurement executions (570 interleaved timing + 57 allocator), 18 fixed-width wide-input refusals. Expectations frozen at 955187b before Rust. Calibrated allocator, separate uninstrumented timing, complete raw evidence, all caps satisfied. Same-author verification, not independent acceptance. Common million-step big-integer arithmetic took approximately 10–13 times checked i64 time for these specific implementations/workloads; checked versus wrapping much closer. Explicit benchmark routes reuse the same homogeneous backends, so no typing-overhead claim. No streaming/in-place BigInt optimization or agent study. Recommend discussing checked fixed integers with explicit big integers and deliberate wrapping; no Mo default chosen. Prior fingerprints unchanged; unrelated CLAUDE.md edit excluded. New branch is In Review, not merged; experiment 9 remains separately In Review. Return to remaining Needs Input discussion, no next experiment authorized.

Earlier statuses and proposal below are historical.

## Authorized — 6 October 2026

Robert instructed “merge it and then work on your rec” after recommending the four-policy integer comparison (D125). Building on `codex/integer-policy-comparison`. Fixed outcomes/checks precede implementation; same-author verification under current owner preference, with Python exact-integer reference separate from Rust implementation. Compare all four policies without selecting Mo's default; retain prior files and any failures. Branch-push delivery only. Earlier proposal status below is historical.

## Current status — 2026-10-06

Needs Input: the bounded comparison below is prepared for scientific scope/acceptance approval. No numeric policy is selected for Mo, no benchmark ran, and no existing specification or lock changed.

## Proposed integer-policy comparison

**Question.** How do four policies differ in observable behavior, resource cost and repair guidance: signed 64-bit integers with explicit overflow failure; signed 64-bit modular arithmetic; arbitrary-size integers; and explicitly chosen fixed/big integer types with explicit conversions?

**Tools.** Use one Rust driver/allocator for the fixed arms, explicit [checked and wrapping operations](<https://doc.rust-lang.org/std/primitive.i64.html>), and a pinned [num-bigint](<https://github.com/rust-num/num-bigint>) release for the arbitrary-size arm. An independently authored exact-integer reference supplies expected mathematical answers and modulo-2^64 results. Pin versions, flags and source before execution. These are experiment tools, not a permanent compiler/backend decision.

**Workloads.** Compare running totals, integer parsing/aggregation and bounded counter arithmetic at 1,000, 100,000 and 1,000,000 operations. Separate the common representable domain from boundary/large-number cases. Exercise zero, negative values, 2^31 and 2^32 boundaries, signed 64-bit minimum/maximum, addition/multiplication overflow, negating the minimum, invalid input and division by zero. Include inputs whose intermediate values exceed 64 bits even when their final answer fits. Big-integer cases include fixed 128- and 1,024-bit inputs; “arbitrary size” does not mean unbounded resource availability.

**Acceptance.** Before implementations, a separate author fixes each arm's semantics and readable expected outcomes. Within the common domain answers agree. Outside it, deliberate failure, modular results and exact big-integer results are scored against their own declared policy, never treated as interchangeable. Explicit-type conversions reject out-of-range narrowing and require an explicit conversion for mixed types. Wrong wrapping, silent narrowing and unexpectedly successful overflow are negative controls. State signed division/remainder conventions explicitly before checks, including the minimum divided by -1.

**Measurements and limits.** Retain all samples from ten interleaved repetitions per workload; record elapsed time, allocation count, live/peak requested bytes and separately process peak memory. Setup/parsing is reported separately from arithmetic. Publish examples of each result/refusal and conversion burden; no agent-usability claim without a separately approved agent study. The [original numeric question](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/design-choices/10-how-are-numbers-represented/README.md>) and benchmark 4's historical ratio do not decide Mo's default.

**Stop and recommendation.** Stop on an unspecified outcome, oracle disagreement, invalid instrumentation or resource-cap breach, preserving evidence. Correct but slower behavior is a valid result. Recommend measuring all four arms before selecting a default; do not silently inherit v1's overflow policy. No floats, decimal finance policy, production runtime or full language design is included.

---

Open design choice 10: compare fixed size with overflow failure, fixed size with wrapping, unlimited size by default, and several explicit types. State claims, realistic workloads, correctness and measurement criteria before choosing tools or answers. Trial unlimited integers and v1 crash-on-overflow preferences do not settle Mo. Benchmark 4’s 1.68× observation is scoped evidence, not a general rule.

Stop condition: produce a plain-English proposal naming claims, comparison tools and limits, acceptance evidence, and an execution stop rule; wait for Robert’s approval. No implementation is authorized by migration.

Source: [https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/design-choices/10-how-are-numbers-represented/README.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/design-choices/10-how-are-numbers-represented/README.md>)
