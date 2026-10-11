# ROB-1333 integration v13 — Stage A small-case review, sanitized delivery and remaining gates

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-integration-v13-stage-a-small-case-review-sanitized-delivery-75b99e40ae59
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

## Ready for parent review, not frozen or dispatched

Acceptance integration now compiles and runs through a canned native interface fixture. No Mo interpreter has been implemented or executed. D153 (exact v12 and conditional integration→review→freeze/Stage A) remains the gate; D154 assigns external-root/full physical-memory reporting to acceptance; D155 approves procedural Stage A separation, not technically denied tool access.

The two parent findings were reproduced before repair and are now rejected: ignored frontend Number denial cannot be hidden by invalid-fixture output; required array fields/nested rows reject empty objects/strings before normalization. Fixed predictions were not changed. The pre-repair source and accepted wrong-output/schema witnesses remain in evidence/integration-review-defects.

## Two distinct exact deliveries

**Sanitized builder delivery, for review before dispatch:** [public archive](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/e84f8d99-750c-41fc-8b11-5f78628a0e4b/7c0d378b-33b0-44a9-90db-31814c464194?signature=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXRoIjoiL2YyOTFhNzQ0LWRiMDMtNDdhMy1iN2E2LTRmOGZhMjZmYmYwOS9lODRmOGQ5OS03NTBjLTQxZmMtOGIxMS01Zjc4NjI4YTBlNGIvN2MwZDM3OGItMzNiMC00NGE5LTkwZGItMzE4MTRjNDY0MTk0IiwiaWF0IjoxNzkxNDA5MDMyLCJleHAiOjE3OTE0MDkzMzJ9.4BtNKr1adlzgJBz-h6eyfoeWPO5aYzcH6ygOyxC39kU>), attachment 9b5373c8-8023-4be0-be02-abfce04a5eea. Filename [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-stage-a-public-v13.tar.gz, 18,017 bytes, SHA256 **80343fc7be0171f1ed133de786ea10f1b25e5dca70ebff24fe5defa54712ea2d**.

Its complete allowlist is BUILDER_HANDOFF.md, retained BUILDER_BRIEF.md, BUILDER_AMENDMENT_D154.md, BUILDER_EXECUTION.md, runtime/Cargo.toml, runtime/Cargo.lock, runtime/lib.rs, runtime/abi.rs, plus DELIVERY.sha256. Four requirements documents, four runtime source/manifest files, one fingerprint inventory. No acceptance implementation, observer/fixture constructor, tests, reference, control implementation, private corpus/seed/predictions or reviewer evidence. Clean unpacked cargo +1.98.1 check --locked passed; one permitted API probe compiled, six forbidden API probes failed as intended. This verifies delivery/API surface only, not hard account isolation.

**Owner/reviewer only:** [review archive](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/83d26b2f-4445-4a5d-85cb-ca4d1b7b4c68/e5aa7e24-7b00-450e-b595-fb5449f2b9ba?signature=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXRoIjoiL2YyOTFhNzQ0LWRiMDMtNDdhMy1iN2E2LTRmOGZhMjZmYmYwOS84M2QyNmIyZi00NDQ1LTRhNWQtODVjYi1jYTRkMWI3YjRjNjgvZTVhYTdlMjQtN2IwMC00NTBlLWI1OTUtZmI1NDQ5ZjJiOWJhIiwiaWF0IjoxNzkxNDA5MDMyLCJleHAiOjE3OTE0MDkzMzJ9.RQKZdGja0Djx3o0N_e3Vj2T41Sp3_68sbUkxDUzmXmo>), attachment c5ad4306-e80f-41ed-8687-25e6c52f776f. Filename [ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-integration-review-v13.tar.gz, 2,536,049 bytes, SHA256 **65083e8e5738abd74b3c77124553efbac6dddde2b421aa51315dde47f9148763**. Contains 490 files under experiments/13-source-acceptance, including source, historical/current evidence and evidence/integration-delivery/review-manifest.json with exact file hashes. Excludes build caches and the separately retained private corpus/seed. NOT builder input and NOT a scientific lock.

Exact interface: public mo_acceptance_runtime::Candidate trait; builder supplies its exported implementation type/CheckedProgram/Run. Acceptance links mo_acceptance_driver::serve::<candidate_crate::ExportedType>(). The actual runtime-only crate now exists. D154 removes memory/outside from candidate snapshot.state and composes them from real native Observer and actual host-retained roots, never reference predictions. Required execution/readback fields and all protection checks remain. Supplemental execution requirements spell out the existing action/reporting schedule rather than requiring acceptance-source retrieval. Parent review must include that public documentation and the documented givenUp omission correction.

## Executed evidence

Commands run from experiments/13-source-acceptance:

| Command/check | Result | Evidence path |
| -- | -- | -- |
| cargo test --locked --manifest-path cells/Cargo.toml | 13/13, including original 7 storage tests | evidence/integration-02/storage-final.txt |
| cargo test --locked --manifest-path driver/Cargo.toml | 2/2: exact four-way pre-run formatter; periodic/cap boundaries | evidence/integration-02/driver-final.txt |
| python3 [integrationcheck.py](<http://integrationcheck.py>) evidence/integration-05 /home/user/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-private-v11 | 23 successful native stub runs, 49 rejected controls, 545 unchanged reference comparisons; three-step large-schedule fixture | evidence/integration-05/summary.json; per-run raw JSONL/summary/stderr |
| python3 corpus_tracecheck.py evidence/integration-regression-corpus_tracecheck | 4,276 cases / 27,721 snapshots / 53,796 reference transitions | same directory/summary.json |
| unchanged wirecheck, bridgecheck, faultcheck | 12 encoding + 9 output + 7 controls; native bridge + 6 controls; 2 fault domains + 12 controls | evidence/integration-regression-\*/summary.json |
| unchanged cleanupcheck, controlcheck, structurecheck | 1,603 synthetic cleanup boundaries + 4 controls; 3 worked control cases + 3 bounded prefixes; 6 structures | same pattern |
| unchanged phasecheck, refusalcheck, decimalcheck, closeoutcheck | 24 phase cases; 24 refusals; 35 wide-decimal cases; 31 evaluator controls specified / 163 record controls | same pattern |

The 49 current controls include four compiled STUB controls and 26 empty-object/string schema controls; none is represented as an executed Mo evaluator mutant. The 545 regressions are existing 21 public + fixed 524 private rows, not a new campaign. Native fixture tests exercise both original outside-root orders, all cuts of three supplied commits, zero/terminal budgets, two destroys, actual cell/Number/Frame denial and actual process-watchdog interruption. The periodic/cap unit test supplies counter values; it did not execute 10,000 or 100 million transitions.

## Refresh these reviewed files

All paths below are under experiments/13-source-acceptance. Full inventory/hashes are in review-manifest.json; latest important identities:

* driver/lib.rs: 8f44b4e1f297ce0fe092c45c6e971a682eb0ab3e6edac31cdc8b12695550bb7d
* [linked.py](<http://linked.py>): 8edca38ae31e18319f90f412f0d6fea45371eb7a17a9c7a37e6e471a88865f05
* [integration.py](<http://integration.py>): e67505cd6174ad469c85df87eca2bd58671597b8411d16e361adb854b0f932bb
* [integrationcheck.py](<http://integrationcheck.py>): 45ba154dc2f553cb825ba8744dfa3b24e6b18903d3935d0377f6100a0441c327
* cells/lib.rs: 73e858943348416c769571c635dba737de7dbad7c6269bf4644c40df36abd738
* cells/host.rs: 47b371505d4ba65371c1a8be4e5caaafd223138c511d753e32ef6d63c222053e
* cells/linkage.rs: 56afd563a1148cefa5cf739357077ac53c6cb74aaffbd25f63cf0196e57218f6
* runtime/lib.rs: 0a4418ea6b513c9fa563f4fdce8dfd9bd12f6255ca4679befa8c6660be07b020
* BUILDER_AMENDMENT_D154.md: f16da7973f501af3db33e979c7b218fbf9cf84c924c4070e5c904d2568d39d27
* BUILDER_HANDOFF.md: 172a7501b18a1f1bec791c7878c7b4194bbf5a98dea4b53ce76ac94cf61fa2e9
* BUILDER_EXECUTION.md: e5c3aa641014e0bf34feb4a7f6caa9cb48bea13d33646bf3e0916415a24ff5df

Also refresh driver/examples/fixture_stub.rs, INTEGRATION_D154.md and new integration evidence. Against exact FINAL v12, the only changed pre-existing files are cells/Cargo.toml, cells/Cargo.lock and cells/lib.rs; all other integration paths are new. Original v12 archive and fixed prediction/check documents are unchanged. Private corpus SHA256 remains 0f176c60d30d30fffd4d7fb25d982cd3517d1a847840027ad3e99f9c572f41f0; it is not in either delivery.

## Gates still open

1. Parent review against approved v12 and D154/D155, then scientific freeze and actual fresh-context/files/prohibited-access verification. Same-account retrieval is technically possible; D155 accepts procedural non-exposure and recorded access checks for Stage A. No further isolation-policy owner approval is needed.
2. Candidate-dependent checks: link the future exported Candidate type, inspect routing/source independence, execute original-source historical cases, all required real resume/destroy/failure cuts, and compiled evaluator controls. No candidate has run. Only parent dispatch can start Stage A; this author remains barred from implementing Mo.
3. Stage B requires separate authorization after Stage A evidence. Actual recursive/native caller protection and abort behavior remain unrun.
4. **Not resource-ready: large streaming adapter is still unimplemented.** linked.run_linked sends large=false; Verifier expects full small traces. Rust's incremental cursor/periodic collection and schedule/cap are tested, but bounded-memory large verification and workload-specific measurements still require acceptance integration before any later authorized resource run. This is unfinished executable preparation, not merely a test waiting for a candidate. No million-depth/resource workload ran.

Timing implemented for small linked runs: before process launch through setup/checks, verification waits, advances, both destroys, outside checks, host teardown, exit and final verification; one uninterrupted watchdog. Compilation/offline predictions precede it. Child stack 8 MiB; available memory and per-child peak RSS recorded. Future large adapter must recheck/enforce >=4 GiB provisioning, not a memory ceiling; current small stubs do not enforce that floor.

Work remains local/uncommitted on acceptance/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-preparation, distinct from parent local main and unchanged [origin/main baseline](<https://github.com/robertguss/mo-v2/commit/03705f1dac1de8cbc9efedaf99ad4feeb62c17a3>). No imported parent edits, freeze, dispatch, interpreter, Stage B/resource execution, Fable, push, merge, deployment or archival. Recorded effort at archive checkpoint: 20:57:55–21:33:44Z = 2,149 seconds this resumed interval, plus previous 935; publication remains active until final delivery and will be recorded separately. Earlier preparation unknown; stopped interval excluded.

### Delivery effort closeout

Measured through 2026-10-07T21:36:48Z: resumed 2,333 seconds plus previous 935 = 3,268 recorded contributor seconds. Earlier preparation unknown; stopped interval excluded. Includes validation/packaging/publication waits through that timestamp; final notification-tool latency afterward unmeasured. Detached evidence/integration-delivery/effort-delivery.json supplements the archived checkpoint; both archive fingerprints remain unchanged. Parent independently confirmed both concrete repair witnesses reject in the final 27,636-byte [integration.py](<http://integration.py>) snapshot. Stopped for parent review, unarchived.
