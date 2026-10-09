import Full.Proofs
import Full.Proofs.Initial
import Full.Proofs.Scope
import Full.Proofs.Lifecycle

/-! Partial stage-1 evidence only. This is not the frozen eight-target ProofGate. -/
example : Full.Statements.F5 := Full.Proofs.f5
example : Full.Statements.L1 := Full.Proofs.l1

example (p : Full.Program) (initial : Trial.Start) (s : Full.Counted.State)
    (h : Full.Counted.begin p initial = .ok s) :
    Full.Inspect.invariant initial s = true :=
  Full.Proofs.Initial.initialized_invariant p initial s h

example (p : Full.Program) (s : Full.Counted.State) (c : Full.Counted.Change)
    (h : Full.Counted.transition p s = .ok c) :
    Full.Inspect.nextScope p s = .ok c.state.entered :=
  Full.Proofs.transition_scope p s c h

#check Full.Proofs.f5
#check Full.Proofs.l1
#check Full.Proofs.Initial.initialized_invariant
#check Full.Proofs.transition_scope
#check Full.Proofs.lifecycleReachable_outside
#check Full.Proofs.destroy_idempotent
#check Full.Proofs.destroy_preserves_observations
#check Full.Proofs.lifecycleReachable_clears_control
#check Full.Proofs.lifecycleReachable_cleanup_membership
#print axioms Full.Proofs.f5
#print axioms Full.Proofs.l1
#print axioms Full.Proofs.Initial.initialized_invariant
#print axioms Full.Proofs.transition_scope
#print axioms Full.Proofs.lifecycleReachable_outside
#print axioms Full.Proofs.destroy_idempotent
#print axioms Full.Proofs.destroy_preserves_observations
#print axioms Full.Proofs.lifecycleReachable_clears_control
#print axioms Full.Proofs.lifecycleReachable_cleanup_membership
