import Proofs.LiveBindings

namespace Trial.Proofs

/-- The final ownership obligations imply the exact locked leak predicate.
The evaluator still has to establish that no binding holds, no reserved cell
remains, and the answer is the only pending result. -/
theorem final_no_leak (s : Start) (t : RunState) (raw : RawValue)
    (hh : Owned t)
    (hbindings : ∀ b ∈ t.bindings, b.status ≠ .holding)
    (htracked : ∀ c ∈ t.mem.cells, c.status = .setAside →
      ∃ bid, (bid, c.addr) ∈ t.setAside)
    (hstack : t.setAside = [])
    (hpending : t.pending = match raw with | .list (some _) => [raw] | _ => [])
    (hout : t.outside = s.outside) :
    NoLeakAt t.mem (answerRoots raw s) := by
  have hb : bindingRoots t.bindings = [] := by
    apply List.filterMap_eq_nil_iff.mpr
    intro b hb
    simp [hbindings b hb]
  have hl : ∀ c ∈ t.mem.cells, c.status = .live := by
    intro c hc
    cases hs : c.status with
    | live => rfl
    | setAside =>
      obtain ⟨bid, hbid⟩ := htracked c hc hs
      simp [hstack] at hbid
  have hn := hh.no_leak hl
  have hr : ownedRoots t = answerRoots raw s := by
    cases raw with
    | num n | bool n => simp [ownedRoots, hb, hpending, hout, answerRoots]
    | list r => cases r <;> simp [ownedRoots, hb, hpending, hout, answerRoots, valueRoot]
  simpa [hr] using hn

/-- Successful execution of the actual runMain gives the actual public
approved outcome. This exposes no alternative evaluator or default answer. -/
theorem counted_of_main (e : Expr) (s : Start) (raw : RawValue) (t : RunState)
    (hv : validStart e s = .ok ())
    (hr : runMain Variant.approved e s.inputs
      { mem := s.toMemory, log := [], bindings := [], scope := [], pending := [],
        outside := s.outside, setAside := [], nextBranch := 0, nextBinding := 0, snaps := [] } =
      (.ok raw, t)) :
    runCounted .approved e s =
      { result := .answer raw, memory := t.mem, log := t.log,
        record := t.mem.record, states := t.snaps } := by
  simp [runCounted, Rule.variant, runCountedWith, hv, StateT.run, ExceptT.run, hr]

end Trial.Proofs
