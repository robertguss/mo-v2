import Full.Lifecycle
import Full.Inspect
import Lean

open Lean (Json toJson fromJson?)
open Full
namespace Export

def getAt (j : Json) (i : Nat) : Except String Json := do
  let a ← j.getArr?
  match a[i]? with
  | some v => pure v
  | none => throw s!"missing index {i}"

def kind (j : Json) : Except String Kind := do
  match ← j.getStr? with
  | "I" => pure .number | "L" => pure .list | "B" => pure .bool
  | _ => throw "unknown kind"

/-- Adapter depth bound only; the logical language and machines are unbounded. -/
def expr : Nat → Json → Except String Expr
  | 0, _ => throw "adapter syntax-depth bound"
  | fuel+1, j => do
    match j with
    | .bool b => pure (.bool b)
    | .num _ => pure (.num (← fromJson? j))
    | .str x => pure (.var x)
    | .arr a =>
      if a.isEmpty then pure .nil else
        let op ← (← getAt j 0).getStr?
        let sub : Nat → Except String Expr := fun i => do expr fuel (← getAt j i)
        match op with
        | "add" => pure (.bin .add (← sub 1) (← sub 2))
        | "sub" => pure (.bin .sub (← sub 1) (← sub 2))
        | "eq" => pure (.bin .eq (← sub 1) (← sub 2))
        | "lt" => pure (.bin .lt (← sub 1) (← sub 2))
        | "le" => pure (.bin .le (← sub 1) (← sub 2))
        | "cons" => pure (.bin .cons (← sub 1) (← sub 2))
        | "let" => pure (.letE (← (← getAt j 1).getStr?) (← sub 2) (← sub 3))
        | "if" => pure (.ifE (← sub 1) (← sub 2) (← sub 3))
        | "match" => pure (.matchE (← sub 1) (← sub 2)
            (← (← getAt j 3).getStr?) (← (← getAt j 4).getStr?) (← sub 5))
        | "call" => pure (.call (← (← getAt j 1).getStr?) (← (a.toList.drop 2).mapM (expr fuel)))
        | _ => throw s!"unknown expression {op}"
    | _ => throw "invalid expression JSON"

def fn (j : Json) : Except String Function := do
  let params ← (← (← getAt j 1).getArr?).toList.mapM fun param => do
    pure (← (← getAt param 0).getStr?, ← kind (← getAt param 1))
  pure ⟨← (← getAt j 0).getStr?, params, ← kind (← getAt j 2),
    ← expr 10000 (← getAt j 3), ← (← getAt j 4).getBool?⟩

def start (j : Json) : Except String Trial.Start := do
  let cells ← (← (← j.getObjVal? "cells").getArr?).toList.mapM fun c => do
    pure (⟨← fromJson? (← getAt c 0), ← fromJson? (← getAt c 1),
      ← fromJson? (← getAt c 2), ← fromJson? (← getAt c 3)⟩ : Trial.StartCell)
  let inputs ← (← (← j.getObjVal? "inputs").getArr?).toList.mapM fun i => do
    let name ← (← getAt i 0).getStr?
    let k ← kind (← getAt i 1)
    let raw : Raw ← match k with
      | .number => pure (.num (← fromJson? (← getAt i 2)))
      | .list => pure (.list (← fromJson? (← getAt i 2)))
      | .bool => pure (.bool (← fromJson? (← getAt i 2)))
    pure (name,raw)
  pure ⟨cells, inputs, ← fromJson? (← j.getObjVal? "outside")⟩

def value : Value → Json
  | .num n => toJson n | .bool b => toJson b | .list xs => toJson xs

def raw : Raw → Json
  | .num n => Json.arr #[toJson "I",toJson n]
  | .bool b => Json.arr #[toJson "B",toJson b]
  | .list p => Json.arr #[toJson "L",toJson p]

def cells (s : Counted.State) : Json := toJson (s.mem.cells.map fun c =>
  Json.arr #[toJson c.addr,toJson c.item,toJson c.link,toJson c.count,
    toJson (if c.status == .live then "live" else "aside")])

def events (s : Counted.State) : Json := toJson (s.events.map fun e =>
  match e with
  | .create a h t => Json.arr #[toJson "C",toJson a,toJson h,toJson t]
  | .write a h t => Json.arr #[toJson "W",toJson a,toJson h,toJson t]
  | .free a => Json.arr #[toJson "F",toJson a]
  | .enter f => Json.arr #[toJson "E",toJson f.name,toJson f.id,toJson f.parent,toJson (f.args.map fun (v : Counted.Slot) => raw v.raw),toJson f.site]
  | .returning i v => Json.arr #[toJson "R",toJson i,raw v.raw])

def holder (role : String) (id : Nat) (r : Raw) (v : Value) : Json :=
  Json.mkObj [("role",toJson role),("id",toJson id),("raw",raw r),("value",value v)]

def holders (initial : Trial.Start) (s : Counted.State) : Json := toJson (
  (s.bindings.filter (fun b => b.record.status == .holding)).map (fun b => holder "binding" b.record.id b.record.value b.value) ++
  s.slots.zipIdx.filterMap (fun (v,i) => if (Inspect.link v.raw).isSome then
    some (holder (if s.answer.isSome then "answer" else if i == 0 &&
      (match s.tasks.head? with | some .givePending => true | _ => false) then "cleanup" else "operand")
      (s.slots.length-1-i) v.raw v.value) else none) ++
  s.mem.cells.filterMap (fun c => if c.status == .live && c.link.isSome then
    (s.edges.find? (fun e => e.1 == c.addr)).map (fun (_,v) => holder "edge" c.addr (.list c.link) v) else none) ++
  initial.outside.zipIdx.filterMap (fun (a,i) => if a.isSome then
    match Trial.readBack initial.toMemory (.list a) with
    | .ok v => some (holder "outside" i (.list a) v) | _ => none else none))

def state (s : Counted.State) (initial : Trial.Start) (complete : Bool := true)
    (extra : List (String × Json) := []) : Json := Json.mkObj ([
  ("steps",toJson s.steps), ("cells",cells s), ("events",events s),
  ("status",toJson (if s.answer.isSome then "finished" else "suspended")),
  ("raw",s.answer.map (fun v => raw v.raw) |>.getD Json.null),
  ("rank",toJson (Control.rank s)),
  ("consContext",match s.tasks.head? with
    | some (.primitive .cons ctx) => Json.mkObj [("invocation",toJson ctx.invocation),
        ("branches",toJson ctx.branches),("site",toJson ctx.site)]
    | _ => Json.null),
  ("outside",toJson s.outside),
  ("bindings",toJson (s.bindings.map fun b => Json.arr #[toJson b.record.id,
    toJson b.record.name,raw b.record.value,toJson (reprStr b.record.status),value b.value,toJson b.invocation,toJson b.origin])),
  ("entered",toJson s.entered),
  ("visibleBindings",toJson ((Counted.visible s).map fun b => b.id)),
  ("slots",toJson (s.slots.map fun v => Json.arr #[raw v.raw,value v.value])),
  ("holders",holders initial s),
  ("requiredBindings",toJson (s.bindings.filterMap fun b =>
    if s.tasks.any (Counted.taskUses b.record.id) then some (Json.arr #[toJson b.record.id,value b.value]) else none)),
  ("decodedPlain",toJson (reprStr (Control.decode s))),
  ("release",toJson s.releaseChain),
  ("memoryOperations",toJson (s.mem.record.map fun e => match e with
    | .created a => Json.arr #[toJson "C",toJson a]
    | .written a => Json.arr #[toJson "W",toJson a]
    | .released a => Json.arr #[toJson "F",toJson a])),
  ("frames",toJson (s.frames.map fun f => Json.arr #[toJson f.id,toJson f.name,toJson f.parent])),
  ("reservations",toJson (s.reservations.map fun r => Json.arr #[toJson r.invocation,toJson r.branch,toJson r.addr])),
  ("actions",toJson (s.history.map fun a => a.name)),
  ("tasks",toJson (reprStr s.tasks))] ++ (if complete then [("completeState",toJson (reprStr s))] else []) ++ extra)

def lifecycle (s : Lifecycle.State) (initial : Trial.Start) : Json := Json.mkObj [
  ("execution",state s.execution initial),
  ("requests",toJson (s.requests.map fun r => Json.arr #[toJson (reprStr r.domain),toJson r.site])),
  ("failure",match s.failure with
    | none => Json.null
    | some f => Json.mkObj [("domain",toJson (reprStr f.request.domain)),("site",toJson f.request.site),
        ("ordinal",toJson f.ordinal),("abort",toJson f.abort)]),
  ("destroyed",toJson s.destroyed),("cleanup",toJson s.cleanup),("completeState",toJson (reprStr s))]

def trace (p : Program) (initial : Trial.Start) (allow : Lifecycle.Policy) :
    Nat → Lifecycle.State → Plain.State → Nat → Except String (List Json)
  | 0, _, _, _ => pure []
  | n+1, s, plain, plainSteps => do
    if s.failure.isSome || s.execution.answer.isSome then pure [] else
      let decoded ← Control.decode s.execution
      if reprStr decoded != reprStr plain then throw "independent plain prefix mismatch"
      let t ← Lifecycle.step p allow s
      if t.failure.isSome && reprStr t.execution != reprStr s.execution then
        throw "denial changed committed state"
      let decodedAfter ← Control.decode t.execution
      let moved := reprStr decodedAfter != reprStr plain
      let plainAfter := if moved then Plain.step p plain else plain
      if reprStr decodedAfter != reprStr plainAfter then throw "independent plain step mismatch"
      let count := plainSteps + if moved then 1 else 0
      let internal ← if t.failure.isSome then pure Json.null else do
        let change ← Counted.transition p s.execution
        pure (state change.state initial)
      let restored := { t.execution with
        steps := s.execution.steps,
        history := s.execution.history, landmarks := s.execution.landmarks }
      pure (state t.execution initial false [
        ("independentPlain",toJson (reprStr plainAfter)),("plainPrefixSteps",toJson count),
        ("plainBefore",toJson (reprStr plain)),("plainNext",toJson (reprStr (Plain.step p plain))),
        ("decodedState",toJson (reprStr decodedAfter)),
        ("correspondence",toJson (if t.failure.isSome then "denial" else if moved then "step" else "stutter")),
        ("rankBefore",toJson (Control.rank s.execution)),("internal",internal),
        ("commitMetadataRestored",toJson (reprStr restored)),
        ("denialBefore",if t.failure.isSome then lifecycle s initial else Json.null),
        ("denialAfter",if t.failure.isSome then lifecycle t initial else Json.null)] ::
        (← trace p initial allow n t plainAfter count))

def resumeChecks (p : Program) (initial : Trial.Start) (first : Counted.State)
    (segments : List (List Nat)) : Except String Json := do
  let groups ← segments.mapM fun budgets => do
    let mut total := 0
    let mut split := first
    let mut evidence := []
    for budget in budgets do
      split ← Counted.advance p budget split
      total := total+budget
      let whole ← Counted.advance p total first
      if reprStr split != reprStr whole then throw "segmented advance mismatch"
      let observation1 := state split initial
      let observation2 := state split initial
      let afterObservation ← Counted.advance p 0 split
      evidence := evidence ++ [Json.mkObj [("budget",toJson budget),("total",toJson total),
        ("split",state split initial),("whole",state whole initial),
        ("observation1",observation1),("observation2",observation2),
        ("afterObservation",state afterObservation initial)]]
    pure (toJson evidence)
  pure (toJson groups)

def cutChecks (p : Program) (initial : Trial.Start) (first : Counted.State)
    (cuts : List Nat) : Except String Json := do
  let evidence ← cuts.mapM fun cut => do
    let s ← Counted.advance p cut first
    let resumed ← Counted.advance p 10000 s
    let whole ← Counted.advance p (cut+10000) first
    let life : Lifecycle.State := { execution := s }
    let once := Lifecycle.destroy life
    let twice := Lifecycle.destroy once
    pure (Json.mkObj [("cut",toJson cut),("before",lifecycle life initial),
      ("resumed",state resumed initial),("whole",state whole initial),
      ("destroyFirst",lifecycle once initial),("destroySecond",lifecycle twice initial)])
  pure (toJson evidence)

def policy (gate : String) : Lifecycle.Policy := fun r ordinal =>
  !(ordinal == 1 && ((gate == "number" && r.domain == .number && r.site == "outerFail/1/0") ||
    (gate == "frame" && r.domain == .frame && r.site == "one") ||
    (gate == "cell" && r.domain == .cell && r.site == "one")))

def run (j : Json) : Except String Json := do
  let fs ← (← (← j.getObjVal? "functions").getArr?).toList.mapM fn
  let p : Program := ⟨fs,← expr 10000 (← j.getObjVal? "main")⟩
  let initial ← start (← j.getObjVal? "start")
  let fuel : Nat ← fromJson? (← j.getObjVal? "budget")
  let gate ← (← j.getObjVal? "gate").getStr?
  let first ← Counted.begin p initial
  if first.entered != Inspect.initialScope initial then throw "initial observer scope"
  let plainInputs ← initial.inputs.mapM fun (name,v) => do pure (name, ← Trial.readBack initial.toMemory v)
  let ps ← Plain.begin p plainInputs
  let s ← Lifecycle.advance p (policy gate) fuel { execution := first }
  let shouldTrace ← (← j.getObjVal? "trace").getBool?
  let states ← if shouldTrace then trace p initial (policy gate) fuel { execution := first } ps 0 else pure []
  let segments : List (List Nat) ← fromJson? (← j.getObjVal? "segments")
  let resumes ← resumeChecks p initial first segments
  let cuts : List Nat ← fromJson? (← j.getObjVal? "cuts")
  let pauses ← cutChecks p initial first cuts
  Inspect.trace p initial s.execution.steps first
  if s.execution.answer.isSome && !Inspect.finalGraph s.execution then throw "final graph"
  let answer ← s.execution.answer.mapM (fun v => Trial.readBack s.execution.mem v.raw)
  let decoded ← Control.decode first
  if reprStr decoded != reprStr ps then throw "initial plain/control correspondence"
  let ps := Plain.advance p fuel ps
  let plainAnswer := match ps.focus with | .finished v => some (value v) | _ => none
  let destroyed := Lifecycle.destroy s
  let twice := Lifecycle.destroy destroyed
  pure (Json.mkObj [
    ("status",toJson (if s.failure.isSome then "failed" else if s.execution.answer.isSome then "finished" else "suspended")),
    ("answer",answer.map value |>.getD Json.null),
    ("raw",s.execution.answer.map (fun v => raw v.raw) |>.getD Json.null),
    ("plainAnswer",plainAnswer.getD Json.null),
    ("state",state s.execution initial),
    ("trace",toJson (if shouldTrace then state first initial false :: states else [])),
    ("resumes",resumes),
    ("cutChecks",pauses),
    ("failure",toJson (reprStr s.failure)),
    ("lifecycle",lifecycle s initial),
    ("destroyFirst",lifecycle destroyed initial),("destroySecond",lifecycle twice initial),
    ("destroyed",state destroyed.execution initial), ("cleanup",toJson destroyed.cleanup),
    ("destroyTwiceEqual",toJson (reprStr twice == reprStr destroyed))])

end Export

def main (args : List String) : IO Unit := do
  let [input,output] := args | throw (IO.userError "usage: Export.lean input.json output.json")
  let parsed := Json.parse (← IO.FS.readFile input)
  let result : Except String Json := do
    let rows ← (← parsed).getArr?
    let pairs ← rows.toList.mapM fun row => do
      pure (← (← row.getObjVal? "id").getStr?, ← Export.run row)
    pure (Json.mkObj pairs)
  match result with
  | .error why => throw (IO.userError why)
  | .ok j => IO.FS.writeFile output (j.pretty ++ "\n")
