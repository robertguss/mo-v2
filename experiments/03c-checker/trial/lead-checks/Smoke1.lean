import Trial
open Trial

-- Lead's smoke rows for part 1 (WORKER-BRIEF.md). Not acceptance criteria.

def wfIs (ins : List (String × Kind)) (e : Expr) (k : Kind) : Bool :=
  match wellFormed ins e with
  | .ok k' => k' == k
  | .error _ => false
def wfRefused (ins : List (String × Kind)) (e : Expr) : Bool :=
  match wellFormed ins e with
  | .ok _ => false
  | .error _ => true
def plainIs (e : Expr) (ins : List (String × PlainValue)) (v : PlainValue) : Bool :=
  match runPlain e ins with
  | .ok v' => v' == v
  | .error _ => false
def plainRefused (e : Expr) (ins : List (String × PlainValue)) : Bool :=
  match runPlain e ins with
  | .ok _ => false
  | .error _ => true

open Expr
def L := Kind.list
def N := Kind.number
-- W1 match xs do [] -> 0; [h | t] -> h + h end
def w1 := matchE (var "xs") (num 0) "h" "t" (add (var "h") (var "h"))
def w2 := eq (var "n") (var "m")
def w3 := letE "x" (var "xs") (letE "x" (num 1) (add (var "x") (num 1)))
def w4 := letE "x" (add (var "x") (num 1)) (var "x")
def w5 := matchE (var "xs") nil "x" "x" nil
def w6 := ifE (lt (var "n") (num 1)) nil (num 0)
def w7 := matchE (var "xs") (num 0) "h" "t" (var "t")
def w8 := add (var "y") (num 1)
def w9 := eq (var "xs") (var "xs")
def w10 := cons (var "xs") (var "xs")
def w11 := cons (num 1) (num 2)
def w12 := ifE (var "n") (num 1) (num 2)
def w13 := matchE (var "n") (num 0) "h" "t" (var "h")
def w14 := add (var "x") (num 1)
def w15 := letE "b" (lt (num 1) (num 2)) (ifE (var "b") (num 7) (num 8))
def w16 := num 1

#guard wfIs [("xs", L)] w1 N
#guard wfIs [("n", N), ("m", N)] w2 Kind.bool
#guard wfIs [("xs", L)] w3 N
#guard wfIs [("x", N)] w4 N
#guard wfRefused [("xs", L)] w5
#guard wfRefused [("n", N)] w6
#guard wfRefused [("xs", L)] w7
#guard wfRefused [] w8
#guard wfRefused [("xs", L)] w9
#guard wfRefused [("xs", L)] w10
#guard wfRefused [] w11
#guard wfRefused [("n", N)] w12
#guard wfRefused [("n", N)] w13
#guard wfRefused [("x", N), ("x", L)] w14
#guard wfIs [] w15 N
#guard wfRefused [("b", Kind.bool)] w16

-- B1..B8
#guard plainIs (sub (num 2) (num 5)) [] (.num (-3))
#guard plainIs w4 [("x", .num 4)] (.num 5)
def b3 := ifE (lt (var "n") (num 1)) (add (var "n") (num 10)) (sub (var "n") (num 10))
#guard plainIs b3 [("n", .num 0)] (.num 10)
#guard plainIs b3 [("n", .num 1)] (.num (-9))
#guard plainIs (le (var "n") (var "m")) [("n", .num 3), ("m", .num 3)] (.bool true)
#guard plainIs (lt (var "n") (var "m")) [("n", .num 3), ("m", .num 3)] (.bool false)
#guard plainIs (eq (var "n") (var "m")) [("n", .num 3), ("m", .num 3)] (.bool true)
#guard plainIs w1 [("xs", .list [])] (.num 0)
#guard plainIs w1 [("xs", .list [7, 8])] (.num 14)
#guard plainIs (cons (add (var "n") (var "n")) (cons (var "n") (var "xs")))
  [("n", .num 2), ("xs", .list [5])] (.list [4, 2, 5])
-- B7: no answer for W5..W14, W16 (with inputs of the right shape)
#guard plainRefused w5 [("xs", .list [1])]
#guard plainRefused w6 [("n", .num 0)]
#guard plainRefused w7 [("xs", .list [1])]
#guard plainRefused w8 []
#guard plainRefused w9 [("xs", .list [1])]
#guard plainRefused w10 [("xs", .list [1])]
#guard plainRefused w11 []
#guard plainRefused w12 [("n", .num 0)]
#guard plainRefused w13 [("n", .num 0)]
#guard plainRefused w14 [("x", .num 0), ("x", .list [])]
#guard plainRefused w16 [("b", .bool true)]
#guard plainIs w15 [] (.num 7)

#print axioms Trial.wellFormed
#print axioms Trial.runPlain
