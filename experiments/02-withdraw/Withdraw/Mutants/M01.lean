import Withdraw.Spec

namespace Withdraw.Mutants.M01

open Withdraw

def withdraw : Impl := fun balance amount =>
  if amount = 0 then
    .error .invalidAmount
  else if amount < balance then
    .error .insufficientFunds
  else
    .ok (balance - amount)

end Withdraw.Mutants.M01
