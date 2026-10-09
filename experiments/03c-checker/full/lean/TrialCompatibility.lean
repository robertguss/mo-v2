import Full.Counted
import Checks.Examples

/-! Fixed projection: `Counted.commit` keeps exactly old StepKind landmarks;
dispatch, scalar leaf/capture/primitive, let/if handoff and call actions have no
old landmark. No runtime subsequence selection or normalization is permitted.
Cell addresses and binding/branch lifetimes embed identically on this fragment. -/
def main : IO Unit := do
  for run in Checks.runs do
    let p : Full.Program := ⟨[],Full.embed run.program⟩
    let old := Trial.runCountedWith .approved run.program run.start
    let new := do Full.Counted.advance p 10000 (← Full.Counted.begin p run.start)
    match new,old.result with
    | .ok s,.answer raw =>
      unless s.answer.map (fun v => v.raw) == some raw do
        throw (IO.userError s!"trial {run.number}: answer mismatch")
      unless s.mem.record == old.record do
        throw (IO.userError s!"trial {run.number}: primitive event mismatch")
      unless reprStr s.landmarks == reprStr old.states do
        let pairs := s.landmarks.zip old.states
        let mismatch := pairs.findIdx? (fun (a,b) => reprStr a != reprStr b)
        throw (IO.userError s!"trial {run.number}: landmark mismatch at {mismatch}; lengths {s.landmarks.length}/{old.states.length}")
    | _,_ => throw (IO.userError s!"trial {run.number}: unexpected result")
  IO.println "PASS: all 28 trial answers, primitive cell events and complete ordered landmark snapshots"
