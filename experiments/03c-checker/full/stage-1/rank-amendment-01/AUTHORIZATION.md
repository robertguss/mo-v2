# D191 — approved one-coefficient rank amendment

10 October 2026. Robert replied “yes” in the
[working thread](https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491)
to the explicit proposal to change Decompose's rank weight from 10 to 12,
obtain separate review, record an amended freeze preserving the old failure,
and resume stage 1.

The only authorized model edit is that coefficient in `Full/Control.lean`.
F1–F6/L1–L2, the decoder, language, execution semantics, predictions and existing
acceptance checks stay unchanged. The old FREEZE/PREPARATION/BASELINE records,
old negative proof and evidence are historical records, not mutable inventories
to make the new model appear to have passed the old freeze.

Before the amendment, all continuation files and the negative proof were
committed locally at `37914e13e175a2f0ad1eec19aa83ac0c2e87a16f`. That revision
retains the original counterexample module at its original import path and is
the reproduction target for `counterexample/Reproduce.lean` and its manifest.
The same negative-proof bytes now also live at
`counterexample/frozen/RankCounterexample.lean`, outside the active Lean module
tree. Do not import that historical theorem against the amended definition.

New regression proofs are in `Full/Proofs/RankRegression.lean`; the amended
runtime check is `Regression.lean` here. The expected local inequalities are
21 → 19 for the unique unused tail and 21 → 20 for the shared unused tail.
These are not a substitute for universal F2 or the unchanged eight-target gate.

After separate review and the amended freeze, resume under the existing stage-1
proof-only write scope. D190's no-discretionary-checkpoint instruction remains
active. Any further verified specification defect still requires preserving the
failure, separate verification and an explicit scoped amendment. No checker,
caller enforcement, PR, merge, deployment or remote push is authorized here.
