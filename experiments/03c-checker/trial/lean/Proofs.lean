import Promises
import Proofs.MatchContract

/-!
This file is the stub the phase-2 builder replaces the bodies of. The statements
stay exactly as they are; only each `sorry` is to be replaced by a proof.
-/

namespace Trial

theorem promiseA : PromiseA := by
  intro e s h
  exact (Proofs.promises_of_contract e (Proofs.eval_contract e) s h).1

theorem promiseB : PromiseB := by
  intro e s h
  exact (Proofs.promises_of_contract e (Proofs.eval_contract e) s h).2.1

theorem promiseC : PromiseC := by
  intro e s h
  exact (Proofs.promises_of_contract e (Proofs.eval_contract e) s h).2.2.1

theorem promiseD : PromiseD := by
  intro e s h
  exact (Proofs.promises_of_contract e (Proofs.eval_contract e) s h).2.2.2

end Trial
