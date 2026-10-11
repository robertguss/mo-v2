import Full.Proofs.Initial
import Full.Proofs.SimulationInitial

namespace Full.Proofs.ControlShape
open Counted

/-- Finish, when present, is the last task. This is a structural property of
saved work, independent of typing, heap safety, or future execution success. -/
def FinishTail : List Task → Prop
  | [] => True
  | .finish :: ts => ts = []
  | _ :: ts => FinishTail ts

theorem finish_tail (task : Task) (h : FinishTail (task::ts)) : FinishTail ts := by
  cases task <;> simp_all [FinishTail]

theorem dead_prefix (bs : List Binding) (env : Env) (future ts : List Task) :
    FinishTail (dead bs env future ++ ts) = FinishTail ts := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ids with
  | nil => rfl
  | cons id ids ih => simpa [FinishTail] using ih

theorem args_prefix (args : List (Expr × Nat)) (ctx : Context) (ts : List Task) :
    FinishTail (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts) =
      FinishTail ts := by
  induction args with
  | nil => rfl
  | cons a args ih => simpa [FinishTail,List.append_assoc] using ih

theorem reserved_prefix (rs : List Reservation) (ts : List Task) :
    FinishTail (rs.map (fun r => .freeReserved r.addr) ++ ts) = FinishTail ts := by
  induction rs with
  | nil => rfl
  | cons r rs ih => simpa [FinishTail] using ih

theorem transition_shape (hs : FinishTail s.tasks) (ha : s.answer = none)
    (ht : Counted.transition p s = .ok c) :
    FinishTail c.state.tasks ∧ (c.state.answer.isSome = true → c.state.tasks = []) := by
  unfold Counted.transition at ht
  simp only [bind,pure,Except.bind,Except.pure] at ht
  split at ht
  · rename_i task rest he
    have hsource : FinishTail (task::rest) := by simpa [he] using hs
    have hrest := finish_tail task hsource
    all_goals repeat' first
      | split at ht
      | cases ht
      | solve | simp_all [FinishTail,dead_prefix,args_prefix,reserved_prefix,List.append_assoc]
  · contradiction

theorem advance_shape
    (hs : FinishTail s.tasks ∧ (s.answer.isSome = true → s.tasks = []))
    (ht : Counted.advance p n s = .ok t) :
    FinishTail t.tasks ∧ (t.answer.isSome = true → t.tasks = []) := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        exact ih (s := commit c) (by
          simpa only [commit] using transition_shape hs.1 ha hc) ht

theorem reachable_shape (hr : Statements.Reachable p initial s) :
    FinishTail s.tasks ∧ (s.answer.isSome = true → s.tasks = []) := by
  obtain ⟨first,n,hb,hn⟩ := hr
  apply advance_shape ?_ hn
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  simp [dead_prefix,FinishTail]

theorem terminal_no_transition (hr : Statements.Reachable p initial s)
    (ha : s.answer.isSome = true) :
    Counted.transition p s = .error "unfinished state with no action" := by
  simp [Counted.transition,(reachable_shape hr).2 ha]

end Full.Proofs.ControlShape
