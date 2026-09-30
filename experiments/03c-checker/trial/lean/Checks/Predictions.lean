import Trial.Broken

/-! Independently copied from the locked PREDICTIONS.md. Derivations are not
acceptance checks. Timing moments are numbered innermost first, as built. -/
namespace Checks
open Trial

structure Totals where
  allocations : Nat
  reuses : Nat
  frees : Nat
  deriving DecidableEq, Repr

structure Prediction where
  number : Nat
  answer : PlainValue
  totals : Totals

def predictions : List Prediction :=
  [⟨1, .list [2, 2, 3], ⟨0, 1, 0⟩⟩,
   ⟨2, .list [2], ⟨0, 1, 0⟩⟩,
   ⟨3, .list [], ⟨0, 0, 0⟩⟩,
   ⟨4, .list [9223372036854775808], ⟨0, 1, 0⟩⟩,
   ⟨5, .list [2, 2, 3], ⟨1, 0, 0⟩⟩,
   ⟨6, .list [2, 1, 3], ⟨0, 2, 0⟩⟩,
   ⟨7, .list [1], ⟨0, 1, 0⟩⟩,
   ⟨8, .list [2, 1, 3], ⟨1, 1, 0⟩⟩,
   ⟨9, .list [2, 3], ⟨0, 0, 1⟩⟩,
   ⟨10, .num 9, ⟨0, 0, 2⟩⟩,
   ⟨11, .num 7, ⟨0, 0, 3⟩⟩,
   ⟨12, .list [0, 1, 2], ⟨1, 0, 0⟩⟩,
   ⟨13, .list [1, 1, 2], ⟨1, 1, 0⟩⟩,
   ⟨14, .list [1, 2, 2], ⟨1, 1, 0⟩⟩,
   ⟨15, .list [3, 3, 4], ⟨0, 1, 1⟩⟩,
   ⟨16, .list [2, 2], ⟨0, 1, 0⟩⟩,
   ⟨17, .list [2], ⟨0, 0, 1⟩⟩,
   ⟨18, .list [2, 2], ⟨0, 1, 0⟩⟩,
   ⟨19, .list [2, 2], ⟨0, 1, 0⟩⟩,
   ⟨20, .list [2], ⟨0, 0, 1⟩⟩,
   ⟨21, .list [2, 2], ⟨0, 1, 0⟩⟩,
   ⟨22, .list [2, 2], ⟨0, 1, 0⟩⟩,
   ⟨23, .list [1, 3, 3], ⟨0, 2, 0⟩⟩,
   ⟨24, .list [2, 2], ⟨0, 1, 0⟩⟩,
   ⟨25, .bool true, ⟨0, 0, 2⟩⟩,
   ⟨26, .list [1, 2, 2], ⟨1, 1, 0⟩⟩,
   ⟨27, .list [5], ⟨1, 0, 2⟩⟩,
   ⟨28, .list [-3], ⟨0, 1, 0⟩⟩]

inductive CellClaim where
  | aside (owner : Addr)
  | absent
  | live

structure TimingCell where
  addr : Addr
  claim : CellClaim

structure TimingMoment where
  label : String
  kind : StepKind
  occurrence : Nat
  cells : List TimingCell
  /-- Recorded branch value, read back in this snapshot; none at branch start. -/
  branchValue : Option PlainValue
  /-- The list result's holder, or none when the result holds no cell. -/
  resultHolder : Option Addr
  /-- Cells released by this moment. This does not predict their release order. -/
  released : List Addr

structure TimingPrediction where
  number : Nat
  boundaries : Nat
  moments : List TimingMoment

def timingPredictions : List TimingPrediction :=
  [⟨9, 1,
     [⟨"Branch value worked out: [2, 3]; intermediate result holds c2",
       .branchValueWorkedOut, 0, [⟨1, .aside 1⟩, ⟨2, .live⟩, ⟨3, .live⟩], some (.list [2, 3]), some 2, []⟩,
      ⟨"Branch value handed on: answer holder goes to caller; tail stays live",
       .branchValueHandedOn, 0, [⟨1, .absent⟩, ⟨2, .live⟩, ⟨3, .live⟩], some (.list [2, 3]), some 2, [1]⟩]⟩,
   ⟨10, 2,
     [⟨"Inner branch value worked out: number 9 holds no cell",
       .branchValueWorkedOut, 0, [⟨1, .aside 1⟩, ⟨2, .aside 2⟩], some (.num 9), none, []⟩,
      ⟨"Inner branch value handed on: only its c2 is freed",
       .branchValueHandedOn, 0, [⟨1, .aside 1⟩, ⟨2, .absent⟩], some (.num 9), none, [2]⟩,
      ⟨"Outer branch value worked out: number 9 holds no cell",
       .branchValueWorkedOut, 1, [⟨1, .aside 1⟩, ⟨2, .absent⟩], some (.num 9), none, [2]⟩,
      ⟨"Outer branch value handed on: c1 is now freed",
       .branchValueHandedOn, 1, [⟨1, .absent⟩, ⟨2, .absent⟩], some (.num 9), none, [2, 1]⟩]⟩,
   ⟨11, 1,
     [⟨"Before the branch runs: unused rest given up; detached tail already freed",
       .branchStarts, 0, [⟨1, .aside 1⟩, ⟨2, .absent⟩, ⟨3, .absent⟩], none, none, [2, 3]⟩,
      ⟨"Branch value worked out: number 7 holds no cell; unused tail already freed",
       .branchValueWorkedOut, 0, [⟨1, .aside 1⟩, ⟨2, .absent⟩, ⟨3, .absent⟩], some (.num 7), none, [2, 3]⟩,
      ⟨"Branch value handed on: front freed after detached tail",
       .branchValueHandedOn, 0, [⟨1, .absent⟩, ⟨2, .absent⟩, ⟨3, .absent⟩], some (.num 7), none, [2, 3, 1]⟩]⟩]

end Checks
