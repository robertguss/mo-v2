import Full.Proofs.TrialExpressionValuesCons

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

theorem values_binding_find (bs : List Binding) (id : Nat) :
    (bs.map (·.record)).find? (fun b => b.id == id) =
      (bs.find? (fun b => b.record.id == id)).map (·.record) := by
  induction bs with
  | nil => rfl
  | cons b bs ih => simp only [List.map_cons, List.find?_cons]; split <;> simp_all

/-- The exact continuation decides acquisition versus transfer. Progress supplies
the successful memory operation; only the textual rule log is erased. -/
theorem evaluation_var (x : String) : Evaluation (.var x) := by
  intro p initial s ctx rest frames log raw u hr ht ha hf he hu
  obtain ⟨t, hs, _⟩ := (Full.Proofs.f1.2 p initial s hr).2.2 ha
  cases hc : transition p s with
  | error why => simp [step, ha, hc] at hs
  | ok c =>
    have htc : t = commit c := by simpa [step, ha, hc] using hs.symm
    cases hen : ctx.env.find? (fun q => q.1 == x) with
    | none => simp [transition, ht, embed, hen] at hc
    | some pair =>
      rcases pair with ⟨name,id⟩
      cases hb : s.bindings.find? (fun b => b.record.id == id) with
      | none => simp [transition, ht, embed, hen, hb] at hc
      | some b =>
        have hbf := values_binding_find s.bindings id
        rw [hb] at hbf
        cases hv : b.record.value with
        | num n | bool n =>
          have hcc : c = ⟨{ s with
            tasks := rest
            slots := ⟨b.record.value,b.value⟩ :: s.slots },⟨"Leaf",none⟩,none⟩ := by
            simpa [transition, ht, embed, hen, hb, hv] using hc.symm
          subst c
          simp [Trial.evalC, hen, Trial.getBinding, logged, observe, hbf, hv] at hu
          obtain ⟨hraw, hu⟩ := hu
          refine ⟨1, t, ⟨b.record.value,b.value⟩, ?_, ?_, ?_, ?_, hv, ?_, ?_, ?_⟩
          · simp [advance, ha, hs]
          · exact reachable_advance p initial s _ 1 hr (by simp [advance, ha, hs])
          · simp [htc, commit]
          · simp [htc, commit]
          · simpa [htc, commit] using ha
          · simp [htc, eraseLog, observe, commit, pending, hv]
          · simpa [htc, Enclosing, commit] using he
        | list addr =>
          cases addr with
          | none =>
            have hcc : c = ⟨{ s with
              tasks := rest
              slots := ⟨b.record.value,b.value⟩ :: s.slots },⟨"Leaf",none⟩,none⟩ := by
              simpa [transition, ht, embed, hen, hb, hv] using hc.symm
            subst c
            simp [Trial.evalC, hen, Trial.getBinding, logged, observe, hbf, hv] at hu
            obtain ⟨hraw, hu⟩ := hu
            refine ⟨1, t, ⟨b.record.value,b.value⟩, ?_, ?_, ?_, ?_, hv, ?_, ?_, ?_⟩
            · simp [advance, ha, hs]
            · exact reachable_advance p initial s _ 1 hr (by simp [advance, ha, hs])
            · simp [htc, commit]
            · simp [htc, commit]
            · simpa [htc, commit] using ha
            · simp [htc, eraseLog, observe, commit, pending, hv]
            · simpa [htc, Enclosing, commit] using he
          | some a =>
            have bh : b.record.status = .holding := by
              cases hh : b.record.status <;> first | rfl | simp [transition, ht, embed, hen, hb, hv, hh] at hc
            cases later : rest.any (taskUses id) with
            | false =>
              have hcc : c = ⟨{ s with
                tasks := rest
                entered := ctx.env
                slots := ⟨b.record.value,b.value⟩ :: s.slots
                bindings := s.bindings.map (fun b => if b.record.id == id then
                  { b with record := { b.record with status := .movedOn } } else b) },
                  ⟨"Leaf",some .holderMoved⟩,none⟩ := by
                simpa [transition, ht, embed, hen, hb, hv, bh, later] using hc.symm
              have snap := commit_snapshot c .holderMoved (by rw [hcc])
              subst c
              have fl : Trial.usedLater frames id = false := (hf id).symm.trans later
              simp [Trial.evalC, hen, Trial.getBinding, logged, observe, hbf, hv, bh,
                fl, Trial.setBindingStatus, Trial.pushPending, Trial.enter] at hu
              obtain ⟨hraw, hu⟩ := hu
              refine ⟨1, t, ⟨b.record.value,b.value⟩, ?_, ?_, ?_, ?_, hv, ?_, ?_, ?_⟩
              · simp [advance, ha, hs]
              · exact reachable_advance p initial s _ 1 hr (by simp [advance, ha, hs])
              · simp [htc, commit]
              · simp [htc, commit]
              · simpa [htc, commit] using ha
              · simp only [Trial.snapshot] at snap
                simp [htc, eraseLog, observe, commit, pending, hv, List.map_map,
                  Function.comp_def, apply_ite] at snap ⊢
                exact snap.symm
              · simpa [htc, Enclosing, commit] using he
            | true =>
              cases hm : s.mem.find? a with
              | none => simp [transition, ht, embed, hen, hb, hv, bh, later, hm] at hc
              | some cell =>
                have hl : cell.status = .live := by
                  cases hh : cell.status <;> first | rfl | simp [transition, ht, embed, hen, hb, hv, bh, later, hm, hh] at hc
                have hcc : c = ⟨{ s with
                  tasks := rest
                  entered := ctx.env
                  slots := ⟨b.record.value,b.value⟩ :: s.slots
                  mem := s.mem.updateCell a (fun d => { d with count := cell.count+1 }) },
                    ⟨"Leaf",some .newHolder⟩,none⟩ := by
                  simpa [transition, ht, embed, hen, hb, hv, bh, later, hm, hl,
                    Trial.Memory.setCount] using hc.symm
                have snap := commit_snapshot c .newHolder (by rw [hcc])
                subst c
                have fl : Trial.usedLater frames id = true := (hf id).symm.trans later
                simp [Trial.evalC, hen, Trial.getBinding, logged, observe, hbf, hv, bh,
                  fl, Trial.addHolder, Trial.getLiveCell, Trial.getCell, hm, hl,
                  Trial.memOp, Trial.Memory.setCount, Trial.pushPending, Trial.enter] at hu
                obtain ⟨hraw, hu⟩ := hu
                refine ⟨1, t, ⟨b.record.value,b.value⟩, ?_, ?_, ?_, ?_, hv, ?_, ?_, ?_⟩
                · simp [advance, ha, hs]
                · exact reachable_advance p initial s _ 1 hr (by simp [advance, ha, hs])
                · simp [htc, commit]
                · simp [htc, commit]
                · simpa [htc, commit] using ha
                · simp only [Trial.snapshot] at snap
                  simp [htc, eraseLog, observe, commit, pending, hv] at snap ⊢
                  exact snap.symm
                · simpa [htc, Enclosing, commit] using he

/-- Recursive operand evaluation followed by the actual reachable constructor
transition, preserving older operands and the entire ordered observation. -/
theorem evaluation_cons (a b : Trial.Expr) (ha : Evaluation a) (hb : Evaluation b) :
    Evaluation (.cons a b) := by
  intro p initial s ctx rest frames log raw u hr ht hs hf he hu
  unfold Trial.evalC at hu
  obtain ⟨rx, l, hl, hk⟩ := trial_bind_success _ _ _ _ _ hu
  obtain ⟨ry, r, hry, hop⟩ := trial_bind_success _ _ _ _ _ hk
  cases rx <;> cases ry
  all_goals try {
    simp [Trial.enter] at hop
    have bad := congrArg Prod.fst hop
    cases bad }
  obtain ⟨n, t, vx, vy, hxt, hrt, htt, hst, hx, hy, hat, hot, het⟩ :=
    binary_operands a b ha hb p initial s ctx .cons rest frames log _ _ l r
      hr ht hs hf he hl hry
  have heq := logged_of_exact t r hot
  obtain ⟨z, v, hz, hrz, htz, hsz, hvz, haz, hoz, hez⟩ :=
    values_cons_primitive p initial t ctx rest vx vy s.slots _ _ r.log raw u
      hrt htt hst hx hy hat het (by rw [heq]; exact hop)
  refine ⟨n+1, z, v, ?_, hrz, htz, hsz, hvz, haz, hoz, hez⟩
  rw [advance_add, hxt]
  exact hz

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.evaluation_var
#print axioms Full.Proofs.TrialExecution.evaluation_cons
