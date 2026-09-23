# Brief: bug planter, Experiment 2

You plant realistic bugs so we can measure which verification methods catch
them. Work only in `experiments/02-withdraw` of the mo-v2 repo (a Lean 4 Lake
project). Read `CLAUDE.md` at the repo root first.

## Read

- `Withdraw/Spec.lean`: the locked spec (four promises, six examples).
- `Withdraw/ImplA.lean`: a correct `withdraw`. Your bugs are changes to it.

Do **not** read `Withdraw/Harness.lean`, `Withdraw/ImplB.lean`, anything in
`briefs/` other than this file, or `Main.lean`. Don't try to learn which inputs
or methods will be used to hunt your bugs.

## Write

Ten files, `Withdraw/Mutants/M01.lean` to `Withdraw/Mutants/M10.lean`. Each one
imports `Withdraw.Spec` and defines, in `namespace Withdraw.Mutants.M01` (and so
on), `def withdraw : Impl`: a copy of builder A's `withdraw` with **one**
realistic bug. It should be the kind of mistake an AI agent or a programmer
might really make. No comments or names that hint at the bug. No proofs.

Aim for a spread of difficulty:

- a few bugs that show up on ordinary inputs;
- a few on edge cases (zero, exact balance, off by one);
- a few that show up only on rare or large inputs, of the kind that slips into
  real code: boundaries such as 2^31 or 2^32, special-casing of particular
  values, or thresholds.

Every mutant must break at least one of the four promises for at least one
input. Check this yourself with `#eval` in a scratch file outside the repo
(under
`/private/tmp/claude-501/-Users-robertguss-Projects-startups-mo-lang/32525768-e4a3-4c89-a101-9192fdc62c23/scratchpad`).

Then write `Withdraw/Mutants/KEY.md`: for each mutant, one line with the bug in
plain English, which promise it breaks, and one input `(balance, amount)` that
triggers it.

## Rules

- Don't edit any other file.
- Done: `lake build Withdraw.Mutants.M01` through `M10` all succeed.
- No git operations. Never use `tr` in shell commands; use python3.

When done, print a one-line summary per mutant.
