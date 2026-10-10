import Full.Proofs.RankRegression

open Full Full.Proofs.RankRegression

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
    if !(Control.rank target < Control.rank source) then throw "rank did not decrease"
    if !Inspect.invariant start source || !Inspect.invariant start target then
      throw "unexpected data-invariant failure"
    let final ← Counted.advance p 100 first
    let some answer := final.answer | throw "program did not finish"
    if (← Trial.readBack final.mem answer.raw) != .num 3 then throw "wrong final answer"
    if !Inspect.finalGraph final then throw "unexpected final-graph failure"
    Inspect.trace p start 100 first
    pure s!"{name}: reachable steps {source.steps}->{target.steps}; rank {before}->{after}; equal decode; Plain step differs; both invariants true; final answer 3; finalGraph true; full trace accepted"
  match result with
  | .ok line => IO.println line
  | .error why => throw (IO.userError s!"{name}: {why}")

def main : IO Unit := do
  checkCase "unique unused tail" program initial 14 21 19
  checkCase "shared unused tail" sharedProgram sharedInitial 4 21 20
  IO.println "PASS: both historical counterexamples satisfy the amended local rank obligation; universal F2 is not yet proved"
