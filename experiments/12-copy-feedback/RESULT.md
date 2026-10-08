# Copy-feedback pilot package — prepared for review

This package prepares six Rust tasks and five feedback conditions for 30 fresh
GPT-6.1 Sol sessions at medium reasoning, using Robert's Codex subscription.
**No participant model sessions have run.** This report concerns task/check
validity and delivery preparation, not whether feedback improves agent behavior.

## What Robert would be approving

The tasks, expected outcomes, feedback messages and proposed protocol are concrete.
The proposed session limit is five minutes each, with timeout/failure retained,
no replacement runs and no paid fallback. A future launcher must verify clean
session/context isolation and process-group cleanup before participant trials.
Approval to prepare this package did not authorize those trials or a merge.

| Task | Required behavior | Baseline operation allocation | Known legal repair |
|---|---|---:|---:|
| U1, 100,000 elements | Add one; no old version required | 100,000 cells / 3,200,000 requested bytes | 0 allocations |
| U2, 100,000 elements | Reverse; no old version required | 100,000 cells / 3,200,000 requested bytes | 0 allocations |
| R1, 100,000 elements | Add one and retain every original value | 100,000 cells / 3,200,000 requested bytes | Baseline already meets requirements |
| R2, 100,000 elements | Running totals and retain every original value | 100,000 cells / 3,200,000 requested bytes | Baseline already meets requirements |
| H1, 4 elements | Add one and retain the original | 4 cells / 128 requested bytes | Leave appropriate code alone |
| H2, 8 elements | Reverse and retain the original | 8 cells / 256 requested bytes | Leave appropriate code alone |

The unique-task repairs drop the unnecessary holder before updating. Retained
versions are real obligations: removing them is a wrong repair. The harmless
cases are deliberately small variants of the retained-version operations, not
six independent application workloads. The study's conclusions must reflect that.

Participant prompts expose requirements and scale, not the categories or reference
repairs. `tasks/` holds the six baseline sources and readable prompts.
[PROTOCOL.md](PROTOCOL.md) describes the experimental conditions and scoring.
[feedback.json](feedback.json) contains the exact possible-copy notes and measured
baseline profiles. The same message is used automatically and on request within
each information type. Static notes are manually authored prototypes; measured
profiles are from the unchanged baseline, not from a participant's later edits.

## Acceptance evidence

A separate acceptance author wrote and fingerprinted the exact Python reference
and external Rust harness before task implementations were written. That freeze
is commit `44f05de`; `acceptance/LOCK.json` contains the immutable fingerprints.
The accepted 3b helper is unchanged. This is a new proposed acceptance package,
not retroactive amendment of any prior experimental lock.

All six baselines passed 20 full-value cases each. The two reference repairs also
passed all 20 cases each and achieved zero operation allocations. Checks include
empty and singleton lists, negative/repeated values, non-profile lengths, signed
remainder boundaries and each full profile. Retained outputs compare every value,
not just a sum or the first element. These are finite tests, not a universal proof.

The acceptance author independently re-evaluated saved outputs and source hashes;
that is distinct from independently rerunning every baseline process. The same
author independently executed the four negative controls. See
[evidence/independent-review-01/REVIEW.md](evidence/independent-review-01/REVIEW.md)
for the precise checked/not-checked boundary.

| Deliberately wrong repair | Required and observed rejection |
|---|---|
| Discard required old version | Full-output/original contract fails |
| Mutate shared storage | Original values change; full-value check fails |
| Weaken the checker | Fingerprint mismatch, before compilation |
| Copy before a participant-chosen inner interval | External whole-operation allocation budget fails |

Three semantic/cost controls compiled successfully; the fourth is intentionally
an integrity rejection before compilation. A build failure was not counted as a
successful semantic catch. The shared-mutation control uses the previous 3b
mutant's different representation, so only its semantics are judged; its cell
allocation calibration is explicitly excluded. All control source and results
are retained in `evidence/controls-01/`.

## Measurement scope

Each unchanged helper cell requested 32 bytes on this pinned toolchain, calibrated
using one/two-cell construction and verified cleanup. Whole-operation accounting
starts before task code is invoked and includes every transient allocation. A
candidate has no editable setup hook or trusted inner stopwatch. Input construction
precedes measurement; full-value checking and formatting follow it. Final requested
live memory returns to baseline after dropping outputs and accounting for checker
vectors. Requested live/peak bytes include driver buffers and are not process RSS.

A second baseline run retained 20 instrumented cases and ten uninstrumented timing
samples per task, all with full answers checked. It followed completion of all
control builds. The six tasks were timed sequentially here; these are preparation
profiles, not a randomized comparison of model outcomes. Every timing sample was
retained, including warm-up/noise. Very short H1/H2 timings are particularly noisy
and have no acceptance threshold. No speed ratio or general performance claim is
made. `evidence/baseline-summary.json` records medians/spreads and allocation data;
full measured profiles are also in the frozen feedback text.

The allocation harness counts alloc, alloc_zeroed and realloc requests separately
from its live totals. Calibration uses the helper's actual layouts. These particular
baseline updates allocate one block per copied cell; arbitrary future candidate
allocations must not automatically be labeled copies.

## Delivery and execution boundary

`delivery.py` creates one workspace containing only its task, helper, public value
examples and request wrapper. Feedback is kept in the controller, served through
a loopback endpoint; explicit requests are logged. Automatic arms receive the
same payload in the initial prompt. It launches no model. Synthetic delivery and
cleanup tests passed all 30 setups, 60 explicit requests, six public checks, and
two forced cleanup paths. They are retained under `evidence/delivery-01/`.

The six public example checks are convenience feedback available in every arm;
they are not the independent hidden acceptance suite and reveal no allocation
score. A participant could still infer costs from source or measure locally;
the future study must record that limitation rather than promise perfect blinding.

This is a cooperative research workflow, not hostile-code containment. The source
restrictions and task-only edit rule require review plus integrity verification.
No evidence here establishes isolation of an actual Codex model session, subscription
capacity for the full run, model-version stability, timeout handling for actual
model processes, or usefulness of the feedback. Those remain pre-run checks or
questions for the approved pilot.

## Reproduce preparation

From the repository root, choose new evidence destinations (existing evidence is
never overwritten):

```sh
python3 experiments/12-copy-feedback/acceptance/check.py U1 experiments/12-copy-feedback/tasks/U1/task.rs /tmp/new-u1-evidence --baseline --timing-runs 10
python3 experiments/12-copy-feedback/acceptance/check.py U1 experiments/12-copy-feedback/controls/U1-repair.rs /tmp/new-u1-repair
python3 experiments/12-copy-feedback/acceptance/controls_check.py /tmp/new-copy-controls
python3 experiments/12-copy-feedback/acceptance/delivery_check.py /tmp/new-copy-delivery
```

Repeat the first command for each task. Do not use `--baseline` to score participant
repairs: it deliberately permits the known baseline's avoidable allocations.
Task implementations, controls, protocol and delivery are authored by the parent;
independent acceptance, control runner and delivery tests by the acceptance agent.
The exact compiler, CLI and model settings are in `toolchain.json`. No global
Codex settings, prior experiment files or unrelated CLAUDE.md edits are included.


Large raw sample JSON files are stored losslessly as `.json.gz`; read them with
Python `gzip.open(path, 'rt')`. `evidence/ARCHIVE.json` retains each original JSON
SHA-256 and byte count. Smaller JSON, build logs, sources and control failures are
uncompressed. Executable build products and Python caches are excluded; rebuilding
uses the pinned source and toolchain. `evidence/MANIFEST.json` fingerprints retained
artifacts; `PACKAGE_LOCK.json` freezes the proposed run inputs for review.

Preparation bookkeeping: an initial scratch-only reference self-check contained a
manually mistyped signed-remainder expectation. The acceptance author corrected
the scratch assertion; no frozen reference or expected result changed. One Python
cache was inadvertently included in the first freeze commit and removed in the
package commit. No baseline, reference repair or control expectation was retuned.
