# ROB-1333 v6 — incomplete acceptance preparation; reference-defect stop

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-v6-incomplete-acceptance-preparation-reference-defect-stop-f39348fa7b7e
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

# [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) v6 — incomplete acceptance preparation checkpoint

**PROPOSED DETAILS / NOT LOCKED / NOT A BUILDER BRIEF. Preparation stopped on a reference defect, 7 October 2026.**

This v6 checkpoint preserves [v5](<https://linear.app/robert-guss/document/rob-1333-v5-approved-exact-prototype-integers-proposed-acceptance-5eece5c832ec>) and all earlier versions unchanged. V5 sections 2–9 and 14–16 remain the proposed grammar, canonical structure, name/type/ownership/transition/output/failure rules and distinguishing examples under review. This document replaces their preparation-authorization/status wording, not any historical scientific requirement. It does not certify those proposed rules or the completed acceptance package.

## Authorization and stop

D141, deliverable-based acceptance preparation, authorizes drafting reference/checker code and validating preparation, then stopping with a reviewable package; it also requires an earlier stop on specification/reference defects, integrity problems or scope-changing choices. It adopts neither the proposed eight-hour preparation cap nor mandatory two-hour approval interruptions. Preparation has now stopped at the reference-defect boundary described below. No further repair, scientific lock or interpreter work follows from this publication.

D139, limited first-language features, approves ordinary Boolean literals, integers/integer lists, bindings/comparisons/branches/list match, addition/subtraction, explicitly typed named functions/recursion and mid-expression suspension/resume. No Boolean equality/operators/inputs or other arithmetic is added. D140, exact growing prototype integers, preserves mathematical answers without choosing permanent Mo policy or promising unlimited resources. D138, this acceptance orb with larger-orb fallback if needed, selects the machine only; actual resources must be rechecked before eventual authorized resource execution.

D127, call-local reservations; D128, unrestricted recursion with bounded resumable observations; D129, continuous live-value protection; and D130, entry-after-explicit-arguments counting including nested/transient allocation, remain approved boundaries. Detailed syntax/semantics/resource thresholds and stage effort units/caps remain proposed. D137, separate Amp acceptance authorship and Fable plan-only review, bars this author from implementing Mo. Fable was not invoked. Parent owns the all-issues audit, register and issue-description updates.

## Concrete defect requiring a stop

V5 section 3 proposes selecting the first lexical/syntax error in source order. The acceptance-owned parser eagerly lexes the entire file, so a later lexical error masks an earlier syntax error.

| Source | English-rule prediction | Current reference result |
| -- | -- | -- |
| main = (1 2) | syntax, (1,11)–(1,12), the second numeral | syntax, (1,11)–(1,12) |
| main = (1 2) @ | syntax, (1,11)–(1,12), same earlier error | lexical, (1,14)–(1,15), later @ |

Ranges are 1-based, half-open. Independent derivation: main occupies columns 1–4, = is 6, ( is 8, first numeral 9, second numeral 11, ) is 12, @ is 14. The result should not move to a later error merely because that error is appended. No interpreter candidate exists and no historical expected result was changed.

Witness in the attached archive: experiments/13-source-acceptance/evidence/refusal-priority-01/counterexample.json. Reproduction from the repository: import parse, Refusal and position from experiments/13-source-acceptance/syntax.py, parse each source and print the refusal class plus converted start/end offsets. The execution produced exactly the two actual rows above.

**One immediate owner question:** should the proposed earliest-source-error rule remain, requiring the reference repair, rather than changing the proposal to give lexical errors priority across the entire file? Recommend retaining earliest-source priority: it points to the first repair the programmer needs. Lexical-first is simpler for a batch lexer but makes this diagnostic jump past the earlier syntax mistake. This is a detailed diagnostic-rule choice, not a change to approved language features. Preparation remains stopped pending direction; it is not a claim that the rules themselves are contradictory.

## Exact review checkpoint delivery

[Source and evidence archive attached to ROB-1333](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/d66c4627-331f-434c-ab87-24650f7acb3a/de0d814a-4fee-47cf-a9ad-55e25db8ca59>). Attachment title: Incomplete acceptance preparation checkpoint — stopped on reference defect; attachment ID 0e1b78a9-ee0e-4a11-9eed-f664465ca19d. It contains only experiments/13-source-acceptance, excluding Python caches. Size 40,841 bytes; SHA-256 0a4c54bd59423975024e774ca872727fec379cf92be629e0da7a23fe1426863f. This fingerprint identifies a review export, **not a scientific lock**. If the direct upload URL requires authentication, use the issue attachment.

Source ownership: [syntax.py](<http://syntax.py>) owns the acceptance tuple-tree lexer/parser/type reference/pretty-printer; finite_reference.py derives logical historical ownership landmarks from expressions/fixtures only; call_reference.py extends the counted reference with calls/local reservation isolation and supplies a separate immutable-value answer reference; [cases.py](<http://cases.py>) states public English-derived C-family totals; [predicates.py](<http://predicates.py>) checks ownership/reachability/outside protection, enter/return allocation intervals, physical evidence continuity and resume suffix/identity joins; [selfcheck.py](<http://selfcheck.py>) tests public predictions and synthetic defects; [generated.py](<http://generated.py>) probes bounded call compositions. These Python references deliberately use host recursion and logical cells. They are not the explicit-state Mo interpreter and must never be used as its implementation.

Code is local, uncommitted and unpushed on acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-preparation, based on origin/main 03705f1dac1de8cbc9efedaf99ad4feeb62c17a3. No parent-local unpushed state was needed. The archive transfers the exact checkpoint without implying Git publication, independent review, merge or acceptance. Historical tracked sources/locks were not edited.

## Validation that actually ran

Run commands from the repository root; each command creates a new evidence directory and refuses overwriting an old one.

* python3 experiments/13-source-acceptance/validate.py experiments/13-source-acceptance/evidence/finite-03 — passed 4,276 cases / 27,721 snapshots, every expected field, ordered primitive record, answer and final memory. Source pretty-print/reparse structure and Stage A type checking passed for every case. Expected states were never fed into the predictor: it computes them from decoded expression/initial roots before comparison. All thirteen kinds retained. This validates the historical landmark schedule, not the entire proposed fine-grained evaluator schedule or physical storage.
* python3 experiments/13-source-acceptance/selfcheck.py experiments/13-source-acceptance/evidence/public-03 — passed 16 must-accept source examples, 12 exact-span must-refuse examples, 21 public C-family cases and seven synthetic predicate-defect controls. Includes true/false and wide integer examples from v5, plus independently stated exact enter/create/write/free/return order for C1/C2/C8/C9 and retained-bump interval totals. Not a full refusal set or full transition prediction table.
* python3 experiments/13-source-acceptance/generated.py experiments/13-source-acceptance/evidence/generated-01 — passed 500 exploratory finite call compositions and 22,090 logical snapshots. The generator actually combines nested calls/arguments, conditionals, local shadowing, constructors, signed values and source/fixture/outside-retained lists. Generic checks compare the immutable reference answer, counts/outside contents, exact final reachability and invocation-boundary nesting. This fixed exploratory seed is public preparation material, **not held out**, not an approved quantity and not the complete generated acceptance layer. No difficult case was filtered to obtain the pass.

All outcomes are saved in those directories' summary.json; public-03/observed.json contains the actual public-case evidence. Success reports aggregate the historical run; a complete per-case projection/transition export is still outstanding. No claim of fine-grained continuous protection follows from checking only historical/reference landmarks. Pending-value acquisitions still need independent expectations; the binding-protection fallback learns first-acquisition values and is not sufficient against corruption at acquisition.

Historical corpus SHA-256 d8d33f795b94e8173b6685462e83a277bfeefad5cc2bfee6bee38a8f63554a8b matches its unchanged old LOCK.json. Thirteen snapshot counts: start 4,276; holderMoved 1,213; branchChosen 1,795; matchStep4Done 272; branchStarts 1,795; newCellBuilt 393; branchValueWorkedOut 637; branchValueHandedOn 637; end 4,276; newHolder 23; holderGivenUp 7,078; cellFreed 5,269; nameBound 57. Split give-up/free and shared-match newHolder/complete are represented. No snapshot kind/field was silently omitted.

Retained failed preparation: finite-01 found a draft reference applying match-style branch cleanup to conditionals; the reference was corrected against unchanged historical semantics and finite-02/03 passed. Public-01 found a missing function-closing end in a newly authored unapproved example; public-02 found a miscounted EOF range (28-character source inserts at column 29). Those new example mistakes were corrected with failed evidence preserved; neither changed a frozen criterion. Public-03 predates the subsequently found combined-error counterexample and is not a blanket frontend pass.

## Missing coverage before a complete package or builder brief

* Exact full fine-grained transition/state predictions and projection report; current logical reference only provides historical landmarks plus call entry/return.
* Complete must-accept/refuse tables, Stage A capability refusals, multi-error priority, smallest-callee-name ranges, independently resolved binding/function identities and canonical external dump adapter.
* New truly private heldouts and a separately isolated generated acceptance corpus; public exploratory cases cannot be relabelled unseen. Builder receives approved rules/grammar/interfaces, public answers and worked spans, never the acceptance files/private seeds/new exact predictions before candidate delivery. Prior public C counts/control categories are already disclosed.
* Acceptance-derived expected live binding AND pending-temporary acquisitions at every committed state. Current generic predicates do not independently establish all continuous-protection obligations.
* Executable candidate protocol/adapter; sole physical cell API instrumentation and real graph inspection; fixture/source suffix equivalence and metadata isolation; all transition-boundary resume joins and state-preserving destroy/failure cleanup.
* Acceptance-controlled allocation failures and compiled relevant runtime mutants. The seven executed synthetic controls reject replaced objects, recycled lifetime IDs, replay, changed resume objects, wrong/missing returns and unreachable final cells. They test predicates only, not actual allocator/runtime behavior.
* Approved resource/effort conventions and eventual actual-machine execution. No million-depth run, new stack-independence evidence or performance claim exists.

V5's full-snapshot obligation is still proposed and partly validated; its full landmark-to-fine-transition gate has not been completed. Stage A success alone never delivers Stage B. Claims remain finite experimental evidence, not a universal safety/refinement/termination proof.

## Owner choices still pending, not a multi-question request

Immediate question is error priority above. Later: precise grammar/literal rewrite/namespaces/kind/ownership/transition/output/failure rules; complete checks and package approval; full compatibility and recursion resource envelope; measurable elapsed contributor-time convention and Stage A/B caps/gates. Preparation authorization is already settled by D141, deliverable-based preparation, so v5 Q5 is superseded on that point. V5 Q4's eight-hour preparation cap and mandatory interval approvals are not adopted. Reporting points are not caps, and proposed numbers are not reliable completion estimates.

Recommend the prior measured convention for eventual stage limits: record explicit start/stop timestamps; include tool/build/debug waits; exclude only recorded owner-wait/stopped intervals; sum concurrent contributor intervals; report implementation plus acceptance execution separately and in stage totals. This remains a proposal, not a new decision.

Exact package/requirements approval still precedes a scientific lock and builder brief; Stage B follows its own owner go-ahead. No lock, Mo implementation, Fable execution, participant trial, deployment, push or merge was performed. Do not archive this acceptance thread: further review/repair is needed.

## Authoritative source links

[Current live register](<https://linear.app/robert-guss/document/decisions-and-approvals-live-register-360d6e9c3d64>); [Start here](<https://linear.app/robert-guss/document/start-here-current-state-and-working-rules-29033acb30ab>); [full Fable v1 review](<https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and#comment-df80ec4f>); [full Fable v2 review](<https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and#comment-9719d936>); [calls draft](<https://linear.app/robert-guss/document/full-3c-calls-and-recursion-specification-draft-5-october-73682eae811b>).

Pinned historical [finite SPEC](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/SPEC.md>), [corpus](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/evidence/expected.jsonl.gz>), [finite lock](<https://github.com/robertguss/mo-v2/blob/a22831f823d2ac7ccbb8726a8d4418fbceb233e0/experiments/10-finite-rust/LOCK.json>), [English RULE](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RULE.md>), [INTERFACE](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/INTERFACE.md>). Local reference/checker/evidence sources are the attached archive, not invented remote commit links.
