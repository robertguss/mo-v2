# Stage A scientific freeze — reviewed v13 plus public v14

This freeze fixes the acceptance contract, interfaces, expectations and checks
before any Mo builder starts. It is **not a passing Mo acceptance result**.
`STAGE_A_LOCK.json` is the exact fingerprint inventory; paths in its `files`
map are relative to this directory. Historical dependencies use repository-relative
paths. The lock does not hash itself; its fingerprint is recorded separately.

Authorization is D153 (the conditional integration, review, freeze and Stage A
sequence), D154 (acceptance-owned external-root and independently observed
physical-memory reporting), and D155 (procedural Stage A builder separation).
The parent completed review and authorized this freeze in
[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333), comment
`8ff483bb-0ecb-42f4-93ed-c828105af49e`, and the
[parent thread](https://ampcode.com/threads/T-01a1165b-f05d-7209-98fb-f205021baff2).
No new language choice or weakened criterion is introduced.

## What is fixed

- The reviewed v13 executable package and evidence, including the fixed
  references, comparisons, schema, native observation, failure and cleanup checks.
- The v14 public documentation amendment: `BUILDER_HANDOFF.md` replaces the v13
  handoff, and `BUILDER_CHECKED_DUMP_V14.md` specifies the exact checked-dump keys.
  No executable file changed after review. The original v13 manifest is retained;
  its handoff fingerprint intentionally describes the older archived handoff.
- The original v12 contract and its recorded archive, amended only by the approved
  external-memory ownership and procedural separation contracts. Old preparation
  documents still say “not frozen”; those statements describe their checkpoints.
- Every historical corpus field: 4,276 cases and 27,721 snapshots. The unchanged
  finite-corpus lock and corpus are separately fingerprinted, not recopied.
- The existing 24 heldouts and 500 generated rows, with 404 distinct generated
  cases and 96 repeats. Only the compressed corpus fingerprint and counts are
  published. Private cases, expected outputs and seed remain acceptance-local.
- All 31 named evaluator-control obligations in `closeoutcheck.py`, including
  intended-path execution, passing baseline and rejection by the intended
  predicate rather than an unrelated failure. They are fixed obligations, not
  31 executed evaluator mutations. Stage B-specific obligations remain deferred.

Acceptance owns external roots and observes actual native storage. It must never
fill an observation from reference predictions. The candidate retains its
execution-state and readback duties. Outside protection, physical comparisons,
failure-prefix checks and negative controls remain intact. The builder cannot
edit these accepting files or retune an expected result to its implementation.

## Exact delivery and procedural separation

The unchanged `rob-1333-stage-a-public-v14.tar.gz` is the **only builder delivery**:
five requirements documents, four runtime crate files and `DELIVERY.sha256`.
Its nine content fingerprints are in the lock. The acceptance branch, scientific
lock, reviewer archives, private files, reference/checker source and controls are
not builder context, even where publicly retrievable.

The parent must verify the fresh starting files/context against that allowlist,
give the explicit prohibition on retrieving excluded material by any route, and
record/check tool use. Same-account tools still technically allow retrieval.
This is procedural separation, not enforced inaccessibility. Package inspection
here does not establish the future builder's context or access compliance.

## Evidence and checks that still require a candidate

Retained acceptance-author evidence: 13 native storage tests, two driver tests,
23 native fixture-stub successes, 49 rejected integration controls, 545 unchanged
reference regressions, and the historical corpus comparison with 53,796 reference
transitions. The parent independently rebuilt storage/driver, checked the clean
public runtime, reran the historical comparison, exercised 19 stub runs and four
compiled bad-stub controls, and reproduced both repaired review defects.
The private 524 rows were not transferred to or rerun by the parent.

These are preparation and stub results. Still unrun: actual candidate linkage,
source/allocation-routing inspection, original-source historical comparisons,
real small-case suspension/resume/destruction/allocation-denial cuts, and the
applicable compiled evaluator controls with their intended-path evidence.
There is no candidate acceptance, builder dispatch, merge or deployment here.

Stage A is call-free. Stage B calls/recursion require separate authorization after
Stage A review. The end-to-end large streaming adapter is **not implemented**:
`linked.py` uses `large=false`, and the verifier holds full small traces. Later
adapter preparation/review and authorized resource execution remain separate;
this freeze makes no scalable or million-depth claim. Retaining Stage B/resource
requirements and evidence fingerprints does not authorize their execution.

## Recheck without a new campaign

Compare each `files` and `historical_dependencies` SHA256 to the corresponding
bytes, compare the private compressed corpus hash locally without exporting it,
and compare each preserved archive hash. For the public archive, additionally
require exactly the nine listed files plus `DELIVERY.sha256`, no links or extra
entries, and check every member against `public_delivery.files`.

`evidence/stage-a-freeze/validation.json` records this inventory/publication audit,
including staged-path exclusions. It is freeze evidence, not an additional
scientific criterion. No executable edits or new test campaign accompany the
freeze. Stop after validated branch commit/push and return to the parent before
dispatch. Keep this acceptance context separate and available for the candidate.
