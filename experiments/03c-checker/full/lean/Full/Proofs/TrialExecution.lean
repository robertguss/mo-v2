import Full.Proofs.TrialCompatibilitySimulation

/-! Exact continuation-use infrastructure and execution base cases. No execution
correspondence hypothesis or F6 theorem is introduced here. -/
namespace Full.Proofs.TrialExecution
open TrialCompatibilitySimulation

/-- Pointwise equality, rather than an inclusion, of future-use decisions. -/
def Future (tasks : List Counted.Task) (frames : List Trial.Frame) : Prop :=
  ∀ id, tasks.any (Counted.taskUses id) = Trial.usedLater frames id

theorem future_nil : Future [] [] := by intro id; rfl

theorem future_eval (ctx : Counted.Context) (e : Trial.Expr)
    {tasks : List Counted.Task} {frames : List Trial.Frame} (h : Future tasks frames) :
    Future (.eval (embed e) ctx :: tasks)
      (⟨e, Trial.toFEnv ctx.env⟩ :: frames) := by
  intro id
  simp only [List.any_cons, eval_task_uses, Trial.usedLater]
  rw [h id]
  rfl

theorem future_bind (ctx : Counted.Context) (x : String) (e : Trial.Expr)
    {tasks : List Counted.Task} {frames : List Trial.Frame} (h : Future tasks frames) :
    Future (.bind x (embed e) ctx :: tasks)
      (⟨e, (x,none)::Trial.toFEnv ctx.env⟩ :: frames) := by
  intro id
  simp only [List.any_cons, bind_task_uses, Trial.usedLater]
  rw [h id]
  rfl

theorem future_if (ctx : Counted.Context) (yes no : Trial.Expr)
    {tasks : List Counted.Task} {frames : List Trial.Frame} (h : Future tasks frames) :
    Future (.chooseIf (embed yes) (embed no) ctx :: tasks)
      (⟨yes, Trial.toFEnv ctx.env⟩ :: ⟨no, Trial.toFEnv ctx.env⟩ :: frames) := by
  intro id
  simp only [List.any_cons, if_task_uses, Trial.usedLater]
  rw [h id]
  exact Bool.or_assoc _ _ _

theorem future_match (ctx : Counted.Context) (empty cell : Trial.Expr) (head tail : String)
    {tasks : List Counted.Task} {frames : List Trial.Frame} (h : Future tasks frames) :
    Future (.chooseMatch (embed empty) head tail (embed cell) ctx :: tasks)
      (⟨empty, Trial.toFEnv ctx.env⟩ ::
       ⟨cell, (tail,none)::(head,none)::Trial.toFEnv ctx.env⟩ :: frames) := by
  intro id
  simp only [List.any_cons, match_task_uses, Trial.usedLater]
  rw [h id]
  exact Bool.or_assoc _ _ _

theorem future_decompose (ctx : Counted.Context) (cell : Trial.Expr)
    (head tail : String) (bid : Nat)
    {tasks : List Counted.Task} {frames : List Trial.Frame} (h : Future tasks frames) :
    Future (.decompose head tail (embed cell) bid ctx :: tasks)
      (⟨cell, (tail,none)::(head,none)::Trial.toFEnv ctx.env⟩ :: frames) := by
  intro id
  simp only [List.any_cons, Counted.taskUses, uses_embed, Trial.usedLater]
  rw [h id]
  rfl

theorem future_silent (task : Counted.Task)
    (hs : ∀ id, Counted.taskUses id task = false)
    {tasks : List Counted.Task} {frames : List Trial.Frame} (h : Future tasks frames) :
    Future (task :: tasks) frames := by
  intro id
  simpa only [List.any_cons, hs, Bool.false_or] using h id

theorem future_append {a b : List Counted.Task} {f g : List Trial.Frame}
    (ha : Future a f) (hb : Future b g) : Future (a ++ b) (f ++ g) := by
  intro id
  simp only [List.any_append, ha id, hb id, Trial.usedLater]

/-- A numeric leaf runs with any saved task suffix and any operand prefix;
the complete Trial observation, including ordered landmarks, is unchanged. -/
theorem eval_num (p : Program) (s : Counted.State) (ctx : Counted.Context)
    (rest : List Counted.Task) (frames : List Trial.Frame) (n : Int)
    (ht : s.tasks = .eval (embed (.num n)) ctx :: rest) (ha : s.answer = none) :
    ∃ t, Counted.advance p 1 s = .ok t ∧
      t.tasks = rest ∧ t.slots = ⟨.num n,.num n⟩ :: s.slots ∧
      t.answer = none ∧ observe t = observe s ∧
      (Trial.evalC .approved (.num n) ctx.env frames ctx.branches (observe s)) =
        (.ok (.num n), observe t) := by
  refine ⟨Counted.commit ⟨{ s with tasks := rest, slots := ⟨.num n,.num n⟩ :: s.slots },⟨"Leaf",none⟩,none⟩, ?_⟩
  simp [Counted.advance, Counted.step, Counted.transition, ht, ha, embed,
    Counted.commit, observe, Counted.pending, Trial.evalC]

theorem eval_nil (p : Program) (s : Counted.State) (ctx : Counted.Context)
    (rest : List Counted.Task) (frames : List Trial.Frame)
    (ht : s.tasks = .eval (embed .nil) ctx :: rest) (ha : s.answer = none) :
    ∃ t, Counted.advance p 1 s = .ok t ∧
      t.tasks = rest ∧ t.slots = ⟨.list none,.list []⟩ :: s.slots ∧
      t.answer = none ∧ observe t = observe s ∧
      (Trial.evalC .approved .nil ctx.env frames ctx.branches (observe s)) =
        (.ok (.list none), observe t) := by
  refine ⟨Counted.commit ⟨{ s with tasks := rest, slots := ⟨.list none,.list []⟩ :: s.slots },⟨"Leaf",none⟩,none⟩, ?_⟩
  simp [Counted.advance, Counted.step, Counted.transition, ht, ha, embed,
    Counted.commit, observe, Counted.pending, Trial.evalC]

/-- Start appends exactly the old all-field start snapshot. -/
theorem start (p : Program) (s : Counted.State) (rest : List Counted.Task)
    (ht : s.tasks = .start :: rest) (ha : s.answer = none) :
    ∃ t, Counted.advance p 1 s = .ok t ∧ t.tasks = rest ∧
      t.answer = none ∧ t.mem.record = s.mem.record ∧
      observe t = (Trial.snapshot .start none (observe s)).2 := by
  let c : Counted.Change := ⟨{ s with tasks := rest },⟨"Start",some .start⟩,none⟩
  refine ⟨Counted.commit c, ?_, rfl, ?_, rfl, ?_⟩
  · simp [Counted.advance, Counted.step, Counted.transition, ht, ha, c]
  · exact ha
  · have h := commit_snapshot c .start rfl
    simp only [c, Counted.commit, observe, Counted.pending] at h ⊢
    simp only [Trial.snapshot] at h ⊢
    rw [h]
    rfl

/-- Finish preserves the exact raw answer and record, and appends exactly the
old end snapshot, without consuming the answer's pending holder. -/
theorem finish (p : Program) (s : Counted.State) (rest : List Counted.Task)
    (v : Counted.Slot) (operands : List Counted.Slot)
    (ht : s.tasks = .finish :: rest) (hv : s.slots = v :: operands)
    (ha : s.answer = none) :
    ∃ t, Counted.advance p 1 s = .ok t ∧ t.tasks = rest ∧
      t.answer.map (fun a => a.raw) = some v.raw ∧
      t.mem.record = s.mem.record ∧
      observe t = (Trial.snapshot .end none (observe s)).2 := by
  let c : Counted.Change := ⟨{ s with answer := some v, tasks := rest },⟨"Finish",some .end⟩,none⟩
  refine ⟨Counted.commit c, ?_, rfl, rfl, rfl, ?_⟩
  · simp [Counted.advance, Counted.step, Counted.transition, ht, hv, ha, c]
  · have h := commit_snapshot c .end rfl
    simp only [c, Counted.commit, observe, Counted.pending] at h ⊢
    simp only [Trial.snapshot] at h ⊢
    rw [h]
    rfl

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.future_nil
#print axioms Full.Proofs.TrialExecution.future_eval
#print axioms Full.Proofs.TrialExecution.future_bind
#print axioms Full.Proofs.TrialExecution.future_if
#print axioms Full.Proofs.TrialExecution.future_match
#print axioms Full.Proofs.TrialExecution.future_decompose
#print axioms Full.Proofs.TrialExecution.future_silent
#print axioms Full.Proofs.TrialExecution.future_append
#print axioms Full.Proofs.TrialExecution.eval_num
#print axioms Full.Proofs.TrialExecution.eval_nil
#print axioms Full.Proofs.TrialExecution.start
#print axioms Full.Proofs.TrialExecution.finish
