import Proofs.CleanupContract

namespace Trial.Proofs

theorem used_env_id (e : Expr) (env : Env) (id : Nat)
    (h : usesBinding e (toFEnv env) id = true) : id ∈ env.map Prod.snd := by
  obtain ⟨x, hx⟩ := uses_binding_mem e (toFEnv env) id h
  obtain ⟨p, hp, he⟩ := List.mem_map.mp hx
  have hi : p.2 = id := by simpa using congrArg Prod.snd he
  exact List.mem_map.mpr ⟨p, hp, hi⟩

/-- Choosing a branch discards precisely the uses in the unchosen branch.
Every holder made dead by that choice is covered by the current environment. -/
theorem cleanup_selected {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (env : Env) (chosen discarded : Expr) (fs : List Frame)
    (hi : ∀ p ∈ env, p.2 < s.nextBinding)
    (hl : LiveFor s.bindings
      ({ text := chosen, env := toFEnv env } :: { text := discarded, env := toFEnv env } :: fs)) :
    ∃ t, giveUpDead Variant.approved env ({ text := chosen, env := toFEnv env } :: fs) s = (.ok (), t) ∧
      StateInvariant start g enc t ∧ LiveFor t.bindings ({ text := chosen, env := toFEnv env } :: fs) ∧
      ReleaseFrame s t ∧ t.pending = s.pending ∧
      (∀ v ∈ s.pending, readBack t.mem v = readBack s.mem v) := by
  apply cleanup_contract h env _ hi
  · intro b hb hv hu
    apply (hl b hb hv).mpr
    simp only [used_later_cons, Bool.or_eq_true] at hu ⊢
    rcases hu with hc | hf
    · exact Or.inl hc
    · exact Or.inr (Or.inr hf)
  · intro b hb hs hn
    have hwas := (hl b hb (h.holding b hb hs)).mp hs
    have hnot : usesBinding chosen (toFEnv env) b.id = false ∧ usedLater fs b.id = false := by
      simpa [used_later_cons] using hn
    have hd : usesBinding discarded (toFEnv env) b.id = true := by
      simpa [used_later_cons, hnot.1, hnot.2] using hwas
    exact used_env_id discarded env b.id hd

/-- Actual selected-branch composition, with cleanup between condition and
branch. Both outcomes carry all semantic, liveness, and history obligations. -/
theorem if_contract (c yes no : Expr) (hc : EvalContract c)
    (hy : EvalContract yes) (hn : EvalContract no) : EvalContract (.ifE c yes no) := by
  intro start g env plain fs enc k s h hl hf henv ht
  cases hcc : check (plain.map (fun p => (p.1, p.2.kind))) c
  · simp [check, hcc] at ht
  rename_i kc
  cases kc <;> simp [check, hcc, expectKind] at ht
  cases hcy : check (plain.map (fun p => (p.1, p.2.kind))) yes
  · simp [hcy] at ht
  rename_i ky
  cases hcn : check (plain.map (fun p => (p.1, p.2.kind))) no
  · simp [hcy, hcn] at ht
  rename_i kn
  by_cases hkn : ky = kn <;> simp [hcy, hcn, hkn] at ht
  subst kn
  subst k
  have hlc : LiveFor s.bindings
      ({ text := c, env := toFEnv env } :: { text := yes, env := toFEnv env } ::
        { text := no, env := toFEnv env } :: fs) :=
    hl.congr (fun _ => by simp [used_later_cons, usesBinding, Bool.or_assoc])
  have hfc := ((hf.tail.prepend no (toFEnv env) hf.head).prepend yes
    (toFEnv env) hf.head).prepend c (toFEnv env) hf.head
  obtain ⟨u, g1, rawc, vc, hcond⟩ := hc start g env plain
    ({ text := yes, env := toFEnv env } :: { text := no, env := toFEnv env } :: fs)
    enc .bool s h hlc hfc henv hcc
  have hkind := hcond.kind
  obtain ⟨b, hb⟩ : ∃ b, vc = .bool b := by
    cases vc <;> simp [PlainValue.kind] at hkind
    exact ⟨_, rfl⟩
  subst vc
  have hraw := read_back_bool hcond.read
  subst rawc
  let u0 : RunState := { u with scope := env.reverse.map Prod.snd }
  let u1 := (snapshot .branchChosen none u0).2
  have hsnap1 : snapshot .branchChosen none u0 = (.ok (), u1) := rfl
  have hsu1 : StateInvariant start g1 enc u1 :=
    (hcond.state.scope (env.reverse.map Prod.snd)).snapshot .branchChosen none
  have hlookup := henv.extend hcond.meanings hf.env
  have hi : ∀ p ∈ env, p.2 < u1.nextBinding := hcond.frames.env
  cases b
  · have hswap : LiveFor u1.bindings
        ({ text := no, env := toFEnv env } :: { text := yes, env := toFEnv env } :: fs) :=
      hcond.live.congr (fun _ => by simp [used_later_cons, Bool.or_left_comm])
    obtain ⟨u2, hclean, hs2, hl2, hr2, hp2, hv2⟩ := cleanup_selected hsu1 env no yes fs hi hswap
    let u3 : RunState := { u2 with scope := env.reverse.map Prod.snd }
    let u4 := (snapshot .branchStarts none u3).2
    have hsnap4 : snapshot .branchStarts none u3 = (.ok (), u4) := rfl
    have hs4 : StateInvariant start g1 enc u4 :=
      (hs2.scope (env.reverse.map Prod.snd)).snapshot .branchStarts none
    have hf4 : FramesBound u4 ({ text := no, env := toFEnv env } :: fs) := by
      intro f hmem x id hid
      change id < u2.nextBinding
      rw [hr2.bindingCounter]
      exact hcond.frames.tail f hmem x id hid
    obtain ⟨t, g2, raw, value, hbranch⟩ := hn start g1 env plain fs enc ky u4 hs4 hl2 hf4 hlookup hcn
    refine ⟨t, g2, raw, value, {
      run := by
        simp only [evalC, m_bind_apply, hcond.run, enter, m_modify_apply]
        rw [hsnap1]
        dsimp only
        rw [hclean]
        dsimp only
        rw [hsnap4]
        exact hbranch.run
      meaning := by simpa [eval, hcond.meaning] using hbranch.meaning
      kind := hbranch.kind
      read := hbranch.read
      state := hbranch.state
      live := hbranch.live
      frames := hbranch.frames
      bindingsGrow := ?_
      branchesGrow := ?_
      meanings := ?_
      pending := ?_
      saved := ?_
      reservations := ?_
      snapshots := ?_ }⟩
    · exact Nat.le_trans hcond.bindingsGrow (by simpa [u4, u3, snapshot, hr2.bindingCounter, u1, u0] using hbranch.bindingsGrow)
    · exact Nat.le_trans hcond.branchesGrow (by simpa [u4, u3, snapshot, hr2.branchCounter, u1, u0] using hbranch.branchesGrow)
    · exact hcond.meanings.trans hbranch.meanings (by simpa [u4, u3, snapshot, hr2.bindingCounter, u1, u0] using hcond.bindingsGrow)
    · simpa [u4, u3, snapshot, hp2, u1, u0, hcond.pending, pendingResult] using hbranch.pending
    · intro v hv
      have hvu1 : v ∈ u1.pending := by simpa [u1, u0, snapshot, hcond.pending, pendingResult] using hv
      have hvu4 : v ∈ u4.pending := by simpa [u4, u3, snapshot, hp2] using hvu1
      exact ((hbranch.saved v hvu4).trans (hv2 v hvu1)).trans (hcond.saved v hv)
    · have hr : t.setAside.IsSuffix u.setAside := by
        simpa [u4, u3, snapshot, hr2.stack, u1, u0] using hbranch.reservations
      exact hr.trans hcond.reservations
    · exact hcond.snapshots.trans ((snapshot_prefix u0 .branchChosen none).trans
        (hr2.snapshots.trans ((snapshot_prefix u3 .branchStarts none).trans hbranch.snapshots)))
  · obtain ⟨u2, hclean, hs2, hl2, hr2, hp2, hv2⟩ := cleanup_selected hsu1 env yes no fs hi hcond.live
    let u3 : RunState := { u2 with scope := env.reverse.map Prod.snd }
    let u4 := (snapshot .branchStarts none u3).2
    have hsnap4 : snapshot .branchStarts none u3 = (.ok (), u4) := rfl
    have hs4 : StateInvariant start g1 enc u4 :=
      (hs2.scope (env.reverse.map Prod.snd)).snapshot .branchStarts none
    have hf4 : FramesBound u4 ({ text := yes, env := toFEnv env } :: fs) := by
      intro f hmem x id hid
      change id < u2.nextBinding
      rw [hr2.bindingCounter]
      rcases List.mem_cons.mp hmem with he | hm
      · subst f; exact hcond.frames.head x id hid
      · exact hcond.frames.tail.tail f hm x id hid
    obtain ⟨t, g2, raw, value, hbranch⟩ := hy start g1 env plain fs enc ky u4 hs4 hl2 hf4 hlookup hcy
    refine ⟨t, g2, raw, value, {
      run := by
        simp only [evalC, m_bind_apply, hcond.run, enter, m_modify_apply]
        rw [hsnap1]
        dsimp only
        rw [hclean]
        dsimp only
        rw [hsnap4]
        exact hbranch.run
      meaning := by simpa [eval, hcond.meaning] using hbranch.meaning
      kind := hbranch.kind
      read := hbranch.read
      state := hbranch.state
      live := hbranch.live
      frames := hbranch.frames
      bindingsGrow := ?_
      branchesGrow := ?_
      meanings := ?_
      pending := ?_
      saved := ?_
      reservations := ?_
      snapshots := ?_ }⟩
    · exact Nat.le_trans hcond.bindingsGrow (by simpa [u4, u3, snapshot, hr2.bindingCounter, u1, u0] using hbranch.bindingsGrow)
    · exact Nat.le_trans hcond.branchesGrow (by simpa [u4, u3, snapshot, hr2.branchCounter, u1, u0] using hbranch.branchesGrow)
    · exact hcond.meanings.trans hbranch.meanings (by simpa [u4, u3, snapshot, hr2.bindingCounter, u1, u0] using hcond.bindingsGrow)
    · simpa [u4, u3, snapshot, hp2, u1, u0, hcond.pending, pendingResult] using hbranch.pending
    · intro v hv
      have hvu1 : v ∈ u1.pending := by simpa [u1, u0, snapshot, hcond.pending, pendingResult] using hv
      have hvu4 : v ∈ u4.pending := by simpa [u4, u3, snapshot, hp2] using hvu1
      exact ((hbranch.saved v hvu4).trans (hv2 v hvu1)).trans (hcond.saved v hv)
    · have hr : t.setAside.IsSuffix u.setAside := by
        simpa [u4, u3, snapshot, hr2.stack, u1, u0] using hbranch.reservations
      exact hr.trans hcond.reservations
    · exact hcond.snapshots.trans ((snapshot_prefix u0 .branchChosen none).trans
        (hr2.snapshots.trans ((snapshot_prefix u3 .branchStarts none).trans hbranch.snapshots)))

end Trial.Proofs
