import Full.Statements

/-! Verifier reproductions, not proofs, predictions, or a demand checker. -/
open Full

def inspectCase (name : String) (p : Program) (initial : Trial.Start) : IO Unit := do
  let result := do
    let s ← Counted.begin p initial
    Inspect.trace p initial 300 s
    let t ← Counted.advance p 300 s
    let plain ← Statements.plainBegin p initial
    pure (t, Plain.advance p 300 plain)
  match result with
  | .error e => throw (IO.userError s!"{name}: {e}")
  | .ok (s,a) => IO.println s!"PASS {name}: answer={reprStr s.answer}; plain={reprStr a.focus}"

def main : IO Unit := do
  let empty : Trial.Start := ⟨[],[],[]⟩
  inspectCase "zero-arity Bool forward call"
    ⟨[⟨"f",[],.bool,.call "g" [],false⟩,⟨"g",[],.bool,.bool true,false⟩],.call "f" []⟩ empty
  inspectCase "three heterogeneous arguments"
    ⟨[⟨"f",[("b",.bool),("n",.number),("xs",.list)],.list,
      .ifE (.var "b") (.bin .cons (.var "n") (.var "xs")) (.var "xs"),false⟩],
      .call "f" [.bool true,.num (-17),.nil]⟩ empty
  let shared : Trial.Start := ⟨[⟨13,7,some 91,2⟩,⟨91,-4,none,2⟩],
    [("xs",.list (some 13))],[some 13,some 91,none]⟩
  inspectCase "sparse IDs shared tails repeated outside"
    ⟨[],.matchE (.var "xs") (.num 0) "h" "t" (.var "h")⟩ shared
  let repeated : Trial.Start := ⟨[⟨42,9,none,3⟩],[],[some 42,some 42,some 42]⟩
  inspectCase "outside-only repeated roots" ⟨[],.num 3⟩ repeated
  let p : Program := ⟨[⟨"ordinary",[("xs",.list)],.list,
    .bin .cons (.num 7) (.var "xs"),false⟩],.call "ordinary" [.nil]⟩
  let .ok first := Counted.begin p empty | throw (IO.userError "begin")
  let mut entry := first
  for _ in [:30] do
    if entry.history.getLast?.map (fun a => a.name) != some "Enter" then
      let .ok next := Counted.step p entry | throw (IO.userError "entry step")
      entry := next
  let some f := entry.frames.head? | throw (IO.userError "frame")
  let .ok done := Counted.advance p 30 entry | throw (IO.userError "advance")
  IO.println s!"CONDITIONAL DOMAIN: demanded=false; last={reprStr entry.history.getLast?}; unique={Statements.uniqueEntry entry f}; creates={Statements.creates f.id done.events}"
  -- Follow-up: the former destructive pop no longer exists. Check the actual
  -- immutable transfer source, exposed output, and metadata commit instead.
  let start : Trial.Start := ⟨[⟨5,11,none,1⟩],[("xs",.list (some 5))],[]⟩
  let cons : Program := ⟨[],.bin .cons (.num 8) (.var "xs")⟩
  let .ok begun := Counted.begin cons start | throw (IO.userError "cons begin")
  let mut before := begun
  for _ in [:20] do
    if !(match before.tasks.head? with | some (.primitive .cons _) => true | _ => false) then
      let .ok next := Counted.step cons before | throw (IO.userError "cons step")
      before := next
  let operand::_ := before.slots | throw (IO.userError "operand")
  let .ok change := Counted.transition cons before | throw (IO.userError "transition")
  let internal := change.state
  let committed := Counted.commit change
  let .ok expected := Inspect.effects before | throw (IO.userError "effects")
  if !Inspect.invariant start before || !Inspect.invariant start internal ||
      !Inspect.invariant start committed || !Inspect.readable before operand then
    throw (IO.userError "transfer boundary invariant")
  if reprStr committed.events != reprStr (before.events ++ expected) then
    throw (IO.userError "transfer boundary effects")
  let .ok a := Control.decode before | throw (IO.userError "source control")
  let .ok b := Control.decode internal | throw (IO.userError "output control")
  if reprStr b != reprStr (Plain.step cons a) ||
      reprStr (Control.decode committed) != reprStr (Control.decode internal) then
    throw (IO.userError "transfer boundary plain correspondence")
  IO.println s!"TRANSFER BOUNDARY: source/output/commit invariant=true; source operand readable=true; source owners={reprStr (Inspect.owners before)}; output owners={reprStr (Inspect.owners internal)}; exact full effects=true; independent plain step=true"
