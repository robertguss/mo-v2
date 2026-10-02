import Proofs.Healthy

namespace Trial.Proofs

/-- The actual approved cascade preserves the stronger heap invariant. -/
theorem give_up_healthy (fuel : Nat) (s : RunState) (a : Addr)
    (roots : List (Option Addr)) (cs : List Cell)
    (hp : ListPath s.mem (some a) cs) (hn : cs.length ≤ fuel)
    (hh : Healthy s.mem (some a :: roots)) :
    Healthy (giveUp Variant.approved fuel a s).2.mem roots := by
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
        have hh0 := hh.release_one hf hl hone hrel
        have htail := (hh.toHeapSafe.release_one hf hl hone hrel cs ht).2.2
        have hlen : cs.length ≤ fuel := by simpa using hn
        rw [hstep fuel]
        cases hlink : c.link with
        | none =>
          have h : Healthy t0.mem (none :: roots) := by simpa [hlink] using hh0
          exact h.drop_none
        | some b =>
          have h : Healthy t0.mem (some b :: roots) := by simpa [hlink] using hh0
          have ht0 : ListPath t0.mem (some b) cs := by simpa [hlink] using htail
          exact ih t0 b roots cs ht0 hlen h
      · have hpositive := hh.positive c (List.mem_of_find?_eq_some hf) hl
        have htwo : 2 ≤ c.count := by omega
        obtain ⟨_, hm, _⟩ := give_up_shared s c.addr c fuel hf hl htwo
        have hu : s.mem.setCount c.addr (c.count - 1) =
            .ok (giveUp Variant.approved (fuel + 1) c.addr s).2.mem := by
          rw [hm]
          simp [Memory.setCount, hf]
        exact hh.remove_shared hf hl htwo hu

/-- The public list-release operation always succeeds on an owned readable root,
preserves the other values, and keeps the stronger heap invariant. -/
theorem give_up_link_safe (s : RunState) (r : Option Addr) (roots : List (Option Addr))
    (hh : Healthy s.mem (r :: roots)) :
    ∃ t, giveUpLink Variant.approved r s = (.ok (), t) ∧ Healthy t.mem roots ∧
      (∀ q ∈ roots, readBack t.mem (.list q) = readBack s.mem (.list q)) ∧
      t.pending = s.pending ∧ t.bindings = s.bindings ∧ t.outside = s.outside := by
  cases r with
  | none => exact ⟨s, rfl, hh.drop_none, fun _ _ => rfl, rfl, rfl, rfl⟩
  | some a =>
    obtain ⟨cs, hp⟩ := hh.readable (some a) (by simp)
    obtain ⟨t, he, _, hr, hpend, hbind, hout⟩ :=
      give_up_safe s.mem.cells.length s a roots cs hp hp.length_le hh.toHeapSafe
    have hhealthy := give_up_healthy s.mem.cells.length s a roots cs hp hp.length_le hh
    rw [he] at hhealthy
    exact ⟨t, by simpa [giveUpLink] using he, hhealthy, hr, hpend, hbind, hout⟩

/-- Adding a holder changes only the count and preserves every read-back. -/
theorem add_holder_safe (s : RunState) (a : Addr) (roots : List (Option Addr))
    (hh : Healthy s.mem roots) (cs : List Cell) (hp : ListPath s.mem (some a) cs) :
    ∃ t, addHolder a s = (.ok (), t) ∧ Healthy t.mem (some a :: roots) ∧
      (∀ v, readBack t.mem v = readBack s.mem v) ∧
      t.pending = s.pending ∧ t.bindings = s.bindings ∧ t.outside = s.outside := by
  obtain ⟨c, ds, _, hf, _, hl, _⟩ := hp.head
  let m' := s.mem.updateCell a (fun d => { d with count := c.count + 1 })
  have hu : s.mem.setCount a (c.count + 1) = .ok m' := by simp [Memory.setCount, hf, m']
  refine ⟨{ s with mem := m' }, ?_, hh.add_count hf hl hu, ?_, rfl, rfl, rfl⟩
  · simp [addHolder, getLiveCell, getCell, memOp, hf, hl, hu]
  · exact set_count_read_back s.mem m' a _ hu

end Trial.Proofs
