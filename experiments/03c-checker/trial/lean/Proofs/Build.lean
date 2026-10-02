import Proofs.Release

namespace Trial.Proofs

/-- Allocation transfers the tail's root to the new cell's link, and creates
exactly one new root at the fresh address. -/
theorem create_holders (m : Memory) (roots : List (Option Addr))
    (item : Int) (link : Option Addr) (a : Addr) :
    holders (m.create item link).2 (some m.next :: roots) a =
      holders m (link :: roots) a + if m.next == a then 1 else 0 := by
  simp only [Memory.create, holders, List.filter_append, List.length_append]
  cases hn : m.next == a <;> cases hl : link == some a <;>
    simp [hn, hl, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]

/-- A missing address is different from every allocated cell's address. -/
theorem missing_addr (m : Memory) (a : Addr) (hf : m.find? a = none) :
    ∀ c ∈ m.cells, c.addr ≠ a := by
  simpa [Memory.find?, List.find?_eq_none] using hf

/-- A new allocation preserves readable roots and correct counts when its
address has no previous holders. The latter is a separate no-dangling obligation. -/
theorem HeapSafe.create {m : Memory} {roots : List (Option Addr)}
    {link : Option Addr} (hh : HeapSafe m (link :: roots)) (item : Int)
    (hf : m.find? m.next = none) (hz : holders m (link :: roots) m.next = 0) :
    HeapSafe (m.create item link).2 (some m.next :: roots) := by
  let c : Cell := { addr := m.next, item := item, link := link, count := 1, status := .live }
  have hn := missing_addr m m.next hf
  have hfound : (m.create item link).2.find? c.addr = some c := by
    simp only [Memory.find?] at hf
    simp [Memory.create, Memory.find?, List.find?_append, c, hf]
  refine ⟨?_, ?_, ?_⟩
  · simp only [Memory.create, List.map_append, List.map_cons, List.map_nil,
      List.nodup_append]
    refine ⟨hh.unique, by simp, ?_⟩
    intro a ha b hb
    obtain ⟨d, hd, he⟩ := List.mem_map.mp ha
    have hb' : b = m.next := by simpa using hb
    subst a
    subst b
    exact hn d hd
  · intro r hr
    rcases List.mem_cons.mp hr with he | hm
    · subst r
      obtain ⟨cs, hp⟩ := hh.readable link (by simp)
      exact ⟨c :: cs, .cons c cs hfound rfl (hp.create item link)⟩
    · obtain ⟨cs, hp⟩ := hh.readable r (by simp [hm])
      exact ⟨cs, hp.create item link⟩
  · intro d hd hl
    change d ∈ m.cells ++ [c] at hd
    rw [create_holders]
    rcases List.mem_append.mp hd with hm | he
    · simp [Ne.symm (hn d hm), hh.counts d hm hl]
    · have he' : d = c := by simpa using he
      subst d
      simp [c, hz]

/-- Changing a cell at a unique address is exactly one list replacement. -/
theorem update_one (m : Memory) (a : Addr) (c : Cell)
    (hu : (m.cells.map Cell.addr).Nodup) (hf : m.find? a = some c)
    (f : Cell → Cell) :
    ∃ before after, m.cells = before ++ c :: after ∧
      (m.updateCell a f).cells = before ++ f c :: after ∧
      (∀ d ∈ before ++ after, d.addr ≠ a) := by
  have hca : c.addr = a := by simpa using (List.find?_some hf)
  obtain ⟨before, after, he, _⟩ := filter_remove_one m.cells hu c (List.mem_of_find?_eq_some hf)
  have hu' := hu
  rw [he] at hu'
  simp only [List.map_append, List.map_cons, List.nodup_append, List.nodup_cons] at hu'
  have hn : ∀ d ∈ before ++ after, d.addr ≠ a := by
    intro d hd hda
    rcases List.mem_append.mp hd with hb | ht
    · exact hu'.2.2 d.addr (List.mem_map.mpr ⟨d, hb, rfl⟩) c.addr (by simp) (hda.trans hca.symm)
    · exact hu'.2.1.1 (List.mem_map.mpr ⟨d, ht, hda.trans hca.symm⟩)
  have hb : before.map (fun d => if d.addr == a then f d else d) = before := by
    calc
      _ = before.map id := List.map_congr_left (fun d hd => by simp [hn d (List.mem_append_left _ hd)])
      _ = before := List.map_id before
  have ht : after.map (fun d => if d.addr == a then f d else d) = after := by
    calc
      _ = after.map id := List.map_congr_left (fun d hd => by simp [hn d (List.mem_append_right _ hd)])
      _ = after := List.map_id after
  simp only [beq_iff_eq] at hb ht
  exact ⟨before, after, he, by simp [Memory.updateCell, he, hb, ht, hca], hn⟩

/-- Reusing a reserved cell transfers the tail root into the written cell's link,
and introduces the new result's root. -/
theorem write_holders (m m' : Memory) (roots : List (Option Addr))
    (a : Addr) (item : Int) (link : Option Addr)
    (hu : (m.cells.map Cell.addr).Nodup)
    (hw : m.writeInPlace a item link = .ok m') (b : Addr) :
    holders m' (some a :: roots) b =
      holders m (link :: roots) b + if a == b then 1 else 0 := by
  unfold Memory.writeInPlace at hw
  cases hf : m.find? a with
  | none => simp [hf] at hw
  | some c =>
    simp only [hf] at hw
    split at hw
    · rename_i hs
      simp only [except_pure, Except.ok.injEq] at hw
      subst m'
      obtain ⟨before, after, he, hm, _⟩ := update_one m a c hu hf
        (fun _ => { addr := a, item := item, link := link, count := 1, status := .live })
      simp only [holders]
      rw [hm, he]
      cases hab : a == b <;> cases hl : link == some b <;>
        simp [List.filter_append, hs, hab, hl, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]
    · simp at hw

/-- Address-preserving updates preserve the list of allocated addresses. -/
theorem update_addresses (m : Memory) (a : Addr) (f : Cell → Cell)
    (hf : ∀ c, c.addr = a → (f c).addr = c.addr) :
    ((m.updateCell a f).cells.map Cell.addr) = m.cells.map Cell.addr := by
  simp only [Memory.updateCell, List.map_map]
  apply List.map_congr_left
  intro c _
  simp only [Function.comp_apply]
  split
  · rename_i hc
    exact hf c (by simpa using hc)
  · rfl

/-- Reuse preserves the local heap obligations, provided the reserved address
has no holders before reuse. -/
theorem HeapSafe.write {m m' : Memory} {roots : List (Option Addr)}
    {link : Option Addr} (hh : HeapSafe m (link :: roots))
    (a : Addr) (item : Int) (hw : m.writeInPlace a item link = .ok m')
    (hz : holders m (link :: roots) a = 0) :
    HeapSafe m' (some a :: roots) := by
  have hc := write_holders m m' roots a item link hh.unique hw
  have hread := write_in_place_preserves m m' a item link hw
  have hnew := write_in_place_read_back m m' a item link hw
  unfold Memory.writeInPlace at hw
  cases hf : m.find? a with
  | none => simp [hf] at hw
  | some c =>
    simp only [hf] at hw
    split at hw
    · simp only [except_pure, Except.ok.injEq] at hw
      subst m'
      refine ⟨?_, ?_, ?_⟩
      · change ((m.updateCell a _).cells.map Cell.addr).Nodup
        rw [update_addresses m a _ (by intro d hd; exact hd.symm)]
        exact hh.unique
      · intro r hr
        rcases List.mem_cons.mp hr with he | hm
        · subst r
          obtain ⟨cs, hp⟩ := hh.readable link (by simp)
          obtain ⟨ds, hd, _⟩ := path_of_read_back _ (some a) _ (hnew cs hp)
          exact ⟨ds, hd⟩
        · obtain ⟨cs, hp⟩ := hh.readable r (by simp [hm])
          exact ⟨cs, hread r cs hp⟩
      · intro d hd hl
        obtain ⟨x, hx, he⟩ := List.mem_map.mp hd
        subst d
        rw [hc]
        split
        · simp [hz]
        · rename_i hn
          have hne : x.addr ≠ a := by simpa using hn
          simp [hne] at hl
          simp [Ne.symm hne, hh.counts x hx hl]
    · simp at hw

end Trial.Proofs
