# ROB-1145: Park Experiment 2 follow-ups for evidence-led proposals

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1145/park-experiment-2-follow-ups-for-evidence-led-proposals
> Status at export: Needs Input
> Created: 2026-10-02
> Updated: 2026-10-07
> Comments: 0

---

## Description

## Reconciled current status — 7 October 2026

The specification-gap case below is an agent recommendation, not Robert’s selected next experiment. No follow-on experiment ran. Larger review and correct-by-construction candidates remain deferred; the lower unranked-candidate record is historical. Original Experiment 2 specification/results remain unchanged.

Earlier records follow, preserved as history.

## Current status — 2026-10-06

Needs Input: one bounded next experiment is proposed below, ready for scoped scientific approval. No proof, model review or paid inference ran; the original Experiment 2 specification/results remain unchanged.

## Proposed specification-gap experiment

**Question.** Can a version be provably correct against an incomplete specification while violating an independently stated user expectation? This tests specification coverage, not Lean soundness.

**Chosen bounded case.** In a new isolated experiment copy, retain the withdrawal interface but omit only the original “a withdrawal of zero is invalid” clause from a deliberately weakened specification. A variant that returns the unchanged balance for a zero withdrawal, and behaves like the accepted implementation otherwise, should satisfy the other three promises. The original complete specification and its zero examples must reject that variant.

**Tools and checks.** Use the original pinned Lean toolchain, without editing the accepted files. Before implementation, an independent acceptance author freezes the full/weak specification pair, plain-English expected matrix and counterexamples. Check the correct implementation against both specifications; check the zero-success variant against the weak specification; evaluate its contradiction of the full zero requirement. The required witness is balance 100 cents, amount zero: the variant succeeds with 100 while the complete intent requires invalid amount. Also retain the original zero-balance/zero-amount case.

A passing weakened proof alone is insufficient. Record exact theorem statements and axiom lists, a clean build, executable outcomes and the full-specification contradiction. Reject unfinished proofs or added assumptions. Reintroducing the missing clause must block the variant, while the original correct implementation remains accepted. The original example suite is a separate evidence source that catches this gap; do not remove its zero examples to manufacture a result where every method misses it.

**Interpretation.** Report whether the expected matrix holds. A proof certifies its stated premises; this experiment does not establish general superiority of proofs or tests. The [original seven-method result](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/02-withdraw/RESULT.md>) remains one small function, one bug mix and one reviewer run.

**Other candidates.** Larger single-version council review remains deferred pending a frozen program/bug corpus, reviewer model and provider budget. Correct-by-construction types remain deferred pending one behavior and a counterexample they are meant to exclude. Neither is bundled into this first experiment or treated as approved.

**Stop and recommendation.** Stop on oracle/spec disagreement, changed original bytes, extra proof assumptions or an unexpected matrix outcome; preserve counterexamples and do not weaken checks. Recommend the specification-gap case first because it isolates a concrete limit without paid agent calls. Approval covers only this new experiment and separately authored checks, not changes to Mo's accepted promises or locks.

---

Unapproved candidates: test the spec gap; test council review on a harder, larger single version; test correct-by-construction types. Preserve the original seven-method planted-bug result and its limits. Select and approve one bounded experiment before execution; no ranking invented here.

Stop condition: produce a plain-English proposal naming claims, comparison tools and limits, acceptance evidence, and an execution stop rule; wait for Robert’s approval. No implementation is authorized by migration.

Source: [https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/02-withdraw/RESULT.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/02-withdraw/RESULT.md>)
