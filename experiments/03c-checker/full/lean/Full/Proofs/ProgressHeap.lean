import Full.Proofs.ProgressControl
import Full.Proofs.LiveBindings
import Full.Proofs.Free
import Proofs.Liveness

namespace Full.Proofs.Progress
open Counted CountedTyping Trial Trial.Proofs

theorem root_ready (hi : Inspect.invariant initial s = true)
    (hr : some addr ∈ executionRoots s) :
    ∃ c, s.mem.find? addr = some c ∧ c.status = .live ∧ 0 < c.count := by
  obtain ⟨hh,_,_⟩ := invariant_heap initial s hi
  obtain ⟨cs,hpath⟩ := hh.readable _ hr
  obtain ⟨c,ds,_,hf,ha,hl,_⟩ := hpath.head
  have hc := hh.counts c (List.mem_of_find?_eq_some hf) hl
  have hm : some addr ∈ (executionRoots s).filter (fun r => r == some addr) := by
    simp [hr]
  have hn : 0 < ((executionRoots s).filter (fun r => r == some addr)).length :=
    List.length_pos_of_mem hm
  refine ⟨c,hf,hl,?_⟩
  simp only [holders,ha] at hc
  omega

theorem binding_root (hb : b ∈ s.bindings) (hh : b.record.status = .holding)
    (hv : b.record.value = .list (some addr)) : some addr ∈ executionRoots s := by
  simp only [executionRoots,List.mem_append,List.mem_map,List.mem_filter]
  exact Or.inr ⟨b,⟨hb,by simp [hh]⟩,by simp [Inspect.link,hv]⟩

theorem slot_root (hv : v ∈ s.slots) (he : v.raw = .list (some addr)) :
    some addr ∈ executionRoots s := by
  simp only [executionRoots,List.mem_append,List.mem_map]
  exact Or.inl (Or.inl ⟨v,hv,by simp [Inspect.link,he]⟩)

theorem variable_progress (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = .eval (.var x) ctx :: rest) :
    ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨out,_,ks,fs,_,_,hw,_⟩ := reachable_typed hr
  rw [ht] at hw
  obtain ⟨static,k,henv,hcheck,_⟩ := top_eval hw
  obtain ⟨id,b,he,hb,_⟩ := env_variable p henv hcheck
  cases hv : b.record.value with
  | num n | bool v => simp [Counted.transition,ht,he,hb,hv]
  | list a =>
    cases a with
    | none => simp [Counted.transition,ht,he,hb,hv]
    | some addr =>
      have hm := List.mem_of_find?_eq_some hb
      have hid : b.record.id = id := by simpa using List.find?_some hb
      have hu : s.tasks.any (taskUses b.record.id) = true := by
        simp [ht,taskUses,uses,Trial.Proofs.lookup_frame_env,he,hid]
      have hh := LiveBindings.reachable_live hr b hm addr hv hu
      obtain ⟨c,hf,hl,_⟩ := root_ready hi (binding_root hm hh hv)
      cases hlater : rest.any (taskUses id) <;>
        simp [Counted.transition,ht,he,hb,hv,hh,hlater,hf,hl,Memory.setCount]

theorem binding_progress {id : Nat} (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = .giveBinding id :: rest) :
    ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨b,addr,hb,hh,hv⟩ := ReleaseQueue.reachable_binding (bid := id) hr (by simp [ht])
  obtain ⟨c,hf,hl,hpos⟩ := root_ready hi
    (binding_root (List.mem_of_find?_eq_some hb) hh hv)
  have hz : c.count ≠ 0 := by omega
  simp [Counted.transition,ht,hb,hh,hv,hf,hl,hz,Memory.setCount]

theorem reservation_ready (hi : Inspect.invariant initial s = true)
    (hr : r ∈ s.reservations) :
    ∃ c, s.mem.find? r.addr = some c ∧ c.status = .setAside ∧ c.count = 0 := by
  have h := hi
  simp only [Inspect.invariant,Bool.and_eq_true,beq_iff_eq,List.all_eq_true] at h
  obtain ⟨⟨⟨⟨⟨⟨⟨_,_⟩,_⟩,_⟩,_⟩,hc⟩,hrs⟩,_⟩ := h
  obtain ⟨c,hm,ha⟩ := List.any_eq_true.mp (hrs r hr)
  simp only [Bool.and_eq_true,beq_iff_eq] at ha
  obtain ⟨haddr,hstatus⟩ := ha
  have hz := (hc c hm).2
  simp only [hstatus,↓reduceIte,Bool.and_eq_true,beq_iff_eq] at hz
  obtain ⟨hh,_,_⟩ := invariant_heap initial s hi
  refine ⟨c,?_,hstatus,hz.1.1⟩
  rw [← haddr]
  exact find_of_mem s.mem hh.unique c hm

set_option maxHeartbeats 1000000 in
theorem cons_progress (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = .primitive .cons ctx :: rest) :
    ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨out,_,ks,fs,hs,_,hw,_⟩ := reachable_typed hr
  rw [ht] at hw
  cases hw
  cases he : s.slots with
  | nil => rw [he] at hs; cases hs
  | cons b more =>
    rw [he] at hs
    cases hm : more with
    | nil => rw [hm] at hs; cases hs; cases ‹SlotsTyped [] (_ :: _)›
    | cons a slots =>
      rw [hm] at hs
      cases hs with
      | cons hb hs =>
        cases hs with
        | cons ha hs =>
          rcases ha with ⟨har,hav⟩
          rcases hb with ⟨hbr,hbv⟩
          simp only [PlainTyping.rightKind] at hbr hbv
          cases hra : a.raw <;> simp_all [RawValue.kind]
          cases hrb : b.raw <;> simp_all [RawValue.kind]
          cases hva : a.value <;> simp_all [PlainValue.kind]
          cases hvb : b.value <;> simp_all [PlainValue.kind]
          cases hel : s.reservations.find? (fun r =>
              r.invocation == ctx.invocation && ctx.branches.contains r.branch) with
          | none =>
            simp only [List.contains_eq_mem] at hel
            simp [Counted.transition,ht,he,hm,hra,hrb,hva,hvb,Plain.primitive,hel]
          | some r =>
            obtain ⟨c,hf,hl,_⟩ := reservation_ready hi (List.mem_of_find?_eq_some hel)
            simp only [List.contains_eq_mem] at hel
            simp [Counted.transition,ht,he,hm,hra,hrb,hva,hvb,Plain.primitive,hel,
              Memory.writeInPlace,hf,hl]

theorem pending_progress (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = .givePending :: rest)
    (hv : s.slots = v :: slots) (hr : v.raw = .list (some addr)) :
    ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨c,hf,hl,hpos⟩ := root_ready hi (slot_root (by simp [hv]) hr)
  have hz : c.count ≠ 0 := by omega
  simp [Counted.transition,ht,hv,hr,hf,hl,hz,Memory.setCount]

theorem reserved_progress (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = .freeReserved addr :: rest)
    (hr : ∃ r ∈ s.reservations, r.addr = addr) :
    ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨r,hm,ha⟩ := hr
  obtain ⟨c,hf,hl,hz⟩ := reservation_ready hi hm
  rw [ha] at hf
  simp [Counted.transition,ht,hf,hl,hz,Memory.release]

theorem free_progress (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = .free addr :: rest)
    (hr : ∃ c, s.mem.find? addr = some c ∧ c.status = .live ∧ c.count = 0) :
    ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨c,hf,hl,hz⟩ := hr
  obtain ⟨change,hc,_⟩ := free_from_invariant p initial s addr c rest hi ht hf hl hz
  exact ⟨change,hc⟩

theorem slot_readable (hi : Inspect.invariant initial s = true) (hm : v ∈ s.slots) :
    Inspect.readable s v = true := by
  have h := hi
  simp only [Inspect.invariant,Bool.and_eq_true] at h
  have hp := h.1.1.1.1.1.1.1
  simp only [Inspect.protection,Bool.and_eq_true,List.all_eq_true] at hp
  exact hp.1.2 v hm

theorem nonempty_value (hi : Inspect.invariant initial s = true)
    (hm : v ∈ s.slots) (hv : v.raw = .list (some addr)) :
    ∃ ph pt, v.value = .list (ph :: pt) := by
  have hread := slot_readable hi hm
  obtain ⟨c,hf,hl,_⟩ := root_ready hi (slot_root hm hv)
  have hn := List.length_pos_of_mem (List.mem_of_find?_eq_some hf)
  cases he : s.mem.cells.length with
  | zero => omega
  | succ n =>
    cases hr : readList s.mem n c.link with
    | error err => simp [Inspect.readable,hv,readBack,readList,he,hf,hl,hr] at hread
    | ok items =>
      have heq : .list (c.item :: items) = v.value := by
        simpa [Inspect.readable,hv,readBack,readList,he,hf,hl,hr,beq_iff_eq] using hread
      exact ⟨c.item,items,heq.symm⟩

theorem decompose_progress (hi : Inspect.invariant initial s = true)
    (ht : s.tasks = .decompose h t body bid ctx :: rest)
    (hv : s.slots = v :: slots) (hr : v.raw = .list (some addr)) :
    ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨ph,pt,hvalue⟩ := nonempty_value hi (by simp [hv]) hr
  obtain ⟨c,hf,hl,hpos⟩ := root_ready hi (slot_root (by simp [hv]) hr)
  have hz : c.count ≠ 0 := by omega
  obtain ⟨hh,hpaths,_⟩ := invariant_heap initial s hi
  have hm := List.mem_of_find?_eq_some hf
  obtain ⟨cs,hpath⟩ := hpaths c hm hl
  obtain ⟨d,ds,_,hfd,_,_,htail⟩ := hpath.head
  have hca : c.addr = addr := by simpa using List.find?_some hf
  rw [hca,hf] at hfd
  cases hfd
  cases hlink : c.link with
  | none =>
    simp [Counted.transition,ht,hv,hr,hvalue,hf,hl,hz,Memory.markSetAside,hlink]
    split <;> simp
  | some tail =>
    rw [hlink] at htail
    obtain ⟨tc,_,_,htc,_,_,_⟩ := htail.head
    simp [Counted.transition,ht,hv,hr,hvalue,hf,hl,hz,Memory.markSetAside,hlink,
      Memory.setCount,htc]
    repeat' first | split | solve | simp

end Full.Proofs.Progress
