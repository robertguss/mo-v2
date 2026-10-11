import Full.Statements

/-! A negative result for the unchanged frozen F2 statement. All witnesses are
computed by the actual begin/advance/step definitions, and checked by reduction
in the kernel. There is no alternative evaluator or altered rank. -/
namespace Full.Proofs.RankCounterexample

def program : Program :=
  ⟨[⟨"f",[],.number,.num 3,false⟩],
    .matchE (.bin .cons (.num 1) (.bin .cons (.num 2) .nil))
      (.num 0) "h" "t" (.call "f" [])⟩

def initial : Trial.Start := ⟨[],[],[]⟩

def first : Counted.State :=
  (Counted.begin program initial).toOption.getD
    {mem := initial.toMemory, outside := []}

def source : Counted.State :=
  (Counted.advance program 14 first).toOption.getD first

def target : Counted.State :=
  (Counted.step program source).toOption.getD first

def plain : Plain.State :=
  ⟨.eval (.call "f" []) [("t",.list [2]),("h",.num 1)],[]⟩

theorem begin_ok : Counted.begin program initial = .ok first := by rfl'

theorem advance_ok : Counted.advance program 14 first = .ok source := by rfl'

theorem reachable : Statements.Reachable program initial source :=
  ⟨first,14,begin_ok,advance_ok⟩

theorem unfinished : source.answer = none := by rfl'

theorem step_ok : Counted.step program source = .ok target := by rfl'

theorem source_decode : Control.decode source = .ok plain := by rfl'

theorem target_decode : Control.decode target = .ok plain := by rfl'

theorem source_rank : Control.rank source = 19 := by rfl'

theorem target_rank : Control.rank target = 19 := by rfl'

theorem plain_step_changes : Plain.step program plain ≠ plain := by
  simp [Plain.step,Plain.enter,program,plain,signature]

/-- Neither disjunct in F2's one-step obligation holds at this reachable state. -/
theorem failed_obligation :
    ¬ (Statements.Related (Plain.step program plain) target ∨
      (Statements.Related plain target ∧ Control.rank target < Control.rank source)) := by
  rintro (h | ⟨_,h⟩)
  · exact plain_step_changes (Except.ok.inj (h.symm.trans target_decode))
  · rw [source_rank,target_rank] at h
    omega

/-- The exact frozen F2 is false, not merely unproved by this implementation. -/
theorem not_f2 : ¬ Statements.F2 := by
  intro hf
  obtain ⟨a,ha,hstep⟩ := hf.2.1 program initial source reachable
  have he : a = plain := Except.ok.inj (ha.symm.trans source_decode)
  subst a
  exact failed_obligation (hstep target step_ok unfinished)

/-- A shared scrutinee needs an additional MatchComplete task. Raising only
the Decompose weight from 10 to 11 would still leave this case nondecreasing. -/
def sharedProgram : Program :=
  ⟨program.functions,.matchE (.var "x") (.num 0) "h" "t" (.call "f" [])⟩

def sharedInitial : Trial.Start :=
  ⟨[⟨0,1,some 1,2⟩,⟨1,2,none,1⟩],[("x",.list (some 0))],[some 0]⟩

def sharedFirst : Counted.State :=
  (Counted.begin sharedProgram sharedInitial).toOption.getD
    {mem := sharedInitial.toMemory, outside := sharedInitial.outside}

def sharedSource : Counted.State :=
  (Counted.advance sharedProgram 4 sharedFirst).toOption.getD sharedFirst

def sharedTarget : Counted.State :=
  (Counted.step sharedProgram sharedSource).toOption.getD sharedFirst

theorem shared_begin_ok : Counted.begin sharedProgram sharedInitial = .ok sharedFirst := by rfl'

theorem shared_advance_ok : Counted.advance sharedProgram 4 sharedFirst = .ok sharedSource := by rfl'

theorem shared_step_ok : Counted.step sharedProgram sharedSource = .ok sharedTarget := by rfl'

theorem shared_reachable : Statements.Reachable sharedProgram sharedInitial sharedSource :=
  ⟨sharedFirst,4,shared_begin_ok,shared_advance_ok⟩

theorem shared_stutter : Control.decode sharedSource = Control.decode sharedTarget := by rfl'

theorem shared_ranks : Control.rank sharedSource = 19 ∧ Control.rank sharedTarget = 20 := by
  constructor <;> rfl'

end Full.Proofs.RankCounterexample

#print axioms Full.Proofs.RankCounterexample.not_f2
#print axioms Full.Proofs.RankCounterexample.shared_ranks
