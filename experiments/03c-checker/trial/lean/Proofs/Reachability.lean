import Proofs.Reserve

namespace Trial.Proofs

/-- Logical reachability through one of the finite live root paths. -/
def RootReaches (m : Memory) (roots : List (Option Addr)) (a : Addr) : Prop :=
  ∃ r ∈ roots, ∃ cs, ListPath m r cs ∧ a ∈ cs.map Cell.addr

/-- The locked address walker returns exactly a finite path's addresses. -/
theorem ListPath.walk {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (n : Nat) (hn : cs.length ≤ n) :
    walkAddrs m n r = .ok (cs.map Cell.addr) := by
  induction hp generalizing n with
  | nil => simp [walkAddrs]
  | cons c cs hf hl ht ih =>
    cases n with
    | zero => simp at hn
    | succ n =>
      have hn' : cs.length ≤ n := by simpa using hn
      simp [walkAddrs, hf, hl, ih n hn']

theorem reachable_cons (m : Memory) (r : Option Addr) (roots : List (Option Addr)) :
    reachable m (r :: roots) = (do
      let xs ← walkAddrs m m.cells.length r
      let ys ← reachable m roots
      pure (xs ++ ys)) := by
  cases hx : walkAddrs m m.cells.length r <;>
    cases hy : roots.mapM (walkAddrs m m.cells.length) <;>
    simp [reachable, List.mapM_cons, hx, hy, Except.map]

/-- Executable reachability succeeds on readable roots and has exactly the
logical finite-path membership relation. -/
theorem reachable_spec (m : Memory) (roots : List (Option Addr))
    (hp : ∀ r ∈ roots, ∃ cs, ListPath m r cs) :
    ∃ xs, reachable m roots = .ok xs ∧ ∀ a, a ∈ xs ↔ RootReaches m roots a := by
  induction roots with
  | nil => exact ⟨[], rfl, by simp [RootReaches]⟩
  | cons r rs ih =>
    obtain ⟨cs, hc⟩ := hp r (by simp)
    obtain ⟨xs, hx, hs⟩ := ih (fun q hq => hp q (by simp [hq]))
    refine ⟨cs.map Cell.addr ++ xs, ?_, ?_⟩
    · rw [reachable_cons, hc.walk _ hc.length_le, hx]
      rfl
    · intro a
      constructor
      · intro hm
        rcases List.mem_append.mp hm with hc' | hx'
        · exact ⟨r, by simp, cs, hc, hc'⟩
        · obtain ⟨q, hq, ds, hd, ha⟩ := (hs a).mp hx'
          exact ⟨q, by simp [hq], ds, hd, ha⟩
      · rintro ⟨q, hq, ds, hd, ha⟩
        rcases List.mem_cons.mp hq with he | ht
        · subst q
          have he := hc.unique hd
          subst ds
          exact List.mem_append_left _ ha
        · exact List.mem_append_right _ ((hs a).mpr ⟨q, ht, ds, hd, ha⟩)

theorem ListPath.root_mem {m : Memory} {a : Addr} {cs : List Cell}
    (hp : ListPath m (some a) cs) : a ∈ cs.map Cell.addr := by
  cases hp with
  | cons c cs hf hl ht => simp

/-- A path containing a cell also contains the address of its nonempty tail. -/
theorem ListPath.follow {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (d : Cell) (hd : m.find? d.addr = some d)
    (a : Addr) (ha : d.link = some a) (hm : d.addr ∈ cs.map Cell.addr) :
    a ∈ cs.map Cell.addr := by
  induction hp with
  | nil => simp at hm
  | cons c cs hf hl ht ih =>
    simp only [List.map_cons, List.mem_cons] at hm ⊢
    rcases hm with he | hm
    · rw [he, hf] at hd
      have hcd := Option.some.inj hd
      subst d
      right
      exact (ha ▸ ht).root_mem
    · exact Or.inr (ih hm)

/-- In a finite acyclic heap with correct positive counts, every live cell is
reachable from a root. Following a holder backwards strictly lengthens a path,
so the search must reach a root before exceeding the number of allocated cells. -/
theorem positive_reachable (m : Memory) (roots : List (Option Addr))
    (hh : HeapSafe m roots) (hp : LivePaths m)
    (hpos : ∀ c ∈ m.cells, c.status = .live → 0 < c.count)
    (c : Cell) (hc : c ∈ m.cells) (hl : c.status = .live) : RootReaches m roots c.addr := by
  have main : ∀ n a cs, ListPath m (some a) cs → m.cells.length - cs.length = n →
      RootReaches m roots a := by
    intro n
    induction n using Nat.strongRecOn with
    | ind n ih =>
      intro a cs hpath hn
      by_cases hr : some a ∈ roots
      · exact ⟨some a, hr, cs, hpath, hpath.root_mem⟩
      · obtain ⟨d, ds, _, hd, hda, hdl, _⟩ := hpath.head
        have hdm := List.mem_of_find?_eq_some hd
        have hcount := hh.counts d hdm hdl
        have hpositive := hpos d hdm hdl
        have hex : ∃ x ∈ m.cells, x.status = .live ∧ x.link = some a := by
          apply Classical.byContradiction
          intro hno
          have hz : holders m roots a = 0 := (holders_zero m roots a).mpr ⟨hr, by
            intro x hx hxl hxa
            exact hno ⟨x, hx, hxl, hxa⟩⟩
          rw [hda, hz] at hcount
          omega
        obtain ⟨x, hx, hxl, hxa⟩ := hex
        have hxf := find_of_mem m hh.unique x hx
        have hlong : ListPath m (some x.addr) (x :: cs) :=
          .cons x cs hxf hxl (hxa ▸ hpath)
        have hbound := hlong.length_le
        have hlt : m.cells.length - (x :: cs).length < n := by
          simp only [List.length_cons] at hbound ⊢
          omega
        obtain ⟨r, hr, ys, hy, hxy⟩ := ih _ hlt x.addr (x :: cs) hlong rfl
        exact ⟨r, hr, ys, hy, hy.follow x hxf a hxa hxy⟩
  obtain ⟨cs, hs⟩ := hp c hc hl
  exact main _ c.addr cs hs rfl

/-- These structural invariants imply the exact locked no-leak predicate at an
end state where no cells remain reserved. This is not yet the evaluator proof. -/
theorem no_leak_of_heap (m : Memory) (roots : List (Option Addr))
    (hh : HeapSafe m roots) (hp : LivePaths m)
    (hlive : ∀ c ∈ m.cells, c.status = .live)
    (hpos : ∀ c ∈ m.cells, 0 < c.count) : NoLeakAt m roots := by
  refine ⟨hlive, hh.unique, ?_, fun c hc => hh.counts c hc (hlive c hc)⟩
  obtain ⟨xs, hx, hs⟩ := reachable_spec m roots hh.readable
  simp only [reachesExactly, hx, Bool.and_eq_true, List.all_eq_true]
  constructor
  · intro a ha
    obtain ⟨r, _, cs, hp, hm⟩ := (hs a).mp ha
    obtain ⟨c, hc, he⟩ := List.mem_map.mp hm
    exact List.any_eq_true.mpr ⟨c, hp.mem_cells c hc, by simp [he]⟩
  · intro c hc
    have hr := positive_reachable m roots hh hp (fun d hd _ => hpos d hd) c hc (hlive c hc)
    simpa using (hs c.addr).mpr hr

end Trial.Proofs
