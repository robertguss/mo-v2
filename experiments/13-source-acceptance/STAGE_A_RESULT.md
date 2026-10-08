# Stage A passes its frozen checks

Final-08 is the reviewed, source-driven, call-free Mo interpreter. It parses and
checks source, evaluates exact growing integers and lists, and suspends/resumes
with observed native ownership and cleanup. The applicable frozen Stage A checks
pass. This is finite experimental evidence, not a proof for every program or the
complete functions-and-recursion milestone.

This result supersedes preparation-only status in the frozen historical files;
those files and their earlier failures remain unchanged. It does not authorize
Stage B, streaming/resource work, merge, release or deployment.

## What passed

| Evidence | Result |
| --- | --- |
| Historical source/native baselines | 4,276 cases; 53,796 committed actions |
| Actual historical native effects | 89 same-allocation Writes, 304 Creates, 5,269 Frees |
| Retained external roots | 1,064 fixture runs; active release depth observed through three |
| Resume checks | 58,634 passes |
| Destruction checks | 58,634 passes |
| Controlled allocation-denial checks | 81,771 passes |
| Additional public baselines | 58 diagnostic/phase/priority/encoding, 2 accepted, 35 wide-decimal, 12 worked and 28 selfcheck sources |
| Applicable compiled controls | 21 passing disabled-mutation baselines; all 21 intended defects rejected |
| Private Stage A coverage | 524 capability refusals only; no private execution |

Historical baselines checked the final answer, native readback, two explicit
destroy calls, Drop and host teardown. Native effect counts above are from the
uninterrupted historical baselines, not sums across repeated lifecycle runs.
The [acceptance report](stage-a-delivery/ACCEPTANCE_RESULT.md) gives the exact
coverage, control predicates and qualifications. Its original local/uncommitted
delivery statement describes the checkpoint before this delivery was prepared.

The first extended lifecycle run reached the filesystem's direct-directory limit
before launching its next request. Continuation preserved that original directory
and used sibling shards. All 197,085 historical schedule IDs reconcile with no
gaps, duplicates or orphan destinations: 60,583 earlier passes were checked from
retained requests/rows and credited, then 136,502 new runs passed. Public-source
cuts supply the remaining 1,954 lifecycle/denial runs. The infrastructure stop
was not a candidate discrepancy and did not justify a changed criterion.

## Implementation and acceptance have separate authors

The [builder](https://ampcode.com/threads/T-01a1185b-f677-74ad-a1c9-769b73fe1411)
received only the public requirements/runtime and public-safe repair explanations.
The [acceptance author](https://ampcode.com/threads/T-01a11697-f670-71bc-bd5d-f6f57958fa55)
owned the frozen checks and ran the complete native campaign. Separation was
procedural, not technically enforced. Recorded-access review found no prohibited
retrieval; this is not proof that same-account access was impossible.

The [parent review](stage-a-delivery/PARENT_REVIEW.md) found no blocking issue.
It inspected routing, staged-action atomicity, schedule reconciliation, actual
control mutations and retained raw failures. Fresh parent builds passed all 41
builder development tests, 25 native-linked spot checks, and all 21 existing
compiled control pairs. The full control predicate-evidence JSON reproduced
exactly. These are additional bounded checks, not a parent rerun of the full
campaign. Moving the unchanged candidate/linker into the delivery checkout also
passed a fresh locked native build and all 41 development tests.

The [routing review](stage-a-delivery/ROUTING_REVIEW.md) checks real Number/Frame
capability use and that inspected actions perform controlled allocation gates
before native mutation. It does not introduce a new all-host allocation policy
for initial bookkeeping. Native operations remain acceptance-observed rather
than populated from reference predictions.

Earlier failed submissions and explanatory repairs remain preserved. Some
reporting-boundary failures exposed imprecise public wording; those limitations
remain recorded rather than being recast as violations of perfectly explicit
instructions. No accepting prediction, threshold or frozen executable was changed
to make a candidate pass.

## Exact source and a reproducible build

The eight files in [candidate/](candidate/) are byte-identical to final-08:

- Archive SHA256: `f79ea749d7a0ed2b7b1d94bd9daf1ebc6997845a1d2d3dcd4726128eb64f2eb8`.
- Candidate manifest SHA256: `943d259f1b81aaf3b572d032499ca3019676d5b459ed0eed0b4b51d628b0cd8b`.
- Scientific lock SHA256: `09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e`.

All 496 frozen files and five historical dependencies remain unchanged. The
candidate exports `mo_stage_a::StageA: mo_acceptance_runtime::Candidate`.
[stage-a-link/](stage-a-link/) contains the unchanged acceptance-owned native
linker files used for the accepted submission, with their dependency lock.

From the repository root, with Rust 1.98.1 installed:

```sh
export CARGO_TARGET_DIR=/tmp/mo-stage-a-build
cargo +1.98.1 fetch --locked --manifest-path experiments/13-source-acceptance/stage-a-link/Cargo.toml
cargo +1.98.1 build --locked --offline --manifest-path experiments/13-source-acceptance/stage-a-link/Cargo.toml
cargo +1.98.1 test --locked --offline --manifest-path experiments/13-source-acceptance/candidate/Cargo.toml
```

This linker speaks the acceptance host's request/acknowledgment protocol; it is
not a new standalone user-facing Mo CLI. The frozen `linked.run_linked` function
owns requests, observations, verification and cleanup. Recorded commands and
inputs identify exact runs; replay must use a new evidence destination.

## What this does not establish

- No functions, calls or recursion execute in Stage A. Ten exact Stage B control
  paths and sixteen Stage B semantic expectations remain deferred, not passed.
- Private cases contain Stage B features and were refused. They establish no
  private execution correctness; their contents and seed remain outside the
  public repository and builder context.
- Denials cover observed frontend/execution allocation attempts. They do not
  cover injected denial during destruction, arbitrary host OOM or every possible
  allocation schedule. Destruction after successful, suspended and failed runs
  is a different, exercised claim.
- The frontend is host-recursive and execution clones state for each action.
  There is no deep-stack, large-workload, streaming, bounded-resource or speed
  claim. The large streaming adapter remains unimplemented.
- The double-free control attempted a second native free; native rejected it
  with UnknownCell. Checks also rejected the mutant's duplicate cleanup report.
  This is not evidence that native physically deallocated the same cell twice.
- No permanent Mo number policy, universal safety proof, agent-helpfulness result
  or production-runtime claim follows from this checkpoint.

## Evidence and delivery

[stage-a-delivery/](stage-a-delivery/) retains all eight exact final submissions,
the earlier partial checkpoint, public v13–v17 packages, original reviewer v12/v13
archives, reviewed reports, reconciliation, compiled-control review source/raw
evidence and fresh parent review evidence. Only `public-packages/` contains
sanitized builder-facing requirements; reviewer archives and acceptance evidence
remain excluded from builder context even when publicly retrievable.

The [lossless evidence package](evidence/stage-a-durable-01/README.md) preserves
all 831,636 regular files from candidate runs 01–08 and the continuation:
4,946,455,087 content bytes in 51 independent compressed volumes. The archives
total 335,184,313 bytes, with 32,704,475 bytes of compressed content indexes.
Every volume is below 20 MiB. Its original-versus-restored check matched every
file, all 831,627 sealed entries and nine manifests, and reconstructed 30 frozen
links. Private cases, seeds and refusal rows are excluded; no sealed original
was changed. The package's restore/verify commands do not execute candidates.
After fetching and integrating the packaging commit, the parent independently
decompressed and hashed all 831,636 archived files and reconciled the same nine
manifests: [passing parent verification](stage-a-delivery/durable-parent-verification.json).
This was archive verification, not another full restoration or candidate run.

The [package index](evidence/stage-a-durable-01/INDEX.json) and per-volume indexes
pin all paths, content hashes and sizes. `stage-a-delivery/DELIVERY.sha256` covers
the integrated source, linker, readable result and smaller delivery files;
`evidence/stage-a-durable-01/PACKAGE.sha256` covers the large package separately.

Acceptance recorded 13,589 measured seconds, with earlier unknown preparation and
final reporting left unknown. Separate packaging measured 619.908 seconds for
build and full restore; other packaging effort was unmeasured. Builder recorded
47m10s active and 70m27s stopped, with stopped time excluded. Parent review has no
separate measured total; these figures are not a complete project effort total.

Dedicated branch: `implementation/rob-1333-stage-a`. Done requires a separately
authorized, confirmed merge; this checkpoint stops for review before Stage B.
