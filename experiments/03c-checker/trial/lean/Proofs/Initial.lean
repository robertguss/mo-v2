import Proofs.Reachability

namespace Trial.Proofs

/-- The validator's successful chain walk and the promised address walk agree. -/
theorem walk_chain_ends (s : Start) (n : Nat) (r : Option Addr)
    (h : chainEnds s.cells n r = true) :
    walkAddrs s.toMemory n r = .ok (chainAddrs s.cells n r) := by
  induction n generalizing r with
  | zero =>
    cases r with
    | none => rfl
    | some a => simp [chainEnds] at h
  | succ n ih =>
    cases r with
    | none => rfl
    | some a =>
      cases hf : s.cells.find? (fun c => c.addr == a) with
      | none => simp [chainEnds, hf] at h
      | some c =>
        have ht : chainEnds s.cells n c.link = true := by simpa [chainEnds, hf] using h
        have hf' : s.toMemory.find? a = some
            { addr := c.addr, item := c.item, link := c.link, count := c.count, status := .live } := by
          simp [Start.toMemory, Memory.find?, List.find?_map, Function.comp_def, hf]
        simp [walkAddrs, hf', hf, chainAddrs, ih c.link ht]

/-- Valid roots pass the same finite-chain test as each allocated cell. -/
theorem valid_start_root_ends (e : Expr) (s : Start) (h : validStart e s = .ok ())
    (r : Option Addr) (hr : r ∈ startRoots s) : chainEnds s.cells s.cells.length r = true := by
  cases r with
  | none => simp [chainEnds]
  | some a =>
    obtain ⟨c, hc, he⟩ := valid_start_roots e s h (some a) hr a rfl
    simpa [he] using valid_start_chain_ends e s h c hc

/-- Validation's reachability loop covers every allocated starting cell. -/
theorem valid_start_reached (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∀ c ∈ s.cells, ∃ r ∈ startRoots s, c.addr ∈ chainAddrs s.cells s.cells.length r := by
  obtain ⟨k, hw⟩ := valid_start_well_formed e s h
  simp only [validStart, hw, except_bind_ok] at h
  cases hd : dupAddr s.cells with
  | some a => simp [hd] at h
  | none =>
    simp only [hd, except_bind_eq_ok] at h
    obtain ⟨⟨⟩, _, ⟨⟩, _, ⟨⟩, _, ⟨⟩, hr, _⟩ := h
    have hh := (checked_loop _ _ _).mp hr
    intro c hc
    have hm := hh c hc
    rw [← List.flatMap_eq_foldl] at hm
    obtain ⟨r, hr, hcr⟩ := List.mem_flatMap.mp (List.contains_iff_mem.mp hm)
    refine ⟨r, ?_, hcr⟩
    rcases List.mem_append.mp hr with hi | ho
    · obtain ⟨p, hp, he⟩ := List.mem_filterMap.mp hi
      apply List.mem_append_left
      refine List.mem_filterMap.mpr ⟨p, hp, ?_⟩
      cases hv : p.2 <;> simp [hv] at he ⊢
      exact he
    · exact List.mem_append_right _ ho

theorem valid_start_root_reaches (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∀ c ∈ s.toMemory.cells, RootReaches s.toMemory (startRoots s) c.addr := by
  intro d hd
  obtain ⟨c, hc, he⟩ := List.mem_map.mp hd
  subst d
  obtain ⟨r, hr, hm⟩ := valid_start_reached e s h c hc
  obtain ⟨cs, hp⟩ := valid_start_paths e s h r hr
  have hwalk := walk_chain_ends s s.cells.length r (valid_start_root_ends e s h r hr)
  have hsize : s.toMemory.cells.length = s.cells.length := by simp [Start.toMemory]
  have hw := hp.walk s.cells.length (by simpa [hsize] using hp.length_le)
  have he := Except.ok.inj (hw.symm.trans hwalk)
  exact ⟨r, hr, cs, hp, by simpa [he] using hm⟩

/-- Every reachable address has at least one actual holder, whether a root or
the preceding cell's live link. -/
theorem reached_has_holder (m : Memory) (roots : List (Option Addr)) (a : Addr)
    (h : RootReaches m roots a) : 0 < holders m roots a := by
  by_cases hz : holders m roots a = 0
  · obtain ⟨hn, hl⟩ := (holders_zero m roots a).mp hz
    obtain ⟨r, hr, cs, hp, hm⟩ := h
    exact False.elim ((hp.avoids a (fun he => hn (he ▸ hr)) hl) hm)
  · omega

/-- Every valid starting cell has a positive count. -/
theorem valid_start_positive (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∀ c ∈ s.toMemory.cells, 0 < c.count := by
  intro c hc
  rw [valid_start_counts e s h c hc]
  exact reached_has_holder _ _ _ (valid_start_root_reaches e s h c hc)

/-- The exact locked no-leak predicate holds before the evaluator begins. -/
theorem valid_start_no_leak (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    NoLeakAt s.toMemory (startRoots s) := by
  apply no_leak_of_heap _ _ (valid_start_heap e s h) (valid_start_live_paths e s h)
  · intro d hd
    obtain ⟨c, _, he⟩ := List.mem_map.mp hd
    subst d
    rfl
  · exact valid_start_positive e s h

/-- The monotonically increasing allocator stays above all allocated addresses. -/
def FreshBound (m : Memory) : Prop := ∀ c ∈ m.cells, c.addr < m.next

theorem initial_bound (s : Start) : FreshBound s.toMemory := by
  have bound : ∀ (cs : List StartCell) (n : Nat),
      n ≤ cs.foldl (fun acc c => max acc (c.addr + 1)) n ∧
      ∀ c ∈ cs, c.addr < cs.foldl (fun acc c => max acc (c.addr + 1)) n := by
    intro cs
    induction cs with
    | nil => intro n; simp
    | cons c cs ih =>
      intro n
      obtain ⟨hn, hc⟩ := ih (max n (c.addr + 1))
      refine ⟨Nat.le_trans (Nat.le_max_left _ _) hn, ?_⟩
      intro d hd
      rcases List.mem_cons.mp hd with he | hm
      · subst d
        have := Nat.le_max_right n (c.addr + 1)
        exact Nat.lt_of_lt_of_le (by omega) hn
      · exact hc d hm
  intro d hd
  obtain ⟨c, hc, he⟩ := List.mem_map.mp hd
  subst d
  exact (bound s.cells 0).2 c hc

theorem FreshBound.missing {m : Memory} (hb : FreshBound m) : m.find? m.next = none := by
  apply List.find?_eq_none.mpr
  intro c hc
  have hne : c.addr ≠ m.next := Nat.ne_of_lt (hb c hc)
  simpa using hne

end Trial.Proofs
