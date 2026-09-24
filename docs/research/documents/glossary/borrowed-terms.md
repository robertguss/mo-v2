# Borrowed Terms

Terms from other traditions, with the meaning Mo uses.

Negative space programming: From Tiger Style: asserting what must never happen, not only what should. In Mo, a first-class part of contracts.

Tiger Style: TigerBeetle's engineering philosophy: assertions everywhere, explicit limits, static allocation, handle every error.

Power of Ten: NASA/JPL's ten rules for safety-critical C (Gerard Holzmann, 2006): bounded loops, no recursion, no dynamic allocation after startup, and more.

Design by Contract: Bertrand Meyer's method, from the Eiffel language: preconditions, postconditions, and invariants.

Correction ladder: Lauren Tan's ranking of where a correction to an agent can live, hardest first: the codebase, static analysis, rules, skills, the style guide. Mo adds a rung above them all: the language itself.

Fence: From Rat Stack: the lint rules, hooks, and CI checks that keep agents on the right path in an existing language. A fence can be climbed; a language rule can't.

Floor: The worst outcome on a normal run. Raising the floor lets agents run longer unattended.

Make illegal states unrepresentable: Yaron Minsky's principle: design types so invalid data can't exist.

Parse, don't validate: Alexis King's principle: convert raw input into precise types once, at the edge, instead of re-checking it everywhere.
