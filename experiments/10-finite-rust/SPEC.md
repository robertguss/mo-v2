# Finite Lean/Rust correspondence — ROB-1146

Use the unchanged accepted trial as the reference. Export all 28 frozen examples,
then a documented template corpus of depth at most three, at most three starting
cells, two list input names (xs, ys), and number input n in -1/0/1. Include unique,
shared-head, shared-tail and outside-holder memories. This is a finite comparison,
not exhaustive enumeration of every expression or a refinement proof.

Before writing Rust, freeze this specification, the exporter, comparison check and
its exported expectations. Lean runs the accepted evaluator; the exporter changes
only serialization and generates new input cases, never the evaluator. The
original frozen example predictions must still pass. Same-author new harness and
Rust implementation under the owner's earlier self-verification preference;
existing Lean evaluator/prediction authorship remains independent and unchanged.

Compare successful answers, raw identity, memory primitive records and rule log,
all exposed snapshots (cells, binding identities/statuses, pending/outside holders,
reservations and branch value), and final memory. Normalize cell addresses using
one bijection per entire run: initial cells in input order, then first creation
order. No per-snapshot renaming may hide changed sharing. This prototype follows
the reference's snapshot scheduling to permit full-record comparison; that is not
a permanent Mo implementation requirement.

Independently walk every outside holder and every holding name at each snapshot;
require its list readable and unchanged for its lifetime. Final cells must exactly
match reachable cells from the answer and outside roots, with correct reference
counts and no reservations. Count primitive creates, writes and frees separately
from system allocator calls/bytes. Rust must really allocate one boxed object per
logical cell, modify that object on reuse and drop it on free. Do not merely print
model-derived expected events. Actual pointers witness same-object reuse, distinct
from logical address normalization. Count physical cell allocations/releases from
before evaluation preparation, separating initial fixture construction. Count the
system allocator separately, including evaluator bookkeeping and snapshot overhead;
these are instrumentation observations, not a performance comparison.

Use stdlib Rust with checked i128 arithmetic only for this fixed corpus; every
exported integer and evaluated arithmetic result must fit i128 or the harness
stops. This is an explicit finite-domain restriction, not Mo integer semantics.
No full language parser, calls, recursion, demand checker, concurrency or loader.
No modification or imports from v1. Accepted trial and 3b remain unchanged.

Real compiled Rust mutations must be rejected for shared mutation, premature free,
unreleased unreachable tails, always allocating replacements and pre-evaluation
copying hidden from the claimed logical interval. A control cannot pass merely by
crashing at compilation. Retain all outcomes and exact sources. Run the comparison
once without retries; on mismatch preserve the counterexample and stop without
changing reference expectations. Compilation/harness setup errors may be repaired
and retained before comparison. A clean pass plus caught controls supports only
this corpus. Deliver report and pushed branch, not automatic merge. Return to the
remaining Needs Input discussion afterward.
