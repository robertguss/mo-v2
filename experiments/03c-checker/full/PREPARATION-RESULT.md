# ROB-1139 preparation result — 9 October 2026

**Ready for owner review of the exact acceptance package; not scientifically
frozen, proved, or a completed demand-checker experiment.** D185 approved the
English scope; D186 approved separate acceptance/specification/verifier authors.
Those approvals do not authorize the next proof or checker campaign.

Delivery is local only: all `full/` files are uncommitted and unpushed. The
unchanged repository baseline is
[a4056b8](https://github.com/robertguss/mo-v2/commit/a4056b8341122622106fe60f834dbf8e2428295f).
No historical trial, Stage A/B artifact, lock, private corpus or seed changed.

## Evidence and review

| Executed check | Result |
| --- | --- |
| Pinned Lean 4.34.0 `lake build` | 15 jobs succeeded; definitions, not proofs |
| `run_spec.py /tmp/full3c-scope-evidence` | 40 declarations, 16 starts, 90 exact cases; 84 finished answers/ledgers/graphs match |
| `acceptance/supplemental-v2/check_expanded.py` | 820 groups pass; 90 histories / 4,591 snapshots; 12/12 corrupted-export controls rejected |
| `verification/check_final.py` | 4,498 complete internal equalities, 9,680 ordered-view checks; 3 corruptions rejected |
| `verification/Controls.lean` | 21 actual faulty logical routes rejected; every unmodified counterpart passes |
| `TrialCompatibility.lean` | All 28 answers, primitive effects and complete ordered landmark snapshots match |
| `verification/ReviewCases.lean` | Bool/forward calls, heterogeneous arguments, sparse/shared/repeated roots and transfer boundaries pass |
| Separate scope follow-up | 90 initial scopes, 4,542 source/output/commit triples; original hidden-scalar witness rejected |
| Original/supplemental acceptance inventories | All four inventories pass; original predictions unchanged |
| Koka 3.2.9, separately authored comparison | 19 categories / 53 concrete answers match; 12 accept categories have no fbip warning; 6 refusal categories warn; arithmetic-helper category conservatively warns |

The accepted traces contain 3,008 Plain steps, 1,490 ranked stutters and 3
controlled denials. The verifier's 4,542-triple scan bypassed denial policy for
inspection; it is not the acceptance-transition count. Koka warns rather than
rejecting compilation and its reuse policy differs from Mo's. Earlier failed
Koka translations and their eventual annotation corrections remain preserved.

The original prediction checkpoint preceded encoding. Supplemental-v2 call
histories were checkpointed after its author saw earlier outputs/schema, before
new usefulness histories; they are not represented as an entirely blind original
checkpoint. Same-account author separation is procedural, not technical isolation.

Separate review found and resolved missing demanded-declaration restrictions,
internal transfer-boundary coverage, exact effect payloads and source-prescribed
observer scope/order. The history is in `VERIFIER.md`, `verification/REVIEW-FOLLOWUP.md`,
`verification/FINAL-REVIEW.md` and the final `verification/SCOPE-FOLLOWUP.md`.
The last report clears the scope gap for consideration of proposed freeze.
It does not grant freeze approval or discharge any theorem.

The scope control matters: hiding C12's scalar parameter still passes ownership,
protection and the observer filter alone, but fails the new F1 source-scope
obligation. The strengthened statement preserves historical delayed shared-match
entry and requires acquisition-ordered complete records at internal boundaries.

## Exact candidate and reproducible observations

`PREPARATION.sha256` inventories this candidate, excluding itself, `.lake/` and
`__pycache__/`. It is a review inventory, **not an approved scientific lock**.
`BASELINE.sha256` identifies the unchanged tracked local Trial dependency.
Run both `sha256sum -c` commands from this directory. Toolchain and dependency
configuration are included in the preparation inventory.

`verification/evidence/` preserves fresh input/summary JSON, expanded and internal
check reports, logical-control logs and separate-verifier logs. `raw.json.gz`
contains the complete exported observations; decompression was compared byte for
byte with the original. No observations are synthesized from expected outputs.
To inspect the retained export without rerunning Lean, from this directory:

```sh
mkdir -p /tmp/full3c-retained
cp verification/evidence/{inputs,summary}.json /tmp/full3c-retained/
gzip -dc verification/evidence/raw.json.gz > /tmp/full3c-retained/raw.json
python3 -B acceptance/supplemental-v2/check_expanded.py /tmp/full3c-retained --report /tmp/full3c-retained/expanded.json
python3 -B verification/check_final.py /tmp/full3c-retained --report /tmp/full3c-retained/boundaries.json
```

For fresh execution, use the commands in `ACCEPTANCE.md`. Historical supplemental-v1
checks predate the richer export and are retained as history, not the current
consumer. Later reports adjudicate their lifetime/scope concerns.

## Remaining approval gates

1. Robert reviews and approves this exact acceptance package before scientific
   freeze. Actual freeze must record its delivered Git revision and hashes;
   there is no approved frozen revision yet.
2. A separately approved stage-1 brief/budget may then authorize proofs of
   F1–F6/L1–L2, with writes restricted to proof modules. `ACCEPTANCE.md` and
   `lean/ProofGate.lean` propose exact type, transitive-axiom and fresh kernel
   checks. No proof exists and none of those proof checks is reported as passing.
3. Stop and review stage 1 before any conditional checker. Caller enforcement
   remains a further separate gate. Checker-specific accept-all/reject-all and
   caller-ownership controls await actual implementations.

Finite tests do not establish universal recursion correctness, termination,
divergence, native Rust refinement or physical resource bounds. Nothing here
authorizes push, merge, deployment, historical-lock edits or a new paid service.
