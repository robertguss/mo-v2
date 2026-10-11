# ROB-1139 stage-2 scientific verification preflight

## Result and separation

**PASS finite preflight, not stage-2 completion.** Separate verifier execution
in the same checkout/account; no new thread, independent-account certification,
commit, push, issue update, branch switch, or frozen/source edit. Parent-owned
universal-proof drafts were excluded from the scratch build and are not judged.
No concrete defect of the original checker or frozen specification was found
by this inspection and finite campaign. An unfinished Conditional proof is not
a specification counterexample. No universal theorem is certified here.

Consumed `stage-2/BRIEF.md`, `ACCEPTANCE.md`, and frozen
`acceptance/{CHECKPOINT,DERIVATIONS,CHECKS}.md`, actual `lean/Full/Demand.lean`,
`stage-2/Run.lean`, `lean/Full/Statements.lean`, and `lean/Export.lean`.
Checkout HEAD: `66f8aac22fbaa31100700a5ca9e5b486efd67c28`, branch
`proofs/rob-1139-stage2`. Authority/context links:
[stage-2 source thread](https://ampcode.com/threads/T-01a121f6-7962-75c6-bb35-922b9a6cc491),
[execution thread](https://ampcode.com/threads/T-01a126e2-69f9-751a-8aff-1a2e19a7e821),
[stage-1 base](https://github.com/robertguss/mo-v2/commit/66f8aac22fbaa31100700a5ca9e5b486efd67c28).
No new external URL/service was needed; all evidence paths below are relative
to this directory.

## Independent acceptance consumption

`verify.py` consumes frozen `check.all_cases()` without interpreting its ASTs
to invent expected results. It validates all reused stage-1 inputs against the
frozen ASTs, transitive declaration closure/order, demanded names, start cells,
inputs and outside multiset (A=0, B=1, etc.). Expected answers and complete
finished C/W/F ledgers come exclusively from frozen predictions. Verdict
requirements come from their A/R/O category meanings. The consumer checks
exact demanded-name sets to avoid vacuous acceptance. It independently counts
all Creates between each Enter and its Return in the observed primitive stream,
including descendants and later-freed cells, and compares that count with Run's
reported interval count. It does not fit expectations to observed verdicts.

Pinned Lean **4.34.0**, commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, was used throughout.
Original checker SHA256:
`bcd1d905ae3bac691d43b17c3dd9ce26d6a61131aacc79f71ecb38125da7a2ba`.
Run SHA256:
`8ced01f085417ac5acfc4edc3c94d680487716fffe3c5b0b18247e00fc10869e`.
Input SHA256:
`9a604ff2a932c32c5715c99bf7e69a53dd82f44117c2a4d8c4e6a06505a14ec1`.
Additional consumed hashes: `evidence/consumed.sha256`.

* All **90 rows** ran via the delivered Run against unchanged
  `stage-1/completion/evidence/inputs.json`; **253 Enter records** inspected.
* All **84 frozen finished answers and primitive cell ledgers** matched.
* Slice 1: **12 accept families / 38 expanded rows**, **6 refuse families /
  14 expanded rows**, **1 observe family / 1 row**. All requirements passed.
  Coverage includes every empty/singleton/additional variant expanded by
  frozen `acceptance/check.py`; per-family counts are in `evidence/summary.json`.
* S1O01 ordinary arithmetic is refused, with interval Create=0: a documented
  usefulness limitation, **not** an allocating refusal witness.
* All **27 categories** remain inventoried. The slice-2 **3/3/2** categories
  are recorded but NOT marked passed as caller-ownership checking.

The baseline six principal allocating refusals have unique entry and Create
counts: duplicate=3, prepend=1, insertNew=1, build=3, twice=2,
allocHelper=1. The original refuses all; complete reasons/entries/events are
in `evidence/original.json`.

## Actual-source scientific controls

Disposable `/tmp/rob1139-preflight-*` reconstruction copied source but no `.lake`
cache; it retained the pinned toolchain and local trial dependency. It compiled
only the checker/statement/model dependencies and Export, not universal proofs.
Its passing unmodified output was exactly equal to the checkout original for
all 90 rows (`evidence/scratch-original.{log,json}`). Temporary reconstruction
was removed automatically. Every mutant changed the actual copied checker
source, rebuilt Full.Demand and reran the unchanged Run/model/input, rather
than altering JSON or substituting a fake interpreter.

| Control | Intended detected failures |
| --- | --- |
| accept-all (`accepts := true`) | 14 must-refuse row failures and 19 accepted, unique-entry allocating interval witnesses; 33 total assertions |
| reject-all (`accepts := false`) | All 38 must-accept expanded rows fail usefulness, including increment/sum and all ten other families |
| missing-affine (disable affine condition only) | U-twice and additional-7 violate S1R05 refusal; U-twice's accepted `twice` invocation 1 has unique entry and **2 Creates**; 3 total assertions |

The missing-affine witness is the intended semantic failure: caller retains xs
for append while preparing bump(xs), forcing two copies within twice's interval.
It is not a compile error or arithmetic-only refusal. Reject-all inherently
has no accepted allocation witness; its intended failure is loss of required
acceptance. All three compile and finish the campaign successfully. Copied
mutant sources are retained as `evidence/*-Demand.lean.txt`; their `.log` and
`.json` files and `summary.json` preserve every detection. Original checker
text was verified unchanged after the campaign.

## Inspection findings

`occurrences` resolves lexical names and hides an outer name under local/match
binders. Sequential operands/arguments add uses; selected branches take max.
List parameter, let and match-tail affinity blocks repeated ownership use.
`spend` consumes innermost branch credits, not caller credits. Match checks both
branches with 0/1 local credit; its credit is popped before branch exit. Branch
joins take minima. Calls check argument preparation under current local credits,
require demanded callees, and neither donate nor borrow callee/caller credits.
`check` validates ordinary function typing and checks every demanded declaration
together from empty credits, not a presumed recursive no-Create summary.
This is plausibly conservative simultaneous syntax discipline; **soundness of
recursion and reservation/uniqueness preservation still needs proof**.

No forbidden proof bypass, new axiom, or native/unsafe proof mechanism occurs
in the two delivered checker/runner sources inspected. This is a source
inspection, not a transitive axiom audit of a future Conditional theorem.

## Exact reproduction commands and additional controls

From repository root:

```sh
python3 -B experiments/03c-checker/full/stage-2/verification-preflight/verify.py \
  > experiments/03c-checker/full/stage-2/verification-preflight/evidence-campaign.log 2>&1
```

The script records actual subprocess commands in each log. For each original,
scratch-original and mutant, the commands are `lake env lean --version`,
`lake build Full.Demand Full.Statements`,
`lake env lean -o .lake/build/lib/lean/Export.olean Export.lean`, then
`FULL3C_INPUTS=<absolute unchanged stage-1 inputs path>` and
`FULL3C_DEMAND_OUTPUT=<absolute evidence path>` with
`lake env lean ../stage-2/Run.lean` (checkout) or
`lake env lean stage-2-run.lean` (copied runner in scratch lean directory).
All five executions passed. `evidence-campaign.log` is the successful consumer
report; `evidence/{original,scratch-original,accept-all,reject-all,missing-affine}.log`
are build/execution logs.

Additional executed commands from `experiments/03c-checker/full/lean`:

```sh
FULL3C_INPUTS=/home/user/workspace/repo/experiments/03c-checker/full/stage-1/completion/evidence/inputs.json \
  lake env lean ../verification/Controls.lean
lake -d ../../trial/lean build Checks
lake env lean --run TrialCompatibility.lean
lake env lean --run ../verification/ReviewCases.lean
```

Logs: `evidence/stage1-controls.log` (**21 faulty routes rejected**, original
controls passing), `trial-checks-build.log`, `trial-compatibility.log`
(**28 trial answers/events/complete ordered landmarks pass**), `review-cases.log`
(heterogeneous arguments, zero-arity Bool, sparse/shared/outside cases and
transfer boundary pass). TrialCompatibility initially lacked Checks.olean;
building the existing Checks dependency resolved this without source changes.
Two initial consumer setup errors (mistaking Export.value for tagged Raw and
enumerating letters rather than alphabetic addresses) were corrected by reading
the actual frozen adapter; neither was a model/spec defect. Successful campaign
was rerun after corrections and independent interval counting was added.

From `experiments/03c-checker/full`, the commands
`sha256sum -c BASELINE.sha256`, `sha256sum -c FREEZE.sha256`, and
`sha256sum -c stage-1/rank-amendment-01/PREPARATION.sha256` all passed
(`evidence/integrity.log`). Frozen predictions' five hashes and original fixture
checker (40 declarations, 16 starts, 90 rows, 84 ledgers, 8 fixture-negative
controls) passed (`evidence/frozen.log`). Historical gzip was already present
and validated by inventories; no download or history/lock change was necessary.
`git diff --name-only` remained empty for tracked files.

## Limitations / remaining delivery work

This runner does not implement lifecycle denial gates; the six frozen nonfinished
cut/denial rows are executed but are **not** asserted as denial/boundary successes
by this consumer. Finished graphs, full scope/lifetime boundaries, destruction,
F1–L2 and unbounded executions are not newly certified here. Existing stage-1
controls were rerun, not replaced by this smaller checker consumer. No fresh
kernel recheck or exact theorem/axiom audit of a universal Conditional proof is
possible until that proof is delivered. The cache-free executable reconstruction
is not a substitute for that proof gate. No caller ownership mutation/enforcement,
Rust/native refinement, recursion/divergence theorem, Koka rerun or private data
access occurred. Existing Koka 3.2.9 comparisons and their limitations remain
unchanged. This preflight is evidence for continued proof work, **not approval
to claim stage-2 completion**.
