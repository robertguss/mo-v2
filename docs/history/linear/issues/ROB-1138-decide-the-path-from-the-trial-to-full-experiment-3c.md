# ROB-1138: Decide the path from the trial to full Experiment 3c

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c
> Status at export: Done
> Created: 2026-10-02
> Updated: 2026-10-09
> Completed: 2026-10-09
> Comments: 0

---

## Description

## Accepted scope — 9 October 2026

**D185: Robert accepted [formal contract v2](<https://linear.app/robert-guss/document/full-3c-post-stage-b-formal-contract-v2-9-october-73682eae811b>).** [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) **is Done:** the bounded scope/contract preparation and owner decision are complete. This is not a completed proof, checker or executable acceptance package.

Continue with exact acceptance preparation tracked under [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment). Preserve separate acceptance authorship/verification and agree the preparation arrangement before dispatch. The exact definitions, statements, predictions, Koka evidence, checks and lock candidate still require preparation and review; proof/checker execution remains separately gated. No repository code changed. Earlier checkpoints are historical.

## Current deliverable — 9 October 2026: v2 contract ready for review

D184's bounded preparation is complete. [Full-3c contract v2](<https://linear.app/robert-guss/document/full-3c-post-stage-b-formal-contract-v2-9-october-73682eae811b>) reconciles the approved Stage B behavior with the finite trial, preserves all four approved semantic choices and all 27 inherited usefulness categories, and defines six core proof obligations plus two explicitly proposed lifecycle obligations. It retains C1–C14 and adds C15–C22 to distinguish pending arguments, interrupted cleanup, unused-parameter entry, shadowing, exact-budget finish, denial, non-tail recursion and transient allocating loops.

**Recommendation:** an independent plain meaning and a counted small-step model with explicit continuations, following the accepted ownership order; first prove rule correctness, then separately authorize the conditional checker and caller enforcement. The formal model is not the Rust interpreter, and empirical Stage B acceptance is not a Rust refinement theorem. Normal termination correspondence assumes mathematical allocation; controlled denial/destruction is a separate stated layer.

**Remaining review/approval:** approve/amend the v2 English scope (including L1/L2 lifecycle obligations) as the basis for separately authorized exact acceptance preparation. That next work must supply independently derived expectations, formal definitions/statements, Koka comparisons, review and a lock candidate. Independent scientific review, exact theorem/code interfaces, execution roles and effort policy remain pending. Do not start proof/checker implementation from this draft or mark [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment) ready.

**Checked now:** authoritative contracts, trial interfaces/limitations, all six usefulness families (12+6+1+3+3+2 = 27), and preservation of the historical draft. Linear edits were read back. No candidate/comparator run, private-corpus access, Lean encoding/proof, scientific lock, repository edit, commit, push or deployment. Status In Review means proposal review, not accepted formal specification. Earlier checkpoints below are historical.

## Active preparation — 9 October 2026

D184: Robert selected [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) next in [this thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). Preparing the post-Stage-B formal contract and acceptance gates; no implementation/proof campaign. The previous recommendation is now authorized as preparation only. Existing scientific approvals and locks remain unchanged.

## Current checkpoint — 9 October 2026, after Stage B

[ROB-1333](<https://linear.app/robert-guss/issue/ROB-1333>) is accepted, merged and Done; [Stage B acceptance matrix](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/STAGE_B_RESULT.md>). Source-driven functions/recursion now have finite execution evidence. This does not prove the full-3c rules or implement/prove the demand checker. The four scoped semantic choices already approved remain approved; they need not be asked again.

**Recommended next work, not approved execution:** reconcile the existing calls/recursion draft with the accepted prototype contract, identify only genuine semantic gaps, and prepare exact full-3c proof obligations, distinguishing examples and acceptance gates for review. The first formal target remains slice 1/stage 1 rule correctness with calls and recursion; checker construction follows the separately approved stage-2 gate. Preserve the accepted trial and Stage A/B locks. Stage B's same-agent exception does not automatically change full-3c acceptance authorship.

**Stop condition:** a reviewable contract and explicit unresolved decisions, not a new implementation or proof campaign. This is an agent recommendation following Robert's request to reconcile tracking and suggest next work, not his selection of the next milestone. Remains Needs Input; [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment) remains blocked on this decision. Earlier status below is historical.

## Reconciled current status — 7 October 2026

The four scoped calls/recursion choices remain approved; full3c formal acceptance and execution remain gated. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) now has its own approved v12 prototype contract and conditional Stage A sequence. That does not authorize full3c proofs, demand-checker construction, Koka comparison or a full3c lock. Earlier workflow/budget recommendations and copy-feedback next-discussion wording are historical, not today’s execution queue.

Earlier records follow, preserved as history.

## Invocation accounting boundary approved — 6 October 2026

6 October 2026. Robert answered “yes” to beginning the zero-new-list-cell promise at function entry, after explicit argument expressions finish. Entry work, including any hidden copying, counts; all work inside the call counts, including descendant calls, their argument preparation, and cells created then freed. Explicit caller input construction before entry is outside that invocation's interval and remains visible in the whole-program record. This approves the experimental accounting boundary presented in the discussion; it does not approve all remaining formal details, acceptance, implementation or execution.

The four discussed semantic choices are recorded in the specification and live register. Remain Needs Input for exact formal acceptance, remaining detailed rules, review, budget and execution authorization. No full-3c implementation started. Continue the broader Needs Input discussion with the separate copy-feedback proposal ROB-1141; this does not approve or reprioritize execution.

## Continuous live-value protection approved — 6 October 2026

6 October 2026. Robert answered “yes” to protecting every live caller value and temporary throughout execution of the calls/recursion experiment, rather than only selected snapshots. Suspended callers' retained values and completed arguments waiting during later argument evaluation must preserve their readable values while live. Storage may become eligible for reuse after the value is no longer needed, subject to the approved ownership/reuse rules. This is a new extension obligation, not a claim that the finite trial already proved it. Approval covers this protection requirement only; exact formal statements, acceptance and implementation authorization remain pending.

Call-local reservations and resumable recursive observations are also approved. Remain Needs Input. Next discussion concerns the exact invocation boundary for the existing zero-list-cell-allocation promise.

## Recursive observation choice approved — 6 October 2026

6 October 2026. Robert answered “yes” to allowing unrestricted recursion with bounded, resumable observations for the calls/recursion experiment. Observation outcomes distinguish finished, failed and still running (suspended). Exhausting the observation budget preserves execution state for continuation; it is neither successful completion nor proof of infinite execution. This does not require every function to terminate or make the observation budget a language-level execution limit. Approval covers this experimental semantic choice only, not the complete specification, formal encoding, acceptance lock, proof/checker work or execution.

Call-local reservations were previously approved. Remain Needs Input for remaining specification/acceptance choices. Next discussion: protecting suspended caller values and completed arguments while other work executes.

## Call-local reservation choice approved — 6 October 2026

6 October 2026. Robert answered “yes” to keeping reservations within each call for the first calls/recursion experiment. A helper cannot consume a cell set aside by its caller; the caller retains its reservation while the helper runs. Existing proposed C1/C2 distinguish the resulting allocation behavior. This approves that experimental semantic choice only, not a permanent Mo rule, the rest of the draft, acceptance lock, proof/checker implementation or experiment execution.

Remain Needs Input. Next discussion is recursive execution and bounded observations; other draft approvals remain pending.

## Current workflow correction — 2026-10-06

D108, Robert's instruction to work here in Codex and retire Amp/Herdr, supersedes the operational dispatch recommendations and outside-Herdr explanation below. Missing Amp or Herdr is not a current Mo workflow gate. Needs Input remains for scoped scientific decisions, independent review of the new calls/recursion draft, and approval of its exact semantics/acceptance before a new lock. No independent review is claimed by this correction; the accepted finite trial and all existing locks remain unchanged.

## 5 October: concrete specification draft prepared

Robert asked Codex to carry out the recommendation to prepare the smallest precise specification for calls and recursion, preserving the completed trial. [The draft specification](<https://linear.app/robert-guss/document/full-3c-calls-and-recursion-specification-draft-5-october-73682eae811b>) now gives proposed call/holder/reservation rules, recursive execution and suspension, precise demand accounting, proof obligations, 14 distinguishing cases, and the acceptance preparation sequence.

This authorizes and records preparation, not approval of the proposed semantics or full-3c implementation. New recommendation: reservations stay within each invocation; alternatives and distinguishing cases remain explicit. Exact expectations still require a separate predictor after the English rules are approved. No trial file, scientific lock, proof or checker changed; no comparator ran. Other research stays deferred.

Independent scientific review and Robert’s scientific choice remain pending. Missing Amp/Crew skills and HERDR_ENV are not blockers; their operational workflows are retired. Historical scientific criteria, locks and independent acceptance authorship remain unchanged.

---

**Bounded proposal preparation complete; follow-on scope remains gated.** Lead and Oracle prepared this under D104 (Robert’s AFK delegation). This is a proposal, not Robert’s scientific decision or an approved implementation brief. No new encoding, comparator runs, locks or Builder dispatch. Preparation stop condition met: evidence-linked options, distinguishing examples and authorization gates are recorded below. Issue remains open pending the scoped decision.

## Evidence and recommendation

[Accepted trial result and limits](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RESULT.md>): all four finite-language promises passed separate Lead/fresh Tester acceptance; frozen fingerprints unchanged; standard Lean axioms only. Authorized elapsed proof work was 4h08m34s, not a forecast for full 3c. Calls, recursion and a demand checker remain unproved. Combined proof/evidence branch was merged and pushed to main at e6a895c8ce2887d9bee6986819a779f8f74b5541 with Robert’s approval; confirmed against remote main during the 5 October review.

Recommendation: prepare the smallest full-3c extension that can honestly describe calls and possibly endless recursion, retaining the trial unchanged as a control. Assess alternatives before choosing an encoding; do not build competing implementations merely to choose architecture. Model agreement is not experimental evidence.

| Option | Benefit | Risk / deciding evidence |
| -- | -- | -- |
| A: retain memory operations and as much evaluator structure as appropriate | Reuses the tested memory vocabulary and potentially useful lemmas | The current evaluator/proof follows expression structure; arbitrary recursive calls need a new execution/proof formulation even here. Reject this approach if suspended callers or finite execution prefixes cannot be stated clearly. |
| B: narrowly change execution interface, retaining memory layer where justified | Can expose calls, suspended ownership and finite prefixes directly | More correspondence work; justify changes by concrete semantics/proof obligations, not preference. |
| C: defer full 3c | Avoids committing to unclear rules or unbounded effort | Leaves the demand-checker question unanswered; appropriate if specification cost exceeds the information sought. |

Under A or B, require finite-fragment agreement on answers, protected lists, creation/reuse/free events and approved timing observations. The 28 frozen examples are regression evidence, not universal equivalence. Existing lemmas are reuse candidates, not assumed to apply unchanged.

## Questions and examples that must distinguish the proposed rules

Predictions must be written independently before encoding. These are proposed cases, not approved expected results or checker verdicts.

| Question | Distinguishing case | What the approved specification must say |
| -- | -- | -- |
| Reservation across calls | Caller sets aside a matched cell, helper builds a cell, caller builds another after return | May helper consume caller reservation; which reservation wins; when unused reservations are freed. Predict counts and timing for each policy. |
| Suspended ownership | Caller needs a shared tail after helper returns; first argument remains live while later arguments execute | Which references protect storage during the call and argument evaluation; how return ownership transfers. |
| Aliasing versus actual allocation | Same argument passed twice; shared list used only for reading | Aliasing alone is not allocation. Specify bodies and outcomes before proposing accept/reject examples. |
| Honest allocation count | Callee creates then frees a cell; callee invokes a helper which creates a cell | Count actual creation events including freed cells and descendant calls. Final memory size cannot substitute for total allocations. |
| Demand interval | Explicit caller creates a fresh list; implementation secretly copies to manufacture exclusive ownership | Set boundary relative to argument evaluation. Permit ordinary explicit caller allocation; disallow hidden copying that evades the measured promise. |
| Recursion and stopping | Deep finite recursion; endless recursion with allocation; endless recursion without allocation | No unconditional-finishing claim. Fuel exhaustion is inconclusive, not success or proof of divergence. |
| Visibility coverage | Caller-held values, temporary argument values and outside holders across call/return | Explicitly resolve or accurately retain the trial’s snapshot/temporary-value limitations; do not silently claim stronger protection. |

## Proposed obligations and inherited stage gates

Preserve the full plan’s two slices and rule-correctness-first order:

1. Stage 1 concerns all well-formed programs with valid starting memory, including shared inputs, not only checker-accepted programs. Propose correspondence of plain/counted termination with equal answers; safety and specified observations throughout ongoing execution; final no-leak only at actual whole-program completion, retaining answer/outside-holder cells. These are proposed new statements, not accepted trial theorems. No claim of bounded memory for endless execution.
2. Stage 2 concerns accepted demanded functions: zero actual creation events, including descendant calls, under the approved unshared-input condition, plus useful examples preventing a reject-everything checker. An endlessly allocating ordinary program can meet Stage 1 while failing a demand; nonallocating divergence is not itself a demand violation.
3. Slice 2 concerns accepted callers enforcing that promise for every demanded invocation. Stage 1 → Stage 2 and subsequent slice execution retain explicit go-ahead gates.

Prepare shared specification/examples for both slices, plus the required slice/stage promises and briefs. Perform the specified Koka 3.2.9 slice-1 comparison before locking examples; it is not the trial’s runtime oracle. No Rust comparison is proposed here. No comparator run has been performed for this proposal.

## Budget, execution and authorization

Budget options are explicitly no total cap or an agreed cap. The existing draft proposes a per-slice budget shared across stages; per-stage caps would be an amendment. Recommend retaining two-hour reports and choosing the cap policy before dispatch. Reporting cadence, automatic continuation and total cap are separate choices. Trial elapsed time does not estimate full-3c effort.

Recommend visible fresh Amp Builder/Tester orbs, separate Lead/Tester acceptance and additional Oracle review for follow-on work. The high-mode fallback was operational recovery, not a model capability result. The trial-only exception does not silently authorize this arrangement for full 3c.

Remaining decisions: whether full 3c proceeds; whether/how to adopt the trial foundation; exact call/divergence semantics, examples and theorem statements; budget; execution roles/model/continuation policy. Resulting scientific specification and acceptance require their own explicit approval and preserved-history lock before implementation. No existing trial requirement is weakened. Merge authorization remains separate.

Stop: record the scoped decision and evidence; do not start full-3c implementation from this proposal alone. No Ready issue was available at the final queue check.

## Sources and review

* [Full 3c draft plan](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/PLAN.md>)
* [Trial plan, including What it feeds](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/PLAN.md>)
* [Lead and Oracle review conversation](<https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7>)

Oracle found no blocker to bounded preparation and required the corrections incorporated here: both extension options need recursive-execution reformulation; explicit reservation/suspended ownership cases; separate rule correctness from demand enforcement; precise demand accounting boundary; retain per-slice budget semantics and follow-on authorization gates.
