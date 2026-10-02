import Proofs.InputCleanup

namespace Trial.Proofs

/-- Pair-pattern form used by runMain's elaborated input loop. -/
theorem input_loop_pattern (start : Start) :
    (forIn start.inputs ([] : Env) (fun p env => match p with
      | (x, val) => do
        let st := pushPending.match_1 (fun _ => BStatus) val (fun _ => .holding) (fun _ => .noHolder)
        let id ← newBinding x val st
        pure (ForInStep.yield ((x, id) :: env))) : M Env)
      { mem := start.toMemory, log := [], bindings := [], scope := [], pending := [],
        outside := start.outside, setAside := [], nextBranch := 0, nextBinding := 0, snaps := [] } =
      (.ok (inputEnv start), inputState start) := by
  have heq : (fun (p : String × RawValue) (env : Env) => match p with
      | (x, val) => do
        let st := pushPending.match_1 (fun _ => BStatus) val (fun _ => .holding) (fun _ => .noHolder)
        let id ← newBinding x val st
        pure (ForInStep.yield ((x, id) :: env)) : (String × RawValue) → Env → M (ForInStep Env)) =
      (fun p env => do
        let st := input_binding_status.match_1 (fun _ => BStatus) p.2 (fun _ => .holding) (fun _ => .noHolder)
        let id ← newBinding p.1 p.2 st
        pure (ForInStep.yield ((p.1, id) :: env))) := by
    funext ⟨x, val⟩ env
    cases val with
    | num _ | bool _ => rfl
    | list r => cases r <;> rfl
  rw [heq]
  exact input_loop_initial start

theorem cleanup_match_eq (α : Type) (v : RawValue) (f : Addr → α) (g : RawValue → α) :
    pushPending.match_1 (fun _ => α) v f g = inputCleanupStep.match_1 (fun _ => α) v f g := by
  cases v with
  | num _ | bool _ => rfl
  | list r => cases r <;> rfl

/-- The locked runner's input loops and snapshots connect a completed
expression contract to the exact public promises, without extra end assumptions. -/
theorem promises_of_contract (e : Expr) (hc : EvalContract e) (start : Start)
    (hv : validStart e start = .ok ()) :
    Finishes (runCounted .approved e start) ∧
      SameAnswer e start (runCounted .approved e start) ∧
      NoVisibleChange start (runCounted .approved e start) ∧
      NoLeak start (runCounted .approved e start) := by
  obtain ⟨plain, hp, hk⟩ := valid_start_plain e start hv
  obtain ⟨k, hw⟩ := valid_start_well_formed e start hv
  have hw' : wellFormed (plain.map (fun p => (p.1, p.2.kind))) e = .ok k := by
    simpa [hk] using hw
  have hcheck : check (plain.map (fun p => (p.1, p.2.kind))) e = .ok k := by
    unfold wellFormed at hw'
    split at hw'
    · simp at hw'
    · split at hw'
      · simp at hw'
      · exact hw'
  obtain ⟨u, hu, hsu, hlu, hnu, hpu⟩ := initial_cleanup_contract e start hv
  let v := (snapshot .start none u).2
  have hsv : StateInvariant start (inputMeanings start) [] v := hsu.snapshot .start none
  have hfv : FramesBound v [{ text := e, env := toFEnv (inputEnv start) }] := by
    intro f hf x id hi
    change id < u.nextBinding
    rw [hnu]
    exact initialized_frame e start hv f hf x id hi
  obtain ⟨t, g, raw, value, he⟩ := hc start (inputMeanings start) (inputEnv start) plain [] [] k v
    hsv hlu hfv (initialized_environment e start hv plain hp) hcheck
  let t' := (snapshot .end none t).2
  have hst' : StateInvariant start g [] t' := he.state.snapshot .end none
  have hrun : runMain Variant.approved e start.inputs
      { mem := start.toMemory, log := [], bindings := [], scope := [], pending := [],
        outside := start.outside, setAside := [], nextBranch := 0, nextBinding := 0, snaps := [] } =
      (.ok raw, t') := by
    unfold runMain
    rw [m_bind_apply, input_loop_pattern]
    dsimp only
    simp only [enter, m_bind_apply, m_modify_apply]
    simp only [inputCleanupStep, ← cleanup_match_eq] at hu
    rw [hu]
    dsimp only
    have hsnap : snapshot .start none u = (.ok (), v) := rfl
    rw [hsnap]
    dsimp only
    rw [he.run]
    rfl
  have hout := counted_of_main e start raw t' hv hrun
  have hfinal : finalAnswer (runCounted .approved e start) = .ok value := by
    rw [hout]
    exact he.read
  have hplain : plainAnswer e start = .ok value := by
    simp [plainAnswer, hp, runPlain, hw', he.meaning]
  have hpending : t'.pending = pendingResult raw [] := by
    simpa [t', v, snapshot, hpu] using he.pending
  refine ⟨by simp [Finishes, hfinal, Except.toBool],
    ⟨by simp [hfinal, Except.toBool], hfinal.trans hplain.symm⟩,
    hst'.visible e hv _ (by rw [hout]), ?_⟩
  rw [hout]
  apply hst'.final_no_leak he.live raw
  cases raw with
  | num n | bool n => simpa [pendingResult] using hpending
  | list r => cases r <;> simpa [pendingResult] using hpending

end Trial.Proofs
