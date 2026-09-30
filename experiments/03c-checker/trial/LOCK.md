# Lock: the trial's frozen files

Fingerprints (SHA-256) of files that must not change. Check one with
`shasum -a 256 <file>` inside `experiments/03c-checker/trial/`.

## Frozen on 30 Sep 2026: the predictions

Robert approved the predictions on 30 Sep 2026 (D95: the predictions are
approved and frozen). `PREDICTIONS.md` was written by a separate Codex session
from the approved rule alone, and committed exactly as written in `471e99c`. It
is frozen from here on: nobody edits it, the lead least of all. Its own status
line still reads as the prediction session left it, because marking it approved
would change its fingerprint; this file records the approval.

If a later run disagrees with a prediction, the failed run and the original
prediction are kept, the mismatch is classified (a wrong prediction, a wrong
encoding, or a counterexample to the rule), and nothing changes without Robert's
decision (`PLAN.md`, "How the trial runs", step 4).

The other rows are the approved documents the predictions were written from, as
they stood when the predictions were frozen. They are recorded so that any later
change to them is visible; a change to one of them needs Robert's decision.
One exception is already agreed (D93: the interface is approved): the proposed
Lean names in `INTERFACE.md` may change if Lean requires it, provided each
plain-English promise still holds and the change is shown to Robert and Codex
before any run is compared with the predictions.

| File | SHA-256 |
| --- | --- |
| `PREDICTIONS.md` | `f4ad4897030fc558b100ace0f65163fe36234833e4300925ebc97d66310c7658` |
| `RULE.md` | `07e3c4adfcea2d57830c2f678f8135936f8bc36f038744b867e6fe3b2aacd75d` |
| `EXAMPLES.md` | `2052d414d621549691913badc90025085a5888bc1cd505b7d0bb26ac87d85f54` |
| `INTERFACE.md` | `17d658fc1a18e7d547f4817add7e30ad25920eee7c7ad6f4428962263f2e88da` |
| `PLAN.md` | `3f110af9f3798662921ecae44d8d9c934339cf51d53209cebd12096c892e76f3` |
| `PREDICTIONS-BRIEF.md` | `1413d036c8b361b644cbd715f7c45dc17cf7b1dfb4e42c9047e5d54d9a4c656c` |

## Still to come

The full lock of `PLAN.md`, "How the trial runs", step 5, is added here when
those files exist and Robert has approved them: the language, both meanings, the
file that checks the predictions, the promises, the acceptance file and the
builder's brief.
