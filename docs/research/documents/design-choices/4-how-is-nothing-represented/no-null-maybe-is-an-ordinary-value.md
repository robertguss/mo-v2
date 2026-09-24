# No null, maybe is an ordinary value

**Label:** Chosen (D28)

Robert's choice (D28). A lookup returns either here it is or nothing; the only way to use the value is to handle both cases, and the checker makes sure.

* Languages: Rust (Option), Elm and Haskell (Maybe), OCaml, Roc.

Why:
* Removes a whole category of crash.
* Never fakes data (fits D25).
* Simpler than a tracked null: no special rules or escape hatches.
* Natural in a pure language (D26).
