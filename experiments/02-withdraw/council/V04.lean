import Spec

namespace Candidate

open Withdraw

def withdraw : Impl := fun balance amount =>
  if amount = 0 then
    .error .invalidAmount
  else if balance < amount || amount > 1000000 then
    .error .insufficientFunds
  else
    .ok (balance - amount)

end Candidate
