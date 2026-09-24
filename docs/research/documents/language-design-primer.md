# Language design primer

Learning notes from a conversation with Robert on 23 Sep 2026. These are explanations, not decisions. Decisions are in DECISIONS.md.

## Two halves of a language
* **Design:** what the language is: the rules a person (or agent) learns in order to write it.
* **Implementation:** the program that makes those rules do something on a computer.
* Design can be worked out without knowing the implementation. For Mo, the design is Robert's part (D5, D6).

## The design questions every language answers
* **Syntax:** what valid writing looks like (spelling and grammar).
* **Semantics:** what valid writing means when it runs. Most hard design decisions are here.
* **Values and types:** what kinds of things exist (numbers, text, true/false, lists, records).
* **Names and scope:** how things get names, and where a name can be seen.
* **Control flow:** how a program decides and repeats.
* **Functions:** how reusable logic is packaged.
* **Errors:** what happens when something goes wrong, and when you find out.
* **Mutability:** whether things can change after they are made.
* **Modules:** how a big program is split into parts.
* **Standard library:** what comes built in.

## The big tradeoffs
* **When are mistakes caught?** Before running (static checking) or while running (dynamic).
* **Does the language guess what you meant?** For example, whether "5" + 3 quietly becomes "53", or is refused.
* **Can things change?** Mutable by default, or immutable by default.
* **How is "nothing" represented?** A null that can hide anywhere, or a "might be missing" case that must be handled.
* **How do errors work?** Thrown and caught far away, or returned as ordinary results the caller must handle.
* **What can code do behind your back?** Any function may touch the outside world, or side effects are tracked.
* **How is a program organised?** Step-by-step instructions, transforming values, objects, or describing the result.
* **Who cleans up memory?** Automatic, manual, or rules the checker enforces.
* **Syntax comes last.** Settle meaning first, then choose a look that makes it clear.

## Principles designers learn the hard way
* Every feature has a cost, and features interact.
* Restrictions are features: what a language forbids is what lets it make guarantees.
* A small core with a rich library.
* Error messages are part of the design.

## How designers work
* Start from purpose: who writes programs in the language, and what are they for? Every other choice follows.
* Write the example programs you wish you could write, then ask what rules make them valid, and what those rules also allow by accident.
* The examples become the spec, and later the tests.

## The implementation pipeline (for reference)
* Lexer: splits text into words (tokens).
* Parser: checks the grammar and builds a tree of the program (the AST).
* Checker: asks whether the program makes sense (type checking lives here).
* Execution: an interpreter runs the tree directly; a compiler translates it to run later.
* Runtime: what must exist while the program runs (memory, built-ins, error reporting).
* Learning resource: Crafting Interpreters by Robert Nystrom (craftinginterpreters.com).

## Where Mo already stands on the purpose question
* Who writes Mo: AI agents, not humans (D2). Robert reads and approves specs, never code (D5).
* What Mo is for: reliable, safe software; verification is the central problem (D2). General purpose, no single domain (D4).
* Guiding principle: make it really hard to do the wrong thing and very easy to do the right thing (D3).
* Earlier research (a proposal, not a decision) named a simple CLI as the first target, with a web server and REST API later.
* Where Mo stands on the tradeoffs above is not yet decided. Robert's v1 preferences (immutable by default, errors as values, no nulls) are in the parking lot until he decides.
