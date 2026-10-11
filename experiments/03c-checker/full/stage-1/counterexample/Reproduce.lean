import Full.Proofs.RankCounterexample

open Full Full.Proofs.RankCounterexample

def checkCase (name : String) (p : Program) (start : Trial.Start) (ticks : Nat)
    (before after : Nat) : IO Unit := do
  let result : Except String String := do
    let first ← Counted.begin p start
    let source ← Counted.advance p ticks first
    let target ← Counted.step p source
    let a ← Control.decode source
    let b ← Control.decode target
    if source.answer.isSome then throw "source already finished"
    if reprStr a != reprStr b then throw "not a stuttering step"
    if reprStr (Plain.step p a) == reprStr b then throw "Plain-step disjunct holds"
    if Control.rank source != before || Control.rank target != after then throw "unexpected ranks"
    if Control.rank target < Control.rank source then throw "rank disjunct holds"
    if !Inspect.invariant start source || !Inspect.invariant start target then
      throw "unexpected data-invariant failure"
    let final ← Counted.advance p 100 first
    let some answer := final.answer | throw "program did not finish"
    if (← Trial.readBack final.mem answer.raw) != .num 3 then throw "wrong final answer"
    if !Inspect.finalGraph final then throw "unexpected final-graph failure"
    match Inspect.trace p start 100 first with
    | .ok () => throw "frozen trace unexpectedly accepted"
    | .error why =>
      if why != s!"administrative rank at {ticks}" then throw s!"unexpected trace failure: {why}"
      pure s!"{name}: reachable steps {source.steps}->{target.steps}; rank {before}->{after}; equal decode; Plain step differs; both invariants true; final answer 3; finalGraph true; trace rejects: {why}"
  match result with
  | .ok line => IO.println line
  | .error why => throw (IO.userError s!"{name}: {why}")

def main : IO Unit := do
  checkCase "unique unused tail" program initial 14 19 19
  checkCase "shared unused tail" sharedProgram sharedInitial 4 19 20
  IO.println "CONFIRMED: exact frozen F2 one-step obligation fails; no memory-safety failure claimed"
