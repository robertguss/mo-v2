import Proofs.ReleaseContract

namespace Trial.Proofs

/-- This is exactly one iteration of the locked dead-name loop, factored only
as proof notation for induction over that loop. -/
def cleanupStep (chosen : List Frame) (p : String × Nat) : M (ForInStep PUnit) := do
  let b ← getBinding p.2
  match b.value with
  | .list (some _) =>
    if b.status == .holding && !(usedLater chosen p.2) then do
      giveUpBinding Variant.approved p.2
      pure (.yield PUnit.unit)
    else pure (.yield PUnit.unit)
  | _ => pure (.yield PUnit.unit)

theorem cleanup_step_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (chosen : List Frame) (p : String × Nat)
    (hi : p.2 < s.nextBinding) :
    ∃ t, cleanupStep chosen p s = (.ok (.yield PUnit.unit), t) ∧
      StateInvariant start g enc t ∧ ReleaseFrame s t ∧ t.pending = s.pending ∧
      (∀ v ∈ s.pending, readBack t.mem v = readBack s.mem v) ∧
      (∀ b ∈ t.bindings, b.status = .holding →
        b ∈ s.bindings ∧ (usedLater chosen b.id = true ∨ b.id ≠ p.2)) := by
  have him : p.2 ∈ s.bindings.map Binding.id := by rw [h.ids]; exact List.mem_range.mpr hi
  obtain ⟨b, hf⟩ := find_binding_id s.bindings p.2 him
  have hb := List.mem_of_find?_eq_some hf
  have hbid : b.id = p.2 := by simpa using List.find?_some hf
  by_cases hrelease : b.status = .holding ∧ usedLater chosen p.2 = false
  · obtain ⟨hs, hu⟩ := hrelease
    obtain ⟨a, ha⟩ := h.holding b hb hs
    obtain ⟨t, ht, hstate, hbind, hpend, hframe, hsave⟩ := release_binding_contract h p.2 b a hf hs ha
    refine ⟨t, ?_, hstate, hframe, hpend, hsave, ?_⟩
    · simp [cleanupStep, getBinding, hf, ha, hs, hu, ht]
    · intro d hd hdhold
      rw [hbind] at hd
      obtain ⟨q, hq, he⟩ := List.mem_map.mp hd
      by_cases hqi : q.id = p.2
      · have hqstatus := congrArg Binding.status he
        simp [hqi, hdhold] at hqstatus
      · have he' : q = d := by simpa [hqi] using he
        rw [← he']
        exact ⟨hq, Or.inr hqi⟩
  · refine ⟨s, ?_, h, .refl s, rfl, fun _ _ => rfl, ?_⟩
    · cases hv : b.value with
      | num _ | bool _ => simp [cleanupStep, getBinding, hf, hv]
      | list r => cases r <;> simp [cleanupStep, getBinding, hf, hv, hrelease]
    · intro d hd hs
      refine ⟨hd, ?_⟩
      by_cases hdi : d.id = p.2
      · have hdf : s.bindings.find? (fun q => q.id == p.2) = some d := by
          simpa [hdi] using binding_find_self s.bindings h.unique d hd
        have hbd := Option.some.inj (hf.symm.trans hdf)
        subst d
        exact Or.inl (by cases hh : usedLater chosen b.id <;> simp_all)
      · exact Or.inr hdi

/-- After the actual loop, every remaining holder was present before it, and
is either used in the selected future or absent from the processed ids. This
is the removal direction missing from preservation-only liveness lemmas. -/
theorem cleanup_loop_contract (xs : Env) (chosen : List Frame)
    (start : Start) (g : Meanings) (enc : List Nat) (s : RunState)
    (h : StateInvariant start g enc s) (hi : ∀ p ∈ xs, p.2 < s.nextBinding) :
    ∃ t, (forIn xs PUnit.unit (fun p _ => cleanupStep chosen p) : M PUnit) s = (.ok PUnit.unit, t) ∧
      StateInvariant start g enc t ∧ ReleaseFrame s t ∧ t.pending = s.pending ∧
      (∀ v ∈ s.pending, readBack t.mem v = readBack s.mem v) ∧
      (∀ b ∈ t.bindings, b.status = .holding →
        b ∈ s.bindings ∧ (usedLater chosen b.id = true ∨ b.id ∉ xs.map Prod.snd)) := by
  induction xs generalizing s with
  | nil => exact ⟨s, rfl, h, .refl s, rfl, fun _ _ => rfl,
      fun b hb _ => ⟨hb, Or.inr (by simp)⟩⟩
  | cons p ps ih =>
    obtain ⟨u, hu, hsu, hfu, hpu, hsvu, hhu⟩ := cleanup_step_contract h chosen p (hi p (by simp))
    have hib : ∀ q ∈ ps, q.2 < u.nextBinding := by
      intro q hq
      rw [hfu.bindingCounter]
      exact hi q (List.mem_cons_of_mem _ hq)
    obtain ⟨t, ht, hst, hft, hpt, hsvt, hht⟩ := ih u hsu hib
    refine ⟨t, ?_, hst, hfu.trans hft, hpt.trans hpu, ?_, ?_⟩
    · simpa [List.forIn_cons, hu] using ht
    · intro v hv
      exact (hsvt v (by simpa [hpu] using hv)).trans (hsvu v hv)
    · intro b hb hs
      obtain ⟨hbu, hbut⟩ := hht b hb hs
      obtain ⟨hbs, hbus⟩ := hhu b hbu hs
      refine ⟨hbs, ?_⟩
      rcases hbut with hused | htail
      · exact Or.inl hused
      · rcases hbus with hused | hhead
        · exact Or.inl hused
        · exact Or.inr (by simp [hhead, htail])

/-- Full dead-name cleanup under explicit coverage of the holders to discard.
The coverage condition is necessary: outer future frames may own other names. -/
theorem cleanup_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (env : Env) (chosen : List Frame)
    (hi : ∀ p ∈ env, p.2 < s.nextBinding)
    (hused : ∀ b ∈ s.bindings, (∃ a, b.value = .list (some a)) →
      usedLater chosen b.id = true → b.status = .holding)
    (hcover : ∀ b ∈ s.bindings, b.status = .holding → usedLater chosen b.id = false →
      b.id ∈ env.map Prod.snd) :
    ∃ t, giveUpDead Variant.approved env chosen s = (.ok (), t) ∧
      StateInvariant start g enc t ∧ LiveFor t.bindings chosen ∧
      ReleaseFrame s t ∧ t.pending = s.pending ∧
      (∀ v ∈ s.pending, readBack t.mem v = readBack s.mem v) := by
  obtain ⟨t, ht, hst, hframe, hpend, hsave, hholders⟩ :=
    cleanup_loop_contract env.reverse chosen start g enc s h (fun p hp => hi p (by simpa using hp))
  have hrun : giveUpDead Variant.approved env chosen s = (.ok (), t) := by
    unfold giveUpDead
    change ((forIn env.reverse PUnit.unit (fun p _ => cleanupStep chosen p) : M PUnit) >>= fun _ => pure ()) s = _
    rw [m_bind_apply, ht]
    rfl
  have he : ∀ p ∈ env, p.2 ∈ s.bindings.map Binding.id := by
    intro p hp
    rw [h.ids]
    exact List.mem_range.mpr (hi p hp)
  obtain ⟨u, hu, _, _, hkeep⟩ := give_up_dead_keeps_used s env chosen h.owned h.unique he
  have hut : u = t := congrArg Prod.snd (hu.symm.trans hrun)
  subst u
  refine ⟨t, hrun, hst, ?_, hframe, hpend, hsave⟩
  intro b hb hv
  constructor
  · intro hs
    obtain ⟨hbs, hrem⟩ := hholders b hb hs
    rcases hrem with hy | hn
    · exact hy
    · cases hy : usedLater chosen b.id with
      | true => rfl
      | false => exact False.elim (hn (by simpa using hcover b hbs hs hy))
  · intro hy
    have hf := binding_find_self t.bindings hst.unique b hb
    rw [hkeep b.id hy] at hf
    exact hused b (List.mem_of_find?_eq_some hf) hv hy

end Trial.Proofs
