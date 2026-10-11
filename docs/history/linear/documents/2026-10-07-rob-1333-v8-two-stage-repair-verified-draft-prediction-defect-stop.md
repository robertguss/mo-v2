# ROB-1333 v8 — two-stage repair verified; draft-prediction defect stop

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-v8-two-stage-repair-verified-draft-prediction-defect-stop-78668472e823
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

# [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) v8 — verified diagnostic repair, incomplete acceptance preparation

**PROPOSED OTHER DETAILS / NOT A SCIENTIFIC LOCK / NOT A BUILDER BRIEF.**

D143, syntax-before-name/type diagnostic order and repair continuation, approves finishing whole-file lexical/syntax validation before duplicate-name/type checks. D142, earliest lexical/syntax source error, still selects the first lexical/syntax error by source position. The reference repair and relevant regressions pass. Continuing preparation exposed an error in this acceptance author's draft refusal prediction; preparation stopped before correcting it under D141, deliverable-based preparation with early defect stops.

[V7 source/evidence/draft](<https://linear.app/robert-guss/document/rob-1333-v7-earliest-error-repair-verified-new-refusal-phase-stop-8ce62ffe648b>), its original predictions and all older versions remain unchanged. [V5 details](<https://linear.app/robert-guss/document/rob-1333-v5-approved-exact-prototype-integers-proposed-acceptance-5eece5c832ec>) remain proposed except expressly approved boundaries. No new language feature, numeric policy, resource threshold or effort cap is adopted.

## Repair that actually passed

Parser records duplicate match binders and identifier-shaped type annotations, retaining their source spans, and completes source validation. Only the later checker tests binder distinctness and supported types. Unknown annotations and prohibited Boolean inputs still refuse on otherwise syntax-valid source; deferring them does not add those features. Function-table lookup is prepared without emitting a later duplicate-declaration error ahead of earlier body checking. Name/callee spans are separately retained; unknown callees use their identifier range rather than the whole call, matching the proposed span contract.

The approved witness now gives lexical @ at (1,40)–(1,41): main = match \[\] do \[\] -> 0; \[x | x\] -> @ end. Replacing @ with 1 makes source syntax-valid and still refuses match-binders at second x, (1,34)–(1,35). Both boundaries are independently stated before execution. Duplicate inputs/parameters/functions and invalid type annotations/argument/body kinds are each paired with later malformed syntax; source syntax wins. Their syntax-valid counterparts still refuse the name/type error. The original earlier-error witness main = (1 2) @ still reports syntax on 2 at (1,11)–(1,12).

Executed from repository root:

* python3 experiments/13-source-acceptance/phasecheck.py experiments/13-source-acceptance/evidence/refusal-phase-02 — PASS: 24 independently annotated exact outcomes across duplicate binders/input/parameters/functions, invalid annotations, wrong result/argument kinds and unbound names, paired with lexical/syntax errors and syntax-valid variants.
* python3 experiments/13-source-acceptance/prioritycheck.py experiments/13-source-acceptance/evidence/refusal-priority-03 — PASS: unchanged 14 mixed lexical/syntax refusals and two valid boundary examples.
* python3 experiments/13-source-acceptance/selfcheck.py experiments/13-source-acceptance/evidence/public-05 — PASS: unchanged 16 source accepts / 12 exact refusals / 21 public call cases / seven synthetic predicate-defect controls.
* python3 experiments/13-source-acceptance/generated.py experiments/13-source-acceptance/evidence/generated-03 — PASS: unchanged 500 exploratory finite call compositions / 22,090 logical snapshots. Public exploratory data, not held out.
* python3 experiments/13-source-acceptance/validate.py experiments/13-source-acceptance/evidence/finite-05 — PASS: unchanged 4,276 historical cases / 27,721 snapshots and every expected field/ordered primitive record/answer/final memory. All thirteen snapshot kinds retained. Logical landmark validation, not full fine-grained or physical runtime acceptance.

Exact source/expected/actual rows are in refusal-phase-02/summary.json and refusal-priority-03/summary.json. Public-05/observed.json contains the public call evidence. No expected output was changed to obtain these passes.

## New defect is in my prediction, not the reference

Continuing python3 experiments/13-source-acceptance/refusalcheck.py experiments/13-source-acceptance/evidence/refusals-02 passed ten proposed rows, then failed on the next original v7 row. Later rows were not executed.

| Source | Preserved draft prediction | Reference result | Independent English-rule derivation |
| -- | -- | -- | -- |
| main = \[\] == 1 | operand-kind on 1, (1,14)–(1,15) | operand-kind on \[\], (1,8)–(1,10) | Equality takes two integers; \[\] is a list and 1 is a valid integer. The offending operand is \[\]. |

The annotation in [refusalcheck.py](<http://refusalcheck.py>) incorrectly selects the right operand. The reference agrees with the proposed integer-only comparison rule. This is an acceptance-authoring defect; it does not justify altering the implementation, English rule or predictions merely to make a test green. The error was found through a failed reference validation and independently classified from the kinds of the two source literals, not by taking expected values from the code.

**One requested action:** approve a versioned correction of this erroneous draft expectation to \[\] at columns 8–10, preserving the old row/archive and failed evidence, and continuation under the same preparation stop. Recommend that correction; no new semantic choice is needed. No correction or additional validation followed this defect stop. We do not claim the 24-row broader refusal set passes or is complete.

Failed source, original expected range, actual range and traceback are retained in evidence/refusals-02/summary.json. V7 [refusalcheck.py](<http://refusalcheck.py>) is byte-identical, so the mistaken annotation is still visible. Historical expectations/locks were never changed.

## Exact checkpoint and remaining work

[Source/evidence archive attached to ROB-1333](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/a5a605da-b973-4389-baae-3e74d30660fb/2fd795f1-d1d2-47d0-b6b7-eec2e42477c9>), title V8 two-stage diagnostic repair and preserved draft-prediction defect. Size 85,334 bytes; SHA-256 d6bc7f560b3f1133ffbe225b0d4f0bc7efd165ae398ed8b21d42f19537fd06c4. Contains exact acceptance sources/evidence excluding caches. This is an incomplete review export, not a lock. If the direct URL requires authentication, use the issue attachment.

V7 archive remains SHA-256 1069d24ac3a25cfbece1ad2f8e051d92a0b96d5654d6e8e574134c7c1351b3de. Byte comparison confirmed original [refusalcheck.py](<http://refusalcheck.py>), [prioritycheck.py](<http://prioritycheck.py>), [cases.py](<http://cases.py>), [selfcheck.py](<http://selfcheck.py>) and evidence/refusals-01/summary.json unchanged against that archive. V6 archive remains preserved. Historical corpus SHA-256 d8d33f795b94e8173b6685462e83a277bfeefad5cc2bfee6bee38a8f63554a8b still matches its old lock.

Complete package remains undelivered. Outstanding: full reviewed refusal/resolution/canonical-tree tables; exact fine-grained transitions and per-case projection evidence; private heldouts/generated acceptance layer; independent pending-value acquisition predictions; candidate/physical-cell/fixture-isolation adapter; all resume/destroy/allocator-failure checks; resource protocol validation under separately authorized execution. Synthetic controls are predicate tests, not compiled runtime mutants. Logical Python references use host recursion, not explicit-state Mo execution; their passes prove neither physical reuse nor no-host-stack behavior nor continuous protection at every proposed committed transition.

Local robertguss/mo-v2 branch acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-preparation remains uncommitted/unpushed, based on origin/main 03705f1dac1de8cbc9efedaf99ad4feeb62c17a3. Parent supplies no local changes/files. No issue description/live register edit, historical artifact/lock modification, accepted scientific lock, interpreter implementation, Fable invocation, participant trial, resource-envelope run, merge, deployment or thread archive. Fable remains plan-review-only. D141, deliverable-based preparation, has no mandatory two-hour approval interruptions or adopted eight-hour preparation cap.

Approved scope remains D139, limited first-language features including true/false; D140, exact growing prototype integers with permanent policy open; D138, this orb/larger only if needed; D127–D130, call-local reservations/resumable observations/continuous live protection/entry-after-arguments creation counting. Detailed other rules and stage effort/resource thresholds remain proposed. Final requirements/checks/package approval still precedes a scientific lock and builder brief. Stage A cannot silently stand in for Stage B.

Pinned source/evidence links are retained in v6/v7: finite SPEC/corpus/lock at a22831f823d2ac7ccbb8726a8d4418fbceb233e0; trial English RULE/INTERFACE at e6a895c8ce2887d9bee6986819a779f8f74b5541; [live register through D143](<https://linear.app/robert-guss/document/decisions-and-approvals-live-register-360d6e9c3d64>). This checkpoint changes no decision and requests no implementation or broader scope.
