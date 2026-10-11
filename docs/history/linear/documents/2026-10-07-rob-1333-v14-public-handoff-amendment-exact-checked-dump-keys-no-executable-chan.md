# ROB-1333 v14 public handoff amendment — exact checked-dump keys, no executable changes

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/rob-1333-v14-public-handoff-amendment-exact-checked-dump-keys-no-291025dfded3
> Created: 2026-10-07
> Updated: 2026-10-07
> Author: Robert Guss
> Attached to: ROB-1333

---

## Documentation omission corrected; still awaiting parent review/freeze

Parent exact v13 review verified both archives, all 489 reviewer-manifest hashes, eight public fingerprints, storage13/13, driver2/2 and public compilation. The remaining omission was that the public brief named checked-node tags without the exact discriminator/key sets. This v14 amendment documents the unchanged canonical contract, not a new language choice or acceptance requirement.

Changed only BUILDER_HANDOFF.md and added BUILDER_CHECKED_DUMP_V14.md. The supplement explicitly specifies discriminator **node**, including node=Program; all exact per-node/declaration/function/match-binder key sets; absent leaf children/value fields; Program lacking path/type; compound child order; declaration paths and scalar kinds. No case outputs or acceptance sources enter builder delivery.

## Exact amended public delivery

[Download sanitized v14 archive](<https://uploads.linear.app/f291a744-db03-47a3-b7a6-4f8fa26fbf09/c9217742-048f-4519-b000-d3358308a128/a1c09168-1f7b-4301-a058-6e79cdee6269>). Attachment f67bfb70-96c8-4568-a10e-43d4438cf9bc. Local file .amp/in/artifacts/[ROB-1333](https://linear.app/robert-guss/issue/ROB-1333/proposal-first-source-driven-mo-interpreter-then-functions-and)-stage-a-public-v14.tar.gz; **19,610 bytes**, SHA256 **3327ee87f52316bec571f91c81b20f556f030614d41a681699a6cdc8f49c94de**.

Complete inventory: BUILDER_HANDOFF.md, BUILDER_BRIEF.md, BUILDER_AMENDMENT_D154.md, BUILDER_EXECUTION.md, BUILDER_CHECKED_DUMP_V14.md, runtime/Cargo.toml, runtime/Cargo.lock, runtime/lib.rs, runtime/abi.rs, DELIVERY.sha256. Nine source/document fingerprints plus the inventory itself. No acceptance tests/references/observer/private cases/seeds/predictions/control implementation or review evidence included.

Changed/new source identities, relative to experiments/13-source-acceptance:

* BUILDER_HANDOFF.md: **2c5083decf663c4377890007e0e3cbe4a5186701488ec67d168176a0dbc100d4**
* BUILDER_CHECKED_DUMP_V14.md: **066fe3dc768304c7ebb0cdd2c43a1b507792c33dcec54a71703e3ddc34083768**

All other public files retain their v13 fingerprints. All executable acceptance sources, predictions, checks, runtime/storage/driver source and historical files retain the reviewed v13 fingerprints. The unchanged [integration.py](<http://integration.py>) remains e67505cd6174ad469c85df87eca2bd58671597b8411d16e361adb854b0f932bb.

## Validation and retained history

A one-off documentation consistency check extracted the field-key table and compared it with 2,156 objects from the existing 21 public examples: all matched. Table coverage includes every declared node kind and all three auxiliary declaration/binder kinds. Eq/Lt were not present in those examples and were checked directly against unchanged structurecheck.canonical; no new case campaign or acceptance-check edit. Clean unpacked cargo +1.98.1 check --locked --manifest-path runtime/Cargo.toml passed. Archive entries and their bytes were checked against the exact allowlist. Evidence: evidence/integration-delivery-v14/summary.json and clean-build.txt.

Both v13 archives remain byte-identical:

* Public: SHA256 80343fc7be0171f1ed133de786ea10f1b25e5dca70ebff24fe5defa54712ea2d, 18,017 bytes.
* Reviewer-only: SHA256 65083e8e5738abd74b3c77124553efbac6dddde2b421aa51315dde47f9148763, 2,536,049 bytes.

[Existing v13 reviewer/source/evidence index](<https://linear.app/robert-guss/document/rob-1333-integration-v13-stage-a-small-case-review-sanitized-delivery-75b99e40ae59>) remains the code/evidence baseline. This document plus v14 public archive is its documentation-only amendment; do not substitute the reviewer archive as builder input.

Remaining gates are unchanged: parent review then scientific freeze and actual fresh-context/procedural delivery/access checks; candidate-dependent source/routing/real execution/control checks later. The large streaming adapter remains unimplemented; Stage B/resource execution is separately unauthorized. No freeze, dispatch, interpreter, push, merge or deployment occurred. Local acceptance branch remains uncommitted; thread stays unarchived.

Measured amendment effort 21:40:01–21:42:45Z:164 contributor seconds; cumulative recorded3,432 seconds. Earlier preparation unknown; stopped interval excluded; final notification latency after timestamp unmeasured. Exact ledger: evidence/integration-delivery-v14/effort.json.
