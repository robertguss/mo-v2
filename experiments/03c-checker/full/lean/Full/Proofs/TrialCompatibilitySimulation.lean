import Full.Statements
import Proofs.MatchContract

/-! Universal infrastructure for the identity embedding. This module does not
claim F6: the recursive execution/continuation simulation is still required.
In particular none of the lemmas below replaces ordered landmark equality by
a subsequence relation. -/
namespace Full.Proofs.TrialCompatibilitySimulation

theorem uses_embed (e : Trial.Expr) (env : Trial.FEnv) (id : Nat) :
    uses (embed e) env id = Trial.usesBinding e env id := by
  induction e generalizing env with
  | var x =>
    simp only [embed, uses, Trial.usesBinding]
    cases Trial.lookupF env x with
    | none => rfl
    | some v => cases v <;> simp
  | num n | nil => simp only [embed, uses, Trial.usesBinding]
  | add a b ha hb | sub a b ha hb | eq a b ha hb | lt a b ha hb | le a b ha hb | cons a b ha hb =>
    simp only [embed, uses, Trial.usesBinding, ha, hb]
  | letE x a b ha hb =>
    simp only [embed, uses, Trial.usesBinding, ha, hb]
  | ifE c t e hc ht he =>
    simp only [embed, uses, Trial.usesBinding, hc, ht, he]
  | matchE s n h t c hs hn hc =>
    simp only [embed, uses, Trial.usesBinding, hs, hn, hc]

theorem eval_task_uses (e : Trial.Expr) (ctx : Counted.Context) (id : Nat) :
    Counted.taskUses id (.eval (embed e) ctx) =
      Trial.usesBinding e (Trial.toFEnv ctx.env) id :=
  uses_embed e (Trial.toFEnv ctx.env) id

theorem bind_task_uses (x : String) (e : Trial.Expr) (ctx : Counted.Context) (id : Nat) :
    Counted.taskUses id (.bind x (embed e) ctx) =
      Trial.usesBinding e ((x,none)::Trial.toFEnv ctx.env) id :=
  uses_embed e ((x,none)::Trial.toFEnv ctx.env) id

theorem if_task_uses (t e : Trial.Expr) (ctx : Counted.Context) (id : Nat) :
    Counted.taskUses id (.chooseIf (embed t) (embed e) ctx) =
      (Trial.usesBinding t (Trial.toFEnv ctx.env) id ||
       Trial.usesBinding e (Trial.toFEnv ctx.env) id) := by
  simp only [Counted.taskUses, uses_embed]

theorem match_task_uses (n c : Trial.Expr) (h t : String)
    (ctx : Counted.Context) (id : Nat) :
    Counted.taskUses id (.chooseMatch (embed n) h t (embed c) ctx) =
      (Trial.usesBinding n (Trial.toFEnv ctx.env) id ||
       Trial.usesBinding c ((t,none)::(h,none)::Trial.toFEnv ctx.env) id) := by
  simp only [Counted.taskUses, uses_embed]

/-- Projection of all fields that determine old landmarks. Ghost values,
invocation metadata and administrative history are not old landmark fields. -/
def observe (s : Counted.State) : Trial.RunState :=
  { mem := s.mem, log := [], bindings := s.bindings.map (·.record),
    scope := s.entered.reverse.map Prod.snd, pending := Counted.pending s,
    outside := s.outside,
    setAside := s.reservations.map (fun r => (r.branch,r.addr)),
    nextBranch := s.nextBranch, nextBinding := s.nextBinding, snaps := s.landmarks }

theorem scope_test (env : Trial.Env) (id : Nat) :
    (env.reverse.map Prod.snd).contains id = env.any (fun p => p.2 == id) := by
  simp only [List.contains_eq_any_beq, List.any_map, List.any_reverse]
  congr 1
  funext p
  apply Bool.eq_iff_iff.mpr
  simp only [Function.comp_apply, beq_iff_eq]
  exact eq_comm

theorem visible_projection (s : Counted.State) :
    (observe s).bindings.filter
        (fun b => (observe s).scope.contains b.id || b.status == .holding) =
      Counted.visible s := by
  simp only [observe, Counted.visible, scope_test]
  induction s.bindings with
  | nil => rfl
  | cons b bs ih =>
    simp only [List.map_cons, List.filter_cons, List.filterMap_cons]
    split <;> simp_all

/-- A Full landmark commit is exactly one Trial snapshot, including every
binding, pending holder, reservation, cell and branch-value field. -/
theorem commit_snapshot (c : Counted.Change) (k : Trial.StepKind)
    (hk : c.action.landmark = some k) :
    (Counted.commit c).landmarks =
      (Trial.snapshot k c.branchValue (observe c.state)).2.snaps := by
  simp only [Counted.commit, hk, Option.map_some, Option.toList_some]
  simp only [Trial.snapshot, observe]
  change c.state.landmarks ++ [_] = c.state.landmarks ++ [_]
  congr 1
  congr 1
  have h := visible_projection c.state
  simp only [observe] at h
  rw [h]

theorem commit_no_landmark (c : Counted.Change)
    (hk : c.action.landmark = none) :
    (Counted.commit c).landmarks = c.state.landmarks := by
  simp [Counted.commit, hk]

theorem commit_record (c : Counted.Change) :
    (Counted.commit c).mem.record = c.state.mem.record := rfl

/-- Capture and plain handoff are genuinely silent on the complete old
observation, not merely on memory or on the last landmark. -/
theorem capture_stutter (p : Program) (s : Counted.State) (rest : List Counted.Task)
    (ht : s.tasks = .capture :: rest) (ha : s.answer = none) :
    ∃ t, Counted.step p s = .ok t ∧ observe t = observe s ∧ t.tasks = rest := by
  refine ⟨Counted.commit ⟨{ s with tasks := rest },⟨"Capture",none⟩,none⟩, ?_, ?_, ?_⟩
  · simp [Counted.step, Counted.transition, ht, ha]
  · simp [observe, Counted.commit, Counted.pending]
  · rfl

theorem handoff_stutter (p : Program) (s : Counted.State) (rest : List Counted.Task)
    (ht : s.tasks = .handoff :: rest) (ha : s.answer = none) :
    ∃ t, Counted.step p s = .ok t ∧ observe t = observe s ∧ t.tasks = rest := by
  refine ⟨Counted.commit ⟨{ s with tasks := rest },⟨"Handoff",none⟩,none⟩, ?_, ?_, ?_⟩
  · simp [Counted.step, Counted.transition, ht, ha]
  · simp [observe, Counted.commit, Counted.pending]
  · rfl

/-- The Trial side of F6 is total for every valid start, by the existing
structural expression contract, not by finite testing. -/
theorem trial_answer (e : Trial.Expr) (initial : Trial.Start)
    (hv : Trial.validStart e initial = .ok ()) :
    ∃ raw, (Trial.runCountedWith .approved e initial).result = .answer raw := by
  have hf := (Trial.Proofs.promises_of_contract e
    (Trial.Proofs.eval_contract e) initial hv).1
  unfold Trial.Finishes Trial.finalAnswer at hf
  change (match (Trial.runCountedWith .approved e initial).result with
    | .answer raw => Trial.readBack (Trial.runCountedWith .approved e initial).memory raw
    | .refused why => .error s!"refused: {why}"
    | .failedRunning why => .error s!"failed while running: {why}").toBool = true at hf
  cases hr : (Trial.runCountedWith .approved e initial).result with
  | answer raw => exact ⟨raw, rfl⟩
  | refused why => simp [hr, Except.toBool] at hf
  | failedRunning why => simp [hr, Except.toBool] at hf

end Full.Proofs.TrialCompatibilitySimulation

#print axioms Full.Proofs.TrialCompatibilitySimulation.uses_embed
#print axioms Full.Proofs.TrialCompatibilitySimulation.eval_task_uses
#print axioms Full.Proofs.TrialCompatibilitySimulation.bind_task_uses
#print axioms Full.Proofs.TrialCompatibilitySimulation.if_task_uses
#print axioms Full.Proofs.TrialCompatibilitySimulation.match_task_uses
#print axioms Full.Proofs.TrialCompatibilitySimulation.scope_test
#print axioms Full.Proofs.TrialCompatibilitySimulation.visible_projection
#print axioms Full.Proofs.TrialCompatibilitySimulation.commit_snapshot
#print axioms Full.Proofs.TrialCompatibilitySimulation.commit_no_landmark
#print axioms Full.Proofs.TrialCompatibilitySimulation.commit_record
#print axioms Full.Proofs.TrialCompatibilitySimulation.trial_answer
#print axioms Full.Proofs.TrialCompatibilitySimulation.capture_stutter
#print axioms Full.Proofs.TrialCompatibilitySimulation.handoff_stutter
