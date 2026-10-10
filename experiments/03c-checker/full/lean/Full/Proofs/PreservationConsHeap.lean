import Full.Proofs.PreservationRelease
import Full.Proofs.ReservedReadiness
import Proofs.Build

namespace Full.Proofs.PreservationCons
open Counted Trial Trial.Proofs

/-- Scalar operands contribute no owners, including when the tail is empty. -/
theorem source_holders (s : State) (b a : Slot) (slots : List Slot)
    (hs : s.slots = b :: a :: slots) (ha : a.raw = .num h)
    (hb : b.raw = .list t) (addr : Nat) :
    holders s.mem (executionRoots s) addr =
      holders s.mem (t :: (slots.map (fun v => Inspect.link v.raw) ++ s.outside ++
        (s.bindings.filter (fun b => b.record.status == .holding)).map
          (fun b => Inspect.link b.record.value))) addr := by
  cases he : t == some addr <;>
    simp [executionRoots, hs, ha, hb, Inspect.link, holders, List.filter_cons, he]

theorem readable_readback (hv : Inspect.readable s v = true) :
    readBack s.mem v.raw = .ok v.value := by
  cases he : readBack s.mem v.raw with
  | error err => simp [Inspect.readable, he] at hv
  | ok value =>
    have h : value = v.value := by simpa [Inspect.readable, he] using hv
    simpa [h] using he

theorem create_preserves_readback (m : Memory) (h : Int) (t : Option Nat)
    (v : RawValue) (w : PlainValue) (hv : readBack m v = .ok w) :
    readBack (m.create h t).2 v = .ok w := by
  cases v with
  | num n | bool b => simpa [readBack] using hv
  | list r =>
    cases hr : readList m m.cells.length r with
    | error err => simp [readBack, hr] at hv
    | ok items =>
      have he : w = .list items := by simpa [readBack, hr] using hv.symm
      obtain ⟨cs,hp,hitems⟩ := path_of_read hr
      simpa [he, hitems] using (hp.create h t).read_back

theorem write_preserves_readback (m m' : Memory) (addr : Nat) (h : Int)
    (t : Option Nat) (hw : m.writeInPlace addr h t = .ok m')
    (v : RawValue) (w : PlainValue) (hv : readBack m v = .ok w) :
    readBack m' v = .ok w := by
  cases v with
  | num n | bool b => simpa [readBack] using hv
  | list r =>
    cases hr : readList m m.cells.length r with
    | error err => simp [readBack, hr] at hv
    | ok items =>
      have he : w = .list items := by simpa [readBack, hr] using hv.symm
      obtain ⟨cs,hp,hitems⟩ := path_of_read hr
      simpa [he, hitems] using
        (write_in_place_preserves m m' addr h t hw r cs hp).read_back

theorem edge_lookup_other (edges : List (Nat × Value)) (addr other : Nat)
    (value : Value) (hn : other ≠ addr) :
    ((addr,value) :: edges.filter (fun q => q.1 != addr)).find?
      (fun q => q.1 == other) = edges.find? (fun q => q.1 == other) := by
  simp only [List.find?_cons, show (addr == other) = false from
    beq_eq_false_iff_ne.mpr (Ne.symm hn), Bool.false_eq_true, ↓reduceIte,
    List.find?_filter]
  congr 1
  funext q
  by_cases he : q.1 = other <;> simp [he, hn]

theorem reservation_filter_other (rs : List Reservation) (addr other : Nat)
    (hn : other ≠ addr) :
    ((rs.filter (fun r => r.addr != addr)).filter (fun r => r.addr == other)) =
      rs.filter (fun r => r.addr == other) := by
  rw [List.filter_filter]
  apply List.filter_congr
  intro r _
  by_cases he : r.addr = other <;> simp [he, hn]

end Full.Proofs.PreservationCons
