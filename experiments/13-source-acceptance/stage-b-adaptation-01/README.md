# Explicit observation candidate adaptation — resource gate not passed

## Current continuation

Robert authorized tracking reconciliation, continued Stage B work and merging
only ready PRs. The original bounded report below records the earlier checkpoint;
its former execution/delivery stop is historical, not the current authorization.
The replacement freeze and adaptation were pushed in
[f576abe](https://github.com/robertguss/mo-v2/commit/f576abeb22a98cc44ae78d0e89dca74ab1d33957).
Original submissions, scientific locks and earlier failures remain unchanged.

The same rebuilt native executable passed all 524 private cases: 24 reserved
and 500 generated, with 35,030 resumes and 35,030 destruction runs at every
boundary. Each of the eight anonymized reserved families passed 3/3; generated
rows have no family labels. Zero failed or unrun cases. Wall time was 1,544.240
seconds including pilot, checking and evidence, excluding compilation. Private
sources, names, seeds and raw rows stay outside the repository; only aggregate
totals are in `evidence/continuation/private-aggregate.json`.

All nine active compiled control classes were caught across ten passing baseline
and rejected mutant pairs. `review_controls.py` replays the retained first
failures with the frozen verifier and records the intended defect. The two
previously disputed controls use the frozen revision's scoring. The adapted
omitted-creation mutant also panics later during cleanup, after its physical
creation was decisively rejected for missing logical accounting. No panic alone
is counted. The always-copy policy is rejected at unique decomposition, before
later construction; no unobserved later allocation is claimed. The separate
entry-allocation control remains inapplicable. All 16 deferred diagnostic
refusals pass. `controls-and-refusals.json` preserves the original run report;
`control-review.json` separately completes its pending source/predicate review.

The initial control build hit a path collision between two spellings of the
same frozen runtime. Only disposable-copy Cargo linkage was corrected, and
the failed source/build log is retained separately. The candidate and frozen
dependencies were not repaired or changed during this continuation.

The million-element recursive sum timed out at 900.000636 seconds. The verifier
had reached step 6,650,000 of 18,000,014, before the required deepest pause at
12,000,005. This is a **failed resource check**, not a correct completed answer
or accepted deep-stack run. No earlier semantic rejection was recorded. The
last in-flight record may have been interrupted by the watchdog; the reached
step is not a claim that every field of that last record completed checking.
The million-element discard was not run after this first material failure.

The same debug binary ran against frozen revision 02, with 15,172,587,520
available bytes and an eight-MiB stack. The unchanged inclusive clock covers
launch, source checking, fixture installation, execution, observations and
cleanup. Every received row was streamed to a compressed public evidence file.
The run did not finish, reach deepest-point observation, or complete cleanup;
the watchdog killed the process. No general safety, leak-freedom or scaling
claim follows. This end-to-end timing does not isolate candidate execution from
collector/verifier/retention cost. No optimized-build resource result is claimed.

`run_approved_large.py` uses the frozen `LargeVerifier`, clock checks and resource
predicates, with the required deepest-pause/resume schedule and unchanged
900/600-second limits. Before approved-depth execution, its orchestration was
checked at small depths against the frozen loop; the resource predicate
correctly refused those small depths. No frozen checks or limits were changed.

**Remaining:** investigate the end-to-end performance failure, obtain passing
results for both unchanged resource obligations, then complete merge review.
PR #9 remains draft and unmerged; CI passing is not Stage B acceptance. Earlier
PRs #7 (historical failed evidence) and #8 (binding-order clarification) merged
under Robert's conditional approval; main Buildkite 31 passed.

Fresh CI-style checks pass: locked native build, 54 candidate development tests
and three collector tests. The fresh binary is byte-identical to the campaign
binary below. CI now builds both the preserved baseline and this adaptation;
CI does not run private cases or resource acceptance.

## Continuation reproduction and evidence

From this directory, each command needs a new external destination. The private
command requires the original private corpus on the acceptance orb. Its runner
SHA256 is `ab888bf07ca5871e5440bc45f6ab86cfe19dc0c8e06d68b6608761b86f622a13`;
it verifies the candidate, corpus, locks and original public schedule before and
after the run. These commands repeat potentially lengthy work, not a new approval.

```sh
python3 run_private.py /home/user/NEW-private "$CARGO_TARGET_DIR/debug/rob1333-stage-b-link"
python3 continue_controls.py /home/user/NEW-controls "$CARGO_TARGET_DIR/debug/rob1333-stage-b-link"
python3 review_controls.py /home/user/NEW-controls /home/user/NEW-control-review.json
python3 run_approved_large.py /home/user/NEW-large "$CARGO_TARGET_DIR/debug/rob1333-stage-b-link"
```

`evidence/continuation/` holds only aggregate private results and public reports.
`public/INDEX.json` indexes byte-preserving public volumes, with original paths,
sizes and SHA256s. It includes the prior adaptation's raw small/public runs,
both control-build attempts, control sources and observations, orchestration
smoke checks and the failed resource run. Build/cache trees and dependency links
are omitted; no private corpus, seed, request, row or per-case result is included.
All originals remain in their external directories. The older bounded evidence
index's `raw_archived: false` describes its earlier checkpoint, not this package.
Full restore and content verification passed for all 33,277 original public
files (33,296 archive members, including large-file chunks), in 162 volumes
totaling 318,499,490 compressed bytes. All seven dependency links were restored,
and the control review reproduced byte for byte from restored raw evidence.
`preservation.json` records the unchanged 967 original frozen files, five
historical dependencies, all 41 replacement-frozen files and candidate manifest.

Restore into a nonexistent directory and verify every original content hash:

```sh
python3 package_continuation.py --restore evidence/continuation/public /home/user/NEW-restored
```

Large files are rejoined from checked byte-offset chunks; the restore verifies
their complete hashes. The index's `omitted_dependency_links` lists each original
link and its target. To rebuild a restored control copy, recreate those links
at their restored paths, replacing the original repository prefix in each target
with the current repository root. All targets are preserved revision-02 files;
no private target is referenced. The failed first copy intentionally retains its
original linkage collision. Reproduction uses `continue_controls.py` for the
corrected copy rather than claiming the failed setup builds.

## Original bounded adaptation checkpoint

Robert approved freezing the reviewed replacement acceptance package and then
adapting the candidate in the acceptance thread. The additive freeze is
`../stage-b-revision-02/LOCK.json`, SHA256
`5749ccb78db090744b9e96c6030e92a80b83776accbf21f5a1dc66e32fa523fc`.
The original lock, reviewed revision and final-03 baseline remain unchanged.

Stop condition: implement explicit summary observations in this separate copy,
check them through the frozen revised native host/verifier at small sizes,
check ordinary-run regression and allocation-denial behavior, and report the
actual result. Do not change the frozen checks to match this implementation.
No private cases, million-element workloads, commit, push, merge or deployment.

Summary observations must be read-only. The implementation counts
distinct input-reachable cells once during begin using the existing allocation
gates, then updates cell counters only after committed operations. Summary
serialization reads these counters and the requested logical-event suffix;
it performs no native reads or allocation-gate calls. The two approved large
workloads have no external roots. This is not a general observer for hidden,
disconnected host-held storage.

## Results

Rust 1.98.1 locked build, 54 candidate development tests, three frozen collector
tests, candidate Clippy with warnings denied, and formatting checks pass. The
one new candidate development test checks repeated full/summary observations,
invocation-event filtering and unchanged state/allocation gates. No acceptance
test, expected value or threshold was changed during this adaptation.

The frozen revised `check_revision.py` passed 891 small native destruction-cut
runs (depths 0–8) and rejected its deliberate missing-deepest-observation run.
It also passed 873 comparisons against the unchanged reference, opaque identity
replay, and the ten existing corrupted-stream/summary probes. The additional
compiled protocol-stub run is explicitly not evaluator evidence.

`validate_public.py` invokes only the frozen revised large verifier and original
per-run small verifier; it introduces no acceptance predicate. Its retained
report has `passed: true`:

| Public validation | Passing extent |
| --- | ---: |
| Real evaluator summary runs | 4, including 9 periodic summaries |
| Full public examples | 21 |
| Resume at every public boundary | 1,624 |
| Destruction at every public boundary | 1,624 |
| Every observed public begin-allocation denial | 42 |
| Historical public corpus, full runs | 4,276 |

Real summary runs used discard depth 10,003 and recursive-sum depth 2,003, each
with both a deepest-destruction and completed schedule. Every schedule includes
the deepest full observation, exact-grid/off-grid pauses and zero-budget joins.
They checked 100,123 committed actions in total. These are real native evaluator
runs, not the earlier protocol stub, but are not million-element resource tests.
The public campaign took 650.812 seconds; the separate small suite took 23.719
seconds. These durations include verifier/evidence overhead, not a benchmark.

All 967 originally frozen files, five historical dependencies and all 41 files
of the replacement freeze verified unchanged before/after the public campaign.
The preservation field `candidate_byte_identical` refers to the retained
final-03 baseline, not this explicitly modified adaptation.

## Evidence and reproduction

Raw requests, per-run rows, stderr, ledger, summaries and logs are preserved at
`/home/user/rob1333-stage-b-adaptation-checks/` in this orb. `evidence/` retains
copies of the small/public result summaries and build/test logs. The runner
uses new destinations only and stops on the first rejection. No private input
or private-run evidence is included or consulted.

The campaign and final rebuilt native binary have identical SHA256:
`7b38989835db8ef6fd274477f625caf5c35e6438256d405f4b5242703427491a`.
Runner SHA256:
`4a6aa55bf812fb9a7a97cd8e1d108b73e7f0348f432ad2564dc0d0dffac2e281`.
Candidate manifest SHA256:
`cc1e09dac565f67341bffee062fa0abbd080f9c60ebeac2fed522f56ff14317e`.
The final build includes the new development test's source; that test-only
addition did not change the native executable bytes used throughout the runs.

From this directory, with a fresh external target/evidence directory:

```sh
export CARGO_TARGET_DIR=/tmp/rob1333-adaptation-target
cargo +1.98.1 build --locked --manifest-path link/Cargo.toml
cargo +1.98.1 build --locked --manifest-path ../stage-b-revision-02/stage-b-stub/Cargo.toml
cargo +1.98.1 test --locked --manifest-path candidate/Cargo.toml
cargo +1.98.1 test --locked --manifest-path ../stage-b-revision-02/driver/Cargo.toml
cargo +1.98.1 clippy --locked --manifest-path candidate/Cargo.toml --all-targets -- -D warnings
cargo +1.98.1 fmt --manifest-path candidate/Cargo.toml -- --check
python3 ../stage-b-revision-02/check_revision.py /tmp/rob1333-adaptation-small "$CARGO_TARGET_DIR/debug"
python3 validate_public.py /tmp/rob1333-adaptation-public "$CARGO_TARGET_DIR/debug/rob1333-stage-b-link"
```

## Limits and remaining gates

This is same-author implementation verification using already frozen checks,
not a new independent review or complete Stage B acceptance. The original
submission, original locks and previous failure/scoring evidence stay intact.
The full collector's strict Clippy remains subject to the three pre-existing
warnings documented in revision 02; candidate Clippy passing does not erase them.

No private cases or million-element workloads ran here. All active sabotage
controls have not been rerun against this adapted candidate. Original obligations
and further execution/delivery approvals remain separate. There is no arbitrary
program summary promise, general OOM/deep-stack claim, commit, push, merge or
deployment. Both the replacement freeze and this adaptation are local only.
