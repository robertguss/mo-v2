import Withdraw.Spec
import Withdraw.Harness
import Withdraw.ImplA
import Withdraw.ImplB
import Withdraw.Mutants.M01
import Withdraw.Mutants.M02
import Withdraw.Mutants.M03
import Withdraw.Mutants.M04
import Withdraw.Mutants.M05
import Withdraw.Mutants.M06
import Withdraw.Mutants.M07
import Withdraw.Mutants.M08
import Withdraw.Mutants.M09
import Withdraw.Mutants.M10

/-!
Experiment 2 scoreboard. Runs the five automated methods on every version and
checks each planted bug's trigger input from `Mutants/KEY.md` against the
promises. A trigger that breaks the promises means `Correct` is false for that
version (by `holdsAt_iff`), so no Lean proof of it can exist: the proof method
catches it.
-/

open Withdraw

/-- Name, implementation, and the trigger input from the key (if any). -/
def versions : List (String × Impl × Option (Nat × Nat)) :=
  [ ("A (correct)", A.withdraw, none),
    ("B (correct)", B.withdraw, none),
    ("M01", Mutants.M01.withdraw, some (10000, 3000)),
    ("M02", Mutants.M02.withdraw, some (0, 100)),
    ("M03", Mutants.M03.withdraw, some (10000, 3000)),
    ("M04", Mutants.M04.withdraw, some (10000, 10000)),
    ("M05", Mutants.M05.withdraw, some (10000, 0)),
    ("M06", Mutants.M06.withdraw, some (100, 101)),
    ("M07", Mutants.M07.withdraw, some (4294967301, 3)),
    ("M08", Mutants.M08.withdraw, some (0, 2147483648)),
    ("M09", Mutants.M09.withdraw, some (2000000, 1000001)),
    ("M10", Mutants.M10.withdraw, some (5, 18446744073709551617)) ]

def show? : Option (Nat × Nat) → String
  | none => "-"
  | some (b, a) => s!"CAUGHT at ({b}, {a})"

def main : IO Unit := do
  for (name, f, trigger) in versions do
    -- B is the reference for everyone else; A is the reference for B.
    let reference := if name == "B (correct)" then A.withdraw else B.withdraw
    let proof := match trigger with
      | none => "proven (see AcceptA/AcceptB)"
      | some (b, a) => if holdsAt f b a then "TRIGGER DOES NOT BREAK PROMISES" else s!"CAUGHT: no proof can exist; ({b}, {a}) breaks a promise"
    IO.println s!"== {name}"
    IO.println s!"  examples     {show? (byExamples f)}"
    IO.println s!"  property     {show? (byProperty f)}"
    IO.println s!"  exhaustive   {show? (byExhaustive f)}"
    IO.println s!"  contracts    {show? (byContract f A.contract)}"
    IO.println s!"  differential {show? (byDifferential f reference)}"
    IO.println s!"  lean proof   {proof}"
