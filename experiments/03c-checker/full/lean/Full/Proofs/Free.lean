import Full.Proofs.Control
import Full.Proofs.Heap

namespace Full.Proofs
open Trial Trial.Proofs

/-- Full exposes zero-count live cells between GiveUp and Free. Releasing one
transfers its outgoing link to a root, preserving the other roots and the whole
heap's finite live paths. Unlike Trial's Healthy, this does not require positive
counts at the intermediate boundary. -/
theorem release_zero {m : Memory} {roots : List (Option Addr)} {a : Addr} {c : Cell}
    (hh : HeapSafe m roots) (hp : LivePaths m) (hb : FreshBound m)
    (hf : m.find? a = some c) (hl : c.status = .live) (hz : c.count = 0) :
    ∃ m', m.release a = .ok m' ∧ HeapSafe m' (c.link :: roots) ∧
      LivePaths m' ∧ FreshBound m' ∧
      (∀ r ∈ roots, readBack m' (.list r) = readBack m (.list r)) ∧
      readBack m' (.list c.link) = readBack m (.list c.link) := by
  have hca : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
  have hmem := List.mem_of_find?_eq_some hf
  have hzero : holders m roots a = 0 := by
    have hc := hh.counts c hmem hl
    simpa [hca, hz] using hc.symm
  obtain ⟨hnroot, hnlink⟩ := (holders_zero m roots a).mp hzero
  let m' : Memory :=
    { m with cells := m.cells.filter (fun d => d.addr != a)
             record := m.record ++ [.released a] }
  have hr : m.release a = .ok m' := by simp [Memory.release, hf, m']
  have keep : ∀ r cs, ListPath m r cs → r ≠ some a → ListPath m' r cs := by
    intro r cs hpath hn
    have hfiltered := hpath.release a (hpath.avoids a hn hnlink)
    apply hfiltered.preserve
    intro d hd
    exact (hfiltered.lookup d hd).1
  obtain ⟨path, hcpath⟩ := hp c hmem hl
  obtain ⟨d, tail, _, hd, _, _, ht⟩ := hcpath.head
  have hdc : d = c := by rw [hca, hf] at hd; exact (Option.some.inj hd).symm
  subst d
  have htail := keep c.link tail ht (hnlink c hmem hl)
  have hroots : ∀ r ∈ roots, ∃ cs, ListPath m r cs ∧ ListPath m' r cs := by
    intro r hm
    obtain ⟨cs, hpath⟩ := hh.readable r hm
    exact ⟨cs, hpath, keep r cs hpath (fun he => hnroot (he ▸ hm))⟩
  refine ⟨m', hr, ⟨?_, ?_, ?_⟩, ?_, ?_, ?_, ?_⟩
  · exact List.Nodup.sublist (List.Sublist.map Cell.addr List.filter_sublist) hh.unique
  · intro r hm
    rcases List.mem_cons.mp hm with he | hm
    · exact ⟨tail, he ▸ htail⟩
    · obtain ⟨cs, _, hpath⟩ := hroots r hm
      exact ⟨cs, hpath⟩
  · intro d hm hld
    rw [release_holders m m' a c hh.unique hf hl hr]
    exact hh.counts d (List.mem_filter.mp hm).1 hld
  · intro d hm hld
    obtain ⟨hm, hn⟩ := List.mem_filter.mp hm
    obtain ⟨cs, hpath⟩ := hp d hm hld
    exact ⟨cs, keep _ cs hpath (by simpa using hn)⟩
  · intro d hm
    exact hb d (List.mem_filter.mp hm).1
  · intro r hm
    obtain ⟨cs, hpath, hpath'⟩ := hroots r hm
    rw [hpath.read_back, hpath'.read_back]
  · rw [ht.read_back, htail.read_back]

/-- The actual frozen Free transfer, including its tail slot, queued release,
edge removal, release-chain boundary and exact event/record payload. -/
theorem free_transition (p : Program) (s : Counted.State) (a : Addr)
    (c : Cell) (tail : Value) (rest : List Counted.Task)
    (ht : s.tasks = .free a :: rest) (hf : s.mem.find? a = some c)
    (hl : c.status = .live) (hz : c.count = 0)
    (he : s.edges.find? (fun q => q.1 == a) = some (a,tail)) :
    Counted.transition p s = .ok
      ⟨{ s with
        mem := { s.mem with cells := s.mem.cells.filter (fun d => d.addr != a)
                            record := s.mem.record ++ [.released a] },
        edges := s.edges.filter (fun q => q.1 != a),
        slots := if c.link.isSome then ⟨.list c.link,tail⟩ :: s.slots else s.slots,
        releaseChain := if c.link.isSome then s.releaseChain else [],
        tasks := if c.link.isSome then .givePending :: rest else rest,
        events := s.events ++ [.free a] }, ⟨"Free",some .cellFreed⟩,none⟩ := by
  simp [Counted.transition, ht, hf, hl, hz, he, Memory.release]

/-- Free is possible under its local heap/control premises and preserves exact
counts, closure, freshness, and every pre-existing external root's readback.
This is a local preservation lemma, not a claim that all reachable states
already satisfy those premises. -/
theorem free_preserves_heap (p : Program) (s : Counted.State) (a : Addr)
    (c : Cell) (tail : Value) (rest : List Counted.Task)
    (ht : s.tasks = .free a :: rest) (hf : s.mem.find? a = some c)
    (hl : c.status = .live) (hz : c.count = 0)
    (he : s.edges.find? (fun q => q.1 == a) = some (a,tail))
    (hh : HeapSafe s.mem (executionRoots s)) (hp : LivePaths s.mem)
    (hb : FreshBound s.mem) :
    ∃ change, Counted.transition p s = .ok change ∧
      HeapSafe change.state.mem (executionRoots change.state) ∧
      LivePaths change.state.mem ∧ FreshBound change.state.mem ∧
      (∀ r ∈ executionRoots s,
        readBack change.state.mem (.list r) = readBack s.mem (.list r)) ∧
      readBack change.state.mem (.list c.link) = readBack s.mem (.list c.link) := by
  obtain ⟨m', hr, hheap, hpaths, hfresh, hroots, htail⟩ := release_zero hh hp hb hf hl hz
  simp only [Memory.release, hf, except_pure, Except.ok.injEq] at hr
  subst m'
  refine ⟨_, free_transition p s a c tail rest ht hf hl hz he, ?_,
    hpaths, hfresh, hroots, htail⟩
  cases hc : c.link with
  | none =>
    simp only [hc] at hheap
    simpa [executionRoots, hc] using hheap.drop_none
  | some b =>
    simpa [executionRoots, hc, Inspect.link] using hheap

/-- The tail slot and its queued GivePending cancel in the decoder. An empty
tail removes just Free. Both leave exactly the same remaining decoder fuel
and immutable Plain state. -/
theorem free_decode (p : Program) (s : Counted.State) (a : Addr)
    (c : Cell) (tail : Value) (rest : List Counted.Task) (change : Counted.Change)
    (ht : s.tasks = .free a :: rest) (hf : s.mem.find? a = some c)
    (hl : c.status = .live) (hz : c.count = 0)
    (he : s.edges.find? (fun q => q.1 == a) = some (a,tail))
    (hc : Counted.transition p s = .ok change) :
    Control.decode change.state = Control.decode s := by
  have hout := free_transition p s a c tail rest ht hf hl hz he
  have hb : change.state.bindings = s.bindings := by rw [hout] at hc; cases hc; rfl
  have ha : change.state.answer = s.answer := by rw [hout] at hc; cases hc; rfl
  have htasks : change.state.tasks = if c.link.isSome then .givePending :: rest else rest := by
    rw [hout] at hc; cases hc; rfl
  have hslots : change.state.slots =
      if c.link.isSome then ⟨.list c.link,tail⟩ :: s.slots else s.slots := by
    rw [hout] at hc; cases hc; rfl
  simp only [Control.decode, ha, htasks, hslots, focus_bindings change.state s hb]
  cases hans : s.answer with
  | some v => rfl
  | none =>
    rw [ht]
    cases c.link <;> rfl

/-- Free pays for a possible GivePending with the removed cell. This uses the
frozen rank, including its factor four, not a replacement progress measure. -/
theorem free_rank (p : Program) (s : Counted.State) (a : Addr)
    (c : Cell) (tail : Value) (rest : List Counted.Task) (change : Counted.Change)
    (ht : s.tasks = .free a :: rest) (hf : s.mem.find? a = some c)
    (hl : c.status = .live) (hz : c.count = 0)
    (he : s.edges.find? (fun q => q.1 == a) = some (a,tail))
    (hc : Counted.transition p s = .ok change) :
    Control.rank change.state < Control.rank s := by
  have hca : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
  have hlt : (s.mem.cells.filter (fun d => d.addr != a)).length < s.mem.cells.length := by
    have hle := List.length_filter_le (fun d : Cell => d.addr != a) s.mem.cells
    have hne : (s.mem.cells.filter (fun d => d.addr != a)).length ≠ s.mem.cells.length := by
      intro heq
      have := List.length_filter_eq_length_iff.mp heq c (List.mem_of_find?_eq_some hf)
      simp [hca] at this
    omega
  rw [free_transition p s a c tail rest ht hf hl hz he] at hc
  cases hc
  simp only [Control.rank, ht, ← List.sum_eq_foldl_nat]
  cases c.link <;> simp only [Option.isSome_none, Option.isSome_some,
    Bool.false_eq_true, ↓reduceIte, List.map_cons, List.sum_cons] <;> omega

/-- A well-formed pending Free is safe at both transfer and metadata-commit
boundaries. The heap and edge premises are derived from Inspect.invariant;
reachability-to-control-shape preservation is still a separate obligation. -/
theorem free_from_invariant (p : Program) (initial : Start) (s : Counted.State)
    (a : Addr) (c : Cell) (rest : List Counted.Task)
    (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = .free a :: rest) (hf : s.mem.find? a = some c)
    (hl : c.status = .live) (hz : c.count = 0) :
    ∃ change, Counted.transition p s = .ok change ∧
      ∀ t, t = change.state ∨ t = Counted.commit change →
        HeapSafe t.mem (executionRoots t) ∧ LivePaths t.mem ∧ FreshBound t.mem ∧
        (∀ r ∈ executionRoots s, readBack t.mem (.list r) = readBack s.mem (.list r)) ∧
        Control.decode t = Control.decode s ∧ Control.rank t < Control.rank s := by
  have hca : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
  obtain ⟨tail, he, _⟩ := invariant_live_edge initial s hi c (List.mem_of_find?_eq_some hf) hl
  rw [hca] at he
  obtain ⟨hh, hp, hb⟩ := invariant_heap initial s hi
  obtain ⟨change, hc, hheap, hpaths, hfresh, hroots, _⟩ :=
    free_preserves_heap p s a c tail rest ht hf hl hz he hh hp hb
  have hd := free_decode p s a c tail rest change ht hf hl hz he hc
  have hr := free_rank p s a c tail rest change ht hf hl hz he hc
  refine ⟨change, hc, ?_⟩
  intro t ht
  rcases ht with rfl | rfl
  · exact ⟨hheap, hpaths, hfresh, hroots, hd, hr⟩
  · exact ⟨hheap, hpaths, hfresh, hroots, (decode_commit change).trans hd, hr⟩

end Full.Proofs
