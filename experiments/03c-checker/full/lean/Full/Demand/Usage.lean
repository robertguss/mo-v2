import Full.Demand
import Full.Counted

namespace Full.Demand

theorem sum_map_zero (xs : List α) (f : α → Nat) :
    (xs.map f).sum = 0 ↔ ∀ x ∈ xs, f x = 0 := by
  induction xs with
  | nil => simp
  | cons x xs ih => simp [ih]

theorem uses_zero (e : Expr) (env : Trial.FEnv) (id : Nat) :
    uses e env id = false ↔ occurrences e env id = 0 := by
  cases e with
  | num n => simp [uses, occurrences]
  | bool b => simp [uses, occurrences]
  | nil => simp [uses, occurrences]
  | var x => simp [uses, occurrences]
  | bin op a b =>
    simp [uses, occurrences, Bool.or_eq_false_iff, uses_zero a, uses_zero b]
  | letE x a b =>
    simp [uses, occurrences, Bool.or_eq_false_iff, uses_zero a, uses_zero b]
  | ifE c t e =>
    simp [uses, occurrences, Bool.or_eq_false_iff, uses_zero c, uses_zero t, uses_zero e, and_assoc]
  | matchE s n h t c =>
    simp [uses, occurrences, Bool.or_eq_false_iff, uses_zero s, uses_zero n, uses_zero c, and_assoc]
  | call name args =>
    have ih (a : { x // x ∈ args }) := uses_zero a.val env id
    simp only [uses, occurrences, List.any_eq_false, sum_map_zero]
    constructor
    · intro h a ha
      exact (ih a).mp (Bool.eq_false_iff.mpr (h a ha))
    · intro h a ha
      exact Bool.eq_false_iff.mp ((ih a).mpr (h a ha))
termination_by sizeOf e
decreasing_by
  all_goals simp_wf
  all_goals first | omega | (have h := List.sizeOf_lt_of_mem a.property; omega)

/-- The numerical version of the frozen future-use predicate. -/
def taskOccurrences (id : Nat) : Counted.Task → Nat
  | .eval e ctx => occurrences e (Trial.toFEnv ctx.env) id
  | .bind x body ctx => occurrences body ((x,none)::Trial.toFEnv ctx.env) id
  | .chooseIf t e ctx => max (occurrences t (Trial.toFEnv ctx.env) id)
      (occurrences e (Trial.toFEnv ctx.env) id)
  | .chooseMatch n h t c ctx => max (occurrences n (Trial.toFEnv ctx.env) id)
      (occurrences c ((t,none)::(h,none)::Trial.toFEnv ctx.env) id)
  | .decompose h t c _ ctx => occurrences c ((t,none)::(h,none)::Trial.toFEnv ctx.env) id
  | _ => 0

theorem taskUses_zero (id : Nat) (task : Counted.Task) :
    Counted.taskUses id task = false ↔ taskOccurrences id task = 0 := by
  cases task <;> simp [Counted.taskUses, taskOccurrences, Bool.or_eq_false_iff, uses_zero]

def futureOccurrences (id : Nat) (tasks : List Counted.Task) : Nat :=
  (tasks.map (taskOccurrences id)).sum

theorem futureUses_zero (id : Nat) (tasks : List Counted.Task) :
    tasks.any (Counted.taskUses id) = false ↔ futureOccurrences id tasks = 0 := by
  simp [futureOccurrences, List.any_eq_false, sum_map_zero, taskUses_zero]

/-- A continuation-wide bound, rather than expression-local acceptance, is
what makes the machine move a holder at a variable leaf. -/
theorem last_use (env : Trial.Env) (id : Nat) (name : String) (ctx : Counted.Context)
    (rest : List Counted.Task) (he : ctx.env = env)
    (hx : Trial.lookupF (Trial.toFEnv env) name = some (some id))
    (hb : futureOccurrences id (.eval (.var name) ctx :: rest) ≤ 1) :
    rest.any (Counted.taskUses id) = false := by
  apply (futureUses_zero id rest).mpr
  simp [futureOccurrences, taskOccurrences, occurrences, he, hx] at hb ⊢
  omega

theorem hide_lookup (a b : Trial.FEnv) (i j : Nat) (name : String)
    (h : ∀ x, (Trial.lookupF a x == some (some i)) = (Trial.lookupF b x == some (some j))) :
    ∀ x, (Trial.lookupF ((name,none)::a) x == some (some i)) =
      (Trial.lookupF ((name,none)::b) x == some (some j)) := by
  intro x
  by_cases hx : name = x
  · simp [Trial.lookupF, hx]
  · simpa [Trial.lookupF, hx] using h x

theorem occurrences_ext (e : Expr) (a b : Trial.FEnv) (i j : Nat)
    (h : ∀ x, (Trial.lookupF a x == some (some i)) = (Trial.lookupF b x == some (some j))) :
    occurrences e a i = occurrences e b j := by
  cases e with
  | num n => simp [occurrences]
  | bool q => simp [occurrences]
  | nil => simp [occurrences]
  | var x => simp only [occurrences, h x]
  | bin op l r =>
    simp only [occurrences, occurrences_ext l a b i j h, occurrences_ext r a b i j h]
  | letE x l r =>
    simp only [occurrences, occurrences_ext l a b i j h,
      occurrences_ext r _ _ i j (hide_lookup a b i j x h)]
  | ifE c t e =>
    simp only [occurrences, occurrences_ext c a b i j h,
      occurrences_ext t a b i j h, occurrences_ext e a b i j h]
  | matchE s n head tail c =>
    simp only [occurrences, occurrences_ext s a b i j h, occurrences_ext n a b i j h,
      occurrences_ext c _ _ i j (hide_lookup _ _ i j tail (hide_lookup a b i j head h))]
  | call name args =>
    simp only [occurrences]
    apply congrArg List.sum
    apply List.map_congr_left
    intro x hx
    exact occurrences_ext x.val a b i j h
termination_by sizeOf e
decreasing_by
  all_goals simp_wf
  all_goals first | omega | (have h := List.sizeOf_lt_of_mem x.property; omega)

theorem occurrences_fresh_shadow (e : Expr) (env : Trial.FEnv) (name : String)
    (fresh id : Nat) (hne : fresh ≠ id) :
    occurrences e ((name,some fresh)::env) id = occurrences e ((name,none)::env) id := by
  apply occurrences_ext
  intro x
  by_cases hx : name = x <;> simp [Trial.lookupF, hx, hne]

theorem occurrences_fresh_pair (e : Expr) (env : Trial.FEnv) (head tail : String)
    (hid tid id : Nat) (hh : hid ≠ id) (ht : tid ≠ id) :
    occurrences e ((tail,some tid)::(head,some hid)::env) id =
      occurrences e ((tail,none)::(head,none)::env) id := by
  rw [occurrences_fresh_shadow e _ tail tid id ht]
  apply occurrences_ext
  exact hide_lookup _ _ id id tail (by
    intro x
    by_cases hx : head = x <;> simp [Trial.lookupF, hx, hh])

end Full.Demand
