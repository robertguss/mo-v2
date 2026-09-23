import Withdraw.Spec

/-! Builder A's implementation of `withdraw`, its runtime contract, and the
proof that it keeps all four promises in `Withdraw/Spec.lean`. -/

namespace Withdraw.A

open Withdraw

/-- Withdraw `amount` cents from `balance` cents. A zero amount is invalid; an
amount larger than the balance is refused for insufficient funds; otherwise the
new balance is returned. -/
def withdraw : Impl := fun balance amount =>
  if amount = 0 then
    .error .invalidAmount
  else if balance < amount then
    .error .insufficientFunds
  else
    .ok (balance - amount)

/-- The runtime contract for `withdraw balance amount`, checked against its
result.

* requires: nothing beyond the types. Balances and amounts are whole cents
  (`Nat`), so negative values cannot be passed in.
* ensures, on success `.ok r`: the amount was positive, it did not exceed the
  balance, and `r + amount = balance` (no silent clamping at zero).
* ensures, on `.error .insufficientFunds`: the amount really was more than the
  balance.
* ensures, on `.error .invalidAmount`: the amount really was zero.

Returns `false` when the result breaks the contract. -/
def contract (balance amount : Nat) : Except WithdrawError Nat → Bool
  | .ok r => decide (0 < amount) && decide (amount ≤ balance) && r + amount == balance
  | .error .insufficientFunds => decide (balance < amount)
  | .error .invalidAmount => amount == 0

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
    have h0 : amount ≠ 0 := by omega
    have h1 : ¬ balance < amount := by omega
    simp [withdraw, h0, h1]
  · intro balance amount hlt
    have h0 : amount ≠ 0 := by omega
    simp [withdraw, h0, hlt]
  · intro balance
    simp [withdraw]

end Withdraw.A
