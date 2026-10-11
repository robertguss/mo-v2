import Full.Demand
import Full.Demand.Certificates
import Full.Demand.Credits
import Full.Demand.Events
import Full.Demand.Scopes
import Full.Demand.Usage
import Full.Demand.UsageTransition
import Lean
#check Full.Demand.Events.Extension.closed
#print axioms Full.Demand.Events.Extension.closed
#check Full.Demand.Events.Extension.closed._proof_1_3
#print axioms Full.Demand.Events.Extension.closed._proof_1_3
#check Full.Demand.Events.Extension.closed._proof_1_4
#print axioms Full.Demand.Events.Extension.closed._proof_1_4
#check Full.Demand.Events.Extension.trace
#print axioms Full.Demand.Events.Extension.trace
#check Full.Demand.Events.Trace.brecOn
#print axioms Full.Demand.Events.Trace.brecOn
#check Full.Demand.Events.advance_closed
#print axioms Full.Demand.Events.advance_closed
#check Full.Demand.Events.advance_invariant
#print axioms Full.Demand.Events.advance_invariant
#check Full.Demand.Events.begin_history
#print axioms Full.Demand.Events.begin_history
#check Full.Demand.Events.begin_invariant
#print axioms Full.Demand.Events.begin_invariant
#check Full.Demand.Events.creates_eq
#print axioms Full.Demand.Events.creates_eq
#check Full.Demand.Events.entry_zero
#print axioms Full.Demand.Events.entry_zero
#check Full.Demand.Events.frame_bound
#print axioms Full.Demand.Events.frame_bound
#check Full.Demand.Events.frame_bound._proof_1_1
#print axioms Full.Demand.Events.frame_bound._proof_1_1
#check Full.Demand.Events.frame_bound._proof_1_2
#print axioms Full.Demand.Events.frame_bound._proof_1_2
#check Full.Demand.Events.frames_nodup
#print axioms Full.Demand.Events.frames_nodup
#check Full.Demand.Events.frames_nodup._proof_1_1
#print axioms Full.Demand.Events.frames_nodup._proof_1_1
#check Full.Demand.Events.frames_ordered
#print axioms Full.Demand.Events.frames_ordered
#check Full.Demand.Events.frames_ordered._proof_1_1
#print axioms Full.Demand.Events.frames_ordered._proof_1_1
#check Full.Demand.Events.future_zero
#print axioms Full.Demand.Events.future_zero
#check Full.Demand.Events.future_zero._proof_1_3
#print axioms Full.Demand.Events.future_zero._proof_1_3
#check Full.Demand.Events.future_zero._proof_1_4
#print axioms Full.Demand.Events.future_zero._proof_1_4
#check Full.Demand.Events.head_ge
#print axioms Full.Demand.Events.head_ge
#check Full.Demand.Events.last_enter
#print axioms Full.Demand.Events.last_enter
#check Full.Demand.Events.next_positive
#print axioms Full.Demand.Events.next_positive
#check Full.Demand.Events.next_positive._proof_1_1
#print axioms Full.Demand.Events.next_positive._proof_1_1
#check Full.Demand.Events.next_positive._proof_1_2
#print axioms Full.Demand.Events.next_positive._proof_1_2
#check Full.Demand.Events.reachable_invariant
#print axioms Full.Demand.Events.reachable_invariant
#check Full.Demand.Events.step_closed
#print axioms Full.Demand.Events.step_closed
#check Full.Demand.Events.step_invariant
#print axioms Full.Demand.Events.step_invariant
#check Full.Demand.Events.tally._sparseCasesOn_3.else_eq
#print axioms Full.Demand.Events.tally._sparseCasesOn_3.else_eq
#check Full.Demand.Events.tally.eq_1
#print axioms Full.Demand.Events.tally.eq_1
#check Full.Demand.Events.tally_active
#print axioms Full.Demand.Events.tally_active
#check Full.Demand.Events.tally_active._proof_1_6
#print axioms Full.Demand.Events.tally_active._proof_1_6
#check Full.Demand.Events.tally_active._simp_1_3
#print axioms Full.Demand.Events.tally_active._simp_1_3
#check Full.Demand.Events.tally_active._simp_1_4
#print axioms Full.Demand.Events.tally_active._simp_1_4
#check Full.Demand.Events.tally_active._simp_1_5
#print axioms Full.Demand.Events.tally_active._simp_1_5
#check Full.Demand.Events.transition_enter_zero
#print axioms Full.Demand.Events.transition_enter_zero
#check Full.Demand.Events.transition_extension
#print axioms Full.Demand.Events.transition_extension
#check Full.Demand.Events.transition_extension._simp_1_20
#print axioms Full.Demand.Events.transition_extension._simp_1_20
#check Full.Demand.Events.transition_history
#print axioms Full.Demand.Events.transition_history
#check Full.Demand.Events.transition_invariant
#print axioms Full.Demand.Events.transition_invariant
#check Full.Demand.Lower.brecOn
#print axioms Full.Demand.Lower.brecOn
#check Full.Demand.Lower.length
#print axioms Full.Demand.Lower.length
#check Full.Demand.Lower.refl
#print axioms Full.Demand.Lower.refl
#check Full.Demand.Lower.tail
#print axioms Full.Demand.Lower.tail
#check Full.Demand.Lower.trans
#print axioms Full.Demand.Lower.trans
#check Full.Demand.Scopes.Work.brecOn
#print axioms Full.Demand.Scopes.Work.brecOn
#check Full.Demand.Scopes.Work.contexts_bound
#print axioms Full.Demand.Scopes.Work.contexts_bound
#check Full.Demand.Scopes.advance_work
#print axioms Full.Demand.Scopes.advance_work
#check Full.Demand.Scopes.after._sparseCasesOn_1.else_eq
#print axioms Full.Demand.Scopes.after._sparseCasesOn_1.else_eq
#check Full.Demand.Scopes.after.eq_1
#print axioms Full.Demand.Scopes.after.eq_1
#check Full.Demand.Scopes.after.eq_2
#print axioms Full.Demand.Scopes.after.eq_2
#check Full.Demand.Scopes.arguments
#print axioms Full.Demand.Scopes.arguments
#check Full.Demand.Scopes.begin_work
#print axioms Full.Demand.Scopes.begin_work
#check Full.Demand.Scopes.contexts._sparseCasesOn_1.else_eq
#print axioms Full.Demand.Scopes.contexts._sparseCasesOn_1.else_eq
#check Full.Demand.Scopes.contexts.eq_1
#print axioms Full.Demand.Scopes.contexts.eq_1
#check Full.Demand.Scopes.contexts.eq_10
#print axioms Full.Demand.Scopes.contexts.eq_10
#check Full.Demand.Scopes.contexts.eq_11
#print axioms Full.Demand.Scopes.contexts.eq_11
#check Full.Demand.Scopes.contexts.eq_12
#print axioms Full.Demand.Scopes.contexts.eq_12
#check Full.Demand.Scopes.contexts.eq_13
#print axioms Full.Demand.Scopes.contexts.eq_13
#check Full.Demand.Scopes.contexts.eq_2
#print axioms Full.Demand.Scopes.contexts.eq_2
#check Full.Demand.Scopes.contexts.eq_3
#print axioms Full.Demand.Scopes.contexts.eq_3
#check Full.Demand.Scopes.contexts.eq_4
#print axioms Full.Demand.Scopes.contexts.eq_4
#check Full.Demand.Scopes.contexts.eq_5
#print axioms Full.Demand.Scopes.contexts.eq_5
#check Full.Demand.Scopes.contexts.eq_6
#print axioms Full.Demand.Scopes.contexts.eq_6
#check Full.Demand.Scopes.contexts.eq_7
#print axioms Full.Demand.Scopes.contexts.eq_7
#check Full.Demand.Scopes.contexts.eq_8
#print axioms Full.Demand.Scopes.contexts.eq_8
#check Full.Demand.Scopes.contexts.eq_9
#print axioms Full.Demand.Scopes.contexts.eq_9
#check Full.Demand.Scopes.dead_prefix
#print axioms Full.Demand.Scopes.dead_prefix
#check Full.Demand.Scopes.headD_bound
#print axioms Full.Demand.Scopes.headD_bound
#check Full.Demand.Scopes.reachable_contexts_bound
#print axioms Full.Demand.Scopes.reachable_contexts_bound
#check Full.Demand.Scopes.reachable_work
#print axioms Full.Demand.Scopes.reachable_work
#check Full.Demand.Scopes.reserved_prefix
#print axioms Full.Demand.Scopes.reserved_prefix
#check Full.Demand.Scopes.task._sparseCasesOn_1.else_eq
#print axioms Full.Demand.Scopes.task._sparseCasesOn_1.else_eq
#check Full.Demand.Scopes.task.eq_1
#print axioms Full.Demand.Scopes.task.eq_1
#check Full.Demand.Scopes.task.eq_10
#print axioms Full.Demand.Scopes.task.eq_10
#check Full.Demand.Scopes.task.eq_11
#print axioms Full.Demand.Scopes.task.eq_11
#check Full.Demand.Scopes.task.eq_12
#print axioms Full.Demand.Scopes.task.eq_12
#check Full.Demand.Scopes.task.eq_13
#print axioms Full.Demand.Scopes.task.eq_13
#check Full.Demand.Scopes.task.eq_2
#print axioms Full.Demand.Scopes.task.eq_2
#check Full.Demand.Scopes.task.eq_3
#print axioms Full.Demand.Scopes.task.eq_3
#check Full.Demand.Scopes.task.eq_4
#print axioms Full.Demand.Scopes.task.eq_4
#check Full.Demand.Scopes.task.eq_5
#print axioms Full.Demand.Scopes.task.eq_5
#check Full.Demand.Scopes.task.eq_6
#print axioms Full.Demand.Scopes.task.eq_6
#check Full.Demand.Scopes.task.eq_7
#print axioms Full.Demand.Scopes.task.eq_7
#check Full.Demand.Scopes.task.eq_8
#print axioms Full.Demand.Scopes.task.eq_8
#check Full.Demand.Scopes.task.eq_9
#print axioms Full.Demand.Scopes.task.eq_9
#check Full.Demand.Scopes.task_bound
#print axioms Full.Demand.Scopes.task_bound
#check Full.Demand.Scopes.transition_work
#print axioms Full.Demand.Scopes.transition_work
#check Full.Demand.accepts.eq_1
#print axioms Full.Demand.accepts.eq_1
#check Full.Demand.accepts_certificates
#print axioms Full.Demand.accepts_certificates
#check Full.Demand.accepts_certificates._simp_1_5
#print axioms Full.Demand.accepts_certificates._simp_1_5
#check Full.Demand.affine.eq_1
#print axioms Full.Demand.affine.eq_1
#check Full.Demand.affine_list_bound
#print axioms Full.Demand.affine_list_bound
#check Full.Demand.arguments_occurrences
#print axioms Full.Demand.arguments_occurrences
#check Full.Demand.call_occurrences
#print axioms Full.Demand.call_occurrences
#check Full.Demand.expression._sparseCasesOn_1.else_eq
#print axioms Full.Demand.expression._sparseCasesOn_1.else_eq
#check Full.Demand.expression._unary._proof_1
#print axioms Full.Demand.expression._unary._proof_1
#check Full.Demand.expression._unary._proof_10
#print axioms Full.Demand.expression._unary._proof_10
#check Full.Demand.expression._unary._proof_11
#print axioms Full.Demand.expression._unary._proof_11
#check Full.Demand.expression._unary._proof_2
#print axioms Full.Demand.expression._unary._proof_2
#check Full.Demand.expression._unary._proof_3
#print axioms Full.Demand.expression._unary._proof_3
#check Full.Demand.expression._unary._proof_4
#print axioms Full.Demand.expression._unary._proof_4
#check Full.Demand.expression._unary._proof_5
#print axioms Full.Demand.expression._unary._proof_5
#check Full.Demand.expression._unary._proof_6
#print axioms Full.Demand.expression._unary._proof_6
#check Full.Demand.expression._unary._proof_7
#print axioms Full.Demand.expression._unary._proof_7
#check Full.Demand.expression._unary._proof_8
#print axioms Full.Demand.expression._unary._proof_8
#check Full.Demand.expression._unary._proof_9
#print axioms Full.Demand.expression._unary._proof_9
#check Full.Demand.expression._unary.eq_def
#print axioms Full.Demand.expression._unary.eq_def
#check Full.Demand.expression.eq_1
#print axioms Full.Demand.expression.eq_1
#check Full.Demand.expression.eq_2
#print axioms Full.Demand.expression.eq_2
#check Full.Demand.expression.eq_3
#print axioms Full.Demand.expression.eq_3
#check Full.Demand.expression.eq_4
#print axioms Full.Demand.expression.eq_4
#check Full.Demand.expression.eq_5
#print axioms Full.Demand.expression.eq_5
#check Full.Demand.expression.eq_6
#print axioms Full.Demand.expression.eq_6
#check Full.Demand.expression.eq_7
#print axioms Full.Demand.expression.eq_7
#check Full.Demand.expression.eq_8
#print axioms Full.Demand.expression.eq_8
#check Full.Demand.expression.eq_9
#print axioms Full.Demand.expression.eq_9
#check Full.Demand.expression.eq_def
#print axioms Full.Demand.expression.eq_def
#check Full.Demand.expression_length
#print axioms Full.Demand.expression_length
#check Full.Demand.expression_length._simp_1_11
#print axioms Full.Demand.expression_length._simp_1_11
#check Full.Demand.expression_length._unary
#print axioms Full.Demand.expression_length._unary
#check Full.Demand.fold_length
#print axioms Full.Demand.fold_length
#check Full.Demand.fold_length._simp_1_1
#print axioms Full.Demand.fold_length._simp_1_1
#check Full.Demand.freeReserved_occurrences
#print axioms Full.Demand.freeReserved_occurrences
#check Full.Demand.futureOccurrences.eq_1
#print axioms Full.Demand.futureOccurrences.eq_1
#check Full.Demand.futureUses_zero
#print axioms Full.Demand.futureUses_zero
#check Full.Demand.futureUses_zero._simp_1_2
#print axioms Full.Demand.futureUses_zero._simp_1_2
#check Full.Demand.futureUses_zero._simp_1_3
#print axioms Full.Demand.futureUses_zero._simp_1_3
#check Full.Demand.futureUses_zero._simp_1_4
#print axioms Full.Demand.futureUses_zero._simp_1_4
#check Full.Demand.future_append
#print axioms Full.Demand.future_append
#check Full.Demand.future_cons
#print axioms Full.Demand.future_cons
#check Full.Demand.future_dead
#print axioms Full.Demand.future_dead
#check Full.Demand.future_nil
#print axioms Full.Demand.future_nil
#check Full.Demand.hide_lookup
#print axioms Full.Demand.hide_lookup
#check Full.Demand.join_lower
#print axioms Full.Demand.join_lower
#check Full.Demand.last_use
#print axioms Full.Demand.last_use
#check Full.Demand.last_use._proof_1_19
#print axioms Full.Demand.last_use._proof_1_19
#check Full.Demand.occurrences._unary._proof_1
#print axioms Full.Demand.occurrences._unary._proof_1
#check Full.Demand.occurrences._unary._proof_10
#print axioms Full.Demand.occurrences._unary._proof_10
#check Full.Demand.occurrences._unary._proof_11
#print axioms Full.Demand.occurrences._unary._proof_11
#check Full.Demand.occurrences._unary._proof_2
#print axioms Full.Demand.occurrences._unary._proof_2
#check Full.Demand.occurrences._unary._proof_3
#print axioms Full.Demand.occurrences._unary._proof_3
#check Full.Demand.occurrences._unary._proof_4
#print axioms Full.Demand.occurrences._unary._proof_4
#check Full.Demand.occurrences._unary._proof_5
#print axioms Full.Demand.occurrences._unary._proof_5
#check Full.Demand.occurrences._unary._proof_6
#print axioms Full.Demand.occurrences._unary._proof_6
#check Full.Demand.occurrences._unary._proof_7
#print axioms Full.Demand.occurrences._unary._proof_7
#check Full.Demand.occurrences._unary._proof_8
#print axioms Full.Demand.occurrences._unary._proof_8
#check Full.Demand.occurrences._unary._proof_9
#print axioms Full.Demand.occurrences._unary._proof_9
#check Full.Demand.occurrences._unary.eq_def
#print axioms Full.Demand.occurrences._unary.eq_def
#check Full.Demand.occurrences.eq_1
#print axioms Full.Demand.occurrences.eq_1
#check Full.Demand.occurrences.eq_2
#print axioms Full.Demand.occurrences.eq_2
#check Full.Demand.occurrences.eq_3
#print axioms Full.Demand.occurrences.eq_3
#check Full.Demand.occurrences.eq_4
#print axioms Full.Demand.occurrences.eq_4
#check Full.Demand.occurrences.eq_5
#print axioms Full.Demand.occurrences.eq_5
#check Full.Demand.occurrences.eq_6
#print axioms Full.Demand.occurrences.eq_6
#check Full.Demand.occurrences.eq_7
#print axioms Full.Demand.occurrences.eq_7
#check Full.Demand.occurrences.eq_8
#print axioms Full.Demand.occurrences.eq_8
#check Full.Demand.occurrences.eq_9
#print axioms Full.Demand.occurrences.eq_9
#check Full.Demand.occurrences.eq_def
#print axioms Full.Demand.occurrences.eq_def
#check Full.Demand.occurrences_ext
#print axioms Full.Demand.occurrences_ext
#check Full.Demand.occurrences_ext._unary
#print axioms Full.Demand.occurrences_ext._unary
#check Full.Demand.occurrences_fresh_pair
#print axioms Full.Demand.occurrences_fresh_pair
#check Full.Demand.occurrences_fresh_shadow
#print axioms Full.Demand.occurrences_fresh_shadow
#check Full.Demand.parameter_occurrences
#print axioms Full.Demand.parameter_occurrences
#check Full.Demand.spend.eq_1
#print axioms Full.Demand.spend.eq_1
#check Full.Demand.spend.eq_2
#print axioms Full.Demand.spend.eq_2
#check Full.Demand.spend.eq_3
#print axioms Full.Demand.spend.eq_3
#check Full.Demand.spend.eq_def
#print axioms Full.Demand.spend.eq_def
#check Full.Demand.spend_length
#print axioms Full.Demand.spend_length
#check Full.Demand.spend_length._simp_1_5
#print axioms Full.Demand.spend_length._simp_1_5
#check Full.Demand.spend_lower
#print axioms Full.Demand.spend_lower
#check Full.Demand.spend_lower._proof_1_6
#print axioms Full.Demand.spend_lower._proof_1_6
#check Full.Demand.spend_lower._simp_1_5
#print axioms Full.Demand.spend_lower._simp_1_5
#check Full.Demand.spend_monotone
#print axioms Full.Demand.spend_monotone
#check Full.Demand.spend_monotone._proof_1_6
#print axioms Full.Demand.spend_monotone._proof_1_6
#check Full.Demand.spend_monotone._proof_1_7
#print axioms Full.Demand.spend_monotone._proof_1_7
#check Full.Demand.spend_monotone._simp_1_5
#print axioms Full.Demand.spend_monotone._simp_1_5
#check Full.Demand.sum_map_zero
#print axioms Full.Demand.sum_map_zero
#check Full.Demand.taskOccurrences._sparseCasesOn_1.else_eq
#print axioms Full.Demand.taskOccurrences._sparseCasesOn_1.else_eq
#check Full.Demand.taskOccurrences.eq_1
#print axioms Full.Demand.taskOccurrences.eq_1
#check Full.Demand.taskOccurrences.eq_2
#print axioms Full.Demand.taskOccurrences.eq_2
#check Full.Demand.taskOccurrences.eq_3
#print axioms Full.Demand.taskOccurrences.eq_3
#check Full.Demand.taskOccurrences.eq_4
#print axioms Full.Demand.taskOccurrences.eq_4
#check Full.Demand.taskOccurrences.eq_5
#print axioms Full.Demand.taskOccurrences.eq_5
#check Full.Demand.taskOccurrences.eq_6
#print axioms Full.Demand.taskOccurrences.eq_6
#check Full.Demand.taskUses_zero
#print axioms Full.Demand.taskUses_zero
#check Full.Demand.taskUses_zero._simp_1_15
#print axioms Full.Demand.taskUses_zero._simp_1_15
#check Full.Demand.taskUses_zero._simp_1_16
#print axioms Full.Demand.taskUses_zero._simp_1_16
#check Full.Demand.transition_old_occurrences
#print axioms Full.Demand.transition_old_occurrences
#check Full.Demand.transition_old_occurrences._proof_1_1
#print axioms Full.Demand.transition_old_occurrences._proof_1_1
#check Full.Demand.transition_old_occurrences._proof_1_2
#print axioms Full.Demand.transition_old_occurrences._proof_1_2
#check Full.Demand.transition_old_occurrences._proof_1_21
#print axioms Full.Demand.transition_old_occurrences._proof_1_21
#check Full.Demand.transition_old_occurrences._proof_1_22
#print axioms Full.Demand.transition_old_occurrences._proof_1_22
#check Full.Demand.transition_old_occurrences._proof_1_23
#print axioms Full.Demand.transition_old_occurrences._proof_1_23
#check Full.Demand.transition_old_occurrences._proof_1_24
#print axioms Full.Demand.transition_old_occurrences._proof_1_24
#check Full.Demand.transition_old_occurrences._proof_1_25
#print axioms Full.Demand.transition_old_occurrences._proof_1_25
#check Full.Demand.transition_old_occurrences._proof_1_26
#print axioms Full.Demand.transition_old_occurrences._proof_1_26
#check Full.Demand.transition_old_occurrences._proof_1_27
#print axioms Full.Demand.transition_old_occurrences._proof_1_27
#check Full.Demand.transition_old_occurrences._proof_1_28
#print axioms Full.Demand.transition_old_occurrences._proof_1_28
#check Full.Demand.transition_old_occurrences._proof_1_29
#print axioms Full.Demand.transition_old_occurrences._proof_1_29
#check Full.Demand.transition_old_occurrences._proof_1_30
#print axioms Full.Demand.transition_old_occurrences._proof_1_30
#check Full.Demand.transition_old_occurrences._proof_1_31
#print axioms Full.Demand.transition_old_occurrences._proof_1_31
#check Full.Demand.transition_old_occurrences._proof_1_32
#print axioms Full.Demand.transition_old_occurrences._proof_1_32
#check Full.Demand.transition_old_occurrences._proof_1_33
#print axioms Full.Demand.transition_old_occurrences._proof_1_33
#check Full.Demand.transition_old_occurrences._proof_1_34
#print axioms Full.Demand.transition_old_occurrences._proof_1_34
#check Full.Demand.uses_zero
#print axioms Full.Demand.uses_zero
#check Full.Demand.uses_zero._simp_1_21
#print axioms Full.Demand.uses_zero._simp_1_21
#check Full.Demand.uses_zero._simp_1_22
#print axioms Full.Demand.uses_zero._simp_1_22
#check Full.Demand.uses_zero._simp_1_23
#print axioms Full.Demand.uses_zero._simp_1_23
#check Full.Demand.uses_zero._simp_1_24
#print axioms Full.Demand.uses_zero._simp_1_24
#check Full.Demand.uses_zero._unary
#print axioms Full.Demand.uses_zero._unary
open Lean Elab Command in
run_cmd do
  let env ← getEnv
  for (name, info) in env.constants.toList do
    if name.toString.startsWith "Full.Demand." then
      match info with
      | .thmInfo _ => logInfo m!"PUBLIC_THEOREM {name}"
      | _ => pure ()
