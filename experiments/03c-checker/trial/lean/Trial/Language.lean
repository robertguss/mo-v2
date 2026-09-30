/-!
# The trial language and its well-formedness check

Encodes `RULE.md` section 2 (the trial language, exactly) and the first promise
of `INTERFACE.md` section 2. Nothing here runs a program: `wellFormed` reads only
the program text.
-/

namespace Trial

/-- The three kinds of value a program can work out (`RULE.md` 2, 2c):
a whole number, a list of numbers, or true or false. -/
inductive Kind where
  | number
  | list
  | bool
  deriving DecidableEq, Repr

/-- Programs: exactly one constructor per row of the table in `RULE.md` section 2.
Names are written as their spelling (`String`, 2e). `match` carries both its
branches, so `RULE.md` 2d (both branches always present) holds by construction. -/
inductive Expr where
  /-- `7`, `-3`: a whole number (2a, D79: unlimited, may be negative). -/
  | num (n : Int)
  /-- `a + b`. -/
  | add (a b : Expr)
  /-- `a - b`: ordinary subtraction, so `2 - 5` is `-3` (2a). -/
  | sub (a b : Expr)
  /-- `a == b`: on numbers only (2b, D80). -/
  | eq (a b : Expr)
  /-- `a < b`. -/
  | lt (a b : Expr)
  /-- `a <= b`. -/
  | le (a b : Expr)
  /-- `[]`: the empty list. -/
  | nil
  /-- `[h | t]`: build one cell, item `h` (a number) in front of the list `t`. -/
  | cons (h t : Expr)
  /-- `let x = e1 in e2`: the new `x` exists only in `e2` (2e). -/
  | letE (x : String) (bound body : Expr)
  /-- `if c then e1 else e2 end`: `c` must be true or false. -/
  | ifE (c t e : Expr)
  /-- `match e do [] -> e1; [h | t] -> e2 end`: the matched expression, the
  empty-list branch, the item name, the rest name, the cell branch. -/
  | matchE (scrut : Expr) (onNil : Expr) (h t : String) (onCell : Expr)
  /-- An input name, or a name bound by `let` or `match`. -/
  | var (x : String)

/-- The nearest binding of a spelling: the first entry, since inner bindings are
put in front (2e, D83: a use refers to its nearest enclosing binding). -/
def lookupKind : List (String × Kind) → String → Option Kind
  | [], _ => none
  | (y, k) :: rest, x => if y = x then some k else lookupKind rest x

/-- Two inputs with one spelling (2e, D97): the repeated spelling, if any. -/
def dupInput : List (String × Kind) → Option String
  | [] => none
  | (x, _) :: rest =>
    if rest.any (fun p => p.1 = x) then some x else dupInput rest

/-- Reject an expression whose kind is not the expected one. -/
def expectKind (what : String) (want got : Kind) : Except String Unit :=
  if got = want then pure () else throw s!"{what}: wrong kind of value"

/-- The kind of a program in a given environment, or a reason it is not
well-formed. The environment allows true-or-false locals (from `let`) and
shadowing: new bindings go in front, so the nearest wins (2e, D83). In
`let x = e1 in e2`, `e1` is checked without the new `x` (2e). Structural
recursion on the expression. -/
def check (env : List (String × Kind)) : Expr → Except String Kind
  | .num _ => pure .number
  | .add a b => do
    expectKind "the left side of +" .number (← check env a)
    expectKind "the right side of +" .number (← check env b)
    pure .number
  | .sub a b => do
    expectKind "the left side of -" .number (← check env a)
    expectKind "the right side of -" .number (← check env b)
    pure .number
  | .eq a b => do
    expectKind "the left side of ==" .number (← check env a)
    expectKind "the right side of ==" .number (← check env b)
    pure .bool
  | .lt a b => do
    expectKind "the left side of <" .number (← check env a)
    expectKind "the right side of <" .number (← check env b)
    pure .bool
  | .le a b => do
    expectKind "the left side of <=" .number (← check env a)
    expectKind "the right side of <=" .number (← check env b)
    pure .bool
  | .nil => pure .list
  | .cons h t => do
    expectKind "a cell's item" .number (← check env h)
    expectKind "a cell's rest" .list (← check env t)
    pure .list
  | .letE x bound body => do
    let k ← check env bound
    check ((x, k) :: env) body
  | .ifE c t e => do
    expectKind "an if condition" .bool (← check env c)
    let kt ← check env t
    let ke ← check env e
    if kt = ke then pure kt
    else throw "the two branches of an if give different kinds of value (2f)"
  | .matchE scrut onNil h t onCell => do
    expectKind "the matched expression" .list (← check env scrut)
    if h = t then
      throw s!"a match introduces two names with one spelling, {h} (2e, D89)"
    else
      let kn ← check env onNil
      let kc ← check ((t, .list) :: (h, .number) :: env) onCell
      if kn = kc then pure kn
      else throw "the two branches of a match give different kinds of value (2f)"
  | .var x =>
    match lookupKind env x with
    | some k => pure k
    | none => throw s!"unbound name {x}"

/-- Is a program well-formed, given the names and kinds of its inputs, and of
what kind is its answer? At the public boundary it refuses two inputs with one
spelling (2e, D97) and any input of kind true-or-false (2c, D82). Reads only the
text; never runs the program. -/
def wellFormed (inputs : List (String × Kind)) (e : Expr) : Except String Kind :=
  match dupInput inputs with
  | some x => throw s!"two inputs are spelled {x} (2e, D97)"
  | none =>
    if inputs.any (fun p => p.2 = .bool) then
      throw "an input is of kind true-or-false (2c, D82)"
    else
      check inputs e

end Trial
