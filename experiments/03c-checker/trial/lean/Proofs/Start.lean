import Proofs.Ownership

namespace Trial.Proofs

theorem except_bind_eq_ok (x : Except ε α) (f : α → Except ε β) (b : β) :
    (x >>= f) = .ok b ↔ ∃ a, x = .ok a ∧ f a = .ok b := by
  cases x <;> simp

theorem checked_loop (xs : List α) (p : α → Bool) (why : α → String) :
    (forIn xs PUnit.unit (fun x _ =>
      if !(p x) then
        (throw (why x) : Except String Unit) >>= fun _ => pure (ForInStep.yield PUnit.unit)
      else pure (ForInStep.yield PUnit.unit))) = .ok PUnit.unit ↔
      ∀ x ∈ xs, p x = true := by
  induction xs with
  | nil => simp
  | cons x xs ih =>
    rw [List.forIn_cons]
    cases hp : p x <;> simp_all

theorem loop_yields (xs : List α) (f : α → Except ε (ForInStep PUnit))
    (hf : ∀ x ∈ xs, f x ≠ .ok (.done PUnit.unit))
    (h : (forIn xs PUnit.unit (fun x _ => f x)) = .ok PUnit.unit) :
    ∀ x ∈ xs, f x = .ok (.yield PUnit.unit) := by
  induction xs with
  | nil => simp
  | cons x xs ih =>
    rw [List.forIn_cons] at h
    cases hx : f x with
    | error why => simp [hx] at h
    | ok step =>
      cases step with
      | done u => cases u; exact False.elim (hf x (by simp) hx)
      | yield u =>
        cases u
        simp [hx] at h
        have ht := ih (fun a ha => hf a (by simp [ha])) h
        intro a ha
        rcases List.mem_cons.mp ha with he | hm
        · simpa [he] using hx
        · exact ht a hm

/-- The roots named by the locked starting-memory validator. -/
def startRoots (s : Start) : List (Option Addr) :=
  s.inputs.filterMap (fun p => match p.2 with | .list l => some l | _ => none) ++ s.outside

/-- Successful validation includes successful text-only well-formedness checking. -/
theorem valid_start_well_formed (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∃ k, wellFormed (s.inputs.map (fun p => (p.1, p.2.kind))) e = .ok k := by
  cases hw : wellFormed (s.inputs.map (fun p => (p.1, p.2.kind))) e with
  | error why => simp [validStart, hw] at h
  | ok k => exact ⟨k, rfl⟩

/-- Every allocated starting cell passes the finite-chain check. -/
theorem valid_start_chain_ends (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∀ c ∈ s.cells, chainEnds s.cells s.cells.length (some c.addr) = true := by
  obtain ⟨k, hw⟩ := valid_start_well_formed e s h
  simp only [validStart, hw, except_bind_ok] at h
  cases hd : dupAddr s.cells with
  | some a => simp [hd] at h
  | none =>
    simp only [hd] at h
    simp only [except_bind_eq_ok] at h
    obtain ⟨⟨⟩, _, ⟨⟩, _, ⟨⟩, hc, _⟩ := h
    exact (checked_loop _ _ _).mp hc

/-- Every nonempty input or outside root names an allocated starting cell. -/
theorem valid_start_roots (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∀ r ∈ startRoots s, ∀ a, r = some a → ∃ c ∈ s.cells, c.addr = a := by
  obtain ⟨k, hw⟩ := valid_start_well_formed e s h
  simp only [validStart, hw, except_bind_ok] at h
  cases hd : dupAddr s.cells with
  | some a => simp [hd] at h
  | none =>
    simp only [hd, except_bind_eq_ok] at h
    obtain ⟨⟨⟩, _, ⟨⟩, hr, _⟩ := h
    have hh := loop_yields _ _ (by
      intro r _
      cases r with
      | none => simp
      | some a => dsimp; split <;> simp) hr
    intro r hm a he
    subst r
    have ha := hh (some a) hm
    by_cases hex : s.cells.any (fun c => c.addr == a) = true
    · simpa using hex
    · simp [hex] at ha

/-- The validator's chain check constructs a finite path in starting memory. -/
theorem path_of_chain_ends (s : Start) (n : Nat) (r : Option Addr)
    (h : chainEnds s.cells n r = true) : ∃ cs, ListPath s.toMemory r cs := by
  induction n generalizing r with
  | zero =>
    cases r with
    | none => exact ⟨[], .nil⟩
    | some a => simp [chainEnds] at h
  | succ n ih =>
    cases r with
    | none => exact ⟨[], .nil⟩
    | some a =>
      cases hf : s.cells.find? (fun c => c.addr == a) with
      | none => simp [chainEnds, hf] at h
      | some c =>
        have ha : c.addr = a := by
          simpa only [beq_iff_eq] using (List.find?_some hf)
        have ht : chainEnds s.cells n c.link = true := by simpa [chainEnds, hf] using h
        obtain ⟨cs, hp⟩ := ih c.link ht
        let d : Cell :=
          { addr := c.addr, item := c.item, link := c.link, count := c.count, status := .live }
        have hd : s.toMemory.find? d.addr = some d := by
          simp [Start.toMemory, Memory.find?, List.find?_map, Function.comp_def, d, ha, hf]
        subst a
        exact ⟨d :: cs, .cons d cs hd rfl hp⟩

/-- Every input or outside root in a valid start has a finite readable path. -/
theorem valid_start_paths (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∀ r ∈ startRoots s, ∃ cs, ListPath s.toMemory r cs := by
  intro r hr
  cases r with
  | none => exact ⟨[], .nil⟩
  | some a =>
    obtain ⟨c, hc, he⟩ := valid_start_roots e s h (some a) hr a rfl
    apply path_of_chain_ends s s.cells.length
    simpa [he] using valid_start_chain_ends e s h c hc

/-- Every validated input reads back with its declared kind. -/
theorem valid_start_input (e : Expr) (s : Start) (h : validStart e s = .ok ())
    (p : String × RawValue) (hp : p ∈ s.inputs) :
    ∃ v, readBack s.toMemory p.2 = .ok v ∧ v.kind = p.2.kind := by
  rcases p with ⟨x, raw⟩
  cases raw with
  | num n => exact ⟨.num n, rfl, rfl⟩
  | bool b => exact ⟨.bool b, rfl, rfl⟩
  | list r =>
    have hr : r ∈ startRoots s := by
      apply List.mem_append_left
      exact List.mem_filterMap.mpr ⟨(x, .list r), hp, rfl⟩
    obtain ⟨cs, hc⟩ := valid_start_paths e s h r hr
    exact ⟨.list (cs.map Cell.item), hc.read_back, rfl⟩

/-- Reading a sequence of readable inputs succeeds and preserves their kinds. -/
theorem read_inputs (m : Memory) (ins : List (String × RawValue))
    (h : ∀ p ∈ ins, ∃ v, readBack m p.2 = .ok v ∧ v.kind = p.2.kind) :
    ∃ vals, ins.mapM (fun p => do
        let v ← readBack m p.2
        pure (p.1, v)) = .ok vals ∧
      vals.map (fun p => (p.1, p.2.kind)) = ins.map (fun p => (p.1, p.2.kind)) := by
  induction ins with
  | nil => exact ⟨[], rfl, rfl⟩
  | cons p ps ih =>
    obtain ⟨v, hv, hk⟩ := h p (by simp)
    obtain ⟨vs, hvs, hks⟩ := ih (fun q hq => h q (by simp [hq]))
    refine ⟨(p.1, v) :: vs, ?_, ?_⟩
    · simp only [except_pure] at hvs
      simp [List.mapM_cons, hv, hvs]
    · simp [hk, hks]

/-- Valid counted inputs have a successful, correctly typed plain interpretation. -/
theorem valid_start_plain (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∃ vals, startPlain s = .ok vals ∧
      vals.map (fun p => (p.1, p.2.kind)) = s.inputs.map (fun p => (p.1, p.2.kind)) := by
  exact read_inputs s.toMemory s.inputs (valid_start_input e s h)

/-- The plain answer used in promise (b) succeeds on every valid start. -/
theorem plain_answer_exists (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∃ v, plainAnswer e s = .ok v := by
  obtain ⟨k, hw⟩ := valid_start_well_formed e s h
  obtain ⟨vals, hv, hk⟩ := valid_start_plain e s h
  obtain ⟨v, hp, _⟩ := run_plain_typed e vals k (by simpa [hk] using hw)
  exact ⟨v, by simp [plainAnswer, hv, hp]⟩

/-- The validator's duplicate-address check is exactly address distinctness. -/
theorem dup_addr_none (cells : List StartCell) :
    dupAddr cells = none ↔ (cells.map StartCell.addr).Nodup := by
  induction cells with
  | nil => simp [dupAddr]
  | cons c cs ih =>
    simp only [dupAddr, List.map_cons, List.nodup_cons]
    by_cases ha : cs.any (fun d => d.addr == c.addr) = true
    · simp [ha]
      intro hn _
      obtain ⟨d, hd, he⟩ := List.any_eq_true.mp ha
      exact hn d hd (by simpa using he)
    · simp [ha, ih]
      intro _ d hd he
      exact ha (List.any_eq_true.mpr ⟨d, hd, by simp [he]⟩)

/-- Validated starting memory has distinct addresses. -/
theorem valid_start_unique (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    (s.toMemory.cells.map Cell.addr).Nodup := by
  obtain ⟨k, hw⟩ := valid_start_well_formed e s h
  cases hd : dupAddr s.cells with
  | some a => simp [validStart, hw, hd] at h
  | none => simpa [Start.toMemory, List.map_map, Function.comp_def] using (dup_addr_none s.cells).mp hd

/-- The two executable ways of counting a root at an address agree. -/
theorem link_names_eq (r : Option Addr) (a : Addr) : linkNames r a = (r == some a) := by
  cases r <;> rfl

/-- The validator's holder totals agree with the totals used in the promises. -/
theorem start_holder_totals (s : Start) (a : Addr) :
    holders s.toMemory (startRoots s) a =
      (s.inputs.filterMap (fun p => match p.2 with | .list l => some l | _ => none)
        |>.filter (fun l => linkNames l a)).length +
      (s.cells.filter (fun c => linkNames c.link a)).length +
      (s.outside.filter (fun l => linkNames l a)).length := by
  simp [holders, startRoots, Start.toMemory, List.filter_append, List.filter_map,
    Function.comp_def, link_names_eq, Nat.add_comm, Nat.add_left_comm]

/-- Every validated starting cell has exactly its actual holder count. -/
theorem valid_start_counts (e : Expr) (s : Start) (h : validStart e s = .ok ()) :
    ∀ c ∈ s.toMemory.cells, c.count = holders s.toMemory (startRoots s) c.addr := by
  obtain ⟨k, hw⟩ := valid_start_well_formed e s h
  simp only [validStart, hw, except_bind_ok] at h
  cases hd : dupAddr s.cells with
  | some a => simp [hd] at h
  | none =>
    simp only [hd, except_bind_eq_ok] at h
    obtain ⟨⟨⟩, _, ⟨⟩, _, ⟨⟩, _, ⟨⟩, _, ⟨⟩, hr, _⟩ := h
    have hh := loop_yields _ _ (by intro c _; dsimp; split <;> simp) hr
    intro d hd
    obtain ⟨c, hc, he⟩ := List.mem_map.mp hd
    subst d
    have hz := hh c hc
    dsimp at hz
    split at hz
    · simp at hz
    · rename_i hn
      rw [start_holder_totals]
      symm
      simp at hn
      exact hn

end Trial.Proofs
