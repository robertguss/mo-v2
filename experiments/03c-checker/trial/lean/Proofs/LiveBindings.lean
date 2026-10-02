import Proofs.Match

namespace Trial.Proofs

/-- Changing one id's status cannot change the lookup of any other id. -/
theorem find_other_status (bs : List Binding) (id other : Nat) (st : BStatus)
    (hne : other ≠ id) :
    (bs.map (fun b => if b.id == id then { b with status := st } else b)).find?
        (fun b => b.id == other) = bs.find? (fun b => b.id == other) := by
  let upd := fun b : Binding => if b.id == id then { b with status := st } else b
  have hid : ∀ b, (upd b).id = b.id := by
    intro b
    simp only [upd]
    split <;> rfl
  change (bs.map upd).find? (fun b => b.id == other) = _
  rw [List.find?_map]
  simp only [Function.comp_def, hid]
  cases hf : bs.find? (fun b => b.id == other) with
  | none => rfl
  | some b =>
    have hb : b.id = other := by simpa using (List.find?_some hf)
    simp [upd, hb, hne]

/-- Dead-name cleanup never changes a binding used in the selected future.
This is about binding identity and status, not just preservation of list data. -/
theorem give_up_dead_keeps_used (s : RunState) (env : Env) (chosen : List Frame)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (he : ∀ p ∈ env, p.2 ∈ s.bindings.map Binding.id) :
    ∃ t, giveUpDead Variant.approved env chosen s = (.ok (), t) ∧ Owned t ∧
      t.bindings.map Binding.id = s.bindings.map Binding.id ∧
      (∀ id, usedLater chosen id = true →
        t.bindings.find? (fun b => b.id == id) = s.bindings.find? (fun b => b.id == id)) := by
  let P := fun t : RunState => Owned t ∧
    t.bindings.map Binding.id = s.bindings.map Binding.id ∧
    (∀ id, usedLater chosen id = true →
      t.bindings.find? (fun b => b.id == id) = s.bindings.find? (fun b => b.id == id))
  let act := fun p : String × Nat => (do
    let b ← getBinding p.2
    match b.value with
    | .list (some _) =>
      if b.status == .holding && !(usedLater chosen p.2) then do
        giveUpBinding Variant.approved p.2
        pure (ForInStep.yield PUnit.unit)
      else pure (ForInStep.yield PUnit.unit)
    | _ => pure (ForInStep.yield PUnit.unit) : M (ForInStep PUnit))
  have hact : ∀ p ∈ env.reverse, ∀ u, P u →
      ∃ t, act p u = (.ok (.yield PUnit.unit), t) ∧ P t := by
    intro p hp u hpu
    obtain ⟨hhu, hids, hkeep⟩ := hpu
    have huniq : (u.bindings.map Binding.id).Nodup := by simpa [hids] using hu
    have hid : p.2 ∈ u.bindings.map Binding.id := by
      rw [hids]
      exact he p (by simpa using hp)
    obtain ⟨b, hf⟩ := find_binding_id u.bindings p.2 hid
    cases hv : b.value with
    | num n => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hkeep⟩
    | bool b => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hkeep⟩
    | list r =>
      cases r with
      | none => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hkeep⟩
      | some a =>
        by_cases hg : (b.status == .holding && !(usedLater chosen p.2)) = true
        · obtain ⟨hstatus, hused⟩ : b.status = .holding ∧ usedLater chosen p.2 = false := by
            simpa using hg
          obtain ⟨t, ht, hht, hbt, _⟩ :=
            give_up_binding_owned u p.2 b (some a) hhu huniq hf hstatus hv
          refine ⟨t, ?_, hht, ?_, ?_⟩
          · simp [act, getBinding, hf, hv, hstatus, hused, ht]
          · rw [hbt, status_update_ids, hids]
          · intro id hi
            have hn : id ≠ p.2 := by intro he; subst id; simp [hused] at hi
            rw [hbt, find_other_status u.bindings p.2 id .givenUp hn]
            exact hkeep id hi
        · refine ⟨u, ?_, hhu, hids, hkeep⟩
          have hno : ¬(b.status = .holding ∧ usedLater chosen p.2 = false) := by simpa using hg
          simp [act, getBinding, hf, hv, hno]
  obtain ⟨t, ht, hpt⟩ := for_in_invariant env.reverse act P hact s ⟨hh, rfl, fun _ _ => rfl⟩
  refine ⟨t, ?_, hpt⟩
  unfold giveUpDead
  change ((forIn env.reverse PUnit.unit (fun p _ => act p) : M PUnit) >>= fun _ => pure ()) s = (.ok (), t)
  rw [m_bind_apply, ht]
  rfl

end Trial.Proofs
