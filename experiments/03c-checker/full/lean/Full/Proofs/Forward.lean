import Full.Proofs.Simulation
import Full.Proofs.Free
import Full.Proofs.DecomposeRank

namespace Full.Proofs.Forward
open Counted Statements

/-- Successful transfer and metadata commit have the same decoder. -/
theorem step_commit (ha : s.answer = none) (ht : Counted.step p s = .ok t) :
    ∃ c, Counted.transition p s = .ok c ∧ t = commit c := by
  cases hc : Counted.transition p s with
  | error why => simp [Counted.step, ha, hc] at ht
  | ok c => exact ⟨c, rfl, by simpa [Counted.step, ha, hc] using ht.symm⟩

/-- F1 provides payload equality, not just the slot's kind. -/
theorem slot_readback (hf : F1) (hr : Reachable p initial s)
    (hv : v ∈ s.slots) : Trial.readBack s.mem v.raw = .ok v.value := by
  have hi := (hf.2 p initial s hr).1
  simp only [Inspect.invariant, Bool.and_eq_true] at hi
  have hp := hi.1.1.1.1.1.1.1
  simp only [Inspect.protection, Bool.and_eq_true] at hp
  have h := List.all_eq_true.mp hp.1.2 v hv
  unfold Inspect.readable at h
  cases he : Trial.readBack s.mem v.raw <;> simp_all [beq_iff_eq]

/-- These administrative tasks remove exactly one task and no operands. -/
inductive Erased : Task → Prop
  | start : Erased .start
  | handoff : Erased .handoff
  | branchStart (ctx) : Erased (.branchStart ctx)
  | matchComplete (ctx) : Erased (.matchComplete ctx)

theorem erased_transfer (he : Erased task) (hs : s.tasks = task :: rest)
    (hc : Counted.transition p s = .ok c) :
    c.state.bindings = s.bindings ∧ c.state.answer = s.answer ∧
    c.state.slots = s.slots ∧ c.state.tasks = rest ∧
    c.state.mem = s.mem := by
  cases he <;> simp [Counted.transition, hs] at hc <;> cases hc <;>
    exact ⟨rfl, rfl, rfl, rfl, rfl⟩

/-- Exact decoder stuttering, including failures, with the real traversal fuel. -/
theorem erased_decode (he : Erased task) (hs : s.tasks = task :: rest)
    (hc : Counted.transition p s = .ok c) :
    Control.decode c.state = Control.decode s := by
  obtain ⟨hb, ha, hv, ht, _⟩ := erased_transfer he hs hc
  simp only [Control.decode, ha, ht, hv, focus_bindings c.state s hb]
  cases hans : s.answer with
  | some v => rfl
  | none => cases he <;> simp [hs, Control.focus]

theorem erased_rank (he : Erased task) (hs : s.tasks = task :: rest)
    (hc : Counted.transition p s = .ok c) :
    Control.rank (commit c) < Control.rank s := by
  obtain ⟨_, _, _, ht, hm⟩ := erased_transfer he hs hc
  simp only [Control.rank, commit, ht, hm, hs, ← List.sum_eq_foldl_nat,
    List.map_cons, List.sum_cons]
  cases he <;> simp

/-- A complete local Forward case, with no reachability or decoding premise
other than the actual source correspondence. -/
theorem erased_step (he : Erased task) (hs : s.tasks = task :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  exact ⟨(decode_commit c).trans ((erased_decode he hs hc).trans hrel),
    erased_rank he hs hc⟩

/-- Free is a complete local Forward case under F1 and actual reachability;
the cell and edge facts are extracted from the successful transition. -/
theorem free_step (hf : F1) (hr : Reachable p initial s)
    (hs : s.tasks = .free addr :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨change, hc, rfl⟩ := step_commit ha ht
  have hsuccess := hc
  simp only [Counted.transition, hs, bind, pure, Except.bind, Except.pure] at hsuccess
  cases hcell : s.mem.find? addr with
  | none => simp [hcell] at hsuccess
  | some cell =>
    have hguard : (cell.status != .live || cell.count != 0) = false := by
      by_cases hg : (cell.status != .live || cell.count != 0) = true
      · simp [hcell, hg] at hsuccess
      · exact Bool.eq_false_iff.mpr hg
    have hl : cell.status = .live := by simpa using (Bool.or_eq_false_iff.mp hguard).1
    have hz : cell.count = 0 := by simpa using (Bool.or_eq_false_iff.mp hguard).2
    have hid : cell.addr = addr := by simpa using List.find?_some hcell
    obtain ⟨tail, hedge, _⟩ := invariant_live_edge initial s
      (hf.2 p initial s hr).1 cell (List.mem_of_find?_eq_some hcell) hl
    rw [hid] at hedge
    exact ⟨(decode_commit change).trans
        ((free_decode p s addr cell tail rest change hs hcell hl hz hedge hc).trans hrel),
      free_rank p s addr cell tail rest change hs hcell hl hz hedge hc⟩

/-- Finish consumes the final Plain value. Successful source decoding excludes
extra operands, independently of generic WorkTyped. -/
theorem finish_step (hs : s.tasks = [.finish]) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t := by
  cases hv : s.slots with
  | nil => simp [Counted.step, Counted.transition, ha, hs, hv] at ht
  | cons v vs =>
    cases vs with
    | cons w ws =>
      simp [Related, Control.decode, ha, hs, hv, Control.focus,
        Control.continuations] at hrel
    | nil =>
      have hea : a = ⟨.value v.value, []⟩ := by
        simpa [Related, Control.decode, ha, hs, hv, Control.focus,
          Control.continuations] using hrel.symm
      subst a
      simp [Counted.step, Counted.transition, ha, hs, hv] at ht
      cases ht
      rfl

/-- The final primitive Capture is a decoder stutter, not a Plain step.
This case uses exact operand order (right :: left :: older). -/
theorem capture_primitive_step
    (hs : s.tasks = .capture :: .primitive op ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  simp [Counted.transition, hs] at hc
  cases hc
  constructor
  · rw [show Related a (commit
        ⟨{ s with tasks := .primitive op ctx :: rest }, ⟨"Capture", none⟩, none⟩) ↔
        Related a { s with tasks := .primitive op ctx :: rest } from
        by unfold Related; rw [decode_commit]]
    unfold Related Control.decode at hrel ⊢
    simp only [focus_bindings { s with tasks := .primitive op ctx :: rest } s rfl]
    simp only [ha, hs, List.length_cons, Control.focus] at hrel ⊢
    cases hv : s.slots with
    | nil => simp [hv] at hrel
    | cons right vs =>
      cases vs with
      | nil => simp [hv, Control.continuations] at hrel
      | cons left older =>
        simp only [hv, Control.continuations] at hrel ⊢
        have he : Control.continuations s (rest.length + 3) rest older =
            Control.continuations s (rest.length + 2) rest older :=
          continuations_fuel s _ _ rest older (by omega) (by omega)
        simpa only [Control.env, he, Control.continuations] using hrel
  · simp only [Control.rank, commit, hs, ← List.sum_eq_foldl_nat,
      List.map_cons, List.sum_cons]
    simp

/-- The first primitive Capture is exactly the Plain left-continuation step;
the current value becomes the saved left operand, without reordering older
operands or assuming arbitrary typed work is decodable. -/
theorem capture_left_step
    (hs : s.tasks = .capture :: .eval b ctx :: .capture :: .primitive op outer :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) : Related (Plain.step p a) t := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  simp [Counted.transition, hs] at hc
  cases hc
  unfold Related
  rw [decode_commit]
  unfold Related at hrel
  unfold Control.decode at hrel ⊢
  simp only [focus_bindings
    { s with tasks := .eval b ctx :: .capture :: .primitive op outer :: rest } s rfl]
  simp only [ha, hs, List.length_cons, Control.focus] at hrel ⊢
  cases hv : s.slots with
  | nil => simp [hv] at hrel
  | cons v older =>
    simp only [hv, Control.continuations] at hrel ⊢
    have he1 : Control.continuations s (rest.length + 5) rest older =
        Control.continuations s (rest.length + 2) rest older :=
      continuations_fuel s _ _ rest older (by omega) (by omega)
    have he2 : Control.continuations s (rest.length + 3) rest older =
        Control.continuations s (rest.length + 2) rest older :=
      continuations_fuel s _ _ rest older (by omega) (by omega)
    rw [he1] at hrel
    rw [he2]
    cases hen : Control.env s ctx.env with
    | error why => simp [hen] at hrel
    | ok env =>
      cases hk : Control.continuations s (rest.length + 2) rest older with
      | error why => simp [hen, hk] at hrel
      | ok ks =>
        have hea : a = ⟨.value v.value, .left op b env :: ks⟩ := by
          simpa [hen, hk] using hrel.symm
        subst a
        simp [Plain.step]

/-- Exact callTail for the argument schedule emitted by Counted.transition.
Child contexts do not affect the caller recovered by the decoder. -/
theorem callTail_arguments (args : List (Expr × Nat)) (ctx : Context)
    (name : String) (arity : Nat) (rest : List Task) :
    Control.callTail
      (args.flatMap (fun (e,i) => [.eval e (child ctx i), .capture]) ++
        .enter name arity ctx :: rest) =
      some ⟨name, arity, ctx, args.map Prod.fst, rest⟩ := by
  induction args with
  | nil => rfl
  | cons pair args ih =>
    cases pair
    simp [Control.callTail, ih]

/-- Specialization to the exact zipIdx schedule used by call dispatch. -/
theorem callTail_dispatch (args : List Expr) (ctx : Context)
    (name : String) (rest : List Task) :
    Control.callTail
      (args.zipIdx.flatMap (fun (e,i) => [.eval e (child ctx i), .capture]) ++
        .enter name args.length ctx :: rest) =
      some ⟨name, args.length, ctx, args, rest⟩ := by
  simpa only [List.zipIdx_map_fst] using
    callTail_arguments args.zipIdx ctx name args.length rest

/-- Capturing the current argument appends it to the source-order prefix;
the counted operand stack itself remains in reverse order. -/
theorem argument_order (v : Slot) (slots : List Slot) (n : Nat) :
    ((v :: slots).take (n+1)).reverse.map Slot.value =
      (slots.take n).reverse.map Slot.value ++ [v.value] := by
  simp

/-- Rank half of the Decompose case at the actual committed step boundary.
Decoder preservation for this task is a separate, still unproved case. -/
theorem decompose_step_rank
    (hs : s.tasks = .decompose h tail body bid ctx :: rest)
    (ha : s.answer = none) (ht : Counted.step p s = .ok t) :
    Control.rank t < Control.rank s := by
  obtain ⟨c, hc, rfl⟩ := step_commit ha ht
  exact decompose_rank_commit p s h tail body bid ctx rest c hs hc

/-- Structural dispatch preserves the actual decoded continuation suffix. -/
theorem env_tasks (s : State) (tasks : List Task) (answer : Option Slot) (names : Env) :
    Control.env { s with tasks := tasks, answer := answer } names = Control.env s names := rfl

theorem continuations_tasks (s : State) (tasks : List Task) (answer : Option Slot) (n : Nat)
    (ts : List Task) (vs : List Slot) :
    Control.continuations { s with tasks := tasks, answer := answer } n ts vs =
      Control.continuations s n ts vs :=
  continuations_bindings { s with tasks := tasks, answer := answer } s rfl n ts vs

inductive Structural : Expr → Prop
  | bin (op a b) : Structural (.bin op a b)
  | letE (x a b) : Structural (.letE x a b)
  | ifE (c t e) : Structural (.ifE c t e)
  | matchE (v n h t c) : Structural (.matchE v n h t c)

theorem structural_step (he : Structural e)
    (hs : s.tasks = .eval e ctx :: rest) (ha : s.answer = none)
    (hrel : Related a s) (ht : Counted.step p s = .ok t) :
    Related (Plain.step p a) t := by
  obtain ⟨change, hc, rfl⟩ := step_commit ha ht
  cases he <;> simp [Counted.transition, hs] at hc <;> cases hc
  all_goals
    unfold Related at hrel ⊢
    rw [decode_commit]
    unfold Control.decode at hrel ⊢
    simp only [ha, hs, List.length_cons, Control.focus] at hrel ⊢
    simp only [Control.continuations, child]
    simp only [env_tasks, continuations_tasks]
    cases hen : Control.env s ctx.env with
    | error why => simp [hen] at hrel
    | ok env =>
      cases hk : Control.continuations s (rest.length + 2) rest s.slots with
      | error why => simp [hen, hk] at hrel
      | ok ks =>
        have hea := hrel.symm
        simp [hen, hk] at hea
        subst a
        simp only [Plain.step]
        try rw [continuations_fuel s _ (rest.length + 2) rest s.slots
          (by omega) (by omega)]
        simp [hen, hk]

/-- Zero-argument dispatch merely installs Enter; the Plain call step occurs
at Enter, not at this dispatch boundary. -/
theorem dispatch_zero_step
    (hs : s.tasks = .eval (.call name []) ctx :: rest)
    (ha : s.answer = none) (hrel : Related a s)
    (ht : Counted.step p s = .ok t) :
    Related a t ∧ Control.rank t < Control.rank s := by
  obtain ⟨change, hc, rfl⟩ := step_commit ha ht
  simp [Counted.transition, hs] at hc
  cases hc
  constructor
  · unfold Related at hrel ⊢
    rw [decode_commit]
    simpa [Control.decode, ha, hs, Control.focus, env_tasks,
      continuations_tasks] using hrel
  · simp only [Control.rank, commit, hs, ← List.sum_eq_foldl_nat,
      List.map_cons, List.sum_cons]
    simp

end Full.Proofs.Forward
