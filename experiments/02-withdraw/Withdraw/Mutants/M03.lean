import Withdraw.Spec

namespace Withdraw.Mutants.M03

open Withdraw

def withdraw : Impl := fun balance amount =>
  if amount = 0 then
    .error .invalidAmount
  else if balance < amount then
    .error .insufficientFunds
  else
    .ok (amount - balance)

end Withdraw.Mutants.M03
