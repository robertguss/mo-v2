import Spec

namespace Candidate

open Withdraw

def withdraw : Impl := fun balance amount =>
  if balance < amount then
    .error .insufficientFunds
  else
    .ok (balance - amount)

end Candidate
