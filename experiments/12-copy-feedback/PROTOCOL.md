# Proposed pilot protocol

This is a review package, not an executed study. Six tasks times five conditions
means 30 sessions. Use Codex subscription authentication, gpt-6.1-sol, medium
reasoning, the same installed CLI version and compiler throughout. Stop at a
subscription limit; no paid API fallback, purchases or model switching.

## What the tasks ask

Every participant receives the same neutral instruction: review the operation at
its stated scale, improve avoidable work only when worthwhile, preserve the full
required outputs, and leave already appropriate code alone. Edit task.rs only.
Two large tasks have unnecessary live holders during an update; two large tasks
must retain an old version; two small tasks retain four/eight-element old versions.
These categories and reference repairs are withheld from participants. Each gets
only its own requirement, baseline task source, unchanged helper and common tools.
The task ID and profile size identify the case, not a preferred answer.

| Task | Required new value | Required previous value | Representative size |
|---|---|---|---:|
| U1 | every input number plus one | none | 100000 |
| U2 | input in reverse order | none | 100000 |
| R1 | every input number plus one | the entire original list | 100000 |
| R2 | running sums, signed remainder modulo 1000003 | the entire original list | 100000 |
| H1 | every input number plus one | the entire original list | 4 |
| H2 | input in reverse order | the entire original list | 8 |

## Conditions and information boundaries

1. No copying feedback.
2. Static possible-copy baseline note appended to initial prompt.
3. The identical static baseline note available only after an explicit request.
4. Measured actual-copy baseline profile appended to initial prompt.
5. The identical measured baseline profile available only after an explicit request.

Static notes are manually authored prototype diagnostics, not a compiler analysis.
They describe a possible copy at the baseline call site, never a measured event.
Measured profiles describe this pinned baseline and profile input only; they do
not pretend to reflect a later candidate. All profiles include size and scope.
User-level model requests for baseline feedback can repeat and are logged.
Automatic arms have the same request access after initial delivery, so availability
is the same within an information type and only initial delivery differs.
The no-feedback condition returns a neutral unavailable response to requests.
Common correctness checks expose values/preservation pass or failure, not allocator
counters or optimization success. Timing/profiling instruments and reference
repairs are kept outside the participant workspace. A participant can reason from
source or add local measurements in any arm; log such behavior as possible
contamination of the intended contrast, rather than concealing it.

Preparation validates the feedback delivery boundary with synthetic requests;
these are not model trials. The package provides a local feedback endpoint: no
stored feedback payload in on-request workspaces, no global history, task answers
or prior session transcripts exposed. A GET request is an explicit feedback
request regardless of whether made through the wrapper or another local client.

## Execution and timing proposal

Fresh conversation and disposable workspace per task/condition, no resume/fork.
No participant gets a solution or another condition's transcript. Use a fixed
randomized interleaving of all 30 pairs, retained before trials. Limit one trial
at a time to avoid timing interference and monitor subscription availability.

Five minutes of wall-clock agent time per trial, starting at process launch,
including model/tool activity and build time. On timeout terminate the process
group, preserve the last available task.rs and transcript, and score it as timed
out with final correctness recorded separately. An incomplete/failed trial stays
in the 30-row result; do not silently replace it or retry to improve a score.
Stop the study on acceptance tampering, setup ambiguity, instrumentation mismatch,
missing usage visibility needed for the chosen limit, or cross-session leakage.
This wall-clock proposal is an experiment limit, not an estimate of model cost.

Before actual runs, the launcher must pin the model/effort, disable unrelated
connectors and context loading, preserve subscription authentication without
putting credentials in artifacts, and prove isolation plus process-group cleanup
using a non-model forced-failure exercise. No model launcher is shipped or run
as part of this preparation; those operational checks precede any approved pilot.

## Measurements and scoring

Independent checks cover full transformed values, every required old value,
empty/negative/repeated/non-profile cases, allocation limits, and eventual cleanup.
Every task-code execution occurs inside the externally controlled counted interval.
No participant-reported count is trusted. Input building happens outside; output
checking/formatting happen after. There is no editable preparation hook.

Record semantics, operation allocations/bytes, live/peak requested bytes and ten
uninstrumented elapsed samples separately; report median and full spread. Timing
has no noisy pass/fail threshold. Operation allocations include temporary and
later-freed storage; net live growth alone cannot demonstrate no copying.
Peak requested bytes are not process RSS. Report allocator scope and pinned
helper layout. The helper allocates one block per copied list cell in these
baseline updates; only those bounded baseline facts justify a cell-copy count.
Do not label arbitrary candidate allocations as copies automatically.

Unique-task repairs must preserve all values and reach zero operation allocations.
Retained/harmless tasks may allocate at most one helper cell per element and must
keep the original version. Baselines that already satisfy requirements count as
successful preservation when left alone. Track byte-identical files, unnecessary
edits, and correctness regressions separately; an edit is not automatically a
bug. Manual necessity judgements need a written reason alongside objective data.
Usage (when reported) and elapsed time describe resource consumption, not a ranking
of language-writing ability. Six tasks and one model cannot establish statistical,
model-wide, language-wide or production superiority; report individual outcomes.

## Review boundary

Separate acceptance author freezes checks before task source is written. Parent
authors baselines and reference repairs, runs them against unchanged checks, and
retains source controls. Approval to prepare does not itself approve these exact
criteria. Final package fingerprints are proposed acceptance artifacts for Robert
to review before model trials. Prior experiment bytes/locks remain unchanged.
