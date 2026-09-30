# The lead's quick checks of the worker's Lean

These are the lead's own checks of the trial's Lean (`../lean/Trial/`), written
and run by the lead outside the repository while the worker was building, as
`../WORKER-BRIEF.md` ("What the lead checks after each part") requires. They are
kept here as evidence once the parts were committed. They are not the acceptance
criteria: those are the frozen predictions (`../PREDICTIONS.md`), checked by the
separate check-writing session's files.

- `Smoke1.lean`: part 1 (well-formedness and the plain meaning), rows W1 to W16
  and B1 to B8 of the brief.
- `Smoke2.lean`: part 2 (starting memories, reading back, the counted meaning),
  rows V1 to V9, F1 to F4, S1 to S5, K1 and K6 of the brief; two extra rows, X1
  (the cascade of frees) and X2 (a `match` gives up unneeded names before its
  sharing check), which the lead added after a deliberate change to the code
  showed the brief's rows did not exercise them. On each of S1 to S5, X1 and X2
  it also checks the log against memory's own record, the answer against the
  plain meaning, promise (d) at the end, outside holders' lists in every
  snapshot, and the coherence of every snapshot (each cell's count equals the
  holders it lists). K1 (the misreport control) has its own checks, including
  coherence; one more line checks coherence alone on `[37 | []]`.

Run either one from `../lean/` after `lake build`:
`lake env lean ../lead-checks/Smoke2.lean`. It prints only Lean's list of
assumptions; any failed check is an error.

Each was also run against deliberately broken copies of the code, each of which
had to fail at least one row: part 1, subtraction done as addition and the
match-names check turned off; part 2, a cell set aside at the wrong count, the
cascade skipped, the D90 free moved before its snapshot, the match's step 3
dropped, and a missing intermediate holder. None of the twenty example programs
(P1 to P20) is run here.
