import Full.Demand.UsageTransition
import Full.Demand.Certificates

namespace Full.Demand
open Counted Full.Proofs

theorem sum_map_le (xs : List α) (f g : α → Nat)
    (h : ∀ x ∈ xs, f x ≤ g x) : (xs.map f).sum ≤ (xs.map g).sum := by
  induction xs with
  | nil => simp
  | cons x xs ih =>
    simp only [List.map_cons,List.sum_cons]
    exact Nat.add_le_add (h x (by simp)) (ih (fun y hy => h y (by simp [hy])))

theorem hide_lookup_imp (a b : Trial.FEnv) (i j : Nat) (name : String)
    (h : ∀ x, Trial.lookupF a x = some (some i) → Trial.lookupF b x = some (some j)) :
    ∀ x, Trial.lookupF ((name,none)::a) x = some (some i) →
      Trial.lookupF ((name,none)::b) x = some (some j) := by
  intro x hx
  by_cases he : name = x
  · simp [Trial.lookupF,he] at hx
  · simpa [Trial.lookupF,he] using h x (by simpa [Trial.lookupF,he] using hx)

/-- Removing possible resolutions can only lower a binding's occurrence count.
This also covers a parameter hidden by another spelling in an environment. -/
theorem occurrences_le (e : Expr) (a b : Trial.FEnv) (i j : Nat)
    (h : ∀ x, Trial.lookupF a x = some (some i) → Trial.lookupF b x = some (some j)) :
    occurrences e a i ≤ occurrences e b j := by
  cases e with
  | num n | bool q | nil => simp [occurrences]
  | var x =>
    simp only [occurrences]
    split
    · rename_i hx
      simp [h x (by simpa using hx)]
    · omega
  | bin op l r =>
    have hl := occurrences_le l a b i j h
    have hr := occurrences_le r a b i j h
    simp only [occurrences]; omega
  | letE x l r =>
    have hl := occurrences_le l a b i j h
    have hr := occurrences_le r _ _ i j (hide_lookup_imp a b i j x h)
    simp only [occurrences]; omega
  | ifE c t e =>
    have hc := occurrences_le c a b i j h
    have ht := occurrences_le t a b i j h
    have he := occurrences_le e a b i j h
    simp only [occurrences]; omega
  | matchE s n head tail c =>
    have hs := occurrences_le s a b i j h
    have hn := occurrences_le n a b i j h
    have hc := occurrences_le c _ _ i j
      (hide_lookup_imp _ _ i j tail (hide_lookup_imp a b i j head h))
    simp only [occurrences]; omega
  | call name args =>
    simp only [occurrences]
    apply sum_map_le
    intro arg _
    exact occurrences_le arg.val a b i j h
termination_by sizeOf e
decreasing_by
  all_goals simp_wf
  all_goals first | omega | (have h := List.sizeOf_lt_of_mem arg.property; omega)

theorem occurrences_member_bound (e : Expr) (env : Env) (name : String) (id : Nat)
    (hu : (env.map Prod.snd).Nodup) (hm : (name,id) ∈ env) :
    occurrences e (Trial.toFEnv env) id ≤ occurrences e [(name,some 0)] 0 := by
  apply occurrences_le
  intro x hx
  have hxmem := HoldingAccounted.toFEnv_mem (Trial.Proofs.lookup_frame_mem _ _ _ hx)
  have hf := Initial.find_key_self env Prod.snd hu (name,id) hm
  have hg := Initial.find_key_self env Prod.snd hu (x,id) hxmem
  have he : x = name := congrArg Prod.fst (Option.some.inj (hg.symm.trans hf))
  subst x
  simp [Trial.lookupF]

theorem fresh_future_zero {id : Nat} (hr : Statements.Reachable p initial s)
    (ht : s.tasks = task::rest) (hf : s.nextBinding ≤ id) :
    futureOccurrences id rest = 0 := by
  apply (futureUses_zero id rest).mp
  apply ReleaseQueue.tasks_fresh_unused (next := s.nextBinding) _ hf
  intro t hm
  exact EnvironmentIdentity.reachable_task hr (by rw [ht]; exact List.mem_cons_of_mem _ hm)

/-- Bind's entire installed continuation, including saved caller work and
unused-binding cleanup, satisfies the new list binding's affine bound. -/
theorem transition_bind_new_bound (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) (hs : s.tasks = .bind name body ctx::rest)
    (ha : affine name .list body = .ok ()) :
    futureOccurrences s.nextBinding c.state.tasks ≤ 1 := by
  have he : EnvironmentIdentity.EnvOK s.nextBinding ctx.env :=
    EnvironmentIdentity.reachable_task (task := .bind name body ctx) hr
      (by rw [hs]; exact List.mem_cons_self)
  have hb := occurrences_member_bound body ((name,s.nextBinding)::ctx.env) name s.nextBinding
    (EnvironmentIdentity.env_cons he).1 (by simp)
  have hrest := fresh_future_zero hr hs (Nat.le_refl s.nextBinding)
  have hbound := affine_list_bound ha
  simp only [Counted.transition,hs,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals simp only [future_append,future_cons,future_nil,future_dead,taskOccurrences,child,makeBinding]
  all_goals simp only [Trial.toFEnv,List.map_cons] at hb ⊢
  all_goals omega

/-- Both unique and shared Decompose paths install the same affine tail body.
Shared acquisition is not ruled out by this lemma; that is an ownership claim. -/
theorem transition_tail_new_bound (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c)
    (hs : s.tasks = .decompose head tail body bid ctx::rest)
    (ha : affine tail .list body = .ok ()) :
    futureOccurrences (s.nextBinding+1) c.state.tasks ≤ 1 := by
  have he : EnvironmentIdentity.EnvOK s.nextBinding ctx.env :=
    EnvironmentIdentity.reachable_task (task := .decompose head tail body bid ctx) hr
      (by rw [hs]; exact List.mem_cons_self)
  have hb := occurrences_member_bound body
    ((tail,s.nextBinding+1)::(head,s.nextBinding)::ctx.env) tail (s.nextBinding+1)
    (EnvironmentIdentity.env_cons (EnvironmentIdentity.env_cons he)).1 (by simp)
  have hrest := fresh_future_zero hr hs (by omega : s.nextBinding ≤ s.nextBinding+1)
  have hbound := affine_list_bound ha
  simp only [Counted.transition,hs,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  all_goals simp only [future_append,future_cons,future_nil,taskOccurrences,child]
  all_goals simp only [Trial.toFEnv,List.map_cons] at hb ⊢
  all_goals omega

theorem zip_slot_kinds (params : List (String × Kind)) (args : List Slot)
    (hk : args.map (fun v => v.raw.kind) = params.map Prod.snd)
    (hm : (param,v) ∈ params.zip args) : v.raw.kind = param.2 := by
  induction params generalizing args with
  | nil => simp at hm
  | cons p ps ih =>
    cases args with
    | nil => simp at hm
    | cons a args =>
      simp only [List.map_cons,List.cons.injEq] at hk
      simp only [List.zip_cons_cons,List.mem_cons] at hm
      rcases hm with he | hm
      · cases he; exact hk.1
      · exact ih args hk.2 hm

theorem parameter_body_bound (pairs : List ((String × Kind) × Slot))
    (next invocation : Nat) (name : String) (body : Expr)
    (hk : ∀ pair ∈ pairs, pair.2.raw.kind = pair.1.2)
    (ha : ∀ pair ∈ pairs, affine pair.1.1 pair.1.2 body = .ok ())
    (hm : b ∈ pairs.zipIdx.map (fun (((x,_),v),i) =>
      makeBinding (next+i) x v invocation s!"{name}/parameter/{x}"))
    (hl : b.record.value.kind = .list) :
    occurrences body (Trial.toFEnv
      ((pairs.zipIdx.map (fun (((x,_),v),i) =>
        makeBinding (next+i) x v invocation s!"{name}/parameter/{x}")).reverse.map
          (fun b => (b.record.name,b.record.id)))) b.record.id ≤ 1 := by
  have hocc := occurrences_member_bound body _ b.record.name b.record.id
    (EnvironmentIdentity.parameter_env pairs next invocation name).1
    (List.mem_map.mpr ⟨b,List.mem_reverse.mpr hm,rfl⟩)
  apply Nat.le_trans hocc
  obtain ⟨⟨⟨⟨x,k⟩,v⟩,i⟩,hi,rfl⟩ := List.mem_map.mp hm
  have hpair := List.fst_mem_of_mem_zipIdx hi
  have hkind : k = .list := (hk ((x,k),v) hpair).symm.trans hl
  subst k
  exact affine_list_bound (ha ((x,.list),v) hpair)

/-- Enter's explicit argument-kind check connects the simultaneous syntactic
parameter certificates to every newly installed list parameter's runtime ID. -/
theorem transition_parameters_new_bound (hr : Statements.Reachable p initial s)
    (ht : Counted.transition p s = .ok c) (hs : s.tasks = .enter name arity ctx::rest)
    (hf : signature p.functions name = some f)
    (ha : ∀ param ∈ f.params, affine param.1 param.2 f.body = .ok ())
    (hm : b ∈ c.state.bindings) (hnew : s.nextBinding ≤ b.record.id)
    (hl : b.record.value.kind = .list) : futureOccurrences b.record.id c.state.tasks ≤ 1 := by
  have hrest := fresh_future_zero hr hs hnew
  simp only [Counted.transition,hs,hf,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  simp only at hm
  rcases List.mem_append.mp hm with hm | hm
  · have := BindingIdentity.reachable_bound hr hm
    omega
  · have hk : ((s.slots.take arity).reverse).map (fun v => v.raw.kind) = f.params.map Prod.snd := by
      simp_all
    have hb := parameter_body_bound (f.params.zip (s.slots.take arity).reverse)
      s.nextBinding s.nextInvocation name f.body
      (fun _ hpair => zip_slot_kinds _ _ hk hpair)
      (fun pair hpair => ha pair.1 (List.of_mem_zip hpair).1) hm hl
    simp only [future_append,future_dead,future_cons,future_nil,taskOccurrences]
    simpa only [hrest,Nat.zero_add,Nat.add_zero] using hb

end Full.Demand
