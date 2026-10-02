import Proofs.Operations

namespace Trial.Proofs

/-- The frame lookup and the counted evaluator's environment lookup agree. -/
theorem lookup_frame_env (env : Env) (x : String) :
    lookupF (toFEnv env) x = (env.find? (fun p => p.1 == x)).map (fun p => some p.2) := by
  induction env with
  | nil => rfl
  | cons p ps ih =>
    rcases p with ⟨y, id⟩
    simp only [toFEnv] at ih
    by_cases he : y = x <;> simp [lookupF, toFEnv, he, ih]

theorem uses_var_iff (env : FEnv) (x : String) (id : Nat) :
    usesBinding (.var x) env id = true ↔ lookupF env x = some (some id) := by
  cases hf : lookupF env x with
  | none => simp [usesBinding, hf]
  | some b => cases b <;> simp [usesBinding, hf]

/-- Giving the same new name to both environments preserves their agreement
about which spellings refer to a particular old binding. -/
theorem lookup_cons_same (env env' : FEnv) (id : Nat)
    (h : ∀ x, lookupF env x = some (some id) ↔ lookupF env' x = some (some id))
    (name : String) (b : Option Nat) :
    ∀ x, lookupF ((name, b) :: env) x = some (some id) ↔
      lookupF ((name, b) :: env') x = some (some id) := by
  intro x
  by_cases he : name = x <;> simp [lookupF, he, h x]

/-- Uses of a binding depend only on which spellings resolve to that binding,
including the shadowing of names introduced by nested lets and matches. -/
theorem uses_binding_congr (e : Expr) (env env' : FEnv) (id : Nat)
    (h : ∀ x, lookupF env x = some (some id) ↔ lookupF env' x = some (some id)) :
    usesBinding e env id = usesBinding e env' id := by
  induction e generalizing env env' with
  | num n => rfl
  | nil => rfl
  | var x =>
    apply Bool.eq_iff_iff.mpr
    rw [uses_var_iff, uses_var_iff]
    exact h x
  | add a b ia ib | sub a b ia ib | eq a b ia ib
  | lt a b ia ib | le a b ia ib | cons a b ia ib =>
    simp only [usesBinding, ia env env' h, ib env env' h]
  | letE x bound body ib ic =>
    simp only [usesBinding, ib env env' h,
      ic _ _ (lookup_cons_same env env' id h x none)]
  | ifE c t e ic it ie =>
    simp only [usesBinding, ic env env' h, it env env' h, ie env env' h]
  | matchE scrut nb x y cb is inb icb =>
    simp only [usesBinding, is env env' h, inb env env' h,
      icb _ _ (lookup_cons_same _ _ id (lookup_cons_same env env' id h x none) y none)]

/-- Replacing a future-name placeholder with a fresh binding does not alter
last-use decisions for any different, older binding. -/
theorem uses_fresh_shadow (e : Expr) (env : FEnv) (name : String) (fresh id : Nat)
    (hne : fresh ≠ id) :
    usesBinding e ((name, some fresh) :: env) id = usesBinding e ((name, none) :: env) id := by
  apply uses_binding_congr
  intro x
  by_cases he : name = x <;> simp [lookupF, he, hne]

theorem lookup_frame_mem (env : FEnv) (x : String) (id : Nat)
    (h : lookupF env x = some (some id)) : (x, some id) ∈ env := by
  induction env with
  | nil => simp [lookupF] at h
  | cons p ps ih =>
    rcases p with ⟨y, b⟩
    by_cases he : y = x
    · simp [lookupF, he] at h
      subst b
      simp [he]
    · simp [lookupF, he] at h
      exact List.mem_cons_of_mem _ (ih h)

/-- An actual binding use must name an id present in the frame environment;
future-name placeholders cannot invent a use of any existing id. -/
theorem uses_binding_mem (e : Expr) (env : FEnv) (id : Nat)
    (h : usesBinding e env id = true) : ∃ x, (x, some id) ∈ env := by
  induction e generalizing env with
  | num n => simp [usesBinding] at h
  | nil => simp [usesBinding] at h
  | var x => exact ⟨x, lookup_frame_mem env x id ((uses_var_iff env x id).mp h)⟩
  | add a b ia ib | sub a b ia ib | eq a b ia ib
  | lt a b ia ib | le a b ia ib | cons a b ia ib =>
    simp only [usesBinding, Bool.or_eq_true] at h
    rcases h with ha | hb
    · exact ia env ha
    · exact ib env hb
  | letE x bound body ib ic =>
    simp only [usesBinding, Bool.or_eq_true] at h
    rcases h with hb | hc
    · exact ib env hb
    · obtain ⟨y, hy⟩ := ic _ hc
      simp at hy
      exact ⟨y, hy⟩
  | ifE c t e ic it ie =>
    simp only [usesBinding, Bool.or_eq_true] at h
    rcases h with (hc | ht) | he
    · exact ic env hc
    · exact it env ht
    · exact ie env he
  | matchE scrut nb x y cb is inb icb =>
    simp only [usesBinding, Bool.or_eq_true] at h
    rcases h with (hs | hn) | hc
    · exact is env hs
    · exact inb env hn
    · obtain ⟨z, hz⟩ := icb _ hc
      simp at hz
      exact ⟨z, hz⟩

/-- A fresh id cannot occur in text whose frame environment contains only older ids. -/
theorem uses_binding_below (e : Expr) (env : FEnv) (next id : Nat)
    (hb : ∀ x j, (x, some j) ∈ env → j < next)
    (h : usesBinding e env id = true) : id < next := by
  obtain ⟨x, hx⟩ := uses_binding_mem e env id h
  exact hb x id hx

theorem used_later_cons (f : Frame) (fs : List Frame) (id : Nat) :
    usedLater (f :: fs) id = (usesBinding f.text f.env id || usedLater fs id) := rfl

theorem used_later_below (fs : List Frame) (next id : Nat)
    (hb : ∀ f ∈ fs, ∀ x j, (x, some j) ∈ f.env → j < next)
    (h : usedLater fs id = true) : id < next := by
  obtain ⟨f, hf, hu⟩ := List.any_eq_true.mp h
  exact uses_binding_below f.text f.env next id (hb f hf) hu

end Trial.Proofs
