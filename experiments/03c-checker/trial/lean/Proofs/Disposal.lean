import Proofs.Construction

namespace Trial.Proofs

/-- Every entry of the branch stack names an allocated reserved cell. -/
def ReservedAllocated (s : RunState) : Prop :=
  ∀ p ∈ s.setAside, ∃ c, s.mem.find? p.2 = some c ∧ c.status = .setAside

/-- With no reserved cell belonging to this branch, disposal is a no-op. -/
theorem dispose_none (s : RunState) (bid fuel : Nat)
    (hn : s.setAside.any (fun p => p.1 == bid) = false) :
    disposeSetAside bid fuel s = (.ok (), s) := by
  cases fuel with
  | zero => simp [disposeSetAside, hn]
  | succ fuel =>
    cases hs : s.setAside with
    | nil => simp [disposeSetAside, hs]
    | cons p ps =>
      rcases p with ⟨b, a⟩
      have hno : ∀ p ∈ s.setAside, p.1 ≠ bid := by simpa using hn
      have hb : b ≠ bid := hno (b, a) (by simp [hs])
      simp [disposeSetAside, hs, hb]
      simp [hn]

/-- Disposal frees the branch's leading reserved cells and leaves the outer
stack and every owned list unchanged. The prefix condition is the branch-stack
ordering obligation to be supplied by the evaluator proof. -/
theorem dispose_prefix (front : List Addr) (rest : List (Nat × Addr)) (bid fuel : Nat)
    (s : RunState) (hh : Owned s) (ha : ReservedAllocated s)
    (hu : (s.setAside.map Prod.snd).Nodup)
    (hstack : s.setAside = front.map (fun a => (bid, a)) ++ rest)
    (hrest : ∀ p ∈ rest, p.1 ≠ bid) (hlen : front.length ≤ fuel) :
    ∃ t, disposeSetAside bid fuel s = (.ok (), t) ∧ Owned t ∧
      t.setAside = rest ∧ ReservedAllocated t ∧
      t.bindings = s.bindings ∧ t.pending = s.pending ∧ t.outside = s.outside ∧
      (∀ q ∈ ownedRoots s, readBack t.mem (.list q) = readBack s.mem (.list q)) := by
  induction front generalizing fuel s with
  | nil =>
    have hs : s.setAside = rest := by simpa using hstack
    have hn : s.setAside.any (fun p => p.1 == bid) = false := by
      rw [hs]
      apply List.any_eq_false.mpr
      intro p hp
      simpa using hrest p hp
    exact ⟨s, dispose_none s bid fuel hn, hh, hs, ha, rfl, rfl, rfl, fun _ _ => rfl⟩
  | cons a front ih =>
    cases fuel with
    | zero => simp at hlen
    | succ fuel =>
      let tail := front.map (fun a => (bid, a)) ++ rest
      have hs : s.setAside = (bid, a) :: tail := by simpa [tail] using hstack
      obtain ⟨c, hf, hc⟩ := ha (bid, a) (by simp [hs])
      let m' : Memory := { s.mem with
        cells := s.mem.cells.filter (fun d => d.addr != a)
        record := s.mem.record ++ [.released a] }
      have hm : s.mem.release a = .ok m' := by simp [Memory.release, hf, m']
      obtain ⟨hhealthy, hread⟩ := hh.release_reserved hf hc hm
      let p : RunState := { s with mem := m', setAside := tail, log := s.log ++ [.free a] }
      let u := (snapshot .cellFreed none p).2
      have hstep : disposeSetAside bid (fuel + 1) s = disposeSetAside bid fuel u := by
        simp [disposeSetAside, hs, logEvent, memOp, hm, snapshot, u, p]
      have hown : Owned u := by
        simpa [Owned, ownedRoots, u, p, snapshot] using hhealthy
      have hu' : (a :: tail.map Prod.snd).Nodup := by simpa [hs] using hu
      have halloc : ReservedAllocated u := by
        intro q hq
        have hqt : q ∈ tail := by simpa [u, p, snapshot] using hq
        obtain ⟨d, hd, hds⟩ := ha q (by simp [hs, hqt])
        have hne : q.2 ≠ a := by
          intro he
          exact (List.nodup_cons.mp hu').1 (List.mem_map.mpr ⟨q, hqt, he⟩)
        refine ⟨d, ?_, hds⟩
        change ({ s.mem with cells := s.mem.cells.filter (fun d => d.addr != a) } : Memory).find? q.2 = some d
        rw [find_filter_other s.mem a q.2 hne, hd]
      have huniq : (u.setAside.map Prod.snd).Nodup := by
        simpa [u, p, snapshot] using (List.nodup_cons.mp hu').2
      have hstack' : u.setAside = front.map (fun a => (bid, a)) ++ rest := by
        simp [u, p, snapshot, tail]
      obtain ⟨t, he, hht, hst, hat, hbt, hpt, hot, hrt⟩ :=
        ih fuel u hown halloc huniq hstack' (by simpa using hlen)
      refine ⟨t, hstep.trans he, hht, hst, hat, ?_, ?_, ?_, ?_⟩
      · simpa [u, p, snapshot] using hbt
      · simpa [u, p, snapshot] using hpt
      · simpa [u, p, snapshot] using hot
      · intro q hq
        have hq' : q ∈ ownedRoots u := by simpa [ownedRoots, u, p, snapshot] using hq
        exact (hrt q hq').trans (hread q hq)

end Trial.Proofs
