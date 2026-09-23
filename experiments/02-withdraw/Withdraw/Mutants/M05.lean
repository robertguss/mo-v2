import Withdraw.Spec

namespace Withdraw.Mutants.M05

open Withdraw

def withdraw : Impl := fun balance amount =>
  if balance < amount then
    .error .insufficientFunds
  else
    .ok (balance - amount)

end Withdraw.Mutants.M05
