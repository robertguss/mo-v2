import Full.Proofs.ForwardLeaves
import Full.Proofs.ForwardBindings
import Full.Proofs.ForwardCallEnter
import Full.Proofs.ForwardCapture
import Full.Proofs.ForwardCleanup

namespace Full.Proofs.Correspondence
open Counted Statements Forward

/-- Every actual transition either performs one source step or strictly
decreases the frozen administrative rank without changing source control. -/
theorem local_step (hr : Reachable p initial s) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) (ha : s.answer = none) :
    Related (Plain.step p a) t ∨ (Related a t ∧ Control.rank t < Control.rank s) := by
  cases hs : s.tasks with
  | nil => simp [Counted.step, Counted.transition, ha, hs] at ht
  | cons task rest =>
    cases task with
    | start => exact Or.inr (erased_step .start hs ha hrel ht)
    | eval e ctx =>
      cases e with
      | num n => exact Or.inl (ForwardLeaves.literal_step (.num n) hs ha hrel ht)
      | bool b => exact Or.inl (ForwardLeaves.literal_step (.bool b) hs ha hrel ht)
      | nil => exact Or.inl (ForwardLeaves.literal_step .nil hs ha hrel ht)
      | var x => exact Or.inl (ForwardLeaves.variable_step hs ha hrel ht)
      | bin op x y => exact Or.inl (structural_step (.bin op x y) hs ha hrel ht)
      | letE x v body => exact Or.inl (structural_step (.letE x v body) hs ha hrel ht)
      | ifE c y n => exact Or.inl (structural_step (.ifE c y n) hs ha hrel ht)
      | matchE v n h tail body =>
          exact Or.inl (structural_step (.matchE v n h tail body) hs ha hrel ht)
      | call name args =>
        cases args with
        | nil => exact Or.inr (dispatch_zero_step hs ha hrel ht)
        | cons e args => exact Or.inl (ForwardCalls.dispatch_nonempty_step hs ha hrel ht)
    | capture => exact ForwardCapture.capture_step hr hs ha hrel ht
    | primitive op ctx => exact Or.inl (ForwardLeaves.primitive_step hs ha hrel ht)
    | bind name body ctx => exact Or.inl (ForwardBindings.bind_step hr hs ha hrel ht)
    | chooseIf yes no ctx => exact Or.inl (ForwardBindings.chooseIf_step hr hs ha hrel ht)
    | chooseMatch empty head tail body ctx =>
        exact Or.inl (ForwardBindings.chooseMatch_step hr hs ha hrel ht)
    | decompose head tail body bid ctx =>
        exact Or.inr (ForwardBindings.decompose_step hr hs ha hrel ht)
    | matchComplete ctx => exact Or.inr (erased_step (.matchComplete ctx) hs ha hrel ht)
    | branchStart ctx => exact Or.inr (erased_step (.branchStart ctx) hs ha hrel ht)
    | branchResult bid inner outer =>
        exact Or.inr (ForwardCleanup.branchResult_step hr hs ha hrel ht)
    | handoffMatch ctx => exact Or.inr (ForwardCleanup.handoffMatch_step hr hs ha hrel ht)
    | handoff => exact Or.inr (erased_step .handoff hs ha hrel ht)
    | enter name arity ctx =>
      cases arity with
      | zero => exact Or.inl (ForwardCalls.enter_zero_step hs ha hrel ht)
      | succ arity => exact Or.inl (ForwardCallEnter.enter_positive_step hr hs ha hrel ht)
    | returning frame ctx => exact Or.inl (ForwardCalls.return_step hs ha hrel ht)
    | giveBinding bid => exact Or.inr (ForwardCleanup.giveBinding_step hr hs ha hrel ht)
    | givePending => exact Or.inr (ForwardCleanup.givePending_step hr hs ha hrel ht)
    | free addr => exact Or.inr (free_step f1 hr hs ha hrel ht)
    | freeReserved addr => exact Or.inr (ForwardCleanup.freeReserved_step hr hs ha hrel ht)
    | finish =>
      have hlast := (ControlShape.reachable_shape hr).1
      simp only [hs, ControlShape.FinishTail] at hlast
      subst rest
      exact Or.inl (finish_step hs ha hrel ht)

/-- Decodability is propagated from initialization; it is not inferred from
generic typing of an arbitrary work stack. -/
theorem advance_decodable (hr : Reachable p initial s) (hrel : Related a s)
    (ht : Counted.advance p n s = .ok t) : ∃ b, Related b t := by
  induction n generalizing s a with
  | zero => cases ht; exact ⟨a, hrel⟩
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance, ha] at ht; subst t; exact ⟨a, hrel⟩
    | none =>
      cases hs : Counted.step p s with
      | error why => simp [Counted.advance, ha, hs] at ht
      | ok u =>
        simp [Counted.advance, ha, hs] at ht
        rcases local_step hr hrel hs ha with hn | ⟨hn, _⟩
        · exact ih (Simulation.reachable_step hr hs) hn ht
        · exact ih (Simulation.reachable_step hr hs) hn ht

theorem forward : Simulation.Forward := by
  intro p initial s hr
  obtain ⟨first, n, hb, hn⟩ := hr
  obtain ⟨a, _, hrel⟩ := SimulationInitial.initial_simulation p initial first hb
  have hr : Reachable p initial s := ⟨first, n, hb, hn⟩
  obtain ⟨b, hdec⟩ := advance_decodable ⟨first, 0, hb, rfl⟩ hrel hn
  exact ⟨b, hdec, fun _ ht ha => local_step hr hdec ht ha⟩

end Full.Proofs.Correspondence

namespace Full.Proofs
open Counted Statements

theorem f2 : Statements.F2 := Simulation.f2_of_f1_forward f1 Correspondence.forward

theorem f3 : Statements.F3 := by
  intro p initial s internal hr hb
  have hi := Invariance.boundary_invariant hr hb
  have hp : Inspect.protection initial internal = true := by
    simp only [Inspect.invariant, Bool.and_eq_true] at hi
    exact hi.1.1.1.1.1.1.1
  refine ⟨hp, ?_⟩
  rcases hb with rfl | ⟨c, hc, rfl | rfl⟩
  · exact Simulation.reachable_related Correspondence.forward hr
  all_goals
    have ha : s.answer = none := by
      cases he : s.answer with
      | none => rfl
      | some v =>
        have hh := ControlShape.terminal_no_transition hr (by simp [he])
        rw [hh] at hc
        contradiction
    have ht : Counted.step p s = .ok (commit c) := by simp [Counted.step, ha, hc]
    obtain ⟨first, n, hb, hrel⟩ := Simulation.reachable_related Correspondence.forward
      (Simulation.reachable_step hr ht)
    refine ⟨first, n, hb, ?_⟩
  · simpa only [Related, decode_commit] using hrel
  · exact hrel

end Full.Proofs
