# Brief: builder A, Experiment 2

You are builder A. Work only in `experiments/02-withdraw` of the mo-v2 repo (a
Lean 4 Lake project; Lean 4.34.0 via elan). Read `CLAUDE.md` at the repo root
first.

## Read

- `Withdraw/Spec.lean`: the locked spec. Four promises about
  `withdraw balance amount`, in whole cents, and six examples.
- `Withdraw/AcceptA.lean`: the locked acceptance file for your work.

Do **not** read `Withdraw/Harness.lean`, `Withdraw/ImplB.lean`, anything under
`Withdraw/Mutants/`, or `briefs/` other than this file.

## Write

Exactly one file, `Withdraw/ImplA.lean`, which imports `Withdraw.Spec` and
defines, in `namespace Withdraw.A`:

1. `def withdraw : Impl`: the function.
2. `def contract : Nat → Nat → Except WithdrawError Nat → Bool`: the runtime
   contract you would attach to `withdraw` (its `requires`/`ensures` checks),
   given the balance, the amount and the result. It returns `false` when the
   result breaks the contract. Write it as you would a real contract in
   production code.
3. `theorem withdraw_correct : Correct withdraw`: the proof.

## Rules

- Don't edit any other file. `Spec.lean`, `Oracle.lean`, `Harness.lean` and both
  `Accept*.lean` files are locked, and their hashes are recorded.
- No `sorry`, `admit`, `axiom`, `native_decide`, `unsafe`, `implemented_by` or
  `set_option`.
- Done: `lake build Withdraw.AcceptA` succeeds, and its `#print axioms` lists
  nothing beyond `propext`, `Classical.choice` and `Quot.sound`.
- Stop condition: if the proof won't go through after about 45 minutes of work,
  stop and say exactly where you are stuck. Don't weaken anything.
- No git operations. Never use `tr` in shell commands; use python3.

When done, print a short summary: build result, `#print axioms` output, and how
long it took.
