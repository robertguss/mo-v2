import Proofs.Liveness

namespace Trial.Proofs

/-- Scalars and the empty list contribute no nonempty root. -/
def valueRoot : RawValue → Option Addr
  | .list r => r
  | _ => none

/-- Roots owned by bindings, in binding order, with their actual multiplicity. -/
def bindingRoots (bs : List Binding) : List (Option Addr) :=
  bs.filterMap (fun b => if b.status == .holding then some (valueRoot b.value) else none)

/-- All counted owners outside cell links at an evaluator boundary. -/
def ownedRoots (s : RunState) : List (Option Addr) :=
  bindingRoots s.bindings ++ s.pending.map valueRoot ++ s.outside

def Owned (s : RunState) : Prop := Healthy s.mem (ownedRoots s)

/-- Updating a nonexistent binding id leaves the list unchanged. -/
theorem status_update_absent (bs : List Binding) (id : Nat) (st : BStatus)
    (h : ∀ b ∈ bs, b.id ≠ id) :
    bs.map (fun b => if b.id == id then { b with status := st } else b) = bs := by
  induction bs with
  | nil => rfl
  | cons b bs ih =>
    have hn := h b (by simp)
    have ht := ih (fun c hc => h c (by simp [hc]))
    simp only [beq_iff_eq] at ht
    simp [hn, ht]

/-- Status updates preserve ids, even for bindings which no longer hold. -/
theorem status_update_ids (bs : List Binding) (id : Nat) (st : BStatus) :
    (bs.map (fun b => if b.id == id then { b with status := st } else b)).map Binding.id =
      bs.map Binding.id := by
  simp only [List.map_map]
  apply List.map_congr_left
  intro b _
  simp only [Function.comp_apply]
  split <;> rfl

/-- Giving up one uniquely identified holding binding removes exactly its root,
regardless of where the binding sits in the list. -/
theorem binding_roots_remove (bs : List Binding) (id : Nat) (b : Binding)
    (hu : (bs.map Binding.id).Nodup)
    (hf : bs.find? (fun d => d.id == id) = some b) (hs : b.status = .holding)
    (st : BStatus) (hn : st ≠ .holding) :
    (bindingRoots bs).Perm
      (valueRoot b.value :: bindingRoots
        (bs.map (fun d => if d.id == id then { d with status := st } else d))) := by
  induction bs with
  | nil => simp at hf
  | cons c cs ih =>
    simp only [List.map_cons, List.nodup_cons] at hu
    by_cases hci : c.id = id
    · simp [hci] at hf
      subst b
      have ha : ∀ d ∈ cs, d.id ≠ id := by
        intro d hd he
        exact hu.1 (List.mem_map.mpr ⟨d, hd, he.trans hci.symm⟩)
      have ht := status_update_absent cs id st ha
      simp only [beq_iff_eq] at ht
      simp [bindingRoots, hs, hci, hn, ht]
    · simp [hci] at hf
      have hp := ih hu.2 hf
      simp only [beq_iff_eq] at hp
      by_cases hc : c.status = .holding
      · simpa [bindingRoots, hci, hc] using
          (hp.cons (valueRoot c.value)).trans (List.Perm.swap (valueRoot b.value) (valueRoot c.value) _)
      · simpa [bindingRoots, hci, hc] using hp

/-- A holding binding's root occurs in the actual ownership list. -/
theorem holding_root_mem (s : RunState) (b : Binding) (hb : b ∈ s.bindings)
    (hs : b.status = .holding) : valueRoot b.value ∈ ownedRoots s := by
  apply List.mem_append_left
  apply List.mem_append_left
  exact List.mem_filterMap.mpr ⟨b, hb, by simp [hs]⟩

/-- The approved binding-release operation succeeds and consumes precisely the
root removed by changing the binding's status. -/
theorem give_up_binding_owned (s : RunState) (id : Nat) (b : Binding) (r : Option Addr)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (hf : s.bindings.find? (fun d => d.id == id) = some b)
    (hs : b.status = .holding) (hv : b.value = .list r) :
    ∃ t, giveUpBinding Variant.approved id s = (.ok (), t) ∧ Owned t ∧
      t.bindings = s.bindings.map (fun d => if d.id == id then { d with status := .givenUp } else d) ∧
      t.pending = s.pending ∧ t.outside = s.outside ∧
      (∀ q ∈ ownedRoots t, readBack t.mem (.list q) = readBack s.mem (.list q)) := by
  let bs := s.bindings.map (fun d => if d.id == id then { d with status := .givenUp } else d)
  let u : RunState := { s with bindings := bs }
  have hperm : (ownedRoots s).Perm (r :: ownedRoots u) := by
    have hp := binding_roots_remove s.bindings id b hu hf hs .givenUp (by decide)
    have hp' := (hp.append_right (s.pending.map valueRoot)).append_right s.outside
    simpa [ownedRoots, hv, valueRoot, u, bs] using hp'
  have hheap : Healthy u.mem (r :: ownedRoots u) := hh.perm hperm
  obtain ⟨t, he, ht, hread, hpend, hbind, hout⟩ := give_up_link_safe u r (ownedRoots u) hheap
  have hroots : ownedRoots t = ownedRoots u := by simp [ownedRoots, hpend, hbind, hout]
  refine ⟨t, ?_, ?_, hbind, hpend, hout, ?_⟩
  · simpa [giveUpBinding, getBinding, setBindingStatus, hf, hv, u, bs] using he
  · unfold Owned
    rw [hroots]
    exact ht
  · intro q hq
    exact hread q (hroots ▸ hq)

/-- Fields used only for logging, scope display and fresh ids do not alter ownership. -/
theorem Owned.same_fields {s t : RunState} (h : Owned s)
    (hm : t.mem = s.mem) (hb : t.bindings = s.bindings)
    (hp : t.pending = s.pending) (ho : t.outside = s.outside) : Owned t := by
  simpa [Owned, ownedRoots, hm, hb, hp, ho] using h

/-- A newly produced nonempty list owns the new first pending holder. -/
theorem owned_push (s : RunState) (a : Addr)
    (h : Healthy s.mem (some a :: ownedRoots s)) :
    Owned { s with pending := .list (some a) :: s.pending } := by
  apply h.perm
  simpa [ownedRoots, valueRoot, List.append_assoc] using
    (List.perm_middle (a := some a) (l₁ := bindingRoots s.bindings)
      (l₂ := s.pending.map valueRoot ++ s.outside)).symm

/-- Moving a binding's holder to a pending result changes no count. -/
theorem owned_move (s : RunState) (id : Nat) (b : Binding) (a : Addr)
    (h : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (hf : s.bindings.find? (fun d => d.id == id) = some b)
    (hs : b.status = .holding) (hv : b.value = .list (some a)) :
    Owned { s with
      bindings := s.bindings.map (fun d => if d.id == id then { d with status := .movedOn } else d)
      pending := .list (some a) :: s.pending } := by
  let u : RunState := { s with
    bindings := s.bindings.map (fun d => if d.id == id then { d with status := .movedOn } else d) }
  have hp := binding_roots_remove s.bindings id b hu hf hs .movedOn (by decide)
  have hp' := (hp.append_right (s.pending.map valueRoot)).append_right s.outside
  have hperm : (ownedRoots s).Perm (some a :: ownedRoots u) := by
    simpa [ownedRoots, valueRoot, hv, u] using hp'
  exact owned_push u a (h.perm hperm)

end Trial.Proofs
