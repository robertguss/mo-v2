# Never guesses, risky conversions can fail

**Label:** Chosen (D25)

As Never guesses, plus any conversion that could lose information or fail (text to number, big number into a small container) gives success or failure, which must be handled.

* Languages: Rust's strict conversions, Ada, Elm.
* Robert chose this (D25). Why: a guess is a hidden decision nobody would notice; being explicit costs an agent almost nothing; it keeps everything the checker reasons about written down.
