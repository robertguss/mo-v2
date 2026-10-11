import Full.Proofs.ReleaseQueue

namespace Full.Proofs.LiveBindings
open Counted

theorem parameters_unused (pairs : List ((String × Kind) × Slot))
    (next invocation : Nat) (name : String) (e : Expr) (hb : bid < next) :
    uses e (Trial.toFEnv
      ((pairs.zipIdx.map (fun (((x,_),v),i) =>
        makeBinding (next+i) x v invocation s!"{name}/parameter/{x}")).reverse.map
          (fun b => (b.record.name,b.record.id)))) bid = false := by
  cases hu : uses e (Trial.toFEnv
      ((pairs.zipIdx.map (fun (((x,_),v),i) =>
        makeBinding (next+i) x v invocation s!"{name}/parameter/{x}")).reverse.map
          (fun b => (b.record.name,b.record.id)))) bid with
  | false => rfl
  | true =>
    obtain ⟨x,hx⟩ := HoldingAccounted.uses_mem _ _ _ hu
    obtain ⟨b,hbmem,he⟩ := List.mem_map.mp (HoldingAccounted.toFEnv_mem hx)
    have hid : b.record.id = bid := congrArg Prod.snd he
    have hm : bid ∈ (List.range pairs.length).map (next+·) := by
      rw [← BindingIdentity.parameter_ids pairs next invocation name]
      exact List.mem_map.mpr ⟨b,List.mem_reverse.mp hbmem,hid⟩
    obtain ⟨i,_,hi⟩ := List.mem_map.mp hm
    omega

set_option maxHeartbeats 2000000 in
/-- A transfer cannot introduce a new source use of an already allocated
binding. New lexical bindings and callee parameters have fresh identities. -/
theorem transition_old_uses (hb : bid < s.nextBinding)
    (ht : Counted.transition p s = .ok c)
    (hu : c.state.tasks.any (taskUses bid) = true) : s.tasks.any (taskUses bid) = true := by
  have hshadow := fun e env x => HoldingAccounted.uses_fresh_shadow e env x
    s.nextBinding bid (by omega : s.nextBinding ≠ bid)
  have hpair := fun e env head tail => HoldingAccounted.uses_fresh_pair e env head tail
    s.nextBinding (s.nextBinding+1) bid (by omega) (by omega)
  have hparameters := fun pairs invocation name e => parameters_unused pairs s.nextBinding invocation name e hb
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp only [List.any_append,ReleaseQueue.dead_unused,Bool.false_or,
      List.any_cons,List.any_nil,taskUses,child,Bool.or_false,Bool.false_or] at hu ⊢
    all_goals try simp only [hparameters,Bool.false_or] at hu
    all_goals try simp only [Trial.toFEnv,List.map_cons,makeBinding,hshadow,hpair] at hu
    all_goals try simpa only [he,List.any_cons,taskUses] using hu
    all_goals simp [he,taskUses,uses,child,List.any_append,Trial.toFEnv] at hu ⊢
    all_goals first
      | solve | grind
      | (rcases hu with ⟨a,i,hi,hu⟩ | hu
         · exact Or.inl ⟨a,List.fst_mem_of_mem_zipIdx hi,hu⟩
         · exact Or.inr hu)

def Live (s : State) : Prop :=
  ∀ b ∈ s.bindings, ∀ addr, b.record.value = .list (some addr) →
    s.tasks.any (taskUses b.record.id) = true → b.record.status = .holding

theorem begin_live (hb : Counted.begin p initial = .ok first) : Live first := by
  intro b hm addr hraw _
  have hh := (Initial.begin_binding_readable p initial first hb b hm).2.2
  simpa [Inspect.link,hraw] using hh.symm

theorem make_live {id : Nat} (hraw : (makeBinding id name v invocation origin).record.value = .list (some addr)) :
    (makeBinding id name v invocation origin).record.status = .holding := by
  change v.raw = .list (some addr) at hraw
  simp [makeBinding,hraw]

theorem update_live (bs : List Binding) (ts : List Task) (id : Nat) (status : Trial.BStatus)
    (old : ∀ b ∈ bs, ∀ addr, b.record.value = .list (some addr) →
      ts.any (taskUses b.record.id) = true → b.record.status = .holding)
    (unused : ts.any (taskUses id) = false) :
    ∀ b ∈ bs.map (fun b => if b.record.id == id then
      { b with record := { b.record with status := status } } else b),
      ∀ addr, b.record.value = .list (some addr) →
        ts.any (taskUses b.record.id) = true → b.record.status = .holding := by
  intro b hm addr hraw hu
  obtain ⟨q,hq,rfl⟩ := List.mem_map.mp hm
  by_cases hid : q.record.id = id
  · simp [hid,unused] at hu
  · simp only [show (q.record.id == id) = false from by simp [hid], Bool.false_eq_true,
      ↓reduceIte] at hraw hu ⊢
    exact old q hq addr hraw hu

set_option maxHeartbeats 2000000 in
theorem transition_live (hs : Live s)
    (hbound : ∀ b ∈ s.bindings, b.record.id < s.nextBinding)
    (henv : EnvironmentIdentity.Invariant s) (hquiet : ReleaseQueue.Quiet s.tasks)
    (ht : Counted.transition p s = .ok c) : Live c.state := by
  have old : ∀ b ∈ s.bindings, ∀ addr, b.record.value = .list (some addr) →
      c.state.tasks.any (taskUses b.record.id) = true → b.record.status = .holding := by
    intro b hm addr hraw hu
    exact hs b hm addr hraw (transition_old_uses (hbound b hm) ht hu)
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    have hfresh := ReleaseQueue.tasks_fresh_unused (bid := s.nextBinding+1)
      (show EnvironmentIdentity.TasksOK s.nextBinding rest from
        fun t hm => henv.2 t (by simp [he,hm])) (by omega)
    have hreleased : ∀ id, task = .giveBinding id → rest.any (taskUses id) = false := by
      intro id hi
      have hh := hquiet id (by simp [he,hi,ReleaseQueue.ids])
      simpa [he,hi,taskUses] using hh
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try solve
      | apply update_live _ _ _ _ old
        simp_all [taskUses]
    all_goals intro b hm addr hraw hu
    all_goals try exact old b hm addr hraw hu
    all_goals rcases List.mem_append.mp hm with hm | hm
    all_goals try exact old b hm addr hraw hu
    all_goals try
      obtain ⟨pair,_,rfl⟩ := List.mem_map.mp hm
      exact make_live hraw
    all_goals try
      have hb := List.mem_singleton.mp hm
      subst b
      exact make_live hraw
    all_goals simp only [List.mem_cons,List.not_mem_nil,or_false] at hm
    all_goals rcases hm with rfl | rfl
    all_goals simp_all [makeBinding,taskUses,child,List.any_append]
    all_goals obtain ⟨x,hx,hu⟩ := hu
    all_goals exact Bool.noConfusion ((hfresh x hx).symm.trans hu)

theorem advance_live (hs : Live s)
    (hi : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding)
    (he : EnvironmentIdentity.Invariant s) (hp : ReleaseQueue.Prefix s.tasks)
    (hq : ReleaseQueue.Quiet s.tasks) (ht : Counted.advance p n s = .ok t) : Live t := by
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
        have hb : ∀ b ∈ s.bindings, b.record.id < s.nextBinding := by
          intro b hm
          apply List.mem_range.mp
          rw [← hi]
          exact List.mem_map.mpr ⟨b,hm,rfl⟩
        exact ih (s := commit c) (transition_live hs hb he hq hc)
          (BindingIdentity.transition_ids hi hc) (EnvironmentIdentity.transition_invariant he hc)
          (ReleaseQueue.transition_prefix hp hc) (ReleaseQueue.transition_quiet hp hq he hc) ht

theorem reachable_live (hr : Statements.Reachable p initial s) : Live s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_live (begin_live hb) (BindingIdentity.begin_ids hb)
    (EnvironmentIdentity.begin_invariant hb) (ReleaseQueue.begin_prefix hb)
    (ReleaseQueue.begin_quiet hb) hn

end Full.Proofs.LiveBindings
