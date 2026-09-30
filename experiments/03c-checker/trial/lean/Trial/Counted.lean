import Trial.Memory

/-!
# The counted meaning: the rule of `RULE.md`

A big-step evaluator, by structural recursion on `Expr`, that runs a program on
counted memory. It carries, as plain data, the program text still to run after the
current expression (a list of `Frame`s, each with the environment it will run in):
"last use" (`RULE.md` 4) is judged from that text. Environments refer to bindings
by id and hold nothing; only the binding itself holds its holder.

The five departures of the broken copies are switches of `Variant`. Each switch is
read at exactly one place, written "if the switch is on, the departure; otherwise
the rule's own step".
-/

namespace Trial

/-- Five true-or-false switches, one per departure (`INTERFACE.md` 7). All off is
the approved rule. -/
structure Variant where
  misreportsReuse : Bool
  reusesShared : Bool
  forgetsRest : Bool
  freesHeld : Bool
  neverReuses : Bool
  deriving DecidableEq, Repr

/-- The approved rule: no departure. -/
def Variant.approved : Variant :=
  { misreportsReuse := false, reusesShared := false, forgetsRest := false,
    freesHeld := false, neverReuses := false }

/-! ## The rule's log and what a snapshot shows -/

/-- The rule's log (`INTERFACE.md` 5): every allocation, reuse and free the rule
claims, in order. Appended only by the rule, never by memory. -/
inductive LogEvent where
  | alloc (a : Addr)
  | reuse (a : Addr)
  | free (a : Addr)
  deriving DecidableEq, Repr

/-- Whether a binding still holds its holder, has given it up, has passed it on, or
never had one (a number, true or false, or the empty list). -/
inductive BStatus where
  | holding
  | givenUp
  | movedOn
  | noHolder
  deriving DecidableEq, Repr

/-- A name bound in a run. Each has a unique id, so two bindings of one spelling are
distinct (D83). -/
structure Binding where
  id : Nat
  name : String
  value : RawValue
  status : BStatus
  deriving DecidableEq, Repr

/-- The kinds of step a snapshot follows (`INTERFACE.md` 6). Every free, whether in
a cascade (`RULE.md` 5) or of an unused set-aside cell (6g), is `cellFreed`. -/
inductive StepKind where
  | start
  | branchChosen
  | newHolder
  | holderGivenUp
  | cellFreed
  | matchStep4Done
  | newCellBuilt
  | branchValueWorkedOut
  | branchValueHandedOn
  /-- A name's holder moved to the user with no count changing (`RULE.md` 4, last use). -/
  | holderMoved
  /-- `let` bound a name and took the holder of `e1`'s result. -/
  | nameBound
  /-- Only in the copy that forgets the rest: a freed cell's link holder was dropped. -/
  | holderForgotten
  /-- The last snapshot of a run, after the answer is worked out; nothing happens after it. -/
  | end
  /-- Immediately before the chosen branch's expression is evaluated (D98). -/
  | branchStarts
  deriving DecidableEq, Repr

/-- The state of the run at one moment (`INTERFACE.md` 6; `RULE.md` 3). -/
structure Snapshot where
  kind : StepKind
  memory : List Cell
  bindings : List Binding
  pending : List RawValue
  outside : List (Option Addr)
  setAside : List (Nat × Addr)
  /-- The value of a finished branch, in the `branchValueWorkedOut` and
  `branchValueHandedOn` snapshots only (D98). A record only: it creates no holder and
  is never in `pending`. -/
  branchValue : Option RawValue
  deriving Repr

/-- `refused`: before running. `failedRunning`: while running, with the operation
that failed. `answer`: the raw answer (read it back with `readBack`). -/
inductive Result where
  | answer (raw : RawValue)
  | refused (why : String)
  | failedRunning (why : String)
  deriving Repr

structure Outcome where
  result : Result
  memory : Memory
  log : List LogEvent
  record : List MemEvent
  states : List Snapshot
  deriving Repr

/-! ## Program text still to run, and "last use" (`RULE.md` 4) -/

/-- Frame environments: `some id` is a binding that exists; `none` is a name that
the text will bind later (so a use of that spelling refers to the new name, not to
an outer one of the same spelling). They hold nothing. -/
abbrev FEnv := List (String × Option Nat)

/-- The environment a running expression uses: nearest binding first. -/
abbrev Env := List (String × Nat)

def toFEnv (env : Env) : FEnv := env.map (fun p => (p.1, some p.2))

/-- A piece of the program text still to run, with the environment it will run in. -/
structure Frame where
  text : Expr
  env : FEnv

def lookupF : FEnv → String → Option (Option Nat)
  | [], _ => none
  | (y, b) :: rest, x => if y = x then some b else lookupF rest x

/-- Does some free use of a spelling in this text refer to binding `id`, and not
merely to a binding with the same spelling? A `let` body and a `match` cell branch
bind their names as `none`. -/
def usesBinding : Expr → FEnv → Nat → Bool
  | .num _, _, _ => false
  | .nil, _, _ => false
  | .add a b, env, id => usesBinding a env id || usesBinding b env id
  | .sub a b, env, id => usesBinding a env id || usesBinding b env id
  | .eq a b, env, id => usesBinding a env id || usesBinding b env id
  | .lt a b, env, id => usesBinding a env id || usesBinding b env id
  | .le a b, env, id => usesBinding a env id || usesBinding b env id
  | .cons h t, env, id => usesBinding h env id || usesBinding t env id
  | .letE x b body, env, id => usesBinding b env id || usesBinding body ((x, none) :: env) id
  | .ifE c t e, env, id => usesBinding c env id || usesBinding t env id || usesBinding e env id
  | .matchE s n h t c, env, id =>
    usesBinding s env id || usesBinding n env id || usesBinding c ((t, none) :: (h, none) :: env) id
  | .var x, env, id =>
    match lookupF env x with
    | some (some i) => i == id
    | _ => false

/-- Is binding `id` used in the program text still to run (`RULE.md` 4)? -/
def usedLater (frames : List Frame) (id : Nat) : Bool :=
  frames.any (fun f => usesBinding f.text f.env id)

/-! ## The run's state -/

structure RunState where
  mem : Memory
  log : List LogEvent
  bindings : List Binding
  scope : List Nat
  pending : List RawValue
  outside : List (Option Addr)
  /-- The set-aside cells, newest first, each labelled with its branch id (`RULE.md` 3, 6e). -/
  setAside : List (Nat × Addr)
  nextBranch : Nat
  nextBinding : Nat
  snaps : List Snapshot

/-- A failure while running keeps the state up to the failure (`INTERFACE.md` 5). -/
abbrev M := ExceptT String (StateM RunState)

def snapshot (k : StepKind) (bv : Option RawValue := none) : M Unit := do
  let st ← get
  -- Every binding in scope, and every binding that still holds a holder (none is hidden by scope).
  let inScope := st.bindings.filter (fun b => st.scope.contains b.id || b.status == .holding)
  let snap : Snapshot :=
    { kind := k, memory := st.mem.cells, bindings := inScope, pending := st.pending,
      outside := st.outside, setAside := st.setAside, branchValue := bv }
  set { st with snaps := st.snaps ++ [snap] }

/-- The bindings in scope, oldest first, for the snapshots that follow. -/
def enter (env : Env) : M Unit :=
  modify fun st => { st with scope := env.reverse.map (fun p => p.2) }

def logEvent (ev : LogEvent) : M Unit :=
  modify fun st => { st with log := st.log ++ [ev] }

/-- Apply a memory operation; its failure is a failure while running. -/
def memOp (f : Memory → Except String Memory) : M Unit := do
  let st ← get
  match f st.mem with
  | .ok m => set { st with mem := m }
  | .error e => throw e

def getCell (a : Addr) : M Cell := do
  match (← get).mem.find? a with
  | some c => pure c
  | none => throw s!"cell {a} is not allocated (freed or never existed)"

def getLiveCell (a : Addr) : M Cell := do
  let c ← getCell a
  if c.status = .setAside then throw s!"cell {a} is set aside, not live" else pure c

def getBinding (id : Nat) : M Binding := do
  match (← get).bindings.find? (fun b => b.id == id) with
  | some b => pure b
  | none => throw s!"binding {id} does not exist"

def setBindingStatus (id : Nat) (s : BStatus) : M Unit :=
  modify fun st => { st with bindings := st.bindings.map (fun b => if b.id == id then { b with status := s } else b) }

def newBinding (name : String) (value : RawValue) (status : BStatus) : M Nat := do
  let st ← get
  set { st with bindings := st.bindings ++ [({ id := st.nextBinding, name := name, value := value, status := status } : Binding)],
                nextBinding := st.nextBinding + 1 }
  pure st.nextBinding

def freshBranch : M Nat := do
  let st ← get
  set { st with nextBranch := st.nextBranch + 1 }
  pure st.nextBranch

/-- An intermediate result (`RULE.md` 3, 4): a list cell's value that an expression
has produced and its surrounding part has not yet taken. It holds one holder. The
producer pushes it at the moment it produces it. -/
def pushPending (r : RawValue) : M Unit :=
  match r with
  | .list (some _) => modify fun st => { st with pending := r :: st.pending }
  | _ => pure ()

/-- The part that takes an intermediate result pops it, at the moment it takes it
(`RULE.md` 4: taking it moves the holder). The result must be the newest one. -/
def popPending (r : RawValue) : M Unit :=
  match r with
  | .list (some _) => do
    let st ← get
    match st.pending with
    | p :: rest =>
      if p == r then set { st with pending := rest }
      else throw "an intermediate result is taken out of order"
    | [] => throw "an intermediate result is taken that does not exist"
  | _ => pure ()

/-- A new holder on a live cell: its count goes up by one (`RULE.md` 4). -/
def addHolder (a : Addr) : M Unit := do
  let c ← getLiveCell a
  memOp (fun m => m.setCount a (c.count + 1))

/-- Give up one holder on a cell (`RULE.md` 4, 5; section 10, "Holder given up"):
the count goes down by one; at zero the cell is freed (the rule's log records a
free, memory releases it), and then its link gives up its holder on the rest, and
so on down the list. The cascade frees one cell per round, so it is bounded by the
number of allocated cells (the caller passes that number); running out is a
failure while running, never a default. -/
def giveUp (v : Variant) : Nat → Addr → M Unit
  | 0, a => throw s!"giving up a holder on cell {a}: the frees ran past the number of allocated cells"
  | fuel + 1, a => do
    let c ← getCell a
    if c.status = .setAside then throw s!"giving up a holder on cell {a}, which is set aside" else pure ()
    if c.count = 0 then throw s!"giving up a holder on cell {a}, whose count is already 0" else pure ()
    let n := c.count - 1
    memOp (fun m => m.setCount a n)
    snapshot .holderGivenUp
    -- Departure `freesHeld`: freed even if the count is still above zero.
    -- Otherwise the rule's own step (RULE.md 5, "Freeing"): freed when the count reaches zero.
    let freeNow := if v.freesHeld then true else n == 0
    if freeNow then
      logEvent (.free a)
      memOp (fun m => m.release a)
      -- The holder the freed cell's link had on the rest is now an intermediate result.
      pushPending (.list c.link)
      snapshot .cellFreed
      match c.link with
      | none => pure ()
      | some r =>
        popPending (.list c.link)
        -- Departure `forgetsRest`: the freed cell's link does not give up its holder.
        -- Otherwise the rule's own step (RULE.md 5, "Freeing"): it does, down the list.
        if v.forgetsRest then snapshot .holderForgotten else giveUp v fuel r
    else pure ()

/-- Give up a holder on a list (the empty list has none). -/
def giveUpLink (v : Variant) (l : Option Addr) : M Unit :=
  match l with
  | none => pure ()
  | some a => do giveUp v (← get).mem.cells.length a

/-- A binding gives up the holder it holds (`RULE.md` 4). -/
def giveUpBinding (v : Variant) (id : Nat) : M Unit := do
  let b ← getBinding id
  setBindingStatus id .givenUp
  match b.value with
  | .list l => giveUpLink v l
  | _ => pure ()

/-- Give up the holders of every name that will not be used from here on, oldest
first (`RULE.md` 6b step 3, 6c). `chosen` is the text still to run: the chosen
branch and everything after the `if` or `match`. The environment is nearest-first,
so its reverse is oldest-first. -/
def giveUpDead (v : Variant) (env : Env) (chosen : List Frame) : M Unit := do
  for (_, id) in env.reverse do
    let b ← getBinding id
    match b.value with
    | .list (some _) =>
      if b.status == .holding && !(usedLater chosen id) then giveUpBinding v id else pure ()
    | _ => pure ()

/-- Does the `match`'s step 4 set the cell aside? `count` is the cell's count after
step 3 (`RULE.md` 6b step 4).
Departure `neverReuses`: never. Departure `reusesShared`: always.
Otherwise the rule's own step (RULE.md 5, 6b): when the match's holder is the only one. -/
def shouldSetAside (v : Variant) (count : Nat) : Bool :=
  if v.neverReuses then false
  else if v.reusesShared then true
  else count == 1

/-- Build a new cell (`RULE.md` 5 "Reusing", 6d, 6e, 6f; section 10, `[h | t]`):
the newest set-aside cell (which must belong to a branch still running around the
build) is reused, or memory allocates a fresh cell. -/
def buildCell (v : Variant) (enc : List Nat) (item : Int) (link : Option Addr) : M RawValue := do
  let st ← get
  let addr ←
    match st.setAside with
    | (bid, a) :: rest => do
      if !(enc.contains bid) then
        throw s!"set-aside cell {a} belongs to a branch that has finished"
      else pure ()
      modify fun s => { s with setAside := rest }
      -- Departure `misreportsReuse`: release the set-aside cell, create a fresh cell,
      -- and log one reuse of the fresh cell's address.
      -- Otherwise the rule's own step (RULE.md 5, "Reusing"): the same cell is written
      -- in place, and the rule logs a reuse of it.
      if v.misreportsReuse then
        memOp (fun m => m.release a)
        snapshot .cellFreed
        let s2 ← get
        let (b, m2) := s2.mem.create item link
        set { s2 with mem := m2 }
        logEvent (.reuse b)
        pure b
      else
        memOp (fun m => m.writeInPlace a item link)
        logEvent (.reuse a)
        pure a
    | [] => do
      let (b, m2) := st.mem.create item link
      set { st with mem := m2 }
      logEvent (.alloc b)
      pure b
  -- `t`'s holder moves into the new cell's link; the new cell is an intermediate
  -- result holding its one holder (RULE.md 4).
  popPending (.list link)
  pushPending (.list (some addr))
  snapshot .newCellBuilt
  pure (.list (some addr))

/-- Free the branch's unused set-aside cells, newest first (`RULE.md` 5 "Disposing",
6g): each is a logged free of that cell only, nothing further given up. Each round
frees one cell of the stack, so the bound is the stack's length when it starts; a
cell of this branch left behind is a failure while running. -/
def disposeSetAside (bid : Nat) : Nat → M Unit
  | 0 => do
    if (← get).setAside.any (fun p => p.1 == bid) then
      throw s!"a set-aside cell of branch {bid} could not be freed"
    else pure ()
  | n + 1 => do
    match (← get).setAside with
    | (b, a) :: rest =>
      if b == bid then
        modify fun s => { s with setAside := rest }
        logEvent (.free a)
        memOp (fun m => m.release a)
        snapshot .cellFreed
        disposeSetAside bid n
      else disposeSetAside bid 0
    | [] => pure ()

/-- A branch finishes (`RULE.md` 6g): its value is worked out; its unused set-aside
cells are freed, newest first; then the value is handed on. A list value stays
pending throughout: whatever surrounds the `match` takes it. -/
def finishBranch (bid : Nat) (inner outer : Env) (w : RawValue) : M RawValue := do
  enter inner
  snapshot .branchValueWorkedOut (some w)
  disposeSetAside bid (← get).setAside.length
  enter outer
  snapshot .branchValueHandedOn (some w)
  pure w

def numOp (what : String) (f : Int → Int → RawValue) (x y : RawValue) : M RawValue :=
  match x, y with
  | .num p, .num q => pure (f p q)
  | _, _ => throw s!"stuck: {what} on non-numbers"

/-- The counted meaning of one expression (`RULE.md` sections 4 to 6, 10). The
arguments are: the expression, its environment, the program text still to run after
it, and the ids of the `match` branches running around it. The result is the value
worked out; a list value comes with its one holder (`RULE.md` 4). Structural
recursion on the expression. -/
def evalC (v : Variant) : Expr → Env → List Frame → List Nat → M RawValue
  | .num n, _, _, _ => pure (.num n)
  | .nil, _, _, _ => pure (.list none)
  -- 6a: operands left to right; the arithmetic itself performs no cell operation.
  | .add a b, env, fs, enc => do
    let x ← evalC v a env ({ text := b, env := toFEnv env } :: fs) enc
    let y ← evalC v b env fs enc
    numOp "+" (fun p q => .num (p + q)) x y
  | .sub a b, env, fs, enc => do
    let x ← evalC v a env ({ text := b, env := toFEnv env } :: fs) enc
    let y ← evalC v b env fs enc
    numOp "-" (fun p q => .num (p - q)) x y
  | .eq a b, env, fs, enc => do
    let x ← evalC v a env ({ text := b, env := toFEnv env } :: fs) enc
    let y ← evalC v b env fs enc
    numOp "==" (fun p q => .bool (decide (p = q))) x y
  | .lt a b, env, fs, enc => do
    let x ← evalC v a env ({ text := b, env := toFEnv env } :: fs) enc
    let y ← evalC v b env fs enc
    numOp "<" (fun p q => .bool (decide (p < q))) x y
  | .le a b, env, fs, enc => do
    let x ← evalC v a env ({ text := b, env := toFEnv env } :: fs) enc
    let y ← evalC v b env fs enc
    numOp "<=" (fun p q => .bool (decide (p ≤ q))) x y
  -- Section 10, `[h | t]`: `h`, then `t`, then take the newest set-aside cell or allocate.
  | .cons h t, env, fs, enc => do
    let hv ← evalC v h env ({ text := t, env := toFEnv env } :: fs) enc
    let tv ← evalC v t env fs enc
    enter env
    match hv, tv with
    | .num n, .list l => buildCell v enc n l
    | _, _ => throw "stuck: a cell needs a number and a list"
  -- Section 10, `let`: e1; its value goes to x; an unused x gives up at once; then e2.
  | .letE x bound body, env, fs, enc => do
    let r ← evalC v bound env ({ text := body, env := (x, none) :: toFEnv env } :: fs) enc
    let st : BStatus := match r with | .list (some _) => .holding | _ => .noHolder
    let id ← newBinding x r st
    let env' : Env := (x, id) :: env
    -- The holder of e1's result moves to x (RULE.md 4).
    popPending r
    enter env'
    if st == .holding then snapshot .nameBound else pure ()
    if st == .holding && !(usesBinding body (toFEnv env') id) then giveUpBinding v id else pure ()
    evalC v body env' fs enc
  -- Section 10, `if`; 6c: condition, choose, give up dead names oldest first, run.
  | .ifE c t e, env, fs, enc => do
    let cv ← evalC v c env ({ text := t, env := toFEnv env } :: { text := e, env := toFEnv env } :: fs) enc
    enter env
    match cv with
    | .bool true =>
      snapshot .branchChosen
      giveUpDead v env ({ text := t, env := toFEnv env } :: fs)
      enter env
      snapshot .branchStarts
      evalC v t env fs enc
    | .bool false =>
      snapshot .branchChosen
      giveUpDead v env ({ text := e, env := toFEnv env } :: fs)
      enter env
      snapshot .branchStarts
      evalC v e env fs enc
    | _ => throw "stuck: an if condition is not true or false"
  -- Section 10, `match`; 6b steps 1 to 6; 6g.
  | .matchE scrut nb h t cb, env, fs, enc => do
    let envCell : FEnv := (t, none) :: (h, none) :: toFEnv env
    -- Step 1: the matched list, with the match's holder.
    let r ← evalC v scrut env ({ text := nb, env := toFEnv env } :: { text := cb, env := envCell } :: fs) enc
    enter env
    match r with
    | .list none =>
      -- Step 2, empty-list branch; step 3; no cell, so no steps 4 and 5; step 6.
      let bid ← freshBranch
      snapshot .branchChosen
      giveUpDead v env ({ text := nb, env := toFEnv env } :: fs)
      enter env
      snapshot .branchStarts
      let w ← evalC v nb env fs (bid :: enc)
      finishBranch bid env env w
    | .list (some a) =>
      -- Step 2: the cell branch. The match's holder stays pending through steps 2 and 3.
      let _ ← getLiveCell a
      let bid ← freshBranch
      snapshot .branchChosen
      -- Step 3: give up the dead names (the match's own holder is not included).
      giveUpDead v env ({ text := cb, env := envCell } :: fs)
      -- Step 4: take the cell apart.
      let c ← getLiveCell a
      let hid ← newBinding h (.num c.item) .noHolder
      let tid ← newBinding t (.list c.link) .noHolder
      let env' : Env := (t, tid) :: (h, hid) :: env
      let tUsed := usesBinding cb (toFEnv env') tid
      if shouldSetAside v c.count then
        -- RULE.md 5, "Setting aside": set aside, no holders, contents detached, the
        -- rest's holder moves to `t`; nothing logged. The match's holder is used here.
        popPending r
        memOp (fun m => m.markSetAside a)
        modify fun s => { s with setAside := (bid, a) :: s.setAside }
        match c.link with
        | some _ => setBindingStatus tid .holding
        | none => pure ()
        enter env'
        snapshot .matchStep4Done
        -- Step 5: an unused `t` gives up the rest's holder at once.
        match c.link with
        | some _ => if !tUsed then giveUpBinding v tid else pure ()
        | none => pure ()
      else
        -- Step 4, otherwise: a used `t` gets a new holder on the rest; then the match's
        -- holder is given up.
        match c.link with
        | some rest =>
          if tUsed then
            addHolder rest
            setBindingStatus tid .holding
            enter env'
            snapshot .newHolder
          else pure ()
        | none => pure ()
        -- The match's holder is used here: popped as it is given up.
        popPending r
        giveUpLink v (some a)
        enter env'
        snapshot .matchStep4Done
      -- Step 6: run the branch.
      enter env'
      snapshot .branchStarts
      let w ← evalC v cb env' fs (bid :: enc)
      finishBranch bid env' env w
    | _ => throw "stuck: match on a non-list"
  | .var x, env, fs, _ => do
    match env.find? (fun p => p.1 == x) with
    | none => throw s!"stuck: unbound name {x}"
    | some (_, id) =>
      let b ← getBinding id
      match b.value with
      | .list (some a) =>
        if b.status != .holding then throw s!"the name {x} is used but holds nothing" else pure ()
        if usedLater fs id then
          -- RULE.md 4: used again later, so the user gets a new holder; the name keeps its own.
          addHolder a
          pushPending b.value
          enter env
          snapshot .newHolder
        else
          -- RULE.md 4: the last use; the holder moves to the user, an intermediate result.
          setBindingStatus id .movedOn
          pushPending b.value
          enter env
          snapshot .holderMoved
        pure b.value
      | val => pure val

/-- A run (`RULE.md` 7): inputs hold the holders the starting memory gave them;
inputs never used anywhere are given up first, in input order; then the program
runs with no text after it. The answer's holder is handed to the caller. -/
def runMain (v : Variant) (e : Expr) (inputs : List (String × RawValue)) : M RawValue := do
  let mut env : Env := []
  for (x, val) in inputs do
    let st : BStatus := match val with | .list (some _) => .holding | _ => .noHolder
    let id ← newBinding x val st
    env := (x, id) :: env
  enter env
  for (_, id) in env.reverse do
    let b ← getBinding id
    match b.value with
    | .list (some _) => if !(usesBinding e (toFEnv env) id) then giveUpBinding v id else pure ()
    | _ => pure ()
  snapshot .start
  let r ← evalC v e env [] []
  -- The answer stays pending: its holder is handed to the caller (RULE.md 7).
  snapshot .end
  pure r

/-- The counted meaning under a choice of switches. A program that is not
well-formed, or a starting memory that is not valid, is refused before running. -/
def runCountedWith (v : Variant) (e : Expr) (s : Start) : Outcome :=
  match validStart e s with
  | .error why => { result := .refused why, memory := {}, log := [], record := [], states := [] }
  | .ok () =>
    let st0 : RunState :=
      { mem := s.toMemory, log := [], bindings := [], scope := [], pending := [],
        outside := s.outside, setAside := [], nextBranch := 0, nextBinding := 0, snaps := [] }
    let (r, st) := ((runMain v e s.inputs).run).run st0
    { result := match r with
                | .ok raw => .answer raw
                | .error why => .failedRunning why
      memory := st.mem, log := st.log, record := st.mem.record, states := st.snaps }

end Trial
