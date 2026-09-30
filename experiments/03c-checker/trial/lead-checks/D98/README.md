# The lead's checks of the D98 change

D98 (Robert's decision, 30 Sep 2026) added two things to the counted meaning's
snapshots: the value a `match` branch has worked out, in the two snapshots taken
as it finishes (`Snapshot.branchValue`), and a snapshot each time a chosen branch
is about to run (`branchStarts`). Nothing a run does was to change. The worker
made the change in `../../lean/Trial/Counted.lean`; these are the lead's checks
of it, run before the oracle's review. They are not acceptance criteria, and none
of the twenty example programs (P1 to P20) is among their programs.

- `DiffOld.lean` and `DiffNew.lean`: the same eleven runs of the lead's programs
  (the lead-check programs, a nested `match` whose outer branch adds 100 to the
  inner branch's number, and an `if` taken both ways) under the approved rule and
  the misreport copy, printed in full. `DiffOld.lean` runs against the Lean as it
  stood at `8a4187b` (for example a `git archive` of that commit); `DiffNew.lean`
  runs against the changed Lean and leaves out the `branchStarts` snapshots and
  the new field. The two outputs were byte for byte the same (887 lines).
- `Values.lean`: against the changed Lean, the recorded values at every finishing
  moment against values worked out by hand (the nested case: 4, 4, 104, 104);
  the value present exactly on the two finishing kinds of snapshot; every chosen
  branch followed by exactly one `branchStarts` before the next is chosen; and,
  on the `if` whose unneeded list is given up when its branch is chosen (D86),
  that list already given up and its cells freed at `branchStarts`. It printed
  no failures.

Run from `../../lean/`: `lake env lean --run ../lead-checks/D98/Values.lean`.

Four deliberately broken copies of the change each had to fail `Values.lean`,
and did: a wrong value recorded (14 failures); the inner branch's value recorded
again at the outer branch's finish (4); the `if`'s `branchStarts` taken before
the unneeded names are given up (1); no value in the handed-on snapshot (16).
The three unsafe copies of the rule and the copy that never reuses were not run
here (`INTERFACE.md` section 7 keeps them for after the proof); reading
`Trial/Broken.lean` shows that each is the approved rule with one switch on,
running through the same code and so the same snapshots.
