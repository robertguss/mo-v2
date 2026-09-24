# Design Doc

AI-First Programming Language — Design Doc
Copied 2026-09-23 from https://claude.ai/code/artifact/46a80a81-a308-4775-8f04-7959bf8a5536

## Thesis

When agents write the code, a programming language should be designed first as a verification system. It should make it easy for AI to do the right thing, hard to do the wrong thing, and fast to discover when something went wrong.

Most languages were designed for human authors, trading strictness for ergonomics. AI-first flips that trade: annotation is cheap, ambiguity is expensive. Strictness that humans found too costly to write becomes affordable when agents pay the cost.

## Guiding principles

Five principles are settled. Every later design decision should serve them.

1. Humans own intent and decisions; agents own implementation. Humans may not write code, but they remain accountable for their programs. The language never takes humans out of important decisions.
2. Verification and fast feedback are the core purpose. The compiler and runtime give fast, precise, machine-readable feedback so an agent knows how to fix a mistake immediately.
3. Strict by default. Rules drawn from safety-critical engineering are enforced by the compiler, not left to style guides and code review.
4. Waivers are explicit, visible, and human-approved. Flexibility exists, but it is never the default. A waiver downgrades a guarantee (from proven, to runtime-checked, to trusted) rather than deleting it. The compiler can list every waiver in a project.
5. Bugs are inevitable; catch them early. The goal is not bug-free code but finding and fixing bugs quickly, as far from production as possible.

## Project scope

This is a research experiment, not a competitor to existing languages. The aim is to explore ideas, push into directions not yet tried, and see how far AI-built software can go.

* Roles: Robert designs; agents build the compiler and tooling.
* Scope: general purpose in the long run, but grown from concrete targets.
* First target: a simple CLI. A web server and REST API come later.
* Success criteria: still open. Candidates include deep personal understanding of language design, measurable evidence that agents ship fewer bugs in this language, and ideas strong enough to influence others.

## Traditions to draw on

Most of this wisdom was enforced by human discipline, not by languages. The AI-first move is to ask why each rule existed: rules for machine analyzability become compiler-enforced; rules for human cognition get reconsidered.

* NASA/JPL Power of Ten: bounded loops, no recursion, no dynamic allocation after startup, assertions, check every return value. Rethink: keep the rules that make programs provable; enforce them in the compiler.
* Tiger Style (TigerBeetle): assertions everywhere, explicit limits, static allocation, handle every error. Rethink: limits and assertions become language features.
* Negative space programming: assert what must never happen, not only what should. Rethink: first-class contracts, checked statically where possible.
* Design by Contract (Eiffel): preconditions, postconditions, invariants. Rethink: contracts are the primary verification surface.
* Ada/SPARK, Dafny: statically proven correctness. Rethink: make proof practical for everyday application code.
* Make illegal states unrepresentable; parse, don't validate: types rule out bad data by construction. Rethink: no null, sum types, exhaustive matching.
* Erlang, "let it crash": isolate failure and recover. Rethink: open question for the error model.

## Open questions

* Where does human intent live? Agents may write contracts freely, so the plain-language requirement they are checked against needs a home.
* How do we stop weak contracts and self-confirming tests? Candidates: mutation testing, property-based testing, independent agents.
* Type system: what is it responsible for?
* Error model: how do failures propagate and get handled?
* Effects: how do functions declare what they do to the outside world?
* Memory management: garbage collection or ownership?
* Concurrency model.
* Compilation target: interpreter first, then what?
* What does success look like?
