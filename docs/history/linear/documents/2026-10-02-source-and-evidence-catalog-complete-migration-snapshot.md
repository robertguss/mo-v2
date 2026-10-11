# Source and evidence catalog — complete migration snapshot

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/source-and-evidence-catalog-complete-migration-snapshot-da667181f973
> Created: 2026-10-02
> Updated: 2026-10-09
> Author: Robert Guss
> Attached to: the Mo v2 project

---

## Current evidence navigation — 9 October 2026

The 328-file inventory below is intentionally the complete **migration snapshot**, not the current repository inventory. Its then-incomplete trial status is historical. Current status and work gates live in [Start here](<https://linear.app/robert-guss/document/start-here-current-state-and-working-rules-29033acb30ab>) and the project issues.

The accepted [Stage A+B interpreter closeout](<https://github.com/robertguss/mo-v2/blob/a4056b8341122622106fe60f834dbf8e2428295f/experiments/13-source-acceptance/STAGE_B_RESULT.md>) indexes the final candidate, public/private aggregate/control evidence, all amendments and resource results. [robertguss/mo-v2#9](https://linear.app/robert-guss/review/accept-stage-b-interpreter-with-reviewed-resource-evidence-a4880103487e) is merged; [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/mo-interpreter-finish-stage-b-acceptance-and-integration) is Done. The [accepted finite Lean trial result](<https://github.com/robertguss/mo-v2/blob/e6a895c8ce2887d9bee6986819a779f8f74b5541/experiments/03c-checker/trial/RESULT.md>) supersedes the historical unfinished-trial status below. These are separate results; neither completes full 3c. Snapshot counts and original pinned links remain unchanged.

## Original migration snapshot

Migration snapshot: [repository tree](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4>). Exactly **328 tracked files**, classified by the non-overlapping groups below. Each directory link is a commit-pinned tree retaining every child file, including code, manifests, data and reviews; counts include all descendants. Documents are indexed, not silently re-authored. This catalog plus Linear issues is the discovery surface; Git stores exact artifacts.

| Source file/subtree | Files | Linear destination / classification |
| -- | -- | -- |
| [.agents/resume](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/.agents/resume>) | 1 | Environment activation artifact |
| [.agents/setup](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/.agents/setup>) | 1 | Environment setup artifact |
| [.gitignore](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/.gitignore>) | 1 | Repository configuration |
| [CLAUDE.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/CLAUDE.md>) | 1 | Governing rules; live entry point changes in migration |
| [docs/DECISION-MAP.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/DECISION-MAP.md>) | 1 | Historical proposal map → Design parking lot |
| [docs/DECISIONS.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/DECISIONS.md>) | 1 | 101 decisions → historical decision documents |
| [docs/README.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/README.md>) | 1 | Historical status/handoff → Start here and issues ROB-1132, ROB-1136–ROB-1139 |
| [docs/research/README.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/README.md>) | 1 | Research navigation |
| [docs/research/big-picture](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture>) | 16 | Seven areas and foundations → Design parking lot |
| [docs/research/brain-export.json](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/brain-export.json>) | 1 | Original TheBrain export; historical data |
| [docs/research/documents](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents>) | 91 | All choice alternatives, neighbouring languages, design doc, glossary and primer → Design parking lot |
| [docs/research/parking-lot](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/parking-lot>) | 3 | Implementation/evaluation proposals → Design parking lot |
| [docs/research/session-orientation.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/session-orientation.md>) | 1 | Historical orientation; not current instructions |
| [docs/research/tools](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/tools>) | 2 | Tool research → Design parking lot |
| [experiments/01-tiny-safe](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/01-tiny-safe>) | 9 | Completed experiment evidence |
| [experiments/02-withdraw](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/02-withdraw>) | 42 | Completed experiment evidence; follow-ups ROB-1145 |
| [experiments/03-in-place](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03-in-place>) | 65 | Completed experiment evidence |
| [experiments/03b-helper](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper>) | 50 | Completed experiment evidence; proposals ROB-1141 and ROB-1144 |
| [experiments/03c-checker](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker>) | 40 | Full 3c proposal and trial artifacts; ROB-1132, ROB-1136–ROB-1139, ROB-1146 |

## Evidence inventory and current classification

Historical reports below are imported evidence, not rerun claims. Each experiment tree above contains its full source, toolchain/manifest, checks and raw evidence. Keep original/corrected/independent runs distinct.

* **Experiment 1 complete:** [RESULT](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/01-tiny-safe/RESULT.md>). Tiny checker safety proved; safety alone does not rule out rejecting everything.
* **Experiment 2 complete:** [RESULT](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/02-withdraw/RESULT.md>). Seven methods against ten planted bugs; proof and Codex review caught all ten in that experiment, not a general ranking. Tree includes briefs, mutant key, code and council verdict.
* **Experiment 3 complete:** [RESULT](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03-in-place/RESULT.md>), [PLAN](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03-in-place/PLAN.md>), [ACCEPTANCE](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03-in-place/ACCEPTANCE.md>), [LOCK](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03-in-place/LOCK.md>). Tree includes benchmark code, runner, diagnostics, raw runs and council reviews. Reuse feasibility/performance findings are scoped; sharing observations are not a pass threshold; Koka warnings are not Mo refusal.
* **Experiment 3b complete:** [RESULT](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/RESULT.md>), [PLAN](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/PLAN.md>), [ACCEPTANCE](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/ACCEPTANCE.md>), [LOCK](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/LOCK.md>). Tree includes helper, benchmarks, measurement data and separate lead/Codex reviews. Reported 1.01–1.19× on four measured workloads is not general performance.
* **3c trial phase 1 run/preparation complete, phase 2 not complete:** [RUN-1](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/RUN-1.md>), [raw output](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/results/run-1.txt>), [LOCK](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/LOCK.md>). Reported 28 matching runs, 438 items, repeated identical output and rejected misreport control. This is not proof for every program. No trial RESULT.md yet.

## Trial document manifest

All under experiments/03c-checker/trial/, pinned above; authority and work destinations:

* [PLAN.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/PLAN.md>): Approved trial scope and stops → ROB-1136/ROB-1137.
* [RULE.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/RULE.md>): Approved semantics; frozen artifact.
* [EXAMPLES.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/EXAMPLES.md>): Approved programs/memories; frozen artifact.
* [INTERFACE.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/INTERFACE.md>): Approved observable interface; frozen artifact.
* [PREDICTIONS.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/PREDICTIONS.md>): Frozen expectations; never retune to implementation.
* [PREDICTIONS-BRIEF.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/PREDICTIONS-BRIEF.md>): Historical prediction-writer ownership.
* [CHECKS-BRIEF.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/CHECKS-BRIEF.md>): Historical independent acceptance-author ownership.
* [WORKER-BRIEF.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/WORKER-BRIEF.md>): Historical encoding scope and restrictions.
* [ACCEPTANCE.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/ACCEPTANCE.md>): Binding ten-check acceptance → ROB-1137.
* [PROOF-BRIEF.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/PROOF-BRIEF.md>): Binding proof scope and unresolved workflow → ROB-1132/ROB-1136.
* [LOCK.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/LOCK.md>): Fingerprints and prior lock history.
* [RUN-1.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/RUN-1.md>): Completed phase-1 run evidence.
* [lead-checks/README.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/lead-checks/README.md>): Historical lead smoke evidence, not replacement acceptance.
* [lead-checks/D98/README.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/lead-checks/D98/README.md>): Snapshot instrumentation checks.
* [lead-checks/step5/README.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/lead-checks/step5/README.md>): Promise-statement checks.

The [Lean tree](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/lean>) covers every locked language/check/statement, acceptance wrapper, proof stub, toolchain and manifest. [Lead checks tree](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/trial/lead-checks>) retains all auxiliary source. [Full 3c PLAN](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03c-checker/PLAN.md>) → ROB-1138/ROB-1139, not an approved full build.

## Reconciliation, not rewriting

* Research’s Experiment 3 “Planned” and conditional 3c gate are historical; results and D66 (3c no longer conditional on 3b success) control current reading.
* D68 (3b plan approval) kept copy-feedback out of 3b despite older “possibly inside” wording.
* Sequences’ older “first after 3b” wording does not displace D71 (3c chosen next) or current trial priority. No new ordering decided.
* Trial numbers, order and release behavior do not decide Mo-wide semantics.
* Historical Herdr panes and local v1 checkout are not present-day orb resources. No claim of access to uncommitted old pane state or untracked files; only tracked snapshot is catalogued.
* Pinned orb setup installed toolchains, not portable old benchmark runners. Older runners still assume macOS/Homebrew; no benchmark reproduction or proof acceptance occurred during migration.

## Reproduce inventory

Run git ls-tree -r --name-only 13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4. Every path belongs to exactly one table group; sum is 328. Links pin that same revision. Future evidence must use its own commit, not overwrite this catalog’s snapshot.
