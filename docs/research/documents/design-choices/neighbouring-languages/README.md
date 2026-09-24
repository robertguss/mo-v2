# Neighbouring languages

Existing languages that share parts of Mo's design choices (D24-D33), and what each lacks. No single language combines them all; the novel part is the combination and the purpose (a spec a human reads, code agents write, a checker joining them).

What is new territory:
* Proof and contracts together with listed effects plus capabilities, in one checker (F* comes closest, without capabilities).
* In-place demands the checker proves, inside a language that also proves logic.
* A spec language designed for a human who never reads code.
* Designing every choice around agents as the writers.

The risk: each piece exists, but the pieces interact, and the integration is research-level.

## Contents

* [Dafny and SPARK Ada](dafny-and-spark-ada.md)
* [Elixir and Erlang](elixir-and-erlang.md)
* [F*](f-star.md)
* [Gleam](gleam.md)
* [Koka](koka.md)
* [Lean 4](lean-4.md)
* [Pony and Austral](pony-and-austral.md)
* [Roc](roc.md)
