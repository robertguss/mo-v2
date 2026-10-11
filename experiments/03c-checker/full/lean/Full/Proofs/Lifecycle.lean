import Full.Statements
import Full.Proofs.Initial

/-! Partial results for the frozen L2 obligation. No execution invariant or
outside-graph preservation theorem is assumed here.

Unresolved L2 obligations: destroyed memory satisfies the exact outside-only
`Trial.validStart` check; and each initial outside root has unchanged
`Trial.readBack`. These require
execution/graph preservation facts not established by the algebraic lemmas
below. In particular, no positive-count assumption is imposed on running
memory: zero-count cells awaiting Free are allowed. This file does not prove
`Full.Statements.L2`. -/
namespace Full.Proofs

theorem transition_outside (p : Program) (s : Counted.State) (c : Counted.Change)
    (h : Counted.transition p s = .ok c) : c.state.outside = s.outside := by
  unfold Counted.transition at h
  simp only [bind, pure, Except.bind, Except.pure] at h
  all_goals repeat' first | split at h | cases h | rfl

theorem step_outside (p : Program) (s t : Counted.State)
    (h : Counted.step p s = .ok t) : t.outside = s.outside := by
  unfold Counted.step at h
  split at h
  · cases h; rfl
  · cases hc : Counted.transition p s with
    | error e => simp [hc] at h
    | ok c =>
      simp [hc] at h
      subst t
      exact transition_outside p s c hc

theorem lifecycle_step_outside (p : Program) (allow : Lifecycle.Policy)
    (s t : Lifecycle.State) (h : Lifecycle.step p allow s = .ok t) :
    t.execution.outside = s.execution.outside := by
  unfold Lifecycle.step at h
  split at h
  · cases h; rfl
  · cases hr : Lifecycle.request s.execution with
    | none =>
      simp only [hr] at h
      cases hs : Counted.step p s.execution with
      | error e => simp [hs] at h
      | ok e =>
        simp [hs] at h
        subst t
        exact step_outside p s.execution e hs
    | some r =>
      simp only [hr] at h
      split at h
      · cases hs : Counted.step p s.execution with
        | error e => simp [hs] at h
        | ok e =>
          simp [hs] at h
          subst t
          exact step_outside p s.execution e hs
      · cases h; rfl

theorem lifecycle_advance_outside (p : Program) (allow : Lifecycle.Policy)
    (n : Nat) (s t : Lifecycle.State)
    (h : Lifecycle.advance p allow n s = .ok t) :
    t.execution.outside = s.execution.outside := by
  induction n generalizing s with
  | zero => cases h; rfl
  | succ n ih =>
    unfold Lifecycle.advance at h
    split at h
    · cases h; rfl
    · cases hs : Lifecycle.step p allow s with
      | error e => simp [hs] at h
      | ok u =>
        simp [hs] at h
        exact (ih u h).trans (lifecycle_step_outside p allow s u hs)

theorem lifecycleReachable_outside (p : Program) (initial : Trial.Start)
    (s : Lifecycle.State) (h : Statements.lifecycleReachable p initial s) :
    s.execution.outside = initial.outside := by
  obtain ⟨first, allow, n, hb, ha⟩ := h
  exact (lifecycle_advance_outside p allow n { execution := first } s ha).trans
    (Initial.begin_memory p initial first hb).2.1

theorem destroy_idempotent (s : Lifecycle.State) :
    Lifecycle.destroy (Lifecycle.destroy s) = Lifecycle.destroy s := by
  by_cases h : s.destroyed = true
  · simp [Lifecycle.destroy, h]
  · simp [Lifecycle.destroy, h]

theorem destroy_destroyed (s : Lifecycle.State) :
    (Lifecycle.destroy s).destroyed = true := by
  by_cases h : s.destroyed = true <;> simp [Lifecycle.destroy, h]

theorem destroy_preserves_observations (s : Lifecycle.State) :
    (Lifecycle.destroy s).execution.events = s.execution.events ∧
    (Lifecycle.destroy s).execution.history = s.execution.history ∧
    (Lifecycle.destroy s).execution.mem.record = s.execution.mem.record ∧
    (Lifecycle.destroy s).execution.outside = s.execution.outside := by
  by_cases h : s.destroyed = true <;> simp [Lifecycle.destroy, h]

theorem destroy_clears_control (s : Lifecycle.State) (h : s.destroyed = false) :
    (Lifecycle.destroy s).execution.bindings = [] ∧
    (Lifecycle.destroy s).execution.entered = [] ∧
    (Lifecycle.destroy s).execution.slots = [] ∧
    (Lifecycle.destroy s).execution.reservations = [] ∧
    (Lifecycle.destroy s).execution.frames = [] ∧
    (Lifecycle.destroy s).execution.tasks = [] ∧
    (Lifecycle.destroy s).execution.releaseChain = [] ∧
    (Lifecycle.destroy s).execution.answer = none := by
  simp [Lifecycle.destroy, h]

theorem destroy_cleanup_membership (s : Lifecycle.State)
    (hd : s.destroyed = false) (hc : s.cleanup = []) (addr : Nat) :
    addr ∈ (Lifecycle.destroy s).cleanup ↔
      (∃ c ∈ s.execution.mem.cells, c.addr = addr) ∧
      ¬ (∃ c ∈ (Lifecycle.destroy s).execution.mem.cells, c.addr = addr) := by
  simp only [Lifecycle.destroy, hd, Bool.false_eq_true, ↓reduceIte, hc,
    List.nil_append, List.mem_map, List.mem_filter, List.length_map]
  constructor
  · rintro ⟨c, ⟨hm, hn⟩, ha⟩
    refine ⟨⟨c, hm, ha⟩, ?_⟩
    rintro ⟨d, ⟨e, ⟨he, hp⟩, rfl⟩, hea⟩
    simp only at hea
    rw [hea] at hp
    rw [ha] at hn
    rw [hp] at hn
    cases hn
  · rintro ⟨⟨c, hm, ha⟩, hn⟩
    refine ⟨c, ⟨hm, ?_⟩, ha⟩
    generalize hb : (s.execution.outside.flatMap
      (Trial.chainAddrs (s.execution.mem.cells.map fun c =>
        (⟨c.addr, c.item, c.link, c.count⟩ : Trial.StartCell))
        s.execution.mem.cells.length)).contains c.addr = b
    cases b
    · rfl
    · exact False.elim (hn ⟨_, ⟨c, ⟨hm, hb⟩, rfl⟩, ha⟩)

theorem lifecycle_step_preserves_destruction_metadata
    (p : Program) (allow : Lifecycle.Policy) (s t : Lifecycle.State)
    (h : Lifecycle.step p allow s = .ok t) :
    t.destroyed = s.destroyed ∧ t.cleanup = s.cleanup := by
  unfold Lifecycle.step at h
  split at h
  · cases h
    exact ⟨rfl, rfl⟩
  · cases hr : Lifecycle.request s.execution with
    | none =>
      simp only [hr] at h
      cases hs : Counted.step p s.execution with
      | error e => simp [hs] at h
      | ok e => simp [hs] at h; cases h; exact ⟨rfl, rfl⟩
    | some r =>
      simp only [hr] at h
      split at h
      · cases hs : Counted.step p s.execution with
        | error e => simp [hs] at h
        | ok e => simp [hs] at h; cases h; exact ⟨rfl, rfl⟩
      · cases h
        exact ⟨rfl, rfl⟩

theorem lifecycle_advance_preserves_destruction_metadata
    (p : Program) (allow : Lifecycle.Policy) (n : Nat)
    (s t : Lifecycle.State) (h : Lifecycle.advance p allow n s = .ok t) :
    t.destroyed = s.destroyed ∧ t.cleanup = s.cleanup := by
  induction n generalizing s t with
  | zero => cases h; exact ⟨rfl, rfl⟩
  | succ n ih =>
    unfold Lifecycle.advance at h
    split at h
    · cases h; exact ⟨rfl, rfl⟩
    · cases hs : Lifecycle.step p allow s with
      | error e => simp [hs] at h
      | ok u =>
        simp [hs] at h
        obtain ⟨hd, hc⟩ := ih u t h
        obtain ⟨hd', hc'⟩ := lifecycle_step_preserves_destruction_metadata p allow s u hs
        exact ⟨hd.trans hd', hc.trans hc'⟩

theorem lifecycleReachable_destruction_metadata
    (p : Program) (initial : Trial.Start) (s : Lifecycle.State)
    (h : Statements.lifecycleReachable p initial s) :
    s.destroyed = false ∧ s.cleanup = [] := by
  obtain ⟨first, allow, n, _, ha⟩ := h
  exact lifecycle_advance_preserves_destruction_metadata p allow n
    { execution := first } s ha

theorem lifecycleReachable_cleanup_membership
    (p : Program) (initial : Trial.Start) (s : Lifecycle.State)
    (h : Statements.lifecycleReachable p initial s) (addr : Nat) :
    addr ∈ (Lifecycle.destroy s).cleanup ↔
      (∃ c ∈ s.execution.mem.cells, c.addr = addr) ∧
      ¬ (∃ c ∈ (Lifecycle.destroy s).execution.mem.cells, c.addr = addr) := by
  obtain ⟨hd, hc⟩ := lifecycleReachable_destruction_metadata p initial s h
  exact destroy_cleanup_membership s hd hc addr

theorem lifecycleReachable_clears_control
    (p : Program) (initial : Trial.Start) (s : Lifecycle.State)
    (h : Statements.lifecycleReachable p initial s) :
    (Lifecycle.destroy s).execution.bindings = [] ∧
    (Lifecycle.destroy s).execution.entered = [] ∧
    (Lifecycle.destroy s).execution.slots = [] ∧
    (Lifecycle.destroy s).execution.reservations = [] ∧
    (Lifecycle.destroy s).execution.frames = [] ∧
    (Lifecycle.destroy s).execution.tasks = [] ∧
    (Lifecycle.destroy s).execution.releaseChain = [] ∧
    (Lifecycle.destroy s).execution.answer = none := by
  exact destroy_clears_control s
    (lifecycleReachable_destruction_metadata p initial s h).1

end Full.Proofs
