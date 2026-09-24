# Listed effects plus keys, runtime holds the doors

**Label:** Chosen (D30)

Robert's choice (D30).
* Every function lists the kinds of effects it has, checked to be complete; no effects listed means it only calculates.
* Code can touch only what it is handed; the program starts with the keys the runtime gives it.
* Tests and replays can swap in pretend worlds.
* Long-lived state is held by the runtime or long-running parts (Erlang-style); details belong to running programs.

Why:
* With nobody reading code, a function's description has to be the truth, about effects too.
* Makes promises like never touches the network checkable (D24).
* Contains damage from bugs and bad dependencies.

Caveat: the most machinery of any choice so far; effect systems are young, research-heavy territory. An experiment was suggested.
