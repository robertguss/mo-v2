import Full.Proofs.TrialExecutionContract

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

/-- Reinstalling the actual accumulated log recovers the entire source state. -/
theorem logged_of_exact (s : State) (u : Trial.RunState)
    (h : eraseLog u = observe s) : logged s u.log = u := by
  unfold logged
  rw [← h]
  rfl

theorem evaluation_num (n : Int) : Evaluation (.num n) := by
  intro p initial s ctx rest frames log raw u hr ht ha hf he hu
  have hu' : ((Except.ok (.num n) : Except String Raw), logged s log) = (.ok raw, u) := by
    exact hu
  have hv : raw = .num n := by injection hu' with h; exact (Except.ok.inj h).symm
  have hs : u = logged s log := (congrArg Prod.snd hu').symm
  subst raw
  subst u
  obtain ⟨t, hex, htt, hslots, hat, ho, _⟩ := eval_num p s ctx rest frames n ht ha
  refine ⟨1, t, ⟨.num n, .num n⟩, hex, reachable_advance p initial s t 1 hr hex,
    htt, hslots, rfl, hat, ?_, ?_⟩
  · exact (erase_logged s log).trans ho.symm
  · have ht' : t = commit ⟨{ s with
        tasks := rest,
        slots := ⟨.num n,.num n⟩ :: s.slots },⟨"Leaf",none⟩,none⟩ := by
      simpa [advance, step, transition, ht, ha, embed] using hex.symm
    simpa [ht', Enclosing, commit] using he

theorem evaluation_nil : Evaluation .nil := by
  intro p initial s ctx rest frames log raw u hr ht ha hf he hu
  have hu' : ((Except.ok (.list none) : Except String Raw), logged s log) = (.ok raw, u) := by
    exact hu
  have hv : raw = .list none := by injection hu' with h; exact (Except.ok.inj h).symm
  have hs : u = logged s log := (congrArg Prod.snd hu').symm
  subst raw
  subst u
  obtain ⟨t, hex, htt, hslots, hat, ho, _⟩ := eval_nil p s ctx rest frames ht ha
  refine ⟨1, t, ⟨.list none, .list []⟩, hex, reachable_advance p initial s t 1 hr hex,
    htt, hslots, rfl, hat, ?_, ?_⟩
  · exact (erase_logged s log).trans ho.symm
  · have ht' : t = commit ⟨{ s with
        tasks := rest,
        slots := ⟨.list none,.list []⟩ :: s.slots },⟨"Leaf",none⟩,none⟩ := by
      simpa [advance, step, transition, ht, ha, embed] using hex.symm
    simpa [ht', Enclosing, commit] using he

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.evaluation_num
#print axioms Full.Proofs.TrialExecution.evaluation_nil
