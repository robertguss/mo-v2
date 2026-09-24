# Verification and Testing

Signature: What a function declares about itself: inputs, output, effects, failures, and contracts. The part of the code the compiler checks everything else against.

Contract: A checkable promise attached to a function. Preconditions (what must be true on the way in), postconditions (what the function guarantees on the way out, written `ensures`), and invariants (what is always true).

Weak contract: A contract that passes but doesn't capture the real intent. Example: `ensures: result >= 0` when the rule is "never more than 50% off."

Effect: Something a function does to the outside world, such as reading files or using the network. Declared in the signature so an agent can't add a side effect silently.

Language spec: The prose description of what Mo is, what it guarantees, and why. Robert's main design artifact.

Golden test: A small example program paired with its expected output or expected diagnostic. The golden test corpus is the executable spec agents build the compiler against.

Mutation testing: Deliberately breaking code (for example, changing `0.5` to `0.2`) to check whether contracts and tests notice. Surviving mutations reveal weak contracts.

Property-based testing: Generating many inputs automatically to check that a property always holds.

Fuzzing: Feeding random or malformed input to find crashes and defects.
