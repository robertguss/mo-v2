import Full.Proofs.CountedTyping

/-! Progress for control transfers that do not read or mutate the heap.
The excluded cases are stated explicitly, not assumed successful. -/
namespace Full.Proofs.Progress
open Counted CountedTyping

def HeapTask : Task → Prop
  | .eval (.var _) _ | .primitive .cons _ | .decompose _ _ _ _ _
  | .giveBinding _ | .givePending | .free _ | .freeReserved _ => True
  | _ => False

theorem slot_exists (hr : Statements.Reachable p initial s)
    (ht : s.tasks = task :: rest) (hn : 1 ≤ Residual.operands task) :
    ∃ v slots, s.slots = v :: slots := by
  have h := Residual.reachable_operands hr ht
  cases he : s.slots with
  | nil => simp [he] at h; omega
  | cons v slots => exact ⟨v,slots,rfl⟩

set_option maxHeartbeats 1000000 in
theorem control_progress (hr : Statements.Reachable p initial s)
    (ht : s.tasks = task :: rest) (hh : ¬ HeapTask task) :
    ∃ c, Counted.transition p s = .ok c := by
  obtain ⟨out,_,ks,fs,hslots,hframes,hwork,_⟩ := reachable_typed hr
  rw [ht] at hwork
  cases task with
  | start | capture | handoff | matchComplete ctx | branchStart ctx =>
    simp [Counted.transition,ht]
  | eval e ctx =>
    cases e <;> simp_all [HeapTask, Counted.transition]
  | primitive op ctx =>
    cases hwork
    cases he : s.slots with
    | nil => simp [he] at hslots; cases hslots
    | cons b more =>
      rw [he] at hslots
      cases hm : more with
      | nil => rw [hm] at hslots; cases hslots; cases ‹SlotsTyped [] (_ :: _)›
      | cons a slots =>
        rw [hm] at hslots
        cases hslots with
        | cons hb hslots =>
          cases hslots with
          | cons ha hslots =>
            rcases ha with ⟨har,hav⟩
            rcases hb with ⟨hbr,hbv⟩
            cases op <;> simp_all [HeapTask, PlainTyping.rightKind]
            all_goals cases hra : a.raw <;> simp_all [Trial.RawValue.kind]
            all_goals cases hrb : b.raw <;> simp_all [Trial.RawValue.kind]
            all_goals cases hva : a.value <;> simp_all [Trial.PlainValue.kind]
            all_goals cases hvb : b.value <;>
              simp_all [Trial.PlainValue.kind,Counted.transition,Plain.primitive]
  | bind x body ctx =>
    obtain ⟨v,slots,hv⟩ := slot_exists hr ht (by simp [Residual.operands])
    simp [Counted.transition,ht,hv]
  | chooseIf yes no ctx =>
    cases hwork
    obtain ⟨v,slots,hv⟩ := slot_exists hr ht (by simp [Residual.operands])
    rw [hv] at hslots
    cases hslots with
    | cons hkind hs =>
      have hk := hkind.1
      cases he : v.raw <;> simp_all [Trial.RawValue.kind,Counted.transition]
  | chooseMatch empty h t body ctx =>
    cases hwork
    obtain ⟨v,slots,hv⟩ := slot_exists hr ht (by simp [Residual.operands])
    rw [hv] at hslots
    cases hslots with
    | cons hkind hs =>
      have hk := hkind.1
      cases he : v.raw <;> simp_all [Trial.RawValue.kind,Counted.transition]
  | branchResult bid inner outer =>
    obtain ⟨v,slots,hv⟩ := slot_exists hr ht (by simp [Residual.operands])
    simp [Counted.transition,ht,hv]
  | handoffMatch ctx =>
    obtain ⟨v,slots,hv⟩ := slot_exists hr ht (by simp [Residual.operands])
    simp [Counted.transition,ht,hv]
  | enter name arity ctx =>
    obtain ⟨f,tail,hf,ha,hks,_⟩ := top_enter hwork
    rw [hks] at hslots
    have hargs := enter_slots hslots
    have hlen := slots_length hargs.1
    have hkind := slots_raw_kinds hargs.1
    simp only [List.length_map,List.length_reverse,List.length_take] at hlen
    simp only [List.length_map,List.map_reverse,List.map_take] at hkind
    simp [Counted.transition,ht,hf,ha,hlen,hkind]
  | returning frame ctx =>
    obtain ⟨v,slots,hv⟩ := slot_exists hr ht (by simp [Residual.operands])
    obtain ⟨active,frames,hf,hi⟩ := Residual.reachable_return hr ht
    simp [Counted.transition,ht,hv,hf,hi]
  | finish =>
    obtain ⟨v,slots,hv⟩ := slot_exists hr ht (by simp [Residual.operands])
    simp [Counted.transition,ht,hv]
  | decompose h t body bid ctx | giveBinding id | givePending
  | free addr | freeReserved addr => simp [HeapTask] at hh

end Full.Proofs.Progress
