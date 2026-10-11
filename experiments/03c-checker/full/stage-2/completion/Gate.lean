import Full.Demand.Soundness
import Full.Proofs
import Lean.Elab.Command

example : Full.Statements.Conditional Full.Demand.accepts :=
  Full.Demand.Soundness.conditional

#check @Full.Demand.Soundness.conditional
#print axioms Full.Demand.Soundness.conditional

-- Enumerate the actual environment, including generated public theorems.
open Lean Elab Command in
run_cmd do
  let env ← getEnv
  for (name, info) in env.constants.toList do
    if name.toString.startsWith "Full.Demand." then
      match info with
      | .thmInfo _ => logInfo m!"PUBLIC_THEOREM {name}"
      | _ => pure ()
