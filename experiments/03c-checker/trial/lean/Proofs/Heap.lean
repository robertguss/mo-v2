import Proofs.Start

namespace Trial.Proofs

/-- The local heap obligations used by release: unique addresses, readable roots,
and exact counts for live cells. This does not assert absence of garbage. -/
structure HeapSafe (m : Memory) (roots : List (Option Addr)) : Prop where
  unique : (m.cells.map Cell.addr).Nodup
  readable : ∀ r ∈ roots, ∃ cs, ListPath m r cs
  counts : CountsCorrect m roots

theorem valid_start_heap (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    HeapSafe s.toMemory (startRoots s) := by
  refine ⟨valid_start_unique e s h, valid_start_paths e s h, ?_⟩
  intro c hc _
  exact valid_start_counts e s h c hc

theorem HeapSafe.drop_none {m : Memory} {roots : List (Option Addr)}
    (h : HeapSafe m (none :: roots)) : HeapSafe m roots := by
  refine ⟨h.unique, fun r hr => h.readable r (by simp [hr]), ?_⟩
  intro c hc hl
  have hh := h.counts c hc hl
  simpa [holders_cons] using hh

/-- Removing a root and adjusting its count preserves these local heap obligations. -/
theorem HeapSafe.remove_count {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (h : HeapSafe m (some a :: roots)) (hf : m.find? a = some c) (hl : c.status = .live)
    (hu : m.setCount a (c.count - 1) = .ok m') : HeapSafe m' roots := by
  refine ⟨set_count_unique m m' a _ hu h.unique, ?_, counts_remove_root m m' roots a c h.counts hf hl hu⟩
  intro r hr
  obtain ⟨cs, hp⟩ := h.readable r (by simp [hr])
  obtain ⟨ds, hd, _, _⟩ := set_count_path m m' a _ hu r cs hp
  exact ⟨ds, hd⟩

/-- Deleting the cell of an exclusive root preserves all other roots and transfers
its link to a new root. The removed cell need not be first in the memory list. -/
theorem HeapSafe.release_one {m m' : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (h : HeapSafe m (some a :: roots)) (hf : m.find? a = some c) (hl : c.status = .live)
    (hc : c.count = 1) (hr : m.release a = .ok m') (cs : List Cell)
    (ht : ListPath m c.link cs) :
    HeapSafe m' (c.link :: roots) ∧
      (∀ r ∈ roots, readBack m' (.list r) = readBack m (.list r)) ∧
      ListPath m' c.link cs := by
  have hca : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
  have hown : holders m (some a :: roots) a = 1 := by
    have hh := h.counts c (List.mem_of_find?_eq_some hf) hl
    simpa [hca, hc] using hh.symm
  have full := ListPath.cons c cs (by simpa [hca] using hf) hl ht
  have ha : a ∉ cs.map Cell.addr := by
    simpa [hca] using (List.nodup_cons.mp full.nodup).1
  have hholders := release_holders m m' a c h.unique hf hl hr
  simp only [Memory.release, hf, except_pure, Except.ok.injEq] at hr
  subst m'
  have htail : ListPath
      { m with cells := m.cells.filter (fun d => d.addr != a), record := m.record ++ [.released a] }
      c.link cs := by
    have hp := ht.release a ha
    apply hp.preserve
    intro d hd
    exact (hp.lookup d hd).1
  have hother : ∀ r ∈ roots, ∃ ds, ListPath m r ds ∧ ListPath
      { m with cells := m.cells.filter (fun d => d.addr != a), record := m.record ++ [.released a] }
      r ds := by
    intro r hr
    obtain ⟨ds, hp⟩ := h.readable r (by simp [hr])
    have hp' := hp.release a (sole_holder_avoids m roots a hown r hr ds hp)
    refine ⟨ds, hp, ?_⟩
    apply hp'.preserve
    intro d hd
    exact (hp'.lookup d hd).1
  refine ⟨⟨?_, ?_, ?_⟩, ?_, htail⟩
  · exact List.Nodup.sublist (List.Sublist.map Cell.addr List.filter_sublist) h.unique
  · intro r hr
    rcases List.mem_cons.mp hr with he | hm
    · exact ⟨cs, he ▸ htail⟩
    · obtain ⟨ds, _, hp⟩ := hother r hm
      exact ⟨ds, hp⟩
  · intro d hd hld
    obtain ⟨hd, hda⟩ := List.mem_filter.mp hd
    have hdne : d.addr ≠ a := by simpa using hda
    rw [hholders]
    have hh := h.counts d hd hld
    simpa [holders_cons, Ne.symm hdne] using hh
  · intro r hr
    obtain ⟨ds, hp, hp'⟩ := hother r hr
    rw [hp.read_back, hp'.read_back]

end Trial.Proofs
