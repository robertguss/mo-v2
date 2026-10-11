import Full.Statements

namespace Full.Proofs

private theorem pure_ok (a : α) : (pure a : Except ε α) = .ok a := rfl
private theorem bind_ok (a : α) (f : α → Except ε β) :
    (Except.ok a >>= f) = f a := rfl
private theorem bind_error (e : ε) (f : α → Except ε β) :
    (Except.error e >>= f) = .error e := rfl
private theorem map_ok (a : α) (f : α → β) :
    f <$> (Except.ok a : Except ε α) = .ok (f a) := rfl
private theorem map_error (e : ε) (f : α → β) :
    f <$> (Except.error e : Except ε α) = .error e := rfl

attribute [local simp] pure_ok bind_ok bind_error map_ok map_error

theorem l1 : Statements.L1 := by
  intro p initial s allow r _ hf hd ha hr
  dsimp
  intro denied
  simp [Lifecycle.step, hf, hd, ha, hr, denied]

private theorem advance_terminal (p : Program) (s : Counted.State) (n : Nat)
    (h : s.answer.isSome = true) : Counted.advance p n s = .ok s := by
  cases n <;> simp [Counted.advance, h]

private theorem advance_add (p : Program) (s : Counted.State) (m n : Nat) :
    Counted.advance p (m+n) s =
      (Counted.advance p m s).bind (Counted.advance p n) := by
  induction m generalizing s with
  | zero => simp [Counted.advance, Except.bind]
  | succ m ih =>
    simp only [Nat.succ_add, Counted.advance]
    split
    · rename_i h
      simpa [Except.bind] using (advance_terminal p s n h).symm
    · cases hs : Counted.step p s <;> simp [ih, Except.bind]

private theorem transition_count (p : Program) (s : Counted.State) (c : Counted.Change)
    (h : Counted.transition p s = .ok c) : c.state.steps = s.steps := by
  unfold Counted.transition at h
  simp only [bind, pure, Except.bind, Except.pure] at h
  all_goals repeat' first | split at h | cases h | rfl

theorem step_count (p : Program) (s t : Counted.State)
    (ha : s.answer = none) (hs : Counted.step p s = .ok t) :
    t.steps = s.steps+1 := by
  cases hc : Counted.transition p s with
  | error e => simp [Counted.step, ha, hc] at hs
  | ok change =>
    simp [Counted.step, ha, hc] at hs
    subst t
    simpa [Counted.commit] using transition_count p s change hc

private theorem advance_count (p : Program) (s : Counted.State) (n : Nat)
    (t : Counted.State) (h : Counted.advance p n s = .ok t) :
    t.steps ≤ s.steps+n ∧ (t.answer = none → t.steps = s.steps+n) := by
  induction n generalizing s with
  | zero =>
    simp [Counted.advance] at h
    subst t
    simp
  | succ n ih =>
    cases ha : s.answer with
    | some v =>
      simp [Counted.advance, ha] at h
      subst t
      simp [ha]
    | none =>
      cases hs : Counted.step p s with
      | error e => simp [Counted.advance, ha, hs] at h
      | ok u =>
        simp [Counted.advance, ha, hs] at h
        have hc := step_count p s u ha hs
        obtain ⟨bound, exactCount⟩ := ih u h
        constructor
        · omega
        · intro ht
          have := exactCount ht
          omega

theorem f5 : Statements.F5 := by
  refine ⟨?_, advance_add, advance_terminal, ?_⟩
  · intro p s
    rfl
  · intro p initial s n t _ h
    exact advance_count p s n t h

end Full.Proofs
