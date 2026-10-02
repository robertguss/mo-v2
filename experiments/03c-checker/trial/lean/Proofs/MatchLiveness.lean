import Proofs.PendingRelease

namespace Trial.Proofs

/-- After selecting the nonempty branch, the unselected empty branch's uses
are removed before taking the cell apart. Placeholders own no existing ids. -/
theorem cleanup_match_cell {start : Start} {g : Meanings} {enc : List Nat} {s : RunState}
    (h : StateInvariant start g enc s) (env : Env) (nb cb : Expr) (headName tailName : String)
    (fs : List Frame) (hi : ∀ p ∈ env, p.2 < s.nextBinding)
    (hl : LiveFor s.bindings ({ text := nb, env := toFEnv env } ::
      { text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs)) :
    ∃ t, giveUpDead Variant.approved env
      ({ text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs) s = (.ok (), t) ∧
      StateInvariant start g enc t ∧
      LiveFor t.bindings ({ text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs) ∧
      ReleaseFrame s t ∧ t.pending = s.pending ∧
      (∀ v ∈ s.pending, readBack t.mem v = readBack s.mem v) := by
  apply cleanup_contract h env _ hi
  · intro b hb hv hu
    apply (hl b hb hv).mpr
    simp only [used_later_cons, Bool.or_eq_true] at hu ⊢
    exact Or.inr hu
  · intro b hb hs hn
    have hu := (hl b hb (h.holding b hb hs)).mp hs
    have hnot : usesBinding cb ((tailName, none) :: (headName, none) :: toFEnv env) b.id = false ∧
        usedLater fs b.id = false := by simpa [used_later_cons] using hn
    have hnb : usesBinding nb (toFEnv env) b.id = true := by
      simpa [used_later_cons, hnot.1, hnot.2] using hu
    exact used_env_id nb env b.id hnb

/-- This closes both directions of liveness after head/tail introduction.
The head is a scalar; the tail holds exactly when its branch uses it. Fresh
ids cannot be used by an enclosing continuation, even with name shadowing. -/
theorem match_bindings_live (s : RunState) (env : Env) (cb : Expr) (fs : List Frame)
    (headName tailName : String) (item : Int) (link : Option Addr) (status : BStatus)
    (hb : ∀ b ∈ s.bindings, b.id < s.nextBinding)
    (hf : FramesBound s fs)
    (hl : LiveFor s.bindings ({ text := cb, env := (tailName, none) :: (headName, none) :: toFEnv env } :: fs))
    (ht : ∀ a, link = some a → (status = .holding ↔
      usesBinding cb (toFEnv ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env)) (s.nextBinding + 1) = true)) :
    LiveFor (s.bindings ++
      [{ id := s.nextBinding, name := headName, value := .num item, status := .noHolder },
       { id := s.nextBinding + 1, name := tailName, value := .list link, status := status }])
      ({ text := cb, env := toFEnv ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env) } :: fs) := by
  have hfuture : usedLater fs (s.nextBinding + 1) = false := by
    cases hu : usedLater fs (s.nextBinding + 1) with
    | false => rfl
    | true =>
      have hi := used_later_below fs s.nextBinding (s.nextBinding + 1) hf hu
      omega
  intro b hmem hnonempty
  rcases List.mem_append.mp hmem with hold | hnew
  · simp only [used_later_cons]
    rw [match_old_uses cb env headName tailName s.nextBinding b.id (hb b hold)]
    exact hl b hold hnonempty
  · rcases List.mem_cons.mp hnew with hhead | htail
    · subst b
      obtain ⟨a, ha⟩ := hnonempty
      contradiction
    · have he := List.mem_singleton.mp htail
      subst b
      obtain ⟨a, ha⟩ := hnonempty
      have hlink : link = some a := RawValue.list.inj ha
      simpa [used_later_cons, hfuture] using ht a hlink

theorem match_frames_bound (s : RunState) (env : Env) (cb : Expr) (fs : List Frame)
    (headName tailName : String) (hi : ∀ p ∈ env, p.2 < s.nextBinding) (hf : FramesBound s fs)
    (t : RunState) (ht : t.nextBinding = s.nextBinding + 2) :
    FramesBound t ({ text := cb, env := toFEnv ((tailName, s.nextBinding + 1) :: (headName, s.nextBinding) :: env) } :: fs) := by
  intro f hmem x id hid
  rw [ht]
  rcases List.mem_cons.mp hmem with he | hm
  · subst f
    obtain ⟨p, hp, heq⟩ := List.mem_map.mp hid
    have hpid : p.2 = id := by simpa using congrArg Prod.snd heq
    rw [← hpid]
    rcases List.mem_cons.mp hp with he | hm
    · subst p; omega
    · rcases List.mem_cons.mp hm with he | hm
      · subst p; omega
      · exact Nat.lt_trans (hi p hm) (by omega)
  · exact Nat.lt_trans (hf f hm x id hid) (by omega)

end Trial.Proofs
