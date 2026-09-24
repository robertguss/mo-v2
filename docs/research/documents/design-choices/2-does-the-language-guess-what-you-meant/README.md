# 2 Does the language guess what you meant?

When two things don't quite match, does the language quietly convert one, or refuse and make the writer say exactly what they mean? Test cases: "5" + 3, 2 + 0.5, 3.9 into a whole number, if customer_list, 0 == "0".

Status: Decided: D25.

## Contents

* [Guesses freely](guesses-freely.md)
* [Guesses only safe-looking cases](guesses-only-safe-looking-cases.md)
* [Never guesses](never-guesses.md)
* [Never guesses, risky conversions can fail](never-guesses-risky-conversions-can-fail.md) (Chosen (D25))
