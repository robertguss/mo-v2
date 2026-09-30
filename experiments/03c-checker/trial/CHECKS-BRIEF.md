# Brief for the check-writing session

**For:** a new Codex session in its own visible Herdr pane, separate from the
Codex session that reviews as oracle and from the finished prediction session.
**Written by** the lead, 30 Sep 2026, for the trial's phase 1, step 3
(`PLAN.md`, "How the trial runs"). Reviewed by Codex as oracle.

## Your job

Write, in Lean, the file that runs the trial's twenty-eight example runs and
checks them against the frozen predictions (`PLAN.md`, "How the trial runs",
step 3; `INTERFACE.md` sections 1 and 8). The predictions are the acceptance
criteria for the lead's encoding of the rule, so the lead and the worker who
wrote that encoding may not write or change these checks. That is why this is
your job.

You write the checks. You do not run the comparison. The run is the plan's step
4, done afterwards by the lead in a visible pane with Robert able to watch, and
every mismatch it shows is kept and classified. So your file must build without
printing any result, and must print its report only when its `main` is run.

## Read these as the source of truth

1. `CLAUDE.md` at the repo root: the working rules. Robert does not read code.
2. `experiments/03c-checker/trial/PLAN.md`: "The two meanings", "What the
   promises cover" and "How the trial runs", steps 3 and 4.
3. `experiments/03c-checker/trial/INTERFACE.md`: all of it, section 8 above all
   (D93: the interface is approved).
4. `experiments/03c-checker/trial/EXAMPLES.md`: the twenty programs, thirteen
   starting memories and twenty-eight runs (D92: the examples are approved).
5. `experiments/03c-checker/trial/PREDICTIONS.md`: the frozen predictions (D95:
   the predictions are approved and frozen): the table of answers and totals,
   and the timing claims on runs 9 to 11. Its derivations explain the numbers;
   they are not themselves checked.
6. `experiments/03c-checker/trial/RULE.md` (D91, with D97): only to understand
   what a timing claim refers to. Your checks test the predictions, not your own
   reading of the rule.
7. `experiments/03c-checker/trial/LOCK.md`: the fingerprints.
8. The lead's Lean, read-only:
   `experiments/03c-checker/trial/lean/Trial/*.lean`. "Names as built" below
   says where it differs from the names `INTERFACE.md` proposed.

Before you copy anything, check the fingerprints of `PREDICTIONS.md` and
`EXAMPLES.md` against `LOCK.md` (`shasum -a 256`). If one differs, stop and say
so.

## What you write

Only these, under `experiments/03c-checker/trial/lean/`:

| File                      | Contains                                                                                                        |
| ------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `Checks/Examples.lean`    | The twenty programs and thirteen starting memories, copied by you from `EXAMPLES.md`, and the twenty-eight runs |
| `Checks/Predictions.lean` | The frozen predictions, copied by you from `PREDICTIONS.md`: answer, three totals, and the timing claims        |
| `Checks/Run.lean`         | The checks, and a `main` that runs them all and prints the report                                               |
| `Checks.lean`             | The root file that imports the three                                                                            |

You copy the programs, memories and predictions yourself (`INTERFACE.md` section
1): a slip in a copy made by the lead could be hidden by the lead's own
encoding.

## What the checks do, for each of the twenty-eight runs

`INTERFACE.md` section 8, with the names as built:

1. Confirm the program is well-formed (`wellFormed`) and the starting memory
   valid (`validStart`).
2. Run the plain meaning (`runPlain`) and the counted meaning
   (`runCounted .approved`).
3. Compare the counted answer, read back with `readBack` from the final memory,
   with the predicted answer and with the plain meaning's answer.
4. Count allocations, reuses and frees **from memory's own record**
   (`Outcome.record`: `created`, `written`, `released`), never from the rule's
   log, and compare them with the predicted totals.
5. Confirm the rule's log (`Outcome.log`) agrees with memory's own record.
6. On runs 9, 10 and 11, compare each frozen timing claim with the snapshots
   (`Outcome.states`) and the record.
7. The misreport control: run `runCounted .misreportsReuse` on run 2 and confirm
   that the checks reject it on the counts. The control passes only if all of
   these hold: the run finishes with an answer (not refused, not failed while
   running); its answer reads back; that answer equals the predicted answer
   and the plain meaning's answer; and the comparison of the totals counted
   from memory's own record with the predicted totals fails. A refusal, a
   failure while running or an unreadable answer is a failed control, never a
   rejection. Report the control's results separately from the twenty-eight
   runs.

Also check on every run, because the plan's promises (c) and (d) name them and
the interface exposes what they need:

- at the end, the allocated cells are exactly those reachable from the answer
  and from the outside holders, and every holder count equals the holders the
  cell actually has (promise (d));
- every outside holder's list reads the same in every snapshot as at the start
  (the part of promise (c) about outside holders).

These two are checks of the promises on the examples, not predictions; report
them separately from the prediction comparisons.

## The report

`main` is declared at the top level of `Checks/Run.lean`, outside any
namespace, so that the command below finds it. Running `main` (from
`experiments/03c-checker/trial/lean/`:
`lake env lean --run Checks/Run.lean`) prints, for every run: the run number;
predicted and actual answer; predicted and actual allocations, reuses and frees;
the plain meaning's answer; whether the log agrees with the record; the promise
checks; and, on runs 9 to 11, each timing claim with what the snapshots show.
Each item is marked as matching or not. Then the misreport control, and whether
the checks rejected it. Then a count of mismatches.

- It runs every check on every run, even after a mismatch. It never stops at the
  first one.
- A failure of any kind (refused, failed while running, unreadable answer) is
  reported as what it is, never replaced by a default or counted as a match.
- Plain English column names; Robert reads this report.

## What you may not do

- Do not edit anything under `Trial/`, the Lake files, any `.md` file, or any
  file outside the four above.
- Do not change a prediction, round it, reinterpret it, or leave one out. If a
  prediction cannot be written as a check against what the interface exposes,
  stop (below).
- Do not run `main`, and put nothing in your files that prints or evaluates a
  comparison at build time (no `#eval`, `#guard`, `example` or `decide` over an
  example run). You may try your helper functions on small programs of your own
  that are not among P1 to P20, outside the repo.
- Do not ask the lead, the worker or the oracle how the encoding behaves on an
  example, and do not read their panes for it. Robert may talk to you directly.
- Do not commit or push. The lead commits your files exactly as you wrote them.

## Stop conditions

Stop and report in your pane as soon as one of these holds:

1. **Done:** the four files exist; `lake build Checks` succeeds from
   `experiments/03c-checker/trial/lean/` with no errors and no warnings and
   prints no result; every run, prediction and timing claim is in, and your
   report lists, for each, the check that covers it.
2. **A prediction or timing claim cannot be checked** against what the interface
   exposes, as written. Say which and why. Do not rewrite it.
3. **An example cannot be copied faithfully** into the language as built (for
   example, a starting memory the `Start` shape cannot hold). Say which.
4. **The lead's Lean does not keep an interface promise** your checks rely on.
   Say which.

In your report, also list anything in `PREDICTIONS.md` or `EXAMPLES.md` you had
to read closely, and the words that settled it.

## Names as built

Where the lead's Lean differs from, or adds to, the names `INTERFACE.md`
proposed (section 9 allows this; each promise still holds, and this list is
shown to Robert):

All of them are in namespace `Trial`, in the files named.

- **Programs** (`Trial/Language.lean`): `Expr` with one constructor per row
  of `RULE.md` section 2: `num`, `add`, `sub`, `eq`, `lt`, `le`, `nil`,
  `cons` (item, rest), `letE` (name, bound expression, body), `ifE`
  (condition, then, else), `matchE` (matched expression, empty-list branch,
  item name, rest name, cell branch) and `var`. Names are `String`s. `Kind`
  is `number`, `list` or `bool` (true or false). `wellFormed` as proposed.
- **Plain meaning** (`Trial/Plain.lean`): `PlainValue` is `num`, `bool` or
  `list` (a `List Int`); `runPlain` as proposed. It refuses a program that
  is not well-formed for the kinds of the inputs it is given.
- **Starting memories** (`Trial/Memory.lean`): an address is a `Nat`
  (`Addr`). A list value is `Option Addr`: `none` is the empty list.
  `RawValue` is `num`, `bool` or `list`. `Start` has `cells` (each a
  `StartCell` with `addr`, `item`, `link`, `count`), `inputs` (in order,
  each a name and a `RawValue`) and `outside` (each an `Option Addr`).
  `validStart` as proposed. EXAMPLES.md's labels `c1`, `c2`, ... become
  addresses of your choosing; no prediction depends on an address.
- **Running** (`Trial/Broken.lean`, `Trial/Counted.lean`):
  `runCounted : Rule → Expr → Start → Outcome`, with `Rule` as proposed
  (`.approved`, `.misreportsReuse`, `.reusesShared`, `.forgetsRest`,
  `.freesHeld`, `.neverReuses`). `Outcome` has `result` (`.answer raw`,
  `.refused why`, `.failedRunning why`), `memory`, `log`, `record` and
  `states`, as proposed.
- **Added, not in `INTERFACE.md`'s list:** `Memory` (`cells`, the counter
  `next` and `record`), `Start.toMemory` (the memory a run starts from), `Cell` (`addr`, `item`, `link`, `count`, `status`: `.live` or
  `.setAside`); `LogEvent` (the rule's log: `.alloc`, `.reuse`, `.free`,
  each with an address); `MemEvent` (memory's own record: `.created`,
  `.written`, `.released`, each with an address). A freed cell is no longer
  in `Memory.cells`.
- **Snapshots:** `Snapshot` has `kind` (a `StepKind`), `memory` (the cells),
  `bindings` (every binding in scope and every binding still holding a
  holder; each a `Binding` with a unique `id`, `name`, `value` and
  `status`: `.holding`, `.givenUp`, `.movedOn` or `.noHolder`), `pending`
  (the intermediate results, newest first), `outside`, and `setAside` (each
  a branch id with an address, newest first). `StepKind` is one of `start`,
  `branchChosen`, `newHolder`, `holderMoved`, `nameBound`, `holderGivenUp`,
  `cellFreed`, `matchStep4Done`, `newCellBuilt`, `branchValueWorkedOut`,
  `branchValueHandedOn`, `holderForgotten` (only in the copy that forgets the
  rest) and `end`. The two moments of the timing claims are
  `branchValueWorkedOut` (before the branch's unused set-aside cells are freed)
  and `branchValueHandedOn` (after). These two snapshots do not name which
  `match`'s branch finished; branches finish innermost first, and the
  set-aside cells carry their branch ids. If that is not enough to check a
  timing claim as written, that is stop condition 2.
- **Added by D98, after your stop** (Robert's decision; `INTERFACE.md` section 6):
  `Snapshot.branchValue : Option RawValue` is `some w` in the
  `branchValueWorkedOut` and `branchValueHandedOn` snapshots, where `w` is the
  value the finishing `match` branch hands on, and `none` in every other
  snapshot; it holds nothing and is not in `pending`. `StepKind.branchStarts`
  is a snapshot taken each time a chosen branch of an `if` or `match` is about
  to run, after the names it will not use have been given up (for a `match`'s
  cell branch, after step 5), immediately before the branch's expression runs.
- **Reading back:** `readBack : Memory → RawValue → Except String PlainValue`
  as proposed. To read a list in a snapshot, build a `Memory` from the
  snapshot's cells and use `readList` or `readBack`.
  `readList : Memory → Nat → Option Addr → Except String (List Int)` takes a
  bound on the number of steps; `readBack` uses the number of cells.
