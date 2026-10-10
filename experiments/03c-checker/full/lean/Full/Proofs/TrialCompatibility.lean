import Full.Proofs.TrialExpressionArithmetic
import Full.Proofs.TrialExpressionValues
import Full.Proofs.TrialExpressionIf
import Full.Proofs.TrialExpressionLet
import Full.Proofs.TrialExpressionMatchEvaluation
import Full.Proofs.TrialInitialCleanup

namespace Full.Proofs

open TrialExecution

/-- Structural induction covers every expression of the frozen Trial language. -/
theorem trial_evaluation (e : Trial.Expr) : Evaluation e := by
  induction e with
  | num n => exact evaluation_num n
  | add a b ha hb => exact evaluation_add a b ha hb
  | sub a b ha hb => exact evaluation_sub a b ha hb
  | eq a b ha hb => exact evaluation_eq a b ha hb
  | lt a b ha hb => exact evaluation_lt a b ha hb
  | le a b ha hb => exact evaluation_le a b ha hb
  | nil => exact evaluation_nil
  | cons a b ha hb => exact evaluation_cons a b ha hb
  | letE _ _ _ ha hb => exact evaluation_let ha hb
  | ifE _ _ _ hc ht he => exact evaluation_if hc ht he
  | matchE _ _ _ _ _ hs hn hc => exact evaluation_match hs hn hc
  | var x => exact evaluation_var x

theorem f6 : Statements.F6 :=
  TrialInitialization.f6_of_evaluation trial_evaluation
    TrialInitialization.initial_cleanup_bridge

end Full.Proofs
