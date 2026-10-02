# Full acceptance: original independent Lead findings

Recorded 2 Oct 2026 around 07:23 UTC, before reading the fresh Tester's findings.
Candidate `baf1d52649bc7a50ff7df19d0368d182efdb3fbd`; amended baseline
`787e0427244837fd0f44b76c4a648d07938c3bcc`. Remote tip matched before checking.

## Outcome

All four exact promises pass the Lead's ten locked checks: finishing, same
answer, no visible changes at recorded moments, and no leaks. No unfinished
bodies or nonstandard assumptions remain. No counterexample to the approved
rule found; this is not a claim of exhaustive empirical testing. Tester and
Oracle review are pending at the time these independent findings are written.

## Checks and raw evidence

1. All 25 effective SHA-256 lock rows match, last occurrence per path wins;
   LOCK.md itself is unchanged (`integrity.txt`).
2. Whole baseline-to-candidate diff contains only 59 permitted proof paths.
   Review checkout was clean, with no untracked source/report changes. Fresh
   baseline archive plus only candidate Proofs.lean/Proofs reconstructed under
   `/tmp/mo-final-lead`, without inherited build files.
3. Source scans and review found no unfinished executable body, extra axiom,
   forbidden construct, parsing override, check/statement change or kernel
   bypass. The original stub's prose still mentions `sorry`; other literal
   keyword matches are prose comments. Helpers use Trial.Proofs; own simp
   lemmas do not alter locked definitions. Prior independently checked helper
   files are unchanged; the final diff closes actual match composition,
   structural induction and the four projections.
4. Empty-.lake `lake build Trial Checks Promises Proofs Acceptance`:
   77 jobs, exit 0, no warnings/errors (`build.txt`, `exits.txt`).
5. Locked Acceptance compiled; separate printed types and unfolded promise
   definitions preserve exact universal valid-start statements about the
   approved rule (`types.txt`).
6. Each accepted theorem's axiom list is exactly
   `[propext, Classical.choice, Quot.sound]`, with no `sorryAx` (`build.txt`).
7. `lake env leanchecker --fresh Acceptance`: exit 0 (`exits.txt`).
8. `lake env lean --run Checks/Run.lean`: exit 0. Frozen run-1 byte comparison
   exit 0, all mismatch counts 0 (`examples.txt`, `exits.txt`).
9. `Controls.lean` executes the pre-existing WORKER-BRIEF K2–K4 inputs.
   All validStart evaluations return `.ok ()`; approved controls return true.
   Shared reuse makes promise C false: outside `[4,9]` becomes unreadable
   while reserved, then reads `[8,9]`. Forget-rest makes promise D false:
   cell 2 remains allocated with count 1 and no root. Free-held makes C false:
   outside cell 1 becomes unallocated (`controls.txt`, execution exit 0).
   In three separate empty-cache throwaway copies, only Rule.variant's
   approved branch was changed to the corresponding named record. Whole
   tracked-file byte comparisons verified that exact one-line change
   (`mutations.txt`). Each clean `lake build Acceptance` exits 1 at
   `Proofs/Final.lean:45:55`, the public-rule/runner connection. The copied
   rule no longer reduces to the approved runner. The concrete failed
   predicates above are essential evidence, not merely these build failures.
10. A fourth exact one-line substitution uses neverReuses. Trial/Checks build
    exits 0; the frozen runner exits 0 but REPORTS 69 approved/total mismatches,
    control mismatches 0. Its exit status alone is not the criterion. K5 also
    returns `[8,9]` with one release and one creation, no write-in-place
    (`neverReuses-examples.txt`, `neverReuses-exit.txt`, `controls.txt`).

All mutations and control inputs stayed outside the candidate repository.
No proof was written by the Lead. Exact raw outputs and the external evaluation
input are in this directory, recorded before seeing Tester findings.

## Limits

These are the locked Lean trial statements, not a proof that the encoding
matches the English on every program. Visibility is at recorded snapshots;
intermediate-only holders are not separately covered by promise C. The trial
excludes calls, recursion, a demand checker, speed claims and the Rust helper.
The original example agreement and newly executed controls support only their
stated roles. Nothing here authorizes a scientific scope change or merge.
