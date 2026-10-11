# ROB-1139: Full 3c: gated conditional and unconditional demand-checker experiment

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment
> Status at export: Building
> Created: 2026-10-02
> Updated: 2026-10-11
> Comments: 7

---

## Description

## Slice 1 stage 2 complete locally; stop at the slice-2 gate — 10 October 2026

**The actual conditional demand checker and exact frozen theorem are complete:** Full.Demand.Soundness.conditional : Full.Statements.Conditional Full.Demand.accepts. Accepted demanded invocations with the approved unique/disjoint entry premise have zero primitive Creates in every finite invocation prefix, including descendants and later-freed cells. No additional hypothesis, model amendment, caller enforcement, unconditional result or Rust refinement is claimed.

**Final-source verification passed:** pinned Lean 4.34.0, cache-free exact rewritten stage-1 archive plus 19 additive checker/proof sources, 172-job build, 525 public/generated theorem constants audited with only propext/Classical.choice/Quot.sound, fresh DemandAudit kernel check, and unchanged eight-target stage-1 gate/fresh kernel. A separate verifier independently repeated these checks and 3 proof rejection controls. Same-account procedural separation, not independent-account certification. It found a missing Lean command import in the builder audit gate; that operational defect was fixed and the complete stock reproduction reran successfully. The original failed gate and review remain historical.

**Unchanged acceptance and usefulness:** 90 cases, 84 frozen finished-answer/ledger checks, 820 expanded checks, 12 export-corruption controls, 4,498 internal equalities, 9,680 views, 3 boundary controls, 28 Trial comparisons and 21 machine mutants. All 27 categories retained: slice1 12 accepts/6 refusals/1 observation pass; slice2 3/3/2 deferred. Actual-source accept-all/reject-all/missing-affine controls produce 33/38/3 intended failures; missing-affine accepts twice at unique entry yet allocates 2 cells. Six principal refused functions allocate 3/1/1/3/2/1 cells. Ordinary arithmetic-only helper refusal remains a usefulness limitation, not an allocating witness.

**Integrity/delivery:** all 423 frozen inventory entries pass; current 19 source hashes and 155 stage-2 record entries pass. Final and separate verifier results and all five checker executions are identical. Regenerated raw observations are byte-identical to the existing D191 release asset; no new gzip/history object or large artifact. Work remains **local, uncommitted and unpushed** on proofs/[ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment)-stage2, based exactly on remote stage1 [66f8aac](<https://github.com/robertguss/mo-v2/commit/66f8aac22fbaa31100700a5ca9e5b486efd67c28>). No merge, deployment or delivery CI run; Buildkite90's canceled jobs are still not a CI pass or proof failure.

Result/reproduction/manifests and separate review: experiments/03c-checker/full/stage-2/completion/ in [the execution thread](<https://ampcode.com/threads/T-01a126e2-69f9-751a-8aff-1a2e19a7e821>). **Needs Input, not Done for the whole experiment:** stage2 work stops here as authorized. Publishing requires delivery authorization; caller ownership enforcement and the unconditional guarantee remain separately gated slice2. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) remains Done. Earlier incomplete-stage2 descriptions below are historical.

## Stage 2 authorized and starting — 10 October 2026

Robert's explicit stage-2 go-ahead clears the former Needs Input gate. Work is in [the stage-2 thread](<https://ampcode.com/threads/T-01a126e2-69f9-751a-8aff-1a2e19a7e821>), on proofs/[ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment)-stage2 starting exactly from remote stage-1 [66f8aac](<https://github.com/robertguss/mo-v2/commit/66f8aac22fbaa31100700a5ca9e5b486efd67c28>), not main. Scope: executable conditional checker, exact Full.Statements.Conditional proof, unchanged usefulness/refusal expectations and separate verification. Concrete write boundaries are being derived from the accepted v2 contract. No stage-2 result or proof is yet claimed.

Caller ownership enforcement and unconditional guarantee remain separately gated slice 2. No frozen-meaning amendment, merge, deployment or new scientific authorization is inferred. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) remains Done. Stage-1 local clean verification passed; Buildkite 90 canceled both jobs without checks and is not a delivery-CI pass. Earlier stage-2-awaiting-approval wording below is historical.

## Stage 1 complete; stage 2 awaits explicit go-ahead — 10 October 2026

**All 8/8 exact F1–F6/L1–L2 obligations are proved against the approved D191 amended model.** The unchanged ProofGate compiles all fully qualified types; complete transitive axiom sets contain only propext/Classical.choice/Quot.sound. F6 covers every Trial expression by structural induction and full ordered landmark equality; no hidden successful-Full-evaluation premise survives. No new model amendment or weakened statement.

**Verification:** cache-free original rewritten freeze plus authorized Control and only permitted proof sources: 153 build jobs pass; exact ProofGate and pinned Lean 4.34.0 fresh kernel exit 0. All auxiliary proof modules also build (155 jobs). A different verifier independently ran exact gate/kernel/axiom checks and 3/3 proof rejection controls. Same-account procedural separation, not independent-account certification. All 423 final inventory entries (342 frozen/evidence plus 81 proof files) pass.

**Unchanged finite acceptance:** 90 cases, 84 finished checks, 820 expanded groups, 12/12 export corruptions, 4,498 internal equalities, 9,680 views, 3/3 boundary corruptions, 28 Trial comparisons, and 21/21 executed faulty routes with passing baselines. Regenerated raw observations are byte-identical to the existing D191 release-archived evidence; no new gzip was committed.

**Delivered:** committed, pushed and remote-verified at [66f8aac](<https://github.com/robertguss/mo-v2/commit/66f8aac22fbaa31100700a5ca9e5b486efd67c28>) on `proofs/rob-1139-stage1`. Worktree clean; rewritten branch history contains no .gz objects. [Result, reproduction and manifest](<https://github.com/robertguss/mo-v2/tree/66f8aac22fbaa31100700a5ca9e5b486efd67c28/experiments/03c-checker/full/stage-1/completion>), including separate verifier review and logs. Main unchanged; no PR, merge or deployment.

**Delivery CI limitation:** [Buildkite 90](<https://buildkite.com/robert-guss/mo-v2/builds/90>) failed immediately with both jobs canceled, no logs and no checks executed. This is not reported as a CI pass; the separate clean stage-1 acceptance above succeeded in the orb. No workflow was manually rerun.

**Needs Input, not Done for the whole experiment:** stop after this completed stage-1 result. Next recommended work is slice 1 stage 2, the conditional demand checker and its proof/usefulness/refusal controls, only after Robert's explicit go-ahead. Caller enforcement and unconditional guarantees remain separately gated slice 2. No native/Rust refinement or physical-resource guarantee is claimed. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) remains Done. Earlier partial-status and delivery paragraphs below are historical.

## Continuing stage 1: reachable typing completed — 10 October 2026

**Building; still 2/8 exact targets (F5/L1).** The amended-model proof now establishes typing preservation for every successful Counted transition and every reachable finite prefix, including lexical environments, operand stacks, call signatures and return kinds. Fresh kernel checks passed for CountedTyping and reservation accounting. Unconditional reachable cleanup results establish no holding bindings, reservations, frames, tasks or release chain at an answered state. Saved-context environment IDs are proved distinct and bounded. The exact F4 conclusion is derived conditionally from F1; it is not an unconditional completed target.

Continuing the coupled binding-use/release-control and heap-preservation work needed for F1, then forward simulation and full Trial compatibility. No new model defect or approval gate is claimed. Continuation proofs are local/uncommitted/unpushed in [the working thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). Frozen model, statements and acceptance checks remain unchanged; no checker/caller work, PR, merge or deployment. The earlier progress descriptions below are historical.

## Amended freeze complete; stage 1 resumed — 10 October 2026

D191's approved Decompose weight 10→12 has passed separate review and clean reconstruction/fresh-kernel verification. The additive amended freeze is preserved locally at commit 1a8a18c55886ad99cc4b5bc75c33df0a080fa009 on proofs/[ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment)-stage1, in experiments/03c-checker/full/stage-1/rank-amendment-01/. The original failure, old freeze and inventories remain unchanged; this is not a retroactive pass of the old model. No additional push, merge or deployment has occurred.

Unchanged finite acceptance passes: 90 cases, 84 finished checks, 820 groups, 12/12 corruption controls, 28 Trial comparisons, 21 faulty routes, and 4,498 internal equalities / 9,680 boundary views. The generated call diagnostic subsequently completed all 4,000 typed programs successfully, superseding the frozen record's accurately contemporaneous “continuing” note. These checks do not establish the universal statements.

**Still Building, 2/8 exact positive targets complete (F5/L1).** Proof construction has resumed under the proof-only scope and no-discretionary-checkpoint instruction. The active gap remains joint residual task/slot/frame and ownership preservation, then exact F1/F2/F3/F4/F6/L2 and the unchanged full gate. The earlier amendment-in-progress descriptions below are historical.

## Approved rank amendment in progress — D191, 10 October 2026

Robert approved Decompose weight 10→12, separate review and an amended freeze preserving the old counterexample, then resumption of stage 1 in [the working thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). Status returns to **Building**, not Done. The old failure and all partial proofs have first been preserved in a local Git checkpoint. The only model edit is the approved weight; exact F1–F6/L1–L2 statements, execution/Plain semantics, predictions and old inventories remain unchanged. New regression checks and separate verification are in progress. No amended freeze or stage-1 completion is yet claimed. Earlier Needs Input/unapproved-amendment wording below is historical.

## Verified frozen F2 contradiction — 10 October 2026

**Needs Input: stage 1 cannot pass as frozen.** D190 records Robert's instruction to continue without discretionary partial checkpoints. Work continued until the existing scientific stop condition was reached: a concrete contradiction to exact Full.Statements.F2, not merely a proof-construction gap.

**Minimal example:** f() returns 3; match \[1,2\], then call f() without using the head or tail. Counted steps 14→15 preserve the decoded Plain state and rank 19→19, while Plain.step would enter f. Thus both alternatives of F2's one-step obligation fail. A shared-input variant at steps 4→5 increases rank 19→20. Both examples finish with answer 3 and pass source/target data-invariant and final-graph checks; this is not demonstrated memory corruption.

**Decisive evidence:** Full.Proofs.RankCounterexample.not_f2 : ¬ Full.Statements.F2. Clean archive of frozen a17f652 plus only the negative proof and reproducer: 14 build jobs pass; pinned Lean 4.34.0 fresh kernel check exits 0; axioms are only propext/Classical.choice/Quot.sound; working proof bytes match clean checked bytes. A different verifier independently inspected all premises, both disjuncts, fallback non-vacuity and imports and repeated build/kernel/runtime checks. Same-account procedural separation. All original inventories pass (2/237/75 plus 17/17 historical checkpoint entries).

**Preserved work and limitations:** F5/L1 remain the only two completed positive targets. Eight additional proof modules build together (88 jobs), with 113 allowed-or-empty public theorem axiom sets; they include conditional L2/F2 consequences and independent Plain typing, not positive F1/F2/F3/F4/F6/L2. The unchanged full ProofGate still exits 1. Diagnostic Trial generation passed 3,000 programs; the call search stopped at its first failure (index 59), not a 4,000-case pass. Old finite acceptance/control results are retained, not newly rerun.

**Evidence/delivery:** experiments/03c-checker/full/stage-1/counterexample/{RESULT.md,REVIEW.md,Reproduce.lean,evidence/}, with the proof in lean/Full/Proofs/RankCounterexample.lean, are local, uncommitted and unpushed in [the working thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). Previous pushed head remains [ea0fde9](<https://github.com/robertguss/mo-v2/commit/ea0fde992d7f9d59bf5f5bedda6e911f4edb8baf>). No frozen file, main, PR, merge, deployment or later checker stage changed.

**Proposed next decision, not approved or implemented:** permit a scoped Decompose rank-weight amendment from 10 to 12, retain both counterexamples as regressions, separately review/re-freeze while preserving the old failed freeze, then resume universal proof work. Weight 11 would still leave the shared case nondecreasing (20→20). This fixes these local rank inequalities, not an assertion that all remaining proof obligations are already satisfied. Earlier progress/Building descriptions below are historical.

## Further stage-1 proof progress — 10 October 2026

**Building, still 2/8 complete exact targets (F5/L1).** D189 records Robert's commit/push/continue instruction. The original checkpoint was delivered first; continuation is now also committed, pushed and remote-verified at [ea0fde9](<https://github.com/robertguss/mo-v2/commit/ea0fde992d7f9d59bf5f5bedda6e911f4edb8baf>) on proofs/[ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment)-stage1. Worktree clean, main unchanged, no PR/merge/deployment.

**New proved components:** exact F2 initialization correspondence; F1 source-prescribed event/memory-record accounting for every successful transition; heap premises derived from the frozen invariant; local live-zero Free heap/readback/control/rank preservation at transfer and commit; and decoder support lemmas. These are 26 new public theorems, not six newly completed target obligations. Free still requires valid pending-cell control premises and does not conclude complete output Inspect.invariant.

**Verification:** [result and reproduction](<https://github.com/robertguss/mo-v2/blob/ea0fde992d7f9d59bf5f5bedda6e911f4edb8baf/experiments/03c-checker/full/stage-1/progress-02/RESULT.md>); separate final-source review found no defect; all 26 transitive axiom sets use only propext/Classical.choice/Quot.sound. Clean frozen archive plus all 11 permitted proof files, no cache copied: 61 build jobs pass and leanchecker --fresh Full.Proofs.ProgressGate exits 0. All working proof bytes match the clean checked sources. Existing inventories pass 2/237/75/17 entries, plus 17 new checkpoint entries. Frozen ProofGate was rerun and exits 1 for f1/f2/f3/f4/f6/l2; it is not replaced by the partial gate. Finite acceptance was not rerun in this continuation because no execution definition changed; earlier evidence is preserved.

**Delivery CI:** [Buildkite 53](<https://buildkite.com/robert-guss/mo-v2/builds/53>) passed for the original checkpoint. [Buildkite 54](<https://buildkite.com/robert-guss/mo-v2/builds/54>) passed for the exact continuation head. This CI covers historical experiments, not complete full-3c proof acceptance.

**Next authorized work:** jointly typed residual control/slot invariant and preservation across evaluation, calls, queued releases and reservations, then complete F1/F2/F3/F4/F6/L2. This remains a proof-construction gap, not a discovered contradiction or a new owner-approval gate. Checker/caller enforcement remain separately gated. Earlier checkpoint delivery/status paragraphs are historical.

## Delivery and continuation — 10 October 2026

Robert authorized “Commit and push then continue” in [the working thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). The verified partial checkpoint [cd33b7c](<https://github.com/robertguss/mo-v2/commit/cd33b7cbfd59ea9a3a8e424b3212e7432637f7d0>) is now pushed and remote-verified on `proofs/rob-1139-stage1`. Main is unchanged; no PR/merge/deployment. [Buildkite 53](<https://buildkite.com/robert-guss/mo-v2/builds/53>) is running; it checks historical experiments, not complete full-3c acceptance.

Stage 1 remains Building, with F5/L1 proved and six exact obligations open. Continuing zero-count Free preservation and the residual-control invariant under D188; the frozen package needs no reapproval. All inventories pass (2/237/75 frozen entries plus 17 partial-checkpoint entries). Earlier local-only delivery wording is historical.

## Stage-1 partial proof checkpoint — 9 October 2026

**Building, not complete: 2 of 8 exact targets proved.** Under D188, the first bounded tranche proves Full.Proofs.f5 : Full.Statements.F5 and Full.Proofs.l1 : Full.Statements.L1. It also proves initialized full invariance, initial scope/IDs, source-prescribed transfer scope, and structural destruction facts including outside-root identity and exact cleanup membership. F1/F2/F3/F4/F6/L2 remain unproved; no placeholder or weakened statement was added.

**Evidence:** clean reconstruction of frozen a17f652 plus five proof files compiles 55 jobs; leanchecker --fresh Full.Proofs.PartialGate exits 0. Separate review inspected all source and 43 public theorems' transitive axioms; only propext/Classical.choice/Quot.sound appear. The unchanged eight-target ProofGate was executed and exits 1 for the six absent proofs: this is not a complete acceptance pass. All original inventories remain valid (2/237/75), and fresh 90-case / 820-group acceptance, 28 Trial comparisons and 21 faulty logical routes pass.

**Delivery:** local-only commit cd33b7cbfd59ea9a3a8e424b3212e7432637f7d0 on proofs/[ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment)-stage1 in [the working thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>), not pushed or merged. The remote still holds the approved freeze. Full result, separate review, clean build/kernel/axiom logs and partial inventory are under experiments/03c-checker/full/stage-1/. No frozen files changed.

**Remaining proof-construction gap, not a discovered model defect:** Full requires a typed residual-control invariant connecting task/slot segments, calls, queued releases and reservations. Trial's Healthy invariant cannot be reused unchanged because Full intentionally exposes live zero-count cells awaiting Free. Next concrete work is zero-count Free preservation using existing heap/count/path lemmas, then full typed-control preservation and simulation. No concrete frozen-theorem contradiction found. D188 permits continuing stage 1 without reapproving its frozen package; checker/caller enforcement remain separately gated. Earlier no-proofs-yet/awaiting-execution statements below are historical.

## Stage-1 proof execution authorized — 9 October 2026

D188 records Robert's “Approved. Do it now.” Work is starting on F1–F6/L1–L2 against the unchanged frozen package, under the additive stage-1/BRIEF.md in [the working thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). Existing orb/toolchain; no checker work. The earlier proof-execution approval gate is cleared. No theorem is yet claimed proved; stop/report a specification defect rather than weakening it. Status Building for this bounded stage, not whole-experiment completion.

## Approved, frozen and pushed — 9 October 2026

D187 records Robert's “Yes. Commit and push” approval of this exact acceptance-package freeze. [Freeze record](<https://github.com/robertguss/mo-v2/blob/a17f65215ed14288416c92e8af028078ffb827ff/experiments/03c-checker/full/FREEZE.md>) pins the unchanged reviewed package at [2dcea71](<https://github.com/robertguss/mo-v2/commit/2dcea716a917635ef51cd523401a7551722d9fe8>). Delivery head [a17f652](<https://github.com/robertguss/mo-v2/commit/a17f65215ed14288416c92e8af028078ffb827ff>) is pushed and remote-verified on acceptance/[ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment)-full3c-freeze; main remains unchanged. All 237 reviewed-file and 75 dependency hashes pass; the new freeze seal passes; build (15 jobs) and all 28 Trial comparisons pass again. No reviewed predictions, definitions, controls or evidence were changed for delivery.

**Delivery CI:** [Buildkite 52](<https://buildkite.com/robert-guss/mo-v2/builds/52>) passed on the exact pushed head; both Rust/frozen-corpus and Lean/kernel-check jobs exited 0. Existing CI checks historical experiments, not the new full-3c package; the latter's local finite evidence is recorded below.

**Remaining gate:** Needs Input for a concrete stage-1 proof brief/budget and execution approval—not exact-package acceptance, which is now complete. No proof/checker campaign, PR, merge or deployment has started. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) stays Done; [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment) is not Done. Previous uncommitted/unpushed and awaiting-freeze descriptions below are historical.

## Exact acceptance preparation ready for review — 9 October 2026

D186's authorized preparation is complete in the [working thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>), under experiments/03c-checker/full/. **Local only: uncommitted and unpushed. Not scientifically frozen; no proofs or demand checker.** [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) remains Done; [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment) now Needs Input for the exact-package approval, not for the already accepted v2 scope or author arrangement.

Evidence: pinned Lean 4.34.0 build passes; 90 exact cases, 84 finished answers/ledgers/graphs, 820 expanded groups across 4,591 snapshots, all 28 historical Trial comparisons, and 21 actual faulty logical routes rejected with passing baselines. Separate boundary checks cover 4,498 complete internal equalities / 9,680 ordered views. Separate scope follow-up checked 90 initial scopes / 4,542 source-output-commit triples and reproduced rejection of the hidden scalar parameter. The two scan totals have different denial handling and are not interchangeable. Koka 3.2.9 comparison covers 19 categories / 53 answers; demand warnings are not compiler refusals.

Separate review findings (demanded declaration, transfer boundaries, exact effect payloads and source-prescribed observer scope/order) were resolved and rechecked. Original predictions, their pre-encoding checkpoint, historical failures and prior reports are unchanged. Later supplements' exposure to earlier outputs is documented. Same-account separation is procedural, not independent scientific certification. Finite tests do not establish universal correctness or native fidelity.

Review entry points: PREPARATION-RESULT.md, ACCEPTANCE.md, verification/SCOPE-FOLLOWUP.md, and PREPARATION.sha256 in the local full/ directory. The proposed inventory covers 237 files and hashes the 75-file unchanged Trial dependency inventory; SHA-256 of PREPARATION.sha256 is dbe6a91d0d76f105d3a8338d4743f3b12a2d7776395624a6f201105063a1cb82. Full raw observations are retained losslessly compressed with logs/reports. This inventory is a review aid, not a lock.

**Next gate:** Robert reviews/approves the exact acceptance package before scientific freeze; actual freeze must record delivered Git revision and hashes. Proof campaign requires a separate stage-1 brief/budget approval; conditional checker and caller enforcement retain later separate gates. No push, merge, deployment, proof/checker execution or historical-lock change is authorized. Earlier active-preparation statements below are historical.

## Active acceptance preparation — 9 October 2026

D186: Robert approved the separate acceptance-author/specification-author/verifier arrangement in [this thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). D185's v2 scope remains unchanged. Starting separately authored exact programs/predictions/checks; current agent will encode the Lean specification only after the prediction checkpoint. A different verifier will inspect the resulting package before proposing a freeze.

The immediate arrangement gate is cleared. No proof/checker implementation, actual scientific freeze, merge or deployment is authorized. Earlier pending-arrangement statements are historical.

## Current gate — 9 October 2026: scope accepted; preparation arrangement pending

D185 approves [v2's English scope](<https://linear.app/robert-guss/document/full-3c-post-stage-b-formal-contract-v2-9-october-73682eae811b>) as the basis for exact acceptance preparation. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) is Done; its scope decision is no longer outstanding. This issue remains Needs Input only for the preparation author/verification arrangement before dispatch, not reapproval of the four semantic choices or the v2 scope. Later exact-package and proof/checker gates remain intact.

**Proposed arrangement for Robert:** a separate acceptance author derives exact example programs, expected answers/events and acceptance checks from the approved English rules before formal encoding. The current agent prepares the Lean specification and theorem statements here after the prediction checkpoint, without changing that author's expectations. A separate verifier subsequently checks the package and controls; the integrating agent resolves findings without claiming model agreement proves correctness. No independent author may also implement the future proof/checker candidate. This preserves full-3c authorship requirements rather than importing Stage B's single-agent exception. Same-account agent contexts are procedural separation, not technically inaccessible/private environments. No model/provider change or extra paid service is proposed.

**Written preparation brief:**

1. Inputs: the accepted v2 contract, unchanged finite trial and public Stage B contracts; do not retrieve private cases/seeds or change historical locks.
2. Acceptance author owns exact C1–C22 programs/starts/predictions, all 27 usefulness-category instances, comparisons and checks. The specification author owns language/plain/counted/lifecycle definitions and F1–F6/L1–L2 statement interfaces; no proofs or demand checker. Expected results must precede encoding and cannot come from candidate output.
3. The independent plain meaning cannot be implemented by erasing the counted machine. Preserve the exact ownership order, finite-trial projection and anti-vacuity controls. Run Koka 3.2.9 slice-1 comparisons before proposing the checker-example lock; record disagreements rather than changing expectations automatically.
4. Review checks include all quantifiers/preconditions, exact identities, no hidden theorem assumptions, valid counterexamples and intended mutant rejections. Independent review is not yet performed or claimed.
5. Stop at a reviewable exact acceptance package and proposed manifest, before scientific freeze or proof/checker execution; stop earlier for an unresolved semantic contradiction or integrity problem. Existing approved artifacts remain untouched.

No author has been dispatched and no executable preparation, comparison or proof has run. This brief is ready; the only immediate owner question is whether to use the proposed separate-author arrangement.

## Current dependency — 9 October 2026

[ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c)'s owner-selected preparation under D184 has produced [formal contract v2](<https://linear.app/robert-guss/document/full-3c-post-stage-b-formal-contract-v2-9-october-73682eae811b>) and is In Review. This issue remains Needs Input and blocked on that scoped contract/acceptance decision. The proposal retains rule correctness first, a separate conditional-checker go-ahead, and caller enforcement as slice 2; no proof/checker execution or new lock is authorized.

## Current checkpoint — 9 October 2026, after Stage B

[ROB-1333](<https://linear.app/robert-guss/issue/ROB-1333>) is accepted, merged and Done; [Stage B acceptance matrix](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/STAGE_B_RESULT.md>). Its empirical calls/recursion results are useful evidence, not the full-language proof, conditional demand checker, caller enforcement, Koka comparison or full-3c acceptance lock. None of those stages becomes complete through the interpreter merge.

Remain Needs Input, blocked on [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c)'s scoped contract/review/approval. Preserve the existing rule-correctness-first and separate checker/caller gates. Next-work recommendation is contract preparation in [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c), not dispatch of this whole experiment. No scientific scope, proof budget, workflow exception or implementation authorization is added here. Earlier status below is historical.

## Reconciled current status — 7 October 2026

Still Needs Input for its own formal scope, checks and approvals. [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)’s separately authorized executable prototype is empirical implementation work, not satisfaction or replacement of full3c’s proof/checker stages, comparison gates or acceptance lock. Historical operational arrangements do not govern new work.

Earlier records follow, preserved as history.

## Current status — 2026-10-06

Needs Input: full3c is held on [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c)'s scoped scientific decisions, independent review and approval of the calls/recursion specification. The accepted finite trial does not satisfy these extension gates. The stage/slice sequence and actual-allocation promise below remain intact; no new encoding, checker, comparator or lock is authorized by this status update. Current Mo work uses Codex under D108, the retirement of Amp/Herdr; operational workflow history is not a current blocker.

Deferred parent; direction partly decided, full plan/execution not approved. Stop after each gate; do not dispatch as one implementation.

1. Approve full plan; prepare full language/meanings/examples, cross-check Koka verdicts, approve acceptance and locks.
2. Slice 1 stage 1: prove full-language reuse-rule correctness; independent checks; show Robert the result. Trial completion does not satisfy this stage.
3. Obtain Robert’s explicit stage-2 go-ahead, then build the conditional demand checker and proof, usefulness/refusal examples and independent checks.
4. Slice 2: caller checks and unconditional demand proof, with separately approved promises/brief and independent checks. Slice 1 alone does not establish enforcement.
5. Report results, refusals and limitations in plain English with reproducible evidence.

Promise counts every list-cell allocation during a demanded call, including callees and later-freed cells; freeing is allowed, numbers/stack are outside this promise. Fixed reuse rule, no Builder preparation rewrite.

[https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/PLAN.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/PLAN.md>)

## Comments

### 2026-10-10 11:43 UTC, Robert Guss

Robert has directed continued work until stage 1 is completed, without another agent-selected partial-checkpoint stop, in [the working thread](https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491). The exact frozen F1–F6/L1–L2 scope and scientific stop condition for a verified counterexample remain unchanged. This does not authorize the conditional checker, caller enforcement, or a specification amendment.

Continuation is active. F5/L1 are still the only two complete target statements. New local proof modules establish L2 conditional on F1 and identity-embedding/snapshot lemmas; these are not unconditional L2 or F6 and are not yet delivered. Existing freeze inventories still pass. Execution/control preservation and complete Trial correspondence remain the proof work.

### 2026-10-10 14:25 UTC, Robert Guss

History rewrite migration completed at Robert's direction. Saved WIP, recorded old base before fetching, rebased only this thread's commits, removed both gzip blobs from the replayed commit range, and force-with-lease pushed [2072a8b](https://github.com/robertguss/mo-v2/commit/2072a8b) on proofs/rob-1139-stage1. No .gz objects remain in origin/main..HEAD. New amended-rank raw evidence was uploaded to gz-evidence-archive as gz-03c-checker-rank-amendment-01.tar, downloaded again and byte-checked; its checksum is in experiments/GZ_ARCHIVE.sha256. Original manifests/model/proof bytes are unchanged, with old/new commit mapping in stage-1/HISTORY-REWRITE.md. Five manifests pass 342 entries; all existing proof modules build together, 111 jobs.

Still Building, stage 1 not complete: only F5/L1 are unconditional exact targets. Pushed continuation includes reachable typing, binding identity/liveness, observer consistency, release/cleanup accounting, conditional F4/L2, partial Forward/F6 and partial invariant/progress proofs. Continuing structural readiness now (new edits after the pushed checkpoint remain local); no PR, merge, deployment, checker or caller enforcement. Prior local-only wording is historical.

### 2026-10-10 15:52 UTC, Robert Guss

Stage 1 continuation: **7/8 exact targets proved and fresh-kernel checked**: F1, F2, F3, F4, F5, L1, L2. ROB-1139 remains Building; F6 is unfinished.

Verification in the working thread: `lake build Full.Proofs` passed (104 jobs); `lake env leanchecker --fresh Full.Proofs` exited 0. The unchanged `lake env lean ProofGate.lean` exited 1, missing only Full.Proofs.f6. All seven transitive axiom reports contain only propext/Classical.choice/Quot.sound. No placeholder, weakened statement, or new model change.

F2 includes actual reachable decoder propagation, both simulation directions, finite-stutter rank descent, and answer equivalence; F3 covers source, transfer, and commit boundaries. F6 still requires exact Trial operation-record and ordered-snapshot equality. Release cascades, several expression cases, and conditional initialization/finalization bridges are proved; the full cleanup loop and remaining recursive expression cases are in progress.

The history-rewrite/rebase/archive migration was completed and pushed earlier. These subsequent proofs remain local, uncommitted and unpushed. No checker/caller work, PR, merge, or deployment. Continuing under the instruction to work until stage 1 is complete: https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491

### 2026-10-10 18:21 UTC, Robert Guss

Stage-2 progress in [execution thread](https://ampcode.com/threads/T-01a126e2-69f9-751a-8aff-1a2e19a7e821): work remains Building, not Needs Input and not complete. The executable conditional-checker candidate and finite runner are local on proofs/rob-1139-stage2, based exactly on the pushed stage-1 commit. Separate same-account verifier preflight passed all 90 rows (253 entries), 84 finished answers/full cell ledgers, 38 required accept rows and 14 required refusal rows; all 27 categories remain inventoried. Actual-source accept-all, reject-all, and missing-affine controls detected their intended failures; missing-affine accepted a unique-entry twice invocation with 2 Creates. Six nonfinished lifecycle rows are not newly certified by that checker consumer.

Lean 4.34.0 currently checks auxiliary proofs for certificate extraction, old-binding remaining-use monotonicity, scoped-credit lower bounds, fresh invocation-event IDs, zero tally at the exact frozen Enter premise, and unchanged tallies after a closed invocation. These are NOT the exact Conditional theorem. The remaining central work is a reachable-state certificate/ownership/reservation invariant establishing no Create while an accepted unique-entry invocation remains active, including descendants. No counterexample or new specification defect has been found. No frozen meanings, predictions, historical locks, or D191 scope were changed. No stage-2 commit/push, merge, deployment, caller enforcement, unconditional guarantee, or Rust refinement is claimed. Stage-1 Buildkite 90 still has no passing delivery checks; its canceled jobs are not a failed proof.

### 2026-10-10 18:35 UTC, Robert Guss

Incomplete stage-2 checkpoint preserved in [execution thread](https://ampcode.com/threads/T-01a126e2-69f9-751a-8aff-1a2e19a7e821), at experiments/03c-checker/full/stage-2/CHECKPOINT.md. I could not finish the central semantic ownership/reservation invariant, so Full.Statements.Conditional Full.Demand.accepts remains unproved. This is unfinished implementation, not a specification defect, a scientific pass, or a request for renewed authorization. No stage-2 completion is claimed; further proof work is still required under the existing authorization.

Final checkpoint checks: builder cache-free Lean 4.34.0 build, 64 explicit theorem type/axiom checks and fresh AuxiliaryGate kernel check passed; the fresh checker execution exactly reproduced the separately verified 90-row output. A separate verifier independently rebuilt the exact stage-1 base plus the seven additive Lean sources, passed its fresh IndependentGate kernel check, and audited all 212 public theorem constants (64 explicit + 148 generated) with only the allowed axioms. Its review is stage-2/verification-auxiliary/REVIEW.md. Earlier separate usefulness/refusal and actual-source mutation evidence remains applicable to the unchanged checker hash. These passes certify only the stated finite campaign and auxiliary proof prefix, not Conditional.

All stage-2 additions remain local and uncommitted on proofs/rob-1139-stage2. No push, merge, deployment, frozen-file or expectation edit, gzip history object, slice-2 enforcement, or model amendment occurred. ROB-1139 remains Building with this incomplete checkpoint; ROB-1138 remains Done. The agent is handing back this unfinished state, not waiting for a new approval.

### 2026-10-10 19:28 UTC, Robert Guss

Stage-2 work resumed in the same thread after Robert's “Proceed.” New Lean 4.34.0 proof modules now build (73 jobs): typed syntactic certificate preservation through all active machine actions, creation-site affinity bounds for parameters/lets/match tails, preservation of the full binding-ID suffix bound, and initialization from the exact frozen pre-cleanup Enter premise. Checker outputs remain identical on all 90 preflight rows after aligning the static parameter environment with Full.validate. This is progress, not stage-2 completion: the unique-region and runtime reservation correspondence and exact Conditional theorem remain unfinished. Prior separate-verifier records apply to their recorded older hashes; they are not certification of the new revision. No tracked frozen source changed, no specification amendment, no slice-2 work, merge, deployment, or CI-pass claim. Stage-2 additions remain local/uncommitted on proofs/rob-1139-stage2.

### 2026-10-10 20:30 UTC, Robert Guss

Stage-2 proof milestone: Full.Demand.Soundness.conditional now compiles at the exact unchanged type Full.Statements.Conditional Full.Demand.accepts (106-job build). This is not yet final certification: cache-free reconstruction, all-export transitive axiom audit, fresh kernel, final-source usefulness/refusal controls and separate verifier execution are next. Source remains local/uncommitted/unpushed in https://ampcode.com/threads/T-01a126e2-69f9-751a-8aff-1a2e19a7e821 on proofs/rob-1139-stage2 from the exact rewritten stage-1 base. No frozen-model amendment, caller enforcement, unconditional theorem, merge or deployment. ROB-1139 remains Building; ROB-1138 remains Done.
