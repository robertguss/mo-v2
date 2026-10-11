import Full.Proofs.ReleaseReadiness

namespace Full.Proofs.ReservedReadiness
open Counted

def Allocated (m : Trial.Memory) (rs : List Reservation) : Prop :=
  ∀ r ∈ rs, ∃ c, m.find? r.addr = some c ∧ c.status = .setAside

def Unique (rs : List Reservation) : Prop := (rs.map Reservation.addr).Nodup

theorem live_distinct (hs : Allocated m rs) (hr : r ∈ rs)
    (hf : m.find? a = some c) (hl : c.status = .live) : r.addr ≠ a := by
  obtain ⟨d,hd,hs⟩ := hs r hr
  intro he
  rw [he,hf] at hd
  cases Option.some.inj hd
  simp_all

theorem allocated_update (hs : Allocated m rs) (a : Nat) (f : Trial.Cell → Trial.Cell)
    (ha : ∀ c, (f c).addr = c.addr) (hh : ∀ c, (f c).status = c.status) :
    Allocated (m.updateCell a f) rs := by
  intro r hr
  obtain ⟨c,hc,hl⟩ := hs r hr
  rw [Trial.Proofs.find_update _ _ _ _ (by intros; apply ha),hc]
  simp only [Option.map_some]
  split <;> exact ⟨_,rfl,by simp_all⟩

theorem allocated_count (hs : Allocated m rs) (ht : m.setCount a n = .ok m') :
    Allocated m' rs := by
  unfold Trial.Memory.setCount at ht
  split at ht <;> simp_all
  cases ht
  exact allocated_update hs a _ (by intros; rfl) (by intros; rfl)

theorem allocated_filter_update (hs : Allocated m rs) (a : Nat)
    (f : Trial.Cell → Trial.Cell) (ha : ∀ c, c.addr = a → (f c).addr = c.addr) :
    Allocated (m.updateCell a f) (rs.filter (fun r => r.addr != a)) := by
  intro r hr
  obtain ⟨hr,hne⟩ := List.mem_filter.mp hr
  obtain ⟨c,hc,hl⟩ := hs r hr
  rw [Trial.Proofs.find_update_other _ _ _ _ ha (by simpa using hne)]
  exact ⟨c,hc,hl⟩

theorem allocated_release (hs : Allocated m rs) (ht : m.release a = .ok m') :
    Allocated m' (rs.filter (fun r => r.addr != a)) := by
  unfold Trial.Memory.release at ht
  split at ht <;> simp_all
  cases ht
  intro r hr
  obtain ⟨hr,hne⟩ := List.mem_filter.mp hr
  obtain ⟨c,hc,hl⟩ := hs r hr
  exact ⟨c,(Trial.Proofs.find_filter_other _ _ _ (by simpa using hne)).trans hc,hl⟩

theorem allocated_create (hs : Allocated m rs) : Allocated (m.create h t).2 rs := by
  intro r hr
  obtain ⟨c,hc,hl⟩ := hs r hr
  refine ⟨c,?_,hl⟩
  simp [Trial.Memory.create,Trial.Memory.find?,List.find?_append,
    Trial.Memory.find?] at hc ⊢
  rw [hc]
  exact Or.inl rfl

theorem allocated_aside (hs : Allocated m rs) (hf : m.find? a = some c)
    (hl : c.status = .live) (ht : m.markSetAside a = .ok m') :
    Allocated m' (⟨inv,bid,a⟩ :: rs) := by
  simp [Trial.Memory.markSetAside,hf] at ht
  subst m'
  intro r hr
  rcases List.mem_cons.mp hr with rfl | hr
  · refine ⟨{ c with status := .setAside, count := 0, link := none },?_,rfl⟩
    rw [Trial.Proofs.find_update _ _ _ _ (by intros; rfl),hf]
    have hid : c.addr = a := by simpa using List.find?_some hf
    simp [hid]
  · obtain ⟨d,hd,hstatus⟩ := hs r hr
    refine ⟨d,?_,hstatus⟩
    rw [Trial.Proofs.find_update_other _ _ _ _ (by intros; rfl)
      (live_distinct hs hr hf hl),hd]

theorem unique_filter (hu : Unique rs) (f : Reservation → Bool) : Unique (rs.filter f) := by
  exact hu.sublist (List.Sublist.map Reservation.addr (List.filter_sublist))

theorem unique_aside (hs : Allocated m rs) (hu : Unique rs)
    (hf : m.find? a = some c) (hl : c.status = .live) :
    Unique (⟨inv,bid,a⟩ :: rs) := by
  simp only [Unique,List.map_cons,List.nodup_cons]
  refine ⟨?_,hu⟩
  intro hm
  obtain ⟨r,hr,he⟩ := List.mem_map.mp hm
  exact live_distinct hs hr hf hl he

theorem allocated_release_live (hs : Allocated m rs) (hf : m.find? a = some c)
    (hl : c.status = .live) (ht : m.release a = .ok m') : Allocated m' rs := by
  have he : rs.filter (fun r => r.addr != a) = rs := by
    apply List.filter_eq_self.mpr
    intro r hr
    simpa using live_distinct hs hr hf hl
  simpa [he] using allocated_release hs ht

set_option maxHeartbeats 2000000 in
theorem transition_resources (hs : Allocated s.mem s.reservations) (hu : Unique s.reservations)
    (ht : Counted.transition p s = .ok change) :
    Allocated change.state.mem change.state.reservations ∧ Unique change.state.reservations := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals try exact ⟨hs,hu⟩
    all_goals try exact ⟨allocated_count hs (by assumption),hu⟩
    all_goals try exact ⟨allocated_create hs,hu⟩
    all_goals try exact ⟨allocated_release hs (by assumption),unique_filter hu _⟩
    all_goals try exact ⟨allocated_release_live hs (by assumption) (by simp_all) (by assumption),hu⟩
    all_goals try exact ⟨allocated_aside hs (by assumption) (by simp_all) (by assumption),
      unique_aside hs hu (by assumption) (by simp_all)⟩
    all_goals constructor
    all_goals try exact unique_filter hu _
    all_goals rename_i hw
    all_goals unfold Trial.Memory.writeInPlace at hw
    all_goals repeat' first | split at hw | cases hw | contradiction
    all_goals exact allocated_filter_update hs _ _ (by intros; simp_all)

def ids : List Task → List Nat
  | [] => []
  | .freeReserved a :: ts => a :: ids ts
  | _ :: ts => ids ts

def Prefix : List Task → Prop
  | [] => True
  | .freeReserved _ :: ts => Prefix ts
  | _ :: ts => ids ts = []

theorem ids_append (xs ys : List Task) : ids (xs ++ ys) = ids xs ++ ids ys := by
  induction xs with
  | nil => rfl
  | cons x xs ih => cases x <;> simp [ids,ih]

theorem ids_reserved (rs : List Reservation) :
    ids (rs.map (fun r => .freeReserved r.addr)) = rs.map Reservation.addr := by
  induction rs with
  | nil => rfl
  | cons r rs ih => simp [ids,ih]

theorem ids_dead (bs : List Binding) (env : Env) (future : List Task) :
    ids (dead bs env future) = [] := by
  obtain ⟨ns,he⟩ := SimulationInitial.dead_is_prefix bs env future
  rw [he]
  clear he
  induction ns with
  | nil => rfl
  | cons n ns ih => simpa [ids] using ih

theorem ids_arguments (args : List (Expr × Nat)) (ctx : Context) :
    ids (args.flatMap (fun (e,i) => [.eval e (child ctx i),.capture])) = [] := by
  induction args with
  | nil => rfl
  | cons a args ih => simpa [ids,ids_append] using ih

theorem no_ids_prefix (h : ids ts = []) : Prefix ts := by
  induction ts with
  | nil => trivial
  | cons task ts ih => cases task <;> simp_all [ids,Prefix]

theorem prefix_reserved (rs : List Reservation) :
    Prefix (rs.map (fun r => .freeReserved r.addr) ++ ts) ↔ Prefix ts := by
  induction rs with
  | nil => rfl
  | cons r rs ih => simpa [Prefix] using ih

set_option maxHeartbeats 2000000 in
theorem transition_prefix (hp : Prefix s.tasks)
    (ht : Counted.transition p s = .ok c) : Prefix c.state.tasks := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp only [he,Prefix] at hp
    all_goals try exact hp
    all_goals dsimp only
    all_goals try simp only [List.append_assoc,prefix_reserved]
    all_goals try solve | apply no_ids_prefix; simp_all [ids,ids_append,ids_dead,ids_arguments]
    all_goals simp_all [Prefix,ids]

def Ready (rs : List Reservation) (ts : List Task) : Prop :=
  ∀ a ∈ ids ts, ∃ r ∈ rs, r.addr = a

theorem ready_empty (h : ids ts = []) : Ready rs ts := by
  intro a hm
  simp [h] at hm

theorem ready_suffix (hs : Ready rs (task :: ts)) : Ready rs ts := by
  intro a hm
  apply hs a
  cases task <;> simp [ids,hm]

theorem ready_release (hs : Ready rs (.freeReserved a :: ts))
    (hu : (ids (.freeReserved a :: ts)).Nodup) :
    Ready (rs.filter (fun r => r.addr != a)) ts := by
  intro b hb
  obtain ⟨r,hr,he⟩ := hs b (by simp [ids,hb])
  refine ⟨r,List.mem_filter.mpr ⟨hr,?_⟩,he⟩
  simp only [ids,List.nodup_cons] at hu
  have hne : b ≠ a := by intro h; exact hu.1 (h ▸ hb)
  simpa [he] using hne

theorem ready_reserved (rs : List Reservation) (hrs : ∀ r ∈ rs, r ∈ all)
    (ht : ids ts = []) : Ready all (rs.map (fun r => .freeReserved r.addr) ++ ts) := by
  intro a hm
  simp only [ids_append,ids_reserved,ht,List.append_nil] at hm
  obtain ⟨r,hr,he⟩ := List.mem_map.mp hm
  exact ⟨r,hrs r hr,he⟩

set_option maxHeartbeats 2000000 in
theorem transition_queue (hp : Prefix s.tasks) (hu : Unique s.reservations)
    (hn : (ids s.tasks).Nodup) (hs : Ready s.reservations s.tasks)
    (ht : Counted.transition p s = .ok c) :
    (ids c.state.tasks).Nodup ∧ Ready c.state.reservations c.state.tasks := by
  cases he : s.tasks with
  | nil => simp [Counted.transition,he] at ht
  | cons task rest =>
    rw [he] at hp hn hs
    cases task
    all_goals simp only [Counted.transition,he,bind,pure,Except.bind,Except.pure] at ht
    all_goals repeat' first | split at ht | cases ht | contradiction
    all_goals simp only [Prefix] at hp
    all_goals dsimp only
    all_goals try solve
      | constructor
        · simp_all [ids,ids_append,ids_dead,ids_arguments]
        · apply ready_empty; simp_all [ids,ids_append,ids_dead,ids_arguments]
    all_goals try solve
      | constructor
        · exact (List.nodup_cons.mp hn).2
        · exact ready_release hs hn
    all_goals constructor
    · simpa [ids_append,ids_reserved,ids,hp,Unique] using unique_filter hu _
    · rw [List.append_assoc]
      apply ready_reserved
      · intro r hr; exact (List.mem_filter.mp hr).1
      · simp [ids,hp]

def Invariant (s : State) : Prop :=
  Allocated s.mem s.reservations ∧ Unique s.reservations ∧ Prefix s.tasks ∧
    (ids s.tasks).Nodup ∧ Ready s.reservations s.tasks

theorem transition_invariant (hs : Invariant s)
    (ht : Counted.transition p s = .ok c) : Invariant c.state := by
  obtain ⟨ha,hu,hp,hn,hr⟩ := hs
  obtain ⟨ha',hu'⟩ := transition_resources ha hu ht
  obtain ⟨hn',hr'⟩ := transition_queue hp hu hn hr ht
  exact ⟨ha',hu',transition_prefix hp ht,hn',hr'⟩

theorem begin_invariant (hb : Counted.begin p initial = .ok first) : Invariant first := by
  obtain ⟨_,_,_,_,_,rfl⟩ := Initial.begin_shape p initial first hb
  constructor
  · simp [Allocated]
  constructor
  · simp [Unique]
  refine ⟨no_ids_prefix ?_,?_,ready_empty ?_⟩
  all_goals simp [ids_append,ids_dead,ids]

theorem advance_invariant (hs : Invariant s)
    (ht : Counted.advance p n s = .ok t) : Invariant t := by
  induction n generalizing s with
  | zero => cases ht; exact hs
  | succ n ih =>
    cases ha : s.answer with
    | some v => simp [Counted.advance,ha] at ht; subst t; exact hs
    | none =>
      cases hc : Counted.transition p s with
      | error why => simp [Counted.advance,Counted.step,ha,hc] at ht
      | ok c =>
        simp [Counted.advance,Counted.step,ha,hc] at ht
        exact ih (s := commit c) (transition_invariant hs hc) ht

theorem reachable_invariant (hr : Statements.Reachable p initial s) : Invariant s := by
  obtain ⟨first,n,hb,hn⟩ := hr
  exact advance_invariant (begin_invariant hb) hn

/-- Cleanup addresses resolve in every actually reachable source state; no
executable invariant or invariant over prior states is assumed. -/
theorem reachable_reserved (hr : Statements.Reachable p initial s)
    (ht : s.tasks = .freeReserved addr :: rest) :
    ∃ r ∈ s.reservations, r.addr = addr := by
  have hs := (reachable_invariant hr).2.2.2.2
  exact hs addr (by simp [ht,ids])

theorem reachable_structural_ready (hr : Statements.Reachable p initial s) :
    Progress.StructuralReady s := by
  intro task rest ht
  cases task <;> try trivial
  · have hs := ReleaseReadiness.reachable_ready hr
    rw [ht] at hs
    exact hs.1
  · have hs := ReleaseReadiness.reachable_ready hr
    rw [ht] at hs
    exact hs.1
  · have hs := ReleaseReadiness.reachable_free_ready hr
    simp only [ReleaseReadiness.FreeReady,ht] at hs
    exact hs.2
  · exact reachable_reserved hr ht

/-- Universal source progress, conditional only on the source executable
invariant, with structural readiness derived from actual reachability. -/
theorem progress (hr : Statements.Reachable p initial s)
    (hi : Inspect.invariant initial s = true) (ha : s.answer = none) :
    ∃ c, Counted.transition p s = .ok c :=
  Progress.progress_of_ready hr hi ha (reachable_structural_ready hr)

end Full.Proofs.ReservedReadiness
