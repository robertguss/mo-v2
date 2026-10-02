import Promises
open Trial Expr

-- Approved, pre-proof smoke inputs K2–K5, WORKER-BRIEF.md lines 330–333.
def V1 : Start := {
  cells := [{ addr := 1, item := 4, link := some 2, count := 1 },
            { addr := 2, item := 9, link := none, count := 1 }]
  inputs := [("xs", .list (some 1))]
  outside := [] }
def V2 : Start := {
  cells := [{ addr := 1, item := 4, link := some 2, count := 2 },
            { addr := 2, item := 9, link := none, count := 1 }]
  inputs := [("xs", .list (some 1))]
  outside := [some 1] }
def program := matchE (var "xs") nil "h" "t"
  (cons (add (var "h") (var "h")) (var "t"))
def discarded := num 12345

#eval validStart program V2
#eval validStart discarded V1
#eval validStart program V1
#guard validStart program V2 = .ok ()
#guard validStart discarded V1 = .ok ()
#guard validStart program V1 = .ok ()

#eval ("approved C", decide (NoVisibleChange V2 (runCounted .approved program V2)))
#eval ("approved D", decide (NoLeak V1 (runCounted .approved discarded V1)))
#eval ("K2 C", decide (NoVisibleChange V2 (runCounted .reusesShared program V2)))
#eval ("K3 D", decide (NoLeak V1 (runCounted .forgetsRest discarded V1)))
#eval ("K4 C", decide (NoVisibleChange V2 (runCounted .freesHeld program V2)))
#guard decide (NoVisibleChange V2 (runCounted .approved program V2))
#guard decide (NoLeak V1 (runCounted .approved discarded V1))
#guard !decide (NoVisibleChange V2 (runCounted .reusesShared program V2))
#guard !decide (NoLeak V1 (runCounted .forgetsRest discarded V1))
#guard !decide (NoVisibleChange V2 (runCounted .freesHeld program V2))

#eval (runCounted .reusesShared program V2).states.map
  (fun sn => (sn.kind, readBack (snapMemory sn) (.list (some 1))))
#eval (runCounted .forgetsRest discarded V1).memory.cells
#eval (runCounted .freesHeld program V2).states.map
  (fun sn => (sn.kind, readBack (snapMemory sn) (.list (some 1))))
#eval finalAnswer (runCounted .neverReuses program V1)
#eval (runCounted .neverReuses program V1).record
#guard finalAnswer (runCounted .neverReuses program V1) = .ok (.list [8, 9])
