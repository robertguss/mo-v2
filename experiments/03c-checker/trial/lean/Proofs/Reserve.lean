import Proofs.Closed

namespace Trial.Proofs

/-- Setting a live cell aside transfers exactly its link-holder to a root. -/
theorem reserve_holders (m m' : Memory) (roots : List (Option Addr))
    (a : Addr) (c : Cell) (hu : (m.cells.map Cell.addr).Nodup)
    (hf : m.find? a = some c) (hl : c.status = .live)
    (hm : m.markSetAside a = .ok m') (b : Addr) :
    holders m' (c.link :: roots) b = holders m roots b := by
  simp only [Memory.markSetAside, hf, except_pure, Except.ok.injEq] at hm
  subst m'
  obtain ⟨before, after, he, hu, _⟩ := update_one m a c hu hf
    (fun d => { d with status := .setAside, count := 0, link := none })
  simp only [holders]
  rw [hu, he]
  cases hb : c.link == some b <;>
    simp [List.filter_append, hl, hb, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]

/-- Setting an exclusively held cell aside preserves every other root's list,
and makes its detached tail available as the new root. -/
theorem HeapSafe.reserve {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (hh : HeapSafe m (some a :: roots)) (hf : m.find? a = some c)
    (hl : c.status = .live) (hc : c.count = 1)
    (hm : m.markSetAside a = .ok m') (cs : List Cell) (ht : ListPath m c.link cs) :
    HeapSafe m' (c.link :: roots) ∧ ListPath m' c.link cs ∧
      (∀ r ∈ roots, readBack m' (.list r) = readBack m (.list r)) := by
  have hca : c.addr = a := by simpa using (List.find?_some hf)
  have hown : holders m (some a :: roots) a = 1 := by
    have hh' := hh.counts c (List.mem_of_find?_eq_some hf) hl
    simpa [hca, hc] using hh'.symm
  have hholders := reserve_holders m m' roots a c hh.unique hf hl hm
  simp only [Memory.markSetAside, hf, except_pure, Except.ok.injEq] at hm
  subst m'
  have hfull := ListPath.cons c cs (by simpa [hca] using hf) hl ht
  have ha : a ∉ cs.map Cell.addr := by
    simpa [hca] using (List.nodup_cons.mp hfull.nodup).1
  have htail := ht.update_other a
    (fun d => { d with status := .setAside, count := 0, link := none })
    (by intro d _; rfl) ha
  have hother : ∀ r ∈ roots, ∃ ds, ListPath m r ds ∧
      ListPath (m.updateCell a (fun d => { d with status := .setAside, count := 0, link := none })) r ds := by
    intro r hr
    obtain ⟨ds, hp⟩ := hh.readable r (by simp [hr])
    exact ⟨ds, hp, hp.update_other a _ (by intro d _; rfl)
      (sole_holder_avoids m roots a hown r hr ds hp)⟩
  refine ⟨⟨?_, ?_, ?_⟩, htail, ?_⟩
  · rw [update_addresses m a _ (by intro d _; rfl)]
    exact hh.unique
  · intro r hr
    rcases List.mem_cons.mp hr with he | hm
    · exact ⟨cs, he ▸ htail⟩
    · obtain ⟨ds, _, hp⟩ := hother r hm
      exact ⟨ds, hp⟩
  · intro d hd hld
    obtain ⟨x, hx, he⟩ := List.mem_map.mp hd
    subst d
    split at hld
    · cases hld
    · rename_i hn
      have hne : x.addr ≠ a := by simpa using hn
      simp only [hn]
      rw [hholders]
      have hcount := hh.counts x hx hld
      simpa [holders_cons, Ne.symm hne] using hcount
  · intro r hr
    obtain ⟨ds, hp, hp'⟩ := hother r hr
    rw [hp.read_back, hp'.read_back]

/-- Reserving an exclusively owned cell cannot break another live cell's path. -/
theorem LivePaths.reserve {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (hp : LivePaths m) (hh : HeapSafe m (some a :: roots))
    (hf : m.find? a = some c) (hl : c.status = .live) (hc : c.count = 1)
    (hm : m.markSetAside a = .ok m') : LivePaths m' := by
  have hca : c.addr = a := by simpa using (List.find?_some hf)
  have hown : holders m (some a :: roots) a = 1 := by
    have ht := hh.counts c (List.mem_of_find?_eq_some hf) hl
    simpa [hca, hc] using ht.symm
  obtain ⟨_, hlinks⟩ := sole_holder m roots a hown
  simp only [Memory.markSetAside, hf, except_pure, Except.ok.injEq] at hm
  subst m'
  intro d hd hld
  obtain ⟨x, hx, he⟩ := List.mem_map.mp hd
  subst d
  split at hld
  · cases hld
  · rename_i hn
    have hne : x.addr ≠ a := by simpa using hn
    simp only [hn]
    obtain ⟨cs, ht⟩ := hp x hx hld
    exact ⟨cs, ht.update_other a _ (by intro d _; rfl)
      (ht.avoids a (by simpa using hne) hlinks)⟩

end Trial.Proofs
