import Full.Language

/-! Independent immutable-value CEK machine. One step dispatches an expression
or consumes one saved continuation; calls never recursively evaluate a body.
No heap, reference count, reservation or counted evaluator is used here. -/
namespace Full.Plain

abbrev Env := List (String × Value)

inductive Kont where
  | left (op : Op) (right : Expr) (env : Env)
  | right (op : Op) (left : Value)
  | bind (name : String) (body : Expr) (env : Env)
  | choose (yes no : Expr) (env : Env)
  | split (empty : Expr) (head tail : String) (cell : Expr) (env : Env)
  | arguments (name : String) (done : List Value) (rest : List Expr) (env : Env)
  | returning (name : String)
  deriving Repr

inductive Focus where
  | eval (expr : Expr) (env : Env)
  | value (v : Value)
  | finished (v : Value)
  | stuck (why : String)
  deriving Repr

structure State where
  focus : Focus
  kont : List Kont := []
  deriving Repr

def primitive (op : Op) (a b : Value) : Except String Value :=
  match op, a, b with
  | .cons, .num h, .list t => pure (.list (h::t))
  | .add, .num a, .num b => pure (.num (a+b))
  | .sub, .num a, .num b => pure (.num (a-b))
  | .eq, .num a, .num b => pure (.bool (a == b))
  | .lt, .num a, .num b => pure (.bool (a < b))
  | .le, .num a, .num b => pure (.bool (a ≤ b))
  | _, _, _ => throw "ill-kinded primitive"

def enter (p : Program) (name : String) (args : List Value) (ks : List Kont) : State :=
  match signature p.functions name with
  | none => ⟨.stuck "unknown function", ks⟩
  | some f =>
    if args.map Trial.PlainValue.kind == f.params.map Prod.snd then
      ⟨.eval f.body (((f.params.map Prod.fst).zip args).reverse), .returning name :: ks⟩
    else ⟨.stuck "ill-kinded call", ks⟩

def step (p : Program) (s : State) : State :=
  match s.focus with
  | .finished _ | .stuck _ => s
  | .eval e env =>
    match e with
    | .num n => { s with focus := .value (.num n) }
    | .bool b => { s with focus := .value (.bool b) }
    | .nil => { s with focus := .value (.list []) }
    | .var x => { s with focus := match Trial.lookupVal env x with
        | some v => .value v | none => .stuck "unbound variable" }
    | .bin op a b => ⟨.eval a env, .left op b env :: s.kont⟩
    | .letE x a b => ⟨.eval a env, .bind x b env :: s.kont⟩
    | .ifE c t e => ⟨.eval c env, .choose t e env :: s.kont⟩
    | .matchE v n h t c => ⟨.eval v env, .split n h t c env :: s.kont⟩
    | .call name [] => enter p name [] s.kont
    | .call name (a::as) => ⟨.eval a env, .arguments name [] as env :: s.kont⟩
  | .value v =>
    match s.kont with
    | [] => ⟨.finished v, []⟩
    | .left op b env :: ks => ⟨.eval b env, .right op v :: ks⟩
    | .right op a :: ks => ⟨match primitive op a v with
        | .ok w => .value w | .error why => .stuck why, ks⟩
    | .bind x b env :: ks => ⟨.eval b ((x,v)::env), ks⟩
    | .choose t e env :: ks => ⟨match v with
        | .bool b => .eval (if b then t else e) env
        | _ => .stuck "non-Boolean condition", ks⟩
    | .split n h t c env :: ks => ⟨match v with
        | .list [] => .eval n env
        | .list (x::xs) => .eval c ((t,.list xs)::(h,.num x)::env)
        | _ => .stuck "non-list scrutinee", ks⟩
    | .arguments name done [] _ :: ks => enter p name (done ++ [v]) ks
    | .arguments name done (a::as) env :: ks =>
      ⟨.eval a env, .arguments name (done ++ [v]) as env :: ks⟩
    | .returning _ :: ks => ⟨.value v, ks⟩

def advance (p : Program) : Nat → State → State
  | 0, s => s
  | n+1, s => advance p n (step p s)

def begin (p : Program) (inputs : Env) : Except String State := do
  let _ ← validate p (inputs.map (fun (name,v) => (name, v.kind)))
  pure ⟨.eval p.main inputs.reverse, []⟩

end Full.Plain
