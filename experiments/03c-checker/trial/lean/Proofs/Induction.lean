import Proofs.Inputs

namespace Trial.Proofs

/-- Immutable raw and plain meanings indexed by binding id. Fresh bindings may
extend this table; meanings for existing ids never change. -/
abbrev Meanings := Nat → RawValue × PlainValue

def ExtendsMeanings (before after : Meanings) (bound : Nat) : Prop :=
  ∀ id, id < bound → after id = before id

/-- Environment correspondence is lookup agreement, not list equality. The
counted input loop reverses inputs, whereas the plain environment does not. -/
def EnvMeaning (env : Env) (plain : List (String × PlainValue)) (g : Meanings) : Prop :=
  ∀ x, lookupVal plain x = (env.find? (fun p => p.1 == x)).map (fun p => (g p.2).2)

/-- Existing ids mentioned by a frame really exist; placeholders for future
bindings are deliberately excluded. -/
def FramesBound (s : RunState) (fs : List Frame) : Prop :=
  ∀ f ∈ fs, ∀ x id, (x, some id) ∈ f.env → id < s.nextBinding

/-- Both directions are needed: future uses keep their holders, and a holder
cannot remain after all its uses disappear. Scalars and empty lists own none. -/
def LiveFor (bs : List Binding) (fs : List Frame) : Prop :=
  ∀ b ∈ bs, (∃ a, b.value = .list (some a)) →
    (b.status = .holding ↔ usedLater fs b.id = true)

/-- Invariants at completed-operation boundaries. Healthy is not asserted for
internal zero-count snapshots. Historical meanings cover holding names only. -/
structure StateInvariant (start : Start) (g : Meanings) (enc : List Nat) (s : RunState) : Prop where
  owned : Owned s
  ids : s.bindings.map Binding.id = List.range s.nextBinding
  raw : ∀ b ∈ s.bindings, b.value = (g b.id).1
  kinds : ∀ b ∈ s.bindings, b.value.kind = (g b.id).2.kind
  readable : ∀ b ∈ s.bindings, b.status = .holding ∨ valueRoot b.value = none →
    readBack s.mem b.value = .ok (g b.id).2
  holding : ∀ b ∈ s.bindings, b.status = .holding → ∃ a, b.value = .list (some a)
  pending : ∀ v ∈ s.pending, ∃ a, v = .list (some a)
  reserved : ReservedAllocated s
  tracked : ∀ c ∈ s.mem.cells, c.status = .setAside → ∃ bid, (bid, c.addr) ∈ s.setAside
  detached : ∀ c ∈ s.mem.cells, c.status = .setAside → c.count = 0 ∧ c.link = none
  addresses : (s.setAside.map Prod.snd).Nodup
  labels : (s.setAside.map Prod.fst).Nodup
  ordered : (s.setAside.map Prod.fst).Sublist enc
  branches : enc.Nodup
  branchBound : ∀ bid ∈ enc, bid < s.nextBranch
  outside : s.outside = start.outside
  outsideValues : ∀ r ∈ start.outside,
    readBack s.mem (.list r) = readBack start.toMemory (.list r)
  history : ∀ sn ∈ s.snaps,
    HoldingMeanings (snapMemory sn) sn.bindings (fun id => (g id).1) (fun id => (g id).2)
  historyBound : ∀ sn ∈ s.snaps, ∀ b ∈ sn.bindings, b.id < s.nextBinding
  outsideHistory : ∀ sn ∈ s.snaps, sn.outside = start.outside ∧
    ∀ r ∈ start.outside, readBack (snapMemory sn) (.list r) = readBack start.toMemory (.list r)

/-- Only a nonempty result contributes a pending holder. Defined outside the
postcondition so its match does not depend on earlier proof fields. -/
def pendingResult (raw : RawValue) (saved : List RawValue) : List RawValue :=
  match raw with | .list (some _) => raw :: saved | _ => saved

/-- The exit contract supplies the semantic answer, exact pending stack,
future liveness, history, and reserved-stack suffix required by the promises. -/
structure EvalPost (e : Expr) (start : Start) (env : Env) (plain : List (String × PlainValue))
    (fs : List Frame) (enc : List Nat) (k : Kind) (s : RunState) (g : Meanings)
    (t : RunState) (g' : Meanings) (raw : RawValue) (value : PlainValue) : Prop where
  run : evalC Variant.approved e env fs enc s = (.ok raw, t)
  meaning : eval plain e = .ok value
  kind : value.kind = k
  read : readBack t.mem raw = .ok value
  state : StateInvariant start g' enc t
  live : LiveFor t.bindings fs
  frames : FramesBound t fs
  bindingsGrow : s.nextBinding ≤ t.nextBinding
  branchesGrow : s.nextBranch ≤ t.nextBranch
  meanings : ExtendsMeanings g g' s.nextBinding
  pending : t.pending = pendingResult raw s.pending
  saved : ∀ v ∈ s.pending, readBack t.mem v = readBack s.mem v
  reservations : t.setAside.IsSuffix s.setAside
  snapshots : s.snaps.IsPrefix t.snaps

/-- The single structural-induction target. This definition is a proof goal,
not a proof of it; each constructor must establish this entire contract. -/
def EvalContract (e : Expr) : Prop :=
  ∀ start g env plain fs enc k s,
    StateInvariant start g enc s →
    LiveFor s.bindings ({ text := e, env := toFEnv env } :: fs) →
    FramesBound s ({ text := e, env := toFEnv env } :: fs) →
    EnvMeaning env plain g → check (plain.map (fun p => (p.1, p.2.kind))) e = .ok k →
    ∃ t g' raw value, EvalPost e start env plain fs enc k s g t g' raw value

/-- The final evaluator contract genuinely supplies the leak promise's
non-semantic final-state obligations; it does not leave dead holders assumed. -/
theorem StateInvariant.final_no_leak {start : Start} {g : Meanings} {s : RunState}
    (h : StateInvariant start g [] s) (hl : LiveFor s.bindings []) (raw : RawValue)
    (hp : s.pending = match raw with | .list (some _) => [raw] | _ => []) :
    NoLeakAt s.mem (answerRoots raw start) := by
  have hb : ∀ b ∈ s.bindings, b.status ≠ .holding := by
    intro b hmem hs
    have hu := (hl b hmem (h.holding b hmem hs)).mp hs
    simp [usedLater] at hu
  have hstack : s.setAside = [] := by
    have he : s.setAside.map Prod.fst = [] := List.sublist_nil.mp h.ordered
    simpa using he
  exact Trial.Proofs.final_no_leak start s raw h.owned hb h.tracked hstack hp h.outside

/-- The same boundary invariant supplies the exact snapshot visibility promise. -/
theorem StateInvariant.visible {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (e : Expr) (hv : validStart e start = .ok ())
    (o : Outcome) (hs : o.states = s.snaps) : NoVisibleChange start o := by
  apply visible_of_meanings start o (fun id => (g id).1) (fun id => (g id).2)
  · simpa [hs] using h.outsideHistory
  · intro r hr
    obtain ⟨cs, hp⟩ := valid_start_paths e start hv r (List.mem_append_right _ hr)
    simp [hp.read_back, Except.toBool]
  · simpa [hs] using h.history

theorem StateInvariant.unique {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) : (s.bindings.map Binding.id).Nodup := by
  rw [h.ids]
  exact List.nodup_range

theorem StateInvariant.bound {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (b : Binding) (hb : b ∈ s.bindings) : b.id < s.nextBinding := by
  have hm : b.id ∈ s.bindings.map Binding.id := List.mem_map.mpr ⟨b, hb, rfl⟩
  rw [h.ids] at hm
  exact List.mem_range.mp hm

theorem FramesBound.tail {s : RunState} {f : Frame} {fs : List Frame}
    (h : FramesBound s (f :: fs)) : FramesBound s fs :=
  fun f hf => h f (List.mem_cons_of_mem _ hf)

theorem LiveFor.congr {bs : List Binding} {fs gs : List Frame} (h : LiveFor bs fs)
    (he : ∀ id, usedLater fs id = usedLater gs id) : LiveFor bs gs := by
  intro b hb hv
  simpa [he b.id] using h b hb hv

theorem number_contract (n : Int) : EvalContract (.num n) := by
  intro start g env plain fs enc k s h hl hf _hk ht
  refine ⟨s, g, .num n, .num n, ?_⟩
  refine ⟨rfl, rfl, ?_, rfl, h, ?_, hf.tail, Nat.le_refl _, Nat.le_refl _,
    (fun _ _ => rfl), rfl, (fun _ _ => rfl), ?_, ?_⟩
  · simpa [check, PlainValue.kind] using ht
  · exact hl.congr (fun _ => by simp [usedLater, usesBinding])
  · exact ⟨[], by simp⟩
  · exact ⟨[], by simp⟩

theorem nil_contract : EvalContract .nil := by
  intro start g env plain fs enc k s h hl hf _hk ht
  refine ⟨s, g, .list none, .list [], ?_⟩
  refine ⟨rfl, rfl, ?_, ?_, h, ?_, hf.tail, Nat.le_refl _, Nat.le_refl _,
    (fun _ _ => rfl), rfl, (fun _ _ => rfl), ?_, ?_⟩
  · simpa [check, PlainValue.kind] using ht
  · simpa using (ListPath.nil (m := s.mem)).read_back
  · exact hl.congr (fun _ => by simp [usedLater, usesBinding])
  · exact ⟨[], by simp⟩
  · exact ⟨[], by simp⟩

theorem FramesBound.head {s : RunState} {f : Frame} {fs : List Frame}
    (h : FramesBound s (f :: fs)) : ∀ x id, (x, some id) ∈ f.env → id < s.nextBinding :=
  h f (by simp)

theorem FramesBound.prepend {s : RunState} {fs : List Frame} (h : FramesBound s fs)
    (e : Expr) (env : FEnv) (he : ∀ x id, (x, some id) ∈ env → id < s.nextBinding) :
    FramesBound s ({ text := e, env := env } :: fs) := by
  intro f hf
  rcases List.mem_cons.mp hf with heq | hm
  · subst f; exact he
  · exact h f hm

theorem FramesBound.env {s : RunState} {e : Expr} {env : Env} {fs : List Frame}
    (h : FramesBound s ({ text := e, env := toFEnv env } :: fs)) :
    ∀ p ∈ env, p.2 < s.nextBinding := by
  intro p hp
  exact h.head p.1 p.2 (List.mem_map.mpr ⟨p, hp, rfl⟩)

theorem EnvMeaning.extend {env : Env} {plain : List (String × PlainValue)} {g g' : Meanings}
    {n : Nat} (h : EnvMeaning env plain g) (he : ExtendsMeanings g g' n)
    (hb : ∀ p ∈ env, p.2 < n) : EnvMeaning env plain g' := by
  intro x
  rw [h x]
  cases hf : env.find? (fun p => p.1 == x) with
  | none => rfl
  | some p => simp [he p.2 (hb p (List.mem_of_find?_eq_some hf))]

theorem ExtendsMeanings.trans {g g' g'' : Meanings} {n n' : Nat}
    (h : ExtendsMeanings g g' n) (h' : ExtendsMeanings g' g'' n') (hn : n ≤ n') :
    ExtendsMeanings g g'' n :=
  fun id hi => (h' id (Nat.lt_of_lt_of_le hi hn)).trans (h id hi)

theorem read_back_number {m : Memory} {raw : RawValue} {n : Int}
    (h : readBack m raw = .ok (.num n)) : raw = .num n := by
  cases raw with
  | num i => simpa [readBack] using h
  | bool b => simp [readBack] at h
  | list r => cases hr : readList m m.cells.length r <;> simp [readBack, hr] at h

theorem read_back_bool {m : Memory} {raw : RawValue} {b : Bool}
    (h : readBack m raw = .ok (.bool b)) : raw = .bool b := by
  cases raw with
  | num i => simp [readBack] at h
  | bool c => simpa [readBack] using h
  | list r => cases hr : readList m m.cells.length r <;> simp [readBack, hr] at h

end Trial.Proofs
