import Proofs.MatchCell

namespace Trial.Proofs

/-- The match constructor requires only its three structural induction
hypotheses. Neither branch assumes any unproved final-state obligation. -/
theorem match_contract (scrut nb cb : Expr) (headName tailName : String)
    (hsc : EvalContract scrut) (hn : EvalContract nb) (hb : EvalContract cb) :
    EvalContract (.matchE scrut nb headName tailName cb) := by
  intro start g env plain fs enc k s h hl hf henv ht
  cases hcs : check (plain.map (fun p => (p.1, p.2.kind))) scrut
  · simp [check, hcs] at ht
  rename_i ks
  cases ks <;> simp [check, hcs, expectKind] at ht
  by_cases hnames : headName = tailName
  · simp [hnames] at ht
  simp [hnames] at ht
  cases hcn : check (plain.map (fun p => (p.1, p.2.kind))) nb
  · simp [hcn] at ht
  rename_i kn
  cases hcb : check ((tailName, .list) :: (headName, .number) ::
      plain.map (fun p => (p.1, p.2.kind))) cb
  · simp [hcn, hcb] at ht
  rename_i kb
  by_cases hkind : kn = kb <;> simp [hcn, hcb, hkind] at ht
  subst kb
  subst k
  have hls : LiveFor s.bindings
      ({ text := scrut, env := toFEnv env } :: { text := nb, env := toFEnv env } ::
        { text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs) :=
    hl.congr (fun _ => by simp [used_later_cons, usesBinding, Bool.or_assoc])
  have hplaceholder : ∀ x id,
      (x, some id) ∈ (tailName, none) :: (headName, none) :: toFEnv env → id < s.nextBinding := by
    intro x id hi
    exact hf.head x id (by simpa using hi)
  have hfs := ((hf.tail.prepend cb _ hplaceholder).prepend nb _ hf.head).prepend scrut _ hf.head
  obtain ⟨u, g1, raw, value, hs⟩ := hsc start g env plain
    ({ text := nb, env := toFEnv env } ::
      { text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs)
    enc .list s h hls hfs henv hcs
  have hk := hs.kind
  obtain ⟨items, hv⟩ : ∃ items, value = .list items := by
    cases value <;> simp [PlainValue.kind] at hk
    exact ⟨_, rfl⟩
  subst value
  obtain ⟨link, hr⟩ := read_back_list hs.read
  subst raw
  have hlookup := henv.extend hs.meanings hf.env
  cases link with
  | none =>
    have hi : items = [] := by
      have hr := hs.read
      simpa [readBack, readList] using hr.symm
    subst items
    exact match_nil_post scrut nb cb headName tailName hn start env plain fs enc kn s u g g1 hs hlookup hcn
  | some a =>
    exact match_cell_post scrut nb cb headName tailName hb start env plain fs enc kn s u g g1 a items hs hlookup hcb

/-- Structural induction covers every expression constructor of the locked
language, with arbitrary valid entry state, meanings, and future frames. -/
theorem eval_contract (e : Expr) : EvalContract e := by
  induction e with
  | num n => exact number_contract n
  | add a b ha hb => exact (numeric_contracts a b ha hb).1
  | sub a b ha hb => exact (numeric_contracts a b ha hb).2.1
  | eq a b ha hb => exact (numeric_contracts a b ha hb).2.2.1
  | lt a b ha hb => exact (numeric_contracts a b ha hb).2.2.2.1
  | le a b ha hb => exact (numeric_contracts a b ha hb).2.2.2.2
  | nil => exact nil_contract
  | cons head tail hh ht => exact cons_contract head tail hh ht
  | letE name bound body hbound hbody => exact let_contract name bound body hbound hbody
  | ifE c yes no hc hy hn => exact if_contract c yes no hc hy hn
  | matchE scrut nb headName tailName cb hs hn hb =>
    exact match_contract scrut nb cb headName tailName hs hn hb
  | var x => exact variable_contract x

end Trial.Proofs
