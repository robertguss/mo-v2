import Full.Proofs.ForwardBindingsEnvironment

namespace Full.Proofs.ForwardLeaves
open Counted Statements Forward

inductive Literal : Expr → Value → Prop
  | num (n) : Literal (.num n) (.num n)
  | bool (b) : Literal (.bool b) (.bool b)
  | nil : Literal .nil (.list [])

theorem literal_step (hl : Literal e value)
    (hs : s.tasks = .eval e ctx :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  unfold Related at hrel ⊢
  rw [decode_commit]
  simp only [Control.decode, ha, hs, List.length_cons, Control.focus] at hrel
  cases he : Control.env s ctx.env with
  | error why => simp [he] at hrel
  | ok env =>
    cases hk : Control.continuations s (rest.length + 2) rest s.slots with
    | error why => simp [he, hk] at hrel
    | ok ks =>
      have hea : a = ⟨.eval e env, ks⟩ := by simpa [he, hk] using hrel.symm
      subst a
      have hkc := ForwardBindings.continuations_success hc hk
      cases hl <;> simp [Counted.transition, hs] at hc <;> cases hc
      all_goals
        simp only [ha] at hkc
        simp only [Control.decode, ha]
        exact ForwardValue.focus_value hkc _

theorem env_lookup {id : Nat} (he : Control.env s names = .ok values)
    (hx : names.find? (fun q => q.1 == x) = some (name, id))
    (hb : s.bindings.find? (fun b => b.record.id == id) = some b) :
    Trial.lookupVal values x = some b.value := by
  induction names generalizing values with
  | nil => simp at hx
  | cons pair names ih =>
    rcases pair with ⟨key, bid⟩
    simp only [Control.env, List.mapM_cons, Trial.Proofs.except_bind_eq_ok] at he
    obtain ⟨v, hv, vs, hvs, hvv⟩ := he
    cases hvv
    cases hf : s.bindings.find? (fun b => b.record.id == bid) with
    | none => simp [hf] at hv
    | some binding =>
      simp [hf] at hv
      subst v
      by_cases hk : key = x
      · simp [hk] at hx
        obtain ⟨rfl, rfl⟩ := hx
        rw [hf] at hb
        cases hb
        simp [Trial.lookupVal, hk]
      · simp [hk] at hx
        simpa [Trial.lookupVal, hk] using ih hvs hx

theorem variable_step
    (hs : s.tasks = .eval (.var x) ctx :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  cases hx : ctx.env.find? (fun q => q.1 == x) with
  | none => simp [Counted.transition, hs, hx] at hc
  | some pair =>
    rcases pair with ⟨name, id⟩
    cases hb : s.bindings.find? (fun b => b.record.id == id) with
    | none => simp [Counted.transition, hs, hx, hb] at hc
    | some binding =>
      unfold Related at hrel ⊢
      rw [decode_commit]
      simp only [Control.decode, ha, hs, List.length_cons, Control.focus] at hrel
      cases he : Control.env s ctx.env with
      | error why => simp [he] at hrel
      | ok env =>
        cases hk : Control.continuations s (rest.length + 2) rest s.slots with
        | error why => simp [he, hk] at hrel
        | ok ks =>
          have hea : a = ⟨.eval (.var x) env, ks⟩ := by simpa [he, hk] using hrel.symm
          subst a
          have hl := env_lookup he hx hb
          have hkc := ForwardBindings.continuations_success hc hk
          simp only [Plain.step, hl]
          simp only [Counted.transition, hs, hx, hb, bind, pure,
            Except.bind, Except.pure] at hc
          repeat' first | split at hc | cases hc | contradiction
          all_goals
            simp only [ha] at hkc
            simp only [Control.decode, ha]
            exact ForwardValue.focus_value hkc _

theorem primitive_step
    (hs : s.tasks = .primitive op ctx :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons right vs =>
    cases vs with
    | nil => simp [Counted.transition, hs, hv] at hc
    | cons left older =>
      cases hp : Plain.primitive op left.value right.value with
      | error why => simp [Counted.transition, hs, hv, hp] at hc
      | ok value =>
        unfold Related at hrel ⊢
        rw [decode_commit]
        simp only [Control.decode, ha, hs, hv, List.length_cons, Control.focus,
          Control.continuations] at hrel
        cases hk : Control.continuations s (rest.length + 2) rest older with
        | error why => simp [hk] at hrel
        | ok ks =>
          have hea : a = ⟨.value right.value, .right op left.value :: ks⟩ := by
            simpa [hk] using hrel.symm
          subst a
          have hkc := ForwardBindings.continuations_success hc hk
          simp only [Plain.step, hp]
          simp only [Counted.transition, hs, hv, hp, bind, pure,
            Except.bind, Except.pure] at hc
          repeat' first | split at hc | cases hc | contradiction
          all_goals
            simp only [ha] at hkc
            simp only [Control.decode, ha]
            exact ForwardValue.focus_value hkc _

end Full.Proofs.ForwardLeaves
