# Counted reuse when uniquely held

The runtime counts holders. When a value has exactly one, the update happens in place; otherwise it copies. Invisible to the program, and what D26 already chose for values in general. Experiment 3 tested it for linked structures; its behaviour on arrays is what the choice 11 experiment measures.

* Languages: Lean (Array), Swift (copy-on-write arrays), Koka (Perceus, for constructors), Roc.
