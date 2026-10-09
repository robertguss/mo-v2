# Stage-1 execution brief — D188

Robert replied “Approved. Do it now” in the
[working thread](https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491)
after delivery of the approved freeze and identification of stage-1 proof
execution as the next gate. This authorizes starting that stage, not a checker
or a change to the frozen specification.

Target the exact F1–F6/L1–L2 types and future proof names in `lean/ProofGate.lean`,
against frozen revision
[a17f652](https://github.com/robertguss/mo-v2/commit/a17f65215ed14288416c92e8af028078ffb827ff).
Check FREEZE, PREPARATION and BASELINE inventories before and after execution.
No definition, theorem statement, prediction, acceptance check or old lock may
change. Builder code writes are restricted to `lean/Full/Proofs.lean` and
`lean/Full/Proofs/`. Integrator records and verification evidence belong in this
new `stage-1/` directory, outside the frozen package.

The integrating specification author performs the proof work, not the original
independent acceptance author. A different verifier checks any delivered result
or counterexample. This remains same-account procedural separation.

Use the existing orb, pinned Lean 4.34.0, and existing dependencies. No new paid
service, provider or infrastructure is authorized. Operational first-tranche
budget chosen by the agent: at most 60 minutes of active work, stopping earlier
at a concrete specification defect or integrity failure. This is an execution
guard, not a bound on programs or a user-selected mathematical assumption.

No placeholders, new axioms, native/unsafe/opaque proof bypasses or changes to
frozen meanings are permitted. Keep fully proved partial results if the whole
stage cannot be completed. A counterexample is a stop condition: preserve a
reproducer and obtain separate verification; do not repair the frozen definition
or weaken its theorem in this execution.

For a successful complete result, compile all eight exact type checks, inspect
transitive axioms against only propext/Classical.choice/Quot.sound, reconstruct
the frozen package plus permitted proof files in a clean build, run the pinned
`leanchecker --fresh ProofGate`, and rerun the unchanged finite acceptance and
applicable controls. Finite tests or compilation of Prop definitions do not
count as universal proofs. Stop after reporting stage 1; conditional checker
and caller enforcement require their separate later approvals.
