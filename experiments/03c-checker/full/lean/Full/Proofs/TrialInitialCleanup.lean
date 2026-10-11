import Full.Proofs.TrialInitialization
import Full.Proofs.TrialCleanup

namespace Full.Proofs.TrialInitialization
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialExecution

theorem initial_cleanup_bridge : InitialCleanupBridge := by
  intro e initial u hv hu
  let env := Trial.Proofs.inputEnv initial
  let q := { Trial.Proofs.inputState initial with scope := env.reverse.map Prod.snd }
  have hq : Trial.Proofs.StateInvariant initial (Trial.Proofs.inputMeanings initial) [] q :=
    (Trial.Proofs.initialized_state e initial hv).scope _
  have hi : ∀ p ∈ env, p.2 < q.nextBinding := (Trial.Proofs.initialized_frame e initial hv).env
  have hn : (env.reverse.map Prod.snd).Nodup := by
    simpa [env, Trial.Proofs.inputEnv, List.map_map, Function.comp_def,
      Trial.Proofs.input_ids_range] using List.nodup_range (n := initial.inputs.length)
  have hh : ∀ b ∈ q.bindings, (∃ a, b.value = .list (some a)) → b.status = .holding := by
    intro b hb hval
    obtain ⟨a, ha⟩ := hval
    simpa [ha] using Trial.Proofs.input_binding_status initial.inputs 0 b hb
  have hsame := Trial.Proofs.input_cleanup_eq env.reverse e env initial
    (Trial.Proofs.inputMeanings initial) [] q hq
    (fun p hp => hi p (by simpa using hp)) hn (fun b hb _ hval => hh b hb hval)
  change (forIn env.reverse PUnit.unit (fun p _ => Trial.Proofs.inputCleanupStep e env p)
    : Trial.M PUnit) q = (.ok (), u) at hu
  rw [hsame] at hu
  obtain ⟨first, hb⟩ := begin_success e initial hv
  have ho := begin_observe ⟨[],embed e⟩ initial first hb
  have hlogged : logged first [] = q := ho
  let ctx : Context := { env := env }
  let rest : List Task := [.start, .eval (embed e) ctx, .finish]
  have hwork : first.tasks = dead first.bindings env rest ++ rest ∧
      first.slots = [] ∧ first.answer = none ∧ first.reservations = [] := by
    obtain ⟨_, edges, bs, _, hbs, rfl⟩ := Initial.begin_shape _ initial first hb
    have hr := input_records initial.inputs 0 initial.toMemory bs hbs
    have henv : bs.reverse.map (fun b => (b.record.name,b.record.id)) = env := by
      simp only [env, Trial.Proofs.inputEnv, List.map_reverse]
      rw [← hr, List.map_map]
      rfl
    simp [rest, ctx, henv]
  have hf : Future rest [⟨e, Trial.toFEnv env⟩] := by
    intro id
    simp [rest, taskUses, ctx, uses_embed, Trial.usedLater]
  obtain ⟨n, t, hex, hrt, htt, hst, hat, hot, hrs⟩ :=
    TrialCleanup.cleanup_loop env.reverse ⟨[],embed e⟩ initial first rest
      [⟨e, Trial.toFEnv env⟩] [] u ⟨first, 0, hb, rfl⟩
      (by simpa using hwork.1) hwork.2.2.1 hf (by rw [hlogged]; exact hu)
  exact ⟨t, hrt, htt, hst.trans hwork.2.1, hat, hrs.trans hwork.2.2.2, hot.symm⟩

end Full.Proofs.TrialInitialization

#print axioms Full.Proofs.TrialInitialization.initial_cleanup_bridge
