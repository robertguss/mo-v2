import Full.Demand.Entry

namespace Full.Demand.LocalIds
open Counted Full.Proofs

/-- Locality of saved environments. Older caller environments are not checked. -/
def ContextOK (root cut : Nat) (ctx : Context) : Prop :=
  root ≤ ctx.invocation → ∀ pair ∈ ctx.env, cut ≤ pair.2

def TaskOK (root cut : Nat) : Task → Prop
  | .eval _ ctx | .primitive _ ctx | .bind _ _ ctx
  | .chooseIf _ _ ctx | .chooseMatch _ _ _ _ ctx
  | .decompose _ _ _ _ ctx | .matchComplete ctx | .branchStart ctx
  | .handoffMatch ctx | .enter _ _ ctx | .returning _ ctx => ContextOK root cut ctx
  | .branchResult _ inner outer => ContextOK root cut inner ∧ ContextOK root cut outer
  | _ => True

def TasksOK (root cut : Nat) (tasks : List Task) : Prop :=
  ∀ task ∈ tasks, TaskOK root cut task

theorem tasks_cons : TasksOK root cut (task::tasks) ↔
    TaskOK root cut task ∧ TasksOK root cut tasks := by simp [TasksOK]

theorem tasks_append : TasksOK root cut (xs++ys) ↔
    TasksOK root cut xs ∧ TasksOK root cut ys := by simp [TasksOK,or_imp,forall_and]

theorem dead_prefix (bs : List Binding) (env : Env) (future ts : List Task) :
    TasksOK root cut (dead bs env future ++ ts) ↔ TasksOK root cut ts := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he,tasks_append]
  simp [TasksOK,TaskOK]

theorem reserved_prefix (rs : List Reservation) :
    TasksOK root cut (rs.map (fun r => .freeReserved r.addr) ++ ts) ↔
      TasksOK root cut ts := by
  rw [tasks_append]
  simp [TasksOK,TaskOK]

theorem args_prefix (args : List (Expr × Nat)) (ctx : Context)
    (hc : ContextOK root cut ctx) (ht : TasksOK root cut ts) :
    TasksOK root cut (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts) := by
  induction args with
  | nil => exact ht
  | cons a args ih => simpa [tasks_append,tasks_cons,TaskOK,ContextOK,child] using And.intro hc ih

theorem context_cons {id : Nat} (hc : ContextOK root cut ctx) (hn : cut ≤ id) :
    ContextOK root cut { ctx with env := (name,id)::ctx.env } := by
  intro hroot pair hm
  rcases List.mem_cons.mp hm with rfl | hm
  · exact hn
  · exact hc hroot pair hm

theorem parameter_env (pairs : List ((String × Kind) × Slot))
    (next invocation : Nat) (name : String) (hn : cut ≤ next) :
    ContextOK root cut ⟨
      (pairs.zipIdx.map (fun (((x,_),v),i) =>
        makeBinding (next+i) x v invocation s!"{name}/parameter/{x}")).reverse.map
          (fun b => (b.record.name,b.record.id)),invocation,[],name⟩ := by
  intro _ pair hm
  obtain ⟨b,hb,rfl⟩ := List.mem_map.mp hm
  obtain ⟨⟨⟨⟨x,k⟩,v⟩,i⟩,hi,rfl⟩ := List.mem_map.mp (List.mem_reverse.mp hb)
  simp only [makeBinding]
  omega

set_option maxHeartbeats 2000000 in
theorem transition (hs : TasksOK root cut s.tasks) (hn : cut ≤ s.nextBinding)
    (ht : Counted.transition p s = .ok c) :
    TasksOK root cut c.state.tasks ∧ cut ≤ c.state.nextBinding := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    obtain ⟨hctx,hrest⟩ := tasks_cons.mp (he ▸ hs)
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals constructor
    all_goals try (dsimp only; omega)
    all_goals simp_all only [TaskOK,tasks_cons,dead_prefix,child,makeBinding,
      List.nil_append,List.cons_append,and_true,true_and]
    all_goals try exact (by
      simp only [List.append_assoc]
      apply args_prefix _ _ hs
      simp only [List.cons_append,List.nil_append,tasks_cons,TaskOK]
      exact ⟨hs,hrest⟩)
    all_goals try exact (by
      simp only [List.append_assoc,reserved_prefix,List.cons_append,List.nil_append,tasks_cons,TaskOK]
      exact ⟨hs.2,hrest⟩)
    all_goals repeat' first
      | assumption
      | exact context_cons hs hn
      | exact context_cons (context_cons hs hn) (by omega)
      | exact parameter_env _ _ _ _ hn
      | apply And.intro
    all_goals simp_all [ContextOK]
    all_goals omega

theorem before_entry (hr : Statements.Reachable p initial s) :
    TasksOK s.nextInvocation cut s.tasks := by
  intro t hm
  have hc : ∀ ctx ∈ Scopes.contexts t, ctx.invocation < s.nextInvocation :=
    fun _ hctx => Scopes.reachable_contexts_bound hr hm hctx
  cases t <;> simp_all [TaskOK,ContextOK,Scopes.contexts]
  all_goals omega

theorem at_entry (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter")
    (hf : s.frames.head? = some f) (ha : accepts p f.name = true) :
    ∃ cut out, PlainTyping.FunctionsTyped p ∧ Affinity.StateCertified f.id p out s ∧
      Affinity.Bound cut s ∧ TasksOK f.id cut s.tasks ∧ cut ≤ s.nextBinding := by
  obtain ⟨before,c,hr',ht,hname,rfl⟩ := Events.last_enter hr hl
  obtain ⟨arity,ctx,rest,htask,hid⟩ := Entry.source ht hname hf
  obtain ⟨out,hp,hs⟩ := CountedTyping.reachable_typed hr'
  obtain ⟨decl,hdecl,hd⟩ := accepts_target ha
  have table := accepts_certificates ha
  have hdeclcert := table decl (List.mem_of_find?_eq_some hdecl) hd
  have hc := Affinity.transition_enter hp ht htask (Affinity.before_entry_certified hr' hs)
    (BindingIdentity.reachable_ids hr') (fun g hg => by
      cases Option.some.inj (hg.symm.trans hdecl)
      exact hdeclcert)
  refine ⟨before.nextBinding,out,hp,?_,?_,?_,?_⟩
  · simpa only [Affinity.StateCertified,commit,hid] using hc
  · intro b hm hnew hk
    exact transition_parameters_new_bound hr' ht htask hdecl hdeclcert.1 hm hnew hk
  · simpa only [commit,hid] using (transition (before_entry hr') (Nat.le_refl _) ht).1
  · exact (transition (before_entry hr') (Nat.le_refl _) ht).2

/-- During the active interval a list variable resolves to a fresh local ID,
and its occurrence is the last one in the entire actual saved continuation. -/
theorem variable_last {id : Nat} (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id) (hs : TasksOK root cut s.tasks)
    (hb : Affinity.Bound cut s) (htask : s.tasks = .eval (.var name) ctx::rest)
    (he : ctx.env.find? (fun q => q.1 == name) = some (spelling,id))
    (hl : s.bindings.find? (fun b => b.record.id == id) = some b)
    (hk : b.record.value.kind = .list) : rest.any (taskUses id) = false := by
  have hid : b.record.id = id := by simpa using List.find?_some hl
  have hc : ContextOK root cut ctx := hs (.eval (.var name) ctx)
    (by rw [htask]; exact List.mem_cons_self)
  have hscope : ctx.invocation = (s.frames.map Frame.id).headD 0 := Scopes.head_scope hr htask
  have hcut := hc (hscope ▸ Scopes.active_head_ge hr active) _ (List.mem_of_find?_eq_some he)
  have hbound := hb b (List.mem_of_find?_eq_some hl) (hid ▸ hcut) hk
  apply last_use ctx.env id name ctx rest rfl
  · simp [Trial.Proofs.lookup_frame_env,he]
  · simpa only [hid,htask] using hbound

/-- This is an equality of the actual machine heap, not a syntactic proxy for
acquisition. Neither shared nor unique local variables increment a count. -/
theorem variable_memory (hr : Statements.Reachable p initial s)
    (active : root ∈ s.frames.map Frame.id) (hs : TasksOK root cut s.tasks)
    (hb : Affinity.Bound cut s) (htask : s.tasks = .eval (.var name) ctx::rest)
    (ht : Counted.transition p s = .ok c) : c.state.mem = s.mem := by
  cases he : ctx.env.find? (fun q => q.1 == name) with
  | none => simp [Counted.transition,htask,he] at ht
  | some pair =>
    obtain ⟨spelling,id⟩ := pair
    cases hl : s.bindings.find? (fun b => b.record.id == id) with
    | none => simp [Counted.transition,htask,he,hl] at ht
    | some b =>
      cases hk : b.record.value with
      | num n | bool b =>
        simp [Counted.transition,htask,he,hl,hk] at ht
        cases ht; rfl
      | list r =>
        have hlast := variable_last hr active hs hb htask he hl (by rw [hk]; rfl)
        simp only [Counted.transition,htask,he,hl,hk,hlast,bind,pure,Except.bind,Except.pure] at ht
        repeat' first | split at ht | cases ht | contradiction
        all_goals rfl

end Full.Demand.LocalIds
