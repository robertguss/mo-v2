import Proofs.Meanings

namespace Trial.Proofs

/-- The existing new-binding and pending-pop operations transfer a result's
holder to its fresh name. Binding ids stay unique and below the fresh counter. -/
theorem bind_result_owned (s : RunState) (name : String) (v : RawValue) (rest : List RawValue)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (hbound : ∀ b ∈ s.bindings, b.id < s.nextBinding)
    (hpend : s.pending = match v with | .list (some _) => v :: rest | _ => rest) :
    let status : BStatus := match v with | .list (some _) => .holding | _ => .noHolder
    ∃ t, (do
      let id ← newBinding name v status
      popPending v
      pure id : M Nat) s = (.ok s.nextBinding, t) ∧ Owned t ∧
      t.bindings = s.bindings ++ [{ id := s.nextBinding, name := name, value := v, status := status }] ∧
      t.pending = rest ∧ t.mem = s.mem ∧ t.outside = s.outside ∧
      t.nextBinding = s.nextBinding + 1 ∧ (t.bindings.map Binding.id).Nodup ∧
      (∀ b ∈ t.bindings, b.id < t.nextBinding) := by
  let status : BStatus := match v with | .list (some _) => .holding | _ => .noHolder
  let b : Binding := { id := s.nextBinding, name := name, value := v, status := status }
  let t : RunState := { s with
    bindings := s.bindings ++ [b]
    pending := rest
    nextBinding := s.nextBinding + 1 }
  refine ⟨t, ?_, ?_, rfl, rfl, rfl, rfl, rfl, ?_, ?_⟩
  · cases v with
    | num n => simp [newBinding, popPending, hpend, t, b, status]
    | bool b => simp [newBinding, popPending, hpend, t, b, status]
    | list r => cases r <;> simp [newBinding, popPending, hpend, t, b, status]
  · cases v with
    | num n | bool n =>
      simpa [Owned, ownedRoots, bindingRoots, t, b, status, hpend] using hh
    | list r => cases r <;>
        simpa [Owned, ownedRoots, bindingRoots, t, b, status, hpend, List.append_assoc] using hh
  · have hn : s.nextBinding ∉ s.bindings.map Binding.id := by
      intro hm
      obtain ⟨c, hc, he⟩ := List.mem_map.mp hm
      exact Nat.ne_of_lt (hbound c hc) he
    have huniq : (s.bindings.map Binding.id ++ [s.nextBinding]).Nodup := by
      apply List.nodup_append.mpr
      refine ⟨hu, by simp, ?_⟩
      intro a ha j hj haj
      have hj' : j = s.nextBinding := by simpa using hj
      exact hn (haj.trans hj' ▸ ha)
    simpa [t, b] using huniq
  · intro c hc
    change c.id < s.nextBinding + 1
    rcases List.mem_append.mp hc with hm | he
    · exact Nat.lt_trans (hbound c hm) (Nat.lt_succ_self _)
    · have he' : c = b := by simpa using he
      subst c
      exact Nat.lt_succ_self _

end Trial.Proofs
