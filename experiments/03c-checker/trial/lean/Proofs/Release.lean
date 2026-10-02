import Proofs.Heap

namespace Trial.Proofs

@[simp] theorem m_pure_apply (x : α) (s : RunState) :
    (pure x : M α) s = (.ok x, s) := rfl

@[simp] theorem m_throw_apply (why : String) (s : RunState) :
    (throw why : M α) s = (.error why, s) := rfl

@[simp] theorem m_bind_apply (act : M α) (f : α → M β) (s : RunState) :
    (act >>= f) s = match act s with
      | (.ok x, s') => f x s'
      | (.error why, s') => (.error why, s') := by
  cases h : act s with
  | mk r s' =>
    cases r <;> simp [bind, ExceptT.bind, ExceptT.bindCont, ExceptT.mk, StateT.bind, h,
      pure, StateT.pure]

@[simp] theorem m_map_apply (f : α → β) (act : M α) (s : RunState) :
    (f <$> act) s = match act s with
      | (.ok x, s') => (.ok (f x), s')
      | (.error why, s') => (.error why, s') := by
  cases h : act s with
  | mk r s' =>
    cases r <;> simp [Functor.map, ExceptT.map, ExceptT.mk, bind, StateT.bind,
      pure, StateT.pure, h]

@[simp] theorem m_get_apply (s : RunState) : (get : M RunState) s = (.ok s, s) := rfl

@[simp] theorem m_set_apply (s' s : RunState) : (set s' : M Unit) s = (.ok (), s') := rfl

@[simp] theorem m_modify_apply (f : RunState → RunState) (s : RunState) :
    (modify f : M Unit) s = (.ok (), f s) := rfl

/-- Giving up one of several holders succeeds and changes only the cell's count. -/
theorem give_up_shared (s : RunState) (a : Addr) (c : Cell) (fuel : Nat)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hc : 2 ≤ c.count) :
    (giveUp Variant.approved (fuel + 1) a s).1 = .ok () ∧
    (giveUp Variant.approved (fuel + 1) a s).2.mem =
      s.mem.updateCell a (fun d => { d with count := c.count - 1 }) ∧
    (giveUp Variant.approved (fuel + 1) a s).2.pending = s.pending ∧
    (giveUp Variant.approved (fuel + 1) a s).2.bindings = s.bindings ∧
    (giveUp Variant.approved (fuel + 1) a s).2.outside = s.outside := by
  have hn : c.count ≠ 0 := by omega
  have hn' : c.count - 1 ≠ 0 := by omega
  simp [giveUp, getCell, memOp, Memory.setCount, snapshot, Variant.approved,
    hf, hl, hn, hn']

/-- With one holder, the first release step removes this cell and then visits its tail.
The state after that first step is obtained from the existing evaluator with one
unit of fuel; no alternative evaluator is introduced. -/
theorem give_up_exclusive (s : RunState) (a : Addr) (c : Cell)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hc : c.count = 1) :
    let t := (giveUp Variant.approved 1 a s).2
    t.mem = { s.mem with
      cells := s.mem.cells.filter (fun d => d.addr != a)
      record := s.mem.record ++ [.released a] } ∧
    t.pending = s.pending ∧ t.bindings = s.bindings ∧ t.outside = s.outside ∧
    t.setAside = s.setAside ∧
    ∀ fuel, giveUp Variant.approved (fuel + 1) a s =
      match c.link with
      | none => (.ok (), t)
      | some b => giveUp Variant.approved fuel b t := by
  have hca : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
  have hz : (s.mem.updateCell a (fun d => { d with count := 0 })).find? a =
      some { c with count := 0 } := by
    rw [find_update s.mem a a _ (by intro d _; rfl)]
    simp [hf, hca]
  cases ht : c.link <;>
    simp [giveUp, getCell, memOp, Memory.setCount, snapshot, Variant.approved,
      Memory.release, logEvent, pushPending, popPending, hf, hl, hc, hz, ht]
  all_goals
    simp [Memory.updateCell]
    simpa only [beq_iff_eq] using filter_count_update s.mem.cells a 0

/-- The approved freeing cascade succeeds with enough fuel for its finite path.
It consumes one root, keeps the other roots' values and exact counts, and leaves
the caller's pending values, bindings and outside holders unchanged. -/
theorem give_up_safe (fuel : Nat) (s : RunState) (a : Addr)
    (roots : List (Option Addr)) (cs : List Cell)
    (hp : ListPath s.mem (some a) cs) (hn : cs.length ≤ fuel)
    (hh : HeapSafe s.mem (some a :: roots)) :
    ∃ t, giveUp Variant.approved fuel a s = (.ok (), t) ∧
      HeapSafe t.mem roots ∧
      (∀ r ∈ roots, readBack t.mem (.list r) = readBack s.mem (.list r)) ∧
      t.pending = s.pending ∧ t.bindings = s.bindings ∧ t.outside = s.outside := by
  induction fuel generalizing s a roots cs with
  | zero =>
    cases hp with
    | cons c cs hf hl ht => simp at hn
  | succ fuel ih =>
    cases hp with
    | cons c cs hf hl ht =>
      have hc := hh.counts c (List.mem_of_find?_eq_some hf) hl
      rw [holders_cons_self] at hc
      by_cases hone : c.count = 1
      · let t0 := (giveUp Variant.approved 1 c.addr s).2
        obtain ⟨hm, hpend, hbind, hout, _, hstep⟩ := give_up_exclusive s c.addr c hf hl hone
        have hrel : s.mem.release c.addr = .ok t0.mem := by
          rw [hm]
          simp [Memory.release, hf]
        obtain ⟨hh0, hread, htail⟩ := hh.release_one hf hl hone hrel cs ht
        have hlen : cs.length ≤ fuel := by simpa using hn
        cases hlink : c.link with
        | none =>
          have hh0' : HeapSafe t0.mem (none :: roots) := by simpa [hlink] using hh0
          refine ⟨t0, ?_, hh0'.drop_none, hread, hpend, hbind, hout⟩
          simpa [hlink] using hstep fuel
        | some b =>
          have hh0' : HeapSafe t0.mem (some b :: roots) := by simpa [hlink] using hh0
          have ht0 : ListPath t0.mem (some b) cs := by simpa [hlink] using htail
          obtain ⟨t, he, hheap, hv, htp, htb, hto⟩ := ih t0 b roots cs ht0 hlen hh0'
          refine ⟨t, ?_, hheap, ?_, htp.trans hpend, htb.trans hbind, hto.trans hout⟩
          · calc
              _ = giveUp Variant.approved fuel b t0 := by simpa [hlink] using hstep fuel
              _ = (.ok (), t) := he
          · intro r hr
            exact (hv r hr).trans (hread r hr)
      · have htwo : 2 ≤ c.count := by omega
        obtain ⟨hok, hm, hpend, hbind, hout⟩ := give_up_shared s c.addr c fuel hf hl htwo
        let t := (giveUp Variant.approved (fuel + 1) c.addr s).2
        have hu : s.mem.setCount c.addr (c.count - 1) = .ok t.mem := by
          rw [hm]
          simp [Memory.setCount, hf]
        refine ⟨t, ?_, hh.remove_count hf hl hu, ?_, hpend, hbind, hout⟩
        · apply Prod.ext
          · exact hok
          · rfl
        · intro r _
          exact set_count_read_back s.mem t.mem c.addr _ hu (.list r)

end Trial.Proofs
