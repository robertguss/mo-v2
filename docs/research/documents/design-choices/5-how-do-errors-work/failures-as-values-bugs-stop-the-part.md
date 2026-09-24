# Failures as values, bugs stop the part

**Label:** Chosen (D29)

Robert's choice (D29).
* Failures are success-or-failure values; the checker makes sure they are handled; a shortcut passes them upward; each function lists the failures it can produce.
* Bugs stop that part of the program immediately and are reported. What restarts it is left to running programs.
* No thrown exceptions.

Why:
* Every failure is visible where it can happen (same rule as D25, D28).
* A program that has proven itself wrong should not keep writing data.
* Natural in a pure language; how Rust and Erlang split the two kinds.
