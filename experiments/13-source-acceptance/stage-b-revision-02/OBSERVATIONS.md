# Explicit Stage B observations — revision 02

Robert approved an explicit full-versus-summary interface in the acceptance
thread on 8 October 2026. This is a prepared replacement interface, not an
amendment silently applied to the original submission or scientific lock.

## The host requests the shape

The version-matched runtime adds `Observation::Full` and
`Observation::Summary { since_event: u64 }`, passed to
`Candidate::observe(&Run, Observation) -> Vec<u8>`.

The request is observational only. It does not authorize execution, consume a
budget, change ownership, acquire holders, reset counters, or reveal an expected
answer. It contains no workload identity. Repeated requests with the same
arguments and unchanged execution state must return the same data.

`Full` returns the existing complete snapshot, byte-schema compatible with
`snapshot`. The default `observe` calls `snapshot` to retain source compatibility
with existing candidates. It does **not** provide summary support: a full
snapshot in response to `Summary` fails checking. An implementation that supports
large observations must override `observe`.

Ordinary runs request `Full` after every committed action. Large runs retain
every action's metadata, births and events, requesting `Summary` at positive
multiples of 10,000 actions. The host does not serialize its full cell graph for
these summary rows. At begin, every advance return (including zero-budget and
terminal calls), and cleanup boundaries, the host requests `Full` and supplies
its actual graph separately. The host owns graph/outside-root reporting as before.

The runner must pause at the deepest boundary and then resume. A periodic
callback at the same step as a boundary produces a summary followed by a full
boundary observation; neither is inferred from the number of snapshot calls.
The two approved workloads' deepest steps are off the 10,000 grid.

## Summary JSON

Exactly these keys, with no full state, event prefix or cleanup-chain body:

```json
{
  "observation": "summary",
  "step": 10000,
  "depth": 0,
  "live_cells": 12,
  "counts": {"create": 0, "write": 0, "free": 8},
  "changed_cells": [41, 57],
  "cleanup_chain_length": 8
}
```

Numbers above illustrate types only; they are not an example program's output.
Every number is an unsigned 64-bit JSON integer, not a string or Boolean.

* `step`: cumulative committed actions, unchanged by observation or resume.
* `depth`: currently active invocation frames, excluding main.
* `live_cells`: actual still-allocated managed cells, including reservations
  and zero-holder cells awaiting their free action; not merely reachable cells.
* `counts`: cumulative evaluation creates, writes and frees. Excludes initial
  fixture installation, destruction and host teardown. Call entry/return events
  are not cell operations and do not increment these three counters.
* `changed_cells`: the identity from each create/write/free event in the logical
  event suffix starting at `since_event`, in event order, preserving repeats.
  The cursor is a zero-based index into the full logical event stream, including
  call events. Filter that suffix for cell events; do not treat it as a cell-event
  count. It is not a predicted value. It is the event counter at the host's most
  recent actual observation, full or summary.
* `cleanup_chain_length`: length of the same active release chain that a full
  snapshot would report. Queued work is not active, as in the existing rule.

Both large workloads have no external roots and no cell creations. This revision
does not claim a general-purpose large-workload verifier for arbitrary programs.
The 900-second recursive-sum limit, 600-second discard limit, eight-MiB stack,
provisioning floor and transition cap are unchanged. No large run follows from
publishing this document.
