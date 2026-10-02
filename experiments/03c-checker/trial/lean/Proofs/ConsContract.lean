import Proofs.BuildContract

namespace Trial.Proofs

theorem read_back_list {m : Memory} {raw : RawValue} {items : List Int}
    (h : readBack m raw = .ok (.list items)) : ∃ link, raw = .list link := by
  cases raw with
  | num _ | bool _ => simp [readBack] at h
  | list link => exact ⟨link, rfl⟩

/-- Head, tail, and actual cell construction compose left-to-right. Reuse
may consume an enclosing reservation, recorded by the suffix postcondition. -/
theorem cons_contract (head tail : Expr) (hh : EvalContract head) (ht : EvalContract tail) :
    EvalContract (.cons head tail) := by
  intro start g env plain fs enc k s h hl hf henv htype
  cases hch : check (plain.map (fun p => (p.1, p.2.kind))) head
  · simp [check, hch] at htype
  rename_i kh
  cases kh <;> simp [check, hch, expectKind] at htype
  cases hct : check (plain.map (fun p => (p.1, p.2.kind))) tail
  · simp [hct] at htype
  rename_i kt
  cases kt <;> simp [hct] at htype
  subst k
  have hlh : LiveFor s.bindings
      ({ text := head, env := toFEnv env } :: { text := tail, env := toFEnv env } :: fs) :=
    hl.congr (fun _ => by simp [used_later_cons, usesBinding, Bool.or_assoc])
  have hfh := (hf.tail.prepend tail _ hf.head).prepend head _ hf.head
  obtain ⟨u, g1, rawh, vh, hx⟩ := hh start g env plain
    ({ text := tail, env := toFEnv env } :: fs) enc .number s h hlh hfh henv hch
  have hkh := hx.kind
  obtain ⟨item, hvh⟩ : ∃ item, vh = .num item := by
    cases vh <;> simp [PlainValue.kind] at hkh
    exact ⟨_, rfl⟩
  subst vh
  have hrawh := read_back_number hx.read
  subst rawh
  obtain ⟨w, g2, rawt, vt, hy⟩ := ht start g1 env plain fs enc .list u hx.state hx.live hx.frames
    (henv.extend hx.meanings hf.env) hct
  have hkt := hy.kind
  obtain ⟨items, hvt⟩ : ∃ items, vt = .list items := by
    cases vt <;> simp [PlainValue.kind] at hkt
    exact ⟨_, rfl⟩
  subst vt
  obtain ⟨link, hr⟩ := read_back_list hy.read
  subst rawt
  let w0 : RunState := { w with scope := env.reverse.map Prod.snd }
  have hsw0 : StateInvariant start g2 enc w0 := hy.state.scope _
  have hpend : w0.pending = pendingResult (.list link) s.pending := by
    cases link <;> simpa [w0, pendingResult, hx.pending] using hy.pending
  obtain ⟨a, t, hb, hst, hread, hbind, hp, hnb, hnbr, hres, hsn, hsave⟩ :=
    build_contract hsw0 item link items s.pending
      (by cases link <;> simpa [pendingResult] using hpend) hy.read
  refine ⟨t, g2, .list (some a), .list (item :: items), {
    run := ?_
    meaning := by simp [eval, hx.meaning, hy.meaning]
    kind := rfl
    read := hread
    state := hst
    live := by simpa [hbind, w0] using hy.live
    frames := ?_
    bindingsGrow := Nat.le_trans hx.bindingsGrow (by simpa [hnb, w0] using hy.bindingsGrow)
    branchesGrow := Nat.le_trans hx.branchesGrow (by simpa [hnbr, w0] using hy.branchesGrow)
    meanings := hx.meanings.trans hy.meanings hx.bindingsGrow
    pending := hp
    saved := ?_
    reservations := hres.trans (hy.reservations.trans hx.reservations)
    snapshots := hx.snapshots.trans (hy.snapshots.trans hsn) }⟩
  · simp only [evalC, m_bind_apply, hx.run, hy.run, enter, m_modify_apply]
    exact hb
  · intro f hf x id hi
    rw [hnb]
    exact hy.frames f hf x id hi
  · intro v hv
    have hvu : v ∈ u.pending := by simpa [hx.pending, pendingResult] using hv
    exact ((hsave v hv).trans (hy.saved v hvu)).trans (hx.saved v hv)

end Trial.Proofs
