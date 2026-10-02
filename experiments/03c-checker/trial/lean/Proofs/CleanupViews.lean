import Proofs.Views

namespace Trial.Proofs

/-- Dead-name cleanup preserves both current holding meanings and the same
per-id meanings in every intermediate snapshot. -/
theorem give_up_dead_meanings (s : RunState) (env : Env) (chosen : List Frame)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (he : ∀ p ∈ env, p.2 ∈ s.bindings.map Binding.id)
    (raw : Nat → RawValue) (meaning : Nat → PlainValue)
    (hnow : HoldingMeanings s.mem s.bindings raw meaning)
    (hpast : ∀ sn ∈ s.snaps, HoldingMeanings (snapMemory sn) sn.bindings raw meaning) :
    ∃ t, giveUpDead Variant.approved env chosen s = (.ok (), t) ∧ Owned t ∧
      t.bindings.map Binding.id = s.bindings.map Binding.id ∧
      HoldingMeanings t.mem t.bindings raw meaning ∧
      (∀ sn ∈ t.snaps, HoldingMeanings (snapMemory sn) sn.bindings raw meaning) := by
  let P := fun t : RunState => Owned t ∧
    t.bindings.map Binding.id = s.bindings.map Binding.id ∧
    HoldingMeanings t.mem t.bindings raw meaning ∧
    (∀ sn ∈ t.snaps, HoldingMeanings (snapMemory sn) sn.bindings raw meaning)
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
    obtain ⟨hhu, hids, hmean, hsnaps⟩ := hpu
    have huniq : (u.bindings.map Binding.id).Nodup := by simpa [hids] using hu
    have hid : p.2 ∈ u.bindings.map Binding.id := by
      rw [hids]
      exact he p (by simpa using hp)
    obtain ⟨b, hf⟩ := find_binding_id u.bindings p.2 hid
    cases hv : b.value with
    | num n => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hmean, hsnaps⟩
    | bool b => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hmean, hsnaps⟩
    | list r =>
      cases r with
      | none => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hmean, hsnaps⟩
      | some a =>
        by_cases hg : (b.status == .holding && !(usedLater chosen p.2)) = true
        · obtain ⟨hstatus, hused⟩ : b.status = .holding ∧ usedLater chosen p.2 = false := by
            simpa using hg
          obtain ⟨t, ht, hht, hbt, _⟩ :=
            give_up_binding_owned u p.2 b (some a) hhu huniq hf hstatus hv
          have hn := give_up_binding_meanings u p.2 b (some a) hhu huniq hf hstatus hv raw meaning hmean
          have hs := give_up_binding_snapshots u p.2 b (some a) hhu huniq hf hstatus hv raw meaning hsnaps hmean
          rw [ht] at hn hs
          refine ⟨t, ?_, hht, ?_, hn, hs⟩
          · simp [act, getBinding, hf, hv, hstatus, hused, ht]
          · rw [hbt, status_update_ids, hids]
        · refine ⟨u, ?_, hhu, hids, hmean, hsnaps⟩
          have hno : ¬(b.status = .holding ∧ usedLater chosen p.2 = false) := by simpa using hg
          simp [act, getBinding, hf, hv, hno]
  obtain ⟨t, ht, hpt⟩ := for_in_invariant env.reverse act P hact s ⟨hh, rfl, hnow, hpast⟩
  refine ⟨t, ?_, hpt⟩
  unfold giveUpDead
  change ((forIn env.reverse PUnit.unit (fun p _ => act p) : M PUnit) >>= fun _ => pure ()) s = (.ok (), t)
  rw [m_bind_apply, ht]
  rfl

end Trial.Proofs
