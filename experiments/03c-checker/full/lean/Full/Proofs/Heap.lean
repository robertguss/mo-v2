import Full.Inspect
import Proofs.Closed
import Proofs.Initial

namespace Full.Proofs
open Trial Trial.Proofs

/-- External heap roots only: live-cell links are counted separately by
Trial.holders. Slot roots come first so cleanup's tail transfer is a cons. -/
def executionRoots (s : Counted.State) : List (Option Addr) :=
  s.slots.map (fun v => Inspect.link v.raw) ++ s.outside ++
    (s.bindings.filter (fun b => b.record.status == .holding)).map
      (fun b => Inspect.link b.record.value)

private theorem eraseDups_length_le [BEq α] (xs : List α) :
    xs.eraseDups.length ≤ xs.length := by
  cases xs with
  | nil => simp
  | cons x xs =>
    rw [List.eraseDups_cons]
    have := eraseDups_length_le (xs.filter (fun y => !y == x))
    have := List.length_filter_le (fun y => !y == x) xs
    simp only [List.length_cons]
    omega
termination_by xs.length
decreasing_by
  simpa using Nat.lt_succ_of_le (List.length_filter_le (fun y => !y == x) xs)

private theorem nodup_of_eraseDups_length [BEq α] [LawfulBEq α] (xs : List α)
    (h : xs.eraseDups.length = xs.length) : xs.Nodup := by
  cases xs with
  | nil => simp
  | cons x xs =>
    rw [List.eraseDups_cons] at h
    simp only [List.length_cons, Nat.add_right_cancel_iff] at h
    have he : (xs.filter (fun y => !y == x)).length = xs.length := by
      have := eraseDups_length_le (xs.filter (fun y => !y == x))
      have := List.length_filter_le (fun y => !y == x) xs
      omega
    have hall := List.length_filter_eq_length_iff.mp he
    have hf := List.filter_eq_self.mpr hall
    rw [hf] at h
    refine List.nodup_cons.mpr ⟨?_, nodup_of_eraseDups_length xs h⟩
    intro hm
    simpa using hall x hm

/-- The root view and the frozen owner count agree, counting live links once. -/
theorem executionRoots_holders (s : Counted.State) (a : Addr) :
    holders s.mem (executionRoots s) a =
      ((Inspect.owners s).filter (fun r => r == some a)).length := by
  simp [holders, executionRoots, Inspect.owners, List.filter_append,
    List.filter_map, List.filter_filter, Function.comp_def,
    Nat.add_comm, Nat.add_left_comm, Nat.add_assoc, Bool.and_comm]

private theorem path_of_readable (s : Counted.State) (v : Counted.Slot)
    (h : Inspect.readable s v = true) : ∃ cs, ListPath s.mem (Inspect.link v.raw) cs := by
  cases hv : v.raw with
  | num n | bool b => exact ⟨[], .nil⟩
  | list r =>
    cases hr : readList s.mem s.mem.cells.length r with
    | error e => simp [Inspect.readable, hv, readBack, hr] at h
    | ok items =>
      obtain ⟨cs, hp, _⟩ := path_of_read hr
      exact ⟨cs, hp⟩

/-- The frozen executable invariant implies the local heap premises used by
preservation proofs. No positivity assumption excludes cells awaiting Free. -/
theorem invariant_heap (initial : Start) (s : Counted.State)
    (h : Inspect.invariant initial s = true) :
    HeapSafe s.mem (executionRoots s) ∧ LivePaths s.mem ∧ FreshBound s.mem := by
  simp only [Inspect.invariant, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at h
  obtain ⟨⟨⟨⟨⟨⟨⟨hprot, _⟩, hu⟩, _⟩, _⟩, hc⟩, _⟩, _⟩ := h
  simp only [Inspect.protection, Bool.and_eq_true, beq_iff_eq, List.all_eq_true] at hprot
  obtain ⟨⟨⟨⟨ho, hout⟩, hb⟩, hs⟩, _⟩ := hprot
  refine ⟨⟨?_, ?_, ?_⟩, ?_, ?_⟩
  · apply nodup_of_eraseDups_length
    simpa using hu
  · intro r hr
    rcases List.mem_append.mp hr with hr | hr
    · rcases List.mem_append.mp hr with hr | hr
      · obtain ⟨v, hv, rfl⟩ := List.mem_map.mp hr
        exact path_of_readable s v (hs v hv)
      · rw [ho] at hr
        have hd := hout r hr
        cases hm : readList s.mem s.mem.cells.length r with
        | error e =>
          have he : readBack s.mem (.list r) = .error e := by simp [readBack, hm]
          rw [he] at hd
          cases hi : readBack initial.toMemory (.list r) <;> rw [hi] at hd <;> cases hd
        | ok items =>
          obtain ⟨cs, hp, _⟩ := path_of_read hm
          exact ⟨cs, hp⟩
    · obtain ⟨b, hm, rfl⟩ := List.mem_map.mp hr
      obtain ⟨hm, hh⟩ := List.mem_filter.mp hm
      have hd := (hb b hm).2
      have hread : Inspect.readable s ⟨b.record.value,b.value⟩ = true := by
        simpa [beq_iff_eq.mp hh] using hd
      exact path_of_readable s _ hread
  · intro c hm hl
    rw [executionRoots_holders]
    exact (hc c hm).1.2
  · intro c hm hl
    have hd := (hc c hm).2
    simp only [hl] at hd
    cases hr : readList s.mem s.mem.cells.length (some c.addr) with
    | error e => simp [hr, Except.isOk, Except.toBool] at hd
    | ok items =>
      obtain ⟨cs, hp, _⟩ := path_of_read hr
      exact ⟨cs, hp⟩
  · intro c hm
    exact of_decide_eq_true (hc c hm).1.1

/-- Every live cell in an invariant state has its immutable tail association,
with the actual recorded address and readable ghost value. -/
theorem invariant_live_edge (initial : Start) (s : Counted.State)
    (h : Inspect.invariant initial s = true) (c : Cell) (hm : c ∈ s.mem.cells)
    (hl : c.status = .live) :
    ∃ tail, s.edges.find? (fun q => q.1 == c.addr) = some (c.addr,tail) ∧
      Inspect.readable s ⟨.list c.link,tail⟩ = true := by
  simp only [Inspect.invariant, Bool.and_eq_true] at h
  have hp := h.1.1.1.1.1.1.1
  simp only [Inspect.protection, Bool.and_eq_true] at hp
  have he := List.all_eq_true.mp hp.2 c hm
  cases hf : s.edges.find? (fun q => q.1 == c.addr) with
  | none => simp [hl, hf] at he
  | some edge =>
    have ha : edge.1 = c.addr := by simpa using List.find?_some hf
    rcases edge with ⟨addr,tail⟩
    dsimp at ha
    subst addr
    exact ⟨tail, rfl, by simpa [hl, hf] using he⟩

end Full.Proofs
