# Binding view order

This normative explanation answers one question about the already-frozen
Stage B contract. It changes no grammar, diagnostic class, execution action,
schema or check. Read it with `BUILDER_EXECUTION.md`,
`BUILDER_STAGE_B_PREFLIGHT.md` and the documents that preflight names. Public
package v21 appends this document to the unchanged v20 package.

The illustration below shows the required order. It is not a new case and it
is not a seed.

## The question

`BUILDER_EXECUTION.md` says the state binding view contains the current
entered lexical binding order plus every still-holding suspended binding, in
acquisition order. `BUILDER_STAGE_B_PREFLIGHT.md` section 3 says the entered
binding view at Enter is the callee's parameter environment, plus every
still-holding suspended binding. Those sentences can be read as putting the
entered bindings first. Which order is required?

## What the frozen rule already does

D169, Robert's decision on 8 October 2026 that creation order is the rule,
selects the reading that matches the frozen behaviour. It adds no behaviour.

A binding receives its identity when it is created. That identity order is
the acquisition order. The binding view is one list: every binding that is
in the current entered scope, or that is still holding, together, in
binding-identity order. Entered bindings do not come first, and suspended
bindings do not come after them as a second group. A still-holding binding
created earlier, with a lower identity, stays ahead of an entered binding
created later.

"Plus" in the execution sentence and in preflight section 3 names which
bindings are included. It does not name a second group that follows the
entered ones. "In acquisition order" applies to the whole view.

The same rule applies at every committed snapshot, not only at Enter. Return
uses it again: the restored view is still one list in creation order.

## Illustration

This is the shape of a call whose caller still holds a list that the callee
also receives. `xs` is a nonempty installed list.

```
input xs: ListInt;
def bump(xs: ListInt): ListInt = xs end
main = let changed = bump(xs) in xs
```

At the Enter snapshot, both bindings are still holding that same list. The
caller's input was created first, so its identity is 0. The callee's
parameter was created second, so its identity is 1. The binding view lists
identity 0, then identity 1. It does not list the entered parameter first.
