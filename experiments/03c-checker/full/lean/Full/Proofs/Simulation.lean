import Full.Proofs
import Full.Proofs.SimulationInitial
import Full.Proofs.Control

namespace Full.Proofs.Simulation
open Statements

/-- The local correspondence obligation. It is a premise of the decomposition
below, not an axiom or an additional condition on valid programs. -/
def Forward : Prop :=
  ∀ p initial s, Reachable p initial s → ∃ a, Related a s ∧
    (∀ t, Counted.step p s = .ok t → s.answer = none →
      Related (Plain.step p a) t ∨ (Related a t ∧ Control.rank t < Control.rank s))

theorem related_unique (h : Related a s) (h' : Related b s) : a = b :=
  Except.ok.inj (h.symm.trans h')

theorem advance_one (p : Program) (s : Counted.State) :
    Counted.advance p 1 s = Counted.step p s := by
  cases ha : s.answer <;> simp [Counted.advance, Counted.step, ha]

theorem reachable_advance (hr : Reachable p initial s)
    (h : Counted.advance p n s = .ok t) : Reachable p initial t := by
  obtain ⟨first,k,hb,hk⟩ := hr
  refine ⟨first,k+n,hb,?_⟩
  rw [f5.2.1 p first k n,hk]
  exact h

theorem reachable_step (hr : Reachable p initial s)
    (h : Counted.step p s = .ok t) : Reachable p initial t :=
  reachable_advance hr ((advance_one p s).trans h)

theorem plain_advance_add (p : Program) (m n : Nat) (a : Plain.State) :
    Plain.advance p (m+n) a = Plain.advance p n (Plain.advance p m a) := by
  induction m generalizing a with
  | zero => simp [Plain.advance]
  | succ m ih => simpa [Nat.succ_add,Plain.advance] using ih (Plain.step p a)

/-- Finite stuttering cannot prevent a required Plain step: the frozen natural
rank supplies the well-founded descent, with no execution-fuel assumption. -/
theorem catch_up (hf : F1) (hsim : Forward)
    (hr : Reachable p initial s) (ha : Related a s) :
    ∃ n t, Counted.advance p n s = .ok t ∧ Related (Plain.step p a) t := by
  generalize he : Control.rank s = rank
  induction rank using Nat.strongRecOn generalizing s a with
  | ind rank ih =>
    cases hans : s.answer with
    | some v =>
      have hea : a = ⟨.finished v.value,[]⟩ := by
        simpa [Related,Control.decode,hans] using ha.symm
      subst a
      exact ⟨0,s,rfl,ha⟩
    | none =>
      obtain ⟨t,ht,_⟩ := (hf.2 p initial s hr).2.2 hans
      obtain ⟨b,hb,hstep⟩ := hsim p initial s hr
      have hab := related_unique ha hb
      subst b
      rcases hstep t ht hans with hnext | ⟨hsame,hless⟩
      · exact ⟨1,t,(advance_one p s).trans ht,hnext⟩
      · obtain ⟨n,u,hu,hrel⟩ := ih (Control.rank t) (by omega)
          (reachable_step hr ht) hsame rfl
        refine ⟨1+n,u,?_,hrel⟩
        rw [f5.2.1 p s 1 n,advance_one p s,ht]
        exact hu

/-- Each finite counted prefix has some independent Plain prefix. -/
theorem advance_related (hsim : Forward) (hr : Reachable p initial s)
    (ha : Related a s) (h : Counted.advance p n s = .ok t) :
    ∃ k, Related (Plain.advance p k a) t := by
  induction n generalizing s a with
  | zero => cases h; exact ⟨0,ha⟩
  | succ n ih =>
    cases hans : s.answer with
    | some v =>
      simp [Counted.advance,hans] at h
      subst t
      exact ⟨0,ha⟩
    | none =>
      cases ht : Counted.step p s with
      | error why => simp [Counted.advance,hans,ht] at h
      | ok u =>
        simp [Counted.advance,hans,ht] at h
        obtain ⟨b,hb,hstep⟩ := hsim p initial s hr
        have hab := related_unique ha hb
        subst b
        rcases hstep u ht hans with hnext | ⟨hsame,_⟩
        · obtain ⟨k,hk⟩ := ih (reachable_step hr ht) hnext h
          exact ⟨k+1,hk⟩
        · exact ih (reachable_step hr ht) hsame h

theorem reachable_related (hsim : Forward) (hr : Reachable p initial s) :
    ∃ first n, plainBegin p initial = .ok first ∧ Related (Plain.advance p n first) s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  obtain ⟨plain,hplain,hrel⟩ := SimulationInitial.initial_simulation p initial first hb
  obtain ⟨k,hk⟩ := advance_related hsim ⟨first,0,hb,rfl⟩ hrel hn
  exact ⟨plain,k,hplain,hk⟩

/-- The reverse finite-prefix direction uses catch-up once per Plain step,
not a bound on the counted implementation's administrative work. -/
theorem plain_advance_related (hf : F1) (hsim : Forward)
    (hr : Reachable p initial s) (ha : Related a s) (n : Nat) :
    ∃ t, Reachable p initial t ∧ Related (Plain.advance p n a) t := by
  induction n generalizing s a with
  | zero => exact ⟨s,hr,ha⟩
  | succ n ih =>
    obtain ⟨k,t,ht,hrel⟩ := catch_up hf hsim hr ha
    exact ih (reachable_advance hr ht) hrel

theorem transition_answer_slot (ha : s.answer = none)
    (ht : Counted.transition p s = .ok c) (hc : c.state.answer = some v) :
    v ∈ c.state.slots := by
  unfold Counted.transition at ht
  simp only [bind,pure,Except.bind,Except.pure] at ht
  all_goals repeat' first | split at ht | cases ht | simp_all

theorem advance_answer_slot (hstart : ∀ v, s.answer = some v → v ∈ s.slots)
    (ht : Counted.advance p n s = .ok t) :
    ∀ v, t.answer = some v → v ∈ t.slots := by
  induction n generalizing s with
  | zero => cases ht; exact hstart
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hstart
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        apply ih ?_ ht
        intro v hv
        exact transition_answer_slot ha hc hv

theorem reachable_answer_slot (hr : Reachable p initial s)
    (ha : s.answer = some v) : v ∈ s.slots := by
  obtain ⟨first,n,hb,hn⟩ := hr
  have hfirst : first.answer = none := by
    obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
    rfl
  exact advance_answer_slot (by simp [hfirst]) hn v ha

theorem answer_readable (hf : F1) (hr : Reachable p initial s)
    (ha : s.answer = some v) : Trial.readBack s.mem v.raw = .ok v.value := by
  have hi := (hf.2 p initial s hr).1
  simp only [Inspect.invariant,Bool.and_eq_true] at hi
  have hp := hi.1.1.1.1.1.1.1
  simp only [Inspect.protection,Bool.and_eq_true] at hp
  have hv := List.all_eq_true.mp hp.1.2 v (reachable_answer_slot hr ha)
  unfold Inspect.readable at hv
  cases hread : Trial.readBack s.mem v.raw <;> simp_all [beq_iff_eq]

theorem focus_not_finished (s : Counted.State) (n : Nat)
    (tasks : List Counted.Task) (slots : List Counted.Slot)
    (h : Control.focus s n tasks slots = .ok a) : ∀ v, a.focus ≠ .finished v := by
  induction n generalizing tasks slots with
  | zero => simp [Control.focus] at h
  | succ n ih =>
    unfold Control.focus at h
    simp only [bind,pure,Except.bind,Except.pure] at h
    all_goals repeat' first | split at h | cases h | (apply ih _ _ h) | simp_all

theorem related_finished (ha : Related a s) (hv : a.focus = .finished v) :
    ∃ answer, s.answer = some answer ∧ answer.value = v := by
  cases hans : s.answer with
  | none =>
    have hfocus : Control.focus s (s.tasks.length+2) s.tasks s.slots = .ok a := by
      simpa [Related,Control.decode,hans] using ha
    exact False.elim (focus_not_finished s _ _ _ hfocus v hv)
  | some answer =>
    have hea : a = ⟨.finished answer.value,[]⟩ := by
      simpa [Related,Control.decode,hans] using ha.symm
    exact ⟨answer,rfl,by simpa [hea] using hv⟩

/-- Once the local forward proof and F1 are supplied, the remaining F2 clauses
follow without any new semantic or termination assumption. -/
theorem f2_of_f1_forward (hf : F1) (hsim : Forward) : F2 := by
  refine ⟨SimulationInitial.initial_simulation,hsim,?_,?_⟩
  · intro p initial s a hr ha
    exact catch_up hf hsim hr ha
  · intro p initial first v hb
    constructor
    · rintro ⟨s,answer,hr,ha,hread⟩
      obtain ⟨plain,n,hplain,hrel⟩ := reachable_related hsim hr
      have hv : answer.value = v := Except.ok.inj ((answer_readable hf hr ha).symm.trans hread)
      have he : Plain.advance p n plain = ⟨.finished v,[]⟩ := by
        simpa [Related,Control.decode,ha,hv] using hrel.symm
      exact ⟨plain,n,hplain,congrArg Plain.State.focus he⟩
    · rintro ⟨plain,n,hplain,hfinish⟩
      obtain ⟨a,ha,hrel⟩ := SimulationInitial.initial_simulation p initial first hb
      have he : a = plain := Except.ok.inj (ha.symm.trans hplain)
      subst a
      obtain ⟨s,hr,hs⟩ := plain_advance_related hf hsim ⟨first,0,hb,rfl⟩ hrel n
      obtain ⟨answer,hanswer,hv⟩ := related_finished hs hfinish
      exact ⟨s,answer,hr,hanswer,by simpa [hv] using answer_readable hf hr hanswer⟩

end Full.Proofs.Simulation
