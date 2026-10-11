import Full.Proofs.Heap
import Full.Proofs.DestructionGraph
import Full.Proofs.HoldingAccounted
import Full.Proofs.ReservationAccounted
import Full.Proofs.Residual
import Full.Proofs.Simulation
import Proofs.Reachability

namespace Full.Proofs.Final
open Counted Trial Trial.Proofs

/-- A release chain can only be suspended at its next release action. -/
def ChainWork (s : State) : Prop :=
  s.releaseChain = [] ∨ ∃ rest, s.tasks = .givePending :: rest ∨
    ∃ addr, s.tasks = .free addr :: rest

set_option maxHeartbeats 2000000 in
theorem transition_chain (hs : ChainWork s)
    (ht : Counted.transition p s = .ok c) : ChainWork c.state := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp_all [ChainWork]

theorem advance_chain (hs : ChainWork s)
    (ht : Counted.advance p n s = .ok t) : ChainWork t := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance, ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance, Counted.step, ha, hc] at ht
      | ok c =>
        simp [Counted.advance, Counted.step, ha, hc] at ht
        exact ih (s := commit c) (transition_chain hs hc) ht

theorem reachable_chain (hr : Statements.Reachable p initial s) : ChainWork s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  apply advance_chain ?_ hn
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  exact Or.inl rfl

theorem answered_no_chain (hr : Statements.Reachable p initial s)
    (ha : s.answer.isSome = true) : s.releaseChain = [] := by
  have ht := (ControlShape.reachable_shape hr).2 ha
  have hc := reachable_chain hr
  simpa [ChainWork, ht] using hc

/-- Terminal heap facts use F1 only for the executable data invariant. -/
theorem terminal_live_positive (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = []) (hr : s.reservations = []) :
    ∀ c ∈ s.mem.cells, c.status = .live ∧ 0 < c.count := by
  simp only [Inspect.invariant, Bool.and_eq_true] at hi
  have hc := List.all_eq_true.mp hi.1.1.2
  intro c hm
  have h := hc c hm
  cases he : c.status <;> simp_all [hr, ht]

theorem terminal_valid (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = []) (hr : s.reservations = []) :
    Trial.validStart (.num 0)
      ⟨s.mem.cells.map Destruction.project, [], executionRoots s⟩ = .ok () := by
  obtain ⟨hh,hp,_⟩ := invariant_heap initial s hi
  have hlp := terminal_live_positive hi ht hr
  apply Destruction.valid_outside _ _ hh.unique hh.readable
  · intro c hc; exact hp c hc (hlp c hc).1
  · intro c hc
    obtain ⟨r,hr,cs,hpath,hm⟩ := positive_reachable _ _ hh hp
      (fun d hd _ => (hlp d hd).2) c hc (hlp c hc).1
    obtain ⟨d,hd,he⟩ := List.mem_map.mp hm
    have hdmem := hpath.mem_cells d hd
    have eqcd : c = d := by
      have hf := find_of_mem _ hh.unique c hc
      have hg := find_of_mem _ hh.unique d hdmem
      rw [he] at hg
      exact Option.some.inj (hf.symm.trans hg)
    exact ⟨r,hr,cs,hpath,eqcd ▸ hd⟩
  · intro c hc
    have hn := hh.counts c hc (hlp c hc).1
    unfold holders at hn
    rw [show s.mem.cells.filter (fun d => d.status == .live && d.link == some c.addr) =
      s.mem.cells.filter (fun d => d.link == some c.addr) from
        List.filter_congr (by intro d hd; simp [(hlp d hd).1])] at hn
    exact hn

/-- Exact F4, explicitly conditional on the still separate F1 obligation. -/
theorem f4_of_f1 (hf : Statements.F1) : Statements.F4 := by
  intro p initial s hr ha
  have ht := (ControlShape.reachable_shape hr).2 ha
  have hres := ReservationAccounted.answered_no_reservations hr ha
  have hhold := HoldingAccounted.answered_no_holding hr ha
  have hchain := answered_no_chain hr ha
  obtain ⟨hlen,hframes⟩ := Residual.terminal_shape hr ha
  have hi := (hf.2 p initial s hr).1
  have hlp := terminal_live_positive hi ht hres
  have hv := terminal_valid hi ht hres
  have hb : s.bindings.filter (fun b => b.record.status == .holding) = [] := by
    apply List.filter_eq_nil_iff.mpr
    intro b hm
    simp [hhold b hm]
  cases he : s.answer with
  | none => simp [he] at ha
  | some v =>
    have hm := Simulation.reachable_answer_slot hr he
    have hs : s.slots = [v] := by
      cases hslots : s.slots with
      | nil => simp [hslots] at hm
      | cons w ws =>
        have hw : ws = [] := by simpa [hslots] using hlen
        subst ws
        have hwv : v = w := by simpa [hslots] using hm
        simpa [hwv] using hslots
    simp only [executionRoots, hs, hb, List.map_cons, List.map_nil,
      List.cons_append, List.nil_append, List.append_nil] at hv
    change Trial.validStart (.num 0)
      ⟨s.mem.cells.map (fun c => ⟨c.addr,c.item,c.link,c.count⟩), [],
        Inspect.link v.raw :: s.outside⟩ = .ok () at hv
    simp only [Inspect.finalGraph, he, ht, hres, hframes, hchain, hs, hv,
      List.any_eq_false, List.all_eq_true]
    simp only [List.isEmpty_nil, Bool.not_eq_true, beq_iff_eq,
      Bool.and_eq_true, Except.isOk, Except.toBool, List.isEmpty_cons,
      List.cons.injEq, and_true, true_and]
    constructor
    · simp only [Bool.not_eq_true', List.any_eq_false, beq_iff_eq]
      exact hhold
    · simpa only [List.all_eq_true, beq_iff_eq] using
        (show ∀ c ∈ s.mem.cells, c.status = .live from fun c hc => (hlp c hc).1)

end Full.Proofs.Final
