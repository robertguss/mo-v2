import Proofs.Build

namespace Trial.Proofs

/-- Every live cell starts a finite live path, including cells not currently
named by a root. This rules out dangling links and cycles throughout the heap. -/
def LivePaths (m : Memory) : Prop :=
  ∀ c ∈ m.cells, c.status = .live → ∃ cs, ListPath m (some c.addr) cs

theorem valid_start_live_paths (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    LivePaths s.toMemory := by
  intro d hd _
  obtain ⟨c, hc, he⟩ := List.mem_map.mp hd
  subst d
  exact path_of_chain_ends s s.cells.length (some c.addr) (valid_start_chain_ends e s h c hc)

/-- The first cell of a nonempty path is found at its root. -/
theorem ListPath.head {m : Memory} {a : Addr} {cs : List Cell}
    (hp : ListPath m (some a) cs) :
    ∃ c ds, cs = c :: ds ∧ m.find? a = some c ∧ c.addr = a ∧
      c.status = .live ∧ ListPath m c.link ds := by
  cases hp with
  | cons c ds hf hl ht => exact ⟨c, ds, rfl, hf, rfl, hl, ht⟩

/-- With unique addresses, every allocated cell is found at its own address. -/
theorem find_of_mem (m : Memory) (hu : (m.cells.map Cell.addr).Nodup)
    (c : Cell) (hc : c ∈ m.cells) : m.find? c.addr = some c := by
  obtain ⟨before, after, he⟩ := List.mem_iff_append.mp hc
  rw [he] at hu
  simp only [List.map_append, List.map_cons, List.nodup_append, List.nodup_cons] at hu
  have hn : before.find? (fun d => d.addr == c.addr) = none := by
    apply List.find?_eq_none.mpr
    intro d hd
    have hne := hu.2.2 d.addr (List.mem_map.mpr ⟨d, hd, rfl⟩) c.addr (by simp)
    simpa using hne
  simp [Memory.find?, he, List.find?_append, hn]

/-- A missing or reserved address cannot be a readable root or the tail of a
live cell in a closed heap. Therefore it has no holders. -/
theorem no_holders_unreadable (m : Memory) (roots : List (Option Addr))
    (hh : HeapSafe m roots) (hc : LivePaths m) (a : Addr)
    (hn : ∀ cs, ¬ListPath m (some a) cs) : holders m roots a = 0 := by
  apply (holders_zero m roots a).mpr
  constructor
  · intro hr
    obtain ⟨cs, hp⟩ := hh.readable (some a) hr
    exact hn cs hp
  · intro c hmem hl he
    obtain ⟨cs, hp⟩ := hc c hmem hl
    obtain ⟨d, ds, _, hd, _, _, ht⟩ := hp.head
    have hcd : c = d := Option.some.inj ((find_of_mem m hh.unique c hmem).symm.trans hd)
    subst d
    rw [he] at ht
    exact hn ds ht

theorem no_holders_missing (m : Memory) (roots : List (Option Addr))
    (hh : HeapSafe m roots) (hc : LivePaths m) (a : Addr)
    (hf : m.find? a = none) : holders m roots a = 0 := by
  apply no_holders_unreadable m roots hh hc a
  intro cs hp
  obtain ⟨c, ds, _, hd, _⟩ := hp.head
  rw [hf] at hd
  cases hd

theorem no_holders_reserved (m : Memory) (roots : List (Option Addr))
    (hh : HeapSafe m roots) (hc : LivePaths m) (a : Addr) (c : Cell)
    (hf : m.find? a = some c) (hs : c.status = .setAside) :
    holders m roots a = 0 := by
  apply no_holders_unreadable m roots hh hc a
  intro cs hp
  obtain ⟨d, ds, _, hd, _, hl, _⟩ := hp.head
  rw [hf] at hd
  have he := Option.some.inj hd
  subst d
  rw [hs] at hl
  cases hl

/-- Holder changes do not create a dangling link or a cycle. -/
theorem LivePaths.set_count {m m' : Memory} (hc : LivePaths m) (a : Addr) (n : Nat)
    (hu : m.setCount a n = .ok m') : LivePaths m' := by
  have hp := set_count_path m m' a n hu
  unfold Memory.setCount at hu
  split at hu
  · simp at hu
  · simp only [except_pure, Except.ok.injEq] at hu
    subst m'
    intro d hd hl
    obtain ⟨c, hm, he⟩ := List.mem_map.mp hd
    subst d
    have haddr : (if c.addr == a then { c with count := n } else c).addr = c.addr := by
      split <;> rfl
    have hstatus : c.status = .live := by split at hl <;> exact hl
    obtain ⟨cs, ht⟩ := hc c hm hstatus
    obtain ⟨ds, ht', _, _⟩ := hp (some c.addr) cs ht
    exact ⟨ds, by simpa only [haddr] using ht'⟩

/-- Appending a fresh cell with a readable tail keeps every live cell readable. -/
theorem LivePaths.create {m : Memory} (hc : LivePaths m) (item : Int)
    (link : Option Addr) (cs : List Cell) (hp : ListPath m link cs)
    (hf : m.find? m.next = none) : LivePaths (m.create item link).2 := by
  intro d hd hl
  rcases List.mem_append.mp hd with hm | he
  · obtain ⟨ds, ht⟩ := hc d hm hl
    exact ⟨ds, ht.create item link⟩
  · simp only [List.mem_cons, List.not_mem_nil, or_false] at he
    subst d
    obtain ⟨ds, ht, _⟩ := path_of_read_back _ _ _ (create_read_back m item link cs hp hf)
    exact ⟨ds, ht⟩

/-- Reuse with a readable tail keeps every live cell readable. -/
theorem LivePaths.write {m m' : Memory} (hc : LivePaths m)
    (a : Addr) (item : Int) (link : Option Addr) (cs : List Cell)
    (hp : ListPath m link cs) (hw : m.writeInPlace a item link = .ok m') : LivePaths m' := by
  have hkeep := write_in_place_preserves m m' a item link hw
  have hnew := write_in_place_read_back m m' a item link hw cs hp
  unfold Memory.writeInPlace at hw
  split at hw
  · simp at hw
  · split at hw
    · simp only [except_pure, Except.ok.injEq] at hw
      subst m'
      intro d hd hl
      obtain ⟨c, hm, he⟩ := List.mem_map.mp hd
      subst d
      split
      · obtain ⟨ds, ht, _⟩ := path_of_read_back _ _ _ hnew
        exact ⟨ds, ht⟩
      · rename_i hn
        simp only [hn] at hl
        obtain ⟨ds, ht⟩ := hc c hm hl
        exact ⟨ds, hkeep _ ds ht⟩
    · simp at hw

end Trial.Proofs
