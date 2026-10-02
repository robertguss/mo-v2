import Proofs.Plain

namespace Trial.Proofs

/-- A finite chain of live cells, recording the exact cells visited. -/
inductive ListPath (m : Memory) : Option Addr → List Cell → Prop where
  | nil : ListPath m none []
  | cons (c : Cell) (cs : List Cell)
      (found : m.find? c.addr = some c) (live : c.status = .live)
      (tail : ListPath m c.link cs) : ListPath m (some c.addr) (c :: cs)

/-- A root determines at most one finite path. -/
theorem ListPath.unique {m : Memory} {r : Option Addr} {xs ys : List Cell}
    (hx : ListPath m r xs) (hy : ListPath m r ys) : xs = ys := by
  induction hx generalizing ys with
  | nil => cases hy; rfl
  | cons c cs found live tail ih =>
    generalize hr : some c.addr = r' at hy
    cases hy with
    | nil => cases hr
    | cons d ds fd ld td =>
      have ha := Option.some.inj hr
      rw [ha] at found
      have cd : c = d := Option.some.inj (found.symm.trans fd)
      subst d
      exact congrArg (List.cons c) (ih td)

/-- Each cell on a path is allocated. -/
theorem ListPath.mem_cells {m : Memory} {r : Option Addr} {xs : List Cell}
    (h : ListPath m r xs) : ∀ c ∈ xs, c ∈ m.cells := by
  induction h with
  | nil => simp
  | cons c cs found live tail ih =>
    intro d hd
    rcases List.mem_cons.mp hd with he | ht
    · subst d
      exact List.mem_of_find?_eq_some found
    · exact ih d ht

/-- A cell on a path starts a suffix which is itself a path. -/
theorem ListPath.suffix {m : Memory} {r : Option Addr} {xs : List Cell}
    (h : ListPath m r xs) {a : Addr} (ha : a ∈ xs.map Cell.addr) :
    ∃ ys, ListPath m (some a) ys ∧ ys.length ≤ xs.length := by
  induction h with
  | nil => simp at ha
  | cons c cs found live tail ih =>
    simp only [List.map_cons, List.mem_cons] at ha
    rcases ha with he | ht
    · subst a
      exact ⟨c :: cs, .cons c cs found live tail, Nat.le_refl _⟩
    · obtain ⟨ys, hp, hl⟩ := ih ht
      exact ⟨ys, hp, Nat.le_trans hl (by simp)⟩

/-- A finite path cannot visit one address twice. -/
theorem ListPath.nodup {m : Memory} {r : Option Addr} {xs : List Cell}
    (h : ListPath m r xs) : (xs.map Cell.addr).Nodup := by
  induction h with
  | nil => simp
  | cons c cs found live tail ih =>
    simp only [List.map_cons, List.nodup_cons]
    refine ⟨?_, ih⟩
    intro hm
    obtain ⟨ys, hp, hl⟩ := tail.suffix hm
    have he := (ListPath.cons c cs found live tail).unique hp
    subst ys
    simp only [List.length_cons] at hl
    omega

/-- A finite path fits within the number of allocated cells. -/
theorem ListPath.length_le {m : Memory} {r : Option Addr} {xs : List Cell}
    (h : ListPath m r xs) : xs.length ≤ m.cells.length := by
  have hs : xs.map Cell.addr ⊆ m.cells.map Cell.addr := by
    intro a ha
    obtain ⟨c, hc, he⟩ := List.mem_map.mp ha
    exact List.mem_map.mpr ⟨c, h.mem_cells c hc, he⟩
  have := List.Nodup.length_le_of_subset h.nodup hs
  simpa using this

/-- With enough fuel, the executable reader returns the path's items. -/
theorem ListPath.read {m : Memory} {r : Option Addr} {xs : List Cell}
    (h : ListPath m r xs) (n : Nat) (hn : xs.length ≤ n) :
    readList m n r = .ok (xs.map Cell.item) := by
  induction h generalizing n with
  | nil => simp [readList]
  | cons c cs found live tail ih =>
    cases n with
    | zero => simp at hn
    | succ n =>
      have ht : cs.length ≤ n := by simpa using hn
      simp [readList, found, live, ih n ht]

/-- The public read-back bound suffices for every finite live path. -/
theorem ListPath.read_back {m : Memory} {r : Option Addr} {xs : List Cell}
    (h : ListPath m r xs) :
    readBack m (.list r) = .ok (.list (xs.map Cell.item)) := by
  simp [readBack, h.read m.cells.length h.length_le]

/-- Every successful executable read witnesses a finite live path. -/
theorem path_of_read {m : Memory} {n : Nat} {r : Option Addr} {items : List Int}
    (h : readList m n r = .ok items) :
    ∃ cs, ListPath m r cs ∧ cs.map Cell.item = items := by
  induction n generalizing r items with
  | zero =>
    cases r with
    | none =>
      simp [readList] at h
      exact ⟨[], .nil, h.symm⟩
    | some a =>
      unfold readList at h
      split at h
      · simp at h
      · split at h <;> simp at h
  | succ n ih =>
    cases r with
    | none =>
      simp [readList] at h
      exact ⟨[], .nil, h.symm⟩
    | some a =>
      cases hf : m.find? a with
      | none => simp [readList, hf] at h
      | some c =>
        have ha : c.addr = a := by
          simpa only [beq_iff_eq] using
            (List.find?_some (p := fun c : Cell => c.addr == a) hf)
        cases hl : c.status with
        | setAside => simp [readList, hf, hl] at h
        | live =>
          cases ht : readList m n c.link with
          | error why => simp [readList, hf, hl, ht] at h
          | ok rest =>
            simp [readList, hf, hl, ht] at h
            obtain ⟨cs, hp, hi⟩ := ih ht
            subst a
            exact ⟨c :: cs, .cons c cs hf hl hp, by simp [hi, h.symm]⟩

/-- Reads ignore holder counts, the allocation counter and the operation log. -/
theorem read_list_contents (m m' : Memory)
    (hc : ∀ a, (m.find? a).map (fun c => (c.status, c.item, c.link)) =
      (m'.find? a).map (fun c => (c.status, c.item, c.link)))
    (n : Nat) (r : Option Addr) : readList m n r = readList m' n r := by
  induction n generalizing r with
  | zero =>
    cases r with
    | none => rfl
    | some a =>
      have hh := hc a
      cases hf : m.find? a <;> cases hg : m'.find? a <;> simp [hf, hg] at hh
      · simp [readList, hf, hg]
      · rcases hh with ⟨hs, hi, hl⟩
        simp [readList, hf, hg, hs]
  | succ n ih =>
    cases r with
    | none => rfl
    | some a =>
      have hh := hc a
      cases hf : m.find? a <;> cases hg : m'.find? a <;> simp [hf, hg] at hh
      · simp [readList, hf, hg]
      · rcases hh with ⟨hs, hi, hl⟩
        simp [readList, hf, hg, hs, hi, hl, ih]

/-- Changing holder counts cannot change any raw value's read-back. -/
theorem read_back_counts (m : Memory) (counts : Cell → Nat) (v : RawValue) :
    readBack { m with cells := m.cells.map (fun c => { c with count := counts c }) } v =
      readBack m v := by
  cases v with
  | num n => rfl
  | bool b => rfl
  | list r =>
    unfold readBack
    have h := read_list_contents
      { m with cells := m.cells.map (fun c => { c with count := counts c }) } m
      (by
        intro a
        simp [Memory.find?, List.find?_map, Function.comp_def, Option.map_map])
      m.cells.length r
    simp only [List.length_map]
    rw [h]

/-- A path remains valid when all cells on that path retain their contents. -/
theorem ListPath.preserve {m m' : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (hf : ∀ c ∈ cs, m'.find? c.addr = some c) :
    ListPath m' r cs := by
  induction hp with
  | nil => exact .nil
  | cons c cs found live tail ih =>
    exact .cons c cs (hf c (by simp)) live (ih (fun d hd => hf d (by simp [hd])))

/-- Looking up after an update returns the updated cell, if it was selected. -/
theorem find_update (m : Memory) (a b : Addr) (f : Cell → Cell)
    (hf : ∀ c, c.addr = a → (f c).addr = c.addr) :
    (m.updateCell a f).find? b =
      (m.find? b).map (fun c => if c.addr == a then f c else c) := by
  unfold Memory.updateCell Memory.find?
  rw [List.find?_map]
  have hp : (fun c => c.addr == b) ∘ (fun c => if c.addr == a then f c else c) =
      (fun c => c.addr == b) := by
    funext c
    simp only [Function.comp_apply]
    split
    · rename_i hc
      rw [hf c (by simpa using hc)]
    · rfl
  rw [hp]

/-- An address-preserving update leaves lookups at other addresses alone. -/
theorem find_update_other (m : Memory) (a b : Addr) (f : Cell → Cell)
    (hf : ∀ c, c.addr = a → (f c).addr = c.addr) (hab : b ≠ a) :
    (m.updateCell a f).find? b = m.find? b := by
  rw [find_update m a b f hf]
  cases hh : m.cells.find? (fun c => c.addr == b) with
  | none => simp [Memory.find?, hh]
  | some c =>
    have hc : c.addr = b := by simpa using (List.find?_some hh)
    simp [Memory.find?, hh, hc, hab]

/-- Releasing another address leaves a lookup unchanged. -/
theorem find_filter_other (m : Memory) (a b : Addr) (hab : b ≠ a) :
    ({ m with cells := m.cells.filter (fun c => c.addr != a) } : Memory).find? b =
      m.find? b := by
  simp only [Memory.find?, List.find?_filter]
  congr 1
  funext c
  by_cases hc : c.addr = b <;> simp [hc, hab]

/-- Deleting a cell outside a path preserves that path, even though memory shrinks. -/
theorem ListPath.release {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (a : Addr) (ha : a ∉ cs.map Cell.addr) :
    ListPath { m with cells := m.cells.filter (fun c => c.addr != a) } r cs := by
  apply hp.preserve
  intro c hc
  have hca : c.addr ≠ a := by
    intro he
    exact ha (List.mem_map.mpr ⟨c, hc, he⟩)
  rw [find_filter_other m a c.addr hca]
  induction hp with
  | nil => simp at hc
  | cons d ds found live tail ih =>
    rcases List.mem_cons.mp hc with he | ht
    · simpa [he] using found
    · exact ih (fun hd => ha (by simp [hd])) ht

theorem update_count_eq_map (m : Memory) (a : Addr) (n : Nat) :
    m.updateCell a (fun c => { c with count := n }) =
      { m with cells := m.cells.map (fun c =>
        { c with count := if c.addr == a then n else c.count }) } := by
  unfold Memory.updateCell
  congr 1
  apply List.map_congr_left
  intro c _
  split <;> rfl

/-- Any successful holder-count change preserves every read-back. -/
theorem set_count_read_back (m m' : Memory) (a : Addr) (n : Nat)
    (h : m.setCount a n = .ok m') (v : RawValue) : readBack m' v = readBack m v := by
  unfold Memory.setCount at h
  split at h
  · simp at h
  · simp only [except_pure, Except.ok.injEq] at h
    subst m'
    rw [update_count_eq_map]
    exact read_back_counts m _ v

/-- Every cell listed on a path is the cell found at its address and is live. -/
theorem ListPath.lookup {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) : ∀ c ∈ cs, m.find? c.addr = some c ∧ c.status = .live := by
  induction hp with
  | nil => simp
  | cons c cs found live tail ih =>
    intro d hd
    rcases List.mem_cons.mp hd with he | ht
    · simpa [he] using And.intro found live
    · exact ih d ht

/-- An update outside a finite path preserves that path. -/
theorem ListPath.update_other {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (a : Addr) (f : Cell → Cell)
    (hf : ∀ c, c.addr = a → (f c).addr = c.addr) (ha : a ∉ cs.map Cell.addr) :
    ListPath (m.updateCell a f) r cs := by
  apply hp.preserve
  intro c hc
  rw [find_update_other m a c.addr f hf (by
    intro he
    exact ha (List.mem_map.mpr ⟨c, hc, he⟩))]
  exact (hp.lookup c hc).1

/-- A reserved cell cannot occur on a finite live path. -/
theorem ListPath.avoids_set_aside {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (a : Addr) (c : Cell)
    (hf : m.find? a = some c) (hs : c.status = .setAside) :
    a ∉ cs.map Cell.addr := by
  intro ha
  obtain ⟨d, hd, he⟩ := List.mem_map.mp ha
  obtain ⟨hfd, hld⟩ := hp.lookup d hd
  rw [he, hf] at hfd
  have hc : c = d := Option.some.inj hfd
  subst d
  rw [hs] at hld
  cases hld

/-- Appending a fresh cell leaves all existing paths intact. -/
theorem ListPath.create {m : Memory} {r : Option Addr} {cs : List Cell}
    (hp : ListPath m r cs) (item : Int) (link : Option Addr) :
    ListPath (m.create item link).2 r cs := by
  apply hp.preserve
  intro c hc
  have hf := (hp.lookup c hc).1
  simp only [Memory.find?] at hf
  simp [Memory.create, Memory.find?, List.find?_append, hf]

/-- A fresh allocation extends the readable tail by the chosen item. -/
theorem create_read_back (m : Memory) (item : Int) (r : Option Addr) (cs : List Cell)
    (hp : ListPath m r cs) (fresh : m.find? m.next = none) :
    readBack (m.create item r).2 (.list (some m.next)) =
      .ok (.list (item :: cs.map Cell.item)) := by
  let c : Cell := { addr := m.next, item := item, link := r, count := 1, status := .live }
  have hf : (m.create item r).2.find? c.addr = some c := by
    simp only [Memory.find?] at fresh
    simp [Memory.create, Memory.find?, List.find?_append, c, fresh]
  exact (ListPath.cons c cs hf rfl (hp.create item r)).read_back

/-- Writing a reserved cell leaves every existing live path intact. -/
theorem write_in_place_preserves (m m' : Memory) (a : Addr) (item : Int) (link : Option Addr)
    (hw : m.writeInPlace a item link = .ok m')
    (r : Option Addr) (cs : List Cell) (hp : ListPath m r cs) : ListPath m' r cs := by
  unfold Memory.writeInPlace at hw
  cases hf : m.find? a with
  | none => simp [hf] at hw
  | some c =>
    simp only [hf] at hw
    split at hw
    · rename_i hs
      simp only [except_pure, Except.ok.injEq] at hw
      subst m'
      have hp' := hp.update_other a
        (fun _ => { addr := a, item := item, link := link, count := 1, status := .live })
        (by intro d hd; exact hd.symm) (hp.avoids_set_aside a c hf hs)
      apply hp'.preserve
      intro d hd
      exact (hp'.lookup d hd).1
    · simp at hw

/-- Writing a reserved cell produces the requested item followed by the readable tail. -/
theorem write_in_place_read_back (m m' : Memory) (a : Addr) (item : Int) (link : Option Addr)
    (hw : m.writeInPlace a item link = .ok m') (cs : List Cell)
    (hp : ListPath m link cs) :
    readBack m' (.list (some a)) = .ok (.list (item :: cs.map Cell.item)) := by
  have ht := write_in_place_preserves m m' a item link hw link cs hp
  let d : Cell := { addr := a, item := item, link := link, count := 1, status := .live }
  have hd : m'.find? a = some d := by
    unfold Memory.writeInPlace at hw
    cases hf : m.find? a with
    | none => simp [hf] at hw
    | some c =>
      have hca : c.addr = a := by
        simpa using (List.find?_some (p := fun c : Cell => c.addr == a) hf)
      simp only [hf] at hw
      split at hw
      · simp only [except_pure, Except.ok.injEq] at hw
        subst m'
        change (m.updateCell a (fun _ => d)).find? a = some d
        rw [find_update m a a (fun _ => d) (by intro c hc; exact hc.symm)]
        simp [hf, hca]
      · simp at hw
  exact (ListPath.cons d cs hd rfl ht).read_back

/-- A count change to the cell being removed disappears with that cell. -/
theorem filter_count_update (cells : List Cell) (a : Addr) (n : Nat) :
    (cells.map (fun c => if c.addr == a then { c with count := n } else c)).filter
        (fun c => c.addr != a) = cells.filter (fun c => c.addr != a) := by
  induction cells with
  | nil => rfl
  | cons c cs ih =>
    simp only [beq_iff_eq] at ih
    by_cases h : c.addr = a <;> simp [h, ih]

theorem path_of_read_back (m : Memory) (r : Option Addr) (items : List Int)
    (h : readBack m (.list r) = .ok (.list items)) :
    ∃ cs, ListPath m r cs ∧ cs.map Cell.item = items := by
  cases hr : readList m m.cells.length r with
  | error why => simp [readBack, hr] at h
  | ok xs =>
    simp [readBack, hr] at h
    subst items
    exact path_of_read hr

/-- A count change preserves a path's items and length, although its count fields change. -/
theorem set_count_path (m m' : Memory) (a : Addr) (n : Nat)
    (h : m.setCount a n = .ok m') (r : Option Addr) (cs : List Cell)
    (hp : ListPath m r cs) :
    ∃ ds, ListPath m' r ds ∧ ds.map Cell.item = cs.map Cell.item ∧ ds.length = cs.length := by
  have hr : readBack m' (.list r) = .ok (.list (cs.map Cell.item)) := by
    rw [set_count_read_back m m' a n h, hp.read_back]
  obtain ⟨ds, hd, he⟩ := path_of_read_back m' r _ hr
  exact ⟨ds, hd, he, by simpa using congrArg List.length he⟩

theorem set_count_unique (m m' : Memory) (a : Addr) (n : Nat)
    (h : m.setCount a n = .ok m') (hu : (m.cells.map Cell.addr).Nodup) :
    (m'.cells.map Cell.addr).Nodup := by
  unfold Memory.setCount at h
  split at h
  · simp at h
  · simp only [except_pure, Except.ok.injEq] at h
    subst m'
    rw [update_count_eq_map]
    simpa [List.map_map, Function.comp_def] using hu

end Trial.Proofs
