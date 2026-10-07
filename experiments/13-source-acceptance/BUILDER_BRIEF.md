# Sanitized builder-facing specification — proposed, not dispatch authorization

This document is the proposed public brief/interface artifact for exact-package
review. It contains requirements, interface declarations and already-public
examples only, not acceptance code, private cases, exact trace/span tables,
seeds or negative-control implementations. No builder or scientific freeze is
authorized. The separate acceptance author never implements the interpreter.

## Deliver one source-driven interpreter in two separately authorized stages

Stage A: original source bytes determine a checked program and call-free execution.
Use the historical expression/input meanings; the host supplies typed fixture
roots, never an expression or answer. Stage B: extend the same source frontend
and interpreter with explicitly typed named first-order functions and recursion.
Review Stage A evidence before separate Stage B authorization. No corpus/case-ID
dispatch, second parser/runtime, acceptance-reference import or replay on resume.

Approved presented behavior: integers, Booleans and integer lists without coercion;
exact growing prototype integers; explicit function parameter/result types;
nearest local shadowing and separate function/local namespaces; left-associated
arithmetic and no chained comparisons; static checking of every body/branch,
including unreachable ones. Arithmetic is addition/subtraction only. Ordinary
true/false literals, conditionals/list match, calls and mid-expression resume
are in scope. Permanent syntax/number policy is not chosen.

Arguments finish left to right, including unused ones. Completed arguments and
suspended callers' live values stay protected. Reservations are call-local;
reuse requires an eligible cell and both cons operands complete. Giving up a
holder and freeing its cell are separate committed actions; queued cleanup survives
suspension. Explicit iterative execution/cleanup state permits saved-state resume.
Per-call creation accounting starts at entry after explicit arguments and includes
entry, nested and transient creation, not merely net memory growth. Optimization-
first tail-call/early-cleanup alternatives are deferred.

Actual cell storage/lifetimes, not counters alone, support reuse evidence. Controlled
cell/number/frame denial preserves the last committed state without partial effects.
Cleanup releases run-owned storage, preserves outside-held values and is repeat-safe.
There is no arbitrary OS-OOM recovery guarantee or unlimited-resource promise.

## Proposed exact small notation — subject to final package approval

```text
program := inputDecl* functionDecl* "main" "=" expr EOF
inputDecl := "input" ID ":" inputType ";"
functionDecl := "def" ID "(" params? ")" ":" type "=" expr "end"
params := ID ":" type ("," ID ":" type)*
inputType := "Int" | "ListInt"
type := inputType | "Bool"
expr := "let" ID "=" expr "in" expr
      | "if" expr "then" expr "else" expr "end"
      | "match" expr "do" "[]" "->" expr ";"
          "[" ID "|" ID "]" "->" expr "end"
      | compare
compare := sum (("==" | "<" | "<=") sum)?
sum := atom (("+" | "-") atom)*
atom := INT | "-" INT | "true" | "false" | ID | ID "(" args? ")"
      | "(" expr ")" | "[]" | "[" expr "|" expr "]"
      | "[" expr ("," expr)* "]"
args := expr ("," expr)*
ID := ASCII letter or underscore followed by ASCII letters/digits/underscores
INT := "0" | nonzero decimal digit followed by decimal digits
```

Proposed lexical detail: case-sensitive identifiers, reserved keywords/type names;
LF/CRLF whitespace, # line comments, longest-token <=/->; leading-zero/hex/float/
exponent/string/Unicode-identifier/trailing-comma forms refuse. Negative syntax
is a signed literal, not general unary negation; -0 means zero. Finite list sugar
expands to nested Cons; operands evaluate left to right and cells build inside-out.
Source checking creates no managed list cells; frontend numbers are separate.

Proposed name/type detail: functions globally visible, including forward/mutual
calls; function bodies see parameters/locals, not main/caller locals. Duplicate
inputs/functions/parameters and equal match binders refuse. Let binds only in its
body; match binds Int head/ListInt tail. +,-,==,<,<= take Int only; Cons is
Int × ListInt; match requires ListInt; if requires Bool and equal branch types.
Arity and ordered argument/result kinds must match declarations. No Boolean
inputs/operators/equality/lists, closures, function values or termination checker.
Stage A parses declarations/calls but reports stage-unsupported capability;
Stage B lifts that restriction without an alternative parser/runtime.

Finish whole-file lexical/syntax validation before names/types. Earliest source
lexical/syntax error wins, including invalid UTF-8. Encoding-first diagnostics use
half-open byte offsets; other spans use 1-based Unicode-scalar line/columns, tabs
one column and CRLF one newline. Proposed refusal names: lexical, encoding,
numeral, syntax, stage-unsupported, duplicate-input/function/parameter,
match-binders, input-type/type, unbound-variable/unknown-function, operand-kind,
head-kind/tail-kind/scrutinee-kind/condition-kind/branch-kind, arity,
argument-kind/result-kind. Unknown names mark the identifier, duplicates the
second identifier, wrong expression kinds that expression, arity the whole call,
branch mismatch the second branch, result mismatch the body, unexpected token
that token and missing token an empty insertion span. No exact new refusal tables
are supplied here.

Already-public examples: 9 - 4 - 2 returns Int 3; 9 - (4 - 2) returns Int 7;
if false then 7 else 11 end returns Int 11. Recursive increment of [3,-2,8]
returns [4,-1,9]; an outside-retained original remains [3,-2,8]. These requirements
do not reveal newly private programs or exact operation/suspension predictions.

## Exact proposed candidate API declarations — interface only

These Rust declaration shapes are a specification, NOT implemented traits or
a claim that a compilable public dependency already exists. Rust 1.98.1/edition
2024 is the current acceptance prototype toolchain, not permanent Mo policy.
Acceptance supplies the final boundary crate and linked driver; builder supplies
only Candidate implementation and its opaque CheckedProgram/Run types.

```rust
pub enum Kind { Int, Bool, ListInt }
pub enum Value { Int(String), Bool(bool), ListInt(Option<u64>) }
pub enum Span {
    Text { start: (u64, u64), end: (u64, u64) },
    Bytes { start: u64, end: u64 },
}
pub struct Diagnostic { pub class: String, pub span: Span }
pub enum CheckFailure {
    Refused(Diagnostic),
    Failed { class: String, domain: Option<Resource> },
}
pub enum Status { Suspended, Finished, Failed }
pub struct Outcome { pub status: Status, pub committed_steps: u64 }
pub struct CleanupFailure { pub class: String }

pub trait Candidate {
    type CheckedProgram;
    type Run;
    fn check_source(source: &[u8], allocations: &RuntimeCells)
        -> Result<Self::CheckedProgram, CheckFailure>;
    fn checked_dump(program: &Self::CheckedProgram) -> Vec<u8>;
    fn source_spans(program: &Self::CheckedProgram) -> Vec<u8>;
    fn begin(program: &Self::CheckedProgram,
             inputs: Vec<(String, Value)>, cells: RuntimeCells) -> Self::Run;
    fn advance(run: &mut Self::Run, budget: u64,
               committed: &mut dyn FnMut(&Self::Run, &[u8])) -> Outcome;
    fn snapshot(run: &Self::Run) -> Vec<u8>;
    fn public_output(run: &Self::Run) -> Vec<u8>;
    fn destroy(run: &mut Self::Run) -> Result<(), CleanupFailure>;
}
```

The callback's bytes are exactly one committed metadata record. Call it once
after each committed action, with the actual Run readable at that boundary;
acceptance immediately reads its retained native Observer and, when required,
calls snapshot. Metadata keys are step, transition, site, event_end, landmark,
events_added, births_added; the latter arrays contain only this commit's additions.
Acceptance assembles small-case full transition records from metadata and snapshot.
Large callbacks do not serialize the full graph every step: snapshot occurs only
at the approved checkpoints, while every cell event remains observable. This is
observation scheduling, not a second evaluator or alternate semantic runtime.
Callback performs no candidate execution or holder acquisition.
It must not depend on a caller-supplied expected state. Trace serialization cannot
commit extra interpreter work. Outcome reports cumulative steps, not callback
counts supplied by acceptance. Budget zero commits/callbacks nothing and preserves
state; an already terminal run stays terminal. A final action at the exact budget
returns terminal. Failed state never resumes. Denied allocation reports the failed
operation without committing it or callbacks for partial work; snapshot/public
output expose that failure and the unchanged committed prefix. Begin creates a
readable zero-step run or a zero-step safely failed run; initial execution cleanup
occurs through advance, inside evaluation counting, not hidden in begin. Invalid
fixtures are rejected by acceptance before begin. Refused source has no run.

Check_source receives an empty store's capability for Number allocation gating
only, not fixtures, expectations, fault settings or observer access. It may not
create/read/write managed cells or allocate interpreter Frames. RuntimeCells moves
into begin, while the acceptance Observer retains access to the same store.
Front-end numeric and runtime resource logs have labeled phases; they are not
managed-list events. Acceptance must install fixtures into that same store after
checking, a host-side capability currently missing from the storage prototype.
This is a concrete required link-boundary change, not permission for the builder
to construct fixtures or implement an alternative store.

Pre-run output ownership is explicit: invalid source returns CheckFailure::Refused;
denied frontend Number allocation returns CheckFailure::Failed with class
resource-exhausted and domain Some(Number), not a Diagnostic/syntax refusal.
There is no Run in either case. The acceptance/host adapter serializes Refused
to the refused class/span schema and pre-run Failed to failed/class/step="0";
fixture rejection likewise uses host-formatted invalid-fixture output. Candidate
public_output is only for an existing Run's finished/suspended/failed outcome.
Host formatting must apply the same exact wire contract, not invent a partial
answer or treat exhaustion as invalid source. Pre-run failure evidence retains
phase/domain/denial log separately; no execution transitions or managed evaluation
events occurred. Host/process death remains abnormal termination, not a fabricated
typed recovery. Implemented host formatter/check-failure adapter is unfinished
acceptance-owned glue; the distinction is specified here, not claimed executed.

## Exact proposed schema requirements

All API byte vectors are strict UTF-8 JSON. Public output is one compact LF line,
fixed key order: finished = status/type/value; suspended = status/steps;
failed = status/class/step; refused = status/class/span; invalid-fixture =
status/class/path. Integers and step totals serialize as canonical decimal strings;
Bool is real JSON Boolean; ListInt output is an array of decimal strings.
Refusal span is start/end line-column pairs or bytes [start,end]. No raw pointers,
timings or IDs occur in deterministic public output. Noncanonical/duplicate keys,
extra records or numeric-as-Bool coercion are forbidden. Format spellings remain
proposed exact-package details, not individually approved in behavior review.

Checked dump: Program has ordered inputs/functions/main; declarations name/type;
Int/Bool/Var/Add/Sub/Eq/Lt/Le/Nil/Cons/Let/If/Match/Call tags. Expanded literal sugar,
node paths, result kinds, lexical declaration paths and resolved function paths
are required. Each node has path/type; Int has canonical decimal value, Bool JSON
value, Var name/binding, Call name/function/children, Let name/binding/children,
Match head/tail declarations/children, and compound nodes ordered children.
Program inputs have name/type/binding; functions name/function/parameters/result/
body. Path scheme: input/i, function/i, function/i/parameter/j, main or
function/i/body, child /j, local /binding and match /head or /tail.
Source_spans returns an ordered JSON array of {path, span} rows, root then
preorder inputs/functions/main; span uses the public Text or Bytes object format.
Every source node has its original explanatory range, including literal/child
ranges despite expansion. Synthetic Cons nodes use the containing literal range,
while explicit item children keep their own ranges. This proposed span-map
availability/serialization needs final approval and acceptance-owned link plumbing;
the builder must not invent another scheme.

Committed record keys: step, transition, site, event_end, landmark, state,
control, ready, release. Step/event_end/identity indices are JSON integers, never
Booleans; Int values are decimal strings. site is the checked source node path or
root. landmark is the optional required historical landmark index. state keys:
kind, memory, bindings, pending, outside, aside, branch, frames. memory rows:
[cell,item,tail,count,status]; bindings [identity,name,value,status]; pending and
branch values ["n",decimal], ["b",Boolean] or ["l",cell-or-null]; outside roots;
aside [owner-branch,cell]; frames ordered active invocation IDs. control rows:
site, scope [name,binding] pairs, invocation, operands; ready is value-or-null;
release is ordered cell IDs. Candidate cells/IDs are raw handles; acceptance
owns the one-run correspondence to its independently predicted identities.
Cell status is live/aside; zero-count queued-free cells remain physically present
until their separate Free action. Binding status is holding/movedOn/noHolder.

Snapshot keys are step, status, state, control, ready, release, event_end, events,
births, failure, cleanup_events. Status is suspended/finished/failed; events and births are the
append-only prefixes (callback supplies incremental additions). Failure is null
or {class, step, domain, aborts}, with domain cell/number/frame for controlled denial,
or null for other failures. Logical cell events are [create|write|free,cell];
enter is [enter,invocation,parent,function,site], return [return,invocation,result].
result uses the tagged Value form. Failure aborts are [abort,invocation] records
in the separate failure evidence, not additions to the preserved committed-event
prefix; never synthesize a return. Cleanup_events is a separate append-only
destroy-phase cell-event list, initially empty, never folded into execution counts.
Birth rows are
{domain,id,origin,invocation}, with domain cell/binding/branch/frame, raw integer
id, source/declaration-path origin or root, and owning invocation (root=0).
They are observations, not expectations;
acceptance validates identity origin/order against source and predictions.
This exact proposed extension is not implemented in the current bridge, which
handles its smaller tested enter/return subset. Acceptance must add validation
and normalization for site/result/abort/birth/span fields before freeze or builder;
no executable checker extension is made during this document reconciliation.
Lifetime IDs never revive; physical addresses need agree only while continuously
live within a run, not across fresh runs. Acceptance—not candidate JSON—supplies
native pointers/content/event observations to the bridge.

## Minimal RuntimeCells dependency — proposed exact public surface

Builder receives only public type/method declarations and a compatible runtime-
only dependency artifact supplied by acceptance. Cell is item:String,
tail:Option<u64>, holders:u64, aside:bool. Error variants are
InjectedAllocationFailure/UnknownCell/InvalidDetach; Resource is Number/Frame.
RuntimeCells is opaque, nonconstructible by the candidate, without Observer,
fixture constructors, pointers, event readers, deny controls or test implementations.

```rust
impl RuntimeCells {
    pub fn allocate<T>(&self, domain: Resource,
                       allocation: impl FnOnce() -> T) -> Result<T, Error>;
    pub fn read(&self, id: u64) -> Result<Cell, Error>;
    pub fn create(&self, cell: Cell) -> Result<u64, Error>;
    pub fn write(&self, id: u64, item: String,
                 tail: Option<u64>) -> Result<(), Error>;
    pub fn detach(&self, id: u64) -> Result<Option<u64>, Error>;
    pub fn metadata(&self, id: u64, holders: u64,
                    aside: bool) -> Result<(), Error>;
    pub fn free(&self, id: u64) -> Result<(), Error>;
}
```

These signatures mirror the existing tested runtime methods. The existing whole
acceptance-cells crate is NOT this sanitized dependency: it publicly exports
fixture/Observer and includes compiled negative-control tests. Acceptance must
prepare a runtime-only export/façade and host-only observer/fixture capability,
with same-store linking; no executable boundary change is made here. Candidate
Number/Frame allocation closures must route real buffers/frame storage through
the gate; a gate call followed by uninstrumented allocation is not compliant.
**Proposed exact Number routing detail:** RuntimeCells::read clones Cell.item's
owned String. A candidate-facing read that yields that owned numeric string must
therefore execute inside the Number callback, for example
`cells.allocate(Resource::Number, || cells.read(id))`; distinguish denial of the
outer gate from an inner read error. The existing gate releases its store borrow
before calling the closure, so this does not require an API implementation repair.
Candidate numeric strings supplied to create/write must themselves have been
produced on gated parse/arithmetic/copy paths; those methods are not permission
to smuggle in ungated owned numeric buffers. Acceptance-only Observer readback
copies and host-fixture bookkeeping are excluded from candidate Number attempts.
This is proposed routing precision, not owner-approved blanket allocation policy,
an all-host-allocation accounting claim or an OS-OOM recovery guarantee.
The retained failure fixtures predict preservation/ordinal classification, not
whole-program Number-attempt schedules. They were not changed; actual candidate
read/copy/create/write routing and any program-specific denial schedule remain
unverified. No mismatch with fixed expectations was demonstrated by this source
review; the current native bridge stub does not establish candidate Number routing.
Managed create denial occurs before cell effects. Multimutating committed actions
must preserve the previous commit on any controlled denial; source inspection
and failure tests establish this, not the gate alone. Actual library/ABI artifact
fingerprint and same-store callback linkage are pending acceptance preparation,
not something a builder is authorized to fill in.

## Delivery inventory, resource clock and authorization gates

Builder-visible artifact now prepared: this BUILDER_BRIEF.md specification only.
After exact approval, acceptance supplies sanitized public declarations/schema
artifact and runtime-only dependency; the eventual builder candidate exports the
Candidate implementation. No implemented interface crate, sanitized runtime
binary, candidate build command or linked executable exists yet. The declaration
specification fixes the intended boundary rather than asking a builder to choose it.

Never deliver acceptance source/checks/references, exact new expectations/span
tables, private cases/seeds, negative-control patches/triggers, Observer sources,
owner/reviewer archive or fixture constructors into builder context. Previously
public examples remain public. Verify filesystem/repository/tool/Linear-attachment
isolation before implementation; isolation has not run. Acceptance supplies host
fixture validation/install/rollback, Number/Frame/cell denial configuration,
native observation collection, typed birth normalization, callback-driven budgets,
resume/destroy loops, event/state comparison, source inspection/control runs and
resource clock/counter provenance. The bridge/stub tests are not candidate runs.

Approved resource conditions: million unique ones non-tail sum returns 1,000,000;
discarded million-list cleanup must complete without leaks/host-stack overflow;
8 MiB stack, >=4 GiB available provisioning (no maximum-memory ceiling), 600
seconds per workload including observation/cleanup and at most 100 million
committed execution transitions. Every small boundary is observed. Large runs
retain every cell event and full state at start/every 10,000 execution steps/
suspend/fail/finish/cleanup boundaries. Record actual memory; recheck resources.

Proposed precise clock: before workload process launch through source/fixture
setup, execution, readback/verification, destruction twice, outside checks and
fixture teardown; no clock pause/reset. Prior compilation/offline predictions
are not runtime workload phases. Internal queued cleanup counts as execution
transitions; post-terminal destroy/teardown counters stay separate but inside
the same watchdog. Timeout/stack overflow fails, not suspension. This is bounded
evidence, not all-depth safety, a speed claim or SLA. Exact phase/schema details
still require package approval and linked integration.

Approved effort is contributor elapsed including builds/test waits, excluding
recorded owner-wait/stopped periods, summing concurrent contributors; old prep
unknown. Arbitrary implementation-hour caps are deferred. Stop at deliverable
or substantive blocker; routine consistent repairs do not require two-hour approvals.
No final package/lock/builder/stage/resource execution is authorized by this
brief. Exact owner approval and independently authorized freeze precede builder;
review Stage A before separate Stage B authorization. Candidate-linked physical
resume/destroy/failure, compiled evaluator controls and resource checks remain gates.
