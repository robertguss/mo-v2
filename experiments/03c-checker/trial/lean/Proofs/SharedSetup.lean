import Proofs.ExclusiveSetup

namespace Trial.Proofs

def sharedSetup (a : Addr) (c : Cell) (headName tailName : String) (cb : Expr) (env : Env) : M Env := do
  let hid ← newBinding headName (.num c.item) .noHolder
  let tid ← newBinding tailName (.list c.link) .noHolder
  let env' := (tailName, tid) :: (headName, hid) :: env
  (match c.link with
   | some r => if usesBinding cb (toFEnv env') tid then do
       addHolder r
       setBindingStatus tid .holding
       enter env'
       snapshot .newHolder
     else pure ()
   | none => pure () : M Unit)
  (do popPending (.list (some a)); giveUpLink Variant.approved (some a) : M Unit)
  enter env'
  snapshot .matchStep4Done
  enter env'
  snapshot .branchStarts
  pure env'

/-- Shared setup copies the tail only when it will be used, releases the
match holder, and establishes exact liveness before entering the cell branch. -/
theorem shared_setup_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (a : Addr) (c : Cell)
    (headName tailName : String) (cb : Expr) (env : Env) (fs : List Frame)
    (rest : List RawValue) (items : List Int)
    (hc : s.mem.find? a = some c)
    (hp : s.pending = .list (some a) :: rest)
    (hr : readBack s.mem (.list c.link) = .ok (.list items)) (hf : FramesBound s fs)
    (hl : LiveFor s.bindings ({ text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs)) :
    ∃ t, sharedSetup a c headName tailName cb env s =
        (.ok ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env), t) ∧
      StateInvariant start (matchMeanings g s.nextBinding c.item c.link items) enc t ∧
      LiveFor t.bindings ({ text := cb, env := toFEnv ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env) } :: fs) ∧
      t.nextBinding = s.nextBinding + 2 ∧ t.nextBranch = s.nextBranch ∧
      t.pending = rest ∧ t.setAside = s.setAside ∧
      s.snaps.IsPrefix t.snaps ∧ (∀ v ∈ rest, readBack t.mem v = readBack s.mem v) := by
  let tid := s.nextBinding + 1
  let env' := (tailName, tid) :: (headName, s.nextBinding) :: env
  let g' := matchMeanings g s.nextBinding c.item c.link items
  let u := matchBindings s headName tailName c.item c.link
  let b : Binding := { id := tid, name := tailName, value := .list c.link, status := .noHolder }
  have hu : StateInvariant start g' enc u := match_bindings_state h headName tailName c.item c.link items hr
  have hbmem : b ∈ u.bindings := by simp [b, u, matchBindings, tid]
  have hb : u.bindings.find? (fun q => q.id == tid) = some b := binding_find_self _ hu.unique b hbmem
  have hread : readBack u.mem (.list c.link) = .ok (g' tid).2 := by
    simpa [u, matchBindings, g', matchMeanings, boundMeanings, tid] using hr
  let tailBindings (status : BStatus) := s.bindings ++
    [{ id := s.nextBinding, name := headName, value := .num c.item, status := .noHolder },
     { id := tid, name := tailName, value := .list c.link, status := status }]
  have hbase : ∀ status, (∀ r, c.link = some r → (status = .holding ↔ usesBinding cb (toFEnv env') tid = true)) →
      LiveFor (tailBindings status) ({ text := cb, env := toFEnv env' } :: fs) := by
    intro status ht
    exact match_bindings_live s env cb fs headName tailName c.item c.link status h.bound hf hl ht
  have hnext : ∃ v,
      (match c.link with
       | some r => if usesBinding cb (toFEnv env') tid then do
           addHolder r
           setBindingStatus tid .holding
           enter env'
           snapshot .newHolder
         else pure ()
       | none => pure () : M Unit) u = (.ok (), v) ∧
      StateInvariant start g' enc v ∧ LiveFor v.bindings ({ text := cb, env := toFEnv env' } :: fs) ∧
      v.nextBinding = u.nextBinding ∧ v.nextBranch = u.nextBranch ∧
      v.pending = u.pending ∧ v.setAside = u.setAside ∧ u.snaps.IsPrefix v.snaps ∧
      (∀ x, readBack v.mem x = readBack u.mem x) := by
    cases hlink : c.link with
    | none =>
      exact ⟨u, rfl, hu, hbase .noHolder (by simp [hlink]), rfl, rfl, rfl, rfl, ⟨[], by simp⟩, fun _ => rfl⟩
    | some r =>
      cases hused : usesBinding cb (toFEnv env') tid with
      | false =>
        exact ⟨u, by simp, hu, hbase .noHolder (by simp [hused]), rfl, rfl, rfl, rfl, ⟨[], by simp⟩, fun _ => rfl⟩
      | true =>
        have hroot : some a ∈ ownedRoots s := by
          simpa [valueRoot] using owned_pending_root s (.list (some a)) (by simp [hp])
        obtain ⟨cs, hpath⟩ := h.owned.readable (some a) hroot
        obtain ⟨d, ds, _, hd, _, _, htail⟩ := hpath.head
        have hdc : d = c := Option.some.inj (hd.symm.trans hc)
        subst d
        have htail' : ListPath s.mem (some r) ds := by simpa [hlink] using htail
        obtain ⟨cr, rs, _, hcr, _, hcrl, _⟩ := htail'.head
        obtain ⟨v0, hv0, hsv0, hbs, hps, hrs, hnbs, hbrs, hsns, hsave⟩ :=
          activate_tail_contract hu tid b r cr hb rfl (by simp [b, hlink]) hcr hcrl (by simpa [hlink] using hread)
        let v1 : RunState := { v0 with scope := env'.reverse.map Prod.snd }
        let v := (snapshot .newHolder none v1).2
        have hmaps : u.bindings.map (fun q => if q.id == tid then { q with status := .holding } else q) = tailBindings .holding := by
          have hnone : ∀ q ∈ s.bindings, q.id ≠ tid := by
            intro q hq
            have hi := h.bound q hq
            dsimp [tid]
            omega
          simp only [u, matchBindings, List.map_append]
          rw [status_update_absent s.bindings tid .holding hnone]
          simp [tailBindings, tid]
        refine ⟨v, ?_, (hsv0.scope _).snapshot .newHolder none, ?_, hnbs, hbrs, hps, hrs,
          ?_, hsave⟩
        · simp only [ite_true]
          have heq : (do addHolder r; setBindingStatus tid .holding; enter env'; snapshot .newHolder : M Unit) =
              ((do addHolder r; setBindingStatus tid .holding : M Unit) >>= fun _ => do enter env'; snapshot .newHolder) := by
            simp [bind_assoc]
          rw [heq, m_bind_apply, hv0]
          rfl
        · change LiveFor v0.bindings _
          rw [hbs, hmaps]
          exact hbase .holding (by simp [hused])
        · rw [← hsns]
          exact snapshot_prefix v1 .newHolder none
  obtain ⟨v, hv, hsv, hlv, hnbv, hbrv, hpv, hrv, hsnv, hsavev⟩ := hnext
  obtain ⟨w, hw, hsw, hbw, hpw, hfw, hsavew⟩ := release_pending_contract hsv a rest (hpv.trans hp)
  let w1 : RunState := { w with scope := env'.reverse.map Prod.snd }
  let w2 := (snapshot .matchStep4Done none w1).2
  let w3 : RunState := { w2 with scope := env'.reverse.map Prod.snd }
  let t := (snapshot .branchStarts none w3).2
  have hsw2 : StateInvariant start g' enc w2 := (hsw.scope _).snapshot .matchStep4Done none
  refine ⟨t, ?_, (hsw2.scope _).snapshot .branchStarts none,
    (by change LiveFor w.bindings _; rw [hbw]; exact hlv),
    hfw.bindingCounter.trans hnbv, hfw.branchCounter.trans hbrv, hpw, hfw.stack.trans hrv,
    hsnv.trans (hfw.snapshots.trans ((snapshot_prefix w1 .matchStep4Done none).trans
      (snapshot_prefix w3 .branchStarts none))), fun x hx => (hsavew x hx).trans (hsavev x)⟩
  simp only [sharedSetup, newBinding, m_bind_apply, m_get_apply, m_set_apply, m_pure_apply]
  have hstate :
      { s with
        bindings := (s.bindings ++ [{ id := s.nextBinding, name := headName, value := .num c.item, status := .noHolder }]) ++
          [{ id := s.nextBinding + 1, name := tailName, value := .list c.link, status := .noHolder }]
        nextBinding := s.nextBinding + 1 + 1 } = u := by simp [u, matchBindings, List.append_assoc]
  rw [hstate, hv]
  dsimp only
  have hw' := hw
  rw [m_bind_apply] at hw'
  rw [hw']
  rfl

end Trial.Proofs
