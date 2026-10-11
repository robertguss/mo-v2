import Full.Demand.Framing
import Full.Proofs.DestructionGraph
import Full.Proofs.Invariance
import Full.Proofs.ProgressHeap

namespace Full.Demand.Region
open Counted Full.Proofs Trial Trial.Proofs

def addresses (s : State) (f : Counted.Frame) : List Nat :=
  f.args.flatMap (fun v => chainAddrs (s.mem.cells.map Destruction.project)
    s.mem.cells.length (Inspect.link v.raw))

def RawIn (region : List Nat) (v : Raw) : Prop :=
  ∀ a, Inspect.link v = some a → a ∈ region

/-- A fixed address set, not the currently allocated set. A live cell awaiting
Free is allowed to have count zero; freed addresses remain in the region. -/
structure Heap (region : List Nat) (mem : Memory) : Prop where
  bounded : ∀ c ∈ mem.cells, c.addr ∈ region → c.count ≤ 1
  closed : ∀ c ∈ mem.cells, c.addr ∈ region → c.status = .live →
    ∀ a, c.link = some a → a ∈ region

theorem path_root (h : ListPath mem (some a) cs) : a ∈ cs.map Cell.addr := by
  cases h
  simp

theorem path_link (h : ListPath mem r cs) (hc : c ∈ cs) (hl : c.link = some a) :
    a ∈ cs.map Cell.addr := by
  induction h with
  | nil => simp at hc
  | cons d ds hf hs ht ih =>
    rcases List.mem_cons.mp hc with rfl | hc
    · rw [hl] at ht
      exact List.mem_cons_of_mem _ (path_root ht)
    · exact List.mem_cons_of_mem _ (ih hc)

/-- Arguments are readable immediately at Enter, before dead-parameter
cleanup. Reading the predecessor's actual operand slots avoids treating the
historical Frame.args snapshots as owners in subsequent states. -/
theorem entry_paths (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter")
    (hf : s.frames.head? = some f) :
    ∀ v ∈ f.args, ∃ cs, ListPath s.mem (Inspect.link v.raw) cs := by
  obtain ⟨before,c,hr',ht,ha,rfl⟩ := Events.last_enter hr hl
  obtain ⟨arity,ctx,rest,htask,_⟩ := Entry.source ht ha hf
  have heap := (invariant_heap initial before (Invariance.reachable_invariant hr')).1
  simp only [Counted.transition,htask,bind,pure,Except.bind,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  simp only [commit,List.head?_cons,Option.some.injEq] at hf
  have hargs := congrArg Counted.Frame.args hf
  intro v hv
  rw [← hargs] at hv
  apply heap.readable
  apply List.mem_append_left
  apply List.mem_append_left
  exact List.mem_map.mpr ⟨v,List.mem_of_mem_take (List.mem_reverse.mp hv),rfl⟩

theorem unique_cells (hu : Statements.uniqueEntry s f = true)
    (ha : a ∈ addresses s f) :
    ∃ c ∈ s.mem.cells, c.addr = a ∧ c.status = .live ∧ c.count = 1 := by
  simp only [Statements.uniqueEntry,Bool.and_eq_true,List.length_map] at hu
  have hc := List.all_eq_true.mp hu.2 a ha
  obtain ⟨c,hm,hc⟩ := List.any_eq_true.mp hc
  simp only [Bool.and_eq_true,beq_iff_eq] at hc
  exact ⟨c,hm,hc.1.1,hc.1.2,hc.2⟩

theorem entry_heap (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter")
    (hf : s.frames.head? = some f) (hu : Statements.uniqueEntry s f = true) :
    Heap (addresses s f) s.mem := by
  have hheap := (invariant_heap initial s (Invariance.reachable_invariant hr)).1
  have hp := entry_paths hr hl hf
  constructor
  · intro c hc ha
    obtain ⟨d,hd,haddr,_,hcount⟩ := unique_cells hu ha
    have hfind := find_of_mem s.mem hheap.unique c hc
    have hfind' := find_of_mem s.mem hheap.unique d hd
    rw [haddr] at hfind'
    cases Option.some.inj (hfind.symm.trans hfind')
    omega
  · intro c hc ha _ a hlink
    obtain ⟨v,hv,ha⟩ := List.mem_flatMap.mp ha
    obtain ⟨cs,hpath⟩ := hp v hv
    rw [Destruction.path_chain hpath _ hpath.length_le] at ha
    obtain ⟨d,hd,haddr⟩ := List.mem_map.mp ha
    have hfind := find_of_mem s.mem hheap.unique c hc
    have hfind' := (hpath.lookup d hd).1
    rw [haddr] at hfind'
    cases Option.some.inj (hfind.symm.trans hfind')
    apply List.mem_flatMap.mpr
    refine ⟨v,hv,?_⟩
    rw [Destruction.path_chain hpath _ hpath.length_le]
    exact path_link hpath hd hlink

theorem entry_roots (hr : Statements.Reachable p initial s)
    (hl : s.history.getLast?.map Action.name = some "Enter")
    (hf : s.frames.head? = some f) (hv : v ∈ f.args) : RawIn (addresses s f) v.raw := by
  intro a ha
  obtain ⟨cs,hp⟩ := entry_paths hr hl hf v hv
  apply List.mem_flatMap.mpr
  refine ⟨v,hv,?_⟩
  rw [Destruction.path_chain hp _ hp.length_le]
  rw [ha] at hp
  exact path_root hp

/-- A local scrutinee is necessarily in the unique Decompose arm. The lower
bound comes from global counted ownership; the upper bound is regional. -/
theorem scrutinee_unique (hr : Statements.Reachable p initial s) (heap : Heap region s.mem)
    (hv : v ∈ s.slots) (hin : RawIn region v.raw) (he : v.raw = .list (some a)) :
    ∃ c, s.mem.find? a = some c ∧ c.status = .live ∧ c.count = 1 := by
  obtain ⟨c,hc,hl,hpos⟩ := Progress.root_ready (Invariance.reachable_invariant hr)
    (Progress.slot_root hv he)
  have haddr : c.addr = a := by simpa using List.find?_some hc
  have hcount := heap.bounded c (List.mem_of_find?_eq_some hc) (haddr ▸ hin a (by simp [he,Inspect.link]))
  exact ⟨c,hc,hl,by omega⟩

theorem Heap.update (h : Heap region mem) (addr : Nat) (f : Cell → Cell)
    (ha : ∀ c, (f c).addr = c.addr)
    (hf : ∀ c ∈ mem.cells, c.addr = addr → c.addr ∈ region →
      (f c).count ≤ 1 ∧ ((f c).status = .live → ∀ a, (f c).link = some a → a ∈ region)) :
    Heap region (mem.updateCell addr f) := by
  constructor
  · intro c hc hr
    obtain ⟨d,hd,rfl⟩ := List.mem_map.mp hc
    by_cases he : d.addr = addr
    · simpa [he] using (hf d hd he (by simpa [he,ha] using hr)).1
    · simpa [he] using h.bounded d hd (by simpa [he] using hr)
  · intro c hc hr hl a hlink
    obtain ⟨d,hd,rfl⟩ := List.mem_map.mp hc
    by_cases he : d.addr = addr
    · exact (hf d hd he (by simpa [he,ha] using hr)).2
        (by simpa [he] using hl) a (by simpa [he] using hlink)
    · exact h.closed d hd (by simpa [he] using hr)
        (by simpa [he] using hl) a (by simpa [he] using hlink)

theorem Heap.set_count (h : Heap region mem) (hn : n ≤ 1)
    (ht : mem.setCount a n = .ok mem') : Heap region mem' := by
  simp only [Memory.setCount,pure,Except.pure] at ht
  split at ht
  · cases ht
  · cases ht
    apply h.update a (fun c => { c with count := n }) (fun _ => rfl)
    intro c hc _ hr
    exact ⟨hn,h.closed c hc hr⟩

theorem Heap.set_aside (h : Heap region mem)
    (ht : mem.markSetAside a = .ok mem') : Heap region mem' := by
  simp only [Memory.markSetAside,pure,Except.pure] at ht
  split at ht
  · cases ht
  · cases ht
    apply h.update a (fun c => { c with status := .setAside, count := 0, link := none })
      (fun _ => rfl)
    intro c hc _ hr
    exact ⟨Nat.zero_le 1,by simp⟩

theorem Heap.write (h : Heap region mem) (hin : ∀ a, link = some a → a ∈ region)
    (ht : mem.writeInPlace a item link = .ok mem') : Heap region mem' := by
  simp only [Memory.writeInPlace,pure,Except.pure] at ht
  repeat' first | split at ht | cases ht | contradiction
  constructor
  · intro c hc hr
    obtain ⟨d,hd,rfl⟩ := List.mem_map.mp hc
    by_cases he : d.addr = a
    · simp [he]
    · simpa [he] using h.bounded d hd (by simpa [he] using hr)
  · intro c hc hr hl addr hlink
    obtain ⟨d,hd,rfl⟩ := List.mem_map.mp hc
    by_cases he : d.addr = a
    · exact hin addr (by simpa [he] using hlink)
    · exact h.closed d hd (by simpa [he] using hr)
        (by simpa [he] using hl) addr (by simpa [he] using hlink)

theorem Heap.release (h : Heap region mem)
    (ht : mem.release a = .ok mem') : Heap region mem' := by
  simp only [Memory.release,pure,Except.pure] at ht
  split at ht
  · cases ht
  · cases ht
    exact ⟨fun c hc => h.bounded c (List.mem_filter.mp hc).1,
      fun c hc => h.closed c (List.mem_filter.mp hc).1⟩

end Full.Demand.Region
