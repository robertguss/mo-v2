import Withdraw.Spec

/-! Builder B's implementation of `withdraw` and its proof of the four promises. -/

namespace Withdraw.B

/-- Withdraw `amount` cents from `balance` cents. Zero is checked first, then
whether the balance covers the amount. -/
def withdraw : Impl := fun balance amount =>
  if amount = 0 then .error .invalidAmount
  else if balance < amount then .error .insufficientFunds
  else .ok (balance - amount)

theorem withdraw_correct : Correct withdraw := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro balance amount r h
    unfold withdraw at h
    split at h
    · cases h
    · split at h
      · cases h
      · cases h
        omega
  · intro balance amount hpos hle
    refine ⟨balance - amount, ?_⟩
    unfold withdraw
    simp [show amount ≠ 0 by omega, show ¬ balance < amount by omega]
  · intro balance amount hlt
    unfold withdraw
    simp [show amount ≠ 0 by omega, hlt]
  · intro balance
    rfl

end Withdraw.B
