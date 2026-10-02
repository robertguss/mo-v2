import Proofs.CleanupViews

namespace Trial.Proofs

/-- Every reserved-cell disposal snapshot preserves all owned list values.
The branch ordering and allocation hypotheses are the same as for disposal's
successful final-state result. -/
theorem dispose_prefix_views (front : List Addr) (rest : List (Nat × Addr)) (bid fuel : Nat)
    (s : RunState) (hh : Owned s) (ha : ReservedAllocated s)
    (hu : (s.setAside.map Prod.snd).Nodup)
    (hstack : s.setAside = front.map (fun a => (bid, a)) ++ rest)
    (hrest : ∀ p ∈ rest, p.1 ≠ bid) (hlen : front.length ≤ fuel) :
    PreservesViews (ownedRoots s) s (disposeSetAside bid fuel s).2 := by
  induction front generalizing fuel s with
  | nil =>
    have hs : s.setAside = rest := by simpa using hstack
    have hn : s.setAside.any (fun p => p.1 == bid) = false := by
      rw [hs]
      apply List.any_eq_false.mpr
      intro p hp
      simpa using hrest p hp
    rw [dispose_none s bid fuel hn]
    exact .refl _ s
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
      have htail := ih fuel u hown halloc huniq hstack' (by simpa using hlen)
      have hroot : ownedRoots u = ownedRoots s := by simp [ownedRoots, u, p, snapshot]
      have hvp : PreservesViews (ownedRoots s) s p :=
        .of_fields _ s p rfl rfl hread rfl
      have hvu := hvp.trans (snapshot_views p (ownedRoots s) .cellFreed none)
      rw [hroot] at htail
      rw [hstep]
      exact hvu.trans htail

/-- The actual branch-finishing operation succeeds, frees exactly this branch's
reserved prefix, and preserves every owned value throughout its observations. -/
theorem finish_branch_safe (front : List Addr) (rest : List (Nat × Addr)) (bid : Nat)
    (inner outer : Env) (w : RawValue) (s : RunState)
    (hh : Owned s) (ha : ReservedAllocated s) (hu : (s.setAside.map Prod.snd).Nodup)
    (hstack : s.setAside = front.map (fun a => (bid, a)) ++ rest)
    (hrest : ∀ p ∈ rest, p.1 ≠ bid) :
    ∃ t, finishBranch bid inner outer w s = (.ok w, t) ∧ Owned t ∧
      t.setAside = rest ∧ ReservedAllocated t ∧ t.pending = s.pending ∧
      PreservesViews (ownedRoots s) s t := by
  let u : RunState := { s with scope := inner.reverse.map Prod.snd }
  let v := (snapshot .branchValueWorkedOut (some w) u).2
  have hv : Owned v := hh.same_fields rfl rfl rfl rfl
  have hva : ReservedAllocated v := ha
  have hvu : (v.setAside.map Prod.snd).Nodup := hu
  have hvs : v.setAside = front.map (fun a => (bid, a)) ++ rest := hstack
  have hlen : front.length ≤ v.setAside.length := by simp [hvs]
  obtain ⟨d, hd, hhd, hsd, had, _, hpd, _, _⟩ :=
    dispose_prefix front rest bid v.setAside.length v hv hva hvu hvs hrest hlen
  have hvd := dispose_prefix_views front rest bid v.setAside.length v hv hva hvu hvs hrest hlen
  rw [hd] at hvd
  let e : RunState := { d with scope := outer.reverse.map Prod.snd }
  let t := (snapshot .branchValueHandedOn (some w) e).2
  have hsu : PreservesViews (ownedRoots s) s u :=
    .of_fields _ s u rfl rfl (fun _ _ => rfl) rfl
  have hsv := hsu.trans (snapshot_views u (ownedRoots s) .branchValueWorkedOut (some w))
  have hroot : ownedRoots v = ownedRoots s := rfl
  rw [hroot] at hvd
  have hde : PreservesViews (ownedRoots s) d e :=
    .of_fields _ d e rfl rfl (fun _ _ => rfl) rfl
  refine ⟨t, ?_, hhd.same_fields rfl rfl rfl rfl, hsd, had, hpd, ?_⟩
  · change ((disposeSetAside bid v.setAside.length >>= fun _ => do
        enter outer
        snapshot .branchValueHandedOn (some w)
        pure w) : M RawValue) v = (.ok w, t)
    rw [m_bind_apply, hd]
    simp [enter, e, t, snapshot]
  · exact ((hsv.trans hvd).trans hde).trans (snapshot_views e (ownedRoots s) .branchValueHandedOn (some w))

end Trial.Proofs
