# Stage-1 first proof tranche — partial, 9 October 2026

**Two of eight exact obligations are proved: F5 and L1. Stage 1 is not complete.**
D188 authorized execution, not acceptance of an unfinished result. This bounded
tranche preserves useful proofs and records the remaining construction gap;
no concrete counterexample to the frozen specification was found.

The source is based on the unchanged approved freeze
[a17f652](https://github.com/robertguss/mo-v2/commit/a17f65215ed14288416c92e8af028078ffb827ff).
Proof additions are restricted to `lean/Full/Proofs.lean` and `lean/Full/Proofs/`.
The `stage-1/` records are additive integrator evidence, not revised frozen inputs.
This tranche is a local proof checkpoint, not pushed or merged. The remote still
contains the approved freeze only; no checker or deployment work occurred.

## Exact results

| Frozen obligation | Status |
| --- | --- |
| F1: invariant/progress/effects/boundaries | Partial: initialized full invariant, initial scope/IDs and source-prescribed transfer scope proved; general preservation/progress/effects remain |
| F2: two-way Plain simulation and rank | Unproved |
| F3: protection and actual Plain prefixes | Unproved |
| F4: exact finished graph | Unproved |
| F5: budget and resumption laws | **Proved as `Full.Proofs.f5 : Full.Statements.F5`** |
| F6: universal Trial compatibility | Unproved; finite comparisons are not a proof |
| L1: denial transaction | **Proved as `Full.Proofs.l1 : Full.Statements.L1`** |
| L2: destruction | Partial: idempotence, destroyed flag, control clearing, preserved events/history/record, outside-root identity and exact cleanup membership proved; outside-only graph validity and unchanged outside readback remain |

F5 includes zero budget, split execution including error propagation, terminal
absorption, and step-count bound/exactness. L1 is equality of the complete denied
state, not just an unchanged answer. Their unused reachability premises are not
replaced with hidden hypotheses: their proofs establish stronger general facts.

All auxiliary results are ordinary proved theorems. There are no placeholders
for the six missing targets. `Full/Proofs/PartialGate.lean` explicitly checks the
partial result; it does not replace the frozen eight-target `ProofGate.lean`.

## Reproduction and evidence

From `full/lean`:

```sh
lake build Full.Proofs.PartialGate
lake env leanchecker --fresh Full.Proofs.PartialGate
lake env lean ProofGate.lean # currently exits 1: six required proofs are absent
```

The integrating author reconstructed frozen source with `git archive a17f652`
from the repository root, selecting `experiments/03c-checker/full` and the
unchanged `experiments/03c-checker/trial` dependency. Only the five new proof files
were copied into that otherwise clean reconstruction; no `.lake` output was
copied. The same commands compiled **55 jobs** and the partial fresh kernel check
exited **0**. All five working proof files were byte-compared to the clean,
kernel-checked copies. See `evidence/clean-build.log` and `evidence/kernel.log`.

Separate review in `REVIEW.md` inspected the exact meanings, source, write scope
and axiom sets. All **43 public theorems** have transitive axioms contained in
`{propext, Classical.choice, Quot.sound}`; private proof dependencies are covered
transitively. `evidence/axioms.log` records the audit. Same-account procedural
verification is not independent-account scientific certification.

The unchanged full gate was also executed. It exits **1** because `f1`, `f2`,
`f3`, `f4`, `f6` and `l2` are absent. This is recorded in
`evidence/full-gate-incomplete.log`, not suppressed or reclassified as a passing
stage. No full ProofGate kernel check or proof-mutation acceptance is claimed.

Fresh finite checks also pass: **90 cases, 820 expanded groups, 12/12 export
corruptions, 4,498 internal equalities, 9,680 observer views, 3 boundary/view
corruptions, 28 Trial comparisons and 21 executed logical faulty routes**.
See `finite-suite.log`, `trial-compatibility.log` and `controls.log` under
`evidence/`. The regenerated raw observation hash matches the retained frozen
observations. These are unchanged-model controls, not proof mutations.

FREEZE/PREPARATION/BASELINE checks still pass (2/237/75 entries). No frozen
statement, definition, original prediction or historical lock changed.
`MANIFEST.sha256` inventories this partial checkpoint; it is not a replacement
scientific freeze or a declaration that stage 1 passed.

## Why the remaining proofs need a stronger induction hypothesis

`Inspect.invariant` is the frozen observable/data obligation, but alone does
not establish task-stack shape, slot splits, expression typing or legal pending
cleanup actions. Proving its initialization does not prove it is sufficient
for transition progress. A full preservation proof needs a stronger invariant
that implies the frozen obligations without assuming their future correctness.

Direct inspection and a focused oracle consultation select a new **typed
residual-control invariant** for Full, reusing Trial's `HeapSafe`, count and path
lemmas rather than its completed-evaluation `StateInvariant`/`Healthy` framework.
The latter demands positive counts, while valid Full execution exposes a live
zero-count cell between GiveUp and Free. This is intentional, not a discovered
contradiction. Recursive functions also cannot inherit Trial's terminating
expression-evaluation contract.

The remaining construction must jointly describe tasks and their slot segments,
typed environments and call/return structure, source uses plus queued releases,
and well-bracketed reservations. Use outside/holding-binding/slot roots for
Trial's holder lemmas: `Inspect.owners` already includes live-cell links and
would double-count them if used as the external roots.

The next concrete lemma is zero-count Free preservation: release an allocated
live zero-count cell, transfer its outgoing link to a cleanup slot, preserve
protected paths and exact counts, and relate the inserted GivePending/slot pair
to unchanged Plain control. Keep GiveUp, transfer output and commit as distinct
boundaries. Then prove the typed residual grammar is initialized and preserved
by each action before deriving F1–F3 on the existing finite Reachable witness.

This is a proof-construction gap, not owner acceptance, a new semantic gate,
or evidence that the frozen theorem is false. D188 permits continuing stage 1;
do not ask to reapprove the frozen package. Checker/caller-enforcement work
remains blocked until the complete stage-1 result and their separate approvals.
