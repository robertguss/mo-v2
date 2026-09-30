# Brief for the phase-1 worker: the trial language and its two meanings in Lean

**For:** the worker, a Claude session on Sonnet in its own visible Herdr pane
(D96: code is written by a Sonnet worker the lead directs). **Written by** the
lead, 30 Sep 2026, for the trial's phase 1, step 3 (`PLAN.md`, "How the trial
runs"). Reviewed by Codex as oracle.

This is not the phase-2 builder's brief. That one is written later, for the
proof, and needs Robert's approval before it is locked (`PLAN.md`, "How the
trial runs", step 5).

## Your job

Write, in Lean, the trial language, its plain meaning, its counted meaning under
the approved rule, and the deliberately broken copies of that rule. You write
only the implementation. You write no checks: the frozen predictions are the
acceptance criteria, a separate Codex session writes the Lean file that runs
them, and the lead verifies your work on its own.

The work comes in two parts (first planned as three; parts 2 and 3 were merged
before part 2 started, see "Part 2 in detail"). Start a part only when the lead prompts you to,
and stop at the end of each part.

| Part | Files                                                       | Contains                                                                                                                                                        |
| ---- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | the Lake project; `Trial/Language.lean`; `Trial/Plain.lean` | The shape of programs and the check that a program is well-formed; the plain meaning                                                                            |
| 2    | `Trial/Memory.lean`; `Trial/Counted.lean`; `Trial/Broken.lean` | Counted memory, its own record of what it did, starting memories and the check that one is valid, reading a list back; the counted meaning of the approved rule; the five broken copies and the six named choices of rule |

## Read these as the source of truth

1. `CLAUDE.md` at the repo root: the working rules.
2. `experiments/03c-checker/trial/RULE.md`: the approved rule (D91: the reuse
   rule is approved as a whole). The counted meaning must do exactly what this
   text says. Section 10 lists one transition for every operation.
3. `experiments/03c-checker/trial/INTERFACE.md`: the approved interface (D93:
   the interface is approved). Sections 2 to 7 are promises your code must keep.
4. `experiments/03c-checker/trial/PLAN.md`, sections "The two meanings" and
   "What the promises cover".
5. `experiments/03c-checker/trial/EXAMPLES.md`, section "The starting memories"
   only, for the form a starting memory takes.

**Do not open `PREDICTIONS.md`.** Do not run any of the twenty programs of
`EXAMPLES.md` (P1 to P20) through your counted meaning. The lead does neither as
well, until Codex's check file exists. The reason: if a run later disagrees with
a prediction, that disagreement has to be seen, kept and classified (a wrong
prediction, a wrong encoding, or a fault in the rule). An encoding adjusted
until the examples come out right would hide it. Try your code on small programs
of your own instead.

## What you may write

Only these, all under `experiments/03c-checker/trial/lean/`:

- the Lake project files: `lakefile.toml`, `lean-toolchain` (exactly
  `leanprover/lean4:v4.34.0`), `lake-manifest.json`, `.gitignore` (ignoring
  `.lake`), and the root file `Trial.lean` that imports the library's files;
- `Trial/Language.lean`, `Trial/Plain.lean`, `Trial/Memory.lean`,
  `Trial/Counted.lean`, `Trial/Broken.lean`.

The `lakefile.toml` names `Trial` as a default target, so that a bare
`lake build` compiles it. It declares the `Trial` library and also a `Checks` library, so
that Codex's files build in the same project later; you create nothing inside
`Checks/`.

## What you may not do

- Do not create or edit anything under `Checks/`, any test or check file, or any
  file outside the list above. In particular no `.md` file in `trial/`, and not
  `docs/DECISIONS.md` or `docs/README.md`.
- Do not commit or push. The lead commits after the oracle signs off.
- Do not settle an unclear point of the rule or the interface by choosing a
  reading. See the stop conditions.

## Rules for the Lean

Phase 2's proofs will be about these same definitions, and the plan relies on
what is proven being what ran. So:

- **Every definition is total and checked by Lean's kernel.** None of these may
  appear: `partial`, `unsafe`, `sorry`, a new `axiom`, `native_decide`,
  `opaque`.
- **Nothing may make the compiled program differ from the definition.** None of
  these: `@[extern]`, `@[implemented_by]`, `@[csimp]`, `@[export]`, `@[inline]`
  and its relatives, the same added through `attribute [...]`, or a `set_option`
  line that changes compilation or the kernel. The only attributes allowed are
  `@[simp]` and `@[reducible]`; `deriving` clauses such as `DecidableEq`,
  `Repr`, `BEq` and `Inhabited` are fine.
- **No fixed fuel.** Recursion is structural or well-founded. Where that is
  impractical, a bound computed from the input (for example the number of cells
  in memory) is allowed if a comment says why it is always enough, and if
  running out is reported as a failure, never as a default value. A constant
  such as `1000` is not allowed.
- **Lean core only.** No Mathlib, no Batteries, no other dependency.
- **Numbers** are Lean's `Int` (D79: unlimited whole numbers that may be
  negative).
- **Names** in a program are written as their spelling (a `String`). In a
  snapshot, two names with the same spelling are shown as two different names
  (D83: a name may reuse a spelling).
- **A failure is never replaced by a default** (`INTERFACE.md` section 4). A
  list that cannot be read is reported as unreadable, never as the empty list.
  Refused before running, failed while running, and failed while reading the
  answer back stay three different things.
- **Two separate accounts of a run** (`INTERFACE.md` section 5). The memory's
  own record is appended only inside the memory operations themselves: a fresh
  cell created, an existing cell written in place, a cell released. The rule's
  log (allocation, reuse, free) is appended by the rule, separately. Changing a
  holder count, setting a cell aside and detaching its contents are recorded as
  none of the three.
- **Fresh addresses** may be chosen any way, provided the choice is
  deterministic. No prediction is about which address a fresh cell gets.
- **Names and shapes.** Use the proposed names in `INTERFACE.md` (`Expr`,
  `Kind`, `wellFormed`, `Start`, `validStart`, `PlainValue`, `runPlain`,
  `RawValue`, `Outcome`, `readBack`, `Snapshot`, `Rule`, `runCounted`) unless
  Lean makes one impractical. Report every difference and the reason; the
  plain-English promise must still hold.
- **The six choices of rule** (`INTERFACE.md` section 7). The approved rule must
  be readable on its own, and each broken copy must differ from it at one named
  place. There must be no import cycle, and at no time may a named choice of
  rule have made-up or placeholder behaviour. How this is arranged in the files
  is fixed in "Part 2 in detail" below, with exactly where each broken copy
  departs from the rule.
- Comments say what a definition means in the words of `RULE.md`, with the
  section number, so that a reader can set the two side by side.

## Stop conditions

Work on one part at a time. Stop and report in your pane as soon as one of these
holds:

1. **Done with the part:** its files exist; `lake build` succeeds in
   `experiments/03c-checker/trial/lean/` on the pinned toolchain with no errors
   and no warnings; and your report is written (below).
2. **The rule does not decide a case:** `RULE.md` can be read two ways, or says
   nothing, about something the code must do. Do not pick one. Report the two
   readings and the words at issue.
3. **An interface promise cannot be kept as written.** Report which, and why.
4. **Lean will not accept a definition as total** after a real attempt. Report
   what you tried. Do not reach for `partial`, fixed or unjustified fuel, or
   an axiom.
5. **Setup blocked:** Lean or Lake cannot run as needed.

**Your report** at the end of a part, in your pane:

- each `INTERFACE.md` promise that part covers, and the definition that keeps
  it;
- every name or shape that differs from the proposed ones, and why;
- every recursion that is not plainly structural, and why it finishes;
- anything in `RULE.md` you had to read closely, and the words that settled it.

## What the lead checks after each part

You do not write or see these checks. They are listed so that the standard is
known before you start.

- A clean rebuild from an empty `.lake`, on the pinned toolchain.
- A search of `Trial/` for every forbidden word above, a list of every attribute
  line, and Lean's list of what each entry point relies on (`#print axioms` on
  `wellFormed`, `runPlain`, `validStart`, `runCounted`, `readBack`).
- The fingerprints in `LOCK.md` are unchanged.
- The smoke table below, run by the lead from a file outside the repository.
  These are not the acceptance criteria. They are quick checks that the code
  does what the approved documents say in the cases those documents spell out.
- For each part, one deliberate change to an operation of your code, in a
  throwaway copy, which must make a smoke row fail. This shows the rows really
  observe the code.

If a smoke row fails, the lead tells you which promise or section is not met.
The expected values are not changed to fit the code.

### Smoke table, part 1

Well-formedness (`RULE.md` section 2; `INTERFACE.md` section 2). Inputs are
given with their kinds.

| #   | Program                                      | Inputs           | Expected                   | From     |
| --- | -------------------------------------------- | ---------------- | -------------------------- | -------- |
| W1  | `match xs do [] -> 0; [h \| t] -> h + h end` | `xs` a list      | well-formed, a number      | 2        |
| W2  | `n == m`                                     | `n`, `m` numbers | well-formed, true or false | 2c (D82) |
| W3  | `let x = xs in let x = 1 in x + 1`           | `xs` a list      | well-formed, a number      | 2e (D83) |
| W4  | `let x = x + 1 in x`                         | `x` a number     | well-formed, a number      | 2e (D83) |
| W5  | `match xs do [] -> []; [x \| x] -> [] end`   | `xs` a list      | refused                    | 2e (D89) |
| W6  | `if n < 1 then [] else 0 end`                | `n` a number     | refused                    | 2f (D89) |
| W7  | `match xs do [] -> 0; [h \| t] -> t end`     | `xs` a list      | refused                    | 2f (D89) |
| W8  | `y + 1`                                      | none             | refused (unbound name)     | the plan |
| W9  | `xs == xs`                                   | `xs` a list      | refused                    | 2b (D80) |
| W10 | `[xs \| xs]`                                 | `xs` a list      | refused                    | 2        |
| W11 | `[1 \| 2]`                                   | none             | refused                    | 2        |
| W12 | `if n then 1 else 2 end`                     | `n` a number     | refused                    | 2        |
| W13 | `match n do [] -> 0; [h \| t] -> h end`      | `n` a number     | refused                    | 2        |
| W14 | `x + 1` | `x` a number, and a second `x` a list | refused (two inputs with one spelling) | 2e (D97) |
| W15 | `let b = 1 < 2 in if b then 7 else 8 end` | none | well-formed, a number | 2c (D82) |
| W16 | `1` | `b` true or false | refused (no true-or-false inputs) | 2c (D82) |

A `match` with a missing branch (2d) cannot be written down at all if `Expr`
gives every `match` both branches; if your `Expr` allows one, `wellFormed` must
refuse it.

Plain meaning (`INTERFACE.md` section 4).

| #   | Program                                      | Inputs                   | Expected answer           | From     |
| --- | -------------------------------------------- | ------------------------ | ------------------------- | -------- |
| B1  | `2 - 5`                                      | none                     | `-3`                      | 2a (D79) |
| B2  | `let x = x + 1 in x`                         | `x = 4`                  | `5`                       | 2e (D83) |
| B3  | `if n < 1 then n + 10 else n - 10 end`       | `n = 0`; then `n = 1`    | `10`; then `-9`           | 2        |
| B4  | `n <= m`; `n < m`; `n == m`                  | `n = 3`, `m = 3`         | true; false; true         | 2b (D80) |
| B5  | `match xs do [] -> 0; [h \| t] -> h + h end` | `xs = []`; then `[7, 8]` | `0`; then `14`            | 2        |
| B6  | `[n + n \| [n \| xs]]`                       | `n = 2`, `xs = [5]`      | `[4, 2, 5]`               | 2        |
| B7  | W5 to W14, W16                                    | any                      | no answer: a stated error | 4        |
| B8 | W15 | none | `7` | 2c (D82) |

### Smoke table, part 2

Valid starting memories (`PLAN.md`, "What the promises cover"; `INTERFACE.md`
section 3). The program is W1 throughout, with the single input `xs`. Cells are
written address: item, link, holder count. Some refused rows break more than one
condition; a row is met by a refusal with any true reason, not only the one
printed.

| #   | Cells                                    | `xs`         | Outside holders          | Expected                   |
| --- | ---------------------------------------- | ------------ | ------------------------ | -------------------------- |
| V1  | A: 4, B, 1. B: 9, `[]`, 1                | A            | none                     | valid                      |
| V2  | A: 4, B, 2. B: 9, `[]`, 1                | A            | one, on A                | valid (sharing is allowed) |
| V3  | A: 4, B, 1. B: 9, `[]`, 2                | A            | none                     | refused: a wrong count     |
| V4  | A: 4, C, 1. B: 9, `[]`, 1                | A            | none                     | refused: a link dangles    |
| V5  | A: 4, B, 1. B: 9, `[]`, 1. C: 1, `[]`, 0 | A            | none                     | refused: C is unreachable  |
| V6  | A: 4, B, 2. B: 9, A, 1                   | A            | none                     | refused: a cycle           |
| V7  | A: 4, B, 1. B: 9, `[]`, 1                | the number 3 | none                     | refused: wrong kind        |
| V8  | A: 4, B, 1. B: 9, `[]`, 1                | A            | one, on Z (no such cell) | refused: dangles           |
| V9  | none                                     | `[]`         | none                     | valid                      |

Reading back and the three kinds of failure (`INTERFACE.md` sections 4 and 5).

| #   | What is asked                                                 | Expected                                      |
| --- | ------------------------------------------------------------- | --------------------------------------------- |
| F1  | Read a list back from memory V1, starting at A                | `[4, 9]`                                      |
| F2  | Read a list back from memory V1, starting at Z (no such cell) | unreadable, with a reason; not the empty list |
| F3  | Run W5 (not well-formed) under the counted meaning on V1      | refused before running; no answer             |
| F4  | Run W1 under the counted meaning on V3                        | refused before running; no answer             |

Single steps of the counted meaning. Each row is one illustration of `RULE.md`
section 8, run as a small program that is not one of P1 to P20. "As the rule
states" marks what section 8 says outright; "the lead's working" marks what the
lead derived from sections 4 to 7 for the rest of that run. If your code
disagrees with a line of the lead's working, that is reported and looked at; it
is not settled by changing either side quietly.

On every row the lead also checks: the rule's log agrees with the memory's own
record; the answer read back equals the plain meaning's answer; at the end the
allocated cells are exactly those reachable from the answer and the outside
holders, with every holder count right; and every outside holder's list reads
the same in every snapshot.

**S1, from 8.1 (setting aside, then reusing).** Program
`match xs do [] -> []; [h | t] -> [h + h | t] end`. Memory V1.

- As the rule states: just after the match takes A apart, A is set aside with no
  holders and holds nothing, B has count 1, and nothing has been logged or
  recorded. After the build, A is live with count 1, item 8, linking to B, and
  B's count is still 1. Logged: one reuse of A. Recorded by memory: one write in
  place, of A; no cell created, none released.
- Answer `[8, 9]`, first cell A. Totals: 0 allocations, 1 reuse, 0 frees.

**S2, from 8.2 (taking apart a cell someone else holds).** The same program.
Memory V2.

- As the rule states: just after the match takes A apart, A is live, not set
  aside, with count 1; B has count 2. The build cannot take A.
- The lead's working: the build makes a fresh cell with item 8, linking to B,
  count 1. Recorded by memory: one cell created; none written in place, none
  released. Answer `[8, 9]`, whose first cell is not A. At the end A still reads
  `[4, 9]` for the outside holder, with count 1, and B has count 2. Totals: 1
  allocation, 0 reuses, 0 frees.

**S3, from 8.3 (using a name that will be used again).** Program
`let y = xs in match xs do [] -> 0; [h | t] -> match y do [] -> h; [g | u] -> g + h end end`.
Memory V1.

- As the rule states: just after `y` is named, A has count 2, and nothing has
  been logged.
- The lead's working: the match on `xs` finds A with count 2, so A is not set
  aside; `t` is unused and gets no holder; the match's holder is given up (A's
  count 1). The match on `y` finds A with count 1 and sets it aside; `u`
  receives B's holder, is unused, and gives it up, which frees B. The branch's
  value is 8. When the inner branch finishes, A is freed. Answer `8`. Totals: 0
  allocations, 0 reuses, 2 frees, B before A. No cell is left.

**S4, from 8.4 (freeing a detached rest, and disposing of a set-aside cell).**
Program W1, `match xs do [] -> 0; [h | t] -> h + h end`. Memory V1.

- As the rule states: `t` is unused, so its holder on B is given up in the
  match's step 5 and B is freed at that moment (logged: a free of B); A is
  unaffected and still set aside. A is freed when the branch finishes (logged: a
  free of A only).
- So in the snapshots: at the moment the branch's value has been worked out, A
  is still allocated and set aside; once the value has been handed on, A is gone
  (6g, D90: an unused set-aside cell is freed when its branch finishes).
- Answer `8`. Totals: 0 allocations, 0 reuses, 2 frees, B before A. No cell is
  left.

**S5, from 8.5 (matching on a name that will be used again).** Program
`let n = match xs do [] -> 0; [h | t] -> match t do [] -> h; [g | u] -> g end end in match xs do [] -> n; [a | b] -> n + a end`.
Memory V1.

- As the rule states: the first match gets a new holder on A (count 2) while
  `xs` keeps its own. Just after that match takes A apart, before its branch
  runs, A has count 1 and is not set aside, B has count 2, and nothing has been
  logged.
- The lead's working: the match on `t` finds B with count 2, does not set it
  aside, and gives up its holder (B's count 1); its value is 9, which `n` names.
  The last match on `xs` finds A with count 1 and sets it aside; `b` receives
  B's holder, is unused, and gives it up, which frees B. The branch's value is
  13, and A is freed when the branch finishes. Answer `13`. Totals: 0
  allocations, 0 reuses, 2 frees, B before A. No cell is left.

### Smoke rows for the broken copies

`INTERFACE.md` section 7 says when each copy is run. The misreport control runs
in phase 1; the three unsafe copies and the copy that never reuses run only
after the proof. So the lead runs K1 and K6 after part 2, and K2 to K5 are
recorded here now and run only after the proof.

| #   | Copy | Program and memory | Expected | When |
| --- | ---- | ------------------ | -------- | ---- |
| K1  | misreports reuse | S1's program, memory V1 | answer `[8, 9]`; the rule's log holds exactly one reuse and nothing else; memory's record holds one release, of A, and one creation, and no write in place | after part 2 |
| K2  | reuses a shared cell | S2's program, memory V2 | the outside holder's list reads `[4, 9]` at the start and `[8, 9]` in a later snapshot: a list someone else can see has changed (promise (c)) | after the proof |
| K3  | forgets the rest | program `12345` with the single input `xs`, memory V1 | `xs` is never used, so it is given up at the start and A is freed; B is then never given up, and at the end B is still allocated with count 1 and no actual holder (promise (d)) | after the proof |
| K4  | frees a held cell | S2's program, memory V2 | A is freed while the outside holder still holds it, and in a later snapshot the outside holder's list cannot be read (promise (c)) | after the proof |
| K5  | never reuses | S1's program, memory V1 | answer `[8, 9]`; memory's record holds one creation and one release, of A, and no write in place: 1 allocation, 0 reuses, 1 free | after the proof |
| K6  | the approved rule | any program and memory | `runCounted` with the approved rule is the same function as the counted meaning with no departure switched on, shown by Lean for all programs and memories (`rfl`), and on S1 to S5 gives what those rows expect | after part 2 |

## Part 2 in detail

Fixed by the lead's plan for part 2, reviewed by Codex as oracle, before part 2
started.

### How the six rules are arranged

- `Trial/Counted.lean` defines a `Variant`: five true-or-false switches, one per
  departure below, and `Variant.approved`, with all five off. The counted
  meaning is `runCountedWith : Variant → Expr → Start → Outcome`. Each switch is
  read at exactly one place, written as "if the switch is on, the departure;
  otherwise the rule's own step", with a comment naming the `RULE.md` section
  of the rule's step.
- `Trial/Broken.lean` imports `Counted` and defines the public `Rule` with the
  six values of `INTERFACE.md` section 7; `Rule.variant`, which maps
  `.approved` to `Variant.approved` and each broken copy to the variant with
  exactly its own switch on; and
  `runCounted : Rule → Expr → Start → Outcome`, which is `runCountedWith` of
  that variant. The checks and the promises are stated about `Rule`, not about
  arbitrary combinations of switches.
- Imports: `Language` → `Plain`; `Language` → `Memory` → `Counted` → `Broken`;
  `Trial.lean` imports all five.

### The five departures, exactly

1. **Misreports reuse** (`.misreportsReuse`, the phase-1 control). Where the
   rule reuses a set-aside cell for a new cell (`RULE.md` 5, "Reusing"; 6e),
   this copy instead releases the set-aside cell (a real release in memory's
   record) and creates a fresh cell with the new item and link (a real
   creation). The rule's log records one reuse, of the fresh cell's address,
   and nothing else. The answer is unchanged.
2. **Reuses a shared cell** (`.reusesShared`). In the match's step 4
   (`RULE.md` 6b), the cell is set aside whenever the cell branch is taken, even
   when the match's holder is not the only one: its status becomes set aside
   with count 0, and its rest's holder moves to `t`, as in `RULE.md` 5. Other
   holders still point at it.
3. **Forgets the rest** (`.forgetsRest`). When a cell's count reaches zero and
   it is freed (`RULE.md` 5, "Freeing"), its link's holder on the rest is not
   given up.
4. **Frees a held cell** (`.freesHeld`). When a holder is given up (`RULE.md`
   4), the cell is freed (logged as a free, and its link given up in turn)
   even if its count after the decrease is above zero.
5. **Never reuses** (`.neverReuses`). In the match's step 4 the cell is never
   set aside: it always takes the path for a cell someone else holds (a used
   `t` gets a new holder on the rest, then the match's holder is given up,
   which frees the cell if that was its last holder).

### Shapes

- **Addresses** are `Nat`. A list is `Option` of an address: none is the empty
  list. Fresh addresses come from a counter that starts above every address in
  the starting memory and only increases, so a freed address is never handed
  out again.
- **Memory** holds the cells, the counter and memory's own record. Only the
  three memory operations (create, write in place, release) add to the record.
  The rule's log is a separate part of the run's state, added to only by the
  rule.
- **`Start`**: the cells (address, item, link, count), the inputs in order (a
  name with a number, the empty list or an address), and the outside holders
  (the empty list or an address). **`validStart`** checks: the program is
  well-formed for the kinds the inputs have (so an input of the wrong kind is
  refused, with the reason); no two cells share an address; nothing dangles; no
  cycles; every cell is reachable from an input or an outside holder; every
  count equals the number of holders the cell actually has. The walks for
  cycles and reachability are bounded by the number of cells, with the reason
  in a comment.
- **The counted meaning** is a big-step evaluator, by structural recursion on
  `Expr`. It carries, as plain data, the program text still to run after the
  current expression: a list of frames, each with the environment it will run
  in. That is what "last use" is judged from (`RULE.md` 4: "anywhere in the
  program text still to run, counting the rest of the surrounding
  computation"). A binding is used again if some free use of its spelling in
  the text still to run refers to that binding, not merely to a binding with
  the same spelling. Two details:
  - A frame waiting to run a `let` body must account for the name that body
    will bind: while `e1` of `let x = e1 in e2` runs, a use of `x` in `e2`
    refers to the new `x`, not to an outer one. In `let xs = xs in xs`, the
    use of `xs` in `e1` is the outer binding's last use.
  - Environments in frames refer to bindings by id; they hold nothing. Only the
    binding itself holds its holder, until that holder moves or is given up.
    Copying an environment into a frame never adds a holder.
- **Bindings** each carry a unique id, so that two bindings of one spelling are
  distinct in snapshots (D83), and a snapshot shows, for each binding, whether
  it still holds its holder or has given it up or passed it on.
- **Cascading frees** are bounded by the number of allocated cells (each round
  frees one), with the reason in a comment. Hitting the bound is a failure while
  running, never a default.
- **Set-aside cells** are a stack, each labelled with the id of the `match`
  branch it belongs to. A new cell takes the top one (the most recently set
  aside, `RULE.md` 6e). Since branches nest, every cell on the stack belongs to
  a running branch that encloses the build (6f); the code checks this, and a
  cell of a finished branch on the stack is a failure while running.
- **`Outcome`** as `INTERFACE.md` section 5: the result (an answer's raw value,
  refused before running, or failed while running with the operation that
  failed), the final memory, the log, memory's record and the snapshots.
  **`readBack`** follows links from an address, bounded by the number of cells;
  a missing cell, a set-aside cell or a cycle makes the list unreadable, with
  the reason.
- **Snapshots** (`INTERFACE.md` section 6) are taken after every event, each
  tagged with its kind. The kinds include at least: the start (after unused
  inputs are given up); a branch has just been chosen; the match's step 4 done;
  a new cell built; a holder given up; a cell freed; and, for each `match`
  branch, "the branch's value is worked out" (before its unused set-aside cells
  are freed), a snapshot after each of those frees, and "the branch's value is
  handed on" (after them). Each snapshot has the memory, the bindings in scope
  with their ids, values and whether they still hold a holder, the intermediate
  results with what they hold, the outside holders, the set-aside cells with
  their branch ids, and the kind of step.
