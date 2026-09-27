# Experiment 3c trial: the reuse rule on a tiny language

**Status: draft proposal, 27 Sep 2026.** Written by the lead; its outline was
reviewed by Codex before drafting (its findings are at the end). Nothing about
the trial is decided. The first question for Robert is the trial's scope (see
"Scope: the options").

What already binds it:

- **D26** (Mo is pure; the compiler may update a value in place when nothing
  else holds it, and a writer can demand in-place updating, which the checker
  must prove or refuse).
- **D47** (Lean's role is proving the in-place rules correct).
- **D62** (whether Mo's checker enforces the demand, shown by a proof, and
  whether useful programs are accepted, shown by examples, are two separate
  checks).
- The 3c decisions: **D72** (two slices on the same small list programs),
  **D73** (the promise: a demanded call makes no new list cells, freeing
  allowed), **D74** (one fixed reuse-and-release rule, written by the lead and
  approved by Robert, decides where cells are reused and released) and **D75**
  (slice 1 first proves that rule correct, and stops for checking, before any
  checker is built).

## Why a trial

On 24 Sep Robert proposed a much smaller trial before any full 3c build, to
learn quickly and then decide next steps. The full 3c plan is
[`../PLAN.md`](../PLAN.md). The trial takes the smallest piece of it that is
still real: the reuse rule on a language without function calls. It is roughly
the first stage of slice 1 (proving the rule correct) on a smaller language.

## What the trial asks

Two terms used throughout. A program's **plain meaning** is the answer it
computes. Its **counted meaning** runs the same program with memory made of list
cells, keeping track of who holds each cell and logging every new cell, every
reuse and every free. Both are described under "The two meanings".

**Q1. The rule, on examples.** Can the lead write the reuse rule exactly, as a
counted meaning that runs, so that on approved examples it gives the plain
meaning's answers, makes exactly the predicted numbers of allocations, reuses
and frees, and leaves every list someone else keeps unchanged?

- Supported: every example matches predictions that Codex wrote and Robert
  approved before the rule was encoded.
- Rejected: a mismatch traced to the rule itself, where the approved English
  rule does something unsafe or something Robert did not intend.
- Reported as what they are: a wrong prediction, or a wrong encoding (the Lean
  differs from the approved English). The failed run and the original prediction
  are kept, and nothing is changed without Robert's decision.

**Q2. The proof.** Can a builder prove in Lean that, for every well-formed
program and every valid starting memory (both defined under "What the promises
cover"):

- (a) the counted run finishes, including all its freeing, and never gets stuck;
- (b) its answer, read back from memory, equals the plain meaning's answer;
- (c) at no point during the run does a list someone else can still see change:
  lists kept by outside holders keep their starting contents, and a name inside
  the program keeps the list it was given for as long as it will still be used;
- (d) nothing leaks: at the end, the cells still allocated are exactly those
  reachable from the answer and from the outside holders, and every holder count
  is right.

Supported: all four proven, and the proof checked (see "Checking the builder's
work"). Rejected: a concrete well-formed program and valid memory that break one
of them. Inconclusive: a proof unfinished when the builder's stop condition is
reached; that does not show the promise is false.

**Q3. What it teaches for the full 3c** (observational): the effort observed for
this trial, where the spec needed changing and why, and whether the form of the
counted meaning is a good base for 3c's shared parts.

## Scope: the options (Robert's first question)

- **T0. No trial.** Go straight to the full 3c. Listed for completeness; Robert
  proposed the trial.
- **T1. The rule on examples only, no proof** (Q1 alone). The fastest. It shows
  whether the rule can be written exactly and does what was meant on the chosen
  examples, and says nothing about programs outside them.
- **T2. The rule on examples, then a builder's proof** (Q1, then Q2). The lead's
  and Codex's earlier proposal. It adds a proof that the rule is right for every
  well-formed program of the trial's language.
- **T3. T2 plus a small in-place checker** for a demanded program, with its
  proof. It could test the checker's usefulness on operations over the first few
  items (swap the first two, drop the first), but not on traversals that walk
  the whole list (add one to every item, reverse), which need recursion and are
  where the full 3c checker is hardest. More work than T2.
- **T4. T2 plus calls to functions that do not call themselves.** It tests
  handing holders across calls, and the rule's requirement that helpers receive
  live cells, never freed ones. More spec work, and still no recursion.

**Recommendation: T2.** The biggest risk in the full 3c is the part everything
else stands on: writing the counted meaning exactly and proving that its
bookkeeping of holders is right. T2 tests that at the smallest size where the
bookkeeping is still the real one (sharing, reuse, freeing whole lists), and the
examples give a first answer before any builder starts. T3 and T4 add parts that
the full 3c tests in their real setting. Codex, reviewing as oracle, also
recommends T2; two agreeing models are not two pieces of evidence.

**Reference points.** The two closest published pieces of work the lead knows
prove rules like this on paper, not by machine:

- **Perceus**, the counting behind Koka (Reinking, Xie, de Moura and Leijen,
  technical report MSR-TR-2020-42), proves for a small core language that its
  counted meaning is sound and leaves no garbage, and that its placing of
  holders is sound and precise. Of its further optimisations, reuse among them,
  it says their soundness "follows naturally" but "a proof is beyond the scope
  of this paper", so its reuse is not covered by a proof.
- **FP²** (Lorenzen, Leijen and Swierstra, ICFP 2023, MSR-TR-2023-19) proves
  that its fully in-place functions run without allocating or freeing, provided
  the values they own are held nowhere else (a whole program is also given, up
  front, the space it will need). Its Theorem 6 proves that a counted memory
  with reuse stays correct for well-formed programs: counts always right,
  nothing released early, no garbage at the end. Its authors say that proof "may
  be well suited to possible mechanized formalization".

Q2 is close to FP²'s Theorem 6, for a smaller language, checked by Lean.

## The trial's language

The full 3c language without function calls:

- whole numbers, with `+`, `-` and comparisons;
- lists of numbers (empty, or a first item followed by the rest);
- `if`, `let`, and `match` on a list;
- named inputs, the program's starting values.

No functions, trees, records, text or pairs. Numbers are not counted as memory;
a number inside a list cell is part of that cell.

With no calls there is no recursion, so every program finishes, and a program
can work only on the first few items of a list. Runs that never finish, and
counting allocations over them, are left to the full 3c.

## The two meanings

The **plain meaning** says what each program computes, with lists as plain
values.

The **counted meaning** runs the same program with counted memory, by the reuse
rule:

- Memory is a set of list cells. Each cell holds a number, a link to the rest of
  the list (another cell, or the empty list) and a holder count.
- Holders are names in the program that will still be used, links from other
  cells, and outside holders (for example a caller keeping the old version).
- A holder is given up right after its last use. Whether a use is the last is
  judged from the program text still to run, so the rule applies as the program
  runs, without knowledge of the future. A cell whose count reaches zero is
  freed, and its link to the rest is given up in turn.
- When a `match` takes a cell apart at its last use and nobody else holds the
  cell, the cell is set aside and stays allocated. The next new cell built in
  that branch reuses it. If the branch builds no new cell, the set-aside cell is
  freed.
- When someone else holds the cell, it is not set aside and cannot be reused:
  its count goes down by one, and the parts taken out get holders of their own.
  A new cell is new memory only when no set-aside cell is available to it (for
  example, one set aside by an enclosing `match` may still be); which set-aside
  cells a new cell may take is part of the fine details below.
- Every allocation, reuse and free is logged.

The fine details are fixed in phase 1 and approved by Robert in plain English:
the order in which the parts of a program run, which set-aside cell a new cell
takes when several are available, exactly when an unused one is freed, and how a
name used in only one branch is given up. The counted meaning must also expose
enough of the run to state promise (c) at every point: its intermediate states,
or a proven connection between the logged events and who holds what at that
moment.

## What the promises cover

- **A well-formed program:** every name used is bound (an input, or a name bound
  by `let` or `match`), and every use has the right kind: numbers where numbers
  are expected, lists where lists are expected, true-or-false where a condition
  is expected. This is checked from the program text before running; it is not
  defined as "runs without getting stuck".
- **A valid starting memory:**
  - each input has the kind the program expects (a number or a list);
  - finitely many cells, and no cycles;
  - every list input and every outside holder names the empty list or an
    allocated cell, and so does every cell's link (nothing dangles);
  - every allocated cell is reachable from an input or an outside holder (no
    garbage at the start);
  - every cell's holder count equals the number of holders it actually has
    (inputs, links from other cells, outside holders), so every count is at
    least one.
  - Sharing is allowed: inputs may share cells with each other and with lists
    outside holders keep.
- **Who holds what:** the run is handed one holder on each input and gives it up
  by the end, except where it becomes part of the answer. Outside holders keep
  theirs throughout.

## The examples

Categories only; the exact programs and starting memories come in phase 1. Each
example has its exact program, its starting memory (who holds what), the
expected answer, and the expected numbers of allocations, reuses and frees.

- Reuse on an unshared list: add one to the first item.
- Two cells reused: swap the first two items.
- Freeing: drop the first item; total the first two items (every cell freed).
- A set-aside cell that no new cell uses, which must be freed.
- New cells needed: put an item on the front; duplicate the first item.
- An outside holder keeps the input: no reuse, and the kept list never changes.
- The list is used again later in the program: no reuse.
- Two inputs share a tail.
- Reuse in one branch and not in the other.

Codex may add examples.

## How the trial runs

**Phase 1: the rule and the examples.** The predictions, which are the
acceptance criteria for the rule, are written and approved before the rule is
encoded. The file that runs them against the rule is written afterwards and
locked with the rest.

1. The lead writes the plain-English rule with its fine details, the example
   programs and starting memories, and the interface the checks will use (the
   names and shapes of what they run and read). Robert approves the rule and the
   examples.
2. Codex writes the predictions (each example's expected answer and expected
   numbers of allocations, reuses and frees) from the approved English rule,
   before any Lean version of the counted meaning exists. Robert approves the
   predictions; they are then frozen, with fingerprints.
3. The lead writes the language and both meanings in Lean. Codex, in its own
   visible Herdr pane (a session separate from its read-only reviewing role),
   writes the Lean file that checks the runs against the frozen predictions. The
   lead never edits a prediction or that file.
4. The run. Each mismatch is classified against the approved English rule: a
   wrong prediction, a wrong encoding, or a counterexample to the rule. The
   failed run and the original prediction are kept, and nothing changes without
   Robert's decision.
5. The lead writes the promises of Q2 as Lean statements, `ACCEPTANCE.md` (the
   same in plain English, with the examples as tables) and the builder's brief.
   Codex answers one bounded question: "can a builder pass these checks while
   failing the intended task?" Robert approves them, and the fingerprints of
   every locked file go in `LOCK.md`: the language, both meanings, the
   predictions and the file that checks them, the promises, the acceptance file
   and the brief.
6. Robert sees the example results and decides whether phase 2 starts.

**Phase 2: the proof** (T2 and up). A builder in a visible Herdr pane (D14,
builders work where Robert can see them) writes only its own proof files, never
the language, the meanings, the promises or the checks.

**Checking the builder's work.** The lead and Codex each check it and write
their findings before seeing the other's (the D70 pattern of independent reviews
compared afterwards):

- The fingerprints match `LOCK.md`, a clean rebuild succeeds, and Lean's list of
  what the proofs rely on (`#print axioms`) shows only its standard assumptions,
  with no unfinished proofs.
- **Broken copies of the rule.** Three unsafe copies: one reuses a cell someone
  else holds, one forgets to give up the rest of a freed cell, and one frees a
  cell that still has a holder. For each, the lead and Codex show a concrete
  program and valid starting memory on which that copy breaks a named promise,
  by running it (for example, a kept list reads differently partway through the
  run). That is the evidence that the promises rule the copy out. The builder's
  proofs must also fail to build against each copy. A failure alone is not
  counted as evidence, since a proof can fail for incidental reasons; but if the
  proofs still build against a copy that has a shown counterexample, the
  promises are not about the rule that runs, and the lock has failed.
- **A copy that never reuses.** The only claim is that the approved examples
  reject it: it makes new cells where the predictions say none. That it would
  also meet the safety promises is Experiment 1's lesson (a safety promise alone
  lets a do-nothing pass). It is argued, not proven, unless Robert chooses to
  budget that proof.
- Robert sees the result in plain English, and the lead writes `RESULT.md`.

## Tools (D64, tools chosen per experiment)

- **Lean 4.34.0,** pinned in the project as in Experiments 1 and 2. It fits
  because the definitions run on the examples and the proofs are about those
  same definitions, so what is proven is what ran. Experiment 1 showed the
  method on a much smaller checker.
- **Not Koka.** The trial has no demand verdicts to compare, and Koka places
  reuse by its own analysis and optimisations, so matching Koka would not test
  this rule. The Koka cross-check of demand verdicts stays in the full 3c.
- **Not Rust.** Whether 3b's Rust helper follows the counted meaning is a later
  question.

What the trial can isolate: whether the reuse rule, written exactly, reuses as
intended on the approved examples; whether it can be proven correct for every
program without calls; and the effort that took. What it cannot: recursion and
runs that never finish; function calls; the in-place checker and the checks on
callers (the two slices proper); whether a checker accepts useful programs;
speed; whether the Rust helper matches the model; and how the proof effort would
scale to the full 3c.

## Stop conditions

Phase 1 stops when:

- **Done:** every example matches, and the files are approved and locked;
- **A mismatch needs Robert:** the lead reports the classified mismatch and
  waits for his decision; or
- **Setup blocked:** Lean cannot run as needed.

Phase 2 stops when any of these happens:

- **Completed:** every promise is proven, the lead's and Codex's checks are
  done, and the result is written up.
- **The builder's stop condition is reached** (Robert's question 2 below). The
  builder stops and reports where the proof stands.
- **A rule is shown wrong:** a concrete program breaks a promise. This is
  reported separately from an unfinished proof.
- **The spec is wrong:** a locked file turns out to be mistaken or unprovable as
  written. Only Robert can approve a change, followed by a new lock.
- **Setup blocked:** Lean cannot run as needed.

In every case the work and the evidence are kept, and every stop report
separates three things: theorems proven and checked, proofs left unfinished, and
concrete programs that break a rule, as D75 (the two-stage plan for 3c's
slice 1) requires.

## What the trial will not tell us

- Anything about recursion, runs that never finish, or function calls.
- Whether a checker can enforce the in-place demand, or accept useful programs.
- Speed, stack use, or the cost of numbers (design choice 10).
- Whether the Rust helper matches the counted meaning.
- How long the full 3c proofs would take. The trial gives only its own observed
  effort.

## What it feeds

Robert's next decisions: whether the full 3c goes ahead as planned or changes;
whether the trial's language and counted meaning become the start of 3c's shared
parts; whether the full 3c has a time cap (Robert has challenged having one);
and whether builders run on a cloud VM instead of his laptop.

## Open questions for Robert, in order

1. The trial's scope: T0 to T4. Recommended: T2.
2. The builder's stop condition for phase 2: a number of hours, or another rule.
   This connects to Robert's challenge to a time cap for the full 3c.
3. Approve the plan. Phase 1's rule, examples and predictions then each get his
   approval before anything is locked.

## Codex's review (27 Sep 2026)

Codex reviewed the lead's outline as oracle in three rounds before this draft
was written, then the draft itself. Taken into the text:

- The predictions are written by Codex, not by the lead who encodes the rule,
  and are approved and frozen before the rule is encoded. The file that runs
  them is Codex's too, written afterwards and locked with the rest.
- Each broken copy of the rule must break a promise on a concrete program; a
  failed proof alone can have incidental causes.
- The promises cover well-formed programs and valid starting memory: nothing
  dangling and no garbage at the start.
- "No visible change" holds at every point of the run, for names inside the
  program still in use as well as for outside holders.
- T3's limits are stated fairly.
- The effort is reported as observed for this trial, not as a bound.
- The papers are described by what they actually prove.
- From the draft: a cell someone else holds cannot be reused, but a new cell may
  still reuse another set-aside cell; the builder's brief is approved and locked
  before phase 2; the two meanings are explained before Q1.
