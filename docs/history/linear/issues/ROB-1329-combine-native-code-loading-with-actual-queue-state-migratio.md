# ROB-1329: Combine native code loading with actual queue-state migration

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1329/combine-native-code-loading-with-actual-queue-state-migration
> Status at export: Done
> Created: 2026-10-06
> Updated: 2026-10-06
> Completed: 2026-10-06
> Comments: 0

---

## Description

## Merged — 6 October 2026

Robert explicitly requested merge. Main fast-forwarded to 6de1d55f25a5451ef21b24afa6e8d92ee4dcc121; remote main verified. Experiment 6–8 manifests verified unchanged. Prior review below is historical. No content changes or deployment.

## Passed bounded experiment — In Review

Branch `codex/native-state-migration` pushed and remote verified at 6de1d55f25a5451ef21b24afa6e8d92ee4dcc121. [Full report](<https://github.com/robertguss/mo-v2/blob/6de1d55f25a5451ef21b24afa6e8d92ee4dcc121/experiments/08-native-migration/RESULT.md>). Three final no-retry trials preserved 291 jobs with five persistent clients per trial. Actual queue storage/operations reside in native modules: array v1 to linked v2, with accepted old jobs retaining old code. Queue and active code publish atomically only after exact row validation. Corrupt nonempty/empty migration refused; held/native-sleep migration expired around 200–201ms after staging. Old queue actually dequeued while stale migration still ran; newer v5/v7 committed before stale return, which was discarded and freed. All observed unloads, including shutdown, reported zero live native queue objects and removed images. Six compiled source controls caught.

Original overly broad stale-publication mutant failed the wrong earlier scenario; retained and narrowed to expired publication, without changing expected behavior. All three successful run series retained; only final run's 291 jobs claimed. Same-author verification, not independent acceptance. Prior files/locks/manifests unchanged. No native runtime defect was repaired in these runs.

Limits: trusted synchronous ABI, bounded queue on macOS; staging unbounded; admission/dequeue pause during migration; no arbitrary preemption, crash/external-effects guarantee, full native heap proof or production SLA. Forever-hung migration retains code/thread. Unrelated CLAUDE.md edit preserved. No merge/deployment/next milestone.

Robert authorized “sounds good. do it” after recommendation to combine native replacement and real state migration: preserve acknowledged jobs/payload/order, old jobs on old code, new jobs on new code, refuse corrupt/stalled migration, fence late returns, unload only after references end. Continue staged 200ms deadline and same-author verification; no separate builder.

Experimental choice: queue storage and operations live in trusted C modules (v1 array, later versions linked list), behind opaque owned handles. Rust pins module lifetimes and accepted job versions. During native migration, freeze admission/dequeue; in-flight work may finish. Copy canonical rows into a candidate outside lock; validate complete rows then atomically publish queue+active code. Timeout resumes old queue independently; stale candidate only disposes itself. Staging latency separate/unbounded. No permanent architecture, v1 import, deployment or merge.

Three fresh-process trials, bounded normal/corrupt/held/native-blocking migrations with nonempty queues, continued clients, exact ledgers and native lifetime/destructor checks. Actual broken-source controls, all failures retained. Stop at pushed reviewable branch and report. Prior experiment files/locks unchanged.
