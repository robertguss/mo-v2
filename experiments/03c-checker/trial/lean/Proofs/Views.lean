import Proofs.NewBinding

namespace Trial.Proofs

/-- A snapshot exposes only the original bindings and outside holders, and
reads every protected root as it read before the operation. -/
def StableView (s : RunState) (roots : List (Option Addr)) (sn : Snapshot) : Prop :=
  sn.bindings.Sublist s.bindings ∧ sn.outside = s.outside ∧
    ∀ r ∈ roots, readBack (snapMemory sn) (.list r) = readBack s.mem (.list r)

/-- Both the current state and every newly recorded snapshot preserve the
protected values. Earlier snapshots are retained as earlier observations. -/
structure PreservesViews (roots : List (Option Addr)) (s t : RunState) : Prop where
  bindings : t.bindings = s.bindings
  outside : t.outside = s.outside
  values : ∀ r ∈ roots, readBack t.mem (.list r) = readBack s.mem (.list r)
  snapshots : ∀ sn ∈ t.snaps, sn ∈ s.snaps ∨ StableView s roots sn

theorem PreservesViews.refl (roots : List (Option Addr)) (s : RunState) :
    PreservesViews roots s s :=
  ⟨rfl, rfl, fun _ _ => rfl, fun _ h => Or.inl h⟩

theorem PreservesViews.trans {roots : List (Option Addr)} {s t u : RunState}
    (h : PreservesViews roots s t) (g : PreservesViews roots t u) :
    PreservesViews roots s u := by
  refine ⟨g.bindings.trans h.bindings, g.outside.trans h.outside,
    fun r hr => (g.values r hr).trans (h.values r hr), ?_⟩
  intro sn hsn
  rcases g.snapshots sn hsn with hp | hv
  · exact h.snapshots sn hp
  · obtain ⟨hb, ho, hr⟩ := hv
    exact Or.inr ⟨by simpa [h.bindings] using hb, ho.trans h.outside,
      fun r hm => (hr r hm).trans (h.values r hm)⟩

/-- An unrecorded state change needs only its current visible fields checked. -/
theorem PreservesViews.of_fields (roots : List (Option Addr)) (s t : RunState)
    (hb : t.bindings = s.bindings) (ho : t.outside = s.outside)
    (hv : ∀ r ∈ roots, readBack t.mem (.list r) = readBack s.mem (.list r))
    (hs : t.snaps = s.snaps) : PreservesViews roots s t :=
  ⟨hb, ho, hv, fun _ h => Or.inl (hs ▸ h)⟩

theorem snapshot_views (s : RunState) (roots : List (Option Addr))
    (kind : StepKind) (bv : Option RawValue) :
    PreservesViews roots s (snapshot kind bv s).2 := by
  refine ⟨rfl, rfl, fun _ _ => rfl, ?_⟩
  intro sn hsn
  simp only [snapshot, m_bind_apply, m_get_apply, m_set_apply] at hsn
  rcases List.mem_append.mp hsn with hp | he
  · exact Or.inl hp
  · have he' := List.mem_singleton.mp he
    subst sn
    exact Or.inr ⟨List.filter_sublist, rfl,
      fun r _ => read_back_cells { cells := s.mem.cells } s.mem rfl (.list r)⟩

/-- A count change is invisible even in the snapshot immediately after it. -/
theorem give_up_shared_views (s : RunState) (a : Addr) (c : Cell) (fuel : Nat)
    (roots : List (Option Addr)) (hf : s.mem.find? a = some c)
    (hl : c.status = .live) (hc : 2 ≤ c.count) :
    PreservesViews roots s (giveUp Variant.approved (fuel + 1) a s).2 := by
  let m := s.mem.updateCell a (fun d => { d with count := c.count - 1 })
  let u : RunState := { s with mem := m }
  have hu : s.mem.setCount a (c.count - 1) = .ok m := by simp [Memory.setCount, hf, m]
  have hv : PreservesViews roots s u :=
    .of_fields roots s u rfl rfl (fun r _ => set_count_read_back s.mem m a _ hu (.list r)) rfl
  have hn : c.count ≠ 0 := by omega
  have hn' : c.count - 1 ≠ 0 := by omega
  have he : (giveUp Variant.approved (fuel + 1) a s).2 =
      (snapshot .holderGivenUp none u).2 := by
    simp [giveUp, getCell, memOp, Memory.setCount, snapshot, Variant.approved,
      hf, hl, hn, hn', u, m]
  rw [he]
  exact hv.trans (snapshot_views u roots .holderGivenUp none)

/-- Both observations of an exclusive release are safe: the zero-count cell
before freeing, and the memory after freeing it. The freed root itself is not
among the protected roots. -/
theorem give_up_exclusive_views (s : RunState) (a : Addr) (c : Cell)
    (roots : List (Option Addr)) (cs : List Cell)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hc : c.count = 1)
    (hh : HeapSafe s.mem (some a :: roots)) (ht : ListPath s.mem c.link cs) :
    PreservesViews roots s (giveUp Variant.approved 1 a s).2 := by
  let m := s.mem.updateCell a (fun d => { d with count := 0 })
  let u : RunState := { s with mem := m }
  let u1 := (snapshot .holderGivenUp none u).2
  let m2 : Memory := { m with
    cells := m.cells.filter (fun d => d.addr != a)
    record := m.record ++ [.released a] }
  let u2 : RunState := { u1 with
    mem := m2
    log := u1.log ++ [.free a]
    pending := match c.link with | none => u1.pending | some _ => .list c.link :: u1.pending }
  let u3 := (snapshot .cellFreed none u2).2
  let t := (giveUp Variant.approved 1 a s).2
  have hm : s.mem.setCount a 0 = .ok m := by simp [Memory.setCount, hf, m]
  have hca : c.addr = a := by simpa using (List.find?_some hf)
  have hz : m.find? a = some { c with count := 0 } := by
    rw [find_update s.mem a a _ (by intro d _; rfl)]
    simp [hf, hca]
  have hrel : s.mem.release a = .ok m2 := by
    simp [Memory.release, hf, m2, m, Memory.updateCell]
    simpa only [beq_iff_eq] using (filter_count_update s.mem.cells a 0).symm
  have hread := (hh.release_one hf hl hc hrel cs ht).2.1
  have hv : PreservesViews roots s u :=
    .of_fields roots s u rfl rfl (fun r _ => set_count_read_back s.mem m a 0 hm (.list r)) rfl
  have hv1 := hv.trans (snapshot_views u roots .holderGivenUp none)
  have hv2 : PreservesViews roots u1 u2 :=
    .of_fields roots u1 u2 rfl rfl
      (fun r hr => (hread r hr).trans (hv1.values r hr).symm) rfl
  have hv3 := (hv1.trans hv2).trans (snapshot_views u2 roots .cellFreed none)
  have he : t = { u3 with pending := s.pending } := by
    cases hlink : c.link <;>
      simp [t, u3, u2, u1, u, m2, giveUp, getCell, memOp, Memory.setCount,
        snapshot, Variant.approved, Memory.release, logEvent, pushPending,
        popPending, hf, hl, hc, hz, hlink, m]
  change PreservesViews roots s t
  rw [he]
  exact hv3.trans (.of_fields roots u3 _ rfl rfl (fun _ _ => rfl) rfl)

/-- Every snapshot throughout a successful freeing cascade preserves the
other roots, not just the cascade's final memory. -/
theorem give_up_views (fuel : Nat) (s : RunState) (a : Addr)
    (roots : List (Option Addr)) (cs : List Cell)
    (hp : ListPath s.mem (some a) cs) (hn : cs.length ≤ fuel)
    (hh : HeapSafe s.mem (some a :: roots)) :
    PreservesViews roots s (giveUp Variant.approved fuel a s).2 := by
  induction fuel generalizing s a roots cs with
  | zero => cases hp with | cons c cs hf hl ht => simp at hn
  | succ fuel ih =>
    cases hp with
    | cons c cs hf hl ht =>
      by_cases hone : c.count = 1
      · let t0 := (giveUp Variant.approved 1 c.addr s).2
        obtain ⟨hm, _, _, _, _, hstep⟩ := give_up_exclusive s c.addr c hf hl hone
        have hrel : s.mem.release c.addr = .ok t0.mem := by
          rw [hm]
          simp [Memory.release, hf]
        obtain ⟨hh0, _, htail⟩ := hh.release_one hf hl hone hrel cs ht
        have hv0 := give_up_exclusive_views s c.addr c roots cs hf hl hone hh ht
        have hlen : cs.length ≤ fuel := by simpa using hn
        rw [hstep fuel]
        cases hlink : c.link with
        | none => exact hv0
        | some b =>
          have hh0' : HeapSafe t0.mem (some b :: roots) := by simpa [hlink] using hh0
          have ht0 : ListPath t0.mem (some b) cs := by simpa [hlink] using htail
          exact hv0.trans (ih t0 b roots cs ht0 hlen hh0')
      · have hc := hh.counts c (List.mem_of_find?_eq_some hf) hl
        rw [holders_cons_self] at hc
        exact give_up_shared_views s c.addr c fuel roots hf hl (by omega)

theorem give_up_link_views (s : RunState) (r : Option Addr) (roots : List (Option Addr))
    (hh : HeapSafe s.mem (r :: roots)) :
    PreservesViews roots s (giveUpLink Variant.approved r s).2 := by
  cases r with
  | none => exact .refl roots s
  | some a =>
    obtain ⟨cs, hp⟩ := hh.readable (some a) (by simp)
    simpa [giveUpLink] using give_up_views s.mem.cells.length s a roots cs hp hp.length_le hh

/-- Protected holding meanings extend to every newly recorded observation. -/
theorem PreservesViews.names {s t : RunState} {roots : List (Option Addr)}
    (h : PreservesViews roots s t)
    (hr : ∀ r ∈ bindingRoots s.bindings, r ∈ roots)
    (raw : Nat → RawValue) (meaning : Nat → PlainValue)
    (hpast : ∀ sn ∈ s.snaps, HoldingMeanings (snapMemory sn) sn.bindings raw meaning)
    (hnow : HoldingMeanings s.mem s.bindings raw meaning) :
    ∀ sn ∈ t.snaps, HoldingMeanings (snapMemory sn) sn.bindings raw meaning := by
  intro sn hsn
  rcases h.snapshots sn hsn with hp | hv
  · exact hpast sn hp
  · obtain ⟨hb, _, hread⟩ := hv
    intro b hbs hs
    have hmem := hb.subset hbs
    obtain ⟨he, hm⟩ := hnow b hmem hs
    refine ⟨he, ?_⟩
    have hroot : valueRoot b.value ∈ roots :=
      hr _ (List.mem_filterMap.mpr ⟨b, hmem, by simp [hs]⟩)
    exact (read_back_root _ _ b.value (hread _ hroot)).trans hm

/-- Releasing a binding preserves every still-held name in every snapshot,
including the snapshots inside a multi-cell release cascade. -/
theorem give_up_binding_snapshots (s : RunState) (id : Nat) (b : Binding) (r : Option Addr)
    (hh : Owned s) (hu : (s.bindings.map Binding.id).Nodup)
    (hf : s.bindings.find? (fun d => d.id == id) = some b)
    (hs : b.status = .holding) (hv : b.value = .list r)
    (raw : Nat → RawValue) (meaning : Nat → PlainValue)
    (hpast : ∀ sn ∈ s.snaps, HoldingMeanings (snapMemory sn) sn.bindings raw meaning)
    (hnow : HoldingMeanings s.mem s.bindings raw meaning) :
    ∀ sn ∈ (giveUpBinding Variant.approved id s).2.snaps,
      HoldingMeanings (snapMemory sn) sn.bindings raw meaning := by
  let bs := s.bindings.map (fun d => if d.id == id then { d with status := .givenUp } else d)
  let u : RunState := { s with bindings := bs }
  have hperm : (ownedRoots s).Perm (r :: ownedRoots u) := by
    have hp := binding_roots_remove s.bindings id b hu hf hs .givenUp (by decide)
    have hp' := (hp.append_right (s.pending.map valueRoot)).append_right s.outside
    simpa [ownedRoots, hv, valueRoot, u, bs] using hp'
  have hheap : Healthy u.mem (r :: ownedRoots u) := hh.perm hperm
  have hview := give_up_link_views u r (ownedRoots u) hheap.toHeapSafe
  have hmean : HoldingMeanings u.mem u.bindings raw meaning :=
    hnow.drop id .givenUp (by decide)
  have hnames := hview.names
    (fun _ hr => List.mem_append_left _ (List.mem_append_left _ hr)) raw meaning hpast hmean
  simpa [giveUpBinding, getBinding, setBindingStatus, hf, hv, u, bs] using hnames

/-- Allocating or reusing a reserved cell records one snapshot, and that
snapshot preserves every previously owned list. -/
theorem build_cell_views (s : RunState) (enc : List Nat) (item : Int) (link : Option Addr)
    (rest : List RawValue) (hh : Owned s)
    (hpend : s.pending = match link with | none => rest | some a => .list (some a) :: rest)
    (hreserved : ∀ bid a more, s.setAside = (bid, a) :: more →
      enc.contains bid = true ∧ ∃ c, s.mem.find? a = some c ∧ c.status = .setAside) :
    PreservesViews (ownedRoots s) s (buildCell Variant.approved enc item link s).2 := by
  obtain ⟨a, t, items, he, _, _, _, _, hb, ho, _, hr, hs⟩ :=
    build_cell_safe s enc item link rest hh hpend hreserved
  rw [he]
  let u : RunState := { t with snaps := s.snaps }
  have hu : PreservesViews (ownedRoots s) s u :=
    .of_fields _ s u hb ho hr rfl
  have hv := hu.trans (snapshot_views u (ownedRoots s) .newCellBuilt none)
  refine ⟨hb, ho, hr, ?_⟩
  intro sn hsn
  apply hv.snapshots sn
  rw [← hs]
  exact hsn

end Trial.Proofs
