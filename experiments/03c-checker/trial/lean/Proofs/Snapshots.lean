import Proofs.Disposal

namespace Trial.Proofs

/-- Read-back depends on allocated cells, not on the allocator counter or log. -/
theorem read_back_cells (m m' : Memory) (hc : m.cells = m'.cells) (v : RawValue) :
    readBack m v = readBack m' v := by
  cases v with
  | num n => rfl
  | bool b => rfl
  | list r =>
    have hr := read_list_contents m m' (by intro a; simp [Memory.find?, hc]) m.cells.length r
    simp only [readBack]
    rw [hr, hc]

/-- A fixed raw value and plain meaning for each binding id; the obligation
applies only while that binding actually holds a holder. -/
def HoldingMeanings (m : Memory) (bs : List Binding)
    (raw : Nat → RawValue) (meaning : Nat → PlainValue) : Prop :=
  ∀ b ∈ bs, b.status = .holding →
    b.value = raw b.id ∧ readBack m b.value = .ok (meaning b.id)

/-- A fixed per-id meaning across snapshots implies the exact locked
first-holding definition, not merely equality between adjacent snapshots. -/
theorem names_of_meanings (o : Outcome) (raw : Nat → RawValue) (meaning : Nat → PlainValue)
    (h : ∀ sn ∈ o.states, HoldingMeanings (snapMemory sn) sn.bindings raw meaning) :
    NamesUnchanged o := by
  intro sn hsn b hb hs
  have hcurrent := h sn hsn b hb hs
  have hsnmatch : sn.bindings.any (fun d => d.id == b.id && d.status == .holding) = true :=
    List.any_eq_true.mpr ⟨b, hb, by simp [hs]⟩
  cases hf : firstHolding o.states b.id with
  | none =>
    have hn : ∀ sn ∈ o.states,
        ¬(sn.bindings.any (fun d => d.id == b.id && d.status == .holding)) = true :=
      List.find?_eq_none.mp hf
    exact False.elim (hn sn hsn hsnmatch)
  | some first =>
    have hfirstmem : first ∈ o.states := List.mem_of_find?_eq_some hf
    have hfirstmatch : first.bindings.any (fun d => d.id == b.id && d.status == .holding) = true :=
      List.find?_some (p := fun sn : Snapshot =>
        sn.bindings.any (fun d => d.id == b.id && d.status == .holding)) hf
    obtain ⟨d, hd, hds⟩ := List.any_eq_true.mp hfirstmatch
    simp only [Bool.and_eq_true, beq_iff_eq] at hds
    obtain ⟨hdi, hdh⟩ := hds
    obtain ⟨hdraw, hdmeaning⟩ := h first hfirstmem d hd hdh
    have hvalues : d.value = b.value := by rw [hdraw, hdi, hcurrent.1]
    have hfirst : readBack (snapMemory first) b.value = .ok (meaning b.id) := by
      simpa [hvalues, hdi] using hdmeaning
    simp [NameSteady, hf, hfirst, hcurrent.2, Except.toBool]

/-- Recording a snapshot retains all earlier per-id meanings and records the
current holding bindings with their current meanings. -/
theorem snapshot_names (s : RunState) (kind : StepKind) (bv : Option RawValue)
    (raw : Nat → RawValue) (meaning : Nat → PlainValue)
    (hpast : ∀ sn ∈ s.snaps, HoldingMeanings (snapMemory sn) sn.bindings raw meaning)
    (hnow : HoldingMeanings s.mem s.bindings raw meaning) :
    ∀ sn ∈ (snapshot kind bv s).2.snaps,
      HoldingMeanings (snapMemory sn) sn.bindings raw meaning := by
  intro sn hsn
  simp only [snapshot, m_bind_apply, m_get_apply, m_set_apply] at hsn
  rcases List.mem_append.mp hsn with hp | he
  · exact hpast sn hp
  · simp only [List.mem_cons, List.not_mem_nil, or_false] at he
    subst sn
    intro b hb hs
    obtain ⟨hraw, hm⟩ := hnow b (List.mem_filter.mp hb).1 hs
    refine ⟨hraw, ?_⟩
    exact (read_back_cells { cells := s.mem.cells } s.mem rfl b.value).trans hm

/-- Readable outside holders and fixed snapshot meanings imply both parts of
the locked visibility promise. The evaluator must establish these hypotheses. -/
theorem visible_of_meanings (s : Start) (o : Outcome)
    (raw : Nat → RawValue) (meaning : Nat → PlainValue)
    (hout : ∀ sn ∈ o.states, sn.outside = s.outside ∧
      ∀ r ∈ s.outside, readBack (snapMemory sn) (.list r) = readBack s.toMemory (.list r))
    (hread : ∀ r ∈ s.outside, (readBack s.toMemory (.list r)).toBool = true)
    (hnames : ∀ sn ∈ o.states, HoldingMeanings (snapMemory sn) sn.bindings raw meaning) :
    NoVisibleChange s o := by
  refine ⟨?_, names_of_meanings o raw meaning hnames⟩
  intro sn hsn
  obtain ⟨he, hr⟩ := hout sn hsn
  exact ⟨he, fun r hm => ⟨hr r hm, hread r hm⟩⟩

end Trial.Proofs
