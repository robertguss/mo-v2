# ROB-1130: Make Linear the live source of truth for Mo v2

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1130/make-linear-the-live-source-of-truth-for-mo-v2
> Status at export: Done
> Created: 2026-10-02
> Updated: 2026-10-02
> Completed: 2026-10-02
> Comments: 1

---

## Description

Robert requested this migration in [https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7](<https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7>). Lead owns bookkeeping; Oracle reviews scope and cutover. No proof work.

Stop condition: existing decisions imported with wording and attribution retained; all planning/research/evidence sources catalogued using pinned links; approved, blocked, deferred and historical work distinguished; records read back and checked; unlocked repository entry points point to Linear; no locked artifact or proof changed.

Git remains artifact storage, not a competing live task list. This migration does not authorize the new Builder arrangement. No need for Builder/Tester code threads for this bookkeeping task.

## Migration delivery and verification

Linear populated: six project documents, twelve issues; all read back. Historical decisions: 101 rows, 38,218 normalized characters, matching FNV-1a feb6f3c3 across source and read-back (formatting stripped for comparison). Git historical decision rows and historical status also checked byte-identical. Catalog: 19 disjoint source groups totaling all 328 tracked files at the pinned source revision; Oracle independently reconciled membership/counts. Actual blocker relations read back; no proposal marked Ready.

Oracle reviewed the plan and final six-file diff, no remaining P1/P2 findings. Oracle inspected Git locally; remote Linear checks were Lead-performed, not independent Oracle execution. git diff --check passed; no experiment/setup/proof/locked-artifact changes. No Builder started, no proof clock began, no benchmark or proof acceptance claimed.

Repository pointers committed and pushed on rob-1130-linear-source-of-truth: [2d8a2b2146199efd5c5da48293e9c0dff0201c4c](<https://github.com/robertguss/mo-v2/commit/2d8a2b2146199efd5c5da48293e9c0dff0201c4c>). Reviewed Lead paths: CLAUDE.md; docs/README.md; docs/DECISIONS.md; docs/DECISION-MAP.md; docs/research/README.md; docs/research/documents/README.md. Preserve these as separately reviewed Lead changes for later isolated proof acceptance; do not replace the original lock baseline.

Merged: Robert authorized merging in the Lead thread. The reviewed commit [2d8a2b2](<https://github.com/robertguss/mo-v2/commit/2d8a2b2146199efd5c5da48293e9c0dff0201c4c>) was fast-forwarded into main and pushed; a fresh fetch confirmed origin/main equals the accepted full SHA 2d8a2b2146199efd5c5da48293e9c0dff0201c4c. Worktree clean. No PR was needed and no deployment occurred. Lead/Oracle thread: [https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7](<https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7>). No Builder/Tester threads were used for this documentation migration. Proof work and its unresolved arrangement remain paused.

## Comments

### 2026-10-02 00:55 UTC, Robert Guss

[lead] Migration merged after Robert’s explicit approval. Accepted branch SHA and fast-forward main commit: [2d8a2b2146199efd5c5da48293e9c0dff0201c4c](https://github.com/robertguss/mo-v2/commit/2d8a2b2146199efd5c5da48293e9c0dff0201c4c). Fresh fetch confirms origin/main equals this commit; worktree clean. No PR or deployment.

Oracle reviewed the migration plan and final diff; no blocking findings remained. Its preservation/coverage concerns were addressed by retaining the arrangement gate, complete pinned catalog and original proof-acceptance baseline. Verification: six documents and twelve issues read back; all 101 historical decisions preserved; catalog covers 328 files; git diff --check passes; no experiment or locked artifact changes.

[Lead and Oracle review thread](https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7). Builder/Tester threads were not used for this documentation migration. Proof work stays paused on ROB-1132; no clock started.
