# Separate bounded stage-1 review — ROB-1139 / D188

Reviewed 2026-10-09; completed within the requested ten-minute bound.
This is separate same-account procedural verification, not independent-account
acceptance. **Partial result accepted within the checks below; full stage 1 is
not complete.** No concrete specification counterexample was found in this
bounded review. This is not an exhaustive counterexample search.

## Scope and findings

Read all five new proof files, frozen `Statements.lean`, `ProofGate.lean`,
`ACCEPTANCE.md`, and `stage-1/BRIEF.md`; checked the relevant frozen Counted,
Inspect and Lifecycle definitions against the proof arguments.

- `Full.Proofs.f5 : Full.Statements.F5` proves the exact four conjuncts:
  zero budget, split via Except bind (including errors), terminal absorption,
  and step-count bound/exactness when the resulting answer is absent. The last
  proof actually works for arbitrary successful advances, so discarding the
  frozen reachability premise does not weaken the target. Transition preserves
  the counter; commit increments it once. No termination premise was added.
- `Full.Proofs.l1 : Full.Statements.L1` proves exact denial-state equality,
  with the frozen request/site/domain ordinal and frame abort list. It unfolds
  the frozen step; denial changes only failure, preserving the entire committed
  execution and other state fields. Unused reachability is a stronger result,
  not a hidden assumption or weakened statement.
- `Initial.initialized_invariant` establishes the actual full
  `Inspect.invariant initial first = true` from successful `Counted.begin`.
  It derives valid-start/healthy graph facts from begin rather than assuming an
  execution invariant. Owner counts, edge read-back, all entered-or-holding
  observer records and ID order are included. `begin_scope_ids` separately
  establishes the exact initial scope, binding IDs and next ID.
- `parameter_scope` has an explicit equal-length premise; its use in
  `transition_scope` derives that premise from successful Enter, rather than
  assuming it for reachable execution. `transition_scope` covers every
  successful transfer and concludes exact source-prescribed `nextScope`.
  Together with commit's unchanged entered field this is useful F1 work, not
  the full F1 progress/effects/boundary theorem.
- Partial L2 facts are accurately bounded: unconditional idempotence,
  destroyed flag and preservation of events/history/memory record/outside;
  reachable executions have destroyed=false and cleanup=[], allowing exact
  control clearing and cleanup-membership proofs. Outside identity is preserved
  through transition, step and lifecycle advance, then tied to initial.outside
  through begin. This proves root-list identity, **not outside graph/read-back
  preservation**. The generic clearing and cleanup lemmas' explicit premises
  are discharged in their reachable wrappers, not hidden in an L2 claim.
- No weakened frozen target, shadowing, new axiom, unsafe/opaque/native bypass,
  syntax/elaborator override, or kernel-check bypass was found. Namespaces add
  new theorem names only. Root `attribute [local simp]` applies solely to five
  new private proved Except monad lemmas, not locked definitions. The scoped
  heartbeat option in Scope is an elaboration budget, not a semantic premise.

## Exact reviewed bytes (SHA-256)

Frozen HEAD: `a17f65215ed14288416c92e8af028078ffb827ff`.
Proof hashes were identical before and after local compilation/review.

```text
7d2471e612c1375be5978b2c1746c5124265d9b7585da80d43a3bd4ef438cf24  lean/Full/Proofs.lean
743d4887ab55438c55eb4d03e418617b70fdfb60a5b0bf773744542ee843ba2d  lean/Full/Proofs/Initial.lean
7ec21040870d963c7ad8762bdd52f0890544b41a8ce932f45bf3d5ca4559f2f1  lean/Full/Proofs/Scope.lean
2e334536d32c60a000fbca0881a769cae358d7af8fb56b0cfd364ff8516b84c6  lean/Full/Proofs/Lifecycle.lean
f02d5b4d6a57cea7eadac637515c4c1c086cad4bd21c96d3f40cc3f4df1fe722  lean/Full/Proofs/PartialGate.lean
b178b3c5af611f7a90f45113e01bdb521bfbf2ecd5134ef6903d1bceb9065178  lean/Full/Statements.lean
013dc1ac5703663fb81b836b94f579efe22d8f68af1d393106687f0eef7eb55e  lean/ProofGate.lean
394e3ffc6233e6792078aea033c756af63978e3e7f3a4d187a08f8fa48144fdd  ACCEPTANCE.md
9af14e7e08219fe8e73be273b09c69d2afddd8b9fc013ca02dd8d7785ad5312a  stage-1/BRIEF.md
d0165b091d5bdee60cad4582570c1a5717d0cad1cffbdad67451d793e2ffd1b7  FREEZE.sha256
dbe6a91d0d76f105d3a8338d4743f3b12a2d7776395624a6f201105063a1cb82  PREPARATION.sha256
f0098292e6445ecee46dd2b69feb55867b8e5f0d949c1e31d6142b1594d9be58  BASELINE.sha256
```

## Executed evidence and limits

Commands ran in the original package, not the parent's clean reconstruction.

1. `git rev-parse HEAD`, `git diff a17f652 --stat`, and
   `git diff --exit-code a17f652 -- . ../../trial`: frozen HEAD above, no tracked
   differences. Status showed only untracked proof files and stage-1 records.
2. `sha256sum -c FREEZE.sha256`, `sha256sum -c PREPARATION.sha256`,
   `sha256sum -c BASELINE.sha256`: respectively **2/237/75 OK**, zero unexpected
   lines, confirmed with pipefail and an awk failure check after the first
   abbreviated inventory display.
3. In `lean/`, `lake env lean --version`: Lean **4.34.0**, release commit
   `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.
   Compiled each source in dependency order with
   `lake env lean -o .lake/build/lib/lean/<module>.olean <module>.lean`, for
   `Full/Proofs`, `Full/Proofs/Initial`, `Full/Proofs/Scope`,
   `Full/Proofs/Lifecycle`, `Full/Proofs/PartialGate`: all exit 0.
   PartialGate's fully qualified F5/L1 examples and sub-obligation examples
   elaborated successfully, with the printed types matching frozen meanings.
4. Additional audit via stdin, without writing a test source:

   ```sh
   { printf 'import Full.Proofs.PartialGate\n';
     awk '/^namespace /{ns=$2} /^theorem /{print "#print axioms " ns "." $2}' \
       lean/Full/Proofs.lean lean/Full/Proofs/Initial.lean \
       lean/Full/Proofs/Scope.lean lean/Full/Proofs/Lifecycle.lean;
   } | (cd lean && lake env lean --stdin)
   ```

   All **43 public theorems** printed transitive axiom sets contained in
   `{propext, Classical.choice, Quot.sound}`; no sorryAx or forbidden axiom.
   F5, initialized invariant and transition scope use all three; L1 and the
   Lifecycle facts use only propext/Quot.sound. Relevant private dependencies
   are included transitively in these checks. Source inspection also found no
   forbidden construction (keyword matches were only legitimate imports,
   namespaces, the local simp attribute and heartbeat option).

These are local source recompilation and transitive-axiom checks, using existing
frozen dependency build outputs. **This reviewer did not perform a clean
dependency reconstruction or `leanchecker --fresh`.** The parent is conducting
that separate verification in `/tmp/rob1139-stage1-clean.KI2lgA`; this review
neither built there nor assumes its outcome. No finite examples, controls or
proof mutations were rerun here. Only this review source was written; ignored
local olean outputs were refreshed by the explicit checks.

## Remaining obligations / verdict

Full **F1/F2/F3/F4/F6/L2 are not proved or claimed**. In particular, L2 still
needs the exact outside-only `Trial.validStart` of destroyed memory and each
initial outside root's unchanged `Trial.readBack`; identity preservation alone
does not establish these. F1 initialization and transfer-scope results do not
establish arbitrary reachable/boundary invariants, progress or exact effects.

The unchanged eight-target `ProofGate.lean` cannot pass with this partial set;
PartialGate is explicitly supplemental, not a replacement or bypass. Complete
stage-1 acceptance still requires all eight exact targets, its fresh kernel
gate, applicable unchanged tests/controls and the prescribed broader evidence.
No checker/caller-enforcement, frozen-source repair, commit, push or Linear
change is authorized or performed by this review. Accept these bounded partial
proofs as useful progress, subject to the parent's separately reported clean
recheck; do not describe the universal full stage as completed.
