# 5 How do errors work?

Two kinds of going wrong:
* Failures: the world misbehaved (file missing, card declined, network down). Expected; a good program plans for them.
* Bugs: the program misbehaved (divide by zero, overflow, a promise turning out false). Not expected; the program is wrong.

Status: Decided: D29.

## Contents

* [Declared exceptions](declared-exceptions.md)
* [Error codes you might check](error-codes-you-might-check.md)
* [Errors as values](errors-as-values.md)
* [Exceptions](exceptions.md)
* [Failures as values, bugs stop the part](failures-as-values-bugs-stop-the-part.md) (Chosen (D29))
* [Let it crash, supervisor restarts](let-it-crash-supervisor-restarts.md)
