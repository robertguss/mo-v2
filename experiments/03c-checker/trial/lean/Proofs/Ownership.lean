import Proofs.Memory

namespace Trial.Proofs

/-- Zero holders means neither an external root nor a live cell links here. -/
theorem holders_zero (m : Memory) (roots : List (Option Addr)) (a : Addr) :
    holders m roots a = 0 ↔
      some a ∉ roots ∧ ∀ c ∈ m.cells, c.status = .live → c.link ≠ some a := by
  simp [holders, List.filter_eq_nil_iff]
  intro _
  constructor
  · intro h hm
    exact h _ hm rfl
  · intro h r hr he
    exact h (he ▸ hr)

/-- Adding one root adds exactly one holder at its address. -/
theorem holders_cons_self (m : Memory) (roots : List (Option Addr)) (a : Addr) :
    holders m (some a :: roots) a = holders m roots a + 1 := by
  simp [holders, Nat.add_comm, Nat.add_left_comm]

/-- A count of one, including this owned root, excludes all other holders. -/
theorem sole_holder (m : Memory) (roots : List (Option Addr)) (a : Addr)
    (h : holders m (some a :: roots) a = 1) :
    some a ∉ roots ∧ ∀ c ∈ m.cells, c.status = .live → c.link ≠ some a := by
  apply (holders_zero m roots a).mp
  rw [holders_cons_self] at h
  omega

/-- Without a root or an incoming live link, an address cannot occur on this path. -/
theorem ListPath.avoids {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (a : Addr) (hr : r ≠ some a)
    (hl : ∀ c ∈ m.cells, c.status = .live → c.link ≠ some a) :
    a ∉ cs.map Cell.addr := by
  induction hp with
  | nil => simp
  | cons c cs found live tail ih =>
    have hm : c ∈ m.cells := List.mem_of_find?_eq_some found
    have hca : a ≠ c.addr := by
      intro he
      exact hr (by rw [he])
    simpa [hca] using ih (hl c hm live)

/-- An exclusively owned root is absent from every other root's finite path. -/
theorem sole_holder_avoids (m : Memory) (roots : List (Option Addr)) (a : Addr)
    (h : holders m (some a :: roots) a = 1)
    (r : Option Addr) (hr : r ∈ roots) (cs : List Cell) (hp : ListPath m r cs) :
    a ∉ cs.map Cell.addr := by
  obtain ⟨hn, hl⟩ := sole_holder m roots a h
  exact hp.avoids a (fun he => hn (he ▸ hr)) hl

/-- Deleting an exclusively owned root preserves every other root's list. -/
theorem sole_holder_release (m : Memory) (roots : List (Option Addr)) (a : Addr)
    (h : holders m (some a :: roots) a = 1)
    (r : Option Addr) (hr : r ∈ roots) (cs : List Cell) (hp : ListPath m r cs) :
    readBack { m with cells := m.cells.filter (fun c => c.addr != a) } (.list r) =
      readBack m (.list r) := by
  have hp' := hp.release a (sole_holder_avoids m roots a h r hr cs hp)
  rw [hp.read_back, hp'.read_back]

/-- Adding a root changes the holder count only at the address it names. -/
theorem holders_cons (m : Memory) (roots : List (Option Addr)) (r : Option Addr) (a : Addr) :
    holders m (r :: roots) a = holders m roots a + if r == some a then 1 else 0 := by
  unfold holders
  cases hr : r == some a <;> simp [hr, Nat.add_comm, Nat.add_left_comm]

/-- Stored holder counts are not themselves holders. -/
theorem holders_counts (m : Memory) (counts : Cell → Nat) (roots : List (Option Addr)) (a : Addr) :
    holders { m with cells := m.cells.map (fun c => { c with count := counts c }) } roots a =
      holders m roots a := by
  simp [holders, List.filter_map, Function.comp_def]

/-- Detaching a live cell turns its link into a root without changing other holders. -/
theorem holders_detach (before after : List Cell) (c : Cell) (hc : c.status = .live)
    (roots : List (Option Addr)) (a : Addr) :
    holders { cells := before ++ after } (c.link :: roots) a =
      holders { cells := before ++ c :: after } roots a := by
  unfold holders
  cases hl : c.link == some a <;>
    simp [List.filter_append, hl, hc, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]

/-- With distinct addresses, filtering one allocated address removes just that cell. -/
theorem filter_remove_one (cells : List Cell) (hu : (cells.map Cell.addr).Nodup)
    (c : Cell) (hc : c ∈ cells) :
    ∃ before after, cells = before ++ c :: after ∧
      cells.filter (fun d => d.addr != c.addr) = before ++ after := by
  obtain ⟨before, after, he⟩ := List.mem_iff_append.mp hc
  subst cells
  simp only [List.map_append, List.map_cons, List.nodup_append, List.nodup_cons] at hu
  have hb : before.filter (fun d => d.addr != c.addr) = before := by
    apply List.filter_eq_self.mpr
    intro d hd
    have hn := hu.2.2 d.addr (List.mem_map.mpr ⟨d, hd, rfl⟩) c.addr (by simp)
    simpa using hn
  have ht : after.filter (fun d => d.addr != c.addr) = after := by
    apply List.filter_eq_self.mpr
    intro d hd
    have hn : d.addr ≠ c.addr := by
      intro he
      exact hu.2.1.1 (List.mem_map.mpr ⟨d, hd, he⟩)
    simpa using hn
  exact ⟨before, after, rfl, by simp [List.filter_append, hb, ht]⟩

/-- A successful release transfers the removed live cell's link-holder to a root. -/
theorem release_holders (m m' : Memory) (a : Addr) (c : Cell)
    (hu : (m.cells.map Cell.addr).Nodup) (hf : m.find? a = some c)
    (hc : c.status = .live) (hr : m.release a = .ok m')
    (roots : List (Option Addr)) (b : Addr) :
    holders m' (c.link :: roots) b = holders m roots b := by
  have ha : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
  obtain ⟨before, after, he, hd⟩ := filter_remove_one m.cells hu c (List.mem_of_find?_eq_some hf)
  simp only [Memory.release, hf, except_pure, Except.ok.injEq] at hr
  subst m'
  have hh := holders_detach before after c hc roots b
  simp only [holders]
  rw [← ha, hd, he]
  exact hh

/-- Each live cell's stored count equals the roots and live links which hold it. -/
def CountsCorrect (m : Memory) (roots : List (Option Addr)) : Prop :=
  ∀ c ∈ m.cells, c.status = .live → c.count = holders m roots c.addr

theorem counts_correct_map (m : Memory) (roots : List (Option Addr)) (counts : Cell → Nat)
    (h : ∀ c ∈ m.cells, c.status = .live → counts c = holders m roots c.addr) :
    CountsCorrect { m with cells := m.cells.map (fun c => { c with count := counts c }) } roots := by
  intro d hd hl
  obtain ⟨c, hc, he⟩ := List.mem_map.mp hd
  subst d
  rw [holders_counts]
  exact h c hc hl

/-- Increasing the named cell's count accounts exactly for one added root. -/
theorem counts_add_root (m m' : Memory) (roots : List (Option Addr)) (a : Addr) (c : Cell)
    (h : CountsCorrect m roots) (hf : m.find? a = some c) (hl : c.status = .live)
    (hu : m.setCount a (c.count + 1) = .ok m') : CountsCorrect m' (some a :: roots) := by
  have hca : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
  have hc : c.count = holders m roots a := by
    simpa [hca] using h c (List.mem_of_find?_eq_some hf) hl
  simp only [Memory.setCount, hf, except_pure, Except.ok.injEq] at hu
  subst m'
  rw [update_count_eq_map]
  apply counts_correct_map
  intro d hd hld
  rw [holders_cons]
  by_cases he : d.addr = a
  · simp [he, hc]
  · simp [he, Ne.symm he, h d hd hld]

/-- Decreasing the named cell's count accounts exactly for one removed root. -/
theorem counts_remove_root (m m' : Memory) (roots : List (Option Addr)) (a : Addr) (c : Cell)
    (h : CountsCorrect m (some a :: roots)) (hf : m.find? a = some c) (hl : c.status = .live)
    (hu : m.setCount a (c.count - 1) = .ok m') : CountsCorrect m' roots := by
  have hca : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
  have hc : c.count = holders m roots a + 1 := by
    simpa [hca, holders_cons_self] using h c (List.mem_of_find?_eq_some hf) hl
  simp only [Memory.setCount, hf, except_pure, Except.ok.injEq] at hu
  subst m'
  rw [update_count_eq_map]
  apply counts_correct_map
  intro d hd hld
  by_cases he : d.addr = a
  · simp [he, hc]
  · have hh := h d hd hld
    rw [holders_cons] at hh
    simpa [he, Ne.symm he] using hh

end Trial.Proofs
