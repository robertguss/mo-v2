# Check-in 2: independent Lead findings

Recorded 2 Oct 2026 before reading the fresh Tester's findings.
Candidate: `38c4b7accc32cea8a3714eeb93c5917b4431ab8c`.
Baseline: `787e0427244837fd0f44b76c4a648d07938c3bcc`.
Prior checkpoint: `8c57ccbd4f41dea91f2cda903d9377362f37270a`.
Remote tip matched candidate; local review branch and worktree were clean.

## Outcome

Proven: none (0/4). Unfinished: all four original theorem bodies at
`Proofs.lean:11,13,15,17`. All accepted axiom lists remain `[propext, sorryAx]`.
Counterexamples: none found in these checks; no exhaustive search performed.
No demonstrated integrity, specification or setup blocker.

## Executed checks

- 25/25 last-occurrence lock fingerprints match; LOCK.md unchanged.
- Full baseline diff: 57 permitted proof paths only. New interval adds 27
  modules and changes only the own-module import in the original proof stub.
  `git diff --check` passes; no untracked review-worktree files at inspection.
- Fresh baseline archive plus only candidate proof files reconstructed under
  `/tmp/mo-checkin-2-lead`; `.lake` absent before build.
- `lake build Trial Checks Promises Proofs Acceptance`: 75 jobs, exit 0,
  exactly four original unfinished-proof warnings. No other warnings/errors.
- Locked Acceptance compiles; separately printed types are exact PromiseA–D,
  and their definitions retain valid-start quantification and approved rule.
- `lake env leanchecker --fresh Acceptance`: exit 0. This does not remove
  the unfinished assumptions.
- `lake env lean --run Checks/Run.lean`: exit 0; byte comparison with frozen
  `results/run-1.txt`: exit 0. All mismatch counts 0.
- Source searches and review of declaration boundaries/invariant definitions,
  runner connection and match/branch composition found no changed locked
  meaning, parser override, kernel bypass, forbidden construct or added axiom.
  Only original four unfinished bodies remain. Helpers use Trial.Proofs;
  simp attributes remain on own lemmas. Conditional `promises_of_contract`
  still requires the unproven evaluator contract.
- Broken-copy checks 9–10 not run, as required before completed proof.

The new contract connects its conditions to the actual four promises and
includes both liveness directions and reservation suffixes. The complete
nonempty-match composition and structural induction are still missing.
Builder's count of 289 helper axiom checks is not independently recounted
here and does not count as completed promises.

This is verified unfinished work, not finished acceptance. Raw command output
is in this directory, recorded before comparing Tester findings.
