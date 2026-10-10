import Full.Proofs.TrialCleanup
import Proofs.LetSetup

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

/-- Saved work cannot mention the binding which the next Bind creates. -/
theorem let_rest_unused (hr : Reachable p initial s)
    (ht : s.tasks = .bind name body ctx :: rest) :
    rest.any (taskUses s.nextBinding) = false := by
  apply ReleaseQueue.tasks_fresh_unused (next := s.nextBinding) _ (Nat.le_refl _)
  intro task hm
  exact EnvironmentIdentity.reachable_task hr (by rw [ht]; exact List.mem_cons_of_mem _ hm)

def letChange (s : State) (ctx : Context) (name : String) (body : Trial.Expr)
    (v : Slot) (slots : List Slot) (rest : List Task) : Change :=
  let b := makeBinding s.nextBinding name v ctx.invocation s!"{ctx.site}/binding"
  let inner := { ctx with env := (name,s.nextBinding)::ctx.env }
  let next := .eval (embed body) (child inner 1) :: .handoff :: rest
  ⟨{ s with
      bindings := s.bindings ++ [b], slots := slots,
      nextBinding := s.nextBinding+1, entered := inner.env,
      tasks := dead (s.bindings ++ [b]) [(name,s.nextBinding)] next ++ next },
    ⟨"Bind", match v.raw with | .list (some _) => some .nameBound | _ => none⟩,none⟩

theorem let_bind_step (ht : s.tasks = .bind name (embed body) ctx :: rest)
    (hs : s.slots = v :: slots) (ha : s.answer = none) :
    advance p 1 s = .ok (commit (letChange s ctx name body v slots rest)) := by
  simp [advance, step, transition, ht, hs, ha, letChange, makeBinding, child]
  rfl

def letBind (name : String) (r : Raw) (env : Env) : Trial.M Env := do
  let id ← Trial.newBinding name r (Trial.Proofs.resultStatus r)
  Trial.popPending r
  let inner := (name,id)::env
  Trial.enter inner
  if Trial.Proofs.resultStatus r == .holding then Trial.snapshot .nameBound else pure ()
  pure inner

theorem let_bind_exact (s : State) (ctx : Context) (name : String) (body : Trial.Expr)
    (v : Slot) (slots : List Slot) (rest : List Task) (log : List Trial.LogEvent)
    (hs : s.slots = v :: slots) :
    letBind name v.raw ctx.env (logged s log) =
      (.ok ((name,s.nextBinding)::ctx.env),
        logged (commit (letChange s ctx name body v slots rest)) log) := by
  cases hv : v.raw with
  | num n | bool b =>
    simp [letBind, Trial.newBinding, Trial.popPending, Trial.enter,
      Trial.Proofs.resultStatus, logged, observe, commit, letChange,
      makeBinding, pending, hs, hv]
  | list addr =>
    cases addr with
    | none =>
      simp [letBind, Trial.newBinding, Trial.popPending, Trial.enter,
        Trial.Proofs.resultStatus, logged, observe, commit, letChange,
        makeBinding, pending, hs, hv]
    | some addr =>
      have h := commit_snapshot (letChange s ctx name body v slots rest) .nameBound
        (by simp [letChange, hv])
      simp only [Trial.snapshot] at h
      simp [letBind, Trial.newBinding, Trial.popPending, Trial.enter,
        Trial.Proofs.resultStatus, logged, observe, commit, letChange,
        makeBinding, pending, hs, hv, Trial.snapshot, ← visible_projection] at h ⊢

theorem eval_let_bind (name : String) (a body : Trial.Expr) (env : Env)
    (frames : List Trial.Frame) (branches : List Nat) :
    Trial.evalC .approved (.letE name a body) env frames branches =
      (do
        let r ← Trial.evalC .approved a env
          (⟨body,(name,none)::Trial.toFEnv env⟩::frames) branches
        let inner ← letBind name r env
        if Trial.Proofs.resultStatus r == .holding &&
            !Trial.usesBinding body (Trial.toFEnv inner) inner.head!.2 then
          Trial.giveUpBinding .approved inner.head!.2 else pure ()
        Trial.evalC .approved body inner frames branches : Trial.M Raw) := by
  simp only [Trial.evalC]
  apply bind_congr
  intro r
  cases r with
  | num n | bool b => simp [letBind, Trial.Proofs.resultStatus, bind_assoc]
  | list addr => cases addr <;> simp [letBind, Trial.Proofs.resultStatus, bind_assoc, List.head!]

theorem let_queue (hr : Reachable p initial s)
    (ht : s.tasks = .bind name (embed body) ctx :: rest) :
    (letChange s ctx name body v slots rest).state.tasks =
      (if Trial.Proofs.resultStatus v.raw == .holding &&
        !Trial.usesBinding body (Trial.toFEnv ((name,s.nextBinding)::ctx.env)) s.nextBinding
       then [.giveBinding s.nextBinding] else []) ++
      .eval (embed body) (child {ctx with env := (name,s.nextBinding)::ctx.env} 1) ::
        .handoff :: rest := by
  have hfresh := let_rest_unused hr ht
  have hold : s.bindings.any (fun b => b.record.id == s.nextBinding &&
      b.record.status == .holding) = false := by
    apply List.any_eq_false.mpr
    intro b hb
    have hn := BindingIdentity.reachable_bound hr hb
    simp [Nat.ne_of_lt hn]
  dsimp only [letChange]
  simp only [dead, List.reverse_cons, List.reverse_nil, List.nil_append,
    List.filterMap_cons, List.filterMap_nil, List.any_append, List.any_cons,
    List.any_nil, hold, Bool.false_or, Bool.or_false, makeBinding, beq_self_eq_true,
    taskUses, child, uses_embed, hfresh]
  cases hv : v.raw with
  | num n | bool b => simp [Trial.Proofs.resultStatus]
  | list addr =>
    cases addr <;> simp [Trial.Proofs.resultStatus]
    by_cases hu : Trial.usesBinding body (Trial.toFEnv ((name,s.nextBinding)::ctx.env))
      s.nextBinding = false <;> simp [hu]

theorem evaluation_let (ha : Evaluation a) (hb : Evaluation body) :
    Evaluation (.letE name a body) := by
  intro p initial s ctx rest frames log raw u hr ht hs hf he hu
  rw [eval_let_bind] at hu
  obtain ⟨r, w, hoperand, htail⟩ := trial_bind_success _ _ _ _ _ hu
  obtain ⟨n, l, v, hl, hrl, htl, hsl, hvl, hal, hol, hel⟩ :=
    let_operand name a body ha p initial s ctx rest frames log r w hr ht hs hf he hoperand
  let d := commit (letChange l ctx name body v s.slots rest)
  have hd : advance p 1 l = .ok d := let_bind_step htl hsl hal
  have hrd := reachable_advance p initial l d 1 hrl hd
  have hen : Enclosing ctx d := by simpa [Enclosing, d, commit, letChange] using hel
  have hlog : logged l w.log = w := logged_of_exact l w hol
  have hbind : letBind name r ctx.env w =
      (.ok ((name,l.nextBinding)::ctx.env), logged d w.log) := by
    rw [← hlog, ← hvl]
    exact let_bind_exact l ctx name body v s.slots rest w.log hsl
  simp only [Trial.Proofs.m_bind_apply, hbind] at htail
  let inner := {ctx with env := (name,l.nextBinding)::ctx.env}
  let next := .eval (embed body) (child inner 1) :: .handoff :: rest
  let release := Trial.Proofs.resultStatus r == .holding &&
    !Trial.usesBinding body (Trial.toFEnv inner.env) l.nextBinding
  have hqueue : d.tasks = (if release then [.giveBinding l.nextBinding] else []) ++ next := by
    simpa [d, commit, release, inner, next, hvl] using let_queue (v := v) (slots := s.slots) hrl htl
  have hbody : ∃ k t finalLog, advance p k d = .ok t ∧ Reachable p initial t ∧
      t.tasks = next ∧ t.slots = s.slots ∧ t.answer = none ∧ Enclosing ctx t ∧
      Trial.evalC .approved body inner.env frames ctx.branches (logged t finalLog) = (.ok raw,u) := by
    cases hc : release with
    | false =>
      refine ⟨0,d,w.log,rfl,hrd,?_,rfl,hal,hen,?_⟩
      · simpa [hc] using hqueue
      · simpa [release, inner, List.head!, hc] using htail
    | true =>
      have htd : d.tasks = .giveBinding l.nextBinding :: next := by simpa [hc] using hqueue
      obtain ⟨b, addr, hfind, hhold, hvalue⟩ :=
        ReleaseQueue.reachable_binding (bid := l.nextBinding) hrd (by simp [htd])
      have hsuccess : (Trial.giveUpBinding .approved l.nextBinding >>=
          fun _ => Trial.evalC .approved body inner.env frames ctx.branches)
          (logged d w.log) = (.ok raw,u) := by
        simpa [release, inner, List.head!, hc] using htail
      obtain ⟨result, z, hz, hbody⟩ := trial_bind_success _ _ _ _ _ hsuccess
      cases result
      have path := binding_cascade_of_success p initial d l.nextBinding b addr next z
        hrd htd hal hfind hhold hvalue hz
      obtain ⟨k,t,finalLog,hx,htt,hst,hat,htrial,hbs,hrs⟩ :=
        cascade_binding p d l.nextBinding b addr next htd hal hfind hhold hvalue path w.log
      have hw : logged t finalLog = z := congrArg Prod.snd (htrial.symm.trans hz)
      exact ⟨k,t,finalLog,hx,reachable_advance p initial d t k hrd hx,htt,hst,hat,
        by simpa [Enclosing, hrs] using hen, by simpa [hw] using hbody⟩
  obtain ⟨k,t,finalLog,hk,hrt,htt,hst,hat,hent,hub⟩ := hbody
  obtain ⟨m,q,vq,hm,hrq,htq,hsq,hvq,haq,hoq,heq⟩ :=
    hb p initial t (child inner 1) (.handoff::rest) frames finalLog raw u hrt htt hat
      (future_silent .handoff (fun _ => rfl) hf)
      (by simpa [Enclosing, child, inner] using hent)
      (by simpa [child, inner] using hub)
  obtain ⟨z,hz,hrz,htz,hsz,haz,hoz,hez⟩ :=
    control_handoff p initial q ctx rest u.log hrq htq haq
      (by simpa [Enclosing, child, inner] using heq)
  refine ⟨n+1+k+m+1,z,vq,?_,hrz,htz,?_,hvq,haz,?_,hez⟩
  · rw [advance_add, advance_add, advance_add, advance_add, hl]
    simp only [bind, Except.bind, hd, hk, hm, hz]
  · rw [hsz, hsq, hst]
  · have hx := congrArg eraseLog hoz
    simp only [erase_logged] at hx
    exact hoq.trans hx.symm

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.let_rest_unused
#print axioms Full.Proofs.TrialExecution.let_bind_step
#print axioms Full.Proofs.TrialExecution.let_bind_exact
#print axioms Full.Proofs.TrialExecution.evaluation_let
