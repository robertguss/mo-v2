# 10 How are numbers represented?

Every language stores whole numbers somehow. Fixed-size numbers (usually 64 bits) are what the hardware handles directly, so they are fast, but they have a ceiling, and what happens when a result passes it is the real choice. Unlimited-size numbers never overflow but cost more. Experiment 3, benchmark 4, measured that cost in Koka: unlimited-size numbers were 1.68× slower than fixed-size int64.

Status: Open (D58). To be tested the data-first way (D38) before an answer is chosen. Nothing here is decided; v1's crash on overflow is in the parking lot.

Related: D25 (no guessing) and D29 (bugs stop the part that hit them) bear on the options.

## Contents

* [Unlimited size by default](unlimited-size-by-default.md)
* [Fixed size, stop on overflow](fixed-size-stop-on-overflow.md)
* [Fixed size, wrap silently](fixed-size-wrap-silently.md)
* [Several types, chosen explicitly](several-types-chosen-explicitly.md)
