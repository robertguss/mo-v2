# Experiment 1: result

22 Sep 2026. Decided in D11 and D12.

## What was built

A type checker for a tiny language (numbers, booleans, `+`, `==`, `if`), written
in Lean by a builder agent, with two proofs checked by Lean's kernel:

- **Safe:** every program the checker approves runs to a value of the type the
  checker gave it. It never gets stuck.
- **Useful:** the checker accepts the 5 programs Robert said it must accept and
  rejects the 4 he said it must reject.

## How it was checked

The builder could write only `Tiny/Checker.lean`. The lead then:

1. confirmed `Tiny/Spec.lean` was unchanged (SHA-256 `22d62fd4…e345`, as
   locked);
2. rebuilt everything from clean: `lake build` succeeded;
3. read Lean's list of what the proofs rely on: only `propext`, a standard
   axiom. No `sorry`, no shortcuts;
4. broke the checker on purpose in a scratch copy, letting `if` accept a number
   as its condition. Both proofs then failed, as they should. The proofs are
   doing real work.

## One correction

The locked `Tiny/Accept.lean` had its `import` lines in the wrong place, so it
could not compile. The lead wrote that file, so the lead fixed it by moving two
lines, with nothing else changed. The builder correctly refused to touch it. New
SHA-256: `856b1fd1…`.

## What it answered

| Unknown                                       | Answer                                                                                                                   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Can an AI build and prove this in Lean?       | Yes. About 1 minute, and the proofs worked on the first attempt.                                                         |
| Does the lock hold?                           | Yes. The builder hit a bug in a locked file and reported it instead of editing it.                                       |
| Is a proof with only a safety promise enough? | No. A checker that rejects everything passes `Safe`; Lean proved it. Examples Robert approves (`Useful`) close that gap. |
| Can Robert follow what the theorem promises?  | Robert's call; see the conversation of 22 Sep.                                                                           |

## Limits

This is a toy. It has no variables, functions, loops, errors or I/O, so its
evaluation always finishes, and the proof was easy. The real test is whether the
method still works as the language grows.
