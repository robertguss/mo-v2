# ROB-1141: Propose a copy-feedback experiment

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/issue/ROB-1141/propose-a-copy-feedback-experiment
> Status at export: Needs Input
> Created: 2026-10-02
> Updated: 2026-10-08
> Comments: 0

---

## Description

## Current status — preparation merged; participant trials not run

8 October 2026 reconciliation: the prepared package is merged in [f36d803](<https://github.com/robertguss/mo-v2/commit/f36d803dc78a8df5c5e8105bb0fc84a20bd4b2c2>), verified in origin/main. Earlier unmerged-package text below is superseded. Needs Input applies to the actual pilot: the detailed run protocol/session limit and real launcher isolation/timeout cleanup still require readiness and approval before participant sessions. Stage B continuation does not authorize this separate pilot. No claim that feedback improves agents has been established. Linux CI exclusion of experiment 12 is recorded at [8d7f0d9](<https://github.com/robertguss/mo-v2/commit/8d7f0d9>); it is not participant evidence.

## Historical preparation record

## Reconciled current status — 7 October 2026

Reviewed package remains [60448b8](<https://github.com/robertguss/mo-v2/commit/60448b8e2cd08d81d3b5a3ece2ed1e51be61983d>). Live remote branch tip is [8000416](<https://github.com/robertguss/mo-v2/commit/800041664cfc6845dfc296fbac69f50283dccadc>), whose only additional change deletes CLAUDE.md. Intent/authorization for that deletion is unestablished; this audit authorizes neither restoration nor merge. Package and proposed five-minute session-limit approval remain pending. Real launcher isolation and process-group cleanup must be implemented and verified before participant trials. No participant sessions ran; retain In Review.

Earlier records follow, preserved as history.

## Preparation complete — In Review

Preparation package pushed and remote verified at 60448b8e2cd08d81d3b5a3ece2ed1e51be61983d on `codex/copy-feedback-package`. [Readable report](<https://github.com/robertguss/mo-v2/blob/60448b8e2cd08d81d3b5a3ece2ed1e51be61983d/experiments/12-copy-feedback/RESULT.md>). Six tasks, exact feedback, 30-pair run order and proposed protocol frozen in PACKAGE_LOCK.json. Separate acceptance author froze checks at 44f05de before task source; all six baselines and two legal repairs passed 20 full-value cases each. Unique baseline updates each allocated 100,000 cells/3.2MB; legal repairs allocated zero; required old values preserved. Four negative controls caught (three compiled semantic/cost failures, one pre-build integrity rejection). Separate baseline profiling: 120 instrumented cases and 60 full-answer-checked uninstrumented timing runs. Independent review re-evaluated saved baseline/repair/timing outputs and ran controls plus all 30 delivery setups, 60 requests, six public checks and two forced cleanup paths. No blocking findings. Actual timing-run execution was by the parent, not independently repeated; checks/control/delivery authorship is separate. Large raw JSON archived losslessly with original hashes. Prior files/locks unchanged; unrelated CLAUDE.md edit excluded. No participant sessions, no merge.

Review gate: approve this concrete package and proposed five-minute limit per session before 30 gpt-6.1-sol/medium Codex-subscription trials. Actual launcher context isolation and process-group failure cleanup must be implemented and verified before any approved trials; current delivery utility launches no model. No paid fallback/top-up. Existing historical criteria remain unchanged.

Earlier preparation status below is historical.

## Preparation underway

Robert instructed “do it” after the recommendation to prepare the concrete copy-feedback pilot package for review, then run 30 sessions after review. This turn prepares six tasks, exact checks/allocation measurements/feedback messages, and deliberately wrong repairs. Branch codex/copy-feedback-package, experiment 12. No participant sessions start during preparation. Separate acceptance author owns frozen reference/checker files; task author owns task code and presentation. Existing helper/trials/locks unchanged, unrelated CLAUDE.md edit excluded. Deliver a pushed reviewable package and report; the five-minute trial cap and complete run protocol remain proposed until package approval. No automatic merge or model-trial execution.

## Model selected — GPT-6.1 Sol

Robert instructed “I would use gpt 6.1 sol instead”. Select gpt-6.1-sol through the existing Codex subscription for all 30 copy-feedback pilot sessions, superseding the agent-selected gpt-6-astra route. Keep the proposed medium reasoning setting unchanged and consistent across conditions. This changes the pilot's planned model only, not the user's global Codex configuration. Subscription-only access, no additional purchases/API fallback, frozen tasks/checks/interfaces before trials and pending execution approval remain unchanged. No trials have run.

Earlier Astra selection below is superseded.

## Subscription route settled — 6 October 2026

6 October 2026. Robert instructed: “you should use my codex subscription or claude code subscription.” Use the existing subscription-authenticated official clients for the approved copy-feedback pilot; a separately billed API budget is not the intended route. Read-only local checks found Codex CLI 0.160.1 signed in with ChatGPT, configured for gpt-6-astra at medium reasoning, and Claude Code 2.1.291 signed in through [claude.ai](<http://claude.ai>) with Max subscription. No model trial ran. Agent-selected implementation route is Codex with the existing gpt-6-astra/medium settings fixed across all 30 fresh sessions, to avoid changing provider/model between conditions; this is not a claim Robert explicitly named that model. No purchase, top-up, paid-overage opt-in or automatic API/provider fallback is authorized. At a subscription limit, stop and retain the incomplete trial evidence. Freeze exact tasks/checks and feedback interfaces before trials; experiment execution approval remains pending.

Remain Needs Input for exact task/check/interface acceptance and execution approval. The earlier request for a separate API spending cap is superseded by subscription access with no additional spending authorized. The five-minute per-trial limit remains a proposal until the run protocol is accepted.

## Pilot scope approved — 6 October 2026

6 October 2026. Robert said “i agree” to the proposed copy-feedback pilot scope: six tasks under each of five conditions, for 30 fresh sessions. Conditions are no feedback, static possible-copy notes automatically/on request, and measured actual-copy profiles automatically/on request. Tasks cover avoidable expensive copying, preservation of required older values, and harmless small copies. Success includes correct cost reductions, preservation of required values, and avoiding unnecessary edits. Model/configuration and provider spending limit must be settled before runs; exact tasks/checks and feedback interfaces must be frozen before agent work. This approves the pilot scope, not a selected model, spending amount, execution, or a Mo diagnostic feature.

Remain Needs Input for model/configuration, spending limit and exact acceptance preparation. No trials started. Earlier proposal status below is historical.

## Current status — 2026-10-06

Needs Input: a bounded proposal is prepared below. Execution still needs approval of the task/check set, fresh-session model and provider budget. No agent trials were started, and no existing lock or Mo diagnostic design changed.

## Proposed copy-feedback pilot

**Question.** Does information about copying help agents remove avoidable costs while preserving retained versions and leaving low-impact code alone? Keep possible-copy information separate from measured actual copies, and keep information type separate from how it is requested.

**Arms.** Compare five conditions: no feedback; static possible-copy notes shown automatically; the same notes on request; actual-copy profiles shown automatically; the same profiles on request. Freeze the text/tool interface before trials. A requested-feedback arm must really require a request, and a static note must never present a possible copy as a measured event.

**Tasks and checks.** Prepare six small Rust tasks from the accepted 3b helper: two with avoidable copying under unique ownership, two retaining an old version whose contents must remain valid, and two with small harmless copies. A different author fixes exact observable values, outside-holder preservation and task-specific allocation/time checks before implementation or agent work. Include known incorrect repairs: discard a required old version, mutate shared data, weaken a check, or hide copies outside the measured interval. They must be rejected. Use one fresh session per task/arm, for 30 pilot trials, without a conversation or answer shared across conditions.

**Tools and measurements.** Use the existing helper/reference instrumentation in isolated copies; freeze source, allocator, compiler, seeds and one approved model/configuration. Record completed correct repairs, regressions, unchanged harmless tasks, unnecessary edits, elapsed time, copy/allocation quantities, peak requested bytes and reported model usage when available. Run correctness and instrumentation checks separately from timing. Randomize/interleave arm order. Report individual outcomes; this small pilot cannot establish model-wide or Mo-wide superiority. It measures Rust tasks with a prototype feedback interface, not a shipped Mo compiler.

**Basis.** [3b's retained-version case](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/RESULT.md>) supplies one observed expensive-copy case. It does not prove feedback helps, and the full previous snapshot is a correctness obligation rather than waste to delete.

**Stop and recommendation.** Propose a five-minute cap per trial and an owner-approved provider spending cap before any real-model calls. Stop on ambiguous task expectations, shared-session contamination, instrumentation mismatch, violated spend limits or acceptance tampering; retain failures. Recommend this pilot before a larger study or diagnostic feature. Model agreement is not acceptance, and results must include failed/uncaught controls. Existing 3b/full3c contracts remain unchanged.

---

Compare no feedback, static possible-copy notes, and runtime actual-copy profiles; separately compare always shown versus on request. Test whether agents fix costly copying and leave harmless copying alone, using fresh sessions and checks approved before agents start. Repeated sharing in 3b supplies a case, not a proven solution. Copy feedback was explicitly kept out of 3b by D68 (approval of the 3b plan); it remains separate.

Stop condition: produce a plain-English proposal naming claims, comparison tools and limits, acceptance evidence, and an execution stop rule; wait for Robert’s approval. No implementation is authorized by migration.

Source: [https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/RESULT.md](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/experiments/03b-helper/RESULT.md>)
