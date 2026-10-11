import Full.Demand.Affinity

namespace Full.Demand.Entry
open Counted Full.Proofs CountedTyping Affinity

set_option maxHeartbeats 2000000 in
/-- The frozen observation identifies an actual Enter, not an arbitrary state
whose current frame happens to name the checked declaration. -/
theorem source (ht : Counted.transition p s = .ok c) (ha : c.action.name = "Enter")
    (hf : c.state.frames.head? = some f) :
    ∃ arity ctx rest, s.tasks = .enter f.name arity ctx::rest ∧ f.id = s.nextInvocation := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp only at ha hf
    all_goals try contradiction
    all_goals simp only [List.head?_cons,Option.some.injEq] at hf
    all_goals subst f
    all_goals exact ⟨_,_,rest,rfl,rfl⟩

/-- Syntactic affinity is established at the precise pre-cleanup entry used by
Conditional. The stronger heap/reservation invariant is a separate obligation. -/
theorem certified (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter")
    (hf : s.frames.head? = some f) (ha : accepts p f.name = true) :
    ∃ cut out, PlainTyping.FunctionsTyped p ∧ StateCertified f.id p out s ∧ Bound cut s := by
  obtain ⟨before,c,hr',ht,hname,rfl⟩ := Events.last_enter hr hl
  obtain ⟨arity,ctx,rest,htask,hid⟩ := source ht hname hf
  obtain ⟨out,hp,hs⟩ := reachable_typed hr'
  obtain ⟨decl,hdecl,hd⟩ := accepts_target ha
  have hcert := accepts_certificates ha
  have hc := transition_enter hp ht htask (before_entry_certified hr' hs)
    (BindingIdentity.reachable_ids hr') (fun g hg => by
      cases Option.some.inj (hg.symm.trans hdecl)
      exact hcert decl (List.mem_of_find?_eq_some hdecl) hd)
  refine ⟨before.nextBinding,out,hp,?_,?_⟩
  · simpa only [StateCertified,commit,hid] using hc
  · intro b hm hnew hk
    exact transition_parameters_new_bound hr' ht htask hdecl
      (hcert decl (List.mem_of_find?_eq_some hdecl) hd).1 hm hnew hk

end Full.Demand.Entry
