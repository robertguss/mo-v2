import Proofs.Induction

namespace Trial.Proofs

/-- All five numeric constructors compose the same strengthened induction
hypotheses through the actual left-to-right counted evaluator. -/
theorem numeric_contracts (a b : Expr) (ha : EvalContract a) (hb : EvalContract b) :
    EvalContract (.add a b) ∧ EvalContract (.sub a b) ∧ EvalContract (.eq a b) ∧
      EvalContract (.lt a b) ∧ EvalContract (.le a b) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  all_goals
    intro start g env plain fs enc k s h hl hf henv ht
    cases hca : check (plain.map (fun p => (p.1, p.2.kind))) a
    · simp [check, hca] at ht
    rename_i ka
    cases ka <;> simp [check, hca, expectKind] at ht
  all_goals
    cases hcb : check (plain.map (fun p => (p.1, p.2.kind))) b
    · simp [hcb] at ht
    rename_i kb
    cases kb <;> simp [hcb] at ht
  all_goals
    subst k
    have hleft : LiveFor s.bindings
        ({ text := a, env := toFEnv env } :: { text := b, env := toFEnv env } :: fs) :=
      hl.congr (fun _ => by simp [usedLater, usesBinding, Bool.or_assoc])
    have hleftBound := (hf.tail.prepend b (toFEnv env) hf.head).prepend a (toFEnv env) hf.head
    obtain ⟨u, g1, rawx, vx, hx⟩ := ha start g env plain
      ({ text := b, env := toFEnv env } :: fs) enc .number s h hleft hleftBound henv hca
    have hkindx := hx.kind
    obtain ⟨x, hxv⟩ : ∃ x, vx = .num x := by
      cases vx <;> simp [PlainValue.kind] at hkindx
      exact ⟨_, rfl⟩
    subst vx
    have hrawx := read_back_number hx.read
    subst rawx
    have henv1 := henv.extend hx.meanings hf.env
    obtain ⟨t, g2, rawy, vy, hy⟩ := hb start g1 env plain fs enc .number u
      hx.state hx.live hx.frames henv1 hcb
    have hkindy := hy.kind
    obtain ⟨y, hyv⟩ : ∃ y, vy = .num y := by
      cases vy <;> simp [PlainValue.kind] at hkindy
      exact ⟨_, rfl⟩
    subst vy
    have hrawy := read_back_number hy.read
    subst rawy
    refine ⟨t, g2, _, _, {
      run := by simp [evalC, hx.run, hy.run, numOp]; rfl
      meaning := by simp [eval, hx.meaning, hy.meaning]; rfl
      kind := rfl
      read := rfl
      state := hy.state
      live := hy.live
      frames := hy.frames
      bindingsGrow := Nat.le_trans hx.bindingsGrow hy.bindingsGrow
      branchesGrow := Nat.le_trans hx.branchesGrow hy.branchesGrow
      meanings := hx.meanings.trans hy.meanings hx.bindingsGrow
      pending := by
        have px : u.pending = s.pending := hx.pending
        have py : t.pending = u.pending := hy.pending
        exact py.trans px
      saved := ?_
      reservations := hy.reservations.trans hx.reservations
      snapshots := hx.snapshots.trans hy.snapshots }⟩
    intro v hv
    have hv' : v ∈ u.pending := by rw [hx.pending]; exact hv
    exact (hy.saved v hv').trans (hx.saved v hv)

end Trial.Proofs
