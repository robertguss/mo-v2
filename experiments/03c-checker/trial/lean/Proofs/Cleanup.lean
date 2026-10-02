import Proofs.Snapshots

namespace Trial.Proofs

/-- A finite stateful loop succeeds if each step yields and preserves its
state invariant. This applies to the locked evaluator's existing `forIn`. -/
theorem for_in_invariant (xs : List α) (act : α → M (ForInStep PUnit))
    (P : RunState → Prop)
    (hstep : ∀ x ∈ xs, ∀ s, P s → ∃ t, act x s = (.ok (.yield PUnit.unit), t) ∧ P t)
    (s : RunState) (hs : P s) :
    ∃ t, (forIn xs PUnit.unit (fun x _ => act x) : M PUnit) s = (.ok PUnit.unit, t) ∧ P t := by
  induction xs generalizing s with
  | nil => exact ⟨s, rfl, hs⟩
  | cons x xs ih =>
    obtain ⟨u, hu, hp⟩ := hstep x (by simp) s hs
    obtain ⟨t, ht, hpt⟩ := ih (fun y hy => hstep y (by simp [hy])) u hp
    refine ⟨t, ?_, hpt⟩
    simpa [List.forIn_cons, hu] using ht

theorem find_binding_id (bs : List Binding) (id : Nat) (h : id ∈ bs.map Binding.id) :
    ∃ b, bs.find? (fun d => d.id == id) = some b := by
  cases hf : bs.find? (fun d => d.id == id) with
  | some b => exact ⟨b, rfl⟩
  | none =>
    obtain ⟨b, hb, he⟩ := List.mem_map.mp h
    have hn := List.find?_eq_none.mp hf b hb
    simp [he] at hn

/-- Giving up dead names succeeds when all environment ids exist. It preserves
ownership, the complete binding-id list, pending results and outside holders.
The liveness proof must additionally show that the discarded names are dead. -/
theorem give_up_dead_safe (s : RunState) (env : Env) (chosen : List Frame)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (he : ∀ p ∈ env, p.2 ∈ s.bindings.map Binding.id) :
    ∃ t, giveUpDead Variant.approved env chosen s = (.ok (), t) ∧ Owned t ∧
      t.bindings.map Binding.id = s.bindings.map Binding.id ∧
      t.pending = s.pending ∧ t.outside = s.outside := by
  let P := fun t : RunState => Owned t ∧
    t.bindings.map Binding.id = s.bindings.map Binding.id ∧
    t.pending = s.pending ∧ t.outside = s.outside
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
    obtain ⟨hhu, hids, hpend, hout⟩ := hpu
    have huniq : (u.bindings.map Binding.id).Nodup := by simpa [hids] using hu
    have hid : p.2 ∈ u.bindings.map Binding.id := by
      rw [hids]
      exact he p (by simpa using hp)
    obtain ⟨b, hf⟩ := find_binding_id u.bindings p.2 hid
    cases hv : b.value with
    | num n => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hpend, hout⟩
    | bool b => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hpend, hout⟩
    | list r =>
      cases r with
      | none => exact ⟨u, by simp [act, getBinding, hf, hv], hhu, hids, hpend, hout⟩
      | some a =>
        by_cases hg : (b.status == .holding && !(usedLater chosen p.2)) = true
        · obtain ⟨hstatus, hused⟩ : b.status = .holding ∧ usedLater chosen p.2 = false := by
            simpa using hg
          obtain ⟨t, ht, hht, hbt, hpt, hot, _⟩ :=
            give_up_binding_owned u p.2 b (some a) hhu huniq hf hstatus hv
          refine ⟨t, ?_, hht, ?_, hpt.trans hpend, hot.trans hout⟩
          · simp [act, getBinding, hf, hv, hstatus, hused, ht]
          · rw [hbt, status_update_ids, hids]
        · refine ⟨u, ?_, hhu, hids, hpend, hout⟩
          have hno : ¬(b.status = .holding ∧ usedLater chosen p.2 = false) := by simpa using hg
          simp [act, getBinding, hf, hv, hno]
  obtain ⟨t, ht, hpt⟩ := for_in_invariant env.reverse act P hact s ⟨hh, rfl, rfl, rfl⟩
  refine ⟨t, ?_, hpt⟩
  unfold giveUpDead
  change ((forIn env.reverse PUnit.unit (fun p _ => act p) : M PUnit) >>= fun _ => pure ()) s = (.ok (), t)
  rw [m_bind_apply, ht]
  rfl

end Trial.Proofs
