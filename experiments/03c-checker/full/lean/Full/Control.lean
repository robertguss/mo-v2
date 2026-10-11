import Full.Counted

/-! Decode saved counted work into independent immutable-value CEK control.
Readability is deliberately NOT used here. A binding's original immutable value
remains available even if a faulty implementation marks its holder dead.
Failure to decode is a correspondence failure, never a vacuous safety success. -/
namespace Full.Control
open Counted

def env (s : State) (names : Env) : Except String Plain.Env :=
  names.mapM fun (name,id) => do
    let some b := s.bindings.find? (fun b => b.record.id == id) | throw "missing control binding"
    pure (name,b.value)

structure CallTail where
  name : String
  arity : Nat
  ctx : Context
  args : List Expr
  rest : List Task

def callTail : List Task → Option CallTail
  | .enter name arity ctx :: ts => some ⟨name,arity,ctx,[],ts⟩
  | .eval e _ :: .capture :: ts => do
    let c ← callTail ts
    pure { c with args := e::c.args }
  | _ => none

def continuations (s : State) : Nat → List Task → List Slot → Except String (List Plain.Kont)
  | 0, _, _ => throw "control traversal exhausted"
  | _+1, [], [] => pure []
  | _+1, [], _::_ => throw "unclaimed operand"
  | n+1, tasks, values => do
    match tasks with
    | .capture :: .eval b ctx :: .capture :: .primitive op _ :: ts =>
      pure (.left op b (← env s ctx.env) :: (← continuations s n ts values))
    | .capture :: .primitive op _ :: ts | .primitive op _ :: ts =>
      let a::vs := values | throw "missing left operand"
      pure (.right op a.value :: (← continuations s n ts vs))
    | .capture :: ts =>
      let some c := callTail ts | throw "capture without caller"
      let count := c.arity-c.args.length-1
      if values.length < count then throw "missing earlier argument"
      let done := (values.take count).reverse.map Slot.value
      pure (.arguments c.name done c.args (← env s c.ctx.env) ::
        (← continuations s n c.rest (values.drop count)))
    | .enter name arity ctx :: ts =>
      if arity == 0 then throw "zero argument call is a focus"
      let count := arity-1
      if values.length < count then throw "missing completed argument"
      pure (.arguments name ((values.take count).reverse.map Slot.value) [] (← env s ctx.env) ::
        (← continuations s n ts (values.drop count)))
    | .bind x b ctx :: ts => pure (.bind x b (← env s ctx.env) :: (← continuations s n ts values))
    | .chooseIf t e ctx :: ts => pure (.choose t e (← env s ctx.env) :: (← continuations s n ts values))
    | .chooseMatch empty h t cell ctx :: ts =>
      pure (.split empty h t cell (← env s ctx.env) :: (← continuations s n ts values))
    | .returning f _ :: ts => pure (.returning f.name :: (← continuations s n ts values))
    | .finish :: [] => if values.isEmpty then pure [] else throw "extra finish operand"
    | .handoff :: ts | .handoffMatch _ :: ts | .branchResult _ _ _ :: ts |
        .freeReserved _ :: ts => continuations s n ts values
    | _ => throw "not a source continuation"

def focus (s : State) : Nat → List Task → List Slot → Except String Plain.State
  | 0, _, _ => throw "control traversal exhausted"
  | n+1, tasks, values => do
    match tasks with
    | .start :: ts | .branchStart _ :: ts | .matchComplete _ :: ts |
        .giveBinding _ :: ts | .free _ :: ts | .freeReserved _ :: ts |
        .branchResult _ _ _ :: ts | .handoff :: ts | .handoffMatch _ :: ts => focus s n ts values
    | .givePending :: ts =>
      let _::vs := values | throw "missing cleanup operand"
      focus s n ts vs
    | .eval e ctx :: ts => pure ⟨.eval e (← env s ctx.env),← continuations s n ts values⟩
    | .decompose h t body _ ctx :: ts =>
      let v::vs := values | throw "missing match value"
      let .list (head::tail) := v.value | throw "invalid match value"
      pure ⟨.eval body ((t,.list tail)::(h,.num head)::(← env s ctx.env)),
        ← continuations s n ts vs⟩
    | .enter name 0 ctx :: ts =>
      pure ⟨.eval (.call name []) (← env s ctx.env),← continuations s n ts values⟩
    | _ =>
      let v::vs := values | throw "missing focused value"
      pure ⟨.value v.value,← continuations s (n+1) tasks vs⟩

def decode (s : State) : Except String Plain.State :=
  match s.answer with
  | some v => pure ⟨.finished v.value,[]⟩
  | none => focus s (s.tasks.length+2) s.tasks s.slots

/-- Administrative work cannot stutter forever if this concrete natural measure
strictly decreases on every step whose decoded plain state is unchanged. -/
def rank (s : State) : Nat :=
  4*s.mem.cells.length + (s.tasks.map fun t => match t with
    | .eval (.call _ []) _ => 2
    | .eval _ _ => 0
    | .decompose _ _ _ _ _ => 12
    | .branchResult _ _ _ => 4
    | .giveBinding _ | .givePending => 3
    | .free _ | .freeReserved _ => 2
    | _ => 1).foldl (·+·) 0

end Full.Control
