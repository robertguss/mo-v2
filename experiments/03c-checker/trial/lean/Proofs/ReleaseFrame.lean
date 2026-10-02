import Proofs.VariableContract

namespace Trial.Proofs

/-- Release never consumes reservations or fresh identifiers, and appends its
observations. Exact reserved-cell identity includes detached links and counts. -/
structure ReleaseFrame (s t : RunState) : Prop where
  bindingCounter : t.nextBinding = s.nextBinding
  branchCounter : t.nextBranch = s.nextBranch
  stack : t.setAside = s.setAside
  snapshots : s.snaps.IsPrefix t.snaps
  reserved : ∀ c, c.status = .setAside → (c ∈ t.mem.cells ↔ c ∈ s.mem.cells)

theorem ReleaseFrame.refl (s : RunState) : ReleaseFrame s s :=
  ⟨rfl, rfl, rfl, ⟨[], by simp⟩, fun _ _ => Iff.rfl⟩

theorem ReleaseFrame.trans {s t u : RunState} (h : ReleaseFrame s t) (h' : ReleaseFrame t u) :
    ReleaseFrame s u :=
  ⟨h'.bindingCounter.trans h.bindingCounter, h'.branchCounter.trans h.branchCounter,
    h'.stack.trans h.stack, h.snapshots.trans h'.snapshots,
    fun c hc => (h'.reserved c hc).trans (h.reserved c hc)⟩

theorem reserved_other_live (m : Memory) (a : Addr) (c : Cell)
    (hu : (m.cells.map Cell.addr).Nodup) (hf : m.find? a = some c) (hl : c.status = .live) :
    ∀ d ∈ m.cells, d.status = .setAside → d.addr ≠ a := by
  intro d hd hs he
  have hd' : m.find? a = some d := by
    simpa [Memory.find?, he] using cell_find_self m.cells hu d hd
  have heq := Option.some.inj (hf.symm.trans hd')
  subst d
  simp [hl] at hs

theorem reserved_count_update (m : Memory) (a : Addr) (n : Nat)
    (hne : ∀ d ∈ m.cells, d.status = .setAside → d.addr ≠ a) :
    ∀ d, d.status = .setAside →
      (d ∈ (m.updateCell a (fun q => { q with count := n })).cells ↔ d ∈ m.cells) := by
  intro d hs
  constructor
  · intro hd
    obtain ⟨q, hq, he⟩ := List.mem_map.mp hd
    by_cases hqa : q.addr = a
    · have hqs : q.status = .setAside := by simpa [hqa, ← he] using hs
      exact False.elim (hne q hq hqs hqa)
    · have he' : q = d := by simpa [hqa] using he
      exact he' ▸ hq
  · intro hd
    exact List.mem_map.mpr ⟨d, hd, by simp [hne d hd hs]⟩

theorem reserved_filter_live (m : Memory) (a : Addr)
    (hne : ∀ d ∈ m.cells, d.status = .setAside → d.addr ≠ a) :
    ∀ d, d.status = .setAside →
      (d ∈ m.cells.filter (fun q => q.addr != a) ↔ d ∈ m.cells) := by
  intro d hs
  constructor
  · exact fun hd => (List.mem_filter.mp hd).1
  · intro hd
    exact List.mem_filter.mpr ⟨hd, by simpa using hne d hd hs⟩

theorem give_up_shared_frame (s : RunState) (a : Addr) (c : Cell) (fuel : Nat)
    (hu : (s.mem.cells.map Cell.addr).Nodup)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hc : 2 ≤ c.count) :
    ReleaseFrame s (giveUp Variant.approved (fuel + 1) a s).2 := by
  have hn : c.count ≠ 0 := by omega
  have hn' : c.count - 1 ≠ 0 := by omega
  have he : (giveUp Variant.approved (fuel + 1) a s).2 =
      (snapshot .holderGivenUp none
        { s with mem := s.mem.updateCell a (fun d => { d with count := c.count - 1 }) }).2 := by
    simp [giveUp, getCell, memOp, Memory.setCount, snapshot, Variant.approved, hf, hl, hn, hn']
  rw [he]
  exact ⟨rfl, rfl, rfl, ⟨_, rfl⟩,
    reserved_count_update s.mem a _ (reserved_other_live s.mem a c hu hf hl)⟩

theorem give_up_exclusive_frame (s : RunState) (a : Addr) (c : Cell)
    (hu : (s.mem.cells.map Cell.addr).Nodup)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hc : c.count = 1) :
    ReleaseFrame s (giveUp Variant.approved 1 a s).2 := by
  have hca : c.addr = a := by simpa using List.find?_some hf
  have hz : (s.mem.updateCell a (fun d => { d with count := 0 })).find? a =
      some { c with count := 0 } := by
    rw [find_update s.mem a a _ (by intro d _; rfl)]
    simp [hf, hca]
  have hm := (give_up_exclusive s a c hf hl hc).1
  refine ⟨?_, ?_, (give_up_exclusive s a c hf hl hc).2.2.2.2.1, ?_, ?_⟩
  · cases ht : c.link <;>
      simp [giveUp, getCell, memOp, Memory.setCount, snapshot, Variant.approved,
        Memory.release, logEvent, pushPending, popPending, hf, hl, hc, hz, ht]
  · cases ht : c.link <;>
      simp [giveUp, getCell, memOp, Memory.setCount, snapshot, Variant.approved,
        Memory.release, logEvent, pushPending, popPending, hf, hl, hc, hz, ht]
  · cases ht : c.link <;>
      simp [giveUp, getCell, memOp, Memory.setCount, snapshot, Variant.approved,
        Memory.release, logEvent, pushPending, popPending, hf, hl, hc, hz, ht]
    all_goals exact ⟨_, by simp [List.append_assoc]⟩
  · intro d hd
    rw [hm]
    exact reserved_filter_live s.mem a (reserved_other_live s.mem a c hu hf hl) d hd

/-- Structural induction over the actual release cascade supplies the frame
facts that local ownership and read-back lemmas do not assert. -/
theorem give_up_frame (fuel : Nat) (s : RunState) (a : Addr)
    (roots : List (Option Addr)) (cs : List Cell)
    (hp : ListPath s.mem (some a) cs) (hn : cs.length ≤ fuel)
    (hh : HeapSafe s.mem (some a :: roots)) :
    ReleaseFrame s (giveUp Variant.approved fuel a s).2 := by
  induction fuel generalizing s a cs roots with
  | zero => cases hp with | cons c cs hf hl ht => simp at hn
  | succ fuel ih =>
    cases hp with
    | cons c cs hf hl ht =>
      by_cases hone : c.count = 1
      · let t0 := (giveUp Variant.approved 1 c.addr s).2
        obtain ⟨hm, _, _, _, _, hstep⟩ := give_up_exclusive s c.addr c hf hl hone
        have hframe := give_up_exclusive_frame s c.addr c hh.unique hf hl hone
        have hrel : s.mem.release c.addr = .ok t0.mem := by
          rw [hm]
          simp [Memory.release, hf]
        obtain ⟨hh0, _, htail⟩ := hh.release_one hf hl hone hrel cs ht
        have hlen : cs.length ≤ fuel := by simpa using hn
        rw [hstep fuel]
        cases hlink : c.link with
        | none => exact hframe
        | some b =>
          have hh0' : HeapSafe t0.mem (some b :: roots) := by simpa [hlink] using hh0
          have ht0 : ListPath t0.mem (some b) cs := by simpa [hlink] using htail
          exact hframe.trans (ih t0 b roots cs ht0 hlen hh0')
      · have hc := hh.counts c (List.mem_of_find?_eq_some hf) hl
        rw [holders_cons_self] at hc
        exact give_up_shared_frame s c.addr c fuel hh.unique hf hl (by omega)

theorem give_up_link_frame (s : RunState) (r : Option Addr) (roots : List (Option Addr))
    (hh : Healthy s.mem (r :: roots)) :
    ReleaseFrame s (giveUpLink Variant.approved r s).2 := by
  cases r with
  | none => exact .refl s
  | some a =>
    obtain ⟨cs, hp⟩ := hh.readable (some a) (by simp)
    simpa [giveUpLink] using give_up_frame s.mem.cells.length s a roots cs hp hp.length_le hh.toHeapSafe

end Trial.Proofs
