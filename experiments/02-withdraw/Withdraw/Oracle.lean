import Withdraw.Spec

/-!
# Experiment 2: the test oracle matches the promises

Locked. The testing methods check `holdsAt` at chosen inputs; the proof checks
`Correct` for all inputs. This theorem shows the two say the same thing, so a
test failure and a proof failure are failures of the same four promises.
-/

namespace Withdraw

theorem holdsAt_iff (f : Impl) : (∀ b a, holdsAt f b a = true) ↔ Correct f := by
  constructor
  · intro h
    refine ⟨?_, ?_, ?_, ?_⟩
    · intro b a r hf
      have := h b a
      simp only [holdsAt, hf, Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at this
      exact this.1
    · intro b a ha hab
      have := h b a
      cases hf : f b a with
      | ok r => exact ⟨r, rfl⟩
      | error e =>
        cases e <;> simp only [holdsAt, hf, decide_eq_true_eq, beq_iff_eq] at this <;> omega
    · intro b a hba
      have := h b a
      cases hf : f b a with
      | ok r =>
        simp only [holdsAt, hf, Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at this
        omega
      | error e =>
        cases e
        · rfl
        · simp only [holdsAt, hf, beq_iff_eq] at this; omega
    · intro b
      have := h b 0
      cases hf : f b 0 with
      | ok r =>
        simp only [holdsAt, hf, Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq] at this
        omega
      | error e =>
        cases e
        · simp only [holdsAt, hf, decide_eq_true_eq] at this; omega
        · rfl
  · rintro ⟨h1, h2, h3, h4⟩ b a
    by_cases ha : a = 0
    · subst ha; simp [holdsAt, h4 b]
    · by_cases hab : a ≤ b
      · obtain ⟨r, hr⟩ := h2 b a (by omega) hab
        have := h1 b a r hr
        simp only [holdsAt, hr, Bool.and_eq_true, beq_iff_eq, decide_eq_true_eq]
        omega
      · simp [holdsAt, h3 b a (by omega)]; omega

end Withdraw
