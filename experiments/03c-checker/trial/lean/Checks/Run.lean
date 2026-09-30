import Checks.Examples
import Checks.Predictions

/-! All comparisons are ordinary functions, called only by main. Nothing in
this file evaluates an example during compilation. Counts come exclusively
from Outcome.record; snapshot reconstruction only checks timing evidence. -/
namespace Checks
open Trial

structure Item where
  label : String
  expected : String
  actual : String
  passed : Bool

def valueText : PlainValue → String
  | .num n => toString n
  | .bool b => if b then "true" else "false"
  | .list xs => "[" ++ String.intercalate ", " (xs.map toString) ++ "]"

def answerText : Except String PlainValue → String
  | .ok v => valueText v
  | .error why => why

def totalsText (t : Totals) : String :=
  s!"allocations {t.allocations}, reuses {t.reuses}, frees {t.frees}"

def rawText : RawValue → String
  | .num n => toString n
  | .bool b => if b then "true" else "false"
  | .list none => "empty list"
  | .list (some a) => s!"list starting at c{a}"

def pendingText (pending : List RawValue) : String :=
  if pending.isEmpty then "no intermediate holders"
  else String.intercalate ", " (pending.map rawText)

def statusText : Status → String
  | .live => "live"
  | .setAside => "set aside"

def actualAnswer (o : Outcome) : Except String PlainValue :=
  match o.result with
  | .answer raw =>
    match readBack o.memory raw with
    | .ok v => .ok v
    | .error why => .error s!"Unreadable answer: {why}"
  | .refused why => .error s!"Refused before running: {why}"
  | .failedRunning why => .error s!"Failed while running: {why}"

def equalAnswer (a : Except String PlainValue) (b : PlainValue) : Bool :=
  match a with | .ok v => v == b | .error _ => false

def answersAgree (a b : Except String PlainValue) : Bool :=
  match a, b with | .ok x, .ok y => x == y | _, _ => false

def plainAnswer (r : Run) : Except String PlainValue := do
  let inputs ← r.start.inputs.mapM fun (name, raw) => do
    match readBack r.start.toMemory raw with
    | .ok v => pure (name, v)
    | .error why => throw s!"Unreadable plain input {name}: {why}"
  match runPlain r.program inputs with
  | .ok v => pure v
  | .error why => throw s!"Plain meaning failed: {why}"

def countRecord (record : List MemEvent) : Totals :=
  record.foldl (fun t ev => match ev with
    | .created _ => { t with allocations := t.allocations + 1 }
    | .written _ => { t with reuses := t.reuses + 1 }
    | .released _ => { t with frees := t.frees + 1 }) ⟨0, 0, 0⟩

def logAsRecord (log : List LogEvent) : List MemEvent :=
  log.map fun ev => match ev with
    | .alloc a => .created a
    | .reuse a => .written a
    | .free a => .released a

def eventText : MemEvent → String
  | .created a => s!"allocated c{a}"
  | .written a => s!"reused c{a}"
  | .released a => s!"freed c{a}"

def recordText (record : List MemEvent) : String :=
  "[" ++ String.intercalate ", " (record.map eventText) ++ "]"

def checkExcept (label : String) (v : Except String α) : Item :=
  match v with
  | .ok _ => ⟨label, "yes", "yes", true⟩
  | .error why => ⟨label, "yes", why, false⟩

def readable (o : Outcome) : Bool :=
  match actualAnswer o with | .ok _ => true | .error _ => false

def pointer : RawValue → Option Addr
  | .list l => l
  | _ => none

def memoryAt (s : Snapshot) : Memory := { cells := s.memory }

def holderCount (cells : List Cell) (roots : List (Option Addr)) (a : Addr) : Nat :=
  (roots.filter (fun r => r == some a)).length +
  (cells.filter (fun c => c.status == .live && c.link == some a)).length

def snapshotHolders (s : Snapshot) (a : Addr) : Nat :=
  holderCount s.memory
    (s.outside ++ s.pending.map pointer ++
      (s.bindings.filter (fun b => b.status == .holding)).map (fun b => pointer b.value)) a

/-- Independent bounded walk: dangling links, set-aside cells and cycles are
errors, never a silently truncated reachable set. -/
def walk (m : Memory) : Nat → Option Addr → Except String (List Addr)
  | _, none => pure []
  | 0, some a => throw s!"Cycle or overlong chain from c{a}"
  | n + 1, some a => do
    match m.find? a with
    | none => throw s!"Dangling reference to c{a}"
    | some c =>
      if c.status != .live then throw s!"Reachable c{a} is set aside"
      else pure (a :: (← walk m n c.link))

def uniqueAddresses (cells : List Cell) : Bool :=
  (cells.map (fun c => c.addr)).eraseDups.length == cells.length

def finalReachable (start : Start) (o : Outcome) : Except String Unit := do
  match o.result with
  | .answer raw =>
    let _ ← actualAnswer o
    if !uniqueAddresses o.memory.cells then throw "Duplicate allocated addresses"
    let chains ← (pointer raw :: start.outside).mapM (walk o.memory o.memory.cells.length)
    let reached := chains.flatten.eraseDups
    let allocated := o.memory.cells.map (fun c => c.addr)
    if allocated.length == reached.length && allocated.all reached.contains then pure ()
    else throw s!"Allocated {allocated}; reachable from answer and outside holders {reached}"
  | _ => throw s!"No readable completed answer: {answerText (actualAnswer o)}"

/-- At end the answer's holder is still represented by pending. Count it there
exactly once, alongside retained bindings, outside holders and live cell links;
the recorded branchValue creates no holder. -/
def finalCounts (start : Start) (o : Outcome) : Except String Unit := do
  match o.result with
  | .answer raw =>
    let _ ← actualAnswer o
    if !uniqueAddresses o.memory.cells then throw "Duplicate allocated addresses"
    let final ← match o.states.getLast? with
      | some s =>
        if s.kind == .end then pure s else throw "Last snapshot is not the end of the run"
      | none => throw "No final snapshot"
    if final.memory != o.memory.cells then throw "Final snapshot and final memory disagree"
    if final.outside != start.outside then throw "Final snapshot's outside holders changed"
    let answerHolder := match pointer raw with
      | some a => [RawValue.list (some a)]
      | none => []
    if final.pending != answerHolder then
      throw s!"Final intermediate holders: expected only {pendingText answerHolder}; actual {pendingText final.pending}"
    let heldNames := (final.bindings.filter (fun b => b.status == .holding)).map (fun b => pointer b.value)
    -- A retained name pointing to a freed cell must fail even when no allocated
    -- cell remains whose count could reveal that dangling holder.
    for root in heldNames do
      let _ ← walk o.memory o.memory.cells.length root
    for c in o.memory.cells do
      let actual := snapshotHolders final c.addr
      if c.status != .live || c.count != actual then
        throw s!"c{c.addr}: stored count {c.count}, actual holders {actual}, status {statusText c.status}"
    pure ()
  | _ => throw s!"No readable completed answer: {answerText (actualAnswer o)}"

def outsideUnchanged (start : Start) (o : Outcome) : Except String Unit := do
  if o.states.isEmpty then throw "No snapshots were produced"
  let initial ← start.outside.mapM (readBack start.toMemory ∘ RawValue.list)
  for (s, index) in o.states.zipIdx do
    if s.outside != start.outside then throw s!"Snapshot {index}: outside holders changed"
    for (root, expected) in start.outside.zip initial do
      match readBack (memoryAt s) (.list root) with
      | .error why => throw s!"Snapshot {index}: outside list unreadable: {why}"
      | .ok actual =>
        if actual != expected then
          throw s!"Snapshot {index}: expected {valueText expected}, read {valueText actual}"
  pure ()

/-- At the exposed primitive-operation snapshots, identify the memory operation
from the cell transition, without consulting the rule's log. This establishes
which prefix of memory's own record belongs to a timing snapshot. -/
def snapshotRecord (initial : List Cell) (states : List Snapshot) :
    Except String (List MemEvent) := do
  let mut previous := initial
  let mut events := []
  for s in states do
    let removed := previous.filter (fun c => !s.memory.any (fun d => d.addr == c.addr))
    let added := s.memory.filter (fun c => !previous.any (fun d => d.addr == c.addr))
    let written := s.memory.filter fun c => c.status == .live &&
      previous.any (fun d => d.addr == c.addr && d.status == .setAside)
    match s.kind with
    | .cellFreed =>
      match removed, added, written with
      | [c], [], [] => events := events ++ [.released c.addr]
      | _, _, _ => throw "Free snapshot does not show exactly one released cell"
    | .newCellBuilt =>
      match removed, added, written with
      | [], [c], [] => events := events ++ [.created c.addr]
      | [], [], [c] => events := events ++ [.written c.addr]
      | _, _, _ => throw "Build snapshot does not show exactly one creation or in-place write"
    | _ =>
      if !removed.isEmpty || !added.isEmpty || !written.isEmpty then
        throw "A primitive memory operation has no corresponding operation snapshot"
    previous := s.memory
  pure events

def ownerOf (states : List Snapshot) (a : Addr) : Except String Nat := do
  match states.find? (fun s => s.kind == .matchStep4Done && s.setAside.any (fun p => p.2 == a)) with
  | none => throw s!"No match step 4 identifies the branch owning c{a}"
  | some s =>
    match s.setAside.filter (fun p => p.2 == a) with
    | [(bid, _)] => pure bid
    | _ => throw s!"Ambiguous branch ownership of c{a}"

def claimText : CellClaim → String
  | .aside owner => s!"set aside, zero holders, detached, owned by the match on c{owner}"
  | .absent => "absent from memory and the set-aside list"
  | .live => "live and allocated, not set aside"

def observedCell (s : Snapshot) (a : Addr) : String :=
  match (memoryAt s).find? a with
  | none => s!"absent; set-aside entries {s.setAside.filter (fun p => p.2 == a)}"
  | some c => s!"{statusText c.status}; stored holders {c.count}; actual holders {snapshotHolders s a}; " ++
    s!"link {rawText (.list c.link)}; set-aside entries {s.setAside.filter (fun p => p.2 == a)}"

def checkCell (states : List Snapshot) (s : Snapshot) (c : TimingCell) : Bool :=
  match c.claim, (memoryAt s).find? c.addr with
  | .absent, none => !s.setAside.any (fun p => p.2 == c.addr)
  | .live, some cell => cell.status == .live && !s.setAside.any (fun p => p.2 == c.addr)
  | .aside owner, some cell =>
    match ownerOf states owner with
    | .error _ => false
    | .ok bid => cell.status == .setAside && cell.count == 0 && cell.link == none &&
      snapshotHolders s c.addr == 0 && s.setAside.filter (fun p => p.2 == c.addr) == [(bid, c.addr)]
  | _, _ => false

def releases (record : List MemEvent) : List Addr :=
  record.filterMap fun ev => match ev with | .released a => some a | _ => none

def sameAddresses (xs ys : List Addr) : Bool :=
  xs.length == ys.length && xs.all ys.contains && ys.all xs.contains

def branchValueItem (moment : TimingMoment) (s : Snapshot) : Item :=
  let label := s!"Timing: {moment.label}; recorded branch value"
  match moment.branchValue, s.branchValue with
  | none, none => ⟨label, "no finishing branch value", "no finishing branch value", true⟩
  | some expected, some raw =>
    let read := readBack (memoryAt s) raw
    ⟨label, valueText expected, answerText read, equalAnswer read expected⟩
  | some expected, none => ⟨label, valueText expected, "Missing branch value", false⟩
  | none, some raw => ⟨label, "no finishing branch value", answerText (readBack (memoryAt s) raw), false⟩

def timingOrder (o : Outcome) (p : TimingPrediction) : Except String Unit := do
  let indices ← p.moments.mapM fun moment => do
    let candidates := (o.states.zipIdx).filter (fun entry => entry.1.kind == moment.kind)
    match candidates[moment.occurrence]? with
    | none => throw s!"Missing snapshot: {moment.label}"
    | some (_, index) => pure index
  for (before, after) in indices.zip (indices.drop 1) do
    if before >= after then throw s!"Timing moments are out of order: snapshot indices {indices}"
  pure ()

/-- Run 11 has one match and no if. Identify its rest binding by the unique id
at match step 4, then inspect that same binding at the sole branch-start state. -/
def restGivenUpBeforeBranch (o : Outcome) : Except String Unit := do
  match o.states.filter (fun s => s.kind == .matchStep4Done),
        o.states.filter (fun s => s.kind == .branchStarts) with
  | [takenApart], [branchStart] =>
    match takenApart.bindings.filter (fun b => b.name == "t") with
    | [rest] =>
      if rest.value != .list (some 2) || rest.status != .holding then
        throw "Match step 4 does not identify t holding the detached tail c2"
      match branchStart.bindings.filter (fun b => b.id == rest.id) with
      | [binding] =>
        if binding.value == rest.value && binding.status == .givenUp then pure ()
        else throw s!"At branch start, t has status {repr binding.status} and value {repr binding.value}"
      | _ => throw "Rest binding is missing or duplicated at branch start"
    | _ => throw "Match step 4 has no unique rest binding"
  | _, _ => throw "Expected one match step 4 and one branch-start snapshot"

def timingItems (r : Run) (o : Outcome) (p : TimingPrediction) : List Item := Id.run do
  let mut items := []
  let kinds := [StepKind.branchValueWorkedOut, StepKind.branchValueHandedOn] ++
    (if p.moments.any (fun m => m.kind == .branchStarts) then [StepKind.branchStarts] else [])
  for kind in kinds do
    let found := (o.states.filter (fun s => s.kind == kind)).length
    let expected := if kind == .branchStarts then 1 else p.boundaries
    let label := if kind == .branchStarts then "branch about to run"
      else if kind == .branchValueWorkedOut then "branch value worked out" else "branch value handed on"
    items := items ++ [⟨s!"Timing boundary count: {label}", toString expected,
      toString found, found == expected⟩]
  items := items ++ [checkExcept "Timing: named moments occur in the frozen order" (timingOrder o p)]
  let fullRecord := snapshotRecord r.start.toMemory.cells o.states
  items := items ++ [match fullRecord with
    | .error why => ⟨"Timing snapshots agree with memory's record", recordText o.record, why, false⟩
    | .ok reconstructed => ⟨"Timing snapshots agree with memory's record", recordText o.record,
        recordText reconstructed, reconstructed == o.record⟩]
  for moment in p.moments do
    let candidates := (o.states.zipIdx).filter (fun entry => entry.1.kind == moment.kind)
    match candidates[moment.occurrence]? with
    | none =>
      for c in moment.cells do
        items := items ++ [⟨s!"Timing: {moment.label}; c{c.addr}", claimText c.claim, "Missing snapshot", false⟩]
      items := items ++ [⟨s!"Timing: {moment.label}; result holder", toString moment.resultHolder, "Missing snapshot", false⟩,
        ⟨s!"Timing: {moment.label}; recorded branch value",
          match moment.branchValue with | some v => valueText v | none => "no finishing branch value",
          "Missing snapshot", false⟩,
        ⟨s!"Timing: {moment.label}; releases already recorded", toString moment.released, "Missing snapshot", false⟩]
    | some (s, index) =>
      for c in moment.cells do
        items := items ++ [⟨s!"Timing: {moment.label}; c{c.addr}", claimText c.claim,
          observedCell s c.addr, checkCell o.states s c⟩]
      let expectedPending := match moment.resultHolder with
        | some a => [RawValue.list (some a)]
        | none => []
      items := items ++ [⟨s!"Timing: {moment.label}; result holder",
        pendingText expectedPending, pendingText s.pending, s.pending == expectedPending &&
          (match moment.branchValue, s.branchValue with
            | none, none => true
            | some _, some raw => pointer raw == moment.resultHolder
            | _, _ => false)⟩,
        branchValueItem moment s]
      let recordPrefix := snapshotRecord r.start.toMemory.cells (o.states.take (index + 1))
      items := items ++ [match recordPrefix with
        | .error why => ⟨s!"Timing: {moment.label}; releases already recorded", toString moment.released, why, false⟩
        | .ok reconstructed =>
          let actualPrefix := o.record.take reconstructed.length
          ⟨s!"Timing: {moment.label}; releases already recorded", toString moment.released,
            toString (releases actualPrefix), actualPrefix == reconstructed &&
              sameAddresses (releases actualPrefix) moment.released⟩]
  if r.number == 9 then
    let callerHolder := do
      match o.result with
      | .answer (.list (some 2)) =>
        match o.states.filter (fun s => s.kind == .end) with
        | [s] =>
          if s.pending == [.list (some 2)] &&
              !s.bindings.any (fun b => b.status == .holding) then pure ()
          else throw "The final snapshot does not show c2's holder handed out without a name retaining it"
        | _ => throw "No unique end snapshot"
      | _ => throw s!"The caller did not receive c2: {answerText (actualAnswer o)}"
    items := items ++ [checkExcept "Timing: caller receives the branch result's holder on c2" callerHolder]
  if r.number == 10 then
    let ownership := do
      let outer ← ownerOf o.states 1
      let inner ← ownerOf o.states 2
      if outer == inner then throw "Inner and outer cells have the same owning branch" else pure ()
    items := items ++ [checkExcept "Timing: inner and outer set-aside cells belong to different branches" ownership]
  if r.number == 11 then
    items := items ++ [checkExcept "Timing: t has given up its holder before the branch runs" (restGivenUpBeforeBranch o)]
    let neverAside := o.states.all (fun s => s.setAside.all (fun entry => entry.2 != 2 && entry.2 != 3) &&
      s.memory.all (fun c => (c.addr != 2 && c.addr != 3) || c.status != .setAside))
    items := items ++ [⟨"Timing: c2 and c3 were never set aside", "yes", toString neverAside, neverAside⟩]
  return items

def runItems (r : Run) (p : Prediction) (o : Outcome) : List Item := Id.run do
  let plain := plainAnswer r
  let answer := actualAnswer o
  let totals := countRecord o.record
  let mut items :=
    [checkExcept "Program well-formed" (wellFormed (r.start.inputs.map (fun entry => (entry.1, entry.2.kind))) r.program),
     checkExcept "Starting memory valid" (validStart r.program r.start),
     ⟨"Counted run finishes with a readable answer", "yes", answerText answer, readable o⟩,
     checkExcept "Plain meaning finishes with an answer" plain,
     ⟨"Predicted and actual answer", valueText p.answer, answerText answer, equalAnswer answer p.answer⟩,
     ⟨"Plain meaning's answer equals counted answer", answerText plain, answerText answer, answersAgree plain answer⟩]
  for (label, expected, actual) in
      [("Allocations", p.totals.allocations, totals.allocations),
       ("Reuses", p.totals.reuses, totals.reuses), ("Frees", p.totals.frees, totals.frees)] do
    items := items ++ [⟨label ++ " (memory's record)", toString expected,
      toString actual ++ (if readable o then "" else " (run did not complete with a readable answer)"),
      readable o && expected == actual⟩]
  items := items ++
    [⟨"Rule's log agrees with memory's record, including order and addresses",
      recordText o.record, recordText (logAsRecord o.log), logAsRecord o.log == o.record⟩,
     checkExcept "Promise (d): allocated cells exactly reachable from answer and outside holders" (finalReachable r.start o),
     checkExcept "Promise (d): every final holder count is correct" (finalCounts r.start o),
     checkExcept "Promise (c): outside lists unchanged in every snapshot" (outsideUnchanged r.start o)]
  for timing in timingPredictions.filter (fun t => t.number == r.number) do
    items := items ++ timingItems r o timing
  return items

def controlItems (r : Run) (p : Prediction) : List Item :=
  let o := runCounted .misreportsReuse r.program r.start
  let answer := actualAnswer o
  let plain := plainAnswer r
  let totals := countRecord o.record
  let finished := match o.result with | .answer _ => true | _ => false
  let countsRejected := totals != p.totals
  let passed := finished && readable o && equalAnswer answer p.answer && answersAgree answer plain && countsRejected
  [⟨"Control finishes with an answer (not refused or failed while running)", "yes", answerText answer, finished⟩,
   ⟨"Control answer reads back", "yes", answerText answer, readable o⟩,
   ⟨"Control answer equals prediction", valueText p.answer, answerText answer, equalAnswer answer p.answer⟩,
   ⟨"Control answer equals plain meaning", answerText plain, answerText answer, answersAgree answer plain⟩,
   ⟨"Control totals differ from prediction", "different from " ++ totalsText p.totals, totalsText totals, countsRejected⟩,
   ⟨"Control log versus memory record (known misreport expected)", recordText o.record,
     recordText (logAsRecord o.log), logAsRecord o.log != o.record⟩,
   ⟨"Control rejected on counts with correct readable answer", "yes", toString passed, passed⟩]

def printItems (items : List Item) : IO Nat := do
  let mut mismatches := 0
  for item in items do
    IO.println s!"  {if item.passed then "MATCH" else "MISMATCH"} — {item.label}"
    IO.println s!"    Expected: {item.expected}; actual: {item.actual}"
    if !item.passed then mismatches := mismatches + 1
  return mismatches

def report : IO Unit := do
  IO.println "Trial predictions: all 28 runs. Counts below come from memory's own record."
  IO.println "Promise checks are separate from prediction comparisons. A mismatch is one failed report item."
  let mut mismatches := 0
  for r in runs do
    IO.println s!"\nRun {r.number}"
    match predictions.filter (fun p => p.number == r.number) with
    | [p] =>
      let o := runCounted .approved r.program r.start
      mismatches := mismatches + (← printItems (runItems r p o))
    | _ =>
      mismatches := mismatches + (← printItems [⟨"Exactly one prediction for this run", "yes", "Missing or duplicate prediction", false⟩])
  IO.println "\nMisreport control — run 2 (separate from the 28 approved-rule runs)"
  let controlMismatches ← match runs.find? (fun r => r.number == 2), predictions.find? (fun p => p.number == 2) with
    | some r, some p => printItems (controlItems r p)
    | _, _ => printItems [⟨"Control data present", "run 2 and prediction 2", "Missing", false⟩]
  IO.println s!"\nApproved-rule mismatch count: {mismatches}"
  IO.println s!"Control mismatch count: {controlMismatches}"
  IO.println s!"Total mismatch count: {mismatches + controlMismatches}"

end Checks

def main : IO Unit := Checks.report
