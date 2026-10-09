import Export
import Full.Statements

/-! Deliberately faulty transition/accounting implementations, not mutations of
exported JSON and not a demand checker. Each transition is invoked on an actual
reachable fixture state. Its unmodified counterpart must pass the same property;
an unreached route, build failure, or thrown candidate error is a failed control.
Run after compiling Export.lean to the package's build/lib/lean/Export.olean:
FULL3C_INPUTS=/path/inputs.json lake env lean ../verification/Controls.lean -/
namespace Controls
open Full

inductive Fault where
  | callerReservation | sharedReuse | pendingHolder | suspendedHolder
  | administrativeLoop | skipFree | hiddenEntryCopy | returnPayload | cellPayload
  | skipBranchCleanup | skipReturnCleanup | skipUnusedParameter
  | hiddenScope | observerOrder
  deriving Repr

def corruptStep (fault : Fault) (p : Program) (s : Counted.State) :
    Except String (Option Counted.State) := do
  match fault, s.tasks with
  | .hiddenScope, .enter _ _ _ :: _ =>
    let change ← Counted.transition p s
    if change.state.entered.isEmpty then pure none else
      pure (some (Counted.commit { change with state := { change.state with entered := [] } }))
  | .observerOrder, .enter _ _ _ :: _ =>
    let change ← Counted.transition p s
    if (Counted.visible change.state).length < 2 then pure none else
      pure (some (Counted.commit { change with state :=
        { change.state with bindings := change.state.bindings.reverse } }))
  | .callerReservation, .primitive .cons ctx :: rest =>
    let some r := s.reservations.find? (fun r => r.invocation != ctx.invocation) | pure none
    -- Actually select and write the suspended caller's reservation.
    let wrong := { ctx with invocation := r.invocation, branches := [r.branch] }
    pure (some (← Counted.step p { s with tasks := .primitive .cons wrong :: rest }))
  | .sharedReuse, .decompose _ _ _ _ _ :: _ =>
    let v::_ := s.slots | pure none
    let .list (some addr) := v.raw | pure none
    let some c := s.mem.find? addr | pure none
    if c.count ≤ 1 then pure none else
      -- The candidate trusts a false uniqueness count and really detaches it.
      let mem ← s.mem.setCount addr 1
      pure (some (← Counted.step p { s with mem }))
  | .pendingHolder, .enter _ arity _ :: _ =>
    if s.slots.length ≤ arity then pure none else
      let t ← Counted.step p s
      let v::_ := t.slots | pure none
      let .list (some addr) := v.raw | pure none
      let some c := t.mem.find? addr | pure none
      let mem ← t.mem.setCount addr (c.count-1)
      pure (some { t with mem, slots := t.slots.tail })
  | .suspendedHolder, .enter _ _ _ :: _ =>
    let t ← Counted.step p s
    let some frame := t.frames.head? | pure none
    let some b := t.bindings.find? (fun b => b.invocation != frame.id && b.record.status == .holding)
      | pure none
    let .list (some addr) := b.record.value | pure none
    let some c := t.mem.find? addr | pure none
    let mem ← t.mem.setCount addr (c.count-1)
    -- Keep counts consistent with the lie; only source-required protection catches it.
    pure (some { t with mem, bindings := t.bindings.map fun q =>
      if q.record.id == b.record.id then { q with record := { q.record with status := .givenUp } } else q })
  | .administrativeLoop, .capture :: _ =>
    -- Re-execute this same administrative action instead of consuming it.
    pure (some (Counted.commit ⟨s,⟨"Capture",none⟩,none⟩))
  | .skipFree, .free _ :: rest =>
    pure (some (Counted.commit ⟨{ s with tasks := rest },⟨"Free",some .cellFreed⟩,none⟩))
  | .skipBranchCleanup, .branchResult _ _ _ :: _ =>
    let t ← Counted.step p s
    if t.reservations.isEmpty then pure none else
      pure (some { t with tasks := t.tasks.filter fun task => match task with
        | .freeReserved _ => false | _ => true })
  | .skipReturnCleanup, .returning _ _ :: _ =>
    let t ← Counted.step p s
    pure (some { t with frames := s.frames })
  | .skipUnusedParameter, .enter _ _ _ :: _ =>
    let t ← Counted.step p s
    let .giveBinding _ :: rest := t.tasks | pure none
    pure (some { t with tasks := rest })
  | .hiddenEntryCopy, .enter _ 1 _ :: _ =>
    let v::slots := s.slots | pure none
    let .list (some addr) := v.raw | pure none
    let some c := s.mem.find? addr | pure none
    if c.count != 1 || c.link.isSome then pure none else
      -- C8's singleton is physically copied/replaced while preparing Enter.
      -- The faulty accounting boundary puts its Create before the Enter event.
      let (fresh,mem) := s.mem.create c.item none
      let mem ← mem.release addr
      let prepared := { s with
        mem, slots := { v with raw := .list (some fresh) }::slots,
        edges := (fresh,.list [])::s.edges.filter (fun e => e.1 != addr),
        events := s.events ++ [.create fresh c.item none,.free addr] }
      pure (some (← Counted.step p prepared))
  | .returnPayload, .returning f _ :: _ =>
    let t ← Counted.step p s
    let v::_ := t.slots | pure none
    let .num n := v.raw | pure none
    pure (some { t with events := s.events ++ [.returning f.id ⟨.num (n+1),.num (n+1)⟩] })
  | .cellPayload, .primitive .cons _ :: _ =>
    let t ← Counted.step p s
    let changed := t.events.map fun e => match e with
      | .create a h tail => Counted.Event.create a (h+1) tail
      | _ => e
    pure (some { t with events := changed })
  | _, _ => pure none

def correctEffects (s t : Counted.State) : Bool :=
  match Inspect.effects s with
  | .error _ => false
  | .ok es => reprStr t.events == reprStr (s.events ++ es) &&
      t.mem.record == s.mem.record ++ Inspect.cellEffects es

def property (fault : Fault) (p : Program) (initial : Trial.Start) (s t : Counted.State) : Except String Bool := do
  match fault with
  | .hiddenScope => pure ((← Inspect.nextScope p s) == t.entered)
  | .observerOrder => pure (Inspect.observer t)
  | .sharedReuse | .suspendedHolder => pure (Inspect.protection initial t)
  | .pendingHolder => match Control.decode s, Control.decode t with
    | .ok before,.ok after => pure (reprStr after == reprStr (Plain.step p before))
    | _,_ => pure false
  | .administrativeLoop => pure (Control.rank t < Control.rank s)
  | .skipBranchCleanup | .skipReturnCleanup | .skipUnusedParameter =>
    let done ← Counted.advance p 300 t
    if done.answer.isNone then throw "cleanup control did not reach Finish"
    pure (Inspect.finalGraph done)
  | _ => pure (correctEffects s t)

def probe (fault : Fault) (p : Program) (initial : Trial.Start) :
    Nat → Counted.State → Except String (Nat × Counted.State × Counted.State)
  | 0, _ => throw "faulty route was not reached"
  | n+1, s => do
    match ← corruptStep fault p s with
    | none => probe fault p initial n (← Counted.step p s)
    | some bad =>
      let good ← Counted.step p s
      if !(← property fault p initial s good) then throw "unmodified transition failed control property"
      if (← property fault p initial s bad) then throw "faulty transition escaped intended property"
      pure (s.steps,good,bad)

def program (rows : List Lean.Json) (id : String) : Except String (Program × Trial.Start) := do
  let some row := rows.find? (fun row => match (row.getObjVal? "id").bind Lean.Json.getStr? with
    | .ok name => name == id | .error _ => false)
    | throw s!"missing fixture {id}"
  let fs ← (← (← row.getObjVal? "functions").getArr?).toList.mapM Export.fn
  pure (⟨fs,← Export.expr 10000 (← row.getObjVal? "main")⟩,← Export.start (← row.getObjVal? "start"))

def unwrap (x : Except String α) : IO α :=
  match x with | .ok v => pure v | .error e => throw (IO.userError e)

def wrongCounter (resetOnChild : Bool) (invocation : Nat) (events : List Counted.Event) : Nat :=
  let (_,n) := events.foldl (fun (active,n) event => match event with
    | .enter f => (active || f.id == invocation, if active && resetOnChild then 0 else n)
    | .returning id _ => (active && id != invocation,n)
    | .create _ _ _ => (active,n + if active then 1 else 0)
    | .free _ => (active,if active && !resetOnChild then n-1 else n)
    | _ => (active,n)) (false,0)
  n

def run : IO Unit := do
  let some path ← IO.getEnv "FULL3C_INPUTS" | throw (IO.userError "set FULL3C_INPUTS")
  let j ← unwrap (Lean.Json.parse (← IO.FS.readFile path))
  let rows := (← unwrap j.getArr?).toList
  let tests : List (Fault × String) := [(.callerReservation,"C1"),(.sharedReuse,"C3"),
    (.pendingHolder,"C3"),(.suspendedHolder,"C4"),(.administrativeLoop,"C19"),
    (.skipFree,"C16"),(.hiddenEntryCopy,"C8"),(.returnPayload,"C7"),(.cellPayload,"C8"),
    (.skipBranchCleanup,"C1"),(.skipReturnCleanup,"C8"),(.skipUnusedParameter,"C17"),
    (.hiddenScope,"C12"),(.observerOrder,"C4")]
  for (fault,id) in tests do
    let (p,initial) ← unwrap (program rows id)
    let first ← unwrap (Counted.begin p initial)
    let (step,good,bad) ← unwrap (probe fault p initial 300 first)
    IO.println s!"REJECT {reprStr fault}: {id} route executed at action {step+1}; baseline=true mutant=false; good-events={reprStr good.events}; bad-events={reprStr bad.events}"
  -- Independently predicted counts: C7/C9 one Create in the outer interval;
  -- C13 two Creates in invocation 1 by action 29, despite an empty heap.
  for (id,reset,budget,expected) in [("C7",false,300,1),("C9",true,300,1),("C13",false,29,2)] do
    let (p,initial) ← unwrap (program rows id)
    let first ← unwrap (Counted.begin p initial)
    let done ← unwrap (Counted.advance p budget first)
    let baseline := Statements.creates 1 done.events
    let faulty := wrongCounter reset 1 done.events
    if baseline != expected || faulty == expected then throw (IO.userError s!"accounting control {id}")
    IO.println s!"REJECT accounting {id}: actual Create={baseline}, faulty counter={faulty}, expected={expected}; descendant-reset={reset}"
  let (p,initial) ← unwrap (program rows "C12")
  let first ← unwrap (Counted.begin p initial)
  let suspended ← unwrap (Counted.advance p 29 first)
  let fake := { suspended with answer := some ⟨.num 0,.num 0⟩ }
  if suspended.answer.isSome || Inspect.finalGraph fake then throw (IO.userError "false Finish control")
  IO.println "REJECT false Finish C12: seven active frames, no source answer; mutant answer violates final graph"
  let (p,initial) ← unwrap (program rows "C19")
  let first ← unwrap (Counted.begin p initial)
  let cut ← unwrap (Counted.advance p 17 first)
  let correct ← unwrap (Counted.advance p 1 cut)
  let whole ← unwrap (Counted.advance p 18 first)
  -- Executed faulty resume route restarts from the saved initial state.
  let restarted ← unwrap (Counted.advance p 1 first)
  if reprStr correct != reprStr whole || reprStr restarted == reprStr whole then
    throw (IO.userError "restart control")
  IO.println s!"REJECT restart C19: correct steps={correct.steps}, restarted steps={restarted.steps}; correct Finished={correct.answer.isSome}"
  let (p,initial) ← unwrap (program rows "C20-number")
  let first ← unwrap (Counted.begin p initial)
  let good ← unwrap (Lifecycle.advance p (Export.policy "number") 300 { execution := first })
  if good.failure.isNone then throw (IO.userError "denial not reached")
  -- The bad lifecycle wrapper executes the denied arithmetic before reporting it.
  let committed ← unwrap (Counted.step p good.execution)
  let bad := { good with execution := committed }
  if reprStr bad.execution == reprStr good.execution then throw (IO.userError "late denial control")
  IO.println s!"REJECT late denial C20-number: last committed steps={good.execution.steps}, mutant={bad.execution.steps}"
  let destroyed := Lifecycle.destroy good
  -- An actual no-op destroy implementation is just the identity function.
  let noOp := (fun s : Lifecycle.State => s) good
  if !destroyed.destroyed || noOp.destroyed || reprStr destroyed == reprStr noOp then
    throw (IO.userError "no-op destroy control")
  IO.println "REJECT no-op destroy C20-number: baseline cleared control; mutant retains failed execution"
  IO.println "PASS: 21 executed faulty routes rejected; baseline controls passed. No proof/checker mutation claimed."

end Controls

#eval Controls.run
