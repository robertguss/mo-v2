import Proofs.ReleaseFrame

namespace Trial.Proofs

theorem read_back_no_root (m m' : Memory) (v : RawValue) (hn : valueRoot v = none) :
    readBack m v = readBack m' v := by
  apply read_back_root
  rw [hn]
  exact (ListPath.nil (m := m)).read_back.trans (ListPath.nil (m := m')).read_back.symm

/-- Giving up a binding establishes the full boundary invariant, including
reserved-cell tracking, historical meanings, and the saved pending values. -/
theorem release_binding_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (id : Nat) (b : Binding) (a : Addr)
    (hf : s.bindings.find? (fun d => d.id == id) = some b)
    (hs : b.status = .holding) (hv : b.value = .list (some a)) :
    ∃ t, giveUpBinding Variant.approved id s = (.ok (), t) ∧
      StateInvariant start g enc t ∧
      t.bindings = s.bindings.map (fun d => if d.id == id then { d with status := .givenUp } else d) ∧
      t.pending = s.pending ∧ ReleaseFrame s t ∧
      (∀ v ∈ s.pending, readBack t.mem v = readBack s.mem v) := by
  let bs := s.bindings.map (fun d => if d.id == id then { d with status := .givenUp } else d)
  let u : RunState := { s with bindings := bs }
  have hperm : (ownedRoots s).Perm (some a :: ownedRoots u) := by
    have hp := binding_roots_remove s.bindings id b h.unique hf hs .givenUp (by decide)
    have hp' := (hp.append_right (s.pending.map valueRoot)).append_right s.outside
    simpa [ownedRoots, hv, valueRoot, u, bs] using hp'
  have hheap : Healthy u.mem (some a :: ownedRoots u) := h.owned.perm hperm
  obtain ⟨t, he, hhealthy, hread, hpend, hbind, hout⟩ :=
    give_up_link_safe u (some a) (ownedRoots u) hheap
  have hframe := give_up_link_frame u (some a) (ownedRoots u) hheap
  have hviews := give_up_link_views u (some a) (ownedRoots u) hheap.toHeapSafe
  rw [he] at hframe hviews
  change ReleaseFrame u t at hframe
  change PreservesViews (ownedRoots u) u t at hviews
  have hframe' : ReleaseFrame s t :=
    ⟨hframe.bindingCounter, hframe.branchCounter, hframe.stack, hframe.snapshots, hframe.reserved⟩
  have hroots : ownedRoots t = ownedRoots u := by simp [ownedRoots, hbind, hpend, hout]
  have howned : Owned t := by unfold Owned; rw [hroots]; exact hhealthy
  have hcurrent : HoldingMeanings t.mem t.bindings (fun id => (g id).1) (fun id => (g id).2) := by
    rw [hbind]
    exact (h.holding_meanings.drop id .givenUp (by decide)).roots
      (fun r hr => hread r (List.mem_append_left _ (List.mem_append_left _ hr)))
  have hhistory := hviews.names
    (fun _ hr => List.mem_append_left _ (List.mem_append_left _ hr))
    (fun id => (g id).1) (fun id => (g id).2) h.history
    (h.holding_meanings.drop id .givenUp (by decide))
  have hbound : ∀ d ∈ u.bindings, d.id < s.nextBinding := by
    intro d hd
    obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
    by_cases hi : q.id = id <;> simpa [hi] using h.bound q hq
  have hraw : ∀ d ∈ t.bindings, d.value = (g d.id).1 := by
    intro d hd
    rw [hbind] at hd
    obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
    by_cases hi : q.id = id <;> simpa [hi] using h.raw q hq
  have hkind : ∀ d ∈ t.bindings, d.value.kind = (g d.id).2.kind := by
    intro d hd
    rw [hbind] at hd
    obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
    by_cases hi : q.id = id <;> simpa [hi] using h.kinds q hq
  have houtMem : ∀ r ∈ start.outside,
      readBack t.mem (.list r) = readBack start.toMemory (.list r) := by
    intro r hr
    have hru : r ∈ ownedRoots u := List.mem_append_right _ (h.outside ▸ hr)
    exact (hread r hru).trans (h.outsideValues r hr)
  refine ⟨t, ?_, {
    owned := howned
    ids := by rw [hbind, status_update_ids, h.ids, hframe'.bindingCounter]
    raw := hraw
    kinds := hkind
    readable := ?_
    holding := ?_
    pending := by simpa [hpend] using h.pending
    reserved := ?_
    tracked := ?_
    detached := fun c hc hs => h.detached c ((hframe.reserved c hs).mp hc) hs
    addresses := by simpa [hframe'.stack] using h.addresses
    labels := by simpa [hframe'.stack] using h.labels
    ordered := by simpa [hframe'.stack] using h.ordered
    branches := h.branches
    branchBound := by simpa [hframe'.branchCounter] using h.branchBound
    outside := hout.trans h.outside
    outsideValues := houtMem
    history := hhistory
    historyBound := ?_
    outsideHistory := ?_ }, hbind, hpend, hframe', ?_⟩
  · simpa [giveUpBinding, getBinding, setBindingStatus, hf, hv, u, bs] using he
  · intro d hd hreadable
    rcases hreadable with hh | hn
    · exact (hcurrent d hd hh).2
    · rw [hbind] at hd
      obtain ⟨q, hq, heq⟩ := List.mem_map.mp hd
      have hid : q.id = d.id := by
        by_cases hi : q.id = id <;> simpa [hi] using congrArg Binding.id heq
      have hval : q.value = d.value := by
        by_cases hi : q.id = id <;> simpa [hi] using congrArg Binding.value heq
      have hqn : valueRoot q.value = none := hval ▸ hn
      have hqr := h.readable q hq (Or.inr hqn)
      exact (read_back_no_root t.mem s.mem d.value hn).trans (by simpa [hval, hid] using hqr)
  · intro d hd hh
    rw [hbind] at hd
    obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hd
    by_cases hi : q.id = id
    · simp [hi] at hh
    · simpa [hi] using h.holding q hq (by simpa [hi] using hh)
  · intro p hp
    rw [hframe.stack] at hp
    obtain ⟨c, hc, hs⟩ := h.reserved p hp
    have ha : c.addr = p.2 := by simpa using List.find?_some hc
    refine ⟨c, ?_, hs⟩
    have hct := (hframe.reserved c hs).mpr (List.mem_of_find?_eq_some hc)
    simpa [Memory.find?, ha] using cell_find_self t.mem.cells howned.unique c hct
  · intro c hc hs
    obtain ⟨bid, hb⟩ := h.tracked c ((hframe.reserved c hs).mp hc) hs
    exact ⟨bid, by simpa [hframe'.stack] using hb⟩
  · intro sn hsn d hd
    rw [hframe.bindingCounter]
    rcases hviews.snapshots sn hsn with hp | hn
    · exact h.historyBound sn hp d hd
    · exact hbound d (List.Sublist.subset hn.1 hd)
  · intro sn hsn
    rcases hviews.snapshots sn hsn with hp | hn
    · exact h.outsideHistory sn hp
    · refine ⟨hn.2.1.trans h.outside, ?_⟩
      intro r hr
      exact (hn.2.2 r (List.mem_append_right _ (h.outside ▸ hr))).trans (h.outsideValues r hr)
  · intro v hv'
    apply read_back_root
    exact hread (valueRoot v)
      (List.mem_append_left _ (List.mem_append_right _ (List.mem_map.mpr ⟨v, hv', rfl⟩)))

end Trial.Proofs
