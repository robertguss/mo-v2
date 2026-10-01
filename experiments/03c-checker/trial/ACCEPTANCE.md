# The trial's acceptance: what the proof must show, and how it is checked

**Status: approved and locked, 30 Sep 2026 (D100: the promises, this file and
the builder's brief are approved and locked; fingerprints in `LOCK.md`).**
Written by the lead for the trial's phase 1, step 5 (`PLAN.md`, "How the trial
runs"). Reviewed by Codex as oracle. Approving it does not start phase 2 or
choose who builds the proof: Robert decides both separately (`PLAN.md` step 6).

The four promises below are the plain-English form of the Lean statements in
`lean/Promises.lean`. When this file is approved, it is locked with them
(`LOCK.md`). A builder's proof is accepted only if it proves exactly those
statements and passes every check in "How a proof is checked".

**Not for the worker.** The examples table below holds the frozen predicted
answers and totals. The worker who wrote the trial's Lean has not seen them and
is not shown this file.

## What is being promised

The promises are `PLAN.md`'s question Q2. They cover **every** program of the
trial language and **every** starting memory, not only the twenty-eight
examples, with two conditions:

- **The program is well-formed.** Every name it uses is bound, every part has
  the right kind of value (numbers where numbers are expected, lists where lists
  are, true or false where a condition is), and the rules of `RULE.md` section 2
  hold (for example, a `match`'s two names are spelled differently and both
  branches give the same kind of value, D89). This is checked from the text
  alone, before anything runs.
- **The starting memory is valid.** Each input has the kind the program expects;
  finitely many cells, no two at the same address, and no loops; nothing points
  at a cell that does not exist; every cell is reachable from an input or an
  outside holder (no garbage at the start); and every cell's holder count is
  exactly the number of holders it has. Sharing is allowed.

In Lean both conditions are one test, `validStart`, which the trial's Lean
already has and which was checked on the examples (run 1). Each promise is about
running the program under the approved rule (D91), `runCounted .approved`.

### (a) The run finishes

**In plain English:** the counted run always reaches an answer. It is never
refused (the conditions above rule that out), it never gets stuck on an
operation it cannot perform, such as using a cell that was already freed, and
the answer can always be read back from memory.

**Why it matters:** a rule that gets stuck on some program has a bug even if it
never gives a wrong answer.

Lean: `PromiseA`, built from `Finishes`.

### (b) The same answer as the plain meaning

**In plain English:** the answer the counted run gives, read back from memory,
is exactly the answer the plain meaning gives (the program run with ordinary
lists and no memory bookkeeping), for the same inputs.

**Why it matters:** reusing cells in place must never change what a program
computes. This is the promise that stops a rule from being "safe" by doing
nothing useful: an answer is required and it must be the right one.

Lean: `PromiseB`, built from `SameAnswer`.

### (c) No list anyone else can see changes

**In plain English:** at every moment the run records, two kinds of list stay
exactly as they were:

- **(c1)** the outside holders (for example a caller that keeps the old version)
  are the same ones, pointing at the same first cells, as at the start; and
  every list they keep can be read back, and reads the same as in the starting
  memory;
- **(c2)** every name in the program that will still be used can be read back,
  and reads the same list it had when it first held it; the list it had then
  must itself have been readable.

**Why it matters:** this is the heart of "invisible in-place updates" (D26):
reuse is allowed only when nobody else can notice.

Lean: `PromiseC`, built from `NoVisibleChange` (`OutsideUnchanged` for c1,
`NamesUnchanged` for c2).

### (d) Nothing leaks

**In plain English:** when the run ends:

- no cell is left set aside for reuse, and no two cells share an address;
- following the links from the answer and from each outside holder never runs
  into a missing cell, a set-aside cell or a loop;
- memory holds exactly the cells those walks reach, no more and no fewer;
- every cell's holder count is exactly its number of holders: the answer (if it
  is that cell), each outside holder that points at it, and each live cell whose
  link points at it.

**Why it matters:** a rule that forgets to free cells, or frees too many, or
keeps wrong counts, would fail here even when its answer is right.

Lean: `PromiseD`, built from `NoLeak`.

## What the promises do not say

These limits are part of what is approved.

- **"Every moment" means every moment the run records.** The run takes a
  snapshot at fixed points, and promise (c) is proven about those snapshots.
  That they catch every change to memory is a reading of the locked code by the
  lead and by Codex, not something the proof shows: after each operation that
  changes memory, a snapshot is taken before the next one. The table lists each
  of those operations in `lean/Trial/Counted.lean` under the approved rule.

  | Operation that changes memory                      | Line | Snapshot that follows                      |
  | -------------------------------------------------- | ---- | ------------------------------------------ |
  | A new holder raises a count (`addHolder`)          | 255  | 522 or 549, at the two places that call it |
  | A holder given up lowers a count (`giveUp`)        | 270  | 271                                        |
  | A cell freed (`giveUp`)                            | 277  | 280                                        |
  | A set-aside cell written in place (`buildCell`)    | 350  | 362                                        |
  | A fresh cell created (`buildCell`)                 | 354  | 362                                        |
  | An unused set-aside cell freed (`disposeSetAside`) | 380  | 381                                        |
  | A cell set aside (`match`)                         | 502  | 508                                        |

  Two more sites run only in the misreport control copy: a release at line 342,
  followed by the snapshot at 343, and a fresh cell created at 345, followed by
  the snapshot at 362. A change to a count does not change what a list reads as.

- **What (c) covers.** It covers lists kept by outside holders and by names that
  will still be used, including every cell further down those lists. It does not
  separately cover a list the run has worked out and not yet handed on (an
  "intermediate result"), nor a list reachable only through some other holder.
  Promise (b) still covers the final answer.
- **(c2) relies on the run's own account of which names will still be used.** A
  name is counted as still in use while the run marks it as holding its holder.
  Codex checked the locked code for a way to mark a name wrongly that would hide
  a change and still let the run finish, and found none. That is a reading, not
  a proof.
- **(d) is about memory alone.** It checks the cells, their counts and what the
  answer and the outside holders reach. It does not look at the run's names or
  intermediate results at the end.
- **The proof is about the Lean, not about the English rule.** That the Lean
  follows the approved English rule (D91) rests on run 1 (`RUN-1.md`): the Lean
  agreed with predictions written separately from the English on all
  twenty-eight runs. That is evidence on those runs, not a proof for every
  program.
- **The trial language only.** Nothing about recursion, function calls, runs
  that never finish, an in-place checker, speed, or the Rust helper (`PLAN.md`,
  "What the trial will not tell us").

## The examples

These twenty-eight runs are the approved examples (D92) with the answers and
totals Codex predicted before the rule was encoded (D95, frozen). Run 1 of the
Lean matched every one of them (`RUN-1.md`), with the totals counted from
memory's own record of what it did. The builder cannot change them: the
programs, the Lean that runs them and the file that checks them are all locked.
Programs and starting memories are written out in `EXAMPLES.md`.

The examples do what a safety promise alone cannot (Experiment 1's lesson, D15):
a rule that never reused any cell would, by the lead's reasoning (argued, not
proven), keep promises (a) to (d), but it would make new cells where these
totals say it reuses one, and the checks reject it.

| Run | Program                                                              | Starting memory | Number inputs | Answer                  | Allocations | Reuses | Frees |
| --- | -------------------------------------------------------------------- | --------------- | ------------- | ----------------------- | ----------- | ------ | ----- |
| 1   | P1, add one to the first item                                        | M-three         |               | `[2, 2, 3]`             | 0           | 1      | 0     |
| 2   | P1, add one to the first item                                        | M-one           |               | `[2]`                   | 0           | 1      | 0     |
| 3   | P1, add one to the first item                                        | M-empty         |               | `[]`                    | 0           | 0      | 0     |
| 4   | P1, add one to the first item                                        | M-large         |               | `[9223372036854775808]` | 0           | 1      | 0     |
| 5   | P1, add one to the first item                                        | M-kept          |               | `[2, 2, 3]`             | 1           | 0      | 0     |
| 6   | P2, swap the first two items                                         | M-three         |               | `[2, 1, 3]`             | 0           | 2      | 0     |
| 7   | P2, swap the first two items                                         | M-one           |               | `[1]`                   | 0           | 1      | 0     |
| 8   | P2, swap the first two items                                         | M-kept-second   |               | `[2, 1, 3]`             | 1           | 1      | 0     |
| 9   | P3, drop the first item                                              | M-three         |               | `[2, 3]`                | 0           | 0      | 1     |
| 10  | P4, total the first two items                                        | M-four-five     |               | `9`                     | 0           | 0      | 2     |
| 11  | P5, the first item                                                   | M-seven         |               | `7`                     | 0           | 0      | 3     |
| 12  | P6, put an item on the front                                         | M-two           | `n = 0`       | `[0, 1, 2]`             | 1           | 0      | 0     |
| 13  | P7, duplicate the first item                                         | M-two           |               | `[1, 1, 2]`             | 1           | 1      | 0     |
| 14  | P8, add one to the first item, then use the old list again           | M-two           |               | `[1, 2, 2]`             | 1           | 1      | 0     |
| 15  | P9, add the first items of two lists                                 | M-shared-tail   |               | `[3, 3, 4]`             | 0           | 1      | 1     |
| 16  | P10, add one to the first item if it is below `n`, otherwise drop it | M-two           | `n = 5`       | `[2, 2]`                | 0           | 1      | 0     |
| 17  | P10, add one to the first item if it is below `n`, otherwise drop it | M-two           | `n = 0`       | `[2]`                   | 0           | 0      | 1     |
| 18  | P11, the same with `<=`                                              | M-two           | `n = 1`       | `[2, 2]`                | 0           | 1      | 0     |
| 19  | P12, the same with `==`                                              | M-two           | `n = 1`       | `[2, 2]`                | 0           | 1      | 0     |
| 20  | P12, the same with `==`                                              | M-two           | `n = 7`       | `[2]`                   | 0           | 0      | 1     |
| 21  | P13, a second name used only in the empty-list branch                | M-same-list     |               | `[2, 2]`                | 0           | 1      | 0     |
| 22  | P14, a second name used only in one branch of an `if`                | M-same-list     | `n = 1`       | `[2, 2]`                | 0           | 1      | 0     |
| 23  | P15, nested matches with a later build                               | M-three         |               | `[1, 3, 3]`             | 0           | 2      | 0     |
| 24  | P16, a name that reuses a spelling                                   | M-two           |               | `[2, 2]`                | 0           | 1      | 0     |
| 25  | P17, is the first item negative?                                     | M-minus         |               | `true`                  | 0           | 0      | 2     |
| 26  | P18, a cell whose two parts both use the same list                   | M-two           |               | `[1, 2, 2]`             | 1           | 1      | 0     |
| 27  | P19, an input that is never used                                     | M-two           | `n = 5`       | `[5]`                   | 1           | 0      | 2     |
| 28  | P20, subtract five from the first item                               | M-just-two      |               | `[-3]`                  | 0           | 1      | 0     |

**The control.** The misreport copy of the rule (it frees a cell and builds a
replacement but logs a reuse), run on run 2, gives the right answer, `[2]`, and
the checks reject it on its totals: memory's record shows 1 allocation, 0 reuses
and 1 free, where 0, 1 and 0 are predicted.

## How a proof is checked

The builder writes only `lean/Proofs.lean` (replacing each `sorry` of the stub
with a proof) and new files under `lean/Proofs/`. Everything else is locked
(`LOCK.md`). The work is **accepted** only if every check below passes. The lead
and Codex each run them and write their findings before seeing the other's
(`PLAN.md`, "Checking the builder's work").

1. **Nothing locked changed.** Every locked file matches its fingerprint in
   `LOCK.md`, including `lean/Promises.lean`, `lean/Acceptance.lean`,
   `lean/lakefile.toml`, `lean/lean-toolchain` and `lean/lake-manifest.json`.
2. **Only allowed files changed.** Compared with the commit that holds the lock,
   the only changed or new paths are `lean/Proofs.lean` and files under
   `lean/Proofs/`, counting untracked files.
3. **Nothing in the builder's files changes what the checks mean.** None of
   these appear in them: `sorry`, `admit`, `axiom`, `partial`, `unsafe`,
   `opaque`, `native_decide`, `implemented_by`, `extern`, `csimp`; anything that
   changes how Lean reads later text (`notation`, `macro`, `macro_rules`,
   `syntax`, `elab`, `infix`, `prefix`, `postfix`); attributes added to a locked
   definition; `export` or `open ... renaming` into `Trial`; `set_option` except
   for one declaration or one tactic, written with `in`, and
   `debug.skipKernelTC` anywhere. The lead and Codex also read the builder's
   files for anything else that could change what the locked statements mean,
   beyond this list.
4. **A clean rebuild.** In a fresh copy with no reused build files,
   `lake build Trial Checks Promises Proofs Acceptance` succeeds with no errors
   and no warnings.
5. **The right statements.** `lean/Acceptance.lean` restates the four promises
   with every name written in full, so it compiles only if the builder's four
   theorems prove exactly the locked statements; the type of each accepted
   theorem is printed and compared with the locked statement.
6. **Nothing assumed.** The axioms printed by `lean/Acceptance.lean` for each of
   the four are no more than `propext`, `Classical.choice` and `Quot.sound`,
   Lean's standard ones. `sorryAx`, or anything else, means not accepted.
7. **Lean's kernel agrees.** `lake env leanchecker --fresh Acceptance`, which
   re-checks every proof from scratch, succeeds.
8. **The examples still pass.** The checks of run 1
   (`lake env lean --run Checks/Run.lean`) give the same report as
   `results/run-1.txt`.
9. **The promises rule out the unsafe copies.** For each of the three unsafe
   copies of the rule (it reuses a cell someone else holds; it forgets to give
   up the rest of a freed cell; it frees a cell that still has a holder), the
   lead and Codex each show a well-formed program and valid starting memory on
   which that copy breaks a named promise, by running it and evaluating the
   promise on the run. And in a throwaway copy where the approved rule is
   replaced by that copy (see "Running a broken copy" below), the builder's
   proofs must fail to build: a clean rebuild of `Acceptance` fails. A failed
   build alone is not taken as evidence, since a proof can fail for incidental
   reasons; but if the proofs still build against a copy with a shown
   counterexample, the promises are not about the rule that runs, and the lock
   has failed.
10. **The examples rule out the copy that never reuses.** In a throwaway copy
    where the approved rule is replaced by it (see below), the checks of run 1
    (`Checks/Run.lean`) report mismatches on the totals. That it would also keep
    promises (a) to (d) is argued, not proven (`PLAN.md`, "Checking the
    builder's work").

Checks 9 and 10 run the broken copies, which `INTERFACE.md` section 7 keeps for
after the proof. Robert then sees the result in plain English, and the lead
writes `RESULT.md`.

**Running a broken copy.** In a fresh copy of the project, outside the
repository, change one line only: in `lean/Trial/Broken.lean`, the `.approved`
case of `Rule.variant` is given the switches of the chosen copy (the same record
its own case already uses). `Variant.approved` itself and the other named copies
stay as they are. Everything that names the approved rule, the promises, the
proofs and the checks alike, then runs that copy instead.

**Partial work** is reported at each check-in (D77: two-hour check-ins, resuming
only on Robert's go-ahead) in three separate lists: promises proven, proofs
unfinished, and any concrete program that breaks a promise. Checks 1 to 10 are
for the finished work; while proofs are unfinished, a single promise counts as
proven when:

- checks 1, 2, 5 and 7 pass as written;
- check 3 passes except that `sorry` may remain in unfinished proofs, each named
  in the report, and check 4 passes except for their "declaration uses `sorry`"
  warnings;
- the axioms printed for that promise's accepted theorem are no more than
  `propext`, `Classical.choice` and `Quot.sound`. This also shows it does not
  rely on any unfinished proof, since those bring in `sorryAx`.

"Proven" means Lean checked the exact promise with nothing unfinished and
nothing extra assumed; progress is counted in promises proven, not helper
lemmas. An unfinished proof is inconclusive: it does not show a promise is
false.
