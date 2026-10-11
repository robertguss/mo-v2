# Slice 1, stage 2 — conditional demand checker

Robert authorized this stage in the
[source thread](https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491),
with execution in [this thread](https://ampcode.com/threads/T-01a126e2-69f9-751a-8aff-1a2e19a7e821).
The branch `proofs/rob-1139-stage2` starts exactly at remote stage-1
[`66f8aac`](https://github.com/robertguss/mo-v2/commit/66f8aac22fbaa31100700a5ca9e5b486efd67c28),
not `origin/main`. No unpushed source-thread implementation was transferred.
This brief applies the already approved v2 contract and frozen acceptance;
it does not request a second stage/specification approval or amend either.

## Target and write ownership

Implement an executable Lean checker with useful refusal reasons and prove
`Full.Statements.Conditional` for its actual `Program → String → Bool` result.
The conditional premise is unique/disjoint list entry before unused parameters
are released. Count all primitive Creates in every finite invocation prefix,
including descendants, argument preparation inside the interval, and later-freed
cells. Caller reservations cannot justify acceptance. Recursive declarations
must be validated together, with their soundness derived, not postulated.

Builder writes are additive: `lean/Full/Demand.lean`, `lean/Full/Demand/`, and
stage-2 proof/gate/runner sources and records under this `stage-2/` directory.
The existing Lake Full library can build additive Full modules without editing
its configuration. This checker scope is not stage 1's proof-only subtree.
All existing model, statement, proof, fixture, acceptance, comparison, toolchain,
and historical lock files remain unchanged. In particular D191's Decompose
rank weight 12 is the sole approved model amendment; do not alter the prior
failure, old rank freeze, or historical proof sources.

The integrating builder does implementation here, not the original independent
acceptance author. Frozen `acceptance/` predictions and checks remain owned by
that author; candidate outputs cannot supply new expectations. Preserve all
27 categories: stage 2 runs the 12/6/1 slice-1 accept/refuse/observe families;
the 3/3/2 slice-2 families remain recorded, not declared passed as caller checks.
Retain the Koka 3.2.9 comparisons and their limitations. Any necessary new
acceptance judgment needs separate authorship; it is not silently decided by
the checker implementation.

## Verification and scientific stops

Use pinned Lean 4.34.0 and existing dependencies. No placeholders, extra axioms,
native/unsafe/opaque proof bypasses, implementation substitutions or changed
frozen meanings. The complete transitive axiom allowlist is `propext`,
`Classical.choice`, `Quot.sound`. Check exact fully qualified theorem types,
all exported theorem axiom sets, and fresh kernel rechecking in a cache-free
reconstruction of the frozen source plus only additive permitted files.
Rerun the unchanged finite acceptance and relevant stage-1 controls.

Execute usefulness and actual allocating refusal witnesses against the checker.
Exercise accept-all, reject-all and a missing-rule control with passing
baselines and the intended semantic failure, not merely a compile error.
Caller-ownership mutation is explicitly deferred with slice 2. Arithmetic-only
ordinary-helper refusal, if chosen, is a usefulness limit, not an allocation.

A different bounded verifier must inspect the delivered checker/proof or any
counterexample and independently execute checks. Tool-invoked separate
verification stays with this checkout; do not create another thread. This is
same-account procedural separation, not inaccessible environments, independent
account certification, or Stage B's single-agent exception. Separate verification
does not delegate the requested implementation.

Restore required public full-3c historical gzip evidence from the release assets
per `experiments/GZ_ARCHIVE.md`, verifying the committed checksums. Never add
gzip evidence objects to Git history, use the source backup branch, or merge
obsolete history. Do not retrieve private experiment-13 cases or seeds.

Work is deliverable-based, with progress reporting and no newly invented
discretionary partial-stop budget. A verified specification defect or integrity
failure is a hard stop: preserve it, obtain separate verification, and present
the evidence before any proposed amendment. An unfinished proof is not such a
defect. Stop after the stage-2 result; no caller ownership enforcement,
unconditional theorem, Rust refinement, merge or deployment is authorized.
No delivery-CI pass is inherited: Buildkite 90 canceled both jobs without checks;
stage 1's separate clean local verification passed.
