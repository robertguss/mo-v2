import Full.Proofs.EnvironmentIdentity
import Full.Proofs.HoldingAccounted

namespace Full.Proofs.ReleaseQueue
open Counted

def ids : List Task → List Nat
  | [] => []
  | .giveBinding bid :: ts => bid :: ids ts
  | _ :: ts => ids ts

/-- Named releases execute before ordinary saved work. A cell-release cascade
may interrupt that prefix, but ordinary work cannot hide a later named release. -/
def Prefix : List Task → Prop
  | [] => True
  | .giveBinding _ :: ts | .givePending :: ts | .free _ :: ts => Prefix ts
  | _ :: ts => ids ts = []

theorem ids_append (xs ys : List Task) : ids (xs ++ ys) = ids xs ++ ids ys := by
  induction xs with
  | nil => rfl
  | cons x xs ih => cases x <;> simp [ids,ih]

theorem ids_named (bs : List Nat) : ids (bs.map Task.giveBinding) = bs := by
  induction bs with
  | nil => rfl
  | cons b bs ih => simp [ids,ih]

theorem no_ids_prefix (h : ids ts = []) : Prefix ts := by
  induction ts with
  | nil => trivial
  | cons task ts ih => cases task <;> simp_all [ids,Prefix]

theorem prefix_named (bs : List Nat) (ts : List Task) :
    Prefix (bs.map Task.giveBinding ++ ts) ↔ Prefix ts := by
  induction bs with
  | nil => rfl
  | cons b bs ih => simpa [Prefix] using ih

theorem prefix_dead (bs : List Binding) (env : Env) (future ts : List Task) :
    Prefix (dead bs env future ++ ts) ↔ Prefix ts := by
  obtain ⟨names,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he,prefix_named]

theorem ids_arguments (args : List (Expr × Nat)) (ctx : Context) :
    ids (args.flatMap (fun (a,i) => [.eval a (child ctx i),.capture])) = [] := by
  induction args with
  | nil => rfl
  | cons a args ih => simpa [ids,ids_append] using ih

theorem ids_reserved (rs : List Reservation) :
    ids (rs.map (fun r => .freeReserved r.addr)) = [] := by
  induction rs with
  | nil => rfl
  | cons r rs ih => simpa [ids] using ih

set_option maxHeartbeats 1000000 in
theorem transition_prefix (hs : Prefix s.tasks)
    (ht : Counted.transition p s = .ok c) : Prefix c.state.tasks := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp_all only [he,Prefix,prefix_dead,ids]
    all_goals first
      | assumption
      | solve | apply no_ids_prefix; simp_all [ids,ids_append,ids_arguments,ids_reserved]

theorem begin_prefix (hb : Counted.begin p initial = .ok first) : Prefix first.tasks := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  simp [prefix_dead,Prefix,ids]

theorem advance_prefix (hs : Prefix s.tasks)
    (ht : Counted.advance p n s = .ok t) : Prefix t.tasks := by
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
        exact ih (s := commit c) (transition_prefix hs hc) ht

theorem reachable_prefix (hr : Statements.Reachable p initial s) : Prefix s.tasks := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_prefix (begin_prefix hb) hn

theorem mem_ids : bid ∈ ids ts ↔ Task.giveBinding bid ∈ ts := by
  induction ts with
  | nil => simp [ids]
  | cons task ts ih => cases task <;> simp [ids,ih]

theorem dead_unique (hu : (env.map Prod.snd).Nodup) :
    (ids (dead bs env future)).Nodup := by
  obtain ⟨names,he,hn⟩ := EnvironmentIdentity.dead_unique (bindings := bs) (future := future) hu
  simpa only [he,ids_named] using hn

set_option maxHeartbeats 2000000 in
theorem transition_unique (hp : Prefix s.tasks) (hu : (ids s.tasks).Nodup)
    (henv : EnvironmentIdentity.Invariant s)
    (ht : Counted.transition p s = .ok c) : (ids c.state.tasks).Nodup := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    have hctx := henv.2 task (by simp [he])
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp_all only [he,Prefix,ids,ids_append,ids_arguments,ids_reserved,
      EnvironmentIdentity.TaskOK,List.nil_append,List.append_nil,List.nodup_cons,List.nodup_nil,
      List.not_mem_nil,true_and,and_true]
    all_goals first
      | assumption
      | trivial
      | exact dead_unique hctx.1
      | solve | apply dead_unique; simp
      | exact dead_unique (EnvironmentIdentity.parameter_env _ _ _ _).1

theorem begin_unique (hb : Counted.begin p initial = .ok first) :
    (ids first.tasks).Nodup := by
  have he := (EnvironmentIdentity.begin_invariant hb).1.1
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  simpa only [ids_append,ids,List.append_nil] using dead_unique he

theorem advance_unique (hp : Prefix s.tasks) (hu : (ids s.tasks).Nodup)
    (he : EnvironmentIdentity.Invariant s)
    (ht : Counted.advance p n s = .ok t) : (ids t.tasks).Nodup := by
  induction n generalizing s with
  | zero => cases ht; exact hu
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hu
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        exact ih (s := commit c) (transition_prefix hp hc) (transition_unique hp hu he hc)
          (EnvironmentIdentity.transition_invariant he hc) ht

theorem reachable_unique (hr : Statements.Reachable p initial s) : (ids s.tasks).Nodup := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_unique (begin_prefix hb) (begin_unique hb)
    (EnvironmentIdentity.begin_invariant hb) hn

def Ready (bs : List Binding) (tasks : List Task) : Prop :=
  ∀ bid ∈ ids tasks, ∃ b ∈ bs, b.record.id = bid ∧ b.record.status = .holding

theorem dead_ready (bs : List Binding) (env : Env) (future : List Task) :
    Ready bs (dead bs env future) := by
  intro bid hm
  have ht := mem_ids.mp hm
  obtain ⟨⟨name,id⟩,_,h⟩ := List.mem_filterMap.mp ht
  dsimp only at h
  split at h
  · rename_i hc
    cases Option.some.inj h
    have hb := (Bool.and_eq_true_iff.mp hc).1
    obtain ⟨b,hb,hh⟩ := List.any_eq_true.mp hb
    exact ⟨b,hb,by simpa using (Bool.and_eq_true_iff.mp hh).1,
      by simpa using (Bool.and_eq_true_iff.mp hh).2⟩
  · contradiction

theorem ready_no_ids (h : ids tasks = []) : Ready bs tasks := by
  intro bid hm
  simp [h] at hm

theorem ready_append (ha : Ready bs a) (hb : Ready bs b) : Ready bs (a ++ b) := by
  intro bid hm
  rw [ids_append] at hm
  rcases List.mem_append.mp hm with hm | hm
  · exact ha bid hm
  · exact hb bid hm

theorem ready_update {s : State} (hs : Ready s.bindings s.tasks)
    (ht : s.tasks = .giveBinding released :: rest) (hu : (ids s.tasks).Nodup)
    (status : Trial.BStatus) :
    Ready (s.bindings.map (fun b => if b.record.id == released then
      { b with record := { b.record with status := status } } else b)) rest := by
  intro bid hm
  obtain ⟨b,hb,hid,hh⟩ := hs bid (by simp [ht,ids,hm])
  have hne : b.record.id ≠ released := by
    simp only [ht,ids,List.nodup_cons] at hu
    intro he
    exact hu.1 (by simpa [← hid,he] using hm)
  refine ⟨b,?_,hid,hh⟩
  exact List.mem_map.mpr ⟨b,hb,by simp [hne]⟩

set_option maxHeartbeats 2000000 in
theorem transition_ready (hp : Prefix s.tasks) (hu : (ids s.tasks).Nodup)
    (hs : Ready s.bindings s.tasks) (ht : Counted.transition p s = .ok c) :
    Ready c.state.bindings c.state.tasks := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try exact ready_update hs he hu .givenUp
    all_goals simp_all only [he,Prefix,ids,ids_append,ids_arguments,ids_reserved,
      List.nil_append,List.append_nil]
    all_goals try first
      | exact hs
      | solve | apply ready_no_ids; simp_all [ids,ids_append,ids_arguments,ids_reserved]
      | solve | apply ready_append (dead_ready _ _ _); apply ready_no_ids; simp_all [ids]
    all_goals intro bid hm
    all_goals try simp only [ids_append,ids,hp,List.mem_append,List.mem_cons,List.not_mem_nil,or_false] at hm
    all_goals first
      | exact hs bid hm
      | (subst bid
         refine ⟨_,List.mem_append_right _ (List.mem_cons_of_mem _ (List.mem_singleton_self _)),rfl,?_⟩
         simp_all [makeBinding]
         split <;> simp_all [← Option.eq_none_iff_forall_ne_some])

theorem begin_ready (hb : Counted.begin p initial = .ok first) :
    Ready first.bindings first.tasks := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  exact ready_append (dead_ready _ _ _) (ready_no_ids rfl)

theorem advance_ready (hp : Prefix s.tasks) (hu : (ids s.tasks).Nodup)
    (he : EnvironmentIdentity.Invariant s) (hs : Ready s.bindings s.tasks)
    (ht : Counted.advance p n s = .ok t) : Ready t.bindings t.tasks := by
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
        exact ih (s := commit c) (transition_prefix hp hc) (transition_unique hp hu he hc)
          (EnvironmentIdentity.transition_invariant he hc) (transition_ready hp hu hs hc) ht

theorem reachable_ready (hr : Statements.Reachable p initial s) : Ready s.bindings s.tasks := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_ready (begin_prefix hb) (begin_unique hb)
    (EnvironmentIdentity.begin_invariant hb) (begin_ready hb) hn

/-- A queued named release always resolves to a still-held nonempty list.
Heap liveness/counts are a separate obligation; no F1 premise is used here. -/
theorem reachable_binding (hr : Statements.Reachable p initial s)
    (hm : Task.giveBinding bid ∈ s.tasks) :
    ∃ b addr, s.bindings.find? (fun b => b.record.id == bid) = some b ∧
      b.record.status = .holding ∧ b.record.value = .list (some addr) := by
  obtain ⟨b,hb,hid,hh⟩ := reachable_ready hr bid (mem_ids.mpr hm)
  obtain ⟨addr,hraw⟩ := HoldingAccounted.reachable_holder_form hr b hb hh
  exact ⟨b,addr,by simpa [hid] using
    Initial.find_key_self s.bindings (fun b => b.record.id) (BindingIdentity.reachable_unique hr) b hb,
    hh,hraw⟩

theorem task_uses_bound (he : EnvironmentIdentity.TaskOK next task)
    (hu : taskUses bid task = true) : bid < next := by
  obtain ⟨x,hx⟩ := HoldingAccounted.task_use_mem hu
  cases task <;> simp only [HoldingAccounted.useEnv] at hx <;> try contradiction
  all_goals exact he.2 (x,bid) hx

theorem tasks_fresh_unused (he : EnvironmentIdentity.TasksOK next tasks) (hn : next ≤ bid) :
    tasks.any (taskUses bid) = false := by
  cases hu : tasks.any (taskUses bid) with
  | false => rfl
  | true =>
    obtain ⟨task,hm,ht⟩ := List.any_eq_true.mp hu
    have := task_uses_bound (he task hm) ht
    omega

def Quiet (tasks : List Task) : Prop :=
  ∀ bid ∈ ids tasks, tasks.any (taskUses bid) = false

theorem quiet_no_ids (h : ids tasks = []) : Quiet tasks := by
  intro bid hm
  simp [h] at hm

theorem dead_unused (bs : List Binding) (env : Env) (future : List Task) (bid : Nat) :
    (dead bs env future).any (taskUses bid) = false := by
  obtain ⟨names,he⟩ := SimulationInitial.dead_is_prefix bs env future
  simp [he,taskUses]

theorem quiet_dead (h : ids future = []) : Quiet (dead bs env future ++ future) := by
  intro bid hm
  simp only [ids_append,h,List.append_nil] at hm
  have ht := mem_ids.mp hm
  obtain ⟨pair,_,hh⟩ := List.mem_filterMap.mp ht
  dsimp only at hh
  split at hh
  · rename_i hc
    cases Option.some.inj hh
    simp only [List.any_append,dead_unused,Bool.false_or]
    simpa using (Bool.and_eq_true_iff.mp hc).2
  · contradiction

set_option maxHeartbeats 2000000 in
theorem transition_quiet (hp : Prefix s.tasks) (hq : Quiet s.tasks)
    (henv : EnvironmentIdentity.Invariant s)
    (ht : Counted.transition p s = .ok c) : Quiet c.state.tasks := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    have hrest : EnvironmentIdentity.TasksOK s.nextBinding rest := by
      intro t hm
      exact henv.2 t (by simp [he,hm])
    have hfresh := tasks_fresh_unused (bid := s.nextBinding+1) hrest (by omega)
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp_all only [he,Prefix,ids,ids_append,ids_arguments,ids_reserved,
      List.nil_append,List.append_nil]
    all_goals try first
      | exact hq
      | solve | apply quiet_no_ids; simp_all [ids,ids_append,ids_arguments,ids_reserved]
      | solve | apply quiet_dead; simp_all [ids]
    all_goals intro bid hm
    all_goals try simp only [ids_append,ids,hp,List.mem_append,List.mem_cons,List.not_mem_nil,or_false] at hm
    all_goals first
      | solve | have h := hq bid (by simp [ids,hm]); simpa [taskUses] using h
      | (subst bid
         simp_all [List.any_append,taskUses,child])

theorem begin_quiet (hb : Counted.begin p initial = .ok first) : Quiet first.tasks := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  exact quiet_dead rfl

theorem advance_quiet (hp : Prefix s.tasks) (hq : Quiet s.tasks)
    (he : EnvironmentIdentity.Invariant s) (ht : Counted.advance p n s = .ok t) :
    Quiet t.tasks := by
  induction n generalizing s with
  | zero => cases ht; exact hq
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hq
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        exact ih (s := commit c) (transition_prefix hp hc) (transition_quiet hp hq he hc)
          (EnvironmentIdentity.transition_invariant he hc) ht

theorem reachable_quiet (hr : Statements.Reachable p initial s) : Quiet s.tasks := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_quiet (begin_prefix hb) (begin_quiet hb) (EnvironmentIdentity.begin_invariant hb) hn

end Full.Proofs.ReleaseQueue
