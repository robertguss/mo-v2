# RuntimeCells method contracts — public clarification v16

This normative supplement explains the existing runtime dependency; it changes
no method, ownership rule, failure requirement, event definition or acceptance
criterion. Read it with the public ownership/execution and interface documents.
Public v16 retains all ten v15 content files byte-for-byte, adds this document,
and regenerates `DELIVERY.sha256` for eleven content files. Parent review precedes
delivery/resumption. This document does not authorize Stage B or resource work.

## Native checks do not grant evaluator permission

A cell is an allocated object identified by its store-issued lifetime ID. Its
fields are `item: String`, `tail: Option<u64>`, `holders: u64`, and `aside: bool`.
An allocated cell can be reserved or queued for freeing; zero holders do not make
it absent. `None` denotes no tail. IDs are opaque handles, not array indices,
physical addresses, or evidence of fixture provenance.

The preconditions below are the checks actually enforced by each native method,
not the full conditions under which the evaluator may use it. The evaluator must
still maintain canonical numeric contents, valid links, accurate holder transfers,
continuous protection, reservation eligibility and the prescribed action order.
In particular, reuse must consume an eligible reservation only after both Cons
operands complete; holder give-up and physical free remain separate actions;
outside-held values must survive. A native method accepting an operation does
not establish compliance with any of those language-level obligations.

No method automatically increments, decrements, acquires, releases, or frees a
different cell reached through a tail. Link replacement and holder bookkeeping
are distinct effects that the evaluator must coordinate. Reading or dropping a
returned `Cell` value does not acquire or release a managed list holder.

## Per-method contracts

| Method | Enforced precondition / typed failure | Successful effect and return | Native observation |
| --- | --- | --- | --- |
| `read(id)` | The ID must currently be allocated; otherwise `UnknownCell`. No injected denial inside this method. | Return an owned copy of all four fields, including a cloned numeric String. Do not change the stored cell or any holder count. | A read attempt is observable, including a missing-ID attempt. No managed-cell event or mutation-journal entry. |
| `create(cell)` | A controlled cell-allocation gate may return `InjectedAllocationFailure`. Supplied field contents are not otherwise validated by this method. | Allocate one new cell containing exactly the supplied fields and return its fresh lifetime ID. Do not acquire its tail or adjust any other cell. | Record the cell-allocation attempt whether allowed or denied. Success records one `create` event and the same operation in the mutation journal; denial records neither cell event nor mutation. |
| `write(id, item, tail)` | The ID must currently be allocated; otherwise `UnknownCell`. No native reservation/count/aside check and no injected denial. | Replace only item and tail, in the same allocated cell. Preserve holders and aside. Return success even if the supplied item/tail equal the old values. Do not adjust old or new tail holders. | Record one `write` event and mutation-journal entry on success, including an unchanged-value write. |
| `detach(id)` | Missing ID returns `UnknownCell`; otherwise require holders exactly 1 and aside false, or return `InvalidDetach`. No injected denial. | Return the previous optional tail, remove the stored tail, set holders to 0 and aside to true, and preserve item and allocation. The optional tail may already be absent. Do not modify the returned tail cell. | Record `detach` in the mutation journal only. This is bookkeeping, **not a counted `write`**, `create`, or `free` event. |
| `metadata(id, holders, aside)` | The ID must currently be allocated; otherwise `UnknownCell`. No native count/aside consistency check and no injected denial. | Overwrite only holders and aside with the supplied values; preserve item, tail and allocation. No automatic free when the new count is zero. | Record `metadata` in the mutation journal only, even if values are unchanged. No counted managed-cell event. |
| `free(id)` | The ID must currently be allocated; otherwise `UnknownCell`. No native zero-holder/reservation/outside-ownership check and no injected denial. | Remove and deallocate that one cell. Return success. Do not recurse into its tail or adjust any tail holder. Subsequent access to this retired ID fails as missing. | Record one `free` event and mutation-journal entry for the removed allocation. |

Missing-cell failures and invalid-detach failures leave cell contents, links,
holders, allocation identities and both cell-event/mutation prefixes unchanged.
The failed read still contributes its separate read-attempt observation. Denied
creation likewise preserves the graph, existing allocations, next lifetime ID,
and cell-event/mutation prefixes; its denied attempt remains observable. Typed
native misuse errors are not controlled resource exhaustion or permission to
continue with fabricated cells/results. The evaluator's existing failure and
cleanup contracts still apply.

## Allocation callbacks and numeric-copy routing

`allocate(domain, allocation)` supports `Number` and `Frame`. Each invocation
first records a one-based attempt in that domain, independently of cell-create
attempts and of the other domain. An allowed attempt releases the store borrow
before invoking the closure **exactly once**, then returns its value inside `Ok`.
A denied attempt returns `InjectedAllocationFailure` without invoking the closure.
The gate itself does not change managed cells or produce a managed-cell event.
Ordinals continue in the same store across execution phases and suspension/resume.
Cell-create attempts also start at one and count both allowed and denied calls;
fixture installation does not consume a cell-create attempt.

The callback may use the same capability after the gate succeeds. Its return is
not flattened: if it returns another `Result`, distinguish an outer gate denial
from an inner operation error. The wrapper does not roll back closure effects or
catch a panic. Preparing a closure's captures happens before the gate; wrapping
an already-created numeric buffer does not gate that buffer's creation.

Real numeric parse/arithmetic/copy buffers and required frame storage must follow
the existing gated allocation paths. In particular, a candidate-facing `read`
that yields an owned numeric String must execute **inside a Number callback**:
`read` itself clones the String but does not gate it. Numeric Strings supplied
to `create` or `write` must already have been produced on the gated path; neither
method supplies an implicit Number gate. Acceptance-only observation copies and
host-fixture bookkeeping remain excluded from candidate allocation attempts.

Only `allocate(Number/Frame)` and `create` support injected denial. The remaining
methods may involve ordinary host allocations internally, but do not thereby
gain another injected-denial point. No guarantee is made of arbitrary host-OOM,
counter/identity-range exhaustion, panic or process-death recovery. An allowed
gate is permission to attempt the closure, not a host-memory reservation.

## Events, physical identity and committed-action failure

Acceptance observes native operations and their phases independently. Attempts
and their allowed/denied outcomes are distinct from cell events. A failed attempt
does not count as a cell creation, interpreter transition, or partial callback.
`detach` and `metadata` remain visible bookkeeping mutations without increasing
the logical create/write/free event prefix. Fixture installation is host-owned
and separately accounted; it is not a candidate create operation.

Successful `write`, `detach`, and `metadata` preserve both the cell's lifetime ID
and its actual allocated-object address. This does not promise stability of an
item String's buffer address. `free` ends that lifetime; a later allocation may
reuse a physical address but never revive a retired lifetime ID. Candidate reports
use their existing logical IDs/events, not raw addresses or invented native logs.

Native operations take effect individually. There is no multi-operation native
transaction or automatic rollback spanning a committed evaluator action. The
evaluator must nevertheless meet the existing stronger requirement: **any
controlled denial while attempting an action preserves the last committed
execution state, physical graph/lifetimes and cell-event prefix**. The failed
action adds no committed step and emits no partial committed callback; denial
attempt evidence and the specified failure/abort report remain separate.

Successful earlier mutations do not disappear merely because a later gate fails.
Restoring only reported state, hiding physical work, truncating journals, or
compensating with new create/free events does not preserve that prefix. The
candidate chooses how to satisfy the obligation; this supplement prescribes
no allocation or evaluator algorithm and grants no new rollback API.

Cleanup remains explicit and iterative. `free` is only a one-cell primitive;
it does not perform the evaluator's tail cleanup, reservation cleanup, outside
protection or repeat-safe destruction. Dropping the Rust capability is not a
substitute for required candidate destruction or separately accounted host
teardown. No host implementation, test, case, prediction or private material is
part of this supplement.
