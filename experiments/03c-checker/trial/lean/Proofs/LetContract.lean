import Proofs.LetSetup

namespace Trial.Proofs

/-- The complete let constructor composes the bound expression and body
through fresh-id binding, shadowing, holder transfer, and immediate cleanup. -/
theorem let_contract (name : String) (bound body : Expr)
    (hbound : EvalContract bound) (hbody : EvalContract body) : EvalContract (.letE name bound body) := by
  intro start g env plain fs enc k s h hl hf henv ht
  cases hcb : check (plain.map (fun p => (p.1, p.2.kind))) bound
  · simp [check, hcb] at ht
  rename_i kb
  simp [check, hcb] at ht
  have hlb : LiveFor s.bindings
      ({ text := bound, env := toFEnv env } :: { text := body, env := (name, none) :: toFEnv env } :: fs) :=
    hl.congr (fun _ => by simp [used_later_cons, usesBinding, Bool.or_assoc])
  have hplaceholder : ∀ x id, (x, some id) ∈ (name, none) :: toFEnv env → id < s.nextBinding := by
    intro x id hi
    exact hf.head x id (by simpa using hi)
  have hfb := (hf.tail.prepend body _ hplaceholder).prepend bound _ hf.head
  obtain ⟨u, g1, rb, vb, hb⟩ := hbound start g env plain
    ({ text := body, env := (name, none) :: toFEnv env } :: fs) enc kb s h hlb hfb henv hcb
  obtain ⟨w, hsetup, hsw, hlw, hbw, hbrw, hrw, hpw, hsnw, hsavew⟩ :=
    let_setup_contract hb.state name rb vb body env fs s.pending hb.pending hb.read hb.live hb.frames.tail
  let env' := (name, u.nextBinding) :: env
  let g' := boundMeanings g1 u.nextBinding rb vb
  have hi : ∀ p ∈ env, p.2 < u.nextBinding :=
    fun p hp => Nat.lt_of_lt_of_le (hf.env p hp) hb.bindingsGrow
  have hlookup : EnvMeaning env' ((name, vb) :: plain) g' :=
    (henv.extend hb.meanings hf.env).bind name u.nextBinding rb vb hi
  have hfw : FramesBound w ({ text := body, env := toFEnv env' } :: fs) := by
    intro f hmem x id hid
    rw [hbw]
    rcases List.mem_cons.mp hmem with he | hm
    · subst f
      change (x, some id) ∈ (name, some u.nextBinding) :: toFEnv env at hid
      rcases List.mem_cons.mp hid with he | hm
      · have he' : id = u.nextBinding := by simpa using congrArg Prod.snd he
        rw [he']
        exact Nat.lt_succ_self _
      · obtain ⟨p, hp, he⟩ := List.mem_map.mp hm
        have he' : p.2 = id := by simpa using congrArg Prod.snd he
        rw [← he']
        exact Nat.lt_succ_of_lt (hi p hp)
    · exact Nat.lt_succ_of_lt (hb.frames.tail f hm x id hid)
  have htc : check (((name, vb) :: plain).map (fun p => (p.1, p.2.kind))) body = .ok k := by
    simpa [hb.kind] using ht
  obtain ⟨t, g2, raw, value, hout⟩ := hbody start g' env' ((name, vb) :: plain) fs enc k w
    hsw hlw hfw hlookup htc
  have hbw' : s.nextBinding ≤ w.nextBinding := by rw [hbw]; exact Nat.le_succ_of_le hb.bindingsGrow
  have hg' : ExtendsMeanings g g' s.nextBinding :=
    hb.meanings.trans (bound_meanings_extend g1 u.nextBinding rb vb) hb.bindingsGrow
  refine ⟨t, g2, raw, value, {
    run := ?_
    meaning := by simpa [eval, hb.meaning] using hout.meaning
    kind := hout.kind
    read := hout.read
    state := hout.state
    live := hout.live
    frames := hout.frames
    bindingsGrow := Nat.le_trans hbw' hout.bindingsGrow
    branchesGrow := Nat.le_trans hb.branchesGrow (by simpa [hbrw] using hout.branchesGrow)
    meanings := hg'.trans hout.meanings hbw'
    pending := by simpa [hpw] using hout.pending
    saved := ?_
    reservations := ?_
    snapshots := hb.snapshots.trans (hsnw.trans hout.snapshots) }⟩
  · rw [eval_let_setup, m_bind_apply, hb.run]
    dsimp only
    rw [m_bind_apply, hsetup]
    exact hout.run
  · intro v hv
    exact ((hout.saved v (by simpa [hpw] using hv)).trans (hsavew v hv)).trans (hb.saved v hv)
  · have hr : t.setAside.IsSuffix u.setAside := by simpa [hrw] using hout.reservations
    exact hr.trans hb.reservations

end Trial.Proofs
