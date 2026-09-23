/-!
# Experiment 2: the spec

Locked (D18). Robert approved these promises and examples. Builders and the
bug planter may not change this file.
-/

namespace Withdraw

/-- Why a withdrawal can fail. -/
inductive WithdrawError where
  | insufficientFunds
  | invalidAmount
  deriving DecidableEq, Repr

/-- Any implementation of `withdraw balance amount`, in whole cents. `.ok r`
means it succeeded and `r` is the new balance. -/
abbrev Impl := Nat → Nat → Except WithdrawError Nat

/-- Promise 1, correct result: a successful withdrawal leaves exactly the old
balance minus the amount. (Stated as `r + amount = balance` so it cannot be
satisfied by subtraction that quietly stops at zero.) -/
def CorrectResult (f : Impl) : Prop :=
  ∀ balance amount r, f balance amount = .ok r → r + amount = balance

/-- Promise 2, succeeds when it should: if the amount is more than zero and no
more than the balance, the withdrawal succeeds. -/
def SucceedsWhenItShould (f : Impl) : Prop :=
  ∀ balance amount, 0 < amount → amount ≤ balance → ∃ r, f balance amount = .ok r

/-- Promise 3, fails when it should: if the amount is more than the balance, it
fails with insufficient funds. -/
def FailsWhenItShould (f : Impl) : Prop :=
  ∀ balance amount, balance < amount → f balance amount = .error .insufficientFunds

/-- Promise 4, zero is invalid: a withdrawal of zero fails with invalid
amount. -/
def ZeroIsInvalid (f : Impl) : Prop :=
  ∀ balance, f balance 0 = .error .invalidAmount

/-- All four promises. -/
def Correct (f : Impl) : Prop :=
  CorrectResult f ∧ SucceedsWhenItShould f ∧ FailsWhenItShould f ∧ ZeroIsInvalid f

/-- The approved examples: balance, amount, expected result (cents). -/
def examples : List (Nat × Nat × Except WithdrawError Nat) :=
  [ (10000, 3000, .ok 7000),
    (10000, 10000, .ok 0),
    (10000, 10100, .error .insufficientFunds),
    (0, 100, .error .insufficientFunds),
    (10000, 0, .error .invalidAmount),
    (0, 0, .error .invalidAmount) ]

/-- The four promises checked at one input, as a yes/no answer a test can run.
`holdsAt_iff` in `Withdraw/Oracle.lean` proves that this holding at every input
is exactly the same as `Correct`. -/
def holdsAt (f : Impl) (balance amount : Nat) : Bool :=
  match f balance amount with
  | .ok r => r + amount == balance && 0 < amount
  | .error .insufficientFunds => balance < amount
  | .error .invalidAmount => amount == 0

end Withdraw
