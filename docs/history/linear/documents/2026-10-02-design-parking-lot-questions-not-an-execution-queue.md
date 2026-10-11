# Design parking lot — questions, not an execution queue

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/design-parking-lot-questions-not-an-execution-queue-86faf283b14a
> Created: 2026-10-02
> Updated: 2026-10-06
> Author: Robert Guss
> Attached to: the Mo v2 project

---

## Direction update — 5 October 2026

[Agent-first development and native continuous delivery](<https://linear.app/robert-guss/document/mo-direction-agent-first-development-and-native-continuous-delivery-0766ce6f46cb>) records Robert’s new priorities and separates them from Codex’s proposed mechanisms. Hot reload and safe continuous evolution are core requirements, not merely parked optional features. Syntax can change substantially based on evidence. Humans do not write or read code; safety and resource control matter equally, with Elm-inspired agent diagnostics. These priorities do not select the next executable experiment.

The document preserves questions about migration, version compatibility, in-flight work, criteria, shadow effects, bounded pauses and recovery. Its continuously running service experiment is a candidate, not approved execution. Earlier research below remains historical proposal material where it conflicts with live decisions D109–D112.

Earlier research and recommendations are proposals unless a specific recorded decision approves them. Preserve options rather than turn each paragraph into a task. Work is chosen one bounded experiment at a time by Robert.

## Foundations and decision map

[Original nine-question map](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/DECISION-MAP.md>): guarantees; what Robert reads; translating plain-English intent to checked statements; Lean’s role; concurrency/TLA+; testing Mo’s premise; first milestone; what comes from v1; how work is done. This map is historical, not a current ordered backlog. Its recommendations do not override later decisions.

## Seven research areas

* [Spec layer](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture/1-spec-layer>): core semantics, human/agent workflow, intent, promises, examples and the specification gap.
* [Code layer](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture/2-code-layer>): syntax, data and functions; exact language surface deferred.
* [Feedback loop](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture/3-feedback-loop>): toolchain/agent interface, diagnostics, verification feedback; judge reaching correct programs, not token cost.
* [Built-in verification](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture/4-built-in-verification>): which methods and when, with independently approved expectations.
* [Effects and authority](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture/5-effects-and-authority>): capabilities, standard library, interop.
* [Running programs](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture/6-running-programs>): runtime, concurrency, replay, long-lived state, pools/regions.
* [Ecosystem](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture/7-ecosystem>): packages, dependency/supply-chain questions, deferred.
* [Foundations](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/big-picture/foundations.md>). The old two-language picture is superseded by D34 (Mo is one language), not by an agent’s rewrite.

## Design choices

[All eleven areas and their alternative-specific notes](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/design-choices>). The first nine have recorded high-level decisions; their implementation details are not automatically settled. Still open: limited shared abilities, pools and long-lived state, exact syntax and promise notation, Mo’s evaluation order, resource-release timing visible to programs, runtime versus compiler reuse pairing. Trial-specific choices settle only the trial.

Number representation is ROB-1142; sequence storage/update is ROB-1143; copy feedback ROB-1141; header/weak holders ROB-1144. Experiment 2 candidates ROB-1145; conditional/post-3c candidates ROB-1146. These are proposals in Backlog, not Ready.

## Implementation and evaluation

[Implementation research](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/parking-lot/implementation.md>): interpreter/compiler order; LLVM/C/WebAssembly/TypeScript targets; compiler implementation language; golden corpus.
[Evaluation research](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/parking-lot/the-experiment.md>): tasks, iterations to correct programs, escaped bugs, suitable comparisons and preapproved success criteria.
[Neighbouring languages](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/design-choices/neighbouring-languages>), [primer](<https://github.com/robertguss/mo-v2/blob/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/language-design-primer.md>), [glossary](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/documents/glossary>), and [Quint/tools](<https://github.com/robertguss/mo-v2/tree/13ca4c99334c3c6fa0ac157a6a5165b0882d7eb4/docs/research/tools>) are references, not adopted requirements.

## v1

Keep/defer/drop suggestions remain suggestions. Nothing transfers without Robert’s decision. The old project’s claims and numeric comparisons are not fresh verification. No crypto/TLS/process expansion is authorized.

Stop condition for activating any item: a bounded proposal identifies claims, appropriate tools, alternatives, evidence for/against, limits and stopping rule; Robert approves before execution.
