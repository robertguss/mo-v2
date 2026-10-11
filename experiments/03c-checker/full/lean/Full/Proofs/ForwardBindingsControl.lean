import Full.Proofs.ForwardValue
import Full.Proofs.Invariance
import Full.Proofs.SimulationInitial
import Full.Proofs.PreservationCells
import Full.Proofs.ForwardBindingsEnvironment

/-! Exact local source steps for binding and branch selection. -/
namespace Full.Proofs.ForwardBindings
open Counted Statements Forward

theorem env_work (s : State) (slots : List Slot) (tasks : List Task) (entered : Env)
    (answer : Option Slot) (names : Env) :
    Control.env {s with slots, tasks, entered, answer} names = Control.env s names := rfl

theorem continuations_work (s : State) (slots : List Slot) (tasks : List Task)
    (entered : Env) (answer : Option Slot) (n : Nat) (ts : List Task) (vs : List Slot) :
    Control.continuations {s with slots, tasks, entered, answer} n ts vs =
      Control.continuations s n ts vs :=
  continuations_bindings {s with slots, tasks, entered, answer} s rfl _ _ _

theorem env_branch (s : State) (slots : List Slot) (tasks : List Task) (entered : Env)
    (answer : Option Slot) (nextBranch : Nat) (names : Env) :
    Control.env {s with slots, tasks, entered, answer, nextBranch} names =
      Control.env s names := rfl

theorem continuations_branch (s : State) (slots : List Slot) (tasks : List Task)
    (entered : Env) (answer : Option Slot) (nextBranch n : Nat)
    (ts : List Task) (vs : List Slot) :
    Control.continuations {s with slots, tasks, entered, answer, nextBranch} n ts vs =
      Control.continuations s n ts vs :=
  continuations_bindings {s with slots, tasks, entered, answer, nextBranch} s rfl _ _ _

theorem focus_dead (s : State) (bs : List Binding) (env : Env)
    (future tasks : List Task) (vs : List Slot) :
    Control.focus s ((dead bs env future ++ tasks).length + 2)
      (dead bs env future ++ tasks) vs =
      Control.focus s (tasks.length + 2) tasks vs := by
  obtain ⟨ids, he⟩ := SimulationInitial.dead_is_prefix bs env future
  simp only [he, List.length_append, List.length_map, Nat.add_assoc]
  exact SimulationInitial.focus_giveBinding_prefix s ids tasks vs _

theorem chooseIf_step (hr : Reachable p initial s)
    (hs : s.tasks = .chooseIf yes no ctx :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t := by
  obtain ⟨change, hc, rfl⟩ := step_commit ha ht
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons v vs =>
    cases hraw : v.raw with
    | num n => simp [Counted.transition, hs, hv, hraw] at hc
    | list l => simp [Counted.transition, hs, hv, hraw] at hc
    | bool b =>
      have hval : v.value = .bool b := by
        have hh := slot_readback (v := v) f1 hr (by simp [hv])
        simpa [hraw, Trial.readBack] using hh.symm
      simp [Counted.transition, hs, hv, hraw] at hc
      cases hc
      unfold Related at hrel ⊢
      rw [decode_commit]
      simp only [Control.decode, ha, hs, List.length_cons, Control.focus,
        hv, Control.continuations] at hrel
      simp only [Control.decode, ha]
      rw [focus_dead]
      simp only [List.length_cons, Control.focus]
      simp only [env_work, continuations_work, child, Control.continuations]
      rw [continuations_fuel s _ (rest.length + 2) rest vs (by omega) (by omega)]
      cases hen : Control.env s ctx.env with
      | error why => simp [hen] at hrel
      | ok env =>
        cases hk : Control.continuations s (rest.length + 2) rest vs with
        | error why => simp [hen, hk] at hrel
        | ok ks =>
          have hea : a = ⟨.value v.value, .choose yes no env :: ks⟩ := by
            simpa [hen, hk] using hrel.symm
          subst a
          simp [Plain.step, hval]

theorem chooseMatch_step (hr : Reachable p initial s)
    (hs : s.tasks = .chooseMatch empty head tail body ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) : Related (Plain.step p a) t := by
  obtain ⟨change, hc, rfl⟩ := step_commit ha ht
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons v vs =>
    cases hraw : v.raw with
    | num n => simp [Counted.transition, hs, hv, hraw] at hc
    | bool b => simp [Counted.transition, hs, hv, hraw] at hc
    | list l =>
      have hi := (f1.2 p initial s hr).1
      have hshape : ∃ items, v.value = .list items ∧
          (l = none → items = []) ∧ (l ≠ none → items ≠ []) := by
        cases l with
        | none =>
          have hh := slot_readback (v := v) f1 hr (by simp [hv])
          have he : v.value = .list [] := by
            simpa [hraw, Trial.readBack, Trial.readList] using hh.symm
          exact ⟨[], he, by simp, by simp⟩
        | some addr =>
          obtain ⟨ph, pt, he⟩ := Progress.nonempty_value hi (by simp [hv]) hraw
          exact ⟨ph :: pt, he, by simp, by simp⟩
      obtain ⟨items, hval, hnil, hcons⟩ := hshape
      simp [Counted.transition, hs, hv, hraw] at hc
      cases hc
      unfold Related at hrel ⊢
      rw [decode_commit]
      simp only [Control.decode, ha, hs, List.length_cons, Control.focus,
        hv, Control.continuations] at hrel
      cases hen : Control.env s ctx.env with
      | error why => simp [hen] at hrel
      | ok env =>
        cases hk : Control.continuations s (rest.length + 2) rest vs with
        | error why => simp [hen, hk] at hrel
        | ok ks =>
          have hea : a = ⟨.value v.value, .split empty head tail body env :: ks⟩ := by
            simpa [hen, hk] using hrel.symm
          subst a
          simp only [Control.decode, ha]
          rw [focus_dead]
          cases l with
          | none =>
            have he := hnil rfl
            subst items
            simp only [List.nil_append, List.cons_append, List.length_cons,
              ite_true, Control.focus, env_branch, continuations_branch,
              child, Control.continuations]
            rw [continuations_fuel s _ (rest.length + 2) rest vs (by omega) (by omega)]
            simp [Plain.step, hval, hen, hk]
          | some addr =>
            cases items with
            | nil => exact False.elim (hcons (by simp) rfl)
            | cons ph pt =>
              simp only [List.nil_append, List.cons_append, List.length_cons,
                Control.focus, hval, env_branch, continuations_branch]
              simp [Plain.step, hval, hen, hk]

theorem bind_step (hr : Reachable p initial s)
    (hs : s.tasks = .bind name body ctx :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t := by
  obtain ⟨change, hc, rfl⟩ := step_commit ha ht
  cases hv : s.slots with
  | nil => simp [Counted.transition, hs, hv] at hc
  | cons v vs =>
    unfold Related at hrel ⊢
    rw [decode_commit]
    simp only [Control.decode, ha, hs, List.length_cons, Control.focus,
      hv, Control.continuations] at hrel
    cases hen : Control.env s ctx.env with
    | error why => simp [hen] at hrel
    | ok env =>
      cases hk : Control.continuations s (rest.length + 2) rest vs with
      | error why => simp [hen, hk] at hrel
      | ok ks =>
        have hea : a = ⟨.value v.value, .bind name body env :: ks⟩ := by
          simpa [hen, hk] using hrel.symm
        subst a
        have hec := env_success hc hen
        have hkc := continuations_success hc hk
        have hnew := fresh_absent hr s.nextBinding (by omega)
        simp [Counted.transition, hs, hv] at hc
        cases hc
        simp only [ha, child] at hec hkc
        simp only [Control.decode, ha]
        rw [focus_dead]
        simp only [List.length_cons, Control.focus, child, Control.continuations]
        rw [continuations_fuel _ _ (rest.length + 2) rest vs (by omega) (by omega)]
        rw [hkc]
        simp only [Control.env] at hec ⊢
        simp only [makeBinding, List.mapM_cons, List.find?_append, hnew,
          List.find?_cons, List.find?_nil, beq_self_eq_true, Option.none_or, ite_true] at hec ⊢
        simp only [bind, pure, Except.bind, Except.pure] at hec ⊢
        rw [hec]
        simp [Plain.step]

end Full.Proofs.ForwardBindings
