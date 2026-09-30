import Trial
open Trial Expr

-- Lead's smoke rows for part 2 (WORKER-BRIEF.md): V1-V9, F1-F4, S1-S5, K1, K6.
-- Not acceptance criteria. Addresses: A = 1, B = 2, C = 3, Z = 99.

def sc (a : Nat) (i : Int) (l : Option Nat) (n : Nat) : StartCell :=
  { addr := a, item := i, link := l, count := n }
def w1 := matchE (var "xs") (num 0) "h" "t" (add (var "h") (var "h"))
def w5 := matchE (var "xs") nil "x" "x" nil

def V1 : Start := { cells := [sc 1 4 (some 2) 1, sc 2 9 none 1], inputs := [("xs", .list (some 1))], outside := [] }
def V2 : Start := { cells := [sc 1 4 (some 2) 2, sc 2 9 none 1], inputs := [("xs", .list (some 1))], outside := [some 1] }
def V3 : Start := { cells := [sc 1 4 (some 2) 1, sc 2 9 none 2], inputs := [("xs", .list (some 1))], outside := [] }
def V4 : Start := { cells := [sc 1 4 (some 3) 1, sc 2 9 none 1], inputs := [("xs", .list (some 1))], outside := [] }
def V5 : Start := { cells := [sc 1 4 (some 2) 1, sc 2 9 none 1, sc 3 1 none 0], inputs := [("xs", .list (some 1))], outside := [] }
def V6 : Start := { cells := [sc 1 4 (some 2) 2, sc 2 9 (some 1) 1], inputs := [("xs", .list (some 1))], outside := [] }
def V7 : Start := { cells := [sc 1 4 (some 2) 1, sc 2 9 none 1], inputs := [("xs", .num 3)], outside := [] }
def V8 : Start := { cells := [sc 1 4 (some 2) 1, sc 2 9 none 1], inputs := [("xs", .list (some 1))], outside := [some 99] }
def V9 : Start := { cells := [], inputs := [("xs", .list none)], outside := [] }

def isOk : Except String Unit → Bool | .ok _ => true | .error _ => false
#guard isOk (validStart w1 V1)
#guard isOk (validStart w1 V2)
#guard !isOk (validStart w1 V3)
#guard !isOk (validStart w1 V4)
#guard !isOk (validStart w1 V5)
#guard !isOk (validStart w1 V6)
#guard !isOk (validStart w1 V7)
#guard !isOk (validStart w1 V8)
#guard isOk (validStart w1 V9)

-- F rows
#guard (match readBack V1.toMemory (.list (some 1)) with | .ok v => v == .list [4, 9] | .error _ => false)
#guard (match readBack V1.toMemory (.list (some 99)) with | .ok _ => false | .error _ => true)
def isRefused (o : Outcome) : Bool := match o.result with | .refused _ => true | _ => false
#guard isRefused (runCounted .approved w5 V1)
#guard isRefused (runCounted .approved w1 V3)

-- General checks applied to every S run
def toPlain : Start → List (String × PlainValue)
  | s => s.inputs.map (fun (x, v) => (x, match v with
      | .num n => .num n
      | .bool b => .bool b
      | .list l => match readList s.toMemory s.cells.length l with
        | .ok xs => .list xs
        | .error _ => .list [999999])) -- never happens on valid starts
def logMatchesRecord (o : Outcome) : Bool :=
  o.log.length == o.record.length &&
  (o.log.zip o.record).all (fun (l, r) => match l, r with
    | .alloc a, .created b => a == b
    | .reuse a, .written b => a == b
    | .free a, .released b => a == b
    | _, _ => false)
def rawAddr : Result → Option Nat
  | .answer (.list l) => l
  | _ => none
def chain (cs : List Cell) : Nat → Option Nat → List Nat
  | _, none => []
  | 0, _ => []
  | n + 1, some a => match cs.find? (fun c => c.addr == a) with
    | some c => a :: chain cs n c.link
    | none => [a]
-- promise (d) on the final memory: allocated = reachable from answer + outside, counts right
def noLeak (o : Outcome) (s : Start) : Bool :=
  let cs := o.memory.cells
  let roots := (rawAddr o.result :: s.outside)
  let reach := roots.foldl (fun acc r => acc ++ chain cs cs.length r) []
  cs.all (fun c => reach.contains c.addr && c.status == .live &&
    c.count == (roots.filter (· == some c.addr)).length + (cs.filter (·.link == some c.addr)).length)
  && reach.all (fun a => cs.any (·.addr == a))
def outsideStable (o : Outcome) (s : Start) : Bool :=
  s.outside.all (fun l =>
    let orig := readList s.toMemory s.cells.length l
    o.states.all (fun sn =>
      let m : Memory := { cells := sn.memory }
      match orig, readList m sn.memory.length l with
      | .ok a, .ok b => a == b
      | _, _ => false))

-- Coherence (INTERFACE.md 6): in every snapshot, each cell's count equals the holders listed in
-- that snapshot (holding bindings, pending results, links, outside holders), and every listed
-- holder names a cell in that snapshot's memory.
def holderAddrs (sn : Snapshot) : List Nat :=
  (sn.bindings.filterMap (fun b => if b.status == .holding then (match b.value with | .list (some a) => some a | _ => none) else none))
  ++ (sn.pending.filterMap (fun r => match r with | .list (some a) => some a | _ => none))
  ++ (sn.memory.filterMap (·.link))
  ++ (sn.outside.filterMap id)
def coherent (sn : Snapshot) : Bool :=
  let hs := holderAddrs sn
  sn.memory.all (fun c => c.count == (hs.filter (· == c.addr)).length)
  && hs.all (fun a => sn.memory.any (·.addr == a))
def allCoherent (o : Outcome) : Bool := o.states.length > 0 && o.states.all coherent

def general (e : Expr) (s : Start) : Bool :=
  let o := runCounted .approved e s
  match o.result with
  | .answer raw =>
    logMatchesRecord o && noLeak o s && outsideStable o s && allCoherent o &&
    (match readBack o.memory raw, runPlain e (toPlain s) with
     | .ok a, .ok b => a == b
     | _, _ => false)
  | _ => false

def cellAt (cs : List Cell) (a : Nat) : Option Cell := cs.find? (·.addr == a)
def firstSnap (o : Outcome) (k : StepKind) : Option Snapshot := o.states.find? (·.kind == k)

-- S1 (8.1)
def s1p := matchE (var "xs") nil "h" "t" (cons (add (var "h") (var "h")) (var "t"))
def o1 := runCounted .approved s1p V1
#guard general s1p V1
#guard (match firstSnap o1 .matchStep4Done with
  | some sn => (match cellAt sn.memory 1, cellAt sn.memory 2 with
      | some a, some b => a.status == .setAside && a.count == 0 && a.link == none && b.count == 1
      | _, _ => false)
  | none => false)
#guard (o1.states.find? (·.kind == .matchStep4Done)).isSome
#guard o1.log == [.reuse 1] && o1.record == [.written 1]
#guard (match cellAt o1.memory.cells 1 with
  | some a => a.status == .live && a.count == 1 && a.item == 8 && a.link == some 2 | none => false)
#guard rawAddr o1.result == some 1
-- nothing logged or recorded before the build: the only events are the one reuse
#guard (match readBack o1.memory (.list (some 1)) with | .ok v => v == .list [8, 9] | _ => false)

-- S2 (8.2)
def o2 := runCounted .approved s1p V2
#guard general s1p V2
#guard (match firstSnap o2 .matchStep4Done with
  | some sn => (match cellAt sn.memory 1, cellAt sn.memory 2 with
      | some a, some b => a.status == .live && a.count == 1 && b.count == 2
      | _, _ => false)
  | none => false)
#guard o2.log == [.alloc 3] && o2.record == [.created 3]
#guard rawAddr o2.result == some 3
#guard (match cellAt o2.memory.cells 1, cellAt o2.memory.cells 2, cellAt o2.memory.cells 3 with
  | some a, some b, some c => a.count == 1 && b.count == 2 && c.count == 1 && c.item == 8 && c.link == some 2
  | _, _, _ => false)

-- S3 (8.3)
def s3p := letE "y" (var "xs")
  (matchE (var "xs") (num 0) "h" "t" (matchE (var "y") (var "h") "g" "u" (add (var "g") (var "h"))))
def o3 := runCounted .approved s3p V1
#guard general s3p V1
#guard (match firstSnap o3 .newHolder with
  | some sn => (match cellAt sn.memory 1 with | some a => a.count == 2 | none => false)
  | none => false)
#guard (o3.states.takeWhile (·.kind != .newHolder)).length < o3.states.length
#guard o3.result matches .answer (.num 8)
#guard o3.log == [.free 2, .free 1] && o3.memory.cells == []

-- S4 (8.4)
def o4 := runCounted .approved w1 V1
#guard general w1 V1
#guard o4.log == [.free 2, .free 1] && o4.memory.cells == []
#guard o4.result matches .answer (.num 8)
-- B is freed before the branch finishes; A still set aside when the value is worked out, gone once handed on
#guard (match firstSnap o4 .branchValueWorkedOut with
  | some sn => (match cellAt sn.memory 1 with | some a => a.status == .setAside | none => false)
               && (cellAt sn.memory 2).isNone
  | none => false)
#guard (match firstSnap o4 .branchValueHandedOn with
  | some sn => (cellAt sn.memory 1).isNone
  | none => false)

-- S5 (8.5)
def s5p := letE "n"
  (matchE (var "xs") (num 0) "h" "t" (matchE (var "t") (var "h") "g" "u" (var "g")))
  (matchE (var "xs") (var "n") "a" "b" (add (var "n") (var "a")))
def o5 := runCounted .approved s5p V1
#guard general s5p V1
#guard (match firstSnap o5 .matchStep4Done with
  | some sn => (match cellAt sn.memory 1, cellAt sn.memory 2 with
      | some a, some b => a.status == .live && a.count == 1 && b.count == 2
      | _, _ => false)
  | none => false)
#guard o5.result matches .answer (.num 13)
#guard o5.log == [.free 2, .free 1] && o5.memory.cells == []


-- X1 (lead's extra row): the cascade. Program 12345, input xs unused, memory V1.
-- RULE.md 7: the unused input is given up first; 5: A reaches 0, is freed, and its link gives up B.
def ox1 := runCounted .approved (num 12345) V1
#guard general (num 12345) V1
#guard ox1.log == [.free 1, .free 2] && ox1.record == [.released 1, .released 2] && ox1.memory.cells == []

-- X2 (lead's extra row): the match's step 3 before step 4 (6b, D85). xs and ys hold A (count 2);
-- ys is used only in the empty-list branch, so it is given up when the cell branch is chosen,
-- A is then set aside, the unused t frees B (step 5), and the build [h | []] reuses A.
def VX2 : Start :=
  { cells := [sc 1 4 (some 2) 2, sc 2 9 none 1]
    inputs := [("xs", .list (some 1)), ("ys", .list (some 1))]
    outside := [] }
def x2p := matchE (var "xs") (var "ys") "h" "t" (cons (var "h") nil)
def ox2 := runCounted .approved x2p VX2
#guard isOk (validStart x2p VX2)
#guard general x2p VX2
#guard ox2.log == [.free 2, .reuse 1] && ox2.memory.cells.length == 1

-- K1: the misreport control on S1
def k1 := runCounted .misreportsReuse s1p V1
#guard (match k1.result with
  | .answer raw => (match readBack k1.memory raw with | .ok v => v == .list [8, 9] | _ => false)
  | _ => false)
#guard (match k1.log with | [.reuse _] => true | _ => false)
#guard (match k1.record with | [.released 1, .created _] => true | _ => false)
#guard !(k1.record.any (fun e => match e with | .written _ => true | _ => false))
#guard !logMatchesRecord k1
#guard allCoherent k1
-- the release and the creation are separate snapshots
#guard (k1.states.filter (·.kind == .cellFreed)).length == 1 && (k1.states.filter (·.kind == .newCellBuilt)).length == 1
-- the oracle's example: [37 | []] from empty memory
#guard allCoherent (runCounted .approved (cons (num 37) nil) V9)

-- K6
example : runCounted .approved = runCountedWith Variant.approved := rfl

#print axioms Trial.validStart
#print axioms Trial.readBack
#print axioms Trial.runCounted
#print axioms Trial.wellFormed
#print axioms Trial.runPlain
