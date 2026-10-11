import Full.Demand.Tickets
import Full.Demand.LocalIds

namespace Full.Demand.CreditWork
open Counted Tickets Full.Proofs

def budget (ctx : Context) (credits : List Nat) : Budget :=
  ⟨ctx.invocation,ctx.branches,credits⟩

def Quiet : Task → Prop
  | .start | .capture | .branchStart .. | .matchComplete .. | .handoffMatch ..
  | .giveBinding .. | .givePending | .free .. => True
  | _ => False

/-- Syntactic saved-work certificates. No constructor assumes a callee's
semantic result. Calls carry only membership in the simultaneously checked
table; entering a call will install its empty-input source certificate. -/
inductive Plan (root : Nat) (p : Program) (saved : List Task) : List Task → List Budget → Prop
  | boundary : Plan root p saved saved [⟨root,[],[]⟩]
  | quiet : Quiet task → Plan root p saved ts budgets → Plan root p saved (task::ts) budgets
  | eval (checked : expression p.functions env before e = .ok after)
      (rest : Plan root p saved ts (budget ctx after::stack)) :
      Plan root p saved (.eval e ctx::ts) (budget ctx before::stack)
  | primitive (checked : (if op == .cons then spend before else .ok before) = .ok after)
      (rest : Plan root p saved ts (budget ctx after::stack)) :
      Plan root p saved (.primitive op ctx::ts) (budget ctx before::stack)
  | bind (checked : expression p.functions env before body = .ok after)
      (rest : Plan root p saved ts (budget ctx after::stack)) :
      Plan root p saved (.bind name body ctx::ts) (budget ctx before::stack)
  | chooseIf (yesChecked : expression p.functions env before yes = .ok left)
      (noChecked : expression p.functions env before no = .ok right)
      (leftBound : Lower after left) (rightBound : Lower after right)
      (rest : Plan root p saved ts (budget ctx after::stack)) :
      Plan root p saved (.chooseIf yes no ctx::ts) (budget ctx before::stack)
  | chooseMatch (emptyChecked : expression p.functions emptyEnv (0::before) empty = .ok left)
      (cellChecked : expression p.functions cellEnv (1::before) body = .ok right)
      (leftBound : Lower after left.tail) (rightBound : Lower after right.tail)
      (rest : Plan root p saved ts (budget ctx after::stack)) :
      Plan root p saved (.chooseMatch empty head tail body ctx::ts) (budget ctx before::stack)
  | decompose (branches : ctx.branches = bid::outer)
      (checked : expression p.functions env (1::before) body = .ok after)
      (bound : Lower joined after.tail)
      (rest : Plan root p saved ts (⟨ctx.invocation,outer,joined⟩::stack)) :
      Plan root p saved (.decompose head tail body bid ctx::ts) (budget ctx (0::before)::stack)
  | branchResult (scope : inner.invocation = outer.invocation ∧ inner.branches = bid::outer.branches)
      (bound : Lower after before.tail)
      (rest : Plan root p saved ts (budget outer after::stack)) :
      Plan root p saved (.branchResult bid inner outer::ts) (budget inner before::stack)
  | handoff (bound : Lower after before)
      (rest : Plan root p saved ts (budget ctx after::stack)) :
      Plan root p saved (.handoff::ts) (budget ctx before::stack)
  | enter (found : signature p.functions name = some f) (demanded : f.demanded = true)
      (rest : Plan root p saved ts (budget ctx credits::stack)) :
      Plan root p saved (.enter name arity ctx::ts) (budget ctx credits::stack)
  | returning (rest : Plan root p saved ts (budget ctx credits::stack)) :
      Plan root p saved (.returning frame ctx::ts) (⟨frame.id,[],[]⟩::budget ctx credits::stack)

theorem Plan.prefix (h : Plan root p saved ts budgets) : ∃ work, ts = work ++ saved := by
  induction h
  case boundary => exact ⟨[],rfl⟩
  all_goals obtain ⟨work,hw⟩ := (by assumption : ∃ work, _ = work ++ saved)
  all_goals rw [hw]
  all_goals exact ⟨_::work,rfl⟩

theorem Plan.at_boundary (h : Plan root p saved ts budgets) (he : ts = saved) :
    budgets = [⟨root,[],[]⟩] := by
  cases h
  case boundary => rfl
  all_goals obtain ⟨work,hw⟩ := Plan.prefix (by assumption)
  all_goals rw [hw] at he
  all_goals have hl := congrArg List.length he
  all_goals simp only [List.length_cons,List.length_append] at hl
  all_goals omega

theorem dead_prefix (bs : List Binding) (env : Env) (future : List Task)
    (h : Plan root p saved ts budgets) : Plan root p saved (dead bs env future ++ ts) budgets := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ids with
  | nil => exact h
  | cons id ids ih => exact .quiet trivial ih

theorem arguments (args : List Expr) (index : Nat) (ctx : Context)
    (checked : args.attach.foldlM (fun credits a => expression p.functions env credits a.val)
      before = .ok after)
    (h : Plan root p saved ts (budget ctx after::stack)) :
    Plan root p saved
      ((args.zipIdx index).flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts)
      (budget ctx before::stack) := by
  induction args generalizing index before with
  | nil =>
    simp only [List.attach_nil,List.foldlM_nil,PlainTyping.pure_eq,Except.ok.injEq] at checked
    subst after
    exact h
  | cons a args ih =>
    simp only [List.attach_cons,List.foldlM_cons,PlainTyping.bind_ok] at checked
    obtain ⟨mid,ha,ht⟩ := checked
    apply Plan.eval (ctx := child ctx index) ha
    apply Plan.quiet (task := .capture) trivial
    apply ih (index+1)
    simpa only [List.foldlM_map] using ht

/-- Dispatch only decomposes successful analysis witnesses. Branch joins are
remembered at handoff/branchResult; there is no re-analysis at concrete counts. -/
theorem dispatch (checked : expression p.functions env before e = .ok after)
    (h : Plan root p saved rest (budget ctx after::stack))
    (htask : s.tasks = .eval e ctx::rest) (ht : Counted.transition p s = .ok c) :
    Plan root p saved c.state.tasks (budget ctx before::stack) := by
  cases e with
  | num n | bool b | nil | var name =>
    simp only [expression,PlainTyping.pure_eq,Except.ok.injEq] at checked
    subst after
    simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
    repeat' first | split at ht | cases ht | contradiction
    all_goals exact h
  | bin op a b =>
    simp only [expression,PlainTyping.bind_ok] at checked
    obtain ⟨mid,ha,last,hb,hc⟩ := checked
    simp only [Counted.transition,htask,pure,Except.pure] at ht
    cases ht
    exact .eval ha (.quiet trivial (.eval hb (.quiet trivial (.primitive hc h))))
  | letE name a b =>
    simp only [expression,PlainTyping.bind_ok] at checked
    obtain ⟨kind,hk,u,hu,mid,ha,hb⟩ := checked
    simp only [Counted.transition,htask,pure,Except.pure] at ht
    cases ht
    exact .eval ha (.bind hb h)
  | ifE cond yes no =>
    simp only [expression,PlainTyping.bind_ok] at checked
    obtain ⟨mid,hc,left,hl,right,hr,he⟩ := checked
    simp only [PlainTyping.pure_eq,Except.ok.injEq] at he
    subst after
    have hlen := (expression_length _ _ _ _ _ hl).trans (expression_length _ _ _ _ _ hr).symm
    obtain ⟨hleft,hright⟩ := join_lower left right hlen
    simp only [Counted.transition,htask,pure,Except.pure] at ht
    cases ht
    exact .eval hc (.chooseIf hl hr hleft hright h)
  | matchE scrut empty head tail body =>
    simp only [expression,PlainTyping.bind_ok] at checked
    obtain ⟨u,hu,mid,hs,left,hl,right,hr,he⟩ := checked
    simp only [PlainTyping.pure_eq,Except.ok.injEq] at he
    subst after
    have hlen : left.tail.length = right.tail.length := by
      have hl := expression_length _ _ _ _ _ hl
      have hr := expression_length _ _ _ _ _ hr
      simp only [List.length_cons] at hl hr
      simp [List.length_tail,hl,hr]
    obtain ⟨hleft,hright⟩ := join_lower left.tail right.tail hlen
    simp only [Counted.transition,htask,pure,Except.pure] at ht
    cases ht
    exact .eval hs (.chooseMatch hl hr hleft hright h)
  | call name args =>
    simp only [expression] at checked
    split at checked
    · rename_i f hf
      split at checked
      · simp at checked
      · have hd : f.demanded = true := by simp_all
        simp only [Counted.transition,htask,pure,Except.pure] at ht
        cases ht
        simp only [List.append_assoc,List.singleton_append]
        exact arguments args 0 ctx checked (.enter hf hd h)
    · simp at checked

end Full.Demand.CreditWork
