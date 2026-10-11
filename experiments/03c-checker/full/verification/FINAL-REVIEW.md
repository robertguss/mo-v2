# D186 final integration review — 2026-10-09

**Finite integration passes. Hold proposed exact-spec freeze for one narrowly
identified observer/specification coverage gap below.** Reviewed current
uncommitted `full/`, not origin/main. This is same-account procedural separation,
not independent scientific certification. No proof/checker campaign or approval.

## Executed passes

From `full/acceptance`:

```sh
python3 -B supplemental-v2/check_expanded.py /tmp/full3c-final-evidence --report /tmp/full3c-final-consumer.json
sha256sum -c supplemental-v2/INVENTORY.sha256
sha256sum -c PREDICTIONS.sha256
sha256sum -c MANIFEST.sha256
sha256sum -c supplemental/INVENTORY.sha256
```

820 groups passed, zero failed; 90 exact histories, 4,591 snapshots,
3,008 Plain steps / 1,490 ranked stutters / 3 denials; 12/12 corrupted-export
controls rejected. All four inventories passed. Original predictions and old
supplements were not edited. The v2 SOURCE inventory describes the author's
earlier archive, not a hash lock of today's added Export fields. Handwritten call
trees consume the original cell ledger, not observed histories or AST evaluation.
The checkpoint is supplemental: the author had seen earlier outputs/schema.
The consumer's field projection, quoted-token-preserving whitespace normalization,
and metadata-only copy for the old holder classifier are explicit and meaningful;
they do not adapt predictions. Supplied required IDs remain counted-derived.
Data-corruption controls are not logical machine mutants.

From `full/lean`:

```sh
lake env lean -o .lake/build/lib/lean/Export.olean Export.lean
FULL3C_INPUTS=/tmp/full3c-final-evidence/inputs.json lake env lean ../verification/Controls.lean > /tmp/full3c-final-controls.log
```

19/19 actual faulty routes rejected, with passing baselines. Exact transition
routes (action numbering includes the mutated action):

| Fault | Case/action |
|---|---|
| caller reservation | C1/16 |
| shared detach | C3/12 |
| pending holder | C3/8 |
| suspended holder | C4/6 |
| repeated administrative Capture | C19/5 |
| omitted Free | C16/6 |
| hidden entry copy | C8/10 |
| Return payload | C7/23 |
| cell payload | C8/8 |
| omitted reserved-branch cleanup | C1/18 |
| retained Return frame | C8/12 |
| omitted unused-parameter drop | C17/7 |

The pending-slot mutation decrements the lost root count and compares decode to
`Plain.step p before`, independently computed from the source (not inventory).
Each cleanup variant actually advances up to 300 actions, requires Finish, then
rejects `finalGraph`; a thrown candidate error would fail the test, not pass it.
Remaining routes: C7/C9/C13 wrong counters 0 versus 1/1/2; false C12 Finish;
C19 restart steps 1 versus 18; C20-number late denial steps 15 versus 14;
identity destruction. These are scoped executable controls, not universal coverage.

From `full/`:

```sh
python3 -B verification/check_final.py /tmp/full3c-final-evidence --report verification/final-results.json
```

90 traces; **4,498 complete internal equalities** against the actual committed
state with only predecessor steps/history/landmarks restored; **9,680 exact
visible-view checks** across all exported nested states (includes repeated
resume/destruction representations). Three controls rejected: changed hidden
nextBinding, omitted visible entry, reordered entries. `final-results.json`
preserves the raw hash and limits. Export constructs restored state from actual
`t.execution`, not from the internal state it compares. Source commit updates
exactly those three fields. This closes the finite omitted-hidden-field gap.
Repr strings are finite evidence, not kernel structural equality proofs.

## Lifetime adjudication: future proof obligation, not a new blocker

F3 quantifies over reachable source/output/commit boundaries and requires both
protection and an actual independently begun Plain prefix. Control decoding
ignores holding flags/readback: it reconstructs original values in task contexts,
pending operands and call continuations. Thus a false dead flag does not erase a
required value from correspondence. Protection checks source-text uses, slots,
outside roots and immutable edge suffix associations. F2 additionally fixes the
next Plain step and ranked stutter relation; F1 checks boundary inventories and
exact effects. Cons, Enter, Decompose and Free install complete immutable transfers
while their source remains intact. Pure intermediate data are not running states.
No concrete uncovered running helper lifetime was found. A separate universal
bijection proof is not a prerequisite to *stating* these obligations; their
universal discharge is stage 1. The author is right that finite required-ID checks
alone do not prove this relation. No universal protection has been established.

## Ordered scope: finite formula passes, missing full-language obligation

`visible` preserves acquisition order by filtering the append-only bindings list
for entered IDs or holding status. Source scope updates are concrete: Bind adds
the lexical binder; Enter switches to parameters; Return restores saved caller
context; branch/match/handoff restores the respective context. Shared Decompose
without a tail acquisition intentionally delays scope entry until MatchComplete.
Holding caller bindings survive in the view even while a callee runs. These
source-derived observations are distinct from the Python formula check: that
check does **not** derive the correctness of entered IDs from source semantics.

No F1/F2/F3 clause relates `entered` to lexical source scope or requires the
complete ordered full-language observer view. Protection/owners/decode ignore
`entered`; F4 ignores it too. F6 constrains old embedded Trial landmarks only,
not function-call scope observations. Concrete missing-relation witness:
at C12 action 5 (Enter spin), entered is `[("n",0)]`, binding 0 is scalar
noHolder, and visible is `[0]`. Replacing entered with `[]` makes visible `[]`
without changing any protection, ownership, decode, Plain correspondence, effects
or rank check. This is a faulty observer-state counterexample to *coverage*,
not a claim that the current transition performs that mutation. The program is
not an embedded Trial program, so F6 cannot rule it out.

Accordingly the promised full ordered active-scope observer requirement needs an
explicit source-scope/entered relation and ordered view obligation (including
internal cuts/call suspension), or a documented approved requirement resolution,
before exact-spec freeze. Correct finite outputs and source inspection cannot
substitute for the absent universal specification clause. This is narrower than
the author's request for universal proofs before freeze: unproved existing Props
are not themselves preparation blockers, but an unstated promised relation is.

## Acceptance and future gate

ACCEPTANCE correctly distinguishes Prop definitions from proofs, stages and
mutants. ProofGate has eight exact fully qualified type checks, eight checks and
eight transitive axiom prints. Full.Proofs is absent; default build targets Full,
not ProofGate. No stubs were introduced. The pin reports Lean 4.34.0; bundled
leanchecker resolves in the pinned environment (a help-style invocation is
interpreted as a module request, not a proof validation). No kernel proof recheck
was performed or claimed.

After the scope-spec finding is resolved, preparation can be reconsidered for
proposed freeze, subject to Robert's separate authority and exact revision/hash
inventory. Future stage 1 must prove all eight types without forbidden bypasses,
inspect transitive axioms against only propext/Classical.choice/Quot.sound,
reconstruct a clean frozen package and run `leanchecker --fresh ProofGate`.
Later checker mutants await actual checkers and separate stage approvals.
No whole baseline/trial duplication was needed; prior passes remain historical
evidence. No push, merge, freeze, proofs or checker changes were performed.
