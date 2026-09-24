# Big Picture

# The big picture

Working picture of Mo v2, accepted by Robert on 23 Sep 2026 (D20). It changes only by decision.

**Update, 23 Sep 2026 (D34, D35):** Mo is a single programming language with a familiar Ruby/Elixir-like syntax that does everything in the Design choices (D24–D33) through its compiler and runtime. The two-languages picture below is superseded in that respect. Syntax, the language surface and how promises are written are deferred; next is small programs and experiments to verify the D24–D33 ideas.

**Mo is two languages joined by a machine:** a small *spec language* Robert reads and approves, and a *code language* agents write, with a checker proving or testing that the code keeps the spec.

```
   ROBERT                       THE MACHINE                     AGENTS
 ┌──────────────┐          ┌────────────────────┐         ┌──────────────┐
 │ Spec layer   │  ──────▶ │ Checker + verifier │ ◀────── │ Code layer   │
 │ intent,      │          │ proofs, tests,     │         │ functions,   │
 │ promises,    │ ◀──────  │ simulation         │ ──────▶ │ data, effects│
 │ examples     │ evidence └────────────────────┘ feedback└──────────────┘
 └──────────────┘
```

## The seven areas

1. **Spec layer (what Robert reads).** Intent, promises and examples in near-English. A proof is only as good as its spec (Experiments 1 and 2).
2. **Code layer (what agents write).** Data, functions, errors. Robert's v1 picks live here: Ruby's look, no OOP, immutable by default, errors as values, no nulls.
3. **Feedback loop (how agents learn Mo).** Instant, precise explanations of what's wrong and how to fix it, so agents that have never seen Mo reach correct programs (D13).
4. **Built-in verification (how the link is checked).** Which methods the language provides natively, and when each runs.
5. **Effects and authority (what code may touch).** Capabilities: code uses only what it is handed, so specs can make promises about side effects.
6. **Running programs.** Runtime, concurrency, exact replay of any run.
7. **Ecosystem.** Packages, dependencies, supply-chain safety. Last.

## Evidence so far

|Area|Experiment|What it showed|:(table="column-widths:-1,0,0,0;justification:default"):
|---|---|---|
| 1, 4 | 1: tiny safe checker       | Lean can prove a checker safe, but a safety promise alone lets a checker that rejects everything pass. Robert's examples close the gap.             |
| 1, 4 | 2: withdraw, seven methods | A proof against a complete spec caught all 10 planted bugs. Every testing method missed the rare-input bugs. A proof is only as strong as its spec. |

## Contents

* [1 Spec layer](1-spec-layer/README.md)
* [2 Code layer](2-code-layer/README.md)
* [3 Feedback loop](3-feedback-loop/README.md)
* [4 Built-in verification](4-built-in-verification/README.md)
* [5 Effects and authority](5-effects-and-authority/README.md)
* [6 Running programs](6-running-programs/README.md)
* [7 Ecosystem](7-ecosystem/README.md)
* [Foundations](foundations.md)
