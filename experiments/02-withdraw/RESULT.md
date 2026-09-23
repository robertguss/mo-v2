# Experiment 2: result

22 Sep 2026. Decided in D16–D18.

## What ran

- **The spec:** Robert approved four promises and six examples for
  `withdraw(balance, amount)`, in whole cents.
- **Two correct versions:** builder A and builder B wrote them independently,
  each in a visible pane. Both are proven correct in Lean. Each took under a
  minute, and both proofs worked on the first attempt.
- **Ten buggy versions:** a planter agent made them, each a copy of A with one
  realistic bug. Five show up on ordinary or edge inputs. Five show up only on
  rare or large inputs: boundaries at 2^31, 2^32 and 2^64, and a hidden
  1,000,000-cent limit. The key is in `Withdraw/Mutants/KEY.md`.
- **Seven methods:** each was run against all twelve versions. The five
  automated methods ran in `lake exe score`. The Lean proof column uses the
  planter's trigger inputs, and `holdsAt_iff` (proven in `Oracle.lean`) shows
  that no proof can exist for a version that breaks a promise. For the AI
  council, Codex (`gpt-6-astra`) reviewed all 11 versions blind and shuffled (A
  plus the ten buggy ones); the lead checked every counterexample it gave.

## Scoreboard

| Bug                           | Kind     | Examples | Property | Exhaustive 0–200 | Contracts | Differential | Lean proof | Codex review |
| ----------------------------- | -------- | -------- | -------- | ---------------- | --------- | ------------ | ---------- | ------------ |
| M01 balance check backwards   | ordinary | ✔        | ✔        | ✔                | ✔         | ✔            | ✔          | ✔            |
| M02 wrong error for overdraft | ordinary | ✔        | ✔        | ✔                | ✔         | ✔            | ✔          | ✔            |
| M03 subtraction reversed      | ordinary | ✔        | ✔        | ✔                | ✔         | ✔            | ✔          | ✔            |
| M04 exact balance refused     | edge     | ✔        | ✔        | ✔                | –         | ✔            | ✔          | ✔            |
| M05 zero check missing        | edge     | ✔        | ✔        | ✔                | ✔         | ✔            | ✔          | ✔            |
| M06 1-cent overdraft allowed  | edge     | –        | ✔        | ✔                | –         | ✔            | ✔          | ✔            |
| M07 32-bit balance wraps      | rare     | –        | –        | –                | –         | –            | ✔          | ✔            |
| M08 amounts ≥ 2^31 "invalid"  | rare     | –        | –        | –                | –         | –            | ✔          | ✔            |
| M09 hidden 1,000,000 limit    | rare     | –        | –        | –                | ✔         | ✔            | ✔          | ✔            |
| M10 64-bit check wraps        | rare     | –        | –        | –                | –         | –            | ✔          | ✔            |
| **Caught**                    |          | **5**    | **6**    | **6**            | **5**     | **7**        | **10**     | **10**       |
| False alarms on A and B       |          | 0        | 0        | 0                | 0         | 0            | 0          | 0            |

## What it shows

1. **Every testing method is only as good as the inputs it tries.** All five
   input-based methods missed the three bugs above 2^31. The differences between
   them come mostly from _which inputs_ they try, not _how_ they check:
   - Contracts missed M04 and M06 because the workload rarely hits an exact
     boundary.
   - Contracts caught M09 only because the workload happened to use large
     balances.
   - Exhaustive checking of 0–200 caught exactly what property testing caught,
     so here it added nothing.
2. **The proof caught everything, because the spec is complete.** The four
   promises fix the right answer for every input, so any behavior change breaks
   one of them. The proof's strength comes from the spec Robert wrote. With a
   gap in the promises, a bug inside that gap would be proven "correct".
3. **Codex caught all ten, with no false alarms, in about 30 seconds.** It found
   its own counterexamples, several different from the planter's. Read this with
   care:
   - The functions are six lines long.
   - Each bug is a one-line change.
   - All eleven versions sat side by side, so Codex could compare them against
     each other.

   Real review sees one version of much larger code. The result is promising,
   not general.

4. **Examples anchor meaning, not coverage.** They caught all five ordinary/edge
   bugs and none of the rare ones, which is their job.

## Limits

- The lead chose the bug mix (half rare), which shapes the percentages.
- In Lean, numbers never overflow, so the fixed-width bugs (M07, M08, M10) had
  to be written in on purpose. In languages with 32/64-bit integers they happen
  naturally.
- One function, one run, one reviewer model.

## Time

About 45 minutes of wall-clock time, most of it spent on the spec, the harness
and the checks. The builders, the planter and Codex each took a minute or less.
