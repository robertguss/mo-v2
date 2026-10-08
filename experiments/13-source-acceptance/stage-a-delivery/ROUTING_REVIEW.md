# Final-08 source/allocation review

Review scope: exact submitted production sources in `../stage-a-08/candidate`,
not development tests or the separate deliberately broken control copy. This
inspection does not prove arbitrary-program correctness, all-host allocation
accounting, arbitrary host-OOM recovery or large-input stack behavior.

## Source drives the evaluator

`lib.rs:19–31` passes original source into `frontend::check`, with the runtime
Number capability as the literal allocator. `frontend.rs:351–447` builds one
parsed program, checks input declarations, rejects Stage A function declarations,
then checks the main tree. `check_node` resolves lexical bindings against the
current declaration stack; checked node IDs, children and use sets drive
`execution.rs:848–1174`. No acceptance dependency, expected-row lookup, host
fixture API, source-case selector or alternative production cell store appears
in the submitted production sources. The test-only `NoCells` variant is not in
the native acceptance build and does not constitute physical evidence.

## Numeric allocation and copying

- Literal construction calls `number::literal` inside the Number closure in
  `lib.rs:25–26`. Parser numeric nodes own the returned String via Arc; later
  expression clones share that immutable buffer rather than copying its digits.
- `execution.rs:263–268` encloses every candidate-facing native read inside a
  Number callback, then distinguishes the outer gate failure from inner cell
  errors. The native read's owned numeric String is therefore gated.
- `numeric` at lines 270–274 allocates its resulting String inside Number.
  Literal execution and arithmetic use it at lines 910 and 996–998. Arithmetic
  scratch/result construction in number.rs occurs inside the same callback.
- Cons copies its numeric item inside Number at lines 1003–1005 before passing
  the resulting owned String to native write/create. Match moves the gated
  read's item into its head binding; it does not clone those digits afterward.
- Input numeric Strings move from validated host input values into immutable
  Arcs at lines 502–550. Val clones and state clones share these Arcs. Integer
  comparisons borrow digits and allocate no numeric result buffer.
- Dump/snapshot/public-output serialization borrows values or emits wire bytes.
  Finish walks list cells through the gated read helper before serializing the
  completed answer. This is not a claim that every wire/JSON allocation is a
  separately counted Number buffer.

## Frame routing and committed-action atomicity

`step`, lines 312–354, checks terminal/destroyed status before allocating. Its
Frame closure contains the actual state clone and next-action execution,
including context/operand/cleanup-vector construction. Controlled denial leaves
the old state selected; only successful action completion replaces it and
advances the committed step. Each callback follows that replacement.

The native methods do not provide transactions. The relevant action paths were
checked for later controlled gates after native mutation:

| Action | Gate/mutation order inspected |
| --- | --- |
| Holder acquisition/give-up/free | Gated read first; then metadata or free; remaining changes are staged bookkeeping. |
| Cons reuse | Gated numeric copy first; write then metadata have no injected denial; reserved target remains allocated between those two operations. |
| Cons creation | Gated numeric copy first; native create is the final controlled gate and makes no cell change on denial. |
| Unique Match | Gated read before detach; binding/reservation bookkeeping follows within the Frame closure. |
| Shared Match | Both head and any acquired-tail reads precede tail metadata; no later controlled gate in that action. |
| Reservation free | Native free, then staged event/removal; no controlled gate follows. |
| Finish | Gated list readback may fail, but it performs no cell mutation; output/finished state is selected only on success. |

This establishes the inspected ordering, not a rollback facility or permission
to use permissive native methods outside evaluator ownership invariants. The
historical and denial checks supply separate finite execution evidence.

Initial zero-step bookkeeping owns input bindings and queues unused holders;
it does not run cleanup or create expression contexts. The public requirements
do not classify every initial vector/Arc/JSON allocation as Frame storage.
Consequently this review does not silently impose an all-host allocation rule,
or claim that every initial bookkeeping allocation was gated.

## Destruction and limitations

`destroy`, lines 451–490, is iterative and repeat-guarded. Each cleanup iteration
enters a Frame closure. `destroy_one`, lines 552–620, gates numeric reads before
native changes; completed holder/free operations update the ownership ledger
immediately. It handles already-given-up Free entries before bindings, pending
holders and reservations, and transfers freed tails to pending cleanup.

Execution-denial schedules cover actual attempts observed before cleanup in the
retained baseline. They do not claim denial coverage during destruction itself,
arbitrary host allocator failure or unobserved schedules. The frontend uses
recursive parsing/checking and nested serialization; no deep-resource or host
stack-independence claim is made for this Stage A small-case acceptance.

The compiled evaluator controls and remaining execution evidence have separate
records. This source review is not a substitute for those obligations.
