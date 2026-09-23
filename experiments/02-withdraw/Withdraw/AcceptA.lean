import Withdraw.Spec
import Withdraw.ImplA

/-! Locked. Compiles only if builder A's `withdraw` keeps all four promises. -/

theorem Withdraw.acceptedA : Withdraw.Correct Withdraw.A.withdraw := Withdraw.A.withdraw_correct

#print axioms Withdraw.acceptedA
