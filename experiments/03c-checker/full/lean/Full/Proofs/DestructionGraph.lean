import Full.Proofs.Heap

namespace Full.Proofs.Destruction
open Trial Trial.Proofs

def project (c : Cell) : StartCell := ⟨c.addr, c.item, c.link, c.count⟩

/-- The frozen address walk is exactly the addresses of a finite live path. -/
theorem path_chain {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (n : Nat) (hn : cs.length ≤ n) :
    chainAddrs (m.cells.map project) n r = cs.map Cell.addr := by
  induction hp generalizing n with
  | nil => simp [chainAddrs]
  | cons c cs hf hl ht ih =>
    cases n with
    | zero => simp at hn
    | succ n =>
      have htlen : cs.length ≤ n := by simpa using hn
      have hfind : (m.cells.map project).find? (fun d => d.addr == c.addr) =
          some (project c) := by
        simpa [Memory.find?, List.find?_map, Function.comp_def, project] using
          congrArg (Option.map project) hf
      simp [chainAddrs, hfind, project, ih n htlen]

def reached (m : Memory) (roots : List (Option Addr)) : List Addr :=
  roots.flatMap (chainAddrs (m.cells.map project) m.cells.length)

def retained (m : Memory) (roots : List (Option Addr)) : Memory :=
  { m with cells := m.cells.filter (fun c => (reached m roots).contains c.addr) }

theorem path_retained {m : Memory} {roots : List (Option Addr)} {r : Option Addr}
    {cs : List Cell} (hp : ListPath m r cs)
    (hc : ∀ c ∈ cs, c.addr ∈ reached m roots) :
    ListPath (retained m roots) r cs := by
  induction hp with
  | nil => exact .nil
  | cons c cs hf hl ht ih =>
    refine .cons c cs ?_ hl (ih (fun d hd => hc d (by simp [hd])))
    have hkeep := List.contains_iff_mem.mpr (hc c (by simp))
    change (m.cells.filter _).find? _ = some c
    rw [List.find?_filter]
    apply List.find?_eq_some_iff_append.mpr
    obtain ⟨hpred, pre, post, he, hpre⟩ := List.find?_eq_some_iff_append.mp hf
    refine ⟨by simp_all, pre, post, he, ?_⟩
    intro d hd
    have := hpre d hd
    simp_all

theorem outside_retained {m : Memory} {roots : List (Option Addr)} {r : Option Addr}
    {cs : List Cell} (hp : ListPath m r cs) (hr : r ∈ roots) :
    ListPath (retained m roots) r cs := by
  apply path_retained hp
  intro c hc
  apply List.mem_flatMap.mpr
  refine ⟨r, hr, ?_⟩
  rw [path_chain hp _ hp.length_le]
  exact List.mem_map.mpr ⟨c, hc, rfl⟩

/-- Removing storage not visited by outside roots preserves each outside read. -/
theorem retained_readBack (m : Memory) (roots : List (Option Addr))
    (h : ∀ r ∈ roots, ∃ cs, ListPath m r cs) (r : Option Addr) (hr : r ∈ roots) :
    readBack (retained m roots) (.list r) = readBack m (.list r) := by
  obtain ⟨cs, hp⟩ := h r hr
  rw [(outside_retained hp hr).read_back, hp.read_back]

theorem path_ends {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (n : Nat) (hn : cs.length ≤ n) :
    chainEnds (m.cells.map project) n r = true := by
  induction hp generalizing n with
  | nil => simp [chainEnds]
  | cons c cs hf hl ht ih =>
    cases n with
    | zero => simp at hn
    | succ n =>
      have htlen : cs.length ≤ n := by simpa using hn
      have hfind : (m.cells.map project).find? (fun d => d.addr == c.addr) =
          some (project c) := by
        simpa [Memory.find?, List.find?_map, Function.comp_def, project] using
          congrArg (Option.map project) hf
      simp [chainEnds, hfind, project, ih n htlen]

/-- Retained membership is precisely membership on an outside live path. -/
theorem retained_path_member (m : Memory) (roots : List (Option Addr))
    (hu : (m.cells.map Cell.addr).Nodup)
    (hr : ∀ r ∈ roots, ∃ cs, ListPath m r cs) (c : Cell)
    (hc : c ∈ (retained m roots).cells) :
    ∃ r ∈ roots, ∃ cs, ListPath m r cs ∧ c ∈ cs := by
  obtain ⟨hm, hk⟩ := List.mem_filter.mp hc
  obtain ⟨r, hroot, ha⟩ := List.mem_flatMap.mp (List.contains_iff_mem.mp hk)
  obtain ⟨cs, hp⟩ := hr r hroot
  rw [path_chain hp _ hp.length_le] at ha
  obtain ⟨d, hd, he⟩ := List.mem_map.mp ha
  have hf := find_of_mem m hu c hm
  have hg := (hp.lookup d hd).1
  rw [he] at hg
  have hcd := Option.some.inj (hf.symm.trans hg)
  exact ⟨r, hroot, cs, hp, hcd ▸ hd⟩

theorem retained_live (m : Memory) (roots : List (Option Addr))
    (hu : (m.cells.map Cell.addr).Nodup)
    (hr : ∀ r ∈ roots, ∃ cs, ListPath m r cs) :
    ∀ c ∈ (retained m roots).cells, c.status = .live := by
  intro c hc
  obtain ⟨r, _, cs, hp, hm⟩ := retained_path_member m roots hu hr c hc
  exact (hp.lookup c hm).2

theorem retained_closed (m : Memory) (roots : List (Option Addr))
    (hu : (m.cells.map Cell.addr).Nodup)
    (hr : ∀ r ∈ roots, ∃ cs, ListPath m r cs) :
    ∀ c ∈ (retained m roots).cells, ∃ cs, ListPath (retained m roots) (some c.addr) cs := by
  intro c hc
  obtain ⟨r, hroot, cs, hp, hm⟩ := retained_path_member m roots hu hr c hc
  obtain ⟨ds, hd, _⟩ := (outside_retained hp hroot).suffix
    (List.mem_map.mpr ⟨c, hm, rfl⟩)
  exact ⟨ds, hd⟩

private theorem yield_loop (xs : List α) (f : α → Except String (ForInStep PUnit))
    (h : ∀ x ∈ xs, f x = .ok (.yield PUnit.unit)) :
    (forIn xs PUnit.unit (fun x _ => f x)) = .ok PUnit.unit := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    rw [List.forIn_cons, h x (by simp)]
    exact ih (fun y hy => h y (by simp [hy]))

private theorem path_root_exists {m : Memory} {a : Addr} {cs : List Cell}
    (hp : ListPath m (some a) cs) : ∃ c ∈ m.cells, c.addr = a := by
  generalize he : some a = r at hp
  cases hp with
  | nil => cases he
  | cons c cs hf hl ht =>
    exact ⟨c, List.mem_of_find?_eq_some hf, (Option.some.inj he).symm⟩

/-- Sufficient graph facts for the literal frozen outside-only validator.
The reachability premise checks every cell, rather than replacing no-garbage
with the weaker local heap safety predicate. -/
theorem valid_outside (m : Memory) (roots : List (Option Addr))
    (hu : (m.cells.map Cell.addr).Nodup)
    (hr : ∀ r ∈ roots, ∃ cs, ListPath m r cs)
    (hc : ∀ c ∈ m.cells, ∃ cs, ListPath m (some c.addr) cs)
    (hg : ∀ c ∈ m.cells, ∃ r ∈ roots, ∃ cs, ListPath m r cs ∧ c ∈ cs)
    (hn : ∀ c ∈ m.cells, c.count =
      (roots.filter (fun r => r == some c.addr)).length +
      (m.cells.filter (fun d => d.link == some c.addr)).length) :
    validStart (.num 0) ⟨m.cells.map project, [], roots⟩ = .ok () := by
  have hd : dupAddr (m.cells.map project) = none := by
    apply (dup_addr_none _).mpr
    simpa [List.map_map, Function.comp_def, project] using hu
  have exists_cell (a : Addr) (h : ∃ c ∈ m.cells, c.addr = a) :
      (m.cells.map project).any (fun c => c.addr == a) = true := by
    obtain ⟨c, hm, he⟩ := h
    exact List.any_eq_true.mpr ⟨project c, List.mem_map.mpr ⟨c, hm, rfl⟩,
      by simp [project, he]⟩
  have hlinks : ∀ c ∈ m.cells.map project,
      (match c.link with
       | some b => if !((m.cells.map project).any (fun c => c.addr == b)) then
           (throw s!"cell {c.addr} links to {b}, which does not exist" : Except String Unit)
             >>= fun _ => pure (ForInStep.yield PUnit.unit)
           else pure (ForInStep.yield PUnit.unit)
       | none => pure (ForInStep.yield PUnit.unit)) = .ok (.yield PUnit.unit) := by
    intro d hd
    obtain ⟨c, hm, rfl⟩ := List.mem_map.mp hd
    obtain ⟨cs, hp⟩ := hc c hm
    cases hl : c.link with
    | none => simp [project, hl]
    | some a =>
      have ht : ∃ ds, ListPath m c.link ds := by
        generalize he : some c.addr = r at hp
        cases hp with
        | nil => cases he
        | cons d ds hf hdl htail =>
          have ha := Option.some.inj he
          have hfc := find_of_mem m hu c hm
          rw [← ha] at hf
          have heq := Option.some.inj (hfc.symm.trans hf)
          subst d
          exact ⟨ds, htail⟩
      obtain ⟨ds, ht⟩ := ht
      rw [hl] at ht
      have hx := exists_cell a (path_root_exists ht)
      simp [project, hl, hx]
  have hroots : ∀ r ∈ roots,
      (match r with
       | some b => if !((m.cells.map project).any (fun c => c.addr == b)) then
           (throw s!"an input or outside holder names {b}, which does not exist" : Except String Unit)
             >>= fun _ => pure (ForInStep.yield PUnit.unit)
           else pure (ForInStep.yield PUnit.unit)
       | none => pure (ForInStep.yield PUnit.unit)) = .ok (.yield PUnit.unit) := by
    intro r hm
    cases r with
    | none => rfl
    | some a =>
      obtain ⟨cs, hp⟩ := hr (some a) hm
      simp [exists_cell a (path_root_exists hp)]
  have hends : ∀ c ∈ m.cells.map project,
      chainEnds (m.cells.map project) (m.cells.map project).length (some c.addr) = true := by
    intro d hd
    obtain ⟨c, hm, rfl⟩ := List.mem_map.mp hd
    obtain ⟨cs, hp⟩ := hc c hm
    exact path_ends hp _ (by simpa using hp.length_le)
  have hreached : ∀ c ∈ m.cells.map project,
      (roots.foldl (fun acc r => acc ++
        chainAddrs (m.cells.map project) (m.cells.map project).length r) []).contains c.addr = true := by
    intro d hd
    obtain ⟨c, hm, rfl⟩ := List.mem_map.mp hd
    obtain ⟨r, hroot, cs, hp, hmem⟩ := hg c hm
    rw [← List.flatMap_eq_foldl]
    apply List.contains_iff_mem.mpr
    refine List.mem_flatMap.mpr ⟨r, hroot, ?_⟩
    rw [path_chain hp _ (by simpa using hp.length_le)]
    exact List.mem_map.mpr ⟨c, hmem, rfl⟩
  have hcounts : ∀ c ∈ m.cells.map project,
      (0 + ((m.cells.map project).filter (fun d => linkNames d.link c.addr)).length +
        (roots.filter (fun r => linkNames r c.addr)).length != c.count) = false := by
    intro d hd
    obtain ⟨c, hm, rfl⟩ := List.mem_map.mp hd
    simp [project, link_names_eq, List.filter_map, Function.comp_def, hn c hm,
      Nat.add_comm]
  unfold validStart
  dsimp only
  simp only [List.map_nil, wellFormed, dupInput, List.any_nil, Trial.check,
    List.filterMap_nil, List.nil_append, hd, List.filter_nil, List.length_nil,
    Bool.false_eq_true, ↓reduceIte]
  erw [yield_loop _ _ hlinks]
  simp only [except_bind_ok]
  erw [yield_loop _ _ hroots]
  simp only [except_bind_ok]
  erw [(checked_loop _ _ _).mpr hends]
  simp only [except_bind_ok]
  erw [(checked_loop _ _ _).mpr hreached]
  simp only [except_bind_ok]
  have hcountloop := yield_loop (m.cells.map project)
    (fun c => if (0 + ((m.cells.map project).filter (fun d => linkNames d.link c.addr)).length +
        (roots.filter (fun r => linkNames r c.addr)).length != c.count) then
      (throw s!"cell {c.addr} has count {c.count} but {0 + ((m.cells.map project).filter (fun d => linkNames d.link c.addr)).length + (roots.filter (fun r => linkNames r c.addr)).length} holders" : Except String Unit)
        >>= fun _ => pure (ForInStep.yield PUnit.unit)
      else pure (ForInStep.yield PUnit.unit))
    (by intro c hc; simp only [hcounts c hc, Bool.false_eq_true, ↓reduceIte]; rfl)
  erw [hcountloop]
  rfl

def recount (roots : List (Option Addr)) (m : Memory) : Memory :=
  { m with cells := m.cells.map (fun c => { c with count :=
      (roots.filter (fun r => r == some c.addr)).length +
      (m.cells.filter (fun d => d.link == some c.addr)).length }) }

theorem path_counts {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (counts : Cell → Nat) :
    ListPath { m with cells := m.cells.map (fun c => { c with count := counts c }) }
      r (cs.map (fun c => { c with count := counts c })) := by
  induction hp with
  | nil => exact .nil
  | cons c cs hf hl ht ih =>
    refine .cons { c with count := counts c } _ ?_ hl ih
    simpa only [Memory.find?, List.find?_map, Function.comp_def, Option.map_some] using
      congrArg (Option.map (fun c => { c with count := counts c })) hf

/-- The literal retained-and-recounted graph passes all frozen checks. -/
theorem retained_valid (m : Memory) (roots : List (Option Addr))
    (hu : (m.cells.map Cell.addr).Nodup)
    (hr : ∀ r ∈ roots, ∃ cs, ListPath m r cs) :
    validStart (.num 0)
      ⟨(recount roots (retained m roots)).cells.map project, [], roots⟩ = .ok () := by
  let k := retained m roots
  let counts := fun c : Cell =>
    (roots.filter (fun r => r == some c.addr)).length +
    (k.cells.filter (fun d => d.link == some c.addr)).length
  let update := fun c : Cell => { c with count := counts c }
  apply valid_outside
  · change ((k.cells.map update).map Cell.addr).Nodup
    have hk : (k.cells.map Cell.addr).Nodup :=
      hu.sublist ((List.filter_sublist).map Cell.addr)
    simpa [List.map_map, Function.comp_def, update] using hk
  · intro r hroot
    obtain ⟨cs, hp⟩ := hr r hroot
    exact ⟨cs.map update, path_counts (outside_retained hp hroot) counts⟩
  · intro c hc
    obtain ⟨d, hd, rfl⟩ := List.mem_map.mp hc
    obtain ⟨cs, hp⟩ := retained_closed m roots hu hr d hd
    exact ⟨cs.map update, path_counts hp counts⟩
  · intro c hc
    obtain ⟨d, hd, rfl⟩ := List.mem_map.mp hc
    obtain ⟨r, hroot, cs, hp, hm⟩ := retained_path_member m roots hu hr d hd
    refine ⟨r, hroot, cs.map update, path_counts (outside_retained hp hroot) counts, ?_⟩
    exact List.mem_map.mpr ⟨d, hm, rfl⟩
  · intro c hc
    obtain ⟨d, hd, rfl⟩ := List.mem_map.mp hc
    simp [recount, List.filter_map, Function.comp_def]

end Full.Proofs.Destruction
