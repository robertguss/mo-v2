# Stage B candidate final-03 — submitted for independent checking, not accepted

Crate: `mo-stage-b` 0.1.0, Rust library `mo_stage_b`.
Export: `mo_stage_b::StageB: mo_acceptance_runtime::Candidate`.
Use Rust 1.98.1. Extract `candidate/` alongside the unchanged public `runtime/`.
This is a separate version directory extending the preserved Stage A final-08.
No source or artifact has been pushed, published, merged or deployed.

## D169 binding-view order repair

The parent reports final-02 matched 18 of 21 public examples; C4/C5/C6 differed
only in binding-view order at Enter. Integrity, locked offline build and source
audit passed. These are final-02 results, not final-03 acceptance. The delivered
public failure report and v21 clarification are the only new repair inputs.

BUILDER_STAGE_B_BINDING_ORDER.md records D169: inclusion means entered OR still
holding, and the entire view follows binding-identity (creation) order, at every
snapshot. The earlier wording could be read as entered bindings followed by a
second suspended group; the clarification explicitly resolves that reading.
No new ambiguity or contradiction remains after applying that clarification.

The production repair only changes snapshot projection: enumerate the existing
creation-ordered binding ledger and retain entered-or-holding members. It does
not change entered-scope membership, control lexical scopes, binding lookup,
holder effects, actions, native operations, events, births or allocation gates.
No special case for Enter or for the supplied public examples was added.

One builder-owned development regression first failed on the previous projection
([2, 0] instead of creation order [0, 2]) and then passed without changing its
expectations. It exercises an older suspended opaque list holder, nested scalar
calls, repeated shadowing, omitted nonholding caller bindings, nested and outer
Return, zero-budget observation, segmented resume and denied-Frame preservation.
It stops before any native access; no native store is constructed or emulated.
All 53 development tests pass. The supplied C4/C5/C6 sources were read, not run
against a fabricated host. Their native recheck belongs to independent checking.
Final-01/final-02 and all Stage A checkpoints remain unchanged; this working copy
is `stage-b-final-03/candidate`. The imbl dependency and lockfile are unchanged.

## D168 dependency swap

Robert directed replacement of `im` with its maintained fork `imbl` because
`im` and `sized-chunks` were reported unmaintained under RUSTSEC-2026-0248 and
RUSTSEC-2026-0251. Final-01 will not go to independent checking; its source and
archive remain unchanged. Final-02 is in a fresh `stage-b-final-02/` directory.

Cargo reports the current release as `imbl` 7.0.2, license `MPL-2.0+`, minimum
Rust 1.85. It builds on Rust 1.98.1. Its serde feature remains necessary for the
existing Vector-backed snapshot serialization; no other optional feature is
enabled. Only the dependency line and `im::` paths changed in candidate code;
no API adjustments, behavior changes or test expectation changes were needed.
Cargo regenerated the lockfile; all subsequent dependency/build/test checks use
`--locked`. `cargo tree --locked` contains neither the `im` nor `sized-chunks`
package. It contains the distinct `imbl-sized-chunks` 0.2.0 dependency instead.
Unrelated lockfile packages retain their prior versions and checksums.
No new public-contract question or observed behavioral discrepancy arose.

## Public contract and implementation

Inputs are the delivered public v14–v21 files, the public final-02 failure report
and this author's implementation.
Stage B dispatch authorized functions and recursion after the parent's freeze.
V19 supersedes v18's sum time limit only: sum 900 seconds, discard 600 seconds.
Neither large workload was run. V19 preflight and v20 forward-type clarification
resolve the previously reported questions; no current contract blocker is known.
Stage A's earlier disclosure/wording qualifications remain as recorded in its
preserved final-08 handoff, not retroactively reclassified as explicit wording.

The same parser and expression arena now retain typed function declarations,
parameter identities, call sites and resolved function indices. Whole-file
syntax precedes ordered semantic checking. Calls see the first matching global
declaration, including forward declarations; annotations are retained verbatim
until their declarations are checked. Function bodies see parameters and locals,
not root inputs. Checked dumps and source spans include functions and parameters.

Execution adds explicit saved invocation frames to the existing iterative machine.
Arguments evaluate and capture left to right before Enter. Enter transfers their
holders, publishes the frame and parameter births, and defers unused-parameter
cleanup to subsequent actions. Return restores the caller's environment and
exposes the result while retaining the producing Call context through its callback.
Remaining-use analysis and reservation eligibility are invocation-local. Caller
reservations remain visible and protected, but cannot be consumed by a callee.
Failure freezes the active innermost-first abort list, which survives destruction.

Growing state collections use persistent `imbl::Vector` storage instead of cloning
whole execution histories for each action. This retains staged Frame-gated
preparation and denial-prefix behavior. Stored Return events share immutable
numeric values rather than copying numeric strings into JSON. Commit records
serialize only newly appended events/births. Reservation cleanup searches only
the current invocation's segment. The lockfile pins `imbl` 7.0.2 and its ordinary
Cargo dependencies. No resource performance or memory-budget claim is made.

Native holder, detach, write, create and free operations remain in the existing
executor, with preparation before mutation. There is no second evaluator,
snapshot replay, case dispatch, native store constructor or native storage mock.
The host derives per-invocation create counts from Enter/Return/Create events;
no extra schema field was introduced.

## Development evidence and limits

Rust 1.98.1 `check --locked`, `build --locked`, `test --locked`,
`clippy --locked --all-targets -- -D warnings` and `fmt --check` pass.
The suite contains 53 passing development tests, zero failures or ignored tests.
The original call-free tests remain; two obsolete Stage A capability-refusal
tests now assert the specified Stage B semantics.

New coverage includes semantic diagnostic priority, forward invalid annotations,
function dumps/spans, separate namespaces, forward/mutual recursion, zero-argument
calls, eager unused arguments, Enter/Return control and birth boundaries, parameter
holder transfers, preservation of earlier arguments across later calls, caller
reservation isolation, segmented resume, all Number/Frame denial ordinals of a
small recursive program, preserved abort lists, and retryable/repeated destruction
at every cut of a small recursive run. A 512-depth non-tail scalar sum finishes
with 131328 and 513 saved frames on an 8 MiB Rust test-thread stack.

The existing test-only NoCells gate variant runs this same executor's scalar,
empty-list and pure bookkeeping paths; any native call panics. Opaque list IDs
are used only in logical transfer tests that stop or deny before native access.
No native storage is constructed or emulated. Actual linked-list execution,
outside-held storage, native allocation identity/reuse, cell-create denial and
native cleanup still require the separate host and independent checking.
The small stack test is not either million-element workload and establishes no
resource acceptance. Frontend parsing/checking/dump serialization still use host
recursion over source structure; runtime invocation depth uses saved frames.

During development one hand-counted function span was corrected by independently
enumerating its source characters (half-open end column 30). No production span
was used as its expected value. The persistent-storage refactor passed the same
46-test baseline before further coverage was added. No failing test was hidden.

## Reproduce and package

From `candidate/`, adjacent to the unmodified delivered `runtime/`:

```sh
export CARGO_TARGET_DIR=/tmp/rob1333-stage-b-target
cargo +1.98.1 check --locked
cargo +1.98.1 build --locked
cargo +1.98.1 test --locked
cargo +1.98.1 clippy --locked --all-targets -- -D warnings
cargo +1.98.1 fmt --check
cargo +1.98.1 tree --locked
sha256sum -c CANDIDATE.sha256
```

The submission is `rob1333-stage-b-candidate-final-03.tar.gz`: eight regular files
under `candidate/`: Cargo.toml, Cargo.lock, lib.rs, frontend.rs, number.rs,
execution.rs, HANDOFF.md and CANDIDATE.sha256. The manifest hashes the other seven.
No supplied requirements/runtime, build outputs or acceptance material is included.
Archive size/hash, manifest hash and final round-trip results are in the delivery
reply, avoiding a self-referential archive hash inside this file.

## Integrity, separation and effort

Public v21 archive: 32,962 bytes, SHA256
`e592d2e97ee8ffbf51c030a63e5de8c979d4827d8992f895ae63dc429b1db482`.
Its DELIVERY.sha256 SHA256 is
`986caf6e013d0c26f2cbf0a22c2a3c4dff42b779f59d60d1f376f5151ecddc15`.
Verified exact seventeen regular members, no links/extras, all sixteen content
hashes, fifteen unchanged v20 contents and the sole added manifest line.
The new binding-order document SHA256 is
`f4ecff12026ea71cb1e711e6c4555023c9784a9f8958ae7edd60c45d9b57a5f4`.
BUILDER_PUBLIC_FAILURE_FINAL02.md: 2,895 bytes, SHA256
`f778f6fcfe19c7ce29593036b09ef1ff47c3420ac06ea7e2f79c3d9034d672c8`.
Both were downloaded with authenticated `amp files get`; neither was modified.

Public v20 archive: 32,158 bytes, SHA256
`29c9478b9f382b2bed86850fb59c281d057082e6e6d54a35f8bbc0e56b5f0e1b`.
Its DELIVERY.sha256 SHA256 is
`ffe40c5ddc69eff42b5d91bfebf5c0681c24090b381b3df2aaf69066c8b51883`.
Verified exact sixteen regular members, no links/extras, all fifteen content
hashes, fourteen unchanged v19 contents and the sole added manifest line.
The working runtime is byte-identical to the public runtime. Public v14–v21
archives and extracted supplied files were rechecked and remain unchanged.
All previous Stage A submissions are preserved. Final-08 archive is 36,392 bytes,
SHA256 `f79ea749d7a0ed2b7b1d94bd9daf1ebc6997845a1d2d3dcd4726128eb64f2eb8`.
Its source is unchanged. An audit initially rejected its existing directory
entry; the corrected audit distinguishes that directory from its eight files.

No excluded repository, history, PR, CI, Linear, other Amp conversation,
acceptance source, reference, private/generated case, prediction, seed, control,
evidence or reviewer archive was retrieved. No accidental exposure was observed.
Only delivered public packages/report, own code, and ordinary Rust/Cargo
dependencies were used. No supplied file, independent check or native runtime was edited.
No additional Amp thread/orb, private execution, large resource run, repository
access, push, PR, merge, release or deployment occurred. Development results do
not establish acceptance; the parent must independently check these exact bytes.

Active effort through final-02: 1h14m04s (4,444 seconds).
Final-03 active interval began 2026-10-08 17:35:00 UTC, including build/test and
packaging waits. The stopped interval since final-02 delivery at 15:31:44 is
excluded. The separate base64 transfers were administrative only.
The final UTC stop and cumulative active elapsed appear in the delivery reply
after archive verification. Stage A effort remains separately recorded in its
preserved handoff. No arbitrary hour cap was applied.
