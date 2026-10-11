# ROB-1333 v9 — span correction verified; trace projection; decimal reference defect stop

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-v9-span-correction-verified-trace-projection-decimal-42c676770e1b
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

# V9 — incomplete acceptance preparation, new reference-defect STOP

7 October 2026. This preserves and extends v8, not an accepted package or scientific lock. [Detailed v5 rules](<https://linear.app/robert-guss/document/rob-1333-v5-approved-exact-prototype-integers-proposed-acceptance-5eece5c832ec>) remain proposed except expressly approved feature/numeric/call/diagnostic decisions. [V8 original prediction and failure](<https://linear.app/robert-guss/document/rob-1333-v8-two-stage-repair-verified-draft-prediction-defect-stop-78668472e823>), prior archives and historical checks remain unchanged.

## Authorized correction, independently verified

D144, one versioned operand-span correction and continuation, permits only changing the active draft expectation for `main = [] == 1`: integer-only equality requires Int operands, so offending `[]` is columns 8–10 rather than valid `1` at 14–15 (1-based half-open). `V8_ORIGINAL_OPERAND_ROW` preserves the mistaken row in `refusalcheck.py`; the v8 archive and failed evidence are retained. No other expectation was retuned.

Commands run from repository root, with new non-overwriting evidence directories:

* `python3 experiments/13-source-acceptance/comparisoncheck.py experiments/13-source-acceptance/evidence/comparison-01`: PASS 12 independently expected wrong-left/wrong-right list/Bool refusals and 11 asymmetric/boundary/wide valid integer comparisons.
* `refusalcheck.py .../evidence/refusals-03`: PASS all 24 refusal rows, including those previously unexecuted.
* Relevant unchanged regressions: `phasecheck.py .../refusal-phase-03` PASS 24; `selfcheck.py .../public-06` PASS 16 accepts/12 refusals/21 public cases/seven synthetic controls; `generated.py .../generated-04` PASS 500 public exploratory compositions/22,090 logical snapshots; `validate.py .../finite-06` PASS 4,276 cases/27,721 exact historical snapshots, every field. These precede the new optional acquisition instrumentation.

## New preparation evidence

`tracecheck.py .../trace-01`: PASS seven independently stated action schedules and all 21 public call cases, 1,603 action boundaries. Give-up-holder and free-cell are separate committed transitions.

`corpus_tracecheck.py .../corpus-trace-01`: PASS all 4,276 cases. 53,796 predicted action boundaries project to all 27,721 mandatory snapshots, preserving every old field and all 13 snapshot kinds. The acceptance predictor reads expression/fixture inputs only, never expected snapshots to construct its states. `per-case.jsonl.gz` retains exact source, predicted actions/events and projection for every case. Empty added frame metadata is explicitly asserted and removed only for historical comparison. This validates the proposed logical landmark map, not physical runtime states, actual suspension or a no-host-stack claim.

`acquisitioncheck.py .../acquisition-01`: PASS four hand-derived binding-acquisition schedules, 18 terminating public cases, 500 generated compositions and four corrupt-first-acquisition controls. Independent tuple evaluation derives input/let/match/parameter contents and binding identities in evaluation order, rather than learning candidate first-acquisition values. The worked examples distinguish shadowed bindings, match head/tail, parameters after both explicit arguments, and live caller values during recursive increment. Pending-temporary and nonterminating-prefix predictions are still missing.

## New blocker: inherited decimal conversion limit

`python3 experiments/13-source-acceptance/decimalcheck.py experiments/13-source-acceptance/evidence/decimal-01` exits 1. The 1,000-digit all-nines numeral plus one passes. The 5,000-digit equivalent throws an unhandled `ValueError` at `syntax.py` numeral conversion: Python has an inherited 4,300-digit integer-string limit. It fails while parsing, before name/type checking or evaluation.

Independent expected input: `main = ` followed by 5,000 nines, then ` + 1`. Expected Int decimal answer: one followed by 5,000 zeros, by carrying one across each nine. Source, exact expected decimal string and failed traceback are retained in `evidence/decimal-01/counterexample.json` and `summary.json`. No expectation is derived from predictor output.

D140, exact growing prototype integers, does not approve an arbitrary host conversion guard as a language digit limit. V5 proposes unrestricted decimal digits and distinguishes actual resource exhaustion; this exception is not measured exhaustion. No unlimited-resource claim follows from testing a small 5 KB input. Under D141, deliverable-based preparation with early defect stops, substantive preparation stopped immediately. No repair or subsequent validation was performed.

**Recommendation for owner:** repair acceptance-local exact decimal conversion in both directions without the inherited digit guard, preserve this failure/prediction, check carry, borrow, negative literals and output conversion at both sides of 4,300 digits, then resume preparation under the unchanged stop. Do not change the grammar or add a silent numeric cap to fit the reference.

## Review export and exact baseline

[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and) attachment: [v9 source and raw evidence archive](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/9be521fb-bce2-45b4-ab3c-ee1a33e48724/cb003cbd-0628-4529-8847-dd5d8a03107c>). Filename `rob-1333-preparation-v9-checkpoint.tar.gz`, 333,085 bytes, SHA256 `c7ea52f97360901e6a84de3676124f6918597a1510337325010044a380edfe98`. This is a review-export fingerprint, NOT a scientific lock. Archive contains all current preparation source/evidence and preserved failed attempts; old v6/v7/v8 archives remain attached separately.

Code remains local, uncommitted/unpushed on `acceptance/rob-1333-preparation`; no parent state is needed. Baseline [origin/main commit](<https://github.com/robertguss/mo-v2/commit/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3>). Frozen [corpus source](<https://github.com/robertguss/mo-v2/blob/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3/experiments/10-finite-rust/evidence/expected.jsonl.gz>) SHA256 remains `d8d33f795b94e8173b6685462e83a277bfeefad5cc2bfee6bee38a8f63554a8b`. Historical models, trials, predictions and locks were not edited.

## Package is NOT complete or ready to lock

Remaining preparation: canonical checked-tree and static identity-resolution tables; truly private heldouts/generated acceptance layer (current 500 are public exploration); independent pending/nonterminating acquisitions; executable candidate adapter, physical cell/event and fixture-isolation verification; full control/operand-slot dumps; every resume/destroy boundary; failure-injection/cleanup checks. Actual candidate/resource-envelope validation necessarily awaits approved rules and authorized implementation/execution; no such runs occurred. Synthetic predicate controls are not compiled runtime mutants.

Outstanding owner decisions stay proposed: detailed grammar/names/types/ownership/action/output/failure/cleanup contract; exact resource thresholds/envelope and implementation effort convention/caps; exact package approval before lock and builder work. D138, current acceptance orb with larger only if needed, selects the target but not thresholds; actual resources must be rechecked before eventual authorized execution. D141 does not adopt an eight-hour preparation cap or mandatory two-hour interruptions.

No Mo implementation, accepted scientific lock, Fable invocation, participant trial, million-depth/resource-envelope run, push, merge, deployment or archive. Acceptance authorship remains separate from the future builder. The parent retains the all-issues audit and register/description edits.
