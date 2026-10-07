# Interface v13 — acceptance-owned external observation

Read with BUILDER_BRIEF.md (retained exact v12). D153, exact v12 approval and
conditional integration/review/freeze/isolation/Stage A, approved that contract.
D154, acceptance-owned external-root and independently observed physical-memory
reporting, changes only the evidence ownership below. The original brief,
counterexample and earlier evidence remain retained, not silently corrected.
This is interface preparation, not builder dispatch or a scientific lock.

## Candidate readback and acceptance observation remain independent

Candidate.snapshot still returns its actual execution state. Its `state` object
now has exactly `kind, bindings, pending, aside, branch, frames`: omit `memory`
and `outside`. Candidate supplies all other v12 snapshot, control, ready, release,
step, event, birth, failure and cleanup fields unchanged. No observer, external
root or fixture-provenance information is added to Candidate.begin or RuntimeCells.

Acceptance retains the actual fixture's ordered external-root list. At each
required full observation it independently reads the native Observer's complete
allocated graph and live pointers, then composes `state.memory` and `state.outside`.
These are observations of storage and host-retained roots, NEVER copies of a
reference prediction. The complete composed state is compared with independently
fixed predictions. Every reported execution value/holder/reservation/control/frame
is still checked; answers are read back from actual cells, not candidate claims.
Every physical operation/lifetime comparison, outside-value protection, cleanup,
negative control and full-state comparison remains required. Unknown candidate
fields, including candidate attempts to supply the two host-owned fields, refuse.

Fixture cell identity correspondence is acceptance-owned initialization, not a
candidate birth/provenance declaration. Root invocation 0 is implicit. Candidate
births report initial input bindings in the zero-step snapshot, then new cell,
binding, match-branch and invocation identities in the committed callback that
first exposes their creation. Existing birth fields remain domain/id/origin/
invocation. Origins are input/declaration paths for bindings, the Cons path for
new cells, Match path for branches and call-site path for invocation frames.
Owning invocation is the active call for cells/bindings/branches and the caller
for a newly entered invocation. No retired ID is reused within a domain.

Source span map uses `root` for the whole file; input/function declarations use
their whole declaration ranges; parameters use name through type annotation;
expression nodes use original parser ranges in root/preorder declaration/body/
main order. Local declaration identities are binding references, not additional
expression nodes. Literal expansion retains original item ranges and gives its
synthetic Cons/Nil nodes the containing literal's range as required by v12.

One documentation omission corrected from the unchanged historical/reference
status set: binding statuses also include `givenUp` (a released holder), alongside
holding/movedOn/noHolder. This preserves the existing predictions rather than
changing them to the shorter list printed in v12.

## Delivery boundary

The public dependency is `runtime/` (mo-acceptance-runtime), with the Candidate
trait and the v12 operation signatures unchanged. It has no Observer, fixture,
event reader or fault control. The acceptance-owned driver provides native
storage, fixture validation/installation, observation composition and checking.
No host collector, reference, private predictions or control implementation is
builder input. Exact inventory and validation precede dispatch.

D155 (procedural builder separation for Stage A) supersedes the old demand for
technically denied account/tool access. The parent supplies a fresh context and
clean starting files containing only the fingerprinted approved delivery, prohibits
retrieval of excluded acceptance material by ANY route, and checks recorded tool
use. Same-account tool/Linear retrieval remains technically available. Neither
clean files nor a recorded-access audit proves technical inaccessibility. Actual
exposure or an integrity discrepancy must be reported. No security framework,
plugin, denied-access configuration or global account changes are required.

BUILDER_HANDOFF.md identifies the exact public inventory and build boundary.
This amendment and the retained v12 brief are requirements, not permission for
the acceptance author to implement Mo or bypass parent review/freeze/dispatch.
