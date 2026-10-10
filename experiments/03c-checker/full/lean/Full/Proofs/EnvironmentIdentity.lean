import Full.Proofs.BindingIdentity
import Full.Proofs.SimulationInitial

namespace Full.Proofs.EnvironmentIdentity
open Counted

def EnvOK (next : Nat) (env : Env) : Prop :=
  (env.map Prod.snd).Nodup ∧ ∀ pair ∈ env, pair.2 < next

def TaskOK (next : Nat) : Task → Prop
  | .eval _ ctx | .primitive _ ctx | .bind _ _ ctx
  | .chooseIf _ _ ctx | .chooseMatch _ _ _ _ ctx
  | .decompose _ _ _ _ ctx | .matchComplete ctx | .branchStart ctx
  | .handoffMatch ctx | .enter _ _ ctx | .returning _ ctx => EnvOK next ctx.env
  | .branchResult _ inner outer => EnvOK next inner.env ∧ EnvOK next outer.env
  | _ => True

def TasksOK (next : Nat) (tasks : List Task) : Prop := ∀ task ∈ tasks, TaskOK next task

def Invariant (s : State) : Prop := EnvOK s.nextBinding s.entered ∧ TasksOK s.nextBinding s.tasks

theorem env_mono (h : EnvOK n env) (hle : n ≤ m) : EnvOK m env :=
  ⟨h.1, fun pair hp => Nat.lt_of_lt_of_le (h.2 pair hp) hle⟩

theorem task_mono (h : TaskOK n task) (hle : n ≤ m) : TaskOK m task := by
  cases task <;> simp_all [TaskOK]
  all_goals first | exact env_mono h hle | exact ⟨env_mono h.1 hle, env_mono h.2 hle⟩

theorem tasks_mono (h : TasksOK n tasks) (hle : n ≤ m) : TasksOK m tasks :=
  fun task ht => task_mono (h task ht) hle

theorem env_cons (h : EnvOK n env) : EnvOK (n+1) ((name,n)::env) := by
  refine ⟨?_, ?_⟩
  · simp only [List.map_cons, List.nodup_cons]
    refine ⟨?_, h.1⟩
    intro hm
    obtain ⟨pair,hp,he⟩ := List.mem_map.mp hm
    have := h.2 pair hp
    omega
  · intro pair hp
    simp only [List.mem_cons] at hp
    rcases hp with rfl | hp
    · simp
    · exact Nat.lt_trans (h.2 pair hp) (Nat.lt_succ_self n)

theorem tasks_cons : TasksOK n (task::tasks) ↔ TaskOK n task ∧ TasksOK n tasks := by
  simp [TasksOK]

theorem tasks_append : TasksOK n (xs ++ ys) ↔ TasksOK n xs ∧ TasksOK n ys := by
  simp [TasksOK, or_imp, forall_and]

theorem dead_prefix (bs : List Binding) (env : Env) (future ts : List Task) :
    TasksOK n (dead bs env future ++ ts) ↔ TasksOK n ts := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he, tasks_append]
  simp [TasksOK, TaskOK]

theorem args_prefix (args : List (Expr × Nat)) (ctx : Context)
    (hc : EnvOK n ctx.env) (ht : TasksOK n ts) :
    TasksOK n (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ ts) := by
  induction args with
  | nil => exact ht
  | cons a args ih => simpa [tasks_append, tasks_cons, TaskOK, child, hc] using ih

theorem reserved_prefix (rs : List Reservation) :
    TasksOK n (rs.map (fun r => .freeReserved r.addr) ++ ts) ↔ TasksOK n ts := by
  induction rs with
  | nil => simp
  | cons r rs ih => simpa [tasks_cons, TaskOK] using ih

theorem parameter_env (pairs : List ((String × Kind) × Slot)) (next invocation : Nat) (name : String) :
    EnvOK (next + pairs.length)
      ((pairs.zipIdx.map (fun (((x,_),v),i) =>
        makeBinding (next+i) x v invocation s!"{name}/parameter/{x}")).reverse.map
          (fun b => (b.record.name,b.record.id))) := by
  constructor
  · simp only [List.map_reverse]
    have he := BindingIdentity.parameter_ids pairs next invocation name
    simp only [List.map_map, Function.comp_def] at he ⊢
    rw [he]
    simpa [List.Nodup, List.pairwise_reverse, List.pairwise_map,
      Nat.add_left_cancel_iff, ne_comm] using (List.nodup_range (n := pairs.length))
  · intro pair hp
    obtain ⟨b,hb,rfl⟩ := List.mem_map.mp hp
    have hm : b.record.id ∈ (List.range pairs.length).map (next+·) := by
      rw [← BindingIdentity.parameter_ids (invocation := invocation) (name := name)]
      exact List.mem_map.mpr ⟨b, by simpa using hb, rfl⟩
    obtain ⟨i,hi,he⟩ := List.mem_map.mp hm
    have := List.mem_range.mp hi
    omega

set_option maxHeartbeats 2000000 in
theorem transition_invariant (hs : Invariant s) (ht : Counted.transition p s = .ok c) :
    Invariant c.state := by
  obtain ⟨hen,htasks⟩ := hs
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    have hsource : TaskOK s.nextBinding task ∧ TasksOK s.nextBinding rest :=
      tasks_cons.mp (by simpa [he] using htasks)
    obtain ⟨hctx,hrest⟩ := hsource
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp_all only [Invariant, TaskOK, tasks_cons, dead_prefix,
      child, makeBinding, List.nil_append, List.cons_append,
      and_true, true_and]
    all_goals try exact (by
      simp only [List.append_assoc]
      exact args_prefix _ _ htasks (by
        simp only [List.cons_append, List.nil_append, tasks_cons, TaskOK]
        exact ⟨htasks,hrest⟩))
    all_goals try exact (by
      simp only [List.append_assoc, reserved_prefix, List.cons_append,
        List.nil_append, tasks_cons, TaskOK]
      exact ⟨htasks.2, hrest⟩)
    all_goals try simp only [List.length_map, List.length_zipIdx]
    all_goals repeat' first
      | assumption
      | exact env_cons htasks
      | exact env_cons (env_cons htasks)
      | exact parameter_env _ _ _ _
      | solve | apply env_mono hen; omega
      | solve | apply env_mono htasks; omega
      | solve | apply tasks_mono hrest; omega
      | apply And.intro

theorem commit_invariant (hs : Invariant c.state) : Invariant (commit c) := hs

theorem begin_invariant (hb : Counted.begin p initial = .ok first) : Invariant first := by
  have hid := (Initial.begin_scope_ids p initial first hb).2.1
  obtain ⟨_,edges,bindings,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  have henv : EnvOK bindings.length
      (bindings.reverse.map (fun b => (b.record.name,b.record.id))) := by
    constructor
    · simp only [List.map_reverse, List.map_map, Function.comp_def]
      rw [hid]
      simpa [List.Nodup, List.pairwise_reverse, ne_comm] using
        (List.nodup_range (n := initial.inputs.length))
    · intro pair hp
      obtain ⟨b,hb,rfl⟩ := List.mem_map.mp hp
      have hi : b.record.id ∈ List.range initial.inputs.length := by
        rw [← hid]
        exact List.mem_map.mpr ⟨b, by simpa using hb, rfl⟩
      have hl := congrArg List.length hid
      simp only [List.length_map, List.length_range] at hl
      rw [hl]
      exact List.mem_range.mp hi
  simp only [Invariant, dead_prefix, tasks_cons, TaskOK]
  exact ⟨henv, trivial, henv, trivial, by simp [TasksOK]⟩

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

theorem reachable_entered (hr : Statements.Reachable p initial s) :
    EnvOK s.nextBinding s.entered := (reachable_invariant hr).1

theorem reachable_task (hr : Statements.Reachable p initial s) (ht : task ∈ s.tasks) :
    TaskOK s.nextBinding task := (reachable_invariant hr).2 task ht

/-- Cleanup identities form a sublist of the reversed environment identities. -/
theorem dead_ids_sublist (bindings : List Binding) (env : Env) (future : List Task) :
    ∃ ids : List Nat, dead bindings env future = ids.map Task.giveBinding ∧
      ids.Sublist (env.reverse.map Prod.snd) := by
  unfold dead
  induction env.reverse with
  | nil => exact ⟨[],rfl,List.Sublist.refl _⟩
  | cons pair xs ih =>
    obtain ⟨ids,hi,hs⟩ := ih
    cases pair with
    | mk name id =>
      simp only [List.filterMap_cons, List.map_cons, hi]
      by_cases hc : (bindings.any (fun b => b.record.id == id && b.record.status == .holding) &&
        !future.any (taskUses id)) = true
      · exact ⟨id::ids,by simp [hc],hs.cons_cons _⟩
      · exact ⟨ids,by simp [hc],hs.cons _⟩

theorem dead_unique (h : (env.map Prod.snd).Nodup) :
    ∃ ids : List Nat, dead bindings env future = ids.map Task.giveBinding ∧ ids.Nodup := by
  obtain ⟨ids,he,hs⟩ := dead_ids_sublist bindings env future
  refine ⟨ids,he,hs.nodup ?_⟩
  simpa [List.map_reverse, List.Nodup, List.pairwise_reverse, ne_comm] using h

theorem dead_bound (next id : Nat) (h : ∀ pair ∈ env, pair.2 < next)
    (ht : Task.giveBinding id ∈ dead bindings env future) : id < next := by
  obtain ⟨ids,he,hs⟩ := dead_ids_sublist bindings env future
  rw [he] at ht
  obtain ⟨i,hi,he⟩ := List.mem_map.mp ht
  cases Task.giveBinding.inj he
  obtain ⟨pair,hp,he⟩ := List.mem_map.mp (hs.subset hi)
  rw [← he]
  exact h pair (by simpa using hp)

end Full.Proofs.EnvironmentIdentity
