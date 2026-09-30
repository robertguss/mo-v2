# The trial's reuse rule, with its fine details

**Status: draft, 27 Sep 2026, for Robert's approval.** Written by the lead for
the trial's phase 1, step 1 (`PLAN.md`, "How the trial runs"). The base rule in
section 1 is already approved (D74: one fixed reuse-and-release rule decides
where cells are reused and released; D78: the trial plan is approved). Every
other section is a **proposed clarification; Robert's choice**, unless it is
marked decided. Nothing here is decided until he decides it, one question at a
time.

Why this document matters: in step 2, Codex writes the predictions (each
example's answer and its numbers of allocations, reuses and frees) from this
English rule alone, before any Lean exists. So the rule has to be exact enough
that two careful readers can never run a program differently. Section 10 is the
check of that.

What this document does not contain: the example programs (they are in
`EXAMPLES.md`), and any answer or count for them (those are Codex's
predictions). The illustrations in section 8 show single steps of memory, never
a whole example.

## 1. The approved base rule

Quoted from `PLAN.md`, "The two meanings" (approved, D78). The phrases marked
**[flag n]** are ones a careful reader could take two ways; the section named
settles each one.

> - Memory is a set of list cells. Each cell holds a number, a link to the rest
>   of the list (another cell, or the empty list) and a holder count.
> - Holders are names in the program that will still be used, links from other
>   cells, and outside holders (for example a caller keeping the old version).
> - A holder is given up right after its **last use [flag 1: section 4]**.
>   Whether a use is the last is judged from the program text still to run, so
>   the rule applies as the program runs, without knowledge of the future. A
>   cell whose **count reaches zero is freed [flag 2: section 5]**, and its link
>   to the rest is given up in turn.
> - When a `match` takes a cell apart at its last use and nobody else holds the
>   cell, the cell is set aside and stays allocated. **The next new cell [flag
>   3: section 6e] built in that branch [flag 4: section 6f]** reuses it. If the
>   branch builds no new cell, the set-aside cell is freed.
> - When someone else holds the cell, it is not set aside and cannot be reused:
>   its count goes down by one, and the parts taken out get holders of their
>   own. A new cell is new memory only when no set-aside cell is available to it
>   (for example, one set aside by an enclosing `match` may still be); which
>   set-aside cells a new cell may take is part of the fine details below.
> - Every allocation, reuse and free is logged, and the log must match what
>   actually happened to memory: a reuse keeps the same, already allocated cell,
>   and freeing a cell and then building a replacement counts as a free plus an
>   allocation, never as a reuse.

Nothing below changes this rule. If an option would change it, the option says
so ("reopens the approved rule").

## 2. The trial language, exactly

These settle what the plan's list of language features means. They are about the
trial only, not decisions about Mo (numbers are design choice 10, D58, and
syntax is deferred, D35). The notation is a stand-in, chosen to read like Ruby
and Elixir.

| Written as                                | Means                                                                                           |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `7`, `-3`                                 | a whole number                                                                                  |
| `a + b`, `a - b`                          | adding and subtracting whole numbers                                                            |
| `a == b`, `a < b`, `a <= b`               | comparing two whole numbers; the result is true or false                                        |
| `[]`                                      | the empty list                                                                                  |
| `[h \| t]`                                | build one cell: item `h` (a number) in front of the list `t`                                    |
| `let x = e1 in e2`                        | work out `e1`, call it `x`, then work out `e2`                                                  |
| `if c then e1 else e2 end`                | `c` must be true or false                                                                       |
| `match e do [] -> e1; [h \| t] -> e2 end` | if the list `e` is empty, `e1`; otherwise `h` is its first item and `t` the rest, and then `e2` |
| input names, e.g. `xs`, `n`               | the program's starting values, given by the example                                             |

Proposed clarifications, except where marked decided. 2a, 2b, 2c and 2e are each
Robert's choice; 2d follows from a promise already in the plan.

- **2a. Whole numbers.** **Decided (D79, 30 Sep 2026):** unlimited in size and
  may be negative; `a - b` is ordinary subtraction, so `2 - 5` is `-3`. The
  options were:
  - unlimited integers (the one chosen; Python, Ruby, Elixir, Haskell's `Integer`,
    Lean's `Int`);
  - natural numbers that stop at zero (Lean's `Nat`), where `2 - 5` is `0`,
    which could steer an `if` differently from what a reader expects;
  - fixed-size numbers (Rust's `i64`, C's `int`), which bring in overflow.

  Unlimited integers keep the trial away from design choice 10 (how Mo
  represents numbers, D58) and from overflow.

- **2b. Comparisons.** **Decided (D80, 30 Sep 2026):** `==`, `<` and `<=`, on
  numbers only; lists cannot be compared. The options were:
  - these three (the one chosen): enough to write every example, since `a > b`
    gives the same true or false as `b < a`. Swapping the sides also swaps the
    order in which they are worked out, so when working out a side touches
    lists, the two spellings can differ in their memory events (Codex's
    correction);
  - all six (`==`, `!=`, `<`, `<=`, `>`, `>=`, as in Ruby, Python, Elixir),
    friendlier to read but more cases for the proof to cover;
  - also comparing lists (as Elixir, Python and Haskell allow), which would make
    comparison a use of a list and so a memory event. Not proposed: it adds a
    kind of list use the trial does not need.
- **2c. True and false.** They come only from comparisons, can be named with
  `let`, and are used as `if` conditions. **Decided (D82, 30 Sep 2026, by the lead and Codex under
  Robert's delegation, D81): a program's answer may be a number, a list, or true
  or false.** Nothing else is added: no written true or false, no logical
  operators, no true-or-false inputs and no lists of them. Working out a
  true-or-false answer can still reuse or free cells, like any other part of a
  program; section 7 says how the run ends. The lead first proposed number or
  list only; Codex argued that the language already works out and names these
  values, so forbidding them as an answer adds a special restriction without
  removing anything, and the lead agreed. The options were:
  - number or list (the lead's first proposal): adds one line to the plan's definition of a
    well-formed program. This restriction is specific to the trial, to keep it
    small; the lead knows of no real language that forbids a true-or-false
    result;
  - any kind, true or false included (the one chosen), as in general-purpose
    languages (Ruby, Python, Rust, Haskell): the language is slightly bigger,
    and a true-or-false answer itself holds no cell.
- **2d. Every `match` has exactly one empty-list branch and one cell branch.**
  This is not a new choice: the plan promises that a well-formed program never
  gets stuck, and a `match` with a missing branch would get stuck on the list it
  does not cover. (Real languages differ: Rust refuses a `match` that misses a
  case; OCaml and Haskell only warn and fail when the case happens.)
- **2e. Names that reuse a spelling.** **Decided (D83, 30 Sep 2026, by the lead
  and Codex under Robert's delegation, D81):** allowed. A use of a name refers
  to its nearest enclosing binding, and an inner `let` or `match` may reuse a
  spelling, which then hides the outer one (Rust, OCaml, Elixir, Haskell allow
  this). The alternative is to refuse it, as Java does for local names inside
  one method, which adds a rule to "well-formed". In this rule "a
  name" always means one binding, never a spelling: two names spelled alike are
  two different names. Two consequences (Codex's additions):
  - A new name begins after its starting value is worked out. In
    `let x = e1 in e2`, a use of `x` inside `e1` refers to the outer `x`; the
    new `x` exists only in `e2`. Likewise the names a `match` branch introduces
    exist only in that branch.
  - Hiding a name neither gives up its holder nor keeps it. The outer name is
    given up right after its own last use, as always: if it is used again after
    the inner name's part of the program ends, it keeps its holder until then;
    if it is not, it was already given up, and uses of the inner name do not
    delay that.

## 3. What a counted run keeps track of

At every moment the run has:

- **Memory:** the cells. Each cell has an address, an item (a number), a link
  (another cell's address, or the empty list), a holder count, and a status:
  **live** or **set aside**.
- **Names in scope,** each with its value: a number, true or false, the empty
  list, or a cell's address. A name whose value is a cell address holds one
  holder on that cell while it is still to be used.
- **Intermediate results:** a list that part of the program has produced and
  that its surrounding part has not yet taken (for example the new cell
  `[h | t]` produces, before the `let` around it names it, or the list a `match`
  is about to take apart). Each holds one holder.
- **The set-aside cells,** each labelled with the `match` branch it belongs to.
- **The record of cell operations:** every allocation, reuse and free, in order,
  as memory performed them.
- **Outside holders:** fixed by the starting memory, never given up.

The empty list is not a cell: nothing holds it and it is never freed.

## 4. Who holds what, and when a holder moves (flag 1)

**"Last use" means:** a use of a name is its last use if the name does not
appear anywhere in the program text still to run, counting the rest of the
surrounding computation (for example the rest of an enclosing `let` body, or the
other operand still waiting in `[h | t]`), not only the current branch. This
needs only the program text, never the future.

Every use of a list-valued name is one of four kinds: the list matched by a
`match`, the rest `t` in `[h | t]`, the value of a `let`, or the program's
answer. (Lists appear nowhere else: they cannot be added or compared.) So:

| Situation                                                     | What happens to holders                                                                                                                                                                          |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| A list-valued name is used, and it is the **last use**        | Its holder **moves** to whatever uses it. No count changes.                                                                                                                                      |
| A list-valued name is used, and it **will be used again**     | The user gets a **new holder**: the cell's count goes up by one. The name keeps its own. (This covers `let y = x` while `x` is still needed, and building `[1 \| x]` while `x` is still needed.) |
| An expression produces a list                                 | The result holds one holder until its surrounding part takes it; taking it **moves** the holder.                                                                                                 |
| `let x = e1 in e2`                                            | The holder of `e1`'s result moves to `x`. If `x` is never used in `e2`, `x` gives up its holder at once.                                                                                         |
| `[h \| t]` builds a cell                                      | The holder of `t` moves into the new cell's link. The new cell starts with one holder: the result.                                                                                               |
| A program input                                               | Holds the holder the starting memory gave it. An input never used anywhere is given up before anything else runs (section 7).                                                                    |
| An outside holder                                             | Never given up.                                                                                                                                                                                  |
| The program's answer                                          | Its holder is handed to the caller (section 7).                                                                                                                                                  |
| A name used along the other branch of an `if` or `match` only | Given up when the branch is chosen (section 6b and 6c).                                                                                                                                          |

"Given up" always means: the cell's count goes down by one, and if it reaches
zero the cell is freed (section 5).

## 5. Setting a cell aside, reusing it, freeing it (flag 2)

**Freeing.** When a cell's count reaches zero it is freed: the record logs a
free of that cell, and then its link gives up its holder on the rest, which may
free the next cell, and so on down the list. (Freeing the front cell before the
rest is an order convention for the record; it changes no totals.)

**Setting aside: the one exception to "count reaches zero, freed".** When a
`match` takes a cell apart and the match's own holder (6b, step 1) is the cell's
only holder, the cell is not freed. Instead, in one step:

- the cell's status becomes **set aside**, with no holders;
- its old contents are detached: the holder its link had on the rest **moves**
  to the name given to the rest (`t`), so the rest's count does not change; the
  set-aside cell holds nothing;
- nothing is logged: setting aside is neither a free nor a reuse.

**Reusing.** When a new cell `[h | t]` is built and a set-aside cell is
available to it (sections 6e and 6f), that same cell is written with the new
item and link, its status becomes live with one holder, and the record logs a
**reuse** of that address.

**Disposing of an unused set-aside cell** (section 6g). The record logs a
**free** of that cell. Only the cell itself is freed: its old contents were
detached when it was set aside, so nothing further is given up.

This is how Lean 4 treats the same situation (its reset and reuse, described in
"Counting Immutable Beans", Ullrich and de Moura, 2019, section 4): the kept
cell is separated from its former contents before it is reused.

## 6. The order of events

Each detail below is a separate choice for Robert, with the options and one
recommendation.

### 6a. The order in which parts of a program run

**Decided (D84, 30 Sep 2026): left to right.** In `a + b`, comparisons and
`[h | t]`, the left part is worked out before the right. In `let x = e1 in e2`,
`e1` before `e2`. In `match` and `if`, the matched list or the condition before
the branch. Each part finishes completely before the next starts, and only the
chosen branch of an `if` or `match` runs; the other branch never runs (Codex's
clarifications).

The options were:

- **Left to right** (Java, C#, Rust, Python). Readers expect it.
- **Right to left** (what OCaml's compiler does in practice).
- **Unspecified** (C, Scheme, and OCaml's language definition). This would let
  two readers predict different orders, which the trial cannot allow.
- **Only when needed** (Haskell): a part runs only if its value is used. A much
  bigger change, since some parts would never run and the memory rules would
  differ (Codex's addition).

Order matters here because building a cell can use up a set-aside cell, so which
part builds first decides which cell it gets.

### 6b. The order inside a `match`

**Decided (D85, 30 Sep 2026)**, in this order:

1. Work out the matched list. Like every list an expression produces (section
   4), it comes with one holder, **the match's holder**, which the `match`
   always uses up: if the matched list is a name at its last use, the name's
   holder moves to the match; if the name will be used again, the match gets a
   new holder (count +1) and the name keeps its own.
2. Choose the branch: the empty-list branch if the list is empty, otherwise the
   cell branch.
3. Give up the holders of every name that will not be used from here on in the
   chosen branch or after the `match` (for example a name used only in the other
   branch). The match's own holder is not included; it is handled in step 4.
   Several are given up in the order their names were bound, oldest first (an
   order convention; it changes no totals).
4. **Only in the cell branch,** take the cell apart:
   - if the match's holder is now the cell's only holder (its count is 1), **set
     it aside** (section 5): the rest's holder moves to `t`;
   - otherwise, if `t` is used in the branch, `t` gets a new holder on the rest
     (its count goes up by one); then the match's holder is given up (the count
     goes down by one and cannot reach zero, since someone else holds it).

   In the empty-list branch there is no cell: no check, no setting aside, no
   parts (and the empty list has no holder to give up).

5. If `t` is never used in the branch and received the rest's holder in step 4,
   that holder is given up at once.
6. Run the branch.

**Why step 3 comes before step 4 matters.** Suppose two names, `xs` and `ys`,
both hold the same first cell (its count is 2), the program matches on `xs` at
its last use (so the match's holder is `xs`'s), and `ys` is used only in the
branch not taken.

| Order                        | At the check, the cell's count is | So the cell is                                   | The branch's first new cell is (no other set-aside cell available) |
| ---------------------------- | --------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------ |
| Chosen: give up `ys` first   | 1                                 | set aside                                        | a reuse                                                            |
| Alternative: check first     | 2                                 | not set aside; `ys` is then given up, freeing it | a free plus a new allocation                                       |

By the lead's reasoning both orders are safe; that is not yet proven, and the
trial's proof must show that giving up those names cannot destroy anything still
needed (Codex's caution). The chosen order reuses more, and it follows the
rule's own wording: `ys`'s last use is already behind the program, so it is
given up before the cell is looked at. A third option, checking, giving up and
then checking again, gives the same result with an extra check (Codex's
addition).

### 6c. A name used in only one branch of an `if` (flag: the plan's fourth fine detail)

**Proposal: given up as soon as the branch is chosen,** before the branch runs:
work out the condition, choose the branch, give up (oldest first) every name
that will not be used from here on, then run the branch. The same step 3 appears
inside `match` (6b).

Options:

- **At the start of the branch that does not use it** (the proposal; Perceus,
  the counting behind Koka, places these releases at the start of branches).
  This is "right after its last use" read exactly, since the last use is behind
  the program once the other branch is chosen.
- **At the end of that branch.** Keeps memory longer, and can stop a reuse
  inside the branch that the proposal would allow.
- **After the whole `if`.** The same, for longer.
- **At the end of the name's scope** (the end of the `let` or `match` branch
  that bound it), which can be much later than the `if`. This is how Rust drops
  a local and how C++ destroys an automatic variable, including their
  reference-counted pointers (`Rc`, `shared_ptr`).

The last three all delay the release past the last use, so each would reopen the
approved rule's "a holder is given up right after its last use".

### 6d. When a new cell picks a set-aside cell

**Proposal: after both its parts are worked out.** For `[h | t]`: work out `h`,
then `t`, then choose a set-aside cell (6e) or allocate.

Options: after the parts (the proposal), or when the building starts, before its
parts. The difference shows when a part builds cells itself: with the proposal,
the inner cells are built first and pick first. Koka and Lean 4 also build a
cell only once its parts are values, but they choose which taken-apart cell it
reuses in advance, from the program text (see 6e), so they are not a precedent
for when a run-time choice is made; the proposal rests on its simplicity (a cell
is chosen at the moment it is written).

### 6e. Which set-aside cell a new cell takes, when several are available (flag 3)

**Proposal: the most recently set aside** of those available to it (6f).

Options:

- **Most recently set aside.** Simple; needs no look-ahead; usually the cell
  from the innermost `match`, which is usually the cell the program just took
  apart.
- **Oldest first.** Equally simple; favours the outer `match`'s cell.
- **Only the nearest enclosing `match`'s cell.** A new cell can then never take
  an outer cell. This would reopen the approved rule, which says an enclosing
  `match`'s cell may still be available.
- **A pairing fixed from the program text.** This is what Koka (Perceus) and
  Lean 4 do: the compiler decides in advance which construction reuses which
  taken-apart cell, and at run time checks only whether that cell turned out to
  be unshared. If the paired cell is shared, that construction allocates, even
  when another set-aside cell is free. So choosing at run time (any of the first
  three options) is not the same rule as Koka's or Lean's, and can reuse in
  cases where they would allocate. It also means the trial's rule is not claimed
  to match Koka or Lean.

The recommendation rests on its own merits: it is the simplest rule that runs
with no look-ahead and uses up the cells closest to where they were taken apart.
The first two options are both safe, but they can change the totals, not only
which cell is reused. Suppose an outer `match` sets aside cell A, a `match`
inside its branch sets aside cell B, the inner branch builds one cell, and after
the inner `match` the outer branch builds one more (other clean-up in the
program is left out):

| Choice                  | Inner build takes | When the inner branch ends | Outer build             | Events for A, B and the two builds |
| ----------------------- | ----------------- | -------------------------- | ----------------------- | ---------------------------------- |
| Most recently set aside | B                 | nothing left to free       | takes A                 | 2 reuses                           |
| Oldest first            | A                 | B is freed                 | nothing left: allocates | 1 reuse, 1 free, 1 allocation      |

Most recently set aside keeps each branch's own cell for that branch, so an
outer cell stays available for the outer branch.

### 6f. Which set-aside cells a new cell may take at all (flag 4)

**Proposal:** a cell set aside by a `match` belongs to the branch that `match`
chose. A new cell may take any set-aside cell belonging to a branch that is
still running and that encloses it: its own branch, or an outer `match`'s branch
it sits inside. Never a cell whose branch has already finished (by then the cell
has been freed, 6g). An `if`'s branches are not places cells belong to; a cell
set aside in a `match` branch stays available inside any `if` within it.

This is how the proposal reads the approved words "the next new cell built in
that branch".

### 6g. When an unused set-aside cell is freed

**Proposal: when the `match` branch it belongs to finishes,** after the branch's
value is worked out and before that value is handed on. Several are freed newest
first (an order convention).

Options:

- **When its branch finishes** (the proposal). Simple to state and to check.
- **As soon as the rest of the branch's text builds no cell.** Frees memory
  earlier.

Under the proposal's other rules (a set-aside cell holds nothing, 5; only
branches still running can use it, 6f), these two options free the same cells
and differ only in when: the totals of allocations, reuses and frees are the
same. This depends on "the rest of the branch's text" counting cells that the
surrounding computation will still build inside the branch.

## 7. Where a run starts and ends

- **What is measured:** from the start of the run to its end. Building the
  starting memory is not part of the run and is not counted.
- **Start:** each input holds the holders the starting memory gave it. Inputs
  never used anywhere in the program are given up first, in the order the inputs
  are listed, before anything else runs.
- **End:** the run ends when the program's answer is worked out, which includes
  every clean-up the rule requires on the way (holders given up, unused
  set-aside cells freed). Nothing else is released after that.
- **The answer:** if it is a cell, its one holder is handed to the caller and
  not given up; the cell and everything it links to stay allocated. If it is a
  number, true or false, or the empty list, the value is returned, and no cell
  holder is handed on.
- **Outside holders** keep their holders throughout; the lists they keep stay
  allocated.
- What the caller later does with the answer is outside the run.

So at the end, the cells still allocated should be exactly those reachable from
the answer and from the outside holders: that is promise (d) in the plan.

## 8. Illustrations: single steps

Each shows one step of memory in isolation, written as a table of cells
(address: item, link, holder count, status). None is a whole program, and none
is one of the examples in `EXAMPLES.md`.

**8.1 Setting aside, then reusing.** Before: the name `xs` holds cell A (A: 4,
links to B, count 1, live), and A is the only holder of B (B: 9, links to empty,
count 1). A `match` on `xs` at its last use takes A apart in the cell branch,
naming the parts `h` and `t`.

| After the match's step 4 | A                                   | B                               |
| ------------------------ | ----------------------------------- | ------------------------------- |
|                          | set aside, 0 holders, holds nothing | 9, empty, count 1 (held by `t`) |

Nothing is logged. When the branch later builds a cell with some item `k` and
some rest `r` (any number and any list), and A is the set-aside cell it takes
(6e), A becomes live with item `k`, links to `r`, count 1; the holder of `r`
moved into A's link, so `r`'s count does not change. Logged: one reuse of A.

**8.2 Taking apart a cell someone else holds.** Before: `xs` holds A (count 2:
`xs` and an outside holder). A `match` on `xs` at its last use; `t` is used in
the branch. Step 4: `t` gets a new holder on B (B's count 1 to 2), then `xs`'s
holder is given up (A's count 2 to 1). A is not set aside. A cell built in the
branch cannot take A; it takes another available set-aside cell or allocates.

**8.3 Using a name that will be used again.** `let y = xs in ...` where `xs` is
used later: A's count goes up by one; `xs` and `y` each hold one holder. Nothing
is logged. When each is last used, its holder moves or is given up by the rules
above.

**8.4 Disposing of a set-aside cell, and freeing a detached rest.** Two separate
steps, each after a match like 8.1's. (i) If `t` is not used anywhere in the
branch, its holder on B is given up in the match's step 5: B's count goes to 0
and B is freed at that moment (logged: free of B). A is unaffected, since it
holds nothing. (ii) If A is still set aside when the branch finishes, A is freed
then (logged: free of A only; nothing further is given up).

**8.5 Matching on a name that will be used again.** Before: `xs` holds A (count
1), A links to B (count 1). A `match` on `xs`, where `xs` is used again after
the `match`; `t` is used in the branch. Step 1: the match gets a new holder on A
(count 1 to 2); `xs` keeps its own. Step 4: the match's holder is not the only
one, so A is not set aside; `t` gets a new holder on B (count 1 to 2); the
match's holder is given up (A's count 2 to 1). Immediately after step 4, before
the branch runs, A has one holder (`xs`) and B two (A's link and `t`). Nothing
is logged in these steps.

**8.6 The order case in 6b** is shown there as a table.

## 9. Limits of the rule (for the trial's Q3)

Recorded now so that a refusal or an extra allocation later can be traced to the
rule rather than to the program:

- No reuse across a finished branch: a cell set aside in a `match` branch is
  freed when that branch ends. A cell built after that `match` cannot take it;
  it takes another set-aside cell of a branch still running around it, if there
  is one, and otherwise is a fresh allocation.
- Setting aside happens only in a `match`: a holder given up any other way (for
  example a name used only in the branch not taken) never makes a set-aside
  cell. The count goes down by one, and the cell is freed only if that was its
  last holder.
- Run-time choice (6e) is not Koka's or Lean's compile-time pairing, so the
  trial's counts are not predictions about those compilers.

## 10. Check: one transition for every operation

Every operation and boundary, with its one proposed transition. If any row could
be read two ways, the rule is not ready.

| Operation or boundary                     | Transition (proposed)                                                                                                                                                                                                                                                                                                                                                                                                                           | Section |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| Start                                     | Inputs hold their given holders; inputs never used are given up, in input order                                                                                                                                                                                                                                                                                                                                                                 | 7       |
| Use of a list name, last use              | Holder moves to the user                                                                                                                                                                                                                                                                                                                                                                                                                        | 4       |
| Use of a list name, used again later      | Count +1; the user gets the new holder                                                                                                                                                                                                                                                                                                                                                                                                          | 4       |
| Number, comparison, `+`, `-`              | Operands left to right, including any cell operations inside them; the arithmetic or comparison itself performs none                                                                                                                                                                                                                                                                                                                            | 6a      |
| `let x = e1 in e2`                        | `e1`; its value goes to `x` (a list cell's holder moves to `x`); if `x` holds a cell and is unused in `e2`, that holder is given up at once; then `e2`                                                                                                                                                                                                                                                                                          | 4, 6a   |
| `if c then e1 else e2 end`                | `c`; choose branch; give up names dead from here on (oldest first); run branch                                                                                                                                                                                                                                                                                                                                                                  | 6c      |
| `match e do ... end`                      | `e`; the match takes the one holder that `e`'s result comes with (a name at its last use moves its holder; a name used again adds one; a computed list already has one); choose branch; give up names dead from here on; cell branch: if the match's holder is the only one, set aside, else new holder for a used `t` and give up the match's holder; unused `t` given up; run branch; free the branch's unused set-aside cells (newest first) | 6b, 6g  |
| `[h \| t]`                                | `h`, then `t`; take the newest available set-aside cell (reuse) or allocate; `t`'s holder moves into the link; count 1                                                                                                                                                                                                                                                                                                                          | 6d, 6e  |
| Set aside                                 | Status set aside, 0 holders, contents detached, rest's holder moves to `t`, nothing logged                                                                                                                                                                                                                                                                                                                                                      | 5       |
| Reuse                                     | Same address, new item and link, live, count 1; logged reuse                                                                                                                                                                                                                                                                                                                                                                                    | 5       |
| Dispose of unused set-aside cell          | Logged free of that cell only                                                                                                                                                                                                                                                                                                                                                                                                                   | 5, 6g   |
| Holder given up                           | Count −1; at zero: logged free, then its link is given up (and so on down)                                                                                                                                                                                                                                                                                                                                                                      | 4, 5    |
| Which set-aside cells a new cell may take | Those of running `match` branches enclosing it                                                                                                                                                                                                                                                                                                                                                                                                  | 6f      |
| End                                       | The answer's holder (if a cell) goes to the caller; nothing else released after                                                                                                                                                                                                                                                                                                                                                                 | 7       |
| Outside holders                           | Never given up                                                                                                                                                                                                                                                                                                                                                                                                                                  | 4, 7    |

## Questions for Robert

In order, one at a time; each is a proposal with a recommendation:

1. Whole numbers: unlimited, and may be negative (2a). **Decided: yes (D79).**
2. Comparisons: `==`, `<` and `<=`, on numbers only (2b). **Decided: yes
   (D80).**
3. A program's answer is a number or a list (2c). **Decided otherwise: true or
   false is also allowed (D82, by the lead and Codex under D81).**
4. Names may reuse a spelling, and then hide the outer one (2e). **Decided: yes
   (D83, by the lead and Codex under D81).**
5. The order in which parts run: left to right (6a). **Decided: yes (D84).**
6. Inside a `match`: names no longer needed are given up before the cell is
   checked for sharing (6b). **Decided: yes (D85).**
7. A name used in only one branch is given up as soon as the branch is chosen
   (6c).
8. A new cell picks its set-aside cell after its parts are worked out (6d).
9. Which set-aside cell: the most recently set aside (6e), from branches still
   running that enclose it (6f).
10. An unused set-aside cell is freed when its branch finishes (6g).
11. Approve the rule as a whole: what a run keeps track of, who holds what and
    when a holder moves, setting aside, reusing and freeing (sections 3 to 5),
    and where a run starts and ends (7).
