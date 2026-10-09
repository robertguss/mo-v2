import Trial.Counted

/-! Preparation definitions, not approved statements or proofs. The finite trial
is an immutable dependency. Function signatures are checked without unfolding
their bodies, so the validator permits forward and mutually recursive calls. -/
namespace Full

abbrev Kind := Trial.Kind
abbrev Value := Trial.PlainValue
abbrev Raw := Trial.RawValue

inductive Op where
  | add | sub | eq | lt | le | cons
  deriving DecidableEq, Repr

inductive Expr where
  | num (n : Int)
  | bool (b : Bool)
  | nil
  | var (name : String)
  | bin (op : Op) (left right : Expr)
  | letE (name : String) (bound body : Expr)
  | ifE (cond yes no : Expr)
  | matchE (scrut empty : Expr) (head tail : String) (cell : Expr)
  | call (name : String) (args : List Expr)
  deriving Repr, BEq

structure Function where
  name : String
  params : List (String × Kind)
  result : Kind
  body : Expr
  demanded : Bool := false
  deriving Repr, BEq

structure Program where
  functions : List Function
  main : Expr
  deriving Repr, BEq

def signature (fs : List Function) (name : String) : Option Function :=
  fs.find? (fun f => f.name == name)

def check (fs : List Function) (env : List (String × Kind)) : Expr → Except String Kind
  | .num _ => pure .number
  | .bool _ => pure .bool
  | .nil => pure .list
  | .var x => match Trial.lookupKind env x with
    | some k => pure k
    | none => throw s!"unbound variable {x}"
  | .bin op a b => do
    Trial.expectKind "left operand" .number (← check fs env a)
    Trial.expectKind "right operand" (if op == .cons then .list else .number) (← check fs env b)
    pure (match op with | .cons => .list | .add | .sub => .number | _ => .bool)
  | .letE x a b => do
    let k ← check fs env a
    check fs ((x,k) :: env) b
  | .ifE c t e => do
    Trial.expectKind "condition" .bool (← check fs env c)
    let k ← check fs env t
    Trial.expectKind "branches" k (← check fs env e)
    pure k
  | .matchE s n h t c => do
    Trial.expectKind "scrutinee" .list (← check fs env s)
    if h == t then throw "duplicate match binder"
    let k ← check fs env n
    Trial.expectKind "branches" k (← check fs ((t,.list)::(h,.number)::env) c)
    pure k
  | .call name args => do
    let some f := signature fs name | throw s!"unknown function {name}"
    let kinds ← args.mapM (check fs env)
    if kinds == f.params.map Prod.snd then pure f.result
    else throw s!"argument kinds or arity: {name}"
termination_by e => sizeOf e

def validate (p : Program) (inputs : List (String × Kind)) : Except String Kind := do
  if (p.functions.map (fun f => f.name)).eraseDups.length != p.functions.length then
    throw "duplicate function"
  if (Trial.dupInput inputs).isSome then throw "duplicate input"
  if inputs.any (fun i => i.2 == .bool) then throw "Boolean main input"
  for f in p.functions do
    if (Trial.dupInput f.params).isSome then throw s!"duplicate parameter: {f.name}"
    Trial.expectKind f.name f.result (← check p.functions f.params f.body)
  check p.functions inputs p.main

/-- Resolved uses: `none` hides an outer binder before a new binder exists.
Function bodies have their own environment; calls contribute only arguments. -/
def uses (e : Expr) (env : Trial.FEnv) (id : Nat) : Bool :=
  match e with
  | .num _ | .bool _ | .nil => false
  | .var x => Trial.lookupF env x == some (some id)
  | .bin _ a b => uses a env id || uses b env id
  | .letE x a b => uses a env id || uses b ((x,none)::env) id
  | .ifE c t e => uses c env id || uses t env id || uses e env id
  | .matchE s n h t c =>
    uses s env id || uses n env id || uses c ((t,none)::(h,none)::env) id
  | .call _ args => args.attach.any (fun a => uses a.val env id)
termination_by sizeOf e
decreasing_by
  all_goals simp_wf
  all_goals first | omega | (have h := List.sizeOf_lt_of_mem a.property; omega)

def embed : Trial.Expr → Expr
  | .num n => .num n
  | .nil => .nil
  | .var x => .var x
  | .add a b => .bin .add (embed a) (embed b)
  | .sub a b => .bin .sub (embed a) (embed b)
  | .eq a b => .bin .eq (embed a) (embed b)
  | .lt a b => .bin .lt (embed a) (embed b)
  | .le a b => .bin .le (embed a) (embed b)
  | .cons a b => .bin .cons (embed a) (embed b)
  | .letE x a b => .letE x (embed a) (embed b)
  | .ifE c t e => .ifE (embed c) (embed t) (embed e)
  | .matchE s n h t c => .matchE (embed s) (embed n) h t (embed c)

end Full
