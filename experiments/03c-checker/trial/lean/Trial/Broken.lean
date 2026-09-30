import Trial.Counted

/-!
# The named choices of rule (`INTERFACE.md` 7)

The approved rule and the five deliberately broken copies. Each broken copy is the
approved rule with exactly one switch of `Variant` turned on.
-/

namespace Trial

inductive Rule where
  /-- The approved rule (D91). -/
  | approved
  /-- Frees a cell and builds a replacement, but logs a reuse (the misreport control). -/
  | misreportsReuse
  /-- Reuses a cell someone else holds. -/
  | reusesShared
  /-- Forgets to give up the rest of a freed cell. -/
  | forgetsRest
  /-- Frees a cell that still has a holder. -/
  | freesHeld
  /-- Never reuses. -/
  | neverReuses
  deriving DecidableEq, Repr

def Rule.variant : Rule → Variant
  | .approved => Variant.approved
  | .misreportsReuse => { Variant.approved with misreportsReuse := true }
  | .reusesShared => { Variant.approved with reusesShared := true }
  | .forgetsRest => { Variant.approved with forgetsRest := true }
  | .freesHeld => { Variant.approved with freesHeld := true }
  | .neverReuses => { Variant.approved with neverReuses := true }

/-- Run a program under the counted meaning, by a named choice of rule. -/
def runCounted (r : Rule) (e : Expr) (s : Start) : Outcome :=
  runCountedWith r.variant e s

end Trial
