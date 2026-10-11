import Full.Proofs.Basic
import Full.Proofs.Lifecycle
import Full.Proofs.Heap
import Full.Proofs.DestructionGraph

namespace Full.Proofs

/-- Lifecycle gates either leave execution alone or take one frozen counted step. -/
theorem destruction_step_execution (p : Program) (allow : Lifecycle.Policy)
    (s t : Lifecycle.State) (h : Lifecycle.step p allow s = .ok t) :
    t.execution = s.execution ∨ Counted.step p s.execution = .ok t.execution := by
  unfold Lifecycle.step at h
  split at h
  · cases h; exact Or.inl rfl
  · cases hr : Lifecycle.request s.execution with
    | none =>
      simp only [hr] at h
      cases hs : Counted.step p s.execution with
      | error e => simp [hs] at h
      | ok e => simp [hs] at h; cases h; exact Or.inr rfl
    | some r =>
      simp only [hr] at h
      split at h
      · cases hs : Counted.step p s.execution with
        | error e => simp [hs] at h
        | ok e => simp [hs] at h; cases h; exact Or.inr rfl
      · cases h; exact Or.inl rfl

theorem destruction_reachable_step (p : Program) (initial : Trial.Start)
    (s t : Counted.State) (hr : Statements.Reachable p initial s)
    (hs : Counted.step p s = .ok t) : Statements.Reachable p initial t := by
  obtain ⟨first, n, hb, ha⟩ := hr
  refine ⟨first, n + 1, hb, ?_⟩
  rw [f5.2.1 p first n 1, ha]
  simp only [Except.bind]
  unfold Counted.advance
  split
  · rename_i ht
    have he : t = s := by simpa [Counted.step, ht] using hs.symm
    subst t
    rfl
  · simp [hs, Counted.advance]

/-- No correctness premise is needed to project a lifecycle run to a counted run. -/
theorem destruction_advance_reachable (p : Program) (initial : Trial.Start)
    (allow : Lifecycle.Policy) (n : Nat) (s t : Lifecycle.State)
    (hr : Statements.Reachable p initial s.execution)
    (ha : Lifecycle.advance p allow n s = .ok t) :
    Statements.Reachable p initial t.execution := by
  induction n generalizing s with
  | zero => cases ha; exact hr
  | succ n ih =>
    unfold Lifecycle.advance at ha
    split at ha
    · cases ha; exact hr
    · cases hs : Lifecycle.step p allow s with
      | error e => simp [hs] at ha
      | ok u =>
        simp [hs] at ha
        apply ih u ?_ ha
        rcases destruction_step_execution p allow s u hs with he | he
        · simpa [he] using hr
        · exact destruction_reachable_step p initial s.execution u.execution hr he

theorem destruction_execution_reachable (p : Program) (initial : Trial.Start)
    (s : Lifecycle.State) (hr : Statements.lifecycleReachable p initial s) :
    Statements.Reachable p initial s.execution := by
  obtain ⟨first, allow, n, hb, ha⟩ := hr
  exact destruction_advance_reachable p initial allow n { execution := first } s
    ⟨first, 0, hb, rfl⟩ ha

theorem destruction_invariant_of_f1 (hf : Statements.F1) (p : Program)
    (initial : Trial.Start) (s : Lifecycle.State)
    (hr : Statements.lifecycleReachable p initial s) :
    Inspect.invariant initial s.execution = true :=
  (hf.2 p initial s.execution (destruction_execution_reachable p initial s hr)).1

/-- The literal destruction keeps every outside read, including count recomputation. -/
theorem destruction_readBack_of_f1 (hf : Statements.F1) (p : Program)
    (initial : Trial.Start) (s : Lifecycle.State)
    (hr : Statements.lifecycleReachable p initial s) :
    ∀ root ∈ initial.outside,
      Trial.readBack (Lifecycle.destroy s).execution.mem (.list root) =
        Trial.readBack initial.toMemory (.list root) := by
  have hi := destruction_invariant_of_f1 hf p initial s hr
  have hh := (invariant_heap initial s.execution hi).1
  have ho := lifecycleReachable_outside p initial s hr
  have hroots : ∀ r ∈ s.execution.outside,
      ∃ cs, Trial.Proofs.ListPath s.execution.mem r cs := by
    intro r hm
    apply hh.readable r
    exact List.mem_append_left _ (List.mem_append_right _ hm)
  have hd := (lifecycleReachable_destruction_metadata p initial s hr).1
  intro r hm
  have hm' : r ∈ s.execution.outside := by simpa [ho] using hm
  have hretain := Destruction.retained_readBack s.execution.mem s.execution.outside hroots r hm'
  have hcount := Trial.Proofs.read_back_counts
    (Destruction.retained s.execution.mem s.execution.outside)
    (fun c => (s.execution.outside.filter (fun r => r == some c.addr)).length +
      ((Destruction.retained s.execution.mem s.execution.outside).cells.filter
        (fun d => d.link == some c.addr)).length) (.list r)
  have hdread : Trial.readBack (Lifecycle.destroy s).execution.mem (.list r) =
      Trial.readBack s.execution.mem (.list r) := by
    simp only [Lifecycle.destroy, hd, Bool.false_eq_true, ↓reduceIte, List.length_map]
    exact hcount.trans hretain
  rw [hdread]
  simp only [Inspect.invariant, Bool.and_eq_true] at hi
  have hp := hi.1.1.1.1.1.1.1
  simp only [Inspect.protection, Bool.and_eq_true] at hp
  have hout := List.all_eq_true.mp hp.1.1.1.2 r hm
  cases ha : Trial.readBack initial.toMemory (.list r) <;>
    cases hb : Trial.readBack s.execution.mem (.list r) <;>
    simp_all [beq_iff_eq]

theorem destruction_validStart_of_f1 (hf : Statements.F1) (p : Program)
    (initial : Trial.Start) (s : Lifecycle.State)
    (hr : Statements.lifecycleReachable p initial s) :
    Trial.validStart (.num 0)
      ⟨(Lifecycle.destroy s).execution.mem.cells.map
        (fun c => ⟨c.addr,c.item,c.link,c.count⟩), [], initial.outside⟩ = .ok () := by
  have hi := destruction_invariant_of_f1 hf p initial s hr
  have hh := (invariant_heap initial s.execution hi).1
  have ho := lifecycleReachable_outside p initial s hr
  have hroots : ∀ r ∈ s.execution.outside,
      ∃ cs, Trial.Proofs.ListPath s.execution.mem r cs := by
    intro r hm
    apply hh.readable r
    exact List.mem_append_left _ (List.mem_append_right _ hm)
  have hv := Destruction.retained_valid s.execution.mem s.execution.outside hh.unique hroots
  have hd := (lifecycleReachable_destruction_metadata p initial s hr).1
  rw [← ho]
  simp only [Lifecycle.destroy, hd, Bool.false_eq_true, ↓reduceIte, List.length_map]
  exact hv

/-- Stage 1 is conditional only on F1; execution and graph checking are frozen. -/
theorem l2_of_f1 : Statements.F1 → Statements.L2 := by
  intro hf p initial s hr
  dsimp only
  obtain ⟨he, hh, hm, ho⟩ := destroy_preserves_observations s
  obtain ⟨hb, _, hs, hrsv, hfr, ht, hrel, ha⟩ :=
    lifecycleReachable_clears_control p initial s hr
  exact ⟨destroy_idempotent s, destroy_destroyed s, he, hh, hm,
    hb, hs, hrsv, hfr, ht, hrel, ha,
    ho.trans (lifecycleReachable_outside p initial s hr),
    destruction_validStart_of_f1 hf p initial s hr,
    destruction_readBack_of_f1 hf p initial s hr,
    lifecycleReachable_cleanup_membership p initial s hr⟩

end Full.Proofs
