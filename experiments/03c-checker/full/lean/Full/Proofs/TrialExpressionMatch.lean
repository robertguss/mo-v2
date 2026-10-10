import Full.Proofs.TrialCleanup
import Full.Proofs.BranchReservations

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease TrialSimulationRelease

/-- Both choices commit the same ordered branch-chosen observation; only the
nonempty choice retains the scrutinee operand for decomposition. -/
theorem match_choose (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (empty cell : Trial.Expr) (head tail : String)
    (rest : List Task) (v : Slot) (slots : List Slot) (addr : Option Nat)
    (hr : Reachable p initial s)
    (ht : s.tasks = .chooseMatch (embed empty) head tail (embed cell) ctx :: rest)
    (hv : s.slots = v :: slots) (hraw : v.raw = .list addr)
    (ha : s.answer = none) (he : Enclosing ctx s) :
    let inner := { ctx with branches := s.nextBranch :: ctx.branches }
    let next := (match addr with
      | none => [.branchStart inner, .eval (embed empty) (child inner 1),
          .branchResult s.nextBranch inner ctx]
      | some _ => [.decompose head tail (embed cell) s.nextBranch inner]) ++ rest
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = dead s.bindings ctx.env next ++ next ∧
      t.slots = (if addr.isNone then slots else s.slots) ∧
      t.mem = s.mem ∧ t.bindings = s.bindings ∧
      t.reservations = s.reservations ∧ t.answer = none ∧
      t.nextBranch = s.nextBranch + 1 ∧
      t.landmarks = (Trial.snapshot .branchChosen none
        (observe { s with nextBranch := s.nextBranch + 1, slots := if addr.isNone then slots else s.slots, entered := ctx.env })).2.snaps ∧
      Enclosing inner t := by
  dsimp only
  let inner := { ctx with branches := s.nextBranch :: ctx.branches }
  let next := (match addr with
    | none => [.branchStart inner, .eval (embed empty) (child inner 1),
        .branchResult s.nextBranch inner ctx]
    | some _ => [.decompose head tail (embed cell) s.nextBranch inner]) ++ rest
  let c : Change := ⟨{ s with nextBranch := s.nextBranch + 1, slots := if addr.isNone then slots else s.slots, tasks := dead s.bindings ctx.env next ++ next, entered := ctx.env },
    ⟨"Choose",some .branchChosen⟩,none⟩
  have hx : advance p 1 s = .ok (commit c) := by
    cases addr <;> simp [advance, step, transition, ht, hv, hraw, ha, c, next, inner]
  refine ⟨commit c, hx, reachable_advance p initial s _ 1 hr hx,
    rfl, rfl, rfl, rfl, rfl, ha, rfl, ?_, ?_⟩
  · simpa [c, observe, pending] using commit_snapshot c .branchChosen rfl
  · intro r hr
    obtain ⟨hi, hb⟩ := he r hr
    exact ⟨hi, List.mem_cons_of_mem _ hb⟩

/-- Invocation filtering does not reorder the reservation stack.  Enclosing
reservations belong to this invocation, including reservations of older branches. -/
theorem match_reservation_filter (ctx : Context) (s : State) (bid : Nat)
    (he : Enclosing ctx s) :
    s.reservations.filter (fun r => r.invocation == ctx.invocation && r.branch == bid) =
      s.reservations.filter (fun r => r.branch == bid) := by
  apply List.filter_congr
  intro r hr
  simp [ (he r hr).1 ]

/-- The worked-out landmark keeps the literal result and all older operands;
the cleanup tasks are in reservation order. -/
theorem match_branch_result (p : Program) (initial : Trial.Start) (s : State)
    (bid : Nat) (inner outer : Context) (rest : List Task) (v : Slot) (slots : List Slot)
    (hr : Reachable p initial s) (ht : s.tasks = .branchResult bid inner outer :: rest)
    (hv : s.slots = v :: slots) (ha : s.answer = none) (he : Enclosing inner s) :
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = (s.reservations.filter (fun r => r.branch == bid)).map
        (fun r => .freeReserved r.addr) ++ [.handoffMatch outer] ++ rest ∧
      t.slots = s.slots ∧ t.mem = s.mem ∧ t.answer = none ∧
      t.reservations = s.reservations ∧
      t.landmarks = (Trial.snapshot .branchValueWorkedOut (some v.raw)
        (observe { s with entered := inner.env })).2.snaps ∧ Enclosing inner t := by
  let rs := s.reservations.filter (fun r => r.invocation == inner.invocation && r.branch == bid)
  let c : Change := ⟨{ s with entered := inner.env, tasks := rs.map (fun r => .freeReserved r.addr) ++ [.handoffMatch outer] ++ rest },
    ⟨"BranchResult",some .branchValueWorkedOut⟩,some v.raw⟩
  have hx : advance p 1 s = .ok (commit c) := by
    simp [advance, step, transition, ht, hv, ha, c, rs]
  refine ⟨commit c, hx, reachable_advance p initial s _ 1 hr hx,
    ?_, rfl, rfl, ha, rfl, ?_, he⟩
  · simpa only [c, commit, rs, match_reservation_filter inner s bid he]
  · simpa [c, observe, pending] using commit_snapshot c .branchValueWorkedOut rfl

/-- The final handoff commits the exact raw value without popping the result. -/
theorem match_handoff (p : Program) (initial : Trial.Start) (s : State)
    (outer : Context) (rest : List Task) (v : Slot) (slots : List Slot)
    (hr : Reachable p initial s) (ht : s.tasks = .handoffMatch outer :: rest)
    (hv : s.slots = v :: slots) (ha : s.answer = none) (he : Enclosing outer s) :
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.mem = s.mem ∧
      t.answer = none ∧ t.reservations = s.reservations ∧
      t.landmarks = (Trial.snapshot .branchValueHandedOn (some v.raw)
        (observe { s with entered := outer.env })).2.snaps ∧ Enclosing outer t := by
  let c : Change := ⟨{ s with tasks := rest, entered := outer.env },
    ⟨"Handoff",some .branchValueHandedOn⟩,some v.raw⟩
  have hx : advance p 1 s = .ok (commit c) := by
    simp [advance, step, transition, ht, hv, ha, c]
  refine ⟨commit c, hx, reachable_advance p initial s _ 1 hr hx,
    rfl, rfl, rfl, ha, rfl, ?_, he⟩
  simpa [c, observe, pending] using commit_snapshot c .branchValueHandedOn rfl

/-- Shared decomposition's delayed step-four landmark is a genuine machine
step; it neither releases a holder nor changes any older operand. -/
theorem match_complete (p : Program) (initial : Trial.Start) (s : State)
    (ctx : Context) (rest : List Task)
    (hr : Reachable p initial s) (ht : s.tasks = .matchComplete ctx :: rest)
    (ha : s.answer = none) (he : Enclosing ctx s) :
    ∃ t, advance p 1 s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.mem = s.mem ∧
      t.answer = none ∧ t.reservations = s.reservations ∧
      t.landmarks = (Trial.snapshot .matchStep4Done none
        (observe { s with entered := ctx.env })).2.snaps ∧ Enclosing ctx t := by
  let c : Change := ⟨{ s with tasks := rest, entered := ctx.env },
    ⟨"MatchComplete",some .matchStep4Done⟩,none⟩
  have hx : advance p 1 s = .ok (commit c) := by
    simp [advance, step, transition, ht, ha, c]
  refine ⟨commit c, hx, reachable_advance p initial s _ 1 hr hx,
    rfl, rfl, rfl, ha, rfl, ?_, he⟩
  simpa [c, observe, pending] using commit_snapshot c .matchStep4Done rfl

end Full.Proofs.TrialExecution

#print axioms Full.Proofs.TrialExecution.match_choose
#print axioms Full.Proofs.TrialExecution.match_reservation_filter
#print axioms Full.Proofs.TrialExecution.match_branch_result
#print axioms Full.Proofs.TrialExecution.match_handoff
#print axioms Full.Proofs.TrialExecution.match_complete
