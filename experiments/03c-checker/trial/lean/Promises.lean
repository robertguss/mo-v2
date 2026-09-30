import Trial

/-!
# The four promises of `PLAN.md` Q2 (a) to (d), as Lean definitions

Definitions only, no theorems. Each promise is about the run of the approved rule,
`runCounted .approved e s`, for every program `e` and starting memory `s` with
`validStart e s = .ok ()` (which already checks `wellFormed` on the inputs' kinds):

* (a) The run finishes: not refused, not failed while running, and its answer can
  be read back from the final memory. (`Finishes`, `PromiseA`)
* (b) Same answer as the plain meaning, with each input's plain value read back
  from the starting memory. (`SameAnswer`, `PromiseB`)
* (c) No list someone else can see changes, at any recorded moment, in every
  snapshot: (c1) the outside holders are the starting ones and each reads back as in
  the starting memory; (c2) every name that still holds its holder reads back as it
  did in the first snapshot where that name held. (`NoVisibleChange`, `PromiseC`)
* (d) Nothing leaks: in the final memory every cell is live, no two share an
  address, the allocated cells are exactly those reachable from the answer and the
  outside holders, and every cell's count equals the holders it actually has.
  (`NoLeak`, `PromiseD`)
-/

namespace Trial

-- Equality of answers and read-backs is decidable: `Except` gets `DecidableEq` from its
-- parts (`String` and `PlainValue` already have it).
deriving instance DecidableEq for Except

/-! ## Reading answers -/

/-- Each input, in order, with its value read back from the starting memory. -/
def startPlain (s : Start) : Except String (List (String × PlainValue)) :=
  s.inputs.mapM (fun p => do
    let v ← readBack s.toMemory p.2
    pure (p.1, v))

/-- The plain meaning's answer for a starting memory: `startPlain s`, then `runPlain e`. -/
def plainAnswer (e : Expr) (s : Start) : Except String PlainValue := do
  let ins ← startPlain s
  runPlain e ins

/-- The answer of a counted run read back from its final memory. A refused run or a
run that failed while running gives an error carrying the reason, never a default. -/
def finalAnswer (o : Outcome) : Except String PlainValue :=
  match o.result with
  | .answer raw => readBack o.memory raw
  | .refused why => throw s!"refused: {why}"
  | .failedRunning why => throw s!"failed while running: {why}"

/-- A memory whose cells are a snapshot's cells (other fields at their defaults),
for reading back. -/
def snapMemory (snap : Snapshot) : Memory := { cells := snap.memory }

/-! ## (a) The run finishes -/

/-- Promise (a): the answer reads back successfully (so the run was not refused and
did not fail while running). Decidable: a `Bool` test, `Except.toBool`. -/
def Finishes (o : Outcome) : Prop := (finalAnswer o).toBool = true

/-! ## (b) Same answer as the plain meaning -/

/-- Promise (b): the answer reads back successfully and is exactly the plain
meaning's answer. Decidable: a `Bool` test and an equality of `Except String
PlainValue` (decidable, see the instance below). -/
def SameAnswer (e : Expr) (s : Start) (o : Outcome) : Prop :=
  (finalAnswer o).toBool = true ∧ finalAnswer o = plainAnswer e s

/-! ## (c) No list someone else can see changes -/

/-- Promise (c1): in every snapshot the outside holders are the starting ones, and
each root reads back in the snapshot's memory exactly as in the starting memory,
where the starting read-back succeeds. Decidable: `∀ x ∈ list`, equalities and a
`Bool` test. -/
def OutsideUnchanged (s : Start) (o : Outcome) : Prop :=
  ∀ snap ∈ o.states, snap.outside = s.outside ∧
    ∀ r ∈ s.outside,
      readBack (snapMemory snap) (.list r) = readBack s.toMemory (.list r) ∧
      (readBack s.toMemory (.list r)).toBool = true

/-- The first snapshot in which some binding with this id has status `holding`. -/
def firstHolding (states : List Snapshot) (id : Nat) : Option Snapshot :=
  states.find? (fun sn => sn.bindings.any (fun b => b.id == id && b.status == .holding))

/-- One holding binding `b`, in snapshot `snap`, reads back as in the first snapshot
where it held, and that first read-back succeeded. (A binding's value never
changes, so reading `b.value` in both memories is reading the same list at two
moments.) A `Bool` test over `firstHolding`, so it is decidable. -/
def NameSteady (states : List Snapshot) (snap : Snapshot) (b : Binding) : Prop :=
  (firstHolding states b.id).any (fun first =>
    (readBack (snapMemory first) b.value).toBool
      && decide (readBack (snapMemory first) b.value = readBack (snapMemory snap) b.value)) = true

/-- Promise (c2): in every snapshot, every binding that still holds its holder is
`NameSteady`. Decidable: `∀ x ∈ list` and an implication on a decidable status. -/
def NamesUnchanged (o : Outcome) : Prop :=
  ∀ snap ∈ o.states, ∀ b ∈ snap.bindings, b.status = .holding → NameSteady o.states snap b

/-- Promise (c): (c1) and (c2). Decidable, a conjunction of decidable statements. -/
def NoVisibleChange (s : Start) (o : Outcome) : Prop :=
  OutsideUnchanged s o ∧ NamesUnchanged o

/-! ## (d) Nothing leaks -/

/-- The addresses met walking from one root along links, bounded by the number of
cells as `readList` is: a readable walk visits distinct live cells, so needs at most
that many steps. A missing cell, a set-aside cell, or running out of steps is an
error with a reason, never a shorter list. -/
def walkAddrs (m : Memory) : Nat → Option Addr → Except String (List Addr)
  | _, none => pure []
  | n, some a =>
    match m.find? a with
    | none => throw s!"not reachable: cell {a} is not allocated"
    | some c =>
      if c.status = .setAside then throw s!"not reachable: cell {a} is set aside"
      else
        match n with
        | 0 => throw s!"not reachable: the walk from cell {a} runs past the number of cells (a cycle)"
        | k + 1 => do
          let rest ← walkAddrs m k c.link
          pure (a :: rest)

/-- The addresses met walking from each root along links. -/
def reachable (m : Memory) (roots : List (Option Addr)) : Except String (List Addr) :=
  (roots.mapM (walkAddrs m m.cells.length)).map List.flatten

/-- How many of the roots are `some a`, plus how many live cells of `m` link to `a`. -/
def holders (m : Memory) (roots : List (Option Addr)) (a : Addr) : Nat :=
  (roots.filter (fun r => r == some a)).length
  + (m.cells.filter (fun c => c.status == .live && c.link == some a)).length

/-- The walk from the roots succeeds, every address it gives is an allocated cell's,
and every allocated cell's address is among them. A `Bool` test. -/
def reachesExactly (m : Memory) (roots : List (Option Addr)) : Bool :=
  match reachable m roots with
  | .ok xs => xs.all (fun a => m.cells.any (fun c => c.addr == a))
              && m.cells.all (fun c => xs.contains c.addr)
  | .error _ => false

/-- Promise (d) for a final memory and its roots (the answer's cell, then the outside
holders): every cell is live; no repeated address; the allocated cells are exactly
the reachable ones; every cell's count equals its holders. Decidable: `∀ x ∈ list`,
`Nodup` and a `Bool` test. Says nothing about bindings or intermediate results. -/
def NoLeakAt (m : Memory) (roots : List (Option Addr)) : Prop :=
  (∀ c ∈ m.cells, c.status = .live)
  ∧ (m.cells.map (fun c => c.addr)).Nodup
  ∧ reachesExactly m roots = true
  ∧ (∀ c ∈ m.cells, c.count = holders m roots c.addr)

/-- The roots of the end of a run: the answer's cell (if a non-empty list), then the
outside holders. -/
def answerRoots (raw : RawValue) (s : Start) : List (Option Addr) :=
  (match raw with
   | .list (some a) => [some a]
   | _ => []) ++ s.outside

/-- Promise (d): the run gave an answer, and `NoLeakAt` holds of the final memory
with the answer's cell and the outside holders as roots. -/
def NoLeak (s : Start) (o : Outcome) : Prop :=
  match o.result with
  | .answer raw => NoLeakAt o.memory (answerRoots raw s)
  | .refused _ => False
  | .failedRunning _ => False

/-! ## Decidability, from existing instances (`DecidableEq` for `Except` is above) -/

instance (states : List Snapshot) (snap : Snapshot) (b : Binding) :
    Decidable (NameSteady states snap b) := inferInstanceAs (Decidable (_ = true))

instance (o : Outcome) : Decidable (Finishes o) := inferInstanceAs (Decidable (_ = true))

instance (e : Expr) (s : Start) (o : Outcome) : Decidable (SameAnswer e s o) :=
  inferInstanceAs (Decidable (_ ∧ _))

instance (s : Start) (o : Outcome) : Decidable (OutsideUnchanged s o) :=
  inferInstanceAs (Decidable (∀ snap ∈ o.states, _))

instance (o : Outcome) : Decidable (NamesUnchanged o) :=
  inferInstanceAs (Decidable (∀ snap ∈ o.states, ∀ b ∈ snap.bindings, _))

instance (s : Start) (o : Outcome) : Decidable (NoVisibleChange s o) :=
  inferInstanceAs (Decidable (_ ∧ _))

instance (m : Memory) (roots : List (Option Addr)) : Decidable (NoLeakAt m roots) :=
  inferInstanceAs (Decidable (_ ∧ _ ∧ _ ∧ _))

instance (s : Start) (o : Outcome) : Decidable (NoLeak s o) :=
  match h : o.result with
  | .answer raw => by unfold NoLeak; rw [h]; exact inferInstance
  | .refused _ => by unfold NoLeak; rw [h]; exact instDecidableFalse
  | .failedRunning _ => by unfold NoLeak; rw [h]; exact instDecidableFalse

/-! ## The four universal statements -/

/-- Promise (a), for every program and valid starting memory. -/
def PromiseA : Prop :=
  ∀ (e : Expr) (s : Start), validStart e s = .ok () → Finishes (runCounted .approved e s)

/-- Promise (b), for every program and valid starting memory. -/
def PromiseB : Prop :=
  ∀ (e : Expr) (s : Start), validStart e s = .ok () → SameAnswer e s (runCounted .approved e s)

/-- Promise (c), for every program and valid starting memory. -/
def PromiseC : Prop :=
  ∀ (e : Expr) (s : Start), validStart e s = .ok () → NoVisibleChange s (runCounted .approved e s)

/-- Promise (d), for every program and valid starting memory. -/
def PromiseD : Prop :=
  ∀ (e : Expr) (s : Start), validStart e s = .ok () → NoLeak s (runCounted .approved e s)

end Trial
