import Full.Proofs.BindingIdentity
import Full.Proofs.ControlShape
import Proofs.Liveness

namespace Full.Proofs.HoldingAccounted
open Counted

/-- A holder is accounted for by saved source text or an explicit release.
This predicate says nothing about whether executing that work will succeed. -/
def Accounted (s : State) : Prop :=
  ∀ b ∈ s.bindings, b.record.status = .holding →
    s.tasks.any (taskUses b.record.id) = true ∨ .giveBinding b.record.id ∈ s.tasks

/-- Resolved uses come from the environment, not just an equal spelling.
The call case inspects arguments only, never a callee body. -/
theorem uses_mem (e : Expr) (env : Trial.FEnv) (id : Nat)
    (hu : uses e env id = true) : ∃ x, (x,some id) ∈ env := by
  match e with
  | .num n => simp [uses] at hu
  | .bool b => simp [uses] at hu
  | .nil => simp [uses] at hu
  | .var x =>
    exact ⟨x,Trial.Proofs.lookup_frame_mem env x id (by simpa [uses] using hu)⟩
  | .bin op a b =>
    simp only [uses,Bool.or_eq_true] at hu
    rcases hu with ha | hb
    · exact uses_mem a env id ha
    · exact uses_mem b env id hb
  | .letE x a b =>
    simp only [uses,Bool.or_eq_true] at hu
    rcases hu with ha | hb
    · exact uses_mem a env id ha
    · obtain ⟨y,hy⟩ := uses_mem b ((x,none)::env) id hb
      exact ⟨y,by simpa using hy⟩
  | .ifE c t f =>
    simp only [uses,Bool.or_eq_true] at hu
    rcases hu with (hc | ht) | hf
    · exact uses_mem c env id hc
    · exact uses_mem t env id ht
    · exact uses_mem f env id hf
  | .matchE s n h t c =>
    simp only [uses,Bool.or_eq_true] at hu
    rcases hu with (hs | hn) | hc
    · exact uses_mem s env id hs
    · exact uses_mem n env id hn
    · obtain ⟨x,hx⟩ := uses_mem c ((t,none)::(h,none)::env) id hc
      exact ⟨x,by simpa using hx⟩
  | .call name args =>
    simp only [uses] at hu
    obtain ⟨a,_,ha⟩ := List.any_eq_true.mp hu
    exact uses_mem a.val env id ha
termination_by sizeOf e
decreasing_by
  all_goals simp_wf
  all_goals first | omega | (have h := List.sizeOf_lt_of_mem a.property; omega)

theorem toFEnv_mem {x : String} {id : Nat} {env : Env}
    (hm : (x,some id) ∈ Trial.toFEnv env) : (x,id) ∈ env := by
  obtain ⟨⟨y,j⟩,hy,he⟩ := List.mem_map.mp hm
  simp only [Prod.mk.injEq,Option.some.injEq] at he
  rcases he with ⟨rfl,rfl⟩
  exact hy

/-- Context of the only task forms that can contain a future source use. -/
def useEnv : Task → Env
  | .eval _ ctx | .bind _ _ ctx | .chooseIf _ _ ctx |
    .chooseMatch _ _ _ _ ctx | .decompose _ _ _ _ ctx => ctx.env
  | _ => []

theorem task_use_mem {id : Nat} {task : Task}
    (hu : taskUses id task = true) : ∃ x, (x,id) ∈ useEnv task := by
  cases task <;> simp only [taskUses,Bool.or_eq_true] at hu
  all_goals try contradiction
  all_goals try (rcases hu with hu | hu)
  all_goals obtain ⟨x,hx⟩ := uses_mem _ _ id hu
  all_goals try simp only [List.mem_cons,Prod.mk.injEq,reduceCtorEq,and_false,false_or] at hx
  all_goals exact ⟨x,toFEnv_mem hx⟩

/-- Dead-name pruning really installs the release, including for a binding
hidden by a nearer spelling in the lexical environment. -/
theorem dead_mem (hb : b ∈ bs) (hh : b.record.status = .holding)
    (he : (x,b.record.id) ∈ env)
    (hu : future.any (taskUses b.record.id) = false) :
    .giveBinding b.record.id ∈ dead bs env future := by
  have ha : bs.any (fun q => q.record.id == b.record.id && q.record.status == .holding) = true :=
    List.any_eq_true.mpr ⟨b,hb,by simp [hh]⟩
  apply List.mem_filterMap.mpr
  exact ⟨(x,b.record.id),List.mem_reverse.mpr he,by simp [ha,hu]⟩

/-- If discarded text was the last use, pruning its own context schedules
release. In particular a masked branch use cannot originate outside it. -/
theorem dropped_use_released (hb : b ∈ bs) (hh : b.record.status = .holding)
    (hu : taskUses b.record.id task = true)
    (hn : future.any (taskUses b.record.id) = false) :
    .giveBinding b.record.id ∈ dead bs (useEnv task) future := by
  obtain ⟨x,hx⟩ := task_use_mem hu
  exact dead_mem hb hh hx hn

/-- Replacing a source task may discard arbitrary branches: pruning its
context accounts for every lost last use while the saved suffix survives. -/
theorem prune_accounted (hs : Accounted s) (ht : s.tasks = task :: rest)
    (hg : ∀ id, task ≠ .giveBinding id)
    (hn : ∀ t ∈ rest, t ∈ next) :
    Accounted { s with tasks := dead s.bindings (useEnv task) next ++ next } := by
  intro b hb hh
  change (dead s.bindings (useEnv task) next ++ next).any (taskUses b.record.id) = true ∨
    .giveBinding b.record.id ∈ dead s.bindings (useEnv task) next ++ next
  cases hu : next.any (taskUses b.record.id) with
  | true => left; simp [List.any_append,hu]
  | false =>
    right
    rcases hs b hb hh with hf | hf
    · obtain ⟨t,hm,huse⟩ := List.any_eq_true.mp hf
      rw [ht] at hm
      rcases List.mem_cons.mp hm with rfl | hm
      · exact List.mem_append_left _ (dropped_use_released hb hh huse hu)
      · have hc := List.any_eq_true.mpr ⟨t,hn t hm,huse⟩
        rw [hu] at hc
        contradiction
    · rw [ht] at hf
      rcases List.mem_cons.mp hf with he | hf
      · exact False.elim (hg b.record.id he.symm)
      · exact List.mem_append_right _ (hn _ hf)

/-- Actual conditional pruning preserves ownership accounting even when the
selected branch drops the sole use of an old lexical binding. -/
theorem chooseIf_accounted (hs : Accounted s)
    (htasks : s.tasks = .chooseIf yes no ctx :: rest)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  simp only [Counted.transition,htasks,pure,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals exact prune_accounted hs htasks (by intro id; simp) (by
    intro t hm
    exact List.mem_append_right _ hm)

/-- Both the nil and cell alternatives of the actual match choose step are
covered; no assumption about the execution of the selected branch is made. -/
theorem chooseMatch_accounted (hs : Accounted s)
    (htasks : s.tasks = .chooseMatch empty head tail body ctx :: rest)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  simp only [Counted.transition,htasks,pure,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals exact prune_accounted hs htasks (by intro id; simp) (by
    intro t hm
    exact List.mem_append_right _ hm)

/-- All holding bindings listed in the cleanup environment are accounted for
after pruning; no uniqueness or successful-future premise is required. -/
theorem dead_accounts (bs : List Binding) (env : Env) (future : List Task)
    (he : ∀ b ∈ bs, b.record.status = .holding → ∃ x, (x,b.record.id) ∈ env) :
    ∀ b ∈ bs, b.record.status = .holding →
      (dead bs env future ++ future).any (taskUses b.record.id) = true ∨
      .giveBinding b.record.id ∈ dead bs env future ++ future := by
  intro b hb hh
  cases hu : future.any (taskUses b.record.id) with
  | true => left; simp [List.any_append,hu]
  | false =>
    obtain ⟨x,hx⟩ := he b hb hh
    exact Or.inr (List.mem_append_left _ (dead_mem hb hh hx hu))

theorem begin_accounted (hb : Counted.begin p initial = .ok first) : Accounted first := by
  obtain ⟨_,edges,bs,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  apply dead_accounts
  intro b hm _
  exact ⟨b.record.name,List.mem_map.mpr ⟨b,List.mem_reverse.mpr hm,rfl⟩⟩

theorem uses_congr (e : Expr) (env env' : Trial.FEnv) (bid : Nat)
    (he : ∀ x, Trial.lookupF env x = some (some bid) ↔
      Trial.lookupF env' x = some (some bid)) : uses e env bid = uses e env' bid := by
  match e with
  | .num _ | .bool _ | .nil => simp [uses]
  | .var x => exact Bool.eq_iff_iff.mpr (by simpa [uses] using he x)
  | .bin op a b => simp only [uses, uses_congr a env env' bid he, uses_congr b env env' bid he]
  | .letE x a b =>
    simp only [uses, uses_congr a env env' bid he,
      uses_congr b _ _ bid (Trial.Proofs.lookup_cons_same env env' bid he x none)]
  | .ifE c t f =>
    simp only [uses, uses_congr c env env' bid he, uses_congr t env env' bid he,
      uses_congr f env env' bid he]
  | .matchE a n h t c =>
    simp only [uses, uses_congr a env env' bid he, uses_congr n env env' bid he,
      uses_congr c _ _ bid (Trial.Proofs.lookup_cons_same _ _ bid
        (Trial.Proofs.lookup_cons_same env env' bid he h none) t none)]
  | .call name args =>
    simp only [uses]
    apply congrArg (fun f => args.attach.any f)
    funext a
    exact uses_congr a.val env env' bid he
termination_by sizeOf e
decreasing_by
  all_goals simp_wf
  all_goals first | omega | (have h := List.sizeOf_lt_of_mem a.property; omega)

theorem uses_fresh_shadow (e : Expr) (env : Trial.FEnv) (name : String) (fresh bid : Nat)
    (hne : fresh ≠ bid) :
    uses e ((name,some fresh)::env) bid = uses e ((name,none)::env) bid := by
  apply uses_congr
  intro x
  by_cases hx : name = x <;> simp [Trial.lookupF, hx, hne]

/-- Replacement source text must retain each old resolved use; queued cleanup
and the saved suffix are carried along literally. This is a local text check. -/
theorem replace_head_accounted (hs : Accounted s) (ht : s.tasks = task :: rest)
    (hu : ∀ bid, taskUses bid task = true → next.any (taskUses bid) = true)
    (hg : ∀ bid, task = .giveBinding bid → .giveBinding bid ∈ next)
    (hr : ∀ t ∈ rest, t ∈ next) : Accounted { s with tasks := next } := by
  intro b hb hh
  rcases hs b hb hh with h | h
  · left
    obtain ⟨t,hm,htuse⟩ := List.any_eq_true.mp h
    rw [ht] at hm
    rcases List.mem_cons.mp hm with rfl | hm
    · exact hu b.record.id htuse
    · exact List.any_eq_true.mpr ⟨t,hr t hm,htuse⟩
  · right
    rw [ht] at h
    rcases List.mem_cons.mp h with h | h
    · exact hg b.record.id h.symm
    · exact hr _ h

theorem bind_accounted (hs : Accounted s)
    (hbound : ∀ b ∈ s.bindings, b.record.id < s.nextBinding)
    (htasks : s.tasks = .bind name body ctx :: rest)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  simp only [Counted.transition, htasks, pure, Except.pure] at ht
  split at ht
  · rename_i v slots hslots
    cases ht
    intro b hb hh
    dsimp only at hb hh ⊢
    let bs := s.bindings ++ [makeBinding s.nextBinding name v ctx.invocation s!"{ctx.site}/binding"]
    let inner : Context := { ctx with env := (name,s.nextBinding)::ctx.env }
    let future : List Task := [.eval body (child inner 1),.handoff] ++ rest
    change (dead bs [(name,s.nextBinding)] future ++ future).any (taskUses b.record.id) = true ∨
      .giveBinding b.record.id ∈ dead bs [(name,s.nextBinding)] future ++ future
    cases hu : future.any (taskUses b.record.id) with
    | true => left; simp [List.any_append, hu]
    | false =>
      right
      rcases List.mem_append.mp hb with hb | hb
      · rcases hs b hb hh with huse | hgive
        · have hne : s.nextBinding ≠ b.record.id := by have := hbound b hb; omega
          have hshadow := uses_fresh_shadow body (Trial.toFEnv ctx.env) name
            s.nextBinding b.record.id hne
          have hfuture : future.any (taskUses b.record.id) = true := by
            change (uses body ((name,some s.nextBinding)::Trial.toFEnv ctx.env) b.record.id ||
              (false || rest.any (taskUses b.record.id))) = true
            rw [hshadow]
            simpa only [htasks, List.any_cons, taskUses, Bool.false_or] using huse
          rw [hu] at hfuture
          contradiction
        · have hm : .giveBinding b.record.id ∈ rest := by simpa [htasks] using hgive
          exact List.mem_append_right _ (List.mem_append_right _ hm)
      · have he : b = makeBinding s.nextBinding name v ctx.invocation s!"{ctx.site}/binding" :=
          List.mem_singleton.mp hb
        apply List.mem_append_left
        apply dead_mem (b := b) (x := name) (by simp [bs, he]) hh
        · simp [he, makeBinding]
        · exact hu
  · contradiction

theorem append_pruned (hs : Accounted s) (added : List Binding) (env : Env)
    (future : List Task) (hkeep : ∀ t ∈ s.tasks, t ∈ future)
    (hnew : ∀ b ∈ added, b.record.status = .holding → ∃ x, (x,b.record.id) ∈ env) :
    Accounted { s with
      bindings := s.bindings ++ added,
      tasks := dead (s.bindings ++ added) env future ++ future } := by
  intro b hb hh
  change (dead (s.bindings ++ added) env future ++ future).any (taskUses b.record.id) = true ∨
    .giveBinding b.record.id ∈ dead (s.bindings ++ added) env future ++ future
  cases hu : future.any (taskUses b.record.id) with
  | true => left; simp [List.any_append, hu]
  | false =>
    right
    rcases List.mem_append.mp hb with hb | hb
    · rcases hs b hb hh with huse | hgive
      · obtain ⟨t,hm,ht⟩ := List.any_eq_true.mp huse
        have hc := List.any_eq_true.mpr ⟨t,hkeep t hm,ht⟩
        rw [hu] at hc
        contradiction
      · exact List.mem_append_right _ (hkeep _ hgive)
    · obtain ⟨x,hx⟩ := hnew b hb hh
      exact List.mem_append_left _ (dead_mem (List.mem_append_right _ hb) hh hx hu)

theorem enter_accounted (hs : Accounted s)
    (htasks : s.tasks = .enter name arity ctx :: rest)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  have hbase : Accounted { s with tasks := rest } :=
    replace_head_accounted hs htasks (by simp [taskUses]) (by intro bid h; cases h)
      (by intro t hm; exact hm)
  simp only [Counted.transition, htasks, pure, bind, Except.pure, Except.bind] at ht
  repeat' first | split at ht | cases ht | contradiction
  apply append_pruned (s := { s with tasks := rest }) hbase
  · intro t hm
    exact List.mem_append_right _ hm
  · intro b hb _
    exact ⟨b.record.name,List.mem_map.mpr ⟨b,List.mem_reverse.mpr hb,rfl⟩⟩

theorem uses_fresh_pair (body : Expr) (env : Trial.FEnv) (head tail : String)
    (hid tid bid : Nat) (hh : hid ≠ bid) (ht : tid ≠ bid) :
    uses body ((tail,some tid)::(head,some hid)::env) bid =
      uses body ((tail,none)::(head,none)::env) bid := by
  apply uses_congr
  intro x
  by_cases he : tail = x <;> by_cases he' : head = x <;>
    simp [Trial.lookupF, he, he', hh, ht]

set_option maxHeartbeats 1000000 in
theorem decompose_accounted (hs : Accounted s)
    (hbound : ∀ b ∈ s.bindings, b.record.id < s.nextBinding)
    (htasks : s.tasks = .decompose head tail body branch ctx :: rest)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  simp only [Counted.transition, htasks, pure, bind, Except.pure, Except.bind] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals intro b hb hh
  all_goals dsimp only at hb hh ⊢
  all_goals rcases List.mem_append.mp hb with hb | hb
  all_goals first
    | (have hold := hs b hb hh
       have hne : s.nextBinding ≠ b.record.id := by have := hbound b hb; omega
       have hne' : s.nextBinding+1 ≠ b.record.id := by have := hbound b hb; omega
       have hshadow := uses_fresh_pair body (Trial.toFEnv ctx.env) head tail
         s.nextBinding (s.nextBinding+1) b.record.id hne hne'
       rcases hold with hu | hg
       · left
         have hu' : (uses body
             (Trial.toFEnv ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env)) b.record.id ||
             rest.any (taskUses b.record.id)) = true := by
           change (uses body ((tail,some (s.nextBinding+1))::(head,some s.nextBinding)::
             Trial.toFEnv ctx.env) b.record.id || rest.any (taskUses b.record.id)) = true
           rw [hshadow]
           simpa only [htasks, List.any_cons, taskUses] using hu
         simpa only [List.any_append, List.any_cons, List.any_nil, taskUses, child,
           Bool.false_or, Bool.or_false] using hu'
       · right
         have hm : .giveBinding b.record.id ∈ rest := by simpa [htasks] using hg
         simp [hm])
    | (simp only [List.mem_cons, List.not_mem_nil, or_false] at hb
       rcases hb with rfl | rfl
       all_goals simp_all [makeBinding, taskUses, child, Trial.toFEnv])
  all_goals split at hh <;> simp_all

def HolderForm (bs : List Binding) : Prop :=
  ∀ b ∈ bs, b.record.status = .holding → ∃ a, b.record.value = .list (some a)

theorem make_holder (hh : (makeBinding bid name v invocation origin holding).record.status = .holding) :
    ∃ a, (makeBinding bid name v invocation origin holding).record.value = .list (some a) := by
  cases hv : v.raw with
  | num n | bool b => simp [makeBinding, hv] at hh
  | list a => cases a <;> simp_all [makeBinding]

theorem holder_append (ha : HolderForm a) (hb : HolderForm b) : HolderForm (a ++ b) := by
  intro q hq hh
  rcases List.mem_append.mp hq with hq | hq
  · exact ha q hq hh
  · exact hb q hq hh

theorem holder_update (hs : HolderForm bs) (bid : Nat) (status : Trial.BStatus)
    (hne : status ≠ .holding) : HolderForm (bs.map (fun b => if b.record.id == bid then
      { b with record := { b.record with status := status } } else b)) := by
  intro b hb hh
  obtain ⟨q,hq,rfl⟩ := List.mem_map.mp hb
  split at hh
  · exact False.elim (hne hh)
  · simpa only [if_neg (by assumption)] using hs q hq hh

theorem begin_holder_form (hb : Counted.begin p initial = .ok first) : HolderForm first.bindings := by
  intro b hm hh
  have hf := (Initial.begin_binding_readable p initial first hb b hm).2.2
  cases hv : b.record.value with
  | num n | bool b => simp [Inspect.link, hv, hh] at hf
  | list a => cases a <;> simp_all [Inspect.link]

set_option maxHeartbeats 1000000 in
theorem transition_holder_form (hs : HolderForm s.bindings)
    (ht : Counted.transition p s = .ok c) : HolderForm c.state.bindings := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals first
      | exact hs
      | solve | apply holder_update hs <;> simp
      | apply holder_append hs
    all_goals intro b hb hh
    all_goals first
      | (simp only [List.mem_cons, List.not_mem_nil, or_false] at hb
         first
           | (subst b; exact make_holder hh)
           | (rcases hb with rfl | rfl <;> exact make_holder hh))
      | (obtain ⟨q,hq,rfl⟩ := List.mem_map.mp hb; exact make_holder hh)

theorem advance_holder_form (hs : HolderForm s.bindings)
    (ht : Counted.advance p n s = .ok t) : HolderForm t.bindings := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance, ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance, Counted.step, ha, hc] at ht
      | ok c =>
        simp [Counted.advance, Counted.step, ha, hc] at ht
        exact ih (s := commit c) (transition_holder_form hs hc) ht

theorem reachable_holder_form (hr : Statements.Reachable p initial s) : HolderForm s.bindings := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_holder_form (begin_holder_form hb) hn

theorem deactivate_accounted (hs : Accounted s) (ht : s.tasks = task :: rest)
    (hu : ∀ id, taskUses id task = true → id = bid)
    (hg : ∀ id, task = .giveBinding id → id = bid)
    (hkeep : ∀ t ∈ rest, t ∈ future) (status : Trial.BStatus) (hne : status ≠ .holding) :
    Accounted { s with
      bindings := s.bindings.map (fun b => if b.record.id == bid then
        { b with record := { b.record with status := status } } else b), tasks := future } := by
  intro b hb hh
  obtain ⟨q,hq,rfl⟩ := List.mem_map.mp hb
  by_cases he : q.record.id = bid
  · simp [he] at hh
    exact False.elim (hne hh)
  · simp only [show (q.record.id == bid) = false from by simp [he], Bool.false_eq_true, ↓reduceIte] at hh ⊢
    rcases hs q hq hh with huse | hgive
    · obtain ⟨t,hm,htu⟩ := List.any_eq_true.mp huse
      rw [ht] at hm
      rcases List.mem_cons.mp hm with rfl | hm
      · exact False.elim (he (hu q.record.id htu))
      · exact Or.inl (List.any_eq_true.mpr ⟨t,hkeep t hm,htu⟩)
    · rw [ht] at hgive
      rcases List.mem_cons.mp hgive with h | h
      · exact False.elim (he (hg q.record.id h.symm))
      · exact Or.inr (hkeep _ h)

theorem giveBinding_accounted (hs : Accounted s)
    (htasks : s.tasks = .giveBinding bid :: rest)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  simp only [Counted.transition, htasks, pure, bind, Except.pure, Except.bind] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals
    apply deactivate_accounted hs htasks (by simp [taskUses])
      (by intro id h; cases h; rfl) ?_ .givenUp (by simp)
  all_goals intro t hm
  all_goals first | exact hm | exact List.mem_cons_of_mem _ hm

set_option maxHeartbeats 1000000 in
theorem variable_accounted (hs : Accounted s) (hform : HolderForm s.bindings)
    (hunique : (s.bindings.map (fun b => b.record.id)).Nodup)
    (htasks : s.tasks = .eval (.var name) ctx :: rest)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  simp only [Counted.transition, htasks, pure, bind, Except.pure, Except.bind] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals first
    | (apply deactivate_accounted hs htasks ?_ (by intro id h; cases h)
         (by intro t hm; exact hm) .movedOn (by simp)
       intro id hu
       simp_all [taskUses, uses, Trial.Proofs.lookup_frame_env]
       done)
    | skip
  all_goals intro q hq hh
  all_goals
    have hself := Initial.find_key_self s.bindings (fun b => b.record.id) hunique q hq
    obtain ⟨a,hroot⟩ := hform q hq hh
    have hac := hs q hq hh
    simp_all [htasks, taskUses, uses, Trial.Proofs.lookup_frame_env]
  all_goals rcases hac with (hid | huse) | hgive <;> simp_all

theorem eval_accounted (hs : Accounted s) (hform : HolderForm s.bindings)
    (hunique : (s.bindings.map (fun b => b.record.id)).Nodup)
    (htasks : s.tasks = .eval e ctx :: rest)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  cases e
  case var name => exact variable_accounted hs hform hunique htasks ht
  all_goals simp only [Counted.transition, htasks, pure, Except.pure] at ht
  all_goals cases ht
  all_goals apply replace_head_accounted hs htasks ?_ (by intro id h; cases h) ?_
  all_goals first
    | (intro t hm; first | exact hm | exact List.mem_append_right _ hm)
    | (intro bid hu
       simp [taskUses, uses, child, List.any_append] at hu ⊢
       all_goals first
         | solve | grind
         | (obtain ⟨a,ha,hu⟩ := hu
            obtain ⟨i,hi⟩ := List.mem_iff_getElem?.mp ha
            exact Or.inl ⟨a,⟨i,List.mk_mem_zipIdx_iff_getElem?.mpr hi⟩,hu⟩))

set_option maxHeartbeats 1000000 in
theorem transition_accounted (hs : Accounted s) (hform : HolderForm s.bindings)
    (hunique : (s.bindings.map (fun b => b.record.id)).Nodup)
    (hbound : ∀ b ∈ s.bindings, b.record.id < s.nextBinding)
    (ht : Counted.transition p s = .ok c) : Accounted c.state := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    cases task
    all_goals first
      | exact eval_accounted hs hform hunique he ht
      | exact bind_accounted hs hbound he ht
      | exact chooseIf_accounted hs he ht
      | exact chooseMatch_accounted hs he ht
      | exact decompose_accounted hs hbound he ht
      | exact enter_accounted hs he ht
      | exact giveBinding_accounted hs he ht
      | skip
    all_goals simp only [Counted.transition, he, pure, bind, Except.pure, Except.bind] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals
      apply replace_head_accounted hs he (by simp [taskUses]) (by intro id h; cases h)
      intro t hm
      first | exact hm | exact List.mem_cons_of_mem _ hm | exact List.mem_append_right _ hm

theorem commit_accounted (c : Change) : Accounted (commit c) ↔ Accounted c.state := by
  rfl

theorem advance_accounted (hs : Accounted s) (hform : HolderForm s.bindings)
    (hids : s.bindings.map (fun b => b.record.id) = List.range s.nextBinding)
    (ht : Counted.advance p n s = .ok t) : Accounted t := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance, ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance, Counted.step, ha, hc] at ht
      | ok c =>
        simp [Counted.advance, Counted.step, ha, hc] at ht
        apply ih (s := commit c) ?_ (transition_holder_form hform hc)
          (BindingIdentity.transition_ids hids hc) ht
        apply transition_accounted hs hform ?_ ?_ hc
        · rw [hids]; exact List.nodup_range
        · intro b hb
          apply List.mem_range.mp
          rw [← hids]
          exact List.mem_map.mpr ⟨b,hb,rfl⟩

theorem reachable_accounted (hr : Statements.Reachable p initial s) : Accounted s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_accounted (begin_accounted hb) (begin_holder_form hb) (BindingIdentity.begin_ids hb) hn

theorem no_holding_of_empty (hs : Accounted s) (ht : s.tasks = []) :
    ∀ b ∈ s.bindings, b.record.status ≠ .holding := by
  intro b hb hh
  have h := hs b hb hh
  simp [ht] at h

theorem answered_no_holding_of_accounted (hr : Statements.Reachable p initial s)
    (ha : s.answer.isSome = true) (hs : Accounted s) :
    ∀ b ∈ s.bindings, b.record.status ≠ .holding :=
  no_holding_of_empty hs ((ControlShape.reachable_shape hr).2 ha)

/-- Every reachable answer has released or transferred every binding holder.
This is derived from initialization and preservation, not assumed final cleanup. -/
theorem answered_no_holding (hr : Statements.Reachable p initial s)
    (ha : s.answer.isSome = true) :
    ∀ b ∈ s.bindings, b.record.status ≠ .holding :=
  answered_no_holding_of_accounted hr ha (reachable_accounted hr)

end Full.Proofs.HoldingAccounted
