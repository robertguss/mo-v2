# The trial's interface: what the checks run and read

**Status: approved, 30 Sep 2026 (D93: the interface is approved).** Written by the lead for
the trial's phase 1, step 1 (`PLAN.md`, "How the trial runs": "the interface the
checks will use (the names and shapes of what they run and read)"). Codex, who
will write the checks, reviewed the plan for this document and asked for several
of the promises below; those are marked.

## What this document is for

Two pieces of Lean will be written later, by two different writers (`PLAN.md`,
"How the trial runs", step 3):

- **The lead** writes the trial language and its two meanings: the plain meaning
  (what a program computes) and the counted meaning (the same program run with
  counted memory, under the approved rule in `RULE.md`).
- **Codex**, in its own visible session, writes the file that runs the examples
  and checks them against the frozen predictions.

Neither edits the other's files. This document is the agreement between them: it
lists what the checks are able to ask for, and what they get back. It is written
before either piece exists so that the checks can be written against a fixed
contract, and so that the lead cannot shape what the checks are able to see
after seeing the predictions.

Each promise is stated in plain English first. A proposed Lean name follows for
the two writers. **The plain-English promise is what Robert is asked to approve;
the names are a convenience** and may change if Lean requires it, as long as the
promise still holds (section 9).

Nothing here has been built or compiled.

## 1. Where things live, and who writes what

A Lean project at `experiments/03c-checker/trial/lean/`, pinned to Lean 4.34.0
like the earlier experiments.

| File                      | Writer | Contains                                                       |
| ------------------------- | ------ | -------------------------------------------------------------- |
| `Trial/Language.lean`     | lead   | The shape of programs; the check that a program is well-formed |
| `Trial/Plain.lean`        | lead   | The plain meaning                                              |
| `Trial/Memory.lean`       | lead   | Counted memory and its own record of what it did               |
| `Trial/Counted.lean`      | lead   | The counted meaning: the rule of `RULE.md`                     |
| `Trial/Broken.lean`       | lead   | The deliberately broken copies of the rule (section 7)         |
| `Checks/Examples.lean`    | Codex  | The programs and starting memories, copied from `EXAMPLES.md`  |
| `Checks/Predictions.lean` | Codex  | The frozen predictions                                         |
| `Checks/Run.lean`         | Codex  | The checks: run every example and compare with the predictions |

Codex copies both the programs and the starting memories from `EXAMPLES.md` into
Lean itself (Codex asked for the memories to be included). The reason: if the
lead copied them, a slip in the lead's copy could be hidden by the lead's own
encoding of the rule.

## 2. Programs

**Promise.** The checks can write down any program of the trial language,
exactly as `RULE.md` section 2 lists it, with one building block for each row of
that section's table: a number, `+`, `-`, the three comparisons, the empty list,
building a cell, `let`, `if`, `match`, and a name. Names are written as their
spelling.

**Promise.** The checks can ask whether a program is well-formed, given the
names and kinds of its inputs (a number or a list), and get back either "yes,
and its answer is of this kind" or a stated reason why not. The check covers:
every name used is bound; every use has the right kind; every `match` has both
branches (`RULE.md` 2d); the two names a `match` introduces are spelled
differently (2e, D89: the two language gaps Codex found and closed with the
lead); both branches give the same kind of value (2f, D89). It reads only the
program text and never runs the program.

Proposed names: `Expr` (programs), `Kind` (number, list, true-or-false),
`wellFormed : List (String × Kind) → Expr → Except String Kind`.

## 3. Starting memories

**Promise.** The checks can write down any starting memory in the form
`EXAMPLES.md` uses: the cells (each with its address, item, link and holder
count), the inputs in order (each a name with its value: a number, the empty
list, or a cell's address), and the outside holders (each naming the empty list
or a cell's address).

**Promise.** The checks can ask whether a starting memory is valid for a given
program, and get back "yes" or a stated reason. The check is the list in
`PLAN.md`, "What the promises cover": each input has the kind the program
expects; finitely many cells and no cycles; nothing dangles; every cell is
reachable from an input or an outside holder; every holder count equals the
number of holders the cell actually has.

Proposed names: `Start` (a starting memory),
`validStart : Expr → Start → Except String Unit`.

## 4. Running a program

**Promise.** The checks can run a program under the plain meaning, giving it
plain input values (a number, or a list of numbers), and get back its plain
answer: a number, true or false, or a list of numbers.

**Promise.** The checks can run a program under the counted meaning, giving it a
starting memory, and get back an outcome (section 5).

**Promise.** Both always finish and both always say what happened. There are
three different ways a counted run can fail to give an answer, and the outcome
says which (Codex asked for the three to be kept apart):

- **Refused before running:** the program is not well-formed, or the starting
  memory is not valid. The reason is given.
- **Failed while running:** the run reached an operation it could not perform
  (for example, using a cell that has already been freed). A correct rule should
  never do this on a well-formed program and a valid memory; a broken copy can.
- **Failed while reading the answer back:** the run finished, but the answer's
  list could not be read from memory (for example, it links to a freed cell).

A failure is never replaced by a default. In particular, a list that cannot be
read is reported as unreadable, never as the empty list.

Proposed names:
`runPlain : Expr → List (String × PlainValue) → Except String PlainValue`;
`runCounted : Rule → Expr → Start → Outcome` (the `Rule` argument is section 7).

The trial language has no loops or function calls, so every run is finite. That
alone does not make it easy to convince Lean that walking and cleaning up memory
always finishes; doing so is the lead's work in the encoding, and is not assumed
here (Codex's caution).

## 5. What an outcome shows

**Promise.** After a counted run, whether it succeeded or failed, the checks can
read everything in the table below that exists. An answer exists only if the run
produced one: a run that was refused, or that failed while running, has no
answer, and none is made up. When a run fails while running, the memory, the
log, the record and the snapshots up to the failure are still there, together
with the operation that failed. When a run finishes but its answer cannot be
read back, the raw answer is there too, and the read-back reports the failure
(Codex asked for
this: a broken copy may free a cell that is still held and only then fail, and
the evidence of which promise it broke must not be thrown away).

| The checks can read                  | What it is                                                                                                                                                                         |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The raw answer                       | A number, true or false, the empty list, or **the address of the answer's first cell**                                                                                             |
| The answer read back                 | The raw answer followed through memory into a plain value, or "unreadable" with the reason                                                                                         |
| The final memory | Every allocated cell: address, item, link, holder count, and whether it is live or set aside. A freed cell is no longer part of memory: it shows only in the log and the record, and cannot be read |
| The rule's log                       | Every allocation, reuse and free the rule claims, in order, each with its cell address                                                                                             |
| The memory's own record              | Every primitive thing memory actually did, in order, each with its cell address: a fresh cell created; an existing cell written in place with a new item and link; a cell released |
| The states along the way (section 6) | A snapshot at each step of the run                                                                                                                                                 |

Three points about this table.

- **The raw answer** (Codex asked for it). A plain list alone does not say which
  cell the caller receives: two different cells can hold equal lists. The checks
  need the address to decide, for themselves, which cells are reachable from the
  answer and whether every holder count is right at the end (`PLAN.md`, promise
  (d)).
- **Reading a list back** is something the checks can do from any memory state,
  final or along the way, starting from any address, and it can fail.
- **The memory's own record is separate from the rule's log, and is written by
  the memory operations themselves** (Codex asked for this to be explicit). It
  is not a second copy of what the rule claims. Changing a holder count, setting
  a cell aside, and detaching a set-aside cell's old contents are not recorded
  as creating, writing or releasing. The checks take the numbers of allocations,
  reuses and frees from this record, or check the rule's log against it
  (`PLAN.md`, "How the trial runs", step 3). That is what rejects a copy of the
  rule that frees a cell, builds a replacement, and logs a reuse.

Proposed names: `Outcome` with fields `result` (`.answer raw`, `.refused why`,
`.failedRunning why`), `memory`, `log`, `record`, `states`;
`readBack : Memory → RawValue → Except String PlainValue`. The third kind of
failure is a run whose `result` is `.answer raw` and whose `readBack` on the
final memory fails.

## 6. Seeing the run as it goes

`PLAN.md` ("The two meanings") requires the counted meaning to "expose enough of
the run to state promise (c) at every point": that a list someone else can see
never changes.

**Promise.** The checks can read a snapshot of the run at every step. Each
snapshot shows who holds what at that moment (Codex asked for each of these):

- the memory, as in the final memory above;
- the names currently in use and what each holds. Two names with the same
  spelling are shown as two different names (D83: a name may reuse a spelling);
- the intermediate results, each with what it holds (`RULE.md` section 3);
- the outside holders;
- the set-aside cells, each with the `match` branch it belongs to;
- what kind of step this is, including the two the rule's timing turns on: a
  branch has just been chosen, and a branch is cleaning up before handing on its
  value.

Proposed names: `Outcome.states : List Snapshot`.

**What this makes possible, and what it does not decide.** With the order of
events and the snapshots visible, checks could tell apart choices that differ
only in when something happens. The case in point is D90 (an unused set-aside
cell is freed when its branch finishes) against the one alternative `RULE.md` 6g
compares it with, freeing as soon as the rest of the branch builds no cell. By
the lead's reasoning, not yet checked, those two give the same totals; if so,
totals alone cannot tell them apart (`EXAMPLES.md`, "One limit"). The approved
plan's predictions are each example's "expected answer and expected numbers of
allocations, reuses and frees": nothing about order. Making any prediction about
order would widen the approved plan, so it is **not decided here**. It is the
second question for Robert at the end.

## 7. The broken copies

`PLAN.md` uses deliberately broken copies of the rule to check that the checks
and the promises really reject wrong behaviour:

| Copy                                                                            | When                     |
| ------------------------------------------------------------------------------- | ------------------------ |
| Frees a cell and builds a replacement, but logs a reuse (the misreport control) | Phase 1, before the lock |
| Reuses a cell someone else holds                                                | After the proof          |
| Forgets to give up the rest of a freed cell                                     | After the proof          |
| Frees a cell that still has a holder                                            | After the proof          |
| Never reuses                                                                    | After the proof          |

**Promise.** Each of these can be run by the same checks, unchanged, by naming
which copy to run. The approved rule is one of the named choices, and it is the
one the predictions are about. This is a short, fixed list of named copies, not
a general way of changing the rule (Codex asked for it to stay that small, and
to cover the unsafe copies, which are not merely different valid choices).

Proposed names: `Rule` with values `.approved`, `.misreportsReuse`,
`.reusesShared`, `.forgetsRest`, `.freesHeld`, `.neverReuses`.

## 8. What the checks will do with this

So Robert can see how the pieces fit, the checks (Codex's file) are expected to,
for each of the twenty-eight runs in `EXAMPLES.md`:

1. confirm the program is well-formed and the starting memory valid;
2. run the plain meaning and the counted meaning;
3. compare the counted answer, read back, with the predicted answer and with the
   plain meaning's answer;
4. count allocations, reuses and frees from the memory's own record and compare
   them with the predictions;
5. confirm the rule's log agrees with the memory's own record;
6. run the misreport copy on run 2 and confirm the checks reject it on the
   counts.

What the checks do is Codex's to write and Robert's to approve later; this list
only shows that the interface gives them what they need.

## 9. What this document does not fix

- How the lead builds anything behind these promises: how memory is stored, how
  addresses for fresh cells are chosen, how the run is organised inside.
  Predictions are about answers and totals, so no check should depend on which
  address a fresh cell gets.
- The exact Lean names and shapes, if Lean makes one of them impractical. Any
  change must keep the plain-English promise, is made before the predictions are
  compared with any run, and is shown to Robert and Codex.
- The promises as Lean statements, the acceptance file and the builder's brief
  (`PLAN.md`, "How the trial runs", step 5).
- The predictions themselves.
- Whether any of this can be built exactly as written. Nothing has been
  compiled; feasibility is untested.

## Questions for Robert

One at a time:

1. Do you approve this interface: the promises in sections 2 to 7? **Decided:
   yes (D93).**
2. Should any prediction be about the order of events, not only the answer and
   the three totals? The approved predictions cover each example's answer and
   its three totals. Order predictions could test a timing choice such as D90
   (an unused set-aside cell is freed when its branch finishes) against freeing
   as soon as no build remains, which by the lead's reasoning, not yet checked,
   give the same totals. The cost is more for Codex to predict and more to
   approve. This would change the approved plan (D78: the trial plan is
   approved).
