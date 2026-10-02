import Proofs.BranchContract

namespace Trial.Proofs

theorem owned_pending_root (s : RunState) (v : RawValue) (hv : v ∈ s.pending) :
    valueRoot v ∈ ownedRoots s :=
  List.mem_append_left _ (List.mem_append_right _ (List.mem_map.mpr ⟨v, hv, rfl⟩))

theorem result_owned (s : RunState) (raw : RawValue) (rest : List RawValue)
    (hp : s.pending = pendingResult raw rest) :
    valueRoot raw = none ∨ valueRoot raw ∈ ownedRoots s := by
  cases raw with
  | num _ | bool _ => exact Or.inl rfl
  | list r => cases r with
    | none => exact Or.inl rfl
    | some a => exact Or.inr (owned_pending_root s _ (by simp [hp, pendingResult]))

/-- Full actual empty-list match composition: fresh branch, selected cleanup,
body evaluation, and branch finishing. The cell branch is not evaluated. -/
theorem match_nil_post (scrut nb cb : Expr) (headName tailName : String)
    (hn : EvalContract nb) (start : Start) (env : Env) (plain : List (String × PlainValue))
    (fs : List Frame) (enc : List Nat) (k : Kind) (s u : RunState) (g g1 : Meanings)
    (hs : EvalPost scrut start env plain
      ({ text := nb, env := toFEnv env } ::
        { text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs)
      enc .list s g u g1 (.list none) (.list []))
    (henv : EnvMeaning env plain g1)
    (hcheck : check (plain.map (fun p => (p.1, p.2.kind))) nb = .ok k) :
    ∃ t g2 raw value, EvalPost (.matchE scrut nb headName tailName cb)
      start env plain fs enc k s g t g2 raw value := by
  let u0 := { u with scope := env.reverse.map Prod.snd }
  let u1 := { u0 with nextBranch := u0.nextBranch + 1 }
  let u2 := (snapshot .branchChosen none u1).2
  have hs2 : StateInvariant start g1 (u.nextBranch :: enc) u2 :=
    ((hs.state.scope (env.reverse.map Prod.snd)).fresh_branch).snapshot .branchChosen none
  have hi : ∀ p ∈ env, p.2 < u2.nextBinding := hs.frames.env
  obtain ⟨u3, hclean, hs3, hl3, hfr, hp3, hsave3⟩ := cleanup_contract hs2 env
    ({ text := nb, env := toFEnv env } :: fs) hi
    (by
      intro b hb hv hu
      apply (hs.live b hb hv).mpr
      simp only [used_later_cons, Bool.or_eq_true] at hu ⊢
      rcases hu with hn | hf
      · exact Or.inl hn
      · exact Or.inr (Or.inr hf))
    (by
      intro b hb hhold hdead
      have hwas := (hs.live b hb (hs.state.holding b hb hhold)).mp hhold
      have hn : usesBinding nb (toFEnv env) b.id = false ∧ usedLater fs b.id = false := by
        simpa [used_later_cons] using hdead
      have hcb : usesBinding cb ((tailName, none) :: (headName, none) :: toFEnv env) b.id = true := by
        simpa [used_later_cons, hn.1, hn.2] using hwas
      obtain ⟨x, hx⟩ := uses_binding_mem cb _ b.id hcb
      have hx' : (x, some b.id) ∈ toFEnv env := by simpa using hx
      obtain ⟨p, hp, he⟩ := List.mem_map.mp hx'
      exact List.mem_map.mpr ⟨p, hp, by simpa using congrArg Prod.snd he⟩)
  let u4 := { u3 with scope := env.reverse.map Prod.snd }
  let u5 := (snapshot .branchStarts none u4).2
  have hs5 : StateInvariant start g1 (u.nextBranch :: enc) u5 := (hs3.scope _).snapshot .branchStarts none
  have hf5 : FramesBound u5 ({ text := nb, env := toFEnv env } :: fs) := by
    intro f hf x id hid
    change id < u3.nextBinding
    rw [hfr.bindingCounter]
    rcases List.mem_cons.mp hf with he | hm
    · subst f; exact hs.frames.head x id hid
    · exact hs.frames.tail.tail f hm x id hid
  obtain ⟨v, g2, raw, value, hv⟩ := hn start g1 env plain fs (u.nextBranch :: enc) k u5
    hs5 hl3 hf5 henv hcheck
  obtain ⟨t, hfinish, hst, hstack, hbind, hpend, hnb, hnbr, hsn, hread⟩ :=
    finish_branch_contract u.nextBranch hv.state env env raw
  have hp5 : u5.pending = s.pending := by
    simp [u5, u4, snapshot, hp3, u2, u1, u0, hs.pending, pendingResult]
  have hnb5 : u5.nextBinding = u.nextBinding := hfr.bindingCounter
  have hbr5 : u5.nextBranch = u.nextBranch + 1 := hfr.branchCounter
  refine ⟨t, g2, raw, value, {
    run := ?_
    meaning := by simpa [eval, hs.meaning] using hv.meaning
    kind := hv.kind
    read := (hread raw (result_owned v raw u5.pending hv.pending)).trans hv.read
    state := hst
    live := by simpa [hbind] using hv.live
    frames := by simpa [FramesBound, hnb] using hv.frames
    bindingsGrow := by rw [hnb]; exact Nat.le_trans hs.bindingsGrow (by simpa [hnb5] using hv.bindingsGrow)
    branchesGrow := by rw [hnbr]; exact Nat.le_trans hs.branchesGrow (Nat.le_trans (Nat.le_succ _) (by simpa [hbr5] using hv.branchesGrow))
    meanings := hs.meanings.trans hv.meanings (by simpa [hnb5] using hs.bindingsGrow)
    pending := by simpa [hpend, hp5] using hv.pending
    saved := ?_
    reservations := ?_
    snapshots := hs.snapshots.trans ((snapshot_prefix u1 .branchChosen none).trans
      (hfr.snapshots.trans ((snapshot_prefix u4 .branchStarts none).trans (hv.snapshots.trans hsn)))) }⟩
  · have hbranch : freshBranch u0 = (.ok u.nextBranch, u1) := rfl
    have hsnap2 : snapshot .branchChosen none u1 = (.ok (), u2) := rfl
    have hsnap5 : snapshot .branchStarts none u4 = (.ok (), u5) := rfl
    simp only [evalC, m_bind_apply, hs.run, enter, m_modify_apply]
    rw [hbranch]
    dsimp only
    rw [hsnap2]
    dsimp only
    rw [hclean]
    dsimp only
    rw [hsnap5]
    dsimp only
    rw [hv.run]
    exact hfinish
  · intro w hw
    have hw2 : w ∈ u2.pending := by simpa [u2, u1, u0, snapshot, hs.pending, pendingResult] using hw
    have hw5 : w ∈ u5.pending := by simpa [hp5] using hw
    have hwv : w ∈ v.pending := by
      rw [hv.pending]
      cases raw with
      | num _ | bool _ => exact hw5
      | list r => cases r <;> simp [pendingResult, hw5]
    exact ((hread w (Or.inr (owned_pending_root v w hwv))).trans
      ((hv.saved w hw5).trans (hsave3 w hw2))).trans (hs.saved w hw)
  · have ht : t.setAside.IsSuffix u.setAside := by
      have hh := hstack.trans hv.reservations
      simpa [u5, u4, snapshot, hfr.stack, u2, u1, u0] using hh
    exact ht.trans hs.reservations

end Trial.Proofs
