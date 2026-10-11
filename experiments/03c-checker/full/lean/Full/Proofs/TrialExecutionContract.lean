import Full.Proofs.TrialSimulationRelease

namespace Full.Proofs.TrialExecution
open Counted Statements TrialCompatibilitySimulation TrialRelease

/-- The finite Trial language has no calls: all reservations surrounding an
expression belong to this invocation and to still-active enclosing branches. -/
def Enclosing (ctx : Context) (s : State) : Prop :=
  ∀ r ∈ s.reservations, r.invocation = ctx.invocation ∧ r.branch ∈ ctx.branches

/-- Exact simulation of a successful recursive Trial evaluation, with arbitrary
saved work and older operands. The log may accumulate, but every observation
field required by F6 is retained. This is an induction goal, not an axiom. -/
def Evaluation (e : Trial.Expr) : Prop :=
  ∀ (p : Program) (initial : Trial.Start) (s : State) (ctx : Context)
    (rest : List Task) (frames : List Trial.Frame) (log : List Trial.LogEvent)
    (raw : Raw) (u : Trial.RunState),
    Reachable p initial s → s.tasks = .eval (embed e) ctx :: rest →
    s.answer = none → Future rest frames → Enclosing ctx s →
    Trial.evalC .approved e ctx.env frames ctx.branches (logged s log) = (.ok raw, u) →
    ∃ ticks t v, Counted.advance p ticks s = .ok t ∧ Reachable p initial t ∧
      t.tasks = rest ∧ t.slots = v :: s.slots ∧ v.raw = raw ∧
      t.answer = none ∧ eraseLog u = observe t ∧ Enclosing ctx t

end Full.Proofs.TrialExecution
