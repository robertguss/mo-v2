# Forward calls and not-yet-checked types

This normative explanation answers one question about the already-frozen
Stage B contract. It changes no grammar, diagnostic class, execution action,
schema or check. Read it with `BUILDER_STAGE_B_PREFLIGHT.md` and the documents
that preflight names. Public package v20 appends this document to the unchanged
v19 package.

Nothing here is a program to run, an expected trace, a private case or a seed.

## The question

A body may call a function declared later, while semantic checking still walks
declarations one at a time. If that later function's parameter name or result
name is not `Int`, `Bool` or `ListInt`, which refusal is reported?

## What the frozen rule already does

Source: `BUILDER_STAGE_B_PREFLIGHT.md`, the semantic order and the order inside
a call, and `BUILDER_BRIEF.md` on argument and result kinds.

The function table is the whole file, and it is filled before any function
body is checked. A call uses the later declaration's parameter names and result
name exactly as written. Whether each of those names is `Int`, `Bool` or
`ListInt` is decided only when checking reaches that later declaration: its
parameters in source order, then its result annotation, then its body.
Checking stops at the first refusal and does not continue into a later
declaration.

A name outside those three kinds is still stored. Filling the table does not
reject it and does not replace it with a known kind.

### An invalid parameter name

Inside the earlier call, arity is checked before any argument. A wrong
argument count is `arity` on the whole call, and the later declaration is not
reached. Otherwise each argument is fully checked, then compared with the
parameter name as written. A refusal inside an argument is reported before
that comparison.

A well-typed argument has kind `Int`, `Bool` or `ListInt`. None of those
equals a parameter name outside that set, so the comparison fails. The
refusal is `argument-kind` on that argument. The later declaration's `type`
refusal is not reported.

If the earlier call never compares that parameter — the call stops earlier,
or there is no call — checking does reach the later declaration, and `type`
is reported on the invalid parameter name.

### An invalid result name

A call is not itself a refusal because its written result name is outside
`Int`, `Bool` and `ListInt`. The call's kind is that written name. The
refusal is the first later requirement that this kind be a particular one:

- the calling function's declared result, reported as `result-kind` on the
  calling body;
- an operand, a condition, a scrutinee, a list head, a list tail, or another
  call's argument, reported on that expression with the class already named
  for that position.

Binding the call and then not placing that binding under one of those
requirements does not demand a kind. The calling function can pass. Checking
then reaches the later declaration and reports `type` on the invalid result
name.

### Annotations on the caller, and `main`

A function's own parameter names and result name are checked before its body.
An invalid name on the calling function is `type` on that name, and the call
in its body is not checked.

`main` is checked only after every function declaration has passed. A use in
`main` does not hide an invalid name on a function. That name is reported as
`type` on the function before `main` is checked.
