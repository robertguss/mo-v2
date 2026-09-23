import Withdraw.Spec
import Withdraw.ImplB

/-! Locked. Compiles only if builder B's `withdraw` keeps all four promises. -/

theorem Withdraw.acceptedB : Withdraw.Correct Withdraw.B.withdraw := Withdraw.B.withdraw_correct

#print axioms Withdraw.acceptedB
