-- Auxiliary proof prefix only; no Conditional proof is claimed.
import Full.Demand
import Full.Demand.Certificates
import Full.Demand.Credits
import Full.Demand.Events
import Full.Demand.Scopes
import Full.Demand.Usage
import Full.Demand.UsageTransition

#check Full.Demand.accepts_certificates
#print axioms Full.Demand.accepts_certificates
#check Full.Demand.affine_list_bound
#print axioms Full.Demand.affine_list_bound
#check Full.Demand.spend_length
#print axioms Full.Demand.spend_length
#check Full.Demand.fold_length
#print axioms Full.Demand.fold_length
#check Full.Demand.expression_length
#print axioms Full.Demand.expression_length
#check Full.Demand.Lower.refl
#print axioms Full.Demand.Lower.refl
#check Full.Demand.Lower.trans
#print axioms Full.Demand.Lower.trans
#check Full.Demand.Lower.length
#print axioms Full.Demand.Lower.length
#check Full.Demand.Lower.tail
#print axioms Full.Demand.Lower.tail
#check Full.Demand.join_lower
#print axioms Full.Demand.join_lower
#check Full.Demand.spend_lower
#print axioms Full.Demand.spend_lower
#check Full.Demand.spend_monotone
#print axioms Full.Demand.spend_monotone
#check Full.Demand.Events.Extension.trace
#print axioms Full.Demand.Events.Extension.trace
#check Full.Demand.Events.begin_invariant
#print axioms Full.Demand.Events.begin_invariant
#check Full.Demand.Events.transition_extension
#print axioms Full.Demand.Events.transition_extension
#check Full.Demand.Events.transition_invariant
#print axioms Full.Demand.Events.transition_invariant
#check Full.Demand.Events.step_invariant
#print axioms Full.Demand.Events.step_invariant
#check Full.Demand.Events.advance_invariant
#print axioms Full.Demand.Events.advance_invariant
#check Full.Demand.Events.reachable_invariant
#print axioms Full.Demand.Events.reachable_invariant
#check Full.Demand.Events.frame_bound
#print axioms Full.Demand.Events.frame_bound
#check Full.Demand.Events.next_positive
#print axioms Full.Demand.Events.next_positive
#check Full.Demand.Events.frames_ordered
#print axioms Full.Demand.Events.frames_ordered
#check Full.Demand.Events.head_ge
#print axioms Full.Demand.Events.head_ge
#check Full.Demand.Events.frames_nodup
#print axioms Full.Demand.Events.frames_nodup
#check Full.Demand.Events.creates_eq
#print axioms Full.Demand.Events.creates_eq
#check Full.Demand.Events.tally_active
#print axioms Full.Demand.Events.tally_active
#check Full.Demand.Events.future_zero
#print axioms Full.Demand.Events.future_zero
#check Full.Demand.Events.Extension.closed
#print axioms Full.Demand.Events.Extension.closed
#check Full.Demand.Events.step_closed
#print axioms Full.Demand.Events.step_closed
#check Full.Demand.Events.advance_closed
#print axioms Full.Demand.Events.advance_closed
#check Full.Demand.Events.transition_history
#print axioms Full.Demand.Events.transition_history
#check Full.Demand.Events.begin_history
#print axioms Full.Demand.Events.begin_history
#check Full.Demand.Events.last_enter
#print axioms Full.Demand.Events.last_enter
#check Full.Demand.Events.transition_enter_zero
#print axioms Full.Demand.Events.transition_enter_zero
#check Full.Demand.Events.entry_zero
#print axioms Full.Demand.Events.entry_zero
#check Full.Demand.Scopes.dead_prefix
#print axioms Full.Demand.Scopes.dead_prefix
#check Full.Demand.Scopes.reserved_prefix
#print axioms Full.Demand.Scopes.reserved_prefix
#check Full.Demand.Scopes.arguments
#print axioms Full.Demand.Scopes.arguments
#check Full.Demand.Scopes.begin_work
#print axioms Full.Demand.Scopes.begin_work
#check Full.Demand.Scopes.transition_work
#print axioms Full.Demand.Scopes.transition_work
#check Full.Demand.Scopes.advance_work
#print axioms Full.Demand.Scopes.advance_work
#check Full.Demand.Scopes.reachable_work
#print axioms Full.Demand.Scopes.reachable_work
#check Full.Demand.Scopes.headD_bound
#print axioms Full.Demand.Scopes.headD_bound
#check Full.Demand.Scopes.task_bound
#print axioms Full.Demand.Scopes.task_bound
#check Full.Demand.Scopes.Work.contexts_bound
#print axioms Full.Demand.Scopes.Work.contexts_bound
#check Full.Demand.Scopes.reachable_contexts_bound
#print axioms Full.Demand.Scopes.reachable_contexts_bound
#check Full.Demand.sum_map_zero
#print axioms Full.Demand.sum_map_zero
#check Full.Demand.uses_zero
#print axioms Full.Demand.uses_zero
#check Full.Demand.taskUses_zero
#print axioms Full.Demand.taskUses_zero
#check Full.Demand.futureUses_zero
#print axioms Full.Demand.futureUses_zero
#check Full.Demand.last_use
#print axioms Full.Demand.last_use
#check Full.Demand.hide_lookup
#print axioms Full.Demand.hide_lookup
#check Full.Demand.occurrences_ext
#print axioms Full.Demand.occurrences_ext
#check Full.Demand.occurrences_fresh_shadow
#print axioms Full.Demand.occurrences_fresh_shadow
#check Full.Demand.occurrences_fresh_pair
#print axioms Full.Demand.occurrences_fresh_pair
#check Full.Demand.future_nil
#print axioms Full.Demand.future_nil
#check Full.Demand.future_cons
#print axioms Full.Demand.future_cons
#check Full.Demand.future_append
#print axioms Full.Demand.future_append
#check Full.Demand.future_dead
#print axioms Full.Demand.future_dead
#check Full.Demand.parameter_occurrences
#print axioms Full.Demand.parameter_occurrences
#check Full.Demand.arguments_occurrences
#print axioms Full.Demand.arguments_occurrences
#check Full.Demand.call_occurrences
#print axioms Full.Demand.call_occurrences
#check Full.Demand.freeReserved_occurrences
#print axioms Full.Demand.freeReserved_occurrences
#check Full.Demand.transition_old_occurrences
#print axioms Full.Demand.transition_old_occurrences
