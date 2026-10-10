import Full.Proofs.TrialExecution
import Full.Proofs.Free
import Proofs.Release

namespace Full.Proofs.TrialRelease
open TrialCompatibilitySimulation

/-- Only the textual rule log is outside F6. Memory (including its record) and
the complete ordered snapshot list are retained literally. -/
def eraseLog (s : Trial.RunState) : Trial.RunState := { s with log := [] }

def logged (s : Counted.State) (log : List Trial.LogEvent) : Trial.RunState :=
  { observe s with log := log }

def giveChange (s : Counted.State) (a : Nat) (c : Trial.Cell)
    (rest : List Counted.Task) (slots : List Counted.Slot) : Counted.Change :=
  ⟨{ s with
    mem := s.mem.updateCell a (fun d => { d with count := c.count-1 }),
    slots := slots, releaseChain := if c.count == 1 then s.releaseChain ++ [a] else [],
    tasks := if c.count == 1 then .free a :: rest else rest },
    ⟨"GiveUp",some .holderGivenUp⟩,none⟩

theorem pending_transition (p : Program) (s : Counted.State) (a : Nat)
    (c : Trial.Cell) (v : Counted.Slot) (slots : List Counted.Slot)
    (rest : List Counted.Task)
    (ht : s.tasks = .givePending :: rest) (hs : s.slots = v :: slots)
    (hv : v.raw = .list (some a)) (hf : s.mem.find? a = some c)
    (hl : c.status = .live) (hn : c.count ≠ 0) :
    Counted.transition p s = .ok (giveChange s a c rest slots) := by
  simp [Counted.transition, ht, hs, hv, hf, hl, hn,
    Trial.Memory.setCount, giveChange]

theorem give_observe (s : Counted.State) (a : Nat) (c : Trial.Cell)
    (rest : List Counted.Task) (slots : List Counted.Slot)
    (log : List Trial.LogEvent) :
    logged (Counted.commit (giveChange s a c rest slots)) log =
      (Trial.snapshot .holderGivenUp none
        { logged s log with
          mem := s.mem.updateCell a (fun d => { d with count := c.count-1 }),
          pending := Counted.pending { s with slots := slots } }).2 := by
  have h := commit_snapshot (giveChange s a c rest slots) .holderGivenUp rfl
  simp only [Trial.snapshot] at h
  simp only [logged, observe, Counted.commit, giveChange] at h ⊢
  rw [h]
  rfl

def freeChange (s : Counted.State) (a : Nat) (c : Trial.Cell)
    (tail : Value) (rest : List Counted.Task) : Counted.Change :=
  ⟨{ s with
    mem := { s.mem with cells := s.mem.cells.filter (fun d => d.addr != a),
                         record := s.mem.record ++ [.released a] },
    edges := s.edges.filter (fun q => q.1 != a),
    slots := if c.link.isSome then ⟨.list c.link,tail⟩ :: s.slots else s.slots,
    releaseChain := if c.link.isSome then s.releaseChain else [],
    tasks := if c.link.isSome then .givePending :: rest else rest,
    events := s.events ++ [.free a] },⟨"Free",some .cellFreed⟩,none⟩

theorem free_observe (s : Counted.State) (a : Nat) (c : Trial.Cell)
    (tail : Value) (rest : List Counted.Task) (log : List Trial.LogEvent) :
    logged (Counted.commit (freeChange s a c tail rest)) (log ++ [.free a]) =
      (Trial.snapshot .cellFreed none
        (Trial.pushPending (.list c.link)
          { logged s (log ++ [.free a]) with
            mem := { s.mem with cells := s.mem.cells.filter (fun d => d.addr != a),
                                record := s.mem.record ++ [.released a] } }).2).2 := by
  have h := commit_snapshot (freeChange s a c tail rest) .cellFreed rfl
  cases hc : c.link <;>
    simp [Trial.snapshot, Trial.pushPending, freeChange, Counted.pending,
      logged, observe, Counted.commit, hc] at h ⊢ <;> rw [h]

/-- The edge prerequisite is supplied by the existing frozen invariant; it is
not discarded just because Trial's raw release does not inspect ghost edges. -/
theorem edge_from_invariant (initial : Trial.Start) (s : Counted.State)
    (a : Nat) (c : Trial.Cell) (hi : Inspect.invariant initial s = true)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) :
    ∃ tail, s.edges.find? (fun q => q.1 == a) = some (a,tail) ∧
      Inspect.readable s ⟨.list c.link,tail⟩ = true := by
  have ha : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Trial.Cell => c.addr == a) hf)
  obtain ⟨tail, he, hr⟩ := invariant_live_edge initial s hi c
    (List.mem_of_find?_eq_some hf) hl
  exact ⟨tail, ha ▸ he, hr⟩

def input (s : Counted.State) (slots : List Counted.Slot)
    (log : List Trial.LogEvent) : Trial.RunState :=
  { logged s log with pending := Counted.pending { s with slots := slots } }

theorem trial_shared (s : Counted.State) (a : Nat) (c : Trial.Cell)
    (rest : List Counted.Task) (slots : List Counted.Slot)
    (log : List Trial.LogEvent) (fuel : Nat)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hn : 2 ≤ c.count) :
    Trial.giveUp .approved (fuel+1) a (input s slots log) =
      (.ok (), logged (Counted.commit (giveChange s a c rest slots)) log) := by
  rw [give_observe]
  have hn0 : c.count ≠ 0 := by omega
  have hn1 : c.count - 1 ≠ 0 := by omega
  simp [Trial.giveUp, Trial.getCell, Trial.memOp, Trial.Memory.setCount,
    Trial.snapshot, Trial.Variant.approved, input, logged, observe, hf, hl, hn0, hn1]

theorem trial_exclusive (s : Counted.State) (a : Nat) (c : Trial.Cell)
    (tail : Value) (rest : List Counted.Task) (slots : List Counted.Slot)
    (log : List Trial.LogEvent) (fuel : Nat)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hn : c.count = 1) :
    let g := Counted.commit (giveChange s a c rest slots)
    let f := Counted.commit (freeChange g a { c with count := 0 } tail rest)
    Trial.giveUp .approved (fuel+1) a (input s slots log) =
      match c.link with
      | none => (.ok (), logged f (log ++ [.free a]))
      | some b => Trial.giveUp .approved fuel b (input f slots (log ++ [.free a])) := by
  dsimp only
  have ha : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Trial.Cell => c.addr == a) hf)
  have hz : (s.mem.updateCell a (fun d => { d with count := 0 })).find? a =
      some { c with count := 0 } := by
    rw [Trial.Proofs.find_update s.mem a a _ (by intro d _; rfl)]
    simp [hf, ha]
  have hfilter := Trial.Proofs.filter_count_update s.mem.cells a 0
  cases hc : c.link <;>
    simp [Trial.giveUp, Trial.getCell, Trial.memOp, Trial.Memory.setCount,
      Trial.snapshot, Trial.Variant.approved, Trial.Memory.release, Trial.logEvent,
      Trial.pushPending, Trial.popPending, input, logged, observe, hf, hl, hn, hz,
      giveChange, freeChange, Counted.commit, Counted.pending, hc,
      ← visible_projection]
  all_goals simp only [Trial.Memory.updateCell, hfilter]

theorem exclusive_steps (p : Program) (s : Counted.State) (a : Nat)
    (c : Trial.Cell) (tail : Value) (rest : List Counted.Task)
    (v : Counted.Slot) (slots : List Counted.Slot)
    (ht : s.tasks = .givePending :: rest) (hs : s.slots = v :: slots)
    (hv : v.raw = .list (some a)) (ha : s.answer = none)
    (hf : s.mem.find? a = some c) (hl : c.status = .live) (hn : c.count = 1)
    (he : s.edges.find? (fun q => q.1 == a) = some (a,tail)) :
    let g := Counted.commit (giveChange s a c rest slots)
    let f := Counted.commit (freeChange g a { c with count := 0 } tail rest)
    Counted.advance p 2 s = .ok f := by
  have hgive := pending_transition p s a c v slots rest ht hs hv hf hl (by omega)
  let g := Counted.commit (giveChange s a c rest slots)
  have haddr : c.addr = a := by
    simpa using (List.find?_some (p := fun c : Trial.Cell => c.addr == a) hf)
  have hfind : g.mem.find? a = some { c with count := 0 } := by
    dsimp [g, Counted.commit, giveChange]
    rw [hn]
    rw [Trial.Proofs.find_update s.mem a a _ (by intro d _; rfl)]
    simp [hf, haddr]
  have hfree := free_transition p g a { c with count := 0 } tail rest
    (by simp [g, Counted.commit, giveChange, hn]) hfind hl rfl he
  change Counted.transition p g = .ok (freeChange g a { c with count := 0 } tail rest) at hfree
  have hga : (Counted.commit (giveChange s a c rest slots)).answer = none := ha
  dsimp only [g] at hfree
  simp [Counted.advance, Counted.step, ha, hgive, hga, hfree]

/-- A bounded raw release path. Its premises are only local heap facts and
immutable readable edges, recursively in the explicitly calculated successor.
There is no Full execution or observation equality in this certificate. -/
inductive Cascade (rest : List Counted.Task) (slots : List Counted.Slot) :
    Nat → Counted.State → Nat → Prop where
  | shared (s : Counted.State) (a : Nat) (c : Trial.Cell) (fuel : Nat)
      (hf : s.mem.find? a = some c) (hl : c.status = .live) (hn : 2 ≤ c.count) :
      Cascade rest slots (fuel+1) s a
  | last (s : Counted.State) (a : Nat) (c : Trial.Cell) (tail : Value) (fuel : Nat)
      (hf : s.mem.find? a = some c) (hl : c.status = .live) (hn : c.count = 1)
      (he : s.edges.find? (fun q => q.1 == a) = some (a,tail))
      (hr : Inspect.readable s ⟨.list c.link,tail⟩ = true) (ht : c.link = none) :
      Cascade rest slots (fuel+1) s a
  | next (s : Counted.State) (a b : Nat) (c : Trial.Cell) (tail : Value) (fuel : Nat)
      (hf : s.mem.find? a = some c) (hl : c.status = .live) (hn : c.count = 1)
      (he : s.edges.find? (fun q => q.1 == a) = some (a,tail))
      (hr : Inspect.readable s ⟨.list c.link,tail⟩ = true) (ht : c.link = some b)
      (more : Cascade rest slots fuel
        (Counted.commit (freeChange (Counted.commit (giveChange s a c rest slots))
          a { c with count := 0 } tail rest)) b) :
      Cascade rest slots (fuel+1) s a

theorem advance_add (p : Program) (n k : Nat) (s : Counted.State) :
    Counted.advance p (n+k) s =
      (Counted.advance p n s >>= Counted.advance p k) := by
  induction n generalizing s with
  | zero => simp [Counted.advance]
  | succ n ih =>
    simp only [Nat.succ_add, Counted.advance]
    cases ha : s.answer.isSome <;> simp [ih]
    induction k with
    | zero => rfl
    | succ k _ => simp [Counted.advance, ha]

theorem cascade_pending (p : Program) (rest : List Counted.Task)
    (slots : List Counted.Slot) (fuel : Nat) (s : Counted.State) (a : Nat)
    (path : Cascade rest slots fuel s a)
    (v : Counted.Slot) (ht : s.tasks = .givePending :: rest)
    (hs : s.slots = v :: slots) (hv : v.raw = .list (some a))
    (ha : s.answer = none) (log : List Trial.LogEvent) :
    ∃ ticks t finalLog, Counted.advance p ticks s = .ok t ∧
      t.tasks = rest ∧ t.slots = slots ∧ t.answer = none ∧
      Trial.giveUp .approved fuel a (input s slots log) = (.ok (), logged t finalLog) ∧
      0 < ticks ∧ ticks ≤ 2*fuel ∧ t.bindings = s.bindings ∧
      t.reservations = s.reservations := by
  induction path generalizing v log with
  | shared s a c fuel hf hl hn =>
    refine ⟨1, Counted.commit (giveChange s a c rest slots), log, ?_, ?_, rfl, ha,
      trial_shared s a c rest slots log fuel hf hl hn, by omega, by omega, rfl, rfl⟩
    · have h := pending_transition p s a c v slots rest ht hs hv hf hl (by omega)
      simp [Counted.advance, Counted.step, ha, h]
    · have hne : c.count ≠ 1 := by omega
      simp [Counted.commit, giveChange, hne]
  | last s a c tail fuel hf hl hn he hr hc =>
    let g := Counted.commit (giveChange s a c rest slots)
    let f := Counted.commit (freeChange g a { c with count := 0 } tail rest)
    refine ⟨2, f, log ++ [.free a],
      exclusive_steps p s a c tail rest v slots ht hs hv ha hf hl hn he,
      ?_, ?_, ha, ?_, by omega, by omega, rfl, rfl⟩
    · simp [f, g, Counted.commit, freeChange, hc]
    · simp [f, g, Counted.commit, freeChange, giveChange, hc]
    · simpa [f, g, hc] using trial_exclusive s a c tail rest slots log fuel hf hl hn
  | next s a b c tail fuel hf hl hn he hr hc more ih =>
    let g := Counted.commit (giveChange s a c rest slots)
    let f := Counted.commit (freeChange g a { c with count := 0 } tail rest)
    obtain ⟨ticks, t, finalLog, hex, ht', hs', ha', htrial, hpos, hbound, hbs, hrs⟩ :=
      ih ⟨.list c.link,tail⟩
        (by simp [Counted.commit, freeChange, hc])
        (by simp [Counted.commit, freeChange, giveChange, hc])
        (by simp [hc]) ha (log ++ [.free a])
    refine ⟨2+ticks, t, finalLog, ?_, ht', hs', ha', ?_, by omega, by omega, hbs, hrs⟩
    · rw [advance_add, exclusive_steps p s a c tail rest v slots ht hs hv ha hf hl hn he]
      exact hex
    · rw [trial_exclusive s a c tail rest slots log fuel hf hl hn]
      simpa [hc] using htrial

/-- Extra information that Trial cannot supply: readable immutable ghost edges
at the calculated free boundaries. No count, liveness, success, transition or
landmark equality is assumed by this predicate. -/
def Ready (rest : List Counted.Task) (slots : List Counted.Slot) :
    Nat → Counted.State → Nat → Prop
  | 0, _, _ => True
  | fuel+1, s, a =>
    ∀ c, s.mem.find? a = some c → c.count = 1 →
      ∃ tail, s.edges.find? (fun q => q.1 == a) = some (a,tail) ∧
        Inspect.readable s ⟨.list c.link,tail⟩ = true ∧
        match c.link with
        | none => True
        | some b => Ready rest slots fuel
            (Counted.commit (freeChange (Counted.commit (giveChange s a c rest slots))
              a { c with count := 0 } tail rest)) b

/-- Actual successful Trial execution supplies every raw heap/count premise of
the finite certificate. The remaining Ready premise is precisely the ghost-edge
information absent from Trial, not a future Full correctness hypothesis. -/
theorem cascade_of_success (rest : List Counted.Task) (slots : List Counted.Slot)
    (fuel : Nat) (s : Counted.State) (a : Nat) (log : List Trial.LogEvent)
    (u : Trial.RunState)
    (hsuccess : Trial.giveUp .approved fuel a (input s slots log) = (.ok (), u))
    (hready : Ready rest slots fuel s a) : Cascade rest slots fuel s a := by
  induction fuel generalizing s a log u with
  | zero =>
    simp [Trial.giveUp] at hsuccess
    have h := congrArg Prod.fst hsuccess
    contradiction
  | succ fuel ih =>
    cases hf : s.mem.find? a with
    | none =>
      simp [Trial.giveUp, Trial.getCell, input, logged, observe, hf] at hsuccess
      have h := congrArg Prod.fst hsuccess
      contradiction
    | some c =>
      have hl : c.status = .live := by
        cases hc : c.status with
        | live => rfl
        | setAside =>
          simp [Trial.giveUp, Trial.getCell, input, logged, observe, hf, hc] at hsuccess
          have h := congrArg Prod.fst hsuccess
          contradiction
      have hn : c.count ≠ 0 := by
        intro hn
        simp [Trial.giveUp, Trial.getCell, input, logged, observe, hf, hl, hn] at hsuccess
        have h := congrArg Prod.fst hsuccess
        contradiction
      by_cases hone : c.count = 1
      · obtain ⟨tail, he, hr, hnext⟩ := hready c hf hone
        rw [trial_exclusive s a c tail rest slots log fuel hf hl hone] at hsuccess
        cases hc : c.link with
        | none => exact .last s a c tail fuel hf hl hone he hr hc
        | some b =>
          simp only [hc] at hsuccess hnext
          apply Cascade.next s a b c tail fuel hf hl hone he hr hc
          apply ih _ _ (log ++ [.free a]) u
          · simpa only [hc] using hsuccess
          · simpa only [hc] using hnext
      · exact .shared s a c fuel hf hl (by omega)

def bindingInput (s : Counted.State) (id : Nat) (b : Counted.Binding)
    (rest : List Counted.Task) : Counted.State :=
  { s with
    bindings := s.bindings.map (fun q => if q.record.id == id then
      { q with record := { q.record with status := .givenUp } } else q),
    slots := ⟨b.record.value,b.value⟩ :: s.slots,
    tasks := .givePending :: rest }

theorem binding_first (p : Program) (s : Counted.State) (id : Nat)
    (b : Counted.Binding) (rest : List Counted.Task)
    (ht : s.tasks = .giveBinding id :: rest)
    (hb : s.bindings.find? (fun q => q.record.id == id) = some b)
    (hh : b.record.status = .holding) :
    Counted.transition p s = Counted.transition p (bindingInput s id b rest) := by
  simp [Counted.transition, ht, hb, hh, bindingInput]

theorem binding_trial (s : Counted.State) (id : Nat) (b : Counted.Binding)
    (rest : List Counted.Task) (a : Nat) (log : List Trial.LogEvent)
    (hb : s.bindings.find? (fun q => q.record.id == id) = some b)
    (hv : b.record.value = .list (some a)) :
    Trial.giveUpBinding .approved id (logged s log) =
      Trial.giveUp .approved s.mem.cells.length a
        (input (bindingInput s id b rest) s.slots log) := by
  have hfind : (s.bindings.map (·.record)).find? (fun q => q.id == id) = some b.record := by
    rw [List.find?_map]
    simp only [Function.comp_def, hb, Option.map_some]
  have hmap : (s.bindings.map (fun q => if q.record.id == id then
      { q with record := { q.record with status := .givenUp } } else q)).map (·.record) =
      (s.bindings.map (·.record)).map (fun q => if q.id == id then { q with status := .givenUp } else q) := by
    simp only [List.map_map]
    congr 1
    funext q
    dsimp only [Function.comp_def]
    split <;> rfl
  simp only [beq_iff_eq] at hmap
  simp [Trial.giveUpBinding, Trial.getBinding, Trial.setBindingStatus,
    Trial.giveUpLink, input, bindingInput, logged, observe, hfind, hv,
    Counted.pending, -List.map_map, hmap]

theorem cascade_binding (p : Program) (s : Counted.State) (id : Nat)
    (b : Counted.Binding) (a : Nat) (rest : List Counted.Task)
    (ht : s.tasks = .giveBinding id :: rest) (ha : s.answer = none)
    (hb : s.bindings.find? (fun q => q.record.id == id) = some b)
    (hh : b.record.status = .holding) (hv : b.record.value = .list (some a))
    (path : Cascade rest s.slots s.mem.cells.length (bindingInput s id b rest) a)
    (log : List Trial.LogEvent) :
    ∃ ticks t finalLog, Counted.advance p ticks s = .ok t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      Trial.giveUpBinding .approved id (logged s log) = (.ok (), logged t finalLog) ∧
      t.bindings = (bindingInput s id b rest).bindings ∧ t.reservations = s.reservations := by
  obtain ⟨ticks, t, finalLog, hex, ht', hs', ha', htrial, hpos, _, hbs, hrs⟩ :=
    cascade_pending p rest s.slots s.mem.cells.length (bindingInput s id b rest) a path
      ⟨b.record.value,b.value⟩ rfl rfl hv ha log
  refine ⟨ticks, t, finalLog, ?_, ht', hs', ha', ?_, hbs, hrs⟩
  · obtain ⟨n, rfl⟩ := Nat.exists_eq_succ_of_ne_zero (by omega : ticks ≠ 0)
    have hfirst := binding_first p s id b rest ht hb hh
    have hba : (bindingInput s id b rest).answer = none := ha
    simpa [Counted.advance, Counted.step, ha, hba, ← hfirst] using hex
  · rw [binding_trial s id b rest a log hb hv]
    exact htrial

theorem erase_logged (s : Counted.State) (log : List Trial.LogEvent) :
    eraseLog (logged s log) = observe s := rfl

theorem exact_fields (s : Counted.State) (t : Trial.RunState)
    (h : eraseLog t = observe s) :
    t.mem = s.mem ∧ t.mem.record = s.mem.record ∧ t.snaps = s.landmarks := by
  exact ⟨congrArg Trial.RunState.mem h, congrArg (fun r => r.mem.record) h,
    congrArg Trial.RunState.snaps h⟩

/-- Public pending-holder contract, starting with the real pending list rather
than a manually popped Trial input. The saved operands and tasks are arbitrary. -/
theorem pending_release (p : Program) (rest : List Counted.Task)
    (slots : List Counted.Slot) (fuel : Nat) (s : Counted.State) (a : Nat)
    (path : Cascade rest slots fuel s a) (v : Counted.Slot)
    (ht : s.tasks = .givePending :: rest) (hs : s.slots = v :: slots)
    (hv : v.raw = .list (some a)) (ha : s.answer = none) :
    ∃ ticks t u, 0 < ticks ∧ ticks ≤ 2*fuel ∧
      Counted.advance p ticks s = .ok t ∧ t.tasks = rest ∧ t.slots = slots ∧
      t.answer = none ∧
      (do Trial.popPending (.list (some a)); Trial.giveUp .approved fuel a : Trial.M Unit)
        (observe s) = (.ok (), u) ∧ eraseLog u = observe t ∧
      u.mem = t.mem ∧ u.mem.record = t.mem.record ∧ u.snaps = t.landmarks := by
  obtain ⟨ticks, t, log, hex, htasks, hslots, hans, htrial, hpos, hbound, _, _⟩ :=
    cascade_pending p rest slots fuel s a path v ht hs hv ha []
  refine ⟨ticks, t, logged t log, hpos, hbound, hex, htasks, hslots, hans,
    ?_, erase_logged t log, rfl, rfl, rfl⟩
  have hpop : Trial.popPending (.list (some a)) (observe s) =
      (.ok (), input s slots []) := by
    simp [Trial.popPending, observe, input, logged, Counted.pending, hs, hv]
  simp only [Trial.Proofs.m_bind_apply, hpop]
  exact htrial

theorem binding_release (p : Program) (s : Counted.State) (id : Nat)
    (b : Counted.Binding) (a : Nat) (rest : List Counted.Task)
    (ht : s.tasks = .giveBinding id :: rest) (ha : s.answer = none)
    (hb : s.bindings.find? (fun q => q.record.id == id) = some b)
    (hh : b.record.status = .holding) (hv : b.record.value = .list (some a))
    (path : Cascade rest s.slots s.mem.cells.length (bindingInput s id b rest) a) :
    ∃ ticks t u, Counted.advance p ticks s = .ok t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      Trial.giveUpBinding .approved id (observe s) = (.ok (), u) ∧
      eraseLog u = observe t ∧ u.mem = t.mem ∧
      u.mem.record = t.mem.record ∧ u.snaps = t.landmarks := by
  obtain ⟨ticks, t, log, hex, ht', hs', ha', htrial, _, _⟩ :=
    cascade_binding p s id b a rest ht ha hb hh hv path []
  exact ⟨ticks, t, logged t log, hex, ht', hs', ha', htrial,
    erase_logged t log, rfl, rfl, rfl⟩

/-- Direct binding contract against an independently supplied successful Trial
execution. Only immutable-edge readiness remains a Full-specific premise. -/
theorem binding_release_of_success (p : Program) (s : Counted.State) (id : Nat)
    (b : Counted.Binding) (a : Nat) (rest : List Counted.Task) (u : Trial.RunState)
    (ht : s.tasks = .giveBinding id :: rest) (ha : s.answer = none)
    (hb : s.bindings.find? (fun q => q.record.id == id) = some b)
    (hh : b.record.status = .holding) (hv : b.record.value = .list (some a))
    (hsuccess : Trial.giveUpBinding .approved id (observe s) = (.ok (), u))
    (hready : Ready rest s.slots s.mem.cells.length (bindingInput s id b rest) a) :
    ∃ ticks t, Counted.advance p ticks s = .ok t ∧
      t.tasks = rest ∧ t.slots = s.slots ∧ t.answer = none ∧
      eraseLog u = observe t ∧ u.mem = t.mem ∧
      u.mem.record = t.mem.record ∧ u.snaps = t.landmarks := by
  have hraw := hsuccess
  rw [show observe s = logged s [] from rfl,
    binding_trial s id b rest a [] hb hv] at hraw
  have path := cascade_of_success rest s.slots s.mem.cells.length
    (bindingInput s id b rest) a [] u hraw hready
  obtain ⟨ticks, t, u', hex, ht', hs', ha', htrial, herase, hm, hr, hsn⟩ :=
    binding_release p s id b a rest ht ha hb hh hv path
  have heq : u' = u := congrArg Prod.snd (htrial.symm.trans hsuccess)
  subst u'
  exact ⟨ticks, t, hex, ht', hs', ha', herase, hm, hr, hsn⟩

end Full.Proofs.TrialRelease

#print axioms Full.Proofs.TrialRelease.pending_transition
#print axioms Full.Proofs.TrialRelease.give_observe
#print axioms Full.Proofs.TrialRelease.free_observe
#print axioms Full.Proofs.TrialRelease.edge_from_invariant
#print axioms Full.Proofs.TrialRelease.trial_shared
#print axioms Full.Proofs.TrialRelease.trial_exclusive
#print axioms Full.Proofs.TrialRelease.exclusive_steps
#print axioms Full.Proofs.TrialRelease.advance_add
#print axioms Full.Proofs.TrialRelease.cascade_pending
#print axioms Full.Proofs.TrialRelease.cascade_of_success
#print axioms Full.Proofs.TrialRelease.binding_first
#print axioms Full.Proofs.TrialRelease.binding_trial
#print axioms Full.Proofs.TrialRelease.cascade_binding
#print axioms Full.Proofs.TrialRelease.erase_logged
#print axioms Full.Proofs.TrialRelease.exact_fields
#print axioms Full.Proofs.TrialRelease.pending_release
#print axioms Full.Proofs.TrialRelease.binding_release
#print axioms Full.Proofs.TrialRelease.binding_release_of_success
