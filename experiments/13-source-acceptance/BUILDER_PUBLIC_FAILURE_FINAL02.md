# Public failure report — final-02 binding order

Final-02 matched 18 of the 21 public examples. Three failed, and only on the
order of the live bindings at an Enter snapshot. No other field in those
snapshots differed. This report states the observed lists and points at the
rule. It does not say how to change the interpreter.

The required order is the one in `BUILDER_STAGE_B_BINDING_ORDER.md`, in public
package v21. D169, Robert's decision on 8 October 2026 that creation order is
the rule, is that document. Entered bindings do not come first. A binding
created earlier is listed before a binding created later.

The three programs share the function definitions below. Each checked source
is its input lines, then these definitions, then its `main` line.

```
def identity(xs: ListInt): ListInt = xs end
def one(n: Int): ListInt = [n | []] end
def first(xs: ListInt): Int = match xs do [] -> 0; [h | t] -> h end end
def bump(xs: ListInt): ListInt = match xs do [] -> []; [h | t] -> [h + 1 | bump(t)] end end
def sum(xs: ListInt): Int = match xs do [] -> 0; [h | t] -> h + sum(t) end end
def choose(a: ListInt, b: ListInt): ListInt = a end
def readBoth(a: ListInt, b: ListInt): Int = first(a) + first(b) end
def makeThenDrop(n: Int): Int = let unused = one(n) in 0 end
def outer(n: Int): ListInt = identity([n | []]) end
def even(n: Int): Bool = if n <= 0 then true else odd(n - 1) end end
def odd(n: Int): Bool = if n <= 0 then false else even(n - 1) end end
def spin(n: Int): Int = spin(n) end
def allocateForever(n: Int): Int = let ignored = one(n) in allocateForever(n) end
```

A binding is written here as identity, name, list root, and status.

## C4

```
input xs: ListInt;
main = let changed = bump(xs) in first(changed) + first(xs)
```

Enter, committed step 6. `xs` is the installed list rooted at cell 1. Both
live bindings are still holding that list.

| | First | Second |
| --- | --- | --- |
| Required | 0, `xs`, cell 1, holding | 1, `xs`, cell 1, holding |
| Final-02 | 1, `xs`, cell 1, holding | 0, `xs`, cell 1, holding |

The caller's input was created first. Final-02 listed the entered parameter
first.

## C5

```
input xs: ListInt;
main = readBoth(xs, xs)
```

Enter, committed step 12. Both live bindings are still holding the list
rooted at cell 1.

| | First | Second |
| --- | --- | --- |
| Required | 2, `b`, cell 1, holding | 3, `xs`, cell 1, holding |
| Final-02 | 3, `xs`, cell 1, holding | 2, `b`, cell 1, holding |

## C6

```
input xs: ListInt;
input ys: ListInt;
main = let changed = bump(xs) in first(changed) + first(ys)
```

Enter, committed step 6. `xs` is the list rooted at cell 1. `ys` is the list
rooted at cell 2.

| | First | Second |
| --- | --- | --- |
| Required | 1, `ys`, cell 2, holding | 2, `xs`, cell 1, holding |
| Final-02 | 2, `xs`, cell 1, holding | 1, `ys`, cell 2, holding |

Final-02's standard error was empty on all three.
