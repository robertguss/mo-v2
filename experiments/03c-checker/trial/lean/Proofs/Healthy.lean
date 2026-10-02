import Proofs.Initial

namespace Trial.Proofs

/-- The heap invariant between complete ownership operations. Reserved cells
are allowed; live cells have finite paths and positive exact counts. -/
structure Healthy (m : Memory) (roots : List (Option Addr)) : Prop extends HeapSafe m roots where
  closed : LivePaths m
  positive : ∀ c ∈ m.cells, c.status = .live → 0 < c.count
  fresh : FreshBound m

theorem valid_start_healthy (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    Healthy s.toMemory (startRoots s) :=
  ⟨valid_start_heap e s h, valid_start_live_paths e s h,
    fun c hc _ => valid_start_positive e s h c hc, initial_bound s⟩

theorem Healthy.no_leak {m : Memory} {roots : List (Option Addr)} (h : Healthy m roots)
    (hl : ∀ c ∈ m.cells, c.status = .live) : NoLeakAt m roots :=
  no_leak_of_heap m roots h.toHeapSafe h.closed hl (fun c hc => h.positive c hc (hl c hc))

theorem FreshBound.update {m : Memory} (h : FreshBound m) (a : Addr) (f : Cell → Cell)
    (ha : ∀ c, c.addr = a → (f c).addr = c.addr) : FreshBound (m.updateCell a f) := by
  intro d hd
  obtain ⟨c, hc, he⟩ := List.mem_map.mp hd
  subst d
  change (if c.addr == a then f c else c).addr < m.next
  split
  · rename_i he
    rw [ha c (by simpa using he)]
    exact h c hc
  · exact h c hc

theorem Healthy.create {m : Memory} {roots : List (Option Addr)} {link : Option Addr}
    (h : Healthy m (link :: roots)) (item : Int) :
    Healthy (m.create item link).2 (some m.next :: roots) := by
  obtain ⟨cs, hp⟩ := h.readable link (by simp)
  refine ⟨h.toHeapSafe.create item h.fresh.missing
    (no_holders_missing m _ h.toHeapSafe h.closed m.next h.fresh.missing),
    h.closed.create item link cs hp h.fresh.missing, ?_, ?_⟩
  · intro c hc hl
    rcases List.mem_append.mp hc with hm | he
    · exact h.positive c hm hl
    · simp only [List.mem_cons, List.not_mem_nil, or_false] at he
      subst c
      exact Nat.zero_lt_succ 0
  · intro c hc
    change c.addr < m.next + 1
    rcases List.mem_append.mp hc with hm | he
    · exact Nat.lt_trans (h.fresh c hm) (Nat.lt_succ_self _)
    · simp only [List.mem_cons, List.not_mem_nil, or_false] at he
      subst c
      exact Nat.lt_succ_self _

theorem Healthy.write {m m' : Memory} {roots : List (Option Addr)} {link : Option Addr}
    (h : Healthy m (link :: roots)) (a : Addr) (item : Int)
    (hw : m.writeInPlace a item link = .ok m') : Healthy m' (some a :: roots) := by
  have hclosed : LivePaths m' := by
    obtain ⟨cs, ht⟩ := h.readable link (by simp)
    exact h.closed.write a item link cs ht hw
  have hsafe : HeapSafe m' (some a :: roots) := by
    apply h.toHeapSafe.write a item hw
    unfold Memory.writeInPlace at hw
    cases hf : m.find? a with
    | none => simp [hf] at hw
    | some c =>
      simp only [hf] at hw
      split at hw
      · rename_i hs
        exact no_holders_reserved m _ h.toHeapSafe h.closed a c hf hs
      · simp at hw
  unfold Memory.writeInPlace at hw
  split at hw
  · simp at hw
  · split at hw
    · simp only [except_pure, Except.ok.injEq] at hw
      subst m'
      refine ⟨hsafe, hclosed, ?_, h.fresh.update a _ (by intro c hc; exact hc.symm)⟩
      intro d hd hl
      obtain ⟨c, hc, he⟩ := List.mem_map.mp hd
      subst d
      split
      · exact Nat.zero_lt_succ 0
      · rename_i hn
        simp only [hn] at hl
        exact h.positive c hc hl
    · simp at hw

theorem Healthy.reserve {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (h : Healthy m (some a :: roots)) (hf : m.find? a = some c)
    (hl : c.status = .live) (hc : c.count = 1) (hm : m.markSetAside a = .ok m') :
    Healthy m' (c.link :: roots) := by
  obtain ⟨cs, hp⟩ := h.closed c (List.mem_of_find?_eq_some hf) hl
  obtain ⟨d, ds, _, hd, _, _, ht⟩ := hp.head
  have hca : c.addr = a := by simpa using (List.find?_some hf)
  rw [hca, hf] at hd
  have he := Option.some.inj hd
  subst d
  refine ⟨(h.toHeapSafe.reserve hf hl hc hm ds ht).1,
    h.closed.reserve h.toHeapSafe hf hl hc hm, ?_, ?_⟩
  all_goals
    simp only [Memory.markSetAside, hf, except_pure, Except.ok.injEq] at hm
    subst m'
  · intro d hd hld
    obtain ⟨x, hx, he⟩ := List.mem_map.mp hd
    subst d
    split at hld
    · cases hld
    · rename_i hn
      simp only [hn]
      exact h.positive x hx hld
  · exact h.fresh.update a _ (by intro d _; rfl)

/-- A positive count update preserves positivity and the allocation bound. -/
theorem positive_count_update (m m' : Memory) (a : Addr) (n : Nat)
    (hpos : ∀ c ∈ m.cells, c.status = .live → 0 < c.count) (hn : 0 < n)
    (hb : FreshBound m) (hu : m.setCount a n = .ok m') :
    (∀ c ∈ m'.cells, c.status = .live → 0 < c.count) ∧ FreshBound m' := by
  unfold Memory.setCount at hu
  split at hu
  · simp at hu
  · simp only [except_pure, Except.ok.injEq] at hu
    subst m'
    refine ⟨?_, hb.update a _ (by intro c _; rfl)⟩
    intro d hd hl
    obtain ⟨c, hc, he⟩ := List.mem_map.mp hd
    subst d
    split
    · exact hn
    · rename_i hne
      simp only [hne] at hl
      exact hpos c hc hl

theorem Healthy.remove_shared {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (h : Healthy m (some a :: roots)) (hf : m.find? a = some c)
    (hl : c.status = .live) (hc : 2 ≤ c.count)
    (hu : m.setCount a (c.count - 1) = .ok m') : Healthy m' roots := by
  obtain ⟨hp, hb⟩ := positive_count_update m m' a _ h.positive (by omega) h.fresh hu
  exact ⟨h.toHeapSafe.remove_count hf hl hu, h.closed.set_count a _ hu, hp, hb⟩

theorem Healthy.add_count {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (h : Healthy m roots) (hf : m.find? a = some c) (hl : c.status = .live)
    (hu : m.setCount a (c.count + 1) = .ok m') : Healthy m' (some a :: roots) := by
  obtain ⟨hpos, hb⟩ := positive_count_update m m' a _ h.positive (by omega) h.fresh hu
  refine ⟨⟨set_count_unique m m' a _ hu h.unique, ?_,
    counts_add_root m m' roots a c h.counts hf hl hu⟩, h.closed.set_count a _ hu, hpos, hb⟩
  intro r hr
  have hp : ∃ cs, ListPath m r cs := by
    rcases List.mem_cons.mp hr with he | hm
    · subst r
      have hca : c.addr = a := by simpa using (List.find?_some hf)
      simpa [hca] using h.closed c (List.mem_of_find?_eq_some hf) hl
    · exact h.readable r hm
  obtain ⟨cs, ht⟩ := hp
  obtain ⟨ds, ht', _, _⟩ := set_count_path m m' a _ hu r cs ht
  exact ⟨ds, ht'⟩

theorem Healthy.drop_none {m : Memory} {roots : List (Option Addr)}
    (h : Healthy m (none :: roots)) : Healthy m roots :=
  ⟨h.toHeapSafe.drop_none, h.closed, h.positive, h.fresh⟩

theorem Healthy.add_none {m : Memory} {roots : List (Option Addr)}
    (h : Healthy m roots) : Healthy m (none :: roots) := by
  refine ⟨⟨h.unique, ?_, ?_⟩, h.closed, h.positive, h.fresh⟩
  · intro r hr
    rcases List.mem_cons.mp hr with he | hm
    · exact ⟨[], he ▸ ListPath.nil⟩
    · exact h.readable r hm
  · intro c hc hl
    simpa [holders_cons] using h.counts c hc hl

theorem Healthy.perm {m : Memory} {roots roots' : List (Option Addr)}
    (h : Healthy m roots) (hp : roots.Perm roots') : Healthy m roots' := by
  refine ⟨⟨h.unique, fun r hr => h.readable r (hp.mem_iff.mpr hr), ?_⟩,
    h.closed, h.positive, h.fresh⟩
  intro c hc hl
  have he : holders m roots c.addr = holders m roots' c.addr := by
    unfold holders
    rw [(hp.filter (fun r => r == some c.addr)).length_eq]
  rw [← he]
  exact h.counts c hc hl

/-- Removing an exclusive live cell preserves the stronger heap invariant after
its link is transferred to a root. -/
theorem Healthy.release_one {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (h : Healthy m (some a :: roots)) (hf : m.find? a = some c)
    (hl : c.status = .live) (hc : c.count = 1) (hr : m.release a = .ok m') :
    Healthy m' (c.link :: roots) := by
  have hca : c.addr = a := by simpa using (List.find?_some hf)
  have hown : holders m (some a :: roots) a = 1 := by
    have ht := h.counts c (List.mem_of_find?_eq_some hf) hl
    simpa [hca, hc] using ht.symm
  obtain ⟨_, hlinks⟩ := sole_holder m roots a hown
  obtain ⟨cs, hp⟩ := h.closed c (List.mem_of_find?_eq_some hf) hl
  obtain ⟨d, ds, _, hd, _, _, ht⟩ := hp.head
  rw [hca, hf] at hd
  have he := Option.some.inj hd
  subst d
  have hs := (h.toHeapSafe.release_one hf hl hc hr ds ht).1
  simp only [Memory.release, hf, except_pure, Except.ok.injEq] at hr
  subst m'
  refine ⟨hs, ?_, ?_, ?_⟩
  · intro d hd hld
    obtain ⟨hd, hn⟩ := List.mem_filter.mp hd
    have hne : d.addr ≠ a := by simpa using hn
    obtain ⟨es, hep⟩ := h.closed d hd hld
    have hep' := hep.release a (hep.avoids a (by simpa using hne) hlinks)
    refine ⟨es, hep'.preserve ?_⟩
    intro x hx
    exact (hep'.lookup x hx).1
  · intro d hd hld
    exact h.positive d (List.mem_filter.mp hd).1 hld
  · intro d hd
    exact h.fresh d (List.mem_filter.mp hd).1

/-- A released reserved cell removes no live link-holder. -/
theorem release_reserved_holders (m m' : Memory) (roots : List (Option Addr))
    (a : Addr) (c : Cell) (hu : (m.cells.map Cell.addr).Nodup)
    (hf : m.find? a = some c) (hs : c.status = .setAside)
    (hr : m.release a = .ok m') (b : Addr) : holders m' roots b = holders m roots b := by
  have hca : c.addr = a := by simpa using (List.find?_some hf)
  obtain ⟨before, after, he, hd⟩ := filter_remove_one m.cells hu c (List.mem_of_find?_eq_some hf)
  simp only [Memory.release, hf, except_pure, Except.ok.injEq] at hr
  subst m'
  simp only [holders]
  rw [← hca, hd, he]
  simp [List.filter_append, hs]

/-- Disposing a reserved cell preserves every live path and all live counts. -/
theorem Healthy.release_reserved {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (h : Healthy m roots) (hf : m.find? a = some c) (hs : c.status = .setAside)
    (hr : m.release a = .ok m') : Healthy m' roots ∧
      (∀ r ∈ roots, readBack m' (.list r) = readBack m (.list r)) := by
  have hholders := release_reserved_holders m m' roots a c h.unique hf hs hr
  simp only [Memory.release, hf, except_pure, Except.ok.injEq] at hr
  subst m'
  have hkeep : ∀ r cs, ListPath m r cs → ListPath
      { m with cells := m.cells.filter (fun d => d.addr != a), record := m.record ++ [.released a] } r cs := by
    intro r cs hp
    have hp' := hp.release a (hp.avoids_set_aside a c hf hs)
    apply hp'.preserve
    intro d hd
    exact (hp'.lookup d hd).1
  refine ⟨⟨⟨?_, ?_, ?_⟩, ?_, ?_, ?_⟩, ?_⟩
  · exact List.Nodup.sublist (List.Sublist.map Cell.addr List.filter_sublist) h.unique
  · intro r hr
    obtain ⟨cs, hp⟩ := h.readable r hr
    exact ⟨cs, hkeep r cs hp⟩
  · intro d hd hl
    rw [hholders]
    exact h.counts d (List.mem_filter.mp hd).1 hl
  · intro d hd hl
    obtain ⟨cs, hp⟩ := h.closed d (List.mem_filter.mp hd).1 hl
    exact ⟨cs, hkeep _ cs hp⟩
  · intro d hd hl
    exact h.positive d (List.mem_filter.mp hd).1 hl
  · intro d hd
    exact h.fresh d (List.mem_filter.mp hd).1
  · intro r hr
    obtain ⟨cs, hp⟩ := h.readable r hr
    rw [hp.read_back, (hkeep r cs hp).read_back]

end Trial.Proofs
