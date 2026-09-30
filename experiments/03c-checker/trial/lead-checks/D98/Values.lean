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

def isBoundary (k : StepKind) : Bool := k == .branchValueWorkedOut || k == .branchValueHandedOn
def recorded (o : Outcome) : List RawValue := o.states.filterMap (·.branchValue)
-- some exactly on the two finishing kinds
def valuePlacement (o : Outcome) : Bool :=
  o.states.all (fun sn => (sn.branchValue.isSome) == isBoundary sn.kind)
-- branchChosen and branchStarts alternate strictly, chosen first, and pair up
def alternates (o : Outcome) : Bool :=
  let ks := (o.states.map (·.kind)).filter (fun k => k == .branchChosen || k == .branchStarts)
  let rec go : List StepKind → Bool
    | [] => true
    | .branchChosen :: .branchStarts :: rest => go rest
    | _ => false
  go ks
def starts (o : Outcome) : Nat := (o.states.filter (·.kind == .branchStarts)).length

def expected : List (String × List RawValue × Nat) :=
  [("s1p V1", [.list (some 1), .list (some 1)], 1),
   ("s1p V2", [.list (some 3), .list (some 3)], 1),
   ("w1 V1", [.num 8, .num 8], 1),
   ("w1 V9", [.num 0, .num 0], 1),
   ("s3p V1", [.num 8, .num 8, .num 8, .num 8], 2),
   ("s5p V1", [.num 9, .num 9, .num 9, .num 9, .num 13, .num 13], 3),
   ("x2p VX2", [.list (some 1), .list (some 1)], 1),
   ("12345 V1", [], 0),
   ("nest VN", [.num 4, .num 4, .num 104, .num 104], 2),
   ("if VI0", [], 1),
   ("if VI5", [], 1)]

def rawEq : RawValue → RawValue → Bool
  | .num a, .num b => a == b
  | .bool a, .bool b => a == b
  | .list a, .list b => a == b
  | _, _ => false

-- if VI5: at branchStarts, xs has been given up and both cells freed (D86, before the branch runs)
def ifGiveUpBeforeStart (o : Outcome) : Bool :=
  match o.states.find? (·.kind == .branchStarts) with
  | some sn => sn.memory == [] && sn.bindings.all (fun b => b.status != .holding)
  | none => false

def main : IO Unit := do
  let mut fails := 0
  for (name, e, s) in cases do
    for r in [Rule.approved, Rule.misreportsReuse] do
      let o := runCounted r e s
      -- the misreport copy frees and builds a replacement at the next address (3) where the approved rule reuses
      let exp := if r == Rule.misreportsReuse && (name == "s1p V1" || name == "x2p VX2")
        then some (name, [RawValue.list (some 3), RawValue.list (some 3)], 1) else expected.find? (·.1 == name)
      match exp with
      | none => IO.println s!"FAIL {name}: no expectation"; fails := fails + 1
      | some (_, vs, n) =>
        let rv := recorded o
        let ok := rv.length == vs.length && (rv.zip vs).all (fun (a, b) => rawEq a b)
        let line := s!"{name}: values {if ok then "ok" else "WRONG " ++ reprStr rv}, placement {valuePlacement o}, alternates {alternates o}, starts {starts o}/{n}"
        let good := ok && valuePlacement o && alternates o && starts o == n
        IO.println ((if good then "PASS " else "FAIL ") ++ line)
        if !good then fails := fails + 1
  let g := ifGiveUpBeforeStart (runCounted .approved ifp VI5)
  IO.println s!"{if g then "PASS" else "FAIL"} if VI5: xs given up and cells freed before branchStarts"
  if !g then fails := fails + 1
  IO.println s!"failures: {fails}"
