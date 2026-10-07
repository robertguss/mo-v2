# Stage A unsupported-feature diagnostics — public clarification v15

This normative explanation supplies the selection, precedence and span detail
omitted from the public brief. It describes the already-frozen Stage A contract;
it changes no grammar, diagnostic policy, expectation, interface or check. Read
it with the unchanged v14 requirements. Public delivery v15 appends this document
to v14's nine content files; its new `DELIVERY.sha256` lists all ten. The earlier
handoff's nine-file inventory describes v14. This document does not authorize
Stage B or independently resume a paused builder; parent review precedes delivery.

## Refusal phases and declaration selection

1. Complete whole-file encoding, lexical and syntax validation before the
   semantic checks below, including syntax inside declarations and arguments.
   Within that first phase, retain the existing earliest-source error rule;
   discovering an invalid UTF-8 byte does not make it override an earlier syntax
   error. No declaration or call capability refusal bypasses this phase.
2. Check input declarations in source order. At each declaration, check for a
   duplicate input name before checking its input-type annotation. Stop at the
   first refusal. Finish these input checks before the declaration restriction.
3. If any function declaration exists, return `stage-unsupported` for the
   **first function declaration in source order**. Its span is the entire
   declaration, from the start of its `def` token through the end of its matching
   terminating `end` token. Exclude whitespace/comments before or after that
   declaration. Do not first diagnose duplicate functions, parameter duplication
   or types, result annotations, function-body semantics, or main semantics.
   Those constructs have already been parsed, but their semantic checks do not
   precede this Stage A refusal.
4. Otherwise, check `main` with the semantic traversal below. Stop immediately
   at the first refusal encountered by that traversal.

This ordering selects source refusals. The existing typed distinction between
source refusal and frontend resource failure, including Number allocation denial,
is unchanged; this supplement does not define a new allocation-attempt schedule.

## Call selection during semantic checking

When semantic traversal reaches a call expression in Stage A, immediately return
`stage-unsupported` on that **whole call expression's source span**. Do this before
resolving the callee, checking argument count, or semantically checking any argument.
In particular, an unresolved callee is still a Stage A capability refusal, and a
call inside an argument is not visited before its enclosing call is refused.

The unparenthesized span starts at the callee identifier and ends immediately
after the call's closing parenthesis. Grouping parentheses that directly enclose
the call are included in its expression span, including multiple such pairs.
Parentheses enclosing a larger expression do not enlarge a nested call's span.
The usual 1-based, half-open Unicode-scalar line/column convention applies; do
not substitute a callee-only, argument-only or whole-file span.

There is **no global unsupported-call pre-scan**. An earlier name/type refusal
encountered by the traversal below wins over a call that would be reached later.
Semantic selection follows these checks, not a global sort of diagnostic spans.

## Exact traversal and intervening checks

“Check an expression” means recursively apply this same table. If any nested
check refuses, stop without visiting subsequent children or performing later
checks. Required-kind checks happen at the stated point, not after visiting all
children. Check both branches statically even when a condition or list shape
makes one unreachable at runtime, unless an earlier refusal has already stopped
checking. This table describes static checking, not runtime evaluation.

| Expression | Ordered semantic work |
| --- | --- |
| Integer, Boolean or empty-list literal | Determine its literal kind; no child traversal. |
| Variable | Resolve its nearest local/input binding, refusing an unbound name. |
| Addition, subtraction or integer comparison | Check the left operand and immediately require Int; then check the right operand and immediately require Int. |
| Cons | Check the head and immediately require Int; then check the tail and immediately require ListInt. |
| Finite list literal | Apply the Cons rule to its nested Cons/Nil expansion: element checks proceed in written order. |
| Let | Check the initializer; then check the body with that binding in scope, shadowing the nearest same-spelled outer name. The new binding is not in scope in its initializer. |
| If | Check the condition and immediately require Bool; check the then branch; check the else branch; only after both succeed require their kinds to match. |
| Match | Check the scrutinee and immediately require ListInt; check the empty branch; then reject equal head/tail binder names; check the nonempty branch with Int head and ListInt tail bindings; only after both branches succeed require their kinds to match. |
| Call | Refuse immediately with `stage-unsupported`; do not traverse its arguments or resolve its callee first. |
| Parenthesized expression | Check the enclosed expression; grouping adds no semantic check or traversal step. It still affects that expression's span as specified above. |

Existing refusal classes for intervening checks remain unchanged: operand-kind,
head-kind, tail-kind, condition-kind, scrutinee-kind, match-binders, branch-kind
and unbound-variable. This explanation contains no acceptance cases, numerical
span examples, expected outputs, private material or reference implementation.
