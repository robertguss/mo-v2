import Full.Proofs.PreservationCons
import Full.Proofs.PreservationRelease
import Full.Proofs.PreservationDecomposeUnique
import Full.Proofs.PreservationDecomposeShared
import Full.Proofs.Simulation
import Full.Proofs.Scope

namespace Full.Proofs.Invariance
open Counted Statements

theorem transition_invariant (hr : Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : Counted.transition p s = .ok c) : Inspect.invariant initial c.state = true := by
  cases hs : s.tasks with
  | nil => simp [Counted.transition,hs] at ht
  | cons task rest =>
    cases task
    all_goals try exact Preservation.administrative_invariant hr hi ht hs (by constructor)
    case eval e ctx =>
      cases e
      all_goals try exact Preservation.administrative_invariant hr hi ht hs (by constructor)
      all_goals first
        | exact PreservationRelease.var_invariant hr hi ht hs
        | exact Preservation.literal_invariant hr hi ht hs (by simp)
    case primitive op ctx =>
      by_cases hop : op = .cons
      · subst op; exact PreservationCons.cons_invariant hr hi ht hs
      · exact PreservationOwnership.scalar_invariant hr hi ht hs hop
    case bind name body ctx => exact PreservationOwnership.bind_invariant hr hi ht hs
    case chooseIf yes no ctx => exact PreservationOwnership.chooseIf_invariant hr hi ht hs
    case chooseMatch empty head tail body ctx => exact PreservationOwnership.chooseMatch_invariant hr hi ht hs
    case enter name arity ctx => exact PreservationOwnership.enter_invariant hr hi ht hs
    case giveBinding id => exact PreservationRelease.giveBinding_invariant hr hi ht hs
    case givePending => exact PreservationRelease.givePending_invariant hr hi ht hs
    case free addr => exact PreservationRelease.free_invariant hr hi ht hs
    case freeReserved addr => exact PreservationRelease.freeReserved_invariant hr hi ht hs
    case decompose head tail body bid ctx =>
      have hready := ReleaseReadiness.reachable_ready hr
      rw [hs] at hready
      obtain ⟨v,slots,addr,hslots,hv⟩ := hready.1
      obtain ⟨ph,pt,hvalue⟩ := Progress.nonempty_value hi (by simp [hslots]) hv
      obtain ⟨cell,hf,_,_⟩ := Progress.root_ready hi (Progress.slot_root (by simp [hslots]) hv)
      by_cases hc : cell.count = 1
      · exact PreservationDecomposeUnique.decompose_unique_invariant hr hi ht hs hslots hv hvalue hf hc
      · exact PreservationDecomposeShared.decompose_shared_invariant hr hi ht hs hslots hv hvalue hf hc

theorem advance_invariant (hr : Reachable p initial s)
    (hi : Inspect.invariant initial s = true) (ht : Counted.advance p n s = .ok t) :
    Inspect.invariant initial t = true := by
  induction n generalizing s with
  | zero => cases ht; exact hi
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hi
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        have hstep : Counted.step p s = .ok (commit c) := by simp [Counted.step,ha,hc]
        simp [Counted.advance,hstep,ha] at ht
        exact ih (Simulation.reachable_step hr hstep) (transition_invariant hr hi hc) ht

theorem reachable_invariant (hr : Reachable p initial s) : Inspect.invariant initial s = true := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_invariant ⟨first,0,hb,rfl⟩ (Initial.initialized_invariant p initial first hb) hn

theorem boundary_invariant (hr : Reachable p initial s)
    (hb : Counted.Boundary p s t) : Inspect.invariant initial t = true := by
  have hi := reachable_invariant hr
  rcases hb with rfl | ⟨c,hc,rfl | rfl⟩
  · exact hi
  · exact transition_invariant hr hi hc
  · exact transition_invariant hr hi hc

end Full.Proofs.Invariance

namespace Full.Proofs
open Counted Statements

theorem f1 : Statements.F1 := by
  refine ⟨fun p initial first hb => (Initial.begin_scope_ids p initial first hb).1,?_⟩
  intro p initial s hr
  have hi := Invariance.reachable_invariant hr
  refine ⟨hi,fun internal hb => Invariance.boundary_invariant hr hb,?_⟩
  intro ha
  obtain ⟨c,hc⟩ := ReservedReadiness.progress hr hi ha
  have hstep : Counted.step p s = .ok (commit c) := by simp [Counted.step,ha,hc]
  refine ⟨commit c,hstep,Invariance.transition_invariant hr hi hc,
    step_count p s (commit c) ha hstep,?_,?_,commit_effects p s c ha hc,?_⟩
  · exact transition_scope p s c hc
  · intro other ho
    have he : other = c := Except.ok.inj (ho.symm.trans hc)
    subst other
    rfl
  · intro other ho
    exact Except.ok.inj (ho.symm.trans hstep)

end Full.Proofs
