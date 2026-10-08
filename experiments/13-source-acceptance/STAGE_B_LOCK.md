# Stage B scientific freeze — preparation package plus public v19

This freeze fixes the Stage B acceptance package before the separate builder
starts. It is **not a passing Mo acceptance result**, and it does not run the
gated work. `STAGE_B_LOCK.json` is the exact fingerprint inventory. Paths in
its `files` map are relative to this directory. The lock does not hash itself.
`evidence/stage-b-freeze/validation.json` is freeze evidence, not an additional
scientific criterion, and it is not part of the content inventory.

Authorization is D165 (scientifically freeze this package, then hand it to a
separate builder), on top of D157 (prepare the package, no build yet), D159
(summaries between boundaries), D160 (the cleanup chain in full only at
photographs), D162 (900 seconds for the million-element recursive sum, 600
seconds for the discard, per-step record kept) and D164 (`omitted-entry-create`
is not applicable because the frozen predictor never allocates on Enter; nine
of the ten sabotage tests stay active). D151 is the resource envelope D162
amends for the sum only. No new language choice is introduced. No frozen Stage
A file is edited.

The builder has written no code. This freeze does not dispatch it, and it does
not authorize private execution, the nine active sabotage tests, or either
million-element run.

## What is fixed

- The Stage A scientific freeze, `STAGE_A_LOCK.json`, and every file it lists.
  Those 496 files, the five historical dependencies and the preserved Stage A
  archives stay byte-for-byte. This lock checks them. It does not replace them.
- The Stage B preparation: the closed-form workload rules, the large-run
  watcher, the link to the frozen Stage B checker, the control harness, and the
  evidence of those preparation runs. Preparation documents that say the
  package is "not frozen" are describing that checkpoint. This file is the
  freeze.
- D164 as already recorded. Nine sabotage tests are active and none has run.
  `omitted-entry-create` is not applicable. A record claiming any of the ten
  ran is still rejected. That gap is unchanged.
- Public package v19, which replaces v18 as the only builder delivery. v18
  remains as history. Its archive fingerprint is
  `0e30809545c3114012c69cceaf024e22f69c08a9b9721eb0a199e35a5d76b997`.

## The v19 amendment

`BUILDER_STAGE_B_V18.md` gave both large workloads 600 seconds.
`BUILDER_BRIEF.md` still prints that older sentence, and it is a frozen Stage A
file, so it was not edited. v19 replaces the Stage B addendum.
`BUILDER_STAGE_B_V19.md` states D162: the recursive sum gets 900 seconds, the
discard stays at 600, and the record of every step stays.
`BUILDER_STAGE_B_PREFLIGHT.md` answers the builder's five preflight questions
from the already-frozen rules. All five are answered. None is left open, so
this lock is not provisional. The clarification adds no rule, no case and no
private material.

The old and new document fingerprints, and every v19 member fingerprint, are
in the lock under `v19_document_amendment` and `public_delivery`.

## Exact delivery and procedural separation

`stage-b-delivery/rob-1333-stage-b-public-v19.tar.gz` is the **only builder
delivery**. It contains the unchanged Stage A public requirements, including
the v15, v16 and v17 clarifications, plus the v19 addendum and the preflight
clarification, the four runtime crate files, and `DELIVERY.sha256`. The
acceptance branch, this lock, the preparation evidence, private files and the
checker source are not builder context, even where this repository is public.

The parent must verify the fresh starting files against that allowlist, give
the explicit prohibition on retrieving excluded material by any route, and
record tool use. Same-account tools still technically allow retrieval. This is
procedural separation, not enforced inaccessibility. Package inspection here
does not establish the future builder's context.

## What this freeze does not do

Still gated, and not done here:

| Gated on | What it is |
| --- | --- |
| The acceptance machine | Private execution of the 24 reserved and 500 generated cases |
| A Stage B interpreter | The nine active sabotage tests |
| Separate authorization | Either million-element run |
| The parent | Dispatching the builder, and merging this freeze |

The projections from preparation still stand and are not remeasured here: the
sum is about 12 minutes, inside 15, and the discard is about 98 seconds,
inside 10. Neither workload was run at a million elements.

## Recheck without a new campaign

Compare each `files` SHA256 with the corresponding bytes. Compare each
`STAGE_A_LOCK.json` file hash again, so the 496 frozen files are still exact.
Compare the v18 and v19 archive hashes. For v19, require exactly the listed
content files plus `DELIVERY.sha256`, no links or extra entries, and check
every member against `public_delivery.files`.

The private corpus is not in this workspace. Before dispatch, the acceptance
orb checks it read-only. Those checks do not change this lock if they pass:

1. SHA256 of `/home/user/rob-1333-private-v11/cases.jsonl.gz` equals
   `0f176c60d30d30fffd4d7fb25d982cd3517d1a847840027ad3e99f9c572f41f0`, and the
   file is 1,003,653 bytes. Do not print or copy its contents.
   `seed.json` beside it is 50 bytes. Do not print the seed.
2. The corpus counts, without exporting a source or an expected output: 24
   heldouts, 8 families, 500 generated rows, 404 distinct generated cases and
   96 repeats.
3. A no-leak scan of this freeze commit. The v19 archive's members are only
   the public allowlist plus `DELIVERY.sha256`. None of those members contains
   the private fingerprint, the private path, the seed filename, a held-out
   case, the acceptance checker sources, or this lock's name. The commit adds
   no private file. The scan looks at the committed bytes. It is not a proof
   that a later builder context stayed clean.

`evidence/stage-b-freeze/validation.json` records the inventory and publication
audit performed with this freeze. The three orb checks above are listed there
as not yet performed. No executable acceptance file from the Stage A freeze was
edited. Stop for the parent before dispatch.
