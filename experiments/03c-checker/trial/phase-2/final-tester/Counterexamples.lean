import Promises

open Trial

-- External evaluation input, not a candidate source or a proof.
def reuseProgram : Expr := .matchE (.var "xs") .nil "h" "t"
  (.cons (.add (.var "h") (.num 1)) (.var "t"))
def reuseStart : Start := ⟨[⟨1, 1, none, 2⟩], [("xs", .list (some 1))], [some 1]⟩
def forgetProgram : Expr := .num 7
def forgetStart : Start := ⟨[⟨1, 11, some 2, 1⟩, ⟨2, 22, none, 1⟩],
  [("xs", .list (some 1))], []⟩
def heldProgram : Expr := .num 7
def heldStart : Start := ⟨[⟨1, 11, none, 2⟩], [("xs", .list (some 1))], [some 1]⟩

def inspect (label : String) (r : Rule) (e : Expr) (s : Start) : IO Unit := do
  let wf := wellFormed (s.inputs.map (fun p => (p.1, p.2.kind))) e
  let valid := validStart e s
  IO.println s!"CASE {label}; rule {repr r}"
  IO.println s!"start = {repr s}"
  IO.println s!"wellFormed = {repr wf}; validStart = {repr valid}"
  IO.println s!"plainAnswer = {repr (plainAnswer e s)}"
  if !wf.toBool || !valid.toBool then throw (IO.userError "invalid counterexample")
  let good := runCounted .approved e s
  let goodPromises := (decide (Finishes good), decide (SameAnswer e s good),
    decide (NoVisibleChange s good), decide (NoLeak s good))
  IO.println s!"approved A,B,C,D = {repr goodPromises}"
  if goodPromises != (true, true, true, true) then throw (IO.userError "approved comparator failed")
  let bad := runCounted r e s
  IO.println s!"named A,B,C,D = {repr (decide (Finishes bad), decide (SameAnswer e s bad), decide (NoVisibleChange s bad), decide (NoLeak s bad))}"
  IO.println s!"named C1,C2 = {repr (decide (OutsideUnchanged s bad), decide (NamesUnchanged bad))}"
  let witness := match r with
    | .reusesShared => !decide (NoVisibleChange s bad)
    | .forgetsRest => !decide (NoLeak s bad)
    | .freesHeld => !decide (NoVisibleChange s bad)
    | _ => false
  if !witness then throw (IO.userError "named promise violation not demonstrated")
  IO.println s!"finalAnswer = {repr (finalAnswer bad)}"
  IO.println s!"full named outcome = {repr bad}"
  IO.println "EXPECTED VIOLATION CONFIRMED"

def main : IO Unit := do
  IO.println "Programs and starts are spelled out in external Counterexamples.lean."
  IO.println "reusesShared: match xs; [] -> []; [h|t] -> [h+1|t]"
  inspect "reusesShared violates Promise C" .reusesShared reuseProgram reuseStart
  IO.println "forgetsRest: constant 7; unused xs input is released before evaluation"
  inspect "forgetsRest violates Promise D" .forgetsRest forgetProgram forgetStart
  IO.println "freesHeld: constant 7; unused xs input shares its cell with outside holder"
  inspect "freesHeld violates Promise C" .freesHeld heldProgram heldStart
