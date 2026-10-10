import Full.Proofs.TrialExpressionBinary

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

/-- Local, successful whole-cleanup contract. In particular this does not
quantify over successful releases at unrelated machine boundaries. -/
def CleanupBridge : Prop :=
  ∀ (p : Program) (initial : Trial.Start) (s : State) (ctx : Context)
    (rest : List Task) (env : Trial.Env) (frames : List Trial.Frame)
    (log : List Trial.LogEvent) (u : Trial.RunState),
    Reachable p initial s →
    s.tasks = dead s.bindings env rest ++ rest → s.answer = none →
    Future rest frames → Enclosing ctx s →
    Trial.giveUpDead .approved env frames (logged s log) = (.ok (), u) →
    ∃ ticks t, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      eraseLog u = observe t ∧ Enclosing ctx t

/-- Execute a dispatch and its first recursive expression at a real reachable
source. All older operands and the complete Trial observation are retained. -/
theorem control_operand (a : Trial.Expr) (ha : Evaluation a)
    (e : Expr) (continuation : List Task) (ctx : Context)
    (p : Program) (initial : Trial.Start) (s : State)
    (rest : List Task) (frames : List Trial.Frame) (log : List Trial.LogEvent)
    (raw : Raw) (u : Trial.RunState)
    (hr : Reachable p initial s) (ht : s.tasks = .eval e ctx :: rest)
    (hs : s.answer = none) (he : Enclosing ctx s)
    (hd : transition p s = .ok ⟨{ s with
      tasks := .eval (embed a) (child ctx 0) :: continuation ++ rest },
      ⟨"Dispatch",none⟩,none⟩)
    (hf : Future (continuation ++ rest) frames)
    (hu : Trial.evalC .approved a ctx.env frames ctx.branches
      (logged s log) = (.ok raw, u)) :
    ∃ ticks t v, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = continuation ++ rest ∧ t.slots = v :: s.slots ∧
      v.raw = raw ∧ t.answer = none ∧ eraseLog u = observe t ∧ Enclosing ctx t := by
  let d := commit ⟨{ s with
    tasks := .eval (embed a) (child ctx 0) :: continuation ++ rest },
    ⟨"Dispatch",none⟩,none⟩
  have hx : advance p 1 s = .ok d := by simp [advance, step, hs, hd, d]
  obtain ⟨n, t, v, hn, hrt, htt, hst, hv, hat, hot, het⟩ :=
    ha p initial d (child ctx 0) (continuation ++ rest) frames log raw u
      (reachable_advance p initial s d 1 hr hx) rfl hs hf
      (by simpa [Enclosing, child, d, commit] using he)
      (by simpa [child, d, logged, observe, commit, pending] using hu)
  refine ⟨1+n, t, v, ?_, hrt, htt, ?_, hv, hat, hot, ?_⟩
  · rw [advance_add, hx]; exact hn
  · simpa [d, commit] using hst
  · simpa [Enclosing, child] using het

theorem let_operand (x : String) (a body : Trial.Expr) (ha : Evaluation a)
    (p : Program) (initial : Trial.Start) (s : State) (ctx : Context)
    (rest : List Task) (frames : List Trial.Frame) (log : List Trial.LogEvent)
    (raw : Raw) (u : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .eval (embed (.letE x a body)) ctx :: rest)
    (hs : s.answer = none) (hf : Future rest frames) (he : Enclosing ctx s)
    (hu : Trial.evalC .approved a ctx.env
      (⟨body, (x,none)::Trial.toFEnv ctx.env⟩::frames) ctx.branches
      (logged s log) = (.ok raw, u)) :
    ∃ ticks t v, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = .bind x (embed body) ctx :: rest ∧ t.slots = v :: s.slots ∧
      v.raw = raw ∧ t.answer = none ∧ eraseLog u = observe t ∧ Enclosing ctx t := by
  exact control_operand a ha _ [.bind x (embed body) ctx] ctx p initial s rest _
    log raw u hr ht hs he (by simp [transition, ht, embed]) (future_bind ctx x body hf) hu

theorem if_operand (c yes no : Trial.Expr) (hc : Evaluation c)
    (p : Program) (initial : Trial.Start) (s : State) (ctx : Context)
    (rest : List Task) (frames : List Trial.Frame) (log : List Trial.LogEvent)
    (raw : Raw) (u : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .eval (embed (.ifE c yes no)) ctx :: rest)
    (hs : s.answer = none) (hf : Future rest frames) (he : Enclosing ctx s)
    (hu : Trial.evalC .approved c ctx.env
      (⟨yes, Trial.toFEnv ctx.env⟩::⟨no, Trial.toFEnv ctx.env⟩::frames)
      ctx.branches (logged s log) = (.ok raw, u)) :
    ∃ ticks t v, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = .chooseIf (embed yes) (embed no) ctx :: rest ∧
      t.slots = v :: s.slots ∧ v.raw = raw ∧ t.answer = none ∧
      eraseLog u = observe t ∧ Enclosing ctx t := by
  exact control_operand c hc _ [.chooseIf (embed yes) (embed no) ctx] ctx
    p initial s rest _ log raw u hr ht hs he (by simp [transition, ht, embed])
    (future_if ctx yes no hf) hu

theorem match_operand (a empty cell : Trial.Expr) (head tail : String) (ha : Evaluation a)
    (p : Program) (initial : Trial.Start) (s : State) (ctx : Context)
    (rest : List Task) (frames : List Trial.Frame) (log : List Trial.LogEvent)
    (raw : Raw) (u : Trial.RunState)
    (hr : Reachable p initial s)
    (ht : s.tasks = .eval (embed (.matchE a empty head tail cell)) ctx :: rest)
    (hs : s.answer = none) (hf : Future rest frames) (he : Enclosing ctx s)
    (hu : Trial.evalC .approved a ctx.env
      (⟨empty, Trial.toFEnv ctx.env⟩::
       ⟨cell, (tail,none)::(head,none)::Trial.toFEnv ctx.env⟩::frames)
      ctx.branches (logged s log) = (.ok raw, u)) :
    ∃ ticks t v, advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = .chooseMatch (embed empty) head tail (embed cell) ctx :: rest ∧
      t.slots = v :: s.slots ∧ v.raw = raw ∧ t.answer = none ∧
      eraseLog u = observe t ∧ Enclosing ctx t := by
  exact control_operand a ha _ [.chooseMatch (embed empty) head tail (embed cell) ctx]
    ctx p initial s rest _ log raw u hr ht hs he (by simp [transition, ht, embed])
    (future_match ctx empty cell head tail hf) hu

/-- Plain let/if handoff preserves every observation field and older slot. -/
theorem control_handoff (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (rest : List Task) (log : List Trial.LogEvent)
    (hr : Reachable p initial s) (ht : s.tasks = .handoff :: rest)
    (ha : s.answer = none) (he : Enclosing ctx s) :
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      logged t log = logged s log ∧ Enclosing ctx t := by
  let t := commit ⟨{ s with tasks := rest },⟨"Handoff",none⟩,none⟩
  have hx : advance p 1 s = .ok t := by
    simp [advance, step, transition, ht, ha, t]
  exact ⟨t, hx, reachable_advance p initial s t 1 hr hx, rfl, rfl, ha,
    by simp [t, logged, observe, commit, pending], he⟩

/-- The branch-start landmark is committed at the entered environment, with
the original ordered landmark prefix, memory record and pending stack. -/
theorem control_branch_start (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (rest : List Task)
    (hr : Reachable p initial s) (ht : s.tasks = .branchStart ctx :: rest)
    (ha : s.answer = none) (he : Enclosing ctx s) :
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      t.entered = ctx.env ∧ t.mem = s.mem ∧
      t.landmarks = (Trial.snapshot .branchStarts none
        (observe { s with entered := ctx.env })).2.snaps ∧ Enclosing ctx t := by
  let c : Change := ⟨{ s with tasks := rest, entered := ctx.env },
    ⟨"BranchStart",some .branchStarts⟩,none⟩
  have hx : advance p 1 s = .ok (commit c) := by
    simp [advance, step, transition, ht, ha, c]
  refine ⟨commit c, hx, reachable_advance p initial s _ 1 hr hx,
    rfl, rfl, ha, rfl, rfl, ?_, he⟩
  simpa [c, observe, pending] using commit_snapshot c .branchStarts rfl

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.control_operand
#print axioms Full.Proofs.TrialExecution.let_operand
#print axioms Full.Proofs.TrialExecution.if_operand
#print axioms Full.Proofs.TrialExecution.match_operand
#print axioms Full.Proofs.TrialExecution.control_handoff
#print axioms Full.Proofs.TrialExecution.control_branch_start
