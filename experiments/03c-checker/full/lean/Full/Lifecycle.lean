import Full.Counted

namespace Full.Lifecycle

inductive Domain where
  | number | frame | cell
  deriving DecidableEq, Repr

structure Request where
  domain : Domain
  site : String
  deriving DecidableEq, Repr

/-- Explicit mathematical gates, not a model of every native allocation.
Number gates occur before arithmetic results; frame gates before Enter;
cell gates only when Cons has no eligible reservation. -/
def request (s : Counted.State) : Option Request :=
  match s.tasks with
  | .primitive .cons ctx :: _ =>
    if s.reservations.any (fun r => r.invocation == ctx.invocation && ctx.branches.contains r.branch)
    then none else some ⟨.cell,ctx.site⟩
  | .primitive .add ctx :: _ | .primitive .sub ctx :: _ => some ⟨.number,ctx.site⟩
  | .enter name _ _ :: _ => some ⟨.frame,name⟩
  | _ => none

structure Failure where
  request : Request
  ordinal : Nat
  abort : List (Nat × String)
  deriving Repr

structure State where
  execution : Counted.State
  requests : List Request := []
  failure : Option Failure := none
  destroyed : Bool := false
  cleanup : List Nat := []
  deriving Repr

abbrev Policy := Request → Nat → Bool

def step (p : Program) (allow : Policy) (s : State) : Except String State := do
  if s.failure.isSome || s.destroyed || s.execution.answer.isSome then pure s else
    match request s.execution with
    | none => pure { s with execution := ← Counted.step p s.execution }
    | some r =>
      let ordinal := (s.requests.filter (fun q => q.domain == r.domain && q.site == r.site)).length+1
      if allow r ordinal then
        pure { s with execution := ← Counted.step p s.execution, requests := s.requests ++ [r] }
      else
        pure { s with failure := some ⟨r,ordinal,s.execution.frames.map (fun f => (f.id,f.name))⟩ }

def advance (p : Program) (allow : Policy) : Nat → State → Except String State
  | 0, s => pure s
  | n+1, s => do
    if s.failure.isSome || s.destroyed || s.execution.answer.isSome then pure s
    else advance p allow n (← step p allow s)

/-- Finite graph destruction, not execution of source continuations. It removes
run-only storage and its incoming ownership, preserving the outside graph. The
ordered cell removals follow allocation-table order. This pure definition makes
no claim about a native allocator or host stack. Evaluation events are unchanged. -/
def destroy (s : State) : State :=
  if s.destroyed then s else
    let e := s.execution
    let cells := e.mem.cells.map fun c => (⟨c.addr,c.item,c.link,c.count⟩ : Trial.StartCell)
    let reached := e.outside.flatMap (Trial.chainAddrs cells cells.length)
    let retained := e.mem.cells.filter (fun c => reached.contains c.addr)
    let freed := e.mem.cells.filter (fun c => !reached.contains c.addr)
    let kept := retained.map fun c => { c with count :=
      (e.outside.filter (fun r => r == some c.addr)).length +
      (retained.filter (fun d => d.link == some c.addr)).length }
    { s with
      execution := { e with
        mem := { e.mem with cells := kept }
        edges := e.edges.filter (fun v => reached.contains v.1)
        releaseChain := []
        bindings := []
        entered := []
        slots := []
        reservations := []
        frames := []
        tasks := []
        answer := none }
      destroyed := true
      cleanup := s.cleanup ++ freed.map (fun c => c.addr) }

end Full.Lifecycle
