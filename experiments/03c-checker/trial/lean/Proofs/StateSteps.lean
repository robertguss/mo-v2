import Proofs.Arithmetic

namespace Trial.Proofs

theorem StateInvariant.holding_meanings {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) :
    HoldingMeanings s.mem s.bindings (fun id => (g id).1) (fun id => (g id).2) :=
  fun b hb hs => ⟨h.raw b hb, h.readable b hb (Or.inl hs)⟩

/-- Scope controls which nonholding names a snapshot displays; it changes no
ownership, meaning, or historical obligation. -/
theorem StateInvariant.scope {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (scope : List Nat) :
    StateInvariant start g enc { s with scope := scope } := by
  exact { h with }

/-- Recording the current state preserves the full boundary invariant and
adds the current meanings and outside values to the historical obligations. -/
theorem StateInvariant.snapshot {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (kind : StepKind) (bv : Option RawValue) :
    StateInvariant start g enc (snapshot kind bv s).2 := by
  refine { h with
    history := snapshot_names s kind bv _ _ h.history h.holding_meanings
    historyBound := ?_
    outsideHistory := ?_ }
  · intro sn hsn
    rcases List.mem_append.mp hsn with hp | he
    · exact h.historyBound sn hp
    · have he' := List.mem_singleton.mp he
      subst sn
      intro b hb
      exact h.bound b (List.mem_filter.mp hb).1
  · intro sn hsn
    rcases List.mem_append.mp hsn with hp | he
    · exact h.outsideHistory sn hp
    · have he' := List.mem_singleton.mp he
      subst sn
      exact ⟨h.outside, fun r hr =>
        (read_back_cells { cells := s.mem.cells } s.mem rfl (.list r)).trans (h.outsideValues r hr)⟩

theorem snapshot_prefix (s : RunState) (kind : StepKind) (bv : Option RawValue) :
    s.snaps.IsPrefix (snapshot kind bv s).2.snaps := by
  exact ⟨_, rfl⟩

end Trial.Proofs
