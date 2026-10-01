# Brief for the phase-2 builder: prove the four promises

**Status: approved and locked, 30 Sep 2026 (D100: the promises, the acceptance
file and this brief are approved and locked; fingerprints in `LOCK.md`).**
Written by the lead for the trial's phase 1, step 5 (`PLAN.md`, "How the trial
runs"). Reviewed by Codex as oracle. Approving it does not start phase 2 and
does not choose the builder: Robert decides both (`PLAN.md` step 6).

**For:** the builder, a coding-agent session in its own visible Herdr pane (D14:
builders work where Robert can see them), chosen by Robert, started by the lead
only after Robert says phase 2 starts.

**Before this brief is handed over.** Choosing a builder does not lift any
restriction that session is already under. The worker that wrote the trial's
Lean (D96: code is written by a Sonnet worker the lead directs) has been kept
away from the predictions, which `ACCEPTANCE.md` holds, and from `lean/Checks/`.
If Robert chooses that worker, the lead first puts to him whether those
restrictions are lifted, records his decision, and only then gives it this brief
or those files.

## Your job

Prove, in Lean, the four promises stated in `lean/Promises.lean`, by replacing
each `sorry` in `lean/Proofs.lean` with a proof:

| Theorem          | States     | In plain English (`ACCEPTANCE.md`)       |
| ---------------- | ---------- | ---------------------------------------- |
| `Trial.promiseA` | `PromiseA` | (a) the run finishes                     |
| `Trial.promiseB` | `PromiseB` | (b) the same answer as the plain meaning |
| `Trial.promiseC` | `PromiseC` | (c) no list anyone else can see changes  |
| `Trial.promiseD` | `PromiseD` | (d) nothing leaks                        |

Each is about every well-formed program and every valid starting memory, run
under the approved rule (`runCounted .approved`). You prove what is stated; you
do not change what is stated.

## Read these as the source of truth

1. `CLAUDE.md` at the repo root: the working rules. Robert does not read code;
   your reports are read by him and by the lead.
2. `experiments/03c-checker/trial/ACCEPTANCE.md`: the promises in plain English,
   their limits, and exactly how your work will be checked.
3. `experiments/03c-checker/trial/lean/Promises.lean`: the statements.
4. `experiments/03c-checker/trial/lean/Trial/`: the language, the plain meaning,
   counted memory and the counted meaning your proofs are about.
5. `experiments/03c-checker/trial/RULE.md`: the approved rule in English, which
   the Lean follows; useful for understanding why an invariant should hold.
6. `experiments/03c-checker/trial/PLAN.md`: "What the trial asks" (Q2),
   "Checking the builder's work" and "Stop conditions".

## What you may write

Only `experiments/03c-checker/trial/lean/Proofs.lean` and new files under
`experiments/03c-checker/trial/lean/Proofs/`. In `Proofs.lean` the four theorem
statements stay exactly as they are; you replace their bodies and may add
imports of your own `Proofs/` files. Your own definitions and lemmas go in a
namespace of your own (for example `Trial.Proofs`), so that no name of yours can
be mistaken for a locked one.

Everything else is locked (`LOCK.md`): `Trial/`, `Checks/`, `Promises.lean`,
`Acceptance.lean`, the root files, `lakefile.toml`, `lean-toolchain`,
`lake-manifest.json`, and every `.md` file. Do not create, edit or delete
anything else, in the trial or anywhere in the repository.

## Rules for the Lean

- **Lean core only**, on the pinned toolchain (Lean 4.34.0, `lean-toolchain`).
  No Mathlib, no Batteries, no other dependency.
- **Nothing assumed, nothing skipped.** None of these may remain in your
  finished files: `sorry`, `admit`, `axiom`, `partial`, `unsafe`, `opaque`,
  `native_decide`, `implemented_by`, `extern`, `csimp`.
- **Nothing that changes how Lean reads the locked files or the acceptance
  file:** no `notation`, `macro`, `macro_rules`, `syntax`, `elab`, `infix`,
  `prefix`, `postfix`; no attribute added to a locked definition
  (`attribute [simp] runCounted` and the like); no `export` or
  `open ... renaming` into `Trial`. You may mark your own lemmas `@[simp]`, and
  name locked definitions in a tactic (`simp [runCounted]`, `unfold`).
- **`set_option`** only for one declaration or one tactic, with `in` (for
  example `set_option maxHeartbeats 400000 in theorem ...`), and never
  `debug.skipKernelTC` or any option that weakens the kernel's checking.
- Your finished work must build cleanly:
  `lake build Trial Checks Promises Proofs Acceptance` in
  `experiments/03c-checker/trial/lean/`, from an empty `.lake`, with no errors
  and no warnings.
- Run programs only under the approved rule. The broken copies of the rule are
  for the lead's and Codex's checks after the proof (`ACCEPTANCE.md`, checks 9
  and 10).

To see what a promise means on a concrete run, you may evaluate it: each per-run
promise (`Finishes`, `SameAnswer`, `NoVisibleChange`, `NoLeak`) is decidable, so
`#eval decide (NoLeak s (runCounted .approved e s))` works on a program and
starting memory of your own. Keep such experiments outside the repository, never
in it.

## How your work is checked

Exactly as `ACCEPTANCE.md` says, "How a proof is checked", checks 1 to 10, by
the lead and by Codex, each writing their findings before seeing the other's.
You build your work and read Lean's messages as often as you like while you work
(including `lake build Trial Checks Promises Proofs Acceptance` and the axioms
it prints); that is development, not acceptance. You do not write or change any
of the checks, and you do not run the broken copies of the rule. Whether the
work is accepted is decided only by the lead's and Codex's independent run of
checks 1 to 10; a build that passes while a check fails is not accepted.

## The clock and check-ins (D77)

Robert's stop rule for this work (D77: two-hour check-ins, resuming only on his
go-ahead):

- Each work interval is 2 hours of elapsed time. The first starts when the lead
  tells you phase 2 has started and you have the locked files and a working
  setup; each later one starts when Robert explicitly says to continue.
- The lead keeps the clock, and records working time and waiting time
  separately, and tells you when an interval ends. Stop then, write your report
  (below), and wait. No answer means you stay stopped. Restarting your session
  does not reset an interval.
- Robert may change the interval at a check-in.

## Stop conditions

Stop and report as soon as one of these holds:

1. **Ready for checking:** all four theorems are proven, with nothing left from
   the list in "Rules for the Lean", and the build is clean. This submits the
   work for the lead's and Codex's checks; phase 2 is complete only when those
   checks are done and the result is written up.
2. **Check-in:** the interval has ended.
3. **A promise is false:** you find a concrete well-formed program and valid
   starting memory on which a promise does not hold under the approved rule.
   Report the program, the memory, which promise, and the evaluations that show
   it: `validStart` succeeding on them, and `#eval decide ...` on the promise
   giving `false`. Do not try to work around it.
4. **The spec is wrong:** a locked file (a statement in `Promises.lean`, or a
   definition in `Trial/`) is mistaken as written, for a specific reason you can
   show: for example, a statement that says something other than its
   plain-English promise in `ACCEPTANCE.md`, with the words and the Lean side by
   side. Report what, why and the evidence. A proof that is hard, a strategy
   that failed, tactics that ran out or an invariant not yet found is not this
   condition: it is unfinished work, reported at the check-in. Only Robert can
   approve a change to a locked file, followed by a new lock.
5. **Setup blocked:** Lean or Lake cannot run as needed.

Do not commit or push. The lead commits after the checks.

## Your report

At every stop, in your pane, three separate lists (D75: proven, unfinished and
counterexamples are always kept apart):

1. **Proven:** each of the four promises Lean has checked in full, with nothing
   unfinished and nothing assumed. Progress is counted in these four, not in
   helper lemmas.
2. **Unfinished:** each promise not yet proven, the `sorry`s that remain (file
   and line), and what you were trying.
3. **Counterexamples:** any concrete program and memory that break a promise, as
   in stop condition 3, or "none".

Then: the files you wrote; the main invariants or lemmas your proofs rest on, in
a sentence each of plain English; and anything in the locked files you had to
read closely, with the words that settled it. "Proven" in a report is what you
claim; the lead marks which claims it has checked itself.

## Background

`PLAN.md` ("Reference points") names the closest published work: FP² (Lorenzen,
Leijen and Swierstra, ICFP 2023), whose Theorem 6 proves on paper that a counted
memory with reuse stays correct for well-formed programs (counts always right,
nothing released early, no garbage at the end). Q2 is close to it, for a smaller
language. The shape of your proof is yours to choose.
