import Full.Demand.Certificates
import Full.Counted

namespace Full.Demand.Tickets
open Counted

/-- Empty scopes remain present until their lexical match exits. -/
structure Scope where
  branch : Nat
  address : Option Nat

def counts (scopes : List Scope) : List Nat :=
  scopes.map (fun s => if s.address.isSome then 1 else 0)

def reservations (inv : Nat) (scopes : List Scope) : List Reservation :=
  scopes.filterMap (fun s => s.address.map (fun a => ⟨inv,s.branch,a⟩))

def consume (inv : Nat) : List Scope → Option (Reservation × List Scope)
  | [] => none
  | ⟨bid,none⟩::ss => (consume inv ss).map (fun (r,ss') => (r,⟨bid,none⟩::ss'))
  | ⟨bid,some addr⟩::ss => some (⟨inv,bid,addr⟩,⟨bid,none⟩::ss)

theorem reservation_fields (hr : r ∈ reservations inv scopes) :
    r.invocation = inv ∧ r.branch ∈ scopes.map Scope.branch := by
  obtain ⟨s,hs,he⟩ := List.mem_filterMap.mp hr
  cases ha : s.address with
  | none => simp [ha] at he
  | some a =>
    simp only [ha,Option.map_some,Option.some.injEq] at he
    subst r
    exact ⟨rfl,List.mem_map.mpr ⟨s,hs,rfl⟩⟩

theorem consume_of_spend (h : spend (counts ss) = .ok after) :
    ∃ r ss', consume inv ss = some (r,ss') ∧ counts ss' = after := by
  induction ss generalizing after with
  | nil => simp [counts,spend] at h
  | cons s ss ih =>
    obtain ⟨bid,address⟩ := s
    cases address with
    | none =>
      simp only [counts,List.map_cons,Option.isSome_none,Bool.false_eq_true,↓reduceIte,
        spend,Full.Proofs.PlainTyping.bind_ok] at h
      obtain ⟨tail,ht,he⟩ := h
      simp only [Full.Proofs.PlainTyping.pure_eq,Except.ok.injEq] at he
      subst after
      obtain ⟨r,ss',hc,ha⟩ := ih ht
      exact ⟨r,⟨bid,none⟩::ss',by simp [consume,hc],by simp [counts] at ha ⊢; exact ha⟩
    | some addr =>
      simp only [counts,List.map_cons,Option.isSome_some,↓reduceIte,spend,Except.ok.injEq] at h
      exact ⟨⟨inv,bid,addr⟩,⟨bid,none⟩::ss,rfl,by simpa [counts] using h⟩

/-- The static spend need not select the same scope as the concrete spend.
The concrete remainder still dominates the promised static remainder. -/
theorem consume_lower (lower : Lower before (counts ss)) (h : spend before = .ok after) :
    ∃ r ss', consume inv ss = some (r,ss') ∧ Lower after (counts ss') := by
  obtain ⟨actual,ha,hl⟩ := spend_monotone lower h
  obtain ⟨r,ss',hc,he⟩ := consume_of_spend (inv := inv) ha
  exact ⟨r,ss',hc,he ▸ hl⟩

theorem consume_shape (h : consume inv ss = some (r,ss')) :
    ss'.map Scope.branch = ss.map Scope.branch ∧
    r ∈ reservations inv ss ∧ r.invocation = inv := by
  induction ss generalizing ss' with
  | nil => simp [consume] at h
  | cons s ss ih =>
    obtain ⟨bid,address⟩ := s
    cases address with
    | none =>
      cases hc : consume inv ss with
      | none => simp [consume,hc] at h
      | some pair =>
        obtain ⟨q,qs⟩ := pair
        simp only [consume,hc,Option.map_some,Option.some.injEq,Prod.mk.injEq] at h
        obtain ⟨rfl,rfl⟩ := h
        obtain ⟨hids,hm,hi⟩ := ih hc
        exact ⟨by simp [hids],by simpa [reservations] using hm,hi⟩
    | some addr =>
      simp only [consume,Option.some.injEq,Prod.mk.injEq] at h
      obtain ⟨rfl,rfl⟩ := h
      exact ⟨rfl,by simp [reservations],rfl⟩

theorem consume_front (h : consume inv ss = some (r,ss')) :
    ∃ rest, reservations inv ss = r::rest := by
  induction ss generalizing ss' with
  | nil => simp [consume] at h
  | cons s ss ih =>
    obtain ⟨bid,address⟩ := s
    cases address with
    | none =>
      cases hc : consume inv ss with
      | none => simp [consume,hc] at h
      | some pair =>
        obtain ⟨q,qs⟩ := pair
        simp only [consume,hc,Option.map_some,Option.some.injEq,Prod.mk.injEq] at h
        obtain ⟨rfl,rfl⟩ := h
        simpa only [reservations,List.filterMap_cons,Option.map_none] using ih hc
    | some addr =>
      simp only [consume,Option.some.injEq,Prod.mk.injEq] at h
      obtain ⟨rfl,rfl⟩ := h
      exact ⟨reservations inv ss,rfl⟩

/-- Concrete lookup sees the first occupied local scope. Foreign reservations
are behind that exact prefix and cannot alter the selected address. -/
theorem consume_find (h : consume inv ss = some (r,ss')) :
    (reservations inv ss ++ suffix).find? (fun q =>
      q.invocation == inv && (ss.map Scope.branch).contains q.branch) = some r := by
  obtain ⟨rest,he⟩ := consume_front h
  obtain ⟨hi,hb⟩ := reservation_fields (consume_shape h).2.1
  have hp : (r.invocation == inv && (ss.map Scope.branch).contains r.branch) = true := by
    simp [hi,hb]
  rw [he]
  simp only [List.cons_append,List.find?_cons,hp,↓reduceIte]

theorem consume_filter (h : consume inv ss = some (r,ss'))
    (unique : ((reservations inv ss ++ suffix).map Reservation.addr).Nodup) :
    (reservations inv ss ++ suffix).filter (fun q => q.addr != r.addr) =
      reservations inv ss' ++ suffix := by
  induction ss generalizing ss' with
  | nil => simp [consume] at h
  | cons s ss ih =>
    obtain ⟨bid,address⟩ := s
    cases address with
    | none =>
      cases hc : consume inv ss with
      | none => simp [consume,hc] at h
      | some pair =>
        obtain ⟨q,qs⟩ := pair
        simp only [consume,hc,Option.map_some,Option.some.injEq,Prod.mk.injEq] at h
        obtain ⟨rfl,rfl⟩ := h
        simpa only [reservations,List.filterMap_cons,Option.map_none] using ih (ss' := qs) hc unique
    | some addr =>
      simp only [consume,Option.some.injEq,Prod.mk.injEq] at h
      obtain ⟨rfl,rfl⟩ := h
      simp only [reservations,List.filterMap_cons,Option.map_some,Option.map_none,
        List.cons_append,List.map_cons,List.nodup_cons] at unique ⊢
      simp only [List.filter_cons,bne_self_eq_false,↓reduceIte,List.nil_append]
      apply List.filter_eq_self.mpr
      intro q hq
      have hne : q.addr ≠ addr := by
        intro he
        exact unique.1 (List.mem_map.mpr ⟨q,hq,he⟩)
      simpa using hne

structure Activation where
  invocation : Nat
  scopes : List Scope

def flatten (stack : List Activation) : List Reservation :=
  stack.flatMap (fun a => reservations a.invocation a.scopes)

structure Budget where
  invocation : Nat
  branches : List Nat
  credits : List Nat

def Covers (budget : Budget) (actual : Activation) : Prop :=
  budget.invocation = actual.invocation ∧ budget.branches = actual.scopes.map Scope.branch ∧
    Lower budget.credits (counts actual.scopes)

inductive StackCovers : List Budget → List Activation → Prop
  | nil : StackCovers [] []
  | cons : Covers b a → StackCovers bs actual → StackCovers (b::bs) (a::actual)

def Valid (root nextInvocation nextBranch : Nat) (stack : List Activation) : Prop :=
  (stack.map Activation.invocation).Nodup ∧ ∀ a ∈ stack,
    root ≤ a.invocation ∧ a.invocation < nextInvocation ∧
    (a.scopes.map Scope.branch).Nodup ∧ ∀ bid ∈ a.scopes.map Scope.branch, bid < nextBranch

theorem Valid.monotone (h : Valid root ni nb stack) (hi : ni ≤ ni') (hb : nb ≤ nb') :
    Valid root ni' nb' stack := by
  refine ⟨h.1,?_⟩
  intro a ha
  obtain ⟨hl,hu,hn,hbs⟩ := h.2 a ha
  exact ⟨hl,Nat.lt_of_lt_of_le hu hi,hn,fun b hm => Nat.lt_of_lt_of_le (hbs b hm) hb⟩

theorem Valid.tail (h : Valid root ni nb (a::stack)) : Valid root ni nb stack :=
  ⟨(List.nodup_cons.mp h.1).2,fun b hb => h.2 b (List.mem_cons_of_mem _ hb)⟩

theorem Valid.replace (h : Valid root ni nb (a::stack))
    (hi : a'.invocation = a.invocation)
    (hs : a'.scopes.map Scope.branch = a.scopes.map Scope.branch) :
    Valid root ni nb (a'::stack) := by
  refine ⟨by simpa only [List.map_cons,hi] using h.1,?_⟩
  intro b hb
  rcases List.mem_cons.mp hb with rfl | hb
  · simpa only [hi,hs] using h.2 a List.mem_cons_self
  · exact h.2 b (List.mem_cons_of_mem _ hb)

theorem Valid.push_scope (h : Valid root ni nb (a::stack)) :
    Valid root ni (nb+1) ({ a with scopes := ⟨nb,none⟩::a.scopes }::stack) := by
  refine ⟨h.1,?_⟩
  intro b hb
  rcases List.mem_cons.mp hb with rfl | hb
  · obtain ⟨hl,hu,hn,hbs⟩ := h.2 a List.mem_cons_self
    refine ⟨hl,hu,?_,?_⟩
    · simp only [List.map_cons,List.nodup_cons]
      exact ⟨fun hm => Nat.lt_irrefl nb (hbs nb hm),hn⟩
    · intro bid hm
      rcases List.mem_cons.mp hm with rfl | hm
      · omega
      · have := hbs bid hm; omega
  · exact (h.monotone (Nat.le_refl ni) (by omega)).2 b (List.mem_cons_of_mem _ hb)

theorem Valid.pop_scope (h : Valid root ni nb (⟨inv,scope::ss⟩::stack)) :
    Valid root ni nb (⟨inv,ss⟩::stack) := by
  refine ⟨h.1,?_⟩
  intro b hb
  rcases List.mem_cons.mp hb with rfl | hb
  · obtain ⟨hl,hu,hn,hbs⟩ := h.2 ⟨inv,scope::ss⟩ List.mem_cons_self
    exact ⟨hl,hu,(List.nodup_cons.mp hn).2,fun bid hm => hbs bid (List.mem_cons_of_mem _ hm)⟩
  · exact h.2 b (List.mem_cons_of_mem _ hb)

theorem Valid.push_call (h : Valid root ni nb stack) (hroot : root ≤ ni) :
    Valid root (ni+1) nb (⟨ni,[]⟩::stack) := by
  refine ⟨?_,?_⟩
  · simp only [List.map_cons,List.nodup_cons]
    refine ⟨?_,h.1⟩
    intro hm
    obtain ⟨a,ha,hi⟩ := List.mem_map.mp hm
    have := (h.2 a ha).2.1
    omega
  · intro a ha
    rcases List.mem_cons.mp ha with rfl | ha
    · exact ⟨hroot,Nat.lt_succ_self ni,by simp,by simp⟩
    · exact (h.monotone (by omega) (Nat.le_refl nb)).2 a ha

theorem flatten_fields (hr : r ∈ flatten stack) :
    ∃ a ∈ stack, r.invocation = a.invocation ∧ r.branch ∈ a.scopes.map Scope.branch := by
  obtain ⟨a,ha,hr⟩ := List.mem_flatMap.mp hr
  exact ⟨a,ha,reservation_fields hr⟩

/-- The caller suffix and suspended invocations cannot be expired by the
current branch. Within this activation the branch ID occurs exactly once. -/
theorem branch_filter (valid : Valid root ni nb (⟨inv,⟨bid,addr⟩::ss⟩::stack))
    (older : ∀ r ∈ old, r.invocation < root) :
    (reservations inv (⟨bid,addr⟩::ss) ++ flatten stack ++ old).filter
        (fun r => r.invocation == inv && r.branch == bid) =
      reservations inv [⟨bid,addr⟩] := by
  have hv := valid.2 ⟨inv,⟨bid,addr⟩::ss⟩ List.mem_cons_self
  have hnot := (List.nodup_cons.mp hv.2.2.1).1
  have hother := (List.nodup_cons.mp valid.1).1
  have hnone : (reservations inv ss ++ flatten stack ++ old).filter
      (fun r => r.invocation == inv && r.branch == bid) = [] := by
    apply List.filter_eq_nil_iff.mpr
    intro r hr
    cases he : (r.invocation == inv && r.branch == bid) with
    | false => simp
    | true =>
      simp only [Bool.and_eq_true,beq_iff_eq] at he
      exfalso
      rcases List.mem_append.mp hr with hr | hr
      · rcases List.mem_append.mp hr with hr | hr
        · obtain ⟨_,hb⟩ := reservation_fields hr
          exact hnot (he.2 ▸ hb)
        · obtain ⟨a,ha,hi,_⟩ := flatten_fields hr
          exact hother (List.mem_map.mpr ⟨a,ha,hi.symm.trans he.1⟩)
      · have := older r hr
        dsimp only at hv
        omega
  simp only [reservations] at hnone
  cases addr <;> simp only [reservations,List.filterMap_cons,List.filterMap_nil,
    Option.map_some,Option.map_none,List.cons_append,List.nil_append,List.filter_cons,
    beq_self_eq_true,Bool.true_and,↓reduceIte,List.filter_nil]
  all_goals rw [hnone]

end Full.Demand.Tickets
