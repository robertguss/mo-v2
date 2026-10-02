import Promises

namespace Trial.Proofs

@[simp] theorem except_pure (a : α) : (pure a : Except ε α) = .ok a := rfl

@[simp] theorem except_throw (e : ε) : (throw e : Except ε α) = .error e := rfl

@[simp] theorem except_bind_ok (a : α) (f : α → Except ε β) :
    (Except.ok a >>= f) = f a := rfl

@[simp] theorem except_bind_error (e : ε) (f : α → Except ε β) :
    (Except.error e >>= f) = .error e := rfl

@[simp] theorem except_map_ok (a : α) (f : α → β) :
    f <$> (Except.ok a : Except ε α) = .ok (f a) := rfl

@[simp] theorem except_map_error (e : ε) (f : α → β) :
    f <$> (Except.error e : Except ε α) = .error e := rfl

/-- Looking up a value and then its kind agrees with looking up the kind. -/
theorem lookup_kind (env : List (String × PlainValue)) (x : String) :
    lookupKind (env.map (fun p => (p.1, p.2.kind))) x =
      (lookupVal env x).map PlainValue.kind := by
  induction env with
  | nil => rfl
  | cons p rest ih =>
    rcases p with ⟨y, v⟩
    simp only [List.map_cons, lookupKind, lookupVal]
    split <;> simp_all

/-- The kind guard succeeds exactly when the actual kind is the required kind. -/
theorem expect_kind_ok (what : String) (want got : Kind) :
    expectKind what want got = .ok () ↔ got = want := by
  unfold expectKind
  split <;> simp_all

/-- The plain evaluator returns a value of the kind determined from the text. -/
theorem eval_typed (e : Expr) (env : List (String × PlainValue)) (k : Kind)
    (h : check (env.map (fun p => (p.1, p.2.kind))) e = .ok k) :
    ∃ v, eval env e = .ok v ∧ v.kind = k := by
  induction e generalizing env k with
  | num n =>
    simp [check] at h
    exact ⟨.num n, rfl, h⟩
  | nil =>
    simp [check] at h
    exact ⟨.list [], rfl, h⟩
  | var x =>
    simp only [check, lookup_kind] at h
    cases hv : lookupVal env x with
    | none => simp [hv] at h
    | some v =>
      simp [hv] at h
      exact ⟨v, by simp [eval, hv], h⟩
  | add a b ia ib | sub a b ia ib | eq a b ia ib
  | lt a b ia ib | le a b ia ib | cons a b ia ib =>
    simp only [check] at h
    cases ha : check (env.map (fun p => (p.1, p.2.kind))) a with
    | error why => simp [ha] at h
    | ok ka =>
      cases hb : check (env.map (fun p => (p.1, p.2.kind))) b with
      | error why => cases ka <;> simp [ha, hb, expectKind] at h
      | ok kb =>
        cases ka <;> cases kb <;> simp [ha, hb, expectKind] at h
        all_goals
          subst k
          obtain ⟨va, ea, ta⟩ := ia env _ ha
          obtain ⟨vb, eb, tb⟩ := ib env _ hb
          cases va <;> cases vb <;> simp [PlainValue.kind] at ta tb
          all_goals simp [eval, ea, eb, PlainValue.kind]
  | letE x bound body ib ic =>
    simp only [check] at h
    cases hb : check (env.map (fun p => (p.1, p.2.kind))) bound with
    | error why => simp [hb] at h
    | ok kb =>
      simp [hb] at h
      obtain ⟨vb, eb, tb⟩ := ib env kb hb
      obtain ⟨vc, ec, tc⟩ := ic ((x, vb) :: env) k (by simpa [tb] using h)
      exact ⟨vc, by simpa [eval, eb] using ec, tc⟩
  | ifE c t e ic it ie =>
    simp only [check] at h
    cases hc : check (env.map (fun p => (p.1, p.2.kind))) c with
    | error why => simp [hc] at h
    | ok kc =>
      cases kc <;> simp [hc, expectKind] at h
      cases ht : check (env.map (fun p => (p.1, p.2.kind))) t with
      | error why => simp [ht] at h
      | ok kt =>
        cases he : check (env.map (fun p => (p.1, p.2.kind))) e with
        | error why => simp [ht, he] at h
        | ok ke =>
          by_cases htk : kt = ke <;> simp [ht, he, htk] at h
          subst ke
          subst k
          obtain ⟨vc, ec, tc⟩ := ic env .bool hc
          cases vc <;> simp [PlainValue.kind] at tc
          rename_i b
          cases b
          · obtain ⟨ve, ee, te⟩ := ie env _ he
            exact ⟨ve, by simpa [eval, ec] using ee, te⟩
          · obtain ⟨vt, et, tt⟩ := it env _ ht
            exact ⟨vt, by simpa [eval, ec] using et, tt⟩
  | matchE scrut nb x y cb is inb icb =>
    simp only [check] at h
    cases hs : check (env.map (fun p => (p.1, p.2.kind))) scrut with
    | error why => simp [hs] at h
    | ok ks =>
      cases ks <;> simp [hs, expectKind] at h
      by_cases hxy : x = y <;> simp [hxy] at h
      cases hn : check (env.map (fun p => (p.1, p.2.kind))) nb with
      | error why => simp [hn] at h
      | ok kn =>
        cases hc : check ((y, .list) :: (x, .number) :: env.map (fun p => (p.1, p.2.kind))) cb with
        | error why => simp [hn, hc] at h
        | ok kc =>
          by_cases hnk : kn = kc <;> simp [hn, hc, hnk] at h
          subst kc
          subst k
          obtain ⟨vs, es, ts⟩ := is env .list hs
          cases vs <;> simp [PlainValue.kind] at ts
          rename_i xs
          cases xs with
          | nil =>
            obtain ⟨vn, en, tn⟩ := inb env _ hn
            exact ⟨vn, by simpa [eval, es] using en, tn⟩
          | cons a rest =>
            obtain ⟨vc, ec, tc⟩ := icb ((y, .list rest) :: (x, .num a) :: env) kn
              (by simpa [PlainValue.kind] using hc)
            exact ⟨vc, by simpa [eval, es] using ec, tc⟩

/-- The public plain runner succeeds on every well-formed plain input. -/
theorem run_plain_typed (e : Expr) (env : List (String × PlainValue)) (k : Kind)
    (h : wellFormed (env.map (fun p => (p.1, p.2.kind))) e = .ok k) :
    ∃ v, runPlain e env = .ok v ∧ v.kind = k := by
  have hc : check (env.map (fun p => (p.1, p.2.kind))) e = .ok k := by
    unfold wellFormed at h
    split at h
    · simp at h
    · split at h
      · simp at h
      · exact h
  obtain ⟨v, hv, hk⟩ := eval_typed e env k hc
  exact ⟨v, by simp [runPlain, h, hv], hk⟩

end Trial.Proofs
