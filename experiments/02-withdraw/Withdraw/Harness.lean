import Withdraw.Spec

/-!
# Experiment 2: how each method runs

Locked. Builders and the bug planter must not read this file, so bugs are not
shaped to slip past a known input range. Each method returns the first input it
finds that breaks something, or `none` if it found nothing.

- Examples: the six approved examples, exact expected results.
- Property testing: 10,000 random inputs whose size grows from 0 to 10,000
  cents, as QuickCheck-style tools do, checked against the four promises.
- Exhaustive: every balance and amount from 0 to 200 cents.
- Contracts: the implementation's own `ensures` check, run on a production-like
  workload of 10,000 withdrawals (balances up to $100,000; mostly valid
  amounts, some too large, a few zero).
- Differential: the implementation's result compared with builder B's
  independent one, on the property-test inputs and the production workload.
- Lean proof and council review are not run here: the proof is checked by Lean,
  and the council reads the code.
-/

namespace Withdraw

/-- A deterministic pseudo-random sequence (64-bit linear congruential). -/
def lcg (s : Nat) : Nat := (6364136223846793005 * s + 1442695040888963407) % 2 ^ 64

/-- `n` pseudo-random draws from a seed. -/
def draws (seed n : Nat) : List Nat := Id.run do
  let mut s := seed
  let mut out := #[]
  for _ in [0:n] do
    s := lcg s
    out := out.push (s / 65536)
  return out.toList

/-- Property-test inputs: test `i` draws balance and amount from `0..i`. -/
def propertyInputs : List (Nat × Nat) :=
  let ds := (draws 42 20000).toArray
  (List.range 10000).map fun i =>
    (ds[2 * i]! % (i + 1), ds[2 * i + 1]! % (i + 1))

/-- Production-like inputs: balances up to 10,000,000 cents; 80% of amounts in
`1..balance`, 15% just over the balance, 5% zero. -/
def workloadInputs : List (Nat × Nat) :=
  let ds := (draws 7 30000).toArray
  (List.range 10000).map fun i =>
    let b := ds[3 * i]! % 10000001
    let kind := ds[3 * i + 1]! % 100
    let r := ds[3 * i + 2]!
    let a :=
      if kind < 80 then (if b = 0 then 1 else 1 + r % b)
      else if kind < 95 then b + 1 + r % 100000
      else 0
    (b, a)

def exhaustiveInputs : List (Nat × Nat) :=
  (List.range 201).flatMap fun b => (List.range 201).map fun a => (b, a)

/-- Two outcomes are the same result. -/
def same : Except WithdrawError Nat → Except WithdrawError Nat → Bool
  | .ok x, .ok y => x == y
  | .error x, .error y => decide (x = y)
  | _, _ => false

def byExamples (f : Impl) : Option (Nat × Nat) :=
  (examples.find? fun (b, a, want) => !same (f b a) want).map fun (b, a, _) => (b, a)

def byProperty (f : Impl) : Option (Nat × Nat) :=
  propertyInputs.find? fun (b, a) => !holdsAt f b a

def byExhaustive (f : Impl) : Option (Nat × Nat) :=
  exhaustiveInputs.find? fun (b, a) => !holdsAt f b a

def byContract (f : Impl) (contract : Nat → Nat → Except WithdrawError Nat → Bool) :
    Option (Nat × Nat) :=
  workloadInputs.find? fun (b, a) => !contract b a (f b a)

def byDifferential (f reference : Impl) : Option (Nat × Nat) :=
  (propertyInputs ++ workloadInputs).find? fun (b, a) => !same (f b a) (reference b a)

end Withdraw
