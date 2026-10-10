import Full.Proofs.ForwardCalls

namespace Full.Proofs.ForwardCallEnter
open Counted Statements Forward

theorem parameter_environment (s : State) (bs : List Binding)
    (hu : (s.bindings.map (fun b => b.record.id)).Nodup)
    (hm : ∀ b ∈ bs, b ∈ s.bindings) :
    Control.env s (bs.reverse.map (fun b => (b.record.name,b.record.id))) =
      .ok (bs.reverse.map (fun b => (b.record.name,b.value))) := by
  unfold Control.env
  apply SimulationInitial.mapM_map_ok
  intro b hb
  have hl := Initial.find_key_self s.bindings (fun b => b.record.id) hu
    b (hm b (by simpa using hb))
  simp [hl]

theorem slot_kind (hr : Reachable p initial s) (hv : v ∈ s.slots) :
    v.raw.kind = v.value.kind := by
  have h := slot_readback f1 hr hv
  cases hrw : v.raw <;> cases hval : v.value <;>
    simp_all [Trial.readBack, Trial.RawValue.kind, Trial.PlainValue.kind]
  all_goals
    rename_i l z
    cases he : Trial.readList s.mem s.mem.cells.length l <;> simp [he] at h

theorem enter_positive_step (hr : Reachable p initial s)
    (hs : s.tasks = .enter name (arity+1) ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) : Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  have hu := BindingIdentity.transition_ids (BindingIdentity.reachable_ids hr) hc
  cases hf : signature p.functions name with
  | none => simp [Counted.transition, hs, hf] at hc
  | some f =>
    have hg : ((s.slots.take (arity+1)).reverse.length != arity+1 ||
        (s.slots.take (arity+1)).reverse.map (fun v => v.raw.kind) !=
          f.params.map Prod.snd) = false := by
      by_cases h : ((s.slots.take (arity+1)).reverse.length != arity+1 ||
        (s.slots.take (arity+1)).reverse.map (fun v => v.raw.kind) !=
          f.params.map Prod.snd) = true
      · simp only [Counted.transition, hs, hf, h, ↓reduceIte,
          bind, pure, Except.bind, Except.pure] at hc
        cases hc
      · exact Bool.eq_false_iff.mpr h
    have hkind : ((s.slots.take (arity+1)).reverse.map Slot.value).map
        Trial.PlainValue.kind = f.params.map Prod.snd := by
      have he := (Bool.or_eq_false_iff.mp hg).2
      simp only [bne_eq_false_iff_eq] at he
      rw [← he, List.map_map]
      apply List.map_congr_left
      intro v hv
      exact (slot_kind hr (List.mem_of_mem_take (by simpa using hv))).symm
    unfold Related at hrel ⊢
    rw [decode_commit]
    simp only [Control.decode, ha, hs, List.length_cons, Control.focus] at hrel
    cases hv : s.slots with
    | nil => simp [hv] at hrel
    | cons v vs =>
      simp only [hv, Control.continuations, Nat.add_sub_cancel,
        Nat.add_eq_zero_iff, Nat.one_ne_zero, and_false, beq_iff_eq,
        ↓reduceIte] at hrel
      by_cases hlen : vs.length < arity
      · simp [hlen] at hrel
      simp only [hlen, ↓reduceIte] at hrel
      cases hen : Control.env s ctx.env with
      | error why => simp [hen] at hrel
      | ok env =>
        cases hk : Control.continuations s (rest.length+2) rest (vs.drop arity) with
        | error why => simp [hen, hk] at hrel
        | ok ks =>
          have hea : a = ⟨.value v.value,
              .arguments name ((vs.take arity).reverse.map Slot.value) [] env :: ks⟩ := by
            simpa [hen, hk] using hrel.symm
          subst a
          have hkc := ForwardBindings.continuations_success hc hk
          simp only [Counted.transition, hs, hf, hg, ↓reduceIte,
            bind, pure, Except.bind, Except.pure] at hc
          cases hc
          have henv := parameter_environment
            (s := _) (bs := (f.params.zip ((s.slots.take (arity+1)).reverse)).zipIdx.map
              (fun (((x,_),v),i) => makeBinding (s.nextBinding+i) x v s.nextInvocation
                s!"{name}/parameter/{x}"))
            (by rw [hu]; exact List.nodup_range) (by intro b hb; simp [hb])
          simp only [Control.decode, ha]
          rw [ForwardBindings.focus_dead]
          simp only [List.cons_append, List.nil_append, List.length_cons,
            Control.focus, Control.continuations, hv, List.drop_succ_cons]
          rw [continuations_fuel _ _ (rest.length+2) rest (vs.drop arity)
            (by omega) (by omega)]
          simp only [ha, hv, List.drop_succ_cons, List.cons_append, List.nil_append] at hkc henv ⊢
          rw [hkc, henv]
          simp only [Plain.step]
          rw [← argument_order v vs arity, ← hv]
          simp only [Plain.enter, hf, hkind, beq_self_eq_true, ↓reduceIte,
            pure, Except.pure, bind, Except.bind]
          congr 2
          simp only [List.map_reverse, List.zip_map_left, List.zip_map_right,
            List.map_map, Function.comp_def, makeBinding, Prod.map]
          simp only [← List.map_reverse, List.zip_map_right,
            List.map_map, Function.comp_def, Prod.map, id_eq]
          congr 1
          have he := List.zipIdx_map_fst
            (l := f.params.zip ((s.slots.take (arity+1)).reverse)) 0
          simpa only [List.map_map, Function.comp_def, ← List.map_reverse] using
            congrArg (fun xs => (xs.map (fun x => (x.1.1,x.2.value))).reverse) he

end Full.Proofs.ForwardCallEnter
