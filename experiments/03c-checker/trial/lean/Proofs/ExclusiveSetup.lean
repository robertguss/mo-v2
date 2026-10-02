import Proofs.MatchLiveness

namespace Trial.Proofs

def exclusiveSetup (bid a : Nat) (c : Cell) (headName tailName : String) (cb : Expr) (env : Env) : M Env := do
  let hid ← newBinding headName (.num c.item) .noHolder
  let tid ← newBinding tailName (.list c.link) .noHolder
  let env' := (tailName, tid) :: (headName, hid) :: env
  reserveAction a c bid tid
  enter env'
  snapshot .matchStep4Done
  (match c.link with
   | some _ => if !(usesBinding cb (toFEnv env') tid) then giveUpBinding Variant.approved tid else pure ()
   | none => pure () : M Unit)
  enter env'
  snapshot .branchStarts
  pure env'

/-- Exclusive match setup composes fresh bindings, reservation, tail transfer,
unused-tail release, and both snapshots before the selected body runs. -/
theorem exclusive_setup_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (bid : Nat) (h : StateInvariant start g (bid :: enc) s) (a : Addr) (c : Cell)
    (headName tailName : String) (cb : Expr) (env : Env) (fs : List Frame)
    (rest : List RawValue) (items : List Int)
    (hc : s.mem.find? a = some c) (hcl : c.status = .live) (hcount : c.count = 1)
    (hp : s.pending = .list (some a) :: rest)
    (hr : readBack s.mem (.list c.link) = .ok (.list items))
    (ho : (s.setAside.map Prod.fst).Sublist enc) (hf : FramesBound s fs)
    (hl : LiveFor s.bindings ({ text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs)) :
    ∃ t, exclusiveSetup bid a c headName tailName cb env s =
        (.ok ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env), t) ∧
      StateInvariant start (matchMeanings g s.nextBinding c.item c.link items) (bid :: enc) t ∧
      LiveFor t.bindings ({ text := cb, env := toFEnv ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env) } :: fs) ∧
      t.nextBinding = s.nextBinding + 2 ∧ t.nextBranch = s.nextBranch ∧
      t.pending = rest ∧ t.setAside = (bid, a) :: s.setAside ∧
      s.snaps.IsPrefix t.snaps ∧ (∀ v ∈ rest, readBack t.mem v = readBack s.mem v) := by
  let tid := s.nextBinding + 1
  let env' := (tailName, tid) :: (headName, s.nextBinding) :: env
  let g' := matchMeanings g s.nextBinding c.item c.link items
  let u := matchBindings s headName tailName c.item c.link
  let b : Binding := { id := tid, name := tailName, value := .list c.link, status := .noHolder }
  have hu : StateInvariant start g' (bid :: enc) u := match_bindings_state h headName tailName c.item c.link items hr
  have hbmem : b ∈ u.bindings := by simp [b, u, matchBindings, tid]
  have hb : u.bindings.find? (fun q => q.id == tid) = some b := binding_find_self _ hu.unique b hbmem
  have hread : readBack u.mem (.list c.link) = .ok (g' tid).2 := by
    simpa [u, matchBindings, g', matchMeanings, boundMeanings, tid] using hr
  let v := reservedState u a c bid tid rest
  have hv : StateInvariant start g' (bid :: enc) v := reserve_contract bid hu a c tid b rest hc hcl hcount hb rfl rfl hp hread ho
  have hres := reserve_action_run u a c bid tid rest hc hp
  have hsave := reserve_action_saved u a c bid tid b rest hu.owned hu.unique hc hcl hcount hb rfl rfl hp
  let v1 : RunState := { v with scope := env'.reverse.map Prod.snd }
  let v2 := (snapshot .matchStep4Done none v1).2
  have hs2 : StateInvariant start g' (bid :: enc) v2 := (hv.scope _).snapshot .matchStep4Done none
  have hbound (q : Binding) (hq : q ∈ s.bindings) : q.id ≠ tid := by
    have hb := h.bound q hq
    dsimp [tid]
    omega
  have hmap (status : BStatus) : s.bindings.map
      (fun q => if q.id == tid then { q with status := status } else q) = s.bindings :=
    status_update_absent s.bindings tid status hbound
  let tailBindings (status : BStatus) := s.bindings ++
    [{ id := s.nextBinding, name := headName, value := .num c.item, status := .noHolder },
     { id := tid, name := tailName, value := .list c.link, status := status }]
  have hstatus (status old : BStatus) : (tailBindings old).map
      (fun q => if q.id == tid then { q with status := status } else q) = tailBindings status := by
    simp only [tailBindings, List.map_append]
    rw [hmap]
    simp [tid]
  have hbs2 : v2.bindings = match c.link with
      | none => tailBindings .noHolder | some _ => tailBindings .holding := by
    cases hlink : c.link with
    | none => simp [v2, v1, v, reservedState, u, matchBindings, snapshot, hlink, tailBindings, tid]
    | some r =>
      change (reservedState u a c bid tid rest).bindings = _
      simp only [reservedState, hlink]
      exact hstatus .holding .noHolder
  have hbase : ∀ status, (∀ r, c.link = some r → (status = .holding ↔ usesBinding cb (toFEnv env') tid = true)) →
      LiveFor (tailBindings status) ({ text := cb, env := toFEnv env' } :: fs) := by
    intro status ht
    exact match_bindings_live s env cb fs headName tailName c.item c.link status h.bound hf hl ht
  have hnext : ∃ w,
      (match c.link with
       | some _ => if !(usesBinding cb (toFEnv env') tid) then giveUpBinding Variant.approved tid else pure ()
       | none => pure () : M Unit) v2 = (.ok (), w) ∧
      StateInvariant start g' (bid :: enc) w ∧ LiveFor w.bindings ({ text := cb, env := toFEnv env' } :: fs) ∧
      w.nextBinding = v2.nextBinding ∧ w.nextBranch = v2.nextBranch ∧
      w.pending = rest ∧ w.setAside = v2.setAside ∧ v2.snaps.IsPrefix w.snaps ∧
      (∀ x ∈ rest, readBack w.mem x = readBack v2.mem x) := by
    cases hlink : c.link with
    | none =>
      refine ⟨v2, rfl, hs2, ?_, rfl, rfl, rfl, rfl, ⟨[], by simp⟩, fun _ _ => rfl⟩
      rw [hbs2, hlink]
      exact hbase .noHolder (by simp [hlink])
    | some r =>
      cases hused : usesBinding cb (toFEnv env') tid with
      | true =>
        refine ⟨v2, by simp, hs2, ?_, rfl, rfl, rfl, rfl, ⟨[], by simp⟩, fun _ _ => rfl⟩
        rw [hbs2, hlink]
        exact hbase .holding (by simp [hused])
      | false =>
        let b' : Binding := { b with status := .holding }
        have hb' : b' ∈ v2.bindings := by simp [hbs2, hlink, tailBindings, b', b]
        have hf' : v2.bindings.find? (fun q => q.id == tid) = some b' := binding_find_self _ hs2.unique b' hb'
        obtain ⟨w, hw, hsw, hbw, hpw, hfw, hsavew⟩ :=
          release_binding_contract hs2 tid b' r hf' rfl (by simp [b', b, hlink])
        refine ⟨w, by simp [hw], hsw, ?_, hfw.bindingCounter, hfw.branchCounter, hpw,
          hfw.stack, hfw.snapshots, hsavew⟩
        rw [hbw, hbs2]
        simp only [hlink]
        rw [hstatus]
        exact hbase .givenUp (by simp [hused])
  obtain ⟨w, hw, hsw, hlw, hnb, hnbr, hpw, hrw, hsnw, hsavew⟩ := hnext
  let w1 : RunState := { w with scope := env'.reverse.map Prod.snd }
  let t := (snapshot .branchStarts none w1).2
  refine ⟨t, ?_, (hsw.scope _).snapshot .branchStarts none, hlw,
    hnb, hnbr, hpw, hrw,
    (snapshot_prefix v1 .matchStep4Done none).trans (hsnw.trans (snapshot_prefix w1 .branchStarts none)),
    fun x hx => (hsavew x hx).trans (hsave x hx)⟩
  have hsnap2 : snapshot .matchStep4Done none v1 = (.ok (), v2) := rfl
  simp only [exclusiveSetup, newBinding, m_bind_apply, m_get_apply, m_set_apply, m_pure_apply]
  have hstate :
      { s with
        bindings := (s.bindings ++ [{ id := s.nextBinding, name := headName, value := .num c.item, status := .noHolder }]) ++
          [{ id := s.nextBinding + 1, name := tailName, value := .list c.link, status := .noHolder }]
        nextBinding := s.nextBinding + 1 + 1 } = u := by simp [u, matchBindings, List.append_assoc]
  rw [hstate, hres]
  dsimp only
  simp only [enter, m_modify_apply]
  rw [hsnap2]
  dsimp only
  rw [hw]
  rfl

end Trial.Proofs
