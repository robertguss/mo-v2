import Full.Inspect
import Full.Lifecycle

/-! Proposed statement interfaces only. These `Prop` definitions prove nothing.
No axiom, sorry, abstract evaluator, recursive-summary assumption or future
correctness condition is used to construct a valid starting state. -/
namespace Full.Statements

def Reachable (p : Program) (initial : Trial.Start) (s : Counted.State) : Prop :=
  ∃ first n, Counted.begin p initial = .ok first ∧ Counted.advance p n first = .ok s

def plainBegin (p : Program) (initial : Trial.Start) : Except String Plain.State := do
  let inputs ← initial.inputs.mapM fun (name,v) => do pure (name, ← Trial.readBack initial.toMemory v)
  Plain.begin p inputs

def Related (plain : Plain.State) (counted : Counted.State) : Prop :=
  Control.decode counted = .ok plain

def F1 : Prop :=
  (∀ p initial first, Counted.begin p initial = .ok first →
    first.entered = Inspect.initialScope initial) ∧
  ∀ p initial s, Reachable p initial s →
    Inspect.invariant initial s = true ∧
    (∀ internal, Counted.Boundary p s internal → Inspect.invariant initial internal = true) ∧
    (s.answer = none → ∃ t, Counted.step p s = .ok t ∧
      Inspect.invariant initial t = true ∧ t.steps = s.steps+1 ∧
      Inspect.nextScope p s = .ok t.entered ∧
      (∀ change, Counted.transition p s = .ok change → change.state.entered = t.entered) ∧
      (∃ effects, Inspect.effects s = .ok effects ∧
        t.events = s.events ++ effects ∧
        t.mem.record = s.mem.record ++ Inspect.cellEffects effects) ∧
      (∀ other, Counted.step p s = .ok other → other = t))

def countedAnswer (p : Program) (initial : Trial.Start) (v : Value) : Prop :=
  ∃ s a, Reachable p initial s ∧ s.answer = some a ∧ Trial.readBack s.mem a.raw = .ok v

def plainAnswer (p : Program) (initial : Trial.Start) (v : Value) : Prop :=
  ∃ first n, plainBegin p initial = .ok first ∧ (Plain.advance p n first).focus = .finished v

/-- Both directions are required. The natural ranking is fixed in Control, not
an assumed witness supplied by the implementation or checker. -/
def F2 : Prop :=
  (∀ p initial first, Counted.begin p initial = .ok first →
    ∃ plain, plainBegin p initial = .ok plain ∧ Related plain first) ∧
  (∀ p initial s, Reachable p initial s → ∃ a, Related a s ∧
    (∀ t, Counted.step p s = .ok t → s.answer = none →
      Related (Plain.step p a) t ∨ (Related a t ∧ Control.rank t < Control.rank s))) ∧
  (∀ p initial s a, Reachable p initial s → Related a s →
    ∃ n t, Counted.advance p n s = .ok t ∧ Related (Plain.step p a) t) ∧
  (∀ p initial first v, Counted.begin p initial = .ok first →
    (countedAnswer p initial v ↔ plainAnswer p initial v))

def F3 : Prop :=
  ∀ p initial s internal, Reachable p initial s → Counted.Boundary p s internal →
    Inspect.protection initial internal = true ∧
    ∃ first n, plainBegin p initial = .ok first ∧ Related (Plain.advance p n first) internal

def F4 : Prop :=
  ∀ p initial s, Reachable p initial s → s.answer.isSome = true → Inspect.finalGraph s = true

def F5 : Prop :=
  (∀ p s, Counted.advance p 0 s = .ok s) ∧
  (∀ p s m n, Counted.advance p (m+n) s =
    (Counted.advance p m s).bind (Counted.advance p n)) ∧
  (∀ p s n, s.answer.isSome = true → Counted.advance p n s = .ok s) ∧
  (∀ p initial s n t, Reachable p initial s → Counted.advance p n s = .ok t →
    t.steps ≤ s.steps+n ∧ (t.answer = none → t.steps = s.steps+n))

/-- Identity embedding, fixed full-field old landmark projection. It cannot
drop cell effects, reorder snapshots or choose a matching subsequence. -/
def F6 : Prop :=
  ∀ e initial, Trial.validStart e initial = .ok () →
    ∃ s raw,
      Reachable ⟨[],embed e⟩ initial s ∧
      (Trial.runCountedWith .approved e initial).result = .answer raw ∧
      s.answer.map (fun a => a.raw) = some raw ∧
      s.mem.record = (Trial.runCountedWith .approved e initial).record ∧
      s.landmarks = (Trial.runCountedWith .approved e initial).states

def lifecycleReachable (p : Program) (initial : Trial.Start) (s : Lifecycle.State) : Prop :=
  ∃ first allow n, Counted.begin p initial = .ok first ∧
    Lifecycle.advance p allow n { execution := first } = .ok s

def L1 : Prop :=
  ∀ p initial s allow r,
    lifecycleReachable p initial s → s.failure = none → s.destroyed = false →
    s.execution.answer = none → Lifecycle.request s.execution = some r →
    let ordinal := (s.requests.filter (fun q => q.domain == r.domain && q.site == r.site)).length+1
    allow r ordinal = false →
    Lifecycle.step p allow s = .ok { s with
      failure := some ⟨r,ordinal,s.execution.frames.map (fun f => (f.id,f.name))⟩ }

def L2 : Prop :=
  ∀ p initial s, lifecycleReachable p initial s →
    let d := Lifecycle.destroy s
    Lifecycle.destroy d = d ∧ d.destroyed = true ∧
    d.execution.events = s.execution.events ∧ d.execution.history = s.execution.history ∧
    d.execution.mem.record = s.execution.mem.record ∧
    d.execution.bindings = [] ∧ d.execution.slots = [] ∧ d.execution.reservations = [] ∧
    d.execution.frames = [] ∧ d.execution.tasks = [] ∧ d.execution.releaseChain = [] ∧
    d.execution.answer = none ∧ d.execution.outside = initial.outside ∧
    Trial.validStart (.num 0)
      ⟨d.execution.mem.cells.map (fun c => ⟨c.addr,c.item,c.link,c.count⟩),[],initial.outside⟩ = .ok () ∧
    (∀ root ∈ initial.outside,
      Trial.readBack d.execution.mem (.list root) = Trial.readBack initial.toMemory (.list root)) ∧
    (∀ addr, addr ∈ d.cleanup ↔
      (∃ c ∈ s.execution.mem.cells, c.addr = addr) ∧
      ¬ (∃ c ∈ d.execution.mem.cells, c.addr = addr))

/-- Primitive Create count from entry until Return. Nested events remain in the
same interval; Free never decrements the total. -/
def creates (invocation : Nat) (events : List Counted.Event) : Nat :=
  let (_,n) := events.foldl (fun (active,n) event => match event with
    | .enter f => (active || f.id == invocation,n)
    | .returning id _ => (active && id != invocation,n)
    | .create _ _ _ => (active,n + if active then 1 else 0)
    | _ => (active,n)) (false,0)
  n

def uniqueEntry (s : Counted.State) (f : Counted.Frame) : Bool :=
  let cells := s.mem.cells.map (fun c => (⟨c.addr,c.item,c.link,c.count⟩ : Trial.StartCell))
  let reached := f.args.flatMap (fun v => Trial.chainAddrs cells cells.length (Inspect.link v.raw))
  reached.eraseDups.length == reached.length && reached.all (fun a =>
    s.mem.cells.any (fun c => c.addr == a && c.status == .live && c.count == 1))

/-- Later slice-1 statement for the checker that actually runs. Acceptance is
the checker's Bool result, not a hypothesized recursive no-Create summary. -/
def Conditional (checker : Program → String → Bool) : Prop :=
  ∀ p initial s f n t,
    Reachable p initial s → s.frames.head? = some f →
    s.history.getLast?.map (fun a => a.name) = some "Enter" →
    (∃ decl ∈ p.functions, decl.name = f.name ∧ decl.demanded = true) →
    checker p f.name = true → uniqueEntry s f = true →
    Counted.advance p n s = .ok t → creates f.id t.events = 0

/-- Later slice-2 statement. No uniqueness assumption is supplied to this
theorem: caller enforcement must establish whatever its checker requires. -/
def Enforced (checker : Program → Bool) : Prop :=
  ∀ p initial s f,
    checker p = true → Reachable p initial s →
    Counted.Event.enter f ∈ s.events →
    (∃ decl ∈ p.functions, decl.name = f.name ∧ decl.demanded = true) →
    creates f.id s.events = 0

end Full.Statements
