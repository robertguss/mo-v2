# ROB-1333 v7 — earliest-error repair verified; new refusal-phase stop

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-v7-earliest-error-repair-verified-new-refusal-phase-stop-8ce62ffe648b
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

# [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) v7 — verified repair, incomplete preparation

**REVIEW CHECKPOINT / DETAILED OTHER RULES PROPOSED / NOT A LOCK OR BUILDER BRIEF.**

D142, earliest lexical/syntax source error and reference-repair continuation, approved repairing the acceptance reference and continuing under D141, deliverable-based preparation with an early stop on new specification/reference defects. The approved repair is verified; expanded refusal coverage exposed a new name-check/syntax-priority boundary mismatch and preparation is now stopped there. No repair followed that new stop.

[V6 checkpoint](<https://linear.app/robert-guss/document/rob-1333-v6-incomplete-acceptance-preparation-reference-defect-stop-f39348fa7b7e>), its source archive/counterexample and all earlier drafts remain unchanged. [V5 detailed proposals](<https://linear.app/robert-guss/document/rob-1333-v5-approved-exact-prototype-integers-proposed-acceptance-5eece5c832ec>) remain the grammar/name/type/ownership/transition/output/failure proposal; only expressly approved decisions bind. No mandatory two-hour interruptions or eight-hour preparation cap has been adopted.

## Approved repair and evidence

The acceptance lexer now yields tokens only as parsing requests them, preserving the consumed token prefix and original spans. It cannot scan past an already-detected syntax error to raise a later lexical error first. The EOF sentinel is distinguished by its zero-width range from a real identifier spelled EOF. This affects reference preparation only, not Mo implementation.

Exact independently stated mixed-error outcomes include:

| Source | Expected and actual refusal, 1-based half-open |
| -- | -- |
| main = (1 2) @ | syntax, (1,11)–(1,12): second numeral, not later @ |
| main = (1 2) 01 | syntax, (1,11)–(1,12): second numeral, not later bad numeral |
| main = (01 2) @ | numeral, (1,9)–(1,11): earlier bad numeral |
| main = (@ 2) @ | lexical, (1,9)–(1,10): earlier invalid character |
| main = (1 @ 2) @ | lexical, (1,11)–(1,12): invalid character before later syntax |
| main = (1 2) # @ 01 | syntax, (1,11)–(1,12): comment contents ignored |
| main = (1 followed by CRLF, tab, 2) @ | syntax, (2,2)–(2,3): CRLF is one newline, tab one column |
| main = | syntax, (1,7)–(1,7): EOF insertion point |
| main = 1 EOF | syntax, (1,10)–(1,13): trailing identifier is not EOF sentinel |

These ranges were stated in [prioritycheck.py](<http://prioritycheck.py>) before execution and not taken from parser output. It also accepts a comment containing @/01 followed by valid arithmetic on the next line, and a local named EOF. Full exact sources and expected/actual results are saved in evidence/refusal-priority-02/summary.json.

Executed commands from repository root:

* python3 experiments/13-source-acceptance/prioritycheck.py experiments/13-source-acceptance/evidence/refusal-priority-02 — PASS: 14 refusals, two valid boundary examples. Original v6 witness now returns syntax at columns 11–12.
* python3 experiments/13-source-acceptance/selfcheck.py experiments/13-source-acceptance/evidence/public-04 — PASS: unchanged 16 source accepts, 12 exact refusals, 21 public call cases and seven synthetic checker-defect controls.
* python3 experiments/13-source-acceptance/generated.py experiments/13-source-acceptance/evidence/generated-02 — PASS: unchanged 500 exploratory finite call compositions / 22,090 logical snapshots. Public exploratory material, not held out.
* python3 experiments/13-source-acceptance/validate.py experiments/13-source-acceptance/evidence/finite-04 — PASS: unchanged 4,276 historical cases / 27,721 snapshots, every expected field/ordered primitive record/answer/final memory. All thirteen kinds retained; logical landmark correspondence, not the complete fine-grained transition or physical-runtime gate.

No predictions were changed. Byte comparison against the v6 archive confirmed [cases.py](<http://cases.py>), [selfcheck.py](<http://selfcheck.py>) and evidence/refusal-priority-01/counterexample.json unchanged. V6 archive SHA-256 remains 0a4c54bd59423975024e774ca872727fec379cf92be629e0da7a23fe1426863f. Historical corpus remains d8d33f795b94e8173b6685462e83a277bfeefad5cc2bfee6bee38a8f63554a8b, matching its old lock. Earlier failures are retained.

## New counterexample: checking names during parsing masks a malformed source

Preparation added [refusalcheck.py](<http://refusalcheck.py>) with 24 draft annotated source examples covering stage refusals, inputs, match binders, list kinds, lexical scope, functions/parameters/calls/results and unsupported types/operators. Expected ranges come from annotations of the explanatory source construct, not reference output. Execution stopped on the first case; later rows are unexecuted/unvalidated, not a completed refusal set.

Source: main = match \[\] do \[\] -> 0; \[x | x\] -> @ end

| Proposed phase rule | Prediction | Reference actually reports |
| -- | -- | -- |
| V5: first lexical/syntax error; otherwise declaration/body name/type errors | lexical @, (1,40)–(1,41) | match-binders on second x, (1,34)–(1,35) |

The reference checks match binder distinctness while parsing, before scanning the later body. D142, earliest lexical/syntax priority, does not expressly settle whether binder distinctness is itself a grammar check or belongs to name checking after complete syntax validation. The draft currently describes it as a name/well-formedness rule while proposing syntax validation before name/type errors. This is a proposed-rule/reference mismatch, not evidence that the approved lexical-versus-syntax rule is broken.

Executed command: python3 experiments/13-source-acceptance/refusalcheck.py experiments/13-source-acceptance/evidence/refusals-01 — FAIL on first case, zero passed rows; exact source, expected/actual ranges and traceback retained in summary.json. No filtering or retuning.

**One owner question:** should lexical/syntax validation finish before reporting duplicate match binders, as v5's proposed phase ordering implies? Recommend yes: treat binder distinctness as a name check, so malformed source is repaired before name/type checking. Alternative: explicitly classify binder distinctness as a grammar restriction and keep its earlier refusal; that changes the detailed proposed priority interpretation and needs owner choice. Both retain the approved same-name prohibition and language feature scope. Neither is assumed here.

## Exact saved delivery and limitations

[New source/evidence archive attached to ROB-1333](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/43ddc5ce-2d82-4b58-b61c-69031d7d530c/15152442-dfc6-4970-ba79-22b8094142b1>), title V7 acceptance reference repair and new refusal-phase counterexample. Size 63,887 bytes; SHA-256 1069d24ac3a25cfbece1ad2f8e051d92a0b96d5654d6e8e574134c7c1351b3de. It contains the exact acceptance directory and saved evidence, excluding caches. Fingerprint identifies an incomplete review export, not a scientific lock. If the direct URL requires sign-in, use the attachment on the issue.

Still missing: complete reviewed refusal/resolution/canonical-tree tables; exact fine-grained transition predictions and per-case projection export; private heldouts/generated acceptance corpus; independent pending-value acquisition expectations; executable candidate/physical-cell/fixture-isolation adapter; all resume/destroy/failure-injection checks; actual resource validation. Runtime controls need a future implementation; executed synthetic controls only exercise predicates. Python references use logical cells/host recursion, not resumable Mo execution. A passing logical corpus run is not physical acceptance, continuous-protection proof, no-host-stack proof or production/performance evidence.

Sources remain local, uncommitted and unpushed on acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-preparation in robertguss/mo-v2, based on origin/main 03705f1dac1de8cbc9efedaf99ad4feeb62c17a3. No parent code/file transfer was needed. No issue description or live register edit, old lock change, interpreter implementation, scientific lock, Fable execution, participant trial, resource-envelope run, merge, deployment or archive action occurred.

D139, approved limited features including Boolean literals; D140, exact growing prototype integers; D138, this orb/larger only if needed; and D127–D130, call-local reservations/resumable observations/continuous protection/entry-based allocation counting, remain unchanged. Detailed other rules, stage effort units/caps and resource thresholds still require review. D141, deliverable-based preparation, is ongoing but stopped at this new defect until direction; the final package is not delivered or approved. Fable remains plan-review-only.

Pinned provenance and unchanged historical sources are indexed in v6: finite corpus/SPEC/lock at a22831f823d2ac7ccbb8726a8d4418fbceb233e0, trial English RULE/INTERFACE at e6a895c8ce2887d9bee6986819a779f8f74b5541; [live register](<https://linear.app/robert-guss/document/decisions-and-approvals-live-register-360d6e9c3d64>). This checkpoint requests no broader scope or builder authorization.
