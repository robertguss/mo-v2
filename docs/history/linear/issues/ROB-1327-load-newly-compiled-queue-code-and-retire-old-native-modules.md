# ROB-1327: Load newly compiled queue code and retire old native modules safely

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1327/load-newly-compiled-queue-code-and-retire-old-native-modules-safely
> Status at export: Done
> Created: 2026-10-06
> Updated: 2026-10-07
> Completed: 2026-10-06
> Comments: 0

---

## Description

## Merged — 6 October 2026

Robert instructed “merge it and continue”. Fast-forwarded main to a1c032fa7fa2b1061ce79f9fd13403061640bb5b, pushed and verified remote main. Experiment fingerprints unchanged; unrelated CLAUDE.md edit preserved. The following is the pre-merge result record.

## Implemented and self-verified — awaiting owner review

Branch `codex/native-code-loading` pushed and remote verified at `a1c032fa7fa2b1061ce79f9fd13403061640bb5b`. [Full report and limits](<https://github.com/robertguss/mo-v2/blob/a1c032fa7fa2b1061ce79f9fd13403061640bb5b/experiments/06-native-loading/RESULT.md>). Three final clean-build trials preserved 249 acknowledged jobs. V2 was separately compiled after startup; five persistent clients per trial remained usable. Held executing and queued old jobs stayed on v1, new jobs used v2, incompatible artifacts refused, and v1 genuinely disappeared from dyld after its references finished. All six compiled source controls were caught, including forced unload while executing and version mixing. Initial path-canonicalization check failure, earlier runs and controls retained.

Same-author verification under Robert's explicit amendment, not independent acceptance. Restricted trusted synchronous C ABI on macOS; slow native loading/destructors remain unbounded, and this experiment does not combine loading with experiment 5's watchdog/state migration. No arbitrary-code safety or production SLA claim. Prior experiment sources/locks unchanged. Unrelated unstaged CLAUDE.md edit preserved and excluded. No merge/deployment/next milestone. In Review; Done requires owner-authorized merge.

Robert authorized the next actual-code-loading experiment: “ok start a new chat and do it, this session is getting full”. Then amended authorship: “dont worry about the separate checks, just confirm it yourself.” Source Codex chat 01a10e93-b9e3-70a2-85e0-246219e61ed5, 6 October 2026. Implement and verify in this chat; verification is not independently authored acceptance. Prior locks/evidence stay unchanged.

Scope: separately compile v2 after a v1 service starts; load/activate without disconnecting clients; pin accepted work to its code version; reject incompatible artifacts; preserve acknowledged work; detect premature retirement and genuinely unload old code after references finish. Small native shared-library C ABI is an experimental boundary, not permanent Mo architecture. Reuse the Rust queue/TCP protocol where practical. No Mo v1 imports.

Plan: specify observable obligations and bounded controls, implement, clean-build and exercise real loading/lifetime plus broken-source controls, retain failures and report limitations. Stop at pushed reviewable branch. No automatic merge, deployment or next milestone.
