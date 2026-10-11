import Export
import Full.Demand
import Full.Statements

open Full Lean
namespace Stage2

def inspect (p : Program) : Nat → Counted.State → List (Counted.Frame × Bool) →
    Except String (Counted.State × List (Counted.Frame × Bool))
  | 0, s, entries => pure (s, entries)
  | n+1, s, entries => do
    if s.answer.isSome then return (s, entries)
    let t ← Counted.step p s
    let entries := if t.history.getLast?.map (·.name) == some "Enter" then
      match t.frames.head? with
      | some f => entries ++ [(f, Statements.uniqueEntry t f)]
      | none => entries
      else entries
    inspect p n t entries

def run (row : Json) : Except String Json := do
  let p : Program := ⟨← (← (← row.getObjVal? "functions").getArr?).toList.mapM Export.fn,
    ← Export.expr 10000 (← row.getObjVal? "main")⟩
  let initial ← Export.start (← row.getObjVal? "start")
  let first ← Counted.begin p initial
  let budget : Nat ← fromJson? (← row.getObjVal? "budget")
  let (last, entries) ← inspect p budget first []
  let verdicts := p.functions.map fun f => Json.mkObj [
    ("name", toJson f.name), ("demanded", toJson f.demanded),
    ("accepted", toJson (Demand.accepts p f.name)),
    ("reason", toJson (match Demand.check p f.name with
      | .ok _ => "accepted" | .error why => why))]
  pure (Json.mkObj [
    ("verdicts", toJson verdicts),
    ("entries", toJson (entries.map fun (f, unique) => Json.mkObj [
      ("name", toJson f.name), ("id", toJson f.id), ("unique", toJson unique),
      ("creates", toJson (Statements.creates f.id last.events))])),
    ("steps", toJson last.steps), ("finished", toJson last.answer.isSome),
    ("answer", last.answer.map (fun v => Export.value v.value) |>.getD Json.null),
    ("events", Export.events last)])

end Stage2

#eval show IO Unit from do
  let some input ← IO.getEnv "FULL3C_INPUTS" | throw (IO.userError "FULL3C_INPUTS required")
  let some output ← IO.getEnv "FULL3C_DEMAND_OUTPUT" | throw (IO.userError "FULL3C_DEMAND_OUTPUT required")
  let parsed := Json.parse (← IO.FS.readFile input)
  let result : Except String Json := do
    let rows ← (← parsed).getArr?
    pure (Json.mkObj (← rows.toList.mapM fun row => do
      pure (← (← row.getObjVal? "id").getStr?, ← Stage2.run row)))
  match result with
  | .error why => throw (IO.userError why)
  | .ok j => IO.FS.writeFile output (j.pretty ++ "\n")
