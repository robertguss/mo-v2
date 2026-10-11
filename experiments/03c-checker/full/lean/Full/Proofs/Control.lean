import Full.Control

namespace Full.Proofs
open Counted

theorem control_env_bindings (s t : State) (hb : s.bindings = t.bindings)
    (names : Env) : Control.env s names = Control.env t names := by
  simp only [Control.env, hb]

theorem continuations_bindings (s t : State) (hb : s.bindings = t.bindings)
    (n : Nat) (tasks : List Task) (values : List Slot) :
    Control.continuations s n tasks values = Control.continuations t n tasks values := by
  induction n generalizing tasks values with
  | zero => rfl
  | succ n ih =>
    unfold Control.continuations
    split <;> simp_all [control_env_bindings s t hb]

theorem focus_bindings (s t : State) (hb : s.bindings = t.bindings)
    (n : Nat) (tasks : List Task) (values : List Slot) :
    Control.focus s n tasks values = Control.focus t n tasks values := by
  induction n generalizing tasks values with
  | zero => rfl
  | succ n ih =>
    simp only [Control.focus, control_env_bindings s t hb,
      continuations_bindings s t hb, ih]

/-- The saved suffix returned by callTail is strictly shorter than its input. -/
theorem callTail_rest_length (tasks : List Task) (c : Control.CallTail)
    (h : Control.callTail tasks = some c) : c.rest.length < tasks.length := by
  fun_induction Control.callTail tasks generalizing c
  · simp only [Option.some.injEq] at h
    subst c
    simp
  · rename_i e ctx ts ih
    cases ht : Control.callTail ts with
    | none => simp [ht] at h
    | some d =>
      simp [ht] at h
      subst c
      have := ih d ht
      simp only [List.length_cons]
      omega
  · simp_all

/-- Decoder traversal fuel above the task count does not change the result,
including errors. This is an implementation bound, not a source-program bound. -/
theorem continuations_fuel (s : State) (n k : Nat) (tasks : List Task)
    (values : List Slot) (hn : tasks.length < n) (hk : tasks.length < k) :
    Control.continuations s n tasks values = Control.continuations s k tasks values := by
  induction n generalizing k tasks values with
  | zero => omega
  | succ n ih =>
    cases k with
    | zero => omega
    | succ k =>
      have hrec : ∀ ts vs, ts.length < tasks.length →
          Control.continuations s n ts vs = Control.continuations s k ts vs := by
        intro ts vs hts
        apply ih <;> omega
      unfold Control.continuations
      split <;> simp_all only [Nat.add_one, Nat.succ.injEq]
      all_goals first | rfl | skip
      all_goals split
      all_goals simp_all only [List.length_cons]
      all_goals try simp (disch := omega) only [hrec]
      all_goals try omega
      split
      · rename_i c hcall
        have := callTail_rest_length _ c hcall
        simp (disch := omega) only [hrec]
      · rfl

theorem focus_fuel (s : State) (n k : Nat) (tasks : List Task)
    (values : List Slot) (hn : tasks.length < n) (hk : tasks.length < k) :
    Control.focus s n tasks values = Control.focus s k tasks values := by
  induction n generalizing k tasks values with
  | zero => omega
  | succ n ih =>
    cases k with
    | zero => omega
    | succ k =>
      have hrec : ∀ ts vs, ts.length < tasks.length →
          Control.focus s n ts vs = Control.focus s k ts vs := by
        intro ts vs hts
        apply ih <;> omega
      simp only [Control.focus]
      split
      all_goals try simp_all only [List.length_cons]
      all_goals simp (disch := omega) only [hrec, continuations_fuel s n k,
        continuations_fuel s (n+1) (k+1)]

/-- Metadata commit leaves the complete decoded control unchanged. -/
theorem decode_commit (change : Change) :
    Control.decode (commit change) = Control.decode change.state := by
  simp only [Control.decode, commit]
  split
  · rfl
  · exact focus_bindings (commit change) change.state rfl _ _ _

end Full.Proofs
