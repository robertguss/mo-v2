# Separate counterexample verification — 10 October 2026

## Judgment and stop condition

**Confirmed: `Full.Proofs.RankCounterexample.not_f2 : ¬ Full.Statements.F2` refutes the exact frozen F2. Stage 1 does not succeed.** This is a separate verifier execution under the same account, not independent-account certification. The scientific stop condition in `stage-1/BRIEF.md` applies: preserve the counterexample and stop proof completion against this specification. Do not repair the frozen rank, weaken F2, approve a refreeze, or proceed to the conditional checker/caller-enforcement gates without separately approved amendment and subsequent verification.

Only this review was written by this verifier; no proof, model, source, lock, or expectation was edited. Lake generated ordinary ignored build outputs. The parent separately owns the clean archived reconstruction; this review does not claim to have performed that reconstruction.

## Independently executed commands and outcomes

Working directory for the following commands: `experiments/03c-checker/full/lean`.

```sh
lake env lean --version
lake build Full.Proofs.RankCounterexample
lake env leanchecker --fresh Full.Proofs.RankCounterexample
lake env lean --run ../stage-1/counterexample/Reproduce.lean
lake env lean Full/Proofs/RankCounterexample.lean
sha256sum Full/Proofs/RankCounterexample.lean
lake build && printf 'BUILD_EXIT=0\n'
lake env leanchecker --fresh Full.Proofs.RankCounterexample && printf 'FRESH_CHECKER_EXIT=0\n'
```

- Version: Lean 4.34.0, release, x86_64-unknown-linux-gnu, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` (the frozen toolchain pin).
- Target build succeeded, 14 jobs (replayed target); package default build succeeded, 15 jobs, explicit `BUILD_EXIT=0`.
- Fresh kernel checker completed silently; separately repeated with explicit `FRESH_CHECKER_EXIT=0`. This checks RankCounterexample, not successful ProofGate completion.
- Direct source elaboration printed `not_f2` axioms exactly `[propext, Classical.choice, Quot.sound]`; `shared_ranks` exactly `[propext, Quot.sound]`.
- Runtime reproducer completed successfully with the following output:

```text
unique unused tail: reachable steps 14->15; rank 19->19; equal decode; Plain step differs; both invariants true; final answer 3; finalGraph true; trace rejects: administrative rank at 14
shared unused tail: reachable steps 4->5; rank 19->20; equal decode; Plain step differs; both invariants true; final answer 3; finalGraph true; trace rejects: administrative rank at 4
CONFIRMED: exact frozen F2 one-step obligation fails; no memory-safety failure claimed
```

SHA-256 of the proof file (also rechecked from the full directory):
`685178dd0be4dbaf08034f0e116671a795dd2b2b1fc4d42f7994c02586d16468`.
Reproducer SHA-256:
`1d8775113dbde8479b8f05f617f638b5f9a2e17cc8501750fd412242de188001`.

From `experiments/03c-checker/full`, before and after build/check execution:

```sh
sha256sum -c FREEZE.sha256
sha256sum -c PREPARATION.sha256
sha256sum -c BASELINE.sha256
```

All entries passed (2 freeze entries, 237 preparation entries, 75 Trial dependency entries). The second pass used `--quiet`, with success markers `FREEZE_OK`, `PREPARATION_237_OK`, `BASELINE_75_OK`. Frozen Statements, Control, Counted, Plain, imports, toolchain, Lake configuration and local Trial sources are covered by these inventories. The initial combined inspection command ended with exit 1 only because `cat stage-1/counterexample/evidence/*` matched no files: that directory is empty. All three inventory checks in that command passed; no historical evidence logs were relied upon.

## Adversarial premise and interpretation checks

Read the proof and reproducer in full, `Full/Statements.lean`, `Full/Control.lean`, `Full/Plain.lean`, relevant Counted transition/begin/advance/step/commit definitions, import headers, and `Trial.validStart` checks.

- **Exact quantifiers:** F2 is a conjunction. Its second conjunct requires, for every program/start/reachable state, an existential decoded plain state `a`, then for every successful target step of an unfinished source either `Related (Plain.step p a) t` or `Related a t ∧ rank t < rank s`. `hf.2.1` selects precisely that conjunct. No demanded-function restriction or separate invariant premise limits it.
- **Reachability and fallback:** `Reachable` means an actual successful `begin`, followed by successful `advance n`. The kernel-reduced `begin_ok` and `advance_ok` equalities supply these premises for n=14, and `step_ok` supplies the actual next target; `unfinished` supplies `answer = none`. Although witness definitions use `toOption.getD`, the proved `.ok` equalities rule out falling back on an error. The shared variant likewise has proved begin/advance/step equalities for n=4.
- **Valid starts:** Counted.begin validates the Full program and calls Trial.validStart before creating state. The primary start has no cells/inputs/outside roots. Shared start has acyclic cells 0->1->nil; cell 0 has two holders (input x and outside root), cell 1 one holder (cell 0's link). Both starts pass actual begin. Invalid-start or unreachable-state vacuity is not available.
- **Step numbering:** State steps defaults to zero; commit increments it by one; advance performs n successful steps unless already finished. Runtime confirms 14->15 and 4->5, with unfinished sources. These are counted ticks, not Plain ticks.
- **Existential plain choice:** Related is decode equality, not a loose simulation relation. `source_decode` fixes the primary existential `a` to `plain` by injectivity of Except.ok, so F2 cannot choose another plain state to escape the example.
- **Both disjuncts fail:** Primary source and target decode to evaluation of `f()` with t=[2], h=1 and empty continuation. Plain.step enters f, giving evaluation of 3 in the empty argument environment with a returning-f continuation. It is not the old plain state. `plain_step_changes` proves this inequality; target_decode therefore excludes the first disjunct. Ranks are kernel-proved 19 and 19, so strict decrease is false. `failed_obligation` and `not_f2` make this a theorem, rather than relying on runtime repr comparisons. Shared decode equality and ranks are also kernel-proved; the runtime independently checks its Plain-step inequality and unfinishedness.
- **No altered imports or bypass:** RankCounterexample imports only Full.Statements, which imports Full.Inspect and Full.Lifecycle; Inspect imports Control, Control imports Counted, Counted imports Plain, Plain imports Language, Language imports Trial.Counted. No other new stage-1 proof is imported along this Full chain. Frozen inventories pass. The proof contains no sorry, new axiom, native_decide, unsafe, opaque or implementation substitution; its transitive axiom list and fresh kernel check corroborate this. Other pre-existing untracked stage-1 proof files were left alone.

## Why Decompose weight 11 still fails the shared case

At these steps Decompose is replaced by administrative/body tasks without changing the number of allocated cells. For the primary unique unused-tail branch, replacement contributes GiveBinding (3), BranchStart (1), Eval zero-argument call (2), BranchResult (4): total 10, matching frozen Decompose weight 10. Shared unused-tail replacement adds GivePending (3), MatchComplete (1), BranchStart (1), Eval call (2), BranchResult (4): total 11. Thus shared frozen rank is 19->20. Changing only the source Decompose weight to 11 would make shared rank **20->20**, still not strictly decreasing; its Plain-step disjunct would remain false. This is analysis of the frozen transition, not an implemented correction or an approval of any amendment.

## Limits

This establishes a concrete contradiction to frozen F2, not a general memory-safety failure, not failure of every other statement, and not successful stage 1. Runtime invariant/finalGraph checks are finite corroboration only. The primary negation theorem supplies the decisive universal-statement refutation; no separate shared negation theorem is needed to refute F2. This verifier used the existing orb/worktree and dependencies, not an independent account or independently rebuilt compiler. Clean archive reconstruction belongs to the parent and remains a separately reported check. No rank correction or refreeze is authorized here.
