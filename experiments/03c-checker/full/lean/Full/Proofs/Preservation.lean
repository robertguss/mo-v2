import Full.Proofs.LiveBindings
import Full.Proofs.Observer
import Full.Proofs.CountedTyping
import Full.Proofs.Effects
import Full.Proofs.Free

namespace Full.Proofs.Preservation
open Counted

/-- The observer at the atomic boundary follows from saved lexical identities,
not from a simulation or F1 premise. -/
theorem transition_observer (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) : Inspect.observer c.state = true :=
  Observer.transition_observer (Observer.reachable_invariant hr)
    (BindingIdentity.reachable_ids hr) ht

/-- The atomic boundary retains exactly the allocated identity range. -/
theorem transition_ids (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) :
    c.state.bindings.map (fun b => b.record.id) = List.range c.state.nextBinding :=
  BindingIdentity.transition_ids (BindingIdentity.reachable_ids hr) ht

/-- Future source uses remain protected even at the pre-commit boundary. -/
theorem transition_live (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) : LiveBindings.Live c.state :=
  LiveBindings.transition_live (LiveBindings.reachable_live hr)
    (fun _ hb => BindingIdentity.reachable_bound hr hb)
    (EnvironmentIdentity.reachable_invariant hr) (ReleaseQueue.reachable_quiet hr) ht

theorem live_check (hl : LiveBindings.Live s) (b : Binding) (hb : b ∈ s.bindings) :
    (!(s.tasks.any (taskUses b.record.id)) || (Inspect.link b.record.value).isNone ||
      b.record.status == .holding) = true := by
  cases hv : b.record.value with
  | num n => simp [Inspect.link, hv]
  | bool v => simp [Inspect.link, hv]
  | list addr =>
    cases addr with
    | none => simp [Inspect.link, hv]
    | some a =>
      cases hu : s.tasks.any (taskUses b.record.id) with
      | false => simp [hu]
      | true => simp [hl b hb a hv hu]

theorem transition_uses_check (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) :
    c.state.bindings.all (fun b =>
      !(c.state.tasks.any (taskUses b.record.id)) || (Inspect.link b.record.value).isNone ||
        b.record.status == .holding) = true :=
  List.all_eq_true.mpr (fun b hb => live_check (transition_live hr ht) b hb)

theorem transition_typed (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) :
    ∃ out, PlainTyping.FunctionsTyped p ∧ CountedTyping.StateTyped p out c.state := by
  obtain ⟨out, hp, hs⟩ := CountedTyping.reachable_typed hr
  exact ⟨out, hp, CountedTyping.transition_typed hp ht hs
    (BindingIdentity.reachable_ids hr)⟩

/-- Metadata commit does not change any executable invariant field. -/
theorem commit_invariant (initial : Trial.Start) (c : Change) :
    Inspect.invariant initial (commit c) = Inspect.invariant initial c.state := rfl

theorem cellEffects_append (xs ys : List Event) :
    Inspect.cellEffects (xs ++ ys) = Inspect.cellEffects xs ++ Inspect.cellEffects ys := by
  simp [Inspect.cellEffects]

set_option maxHeartbeats 4000000 in
/-- Exact record accounting is independent of whether the source has an
answer: this is a theorem about successful transfers, not about `step`. -/
theorem transition_record
    (hs : Inspect.cellEffects s.events = s.mem.record)
    (ht : Counted.transition p s = .ok c) :
    Inspect.cellEffects c.state.events = c.state.mem.record := by
  unfold Counted.transition at ht
  simp only [Trial.Memory.setCount, Trial.Memory.markSetAside,
    Trial.Memory.writeInPlace, Trial.Memory.release,
    bind, pure, Except.bind, Except.pure] at ht
  repeat' first
    | (simp_all [cellEffects_append, Inspect.cellEffects, Trial.Memory.create,
        Trial.Memory.updateCell, pure, Except.pure,
        throw, -List.find?_eq_none]; done)
    | split at ht
    | cases ht
  all_goals subst_vars
  all_goals simp_all [cellEffects_append, Inspect.cellEffects,
    Trial.Memory.updateCell, pure, Except.pure, throw, -List.find?_eq_none]
  all_goals repeat' first
    | (simp_all [-List.find?_eq_none]; done)
    | split at *
  all_goals subst_vars
  all_goals simp_all
  all_goals
    rename_i hm
    first
    | exact congrArg Trial.Memory.record hm
    | exact (congrArg Trial.Memory.record hm).symm

set_option maxHeartbeats 2000000 in
theorem transition_outside (ht : Counted.transition p s = .ok c) :
    c.state.outside = s.outside := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals rfl

theorem transition_identity_checks (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) :
    (c.state.bindings.map (fun b => b.record.id)).eraseDups.length = c.state.bindings.length ∧
      c.state.bindings.all (fun b => b.record.id < c.state.nextBinding) = true := by
  have hi := transition_ids hr ht
  have hn : (c.state.bindings.map (fun b => b.record.id)).Nodup := by
    rw [hi]
    exact List.nodup_range
  refine ⟨?_, List.all_eq_true.mpr ?_⟩
  · rw [Initial.eraseDups_of_nodup _ hn, List.length_map]
  · intro b hb
    apply decide_eq_true
    apply List.mem_range.mp
    rw [← hi]
    exact List.mem_map.mpr ⟨b, hb, rfl⟩

/-- Reassemble the full invariant for a transfer retaining memory and binding
data. Slots may change, provided readback and each address's owner count remain
the same. Pending Free tasks must survive for zero-count live cells. -/
theorem unchanged_heap_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hm : c.state.mem = s.mem) (hb : c.state.bindings = s.bindings)
    (he : c.state.edges = s.edges)
    (hres : c.state.reservations = s.reservations)
    (hslots : c.state.slots.all (Inspect.readable c.state) = true)
    (howners : ∀ a, ((Inspect.owners c.state).filter (fun r => r == some a)).length =
      ((Inspect.owners s).filter (fun r => r == some a)).length)
    (hfree : ∀ a, s.tasks.any (fun t => match t with | .free b => b == a | _ => false) = true →
      c.state.tasks.any (fun t => match t with | .free b => b == a | _ => false) = true) :
    Inspect.invariant initial c.state = true := by
  have ho := transition_outside ht
  have hobs := transition_observer hr ht
  have huses := transition_live hr ht
  simp only [Inspect.invariant, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hi ⊢
  obtain ⟨⟨⟨⟨⟨⟨⟨hprot, _⟩, hunique⟩, hids⟩, hbound⟩, hcells⟩, hreserved⟩, hrecord⟩ := hi
  refine ⟨⟨⟨⟨⟨⟨⟨?_, hobs⟩, ?_⟩, ?_⟩, ?_⟩, ?_⟩, ?_⟩,
    transition_record hrecord ht⟩
  · simp only [Inspect.protection, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hprot ⊢
    obtain ⟨⟨⟨⟨hout, hread⟩, hbindings⟩, _⟩, hedges⟩ := hprot
    refine ⟨⟨⟨⟨by simpa [ho] using hout, by simpa [hm] using hread⟩, ?_⟩,
      List.all_eq_true.mp hslots⟩,
      by simpa [hm, he, Inspect.readable] using hedges⟩
    intro b hmem
    have hx := hbindings b (hb ▸ hmem)
    exact ⟨⟨hx.1.1, live_check huses b hmem⟩, by simpa [Inspect.readable, hm] using hx.2⟩
  · simpa [hm] using hunique
  · simpa [hb] using hids
  · exact (transition_identity_checks hr ht).2 |> List.all_eq_true.mp
  · intro d hd
    have hx := hcells d (hm ▸ hd)
    refine ⟨by simpa [hm, howners] using hx.1, ?_⟩
    split
    · rename_i hstatus
      simpa [hstatus, hres] using hx.2
    · rename_i hstatus
      have hh := hx.2
      simp only [hstatus, ↓reduceIte, Bool.and_eq_true] at hh
      rcases hh with ⟨hpath, hqueue⟩
      simp only [Bool.and_eq_true, Bool.or_eq_true] at hqueue ⊢
      refine ⟨by simpa [hm] using hpath, ?_⟩
      rcases hqueue with hn | hf
      · exact Or.inl hn
      · exact Or.inr (hfree d.addr hf)
  · simpa [hm, hres] using hreserved

/-- A convenient specialization for purely administrative transfers. -/
theorem unchanged_data_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hm : c.state.mem = s.mem) (hb : c.state.bindings = s.bindings)
    (hv : c.state.slots = s.slots) (he : c.state.edges = s.edges)
    (hres : c.state.reservations = s.reservations)
    (hfree : ∀ a, s.tasks.any (fun t => match t with | .free b => b == a | _ => false) = true →
      c.state.tasks.any (fun t => match t with | .free b => b == a | _ => false) = true) :
    Inspect.invariant initial c.state = true := by
  have hslot : s.slots.all (Inspect.readable s) = true := by
    simp only [Inspect.invariant, Bool.and_eq_true] at hi
    have hp := hi.1.1.1.1.1.1.1
    simp only [Inspect.protection, Bool.and_eq_true] at hp
    exact hp.1.2
  apply unchanged_heap_invariant hr hi ht hm hb he hres
    (by simpa [hv, Inspect.readable, hm] using hslot) _ hfree
  intro a
  simp [Inspect.owners, hm, hb, hv, transition_outside ht]

/-- Literal evaluation adds no address owner, including the empty-list literal. -/
theorem literal_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .eval e ctx :: rest)
    (he : (∃ n, e = .num n) ∨ (∃ b, e = .bool b) ∨ e = .nil) :
    Inspect.invariant initial c.state = true := by
  have hslot : s.slots.all (Inspect.readable s) = true := by
    simp only [Inspect.invariant, Bool.and_eq_true] at hi
    have hp := hi.1.1.1.1.1.1.1
    simp only [Inspect.protection, Bool.and_eq_true] at hp
    exact hp.1.2
  have htransfer := ht
  rcases he with ⟨n, rfl⟩ | ⟨b, rfl⟩ | rfl
  all_goals simp only [Counted.transition, hs, pure, Except.pure, Except.ok.injEq] at ht
  all_goals subst c
  all_goals apply unchanged_heap_invariant hr hi htransfer rfl rfl rfl rfl
  all_goals first
    | solve | simpa [Inspect.readable, Trial.readBack, Trial.readList] using hslot
    | solve | intro a; simp [Inspect.owners, Inspect.link, List.filter_append]
    | solve | intro a hf; simpa [hs] using hf

/-- The control-only cases of the frozen transfer function. -/
inductive Administrative : Task → Prop where
  | start : Administrative .start
  | capture : Administrative .capture
  | bin : Administrative (.eval (.bin op a b) ctx)
  | letE : Administrative (.eval (.letE x a b) ctx)
  | ifE : Administrative (.eval (.ifE a b d) ctx)
  | matchE : Administrative (.eval (.matchE a n h t body) ctx)
  | call : Administrative (.eval (.call name args) ctx)
  | matchComplete : Administrative (.matchComplete ctx)
  | branchStart : Administrative (.branchStart ctx)
  | branchResult : Administrative (.branchResult bid inner outer)
  | handoffMatch : Administrative (.handoffMatch ctx)
  | handoff : Administrative .handoff
  | returning : Administrative (.returning frame ctx)
  | finish : Administrative .finish

set_option maxHeartbeats 2000000 in
/-- Full executable invariant preservation for every administrative transfer,
including source dispatch, branch cleanup scheduling, return and finish. -/
theorem administrative_invariant (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = task :: rest) (ha : Administrative task) :
    Inspect.invariant initial c.state = true := by
  have htransfer := ht
  cases ha
  all_goals simp only [Counted.transition, hs, bind, pure, Except.bind, Except.pure] at ht
  all_goals repeat' first | split at ht | cases ht | contradiction
  all_goals apply unchanged_data_invariant hr hi htransfer rfl rfl rfl rfl rfl
  all_goals intro a hf
  all_goals simp only [hs, List.any_cons, Bool.false_or] at hf
  all_goals simpa [List.any_append, hf]

end Full.Proofs.Preservation
