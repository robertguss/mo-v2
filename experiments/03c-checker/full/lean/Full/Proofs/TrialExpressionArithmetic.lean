import Full.Proofs.TrialExpressionBinary

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

def numericRaw (op : Op) (x y : Int) : Raw :=
  match op with
  | .add => .num (x+y)
  | .sub => .num (x-y)
  | .eq => .bool (x == y)
  | .lt => .bool (x < y)
  | .le => .bool (x ≤ y)
  | .cons => .list none

/-- F1 supplies an actual successful transition, including the ghost primitive.
No successful Counted evaluation or ghost-number premise is required. -/
theorem numeric_primitive (op : Op) (hn : op ≠ .cons)
    (p : Program) (initial : Trial.Start) (s : State) (ctx : Context)
    (rest : List Task) (vx vy : Slot) (slots : List Slot) (x y : Int)
    (hr : Reachable p initial s) (ht : s.tasks = .primitive op ctx :: rest)
    (hv : s.slots = vy :: vx :: slots) (hx : vx.raw = .num x) (hy : vy.raw = .num y)
    (ha : s.answer = none) (he : Enclosing ctx s) :
    ∃ t v, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = v :: slots ∧ v.raw = numericRaw op x y ∧
      t.answer = none ∧ observe t = observe s ∧ Enclosing ctx t := by
  obtain ⟨t, hs, _⟩ := (Full.Proofs.f1.2 p initial s hr).2.2 ha
  cases hc : transition p s with
  | error why => simp [step, ha, hc] at hs
  | ok c =>
    have htc : t = commit c := by simpa [step, ha, hc] using hs.symm
    cases hp : Plain.primitive op vx.value vy.value with
    | error why => simp [transition, ht, hv, hp] at hc
    | ok value =>
      have hop : (op == .cons) = false := beq_eq_false_iff_ne.mpr hn
      have hcc : c = ⟨{ s with
          tasks := rest,
          slots := ⟨numericRaw op x y, value⟩ :: slots },⟨"Primitive",none⟩,none⟩ := by
        cases op <;> try contradiction
        all_goals simpa [transition, ht, hv, hp, hx, hy, numericRaw] using hc.symm
      subst c
      subst t
      refine ⟨commit ⟨{ s with
        tasks := rest, slots := ⟨numericRaw op x y, value⟩ :: slots },
        ⟨"Primitive",none⟩,none⟩, ⟨numericRaw op x y, value⟩,
        ?_, ?_, rfl, rfl, rfl, ha, ?_, he⟩
      · simp [advance, ha, hs]
      · exact reachable_advance p initial s _ 1 hr (by simp [advance, ha, hs])
      · cases op <;> try contradiction
        all_goals simp [observe, commit, pending, hv, hx, hy, numericRaw]

theorem numeric_contracts (a b : Trial.Expr) (ha : Evaluation a) (hb : Evaluation b) :
    Evaluation (.add a b) ∧ Evaluation (.sub a b) ∧ Evaluation (.eq a b) ∧
      Evaluation (.lt a b) ∧ Evaluation (.le a b) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  all_goals
    intro p initial s ctx rest frames log raw u hr ht hs hf he hu
    unfold Trial.evalC at hu
    obtain ⟨rx, l, hl, hk⟩ := trial_bind_success _ _ _ _ _ hu
    obtain ⟨ry, r, hry, hop⟩ := trial_bind_success _ _ _ _ _ hk
    cases rx <;> cases ry <;> simp only [Trial.numOp] at hop
    all_goals try { have bad := congrArg Prod.fst hop; cases bad }
  all_goals
    have hraw := congrArg Prod.fst hop
    have hu := congrArg Prod.snd hop
    dsimp at hu
    have hrval := Except.ok.inj hraw
    subst raw
    subst u
    obtain ⟨n, t, vx, vy, hxt, hrt, htt, hst, hx, hy, hat, hot, het⟩ :=
      binary_operands a b ha hb p initial s ctx _ rest frames log _ _ l r
        hr ht hs hf he hl hry
    obtain ⟨z, v, hz, hrz, htz, hsz, hvz, haz, hoz, hez⟩ :=
      numeric_primitive _ (by decide) p initial t ctx rest vx vy s.slots _ _
        hrt htt hst hx hy hat het
    refine ⟨n+1, z, v, ?_, hrz, htz, hsz, ?_, haz, hot.trans hoz.symm, hez⟩
    · rw [advance_add, hxt]; exact hz
    · first
      | exact hvz
      | (rw [hvz]; congr 1; apply Bool.eq_iff_iff.mpr; simp [numericRaw, beq_iff_eq])

theorem evaluation_add (a b : Trial.Expr) (ha : Evaluation a) (hb : Evaluation b) :
    Evaluation (.add a b) := (numeric_contracts a b ha hb).1

theorem evaluation_sub (a b : Trial.Expr) (ha : Evaluation a) (hb : Evaluation b) :
    Evaluation (.sub a b) := (numeric_contracts a b ha hb).2.1

theorem evaluation_eq (a b : Trial.Expr) (ha : Evaluation a) (hb : Evaluation b) :
    Evaluation (.eq a b) := (numeric_contracts a b ha hb).2.2.1

theorem evaluation_lt (a b : Trial.Expr) (ha : Evaluation a) (hb : Evaluation b) :
    Evaluation (.lt a b) := (numeric_contracts a b ha hb).2.2.2.1

theorem evaluation_le (a b : Trial.Expr) (ha : Evaluation a) (hb : Evaluation b) :
    Evaluation (.le a b) := (numeric_contracts a b ha hb).2.2.2.2

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.numeric_primitive
#print axioms Full.Proofs.TrialExecution.numeric_contracts
#print axioms Full.Proofs.TrialExecution.evaluation_add
#print axioms Full.Proofs.TrialExecution.evaluation_sub
#print axioms Full.Proofs.TrialExecution.evaluation_eq
#print axioms Full.Proofs.TrialExecution.evaluation_lt
#print axioms Full.Proofs.TrialExecution.evaluation_le
