# Mo v1 review — ideas, evidence, and experiments for v2 (5 October)

> Exported from Linear on 2026-10-11 (D199: Linear retired; tracking moved to Notion).
> Original: https://linear.app/robert-guss/document/mo-v1-review-ideas-evidence-and-experiments-for-v2-5-october-47ba263eb84e
> Created: 2026-10-06
> Updated: 2026-10-06
> Author: Robert Guss
> Attached to: the Mo v2 project

---

**Owner clarification after this review — 5 October:** [Current direction](<https://linear.app/robert-guss/document/mo-direction-agent-first-development-and-native-continuous-delivery-0766ce6f46cb>) supersedes this review's recommendations to preserve syntax for human enjoyment, require human reading of code/formal specifications, or defer hot reload as peripheral. Robert wants a language solely for agents, equal safety and resource control, evidence-led syntax, and hot reload/native continuous delivery as core requirements. Historical evidence below remains unchanged; proposed mechanisms are still unproved.

# Mo v1: what to preserve, what to question, and what to explore in v2

Review dated 5 October 2026. **Discussion material, not approved v2 requirements or an implementation plan.**

## Purpose and review boundary

Robert wants to build his own language and test ideas. Commercial adoption, replacing BEAM, or outperforming every existing language is not a condition for this work being worthwhile. Comparative experiments can answer specific questions without deciding whether Mo deserves to exist.

This is a broad inventory and evidence review. I inspected the original directions, specifications, research maps, implementation components, experiment reports and later research additions. I did not execute v1 tests, reproduce benchmarks, run fresh experiments, inspect every implementation line, or certify the runtime. Historical measurements below are repository-reported results, not newly reproduced findings. I did not read private history contents or sealed hidden suites.

V1 implementation snapshot: **d58f67cd9df14b6f67e63527451e41a796ce18d8**. Fetching origin found main at **ac733eb59a1a1d846cc129e8577528afac02a7f5**. Its two later commits add research and documentation; executable source is unchanged. I included those later notes as proposals. The working tree was left unchanged.

V2 snapshot: **e6a895c8ce2887d9bee6986819a779f8f74b5541**, already pulled and reviewed in this conversation. All 12 project issues and their comments were reviewed earlier. Linear is the current planning authority; historical repository research is not automatically a current decision. The retired Amp/Herdr workflow was not used.

CodeScent and codebase-memory tools were unavailable in this session. The installed ast-grep does not support Zig. I used repository maps, documentation links and targeted source inspection.

## My understanding of Mo

Mo is an attempt to make the important parts of a program explicit enough that a person can understand and approve them while agents do most implementation work.

The appealing combination is readable functional code, immutable values, explicit authority, distinguishable failures, executable promises, useful compiler feedback, and a runtime that can explain what happened. Recipes extend the same idea across projects: share a behavioral agreement, then own an implementation of it.

V1 explored most of that combination at once. V2 has started by making much narrower claims precise and proving them. I see v2 as a better experimental foundation for the original ambitions, not a commitment to reduce Mo permanently to memory management.

The human still needs a way to notice a missing requirement. A correct proof against the wrong promise cannot supply that requirement. Positive examples, forbidden outcomes and explicit uncertainty belong together.

## Broad inventory: all 43 original directions

The direction numbers preserve traceability. “Implemented” means implementation was found; it does not mean generally proved safe or production-ready.

| Original directions | Idea and v1 standing | My assessment for v2 |
| -- | -- | -- |
| 1, 2, 5 | Agents implement; humans read intent, promises and authority. An organizing premise, supported in part by regeneration exercises. | Preserve as a design goal. Test how accurately a person can understand and approve a change from the exposed information. |
| 3 | Source carries evidence. Generated verified lines and dependency-sensitive sidecars exist. | Preserve traceable evidence. Make its scope, freshness and incomplete outcomes explicit; a badge must not imply unrun proof. |
| 4 | Compiler-enforced laws. Bounds, deadline rules, exhaustiveness and shape restrictions were implemented; some numerical shape rules were reconsidered after friction. | Separate semantic guarantees from style preferences. A 70-line limit needs a different justification from checked overflow. |
| 6, 7, 9, 26, 27 | No OOP; pragmatic functional/procedural style; Ruby/Elixir-like readability; selected ideas from other languages. | Preserve what Robert enjoys. Taste does not need a benchmark to be legitimate. Test syntax usability separately from correctness claims. |
| 10, 11, 13, 22 | Immutable values, static boundaries, local var/inout, enums, traits, generics and refinements. Substantial implementation exists. | Preserve the direction. Specify aliasing, inference, refinement enforcement and generic behavior precisely before expanding. Do not equate checker implementation with a soundness proof. |
| 12, 14 | Concurrency at the edges; processes as identities and state machines. Implemented in interpreter and native runtimes. | Strong candidate, but introduce after the value/function core is coherent. Start with a small state machine and explicit observable transitions. |
| 15, 31 | Capabilities express authority; restrictions keep effects visible through calls and closures. Checker passes exist. | Preserve visible authority. Revisit the mechanism with v2's choices rather than importing v1's exact closure restrictions. |
| 16, 17 | Direct-style intercepted I/O; deadlines on waits. Implemented, including propagated deadlines. | Worth retaining as hypotheses about simplicity and bounded waiting. Specify what continues after timeout, who owns cleanup, and what completion means. |
| 18, 33 | Expected errors are values; bugs crash processes. Mailboxes are bounded and overflow crashes the sender. Implemented policy. | Preserve the error/defect distinction. Treat sender-crash overload policy as an open design choice requiring workloads, not an inevitable consequence of bounds. |
| 19, 20 | Human-approved never clauses; human attention when the agreement changes. Clauses exist; the full approval boundary was partly workflow. | Preserve readable forbidden outcomes. Add positive obligations and an independently protected change boundary. Merely retaining a never clause does not preserve its intended meaning. |
| 21 | Crash → agent diagnosis → repair without human intervention unless the agreement changes. | A valuable long-term experiment, not an established autonomous production capability. Begin with diagnosis and proposed repair under a fixed specification. |
| 23 | Compile/feedback latency matters. Measured on particular programs. | Preserve fast feedback as a product requirement. Measure time to a correct change, including misleading diagnostics and repeated failed attempts. |
| 24, 25, 36 | Interpreter/reference runtime plus C-via-Zig native compilation. Both exist; framing changed toward VM-first. | Preserve an executable reference and cross-backend checks as methods. Keep implementation technology open. Two matching backends can share a semantic mistake. |
| 28, 41, 42 | Pre-registered measurements, smaller-model trials and an Elixir comparator. Experiments were conducted with important caveats. | Preserve disciplined learning. Comparators answer bounded questions; results do not veto the personal language project. |
| 29 | Declaration IDs and semantic edits. Sidecar IDs/hashes exist; proposed edit/rename/insert/delete CLI commands do not. | An attractive small tooling experiment. Test wrong-target prevention, stale-edit rejection and identity across renames. |
| 30, 34, 35 | Explicit package authority; bricks, owned-source kits and spec recipes. Recipe conformance exists; the full registry/trust ecosystem does not. | Preserve recipes as an experiment in specification and ownership. Do not assume maintenance becomes negligible or regeneration solves supply-chain security. |
| 32 | Optional proof tool distinct from ordinary checks. V1 prints proven: not run; the proposed prover is absent. | V2 already explores a stronger formal foundation. Keep theorem scope explicit; runtime code is not verified merely because a model is. |
| 37, 40 | Queryable runtime and structured events. Runtime capability, HTTP/JSON surface and event ring exist. | High-value candidate. Distinguish an actual runtime API from a native MCP implementation, and bounded events from a complete history. |
| 38, 39 | Production time travel and hot code reload. Seeded simulation provides foundations, but these broader capabilities remain proposals. | Preserve the questions, defer the infrastructure. Replay needs captured nondeterminism; reload needs state migration and in-flight-call rules. |
| 43 | Bodies as cache, sampling, erosion, incident diagnosis and feedback measurements. Several ran; the entire package was not completed as originally envisioned. | Keep these as separate hypotheses with separate outcomes. Their evidence does not establish a single sweeping “agent-native” advantage. |

Primary inventory: [43 directions](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/directions/>); [current premise](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/spec/design-v0/01-premise.md>); [semantics](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/spec/design-v0/03-semantics.md>); [runtime proposals](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/deep-dives/agent-native-runtime-features.md>).

## What the strongest evidence actually says

### 1. Regeneration worked when the behavioral assets stayed

The bodies-as-cache record reports 12 of 12 regenerations passing their retained oracles across six programs. The retained material included tests, contracts, signatures, examples/transcripts and surrounding program context. This is meaningful evidence that implementations can be replaceable when behavioral assets are rich enough.

The stronger logstat run removed tests too. It passed its own tests and all eight transcripts, but passed only 23 of the original 31 tests when those were restored. Missing requirements included output formatting and input-boundary rules.

**My reading:** the promising asset is the specification together with its examples and tests. V1 did not establish that brief intent and signatures are sufficient, that arbitrary implementations are equivalent, or that regenerating packages eliminates security review. The reported “completeness” is coverage under named oracles, not universal semantic completeness.

Source: [Bodies as cache: setup, results and stronger control](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/plans/bodies-as-cache.md>).

### 2. Agreement did not replace an oracle

Five regenerated queue modules agreed across 132,000 operations in the reported sampling run. The normal API driver found no defect or specification hole. A directed reconstruction case, informed by the agents' lists of unspecified decisions, found a disagreement about an impossible persisted state.

**My reading:** asking agents to identify unspecified choices was more productive here than generating more ordinary API sequences. Agreement is useful for detecting discrepancies, but correlated assumptions and unreachable input regions remain. A majority cannot decide the intended behavior.

Source: [Sampling as verification](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/plans/sampling-as-verification.md>).

### 3. The “laws prevent maintenance erosion” claim remained unestablished

The erosion record reaches six generations, not the proposed ten. Its specific prediction that a never or invariant would trip on a maintainer's wrong edit failed six times. A Mo-only defect was introduced in generation five and repaired in generation six.

Generation six also carries substantive corrections: a real earlier Mo failure means “zero under every earlier suite” was not met; a Python fixture had failed to construct the intended illegal input; a shared queue-listing discrepancy remained disputed. Sessions were interrupted and moved between machines, and the sealed new suite was invalid before a corrected version was used.

**My reading:** this is evidence against claiming that the tested laws had already delivered their predicted maintenance advantage. It is not proof that contracts are useless. A contract may detect a bad persisted state without having prevented the edit that created it. The corrections must outrank the original celebratory table.

Source: [Erosion round, including generation-six corrections](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/plans/erosion-round.md>).

### 4. Diagnostics helped agents compile; that did not ensure correct behavior

The small-model record reports 21 of 23 diagnostic loops fixed on the first attempt, yet some resulting programs still failed behavioral checks. The larger comparison was also incomplete in places, including the planned Opus-in-Pi baseline.

**My reading:** compiler-as-teacher is promising, but compiler acceptance and task success need separate measures. A useful future comparison would isolate diagnostic quality while holding the task and model conditions fixed.

Source: [Small-model direction and reported outcome](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/directions/d41-small-model-round.md>).

### 5. Real use found failures the corpus missed

The September 22 project account records synthetic Linux acceptance followed by failures on a real history corpus: native JSON decoding used stale pointers beyond a container threshold; interpreter temporaries accumulated; an interrupted search incorrectly reported no matches. The record reports subsequent fixes and Darwin verification, with Linux replay of that final state still absent.

**My reading:** keep small useful programs in the loop. Memory pressure, realistic nesting, long-lived ownership and truthful incomplete outcomes are part of language usability. Historical failures are not current unfixed findings; the record says these were repaired.

Source: [September 22 project account](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/state-of-the-project.md>); [current v1 handoff](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/HANDOFF.md>).

### 6. Benchmark semantics mattered as much as numbers

Generation six identified differing macOS flush guarantees in the compared programs. It also disclosed machine load, session interruptions and a performance task whose brief revealed the supposed discovery target.

**My reading:** retain performance experiments, but compare the same promises and distinguish “fixed when told the cause” from “discovered the cause.” There is no defensible general Mo-versus-Go-versus-Elixir ranking from these rows.

Source: [Erosion performance and interpretation corrections](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/mo-wiki/plans/erosion-round.md>).

## Implementation details that change the interpretation

* **V1 reuse was real but not v2's proof.** The move pass identifies last reads and overwrites, while backends use ownership claims to decide copying. Its region allocator compacts live values and explicitly records fallback allocations that survive until run end. This is a different implementation and assurance story from v2's holder-counting experiment. Sources: [moves.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/moves.zig>), [region.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/region.zig>).
* **Authority claims have defined limits.** The capability pass documents bounded static flow analysis; it does not chase every collection or function-return flow at that tier. Early direction 31 even permits a capability-capturing callback example, whereas the later checker explicitly rejects authority capture. Preserve the intention, not contradictory historical examples. Source: [caps.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/caps.zig>).
* **Evidence output is not a proof receipt.** The renderer always prints proven: not run. It distinguishes simulation not run, but its own documented policy permits tests that pass only without faults without holding the verification line back. Hash-linked sidecars help freshness; they do not themselves protect the verifier from an authorized writer changing both implementation and evidence. Sources: [verified.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/verified.zig>), [ids.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/ids.zig>).
* **Recipes have an actual conformance mechanism.** It checks signatures/contracts and runs the recipe's tests and never blocks against the implementation. Matching checked clauses and passing finite tests are valuable without being a proof of all behavior. Source: [recipe.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/recipe.zig>).
* **Observation is implemented; full historical reconstruction is not.** The runtime surface offers process/state/event/crash/source/memory queries and controlled actions. Events are bounded. Seeded simulation varies schedules and fixture faults; it does not establish production replay of every external effect. Sources: [surface.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/surface.zig>), [events.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/events.zig>), [sim.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/sim.zig>).
* **The CLI is narrower than the original tool vision.** It exposes check/test/run/build/fmt/fix, not the proposed semantic-edit or prove commands. It also permits disabling native contracts for measurement, contrary to reading every early “no escape” phrase as an unconditional shipped rule. Source: [main.zig](<https://github.com/robertguss/mo-lang/blob/d58f67cd9df14b6f67e63527451e41a796ce18d8/toolchain/src/main.zig>).

## Later research worth carrying forward as questions

The September 23–October 3 additions emphasize preserving distinctions: retained bytes versus logical output size; streamed input versus a stable snapshot; incomplete UTF-8 versus invalid input; duplicate-key policy versus parser agreement; resource exhaustion versus a completed miss; accepted writes versus durable writes; cancellation request versus stopped work; startup acknowledgment versus recovery readiness.

These are research recommendations, not implemented improvements or newly reproduced defects. Their strongest common contribution is a design principle: **an operation's result should say exactly what was established, including partial completion.** That is relevant to both Mo programs and Mo's verifier.

Sources: [weekly synthesis](<https://github.com/robertguss/mo-lang/blob/ac733eb59a1a1d846cc129e8577528afac02a7f5/mo-wiki/research/concepts/hermes-weekly-2026-09-28.md>), [cancellation note](<https://github.com/robertguss/mo-lang/blob/ac733eb59a1a1d846cc129e8577528afac02a7f5/mo-wiki/research/concepts/hermes-daily-2026-10-02.md>), [recovery readiness note](<https://github.com/robertguss/mo-lang/blob/ac733eb59a1a1d846cc129e8577528afac02a7f5/mo-wiki/research/concepts/hermes-daily-2026-10-03.md>).

## How I would carry this into v2

**Preserve now as design intentions:** enjoyable syntax; functions and immutable values; explicit authority; expected errors distinct from defects; readable promises with positive examples; honest evidence; fast actionable feedback; learning through real programs.

**Keep as focused experiments:** bodies regenerated from a protected behavioral specification; recipes with independent conformance checks; declaration-addressed edits; diagnostics that improve behavioral success; readable memory-copy explanations; bounded runtime inspection.

**Keep open rather than importing wholesale:** numerical shape laws, sender-crash overload, closure restrictions, process-only identity, region versus holder-counted allocation, production replay, hot reload and fully autonomous repair.

**Avoid making prerequisites for the language:** a complete first-party ecosystem, custom security infrastructure, a package registry, a large coding harness, or a proof of universal superiority. Each can still be explored for its own learning value.

V2's completed finite-language trial proves four specified properties for its model: completion, matching answers, snapshot visibility preservation for the specified holders, and final cleanup. It does not yet prove calls/recursion, an allocation-demand checker, native execution or performance. [ROB-1138](https://linear.app/robert-guss/issue/ROB-1138/decide-the-path-from-the-trial-to-full-experiment-3c) and [ROB-1139](https://linear.app/robert-guss/issue/ROB-1139/full-3c-gated-conditional-and-unconditional-demand-checker-experiment) concern the calls/recursion extension; the full3c draft remains a proposal. The queued copy-feedback, numbers, sequences, holder-layout and verification follow-ups are compatible with this inventory, but their existence does not ratify every v1 direction.

V2 already describes itself as one language; its older two-language diagram is explicitly superseded. The useful enduring separation is between what a human approves and how an agent implements it.

## Candidate experiments for discussion — none run or approved here

| Question | Small experiment | What would count against the idea? |
| -- | -- | -- |
| Can the visible agreement carry the important behavior? | One small module, reviewed promises/examples, independently prepared behavioral cases; regenerate bodies and compare. Include a controlled removal of an important requirement. | Regenerations pass visible checks while missing important behavior; the missing requirement is hard for Robert to see. |
| Does negative space add useful information? | Same task with positive requirements alone, then with selected never clauses; distinguish duplicate catches, unique catches and false alarms. | Clauses mostly restate tests, block valid work, or fail to express the mistakes we care about. |
| Can owned recipes remain manageable? | A pure recipe, several implementations, then one specification update; retain independent checks and count repair work. | Compatibility and maintenance work grows faster than the claimed benefit, or shared ambiguity produces shared defects. |
| Can semantic edits be simpler and safer? | Tiny declaration-edit prototype with parse-before-write and expected-hash checking. Exercise stale edits, duplicate names and renames. | IDs drift, edits target the wrong declaration, or the interface creates more repair work than text editing. |
| Can effects remain obvious without awkward code? | A small file-processing program with a callback and narrowed authority; inspect both allowed operations and refused attempts. | Authority leaks through values, or ordinary composition requires excessive process/capability plumbing. |
| Does runtime evidence improve diagnosis? | One planted process failure, fixed expected diagnosis, bounded events versus ordinary logs; assess diagnosis before repair. | More telemetry does not improve the answer, misses the crucial external event, or exposes excessive state. |
| Does the memory model remain understandable through calls? | Continue the already proposed full3c specification work; keep proof obligations and programmer-facing copy explanations distinct. | Local reasoning breaks down, suspended holders become observable, or useful code requires unpredictable copies. |

My recommended discussion starting point is the human-readable agreement. It connects the original spec-altitude, never, recipe and regeneration ideas, and asks what Robert actually wants to understand and approve. The memory work can continue as its own precise foundation without swallowing the rest of the language's purpose.
