# Stage A public handoff — documentation amendment version 14

Read this first, then BUILDER_BRIEF.md, BUILDER_AMENDMENT_D154.md and
BUILDER_EXECUTION.md, with BUILDER_CHECKED_DUMP_V14.md for exact checked-dump
field keys. Version 14 only fills that public documentation omission; both v13
archives are retained and no executable acceptance or prediction changes.
The original v12 brief is retained byte-for-byte, so its
old “proposed” and “not implemented” status paragraphs are historical. D153
(exact v12 approval and conditional integration/review/freeze/Stage A) approved
the contract and preparation, not an already completed handoff. D154
(acceptance-owned external-root/physical-memory reporting) amends its observation
ownership. D155 (procedural builder separation for Stage A) amends its isolation
requirement. The current public runtime crate implements the specified interface;
it implements no Mo source frontend or interpreter.

The parent must review this integrated delivery, confirm independently frozen
checks and fresh-context delivery, and explicitly dispatch Stage A. This file
does not dispatch a builder. Stage B and resource workloads remain unauthorized.

## Exact builder-visible inventory

- BUILDER_HANDOFF.md: status, build/link boundary and access instructions.
- BUILDER_BRIEF.md: retained exact v12 grammar, types, API and wire contract.
- BUILDER_AMENDMENT_D154.md: current observation ownership and schema precision.
- BUILDER_EXECUTION.md: normative execution-reporting requirements, not a reference
  implementation or program-specific trace predictions.
- BUILDER_CHECKED_DUMP_V14.md: exact checked-program JSON key sets and omissions.
- runtime/Cargo.toml, runtime/Cargo.lock, runtime/lib.rs, runtime/abi.rs: the
  dependency-free `mo-acceptance-runtime` capability/interface crate.
- DELIVERY.sha256: fingerprints of precisely these nine source/document files.

No other repository/history, acceptance source, tests, references, predictions,
private case/seed, observer/fixture code, deliberate control implementation,
review archive or raw evidence is part of this delivery. Public examples in the
brief are already disclosed and must not be called unseen.

The public dependency deliberately has no executable fixture constructor. That
is an API boundary, not a sandbox against hostile native code. The builder may
compile its candidate library and its own unit tests, but does not receive or
reimplement acceptance storage to manufacture an acceptance result. Acceptance
constructs the capability and links the candidate in its own context.

## Compile and link without inventing an interface

Use rustc/cargo **1.98.1**, edition 2024, the same toolchain on both sides of the
private Rust dispatch boundary. Run from the unpacked public delivery:

```sh
sha256sum -c DELIVERY.sha256
cargo +1.98.1 check --locked --manifest-path runtime/Cargo.toml
```

The builder creates its own `candidate/Cargo.toml` and library, depending on
`mo-acceptance-runtime = { path = "../runtime" }`, and exports one public type
implementing `mo_acceptance_runtime::Candidate`. Name that type and library in
the return handoff. Build with `cargo +1.98.1 check --manifest-path
candidate/Cargo.toml` and then retain the generated lock; subsequent checks use
`--locked`. Do not modify the delivered runtime/interface files. Return candidate
source, Cargo manifest/lock, build command and the exported type path. No second
parser/evaluator, fixture-case dispatch or acceptance-source import is allowed.

Acceptance links that exported type into its generic driver. The host-only entry
point is `mo_acceptance_driver::serve::<candidate_crate::ExportedType>()`; its
implementation, dependency on physical storage, fixture approval channel and
observer/denial controls remain outside builder context. The same-store capability
is passed first by reference to source checking, then by ownership to begin after
host fixture validation/installation. No fixture/outside provenance crosses that
boundary. There are no unresolved candidate API signatures for a builder to pick.

The approved Number routing applies: numeric parse/arithmetic/copy buffers are
created inside Number allocation callbacks. In particular, `read` clones the
owned numeric string and must be called through `allocate(Number, || read(id))`.
Number/Frame gates run before callbacks and release the store borrow first.
Observer copies and host-fixture bookkeeping are excluded. This is not an
all-host-allocation or arbitrary OS-OOM recovery guarantee.

## Procedural access rule

Work only from this delivered context and your own implementation. Do not retrieve
excluded acceptance material using Linear, other threads, file-download tools,
repositories/librarian, shell/network, prior conversations or any other route.
Do not open owner review links merely because they are technically accessible.
Report accidental exposure immediately and stop for the parent to assess it.

Same-account tools retain technical access; there is no claim of enforced
inaccessibility. The parent verifies starting files/context and this allowlist,
records the dispatch, then inspects recorded tool use for compliance. That audit
establishes only what its evidence supports. It is not a new security framework.
