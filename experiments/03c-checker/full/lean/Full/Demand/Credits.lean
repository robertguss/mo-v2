import Full.Demand
import Full.Proofs.PlainTyping

namespace Full.Demand
open Full.Proofs.PlainTyping

theorem spend_length (xs ys : List Nat) (h : spend xs = .ok ys) :
    ys.length = xs.length := by
  induction xs generalizing ys with
  | nil => simp [spend] at h
  | cons x xs ih =>
    cases x with
    | zero =>
      simp only [spend, bind_ok] at h
      obtain ⟨zs,hz,he⟩ := h
      simp only [pure_eq, Except.ok.injEq] at he
      subst ys
      simp [ih _ hz]
    | succ n =>
      simp only [spend, Except.ok.injEq] at h
      subst ys
      rfl

theorem fold_length (xs : List α) (f : List Nat → α → Except String (List Nat))
    (step : ∀ x ∈ xs, ∀ a b, f a x = .ok b → b.length = a.length)
    (h : xs.foldlM f a = .ok b) : b.length = a.length := by
  induction xs generalizing a with
  | nil => simp at h; subst b; rfl
  | cons x xs ih =>
    simp only [List.foldlM_cons, bind_ok] at h
    obtain ⟨mid,hm,ht⟩ := h
    exact (ih (fun y hy => step y (by simp [hy])) ht).trans (step x (by simp) a mid hm)

/-- Every branch merge aligns the complete active match stack. zipWith never
silently truncates a successful analysis's credit stack. -/
theorem expression_length (e : Expr) (fs : List Function) (env : List (String × Kind))
    (a b : List Nat) (h : expression fs env a e = .ok b) : b.length = a.length := by
  cases e with
  | num n | bool q | nil | var x =>
    simp [expression] at h
    subst b
    rfl
  | bin op left right =>
    simp only [expression, bind_ok] at h
    obtain ⟨x,hx,y,hy,h⟩ := h
    have hl := expression_length left fs env a x hx
    have hr := expression_length right fs env x y hy
    split at h
    · exact (spend_length y b h).trans (hr.trans hl)
    · simp only [pure_eq, Except.ok.injEq] at h
      subst b
      exact hr.trans hl
  | letE name bound body =>
    simp only [expression, bind_ok] at h
    obtain ⟨kind,_,u,_,x,hx,hy⟩ := h
    exact (expression_length body fs ((name,kind)::env) x b hy).trans
      (expression_length bound fs env a x hx)
  | ifE cond yes no =>
    simp only [expression, bind_ok] at h
    obtain ⟨x,hx,y,hy,z,hz,he⟩ := h
    simp only [pure_eq, Except.ok.injEq] at he
    subst b
    have hx := expression_length cond fs env a x hx
    have hy := expression_length yes fs env x y hy
    have hz := expression_length no fs env x z hz
    simp [List.length_zipWith, hx, hy, hz]
  | matchE scrut empty head tail cell =>
    simp only [expression, bind_ok] at h
    obtain ⟨u,_,x,hx,y,hy,z,hz,he⟩ := h
    simp only [pure_eq, Except.ok.injEq] at he
    subst b
    have hx := expression_length scrut fs env a x hx
    have hy := expression_length empty fs env (0::x) y hy
    have hz := expression_length cell fs ((tail,.list)::(head,.number)::env) (1::x) z hz
    simp [List.length_zipWith, List.length_tail, hx, hy, hz]
  | call name args =>
    simp only [expression] at h
    split at h
    · split at h
      · simp at h
      · apply fold_length args.attach _ _ h
        intro arg _ x y hy
        exact expression_length arg.val fs env x y hy
    · simp at h
termination_by sizeOf e
decreasing_by
  all_goals subst e
  all_goals simp_wf
  all_goals first | omega | (have h := List.sizeOf_lt_of_mem arg.property; omega)

/-- Ordered, aligned lower bounds; a total credit count would lose the scope
that expires when a match exits. -/
inductive Lower : List Nat → List Nat → Prop
  | nil : Lower [] []
  | cons (head : a ≤ b) (tail : Lower as bs) : Lower (a::as) (b::bs)

theorem Lower.refl (xs : List Nat) : Lower xs xs := by
  induction xs with
  | nil => exact .nil
  | cons x xs ih => exact .cons (Nat.le_refl x) ih

theorem Lower.trans (ha : Lower a b) (hb : Lower b c) : Lower a c := by
  induction ha generalizing c with
  | nil => cases hb; exact .nil
  | cons hx ht ih => cases hb with | cons hy hu => exact .cons (Nat.le_trans hx hy) (ih hu)

theorem Lower.length (h : Lower a b) : a.length = b.length := by
  induction h <;> simp_all

theorem Lower.tail (h : Lower a b) : Lower a.tail b.tail := by
  cases h with
  | nil => exact .nil
  | cons _ ht => exact ht

theorem join_lower (a b : List Nat) (hl : a.length = b.length) :
    Lower (a.zipWith min b) a ∧ Lower (a.zipWith min b) b := by
  induction a generalizing b with
  | nil =>
    cases b with
    | nil => exact ⟨.nil,.nil⟩
    | cons _ _ => simp at hl
  | cons x xs ih =>
    cases b with
    | nil => simp at hl
    | cons y ys =>
      have ht := ih ys (by simpa using hl)
      exact ⟨.cons (Nat.min_le_left _ _) ht.1, .cons (Nat.min_le_right _ _) ht.2⟩

theorem spend_lower (h : spend a = .ok b) : Lower b a := by
  induction a generalizing b with
  | nil => simp [spend] at h
  | cons x xs ih =>
    cases x with
    | zero =>
      simp only [spend,bind_ok] at h
      obtain ⟨ys,hy,he⟩ := h
      simp only [pure_eq,Except.ok.injEq] at he
      subst b
      exact .cons (Nat.le_refl 0) (ih hy)
    | succ n =>
      simp only [spend,Except.ok.injEq] at h
      subst b
      exact .cons (by omega) (.refl xs)

/-- A concrete innermost-first spend can use an extra credit not represented
by the lower bound. It still leaves at least the statically promised remainder. -/
theorem spend_monotone (hl : Lower a b) (ha : spend a = .ok a') :
    ∃ b', spend b = .ok b' ∧ Lower a' b' := by
  induction hl generalizing a' with
  | nil => simp [spend] at ha
  | @cons x y xs ys hxy htail ih =>
    cases x with
    | zero =>
      simp only [spend,bind_ok] at ha
      obtain ⟨zs,hz,he⟩ := ha
      simp only [pure_eq,Except.ok.injEq] at he
      subst a'
      cases y with
      | zero =>
        obtain ⟨ws,hw,hbound⟩ := ih hz
        exact ⟨0::ws,by simp [spend,hw],.cons (Nat.le_refl 0) hbound⟩
      | succ n =>
        exact ⟨n::ys,rfl,.cons (Nat.zero_le n) ((spend_lower hz).trans htail)⟩
    | succ n =>
      cases y with
      | zero => omega
      | succ m =>
        simp only [spend,Except.ok.injEq] at ha
        subst a'
        exact ⟨m::ys,rfl,.cons (by omega) htail⟩

end Full.Demand
