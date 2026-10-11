# ROB-1139 slice1 stage2 — separately executed final verification

## Verdict

**PASS for the actual checker and exact Conditional proof, with one delivery-runner
operational defect: the supplied Gate.lean lacks `import Lean.Elab.Command`.**
The unmodified runner independently failed at this gate (exit 1), not at the
proof's exact type or axiom check. I did not modify it. My additive verifier gate
includes that import; a second cache-free reconstruction then completed all
checks successfully. Recommend stage2 scientific completion, but repair and
rerun the stock delivery gate before claiming its original reproduction passes.
No specification defect or allocating accepted unique-entry counterexample was
found in the delivered checker. No CI pass is implied: Buildkite90 cancellation
is neither proof failure nor passing CI.

This is a different verifier execution in the same account: **procedural
separation, not independent-account certification**. I executed verification
myself without delegation or another thread. Only additive verifier records and
scripts were written. No implementation, acceptance, historical evidence, lock,
branch/history, Linear or external publication was changed.

## Source and integrity

Read BRIEF, frozen full/ACCEPTANCE.md, exact Statements.Conditional, stage1
completion RESULT and verifier review, builder runner/gate, actual executable
checker, proof assembly and semantic/dependency modules. HEAD remains exactly
`66f8aac22fbaa31100700a5ca9e5b486efd67c28` on proofs/rob-1139-stage2; tracked
diff is empty. All 19 source files (Demand.lean plus 18 modules) are covered
exactly by sources.sha256, with the same hashes in both independent attempts
and at campaign completion. Checker SHA256:
`f83b33773c280697a36b2610a9a450a2813bb743240e3e5d26971ffe40aa5105`.
Soundness SHA256:
`466820f0123e0f9871ba8c7e9e124e3ec4bd38e6a51d812c9bd51a7612397477`.
All per-module and adapter/consumer/gate/runner hashes are preserved in
independent-reproduction/sources.sha256. The historical preflight checker hash
was not used as the final source identity.

Six frozen inventories passed in the working tree before/after and archived
reconstruction: **423 entries each, 1269 OK checks total** in the successful
run. Reconstruction used git archive stage1 plus only permitted Demand sources,
no copied .lake. Only two checksummed public full3c gzip assets were restored;
no private experiment13 access, no gzip history addition. Regenerated raw export
equals archived D191 exactly, SHA256
`d358ba51249cf260882eb437f1fbc9103260c0ef8f76849da2ed361a057ac78a`.

## Exact proof and trust checks

* Lean **4.34.0**, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`;
  cache-free build **172 jobs**, exit 0.
* Exact `Full.Statements.Conditional Full.Demand.accepts` elaborates without
  extra premises. Its transitive axioms are precisely propext, Classical.choice,
  Quot.sound. No caller-enforcement or unconditional theorem is substituted.
* Environment enumeration covers **525 public/generated Demand theorem
  constants**; separate working-tree enumeration equals clean enumeration.
  Axiom sets: **34 empty; 116 propext; 295 propext/Quot.sound;
  80 propext/Classical.choice/Quot.sound**. All pass the complete allowlist.
  Other public/generated constants enumerated: 342. This is an environment
  inventory, not a source-line regex excluding generated theorems.
* Fresh `leanchecker --fresh DemandAudit`: exit 0. All eight stage1 exact targets
  and transitive axiom checks pass; fresh ProofGate recheck exits 0.
* Independent proof controls: passing baseline plus **3/3 intended rejections**.
  True.intro fails exact-target elaboration (exit 1). Placeholder and added-axiom
  candidates elaborate (exit 0), then fail the allowlist on sorryAx and unsupported
  respectively. This is policy rejection, not claiming Lean rejects axioms.
  Runnable scratch sources were deleted; exact text/logs remain here.
* No placeholder, new axiom, unsafe/native/opaque/trust bypass, custom elaborator
  or frozen-definition-altering attribute was found in real Demand sources.

## Meaning inspected

`check` validates ordinary function typing and every demanded declaration under
one simultaneous **syntactic** certification table. Calls require demanded
callees and check actual argument work; recursion is not assumed to satisfy a
semantic no-Create summary. Parameter environments match Full.validate's order.
Ordinary helper refusal is deliberately conservative.

`occurrences` sums sequential operands/arguments and takes branch maxima with
lexical shadowing. Usage/UsageTransition establish continuation-wide usage;
Births establishes new let/tail/parameter bounds using fresh IDs, including
saved work. Affinity certifies descendants while leaving older caller work
unconstrained. At_entry obtains the actual predecessor of the last Enter and
initializes every invariant using **the same before.nextBinding cutoff**, not
independent existential cutoffs. uniqueEntry applies immediately at actual Enter,
before unused parameter release; heap readability and count-one/disjoint entry
are not assumed only after cleanup.

Region uses the fixed entry address region (freed addresses remain members),
count bounds and live-link closure; it is not a varying allocated-set tautology.
Regional local operands/new bindings and cleanup are propagated through actual
transitions. Framing preserves the older operand suffix above the exact Return
delimiter, with local operand arity justifying variable-arity calls and cleanup.

CreditExecution.Credit retains **expired reservation cleanup prefix ++ concrete
local activation stack ++ older caller suffix** in exact physical order.
Tickets retains empty lexical scopes, consumes the innermost occupied scope and
proves actual find/filter correspondence. Branch exit moves remaining local
reservations into mandatory expiry work; older caller reservations cannot supply
credits. Descendant Enter pushes an empty activation from the syntactic table;
Return pops it. Static aligned lower bounds and branch joins are proved, not
unchecked zip truncations or global total-credit accounting.

Soundness's induction follows every finite advance prefix, including descendant
execution and argument preparation within the target interval. Actual eligible
Cons proves no Create, while event accounting counts all Creates regardless of
later frees. Entry starts at zero; Return closes the interval and Events.advance_closed
uses fresh monotone invocation IDs to preserve that count through arbitrary later
caller actions, including later Creates. No post-Return prefix is discarded.
This inspection covers assembly/contracts and key preservation paths, not an
independent line-by-line rederivation of every helper.

## Executed finite and mutation results

* **90 cases** and exact frozen AST/function closure/demanded-set/start-address
  encoding validation; baseline and scratch baseline identical.
* All **27 categories preserved**: slice1 **12A/6R/1O** exercised; slice2
  **3A/3R/2O deferred**, not reported as caller enforcement passes.
* Expanded consumer: **820 PASS checks, 12 negative controls**; 90 traces,
  4591 snapshots, 3008 steps, 1490 stutters, 3 denials; 126 Cons instances,
  7 with multiple eligible reservations. Boundary consumer: **4498 internal
  equalities, 9680 visible views, 3 negative controls**. Unchanged machine
  controls: **21/21 faulty routes rejected with passing baselines**.
  TrialCompatibility and ReviewCases also exit 0.
* Actual-source mutations compile and execute: accept-all produces **33**
  semantic failures; reject-all **38** required-accept failures; missing-affine
  **3** semantic failures. In particular missing-affine accepts all declarations
  in U-twice, yet target twice enters uniquely and allocates **2**. These are not
  compilation failures or fabricated JSON mutations.
* Independently recomputed principal refusal event-prefix counts in witnesses.json:
  duplicate **3**, prepend **1**, insertNew **1**, build **3**, twice **2**,
  allocHelper via ordinary one **1**. Each target enters uniquely and is refused.
  First four report no eligible reservation; twice reports repeated list xs;
  allocHelper reports ordinary callee one lacks certification. Allocating
  descendants are counted; counts remain unchanged after Return. Arithmetic-only
  arithDemand is refused but has **0** Creates: a usefulness limit, not an
  allocating witness. Fresh demand and chained demanded calls are accepted.

## Limits and recommendation

Finite consumers retain their published limitations (repr comparisons and
bounded traces are not universal proofs). The kernel proof provides the frozen
mathematical conditional result, not Rust/native refinement, caller ownership
enforcement, physical storage guarantees or a divergence decision. Koka 3.2.9
historical comparisons are unchanged; they were not freshly rerun here and do
not extend this theorem. Source remains uncommitted; these hashes bind this
review to the current bytes, not an externally published revision.

Recommend completion of **slice1 stage2 only**, subject to explicitly acknowledging
or repairing the stock Gate import operational defect. No scientific expectation
amendment, stage2 source correction or slice2 authorization is indicated.
COMMANDS.md, inventory/axiom counts, proof-control sources/logs, witnesses.json
and independent-reproduction/ contain reproducible evidence. Original builder
evidence and old preflight/auxiliary reviews were not touched.
