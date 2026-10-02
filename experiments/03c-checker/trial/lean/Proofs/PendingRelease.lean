import Proofs.SharedContract

namespace Trial.Proofs

/-- Releasing the match's pending holder preserves the complete invariant,
including every intermediate release snapshot and other pending values. -/
theorem release_pending_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (a : Addr) (rest : List RawValue)
    (hp : s.pending = .list (some a) :: rest) :
    ∃ t, (do popPending (.list (some a)); giveUpLink Variant.approved (some a) : M Unit) s = (.ok (), t) ∧
      StateInvariant start g enc t ∧ t.bindings = s.bindings ∧ t.pending = rest ∧
      ReleaseFrame s t ∧ (∀ v ∈ rest, readBack t.mem v = readBack s.mem v) := by
  let u := { s with pending := rest }
  have hheap : Healthy u.mem (some a :: ownedRoots u) := pending_tail_heap s (some a) rest h.owned hp
  obtain ⟨t, ht, hhealthy, hread, hpend, hbind, hout⟩ := give_up_link_safe u (some a) (ownedRoots u) hheap
  have hframe := give_up_link_frame u (some a) (ownedRoots u) hheap
  have hview := give_up_link_views u (some a) (ownedRoots u) hheap.toHeapSafe
  rw [ht] at hframe hview
  change ReleaseFrame u t at hframe
  change PreservesViews (ownedRoots u) u t at hview
  have hfr : ReleaseFrame s t :=
    ⟨hframe.bindingCounter, hframe.branchCounter, hframe.stack, hframe.snapshots, hframe.reserved⟩
  have hroots : ownedRoots t = ownedRoots u := by simp [ownedRoots, hpend, hbind, hout]
  have howned : Owned t := by unfold Owned; rw [hroots]; exact hhealthy
  have hhold : HoldingMeanings t.mem t.bindings (fun id => (g id).1) (fun id => (g id).2) := by
    rw [hbind]
    exact h.holding_meanings.roots
      (fun r hr => hread r (List.mem_append_left _ (List.mem_append_left _ hr)))
  refine ⟨t, ?_, {
    owned := howned
    ids := by rw [hbind, hframe.bindingCounter]; exact h.ids
    raw := by simpa [hbind, u] using h.raw
    kinds := by simpa [hbind, u] using h.kinds
    readable := ?_
    holding := by simpa [hbind, u] using h.holding
    pending := ?_
    reserved := ?_
    tracked := ?_
    detached := fun c hc hs => h.detached c ((hframe.reserved c hs).mp hc) hs
    addresses := by simpa [hframe.stack, u] using h.addresses
    labels := by simpa [hframe.stack, u] using h.labels
    ordered := by simpa [hframe.stack, u] using h.ordered
    branches := h.branches
    branchBound := by simpa [hframe.branchCounter, u] using h.branchBound
    outside := hout.trans h.outside
    outsideValues := fun r hr => (hread r (List.mem_append_right _ (h.outside ▸ hr))).trans (h.outsideValues r hr)
    history := hview.names (fun _ hr => List.mem_append_left _ (List.mem_append_left _ hr))
      _ _ h.history h.holding_meanings
    historyBound := ?_
    outsideHistory := ?_ }, hbind, hpend, hfr, ?_⟩
  · simpa [popPending, hp, u] using ht
  · intro b hb hreadable
    rcases hreadable with hh | hn
    · exact (hhold b hb hh).2
    · exact (read_back_no_root t.mem s.mem b.value hn).trans
        (h.readable b (hbind ▸ hb) (Or.inr hn))
  · intro v hv
    rw [hpend] at hv
    exact h.pending v (hp ▸ List.mem_cons_of_mem _ hv)
  · intro p hp'
    rw [hframe.stack] at hp'
    obtain ⟨c, hc, hs⟩ := h.reserved p hp'
    have ha : c.addr = p.2 := by simpa using List.find?_some hc
    refine ⟨c, ?_, hs⟩
    have hm := (hframe.reserved c hs).mpr (List.mem_of_find?_eq_some hc)
    simpa [Memory.find?, ha] using cell_find_self t.mem.cells howned.unique c hm
  · intro c hc hs
    obtain ⟨bid, hb⟩ := h.tracked c ((hframe.reserved c hs).mp hc) hs
    exact ⟨bid, by simpa [hframe.stack, u] using hb⟩
  · intro sn hsn b hb
    rw [hframe.bindingCounter]
    rcases hview.snapshots sn hsn with hp | hn
    · exact h.historyBound sn hp b hb
    · exact h.bound b (hn.1.subset hb)
  · intro sn hsn
    rcases hview.snapshots sn hsn with hp | hn
    · exact h.outsideHistory sn hp
    · refine ⟨hn.2.1.trans h.outside, ?_⟩
      intro r hr
      exact (hn.2.2 r (List.mem_append_right _ (h.outside ▸ hr))).trans (h.outsideValues r hr)
  · intro v hv
    exact read_back_root _ _ v (hread _ (owned_pending_root u v hv))

end Trial.Proofs
