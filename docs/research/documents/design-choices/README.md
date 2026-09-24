# Design choices

Working through the big design choices with Robert, one at a time, from a blank slate (started 23 Sep 2026).

* Each child is one choice. Its children are the options discussed.
* The option Robert chose carries the label Chosen, with its decision number. Decisions are recorded in the repo's [DECISIONS.md](https://github.com/robertguss/mo-v2/blob/main/docs/DECISIONS.md).
* Working assumption behind the recommendations: the code is written by AI agents, and it has to be trustworthy without a human reading it.

## Summary (23 Sep 2026)
* 1 Mistakes caught: static floor, contracts and proof on top (D24).
* 2 Guessing: never; risky conversions can fail (D25).
* 3 Change: pure, invisible in-place updates, provable demands; to be tested (D26). Speed very important, not fastest possible (D27).
* 4 Nothing: no null; maybe is a value (D28).
* 5 Errors: failures as values, bugs stop the part (D29).
* 6 Effects: listed effects plus keys, runtime holds the doors (D30).
* 7 Organisation: plain data, modules, limited shared abilities; no OOP (D31).
* 8 Memory: counting holders; pools to explore (D32).
* 9 Look: keywords and end, Ruby and Elixir spirit (D33).
* 10 Numbers: open, to be tested (D58).
* 11 Sequences: open, first experiment after 3b (D65).

Open threads: experiment for D26 (and suggested for D30); pools and where long-lived state lives (running programs); how limited shared abilities are; the spec language's look. Close neighbour worth studying: Gleam (typed, BEAM).

Next (D34, D35): one Ruby/Elixir-like language doing all of the above through its compiler and runtime; syntax and how promises are written are deferred; next step is experiments on D24–D33.

## Contents

* [1 When are mistakes caught?](1-when-are-mistakes-caught/README.md)
* [2 Does the language guess what you meant?](2-does-the-language-guess-what-you-meant/README.md)
* [3 Can things change after they are made?](3-can-things-change-after-they-are-made/README.md)
* [4 How is nothing represented?](4-how-is-nothing-represented/README.md)
* [5 How do errors work?](5-how-do-errors-work/README.md)
* [6 What can code do behind your back?](6-what-can-code-do-behind-your-back/README.md)
* [7 How is a program organised?](7-how-is-a-program-organised/README.md)
* [8 Who cleans up memory?](8-who-cleans-up-memory/README.md)
* [9 What does it look like?](9-what-does-it-look-like/README.md)
* [10 How are numbers represented?](10-how-are-numbers-represented/README.md)
* [11 How are sequences stored and updated?](11-how-are-sequences-stored-and-updated/README.md)
* [Neighbouring languages](neighbouring-languages/README.md)
