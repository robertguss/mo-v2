# Code review brief

You are reviewing implementations of one small function for correctness.
Work only in this folder. Do not look anywhere else on the machine.

`Spec.lean` defines `withdraw balance amount` (whole cents, natural numbers)
and four promises it must keep:

1. Correct result: a successful withdrawal leaves exactly the old balance
   minus the amount.
2. Succeeds when it should: if the amount is more than zero and no more than
   the balance, it succeeds.
3. Fails when it should: if the amount is more than the balance, it fails with
   insufficient funds.
4. Zero is invalid: a withdrawal of zero fails with invalid amount.

The files `V01.lean` to `V11.lean` each contain one implementation, written in
Lean 4. Some may be correct and some may have bugs; there is no fixed number of
either. Review each one by reading it. Do not run, compile or execute any code.

Write your verdicts to `verdict-<your model name>.md`, one line per version:

    V01: CORRECT
    V02: BUGGY - <which promise breaks, and an input (balance, amount) that shows it>

Be precise: mark a version BUGGY only if you can name an input where it breaks
a promise.
