import Full.Proofs.EnvironmentIdentity

namespace Full.Proofs.Observer
open Counted

def EnvOK (bs : List Binding) (env : Env) : Prop :=
  ∀ pair ∈ env, ∃ b ∈ bs, b.record.id = pair.2 ∧ b.record.name = pair.1

def TaskOK (bs : List Binding) : Task → Prop
  | .eval _ ctx | .primitive _ ctx | .bind _ _ ctx
  | .chooseIf _ _ ctx | .chooseMatch _ _ _ _ ctx
  | .decompose _ _ _ _ ctx | .matchComplete ctx | .branchStart ctx
  | .handoffMatch ctx | .enter _ _ ctx | .returning _ ctx => EnvOK bs ctx.env
  | .branchResult _ inner outer => EnvOK bs inner.env ∧ EnvOK bs outer.env
  | _ => True

def TasksOK (bs : List Binding) (ts : List Task) : Prop := ∀ t ∈ ts, TaskOK bs t
def Invariant (s : State) : Prop := EnvOK s.bindings s.entered ∧ TasksOK s.bindings s.tasks

theorem env_mono (h : EnvOK bs env)
    (hp : (bs.map BindingIdentity.data).IsPrefix (cs.map BindingIdentity.data)) :
    EnvOK cs env := by
  intro pair hm
  obtain ⟨b,hb,hi,hn⟩ := h pair hm
  obtain ⟨c,hc,he⟩ := List.mem_map.mp (hp.subset (List.mem_map.mpr ⟨b,hb,rfl⟩))
  have hid := congrArg Prod.fst he
  have hname := congrArg (fun d : Nat × String × Raw × Value => d.2.1) he
  exact ⟨c,hc,hid.trans hi,hname.trans hn⟩

theorem task_mono (h : TaskOK bs t)
    (hp : (bs.map BindingIdentity.data).IsPrefix (cs.map BindingIdentity.data)) :
    TaskOK cs t := by
  cases t <;> simp_all [TaskOK]
  all_goals first | exact env_mono h hp | exact ⟨env_mono h.1 hp,env_mono h.2 hp⟩

theorem tasks_mono (h : TasksOK bs ts)
    (hp : (bs.map BindingIdentity.data).IsPrefix (cs.map BindingIdentity.data)) :
    TasksOK cs ts := fun t ht => task_mono (h t ht) hp

theorem tasks_cons : TasksOK bs (t::ts) ↔ TaskOK bs t ∧ TasksOK bs ts := by
  simp [TasksOK]
theorem tasks_append : TasksOK bs (xs ++ ys) ↔ TasksOK bs xs ∧ TasksOK bs ys := by
  simp [TasksOK, or_imp, forall_and]
theorem dead_prefix (bindings : List Binding) (env : Env) (future ts : List Task) :
    TasksOK bs (dead bindings env future ++ ts) ↔ TasksOK bs ts := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bindings env future
  rw [he,tasks_append]
  simp [TasksOK,TaskOK]
theorem args_prefix (args : List (Expr × Nat)) (ctx : Context)
    (hc : EnvOK bs ctx.env) (ht : TasksOK bs ts) :
    TasksOK bs (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts) := by
  induction args with
  | nil => exact ht
  | cons a args ih => simpa [tasks_append,tasks_cons,TaskOK,child,hc] using ih
theorem reserved_prefix (rs : List Reservation) :
    TasksOK bs (rs.map (fun r => .freeReserved r.addr) ++ ts) ↔ TasksOK bs ts := by
  induction rs with
  | nil => simp
  | cons r rs ih => simpa [tasks_cons,TaskOK] using ih

theorem env_cons (h : EnvOK bs env) (hb : b ∈ bs) :
    EnvOK bs ((b.record.name,b.record.id)::env) := by
  intro pair hp
  rcases List.mem_cons.mp hp with rfl | hp
  · exact ⟨b,hb,rfl,rfl⟩
  · exact h pair hp

theorem records_env {xs bs : List Binding} (hp : xs.Sublist bs) :
    EnvOK bs (xs.reverse.map (fun b => (b.record.name,b.record.id))) := by
  intro pair hm
  obtain ⟨b,hb,rfl⟩ := List.mem_map.mp hm
  exact ⟨b,hp.subset (by simpa using hb),rfl,rfl⟩

theorem fresh_one {id : Nat} (h : EnvOK (bs ++ [makeBinding id name v inv site]) env) :
    EnvOK (bs ++ [makeBinding id name v inv site]) ((name,id)::env) :=
  env_cons (b := makeBinding id name v inv site) h (by simp)

theorem fresh_two {id : Nat} (h : EnvOK (bs ++ [makeBinding id name v inv site,
    makeBinding tid t w inv tsite hold]) env) :
    EnvOK (bs ++ [makeBinding id name v inv site,makeBinding tid t w inv tsite hold])
      ((t,tid)::(name,id)::env) :=
  env_cons (b := makeBinding tid t w inv tsite hold)
    (env_cons (b := makeBinding id name v inv site) h (by simp)) (by simp)

theorem commit_invariant (hs : Invariant c.state) : Invariant (commit c) := hs

set_option maxHeartbeats 2000000 in
theorem transition_invariant (hs : Invariant s) (ht : Counted.transition p s = .ok c) :
    Invariant c.state := by
  have hp := BindingIdentity.transition_data ht
  have hen := env_mono hs.1 hp
  have htasks := tasks_mono hs.2 hp
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    obtain ⟨hctx,hrest⟩ := tasks_cons.mp (by simpa [he] using htasks)
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp_all only [Invariant,TaskOK,tasks_cons,dead_prefix,child,
      List.nil_append,List.cons_append,and_true,true_and]
    all_goals try exact (by
      simp only [List.append_assoc]
      exact args_prefix _ _ hs (by
        simp only [List.cons_append,List.nil_append,tasks_cons,TaskOK]
        exact ⟨hs,hrest⟩))
    all_goals try exact (by
      simp only [List.append_assoc,reserved_prefix,List.cons_append,
        List.nil_append,tasks_cons,TaskOK]
      exact ⟨hs.2,hrest⟩)
    all_goals repeat' first
      | assumption
      | solve | apply records_env; exact List.sublist_append_right _ _
      | exact fresh_one htasks
      | exact fresh_two htasks
      | exact fresh_two htasks.1
      | apply And.intro

theorem begin_invariant (hb : Counted.begin p initial = .ok first) : Invariant first := by
  obtain ⟨_,edges,bindings,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  have henv := records_env (List.Sublist.refl bindings)
  simp only [Invariant,dead_prefix,tasks_cons,TaskOK]
  exact ⟨henv,trivial,henv,trivial,by simp [TasksOK]⟩

theorem advance_invariant (hs : Invariant s) (ht : Counted.advance p n s = .ok t) :
    Invariant t := by
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
        exact ih (commit_invariant (transition_invariant hs hc)) ht

theorem reachable_invariant (hr : Statements.Reachable p initial s) : Invariant s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_invariant (begin_invariant hb) hn

theorem visible_sorted (hi : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding) :
    (visible s).Pairwise (fun a b => (decide (a.id ≤ b.id)) = true) := by
  have hp : s.bindings.Pairwise (fun a b => a.record.id ≤ b.record.id) := by
    apply List.pairwise_map.mp
    rw [hi]
    exact List.pairwise_le_range
  unfold visible
  apply List.pairwise_filterMap.mpr
  apply hp.imp
  intro a b hab x hx y hy
  split at hx <;> simp_all

theorem observer (hs : Invariant s)
    (hi : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding) :
    Inspect.observer s = true := by
  have he : s.entered.all (fun (name,id) => s.bindings.any (fun b =>
      b.record.id == id && b.record.name == name)) = true := by
    apply List.all_eq_true.mpr
    intro pair hm
    obtain ⟨b,hb,hid,hn⟩ := hs.1 pair hm
    exact List.any_eq_true.mpr ⟨b,hb,by simp [hid,hn]⟩
  have hsort := List.mergeSort_of_pairwise (visible_sorted hi)
  simp only [Inspect.observer,he,Bool.true_and]
  change decide (visible s = (visible s).mergeSort (fun a b => a.id ≤ b.id)) = true
  rw [hsort]
  simp

theorem begin_observer (hb : Counted.begin p initial = .ok first) :
    Inspect.observer first = true := observer (begin_invariant hb) (BindingIdentity.begin_ids hb)

theorem transition_observer (hs : Invariant s)
    (hi : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding)
    (ht : Counted.transition p s = .ok c) : Inspect.observer c.state = true :=
  observer (transition_invariant hs ht) (BindingIdentity.transition_ids hi ht)

theorem reachable_observer (hr : Statements.Reachable p initial s) :
    Inspect.observer s = true := observer (reachable_invariant hr) (BindingIdentity.reachable_ids hr)

end Full.Proofs.Observer
