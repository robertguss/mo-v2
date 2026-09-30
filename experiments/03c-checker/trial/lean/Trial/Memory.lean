import Trial.Language
import Trial.Plain

/-!
# Counted memory, starting memories, and reading a list back

`RULE.md` section 3 ("What a counted run keeps track of": memory, cells with an
address, an item, a link, a holder count and a status) and `INTERFACE.md`
sections 3 and 5. Memory keeps its own record of the three primitive things it
does (a fresh cell created, a cell written in place, a cell released). Only the
operations `Memory.create`, `Memory.writeInPlace` and `Memory.release` add to
that record. Changing a count, setting a cell aside and detaching its contents
are recorded as none of the three.
-/

namespace Trial

/-- Addresses are natural numbers. -/
abbrev Addr := Nat

/-- A value a run works out, or an input is given (`RULE.md` 3): a number, true or
false, or a list, which is either the empty list (`none`: not a cell, nothing
holds it) or the address of its first cell. -/
inductive RawValue where
  | num (n : Int)
  | bool (b : Bool)
  | list (l : Option Addr)
  deriving DecidableEq, Repr

/-- The kind a raw value has. -/
def RawValue.kind : RawValue → Kind
  | .num _ => .number
  | .bool _ => .bool
  | .list _ => .list

/-- A cell is live or set aside (`RULE.md` 3). -/
inductive Status where
  | live
  | setAside
  deriving DecidableEq, Repr

/-- One cell of memory (`RULE.md` 3): address, item, link (the rest of the list:
another cell's address, or `none` for the empty list), holder count, status. -/
structure Cell where
  addr : Addr
  item : Int
  link : Option Addr
  count : Nat
  status : Status
  deriving DecidableEq, Repr

/-- What memory itself did (`INTERFACE.md` 5: the memory's own record). -/
inductive MemEvent where
  | created (a : Addr)
  | written (a : Addr)
  | released (a : Addr)
  deriving DecidableEq, Repr

/-- Memory: the allocated cells, the counter for fresh addresses, and memory's own
record. Fresh addresses come from the counter, which starts above every address
in the starting memory and only increases, so a freed address is never handed
out again. A freed cell is no longer part of `cells`. -/
structure Memory where
  cells : List Cell := []
  next : Nat := 0
  record : List MemEvent := []
  deriving Repr

def Memory.find? (m : Memory) (a : Addr) : Option Cell :=
  m.cells.find? (fun c => c.addr == a)

/-- Change one cell in place; changes nothing if there is no such cell. Not itself
a recorded operation: used only for counts and statuses. -/
def Memory.updateCell (m : Memory) (a : Addr) (f : Cell → Cell) : Memory :=
  { m with cells := m.cells.map (fun c => if c.addr == a then f c else c) }

/-- Create a fresh cell: live, count 1. Recorded as created. -/
def Memory.create (m : Memory) (item : Int) (link : Option Addr) : Addr × Memory :=
  let a := m.next
  (a, { cells := m.cells ++ [{ addr := a, item := item, link := link, count := 1, status := .live }]
        next := m.next + 1
        record := m.record ++ [.created a] })

/-- Write a set-aside cell in place with a new item and link: it becomes live with
count 1 (`RULE.md` 5, "Reusing"). Recorded as written. -/
def Memory.writeInPlace (m : Memory) (a : Addr) (item : Int) (link : Option Addr) :
    Except String Memory :=
  match m.find? a with
  | none => throw s!"write in place: cell {a} is not allocated"
  | some c =>
    if c.status = .setAside then
      pure { m.updateCell a (fun _ => { addr := a, item := item, link := link, count := 1, status := .live })
             with record := m.record ++ [.written a] }
    else throw s!"write in place: cell {a} is not set aside"

/-- Release a cell: it is no longer part of memory. Recorded as released. -/
def Memory.release (m : Memory) (a : Addr) : Except String Memory :=
  match m.find? a with
  | none => throw s!"release: cell {a} is not allocated"
  | some _ =>
    pure { m with cells := m.cells.filter (fun c => c.addr != a)
                  record := m.record ++ [.released a] }

/-- Set a cell aside (`RULE.md` 5, "Setting aside"): status set aside, no holders
(count 0), old contents detached (the link is cleared; the holder it had moves to
the name for the rest, which the caller arranges). Not recorded. -/
def Memory.markSetAside (m : Memory) (a : Addr) : Except String Memory :=
  match m.find? a with
  | none => throw s!"set aside: cell {a} is not allocated"
  | some _ => pure (m.updateCell a (fun c => { c with status := .setAside, count := 0, link := none }))

/-- Change a cell's holder count. Not recorded. -/
def Memory.setCount (m : Memory) (a : Addr) (n : Nat) : Except String Memory :=
  match m.find? a with
  | none => throw s!"holder count: cell {a} is not allocated"
  | some _ => pure (m.updateCell a (fun c => { c with count := n }))

/-! ## Reading a list back (`INTERFACE.md` 4 and 5) -/

/-- Follow links from an address into a list of numbers. The walk is bounded by the
number of cells: a readable list visits distinct allocated cells, so it needs at
most that many steps; more steps mean a cycle. Running out is an error, never the
empty list. A missing cell or a set-aside cell is unreadable, with the reason. -/
def readList (m : Memory) : Nat → Option Addr → Except String (List Int)
  | _, none => pure []
  | n, some a =>
    match m.find? a with
    | none => throw s!"unreadable: cell {a} is not allocated"
    | some c =>
      if c.status = .setAside then throw s!"unreadable: cell {a} is set aside"
      else
        match n with
        | 0 => throw s!"unreadable: the list from cell {a} runs past the number of cells (a cycle)"
        | k + 1 => do
          let rest ← readList m k c.link
          pure (c.item :: rest)

/-- The raw answer followed through memory into a plain value, or "unreadable" with
the reason (`INTERFACE.md` 5). -/
def readBack (m : Memory) : RawValue → Except String PlainValue
  | .num n => pure (.num n)
  | .bool b => pure (.bool b)
  | .list l => do pure (.list (← readList m m.cells.length l))

/-! ## Starting memories (`INTERFACE.md` 3) -/

/-- A cell of a starting memory: address, item, link, holder count. -/
structure StartCell where
  addr : Addr
  item : Int
  link : Option Addr
  count : Nat
  deriving DecidableEq, Repr

/-- A starting memory: the cells, the inputs in order (a name with its value), and
the outside holders (each the empty list, which holds nothing, or a cell's address). -/
structure Start where
  cells : List StartCell
  inputs : List (String × RawValue)
  outside : List (Option Addr)
  deriving Repr

/-- The memory a run starts from: every cell live, the counter above every address. -/
def Start.toMemory (s : Start) : Memory :=
  { cells := s.cells.map (fun c => { addr := c.addr, item := c.item, link := c.link, count := c.count, status := .live })
    next := s.cells.foldl (fun acc c => max acc (c.addr + 1)) 0
    record := [] }

def dupAddr : List StartCell → Option Addr
  | [] => none
  | c :: rest => if rest.any (fun d => d.addr == c.addr) then some c.addr else dupAddr rest

/-- The addresses met walking from a link, bounded like `readList`. Used only after
the dangling and cycle checks have passed. -/
def chainAddrs (cells : List StartCell) : Nat → Option Addr → List Addr
  | _, none => []
  | 0, some _ => []
  | n + 1, some a =>
    match cells.find? (fun c => c.addr == a) with
    | none => [a]
    | some c => a :: chainAddrs cells n c.link

/-- Does the walk from a link reach the empty list? Bounded by the number of cells:
with distinct addresses an acyclic walk has at most that many cells, so running
out of steps means a cycle (or a dangling link, reported separately). -/
def chainEnds (cells : List StartCell) : Nat → Option Addr → Bool
  | _, none => true
  | 0, some _ => false
  | n + 1, some a =>
    match cells.find? (fun c => c.addr == a) with
    | none => false
    | some c => chainEnds cells n c.link

def linkNames (l : Option Addr) (a : Addr) : Bool :=
  match l with
  | some b => b == a
  | none => false

/-- Is the starting memory valid for the program (`PLAN.md`, "What the promises
cover"; `INTERFACE.md` 3)? The program must be well-formed for the kinds the inputs
have (so an input of the wrong kind is refused, with the reason); no two cells
share an address; nothing dangles; no cycles; every cell is reachable from an
input or an outside holder; every holder count equals the number of holders the
cell actually has (inputs, links from cells, outside holders). -/
def validStart (e : Expr) (s : Start) : Except String Unit := do
  let _ ← wellFormed (s.inputs.map (fun p => (p.1, p.2.kind))) e
  match dupAddr s.cells with
  | some a => throw s!"two cells share the address {a}"
  | none => pure ()
  let inputLinks : List (Option Addr) :=
    s.inputs.filterMap (fun p => match p.2 with | .list l => some l | _ => none)
  let roots := inputLinks ++ s.outside
  let exists_ := fun (a : Addr) => s.cells.any (fun c => c.addr == a)
  for c in s.cells do
    match c.link with
    | some b => if !(exists_ b) then throw s!"cell {c.addr} links to {b}, which does not exist" else pure ()
    | none => pure ()
  for r in roots do
    match r with
    | some b => if !(exists_ b) then throw s!"an input or outside holder names {b}, which does not exist" else pure ()
    | none => pure ()
  let n := s.cells.length
  for c in s.cells do
    if !(chainEnds s.cells n (some c.addr)) then throw s!"the links from cell {c.addr} form a cycle"
    else pure ()
  let reached := roots.foldl (fun acc r => acc ++ chainAddrs s.cells n r) []
  for c in s.cells do
    if !(reached.contains c.addr) then
      throw s!"cell {c.addr} is unreachable from every input and outside holder"
    else pure ()
  for c in s.cells do
    let holders :=
      (inputLinks.filter (fun l => linkNames l c.addr)).length
      + (s.cells.filter (fun d => linkNames d.link c.addr)).length
      + (s.outside.filter (fun l => linkNames l c.addr)).length
    if holders != c.count then
      throw s!"cell {c.addr} has count {c.count} but {holders} holders"
    else pure ()

end Trial
