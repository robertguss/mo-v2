# ROB-1137 independent partial-checkpoint acceptance

Recorded 2026-10-02 UTC in Tester thread T-01a0fae6-c94d-727a-bb87-11152865679f before receiving or reading any Lead findings. No proofs were written or changed. Stop condition: finish applicable partial checks 1–8 and report, or stop on integrity/setup/specification blocker. No blocker found.

## Identity and reconstruction

- Fetched `origin rob-1136-trial-proofs-high`; FETCH_HEAD exactly `8c57ccbd4f41dea91f2cda903d9377362f37270a`; checked out that exact SHA detached.
- Amended baseline: `787e0427244837fd0f44b76c4a648d07938c3bcc`.
- Plan: `ad9302cd4aacaf08ca0d82a01c3aaadca92c9201`; verified ancestor of candidate (exit 0), with no tree difference from amended baseline.
- Read candidate CLAUDE.md, ACCEPTANCE.md, PROOF-BRIEF.md, LOCK.md, Promises.lean and Acceptance.lean, and all 30 candidate proof files in full.
- Fresh copy created by `git archive 787e0427244837fd0f44b76c4a648d07938c3bcc | tar -x -C /tmp/rob-1137-independent/fresh`, then copying only candidate `lean/Proofs.lean` and `lean/Proofs/` into its trial. Every candidate tracked file byte-compared equal to the reconstruction before building. `.lake` did not exist.
- Fresh Lean working directory: `/tmp/rob-1137-independent/fresh/experiments/03c-checker/trial/lean`.
- Lean 4.34.0, commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b; Lake 5.0.0-src+293d5d0. Selected by the locked local lean-toolchain; no global default changed.

## Three separate result lists

**Proven:** none (0/4).

**Unfinished:** all four, with the only executable `sorry` occurrences:

| Theorem | Meaning | Location in trial |
| --- | --- | --- |
| Trial.promiseA | Every valid run finishes with a readable answer | lean/Proofs.lean:11 |
| Trial.promiseB | Every valid run agrees with the plain meaning | lean/Proofs.lean:13 |
| Trial.promiseC | Outside and still-held names' lists remain unchanged | lean/Proofs.lean:15 |
| Trial.promiseD | Final memory has no leaks and exact holder counts | lean/Proofs.lean:17 |

**Counterexamples:** none found in this acceptance run. This is not an exhaustive counterexample search and does not establish that the promises are true.

## Check outcomes

1. PASS. All 25 effective lock rows match SHA-256 in candidate and reconstruction, using the last table occurrence of each path. LOCK.md itself is unchanged from baseline.
2. PASS. Whole baseline-to-candidate diff contains 30 allowed paths, 3,767 insertions: one import in Proofs.lean and 29 new helper files. No other tracked change, untracked path or ignored path existed at audit time. `git diff --check` succeeded. Original whole diff and path lists preserved separately from reconstruction.
3. PASS under partial-work exception. Full reading plus token search found only the four allowed unfinished proofs. Other search hits are the original comment mentioning `sorry` and English comments saying “prefix.” Helpers use namespace Trial.Proofs, imports lead back to locked Promises/Trial, and simp attributes are on their own lemmas. No added axiom, unsafe/native implementation, syntax/notation manipulation, locked-definition attribute, export/renaming, kernel option, or changed statement meaning found. Helper hypotheses remain explicit obligations, not replacements for the universal promises.
4. PASS under partial-work exception. `lake build Trial Checks Promises Proofs Acceptance` exited 0, “Build completed successfully (48 jobs).” Exactly four declaration-uses-sorry warnings, at the four locations above; no other warnings or errors. All 29 helper modules built.
5. PASS. Locked Acceptance compiled. `lake env lean /tmp/rob-1137-independent/Types.lean` exited 0 and printed Trial.accepted_a : Trial.PromiseA, accepted_b : PromiseB, accepted_c : PromiseC, accepted_d : PromiseD. Printed definitions quantify over every Expr and Start, assume only validStart = .ok (), and use runCounted Rule.approved with the exact respective locked predicate.
6. NOT SATISFIED for any promise. All four accepted theorems print exactly `[propext, sorryAx]`. Therefore none qualifies as proven, even though the allowed partial build and kernel recheck succeed.
7. PASS. `lake env leanchecker --fresh Acceptance` exited 0, with empty stdout/stderr. This rechecks proof terms; it does not remove the unfinished assumptions identified by check 6.
8. PASS. `lake env lean --run Checks/Run.lean` exited 0; `diff -u ../results/run-1.txt /tmp/rob-1137-independent/evidence/examples.txt` exited 0 with empty diff. Approved-rule mismatch count 0; control mismatch count 0; total mismatch count 0. Output SHA-256 is the frozen `4b85ff0c0561722d584e8c60b730a25d6f5cdca7d0222dde33fcc2d024ca8847`. The locked check-8 runner includes its existing misreport control; no separately substituted broken-copy checks were run.

Checks 9–10 deliberately not run: proof is unfinished. No completed-proof acceptance claim is made.

## Interpretation and limits

The helper library establishes conditional results about finite live paths, exact ownership counts, release/reuse, binding liveness, snapshot visibility, input initialization and final-state predicates. These are not four universal counted-evaluator proofs; those bodies remain unchanged stubs. No integrity, setup or demonstrated specification violation found. An unfinished proof is inconclusive, not evidence that its promise is false.

No source edits, Linear writes, Oracle calls, commits, pushes, child threads or proof-solving attempts occurred. Candidate checkout remained clean after acceptance. The only later workspace addition is the explicitly labeled Tester evidence export, not candidate work.

## Original evidence

All original evidence lives in this orb under `/tmp/rob-1137-independent/evidence/`:

- `integrity.txt`: effective lock hashes for both copies, exact identities and empty-cache observation.
- `whole-candidate.diff`, `paths.txt`: complete candidate diff and allowed-path review input.
- `status-before.txt`, `status-after.txt`, `untracked.txt`, `ignored.txt`: all empty.
- `forbidden-scan.txt`: literal token matches, interpreted above after full file reading.
- `toolchain.txt`: actual pinned tool versions.
- `build.log`, `build-exit.txt`: clean reconstruction build and exit 0.
- `types-axioms.txt`: exact theorem types, unfolded promise definitions and axioms.
- `leanchecker.log`, `leanchecker-exit.txt`: empty kernel log and exit 0.
- `examples.txt`, `examples-stderr.txt`, `examples.diff`, `examples-exit.txt`: raw frozen-comparison output, empty stderr/diff, exits 0.

External type-printing input: `/tmp/rob-1137-independent/Types.lean`. Original report: `/tmp/rob-1137-independent/REPORT.md`. A review export packages this report, the type-printing input and raw evidence; it does not include build products.
