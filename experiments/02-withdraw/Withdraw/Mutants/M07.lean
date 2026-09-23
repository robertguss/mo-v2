import Withdraw.Spec

namespace Withdraw.Mutants.M07

open Withdraw

def withdraw : Impl := fun balance amount =>
  if amount = 0 then
    .error .invalidAmount
  else if balance < amount then
    .error .insufficientFunds
  else
    .ok (balance.toUInt32 - amount.toUInt32).toNat

end Withdraw.Mutants.M07
