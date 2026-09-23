import Withdraw.Spec

namespace Withdraw.Mutants.M06

open Withdraw

def withdraw : Impl := fun balance amount =>
  if amount = 0 then
    .error .invalidAmount
  else if balance + 1 < amount then
    .error .insufficientFunds
  else
    .ok (balance - amount)

end Withdraw.Mutants.M06
