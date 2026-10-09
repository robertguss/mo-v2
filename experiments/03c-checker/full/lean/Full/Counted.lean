import Full.Plain

/-! Explicit work-list machine. Tasks are saved continuation data, never host
closures. Each tick consumes one action. Immutable source states retain every
operand while a transfer is calculated; no helper removes a holder into a host
local. One complete state installs each ownership transfer. The pre-commit
state is an explicit boundary, checked separately from metadata commit. -/
namespace Full.Counted

abbrev Env := Trial.Env

structure Context where
  env : Env := []
  invocation : Nat := 0
  branches : List Nat := []
  site : String := "main"
  deriving Repr

structure Slot where
  raw : Raw
  value : Value
  deriving Repr

structure Binding where
  record : Trial.Binding
  value : Value
  invocation : Nat
  origin : String
  deriving Repr

structure Reservation where
  invocation : Nat
  branch : Nat
  addr : Nat
  deriving Repr

structure Frame where
  id : Nat
  name : String
  parent : Nat
  args : List Slot
  site : String
  deriving Repr

inductive Task where
  | start
  | eval (e : Expr) (ctx : Context)
  | capture
  | primitive (op : Op) (ctx : Context)
  | bind (name : String) (body : Expr) (ctx : Context)
  | chooseIf (yes no : Expr) (ctx : Context)
  | chooseMatch (empty : Expr) (head tail : String) (cell : Expr) (ctx : Context)
  | decompose (head tail : String) (body : Expr) (bid : Nat) (ctx : Context)
  | matchComplete (ctx : Context)
  | branchStart (ctx : Context)
  | branchResult (bid : Nat) (inner outer : Context)
  | handoffMatch (outer : Context)
  | handoff
  | enter (name : String) (arity : Nat) (ctx : Context)
  | returning (frame : Frame) (ctx : Context)
  | giveBinding (id : Nat)
  | givePending
  | free (addr : Nat)
  | freeReserved (addr : Nat)
  | finish
  deriving Repr

inductive Event where
  | create (addr : Nat) (item : Int) (link : Option Nat)
  | write (addr : Nat) (item : Int) (link : Option Nat)
  | free (addr : Nat)
  | enter (frame : Frame)
  | returning (id : Nat) (result : Slot)
  deriving Repr

structure Action where
  name : String
  landmark : Option Trial.StepKind := none
  deriving Repr

structure State where
  mem : Trial.Memory
  outside : List (Option Nat)
  /-- Immutable suffix installed with each live cell link. -/
  edges : List (Nat × Value) := []
  releaseChain : List Nat := []
  bindings : List Binding := []
  entered : Env := []
  slots : List Slot := []
  reservations : List Reservation := []
  frames : List Frame := []
  tasks : List Task := []
  nextBinding : Nat := 0
  nextBranch : Nat := 0
  nextInvocation : Nat := 1
  events : List Event := []
  history : List Action := []
  landmarks : List Trial.Snapshot := []
  steps : Nat := 0
  answer : Option Slot := none
  deriving Repr

def pending (s : State) : List Raw := s.slots.filterMap fun v =>
  match v.raw with | .list (some _) => some v.raw | _ => none

def visible (s : State) : List Trial.Binding :=
  s.bindings.filterMap fun b =>
    if s.entered.any (fun p => p.2 == b.record.id) || b.record.status == .holding
    then some b.record else none

structure Change where
  state : State
  action : Action
  branchValue : Option Raw := none
  deriving Repr

/-- Ownership/control/effects are already installed. This helper changes only
observation metadata and is a separately stated internal boundary. -/
def commit (change : Change) : State :=
  let s := change.state
  let snap := change.action.landmark.map fun k =>
    ({ kind := k, memory := s.mem.cells, bindings := visible s,
       pending := pending s, outside := s.outside,
       setAside := s.reservations.map (fun r => (r.branch,r.addr)),
       branchValue := change.branchValue } : Trial.Snapshot)
  { s with
    steps := s.steps+1, history := s.history ++ [change.action],
    landmarks := s.landmarks ++ snap.toList }

/-- Only unevaluated source text contributes future uses. Binders not yet born
hide equal spellings. No recursive callee body is inspected in caller scope. -/
def taskUses (id : Nat) : Task → Bool
  | .eval e ctx => uses e (Trial.toFEnv ctx.env) id
  | .bind x body ctx => uses body ((x,none)::Trial.toFEnv ctx.env) id
  | .chooseIf t e ctx => uses t (Trial.toFEnv ctx.env) id || uses e (Trial.toFEnv ctx.env) id
  | .chooseMatch n h t c ctx =>
    uses n (Trial.toFEnv ctx.env) id || uses c ((t,none)::(h,none)::Trial.toFEnv ctx.env) id
  | .decompose h t c _ ctx => uses c ((t,none)::(h,none)::Trial.toFEnv ctx.env) id
  | _ => false

def dead (bindings : List Binding) (env : Env) (future : List Task) : List Task :=
  env.reverse.filterMap fun (_,id) =>
    if bindings.any (fun b => b.record.id == id && b.record.status == .holding) &&
        !future.any (taskUses id) then some (.giveBinding id) else none

def child (ctx : Context) (index : Nat) : Context :=
  { ctx with site := s!"{ctx.site}/{index}" }

/-- Constructs data, without installing an additional owner in any State. -/
def makeBinding (id : Nat) (name : String) (v : Slot) (invocation : Nat)
    (origin : String) (holding : Bool := true) : Binding :=
  let status := match v.raw with
    | .list (some _) => if holding then Trial.BStatus.holding else .noHolder
    | _ => .noHolder
  ⟨⟨id,name,v.raw,status⟩,v.value,invocation,origin⟩

/-- No StateT, destructive pop, partial scope, or partly installed frame exists
inside a transfer. All reads refer to the unchanged source `s`; intermediate
Memory/list calculations are proposed data, not running machine states. Even
the current cleanup task stays in `s` until its replacement is installed. -/
def transition (p : Program) (s : State) : Except String Change := do
  let task::rest := s.tasks | throw "unfinished state with no action"
  match task with
  | .start => pure ⟨{ s with tasks := rest },⟨"Start",some .start⟩,none⟩
  | .capture => pure ⟨{ s with tasks := rest },⟨"Capture",none⟩,none⟩
  | .eval e ctx =>
    match e with
    | .num n => pure ⟨{ s with tasks := rest, slots := ⟨.num n,.num n⟩::s.slots },⟨"Leaf",none⟩,none⟩
    | .bool b => pure ⟨{ s with tasks := rest, slots := ⟨.bool b,.bool b⟩::s.slots },⟨"Leaf",none⟩,none⟩
    | .nil => pure ⟨{ s with tasks := rest, slots := ⟨.list none,.list []⟩::s.slots },⟨"Leaf",none⟩,none⟩
    | .var x =>
      let some (_,id) := ctx.env.find? (fun q => q.1 == x) | throw "unbound variable"
      let some b := s.bindings.find? (fun b => b.record.id == id) | throw "missing binding"
      let v : Slot := ⟨b.record.value,b.value⟩
      match v.raw with
      | .list (some addr) =>
        if b.record.status != .holding then throw "use after transfer"
        let later := rest.any (taskUses id)
        let mem ← if later then do
          let some c := s.mem.find? addr | throw "missing cell"
          if c.status != .live then throw "acquire reserved cell"
          s.mem.setCount addr (c.count+1)
          else pure s.mem
        let bindings := if later then s.bindings else s.bindings.map fun b =>
          if b.record.id == id then { b with record := { b.record with status := .movedOn } } else b
        pure ⟨{ s with mem, bindings, slots := v::s.slots, tasks := rest, entered := ctx.env },
          ⟨"Leaf",some (if later then .newHolder else .holderMoved)⟩,none⟩
      | _ => pure ⟨{ s with slots := v::s.slots, tasks := rest },⟨"Leaf",none⟩,none⟩
    | .bin op a b => pure ⟨{ s with tasks :=
        [.eval a (child ctx 0),.capture,.eval b (child ctx 1),.capture,.primitive op ctx] ++ rest },
        ⟨"Dispatch",none⟩,none⟩
    | .letE x a b => pure ⟨{ s with tasks := [.eval a (child ctx 0),.bind x b ctx] ++ rest },⟨"Dispatch",none⟩,none⟩
    | .ifE c t e => pure ⟨{ s with tasks := [.eval c (child ctx 0),.chooseIf t e ctx] ++ rest },⟨"Dispatch",none⟩,none⟩
    | .matchE a n h t c => pure ⟨{ s with tasks := [.eval a (child ctx 0),.chooseMatch n h t c ctx] ++ rest },⟨"Dispatch",none⟩,none⟩
    | .call name args =>
      let tasks := args.zipIdx.flatMap (fun (a,i) => [.eval a (child ctx i),.capture]) ++ [.enter name args.length ctx] ++ rest
      pure ⟨{ s with tasks },
        ⟨"Dispatch",none⟩,none⟩
  | .primitive op ctx =>
    let b::a::slots := s.slots | throw "missing operands"
    let value ← Plain.primitive op a.value b.value
    if op == .cons then
      let .num h := a.raw | throw "non-number head"
      let .list t := b.raw | throw "non-list tail"
      let eligible := s.reservations.find? fun r =>
        r.invocation == ctx.invocation && ctx.branches.contains r.branch
      let (addr,mem,effect,reservations) ← match eligible with
        | some r => do pure (r.addr,← s.mem.writeInPlace r.addr h t,Event.write r.addr h t,
            s.reservations.filter (fun q => q.addr != r.addr))
        | none =>
          let (addr,mem) := s.mem.create h t
          pure (addr,mem,Event.create addr h t,s.reservations)
      pure ⟨{ s with
        mem, reservations, tasks := rest, entered := ctx.env,
        edges := (addr,b.value)::s.edges.filter (fun q => q.1 != addr),
        slots := ⟨.list (some addr),value⟩::slots, events := s.events ++ [effect] },
        ⟨"Primitive",some .newCellBuilt⟩,none⟩
    else
      let .num x := a.raw | throw "non-number operand"
      let .num y := b.raw | throw "non-number operand"
      let raw : Raw := match op with
        | .add => .num (x+y) | .sub => .num (x-y)
        | .eq => .bool (x == y) | .lt => .bool (x < y) | .le => .bool (x ≤ y)
        | .cons => .list none
      pure ⟨{ s with slots := ⟨raw,value⟩::slots, tasks := rest },⟨"Primitive",none⟩,none⟩
  | .bind x body ctx =>
    let v::slots := s.slots | throw "missing binding operand"
    let b := makeBinding s.nextBinding x v ctx.invocation s!"{ctx.site}/binding"
    let bindings := s.bindings ++ [b]
    let inner := { ctx with env := (x,b.record.id)::ctx.env }
    let next := [.eval body (child inner 1),.handoff] ++ rest
    pure ⟨{ s with
      bindings, slots, nextBinding := s.nextBinding+1, entered := inner.env,
      tasks := dead bindings [(x,b.record.id)] next ++ next },
      ⟨"Bind",match v.raw with | .list (some _) => some .nameBound | _ => none⟩,none⟩
  | .chooseIf yes no ctx =>
    let v::slots := s.slots | throw "missing condition"
    let .bool b := v.raw | throw "non-Boolean condition"
    let next := [.branchStart ctx,.eval (if b then yes else no) (child ctx (if b then 1 else 2)),.handoff] ++ rest
    pure ⟨{ s with slots, tasks := dead s.bindings ctx.env next ++ next, entered := ctx.env },
      ⟨"Choose",some .branchChosen⟩,none⟩
  | .chooseMatch empty h t body ctx =>
    let v::slots := s.slots | throw "missing scrutinee"
    let .list l := v.raw | throw "non-list scrutinee"
    let bid := s.nextBranch
    let inner := { ctx with branches := bid::ctx.branches }
    let next := (match l with
      | none => [.branchStart inner,.eval empty (child inner 1),.branchResult bid inner ctx]
      | some _ => [.decompose h t body bid inner]) ++ rest
    pure ⟨{ s with
      nextBranch := bid+1, slots := if l.isNone then slots else s.slots,
      tasks := dead s.bindings ctx.env next ++ next, entered := ctx.env },⟨"Choose",some .branchChosen⟩,none⟩
  | .decompose h t body bid ctx =>
    let v::slots := s.slots | throw "missing scrutinee"
    let .list (some addr) := v.raw | throw "decompose empty"
    let .list (ph::pt) := v.value | throw "ghost scrutinee mismatch"
    let some c := s.mem.find? addr | throw "missing cell"
    if c.status != .live || c.count == 0 then throw "invalid scrutinee"
    let hid := s.nextBinding
    let tid := hid+1
    let inner := { ctx with env := (t,tid)::(h,hid)::ctx.env }
    let used := uses body (Trial.toFEnv inner.env) tid
    let outer := { ctx with branches := ctx.branches.tail }
    let continuation := [.branchStart inner,.eval body (child inner 2),.branchResult bid inner outer] ++ rest
    let bindings := s.bindings ++ [makeBinding hid h ⟨.num c.item,.num ph⟩ ctx.invocation s!"{ctx.site}/head",
      makeBinding tid t ⟨.list c.link,.list pt⟩ ctx.invocation s!"{ctx.site}/tail" (c.count == 1 || used)]
    if c.count == 1 then
      let mem ← s.mem.markSetAside addr
      pure ⟨{ s with
        mem, bindings, slots, nextBinding := tid+1, entered := inner.env,
        reservations := ⟨ctx.invocation,bid,addr⟩::s.reservations,
        edges := s.edges.filter (fun q => q.1 != addr),
        tasks := (if c.link.isSome && !used then [.giveBinding tid] else []) ++ continuation },
        ⟨"Decompose",some .matchStep4Done⟩,none⟩
    else
      let mem ← if used then match c.link with
        | none => pure s.mem
        | some tail => do
          let some tc := s.mem.find? tail | throw "missing tail cell"
          s.mem.setCount tail (tc.count+1)
        else pure s.mem
      -- A shared match without a tail acquisition enters scope only after release.
      pure ⟨{ s with
        mem, bindings, nextBinding := tid+1,
        entered := if used && c.link.isSome then inner.env else s.entered,
        tasks := [.givePending,.matchComplete inner] ++ continuation },
        ⟨"Decompose",if used && c.link.isSome then some .newHolder else none⟩,none⟩
  | .matchComplete ctx => pure ⟨{ s with entered := ctx.env, tasks := rest },⟨"MatchComplete",some .matchStep4Done⟩,none⟩
  | .branchStart ctx => pure ⟨{ s with entered := ctx.env, tasks := rest },⟨"BranchStart",some .branchStarts⟩,none⟩
  | .branchResult bid inner outer =>
    let v::_ := s.slots | throw "missing branch result"
    let rs := s.reservations.filter (fun r => r.invocation == inner.invocation && r.branch == bid)
    pure ⟨{ s with
      entered := inner.env,
      tasks := rs.map (fun r => .freeReserved r.addr) ++ [.handoffMatch outer] ++ rest },
      ⟨"BranchResult",some .branchValueWorkedOut⟩,some v.raw⟩
  | .handoffMatch outer =>
    let v::_ := s.slots | throw "missing branch result"
    pure ⟨{ s with entered := outer.env, tasks := rest },⟨"Handoff",some .branchValueHandedOn⟩,some v.raw⟩
  | .handoff => pure ⟨{ s with tasks := rest },⟨"Handoff",none⟩,none⟩
  | .enter name arity ctx =>
    let some f := signature p.functions name | throw "unknown callee"
    let args := (s.slots.take arity).reverse
    if args.length != arity || args.map (fun v => v.raw.kind) != f.params.map Prod.snd then
      throw "call kind or arity mismatch"
    let frame : Frame := ⟨s.nextInvocation,name,ctx.invocation,args,ctx.site⟩
    let parameters := (f.params.zip args).zipIdx.map fun (((x,_),v),i) =>
      makeBinding (s.nextBinding+i) x v frame.id s!"{name}/parameter/{x}"
    let env := parameters.reverse.map (fun b => (b.record.name,b.record.id))
    let bindings := s.bindings ++ parameters
    let callee : Context := ⟨env,frame.id,[],name⟩
    let next := [.eval f.body callee,.returning frame ctx] ++ rest
    pure ⟨{ s with
      bindings, entered := env, slots := s.slots.drop arity,
      nextBinding := s.nextBinding+parameters.length, nextInvocation := s.nextInvocation+1,
      frames := frame::s.frames, tasks := dead bindings env next ++ next, events := s.events ++ [.enter frame] },
      ⟨"Enter",none⟩,none⟩
  | .returning frame ctx =>
    let v::_ := s.slots | throw "missing return result"
    let f::frames := s.frames | throw "missing frame"
    if f.id != frame.id then throw "return order"
    pure ⟨{ s with frames, entered := ctx.env, tasks := rest, events := s.events ++ [.returning frame.id v] },
      ⟨"Return",none⟩,none⟩
  | .giveBinding _ | .givePending =>
    let (v,bindings,slots) ← match task with
      | .giveBinding id => do
        let some b := s.bindings.find? (fun b => b.record.id == id) | throw "missing binding"
        if b.record.status != .holding then throw "release dead binding"
        pure (⟨b.record.value,b.value⟩,s.bindings.map (fun b =>
          if b.record.id == id then { b with record := { b.record with status := .givenUp } } else b),s.slots)
      | _ => do
        let v::slots := s.slots | throw "missing release operand"
        pure (v,s.bindings,slots)
    let .list (some addr) := v.raw | throw "release without holder"
    let some c := s.mem.find? addr | throw "missing cell"
    if c.status != .live || c.count == 0 then throw "invalid release"
    let mem ← s.mem.setCount addr (c.count-1)
    pure ⟨{ s with
      mem, bindings, slots,
      releaseChain := if c.count == 1 then s.releaseChain ++ [addr] else [],
      tasks := if c.count == 1 then .free addr::rest else rest },⟨"GiveUp",some .holderGivenUp⟩,none⟩
  | .free addr =>
    let some c := s.mem.find? addr | throw "missing cell"
    if c.status != .live || c.count != 0 then throw "free nonzero or reserved"
    let some (_,tail) := s.edges.find? (fun q => q.1 == addr) | throw "missing immutable edge association"
    let mem ← s.mem.release addr
    pure ⟨{ s with
      mem, edges := s.edges.filter (fun q => q.1 != addr),
      slots := if c.link.isSome then ⟨.list c.link,tail⟩::s.slots else s.slots,
      releaseChain := if c.link.isSome then s.releaseChain else [],
      tasks := if c.link.isSome then .givePending::rest else rest,
      events := s.events ++ [.free addr] },⟨"Free",some .cellFreed⟩,none⟩
  | .freeReserved addr =>
    let some c := s.mem.find? addr | throw "missing cell"
    if c.status != .setAside || c.count != 0 then throw "free unreserved"
    let mem ← s.mem.release addr
    pure ⟨{ s with
      mem, reservations := s.reservations.filter (fun r => r.addr != addr),
      tasks := rest, events := s.events ++ [.free addr] },⟨"Free",some .cellFreed⟩,none⟩
  | .finish =>
    let v::_ := s.slots | throw "missing result"
    pure ⟨{ s with answer := some v, tasks := rest },⟨"Finish",some .end⟩,none⟩

def step (p : Program) (s : State) : Except String State := do
  if s.answer.isSome then pure s else pure (commit (← transition p s))

/-- Every running State in an action: source, atomic transfer output, and
metadata commit. Pure helper data never replaces the source State. -/
def Boundary (p : Program) (s t : State) : Prop :=
  t = s ∨ ∃ change, transition p s = .ok change ∧ (t = change.state ∨ t = commit change)

def advance (p : Program) : Nat → State → Except String State
  | 0, s => pure s
  | n+1, s => do
    if s.answer.isSome then pure s else advance p n (← step p s)

def begin (p : Program) (start : Trial.Start) : Except String State := do
  let _ ← validate p (start.inputs.map (fun (x,v) => (x,v.kind)))
  Trial.validStart (.num 0) start
  let edges ← start.cells.mapM fun c => do
    pure (c.addr, ← Trial.readBack start.toMemory (.list c.link))
  let bindings ← start.inputs.zipIdx.mapM fun ((name,raw),id) => do
    let value ← Trial.readBack start.toMemory raw
    pure (makeBinding id name ⟨raw,value⟩ 0 s!"main/input/{name}")
  let env := bindings.reverse.map (fun b => (b.record.name,b.record.id))
  let ctx : Context := { env := env }
  let tasks : List Task := [.start,.eval p.main ctx,.finish]
  pure {
    mem := start.toMemory, outside := start.outside, edges, bindings,
    nextBinding := bindings.length, entered := env, tasks := dead bindings env tasks ++ tasks }

end Full.Counted
