# Mo direction — agent-first development and native continuous delivery

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/mo-direction-agent-first-development-and-native-continuous-delivery-0766ce6f46cb
> Created: 2026-10-06
> Updated: 2026-10-06
> Author: Robert Guss
> Attached to: the Mo v2 project

---

# Agent-first Mo and continuous evolution

Recorded 5 October 2026 from Robert's discussion in the current Codex conversation, at his request to update the Linear project.

## Confirmed direction

**Mo is designed solely for agents to write, debug, refactor, maintain and operate code. Humans no longer write or read code.** Robert communicates intent, desired outcomes and tradeoffs in conversation; agent-facing source and formal specifications are not a required human interface.

Mo draws heavily from **BEAM/Elixir and Rust**. Robert values Rust's safety and strong types and its precise memory/performance control **equally**. Elm supplies an inspiration for helpful diagnostics: Mo should guide agents as deliberately as Elm guides human programmers.

**Syntax is evidence-led.** Ruby/Elixir-like appearance may change substantially if evidence shows agents work more reliably with another form. Familiar syntax is an option to evaluate, not a fixed aesthetic constraint.

**Hot code reloading is paramount.** Robert describes software as increasingly like an organism: agents continually modify it, including in production. Continued safe evolution must shape the language and runtime from the beginning.

**Continuous delivery is a native language/runtime ambition.** Robert wants to eliminate conventional CD as he knows it by having Mo support the transition from a candidate change to running production behavior. Agents may deploy intentional behavioral changes autonomously when the approved criteria have been met. This is a requirement for the future Mo system, not permission for this documentation task to deploy anything.

Purpose remains learning through building Robert's own language and testing ideas; adoption or universal superiority over existing languages is not a prerequisite.

## Working assumption, tentatively accepted

A brief, bounded pause of an individual process during migration may be acceptable if its connections and queued work survive and the overall service remains available. Robert answered “I think so.” This is provisional, not a fixed latency budget or an accepted implementation.

Still to determine: pause duration, reaching a safe boundary, backlog limits during the pause, behavior when the budget expires, long-lived operations and coordinated changes.

## Robert's words and attribution

* “Mo is heavily inspired by the beam and elixir and also rust. I want to combine the best features of these languages together as much as possible.”
* Asked whether Rust's appeal is safety/strong types or memory/performance control: “Equally both.”
* “Everything in this language is solely focused and designed on agents writing, debugging, refactorint, etc the code. Humans no longer write or read code.”
* Asked about substantially changing syntax when evidence supports it: “Change is substantially if the evidence shows it.”
* “hot code reloading is paramount” and “software is more like an organism”.
* Asked whether a bounded individual-process pause preserving connections and work is acceptable: “I think so”.
* Asked whether agents may deploy behavioral changes autonomously within approved goals: “Yes if the criteria has been met.”
* “Basically I am trying to get around and frankly eliminate CD as we know it today and have the language support continuous delivery”.
* Requested this record: “Pleaese the linear project with these idead”.

These excerpts are the approval provenance available in this conversation; no public conversation-share link was generated. The following mechanisms were proposed by Codex and have not been individually approved or demonstrated.

## Proposed language shape

* Ordinary computation uses composable functions and value semantics; processes supply independent lifetimes, state, concurrency and recovery.
* Typed messages, explicit state transitions, expected errors as values and supervised defects.
* Visible capabilities constrain authority; resource ownership and transfer rules explain memory and external-resource lifetimes.
* Compiler feedback joins type, ownership, effect, behavioral and resource obligations. A repair that introduces copying or allocation discloses that consequence.
* Queryable declarations, dependency context and semantic edits support agent refactoring with stale-edit protection.
* Runtime evidence uses the same declarations and promises as compiler diagnostics, so an agent can connect failures with the responsible version and operation.
* Evaluation measures correct changes, escaped regressions, repair attempts, context consumed and performance preservation. Compact syntax or JSON diagnostics alone do not establish agent effectiveness.

Exact syntax, type/effect mechanisms, allocation strategy, scheduler and runtime architecture remain research questions. This document does not select a backend or import v1 implementations.

## Proposed continuous-delivery model

A program includes the rules under which it may change while running. A candidate update carries more than replacement code:

1. Intentional behavior changes and existing promises to preserve.
2. State transformation and its obligations.
3. Message, dependency and persistent-data compatibility.
4. Permitted transition boundaries and resource budgets.
5. Required evidence and recovery conditions.

### Three kinds of criteria

| Kind | Illustrative obligations |
| -- | -- |
| Language | Type/ownership compatibility, valid state transformation, safe version retirement, bounded migration |
| Application | Preserve acknowledged jobs, authorization boundaries, active leases and live sessions |
| Operations | Pause and memory budgets, latency limits, observation windows, rollout scope and failure response |

These are proposed categories, not a finalized acceptance specification. Criteria themselves need an approval policy; an agent must not obtain acceptance by quietly weakening the definition of success.

### Candidate lifecycle

**Prepare → validate evidence → exercise in isolation → reach a safe boundary → migrate → activate within limited scope → observe → expand or recover.**

There are two distinct decisions: sufficient evidence to permit a transition, and sufficient observed behavior to continue or expand it. Types and proofs can establish scoped properties; some operating criteria require runtime observation. A finite observation window does not prove the absence of future regressions.

A proposed safe boundary is between process operations, with a consistent code/dependency version during each operation. A process suspended on I/O is still mid-operation. Queued messages, timers, deferred replies, callbacks, connections and other resources must be covered. Coordinated process changes need compatible intermediate states or an explicit protocol; local atomicity does not imply distributed atomicity.

The transition must have a time/resource budget and a defined refusal outcome when the safe boundary cannot be reached. Incoming work remains bounded during migration.

### Migration as a checked program

For a queue representation change, candidate obligations include preserving every pending job exactly once, retaining active lease deadlines, preventing completed jobs from becoming runnable, and changing ordering only where intended. Migration must also respect its resource budget.

Types alone do not establish these behavioral obligations. Appropriate proofs, tests, simulation and measurements need to be selected for the exact claim.

### Shadow execution and effects

A proposed candidate may consume recorded or selected live inputs without authority to perform real external effects. The runtime intercepts proposed writes/messages for comparison with the intended change. Capabilities could enforce this separation.

Shadow state and captured nondeterminism must be adequate for the comparison. A candidate diverging intentionally from the old implementation is not automatically wrong, and shadow agreement is not a universal correctness proof.

### Recovery with explicit limits

| Recovery category | Meaning |
| -- | -- |
| Abort before activation | Candidate preparation/migration can be abandoned while retaining valid old execution |
| Compatible rollback | Old code can consume state produced by the new version |
| Compensation | Specific completed external effects require corrective operations |
| Forward recovery | Returning to the old version is invalid; repair must continue forward |

Replacing code does not undo payments, sent messages or database writes. Restoring an old snapshot must not silently discard legitimate intervening work. Database and protocol evolution need explicit adapters and guarantees.

### Ownership and performance

Version retirement must account for active frames, callbacks, state layouts and resources still referring to old code or representations. This connects to v2's question of when an old value is no longer observable, but the current trial does not prove hot-update safety.

Reloadable boundaries may require indirection, tracking and temporary coexistence of versions/state. Their costs should be explicit and measured; computation inside a component should remain eligible for optimization.

## Candidate first experiment — proposal only

A small continuously running service changes its internal state representation while requests remain active.

Potential acceptance cases: preserve live connections and acknowledged work; preserve queued requests and leases; reject a deliberately incorrect migration; refuse an update that cannot reach its boundary within budget; survive failure during migration; explicitly classify recovery after candidate effects.

Select the workload, observable promises, controls, budgets and stop conditions before execution. No experiment, production update, new proof interval or implementation has been started by recording this discussion. Existing full3c scope and locks remain unchanged; next-work sequencing needs an explicit decision.

## Supersession and related records

* This direction supersedes the current prose that treats Ruby/Elixir-like appearance as fixed.
* It supersedes Codex's earlier recommendation to defer hot reload as peripheral infrastructure. Hot reload and continuous evolution are core design requirements; implementation order remains open.
* Humans are not required to read code or formal specification syntax. Plain-language intent, examples and evidence remain the human interface.
* Prior v1 review findings and historical experiments retain their evidence status; these priorities do not establish that the proposed mechanisms work.
* Robert retired the Amp/Herdr workflow in this conversation and requested that work happen here in Codex. Historical trial attribution, accepted proof results and locked scientific criteria remain intact.

Related: [v1 review](<https://linear.app/robert-guss/document/mo-v1-review-ideas-evidence-and-experiments-for-v2-5-october-47ba263eb84e>), [live decision register](<https://linear.app/robert-guss/document/decisions-and-approvals-live-register-360d6e9c3d64>), [full3c transition](<https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c>).

## Research references

Background, not evidence that Mo has implemented these capabilities:

* [Elm: Compiler Errors for Humans](<https://elm-lang.org/news/compiler-errors-for-humans>) and [Compilers as Assistants](<https://elm-lang.org/news/compilers-as-assistants>): contextual guidance and useful diagnostics.
* [Rust ownership](<https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html>): checked ownership and resource lifetime inspiration.
* [Erlang code loading](<https://www.erlang.org/doc/system/code_loading.html>): old/current versions.
* [OTP release handling](<https://www.erlang.org/doc/system/release_handling.html>): coordinated updates and state transformation.
* [Dynamic software updating research](<https://www.cs.umd.edu/~mwh/papers/dyn_update.pdf>): precedent for safe update points and state transformation.

Novelty of the proposed combination remains to be investigated; no claim that hot reload or state migration themselves are new.
