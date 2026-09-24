# Pure, with invisible in-place updates and provable demands

**Label:** Chosen (D26)

Robert's choice for now (D26), to be tested by experiments.

* No value is ever changed in place, from the program's point of view.
* The compiler counts who holds each value and edits in place when only one does (functional but in-place; used by Lean 4, Koka, Roc).
* Where speed matters, the writer can demand in-place updating; the checker proves it or refuses the program (Koka's fip, Clean's uniqueness types).

Why: Robert wants Rust's speed, control and if-it-compiles-it-runs confidence with a functional language's simplicity. The confidence comes mostly from strict checking (D24, D25); this blend adds guaranteed speed where it matters.

Caveats:
* Research territory; Koka's fip covers fewer programs than Rust.
* Counting holders has a small cost; slower than Rust at the extremes (fine under D27).
* Linked to choice 8 (memory cleanup).
* Experiment needed: does the helper fire reliably, and can agents use the in-place demands?
