# The lead's quick checks of the promises' Lean statements (step 5)

Checks by the lead of `../../lean/Promises.lean`, the four promises of `PLAN.md`
Q2 as Lean statements, typed by the worker from `../../WORKER-BRIEF.md` part 4.
They are not acceptance criteria. Run from `../../lean/` after
`lake build Trial Checks Promises`:
`lake env lean ../lead-checks/step5/Step5.lean`. It prints one line naming the
run used for the (c2) changes; any failed check is an error.

`Step5.lean` checks two things:

- On all twenty-eight example runs, under the approved rule, the starting memory
  is valid, there is at least one snapshot, and each promise evaluates to true
  for that run: (a) `Finishes`, (b) `SameAnswer`, (c) `NoVisibleChange`, (d)
  `NoLeak`.
- On real outcomes changed by hand, the matching promise evaluates to false:
  (c1) an outside holder's cell changed in one snapshot, and the outside holders
  themselves changed; (c2) a name's cell changed, or missing, in a later snapshot
  where the name still holds, and a baseline that cannot be read back; (a) and
  (b) a run that failed while running, a refused run, an unreadable answer, and a
  readable but different answer; (d) an extra unreachable cell (with count 0 and
  with count 1), every count one too high, a cell left set aside, two cells at one
  address, and an outside holder's cells removed.

Each check was also run against three deliberately broken copies of
`Promises.lean`, each of which had to make a check fail, and did: (d) without its
count clause; (c2) without its requirement that the baseline reads back; (c1)
without its comparison of each snapshot's read-back with the starting one.

Also checked, not kept as files: a clean build of `Trial Checks Promises Proofs
Acceptance` from an empty `.lake` in a copy outside the repository (no errors;
exactly the four `sorry` warnings of the stub); `#print axioms` in
`Acceptance.lean` shows `propext` and `sorryAx` for each of the four;
`lake env leanchecker --fresh Acceptance` passes; a search of the three new
files for forbidden words finds only the four stub `sorry`s and the words in
comments and `#print axioms`; the fingerprints of the frozen and run files
match `LOCK.md` and `RUN-1.md`.

The broken copies of the rule are not run here (`INTERFACE.md` section 7 keeps
them for after the proof).
