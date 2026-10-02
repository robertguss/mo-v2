import Proofs.BindContract

namespace Trial.Proofs

/-- The locked let's binding, transfer, snapshot, and unused-name cleanup
fragment. eval_let_setup below equates its composition to the actual evaluator. -/
def letSetup (name : String) (r : RawValue) (body : Expr) (env : Env) : M Env := do
  let id ← (do
    let id ← newBinding name r (resultStatus r)
    popPending r
    pure id : M Nat)
  let env' := (name, id) :: env
  enter env'
  (if resultStatus r == .holding then snapshot .nameBound else pure () : M Unit) >>= fun _ =>
    (if resultStatus r == .holding && !(usesBinding body (toFEnv env') id) then
      giveUpBinding Variant.approved id else pure () : M Unit) >>= fun _ =>
    pure env'

theorem eval_let_setup (name : String) (bound body : Expr) (env : Env) (fs : List Frame) (enc : List Nat) :
    evalC Variant.approved (.letE name bound body) env fs enc =
      (do
        let r ← evalC Variant.approved bound env ({ text := body, env := (name, none) :: toFEnv env } :: fs) enc
        let env' ← letSetup name r body env
        evalC Variant.approved body env' fs enc : M RawValue) := by
  simp only [evalC]
  apply bind_congr
  intro r
  cases r with
  | num _ | bool _ => simp [letSetup, resultStatus, bind_assoc]
  | list l =>
    cases l <;> simp [letSetup, resultStatus, bind_assoc]
    apply bind_congr
    intro id
    apply bind_congr
    intro _
    apply bind_congr
    intro _
    apply bind_congr
    intro _
    by_cases hu : usesBinding body (toFEnv ((name, id) :: env)) id = false <;> simp [hu]

theorem let_setup_contract {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (name : String) (r : RawValue) (v : PlainValue)
    (body : Expr) (env : Env) (fs : List Frame) (rest : List RawValue)
    (hp : s.pending = pendingResult r rest) (hr : readBack s.mem r = .ok v)
    (hl : LiveFor s.bindings ({ text := body, env := (name, none) :: toFEnv env } :: fs))
    (hfs : FramesBound s fs) :
    ∃ t, letSetup name r body env s = (.ok ((name, s.nextBinding) :: env), t) ∧
      StateInvariant start (boundMeanings g s.nextBinding r v) enc t ∧
      LiveFor t.bindings ({ text := body, env := toFEnv ((name, s.nextBinding) :: env) } :: fs) ∧
      t.nextBinding = s.nextBinding + 1 ∧ t.nextBranch = s.nextBranch ∧
      t.setAside = s.setAside ∧ t.pending = rest ∧ s.snaps.IsPrefix t.snaps ∧
      (∀ v ∈ rest, readBack t.mem v = readBack s.mem v) := by
  let env' := (name, s.nextBinding) :: env
  let g' := boundMeanings g s.nextBinding r v
  let u := boundState s name r rest
  let u1 : RunState := { u with scope := env'.reverse.map Prod.snd }
  let u2 := if resultStatus r == .holding then (snapshot .nameBound none u1).2 else u1
  have hs1 : StateInvariant start g' enc u1 := (bind_result_state h name r v rest hp hr).scope _
  have hs2 : StateInvariant start g' enc u2 := by
    dsimp only [u2]
    split
    · exact hs1.snapshot .nameBound none
    · exact hs1
  have hbind := bind_result_run s name r rest hp
  have hsnap : (if resultStatus r == .holding then snapshot .nameBound else pure () : M Unit) u1 =
      (.ok (), u2) := by
    dsimp only [u2]
    split <;> rfl
  have hprefix : s.snaps.IsPrefix u2.snaps := by
    dsimp only [u2]
    split
    · exact snapshot_prefix u1 .nameBound none
    · exact ⟨[], by simp [u1, u, boundState]⟩
  have hfields : u2.nextBinding = s.nextBinding + 1 ∧ u2.nextBranch = s.nextBranch ∧
      u2.setAside = s.setAside ∧ u2.pending = rest ∧ u2.mem = s.mem ∧ u2.bindings = u.bindings := by
    dsimp only [u2]
    split <;> simp [u1, u, boundState, snapshot]
  obtain ⟨hcounter, hbranch, hstack, hpend, hmem, hbindings⟩ := hfields
  have hfuture : usedLater fs s.nextBinding = false := by
    cases he : usedLater fs s.nextBinding with
    | false => rfl
    | true => exact False.elim (Nat.lt_irrefl _ (used_later_below fs s.nextBinding s.nextBinding hfs he))
  have holdlive := bound_old_live s env body fs name hl h.bound
  by_cases hrelease : resultStatus r = .holding ∧ usesBinding body (toFEnv env') s.nextBinding = false
  · obtain ⟨hstatus, hused⟩ := hrelease
    have hraw : ∃ a, r = .list (some a) := by
      cases r with
      | num _ | bool _ => simp [resultStatus] at hstatus
      | list l => cases l with
        | none => simp [resultStatus] at hstatus
        | some a => exact ⟨a, rfl⟩
    obtain ⟨a, ha⟩ := hraw
    let b : Binding := { id := s.nextBinding, name := name, value := r, status := resultStatus r }
    have hb : b ∈ u2.bindings := by simp [hbindings, u, boundState, b]
    have hf : u2.bindings.find? (fun q => q.id == s.nextBinding) = some b :=
      binding_find_self u2.bindings hs2.unique b hb
    obtain ⟨t, ht, hst, hbt, hpt, hft, hvt⟩ := release_binding_contract hs2 s.nextBinding b a hf hstatus ha
    refine ⟨t, ?_, hst, ?_, hft.bindingCounter.trans hcounter, hft.branchCounter.trans hbranch,
      hft.stack.trans hstack, hpt.trans hpend, hprefix.trans hft.snapshots, ?_⟩
    · rw [letSetup, m_bind_apply, hbind]
      dsimp only
      simp only [enter, m_bind_apply, m_modify_apply]
      rw [hsnap]
      dsimp only
      simp [hstatus, hused, ht, env']
    · intro d hd hn
      rw [hbt, hbindings] at hd
      obtain ⟨q, hq, he⟩ := List.mem_map.mp hd
      rcases List.mem_append.mp hq with hq | hq
      · have hne : q.id ≠ s.nextBinding := Nat.ne_of_lt (h.bound q hq)
        have he' : q = d := by simpa [hne] using he
        rw [← he'] at hn ⊢
        exact holdlive q hq hn
      · have hq' := List.mem_singleton.mp hq
        subst q
        have hd' : d = { b with status := .givenUp } := by simpa [b] using he.symm
        rw [hd']
        simp [used_later_cons, b, hused, hfuture, env']
    · intro w hw
      simpa [hmem] using hvt w (by simpa [hpend] using hw)
  · refine ⟨u2, ?_, hs2, ?_, hcounter, hbranch, hstack, hpend, hprefix, ?_⟩
    · rw [letSetup, m_bind_apply, hbind]
      dsimp only
      simp only [enter, m_bind_apply, m_modify_apply]
      rw [hsnap]
      dsimp only
      simp [hrelease, env']
    · intro d hd hn
      rw [hbindings] at hd
      rcases List.mem_append.mp hd with hd | hd
      · exact holdlive d hd hn
      · have he := List.mem_singleton.mp hd
        subst d
        obtain ⟨a, ha⟩ := hn
        change r = .list (some a) at ha
        have hs : resultStatus r = .holding := by simp [ha, resultStatus]
        have hu : usesBinding body (toFEnv env') s.nextBinding = true := by
          cases hh : usesBinding body (toFEnv env') s.nextBinding <;> simp_all
        simp [used_later_cons, hs, hu, env']
    · intro w _
      rw [hmem]

end Trial.Proofs
