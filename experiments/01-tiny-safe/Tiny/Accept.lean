/-!
# Experiment 1: acceptance

Locked, like `Spec.lean`. This file compiles only if the builder's `typecheck`
keeps both promises in the spec. The `#print axioms` lines show exactly what
the proofs rely on: anything beyond Lean's standard axioms (`propext`,
`Classical.choice`, `Quot.sound`), such as `sorryAx`, means the work is not
accepted.
-/
import Tiny.Spec
import Tiny.Checker

namespace Tiny

theorem accepted_safe : Safe typecheck := safety
theorem accepted_useful : Useful typecheck := useful

end Tiny

#print axioms Tiny.accepted_safe
#print axioms Tiny.accepted_useful
