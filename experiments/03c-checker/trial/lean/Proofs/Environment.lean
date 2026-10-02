import Proofs.StateSteps

namespace Trial.Proofs

theorem dup_input_none (xs : List (String × Kind)) :
    dupInput xs = none ↔ (xs.map Prod.fst).Nodup := by
  induction xs with
  | nil => simp [dupInput]
  | cons p ps ih =>
    rcases p with ⟨x, k⟩
    by_cases ha : ps.any (fun p => p.1 = x) = true
    · simp [dupInput, ha]
      intro hn _
      obtain ⟨⟨y, k'⟩, hp, he⟩ := List.any_eq_true.mp ha
      have hy : y = x := by simpa using he
      subst y
      exact hn k' hp
    · simp [dupInput, ha, ih]
      intro _ k' hp
      exact ha (List.any_eq_true.mpr ⟨(x, k'), hp, by simp⟩)

theorem valid_input_names (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    (s.inputs.map Prod.fst).Nodup := by
  obtain ⟨k, hw⟩ := valid_start_well_formed e s h
  cases hd : dupInput (s.inputs.map (fun p => (p.1, p.2.kind))) with
  | some name => simp [wellFormed, hd] at hw
  | none => simpa [List.map_map, Function.comp_def] using (dup_input_none _).mp hd

/-- Unique input spellings make reversal irrelevant to nearest-name lookup. -/
theorem find_reverse_names (env : Env) (hu : (env.map Prod.fst).Nodup) (x : String) :
    env.reverse.find? (fun p => p.1 == x) = env.find? (fun p => p.1 == x) := by
  induction env with
  | nil => rfl
  | cons p ps ih =>
    have hn := List.nodup_cons.mp hu
    by_cases he : p.1 = x
    · have hf : ps.reverse.find? (fun q => q.1 == x) = none := by
        apply List.find?_eq_none.mpr
        intro q hq
        have hq' : q ∈ ps := by simpa using hq
        have hne : q.1 ≠ x := by
          intro hqx
          exact hn.1 (List.mem_map.mpr ⟨q, hq', hqx.trans he.symm⟩)
        simpa using hne
      simp [List.reverse_cons, List.find?_append, hf, he]
    · simp [List.reverse_cons, List.find?_append, he, ih hn.2]

theorem lookup_meaning_env (env : Env) (g : Meanings) (x : String) :
    lookupVal (env.map (fun p => (p.1, (g p.2).2))) x =
      (env.find? (fun p => p.1 == x)).map (fun p => (g p.2).2) := by
  induction env with
  | nil => rfl
  | cons p ps ih =>
    by_cases he : p.1 = x <;> simp [lookupVal, he, ih]

theorem binding_find_self (bs : List Binding) (hu : (bs.map Binding.id).Nodup)
    (b : Binding) (hb : b ∈ bs) : bs.find? (fun d => d.id == b.id) = some b := by
  induction bs with
  | nil => simp at hb
  | cons d ds ih =>
    have hn := List.nodup_cons.mp hu
    rcases List.mem_cons.mp hb with he | hm
    · subst b; simp
    · have hne : d.id ≠ b.id := by
        intro he
        exact hn.1 (List.mem_map.mpr ⟨b, hm, he.symm⟩)
      simp [hne, ih hn.2 hm]

/-- The record for each input keeps that input's original name and raw value. -/
theorem input_binding_source (inputs : List (String × RawValue)) (next : Nat)
    (b : Binding) (hb : b ∈ inputBindings next inputs) : (b.name, b.value) ∈ inputs := by
  induction inputs generalizing next with
  | nil => simp [inputBindings] at hb
  | cons p ps ih =>
    rcases p with ⟨name, value⟩
    rcases List.mem_cons.mp hb with he | hm
    · subst b; simp
    · exact List.mem_cons_of_mem _ (ih (next + 1) hm)

theorem input_binding_names (inputs : List (String × RawValue)) (next : Nat) :
    (inputBindings next inputs).map Binding.name = inputs.map Prod.fst := by
  induction inputs generalizing next with
  | nil => rfl
  | cons p ps ih => rcases p with ⟨name, value⟩; simp [inputBindings, ih]

/-- Relate successful input read-back to the table's plain input meanings. -/
theorem read_inputs_meanings (inputs : List (String × RawValue)) (next : Nat)
    (m : Memory) (g : Meanings)
    (hr : ∀ b ∈ inputBindings next inputs, readBack m b.value = .ok (g b.id).2) :
    inputs.mapM (fun p => do let v ← readBack m p.2; pure (p.1, v)) =
      .ok ((inputBindings next inputs).map (fun b => (b.name, (g b.id).2))) := by
  induction inputs generalizing next with
  | nil => rfl
  | cons p ps ih =>
    rcases p with ⟨name, value⟩
    have hhead := hr _ (List.mem_cons_self ..)
    have htail := ih (next + 1) (fun b hb => hr b (List.mem_cons_of_mem _ hb))
    simp only [except_pure] at htail
    simp [inputBindings, List.mapM_cons, hhead, htail]

end Trial.Proofs
