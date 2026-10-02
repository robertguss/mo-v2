import Proofs.MatchSetup

namespace Trial.Proofs

/-- Nonempty match follows the actual ordering: inspect, choose, clean up,
inspect again, set up the selected body, evaluate it, then finish. In
particular, the exclusive/shared decision uses the post-cleanup cell. -/
theorem match_cell_post (scrut nb cb : Expr) (headName tailName : String)
    (hb : EvalContract cb) (start : Start) (env : Env) (plain : List (String × PlainValue))
    (fs : List Frame) (enc : List Nat) (k : Kind) (s u : RunState) (g g1 : Meanings)
    (a : Addr) (items : List Int)
    (hs : EvalPost scrut start env plain
      ({ text := nb, env := toFEnv env } ::
        { text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs)
      enc .list s g u g1 (.list (some a)) (.list items))
    (henv : EnvMeaning env plain g1)
    (hcheck : check ((tailName, .list) :: (headName, .number) ::
      plain.map (fun p => (p.1, p.2.kind))) cb = .ok k) :
    ∃ t g2 raw value, EvalPost (.matchE scrut nb headName tailName cb)
      start env plain fs enc k s g t g2 raw value := by
  let u0 : RunState := { u with scope := env.reverse.map Prod.snd }
  let u1 : RunState := { u0 with nextBranch := u0.nextBranch + 1 }
  let u2 := (snapshot .branchChosen none u1).2
  have hpu : .list (some a) ∈ u.pending := by simp [hs.pending, pendingResult]
  have hroot : some a ∈ ownedRoots u := owned_pending_root u _ hpu
  obtain ⟨cs0, hpath0⟩ := hs.state.owned.readable _ hroot
  obtain ⟨c0, ds0, _, hc0, _, hcl0, _⟩ := hpath0.head
  have hget0 : getLiveCell a u0 = (.ok c0, u0) := by
    simp [getLiveCell, getCell, u0, hc0, hcl0]
  have hs2 : StateInvariant start g1 (u.nextBranch :: enc) u2 :=
    ((hs.state.scope (env.reverse.map Prod.snd)).fresh_branch).snapshot .branchChosen none
  have hi : ∀ p ∈ env, p.2 < u2.nextBinding := hs.frames.env
  obtain ⟨u3, hclean, hs3, hl3, hfr, hp3, hsave3⟩ :=
    cleanup_match_cell hs2 env nb cb headName tailName fs hi hs.live
  have hp2 : u2.pending = .list (some a) :: s.pending := hs.pending
  have hp3' : u3.pending = .list (some a) :: s.pending := hp3.trans hp2
  have hread3 : readBack u3.mem (.list (some a)) = .ok (.list items) :=
    (hsave3 _ (by simp [hp2])).trans hs.read
  have hroot3 : some a ∈ ownedRoots u3 := owned_pending_root u3 (.list (some a)) (by simp [hp3'])
  obtain ⟨cs, hpath⟩ := hs3.owned.readable _ hroot3
  obtain ⟨c, ds, hcs, hc, _, hcl, htail⟩ := hpath.head
  have hitems : items = c.item :: ds.map Cell.item := by
    have he := hread3.symm.trans hpath.read_back
    simpa [hcs] using he
  have hget3 : getLiveCell a u3 = (.ok c, u3) := by
    simp [getLiveCell, getCell, hc, hcl]
  have hi3 : ∀ p ∈ env, p.2 < u3.nextBinding := by
    simpa [hfr.bindingCounter] using hi
  have hf3 : FramesBound u3 fs := by
    simpa [FramesBound, hfr.bindingCounter, u2, u1, u0, snapshot] using hs.frames.tail.tail
  have ho3 : (u3.setAside.map Prod.fst).Sublist enc := by
    simpa [hfr.stack, u2, u1, u0, snapshot] using hs.state.ordered
  obtain ⟨w, hsetup, hsw, hlw, hbw, hbrw, hpw, hrw, hsnw, hsavew⟩ :=
    match_cell_setup_contract u.nextBranch hs3 a c headName tailName cb env fs s.pending
      (ds.map Cell.item) hc hcl hp3' htail.read_back ho3 hf3 hl3
  let env' := (tailName, u3.nextBinding + 1) :: (headName, u3.nextBinding) :: env
  let plain' := (tailName, PlainValue.list (ds.map Cell.item)) :: (headName, PlainValue.num c.item) :: plain
  let g' := matchMeanings g1 u3.nextBinding c.item c.link (ds.map Cell.item)
  have henv' : EnvMeaning env' plain' g' :=
    henv.match_bindings headName tailName u3.nextBinding c.item c.link (ds.map Cell.item) hi3
  have hfw : FramesBound w ({ text := cb, env := toFEnv env' } :: fs) :=
    match_frames_bound u3 env cb fs headName tailName hi3 hf3 w hbw
  have hcheck' : check (plain'.map (fun p => (p.1, p.2.kind))) cb = .ok k := by
    simpa [plain', PlainValue.kind] using hcheck
  obtain ⟨v, g2, raw, value, hv⟩ := hb start g' env' plain' fs (u.nextBranch :: enc) k w
    hsw hlw hfw henv' hcheck'
  obtain ⟨t, hfinish, hst, hstack, hbind, hpend, hnb, hnbr, hsn, hread⟩ :=
    finish_branch_contract u.nextBranch hv.state env' env raw
  have hnb3 : u3.nextBinding = u.nextBinding := hfr.bindingCounter
  have hbr3 : u3.nextBranch = u.nextBranch + 1 := hfr.branchCounter
  have hbw' : s.nextBinding ≤ w.nextBinding := by
    rw [hbw, hnb3]
    exact Nat.le_trans hs.bindingsGrow (Nat.le_add_right _ _)
  have hg' : ExtendsMeanings g g' s.nextBinding :=
    hs.meanings.trans (match_meanings_extend g1 u3.nextBinding c.item c.link (ds.map Cell.item))
      (by rw [hnb3]; exact hs.bindingsGrow)
  refine ⟨t, g2, raw, value, {
    run := ?_
    meaning := by simpa [eval, hs.meaning, hitems, plain'] using hv.meaning
    kind := hv.kind
    read := (hread raw (result_owned v raw w.pending hv.pending)).trans hv.read
    state := hst
    live := by simpa [hbind] using hv.live
    frames := by simpa [FramesBound, hnb] using hv.frames
    bindingsGrow := by rw [hnb]; exact Nat.le_trans hbw' hv.bindingsGrow
    branchesGrow := by
      rw [hnbr]
      exact Nat.le_trans hs.branchesGrow (Nat.le_trans (Nat.le_succ _)
        (by simpa [hbrw, hbr3] using hv.branchesGrow))
    meanings := hg'.trans hv.meanings hbw'
    pending := by simpa [hpend, hpw] using hv.pending
    saved := ?_
    reservations := ?_
    snapshots := hs.snapshots.trans ((snapshot_prefix u1 .branchChosen none).trans
      (hfr.snapshots.trans (hsnw.trans (hv.snapshots.trans hsn)))) }⟩
  · have hbranch : freshBranch u0 = (.ok u.nextBranch, u1) := rfl
    have hsnap2 : snapshot .branchChosen none u1 = (.ok (), u2) := rfl
    rw [eval_match_setup]
    simp only [m_bind_apply, hs.run, enter, m_modify_apply]
    rw [hget0]
    dsimp only
    rw [hbranch]
    dsimp only
    rw [hsnap2]
    dsimp only
    rw [hclean]
    dsimp only
    rw [hget3]
    dsimp only
    rw [hsetup]
    dsimp only
    rw [hv.run]
    exact hfinish
  · intro x hx
    have hx2 : x ∈ u2.pending := by simp [hp2, hx]
    have hxw : x ∈ w.pending := by simpa [hpw] using hx
    have hxv : x ∈ v.pending := by
      rw [hv.pending]
      cases raw with
      | num _ | bool _ => exact hxw
      | list r => cases r <;> simp [pendingResult, hxw]
    exact ((hread x (Or.inr (owned_pending_root v x hxv))).trans
      ((hv.saved x hxw).trans ((hsavew x hx).trans (hsave3 x hx2)))).trans (hs.saved x hx)
  · have ht : t.setAside.IsSuffix u3.setAside := by
      have hh := hstack.trans hv.reservations
      rw [hrw] at hh
      split at hh
      · apply suffix_without_new_head u.nextBranch a u3.setAside t.setAside hh
        intro hm
        have hin := hst.ordered.subset hm
        exact (List.nodup_cons.mp hs2.branches).1 hin
      · exact hh
    have ht' : t.setAside.IsSuffix u.setAside := by
      simpa [hfr.stack, u2, u1, u0, snapshot] using ht
    exact ht'.trans hs.reservations

end Trial.Proofs
