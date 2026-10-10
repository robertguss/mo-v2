import Full.Proofs.TrialExpression

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

theorem trial_bind_success {α β : Type} (m : Trial.M α) (k : α → Trial.M β)
    (s u : Trial.RunState) (b : β) (h : (m >>= k) s = (.ok b, u)) :
    ∃ a t, m s = (.ok a, t) ∧ k a t = (.ok b, u) := by
  cases hm : m s with
  | mk result t =>
    cases result with
    | error why =>
      simp [bind, ExceptT.bind, ExceptT.mk, StateT.bind,
        ExceptT.bindCont, hm, pure, StateT.pure] at h
      have bad := congrArg Prod.fst h
      cases bad
    | ok a => exact ⟨a, t, rfl, by simpa [bind, ExceptT.bind, ExceptT.mk,
        StateT.bind, ExceptT.bindCont, hm] using h⟩

/-- Administrative capture preserves older operands and every observation field. -/
theorem capture_exact (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (rest : List Task) (log : List Trial.LogEvent)
    (hr : Reachable p initial s) (ht : s.tasks = .capture :: rest)
    (ha : s.answer = none) (he : Enclosing ctx s) :
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      logged t log = logged s log ∧ Enclosing ctx t := by
  let t := commit ⟨{ s with tasks := rest },⟨"Capture",none⟩,none⟩
  have hx : advance p 1 s = .ok t := by
    simp [advance, step, transition, ht, ha, t]
  refine ⟨t, hx, reachable_advance p initial s t 1 hr hx, rfl, rfl, ha, ?_, ?_⟩
  · simp [t, logged, observe, commit, pending]
  · exact he

/-- Execute both operands using their recursive contracts at actual reachable
sources. The final primitive is left as the next real task, not assumed to run. -/
theorem binary_operands (a b : Trial.Expr) (ha : Evaluation a) (hb : Evaluation b)
    (p : Program) (initial : Trial.Start) (s : State) (ctx : Context)
    (op : Op) (rest : List Task) (frames : List Trial.Frame)
    (log : List Trial.LogEvent) (x y : Raw) (u w : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .eval (.bin op (embed a) (embed b)) ctx :: rest)
    (hs : s.answer = none) (hf : Future rest frames) (he : Enclosing ctx s)
    (hx : Trial.evalC .approved a ctx.env
      (⟨b, Trial.toFEnv ctx.env⟩ :: frames) ctx.branches (logged s log) = (.ok x, u))
    (hy : Trial.evalC .approved b ctx.env frames ctx.branches u = (.ok y, w)) :
    ∃ ticks t vx vy, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = .primitive op ctx :: rest ∧ t.slots = vy :: vx :: s.slots ∧
      vx.raw = x ∧ vy.raw = y ∧ t.answer = none ∧
      eraseLog w = observe t ∧ Enclosing ctx t := by
  let d := commit ⟨{ s with tasks :=
    [.eval (embed a) (child ctx 0), .capture, .eval (embed b) (child ctx 1),
      .capture, .primitive op ctx] ++ rest },⟨"Dispatch",none⟩,none⟩
  have hd : advance p 1 s = .ok d := by
    simp [advance, step, transition, ht, hs, d]
  have hfd : Future (.capture :: .eval (embed b) (child ctx 1) ::
      .capture :: .primitive op ctx :: rest) (⟨b, Trial.toFEnv ctx.env⟩ :: frames) := by
    apply future_silent _ (fun _ => rfl)
    have h := future_eval (child ctx 1) b
      (future_silent .capture (fun _ => rfl)
        (future_silent (.primitive op ctx) (fun _ => rfl) hf))
    simpa [child] using h
  obtain ⟨n, l, vx, hl, hrl, htl, hsl, hxl, hal, hel, henl⟩ :=
    ha p initial d (child ctx 0) _ _ log x u
      (reachable_advance p initial s d 1 hr hd) rfl hs hfd
      (by simpa [Enclosing, child, d, commit] using he)
      (by simpa [child, d, logged, observe, commit, pending] using hx)
  obtain ⟨lc, hlc, hrlc, htlc, hslc, halc, holc, henlc⟩ :=
    capture_exact p initial l (child ctx 0) _ u.log hrl htl hal henl
  have heu : logged lc u.log = u := holc.trans (logged_of_exact l u hel)
  have hfb : Future (.capture :: .primitive op ctx :: rest) frames :=
    future_silent .capture (fun _ => rfl)
      (future_silent (.primitive op ctx) (fun _ => rfl) hf)
  obtain ⟨m, r, vy, hry, hrr, htr, hsr, hyr, har, her, henr⟩ :=
    hb p initial lc (child ctx 1) _ frames u.log y w hrlc htlc halc hfb
      (by simpa [Enclosing, child] using henlc)
      (by simpa [child, heu] using hy)
  obtain ⟨t, htc, hrt, htt, hst, hat, hot, hent⟩ :=
    capture_exact p initial r ctx _ w.log hrr htr har
      (by simpa [Enclosing, child] using henr)
  refine ⟨1 + n + 1 + m + 1, t, vx, vy, ?_, hrt, htt, ?_, hxl, hyr, hat, ?_, hent⟩
  · rw [advance_add, advance_add, advance_add, advance_add, hd]
    simp only [bind, Except.bind, hl, hlc, hry, htc]
  · simp [hst, hsr, hslc, hsl, d, commit]
  · have hlog := congrArg eraseLog hot
    simp only [erase_logged] at hlog
    exact her.trans hlog.symm

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.trial_bind_success
#print axioms Full.Proofs.TrialExecution.binary_operands
