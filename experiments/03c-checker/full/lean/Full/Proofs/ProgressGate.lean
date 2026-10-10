import Full.Proofs.PartialGate
import Full.Proofs.Free
import Full.Proofs.SimulationInitial
import Full.Proofs.Effects

/-! Further partial stage-1 evidence, not the frozen eight-target ProofGate.
F5/L1 remain the only complete targets. The new universal results cover the
first F2 conjunct, F1 effect accounting, and local Free/heap/control lemmas. -/

example : ∀ p initial first, Full.Counted.begin p initial = .ok first →
    ∃ plain, Full.Statements.plainBegin p initial = .ok plain ∧
      Full.Statements.Related plain first :=
  Full.Proofs.SimulationInitial.initial_simulation

#check Full.Proofs.invariant_heap
#check Full.Proofs.free_from_invariant
#check Full.Proofs.transition_effects
#check Full.Proofs.SimulationInitial.initial_simulation

#print axioms Full.Proofs.control_env_bindings
#print axioms Full.Proofs.continuations_bindings
#print axioms Full.Proofs.focus_bindings
#print axioms Full.Proofs.callTail_rest_length
#print axioms Full.Proofs.continuations_fuel
#print axioms Full.Proofs.focus_fuel
#print axioms Full.Proofs.decode_commit
#print axioms Full.Proofs.executionRoots_holders
#print axioms Full.Proofs.invariant_heap
#print axioms Full.Proofs.invariant_live_edge
#print axioms Full.Proofs.release_zero
#print axioms Full.Proofs.free_transition
#print axioms Full.Proofs.free_preserves_heap
#print axioms Full.Proofs.free_decode
#print axioms Full.Proofs.free_rank
#print axioms Full.Proofs.free_from_invariant
#print axioms Full.Proofs.SimulationInitial.input_lookup
#print axioms Full.Proofs.SimulationInitial.mapM_map_ok
#print axioms Full.Proofs.SimulationInitial.input_environment
#print axioms Full.Proofs.SimulationInitial.focus_giveBinding_prefix
#print axioms Full.Proofs.SimulationInitial.mapM_transfer
#print axioms Full.Proofs.SimulationInitial.input_values
#print axioms Full.Proofs.SimulationInitial.dead_is_prefix
#print axioms Full.Proofs.SimulationInitial.initial_simulation
#print axioms Full.Proofs.transition_effects
#print axioms Full.Proofs.commit_effects
