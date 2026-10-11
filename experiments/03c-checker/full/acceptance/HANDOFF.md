# Acceptance-author handoff — ROB-1139

**Prepared, checked and compared; not frozen or independently verified.**
All work is new under `experiments/03c-checker/full/acceptance/`, based on public
baseline `a4056b8341122622106fe60f834dbf8e2428295f`. No historical file/lock was
modified, no private corpus accessed, no Lean model/theorem or demand checker
authored, and no push/merge performed. Files are local and uncommitted for the
parent's thread-transfer workflow. The parent reports it received the prediction
checkpoint before starting model encoding; later transfer still needs all files.

## Checkpoint and exact artifacts

Recorded before new model/comparison execution: **2026-10-09T19:21:39Z**.
`PREDICTIONS.sha256` SHA-256:

```
ee9b4aa5477da5b9aa379172edcbd01b0dca840b3ff64a74705e78f57d82767a
```

It fingerprints `programs.json`, `starts.json`, `predictions.json`,
`DERIVATIONS.md`, `BOUNDARIES.md`; all remain unchanged. `CHECKPOINT.md` records
the chronology and authorship boundary. `MANIFEST.sha256` fingerprints the full
handoff (excluding itself); it is an inventory, **not a new scientific lock**.

* **Exact corpus:** 40 typed library declarations, per-case syntactic call
  closures, 16 explicit valid starting DAGs/root multisets and 90 concrete cases.
  Coverage: C1–C22 and all 27 inherited categories (12/6/1 slice-1 and 3/3/2
  slice-2 accept/refuse/observe). No category deleted. Six cases are specified
  suspension/failure prefixes; 84 specify genuine finished answers and graphs.
* **Rule-derived evidence:** full ordered cell effects, call interleavings,
  raw answer identities, final retained graphs/counts, selected protected-holder,
  cleanup, entry, resume/budget, failure and destruction boundaries in the five
  checkpointed files. No expected answer came from candidate/reference output.
* **Checks and integration I/O:** `check.py`, `CHECKS.md`, `checks.log`,
  `consumer-unit.log`. The summary consumer's exact JSON schema and all remaining
  boundary-data requirements are explicit. No formal integration pass is claimed.
* **Koka:** `KOKA.md`, `compare_koka.py`, `comparison*.log`, and `koka/`,
  `koka-r2/`, `koka-r3/`. Exact source/compiler/runtime output and failed attempts
  retained. Final evidence selects r2 except merge/build, which select r3.

## Executed verification and result

`python3 -B check.py`: all 40 declaration types, 16 starts, 90 case types/coverage,
84 finished manual cell-ledger/retained-graph consistency checks passed; all
eight malformed-fixture controls rejected. Separate consumer unit checks accept
a synthetic complete payload and reject seven corruptions, without pretending
to execute the formal model. `sha256sum -c PREDICTIONS.sha256` passes unchanged.

Koka **3.2.9**: all **19 categories / 53 concrete answers** compiled and ran in
the final selection; every answer matches the prior prediction. Twelve required
accepts have no fbip warning; six required refusals have one. Arithmetic-only
ordinary helper conservatively warns (observed usefulness limitation).

Differences: initial harness parse error (retained, corrected); merge/build
needed explicit Koka `div` signatures (termination/representation, bodies
unchanged); ordinary helper warnings are library/annotation boundaries. Unused
pattern and bundled-mimalloc compiler warnings retained, not misreported as
demand verdicts. No mandated memory-verdict disagreement found. This does not
establish Mo's cell-event predictions or universal claims.

## Remaining gaps and decisions

No substantive contradiction in the English contract was found during this
preparation. Preserve the predictions when integrating; surface any later
disagreement rather than adapting expected traces to output.

Before scientific freeze, still required: actual formal execution against the
summary/boundary checks, exact Lean statement names/quantifiers and independent
plain-to-counted required-value relation; fixed F6 embedding/landmark projection
and all 28 inherited regressions; executable scientific mutants with reached
fault provenance; explicit permitted-axiom allowlist and fresh kernel rechecking
when proofs exist; third-author verification and Robert's exact-package approval.

The concrete unresolved interface choices are C20's modeled number/frame request
sites/ordinals and the total export projection for nested state/holder records.
BOUNDARIES.md specifies the intended semantics and cuts; CHECKS.md specifies the
data checks need. These require specification-author definitions and review, not
an invented assertion that integration already runs. No proof/checker stage,
scientific freeze or additional owner approval is inferred from this handoff.
