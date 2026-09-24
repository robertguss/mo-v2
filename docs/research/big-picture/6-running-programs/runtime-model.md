# Runtime Model

**Type:** Earlier research

**Links:**

* [Standard Library and Interop](../5-effects-and-authority/standard-library-and-interop.md) depends on → this
* [Core Semantics](../1-spec-layer/core-semantics.md) coupled with → this
* [Implementation](../../parking-lot/implementation.md) depends on → this

Earlier research: proposals, not decisions. Decisions are in DECISIONS.md.

How Mo programs behave while running.

Status: fault tolerance partly explored; the rest open.

Territory:
* Fault tolerance: Erlang-style supervision, fail fast and keep moving (settled)
* Concurrency model: share-nothing isolated units? (open)
* Memory management: garbage collection or ownership? (open)
* How defect reports are delivered while the system keeps running
