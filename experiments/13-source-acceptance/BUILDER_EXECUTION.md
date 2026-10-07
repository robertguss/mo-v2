# Execution reporting requirements — interface version 13

This spells out the existing committed-action contract for the public handoff.
It is requirements text, not executable acceptance or a set of exact case answers.
It does not authorize Stage B. The candidate chooses its internal representation,
but its observable committed state must follow this contract rather than an
optimized alternative schedule. Private reference/trace files are not builder input.

## Ownership and ordering

Bindings have distinct identities even when names shadow. Lookup chooses the
nearest name; binding-order reporting retains shadowed lexical bindings. Numeric,
Boolean and empty-list bindings have no managed holder. Nonempty-list bindings
begin `holding`; transfer changes them to `movedOn`, release to `givenUp`.

Pending nonempty-list values are a stack, newest first. Evaluating a nonempty
list variable adds a pending value: if that binding is used in the remaining
lexically resolved expressions, acquire another holder; otherwise transfer its
existing holder. Remaining expressions include later operands/arguments and
enclosing continuations. Before branch selection, both alternatives count as
possible uses. Inner let/match binders hide the same spelling for this analysis.
An unused holding input is released before Start, through committed cleanup, not
hidden in begin. Newly bound unused holding values and unused call parameters are
released after their Bind/Enter. Once a branch is selected, release outer holders
unused by that branch and the enclosing continuation, in lexical binding order.

Giving up a holder decrements the count and commits. A zero count does NOT remove
the cell in that action. Free the cell in a separate commit, temporarily protect
its tail as pending, then release the tail iteratively. The ordered release stack
retains the parent cleanup entries while descending. Snapshots may therefore
contain a zero-count, live, queued-for-free cell. Reserved cells are a different
state: detached, zero-count, `aside`, with an originating match-branch identity.

Match selects empty/nonempty only after its scrutinee completes. A nonempty match
binds the head then tail. For a unique scrutinee, transfer the tail holder, detach
the head link and place that same physical head at the front of the reservation
list. Release an unused tail after decomposition. For a shared scrutinee, acquire
a tail holder only if the tail binder is used, then separately release the
scrutinee holder before Match complete. A new match-branch identity belongs to
each match, including its empty branch. Branches are nested; reservations are
eligible only inside the originating branch and its nested expressions in the
same call. A Cons uses the first eligible reservation only after both operands
complete, preserving its actual allocation, or creates one new cell otherwise.
It transfers the tail pending holder into the new link and pushes its result.

At match-branch completion, commit the result, free unused reservations belonging
to that branch one per action, restore the outer scope, then hand off the result.
At call entry, all explicit arguments are already fully evaluated, including
unused arguments. Transfer pending argument holders in reverse pending order,
bind parameters in declaration order, record entry, and suspend the caller's
reservations separately. Only callee reservations are available until return.
The callee's body does not see caller/main locals. Return restores caller
reservations/scope and records the same invocation's result. Suspended callers
and completed arguments remain continuously protected.

## Exact action names and landmark rules

Each action below commits exactly once when the stated condition occurs. No extra
unbounded stuttering actions or hidden committed work is permitted. `landmark`
is the next zero-based index only when a kind is given below; otherwise it is null
and `state.kind`/`state.branch` are null. Indices are cumulative across resume.

| Action | When it commits | Landmark kind |
| --- | --- | --- |
| Start | After unused input cleanup, before evaluating main | start |
| Dispatch compound | Once on entry to each binary, let, if, match or call expression | none |
| Leaf | Literal, empty list, or variable value produced | holderMoved/newHolder for a nonempty list variable; otherwise none |
| Operand capture | After each binary operand or explicit call argument completes | none |
| Primitive result | After both operands; arithmetic/comparison result or Cons acquisition | newCellBuilt for Cons; otherwise none |
| Bind | Let initializer completed and transferred to new binding | nameBound for nonempty list; otherwise none |
| Choose branch | Condition/scrutinee completed, before branch-specific cleanup/decomposition | branchChosen |
| Give up holder | Binding marked givenUp if applicable; one live holder decremented | holderGivenUp |
| Free cell | One queued zero-count cell or unused reserved cell physically freed | cellFreed |
| Match decompose | Head/tail bindings created; unique head detached, or used shared tail holder acquired | matchStep4Done for unique; newHolder for acquired shared tail; otherwise none |
| Match complete | Shared-match scrutinee holder has been released | matchStep4Done |
| Branch start | Chosen branch's cleanup/decomposition is complete | branchStarts |
| Branch result/cleanup | Match branch result worked out, before reservation cleanup | branchValueWorkedOut, with branch result |
| Handoff | Let/if returns its body/branch; match after reservation cleanup and outer-scope restoration | branchValueHandedOn with result for match; otherwise none |
| Enter | Argument transfer, parameter binding and call-local reservation setup | callEntered |
| Return | Callee result and restored caller, before returning the call expression | callReturned |
| Finish | Main result complete | end |

Let and if do not add an Operand capture action for their initializer/condition
or body. Match does not add one for its scrutinee or branches. Its decomposition
and result/handoff actions above are the corresponding boundaries. Calls and
binary operations capture each operand; their final child appears as completed
in the enclosing control before that Operand capture commit.

## Complete execution state, not just action counters

`control` lists active expression contexts outermost first, including the current
expression until it hands its result to its parent. Each context carries its source
path, nearest-name lexical scope in name insertion order, owning invocation, and
completed child values in evaluation order. Returning a child removes its context
and appends the value to its parent's completed operands. Numeric values are
reported even though they do not own list cells. Control has no implicit evaluator
replay hidden behind it; saved state must actually resume the next action.

Bind, Enter, Primitive result, Match decompose, Branch start, Handoff and Return
clear the current context's consumed operands in their committed snapshot.
`ready` is the just-produced value for Leaf and Primitive result; Handoff and
Return expose the last completed child before clearing operands; Finish exposes
the main result. Other actions have null ready. `release` is the ordered active
release chain. Site is the active expression's source path; root-level input
cleanup, Start and Finish use `root`. No active expression means empty control.

The state binding view contains the current entered lexical binding order plus
every still-holding suspended binding, in acquisition order. Entered scope changes
at input setup, binding transfer, nonempty list-variable transfer, Cons, branch
choice/decomposition/start/completion, call entry and return. A scalar leaf or
primitive result does not itself switch this ownership scope. Control's lexical
scope is separately reported for every context; do not replace either view by
the other. `pending` contains only managed nonempty-list holders; `branch` is a
match result only at its two branch-result landmarks. Active named-call frames
exclude implicit root invocation 0. All caller reservations remain visible, oldest
caller first, followed by current reservations, though only current eligible
reservations can be consumed.

At begin, step is zero, kind is null, input bindings have their initial statuses,
events/control/pending/reservations/release/frames are empty and ready is null.
No unused-input cleanup has run. Initial input binding births are already present.
Birth and span origins follow BUILDER_AMENDMENT_D154.md. Complete native memory
and external roots are supplied by acceptance, never candidate shadow memory.

Failed controlled allocation has no commit and preserves this last committed
execution/event state; its separately reported abort list unwinds active named
invocations innermost first. Destroy does not resume the interpreter: it releases
run-held values/reservations/frames, preserves externally held storage, empties
control/ready/release and records frees only in cleanup_events. Repeated destroy
adds no frees. Destruction and host teardown stay separate from execution steps.
