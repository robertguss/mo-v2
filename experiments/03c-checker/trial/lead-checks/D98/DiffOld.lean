import Trial
open Trial Expr

-- Lead's differential and value checks for D98 (outside the repo). Programs are the lead-check
-- programs and a few of the lead's own; none of P1 to P20.
def sc (a : Nat) (i : Int) (l : Option Nat) (n : Nat) : StartCell :=
  { addr := a, item := i, link := l, count := n }
def V1 : Start := { cells := [sc 1 4 (some 2) 1, sc 2 9 none 1], inputs := [("xs", .list (some 1))], outside := [] }
def V2 : Start := { cells := [sc 1 4 (some 2) 2, sc 2 9 none 1], inputs := [("xs", .list (some 1))], outside := [some 1] }
def V9 : Start := { cells := [], inputs := [("xs", .list none)], outside := [] }
def VX2 : Start :=
  { cells := [sc 1 4 (some 2) 2, sc 2 9 none 1], inputs := [("xs", .list (some 1)), ("ys", .list (some 1))], outside := [] }
def VN : Start := { cells := [sc 1 3 (some 2) 1, sc 2 4 none 1], inputs := [("xs", .list (some 1))], outside := [] }
def VI0 : Start := { cells := [sc 1 4 (some 2) 1, sc 2 9 none 1], inputs := [("n", .num 0), ("xs", .list (some 1))], outside := [] }
def VI5 : Start := { cells := [sc 1 4 (some 2) 1, sc 2 9 none 1], inputs := [("n", .num 5), ("xs", .list (some 1))], outside := [] }

def w1 := matchE (var "xs") (num 0) "h" "t" (add (var "h") (var "h"))
def s1p := matchE (var "xs") nil "h" "t" (cons (add (var "h") (var "h")) (var "t"))
def s3p := letE "y" (var "xs")
  (matchE (var "xs") (num 0) "h" "t" (matchE (var "y") (var "h") "g" "u" (add (var "g") (var "h"))))
def s5p := letE "n"
  (matchE (var "xs") (num 0) "h" "t" (matchE (var "t") (var "h") "g" "u" (var "g")))
  (matchE (var "xs") (var "n") "a" "b" (add (var "n") (var "a")))
def x2p := matchE (var "xs") (var "ys") "h" "t" (cons (var "h") nil)
-- nested: the enclosing branch transforms the inner branch's number
def nestp := matchE (var "xs") (num 0) "a" "r" (add (matchE (var "r") (var "a") "b" "s" (var "b")) (num 100))
-- if, both branches; xs used only in the true branch (D86: given up when the false branch is chosen)
def ifp := ifE (lt (var "n") (num 1)) (var "xs") nil

def cases : List (String × Expr × Start) :=
  [("s1p V1", s1p, V1), ("s1p V2", s1p, V2), ("w1 V1", w1, V1), ("w1 V9", w1, V9),
   ("s3p V1", s3p, V1), ("s5p V1", s5p, V1), ("x2p VX2", x2p, VX2), ("12345 V1", num 12345, V1),
   ("nest VN", nestp, VN), ("if VI0", ifp, VI0), ("if VI5", ifp, VI5)]
def keep (_ : Snapshot) : Bool := true

def showSnap (sn : Snapshot) : String :=
  s!"{repr sn.kind} | {repr sn.memory} | {repr sn.bindings} | {repr sn.pending} | {repr sn.outside} | {repr sn.setAside}"
def showOutcome (o : Outcome) : String :=
  s!"{repr o.result}\n{repr o.memory}\n{repr o.log}\n{repr o.record}\n" ++
  String.intercalate "\n" ((o.states.filter keep).map showSnap)

def main : IO Unit := do
  for (name, e, s) in cases do
    for (rn, r) in [("approved", Rule.approved), ("misreportsReuse", Rule.misreportsReuse)] do
      IO.println s!"=== {name} / {rn}"
      IO.println (showOutcome (runCounted r e s))
