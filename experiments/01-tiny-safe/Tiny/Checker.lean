import Tiny.Spec

/-!
# Experiment 1: the checker

The builder's part: a type checker for the tiny language in `Tiny/Spec.lean`,
and proofs that it keeps both promises there (`Safe` and `Useful`).
-/

namespace Tiny

/-- The type checker. `none` means the program is rejected. -/
def typecheck : Term → Option Ty
  | .num _ => some .num
  | .bool _ => some .bool
  | .add a b =>
    match typecheck a, typecheck b with
    | some .num, some .num => some .num
    | _, _ => none
  | .eq a b =>
    match typecheck a, typecheck b with
    | some ta, some tb => if ta = tb then some .bool else none
    | _, _ => none
  | .ite c t e =>
    match typecheck c, typecheck t, typecheck e with
    | some .bool, some tt, some te => if tt = te then some tt else none
    | _, _, _ => none

/-- A value of type `num` is a number. -/
theorem Value.ty_num {v : Value} (h : v.ty = .num) : ∃ n, v = .num n := by
  cases v with
  | num n => exact ⟨n, rfl⟩
  | bool b => cases h

/-- A value of type `bool` is a boolean. -/
theorem Value.ty_bool {v : Value} (h : v.ty = .bool) : ∃ b, v = .bool b := by
  cases v with
  | num n => cases h
  | bool b => exact ⟨b, rfl⟩

/-- **Safety.** Every program the checker approves runs to a value of the
type the checker gave it. -/
theorem safety : Safe typecheck := by
  intro e
  induction e with
  | num n =>
    intro t h
    simp only [typecheck, Option.some.injEq] at h
    subst h
    exact ⟨.num n, rfl, rfl⟩
  | bool b =>
    intro t h
    simp only [typecheck, Option.some.injEq] at h
    subst h
    exact ⟨.bool b, rfl, rfl⟩
  | add a b iha ihb =>
    intro t h
    simp only [typecheck] at h
    split at h
    · rename_i hta htb
      simp only [Option.some.injEq] at h
      subst h
      obtain ⟨va, hea, hva⟩ := iha _ hta
      obtain ⟨vb, heb, hvb⟩ := ihb _ htb
      obtain ⟨x, rfl⟩ := Value.ty_num hva
      obtain ⟨y, rfl⟩ := Value.ty_num hvb
      exact ⟨.num (x + y), by simp only [eval, hea, heb], rfl⟩
    · cases h
  | eq a b iha ihb =>
    intro t h
    simp only [typecheck] at h
    split at h
    · rename_i ta tb hta htb
      split at h
      · rename_i hab
        simp only [Option.some.injEq] at h
        subst h
        subst hab
        obtain ⟨va, hea, hva⟩ := iha _ hta
        obtain ⟨vb, heb, hvb⟩ := ihb _ htb
        cases ta with
        | num =>
          obtain ⟨x, rfl⟩ := Value.ty_num hva
          obtain ⟨y, rfl⟩ := Value.ty_num hvb
          exact ⟨.bool (x == y), by simp only [eval, hea, heb], rfl⟩
        | bool =>
          obtain ⟨x, rfl⟩ := Value.ty_bool hva
          obtain ⟨y, rfl⟩ := Value.ty_bool hvb
          exact ⟨.bool (x == y), by simp only [eval, hea, heb], rfl⟩
      · cases h
    · cases h
  | ite c u w ihc ihu ihw =>
    intro t h
    simp only [typecheck] at h
    split at h
    · rename_i tu tw htc htu htw
      split at h
      · rename_i huw
        simp only [Option.some.injEq] at h
        subst h
        subst huw
        obtain ⟨vc, hec, hvc⟩ := ihc _ htc
        obtain ⟨b, rfl⟩ := Value.ty_bool hvc
        cases b with
        | true =>
          obtain ⟨vu, heu, hvu⟩ := ihu _ htu
          exact ⟨vu, by simp only [eval, hec, heu], hvu⟩
        | false =>
          obtain ⟨vw, hew, hvw⟩ := ihw _ htw
          exact ⟨vw, by simp only [eval, hec, hew], hvw⟩
      · cases h
    · cases h

/-- **Usefulness.** The checker accepts and rejects the spec's examples. -/
theorem useful : Useful typecheck := by
  constructor
  · intro p hp
    simp only [mustAccept, List.mem_cons, List.not_mem_nil, or_false] at hp
    rcases hp with rfl | rfl | rfl | rfl | rfl <;> rfl
  · intro e he
    simp only [mustReject, List.mem_cons, List.not_mem_nil, or_false] at he
    rcases he with rfl | rfl | rfl | rfl <;> rfl

end Tiny
