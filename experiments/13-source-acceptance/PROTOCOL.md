# Final consolidated candidate contract — exact-package review, not a lock

This supplements Linear v5's proposed English rules. D141, deliverable-based
acceptance preparation, authorizes these reference/checker preparations, not a
Mo implementation. D145, bounded continuation without routine repair approvals,
authorizes consistent local repairs. D147, presented language behavior; D148,
presented ownership/step behavior; D149, presented observation/failure behavior;
D150, coverage/isolation; D151, resource targets/schedule; and D152, effort/stage
arrangement, approve only their presented scopes. Exact unpresented spellings,
fields/routing and the finished package still need approval. Existing historical
criteria, v11 document/export and earlier versions remain unchanged.

## Candidate and observer have separate capabilities

BUILDER_BRIEF.md is the exact proposed sanitized declaration/schema artifact.
Its candidate operation families are check source bytes, inspect checked structure
and source spans, begin with fixture roots, advance with a committed callback,
read snapshot/public output, and destroy. They are documentation, not executable
bindings or a claim that candidate-linked integration has run.
Snapshot reads execution state without acquiring holders or performing work.
Source checking takes the complete file, validates syntax before names/types,
and must not create managed cells. The checked program is an opaque candidate
value, not an acceptance-owned tree supplied instead of source. Stage A and B
use the same parser and interpreter entry points.

D146, invalid encoding participates in earliest-source ordering, includes UTF-8
errors in the lexical/syntax phase, not an unconditional whole-file decode-first
refusal. Earlier syntax beats later invalid bytes; earlier encoding beats later
syntax. Encoding-first diagnostics use half-open byte offsets. D143, complete
syntax before names/types, still means later encoding beats earlier semantic
errors. `wirecheck.py` fixes twelve independent examples and the proposed exact
public-output bytes. No additional operators or Boolean inputs are introduced.

Acceptance retains `cells::Observer`; the candidate receives only
`cells::RuntimeCells`. Fixture and source cells use the same actual boxed
storage. No origins, pointers, event log, expected values, private seed or
fault choices are exposed through the runtime capability. Runtime lifetime IDs
are opaque handles, not a provenance signal: the reviewer must check that the
candidate does not branch on numerical IDs or the fixture boundary. The current
prototype DOES return IDs; it is not a proof of noninterference by itself.

`read` observes actual contents, `create` allocates a new Box, `write` changes
the existing item/link, `detach` removes the unique head link into a reservation,
`metadata` changes holder/aside bookkeeping, and `free` releases the actual Box.
Detach is not a counted rebuild. API mutations are journaled; primitive counts
include only create/write/free. The observer snapshots contents and pointers
directly. Candidate-authored graph/pointer JSON cannot substitute for this.
Lifetime numbers never revive; addresses may recycle AFTER a lifetime ends.
Exact integers in this storage prototype use canonical decimal strings; this
does not choose permanent Mo representation or claim numeric/frame allocations
are free. ID/counter exhaustion is a harness-integrity failure, not a Mo cap.

The source inspection obligation covers bypass allocation, a hidden shadow
graph, fixture-ID special cases and unlogged mutations. The native storage unit
tests validate primitives only. A compiled storage-replacement control must fail
live-pointer continuity even when logical ID and readable contents are retained.
It is not a compiled Mo evaluator mutant.

## Canonical evidence and identity correspondence

`structurecheck.canonical` specifies tagged checked nodes and static declaration
paths. Bool nodes retain real Boolean values, not integers. Source ranges remain
separate. Acceptance determines lexical bindings and resolved function paths,
not candidate dumps. Runtime bindings, calls, branches and cell lifetimes get
one consistent run-wide bijection to predicted identities. Normalize every
reference through that map, including event/frame/operand/return references;
never renumber independently per snapshot. Call-enter identifies invocation and
parent; call-return identifies that same invocation. No return may be fabricated
for a suspended call.

The proposed trace is an ordered list of `step`, `transition`, source `site`,
`event_end`, `landmark`, `state`, `control`, `ready` and `release`. State includes
actual memory, binding identities/status/values, pending values, outside roots,
reservations with originating branch/call, branch and active frames. Control
contains source path, lexical scope, invocation and completed operands; release
contains the ordered cleanup chain. `controlcheck.py` gives independently
worked operand/ready/invocation/release examples. Full-state equality is required;
checking just total counts or final answers is insufficient.

`trace_projection` selects specified landmarks once and in order. It does not
invent snapshots by copying historical values. The thirteen-kind table remains
in Linear v5 section P1. Give up holder and Free cell are separate committed
actions, preserving both frozen snapshots. The full-corpus check compares every
old output/state/event field; only newly added empty root-frame metadata is
removed. Extra non-landmark dispatch/capture/leaf states are specified, not an
unbounded allowance for stuttering.

## Suspension, destruction and failure checks to execute on a future candidate

For every small public-case boundary k, start a fresh run, advance exactly k
committed actions, snapshot, resume with budget zero, snapshot again, then run
the remaining suffix. Include k=0 and terminal k. Compare the unchanged prefix,
all still-live native pointers and lifetime IDs across the zero-work join, then
the independently predicted suffix. Across separate fresh runs normalize IDs;
do NOT compare raw addresses. Boundary budgets are transitions, not call counts
or time limits. A last action reaching terminal at the exact budget reports
terminal, not suspended. Observe terminal again with zero/positive budgets and
require no changes. `observationcheck` checks supplied bundles, not a real run.

Separately destroy fresh runs at every small boundary and at terminal/failure;
call destroy twice. `cleanupcheck.outside_graph` derives the remaining graph and
counts from outside roots/edges alone. Each run-owned allocation not remaining
must be freed exactly once, outside objects retain contents and live identity,
and all run holders/temporaries/reservations/frames disappear. Evaluation,
destruction and host-fixture teardown counters remain distinct. Synthetic valid
post-states exercise predicates; they are not evidence that destroy executed.

Acceptance controls the Nth managed-create failure before side effects, excludes
fixture allocation from source counts, and exercises nested arguments/transient
cells. Preserve the last committed state and event prefix before destroy.
The storage prototype supplies independent one-based Number and Frame gates via
`RuntimeCells.allocate(domain, closure)`, controlled only through the observer.
Denial occurs before executing the allocating callback. `faultcheck.py` specifies
unchanged committed prefix, domain/ordinal and failure classification. Candidate
integration must route actual numeric buffers/frame storage through these gates;
source inspection checks bypasses. These tagged attempt counts are not proof
that all system allocations were intercepted or that arbitrary OS OOM recovers.
Refused source/invalid fixtures create
no run. OOM, timeout, invariant/readback failure and suspension remain distinct;
fatal process failure is recorded as abnormal termination, not invented recovery.
The acceptance bridge normalizes all identity-bearing full-state/event fields
and compares reported cells with separately acquired native contents at every
provided boundary. `bridgecheck.py` exercises it with a scripted execution dump
and actual Rust storage; checked lexical identities are derived from source.
The linked candidate driver and actual source execution remain future gates.

## Visibility, generated coverage and resource limits

The public review export includes acceptance source and public predictions for review,
NOT for mounting into a builder checkout/context. The private 500-case seed,
sources/predictions and 24 balanced heldouts remain outside the repository and
export. Eight heldout families each have three independently worked cases.
`boundedcheck.py` enforces depth ≤5, function table ≤3, arity ≤4 and initial
list length ≤4, and requires executed calls. Generated cases include 404 distinct
program/fixture combinations and 96 repeats; keep and report those repeats rather
than silently choosing a more favorable set. Generic predicates cover answer, continuous protection,
reachability/counts and invocation creations. Private cases add compositions
and renamed functions; generated coverage is bounded, not all source shapes.
Public manifests are review fingerprints, not scientific locks. The builder sees
approved English rules, common source/interface formats and public examples, not
private sources/predictions or expected full traces. Exact delivery isolation
must be verified before a builder starts; merely keeping a seed private is not
sufficient when executable acceptance source is otherwise mounted into context.

D151, presented bounded resource tests, approves non-tail sum of a million unique
ones returning 1,000,000 and disposal of a million-cell list without leaks or
host-stack overflow. Conditions: at least 4 GiB available provisioning (NOT a
maximum memory ceiling), 8 MiB host stack, 600 seconds per workload including
runtime observation and cleanup, at most 100 million committed execution
transitions. Record actual memory usage and recheck effective orb resources
before eventual execution. None of these workloads has run.

Small cases keep every-boundary observation. Large cases record every physical
cell operation and full state at start, every 10,000 committed execution
transitions, suspension/failure/finish and cleanup boundaries. Source/path and
stack/frame evidence complement depth: this is bounded evidence with narrower
large-run observation, not all-depth safety, speed superiority or a production SLA.
Timeout or stack overflow fails, never counts as successful suspension.

**Precise phase convention proposed for exact-package approval:** start one
monotonic 600-second clock before launching each workload process; stop only
after its required observations, cleanup and workload-specific verification
complete. Include process/runtime startup, source checking, fixture installation,
begin/initial unused-input preparation, execution, streaming/snapshot readback and
verification, finish/failure observation, run destruction/repeated destruction,
outside-value checks and host-fixture teardown. Do not pause/reset for observation,
cleanup or suspension. Record these phase durations separately but charge them
to the same clock. Prior compilation and offline preparation of expectations are
outside this workload clock and remain in the contributor effort ledger. This
inclusive convention introduces no fixture/cleanup exemption from the watchdog.

Count Start/Dispatch/Leaf/Capture/Enter/Return and all committed execution actions,
including queued Give up holder/Free cell actions in unused-input, entry, branch
and return cleanup, in the cumulative execution counter. Resume never resets it;
the cap is 100,000,000 inclusive. Observer reads and source/fixture installation
are not interpreter transitions. After execution terminates, explicit destroy
and host teardown have separately reported action/event counters, not fabricated
execution steps or additions to successful evaluation counts. They still consume
the same 600-second clock and must finish without leaks/stack overflow. Large
cleanup boundaries mean before/after each explicit destroy/teardown operation;
retain every cell event within it, not full snapshots after each cell free.
The cleanup-phase counting/clock schema is an exact-package detail for review,
not a new cleanup cap, unlimited cleanup allowance or an executed measurement.
`closeoutcheck.check_resource` currently validates supplied totals only: linked
timing/counter provenance and this phase convention still require integration.

D152, approved effort tracking and staged delivery, adopts contributor elapsed
seconds from explicit start to stop,
including tool/build/test waits, minus timestamped owner-wait/stopped intervals;
sum concurrent contributors, and separate preparation/A/B ledger rows. Host
wall time/CPU/RSS are different measurements. Earlier aggregate preparation
effort was not recorded precisely and must not be reconstructed from file mtimes.
Arbitrary implementation-hour caps are deferred: no 8/12/20/40-hour recommendation
or mandatory two-hour approvals is current. Stop at the deliverable or a substantive
blocker; routine consistent repairs continue under the existing authority.
The resource watchdog is a distinct workload condition, not an agent-effort cap.
Review Stage A evidence before separately authorizing Stage B; independently
authored checks freeze before any builder. No exact package/freeze/stage execution
is authorized by approving this arrangement.

## Review stop and remaining work

This is the consolidated review after v11, NOT final executable acceptance.
The reference uses host recursion and logical cells; it is forbidden as the Mo
implementation. The requirement/predicate/capability table in README identifies
the exercised independent checks and each candidate capability still awaited.
Actual compiled source checking/evaluation, real full-state resume/destroy/failure
execution, complete compiled evaluator controls and actual resource execution
remain unrun. A supplied record with `compiled=true` is not proof of compilation:
retain the source patch, build log, baseline result and intended-path evidence
and apply the named target predicate to actual execution records. No reference
report or stub can self-certify those gates.

### Remaining exact-package review — presented choices are not reopened

Approved presented behavior is recorded in D147 (three kinds/no coercion,
explicit function types, nearest shadowing, separate namespaces, left association,
no chained comparisons, checking unreachable bodies/branches); D148 (full ordered
arguments, live protection, call-local eligible reservations after operands,
split holder/free and saved-state resume, iterative cleanup); D149 (actual-storage
observation, separate outcomes/evidence, controlled denial without partial effects,
repeat-safe cleanup/outside protection); D150 (unchanged corpus, fixed private
coverage and builder isolation); D151 (bounded workloads/schedule); D152 (effort
and staged delivery). Earlier exact prototype integers/Bool scope and approved
diagnostic priorities remain settled. Optimizations and permanent policy remain
deferred, not extra tasks.

Still proposed for final exact approval: token spelling/precedence details not
presented, finite-literal sugar/signed-literal and fixture declaration notation,
case/reserved-name/duplicate-name and explanatory-span tables; exact comparison
spellings; exact unused-holder/reservation ordering and Enter/Return/abort fields;
wire key order/spellings, checked-tree/span/trace schemas and numeric/frame routing;
invalid-fixture rollback and invariant/readback/abnormal-failure record details;
inclusive resource phase convention above and large snapshot serialization.
The candidate-independent index fixes which draft checker implements each detail.
Recommend approving this concrete bounded package as a package, not declaring
those details individually approved by the six presented behavior decisions.
No substantive contradiction found in this reconciliation. The phase convention
is explicitly a proposed precision, not an exception to D151's watchdog.

### Delivery inventory and remaining execution gates

**Owner/reviewer archive, NOT builder input:** README/PROTOCOL; acceptance frontend,
references, exact case/prediction/span/control check sources; native observer/storage
prototype including tests and bridge stub; public evidence and retained failures.
This archive necessarily contains exact expectations/controls and must not be
mounted into the builder's checkout/context. Existing issue/document disclosures
cannot be retroactively hidden. Isolation verification must account for tool,
Linear attachment, repository and filesystem access, not just hide the seed.

**Builder-visible proposed inventory:** the finally approved language/execution
requirements; checked-source/run/snapshot/destroy and storage capability interface
declarations and field schemas; public source/fixture examples, answers and refusal
classes already disclosed. BUILDER_BRIEF.md now supplies the exact proposed
Candidate and RuntimeCells declarations/schema requirements; no implemented
interface crate or sanitized runtime dependency binary has been delivered.
It must omit executable acceptance sources, exact new prediction/span tables,
control patches/triggers and the owner/reviewer archive. The native observer source
contains compiled controls, so handing its entire crate to a builder is not an
approved interface-only delivery; supply only reviewed declarations and arrange
acceptance-side linking later. No builder starts until this is verified.

Concrete executable acceptance-boundary work still needed (not silently made):
separate runtime-only exports from Observer/fixture/control implementation in the
current all-in-one cells crate; permit host-only fixture installation/rollback
after checking into the same empty store used for frontend Number gating; supply
candidate interface bindings and callback-based collector; extend current bridge
for source spans, incremental birth/event registration, call-site/result and
failure-abort/cleanup records; add native event cursor collection for large runs
instead of repeatedly cloning complete logs/graphs; implement the approved phase
clock/counter verification. These are acceptance-owned link preparations, not
Mo interpreter work or builder-chosen boundaries. Executable changes need explicit
follow-through authorization beyond this document-only reconciliation.

**Acceptance-private files, never in review archive or builder delivery:**
`/home/user/rob-1333-private-v11/seed.json` (50 bytes), `cases.jsonl.gz`
(1,003,653 bytes; SHA256
`0f176c60d30d30fffd4d7fb25d982cd3517d1a847840027ad3e99f9c572f41f0`),
and retained `bounded-02-failure.txt`. The gzip contains the 24 heldouts and 500
generated cases/fixtures/expected data. Earlier private-version files stay retained
outside exports. Public aggregate reports reveal family/count/bounds/fingerprints
only, not private seeds/cases. Public generator/check source in the reviewer archive
is acceptance-only, not evidence that any builder has been isolated yet.

Remaining gates, in order: exact requirements/checks/package owner approval;
separately authorized scientific freeze and sanitized builder isolation; separately
authorized Stage A implementation/linked acceptance; review Stage A evidence before
separate Stage B authorization; final Stage A regression on Stage B plus actual
resume/destroy/failure, viable compiled evaluator controls and authorized resource
workloads. Candidate-linked timing, actual buffer/frame routing, birth registration,
fixture rollback, every small cut and real cleanup remain unrun. Unit/storage/stub
or synthetic record results do not substitute. No new tests or code changed during
this document-only reconciliation. Stop for final review; no scientific lock,
builder, Fable, stage/resource run, push/merge or deployment follows.
