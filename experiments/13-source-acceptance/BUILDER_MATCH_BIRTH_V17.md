# Match-branch identity timing — public clarification v17

This normative supplement makes explicit the existing match-branch birth timing.
Read it with BUILDER_AMENDMENT_D154.md and BUILDER_EXECUTION.md. It changes no
action, ownership rule, failure requirement or acceptance criterion and prescribes
no evaluator algorithm. Public v17 preserves all eleven v16 content files, adds
this document, and regenerates DELIVERY.sha256 for twelve content files. It does
not authorize Stage B or resource workloads.

## Creation follows Choose branch, not selection publication

Each evaluated Match creates one fresh match-branch identity, whether its
scrutinee is empty or nonempty and, when nonempty, whether unique or shared.
The timing is:

1. Complete the scrutinee and commit `Choose branch`. This commit does **not**
   create or publish the branch identity for this Match. Previously committed
   births, including any produced while evaluating the scrutinee, remain present.
2. Create this Match's branch identity after `Choose branch` and before the
   branch-specific cleanup of unused outer holders.
3. First publish its birth in the next existing committed action, according to
   the table below. Identity creation adds no separate transition or callback.

| Work following Choose branch | First callback containing this Match's branch birth |
| --- | --- |
| Branch-specific outer-holder cleanup performs a committed action | The first such cleanup action (`Give up holder`), for either empty or nonempty match |
| No such cleanup action; empty scrutinee | `Branch start` |
| No such cleanup action; nonempty scrutinee, unique or shared | `Match decompose` |

Do not delay the birth until all outer-holder cleanup finishes when that cleanup
has already committed an action. For nonempty matches, head/tail decomposition,
any subsequent tail or scrutinee release, `Match complete` when applicable, and
`Branch start` retain their existing order. The branch birth is not deferred to
the shared-match completion or reservation use, and empty matches also have it.
An If selection does not create a match-branch identity.

## Origin and order stay tied to execution

The birth row retains the existing fields `domain`, `id`, `origin`, `invocation`:
domain is `branch`, origin is this Match expression's checked source path, and
invocation is its owning invocation (implicit root 0 in Stage A). The origin is
not the selected alternative's path. IDs remain opaque per-domain identities;
no retired ID is reused. This clarification does not prescribe numeric ID values.

Births remain one append-only execution-ordered prefix. A Match's branch birth
precedes its head-binding birth, which precedes its tail-binding birth; for a
nonempty match with no preceding cleanup action, those three additions first
appear in that order in `Match decompose`. With preceding cleanup, the branch
birth is already present when the two bindings are added. Empty matches create
neither head nor tail binding. Matches evaluated inside the scrutinee create
their own identities at their own boundaries, before the enclosing Match's
identity; source traversal order is not a substitute for execution order.

## Committed-prefix and failure obligations are unchanged

The first exposing callback supplies the new row in `births_added`; its snapshot
contains the corresponding complete `births` prefix. Later callbacks do not
repeat that addition or rewrite earlier rows. No extra step, landmark or managed
cell event is introduced for branch identity creation.

A controlled denial while attempting an action adds no committed step and emits
no partial callback. Preserve the last committed execution state, birth/event
prefixes and native graph/lifetimes, with the existing separate failure evidence.
In particular, if the first action after `Choose branch` fails before committing,
its newly prepared branch birth must not appear in the preserved prefix. If the
birth was already committed, a later denial must not remove it. Suspension and
resumption likewise retain the committed prefix and do not recreate a published
identity. These are the existing preservation obligations, not a rollback API or
an arbitrary host-OOM recovery promise.
