# Experiment 3c: a checker that refuses broken in-place demands

**Status: draft, 24 Sep 2026.** Written by the lead after working the shape
through with Codex. Decided so far: 3c is next (D71), it runs in two slices
(D72), what the demand promises (D73), that the reuse-and-release rule is
fixed in the locked counted meaning (D74), and that slice 1 runs in two stages
(D75). Everything else here is a proposal
for Robert to approve. The acceptance file (the exact promises and examples)
comes after the plan, with its own review and approval before locking.

## Where it comes from

- **D26:** Mo is pure. The compiler may update a value in place when nothing
  else holds it, and a writer can demand in-place updating for a function, which
  the checker must prove or refuse.
- **Experiment 3** showed Koka's version works, but Koka only warns about a
  broken demand (D41), and its promise is conditional: a demanded function
  handed data someone else holds copies it silently. The lead confirmed this on
  24 Sep with a four-line Koka program.
- **D62:** whether Mo's own checker can enforce the demand (a proof) and whether
  useful programs can meet it (examples) are two separate checks, left for 3c.
- **D47:** Lean's role is proving the in-place rules correct.
- **3b** (outcome 2 under D66) made its helper a candidate runtime foundation.
  Its rule (update in place with one holder, copy when shared) is the rule 3c
  models.
- **D72:** two slices on the same small list programs. Slice 1 proves Koka's
  conditional promise; slice 2 adds checks on callers so the promise holds for
  every demanded call.
- **D73:** the promise is Koka's relaxed one: a demanded call makes no new list
  cells, counting every allocation during the call (including in the functions
  it calls, and cells later freed); freeing is allowed. List cells only, not
  stack or number storage.

## The questions

**Slice 1.** Can a small checker, written in Lean, accept a demanded function
only when the call, handed lists nobody else holds, is guaranteed to make no new
list cells, with a Lean proof about the checker that actually runs, while still
accepting the approved useful functions?

**Slice 2.** Can checks on callers turn that into an enforced promise, so that
in every program the checker accepts, every demanded call makes no new list
cells, with a Lean proof, while still accepting the approved useful callers?

Finishing only slice 1 does not count as testing enforcement (D72).

## Tools (D64)

- **Lean 4.34** for everything the proofs are about: the language, its two
  meanings, the checker, and the proofs. Why it fits: the proof is about the
  checker that runs, not a description of it, so there is no gap between what
  was proven and what was built. Lean can also run the checker and the programs
  on the examples. Experiment 1 showed the method on a much smaller checker.
- **Koka 3.2.9** as an independent reference, for slice 1 only. Before locking,
  the lead writes each slice-1 example in Koka and compares Koka's
  relaxed-demand verdict with the expected verdict. The Koka translations and
  Koka's exact messages are kept. Differences are sorted by cause (memory,
  termination, library, or how the program is represented) and explained in the
  acceptance file. Agreement is supporting evidence about the lead's
  expectations, not the definition of correct: Koka's demand is not identical to
  D73's.
- **Not Rust.** Connecting the toy language to 3b's helper (compiling accepted
  programs to Rust and counting allocations) is a later step. Proving the model
  does not prove the Rust helper follows it, and that connection is its own
  question.

What the comparison can isolate: whether rules of this kind can be proven
correct and still accept the approved examples, in a small first-order language
with lists of numbers. What it cannot: speed; whether the Rust helper matches
the model; trees, records, text or higher-order functions; stack use; whether a
full-size Mo checker would behave the same way.

## The toy language

Deliberately small (D10), for both slices:

- whole numbers, with `+`, `-` and comparisons;
- lists of numbers (empty, or a first item followed by the rest);
- `if`, `let`, and `match` on a list;
- named functions, which may call each other and themselves;
- a marker saying a function demands in-place updating.

No trees, records, text, pairs or functions as values. Numbers are not counted
as memory; a number inside a list cell is part of that cell.

Programs may run forever (a function can call itself without end). The promises
must cover that honestly. Allocations are counted over every part of a run,
including runs that never finish. A program whose plain meaning finishes must
also finish in the counted meaning, with the same answer, so an endless loop can
never be passed off as success. "Gets stuck" never counts as success either.

## What is locked and what the builder writes

The lead writes, and Robert approves before locking:

1. **The language** and its **plain meaning**: what each program computes, with
   lists as plain values.
2. **The counted meaning**: how a program runs with counted memory. Every list
   cell has a holder count. A new cell either reuses a cell that is being given
   up, or is new memory, logged as an allocation event. Every freed cell is
   logged as a free. This is the yardstick that decides what "no new list
   cells" means.
3. **The promises** (next section), stated in Lean and in plain English.
4. **The examples**, each with its exact program, expected verdict and expected
   answer.

The builder writes, in a visible Herdr pane (D14), only the checker (which
refuses with a reason) and the proofs.

**Who decides where cells are reused and released (decided, D74: option a).** Koka's compiler
decides this invisibly. In 3c it can be:

- **(a) fixed in the locked counted meaning** (chosen, D74): one simple, automatic rule written by the lead, in the style of
  Koka's. A holder is given up right after its last use. When a list cell is
  taken apart in a branch and given up there, the next new cell built in that
  branch reuses it if nobody else holds it. The builder writes no preparation
  step, so it never touches the yardstick.
- **(b) a preparation step the builder writes**, limited to lead-fixed
  changes and with its own proof. Codex's review of the first draft found that
  without such limits, the step could copy a shared list just before the
  demanded call, so the call itself makes no new cells while the program still
  copies.
- **(c) written into the programs by hand**, which goes against D26's
  "invisible".

The details of (a) are for the acceptance file, with Codex's qualifications:
"last use" must be a rule the counted meaning can apply as it runs, not
knowledge of the future; a cell set aside for reuse stays allocated, and if it
is freed instead, replacing it counts as an allocation; helpers receive live
cells (for example a one-cell list), never freed ones. Under (a), 3c's
conclusion is about this one rule: a refusal may show a limit of the rule
rather than something that cannot run in place, and the result records which.

## The promises

**Both slices:**

- **Same answers.** For every well-formed program, the counted run gives the
  same answer as the plain meaning, never gets stuck, and never changes a list
  that another holder can still see.
- **Nothing leaks.** When a whole program's counted run finishes, every cell
  that is not part of the answer has been freed. (This covers complete programs
  only; while a program runs, cells still held elsewhere must stay.)

**Slice 1:**

- **In place, if unshared.** If the checker accepts a demanded function, then
  whenever it is called with lists whose every cell has exactly one holder, and
  no two of which share cells, the call makes no new list cells: zero allocation
  events from the call's start to its end, including in every function it
  calls, and over every part of a run that does not finish.
- **Useful.** The checker accepts every approved must-accept function and
  refuses every must-refuse one, and each accepted example computes its approved
  answer.

**Slice 2:**

- **In place, enforced.** If the checker accepts a whole program, then in its
  counted run every demanded call makes no new list cells.
- **Useful.** As for slice 1, over the approved caller programs.

A checker that refuses everything passes the in-place promises; the useful
examples close that gap (Experiment 1's lesson). A checker that accepts
everything passes the useful examples it must accept; the proofs and the
must-refuse examples close that gap.

## The examples (categories; the full list comes with the acceptance file)

Each example has its exact program, an expected verdict and, if accepted, an
expected answer on stated inputs. Each also records whether any cell was freed
on those inputs, which is the only record of strictness (D73). The exact
programs matter: keeping an old version is harmless if the demanded function
only reads it, and an ordinary function that sometimes makes cells need not
make them on every call. Each must-refuse example is written so that it really
does the thing it tests.

**Slice 1, must accept:** add one to every item; reverse; running totals; append one list onto another; swap each pair of neighbours; rotate the first item to the end; merge two sorted lists; insertion sort (moving existing cells only); total a list (all cells freed); keep the first item and drop the rest; remove the first match; keep only positive numbers.

**Slice 1, must refuse:** duplicate every item; put an item on the front; insert
a new number into a sorted list; build a list from a number; use the same list
twice (for example append a list to a changed copy of itself); call an ordinary
function that makes new cells.

**Slice 1, observed (no expected verdict):** a demanded function that calls an
ordinary function doing only arithmetic. Accepting it needs the checker to look
inside ordinary functions; refusing it is a limit on usefulness, not a failure.

**Slice 2, must accept:** build a fresh list and pass it to a demanded call;
chain demanded calls; call an ordinary function on a list someone else still
holds (ordinary code may copy; slice 2 must not over-restrict it).

**Slice 2, must refuse:** keep the old version and use it after a demanded
call that changes every item; pass the same list twice to a demanded call that
changes both; pass one of two lists that share a tail while
the other is kept.

**Slice 2, observed (no expected verdict; the result records what happens):**
share a list, drop the extra holder, then make the demanded call; hand a fresh
list through an ordinary function that passes it on to a demanded call. Correct
programs the checker refuses here are recorded as limits on usefulness, not
failures.

## How the work is split (the lock pattern)

1. The lead writes this plan. Codex reviews it. Robert approves.
2. The lead writes the Lean spec (language, both meanings, promises, examples)
   and `ACCEPTANCE.md` (the same in plain English, examples as tables), and runs
   the Koka cross-check on the slice-1 examples. Codex answers one bounded
   question before locking: "can a builder pass these checks while failing the
   intended task?" Robert approves. The shared parts (language, both meanings,
   examples) are locked for both slices at once, so slice 2 cannot be reshaped
   around what slice 1 managed. Each slice's own promises and builder brief are
   approved and locked before that slice's builder starts. Fingerprints go in
   `LOCK.md`.
3. A builder does slice 1 in a visible Herdr pane, writing only its own files,
   in two stages (D75):
   - **Stage 1:** prove the counted meaning correct for every well-formed
     program, shared data included (same answers, nothing leaks, finishing
     matches). Then stop.
   - The lead and Codex check stage 1 independently: the fingerprints, a clean
     rebuild, `#print axioms`, and a deliberately broken copy of the rule (one
     that reuses a cell someone else holds) that must make the proof fail.
     Robert sees the result in plain English. Stage 2 starts only on his
     go-ahead.
   - **Stage 2:** the checker and its in-place proof, on top of stage 1.
4. The lead and Codex verify stage 2 independently (D70's pattern): the
   fingerprints, a clean rebuild, `#print axioms`, and deliberately broken
   checkers that must fail (one that accepts everything, one that refuses
   everything, and one missing a single rule, such as letting a list be used
   twice).
5. A builder does slice 2, and step 4 is repeated.
6. The lead writes `RESULT.md`.

## Stop conditions

Each slice stops when any of these happens:

- **Completed.** Every promise is proven, the examples are checked, the lead's
  verification is done, and the result is written up.
- **Effort bound reached.** The builder has worked a set number of hours on
  the slice, counted from when it starts, without finishing the proofs. It
  stops and reports where the proof stands. The number is Robert's to set; it
  is a stopping budget, not an estimate of how long the work takes.
- **A rule is shown wrong.** A concrete program shows a checker rule accepting
  something that breaks a promise. The builder stops and reports it. This is
  different from an unfinished proof and is reported separately.
- **The spec is wrong.** A locked file turns out to be mistaken or unprovable as
  written. The builder stops and reports; only Robert can approve a change,
  followed by a new lock.
- **Setup blocked.** Lean or Koka cannot run as needed.

In every case, the work and the evidence are kept. Every stop report separates
three things: theorems proven and checked, proofs left unfinished, and concrete
programs that break a rule (D75). An unfinished proof does not show a rule is
wrong. If slice 1 stops without completing, slice 2 does not start without
Robert's decision.

## What 3c will not tell us

- Anything about speed. 3b answered that for the helper on four workloads.
- Whether the Rust helper matches the counted meaning (a later step).
- Whether the rules extend to trees, records, text, or functions as values.
- Stack use, or the cost of numbers (design choice 10).
- Whether agents can write code that meets demands (the D59 follow-up and later
  work).
- Whether Mo should have a full ownership system. Slice 2 is a small check for a
  toy language (D72).

## After 3c (candidates, not commitments)

- Allocation budgets, Koka's `fip(n)` (D73).
- Compiling accepted programs onto 3b's helper and counting allocations.
- Trees and records.
- Comparing with a runtime check that stops a demanded call before it copies
  (option 2b in the 24 Sep discussion).

## Open questions for Robert, in order

1. ~~Who decides where cells are reused and released.~~ Decided, D74: option
   (a).
2. ~~Whether slice 1 runs in two stages.~~ Decided, D75: yes, with a checked
   stop between them.
3. The effort bound: how many builder hours per slice, shared by both stages if
   they are split, with the clock starting when the builder has the locked
   files and a working setup.
4. Approve the plan. The acceptance file (exact programs, both meanings, the
   promises in Lean and plain English) follows, with its own review and
   approval before locking.

## Codex's review of the draft (24 Sep 2026)

Codex reviewed the first draft and found, all taken into the text above: the
preparation loophole (a builder-written step could copy just before a demanded
call); example programs must be exact, because sharing alone does not force
copying; allocations counted over every part of a run, with finishing programs
required to finish in the counted meaning too; the no-leak promise limited to
complete programs; the effort bound stated in hours, as a stopping budget; Koka
agreement treated as supporting evidence only; shared parts locked up front and
each slice's own promises locked before its builder starts. It then agreed with
the lead that option (a) is the smaller and safer step for 3c, with four
qualifications (recorded under option (a)). No disagreement remains.
