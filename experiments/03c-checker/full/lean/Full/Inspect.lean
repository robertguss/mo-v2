import Full.Control

namespace Full.Inspect
open Counted

def link : Raw → Option Nat
  | .list a => a | _ => none

def owners (s : State) : List (Option Nat) :=
  s.outside ++ (s.bindings.filter (fun b => b.record.status == .holding)).map (fun b => link b.record.value) ++
  s.slots.map (fun v => link v.raw) ++
  (s.mem.cells.filter (fun c => c.status == .live)).map (fun c => c.link)

def readable (s : State) (v : Slot) : Bool :=
  match Trial.readBack s.mem v.raw with | .ok w => w == v.value | .error _ => false

/-- Input identities are acquired in declaration order; lexical lookup reverses it. -/
def initialScope (initial : Trial.Start) : Env :=
  (initial.inputs.zipIdx.map fun ((name,_),id) => (name,id)).reverse

/-- Source-prescribed observer scope, without executing the transfer or reading
its output. Administrative actions retain the last entered scope. In particular,
shared decomposition without a tail acquisition delays entry until MatchComplete,
as in the historical trial; this is not simply the next task's lexical context. -/
def nextScope (p : Program) (s : State) : Except String Env := do
  match s.tasks with
  | .enter name _ _ :: _ =>
    let some f := signature p.functions name | throw "scope: unknown callee"
    pure ((f.params.zipIdx.map fun ((name,_),i) => (name,s.nextBinding+i)).reverse)
  | .bind name _ ctx :: _ => pure ((name,s.nextBinding)::ctx.env)
  | .decompose h t body _ ctx :: _ =>
    let v::_ := s.slots | throw "scope: missing scrutinee"
    let .list (some addr) := v.raw | throw "scope: empty scrutinee"
    let some c := s.mem.find? addr | throw "scope: missing cell"
    let inner := (t,s.nextBinding+1)::(h,s.nextBinding)::ctx.env
    let acquired := uses body (Trial.toFEnv inner) (s.nextBinding+1) && c.link.isSome
    pure (if c.count == 1 || acquired then inner else s.entered)
  | .eval (.var name) ctx :: _ =>
    let some (_,id) := ctx.env.find? (fun q => q.1 == name) | throw "scope: unbound variable"
    let some b := s.bindings.find? (fun b => b.record.id == id) | throw "scope: missing binding"
    pure (if (link b.record.value).isSome then ctx.env else s.entered)
  | .primitive .cons ctx :: _ | .chooseIf _ _ ctx :: _ | .chooseMatch _ _ _ _ ctx :: _
  | .matchComplete ctx :: _ | .branchStart ctx :: _ | .branchResult _ ctx _ :: _
  | .handoffMatch ctx :: _ | .returning _ ctx :: _ => pure ctx.env
  | _ => pure s.entered

/-- Exact full records, including scalar/noHolder entries, in acquisition-ID
order. Suspended holding bindings remain visible even outside entered scope. -/
def observer (s : State) : Bool :=
  let required := s.bindings.filterMap fun b =>
    if s.entered.any (fun pair => pair.2 == b.record.id) || b.record.status == .holding
    then some b.record else none
  s.entered.all (fun (name,id) => s.bindings.any (fun b =>
    b.record.id == id && b.record.name == name)) &&
  decide (Counted.visible s = required.mergeSort (fun a b => a.id ≤ b.id))

/-- Effects prescribed by the next action and its source operands, without
running the transfer or reading its resulting event list. -/
def effects (s : State) : Except String (List Event) := do
  if s.answer.isSome then pure [] else
    match s.tasks with
    | .primitive .cons ctx :: _ =>
      let b::a::_ := s.slots | throw "effect operands missing"
      let .num h := a.raw | throw "effect head kind"
      let .list t := b.raw | throw "effect tail kind"
      match s.reservations.find? (fun r => r.invocation == ctx.invocation && ctx.branches.contains r.branch) with
      | some r => pure [.write r.addr h t]
      | none => pure [.create s.mem.next h t]
    | .free addr :: _ | .freeReserved addr :: _ => pure [.free addr]
    | .enter name arity ctx :: _ =>
      pure [.enter ⟨s.nextInvocation,name,ctx.invocation,(s.slots.take arity).reverse,ctx.site⟩]
    | .returning f _ :: _ =>
      let v::_ := s.slots | throw "effect return result missing"
      pure [.returning f.id v]
    | _ => pure []

def cellEffects (events : List Event) : List Trial.MemEvent :=
  events.filterMap fun e => match e with
    | .create a _ _ => some (.created a)
    | .write a _ _ => some (.written a)
    | .free a => some (.released a)
    | _ => none

/-- Independent data obligations include all still-required binding identities,
not only the machine's holding flags. The decode/step check separately prevents
deleting the continuation that made an identity required. -/
def protection (initial : Trial.Start) (s : State) : Bool :=
  s.outside == initial.outside &&
  initial.outside.all (fun a => match Trial.readBack initial.toMemory (.list a), Trial.readBack s.mem (.list a) with
    | .ok x,.ok y => x == y | _,_ => false) &&
  s.bindings.all (fun b =>
    b.record.value.kind == b.value.kind &&
    (!(s.tasks.any (taskUses b.record.id)) || (link b.record.value).isNone || b.record.status == .holding) &&
    ((b.record.status != .holding && (link b.record.value).isSome) || readable s ⟨b.record.value,b.value⟩)) &&
  s.slots.all (readable s) &&
  s.mem.cells.all (fun c => c.status != .live ||
    match s.edges.find? (fun e => e.1 == c.addr) with
    | some (_,v) => readable s ⟨.list c.link,v⟩ | none => false)

def invariant (initial : Trial.Start) (s : State) : Bool :=
  protection initial s && observer s &&
  (s.mem.cells.map (fun c => c.addr)).eraseDups.length == s.mem.cells.length &&
  (s.bindings.map (fun b => b.record.id)).eraseDups.length == s.bindings.length &&
  s.bindings.all (fun b => b.record.id < s.nextBinding) &&
  s.mem.cells.all (fun c => c.addr < s.mem.next &&
    c.count == ((owners s).filter (fun a => a == some c.addr)).length &&
    (if c.status == .setAside then
      c.count == 0 && c.link.isNone && (s.reservations.filter (fun r => r.addr == c.addr)).length == 1
    else
      (Trial.readList s.mem s.mem.cells.length (some c.addr)).isOk &&
      (c.count != 0 || s.tasks.any (fun t => match t with | .free a => a == c.addr | _ => false)))) &&
  s.reservations.all (fun r => s.mem.cells.any (fun c => c.addr == r.addr && c.status == .setAside)) &&
  cellEffects s.events == s.mem.record

def finalGraph (s : State) : Bool :=
  match s.answer with
  | none => false
  | some v =>
    s.frames.isEmpty && s.reservations.isEmpty && s.tasks.isEmpty && s.releaseChain.isEmpty &&
    !s.bindings.any (fun b => b.record.status == .holding) &&
    (match s.slots with | [w] => w.raw == v.raw && w.value == v.value | _ => false) &&
    (Trial.validStart (.num 0)
      ⟨s.mem.cells.map (fun c => ⟨c.addr,c.item,c.link,c.count⟩),[],link v.raw :: s.outside⟩).isOk &&
    s.mem.cells.all (fun c => c.status == .live)

/-- Finite validation of the proposed simulation and natural ranking. Neither
this function nor the examples establish the universally quantified theorem. -/
def trace (p : Program) (initial : Trial.Start) : Nat → State → Except String Unit
  | 0, s => if invariant initial s then pure () else throw s!"invariant at {s.steps}"
  | n+1, s => do
    if !invariant initial s then throw s!"invariant at {s.steps}"
    let a ← Control.decode s
    if s.answer.isSome then
      if !finalGraph s then throw "final graph"
      pure ()
    else
      let change ← Counted.transition p s
      if !invariant initial change.state then throw s!"internal transfer boundary at {s.steps}"
      let t ← Counted.step p s
      let scope ← nextScope p s
      if change.state.entered != scope || t.entered != scope then
        throw s!"source-prescribed scope at {s.steps}"
      let expected ← effects s
      if reprStr t.events != reprStr (s.events ++ expected) ||
          t.mem.record != s.mem.record ++ cellEffects expected then
        throw s!"exact cell/call effects at {s.steps}"
      let b ← Control.decode t
      if reprStr (← Control.decode change.state) != reprStr b then
        throw s!"metadata commit changed control at {s.steps}"
      if reprStr b == reprStr a then
        if !(Control.rank t < Control.rank s) then throw s!"administrative rank at {s.steps}"
      else if reprStr b != reprStr (Plain.step p a) then
        throw s!"plain control simulation at {s.steps}\nbefore {reprStr a}\nafter {reprStr b}\nplain {reprStr (Plain.step p a)}"
      trace p initial n t

end Full.Inspect
