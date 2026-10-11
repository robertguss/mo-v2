import Full.Proofs.ForwardCalls
import Full.Proofs.ControlShape

namespace Full.Proofs.ForwardCapture
open Counted Statements Forward

theorem capture_call_step
    (args : List (Expr × Nat))
    (hs : s.tasks = .capture :: .eval b ctx :: .capture ::
      (args.flatMap (fun (e,i) => [.eval e (child outer i), .capture]) ++
        .enter name arity outer :: rest))
    (henv : ctx.env = outer.env) (hlen : args.length + 1 < arity)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) : Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  simp [Counted.transition, hs] at hc
  cases hc
  unfold Related at hrel ⊢
  rw [decode_commit]
  unfold Control.decode at hrel ⊢
  rw [focus_bindings { s with tasks := .eval b ctx :: .capture ::
    (args.flatMap (fun (e,i) => [.eval e (child outer i), .capture]) ++
      .enter name arity outer :: rest) } s rfl]
  simp only [ha, hs, List.length_cons, Control.focus] at hrel ⊢
  cases hv : s.slots with
  | nil => simp [hv] at hrel
  | cons v older =>
    let n := arity - args.length - 2
    have hcount : arity - args.length - 1 = n + 1 := by dsimp [n]; omega
    have hprev : arity - (args.length + 1) - 1 = n := by dsimp [n]; omega
    cases args <;> (try (rename_i pair args; cases pair; cases args <;>
      (try (rename_i pair args; cases pair))))
    all_goals
      simp only [List.flatMap_nil, List.flatMap_cons, List.cons_append,
        List.nil_append, List.length_cons] at hrel ⊢
      simp only [hv, Control.continuations, Control.callTail,
        callTail_arguments, List.map_cons, List.map_nil, List.length_cons,
        List.length_nil] at hrel ⊢
      simp only [bind, pure, Option.bind] at hrel ⊢
      simp only [List.length_cons, List.length_nil, List.length_map] at hrel ⊢ hcount hprev
      rw [hprev] at hrel
      rw [hcount]
      simp only [control_env_bindings _ s rfl, continuations_bindings _ s rfl,
        henv, argument_order, List.drop_succ_cons]
      by_cases hmissing : older.length < n
      · simp [hmissing, Except.bind] at hrel
      have hok : ¬ older.length + 1 < n + 1 := by omega
      simp only [hmissing, hok, ↓reduceIte] at hrel ⊢
      rw [continuations_fuel s _ (rest.length + 2) rest (older.drop n)
        (by (try simp only [List.length_append, List.length_cons]); omega) (by omega)] at hrel
      rw [continuations_fuel s _ (rest.length + 2) rest (older.drop n)
        (by (try simp only [List.length_append, List.length_cons]); omega) (by omega)]
      cases he : Control.env s outer.env with
      | error why => simp [he, Except.bind] at hrel
      | ok env =>
        cases hk : Control.continuations s (rest.length + 2) rest (older.drop n) with
        | error why => simp [he, hk, Except.bind] at hrel
        | ok ks =>
          have hea := hrel.symm
          simp [he, hk, Except.bind, Except.pure] at hea
          subst a
          simp [he, hk, Except.bind, Except.pure, Plain.step]

inductive CaptureTail : List Task → Prop
  | left (b ctx op outer rest) : CaptureTail
      (.eval b ctx :: .capture :: .primitive op outer :: rest)
  | primitive (op ctx rest) : CaptureTail (.primitive op ctx :: rest)
  | call (args : List (Expr × Nat)) (ctx name arity rest)
      (hlen : args.length < arity) : CaptureTail
      (args.flatMap (fun (e,i) => [.eval e (child ctx i), .capture]) ++
        .enter name arity ctx :: rest)

/-- Every capture in the saved work has its actual, well-formed schedule. -/
def Certificate : List Task → Prop
  | [] => True
  | .capture :: ts => CaptureTail ts ∧ Certificate ts
  | _ :: ts => Certificate ts

theorem capture_certificate_tail (task : Task) (h : Certificate (task :: ts)) :
    Certificate ts := by cases task <;> simp_all [Certificate]

theorem capture_certificate_dead (bs : List Binding) (env : Env) (future ts : List Task) :
    Certificate (dead bs env future ++ ts) = Certificate ts := by
  obtain ⟨ids,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ids with
  | nil => rfl
  | cons id ids ih => simpa [Certificate] using ih

theorem capture_certificate_reserved (rs : List Reservation) (ts : List Task) :
    Certificate (rs.map (fun r => .freeReserved r.addr) ++ ts) = Certificate ts := by
  induction rs with
  | nil => rfl
  | cons r rs ih => simpa [Certificate] using ih

theorem capture_certificate_arguments (args : List (Expr × Nat)) (ctx : Context)
    (hrest : Certificate rest) (hlen : args.length ≤ arity) :
    Certificate (args.flatMap (fun (e,i) => [.eval e (child ctx i), .capture]) ++
      .enter name arity ctx :: rest) := by
  induction args with
  | nil => simpa [Certificate] using hrest
  | cons pair args ih =>
    cases pair
    simp only [List.flatMap_cons, List.cons_append, List.nil_append, Certificate]
    exact ⟨CaptureTail.call args ctx name arity rest (by simp only [List.length_cons] at hlen; omega),
      ih (by simp only [List.length_cons] at hlen; omega)⟩

set_option maxHeartbeats 2000000 in
theorem capture_certificate_transition (hs : Certificate s.tasks)
    (ht : Counted.transition p s = .ok c) : Certificate c.state.tasks := by
  cases he : s.tasks with
  | nil => simp [Counted.transition, he] at ht
  | cons task rest =>
    have hrest := capture_certificate_tail task (he ▸ hs)
    cases task
    all_goals simp only [Counted.transition, he, bind, pure, Except.bind, Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try exact hrest
    all_goals simp only [capture_certificate_dead, capture_certificate_reserved,
      List.append_assoc, List.cons_append, List.nil_append]
    all_goals try solve
      | apply capture_certificate_arguments _ _ hrest
        simp
      | simp only [Certificate]
        exact ⟨CaptureTail.left _ _ _ _ _, CaptureTail.primitive _ _ _, hrest⟩
      | simpa [Certificate] using hrest

theorem capture_certificate_begin (hb : Counted.begin p initial = .ok first) :
    Certificate first.tasks := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  simp [capture_certificate_dead, Certificate]

theorem capture_certificate_advance (hs : Certificate s.tasks)
    (ht : Counted.advance p n s = .ok t) : Certificate t.tasks := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance, ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance, Counted.step, ha, hc] at ht
      | ok c =>
        simp [Counted.advance, Counted.step, ha, hc] at ht
        exact ih (s := commit c) (capture_certificate_transition hs hc) ht

theorem capture_certificate_reachable (hr : Reachable p initial s) : Certificate s.tasks := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact capture_certificate_advance (capture_certificate_begin hb) hn

theorem capture_step (hr : Reachable p initial s)
    (hs : s.tasks = .capture :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t ∨ (Related a t ∧ Control.rank t < Control.rank s) := by
  have hcert := capture_certificate_reachable hr
  rw [hs] at hcert
  have htail := hcert.1
  cases htail with
  | left b ctx op outer rest => exact Or.inl (capture_left_step hs ha hrel ht)
  | primitive op ctx rest => exact Or.inr (capture_primitive_step hs ha hrel ht)
  | call args ctx name arity rest hlen =>
    cases args with
    | nil =>
      cases arity with
      | zero => simp at hlen
      | succ arity => exact Or.inr (ForwardCalls.capture_last_step hs ha hrel ht)
    | cons pair args =>
      cases pair
      exact Or.inl (capture_call_step args hs rfl hlen ha hrel ht)

end Full.Proofs.ForwardCapture
