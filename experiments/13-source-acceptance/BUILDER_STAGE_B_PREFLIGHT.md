# Stage B preflight — public clarification

This normative explanation answers five questions about the already-frozen
Stage B contract. It changes no grammar, diagnostic class, execution action,
schema or check. Read it with `BUILDER_BRIEF.md`, `BUILDER_STAGE_A_DIAGNOSTICS_V15.md`,
`BUILDER_EXECUTION.md`, `BUILDER_AMENDMENT_D154.md`, `BUILDER_CHECKED_DUMP_V14.md`
and `BUILDER_STAGE_B_V19.md`. Public package v19 appends this document to the
unchanged Stage A requirements and replaces the v18 Stage B addendum.

Nothing here is a program to run, an expected trace, a private case or a seed.
Stage A behaviour is unchanged: a source with any function declaration is still
`stage-unsupported` on the first function declaration, before the Stage B checks
below. Those Stage B checks apply only once that restriction is lifted.

## 1. Semantic diagnostic precedence

Source: `BUILDER_BRIEF.md` (whole-file lexical and syntax validation before
names and types; earliest lexical or syntax error wins; duplicate, arity,
argument and result spans) and `BUILDER_STAGE_A_DIAGNOSTICS_V15.md` (Stage A
stops at the first function declaration). The order below is the frozen Stage B
name-and-type rule that those documents name but do not spell out step by step.

Finish the whole file's encoding, lexical and syntax checks first, including
the insides of declarations, function bodies and arguments. Stop at the first
lexical or syntax error. No later name or type check runs.

Then check semantics in this order. Stop at the first refusal. Do not continue
into a later declaration or into `main`.

1. Input declarations, in source order. At each one, a repeated input name is
   `duplicate-input` on the second name, before that input's type is checked.
   The type check is next, and a Boolean input is `input-type`.
2. Function declarations, in source order. The function table used by calls is
   the whole file, so a body may call a function declared later. A repeated
   function name uses the first declaration's parameters and result. The later
   declaration is `duplicate-function` on that later function's name, and its
   parameters, result annotation and body are not checked.
3. For a function name that is not a duplicate, check its parameters in source
   order. A repeated parameter name is `duplicate-parameter` on the second
   name, before that parameter's type annotation. Then check the result
   annotation. Then check the body. If the body's kind is not the declared
   result, the refusal is `result-kind` on the body.
4. Only after every function declaration has passed, check `main`.

`main` sees the declared inputs. It does not see function parameters or locals.
A call looks up the global function table, not the local environment.

Inside a call expression, in a function body or in `main`, the order is:

1. Resolve the callee name. An unknown name is `unknown-function` on the callee
   identifier. Do not check arity or arguments.
2. If the argument count differs from that declaration, `arity` on the whole
   call. Do not check the arguments.
3. Otherwise check the arguments from left to right. Each argument is fully
   checked, including calls nested inside it, and only then compared with the
   corresponding parameter's kind. A mismatch is `argument-kind` on that
   argument. A refusal inside an argument stops before later arguments.

Spans follow the brief: an unknown name is the identifier, a duplicate is the
second identifier, a wrong expression kind is that expression, arity is the
whole call, a branch mismatch is the second branch, and a result mismatch is
the body.

## 2. What a function body may name

Source: `BUILDER_BRIEF.md`, "function bodies see parameters/locals, not
main/caller locals", and the separate function and local namespaces in that
same section. The frozen Stage B environment for a body is exactly that.

A function body may name its own parameters, the locals it binds with `let`
and `match`, and global function names at calls. It may not name a declared
input. An input is a binding of the root program, visible to `main`, and it is
not in the body's environment. Using an input name as a variable inside a
function is `unbound-variable`, even when `main` could use that name.

A parameter may be spelled the same as a function. The parameter is the local
variable. The function is still called by that spelling, because calls use the
function table and variables use the local environment.

## 3. Enter and Return snapshots

Source: `BUILDER_EXECUTION.md` (Enter is argument transfer, parameter binding
and call-local reservation setup; Return is the callee result and the restored
caller, before the call expression itself returns; unused parameters are
released after Enter; control keeps the current expression until it hands its
result up) and `BUILDER_AMENDMENT_D154.md` (a birth is published in the commit
that first exposes it; a frame's origin is the call site and its owner is the
caller; a binding's owner is the active call). The frozen commit order makes
the timing below explicit. It adds no action.

At the Enter callback, all of the following have already happened, and the
callee body has not started:

* Every explicit argument has been evaluated, including unused arguments.
* The new invocation is already in `state.frames`. Implicit root invocation 0
  is never listed there.
* The entry event has been recorded.
* Pending argument holders have been transferred and parameters have been bound
  in declaration order.
* The caller's reservations are suspended. Only the callee's reservations are
  eligible until return. The caller's reservations stay visible, oldest caller
  first.
* The entered binding view is the callee's parameter environment, plus every
  still-holding suspended binding.
* The call expression is still in `control`, with its consumed operands
  cleared. The callee body's control context is not in `control` yet. The call
  expression's own context belongs to the caller, because that context was
  opened before the new frame existed.

Births first published in that Enter callback, in this order: the invocation
frame, then one binding for each parameter in declaration order. A call with
no parameters still publishes the frame birth in the Enter callback and
publishes no parameter birth. The frame's origin is the call expression's
source path, and its owning invocation is the caller. Each parameter binding's
origin is `function/i/parameter/j` for that declaration, and its owning
invocation is the new frame.

Releasing a parameter that the body does not use is a later committed action.
It is not part of the Enter snapshot.

The body's control context appears on the body's own later commits. Its
invocation is the new frame. It is gone again before the Return callback. At
Return, `state.frames` no longer contains that frame, the caller's reservations
are restored, and the entered binding view is again the lexical environment of
the call, plus every still-holding suspended binding. That restored view is
the caller's environment, not the parameter environment. `ready` is the body
result. The call expression is still in `control`, with its operands cleared,
until it hands that result to its parent.

## 4. The enter event's function field

Source: `BUILDER_BRIEF.md`, the committed event `enter` is
`[enter, invocation, parent, function, site]`, and `BUILDER_CHECKED_DUMP_V14.md`,
where a call node separately has `name` and `function`. The frozen event rule
fills the event from the declaration's name and the call's source path.

In the enter event, `function` is the function's declared name, the same
spelling as `Call.name` in the checked dump. It is not the static path
`function/i`. That path is a different field: `Call.function` in the checked
dump, and it is not this event field. `site` is the call expression's source
path. `invocation` is the new frame and `parent` is the caller, or 0 when the
caller is the root.

## 5. Per-invocation creation accounting

Source: `BUILDER_STAGE_B_V19.md` (accounting starts at function entry, after
explicit arguments, and includes entry work, descendant calls, their argument
preparation, and cells created and then freed inside the call) and
`BUILDER_BRIEF.md` (the same rule, and the snapshot and event schemas). No
exact schema has a counter field. `BUILDER_CHECKED_DUMP_V14.md` and the
snapshot keys in the brief list the fields that exist; a creation count is not
one of them.

The candidate does not report a per-invocation creation counter. It reports
`enter`, `return` and `create` events. The host derives the count from those
events: a `create` counts for every invocation that has entered and not yet
returned. Argument preparation for a call therefore counts for the caller, not
for the callee, because it happens before that callee's `enter`. Creates after
`enter` and before the matching `return`, including creates in descendant
calls and in those descendants' argument preparation, count for this
invocation. The candidate must not add a field to carry the count.
