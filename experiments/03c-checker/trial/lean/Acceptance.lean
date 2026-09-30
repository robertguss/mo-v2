import Promises
import Proofs

/-!
LOCKED. This file states the four promises at the locked statements of
`Promises.lean`, with every name written in full from the root, so that nothing a
builder file declares can change which statement is meant. It compiles only if the
builder's proofs have exactly those statements. The axioms printed below must be
no more than `propext`, `Classical.choice` and `Quot.sound`; anything else (such as
`sorryAx`) means the work is not accepted.
-/

theorem Trial.accepted_a : _root_.Trial.PromiseA := _root_.Trial.promiseA
theorem Trial.accepted_b : _root_.Trial.PromiseB := _root_.Trial.promiseB
theorem Trial.accepted_c : _root_.Trial.PromiseC := _root_.Trial.promiseC
theorem Trial.accepted_d : _root_.Trial.PromiseD := _root_.Trial.promiseD

#print axioms Trial.accepted_a
#print axioms Trial.accepted_b
#print axioms Trial.accepted_c
#print axioms Trial.accepted_d
