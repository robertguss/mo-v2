# Stage B addendum — proposed builder-facing requirements, not dispatch

This is the proposed public addendum for Stage B of the source-driven Mo
interpreter. It adds nothing to the approved language: `BUILDER_BRIEF.md`
already states the whole two-stage contract, including typed named functions,
recursion and mid-expression resume. What this document does is say which parts
of that contract Stage B must now actually satisfy, and what Stage A behaviour
must not change while it does.

Like every other builder-facing file, it contains requirements, interface
statements and already-public examples only. It contains no acceptance source,
no expected trace or span table, no reserved example, no seed and no negative
control. Delivery of this package is a proposal for owner review; it is not a
builder dispatch, a scientific freeze or authorization to start Stage B.

## What changes

Stage A parsed function declarations and calls and then refused them with the
`stage-unsupported` capability class. Stage B lifts exactly that restriction.
The same source frontend and the same interpreter entry points are used; no
second parser, alternative runtime, corpus or case-identifier dispatch, or
replay on resume is permitted. A candidate that passes Stage A and then changes
how a call-free program behaves has failed Stage B.

Concretely, Stage B must:

1. Accept and execute explicitly typed named first-order functions, including
   forward references and mutual recursion between two or more functions.
2. Evaluate every explicit argument, left to right, including arguments the
   callee never uses, before entering the invocation.
3. Keep the caller's live values and its completed arguments readable for as
   long as they are live, including while the caller is suspended.
4. Keep each reservation inside the call that made it. A callee may not consume
   a cell its caller set aside, and the caller keeps that reservation while the
   callee runs.
5. Begin per-invocation creation accounting at function entry, after the
   explicit arguments have finished, and include entry work, descendant calls,
   their argument preparation, and cells created and then freed inside the call.
6. Represent the call stack as explicit, saved execution state, so that a run
   can be suspended between any two committed actions, observed, and resumed
   from the saved state rather than replayed. Recursion depth must not be
   carried on the host language's own call stack.
7. Give up a holder and free its cell as two separate committed actions, and
   keep queued cleanup across a suspension, including cleanup owed on return.
8. Report finished, suspended, failed and refused as four distinct outcomes.
   Running out of the observation budget is suspension, never completion, and
   never a claim that a program does not terminate.

## What Stage A behaviour must not change

Every call-free program that Stage A answered must still produce the same
answer, the same committed actions, the same cell operations and the same
diagnostics. The refusal classes, the two-phase diagnostic order (finish
whole-file lexical and syntax validation, then check names and types), the
earliest-error rule and the span conventions are unchanged. The only expected
difference is that sources previously refused with `stage-unsupported` are now
checked for names and types like any other source, and executed if they pass.

## Resource shape

Two bounded workloads are acceptance conditions for Stage B. They are stated
here so the implementation is built for them, not as a benchmark or a
performance promise:

* A non-tail recursive sum over a list of one million elements must finish with
  the correct total, on an eight-mebibyte host stack, without overflowing it.
* Discarding a list of one million elements must complete without overflowing
  the host stack and without leaking a cell.

Both run under a single six-hundred-second limit per workload that includes
start-up, checking, fixture installation, execution, observation, cleanup and
teardown, and both are capped at one hundred million committed execution
transitions. Memory provisioning is at least four gibibytes; that is a
provisioning floor, not a budget the implementation may spend freely. These are
workload acceptance conditions for this prototype, not a production guarantee.

## Already-public examples

These were disclosed before and remain public. They are illustrations of the
rules, not an acceptance set, and they are not the examples acceptance uses.

| Program | Answer |
| --- | --- |
| `def f(): Int = 7 end main = f()` | Int `7` |
| `def f(n: Int): Int = F(n) end def F(n: Int): Int = n - 3 end main = f(8)` | Int `5` |
| `def f(f: Int): Int = f + 2 end main = f(9)` | Int `11` |
| `def pick(flag: Bool): Int = if flag then 7 else 11 end end main = pick(false)` | Int `11` |
| recursive increment of `[3, -2, 8]` | `[4, -1, 9]` |
| the same list retained outside the run | still `[3, -2, 8]` |

Two function names may differ only by case, and a parameter may share a name
with a function, because function and local names are separate namespaces.

## Interfaces

The candidate interface, the storage capability, the checked-program dump keys,
the diagnostic record shapes and the runtime crate are unchanged from the Stage
A package and are included here byte for byte. Stage B needs no new capability:
invocation entry and return are ordinary committed actions, frames are ordinary
gated allocations, and the observation protocol already carries them.

## Boundaries

This document does not authorize Stage B work, choose permanent Mo syntax or
number policy, promise any speed, or describe how acceptance checks a
candidate. Acceptance keeps its own examples, predictions and controls, and the
author of this package does not implement the interpreter.
