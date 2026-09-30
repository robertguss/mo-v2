# The trial's examples

**Status: draft, 30 Sep 2026, for Robert's approval.** Written by the lead for
the trial's phase 1, step 1 (`PLAN.md`, "How the trial runs"). The rule these
programs run under is `RULE.md`, approved on 30 Sep 2026 (D91: the reuse rule is
approved as a whole).

**What is here:** each example's exact program, its inputs and its starting
memory (who holds what before the run starts).

**What is deliberately not here:** any answer, any number of allocations, reuses
or frees, and any walk-through of a run. Those are the predictions. Codex writes
them from `RULE.md` alone, in a separate session, after Robert approves this
file (plan step 2). The lead does not write or edit them.

The example names and the "covers" lines say what each example is aimed at, in
the plan's own words for its categories (`PLAN.md`, "The examples"). They are
targets, not predictions: whether an example behaves as its category suggests is
for the predictions and the run to say.

## How to read an example

- **Program.** Written in the notation of `RULE.md` section 2. Round brackets
  only group; they are not an operation.
- **Inputs.** Listed in order. The order matters for one thing only: inputs
  never used are given up in this order (`RULE.md` section 7).
- **Starting memory.** One row per list cell. A list such as `[1, 2, 3]` is
  three cells: the first holds 1 and links to the second, and so on; the last
  links to the empty list, written `[]`. "Holders" counts who holds the cell at
  the start: an input name, the link of another cell, or an outside holder (for
  example a caller keeping the old list, who never lets go).
- **Unshared** means every cell has exactly one holder.

Several examples run the same program on different starting memories. Each run
is numbered separately, because each gets its own prediction.

## The programs

Twenty programs, named P1 to P20.

**P1, add one to the first item.**

```
match xs do
  [] -> []
  [h | t] -> [h + 1 | t]
end
```

**P2, swap the first two items.**

An empty list stays empty. A one-item list comes back as a one-item list with
the same item. Otherwise the first two items change places and the rest is left
alone.

```
match xs do
  [] -> []
  [a | t] ->
    match t do
      [] -> [a | []]
      [b | u] -> [b | [a | u]]
    end
end
```

**P3, drop the first item.**

```
match xs do
  [] -> []
  [h | t] -> t
end
```

**P4, total the first two items.**

The answer is a number: 0 for an empty list, the item itself for a one-item
list, otherwise the sum of the first two items. The list is not part of the
answer.

```
match xs do
  [] -> 0
  [a | t] ->
    match t do
      [] -> a
      [b | u] -> a + b
    end
end
```

**P5, the first item.**

The answer is a number: the first item, or 0 for an empty list. The rest of the
list is never used.

```
match xs do
  [] -> 0
  [h | t] -> h
end
```

**P6, put an item on the front.**

```
[n | xs]
```

**P7, duplicate the first item.**

```
match xs do
  [] -> []
  [h | t] -> [h | [h | t]]
end
```

**P8, add one to the first item, then use the old list again.**

First it makes a second list, named `ys`: `xs` with one added to its first
item, or the empty list when `xs` is empty. The program still needs the original
`xs` after that. It then puts the original first item of `xs` on the front of
`ys`. If `xs` is empty, the answer is `ys`, the empty list.

```
let ys =
  match xs do
    [] -> []
    [h | t] -> [h + 1 | t]
  end
in
match xs do
  [] -> ys
  [h | t] -> [h | ys]
end
```

**P9, add the first items of two lists.**

If `xs` is empty, the answer is `ys`. If `ys` is empty, the answer is `xs`
without its first item. Otherwise the answer is `ys` with its first item
replaced by the sum of the two first items, and the rest of `xs` is not used.

```
match xs do
  [] -> ys
  [h | t] ->
    match ys do
      [] -> t
      [k | u] -> [h + k | u]
    end
end
```

**P10, add one to the first item if it is below `n`, otherwise drop it.**

```
match xs do
  [] -> []
  [h | t] -> if h < n then [h + 1 | t] else t end
end
```

**P11, the same with `<=`.**

```
match xs do
  [] -> []
  [h | t] -> if h <= n then [h + 1 | t] else t end
end
```

**P12, the same with `==`.**

```
match xs do
  [] -> []
  [h | t] -> if h == n then [h + 1 | t] else t end
end
```

**P13, a second name used only in the empty-list branch.**

If `xs` is empty, the answer is `ys`. Otherwise the answer is `xs` with one
added to its first item, and `ys` is not used.

```
match xs do
  [] -> ys
  [h | t] -> [h + 1 | t]
end
```

**P14, a second name used only in one branch of an `if`.**

If `n` is below zero, the answer is `ys`, and `xs` is not used. Otherwise the
answer is `xs` with one added to its first item (an empty `xs` stays empty), and
`ys` is not used.

```
if n < 0 then
  ys
else
  match xs do
    [] -> []
    [h | t] -> [h + 1 | t]
  end
end
```

**P15, nested matches with a later build.**

It keeps the first item, adds one to the second item when there is one, and
leaves the following items alone. An empty list stays empty. It is written as
one `match` inside another: the inner one finishes, and its result is named
`r`, before the outer one builds its cell.

```
match xs do
  [] -> []
  [a | t] ->
    let r =
      match t do
        [] -> []
        [b | u] -> [b + 1 | u]
      end
    in
    [a | r]
end
```

**P16, a name that reuses a spelling.**

The same operation as P1. Its result is given the name `xs`, the same spelling
as the input, and the answer is that new `xs`.

```
let xs =
  match xs do
    [] -> []
    [h | t] -> [h + 1 | t]
  end
in
xs
```

**P17, is the first item negative?**

The answer is true or false: true when the first item is below zero. For an
empty list it is false, written `0 < 0` because the language has no written
true or false.

```
match xs do
  [] -> 0 < 0
  [h | t] -> h < 0
end
```

**P18, a cell whose two parts both use the same list.**

It puts the original first item of `xs` in front of a changed copy of `xs`. The
item part is the first item of `xs` (0 if `xs` is empty). The rest part is `xs`
with one added to its first item (empty if `xs` is empty). Both parts take `xs` apart, one after the other.

```
[ (match xs do
     [] -> 0
     [h | t] -> h
   end)
| (match xs do
     [] -> []
     [h | t] -> [h + 1 | t]
   end)
]
```

**P19, an input that is never used.**

The answer is a one-item list holding `n`. The input `xs` is never used.

```
[n | []]
```

**P20, subtract five from the first item.**

```
match xs do
  [] -> []
  [h | t] -> [h - 5 | t]
end
```

## The starting memories

Each is named M and a letter. Cell addresses `c1`, `c2`, ... are labels for this
document only.

**M-empty.** No cells. `xs` is the empty list.

**M-one.** `xs = [1]`, unshared.

| Cell | Item | Link | Holders | Held by |
| ---- | ---- | ---- | ------- | ------- |
| c1   | 1    | `[]` | 1       | `xs`    |

**M-two.** `xs = [1, 2]`, unshared.

| Cell | Item | Link | Holders | Held by   |
| ---- | ---- | ---- | ------- | --------- |
| c1   | 1    | c2   | 1       | `xs`      |
| c2   | 2    | `[]` | 1       | c1's link |

**M-three.** `xs = [1, 2, 3]`, unshared.

| Cell | Item | Link | Holders | Held by   |
| ---- | ---- | ---- | ------- | --------- |
| c1   | 1    | c2   | 1       | `xs`      |
| c2   | 2    | c3   | 1       | c1's link |
| c3   | 3    | `[]` | 1       | c2's link |

**M-four-five.** `xs = [4, 5]`, unshared.

| Cell | Item | Link | Holders | Held by   |
| ---- | ---- | ---- | ------- | --------- |
| c1   | 4    | c2   | 1       | `xs`      |
| c2   | 5    | `[]` | 1       | c1's link |

**M-seven.** `xs = [7, 8, 9]`, unshared.

| Cell | Item | Link | Holders | Held by   |
| ---- | ---- | ---- | ------- | --------- |
| c1   | 7    | c2   | 1       | `xs`      |
| c2   | 8    | c3   | 1       | c1's link |
| c3   | 9    | `[]` | 1       | c2's link |

**M-kept.** `xs = [1, 2, 3]`, and an outside holder, `keeper`, also holds the
first cell (a caller keeping the old list).

| Cell | Item | Link | Holders | Held by        |
| ---- | ---- | ---- | ------- | -------------- |
| c1   | 1    | c2   | 2       | `xs`, `keeper` |
| c2   | 2    | c3   | 1       | c1's link      |
| c3   | 3    | `[]` | 1       | c2's link      |

**M-kept-second.** `xs = [1, 2, 3]`, and an outside holder, `keeper`, also holds
the second cell.

| Cell | Item | Link | Holders | Held by             |
| ---- | ---- | ---- | ------- | ------------------- |
| c1   | 1    | c2   | 1       | `xs`                |
| c2   | 2    | c3   | 2       | c1's link, `keeper` |
| c3   | 3    | `[]` | 1       | c2's link           |

**M-shared-tail.** Inputs `xs`, then `ys`. `xs = [1, 3, 4]` and
`ys = [2, 3, 4]`, and the `[3, 4]` part is the same two cells in both.

| Cell | Item | Link | Holders | Held by              |
| ---- | ---- | ---- | ------- | -------------------- |
| c1   | 1    | c3   | 1       | `xs`                 |
| c2   | 2    | c3   | 1       | `ys`                 |
| c3   | 3    | c4   | 2       | c1's link, c2's link |
| c4   | 4    | `[]` | 1       | c3's link            |

**M-same-list.** Inputs `xs`, then `ys`. Both name the same list `[1, 2]`: the
same first cell.

| Cell | Item | Link | Holders | Held by    |
| ---- | ---- | ---- | ------- | ---------- |
| c1   | 1    | c2   | 2       | `xs`, `ys` |
| c2   | 2    | `[]` | 1       | c1's link  |

**M-large.** `xs = [9223372036854775807]`, unshared. (This item is the largest
number a 64-bit signed machine number can hold.)

| Cell | Item                | Link | Holders | Held by |
| ---- | ------------------- | ---- | ------- | ------- |
| c1   | 9223372036854775807 | `[]` | 1       | `xs`    |

**M-minus.** `xs = [-3, 4]`, unshared.

| Cell | Item | Link | Holders | Held by   |
| ---- | ---- | ---- | ------- | --------- |
| c1   | -3   | c2   | 1       | `xs`      |
| c2   | 4    | `[]` | 1       | c1's link |

**M-just-two.** `xs = [2]`, unshared.

| Cell | Item | Link | Holders | Held by |
| ---- | ---- | ---- | ------- | ------- |
| c1   | 2    | `[]` | 1       | `xs`    |

## The runs

Each row is one example: a program, its inputs in order, and a starting memory.
Number inputs are given in the row.

| Run | Program | Inputs, in order | Starting memory | Number inputs |
| --- | ------- | ---------------- | --------------- | ------------- |
| 1   | P1      | `xs`             | M-three         |               |
| 2   | P1      | `xs`             | M-one           |               |
| 3   | P1      | `xs`             | M-empty         |               |
| 4   | P1      | `xs`             | M-large         |               |
| 5   | P1      | `xs`             | M-kept          |               |
| 6   | P2      | `xs`             | M-three         |               |
| 7   | P2      | `xs`             | M-one           |               |
| 8   | P2      | `xs`             | M-kept-second   |               |
| 9   | P3      | `xs`             | M-three         |               |
| 10  | P4      | `xs`             | M-four-five     |               |
| 11  | P5      | `xs`             | M-seven         |               |
| 12  | P6      | `n`, `xs`        | M-two           | `n = 0`       |
| 13  | P7      | `xs`             | M-two           |               |
| 14  | P8      | `xs`             | M-two           |               |
| 15  | P9      | `xs`, `ys`       | M-shared-tail   |               |
| 16  | P10     | `xs`, `n`        | M-two           | `n = 5`       |
| 17  | P10     | `xs`, `n`        | M-two           | `n = 0`       |
| 18  | P11     | `xs`, `n`        | M-two           | `n = 1`       |
| 19  | P12     | `xs`, `n`        | M-two           | `n = 1`       |
| 20  | P12     | `xs`, `n`        | M-two           | `n = 7`       |
| 21  | P13     | `xs`, `ys`       | M-same-list     |               |
| 22  | P14     | `n`, `xs`, `ys`  | M-same-list     | `n = 1`       |
| 23  | P15     | `xs`             | M-three         |               |
| 24  | P16     | `xs`             | M-two           |               |
| 25  | P17     | `xs`             | M-minus         |               |
| 26  | P18     | `xs`             | M-two           |               |
| 27  | P19     | `n`, `xs`        | M-two           | `n = 5`       |
| 28  | P20     | `xs`             | M-just-two      |               |

Run 2 is the one the plan names for its control: a deliberately broken copy of
the rule is run on it, and the checks must reject that copy on the counts
(`PLAN.md`, "How the trial runs", step 4).

## What each run is aimed at

The plan's categories, in its words:

| Plan category                                                        | Runs      |
| -------------------------------------------------------------------- | --------- |
| Reuse on an unshared list: add one to the first item                 | 1, 2      |
| Two cells reused: swap the first two items                           | 6         |
| Freeing: drop the first item; total the first two items              | 9, 10     |
| A set-aside cell that no new cell uses, which must be freed          | 9, 10, 11 |
| New cells needed: put an item on the front; duplicate the first item | 12, 13    |
| An outside holder keeps the input                                    | 5         |
| The list is used again later in the program                          | 14, 26    |
| Two inputs share a tail                                              | 15        |
| Reuse in one branch and not in the other                             | 16 to 20  |

The decided details of `RULE.md`:

| Detail                                                                                 | Runs         |
| -------------------------------------------------------------------------------------- | ------------ |
| Unlimited whole numbers that may be negative (D79)                                     | 4, 28        |
| The three comparisons `==`, `<`, `<=` (D80)                                            | 16 to 20, 25 |
| A true-or-false answer (D82)                                                           | 25           |
| A name that reuses a spelling (D83)                                                    | 24           |
| Left to right, where both parts of one build use the same list (D84)                   | 26           |
| In a `match`, unneeded names are given up before the sharing check (D85)               | 21           |
| A name unused from the chosen branch of an `if` on is given up when it is chosen (D86) | 22           |
| A new cell picks its set-aside cell after its parts are worked out (D87)               | 6, 13        |
| Which set-aside cell, when more than one match is running (D88)                        | 6, 23        |
| An unused set-aside cell is freed when its branch finishes (D90)                       | 9, 10, 11    |
| A rest `t` that the branch never uses (`RULE.md` 6b, step 5)                           | 11           |
| An input never used (`RULE.md` section 7)                                              | 27           |
| An empty list as input                                                                 | 3            |
| A `match` on a list with one cell, taking its empty-list inner branch                  | 7            |
| An outside holder on a later cell only, so part of the list is shared | 8 |
| The two static limits on programs (D89: a `match`'s two names are spelled differently; both branches give the same kind of value) | checked across all twenty programs; not something a run shows |

One limit to keep in mind: the predictions are an answer and three totals. Some
details decide only when something happens. The order conventions in `RULE.md`
(which of several names is given up first, which of several cells is freed
first) change no totals. For D90 (an unused set-aside cell is freed when its
branch finishes), `RULE.md` 6g compares it with one alternative, freeing as soon
as the rest of the branch builds no cell, and says that by the lead's reasoning,
not yet checked, the two give the same totals. If so, totals alone cannot tell
those two apart. Whether the checks can see the order of events is a question
for the interface (the next document).

## Checks the lead made by hand

- Every program has both branches in every `match` (`RULE.md` 2d), no `match`
  introduces two names with one spelling (2e), and both branches of every `if`
  and `match` give the same kind of value (2f).
- Every use has the right kind: numbers in `+`, `-` and comparisons and as the
  item of a new cell; lists as the matched list and the rest of a new cell; true
  or false as an `if` condition.
- Every starting memory is valid (`PLAN.md`, "What the promises cover"): each
  input has the kind its program expects; finitely many cells and no cycles;
  nothing dangles; every cell is reachable from an input or an outside holder;
  every holder count equals the number of holders listed.

Codex may add examples when it writes the predictions (`PLAN.md`, "The
examples").

## Question for Robert

Do you approve these examples as the ones the predictions are written for?
