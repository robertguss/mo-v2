import Full.Proofs.ForwardValue
import Full.Proofs.Invariance
import Full.Proofs.ForwardBindingsControl

namespace Full.Proofs.ForwardCalls
open Counted Statements Forward

theorem enter_zero_step
    (hs : s.tasks = .enter name 0 ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) : Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  cases hf : signature p.functions name with
  | none => simp [Counted.transition, hs, hf] at hc
  | some f =>
    have hp : f.params = [] := by
      by_cases hh : f.params = []
      · exact hh
      · have hm : f.params.map Prod.snd ≠ [] := by simpa using hh
        simp [Counted.transition, hs, hf, hm] at hc
    unfold Related at hrel ⊢
    rw [decode_commit]
    simp only [Control.decode, ha, hs, List.length_cons, Control.focus] at hrel
    cases he : Control.env s ctx.env with
    | error why => simp [he] at hrel
    | ok env =>
      cases hk : Control.continuations s (rest.length + 2) rest s.slots with
      | error why => simp [he, hk] at hrel
      | ok ks =>
        have hea : a = ⟨.eval (.call name []) env, ks⟩ := by
          simpa [he, hk] using hrel.symm
        subst a
        have hkc := ForwardBindings.continuations_success hc hk
        simp [Counted.transition, hs, hf, hp] at hc
        cases hc
        simp only [Control.decode, ha]
        rw [ForwardBindings.focus_dead]
        simp only [List.length_cons, Control.focus, Control.continuations]
        rw [continuations_fuel _ _ (rest.length + 2) rest s.slots (by omega) (by omega)]
        simp only [ha] at hkc
        rw [hkc]
        simp [Plain.step, Plain.enter, hf, hp, Control.env]

theorem dispatch_nonempty_step
    (hs : s.tasks = .eval (.call name (e :: args)) ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) : Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  simp [Counted.transition, hs] at hc
  cases hc
  unfold Related at hrel ⊢
  rw [decode_commit]
  unfold Control.decode at hrel ⊢
  simp only [ha, hs, List.length_cons, Control.focus] at hrel
  cases hen : Control.env s ctx.env with
  | error why => simp [hen] at hrel
  | ok env =>
    cases hk : Control.continuations s (rest.length + 2) rest s.slots with
    | error why => simp [hen, hk] at hrel
    | ok ks =>
      have hea : a = ⟨.eval (.call name (e::args)) env, ks⟩ := by
        simpa [hen, hk] using hrel.symm
      subst a
      simp only [Plain.step]
      cases args <;> (try (rename_i b bs; cases bs))
      all_goals
        simp only [List.zipIdx_cons, List.zipIdx_nil, List.flatMap_cons, List.flatMap_append,
        List.flatMap_nil, List.append_assoc, List.cons_append, List.nil_append]
        simp only [ha, Control.focus, env_tasks, continuations_tasks]
        simp only [Control.continuations, Control.callTail, callTail_arguments]
        simp only [bind, pure, Option.bind]
        simp only [List.length_map, List.length_zipIdx, List.length_cons, List.length_nil,
        Nat.add_sub_cancel, Nat.add_sub_cancel_left, Nat.add_sub_add_right, Nat.sub_self, List.take_zero, List.reverse_nil,
        List.map_nil, List.drop_zero, List.map_cons, Nat.sub_zero]
        try simp only [List.map_map, Function.comp_def, List.zipIdx_map_fst]
        rw [continuations_fuel s _ (rest.length + 2) rest s.slots
          (by
            try simp only [List.length_append, List.length_cons]
            omega) (by omega)]
        simp [child, hen, hk, Except.bind, Except.pure]

theorem capture_last_step
    (hs : s.tasks = .capture :: .enter name (arity+1) ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  simp [Counted.transition, hs] at hc
  cases hc
  constructor
  · unfold Related at hrel ⊢
    rw [decode_commit]
    unfold Control.decode at hrel ⊢
    simp only [focus_bindings { s with tasks := .enter name (arity+1) ctx :: rest } s rfl]
    simp only [ha, hs, List.length_cons, Control.focus] at hrel ⊢
    cases hv : s.slots with
    | nil => simp [hv] at hrel
    | cons v vs =>
      simp only [hv, Control.continuations, Control.callTail] at hrel ⊢
      simp only [List.length_nil, Nat.sub_zero, Nat.add_sub_cancel,
        Nat.add_eq_zero_iff, Nat.one_ne_zero, and_false, beq_iff_eq,
        Bool.false_eq_true, ↓reduceIte] at hrel ⊢
      by_cases hlen : vs.length < arity
      · simp [hlen] at hrel
      simp only [hlen, ↓reduceIte] at hrel ⊢
      rw [continuations_fuel s (rest.length + 3) (rest.length + 2)
        rest (vs.drop arity) (by omega) (by omega)] at hrel
      simpa using hrel

  · simp only [Control.rank, commit, hs, ← List.sum_eq_foldl_nat,
      List.map_cons, List.sum_cons]
    simp

theorem return_step
    (hs : s.tasks = .returning frame ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) : Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons v vs =>
    cases hf : s.frames with
    | nil => simp [Counted.transition, hs, hv, hf] at hc
    | cons f fs =>
      by_cases hid : f.id = frame.id
      · simp [Counted.transition, hs, hv, hf, hid] at hc
        cases hc
        unfold Related at hrel ⊢
        rw [decode_commit]
        unfold Control.decode at hrel ⊢
        simp only [ha, hs, hv, List.length_cons, Control.focus,
          Control.continuations] at hrel
        cases hk : Control.continuations s (rest.length + 2) rest vs with
        | error why => simp [hk] at hrel
        | ok ks =>
          have hea : a = ⟨.value v.value, .returning frame.name :: ks⟩ := by
            simpa [hk] using hrel.symm
          subst a
          simp only [Plain.step]
          simp only [ha]
          rw [focus_bindings ({ s with frames := fs, entered := ctx.env, slots := v::vs, tasks := rest, events := s.events ++ [.returning frame.id v], answer := none }) s rfl]
          exact ForwardValue.focus_value hk v
      · simp [Counted.transition, hs, hv, hf, hid] at hc

/-- The cases below need no reachability facts: correspondence and a successful
transition already supply every decoder premise they use. -/
inductive ReadyCase : List Task → Prop
  | dispatch (name e args ctx rest) :
      ReadyCase (.eval (.call name (e::args)) ctx :: rest)
  | dispatchZero (name ctx rest) : ReadyCase (.eval (.call name []) ctx :: rest)
  | lastCapture (name arity ctx rest) :
      ReadyCase (.capture :: .enter name (arity+1) ctx :: rest)
  | enterZero (name ctx rest) : ReadyCase (.enter name 0 ctx :: rest)
  | returning (frame ctx rest) : ReadyCase (.returning frame ctx :: rest)

theorem ready_step (_hr : Reachable p initial s) (hshape : ReadyCase s.tasks)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t ∨ (Related a t ∧ Control.rank t < Control.rank s) := by
  generalize hs : s.tasks = tasks at hshape
  cases hshape with
  | dispatch name e args ctx rest =>
    exact Or.inl (dispatch_nonempty_step hs ha hrel ht)
  | dispatchZero name ctx rest =>
    exact Or.inr (dispatch_zero_step hs ha hrel ht)
  | lastCapture name arity ctx rest =>
    exact Or.inr (capture_last_step hs ha hrel ht)
  | enterZero name ctx rest =>
    exact Or.inl (enter_zero_step hs ha hrel ht)
  | returning frame ctx rest =>
    exact Or.inl (return_step hs ha hrel ht)

end Full.Proofs.ForwardCalls
