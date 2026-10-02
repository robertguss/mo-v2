import Proofs.ConsContract

namespace Trial.Proofs

/-- The initial loop differs from later branch cleanup by omitting a status
test. Each input is processed exactly once, while its original holder is live. -/
def inputCleanupStep (e : Expr) (env : Env) (p : String × Nat) : M (ForInStep PUnit) := do
  let b ← getBinding p.2
  match b.value with
  | .list (some _) =>
    if !(usesBinding e (toFEnv env) p.2) then do
      giveUpBinding Variant.approved p.2
      pure (.yield PUnit.unit)
    else pure (.yield PUnit.unit)
  | _ => pure (.yield PUnit.unit)

theorem input_cleanup_eq (xs : Env) (e : Expr) (env : Env)
    (start : Start) (g : Meanings) (enc : List Nat) (s : RunState)
    (h : StateInvariant start g enc s) (hi : ∀ p ∈ xs, p.2 < s.nextBinding)
    (hn : (xs.map Prod.snd).Nodup)
    (hh : ∀ b ∈ s.bindings, b.id ∈ xs.map Prod.snd →
      (∃ a, b.value = .list (some a)) → b.status = .holding) :
    (forIn xs PUnit.unit (fun p _ => inputCleanupStep e env p) : M PUnit) s =
      (forIn xs PUnit.unit (fun p _ => cleanupStep [{ text := e, env := toFEnv env }] p) : M PUnit) s := by
  induction xs generalizing s with
  | nil => rfl
  | cons p ps ih =>
    have hn' := List.nodup_cons.mp hn
    have him : p.2 ∈ s.bindings.map Binding.id := by
      rw [h.ids]
      exact List.mem_range.mpr (hi p (by simp))
    obtain ⟨b, hf⟩ := find_binding_id s.bindings p.2 him
    have hb := List.mem_of_find?_eq_some hf
    have hbid : b.id = p.2 := by simpa using List.find?_some hf
    have htail : ∀ d ∈ s.bindings, d.id ∈ ps.map Prod.snd →
        (∃ a, d.value = .list (some a)) → d.status = .holding :=
      fun d hd hm hv => hh d hd (List.mem_cons_of_mem _ hm) hv
    have hitail : ∀ q ∈ ps, q.2 < s.nextBinding :=
      fun q hq => hi q (List.mem_cons_of_mem _ hq)
    cases hv : b.value with
    | num n | bool n =>
      simpa [List.forIn_cons, inputCleanupStep, cleanupStep, getBinding, hf, hv] using
        ih s h hitail hn'.2 htail
    | list r =>
      cases r with
      | none =>
        simpa [List.forIn_cons, inputCleanupStep, cleanupStep, getBinding, hf, hv] using
          ih s h hitail hn'.2 htail
      | some a =>
        have hs := hh b hb (by simp [hbid]) ⟨a, hv⟩
        cases hu : usesBinding e (toFEnv env) p.2 with
        | true =>
          simpa [List.forIn_cons, inputCleanupStep, cleanupStep, getBinding, hf, hv, hu,
            usedLater] using ih s h hitail hn'.2 htail
        | false =>
          obtain ⟨u, he, hsu, hbu, _, hfr, _⟩ := release_binding_contract h p.2 b a hf hs hv
          have hiu : ∀ q ∈ ps, q.2 < u.nextBinding := by
            simpa [hfr.bindingCounter] using hitail
          have hhu : ∀ d ∈ u.bindings, d.id ∈ ps.map Prod.snd →
              (∃ a, d.value = .list (some a)) → d.status = .holding := by
            intro d hd hm hdv
            rw [hbu] at hd
            obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
            by_cases hqi : q.id = p.2
            · have hid : d.id = p.2 := by simpa [hqi] using (congrArg Binding.id heq).symm
              exact False.elim (hn'.1 (hid ▸ hm))
            · have hqd : q = d := by simpa [hqi] using heq
              rw [← hqd] at hm hdv ⊢
              exact htail q hq hm hdv
          simpa [List.forIn_cons, inputCleanupStep, cleanupStep, getBinding, hf, hv, hs, hu,
            usedLater, he] using ih u hsu hiu hn'.2 hhu

/-- Before evaluating the program, the real input cleanup establishes exact
liveness: all and only the inputs that will be used still hold their lists. -/
theorem initial_cleanup_contract (e : Expr) (start : Start) (hv : validStart e start = .ok ()) :
    ∃ t, (forIn (inputEnv start).reverse PUnit.unit
      (fun p _ => inputCleanupStep e (inputEnv start) p) : M PUnit)
      { inputState start with scope := (inputEnv start).reverse.map Prod.snd } = (.ok PUnit.unit, t) ∧
      StateInvariant start (inputMeanings start) [] t ∧
      LiveFor t.bindings [{ text := e, env := toFEnv (inputEnv start) }] ∧
      t.nextBinding = start.inputs.length ∧ t.pending = [] := by
  let s := { inputState start with scope := (inputEnv start).reverse.map Prod.snd }
  have h : StateInvariant start (inputMeanings start) [] s :=
    (initialized_state e start hv).scope _
  have hi : ∀ p ∈ inputEnv start, p.2 < s.nextBinding := (initialized_frame e start hv).env
  have hhold : ∀ b ∈ s.bindings, (∃ a, b.value = .list (some a)) → b.status = .holding := by
    intro b hb hval
    obtain ⟨a, ha⟩ := hval
    simpa [ha] using input_binding_status start.inputs 0 b hb
  have hcover : ∀ b ∈ s.bindings, b.id ∈ (inputEnv start).map Prod.snd := by
    intro b hb
    simp only [inputEnv, List.map_reverse, List.mem_reverse]
    exact List.mem_map.mpr ⟨(b.name, b.id), List.mem_map.mpr ⟨b, hb, rfl⟩, rfl⟩
  obtain ⟨t, ht, hst, hlt, hfr, hp, _⟩ := cleanup_contract h (inputEnv start)
    [{ text := e, env := toFEnv (inputEnv start) }] hi
    (fun b hb hval _ => hhold b hb hval) (fun b hb _ _ => hcover b hb)
  have hn : (((inputEnv start).reverse).map Prod.snd).Nodup := by
    simpa [inputEnv, List.map_map, Function.comp_def, input_ids_range] using
      List.nodup_range (n := start.inputs.length)
  have heq := input_cleanup_eq (inputEnv start).reverse e (inputEnv start) start (inputMeanings start)
    [] s h (fun p hp => hi p (by simpa using hp)) hn (fun b hb _ hval => hhold b hb hval)
  refine ⟨t, ?_, hst, hlt, hfr.bindingCounter, hp⟩
  rw [heq]
  unfold giveUpDead at ht
  change ((forIn (inputEnv start).reverse PUnit.unit
    (fun p _ => cleanupStep [{ text := e, env := toFEnv (inputEnv start) }] p) : M PUnit)
      >>= fun _ => pure ()) s = (.ok (), t) at ht
  cases hr : (forIn (inputEnv start).reverse PUnit.unit
    (fun p _ => cleanupStep [{ text := e, env := toFEnv (inputEnv start) }] p) : M PUnit) s with
  | mk result u =>
    cases result with
    | error msg =>
      have hbad := congrArg Prod.fst ht
      simp [m_bind_apply, hr] at hbad
    | ok val =>
      have he := congrArg Prod.snd ht
      simp [m_bind_apply, hr] at he
      cases val
      simp [he]

end Trial.Proofs
