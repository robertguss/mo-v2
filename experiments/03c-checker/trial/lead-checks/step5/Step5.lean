import Promises
import Checks.Examples

/-!
The lead's quick checks of `Promises.lean` (step 5). Not acceptance criteria.

1. On all twenty-eight example runs, under the approved rule, the start is valid
   and each of the four per-run promises evaluates to true.
2. On hand-made changes to real outcomes, the matching promise evaluates to false.
   Any failed check is an error.
-/

open Trial Checks

def outcomeOf (r : Run) : Outcome := runCounted .approved r.program r.start

def allHold (r : Run) : Bool :=
  let o := outcomeOf r
  (match validStart r.program r.start with | .ok () => true | .error _ => false)
  && decide (Finishes o) && decide (SameAnswer r.program r.start o)
  && decide (NoVisibleChange r.start o) && decide (NoLeak r.start o)
  && !o.states.isEmpty

-- 1. Every example run satisfies all four promises.
#guard runs.length == 28
#guard runs.all allHold

/-! 2. Deliberate changes that each promise must catch. -/

instance : Inhabited Run := ⟨⟨0, .nil, ⟨[], [], []⟩⟩⟩

def run5 : Run := (runs.find? (fun r => r.number == 5)).get!   -- p1 on mKept: an outside holder
def o5 : Outcome := outcomeOf run5
def run2 : Run := (runs.find? (fun r => r.number == 2)).get!   -- p1 on mOne
def o2 : Outcome := outcomeOf run2

#guard run5.number == 5 && run2.number == 2
#guard decide (NoVisibleChange run5.start o5)

/-- Change the item of cell `a` in one snapshot (index `i`). -/
def bumpCellAt (o : Outcome) (i : Nat) (a : Addr) : Outcome :=
  { o with states := o.states.mapIdx (fun j s =>
      if j == i then { s with memory := s.memory.map (fun c => if c.addr == a then { c with item := c.item + 100 } else c) }
      else s) }

-- (c1): the outside holder's first cell changed in the last snapshot.
#guard run5.start.outside == [some 1]
#guard !decide (OutsideUnchanged run5.start (bumpCellAt o5 (o5.states.length - 1) 1))
-- (c1): a snapshot whose outside holders differ.
#guard !decide (OutsideUnchanged run5.start
  { o5 with states := o5.states.map (fun s => { s with outside := [] }) })

/-- A snapshot index where a binding holds a list and is not in its first holding
snapshot, with that list's first cell. -/
def laterHeld (o : Outcome) : Option (Nat × Addr) := Id.run do
  let mut seen : List Nat := []
  let mut found := none
  for (s, i) in o.states.zipIdx do
    for b in s.bindings do
      if b.status == .holding then
        match b.value with
        | .list (some a) =>
          if seen.contains b.id then
            if found.isNone then found := some (i, a)
          else seen := b.id :: seen
        | _ => pure ()
  return found

/-- The first example run with such a snapshot. -/
def runC2 : Run := (runs.find? (fun r => (laterHeld (outcomeOf r)).isSome)).get!
def oC2 : Outcome := outcomeOf runC2
#eval s!"(c2) mutation uses run {runC2.number} at {laterHeld oC2}"

-- (c2): a name's list changed in a later snapshot where it still holds.
#guard (laterHeld oC2).isSome
#guard decide (NamesUnchanged oC2)
#guard match laterHeld oC2 with
  | some (i, a) => !decide (NamesUnchanged (bumpCellAt oC2 i a))
  | none => false
-- (c2): the name's cell missing in a later holding snapshot (read-back fails).
#guard match laterHeld oC2 with
  | some (i, a) => !decide (NamesUnchanged
      { oC2 with states := oC2.states.mapIdx (fun j s =>
          if j == i then { s with memory := s.memory.filter (fun c => c.addr != a) } else s) })
  | none => false
-- (c2): the baseline itself unreadable (first holding snapshot loses the cell): the
-- promise must not hold even though both read-backs would be equal errors.
def firstHeld (o : Outcome) : Option (Nat × Addr) := Id.run do
  for (s, i) in o.states.zipIdx do
    for b in s.bindings do
      if b.status == .holding then
        match b.value with
        | .list (some a) => return some (i, a)
        | _ => pure ()
  return none
#guard match firstHeld oC2 with
  | some (_, a) => !decide (NamesUnchanged
      { oC2 with states := oC2.states.map (fun s => { s with memory := s.memory.filter (fun c => c.addr != a) }) })
  | none => false

-- (a) and (b): a run that failed while running, and one whose answer is unreadable.
def failed (o : Outcome) : Outcome := { o with result := .failedRunning "made up" }
#guard !decide (Finishes (failed o2))
#guard !decide (SameAnswer run2.program run2.start (failed o2))
#guard !decide (NoLeak run2.start (failed o2))
#guard !decide (NoLeak run2.start { o2 with result := .refused "made up" })
def unreadable (o : Outcome) : Outcome := { o with memory := { o.memory with cells := [] } }
#guard !decide (Finishes (unreadable o2))
#guard !decide (SameAnswer run2.program run2.start (unreadable o2))
def refusedO (o : Outcome) : Outcome := { o with result := .refused "made up" }
#guard !decide (Finishes (refusedO o2))
#guard !decide (SameAnswer run2.program run2.start (refusedO o2))
-- (b): a readable but different answer (the answer's item changed in the final memory).
def changedAnswer (o : Outcome) : Outcome :=
  { o with memory := { o.memory with cells := o.memory.cells.map (fun c => { c with item := c.item + 1 }) } }
#guard decide (Finishes (changedAnswer o2))
#guard !decide (SameAnswer run2.program run2.start (changedAnswer o2))

-- (d): an extra unreachable cell; a count off by one; a cell left set aside; two cells at one address.
#guard decide (NoLeak run2.start o2)
#guard !o2.memory.cells.isEmpty
def withCells (o : Outcome) (f : List Cell → List Cell) : Outcome :=
  { o with memory := { o.memory with cells := f o.memory.cells } }
#guard !decide (NoLeak run2.start (withCells o2 (· ++ [⟨999, 0, none, 0, .live⟩])))
#guard !decide (NoLeak run2.start (withCells o2 (· ++ [⟨999, 0, none, 1, .live⟩])))
#guard !decide (NoLeak run2.start (withCells o2 (·.map (fun c => { c with count := c.count + 1 }))))
#guard !decide (NoLeak run2.start (withCells o2 (· ++ [⟨999, 0, none, 0, .setAside⟩])))
#guard !decide (NoLeak run2.start (withCells o2 (fun cs => cs ++ cs.take 1)))
-- (d) on a run with an outside holder: dropping the outside holder's cells leaves them dangling.
#guard decide (NoLeak run5.start o5)
#guard !decide (NoLeak run5.start (withCells o5 (·.filter (fun c => c.addr != 1))))
