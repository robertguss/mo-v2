import Trial.Language

/-!
# The plain meaning

`INTERFACE.md` section 4 (the plain half): run a program with lists as plain
values. Well-formedness is checked first, from the text; only then does
evaluation start.
-/

namespace Trial

/-- Plain values (`INTERFACE.md` 4): a number, true or false, or a list of numbers. -/
inductive PlainValue where
  | num (n : Int)
  | bool (b : Bool)
  | list (xs : List Int)
  deriving DecidableEq, Repr

/-- The kind a plain value has. -/
def PlainValue.kind : PlainValue → Kind
  | .num _ => .number
  | .bool _ => .bool
  | .list _ => .list

/-- The nearest binding of a spelling (2e, D83): inner bindings are in front. -/
def lookupVal : List (String × PlainValue) → String → Option PlainValue
  | [], _ => none
  | (y, v) :: rest, x => if y = x then some v else lookupVal rest x

/-- Evaluate left to right by structural recursion (`RULE.md` 2). Every case that
cannot happen on a well-formed program is an error with a reason, never a default. -/
def eval (env : List (String × PlainValue)) : Expr → Except String PlainValue
  | .num n => pure (.num n)
  | .add a b => do
    match (← eval env a), (← eval env b) with
    | .num x, .num y => pure (.num (x + y))
    | _, _ => throw "stuck: + on non-numbers"
  | .sub a b => do
    match (← eval env a), (← eval env b) with
    | .num x, .num y => pure (.num (x - y))
    | _, _ => throw "stuck: - on non-numbers"
  | .eq a b => do
    match (← eval env a), (← eval env b) with
    | .num x, .num y => pure (.bool (decide (x = y)))
    | _, _ => throw "stuck: == on non-numbers"
  | .lt a b => do
    match (← eval env a), (← eval env b) with
    | .num x, .num y => pure (.bool (decide (x < y)))
    | _, _ => throw "stuck: < on non-numbers"
  | .le a b => do
    match (← eval env a), (← eval env b) with
    | .num x, .num y => pure (.bool (decide (x ≤ y)))
    | _, _ => throw "stuck: <= on non-numbers"
  | .nil => pure (.list [])
  | .cons h t => do
    match (← eval env h), (← eval env t) with
    | .num x, .list xs => pure (.list (x :: xs))
    | _, _ => throw "stuck: a cell needs a number and a list"
  | .letE x bound body => do
    let v ← eval env bound
    eval ((x, v) :: env) body
  | .ifE c t e => do
    match (← eval env c) with
    | .bool true => eval env t
    | .bool false => eval env e
    | _ => throw "stuck: an if condition is not true or false"
  | .matchE scrut onNil h t onCell => do
    match (← eval env scrut) with
    | .list [] => eval env onNil
    | .list (x :: xs) => eval ((t, .list xs) :: (h, .num x) :: env) onCell
    | _ => throw "stuck: match on a non-list"
  | .var x =>
    match lookupVal env x with
    | some v => pure v
    | none => throw s!"stuck: unbound name {x}"

/-- Run a program under the plain meaning. First works out each input's kind from
its value and checks `wellFormed`; if that refuses, refuses with its reason and
gives no answer. Only then evaluates. -/
def runPlain (e : Expr) (inputs : List (String × PlainValue)) :
    Except String PlainValue := do
  let _ ← wellFormed (inputs.map (fun p => (p.1, p.2.kind))) e
  eval inputs e

end Trial
