# Trial predictions

**Status: complete — all twenty-eight runs have answers, totals and
derivations; runs 9–11 have timing claims; the closing section is complete.**

Written by the prediction session on 30 Sep 2026, from the approved English
rule alone. No Lean or other program was written or run to calculate an answer
or count. References such as “6b” below are sections of `RULE.md`.

## Predicted answers and whole-run totals

Starting-memory construction and the caller's later handling of the answer
are outside the measured run (section 7). An allocation means new memory;
setting aside logs nothing; a reuse keeps the same allocated cell (section 5).

| Run | Predicted answer | Allocations | Reuses | Frees |
| --- | ---------------- | ----------- | ------ | ----- |
| 1 | `[2, 2, 3]` | 0 | 1 | 0 |
| 2 | `[2]` | 0 | 1 | 0 |
| 3 | `[]` | 0 | 0 | 0 |
| 4 | `[9223372036854775808]` | 0 | 1 | 0 |
| 5 | `[2, 2, 3]` | 1 | 0 | 0 |
| 6 | `[2, 1, 3]` | 0 | 2 | 0 |
| 7 | `[1]` | 0 | 1 | 0 |
| 8 | `[2, 1, 3]` | 1 | 1 | 0 |
| 9 | `[2, 3]` | 0 | 0 | 1 |
| 10 | `9` | 0 | 0 | 2 |
| 11 | `7` | 0 | 0 | 3 |
| 12 | `[0, 1, 2]` | 1 | 0 | 0 |
| 13 | `[1, 1, 2]` | 1 | 1 | 0 |
| 14 | `[1, 2, 2]` | 1 | 1 | 0 |
| 15 | `[3, 3, 4]` | 0 | 1 | 1 |
| 16 | `[2, 2]` | 0 | 1 | 0 |
| 17 | `[2]` | 0 | 0 | 1 |
| 18 | `[2, 2]` | 0 | 1 | 0 |
| 19 | `[2, 2]` | 0 | 1 | 0 |
| 20 | `[2]` | 0 | 0 | 1 |
| 21 | `[2, 2]` | 0 | 1 | 0 |
| 22 | `[2, 2]` | 0 | 1 | 0 |
| 23 | `[1, 3, 3]` | 0 | 2 | 0 |
| 24 | `[2, 2]` | 0 | 1 | 0 |
| 25 | true | 0 | 0 | 2 |
| 26 | `[1, 2, 2]` | 1 | 1 | 0 |
| 27 | `[5]` | 1 | 0 | 2 |
| 28 | `[-3]` | 0 | 1 | 0 |

## Derivations

These explain the totals. Their event order is not an additional acceptance
claim; only the table and the explicit timing claims below are predictions to
check. Cell labels refer to the starting-memory table for that run. Each final
list's holder goes to the caller, without freeing its cells (section 7).

### Run 1 — add one, three unshared cells

1. The last use of `xs` moves its holder to the match (4, 6b step 1).
   The match sets aside c1 and moves its link's holder on c2 to `t` (5, 6b
   step 4); neither operation is logged.
2. The item becomes 2 by adding 1 to 1 (2a). After working out the item and
   `t`, the build reuses c1 and moves `t`'s holder into its link (4, 6d–6f).
3. No unused set-aside cell remains to free (6g). The answer is `[2, 2, 3]`:
   no allocations, one reuse, no frees (5, 7).

### Run 2 — add one, one unshared cell

1. The last use of `xs` moves its holder to the match; c1 is set aside and its
   empty rest is named `t` (4, 5, 6b). The empty list has no holder or cell (3).
2. The build computes 1 + 1 and reuses c1 with item 2 and an empty link
   (2a, 6d–6f).
3. Cleanup has no unused set-aside cell (6g). The answer is `[2]`: no
   allocations, one reuse, no frees (5, 7).

### Run 3 — add one, empty input

1. Matching the empty `xs` chooses the empty-list branch. No cell is taken
   apart or set aside (3, 6b).
2. That branch returns `[]`, which holds no cell (3, 7). No build or free
   occurs: no allocations, no reuses, no frees.

### Run 4 — add one beyond a signed 64-bit number

1. The last use of the unshared `xs` sets aside c1, with empty rest (4, 5,
   6b).
2. Whole numbers are unlimited, so 9223372036854775807 + 1 is
   9223372036854775808 (2a). The build reuses c1 after both parts are worked
   out (6d–6f).
3. Cleanup has nothing left to free (6g). The answer is
   `[9223372036854775808]`: no allocations, one reuse, no frees (5, 7).

### Run 5 — add one while an outside holder keeps the original

1. The last use of `xs` moves its holder to the match. c1 still has the
   outside holder `keeper`, so the match cannot set it aside (4, 6b step 4).
2. Because the branch uses `t`, it gets a new holder on c2; the match gives
   up its holder on c1, leaving `keeper`'s holder (6b step 4). No count reaches
   zero, so there is no free (5).
3. The build computes 1 + 1 = 2 and moves `t`'s holder into its link. No
   set-aside cell is available, so it allocates one cell (2a, 4, 6d–6f).
4. The answer is `[2, 2, 3]`. The original `[1, 2, 3]` remains held by
   `keeper` (4, 7). Totals: one allocation, no reuses, no frees.

### Run 6 — swap two unshared front cells

1. The outer match takes the last-use holder of `xs`, sets aside c1, and
   moves its old link's holder on c2 to `t` (4, 5, 6b).
2. The inner match takes `t` at its last use, sets aside c2, and moves the
   holder on c3 to `u` (4, 5, 6b).
3. The inner build `[a | u]` finishes first: the outer build must finish its
   rest before choosing a cell (6a, 6d). It reuses c2, the most recently
   set-aside eligible cell, with item 1 and link c3 (4, 6e, 6f).
4. The build `[b | ...]` then reuses c1 with item 2 and link c2. Both builds
   are within the running inner and outer match branches (6d–6f).
5. Neither branch has an unused set-aside cell to free (6g). The answer is
   `[2, 1, 3]`: no allocations, two reuses, no frees (5, 7).

### Run 7 — swap when there is only one item

1. The outer match sets aside the unshared c1 and names its empty rest `t`
   (4, 5, 6b).
2. The inner match on `t` chooses its empty-list branch and sets aside
   nothing (3, 6b). Its build `[a | []]` may use the still-running outer
   branch's c1, so it reuses that cell with item 1 (6d–6f).
3. Neither branch has an unused set-aside cell left (6g). The answer is
   `[1]`: no allocations, one reuse, no frees (5, 7).

### Run 8 — swap with an outside holder on the second cell

1. The outer match sets aside c1, whose only holder is the last-use `xs`.
   Its link's holder on c2 moves to `t`, leaving c2 held by `t` and `keeper`
   (4, 5, 6b).
2. The inner match takes `t`'s holder. Because `keeper` also holds c2,
   c2 cannot be set aside. The used rest `u` gets a new holder on c3; the
   match gives up its holder on c2, leaving `keeper` (6b step 4).
3. `[a | u]` finishes before the surrounding build chooses a cell. It
   reuses the eligible outer cell c1, writing item 1 and link c3 (4, 6d–6f).
4. `[b | ...]` has no set-aside cell left, so it allocates a new front cell
   with item 2 and link c1 (6d–6f). Cleanup frees nothing (6g).
5. The answer is `[2, 1, 3]`, while `keeper` retains the original c2 and
   its `[2, 3]` list (4, 7). Totals: one allocation, one reuse, no frees.

### Run 9 — drop the first item

1. The match takes `xs` at its last use, sets aside c1, and moves its
   holder on c2 to `t` (4, 5, 6b).
2. The branch's value is `t`: its holder moves to the result, giving
   `[2, 3]` without building a cell (4).
3. After that value is worked out, and before handing it on, branch cleanup
   frees the unused set-aside c1 only; its old link was already detached
   (5, 6g). The answer keeps c2 and c3 (7).
4. Totals: no allocations, no reuses, one free.

### Run 10 — total the first two items

1. The outer match sets aside c1 and moves its holder on c2 to `t` (4, 5,
   6b).
2. The inner match takes `t` at its last use and sets aside c2. Its rest
   `u` is empty and unused, so giving it up frees nothing (3, 6b step 5).
3. The inner branch computes 4 + 5 = 9, with no cell build (2a, 10).
   After computing that value and before handing it to the outer branch,
   cleanup frees c2 only (5, 6g).
4. The outer branch now has value 9. Before handing it on, its cleanup
   frees c1 only (5, 6g). A number answer holds no cell (7).
5. Totals: no allocations, no reuses, two frees.

### Run 11 — take the first item and discard the rest

1. The match takes the last-use `xs`, sets aside c1, and transfers its old
   link's holder on c2 to `t` (4, 5, 6b).
2. The branch never uses `t`, so that holder is given up immediately,
   before running the branch (6b step 5). c2 reaches zero and is freed; its
   link then gives up c3's only holder, freeing c3 (5).
3. The branch computes its number value `h`, which is 7 (2, 6b step 6).
   c1 still holds nothing and remains set aside until branch cleanup frees
   it before handing on 7 (5, 6g). The number answer has no holder (7).
4. Totals: no allocations, no reuses, three frees.

### Run 12 — put zero on the front

1. The build works out `n = 0`, then `xs` (6a, 6d). This is `xs`'s last
   use, so its holder moves to the build (4).
2. No match has set aside a cell. The build allocates a new cell with item 0
   and moves the holder on c1 into its link (4, 6d–6f).
3. The answer `[0, 1, 2]` keeps that cell, c1 and c2 allocated (7).
   Totals: one allocation, no reuses, no frees.

### Run 13 — duplicate the first item

1. The match sets aside c1 at the last use of `xs` and moves its holder on
   c2 to `t` (4, 5, 6b).
2. The inner build `[h | t]` finishes before the outer build chooses its
   cell. It reuses c1 with item 1 and link c2 (4, 6a, 6d–6f).
3. The outer build `[h | ...]` has no remaining set-aside cell, so it
   allocates a new front cell with item 1 and a link to the inner result
   (4, 6d–6f). Cleanup frees nothing (6g).
4. The answer is `[1, 1, 2]`: one allocation, one reuse, no frees (7).

### Run 14 — build a changed list, then use the original again

1. In the first match, `xs` will be used again in the enclosing `let` body.
   The match gets an extra holder on c1, leaving `xs`'s holder in place
   (4, 6b step 1).
2. c1 is shared at the check and cannot be set aside. The used `t` gets
   an extra holder on c2, then the match gives up its holder on c1, leaving
   `xs` (6b step 4).
3. `[h + 1 | t]` computes item 2 and allocates a new cell, because no
   set-aside cell exists. Its link takes `t`'s holder on c2; the result's
   holder then moves to `ys` (2a, 4, 6d–6f). c2 has two holders: c1's old
   link and `ys`'s new front cell's link.
4. The second match takes `xs` at its last use. c1 has only that holder,
   so it is set aside; its old link's holder moves to the new branch's `t`
   (4, 5, 6b step 4).
5. This branch never uses its `t`, so the holder on c2 is given up at once.
   c2 stays allocated through the new front cell's link (5, 6b step 5).
6. `[h | ys]` reuses c1 with item 1 and link to `ys`'s front cell; `ys`'s
   holder moves into that link (4, 6d–6f). Cleanup frees nothing (6g).
7. The answer is `[1, 2, 2]`: one allocation, one reuse, no frees (7).

### Run 15 — add the front items of lists sharing a tail

1. The outer match takes `xs` at its last use, sets aside c1, and moves
   its old link's holder on c3 to `t`. c3 still has two holders: `t` and
   c2's link (4, 5, 6b).
2. The inner match takes `ys`'s holder on c2 and chooses the cell branch.
   The outer `t` is used only in this inner match's empty-list branch and
   nowhere afterwards. It is therefore given up before the sharing check;
   c3's count goes from two to one, so it is not freed (4, 5, 6b step 3).
3. c2 has only the match's holder, so it is set aside and its holder on c3
   moves to `u` (5, 6b step 4).
4. The build computes 1 + 2 = 3 and reuses c2, the newest available
   set-aside cell. `u`'s holder moves into its link (2a, 4, 6d–6f).
5. The inner branch has no unused set-aside cell. When the outer branch
   finishes with that same list value, it frees the unused c1 only; c1's
   former contents are detached (5, 6g).
6. The answer is `[3, 3, 4]`, using c2, c3 and c4 (7). Totals: no
   allocations, one reuse, one free.

### Run 16 — the first item is below five

1. The match sets aside unshared c1 and moves the holder on c2 to `t`
   (4, 5, 6b).
2. The condition 1 < 5 is true, so only the build branch runs. `t` is
   needed there, so it is kept (2b, 6a, 6c).
3. `[h + 1 | t]` computes item 2 and reuses c1. A cell set aside by the
   enclosing match is available inside its `if` (2a, 4, 6d–6f).
4. Cleanup frees nothing (6g). The answer is `[2, 2]`: no allocations,
   one reuse, no frees (7).

### Run 17 — the first item is not below zero

1. The match sets aside unshared c1 and moves its holder on c2 to `t`
   (4, 5, 6b).
2. The condition 1 < 0 is false, so only the branch returning `t` runs.
   `t`'s last-use holder moves to that branch's result; no cell is built
   (2b, 4, 6a, 6c).
3. When the enclosing match branch finishes, it frees the unused c1 only
   (5, 6g). The answer `[2]` keeps c2 (7).
4. Totals: no allocations, no reuses, one free.

### Run 18 — the first item equals the inclusive bound

1. The match sets aside unshared c1 and moves its holder on c2 to `t`
   (4, 5, 6b).
2. The condition 1 <= 1 is true. The selected branch uses `t` and builds
   item 1 + 1 = 2 (2a, 2b, 6a, 6c).
3. That build reuses c1 and moves `t`'s holder into its link (4, 6d–6f).
   Nothing remains set aside at cleanup (6g).
4. The answer is `[2, 2]`: no allocations, one reuse, no frees (7).

### Run 19 — the first item equals one

1. The match sets aside unshared c1 and moves its holder on c2 to `t`
   (4, 5, 6b).
2. The condition 1 == 1 is true. The selected branch uses `t` and builds
   item 1 + 1 = 2 (2a, 2b, 6a, 6c).
3. The build reuses c1 and moves `t`'s holder into its link (4, 6d–6f).
   Branch cleanup has no unused set-aside cell (6g).
4. The answer is `[2, 2]`: no allocations, one reuse, no frees (7).

### Run 20 — the first item does not equal seven

1. The match sets aside unshared c1 and moves its holder on c2 to `t`
   (4, 5, 6b).
2. The condition 1 == 7 is false. The selected branch returns `t`, moving
   its holder to the result and building no cell (2b, 4, 6a, 6c).
3. Match-branch cleanup frees c1 only, because it was set aside and unused
   (5, 6g). The answer `[2]` keeps c2 (7).
4. Totals: no allocations, no reuses, one free.

### Run 21 — give up the other name before checking sharing

1. `xs` is at its last use, so its holder moves to the match. c1 initially
   has two holders, the match's and `ys`'s (4, 6b step 1).
2. The match chooses the cell branch. `ys` is used only in the unchosen
   empty-list branch, so its holder is given up before checking c1. The count
   falls from two to one; there is no free (5, 6b step 3).
3. Now the match's holder is the only one, so c1 is set aside and its holder
   on c2 moves to `t` (5, 6b step 4).
4. The build computes item 1 + 1 = 2 and reuses c1, moving `t`'s holder into
   its link (2a, 4, 6d–6f). Cleanup frees nothing (6g).
5. The answer is `[2, 2]`: no allocations, one reuse, no frees (7).

### Run 22 — give up the other name when the `if` chooses

1. The condition 1 < 0 is false (2b). When the `if` selects its other
   branch, `ys` is no longer used anywhere still to run. Its holder on c1 is
   given up before the branch runs, leaving only `xs`; c1 is not freed
   (5, 6c).
2. The match then takes `xs` at its last use. It sets aside the now-unshared
   c1 and moves its holder on c2 to `t` (4, 5, 6b).
3. The build computes item 1 + 1 = 2 and reuses c1, transferring `t`'s
   holder into its link (2a, 4, 6d–6f). Cleanup frees nothing (6g).
4. The answer is `[2, 2]`: no allocations, one reuse, no frees (7).

### Run 23 — inner reuse, then a later outer build

1. The outer match sets aside unshared c1 and moves its holder on c2 to
   `t`; the inner match takes `t` at its last use, sets aside c2, and moves
   its holder on c3 to `u` (4, 5, 6b).
2. The inner build computes item 2 + 1 = 3 and reuses c2, the most recently
   set-aside eligible cell, linking it to c3 (2a, 4, 6d–6f).
3. Inner-branch cleanup has no unused cell of its own. c1 belongs to the
   outer branch, so it remains available there. The inner result's holder
   moves to `r` (4, 6f, 6g).
4. The later outer build `[a | r]` reuses c1 with item 1 and link c2,
   moving `r`'s holder into the link (4, 6d–6f). Outer cleanup frees nothing
   (6g).
5. The answer is `[1, 3, 3]`: no allocations, two reuses, no frees (7).

### Run 24 — the result has the same spelling as the input

1. The new `xs` does not exist until its starting value has been worked
   out. The match therefore uses the input `xs`, at that binding's last use
   (2e, 4).
2. The match sets aside c1 and moves its holder on c2 to `t` (5, 6b).
   The build computes item 1 + 1 = 2 and reuses c1, with `t`'s holder moving
   into its link (2a, 4, 6d–6f).
3. Cleanup has nothing to free (6g). The result's holder moves to the new
   `xs`, whose last use moves it to the answer (2e, 4).
4. The answer is `[2, 2]`: no allocations, one reuse, no frees (7).

### Run 25 — a true-or-false answer

1. The match takes the last-use `xs`, sets aside c1, and moves its holder
   on c2 to `t` (4, 5, 6b).
2. `t` is never used in the branch, so its holder is given up before the
   branch runs. c2 reaches zero and is freed (5, 6b step 5).
3. The comparison -3 < 0 produces true and performs no cell operation
   itself (2a–2c, 10). After that value is worked out, cleanup frees the
   unused set-aside c1 (5, 6g).
4. A true-or-false answer holds no cell (7). Totals: no allocations,
   no reuses, two frees.

### Run 26 — both parts of a build use the same input

1. The outer build works out its item before its rest (6a, 6d). In the
   item's match, `xs` is not at its last use: the rest's match still needs
   it. The match therefore gets an extra holder on c1 (4, 6b step 1).
2. c1 is shared, so it is not set aside. This branch never uses `t`, so
   `t` gets no new holder on c2. The match gives up its own holder on c1,
   leaving `xs`'s holder, and returns item 1 (6b step 4). There is no
   set-aside cell to clean up and no free (5, 6g).
3. The outer build now works out its rest. This match takes `xs` at its
   last use, sets aside the now-unshared c1, and moves its holder on c2 to
   its own `t` (4, 5, 6b).
4. The rest's build computes item 1 + 1 = 2 and reuses c1 with link c2
   (2a, 4, 6d–6f). That match finishes completely, with no unused cell to
   free (6a, 6g).
5. Only now does the outer build choose its cell. No set-aside cell is
   available, so it allocates a front cell with item 1 and link to the
   rest's result (4, 6d–6f).
6. The answer is `[1, 2, 2]`: one allocation, one reuse, no frees (7).

### Run 27 — an input that is never used

1. `xs` never appears in the program, so its input holder is given up before
   anything runs (7). c1 reaches zero and is freed; its link then gives up
   c2's only holder, freeing c2 (5). These are frees, not cells set aside
   for reuse (5, 9).
2. The build works out `n = 5` and the empty rest. No set-aside cell exists,
   so it allocates a cell holding 5 with an empty link (3, 6d–6f).
3. The answer is `[5]`: one allocation, no reuses, two frees (7). Even if
   an allocator later chooses an old address, these events cannot count as
   reuse (1, 5).

### Run 28 — subtraction can give a negative item

1. The last use of `xs` moves its holder to the match, which sets aside
   unshared c1 and names its empty rest `t` (4, 5, 6b).
2. Ordinary whole-number subtraction gives 2 - 5 = -3 (2a). After both
   parts are worked out, the build reuses c1 with item -3 and an empty link
   (6d–6f).
3. Cleanup frees nothing (6g). The answer is `[-3]`: no allocations,
   one reuse, no frees (7).

## Timing claims

These test the decision that an unused set-aside cell is freed when its
match branch finishes, after computing the value and before handing it on
(D90, `RULE.md` 6g). They are acceptance claims in addition to the totals.

“Just after the branch's value is worked out” means the snapshot at entry to
that branch's cleanup, before its unused set-aside cell is freed. “Just after
that value is handed on” means the snapshot after that branch's cleanup and
the transfer of its value to its surrounding computation or the caller.
`INTERFACE.md` section 6 exposes the branch-cleanup step, memory,
intermediate results and branch ownership of set-aside cells.

A cell marked **yes, set aside** must be present in the snapshot's memory,
with status set aside, zero holders and no held contents, and listed among
the set-aside cells with its owning match branch (3, 5). **No** means the
cell is absent from memory and the set-aside list. Identify each cell by its
starting address, not by its old item after detachment.

### Run 9 — the outer cell outlives computing the tail value

The branch is P3's cell branch, whose value is `t`, the list `[2, 3]`.

| Unused set-aside cell | Just after this branch's value is worked out | Just after that value is handed on |
| --- | --- | --- |
| c1, belonging to this match's cell branch | yes, set aside | no |

At the first moment, the intermediate result holds c2. At the second, the
answer's holder has gone to the caller. c2 and c3 remain live and allocated
at both moments (4, 7). They are not unused set-aside cells.

### Run 10 — both nested branch boundaries

P4's cell branch contains another match, so both boundaries are named here.
The inner cell branch computes `a + b`, the number 9, and hands that value
to the outer cell branch. The outer cell branch then hands the same number
to its surrounding computation, ultimately the caller.

| Unused set-aside cell | Just after the inner branch's value is worked out | Just after that value is handed on by the inner branch |
| --- | --- | --- |
| c1, belonging to the outer cell branch | yes, set aside | yes, set aside |
| c2, belonging to the inner cell branch | yes, set aside | no |

| Unused set-aside cell | Just after the outer branch's value is worked out | Just after that value is handed on by the outer branch |
| --- | --- | --- |
| c1, belonging to the outer cell branch | yes, set aside | no |
| c2, formerly belonging to the inner cell branch | no | no |

Inner cleanup frees only its own c2. It does not free the outer branch's
c1; that branch is still running (6f, 6g). Neither number result holds a
cell (7). These claims require snapshots between the two branch cleanups,
even though no arithmetic remains for the outer branch to perform.

### Run 11 — the unused rest is already gone, but the front is kept

The branch is P5's cell branch, whose value is `h`, the number 7.

| Unused set-aside cell | Just after this branch's value is worked out | Just after that value is handed on |
| --- | --- | --- |
| c1, belonging to this match's cell branch | yes, set aside | no |

c2 and c3 are already absent from memory at both moments: the unused `t`
was given up before the branch ran, freeing that detached tail (5, 6b
step 5). They were never set aside. The intermediate number 7 holds no
cell (7).

## Added examples

None. These predictions cover the twenty-eight approved runs only. No
timing claims beyond the required runs 9, 10 and 11 are added.

## What I was unsure of

These were close-reading choices between possible outcomes, settled by the
quoted words of the approved rule. None remains unresolved.

- **Whether starting or answer cells count as allocations or frees.**
  Section 7 says building starting memory “is not counted” and the answer's
  holder is “handed to the caller and not given up.” This rules out charging
  for the starting cells or freeing the returned list at run end.
- **Whether setting aside frees the old tail or keeps holding it.** Section 5
  says the link's holder “moves” to `t`, “the rest's count does not change,”
  and “the set-aside cell holds nothing.” This settles tail preservation in
  runs 1, 6 and 9, and why freeing c1 cannot free the returned tail in run 9.
- **Whether a never-used rest keeps memory until branch exit.** Section 6b,
  step 5 says its holder is “given up at once.” Section 5 then frees down
  the tail. In runs 11 and 25 the tail is freed before the branch value is
  worked out, while the set-aside front waits for cleanup.
- **Whether an unused rest gets a new holder when the matched cell is
  shared.** Section 6b, step 4 grants that holder only “if `t` is used in
  the branch.” Thus the first match in run 26 does not acquire a tail
  holder, and does not free the original list while `xs` still needs it.
- **Whether “last use” ignores the surrounding computation.** Section 4
  explicitly counts “the rest of the surrounding computation,” including
  the enclosing `let` body and the other build operand. Thus the first
  matches in runs 14 and 26 cannot set aside c1, whereas their second
  matches can. The example category “no reuse” does not override this rule
  or prohibit reuse at the later last use in run 14.
- **Whether a surrounding build reserves a cell before its inner build.**
  Section 6d says “after both its parts are worked out.” Thus in runs 6,
  8 and 13 the rest's inner build picks first. In run 13 it consumes c1,
  leaving the outer build to allocate.
- **Whether sharing the inner matched cell prohibits using an outer
  set-aside cell.** Section 6f permits “any set-aside cell” of a still-running
  enclosing branch. Thus run 8's inner build reuses c1 even though c2 is
  kept by an outside holder; the following build must allocate.
- **Which cell wins when both nested matches set one aside.** Section 6e
  chooses “the most recently set aside.” In run 6 the first inner build
  takes c2, then the next takes c1. In run 23 the inner build takes c2,
  preserving c1 for the later outer build.
- **Whether inner cleanup disposes of every available cell, including an
  outer one.** Section 6g ties freeing to “the `match` branch it belongs to,”
  and 6f says a cell belongs to the branch its match chose. Hence run 10's
  inner cleanup frees c2 while c1 waits for outer cleanup; run 23's outer
  c1 remains available after the inner match returns.
- **Whether a cell with no possible reuse is freed before computing the
  branch value.** Section 6g requires freeing “after the branch's value is
  worked out and before that value is handed on.” This settles the required
  timing claims on runs 9–11. Its alternative of freeing as soon as the
  remaining text builds no cell is not the chosen rule.
- **Whether an alias used only in an unchosen branch keeps preventing reuse.**
  Section 6b, step 3 gives up dead names before step 4's sharing check;
  section 6c gives them up “before the branch runs.” This settles reuse
  in run 21's match and run 22's `if`.
- **Whether the outer `t` in run 15 stays alive through the inner cell
  branch.** Section 6b, step 3 includes names used “only in the other
  branch.” Once the inner cell branch is chosen, outer `t` has no later
  use, so its holder is given up before c2 is taken apart. c3 remains
  allocated through c2's link, then through `u` and the answer's link.
- **Whether reusing the spelling `xs` makes the input remain needed in
  run 24.** Section 2e says “a name” means “one binding, never a spelling,”
  and “A new name begins after its starting value is worked out.” The
  initial match uses the old binding at its last use; the final name uses
  the new binding. This permits the same reuse as run 1.
- **Whether overflow, natural-number subtraction, or a forbidden boolean
  result changes an answer.** Section 2a requires unlimited whole numbers
  and ordinary subtraction; section 2c permits true-or-false answers. Thus
  run 4 exceeds the signed 64-bit maximum, run 28 gives -3, and run 25
  returns true without a cell holder.
- **Whether freeing a never-used input makes its cells available as reuses.**
  Section 7 releases such inputs “before anything else runs”; section 9
  says setting aside happens “only in a `match`.” Section 1 calls freeing
  then replacing a cell “a free plus an allocation, never ... a reuse.”
  Thus run 27 frees both input cells and allocates its answer cell.
