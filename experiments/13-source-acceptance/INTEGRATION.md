# D153 acceptance integration — blocked checkpoint, not frozen

D153 (exact v12 approval and conditional integration/review/freeze/isolation/Stage A)
authorizes this work. FINAL v12 and its fingerprints remain unchanged; its
pre-approval status prose is historical. No interpreter is being implemented.
This checkpoint is an acceptance-review overlay on FINAL v12, not a replacement
contract or builder delivery. Integration stops at the discrepancy recorded below.

Stop: validated bounded integration for parent review, before scientific freeze
or dispatch. Earlier preparation effort is unknown. Recorded integration clock
starts **2026-10-07T19:52:44Z**; the initial authorization-reading interval before
that first clock read is unmeasured, not retroactively estimated. One contributor;
elapsed includes tool/build/test waits. No stopped/owner-wait interval recorded yet.

`runtime/` is the builder dependency. It contains only runtime operations, public
types, the Candidate trait and private host dispatch layout. It has no public
constructor, Observer, fixture, pointer reader, fault control, reference or test.
`cells/` remains acceptance-only and owns physical storage/observation. A private
version-matched repr(C) dispatch table avoids exporting host constructors or
linking acceptance implementation into the builder dependency. Its context owns
one Box containing the existing shared storage capability; Drop releases exactly
that ownership. Both sides compile the same layout file and public Rust types
with one toolchain. This is not a cross-version or external stable ABI promise.
Safe candidate code cannot manufacture a capability; source review still checks
unsafe forgery, allocation bypasses and fixture-ID branching. No claim of hostile
native-code sandboxing is made.

Pending: complete integration checks, delivery fingerprints, parent review,
scientific freeze and filesystem/tool/repository/Linear isolation verification.
Actual candidate parsing/evaluation, all physical resume/destroy/failure cuts,
compiled evaluator controls and resource workloads remain unrun.

## Blocked: required snapshot information never reaches the candidate

The approved `begin(program, inputs, cells)` signature supplies no outside roots.
The runtime API exposes individual cell contents, not outside-root identities or
their order. But the approved candidate snapshot requires `state.outside`, and
the existing full-state bridge compares it with the independently predicted list.

Concrete witness, with source `input xs: ListInt; main = xs`:

| Field | Fixture A | Fixture B |
| --- | --- | --- |
| Input | xs points to cell 9 | Identical |
| Cell 9 | item 37, tail 2, holders 2 | Identical |
| Cell 2 | item -4, no tail, holders 2 | Identical |
| Outside roots | [9, 2] | [2, 9] |
| Required snapshot outside field | [9, 2] | [2, 9] |

Both fixtures pass the unchanged fixture validator. Both pass actual native
installation; runtime reads return identical contents. The unchanged logical
reference preserves the different outside ordering in every predicted state.
No candidate using the approved information can choose the required ordering.
This is a boundary-contract discrepancy, not a reference output to copy into
new expectations. No repair to the signature/schema or weakening of checks
has been made.

Coverage qualification: all 4,276 historical fixtures were inspected; none has
multiple outside roots or outside-only cells. This witness is valid under the
current fixture rules, not a demonstrated failing historical case. Outside-only
cells also cannot be enumerated through the current candidate API, but the
ordered-root witness alone establishes the missing information.

Parent review must resolve field ownership: either acceptance supplies the
outside/full-native-memory fields when composing evidence, with explicit
candidate-report/readback obligations, or an amended initialization/observation
interface supplies enough context. Prefer acceptance-owned external-root/native
fields to revealing outside/fixture provenance to the candidate. That is a
recommendation, not an adopted contract change; preserve complete observation,
outside protection and the existing negative-control obligations either way.

## Verified partial integration, not a freeze-ready handoff

- `cargo test --locked --manifest-path cells/Cargo.toml`: **12 passed**, including
  all seven original storage tests, same-store installation/rollback, cursor and
  phase access, gated numeric read, capability lifetime and the contract witness.
- `cargo test --locked --manifest-path driver/Cargo.toml`: **1 passed**, four exact typed
  pre-run formatter expectations. The generic collector compiles, but has NOT
  been exercised with a candidate or callback stub; it is unfinished code.
- Public dependency compile probe succeeds for runtime operations. Six probes
  reject Observer, fixture, constructor, private handle, events and deny controls.
  This checks the crate surface, NOT full builder context/tool isolation.
- Unchanged `bridgecheck.py`: native stub and all six rejection controls pass.
- Unchanged `wirecheck.py`: 12 encoding cases, 9 public-output cases and 7
  rejection controls pass.
- `evidence/integration-01/contract-witness.json` records both valid fixtures,
  preserved reference ordering and historical corpus qualification. Detailed
  native/formatter/access evidence is in the same directory; bridge and wire
  regressions are in `evidence/integration-bridge-01` and `integration-wire-01`.

The remaining approved integration is incomplete: executable fixture/name/type
adapter and callback-stub validation; strict schema and birth/call/failure/cleanup
normalization; incremental full-state bridge; process-inclusive timing/counter
supervision and validation; sanitized delivery assembly/inventory. The current
collector's internal Instant is NOT the approved before-process-launch watchdog.
No whole-package completion or candidate-linked execution is claimed.

FINAL v12 archive/brief/protocol/index and private corpus fingerprints remain
unchanged. Changes remain local and uncommitted on
`acceptance/rob-1333-preparation`, distinct from the unchanged `origin/main`.
No lock, builder, stage/resource run, push, merge or deployment occurred.

## Builder access isolation is a separate unmet gate

The crate compile probes establish a Rust API boundary only. They do not establish
a clean builder filesystem/context, and neither would establish tool isolation.
A new same-account Amp orb may still retrieve owner material through Linear,
read_thread, download_thread_file/changes or librarian/repository access. Private
seeds staying here is insufficient. No hard access boundary has been verified.

Proposed verifiable handoff: an explicit fingerprinted allowlist containing the
sanitized brief, runtime source/lock/toolchain and candidate build instructions;
clean builder filesystem/history/context; and independently verified tool/account/
network access that cannot retrieve owner review archives, acceptance source,
private cases or control implementations. Verify denied access through the actual
builder environment, not just absence of local files. Previously public material
cannot become unseen. Supported tool configuration is parent-owned investigation;
this thread has created no security framework/plugin or account changes.

If available configuration cannot enforce the required access restriction,
report that constraint before dispatch. An instruction not to fetch material is
not a verified hard restriction. No relaxation of the approved privacy criteria
is proposed or treated as granted here.
