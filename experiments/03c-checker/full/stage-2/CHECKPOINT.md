# ROB-1139 stage 2 — incomplete implementation checkpoint

**Stage 2 is not complete. The exact Conditional theorem is not delivered.**
The builder could not discharge the central semantic ownership/reservation
invariant. This checkpoint preserves executable and auxiliary-proof work; it is
not a scientific pass, a counterexample, a specification amendment, a new
authorization gate, or a substitute for the requested stage-2 result.

Work is local on `proofs/rob-1139-stage2`, based exactly on the remote stage-1
[commit](https://github.com/robertguss/mo-v2/commit/66f8aac22fbaa31100700a5ca9e5b486efd67c28).
The stage-2 additions are not committed or pushed. No existing tracked file was
changed. ROB-1139 remains Building, with explicit progress limitations; ROB-1138
remains Done. No merge, deployment, caller enforcement, unconditional guarantee,
or Rust refinement is claimed. Stage-1 Buildkite 90's canceled jobs remain a
delivery-CI limitation, not a failed proof or a CI pass.

## What exists and what was checked

The executable `Full.Demand.accepts` validates ordinary function typing, checks
list-parameter/local-list affinity, tracks innermost-first branch credits and
checks every demanded declaration under the same syntactic call rule. Callees
start with empty credit stacks; caller reservations do not justify acceptance.
Ordinary callees are conservatively refused, including the nonallocating
arithmetic-helper observation. There is no recursive no-Create premise in the
checker or certificate extraction.

The separate finite review is `verification-preflight/REVIEW.md`. It inspected
90 rows and 253 Enter records; all 84 finished answers and complete primitive
cell ledgers matched frozen predictions. All 12 accept / 6 refuse / 1 observe
slice-1 families passed their requirements (38 accept rows, 14 refusal rows,
1 observation). All 27 categories remain inventoried; slice 2's 3/3/2 categories
are not called caller-enforcement passes. The consumer does not newly certify
the six nonfinished lifecycle rows.

Actual-source controls detected accept-all (14 refusal failures plus 19
accepted allocating intervals), reject-all (38 usefulness failures), and
disabled affinity (`twice` accepted at unique entry with 2 Creates). Existing
21 stage-1 faulty routes and 28 Trial comparisons passed their controls.
No original-checker counterexample or specification defect was found.

The Lean proof prefix establishes syntactic certificate extraction, equivalence
of zero numeric/Boolean uses, continuation-wide last use given its bound,
nonincreasing occurrences for old binding IDs, ordered credit lower bounds,
invocation/event freshness, zero tally at the frozen Enter premise, closed
interval stability after Return, and saved-work invocation scope.

Builder reproduction, from repository root:

```sh
python3 -B experiments/03c-checker/full/stage-2/check-auxiliary.py
```

Its cache-free build, all 64 explicit public theorem type/axiom checks and
`lake env leanchecker --fresh AuxiliaryGate` passed. The freshly executed
checker reproduced all 90 prior preflight rows exactly. Source hashes, generated
gate, command logs and `result.json` are in `auxiliary/evidence/`; the result
explicitly sets `conditional_theorem_delivered` and `stage_2_complete` to false.

The separate proof-prefix verifier independently reconstructed the exact
stage-1 base plus only the seven additive Lean source files, without build
cache. Its 69-job build and `lake env leanchecker --fresh IndependentGate`
passed. It audited 64 explicit public theorems and 148 generated theorem
constants (212 total) against the complete `propext`, `Classical.choice`,
`Quot.sound` allowlist. No forbidden axiom or proof bypass was found. See
`verification-auxiliary/REVIEW.md`, the exact gate, inventories and command logs.
This is separate same-account verification, not independent-account isolation
or Stage B's single-agent exception.

## The remaining obligation is semantic, not another approval

An actual theorem of unchanged type
`Full.Statements.Conditional Full.Demand.accepts` must connect these facts:

1. Accepted syntax establishes continuation-wide affinity for newly introduced
   parameters, lets and match tails. The old-ID monotonicity theorem alone does
   not do this.
2. From the frozen unique/disjoint entry premise before parameter cleanup, local
   bindings, pending operands, descendants and cleanup preserve a unique region
   of cells. Saved caller holders/work cannot supply missing ownership.
3. The ordered lower-bound credits correspond to actual eligible reservations
   in the current invocation and active match scopes; each accepted Cons uses
   one. Static credit arithmetic alone does not establish this correspondence.
4. Finite-step induction preserves that invariant across simultaneous recursive
   calls, without postulating their no-Create result. The completed event lemmas
   then connect the active interval and arbitrary later caller execution to the
   frozen `creates` conclusion.

Only after this is proved can the exact Conditional gate, its axiom audit and
fresh kernel check, complete controls and separate full verification certify
stage 2. No such certification is recorded here. The accepted specification,
original predictions, all historical locks and D191's sole rank amendment are
unchanged. Required public gzip evidence was restored and checksum-verified
from release assets; no gzip evidence object was added to branch history.
