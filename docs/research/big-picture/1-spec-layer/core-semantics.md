# Core Semantics

**Type:** Earlier research

**Also filed under:** [5 Effects and authority](../5-effects-and-authority/README.md), [2 Code layer](../2-code-layer/README.md)

**Links:**

* [Standard Library and Interop](../5-effects-and-authority/standard-library-and-interop.md) depends on → this
* coupled with → [Verification and Feedback](../3-feedback-loop/verification-and-feedback.md)
* coupled with → [Runtime Model](../6-running-programs/runtime-model.md)
* [Implementation](../../parking-lot/implementation.md) depends on → this
* [Syntax](../2-code-layer/syntax.md) depends on → this

Earlier research: proposals, not decisions. Decisions are in DECISIONS.md.

What Mo programs mean: the heart of the language.

Status: errors partly explored; everything else open.

Territory:
* Type system: what it is responsible for
* Data: records, sum types, no null
* Functions and signatures: inputs, outputs, effects, failures, contracts
* Contracts: preconditions, postconditions, invariants, negative space
* Effects: how functions declare what they do to the outside world
* Errors: failures vs. defects (settled)
* Modules and visibility
