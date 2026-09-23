import Withdraw.Spec

namespace Withdraw.Mutants.M08

open Withdraw

def withdraw : Impl := fun balance amount =>
  if amount.toInt32 ≤ 0 then
    .error .invalidAmount
  else if balance < amount then
    .error .insufficientFunds
  else
    .ok (balance - amount)

end Withdraw.Mutants.M08
