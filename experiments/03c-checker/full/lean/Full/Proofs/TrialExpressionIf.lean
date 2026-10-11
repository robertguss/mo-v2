import Full.Proofs.TrialCleanup

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

/-- Exact execution of a successful conditional: decide, clean the selected
continuation, start its branch, evaluate it, and silently hand off its result. -/
theorem evaluation_if {c t e : Trial.Expr}
    (hc : Evaluation c) (ht : Evaluation t) (he : Evaluation e) :
    Evaluation (.ifE c t e) := by
  intro p initial s ctx rest frames log raw u hr htasks hs hf hen hu
  unfold Trial.evalC at hu
  obtain ⟨cv, q, hq, hk⟩ := trial_bind_success _ _ _ _ _ hu
  obtain ⟨token, q', henter, hk⟩ := trial_bind_success _ _ _ _ _ hk
  cases token
  have hq' : q' = { q with scope := ctx.env.reverse.map Prod.snd } := by
    exact (congrArg Prod.snd henter).symm
  subst q'
  cases cv with
  | num n | list a =>
    have bad := congrArg Prod.fst hk
    cases bad
  | bool b =>
    let chosen := if b then t else e
    have hi : Evaluation chosen := by cases b <;> assumption
    have hk' : (Trial.snapshot .branchChosen >>= fun _ =>
        Trial.giveUpDead .approved ctx.env (⟨chosen, Trial.toFEnv ctx.env⟩ :: frames) >>=
        fun _ => Trial.enter ctx.env >>= fun _ => Trial.snapshot .branchStarts >>=
        fun _ => Trial.evalC .approved chosen ctx.env frames ctx.branches)
        { q with scope := ctx.env.reverse.map Prod.snd } = (.ok raw, u) := by
      cases b <;> exact hk
    obtain ⟨token, decision, hd, hk⟩ := trial_bind_success _ _ _ _ _ hk'
    cases token
    obtain ⟨token, clean, hclean, hk⟩ := trial_bind_success _ _ _ _ _ hk
    cases token
    obtain ⟨token, entered, hentered, hk⟩ := trial_bind_success _ _ _ _ _ hk
    cases token
    obtain ⟨token, started, hstarted, hbranch⟩ := trial_bind_success _ _ _ _ _ hk
    cases token
    obtain ⟨n, a, v, ha, hra, hta, hsa, hva, haa, hoa, hena⟩ :=
      if_operand c t e hc p initial s ctx rest frames log (.bool b) q
        hr htasks hs hf hen hq
    let next := [.branchStart ctx,
      .eval (embed chosen) (child ctx (if b then 1 else 2)), .handoff] ++ rest
    let change : Change := ⟨{ a with
      slots := s.slots,
      tasks := dead a.bindings ctx.env next ++ next, entered := ctx.env },
      ⟨"Choose", some .branchChosen⟩, none⟩
    have htrans : transition p a = .ok change := by
      cases b <;> simp [transition, hta, hsa, hva, change, next, chosen]
    obtain ⟨actual, hactual, _⟩ := (Full.Proofs.f1.2 p initial a hra).2.2 haa
    have hactual' : actual = commit change := by
      simpa [step, haa, htrans] using hactual.symm
    subst actual
    have hchoose : advance p 1 a = .ok (commit change) := by
      simp [advance, haa, hactual]
    have hdecision : logged (commit change) q.log = decision := by
      have hd' : decision = (Trial.snapshot .branchChosen none
          { q with scope := ctx.env.reverse.map Prod.snd }).2 :=
        (congrArg Prod.snd hd).symm
      rw [hd', ← logged_of_exact a q hoa]
      simp [logged, observe, change, commit, pending, hsa, hva, Trial.snapshot]
      simpa [observe, change] using (visible_projection change.state).symm
    have hfn : Future next (⟨chosen, Trial.toFEnv ctx.env⟩ :: frames) := by
      exact future_silent _ (fun _ => rfl)
        (future_eval _ _ (future_silent _ (fun _ => rfl) hf))
    obtain ⟨m, z, hz, hrz, htz, hsz, haz, hoz, henz⟩ :=
      TrialCleanup.cleanup_bridge p initial (commit change) ctx next ctx.env
        _ q.log clean (reachable_advance p initial a _ 1 hra hchoose) rfl haa hfn
        (by simpa [Enclosing, change, commit] using hena)
        (by rw [hdecision]; exact hclean)
    obtain ⟨w, hw, hrw, htw, hsw, haw, hew, hmw, hlw, henw⟩ :=
      control_branch_start p initial z ctx _ hrz htz haz henz
    have hstart : logged w clean.log = started := by
      have hi' : entered = { clean with scope := ctx.env.reverse.map Prod.snd } :=
        (congrArg Prod.snd hentered).symm
      have hs' : started = (Trial.snapshot .branchStarts none entered).2 :=
        (congrArg Prod.snd hstarted).symm
      rw [hs', hi', ← logged_of_exact z clean hoz]
      have hw' : w = commit ⟨{ z with
          tasks := [.eval (embed chosen) (child ctx (if b then 1 else 2)),
            .handoff] ++ rest, entered := ctx.env },
          ⟨"BranchStart",some .branchStarts⟩,none⟩ := by
        simpa [advance, step, transition, htz, next, haz] using hw.symm
      simp [logged, observe, Trial.snapshot, hw', commit, pending]
      simpa [observe, visible] using
        (visible_projection { z with entered := ctx.env }).symm
    obtain ⟨k, r, result, hresult, hrr, htr, hsr, hvr, har, hor, henr⟩ :=
      hi p initial w (child ctx (if b then 1 else 2)) (.handoff :: rest)
        frames clean.log raw u hrw htw haw
        (future_silent _ (fun _ => rfl) hf)
        (by simpa [Enclosing, child] using henw)
        (by simpa [child, hstart] using hbranch)
    obtain ⟨final, hfinal, hrfinal, htfinal, hsfinal, hafinal, hofinal, henfinal⟩ :=
      control_handoff p initial r ctx rest u.log hrr htr har
        (by simpa [Enclosing, child] using henr)
    refine ⟨n + 1 + m + 1 + k + 1, final, result, ?_, hrfinal, htfinal,
      ?_, hvr, hafinal, ?_, henfinal⟩
    · rw [advance_add, advance_add, advance_add, advance_add, advance_add, ha]
      simp only [bind, Except.bind, hchoose, hz, hw, hresult, hfinal]
    · simp [hsfinal, hsr, hsw, hsz, change, commit]
    · have hobs := congrArg eraseLog hofinal
      simp only [erase_logged] at hobs
      exact hor.trans hobs.symm

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.evaluation_if
