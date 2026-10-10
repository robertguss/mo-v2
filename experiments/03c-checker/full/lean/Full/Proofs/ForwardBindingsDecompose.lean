import Full.Proofs.ForwardBindingsControl

namespace Full.Proofs.ForwardBindings
open Counted Statements Forward

set_option maxHeartbeats 2000000 in
theorem decompose_step (hr : Reachable p initial s)
    (hs : s.tasks = .decompose head tail body bid ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨change, hc, rfl⟩ := step_commit ha ht
  refine ⟨?_, decompose_rank_commit p s head tail body bid ctx rest change hs hc⟩
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons v vs =>
    cases hraw : v.raw with
    | num n => simp [Counted.transition, hs, hv, hraw] at hc
    | bool b => simp [Counted.transition, hs, hv, hraw] at hc
    | list l =>
      cases l with
      | none => simp [Counted.transition, hs, hv, hraw] at hc
      | some addr =>
        have hi := (f1.2 p initial s hr).1
        obtain ⟨ph, pt, hval⟩ := Progress.nonempty_value hi (by simp [hv]) hraw
        obtain ⟨cell, hf, hl, hpos⟩ := Progress.root_ready hi
          (Progress.slot_root (by simp [hv]) hraw)
        obtain ⟨hhead, htail⟩ := PreservationCells.decompose_readback hi
          (by simp [hv]) hraw hval hf
        have hz : cell.count ≠ 0 := by omega
        unfold Related at hrel ⊢
        rw [decode_commit]
        simp only [Control.decode, ha, hs, List.length_cons, Control.focus,
          hv, hval] at hrel
        cases hen : Control.env s ctx.env with
        | error why => simp [hen] at hrel
        | ok env =>
          cases hk : Control.continuations s (rest.length + 2) rest vs with
          | error why => simp [hen, hk] at hrel
          | ok ks =>
            have hea : a = ⟨.eval body ((tail,.list pt)::(head,.num ph)::env), ks⟩ := by
              simpa [hen, hk] using hrel.symm
            subst a
            have hec := env_success hc hen
            have hkc := continuations_success hc hk
            have hn0 := fresh_absent hr s.nextBinding (by omega)
            have hn1 := fresh_absent hr (s.nextBinding + 1) (by omega)
            simp only [Counted.transition, hs, hv, hraw, hval, hf, hl,
              bne_self_eq_false, beq_eq_false_iff_ne.mpr hz, Bool.false_or,
              Bool.false_eq_true, reduceIte] at hc
            dsimp only [Trial.Memory.markSetAside, Trial.Memory.setCount,
              Trial.Memory.updateCell, pure, Except.pure, bind, Except.bind,
              Functor.map, Except.map] at hc
            repeat' first
              | simp only [Except.ok.injEq, reduceCtorEq, *] at hc
              | cases hc
              | split at hc
              | contradiction
            all_goals by_cases hcleanup : (cell.link.isSome &&
              !uses body (Trial.toFEnv ((tail,s.nextBinding+1)::
                (head,s.nextBinding)::ctx.env)) (s.nextBinding+1)) = true
            all_goals simp only [ha, child, List.nil_append,
              List.cons_append, Bool.true_or, Bool.false_or, Bool.true_and] at hec hkc ⊢
            all_goals try simp only [hcleanup, reduceCtorEq, ite_true, ite_false,
              List.cons_append, List.nil_append] at hec hkc ⊢
            all_goals simp only [Control.decode, ha, List.length_cons,
              List.length_append, List.nil_append, List.cons_append,
              Control.focus, hv, hval, child, Control.continuations]
            all_goals try simp only [Control.focus,
              List.length_cons, List.length_append, List.nil_append, List.cons_append,
              Control.continuations, hv, hval, child]
            all_goals rw [continuations_fuel _ _ (rest.length + 2) rest vs
              (by omega) (by omega), hkc]
            all_goals simp only [Control.env] at hec ⊢
            all_goals simp only [makeBinding, List.mapM_cons, List.find?_append,
              hn0, hn1, List.find?_cons, List.find?_nil, beq_self_eq_true,
              Option.none_or, ite_true, Nat.add_one_ne_self, beq_eq_false_iff_ne] at hec ⊢
            all_goals simp only [show (s.nextBinding == s.nextBinding+1) = false from by simp,
              reduceIte] at hec ⊢
            all_goals simp only [bind, pure, Except.bind, Except.pure] at hec ⊢
            all_goals rw [hec]
            all_goals simp [hhead]

end Full.Proofs.ForwardBindings
