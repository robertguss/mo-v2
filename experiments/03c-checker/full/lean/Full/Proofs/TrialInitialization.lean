import Full.Proofs.TrialExecutionContract
import Proofs.RunContract

namespace Full.Proofs.TrialInitialization
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialExecution

theorem check_embed (e : Trial.Expr) (env : List (String × Kind)) (k : Kind)
    (h : Trial.check env e = .ok k) : check [] env (embed e) = .ok k := by
  induction e generalizing env k with
  | num n | nil =>
    simpa [Trial.check, check, embed] using h
  | var x =>
    cases hl : Trial.lookupKind env x <;> simp_all [Trial.check, check, embed]
  | add a b ha hb | sub a b ha hb | eq a b ha hb | lt a b ha hb | le a b ha hb
  | cons a b ha hb =>
    simp only [Trial.check, Trial.Proofs.except_bind_eq_ok] at h
    obtain ⟨ka, hka, _, hea, kb, hkb, _, heb, hout⟩ := h
    have hfa := ha _ _ hka
    have hfb := hb _ _ hkb
    cases ka <;> cases kb <;> simp_all [Trial.expectKind, check, embed]
  | letE x a b ha hb =>
    simp only [Trial.check, Trial.Proofs.except_bind_eq_ok] at h
    obtain ⟨ka, hka, hkb⟩ := h
    simp [check, embed, ha _ _ hka, hb _ _ hkb]
  | ifE c a b hc ha hb =>
    simp only [Trial.check, Trial.Proofs.except_bind_eq_ok] at h
    obtain ⟨kc, hkc, _, hec, ka, hka, kb, hkb, hout⟩ := h
    have hfc := hc _ _ hkc
    have hfa := ha _ _ hka
    have hfb := hb _ _ hkb
    cases kc <;> simp_all [Trial.expectKind, check, embed]
    split at hout <;> simp_all
  | matchE s n x y c hs hn hc =>
    simp only [Trial.check, Trial.Proofs.except_bind_eq_ok] at h
    obtain ⟨ks, hks, _, hes, hout⟩ := h
    have hfs := hs _ _ hks
    cases ks <;> simp_all [Trial.expectKind]
    split at hout
    · simp_all
    simp only [Trial.Proofs.except_bind_eq_ok] at hout
    obtain ⟨kn, hkn, kc, hkc, hout⟩ := hout
    have hfn := hn _ _ hkn
    have hfc := hc _ _ hkc
    split at hout <;> simp_all [check, embed, Trial.expectKind]

theorem validate_embed (e : Trial.Expr) (inputs : List (String × Kind)) (k : Kind)
    (h : Trial.wellFormed inputs e = .ok k) :
    validate ⟨[],embed e⟩ inputs = .ok k := by
  unfold Trial.wellFormed at h
  split at h
  · simp at h
  · split at h
    · simp at h
    · have hc := check_embed e inputs k h
      simp_all [validate, List.any_eq_true, beq_iff_eq]

theorem valid_start_num (e : Trial.Expr) (initial : Trial.Start)
    (hv : Trial.validStart e initial = .ok ()) : Trial.validStart (.num 0) initial = .ok () := by
  obtain ⟨k, hw⟩ := Trial.Proofs.valid_start_well_formed e initial hv
  have hn : Trial.wellFormed (initial.inputs.map (fun p => (p.1,p.2.kind))) (.num 0) = .ok .number := by
    unfold Trial.wellFormed at hw ⊢
    split at hw <;> simp_all
    split at hw <;> simp_all [Trial.check, List.any_eq_true]
    assumption
  simpa only [Trial.validStart, hw, hn, bind, Except.bind, pure, Except.pure] using hv

theorem mapM_success (xs : List α) (f : α → Except ε β)
    (h : ∀ x ∈ xs, ∃ y, f x = .ok y) : ∃ ys, xs.mapM f = .ok ys := by
  induction xs with
  | nil => exact ⟨[], rfl⟩
  | cons x xs ih =>
    obtain ⟨y, hy⟩ := h x (by simp)
    obtain ⟨ys, hys⟩ := ih (fun a ha => h a (by simp [ha]))
    exact ⟨y :: ys, by simp [hy, hys]⟩

/-- Valid Trial starts really pass Full begin, including every ghost read-back. -/
theorem begin_success (e : Trial.Expr) (initial : Trial.Start)
    (hv : Trial.validStart e initial = .ok ()) :
    ∃ first, Counted.begin ⟨[],embed e⟩ initial = .ok first := by
  obtain ⟨k, hw⟩ := Trial.Proofs.valid_start_well_formed e initial hv
  have hval := validate_embed e _ k hw
  have hn := valid_start_num e initial hv
  obtain ⟨edges, hedges⟩ := mapM_success initial.cells
    (fun c => do pure (c.addr, ← Trial.readBack initial.toMemory (.list c.link))) (by
      intro c hc
      have hp := Trial.Proofs.path_of_chain_ends initial initial.cells.length (some c.addr)
        (Trial.Proofs.valid_start_chain_ends e initial hv c hc)
      obtain ⟨cs, hp⟩ := hp
      let cell : Trial.Cell := ⟨c.addr,c.item,c.link,c.count,.live⟩
      have hf : initial.toMemory.find? c.addr = some cell :=
        Trial.Proofs.find_of_mem initial.toMemory
          (Trial.Proofs.valid_start_unique e initial hv) cell
          (List.mem_map.mpr ⟨c, hc, rfl⟩)
      generalize heq : some c.addr = root at hp
      cases hp with
      | nil => cases heq
      | cons d ds hd hl ht =>
        have he : c.addr = d.addr := Option.some.inj heq
        rw [← he] at hd
        rw [hf] at hd
        have hd' : d = cell := (Option.some.inj hd).symm
        subst d
        have hr := ht.read_back
        change Trial.readBack initial.toMemory (.list c.link) = _ at hr
        exact ⟨(c.addr, .list (ds.map Trial.Cell.item)), by simp [hr]⟩)
  obtain ⟨bindings, hbindings⟩ := mapM_success initial.inputs.zipIdx
    (fun ((name,raw),id) => do
      let value ← Trial.readBack initial.toMemory raw
      pure (makeBinding id name ⟨raw,value⟩ 0 s!"main/input/{name}")) (by
        intro p hp
        have hm : p.1 ∈ initial.inputs := List.fst_mem_of_mem_zipIdx hp
        obtain ⟨v, hr, _⟩ := Trial.Proofs.valid_start_input e initial hv p.1 hm
        exact ⟨makeBinding p.2 p.1.1 ⟨p.1.2,v⟩ 0 s!"main/input/{p.1.1}", by simp [hr]⟩)
  simp only [Counted.begin, hval, hn, hedges, hbindings]
  exact ⟨_, rfl⟩

theorem input_records (xs : List (String × Raw)) (next : Nat) (m : Trial.Memory)
    (bs : List Binding)
    (h : (xs.zipIdx next).mapM (fun ((name,raw),id) => do
      let value ← Trial.readBack m raw
      pure (makeBinding id name ⟨raw,value⟩ 0 s!"main/input/{name}")) = .ok bs) :
    bs.map (·.record) = Trial.Proofs.inputBindings next xs := by
  induction xs generalizing next bs with
  | nil => simp at h; subst bs; rfl
  | cons p xs ih =>
    rcases p with ⟨name, raw⟩
    simp only [List.zipIdx_cons, List.mapM_cons, Trial.Proofs.except_bind_eq_ok] at h
    obtain ⟨b, hb, tail, ht, hout⟩ := h
    obtain ⟨value, _, hb⟩ := hb
    cases Except.ok.inj hb
    cases Except.ok.inj hout
    rw [List.map_cons, ih _ _ ht]
    cases raw with
    | num n | bool b => rfl
    | list r => cases r <;> rfl

/-- Exact agreement before the unused-input loop: ordered records, ids, scope,
memory record, pending holders, reservations and snapshots all agree. -/
theorem begin_observe (p : Program) (initial : Trial.Start) (first : State)
    (hb : Counted.begin p initial = .ok first) :
    observe first = { Trial.Proofs.inputState initial with
      scope := (Trial.Proofs.inputEnv initial).reverse.map Prod.snd } := by
  obtain ⟨_, edges, bs, _, hbs, rfl⟩ := Initial.begin_shape p initial first hb
  have hr := input_records initial.inputs 0 initial.toMemory bs hbs
  have henv : bs.reverse.map (fun b => (b.record.name,b.record.id)) = Trial.Proofs.inputEnv initial := by
    simp only [Trial.Proofs.inputEnv, List.map_reverse]
    rw [← hr, List.map_map]
    rfl
  have hlen : bs.length = initial.inputs.length := by
    have hi := Trial.Proofs.input_binding_ids initial.inputs 0
    have hl := congrArg List.length hi
    simpa [← hr] using hl
  simp only [observe, Trial.Proofs.inputState, henv, hr, hlen, Counted.pending]
  rfl

/-- The remaining initialization obligation is only the unused-input prefix.
It stops before Start, so neither expression evaluation nor finalization is
assumed. The Trial state is the actual input creation/enter/cleanup state. -/
def InitialCleanupBridge : Prop :=
  ∀ (e : Trial.Expr) (initial : Trial.Start) (u : Trial.RunState),
    Trial.validStart e initial = .ok () →
    (forIn (Trial.Proofs.inputEnv initial).reverse PUnit.unit
      (fun p _ => Trial.Proofs.inputCleanupStep e (Trial.Proofs.inputEnv initial) p)
      : Trial.M PUnit)
      { Trial.Proofs.inputState initial with
        scope := (Trial.Proofs.inputEnv initial).reverse.map Prod.snd } = (.ok (), u) →
    ∃ s, Reachable ⟨[],embed e⟩ initial s ∧
      s.tasks = [.start, .eval (embed e) { env := Trial.Proofs.inputEnv initial }, .finish] ∧
      s.slots = [] ∧ s.answer = none ∧ s.reservations = [] ∧
      observe s = eraseLog u

theorem start_step (p : Program) (s : State) (rest : List Task)
    (ht : s.tasks = .start :: rest) (ha : s.answer = none) :
    let t := Counted.commit ⟨{ s with tasks := rest },⟨"Start",some .start⟩,none⟩
    Counted.step p s = .ok t ∧ t.tasks = rest ∧ t.slots = s.slots ∧
      t.answer = none ∧ t.reservations = s.reservations ∧
      observe t = (Trial.snapshot .start none (observe s)).2 := by
  dsimp only
  refine ⟨?_, rfl, rfl, ha, rfl, ?_⟩
  · simp [Counted.step, Counted.transition, ht, ha]
  · have h := commit_snapshot
      (⟨{ s with tasks := rest },⟨"Start",some .start⟩,none⟩ : Change) .start rfl
    simp only [Trial.snapshot] at h
    simp only [observe, Counted.commit] at h ⊢
    rw [h]
    rfl

theorem finish_step (p : Program) (s : State) (v : Slot) (slots : List Slot)
    (ht : s.tasks = [.finish]) (hs : s.slots = v :: slots) (ha : s.answer = none) :
    let t := Counted.commit ⟨{ s with answer := some v, tasks := [] },
      ⟨"Finish",some .end⟩,none⟩
    Counted.step p s = .ok t ∧ t.answer = some v ∧
      observe t = (Trial.snapshot .end none (observe s)).2 := by
  dsimp only
  refine ⟨?_, rfl, ?_⟩
  · simp [Counted.step, Counted.transition, ht, hs, ha]
  · have h := commit_snapshot
      (⟨{ s with answer := some v, tasks := [] },⟨"Finish",some .end⟩,none⟩ : Change) .end rfl
    simp only [Trial.snapshot] at h
    simp only [observe, Counted.commit] at h ⊢
    rw [h]
    rfl

theorem snapshot_erase (k : Trial.StepKind) (u : Trial.RunState) :
    eraseLog (Trial.snapshot k none u).2 =
      (Trial.snapshot k none (eraseLog u)).2 := rfl

theorem logged_erase (s : State) (u : Trial.RunState)
    (h : observe s = eraseLog u) : logged s u.log = u := by
  simp only [logged, h, eraseLog]

/-- Exact factorization of the locked public runner around its input prefix. -/
theorem runner_of_cleanup (e : Trial.Expr) (initial : Trial.Start)
    (u : Trial.RunState) (raw : Raw) (w : Trial.RunState)
    (hv : Trial.validStart e initial = .ok ())
    (hu : (forIn (Trial.Proofs.inputEnv initial).reverse PUnit.unit
      (fun p _ => Trial.Proofs.inputCleanupStep e (Trial.Proofs.inputEnv initial) p)
      : Trial.M PUnit)
      { Trial.Proofs.inputState initial with
        scope := (Trial.Proofs.inputEnv initial).reverse.map Prod.snd } = (.ok (), u))
    (he : Trial.evalC .approved e (Trial.Proofs.inputEnv initial) [] []
      (Trial.snapshot .start none u).2 = (.ok raw, w)) :
    Trial.runCountedWith .approved e initial =
      { result := .answer raw, memory := w.mem, log := w.log,
        record := w.mem.record, states := (Trial.snapshot .end none w).2.snaps } := by
  have hr : Trial.runMain .approved e initial.inputs
      { mem := initial.toMemory, log := [], bindings := [], scope := [], pending := [],
        outside := initial.outside, setAside := [], nextBranch := 0, nextBinding := 0, snaps := [] } =
      (.ok raw, (Trial.snapshot .end none w).2) := by
    unfold Trial.runMain
    rw [Trial.Proofs.m_bind_apply, Trial.Proofs.input_loop_pattern]
    dsimp only
    simp only [Trial.enter, Trial.Proofs.m_bind_apply, Trial.Proofs.m_modify_apply]
    simp only [Trial.Proofs.inputCleanupStep, ← Trial.Proofs.cleanup_match_eq] at hu
    rw [hu]
    dsimp only
    rw [show Trial.snapshot .start none u = (.ok (), (Trial.snapshot .start none u).2) from rfl]
    dsimp only
    rw [he]
    rfl
  simp [Trial.runCountedWith, hv, StateT.run, ExceptT.run, hr, Trial.snapshot]

/-- Initialization and finalization need no expression-specific hypotheses
other than the universal recursive evaluation theorem. All F6 fields are exact. -/
theorem f6_of_evaluation (evaluation : ∀ e, Evaluation e)
    (cleanup : InitialCleanupBridge) : F6 := by
  intro e initial hv
  obtain ⟨plain, hp, hk⟩ := Trial.Proofs.valid_start_plain e initial hv
  obtain ⟨k, hw⟩ := Trial.Proofs.valid_start_well_formed e initial hv
  have hw' : Trial.wellFormed (plain.map (fun p => (p.1, p.2.kind))) e = .ok k := by
    simpa [hk] using hw
  have hcheck : Trial.check (plain.map (fun p => (p.1, p.2.kind))) e = .ok k := by
    unfold Trial.wellFormed at hw'
    split at hw'
    · simp at hw'
    · split at hw'
      · simp at hw'
      · exact hw'
  obtain ⟨u, hu, hsu, hlu, hnu, _⟩ := Trial.Proofs.initial_cleanup_contract e initial hv
  let a := (Trial.snapshot .start none u).2
  have hsa := hsu.snapshot .start none
  have hfa : Trial.Proofs.FramesBound a
      [{ text := e, env := Trial.toFEnv (Trial.Proofs.inputEnv initial) }] := by
    intro f hf x id hi
    change id < u.nextBinding
    rw [hnu]
    exact Trial.Proofs.initialized_frame e initial hv f hf x id hi
  obtain ⟨w, g, raw, value, he⟩ := Trial.Proofs.eval_contract e initial
    (Trial.Proofs.inputMeanings initial) (Trial.Proofs.inputEnv initial) plain [] [] k a
    hsa hlu hfa (Trial.Proofs.initialized_environment e initial hv plain hp) hcheck
  obtain ⟨s, hrs, hts, hss, has, hres, hos⟩ := cleanup e initial u hv hu
  let ctx : Context := { env := Trial.Proofs.inputEnv initial }
  let t := Counted.commit ⟨{ s with tasks := [.eval (embed e) ctx, .finish] },
    ⟨"Start",some .start⟩,none⟩
  obtain ⟨hst, htt, hslot, hat, hrt, hot⟩ := start_step ⟨[],embed e⟩ s _ hts has
  have hadv : Counted.advance ⟨[],embed e⟩ 1 s = .ok t := by
    simp only [Counted.advance, has, Option.isSome_none, Bool.false_eq_true, ↓reduceIte]
    rw [hst]
    rfl
  have hr : Reachable ⟨[],embed e⟩ initial t :=
    TrialSimulationRelease.reachable_advance _ _ _ _ 1 hrs hadv
  have ho : observe t = eraseLog a := by
    rw [hot, hos, ← snapshot_erase]
  have hen : Enclosing ctx t := by
    have hz : t.reservations = [] := hrt.trans hres
    simp [Enclosing, hz]
  have hf : Future [.finish] [] := by intro id; rfl
  have hev : Trial.evalC .approved e ctx.env [] ctx.branches (logged t a.log) = (.ok raw, w) := by
    rw [logged_erase t a ho]
    exact he.run
  obtain ⟨ticks, r, v, hex, hrr, htr, hsv, hvr, har, hor, _⟩ :=
    evaluation e ⟨[],embed e⟩ initial t ctx [.finish] [] a.log raw w
      hr htt hat hf hen hev
  obtain ⟨f, hfin, _, hraw, _, hof⟩ := TrialExecution.finish ⟨[],embed e⟩ r [] v t.slots htr hsv har
  have hrfin := TrialSimulationRelease.reachable_advance _ _ _ _ 1 hrr hfin
  have hobs : observe f = eraseLog (Trial.snapshot .end none w).2 := by
    rw [hof, ← hor, ← snapshot_erase]
  have hout := runner_of_cleanup e initial u raw w hv hu he.run
  refine ⟨f, raw, hrfin, ?_, ?_, ?_, ?_⟩
  · rw [hout]
  · simpa [hvr] using hraw
  · rw [hout]
    exact congrArg (fun q : Trial.RunState => q.mem.record) hobs
  · rw [hout]
    exact congrArg (fun q : Trial.RunState => q.snaps) hobs

end Full.Proofs.TrialInitialization

#print axioms Full.Proofs.TrialInitialization.f6_of_evaluation
#print axioms Full.Proofs.TrialInitialization.check_embed
#print axioms Full.Proofs.TrialInitialization.validate_embed
#print axioms Full.Proofs.TrialInitialization.valid_start_num
#print axioms Full.Proofs.TrialInitialization.begin_success
#print axioms Full.Proofs.TrialInitialization.input_records
#print axioms Full.Proofs.TrialInitialization.begin_observe
#print axioms Full.Proofs.TrialInitialization.start_step
#print axioms Full.Proofs.TrialInitialization.finish_step
#print axioms Full.Proofs.TrialInitialization.runner_of_cleanup
