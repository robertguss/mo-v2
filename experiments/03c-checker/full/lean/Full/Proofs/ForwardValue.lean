import Full.Proofs.Forward
import Full.Proofs.BindingIdentity

namespace Full.Proofs.ForwardValue
open Counted Statements

/-- A successful saved-continuation decode accepts a newly produced value.
This follows from the decoder itself, not from generic residual typing. -/
theorem focus_value (h : Control.continuations s n ts vs = .ok ks) (v : Slot) :
    Control.focus s n ts (v::vs) = .ok ⟨.value v.value,ks⟩ := by
  induction n generalizing ts vs with
  | zero => simp [Control.continuations] at h
  | succ n ih =>
    cases ts with
    | nil => simp [Control.focus,h]
    | cons task ts =>
      cases task
      all_goals try simpa only [Control.focus,h,bind,pure,Except.bind,Except.pure] using
        (show (.ok (⟨.value v.value,ks⟩ : Plain.State) : Except String Plain.State) = .ok _ from rfl)
      all_goals simp only [Control.continuations] at h
      all_goals try contradiction
      all_goals try exact ih h
      all_goals simp_all [Control.focus]
      all_goals rename_i name arity ctx
      all_goals cases arity <;> simp_all [Control.focus,Control.continuations]

end Full.Proofs.ForwardValue
