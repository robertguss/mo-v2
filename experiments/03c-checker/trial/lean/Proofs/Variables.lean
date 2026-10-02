import Proofs.Bindings

namespace Trial.Proofs

/-- Looking up a holding list binding succeeds under either last-use choice.
The result owns a new pending holder, and no raw value's read-back changes. -/
theorem variable_list_safe (s : RunState) (env : Env) (fs : List Frame) (enc : List Nat)
    (x : String) (id : Nat) (b : Binding) (a : Addr)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (henv : env.find? (fun p => p.1 == x) = some (x, id))
    (hf : s.bindings.find? (fun d => d.id == id) = some b)
    (hs : b.status = .holding) (hv : b.value = .list (some a)) :
    ∃ t, evalC Variant.approved (.var x) env fs enc s = (.ok (.list (some a)), t) ∧
      Owned t ∧ t.pending = .list (some a) :: s.pending ∧ t.outside = s.outside ∧
      ∀ v, readBack t.mem v = readBack s.mem v := by
  by_cases hlater : usedLater fs id = true
  · have hr : some a ∈ ownedRoots s := by
      simpa [hv, valueRoot] using holding_root_mem s b (List.mem_of_find?_eq_some hf) hs
    obtain ⟨cs, hp⟩ := hh.readable (some a) hr
    obtain ⟨u, hadd, hu, hread, hpend, hbind, hout⟩ := add_holder_safe s a (ownedRoots s) hh cs hp
    have hroots : ownedRoots u = ownedRoots s := by simp [ownedRoots, hpend, hbind, hout]
    have hup : Owned { u with pending := .list (some a) :: u.pending } :=
      owned_push u a (by simpa [hroots] using hu)
    let p : RunState := { u with
      pending := .list (some a) :: u.pending
      scope := env.reverse.map (fun q => q.2) }
    let t := (snapshot .newHolder none p).2
    refine ⟨t, ?_, ?_, ?_, ?_, ?_⟩
    · simp [evalC, henv, getBinding, hf, hs, hv, hlater, hadd, pushPending, enter, snapshot, p, t]
    · apply hup.same_fields <;> simp [t, p, snapshot]
    · simp [t, p, snapshot, hpend]
    · simp [t, p, snapshot, hout]
    · intro v
      simpa [t, p, snapshot] using hread v
  · let p : RunState := { s with
      bindings := s.bindings.map (fun d => if d.id == id then { d with status := .movedOn } else d)
      pending := .list (some a) :: s.pending
      scope := env.reverse.map (fun q => q.2) }
    let t := (snapshot .holderMoved none p).2
    have hmove := owned_move s id b a hh hu hf hs hv
    refine ⟨t, ?_, ?_, ?_, ?_, ?_⟩
    · simp [evalC, henv, getBinding, hf, hs, hv, hlater, setBindingStatus,
        pushPending, enter, snapshot, p, t]
    · apply hmove.same_fields <;> simp [t, p, snapshot]
    · simp [t, p, snapshot]
    · simp [t, p, snapshot]
    · intro v
      simp [t, p, snapshot]

/-- Scalar and empty-list names do not perform any memory operation. -/
theorem variable_no_holder (s : RunState) (env : Env) (fs : List Frame) (enc : List Nat)
    (x : String) (id : Nat) (b : Binding)
    (henv : env.find? (fun p => p.1 == x) = some (x, id))
    (hf : s.bindings.find? (fun d => d.id == id) = some b)
    (hn : ∀ a, b.value ≠ .list (some a)) :
    evalC Variant.approved (.var x) env fs enc s = (.ok b.value, s) := by
  cases hv : b.value with
  | num n => simp [evalC, henv, getBinding, hf, hv]
  | bool b => simp [evalC, henv, getBinding, hf, hv]
  | list r =>
    cases r with
    | none => simp [evalC, henv, getBinding, hf, hv]
    | some a => exact False.elim (hn a hv)

end Trial.Proofs
