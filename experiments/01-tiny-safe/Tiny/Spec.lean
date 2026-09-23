/-!
# Experiment 1: the spec

This file is the part Robert approves. It is locked: the builder may not change
it. It says what the tiny language is, what each program means, and what a
type checker must promise. The builder writes the checker and the proofs in
`Tiny/Checker.lean`; `Tiny/Accept.lean` then checks them against this file.
-/

namespace Tiny

/-- The two types in the language. -/
inductive Ty where
  | num
  | bool
  deriving DecidableEq, Repr

/-- A program. `ite c t e` is `if c then t else e`. -/
inductive Term where
  | num (n : Nat)
  | bool (b : Bool)
  | add (a b : Term)
  | eq (a b : Term)
  | ite (c t e : Term)
  deriving DecidableEq, Repr

/-- What a finished program produces. -/
inductive Value where
  | num (n : Nat)
  | bool (b : Bool)
  deriving DecidableEq, Repr

/-- The type of a value. -/
def Value.ty : Value → Ty
  | .num _ => .num
  | .bool _ => .bool

/-- What each program means. `none` means the program gets stuck: a runtime
type error such as `1 + true`, or `if 5 then ...`. -/
def eval : Term → Option Value
  | .num n => some (.num n)
  | .bool b => some (.bool b)
  | .add a b =>
    match eval a, eval b with
    | some (.num x), some (.num y) => some (.num (x + y))
    | _, _ => none
  | .eq a b =>
    match eval a, eval b with
    | some (.num x), some (.num y) => some (.bool (x == y))
    | some (.bool x), some (.bool y) => some (.bool (x == y))
    | _, _ => none
  | .ite c t e =>
    match eval c with
    | some (.bool true) => eval t
    | some (.bool false) => eval e
    | _ => none

/-- **The promise.** If the checker approves a program and says it has type
`t`, then running it never gets stuck: it produces a value, and that value has
type `t`. -/
def Safe (check : Term → Option Ty) : Prop :=
  ∀ e t, check e = some t → ∃ v, eval e = some v ∧ v.ty = t

/-- Programs the checker must approve, with the type it must give them. -/
def mustAccept : List (Term × Ty) :=
  [ (.num 2, .num),
    (.add (.num 1) (.num 2), .num),
    (.eq (.num 1) (.num 1), .bool),
    (.eq (.bool true) (.bool false), .bool),
    (.ite (.eq (.num 1) (.num 2)) (.num 3) (.num 4), .num) ]

/-- Programs the checker must reject. -/
def mustReject : List Term :=
  [ .add (.num 1) (.bool true),
    .eq (.num 1) (.bool true),
    .ite (.num 1) (.num 2) (.num 3),
    .ite (.bool true) (.num 1) (.bool false) ]

/-- The checker gives the right answer on every example above. -/
def Useful (check : Term → Option Ty) : Prop :=
  (∀ p ∈ mustAccept, check p.1 = some p.2) ∧ (∀ e ∈ mustReject, check e = none)

end Tiny
