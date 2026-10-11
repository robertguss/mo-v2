# Full 3c — post-Stage-B formal contract (v2, 9 October)

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/full-3c-post-stage-b-formal-contract-v2-9-october-73682eae811b
> Created: 2026-10-06
> Updated: 2026-10-09
> Author: Robert Guss
> Attached to: ROB-1138

---

## Exact package accepted and frozen — 9 October 2026

D187 records Robert's approval to freeze, commit and push the reviewed acceptance package. [Exact freeze](<https://github.com/robertguss/mo-v2/blob/a17f65215ed14288416c92e8af028078ffb827ff/experiments/03c-checker/full/FREEZE.md>) is delivered at [a17f652](<https://github.com/robertguss/mo-v2/commit/a17f65215ed14288416c92e8af028078ffb827ff>) on acceptance/[ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment)-full3c-freeze; main and the reviewed definitions/predictions remain unchanged. This completes the exact-artifact approval gate under [ROB-1139](<https://linear.app/robert-guss/issue/ROB-1139>), not any universal proof or demand checker. The next gate remains a separately approved stage-1 proof brief/budget and execution. Earlier local-only/unfrozen statements below are historical.

## Executable preparation checkpoint — 9 October 2026

The accepted D185 English scope below remains unchanged. D186's separate-author preparation and verifier follow-ups are complete locally in [the working thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). [ROB-1139](<https://linear.app/robert-guss/issue/ROB-1139>) now records the exact package, passing finite checks, resolved review findings and proposed hash inventory; it is Needs Input for exact-artifact approval. Files are uncommitted/unpushed, not scientifically frozen. No universal proof, demand checker, proof campaign or merge approval follows from preparation. Earlier statements that executable preparation has not started are historical.

## Owner acceptance — 9 October 2026

**D185: Robert accepted the v2 English scope as the basis for exact acceptance preparation.** [Approval thread](<https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491>). This includes the six core obligations, separate controlled-failure/destruction layer and preserved example requirements. The reviewed v2 text below is retained unchanged; its “not approved” wording describes the preparation checkpoint before this acceptance.

Exact executable artifacts are not yet prepared, approved or frozen. No proof or checker work is authorized. The next work is acceptance preparation under [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment), after agreeing the required separate-author/verification arrangement. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c)'s scope decision is complete; independent scientific review of the resulting exact package remains a later gate.

# Full 3c contract v2 — prove the recursive rules before building the demand checker

**9 October 2026 ·** [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) **· Prepared for review, not approved or frozen.** Robert selected this preparation in D184. This is the current proposed contract; the 5 October draft and its approval history remain below unchanged. The accepted trial and Stage A/B artifacts are not modified.

**Decision needed:** approve this bounded formal-model scope as the basis for separately reviewed acceptance preparation. That next preparation would produce exact Lean definitions/statements, typed example programs, independently derived predictions, comparison evidence and a lock candidate—not proofs or a demand-checker implementation. Approval of this prose would not approve those still-unwritten artifacts.

**Recommendation:** reuse the trial's integer/list memory vocabulary, but model calls with explicit saved execution state and small steps, following the approved Stage B ownership order. Prove the recursive execution rules first; retain separate go-aheads for the conditional demand checker and caller enforcement. Do not turn the Rust interpreter into the formal specification.

## 1. What is already settled, and what is only proposed here

| Item | Authority and disposition |
| -- | -- |
| Reservations stay in their owning invocation | D127; already approved. A helper cannot spend its caller's reservation. |
| Recursion need not terminate; suspension preserves execution | D128; already approved. A finite observation budget is not a language limit or proof of divergence. |
| Live callers and temporaries remain readable | D129; already approved. This is stronger than the finite trial's recorded-binding-only theorem. |
| Count from entry after explicit arguments | D130; already approved. Include entry work, descendants, their argument preparation, and cells created then freed. |
| Rule correctness before the checker; two slices | D72/D75 and the [full-3c plan](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/03c-checker/PLAN.md>). Preserve the stage-1 review and Robert's stage-2 go-ahead. |
| Stage B is accepted and merged | [Closeout](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/STAGE_B_RESULT.md>). Finite native evidence, not a proof of this model or Rust refinement. |
| Detailed Stage B behavior as the new formal baseline | Recommended in this v2; Stage B's approval does not itself approve a new formal encoding. The table below makes the proposed carryover explicit. |
| Exact theorem interfaces, predictions, acceptance files and lock | Still to be authored/reviewed in the next authorized preparation. No claim of independent scientific review or executable acceptance readiness. |

No new surface syntax, permanent number/sequence policy, compiler backend, concurrency or hot-reload work is proposed. Demand annotations are formal metadata on named declarations/calls for this experiment; a source spelling is not selected. No new Rust implementation or resource benchmark is required by this preparation.

## 2. Reconcile the model with the accepted prototype, without inheriting its test limits

| Formal contract recommendation | Stage B / trial source and qualification |
| -- | -- |
| Three distinct kinds: mathematical integers, Booleans and integer lists. Addition/subtraction and integer comparisons only; no conversions. Inputs remain integer/list, while functions may accept/return Bool. Include true/false literals. | D139/D140/D147; [builder brief](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/BUILDER_BRIEF.md>). Extends the trial conservatively; exact integers do not promise unlimited physical memory. |
| Finite globally known function table; first-order named forward/direct/mutual calls; explicit parameter/result kinds; lexical locals, no implicit access to main/caller inputs. Every body and branch type-checks. | [Stage B preflight, §§1–2](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/BUILDER_STAGE_B_PREFLIGHT.md>). Formal validation uses resolved identities; parser, diagnostic spans and JSON schemas are not new proof targets. |
| Left-to-right evaluation, including unused explicit arguments. Move at last lexical use; otherwise acquire a holder. Unselected branches count as possible uses until selection. Shadowing follows resolved binding identities. | [Execution contract, Ownership and ordering](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/BUILDER_EXECUTION.md>). No speculative last-use analysis based on whether recursive code terminates. |
| Unused inputs are released before Start; unused parameters only after Enter; giving up a holder and freeing its cell are distinct steps. Cleanup is explicit saved work. | Same source. A queued zero-count allocated cell is not a reservation and is not prematurely a leak. |
| A unique match detaches its cell; a shared match preserves the other holders. Reuse the newest eligible reservation only after both Cons operands finish, inside its branch and invocation. Free an unused reservation at branch completion. | Same source; no cross-call reuse, early branch cleanup or tail-call elimination added here. |
| Enter transfers all completed arguments and records fresh invocation/parameter identities; Return transfers the result and restores caller state. All suspended reservations stay visible, but only eligible current-call reservations are usable. | [Preflight, §§3–5](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/BUILDER_STAGE_B_PREFLIGHT.md>). No source or hidden preparation copy between argument completion and entry. |
| Include current-scope bindings and still-holding suspended bindings in one acquisition-order view, not two concatenated groups. | [D169 binding-order clarification](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/BUILDER_STAGE_B_BINDING_ORDER.md>). Identity correspondence must not silently reorder this view. |
| Observer calls do not execute or acquire holders. Resume continues the same state and history. | [Protocol](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/PROTOCOL.md>) and [revision-02 observations](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/stage-b-revision-02/OBSERVATIONS.md>). Prove a logical observation projection; do not encode the 10,000-step sampling schedule as the meaning of safety. |
| Resource denial is distinct from suspension, refusal and success. | D149; [protocol](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/PROTOCOL.md>). Separate the ideal semantics from a controlled-failure wrapper below. No arbitrary OS-OOM recovery theorem. |

Stage B's approved 1,800/600-second watchdogs, eight-MiB stack and measured memory usage stay with that experiment. They are neither theorem assumptions nor new full-3c performance promises. Wire metadata, physical pointers and serialized histories are evidence mechanisms; logical ownership/lifetimes and ordered effects are the formal obligations.

## 3. Two meanings, one precise starting domain

**Plain meaning:** an independent deterministic recursive machine over immutable mathematical values. It has the same evaluation order and function scope, but no counted heap, reservations or copy/reuse policy. Its answer must not be obtained by running the counted machine and erasing memory. Both meanings admit infinite executions.

**Counted meaning:** a deterministic machine with an active expression, saved continuations/completed operands, lexical bindings, invocation stack, active/suspended branch reservations, pending holders, queued release work, optional produced result, heap and append-only events. Use unbounded mathematical identities/counters; fresh identities cannot collide or wrap. The formal state is not required to retain serialized copies of every past heap.

**Valid start:** a finite well-typed program and matching ordered inputs; unique input/function/parameter and binding identities as required by scope; finite unique cell identities, acyclic list links, no dangling roots/links, no initial reservations or garbage. Every allocated cell is reachable from an input or outside root. Counts equal the multiplicity of input roots, outside roots and incoming live cell links. Repeated outside roots and shared tails are valid when counts reflect them. Outside roots are fixed by the environment, not invented or hidden by the program. This generalizes [Trial.validStart](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/03c-checker/trial/lean/Trial/Memory.lean>), not only the unshared-input case.

**One owner per holder:** a nonempty-list holder is owned by exactly one live binding, pending argument/result slot, external root, or live cell link. Control/ready/frame views may refer to the same holder but must not count it twice. Transfers change ownership, not the represented value or reference count; acquiring/releasing changes multiplicity. Reservations own allocated detached cells, not readable list roots. A zero-count cell awaiting Free remains allocated with its cleanup obligation; freeing transfers its tail edge to the appropriate pending cleanup holder before release continues.

**Continuous protection:** associate every required live holder with a plain value when it is produced/acquired, independently of mutable readback. Transfers preserve that value; consumed holders end at specified rules. Prove that the counted machine represents every value still required by the plain continuation, including pending arguments and suspended callers. Merely trusting a counted binding's holding/movedOn flag would repeat the finite trial's stated limitation. Every readable holder reads its associated value at every semantic state; helpers inside an atomic step must preserve this property too, or be split into specified microsteps. Changing a unique cell after its previous holder is consumed does not preserve an obsolete value that no longer has a live holder.

## 4. Stage 1 theorem contract: safety and honest recursive execution

The following are proposed mathematical interfaces, not Lean declarations already written or proved. Quantify over every well-typed program and valid finite start, not just named examples, shallow generated inputs or checker-accepted programs. Unless a row explicitly concerns failure, allocation is mathematical and does not fail.

| ID | Required statement | A plausible incorrect implementation it excludes |
| -- | -- | -- |
| F1 — Invariant and progress | Initialization establishes the full state invariant. Every finite reachable nonterminal counted state has a unique valid next semantic step; each step terminates, preserves types, ownership, acyclicity and readable protected values, and appends exactly its primitive cell/call effects. | Dangling tail, lost pending argument, invalid ownership, or an internal step that loops forever. |
| F2 — Plain/counted correspondence | Define an explicit relation between independent plain control/values and counted state. Each execution simulates the other, preserving answers. Plain execution terminates iff counted execution terminates with the same readable answer. A well-founded measure rules out infinitely many administrative counted steps that match no plain progress. | Counted bookkeeping diverges on a terminating program; a fabricated result makes a divergent program finish. |
| F3 — Every finite prefix protects live values | At every reachable state, all required holders, including outside roots, pending results and suspended callers, retain their independently associated values. The control/holder correspondence must also prove the holder was not incorrectly discarded. | Mark an inconvenient holder moved/given-up, then overwrite the value and claim nothing live changed. |
| F4 — Completion leaves exactly the retained graph | On genuine Finish, heap cells are exactly those reachable from the answer and outside roots, counts match those roots/links, and no extra run-owned holders remain in bindings, pending values or control beyond the designated returned answer ownership. There are no active invocation frames, reservations or unfinished cleanup obligations. Non-owning scalar/binding metadata and recorded history may remain; views of the answer must not count as extra holders. | A result is right while frames or hidden references retain garbage. |
| F5 — Bounded observation is compositional | advance with budget zero changes nothing; splitting a budget into m then n gives the same state, status, ordered events and cumulative count as m+n uninterrupted actions. Positive work stops only at budget exhaustion or terminal status. Finishing on the last allowed action is Finished, not Suspended. Terminal advances are inert. | Replay on resume, counter reset, changed live identities or delayed terminal status. |
| F6 — Conservative extension of the finite trial | For every original call-free trial expression and valid start, an explicit embedding and fixed projection preserve answer, ordered create/write/free effects and every old landmark's approved state fields/timing. Additional specified dispatch/control steps may project away; cell effects and old landmarks may not. Identity mapping preserves live lifetime continuity. | Matching only the final value, or using an arbitrary subsequence to hide a changed free/reuse schedule. |

**No universal termination theorem:** F1–F3 hold on every finite prefix, including prefixes of endless recursion. F2 requires both directions and rules out administrative divergence; merely proving that matching terminating runs return the same value is insufficient. F4 applies only after actual completion. Nonallocating infinite recursion is allowed; no bounded-memory promise follows.

**No false universal trace identity:** the old trial records selected landmarks and the new machine adds explicit control steps. The projection in F6 must be defined and reviewed before proof work, by action/state fields, not selected afterwards to make examples pass. Preserve all 28 frozen trial runs as regressions, plus the universal theorem. The broader 4,276 native historical cases are empirical evidence, not a replacement for F6.

### Controlled failure and destruction are a separate lifecycle layer

Propose two additional stage-1 interface obligations, kept distinct from the ideal execution theorem:

* **L1 — Controlled denial:** at an explicitly modeled allocation request, denial occurs before semantic effects. It returns Failed with a separate cause/abort report while preserving the last committed state and evaluation-event prefix. It is neither successful completion nor ordinary suspension. Domain/ordinal choices are external inputs; formal correctness does not assert that every Rust allocation actually passes through these gates.
* **L2 — Destruction:** from any finite reachable suspended, finished or controlled-failure state, modeled destruction terminates without evaluating further source code, releases all run-owned holders/reservations/frames, and leaves exactly the graph reachable from outside roots with correct counts and unchanged values. Destroy also releases the run-owned answer; transferring it to the host beforehand would require an explicit outside-root transfer, not an implicit exemption. Repeating destruction has no effects. Cleanup events remain separate from evaluation events.

L1/L2 are an explicit proposed extension of the old formal trial, motivated by Stage B's accepted public interface—not already-proved inherited theorems. Approve their inclusion with this contract. Mathematical cleanup can be proved terminating over finite acyclic state; this does not prove native host-stack bounds or recovery from arbitrary killed processes. If concrete denial-gate fidelity requires a Rust refinement theorem, report that boundary instead of claiming it here.

## 5. Later checker contracts preserve both slices

Let an invocation's counted interval begin at entry after all explicit arguments, before any entry work; end only after required callee cleanup and result transfer. Count every primitive Create while it is active, including descendants and their argument preparation. Free never subtracts a creation; address recycling is still Create, whereas writing a still-allocated eligible reservation is reuse. A nested Create counts against every active demanded ancestor. Require the effect log to agree with actual modeled memory operations rather than trust a checker/candidate counter.

**Slice 1 / stage 2 — conditional demand:** if the checker accepts a demanded function within a validated whole function table, then for every valid invocation whose list arguments are disjoint and every reachable input cell has exactly one holder at entry, every finite prefix of that invocation has zero Create events. Measure the precondition before dropping unused parameters. Quantify over arbitrary permitted caller state and descendants; no caller reservation may be used to justify acceptance. Validate recursive summaries/simultaneous assumptions soundly—never assume each recursive callee's zero-allocation conclusion as an unproved premise.

**Slice 2 — enforced demand:** for every program the whole-program checker accepts and every demanded invocation actually entered, every finite prefix of its interval has zero Create events. The caller checker must establish the necessary ownership conditions (or prove the property by a separately justified stronger analysis). Ordinary calls may allocate or copy; sharing alone is not evidence of an allocation. Slice 1 completion does not establish this theorem.

Both checker proofs concern the checker that actually runs. Runtime allocation denial is not demand enforcement: accepting an allocating program and aborting before it allocates does not establish the ideal no-allocation promise. Preserve ordinary type validation, F1–F6, and exact useful/refused examples so neither accept-all nor reject-all passes.

## 6. Preserve all 27 usefulness categories before fixing exact programs

These are acceptance requirements for the next preparation, not new executed results. Exact programs, starting memories, answers, event expectations and category membership must be independently reviewed before the lock. No category may be silently deleted because an implementation or proof is difficult.

| Family | Required categories from the full-3c plan |
| -- | -- |
| Slice 1 must accept — 12 | Increment every item; reverse; running totals; append two lists; swap neighbouring pairs; rotate first to end; merge sorted lists; insertion sort using existing cells; total a list; keep first/drop rest; remove first match; keep positive items. |
| Slice 1 must refuse — 6 | Duplicate every item; prepend a new item; insert a new number into a sorted list; build a list from a number; use the same list twice in a body that actually requires new cells; call an ordinary allocating helper. |
| Slice 1 observe — 1 | Demanded function calling an ordinary arithmetic-only helper. Report conservative refusal as a usefulness limit, not an allocation witnessed. |
| Slice 2 must accept — 3 | Construct fresh input then demand; chain demanded calls; ordinary call on retained/shared data. |
| Slice 2 must refuse — 3 | Retain/use old version after a demand that changes every item; pass one list twice to a demand changing both; demand on a shared-tail list while the other remains held. |
| Slice 2 observe — 2 | Drop an extra holder before demanding; pass fresh data through an ordinary forwarding helper into a demand. |

Every exact category instance needs observable values and a clear reason for its verdict. Use empty/singleton and asymmetric multi-element lists with mixed signs; distinct retained tails; sorted distinct inputs where sorting/merge matters; and both sides of ownership/lifetime boundaries. Count whether cells were freed separately from created. A refusal witness must actually allocate under the approved rule; a mere shared reference is not a counterexample to zero creation. These requirements do not declare all possible algorithms for each category acceptable.

### Keep C1–C14, and add cases that expose the formal gaps

The complete C1–C14 sketches and starting memories in the retained draft below remain required: cross-call reservations, caller reconstruction, pending/caller/tail protection, read-only aliasing, transient/explicit/nested allocation, finite/mutual recursion, allocating/nonallocating divergence and an unreturned branch reservation. They are not frozen independent predictions. Add the following exact-program obligations in preparation:

| ID | Required distinguishing case | Required observation / competing interpretation |
| -- | -- | -- |
| C15 | A later unused argument constructs a cell before entering a function that returns its first argument. Use different values for the two arguments. | All arguments execute; the earlier completed value remains unchanged. Creation belongs to the caller's active interval, not the callee's. |
| C16 | Discard a nonempty list, pause immediately after its root holder is given up but before Free; also pause after head free before tail release. | Zero-count queued live storage is valid until its Free action; each tail holder survives across the join. No duplicate free after resume. |
| C17 | Reach Enter with an unused list parameter; pause, then continue its cleanup. | Parameter bindings and frame are present at Enter; unused-parameter release is a later step. Count the precondition before release. |
| C18 | Shadow an outer list name inside a callee/branch while the old value is still required by a suspended continuation. | Resolved identity and future use, not spelling or active-scope-only liveness, determine protection. |
| C19 | Same started run with budgets 0; one action short of Finish; exactly Finish; greater than Finish; and segmented budgets cutting a nested call. | F5 terminal boundary and history laws; no replay, altered prefix or extra actions. |
| C20 | Controlled denial just before Create and at a modeled number/frame request inside nested arguments; destroy twice. | Last committed execution is unchanged; failure is not suspension/success; only outside-retained graph remains after destruction. |
| C21 | Non-tail finite recursion with deliberately nontrivial pending scalar/list work after the recursive return. | Explicit continuations and exact answers, not just a depth counter; no theorem-level promise about a particular native stack size. |
| C22 | A loop keeps making and freeing one cell; compare with a loop that never creates a cell. | Prefix creation counts distinguish them even with the same small final observed heap; neither finite run proves divergence. Prove the small looping witnesses separately if claiming they diverge. |

For C1–C22, the independent predictor must state exact typed programs, initial cell/holder tables, answers or finite-prefix outcomes, event ordering and selected ownership boundaries before encoding. Candidate output cannot supply expectations. Public Stage B evidence may identify risks, but no private cases/seeds are retrieved or promoted into a new independent corpus.

## 7. Acceptance must test the intended promise, not only build the proofs

The next acceptance package must name F1–F6, L1–L2 and each later checker theorem in plain English and fully qualified Lean declarations. Check the theorem statements themselves: correct program/start quantifiers; valid-start domain; independent plain machine; reachable-state definition; simultaneous recursion conditions; exact allocation interval; and explicit permitted axioms. No expected conclusion may be assumed, hidden in validStart, or weakened to a bounded enumeration.

| Control | Intended rejection, not merely a compiler error |
| -- | -- |
| Reuse a shared cell / consume a caller reservation | A valid retained-value or call-local event witness fails. |
| Remove a pending or suspended holder; mark it dead too early | Independent continuation/value relation fails, even if the counted holder list claims it disappeared. |
| Reset nested counters or count only net growth | C7/C9/C22 primitive Create witness violates the interval property. |
| Report suspension as Finish; restart after resume | C19/F5 detects wrong result/status/history. |
| Loop only in administrative bookkeeping | F2's progress/ranking requirement cannot be discharged; ordinary finite source has no corresponding completed counted answer. |
| Skip branch/return/free cleanup | C16/C17 and final/destruction graph obligations fail for their named reason. |
| Hide a copy before invocation entry | An explicitly constructed accounting control is rejected. Stage B's omitted-entry-create control was inapplicable because its fixed entry allocates nothing; do not relabel that historical gap as an executed control. |
| Accept every demand / reject every demand / omit caller ownership check | Actual allocating must-refuse example, an approved must-accept example, and a retained/shared-tail caller distinguish the three. |

Acceptance includes a passing unmodified baseline and evidence that each applicable faulty path executed and failed its intended property. A mutant proof failing only because a name/type changed is not scientific control evidence. Predicates and witnesses must be independent of the builder's asserted results. Any inapplicable control must be reported and resolved explicitly before freeze, not counted as passed.

Fresh verification must reconstruct the exact locked spec and only permitted proof/checker files, build with the approved pinned toolchain (Lean 4.34.0 is the existing reuse recommendation), inspect transitive axioms for every exported theorem, and use the kernel re-checker. Reject sorryAx, extra assumptions, proof bypasses or a compiled evaluator/checker different from the logical definition. Standard axioms require an explicit allowlist. No toolchain upgrade is bundled into this proposal.

Retain independent acceptance authorship and separate verification for full 3c unless Robert explicitly changes that scope. D170 removed the split for Stage B only. Model brand, a fresh thread, and model agreement are not themselves scientific independence; the next brief must name the author/verification separation and access boundaries. This preparation has not performed that independent review.

## 8. Work and approval gates

1. **This deliverable —** [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c): the reconciled English contract, preserved category matrix, risks and proposed formal interfaces. Preparation complete when reviewable; no Lean encoding, Koka run, proof or lock here.
2. **Owner scope decision:** approve/amend this v2, including the ideal/lifecycle split and the proposed reuse of detailed Stage B semantics. The four settled choices in section 1 do not need reapproval. Agree the next acceptance-author/verification arrangement before dispatch; historical tool branding is not a blocker.
3. **Separately authorized acceptance preparation:** exact programs and independent predictions; formal language/plain/counted definitions and statements under a written spec-encoding brief; independently authored checks; retain all old trial artifacts. Koka 3.2.9 slice-1 translations and verdicts are run before locking checker expectations, with differences classified as memory/termination/library/representation. Koka agreement supports expectations; it does not define correctness. This step is not a proof/checker campaign.
4. **Review and freeze before proofs:** check that the prepared definitions/observations express F1–F6 and L1–L2 without circular assumptions; validate the examples and controls; freeze shared language/meanings/examples for both slices together and stage-1 acceptance/brief. No old lock changes. Robert approves exact artifacts and execution, separately from this English proposal.
5. **Slice 1 / stage 1:** prove rule correctness, lifecycle and finite-fragment correspondence; independent checks and readable result; stop. A verified counterexample is different from a merely unfinished proof.
6. **Separate stage-2 go-ahead:** build/prove the conditional checker against its approved promises/brief and frozen shared examples; check both usefulness and refusal controls.
7. **Separate slice-2 approval:** prove caller enforcement against its own approved brief; no automatic scope expansion from slice 1.

**Effort recommendation for approval before formal execution:** deliverable-based work with progress reporting and hard stops for counterexamples, specification defects and integrity failures; do not invent a duration from the trial's four-hour proof. The older full-3c budget/interval proposal remains unresolved: [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration)'s no-mandatory-interval decision does not silently amend it. If Robert chooses a numerical cap, define it per slice and shared across its stages unless he explicitly selects a different policy. No additional paid services, model purchases or provider fallback are authorized.

**Not yet specified:** exact Lean structures/relation/ranking measures and exported types; independent expected traces; exact algorithm per usefulness category; Koka translations/results; frozen access/write boundaries and executable control routes. These are concrete outputs of gate 3, not claims this prose is a ready-to-run acceptance package. A contradiction between a required example and the fixed semantics stops that preparation for a reported decision; do not weaken either silently.

## 9. Why this scope, and what could change the recommendation

* **Reuse the old terminating evaluator unchanged:** cannot express unrestricted recursive continuations or all finite prefixes. Keep its memory vocabulary, original proofs and call-free behavior as the compatibility target, not its structural-termination assumption.
* **Prove the current Rust interpreter directly:** would require a separate Rust/refinement and native-resource verification effort. Stage B's empirical success does not provide that bridge. Defer; report explicitly that the Lean theorems do not certify arbitrary Rust execution.
* **Build the demand checker first:** risks proving the checker against a wrong execution rule and violates the agreed rule-correctness-first gate. Defer until stage 1 is accepted.

Risks that must surface early: the exact F6 projection might expose a real trial/prototype mismatch; a must-accept algorithm may be incompatible with call-local reservations; continuous-holder protection may require more precise liveness than the old trial states; and failure-gate modeling may claim more than the interface can justify. Check those during acceptance preparation, before a proof lock. Preserve counterexamples instead of retroactively redefining success.

**Preparation evidence:** read the live approvals, full plan, old theorem interfaces/validStart/explicit limitations, approved public Stage B action/preflight/binding-order contracts, amended observation interface and final acceptance report at the pinned commit above. No private corpus was opened. No candidate/comparator was run, no theorem was proved, and no repository source was changed. This is a source-grounded proposal with independent review still pending.

---

# Historical draft and prior checkpoints — preserved verbatim below

## Post-Stage-B context — 9 October 2026

[ROB-1333](<https://linear.app/robert-guss/issue/ROB-1333>) is now accepted, merged and Done; [Stage B acceptance matrix](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/STAGE_B_RESULT.md>). This document remains the full-3c formal-extension draft, with its four scoped owner approvals preserved below. Stage B completion neither approves all of this draft nor proves its universal obligations.

The proposed next step in [ROB-1138](<https://linear.app/robert-guss/issue/ROB-1138>) is to reconcile this draft with the accepted prototype contract and prepare exact proof/acceptance scope. This recommendation is not owner approval to build, prove, amend locks or skip the rule-correctness-first gate. Earlier preparation and approval records follow unchanged.

## Partial owner approval — allocation accounting boundary

6 October 2026. Robert answered “yes” to beginning the zero-new-list-cell promise at function entry, after explicit argument expressions finish. Entry work, including any hidden copying, counts; all work inside the call counts, including descendant calls, their argument preparation, and cells created then freed. Explicit caller input construction before entry is outside that invocation's interval and remains visible in the whole-program record. This approves the experimental accounting boundary presented in the discussion; it does not approve all remaining formal details, acceptance, implementation or execution.

Four discussed choices are now approved: call-local reservations, unrestricted recursion with resumable observations, protection of live values throughout execution, and this accounting boundary. Exact formal acceptance, remaining detailed rules, review and execution gates are still pending. Older approval status below is historical.

## Partial owner approval — protection throughout execution

6 October 2026. Robert answered “yes” to protecting every live caller value and temporary throughout execution of the calls/recursion experiment, rather than only selected snapshots. Suspended callers' retained values and completed arguments waiting during later argument evaluation must preserve their readable values while live. Storage may become eligible for reuse after the value is no longer needed, subject to the approved ownership/reuse rules. This is a new extension obligation, not a claim that the finite trial already proved it. Approval covers this protection requirement only; exact formal statements, acceptance and implementation authorization remain pending.

Call-local reservations and resumable recursive observations are also approved. Remaining specification and execution gates are pending; older approval status below is historical.

## Partial owner approval — recursive execution observations

6 October 2026. Robert answered “yes” to allowing unrestricted recursion with bounded, resumable observations for the calls/recursion experiment. Observation outcomes distinguish finished, failed and still running (suspended). Exhausting the observation budget preserves execution state for continuation; it is neither successful completion nor proof of infinite execution. This does not require every function to terminate or make the observation budget a language-level execution limit. Approval covers this experimental semantic choice only, not the complete specification, formal encoding, acceptance lock, proof/checker work or execution.

Call-local reservations are also approved. Remaining detailed rules, proof obligations and execution gates are pending; earlier preparation status below is historical.

## Partial owner approval — call-local reservations

6 October 2026. Robert answered “yes” to keeping reservations within each call for the first calls/recursion experiment. A helper cannot consume a cell set aside by its caller; the caller retains its reservation while the helper runs. Existing proposed C1/C2 distinguish the resulting allocation behavior. This approves that experimental semantic choice only, not a permanent Mo rule, the rest of the draft, acceptance lock, proof/checker implementation or experiment execution.

The remaining specification and execution gates are pending. Original preparation history follows.

# Full 3c: proposed calls and recursion specification

**Draft for** [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) **— 5 October 2026. Not approved, independently reviewed, encoded, or locked.**

Robert's “Do it” in the current Codex conversation follows the recommendation to prepare the smallest precise specification for calls and recursion while retaining the completed trial. This authorizes preparation; it is not recorded as approval of the new semantic choices below. No full-3c implementation starts from this document.

The [accepted trial](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RESULT.md>) is merged into main at e6a895c. Its files, statements, examples and lock remain unchanged.

## 1. Question and scope

Can the fixed reuse rule remain correct with named calls and unrestricted recursion, and can a checker both enforce zero new list-cell allocations and accept useful programs?

Preserve the existing two slices and their order:

1. Slice 1, stage 1: prove the extended execution rules correct, including shared inputs.
2. Stop and show the independently checked result to Robert.
3. Only after the stage-2 go-ahead: build and prove the conditional demand checker, plus usefulness checks.
4. Slice 2: check callers so every demanded invocation obeys the promise, with its separately approved brief and acceptance.

Trial completion does not satisfy full-language stage 1. This draft prepares shared semantics and examples for both slices; it does not reduce full 3c to the first proof.

Keep numbers, lists of numbers, comparisons, let, if and list match from the trial. Add only a finite table of named first-order functions, calls, and demand annotations. No closures, function values, new collections, I/O, concurrency, compiler backend, performance target or parser project.

**Proposed function rules:** unique function names; distinct parameter names per function; explicit parameter and result kinds drawn from number/list/Boolean; exact argument count and kinds; every function body checks against its declared result kind. Functions see their parameters and local bindings, not their caller's names. Direct and mutual recursion are permitted. There is no termination check for ordinary programs. The top-level starting inputs retain the trial's number/list restriction; Boolean arguments may be results of expressions. Surface notation is illustrative, not Mo syntax approval.

## 2. Proposed call and ownership rules

**Evaluation order.** Evaluate argument expressions completely, left to right. A finished argument stays held while later arguments run. If an argument does not finish, later arguments and the callee body do not begin.

**Holders.** Apply the trial's move-at-last-use and add-a-holder-if-used-again rule to argument expressions. At invocation, move the completed arguments' holders into parameter bindings, without copying cells. Drop unused parameters in declaration order before the body runs. On return, move the result holder to the caller's waiting expression; do not free or duplicate it.

Each invocation gets fresh binding and branch identities, even during recursion. A suspended caller retains every name, temporary result and reservation it still needs. Callee liveness never releases a suspended caller's bindings. Within the active invocation, liveness follows the remaining expression and continuations, including unevaluated arguments, without predicting which path a recursive callee will take.

**Reservations — approved for this experiment (D127, call-local reservations).** A matched cell set aside in one invocation may be reused only by constructions in that same invocation's still-active enclosing match branches. A callee cannot consume its caller's reservation. Within an invocation, retain the trial's newest-eligible-first rule, selection after both construction operands finish, and branch-end disposal.

Caller reservations remain allocated while calls run. Callee reservations are consumed or disposed of before returning from their owning branches. A caller can still pass a live list explicitly; the callee can match that list and establish its own reservation. No freed or set-aside cell is passed as an ordinary argument.

The alternatives are: let callees consume reservations from dynamically enclosing caller branches; or introduce explicit reservation transfer. The first can reduce allocations in some programs but makes a function's reuse depend on hidden caller resources. The second adds machinery outside this minimal proposal. Keeping reservations within a call makes the resource promise easier to state locally; it may reject programs another rule could run in place. No optimality or performance claim is made.

**Return and cleanup.** A branch finishes only after its result is computed and its unused reservations are disposed of, as in the trial. Call-return cleanup must preserve the returned value and all suspended caller holders. No early branch cleanup or tail-call transformation is silently introduced. An endlessly recursive call may retain caller reservations indefinitely; this draft promises neither bounded memory nor eventual cleanup for a program that never finishes.

## 3. Execution that can run forever

Owner approved unrestricted recursion and bounded resumable observations (D128, honest suspension without a termination claim). The execution encoding and detailed proof obligations below remain proposals.

Recommend a deterministic step relation with explicit waiting work and call frames, while retaining the trial's memory vocabulary where justified. This is a proposed execution interface, not an instruction to rewrite the trial. A fuelled evaluator is a possible executable interface; it is not the definition of divergence.

Expose three outcomes for a bounded observation:

* **Finished:** final answer and required cleanup completed.
* **Suspended:** the observation budget ended; preserve the resumable state and exact event prefix. This says nothing about eventual termination.
* **Failed:** malformed input or a specified runtime/read-back failure, with its reason and evidence. For well-formed programs and valid starts, stage 1 must rule out runtime failure.

Running a larger budget or resuming a suspended run must extend the same execution; it cannot restart counts, lose holders, change a previous answer, or convert budget exhaustion into success. An actual infinite execution is addressed by proofs over all finite prefixes, not by a timeout label.

The plain meaning also needs honest recursive execution. Both meanings must agree on whether execution terminates and, when it does, on the answer. The counted machine cannot replace a terminating program with bookkeeping that runs forever.

## 4. What a demand measures

Owner approved the entry-after-explicit-arguments boundary and inclusion of all nested/transient list-cell creations (D130, invocation allocation accounting). Detailed formalization below remains subject to acceptance review.

The demanded invocation begins after its explicit argument expressions finish, **before** parameter-entry cleanup or body execution. It ends after the callee's required cleanup and transfer of its return value, before the caller's next operation.

Count every fresh list-cell creation during that interval, including in ordinary or demanded descendants, their argument evaluation, and cells later freed. Each event belongs to every demanded invocation active when it occurs. The outer demanded call therefore counts allocations used to prepare an inner call, even though that inner invocation begins later.

Explicit caller construction before the outer invocation is allowed and remains visible in the whole-program record. There is no hidden copy or preparation pass between argument evaluation and invocation. Any future transformation requires a separately justified accounting boundary.

Counts come from memory's primitive creation/write/release record. A freed cell's replacement is a fresh creation, even if an address is recycled. Reuse means writing an already allocated reserved cell. Net heap growth is never an allocation count. Number storage, stack space and call-frame storage remain outside the list-cell promise.

For slice 1, the unshared-input precondition is measured at invocation before unused parameters are dropped: every cell reachable from a list argument has exactly one holder, and different list arguments have disjoint reachable cells. Empty lists contribute no cells. Slice 2 must prove the demand for its accepted callers; it must not claim that sharing itself demonstrates an allocation.

## 5. Proposed proof obligations

| Obligation | Required meaning |
| -- | -- |
| Well-formed execution is safe | Every reachable nonfinal machine state from a valid start has the specified next step; no dangling read, invalid ownership operation, or unreadable successful answer. Internal bookkeeping operations themselves terminate. |
| Termination and answer correspondence | Plain execution terminates if and only if counted execution terminates, with identical plain answers. No universal-finishing promise for recursive programs. |
| Protected values remain unchanged | Outside roots, suspended caller bindings, and completed argument/return temporaries preserve their readable values while their holders remain live. The initial value and lifetime of each protected holder must be identified independently of the mutation being checked. |
| Ownership and cleanup | At observable machine-state boundaries, holder accounting includes active and suspended bindings, links and temporaries; reservations are allocated, detached and uniquely owned. At whole-program completion, allocated cells are exactly those reachable from the answer and outside holders, with correct counts. |
| Trial compatibility | For all call-free trial programs and valid starts, embedding in the extension preserves answers, creation/reuse/free events, and the trial's approved timing observations, under an explicit correspondence for addresses and states. The 28 examples provide regression evidence, not this universal theorem. |
| Conditional demand | Every accepted demanded function, invoked under the specified unshared-input condition, creates zero list cells in every finite prefix of the invocation and its descendants. |
| Enforced demand | Every demanded invocation in a whole program accepted by slice 2 creates zero list cells in every finite prefix, including invocations that never return. |
| Usefulness | The checker accepts every approved must-accept program and refuses every approved must-refuse program. Proofs alone do not excuse a reject-everything checker. |

The visibility obligation includes call-related temporary holders and is stronger than the trial's snapshot-only statement. Robert approved that stronger protection requirement (D129, continuous live-value protection). Its new explicit formal statement still needs review and acceptance approval; this is not a reinterpretation of an existing theorem.

A semantic transition may include a finite atomic bookkeeping operation, but must specify its boundary and prove its intermediate safety. It cannot conceal allocation events or arbitrary execution inside an unobservable transition. The formal acceptance must define the plain/counted state correspondence and progress obligations precisely before proof work starts.

## 6. Distinguishing programs and starting memories

These are proposed program sketches to make choices reviewable, not frozen predictions or preapproved checker verdicts. Each must become an exact typed program and address/holder table. A separate predictor derives answers, memory events and selected timing claims from the approved English rules before encoding.

Use illustrative definitions:

* identity(xs) = xs
* one(n) = \[n | \[\]\]
* first(xs) = match xs do \[\] -> 0; \[h | t\] -> h end
* bump(xs) = match xs do \[\] -> \[\]; \[h | t\] -> \[h + 1 | bump(t)\] end
* sum(xs) = match xs do \[\] -> 0; \[h | t\] -> h + sum(t) end
* spin(n) = spin(n)
* allocateForever(n) = let ignored = \[n | \[\]\] in allocateForever(n)
* **C1: reservation across a call**
  * **Concrete setup and program:** One uniquely held cell \[1\]. match xs do \[\] -> \[\]; \[h | t\] -> one(h) end.
  * **What it distinguishes:** With call-local reservations, one creates a fresh cell and the caller later disposes of its unused reservation. With dynamic access, one may reuse that reservation. Same answer; different events.
* **C2: caller resumes construction**
  * **Concrete setup and program:** Same start. match xs do \[\] -> \[\]; \[h | t\] -> \[h | one(h)\] end.
  * **What it distinguishes:** Which construction receives the original cell; caller reservation survives until return. Totals alone may not distinguish the policies.
* **C3: pending argument protection**
  * **Concrete setup and program:** Same uniquely held xs = \[1,2\]. choose(a,b) = a; evaluate choose(xs, bump(xs)).
  * **What it distinguishes:** First argument stays held during second-argument evaluation. Original xs survives unchanged as the result; bump cannot mutate it through the other argument.
* **C4: suspended caller protection**
  * **Concrete setup and program:** xs = \[1,2\]; let changed = bump(xs) in first(changed) + first(xs).
  * **What it distinguishes:** A caller's later use remains protected throughout the nested call.
* **C5: aliases that only read**
  * **Concrete setup and program:** xs = \[1,2\]; readBoth(a,b) = first(a) + first(b); call readBoth(xs,xs).
  * **What it distinguishes:** Aliasing can coexist with zero creation events. A conservative checker refusal must be reported as a usefulness limitation, not as evidence that the run allocates.
* **C6: live tail overlap**
  * **Concrete setup and program:** Cells A=\[1|B\], B=\[2|empty\]; xs points to A, ys to B. Counts A=1, B=2. let changed = bump(xs) in first(changed) + first(ys).
  * **What it distinguishes:** Protecting a shared tail matters even when top-level roots differ.
* **C7: transient allocation**
  * **Concrete setup and program:** makeThenDrop(n) = let unused = one(n) in 0; invoke it as demanded with no caller reservation.
  * **What it distinguishes:** Creating and then freeing a cell still violates zero-allocation demand; includes an ordinary helper.
* **C8: explicit caller construction**
  * **Concrete setup and program:** demanded identity; identity(\[1|\[\]\]).
  * **What it distinguishes:** Caller creation is visible globally but precedes identity's demand interval.
* **C9: nested demand accounting**
  * **Concrete setup and program:** demanded outer(n) = identity(\[n|\[\]\]); identity is demanded.
  * **What it distinguishes:** The new cell belongs to outer's interval even though it precedes identity's interval.
* **C10: terminating recursion**
  * **Concrete setup and program:** bump and sum on empty, singleton and longer unshared lists; bump also on lists kept by an outside holder.
  * **What it distinguishes:** Different finite depths, branch cleanup, recursive return ownership, and the difference between ordinary shared execution and conditional demanded execution.
* **C11: mutual recursion**
  * **Concrete setup and program:** even(n) = if n <= 0 then 1 else odd(n-1) end; odd(n) = if n <= 0 then 0 else even(n-1) end.
  * **What it distinguishes:** Function-table scope and recursion without list allocation.
* **C12: nonallocating divergence**
  * **Concrete setup and program:** spin(0).
  * **What it distinguishes:** Every bounded observation is suspended, never a fabricated answer; divergence itself is not a cell-allocation violation.
* **C13: allocating divergence**
  * **Concrete setup and program:** allocateForever(0), with no input cells or reservations.
  * **What it distinguishes:** Its prefixes contain creation events even if each unused list is immediately freed. Small final heap size cannot hide demand failure.
* **C14: branch never returns**
  * **Concrete setup and program:** Unique xs=\[1\]; match xs do \[\] -> 0; \[h | t\] -> spin(h) end.
  * **What it distinguishes:** The caller's reservation remains allocated while its branch has not finished; final no-leak is not applied to a suspended run.

Retain every must-accept, must-refuse and observed category from the full draft plan until Robert explicitly approves a change. The cases above supplement them; they are not a smaller substitute. Arithmetic-only ordinary helpers and harmless aliasing are not assigned mandatory checker verdicts by this draft.

## 7. Acceptance preparation and stop conditions

Before implementation:

1. Oracle reviews this proposal against the full plan and trial limits. Robert settles new semantic choices and approves the resulting plan.
2. Write exact shared examples and starting memories for both slices. A separate predictor produces approved expectations before encoding.
3. Run and retain the specified Koka 3.2.9 slice-1 comparison before locking checker expectations. Explain discrepancies; Koka is supporting evidence, not the runtime oracle or a reason to change an expectation automatically.
4. Encode the shared language, both meanings and exact theorem statements through an approved visible worker arrangement, with independently authored checks. This preparation encoding requires its own approved brief; it is not authorized by this draft.
5. Approve and lock the new acceptance package and appropriate stage brief. Preserve the original trial and all its fingerprints.
6. Decide the execution arrangement, two-hour reporting/continuation policy and either no total cap or a per-slice cap shared across stages. No elapsed-time estimate follows from the trial.

Acceptance must retain fresh reconstruction, exact theorem statements, standard-axiom checks, kernel rechecking, and independent Lead/Tester executions. Add controls that lose a suspended holder, reset descendant allocation counts, misclassify suspension as success, hide an allocation in call entry, and skip return/branch cleanup. Each must fail for its intended reason on valid inputs. Checker controls include accept-all, reject-all and an omitted ownership rule. Event-report mismatches must be checked explicitly, not inferred from process exit status.

**Preparation stop:** a concrete draft is saved and its unresolved choices/review needs are stated. No proof, checker, new lock or comparator run is started by this preparation task. No existing acceptance criterion is weakened.

**Implementation stops, for the later approved brief:** completed candidate; reporting deadline or agreed total budget; a concrete valid counterexample; specification defect; integrity violation; setup blocker. Preserve evidence, distinguish unfinished proof from false promise, and never repair a failed expectation to match the implementation.

## 8. Review status and next decision

Prepared by Codex from the repository and Linear issue. Independent scientific review and owner scope approval remain pending. Missing Amp/Crew skills or HERDR_ENV are not blockers: those operational workflows are retired. Historical scientific locks and independent acceptance authorship remain unchanged.

First semantic choice approved: keep reservations within each invocation for this experiment (D127, call-local reservations), with C1/C2 exposing the cost and future alternatives preserved. Recursive execution with bounded resumable observations is also approved (D128, honest suspension without a termination claim). Protection of live caller values and temporaries throughout execution is approved (D129, continuous live-value protection). The invocation boundary is also approved (D130, counting from entry after explicit arguments, including nested and transient allocations). These four discussion choices are recorded; exact formal acceptance, remaining detailed rules and execution gates are pending. This is not a decision about all of Mo.

Other pending approvals are the exact recursive execution/visibility obligations, formal acceptance, budget and execution arrangement. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) remains open; [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment) remains gated.

Sources: [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138), [full 3c draft](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/PLAN.md>), [trial rule](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RULE.md>), [accepted trial limits](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RESULT.md>).
