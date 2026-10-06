import Lean
import Checks.Run
open Trial Lean
namespace Bridge
set_option maxRecDepth 10000
set_option maxHeartbeats 0

def arr (xs : List Json) : Json := .arr xs.toArray
def js (s : String) : Json := .str s
def jn (n : Nat) : Json := toJson n
def ji (n : Int) : Json := js (toString n)
def ptr (a : Option Nat) : Json := match a with | none => .null | some a => jn a
def raw : RawValue → Json
  | .num n => arr [js "n", ji n]
  | .bool b => arr [js "b", toJson b]
  | .list p => arr [js "l", ptr p]
def cell (c : Cell) : Json := arr [jn c.addr, ji c.item, ptr c.link, jn c.count, js (if c.status == .live then "live" else "aside")]
def bind (b : Binding) : Json := arr [jn b.id, js b.name, raw b.value, js (match b.status with
  | .holding => "holding" | .givenUp => "givenUp" | .movedOn => "movedOn" | .noHolder => "noHolder")]
def step (k : StepKind) : String := (repr k).pretty |>.splitOn "." |>.getLast!
def snap (s : Snapshot) : Json := Json.mkObj [
  ("kind", js (step s.kind)), ("memory", arr (s.memory.map cell)),
  ("bindings", arr (s.bindings.map bind)), ("pending", arr (s.pending.map raw)),
  ("outside", arr (s.outside.map ptr)), ("aside", arr (s.setAside.map fun (b,a) => arr [jn b,jn a])),
  ("branch", match s.branchValue with | none => .null | some r => raw r)]
def event : MemEvent → Json
  | .created a => arr [js "create",jn a]
  | .written a => arr [js "write",jn a]
  | .released a => arr [js "free",jn a]
def plain : PlainValue → Json
  | .num n => arr [js "n",ji n]
  | .bool b => arr [js "b",toJson b]
  | .list ns => arr [js "l",arr (ns.map ji)]
def tokens : Trial.Expr → String
  | .num n => s!"num {n}"
  | .nil => "nil"
  | .var x => s!"var {x}"
  | .add a b => s!"add {tokens a} {tokens b}"
  | .sub a b => s!"sub {tokens a} {tokens b}"
  | .eq a b => s!"eq {tokens a} {tokens b}"
  | .lt a b => s!"lt {tokens a} {tokens b}"
  | .le a b => s!"le {tokens a} {tokens b}"
  | .cons a b => s!"cons {tokens a} {tokens b}"
  | .letE x a b => s!"let {x} {tokens a} {tokens b}"
  | .ifE c a b => s!"if {tokens c} {tokens a} {tokens b}"
  | .matchE s n h t c => s!"match {h} {t} {tokens s} {tokens n} {tokens c}"
def rawTok : RawValue → String
  | .num n => s!"n {n}"
  | .bool b => s!"b {if b then 1 else 0}"
  | .list l => s!"l {l.getD 0}"
-- Every fixture uses positive addresses; zero is only the empty-link wire token.
def wire (e : Trial.Expr) (s : Start) : String := String.intercalate " "
  ([toString s.cells.length] ++ s.cells.map (fun c => s!"{c.addr} {c.item} {c.link.getD 0} {c.count}") ++
   [toString s.inputs.length] ++ s.inputs.map (fun (n,v) => s!"{n} {rawTok v}") ++
   [toString s.outside.length] ++ s.outside.map (fun a => toString (a.getD 0)) ++ [tokens e])
def depth : Trial.Expr → Nat
  | .num _ | .nil | .var _ => 0
  | .add a b | .sub a b | .eq a b | .lt a b | .le a b | .cons a b | .letE _ a b => 1 + max (depth a) (depth b)
  | .ifE a b c | .matchE a b _ _ c => 1 + max (depth a) (max (depth b) (depth c))
def corpus : List Trial.Expr := Id.run do
  let atoms := [Trial.Expr.num (-1),.num 0,.num 1,.var "n"]
  let lists := [Trial.Expr.nil,.var "xs",.var "ys"]
  let mut es := atoms ++ lists
  for a in atoms do
    for b in atoms do
      es := es ++ [.add a b,.sub a b,.eq a b,.lt a b,.le a b]
      for op in [Trial.Expr.eq,Trial.Expr.lt,Trial.Expr.le] do
        es := es ++ [.ifE (op a b) (.var "xs") (.var "ys")]
    for t in lists do es := es ++ [.cons a t]
  for t in lists do
    es := es ++ [.letE "xs" t (.var "xs"),.letE "z" t .nil]
    for n in atoms do
      es := es ++ [.matchE t n "h" "rest" (.add (.var "h") n)]
    es := es ++ [.matchE t .nil "h" "rest" (.var "rest"),
      .matchE t .nil "h" "rest" (.cons (.var "h") (.var "rest")),
      .matchE t .nil "h" "rest" (.cons (.add (.var "h") (.num 1)) (.var "rest")),
      .matchE t .nil "h" "rest" (.matchE (.var "rest") .nil "h" "rest" (.cons (.var "h") (.var "rest")))]
  return es

def shape (k : Nat) (n : Int) : Start := Id.run do
  let (items, links, xs, ys, outside) : List Int × List (Option Nat) × Option Nat × Option Nat × List (Option Nat) :=
    match k with
    | 0 => ([],[],none,none,[])
    | 1 => ([-1],[none],some 1,none,[])
    | 2 => ([-1,0],[some 2,none],some 1,none,[])
    | 3 => ([-1,0,1],[some 2,some 3,none],some 1,none,[])
    | 4 => ([-1,0,1],[some 2,some 3,none],some 1,some 1,[])
    | 5 => ([-1,0,1],[some 3,some 3,none],some 1,some 2,[])
    | 6 => ([-1,0,1],[some 2,some 3,none],some 1,none,[some 1])
    | _ => ([-1,0,1],[some 2,some 3,none],some 1,none,[some 2])
  let roots := [xs,ys] ++ outside
  let cells := (items.zip links).zipIdx |>.map fun ((item,link),i) =>
    let a := i+1
    ({addr:=a,item:=item,link:=link,count:=((roots++links).filter (· == some a)).length} : StartCell)
  return { cells:=cells, inputs:=[("xs",.list xs),("ys",.list ys),("n",.num n)], outside:=outside }

def emit (id : String) (e : Trial.Expr) (s : Start) : IO Unit := do
  match validStart e s with | .error err => throw (IO.userError s!"{id}: {err}") | .ok _ => pure ()
  let o := runCounted .approved e s
  let r ← match o.result with | .answer r => pure r | _ => throw (IO.userError s!"{id}: no answer")
  let p ← match readBack o.memory r with | .ok p => pure p | .error err => throw (IO.userError err)
  let pa ← match Checks.plainAnswer ⟨0,e,s⟩ with | .ok p => pure p | .error err => throw (IO.userError err)
  if p != pa then throw (IO.userError s!"{id}: plain/counted mismatch")
  for test in [Checks.finalReachable s o,Checks.finalCounts s o,Checks.outsideUnchanged s o] do
    match test with | .ok _ => pure () | .error err => throw (IO.userError s!"{id}: {err}")
  IO.println (Json.mkObj [
    ("id",js id),("input",js (wire e s)),("depth",jn (depth e)),
    ("initial",arr (s.toMemory.cells.map cell)),("outside",arr (s.outside.map ptr)),
    ("expected",Json.mkObj [("answer",raw r),("value",plain p),("memory",arr (o.memory.cells.map cell)),
      ("record",arr (o.record.map event)),("log",arr ((Checks.logAsRecord o.log).map event)),
      ("states",arr (o.states.map snap))])]).compress

def main : IO Unit := do
  for r in Checks.runs do
    let o := runCounted .approved r.program r.start
    let p ← match Checks.predictions.find? (fun p => p.number == r.number) with
      | some p => pure p | none => throw (IO.userError "missing original prediction")
    if (Checks.runItems r p o).any (fun i => !i.passed) then throw (IO.userError "original predictions failed")
    emit s!"original-{r.number}" r.program r.start
  for k in List.range 8 do
    for n in [(-1 : Int),0,1] do
      for (e,i) in corpus.zipIdx do
        if depth e > 3 then throw (IO.userError "generated depth exceeded")
        emit s!"generated-{k}-{n}-{i}" e (shape k n)

end Bridge
#eval Bridge.main
