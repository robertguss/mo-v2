# ROB-1139 D191 — separate scoped amendment review

10 October 2026. **Approved for this one-coefficient amendment only.** This is a separate execution under the same account (procedural separation), not independent-account certification. I read AUTHORIZATION.md and reviewed against local checkpoint `37914e13e175a2f0ad1eec19aa83ac0c2e87a16f`, not origin/main. No universal F2, complete stage-1 acceptance, or final freeze is certified here. The parent owns the clean archived amended build, unchanged finite-suite/controls runs, and final freeze.

## Scope and history

- `git rev-parse HEAD origin/main` returned respectively `37914e13e175a2f0ad1eec19aa83ac0c2e87a16f` and `a4056b8341122622106fe60f834dbf8e2428295f`. Repository is not shallow. No push, commit, or refreeze was performed.
- `git diff 37914e1 -- lean/Full/Control.lean` is exactly Decompose rank weight `10` → `12`. The only other tracked difference is deletion of the active negative module. All remaining tracked paths compare unchanged, including execution semantics, decoder, Statements F1–F6/L1–L2, predictions, old acceptance, locks, and old records. Untracked additions were enumerated and reviewed as regression/history/authorization/inventory/evidence artifacts, not substitute model definitions.
- `git show 37914e1:experiments/03c-checker/full/lean/Full/Proofs/RankCounterexample.lean | cmp - stage-1/counterexample/frozen/RankCounterexample.lean` exited 0: byte-for-byte historical preservation outside the active module tree. All 33 counterexample MANIFEST entries were independently SHA-256 checked against `git show <checkpoint>:experiments/03c-checker/full/<entry>`; all passed. This confirms the original proof, reproducer, dependencies and evidence remain at their checkpoint paths. I did not rebuild the historical checkout; its executable reproduction target remains that checkpoint, not the amended tree.
- The old counterexample MANIFEST check against the current tree fails only because the original negative module path is absent. This is intentional historical relocation, not a rewritten manifest. The historical reproducer still imports the old module and is not an amended-tree runner.
- `rg -n '^import .*RankCounterexample' lean --glob '*.lean'` found no active negative imports. A broader scan for RankCounterexample, sorry, axiom declarations, native_decide, unsafe and implemented_by found only explanatory comments about axioms, not bypasses. RankRegression imports Full.Statements; Full's default root still imports Full.Statements only. The fresh checker below validates the regression's transitive environment, rather than trusting stale negative build artifacts.
- All eleven concrete witness definitions in RankRegression (program/initial/first/source/target/plain and shared counterparts) compare byte-identically to the preserved negative module. Successful begin/advance/step equalities prevent the `getD` fallback from making reachability vacuous.

## Independently executed checks

From `experiments/03c-checker/full`:

```sh
diff -u PREPARATION.sha256 stage-1/rank-amendment-01/PREPARATION.sha256
sha256sum -c --quiet stage-1/rank-amendment-01/PREPARATION.sha256
sha256sum -c --quiet PREPARATION.sha256
sha256sum -c --quiet FREEZE.sha256
sha256sum -c --quiet BASELINE.sha256
git diff --check
```

Both preparations have exactly 237 entries. Their diff changes only the hash for `./lean/Full/Control.lean`, from `5e805da8c2b7f86fbf4e3f4fffb0f192aa773e5774a1f96c13eaea1d79a3ba15` to `c4f95e4d50044803b6daa6b5800bbd86850ce32995c9a221b908ff8afd1edde1`. Amended verification exits 0; old verification exits 1 with exactly Control failing, as approved. FREEZE and BASELINE verification exit 0. Diff whitespace check exits 0. No old inventory was rewritten.

From `experiments/03c-checker/full/lean`:

```sh
lake env lean --version
lake build Full.Proofs.RankRegression
lake env lean --run ../stage-1/rank-amendment-01/Regression.lean
lake env leanchecker --fresh Full.Proofs.RankRegression
lake env lean Full/Proofs/RankRegression.lean
```

All exit 0. Lean is 4.34.0, release, x86_64-unknown-linux-gnu, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`. Lake's 14-job target build replayed the target; this is not claimed as a clean archived build. The independently invoked fresh leanchecker completed silently, with explicit `FRESH_CHECKER_EXIT=0`. Direct source elaboration printed axioms for both `unique_decrease` and `shared_decrease` exactly `[propext, Quot.sound]`; neither depends on sorryAx, a new assumption, or the historical negation of F2.

Runtime output:

```text
unique unused tail: reachable steps 14->15; rank 21->19; equal decode; Plain step differs; both invariants true; final answer 3; finalGraph true; full trace accepted
shared unused tail: reachable steps 4->5; rank 21->20; equal decode; Plain step differs; both invariants true; final answer 3; finalGraph true; full trace accepted
PASS: both historical counterexamples satisfy the amended local rank obligation; universal F2 is not yet proved
```

The primary local Related/decrease obligation is kernel-proved; the shared decrease/stutter/reachability are kernel-proved, while its unfinishedness, Plain-step inequality and successful decode are additionally checked by this runtime runner. These checks do not assert the full universally quantified F2.

## Why 12 suffices; limits and potential effects

Reviewed Counted's Decompose transition and Control's rank/decoder. Both concrete steps retain the cell-list length (two cells, contributing 8), and the untouched continuation contributes 1. Unique unused-tail Decompose becomes GiveBinding (3), BranchStart (1), Eval zero-argument call (2), BranchResult (4): replacement weight 10. Shared unused-tail becomes GivePending (3), MatchComplete (1), BranchStart (1), Eval call (2), BranchResult (4): replacement weight 11. Thus the source is `8+12+1=21`, targets are `8+10+1=19` and `8+11+1=20`. Weight 11 would still give equality in the shared case; 12 is the smallest integer strictly exceeding both replacements. General bodies have eval weight at most 2, and these replacements introduce no further Decompose task.

There is no new issue found in this scoped correction. Raising the weight also increases the rank of states containing other Decompose tasks; preservation/decrease across every other transition is still an outstanding universal proof obligation. In particular, creation of Decompose work is not automatically justified by these local examples: the appropriate Plain-step disjunct must be established where rank increases. I do not infer global F2 from this arithmetic or from two accepted traces. Existing eight-target gate and acceptance requirements remain unchanged.

## Exact SHA-256 identities

```text
c4f95e4d50044803b6daa6b5800bbd86850ce32995c9a221b908ff8afd1edde1  lean/Full/Control.lean
9235fa69e9b2b5f4e99ce64382b087f5f3fd826059513e39d73945b31e0d9779  lean/Full/Proofs/RankRegression.lean
77c2ac2055b7239f0f60535503a0982832e573371e961a9eabfb615b289cfb6c  stage-1/rank-amendment-01/AUTHORIZATION.md
69f9d09183c304414714188a443cf08d618097a2ea432718f03a1e8c4a8c59cb  stage-1/rank-amendment-01/Regression.lean
821da5b1897b4b09245887fa27ac8d16d826998b15a283a4bb26771c349982db  stage-1/rank-amendment-01/PREPARATION.sha256
685178dd0be4dbaf08034f0e116671a795dd2b2b1fc4d42f7994c02586d16468  stage-1/counterexample/frozen/RankCounterexample.lean
dbe6a91d0d76f105d3a8338d4743f3b12a2d7776395624a6f201105063a1cb82  PREPARATION.sha256
d0165b091d5bdee60cad4582570c1a5717d0cad1cffbdad67451d793e2ffd1b7  FREEZE.sha256
f0098292e6445ecee46dd2b69feb55867b8e5f0d949c1e31d6142b1594d9be58  BASELINE.sha256
```

Only this REVIEW.md was written by this verifier; ordinary ignored Lake outputs were generated. Sources, expectations, locks and frozen records were left untouched.
