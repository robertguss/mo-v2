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
change to them is visible; a change to one of them needs Robert's decision. One
exception is already agreed (D93: the interface is approved): the proposed Lean
names in `INTERFACE.md` may change if Lean requires it, provided each
plain-English promise still holds and the change is shown to Robert and Codex
before any run is compared with the predictions.

| File                   | SHA-256                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| `PREDICTIONS.md`       | `f4ad4897030fc558b100ace0f65163fe36234833e4300925ebc97d66310c7658`                             |
| `RULE.md`              | `ea918fb4899b7f540fc42743831b824b8fadad45b1d95b4a2b4faa9079926d40` (changed by D97; see below) |
| `EXAMPLES.md`          | `2052d414d621549691913badc90025085a5888bc1cd505b7d0bb26ac87d85f54`                             |
| `INTERFACE.md`         | `91297547225831666507036b41b1e3c2a0fc6723223584a0553cf5411c709320` (changed by D98; see below) |
| `PLAN.md`              | `3f110af9f3798662921ecae44d8d9c934339cf51d53209cebd12096c892e76f3`                             |
| `PREDICTIONS-BRIEF.md` | `1413d036c8b361b644cbd715f7c45dc17cf7b1dfb4e42c9047e5d54d9a4c656c`                             |

## Changed on 30 Sep 2026: `RULE.md`, by D97

Robert decided that a program's inputs must all be spelled differently (D97),
closing a gap Codex found after the rule was approved. One paragraph was added
to `RULE.md`, section 2e. The predictions were written from the earlier text,
whose fingerprint was
`07e3c4adfcea2d57830c2f678f8135936f8bc36f038744b867e6fe3b2aacd75d`. No approved
example has two inputs with one spelling, so no prediction depends on the
change.

## Changed on 30 Sep 2026: `INTERFACE.md`, by D98

Robert decided that the snapshots record two more things (D98): the value a
`match` branch has worked out, in the two snapshots taken as it finishes, and a
snapshot each time a chosen branch is about to run. The check-writing session
had stopped because the snapshots could not show these, so two timing claims in
the predictions on runs 10 and 11 could not be checked as written. One paragraph
was added to `INTERFACE.md` section 6, and its status line notes the extension.
The predictions were written from the earlier text, whose fingerprint was
`17d658fc1a18e7d547f4817add7e30ad25920eee7c7ad6f4428962263f2e88da`. The addition
only lets the checks see more of a run; it changes nothing a run does, and no
prediction changes.

## Locked on 30 Sep 2026: the full lock (D100)

Robert approved the four proof promises, `ACCEPTANCE.md` and `PROOF-BRIEF.md` on
30 Sep 2026 (D100: the promises, the acceptance file and the builder's brief are
approved and locked). This is the full lock of `PLAN.md`, "How the trial runs",
step 5: the language, both meanings, the predictions and the file that checks
them, the promises, the acceptance file and the brief, with the project files
that decide how they build and the run's output that acceptance check 8 compares
against. Before the lock, a freshly restarted Codex oracle answered the plan's
one bounded question ("can a builder pass these checks while failing the
intended task?") and found no way beyond the limits `ACCEPTANCE.md` states (a
reading, not a proof).

**Frozen.** Nobody edits these. A change to any of them needs Robert's decision
and a new lock, with the old fingerprint kept.

| File                           | SHA-256                                                            |
| ------------------------------ | ------------------------------------------------------------------ |
| `PLAN.md`                      | `3f110af9f3798662921ecae44d8d9c934339cf51d53209cebd12096c892e76f3` |
| `RULE.md`                      | `ea918fb4899b7f540fc42743831b824b8fadad45b1d95b4a2b4faa9079926d40` |
| `EXAMPLES.md`                  | `2052d414d621549691913badc90025085a5888bc1cd505b7d0bb26ac87d85f54` |
| `INTERFACE.md`                 | `91297547225831666507036b41b1e3c2a0fc6723223584a0553cf5411c709320` |
| `PREDICTIONS.md`               | `f4ad4897030fc558b100ace0f65163fe36234833e4300925ebc97d66310c7658` |
| `PREDICTIONS-BRIEF.md`         | `1413d036c8b361b644cbd715f7c45dc17cf7b1dfb4e42c9047e5d54d9a4c656c` |
| `ACCEPTANCE.md`                | `19c1ad2f1c760264322af02050d30d72871d6d448dd7e8b8f69e3d32bc844df1` |
| `PROOF-BRIEF.md`               | `056b6e1712be25e570f57240641fa1e0be9487465813e7067cb49af254bd4037` |
| `results/run-1.txt`            | `4b85ff0c0561722d584e8c60b730a25d6f5cdca7d0222dde33fcc2d024ca8847` |
| `lean/lakefile.toml`           | `beb8daf50e57df87858b003e5d02107efd0299c7d6c6b581f7b9c1a24faaeced` |
| `lean/lean-toolchain`          | `8733782dc070a99b312039cda424f601b80f3be6f6f512627da5ba25adc27632` |
| `lean/lake-manifest.json`      | `03a59facc53776ea216ba5477dd41aec889472eab38f6673006e1a0023faebe0` |
| `lean/.gitignore`              | `d4e3917adcfaaa8d53ccc3eb2c9c3423307b0de18d8efbb32e3a92aa53ffb0f9` |
| `lean/Trial.lean`              | `9bc52e4245a1bdf8fd8f7be8d8bb5e23248b033fc95aa82734b0d612014fdbe8` |
| `lean/Trial/Language.lean`     | `2aef4053975808559849881c376cc88b7dd290269a73c571d0c605ed42492913` |
| `lean/Trial/Plain.lean`        | `bac8b5df8920396ddccd351548a4fad7a880d3c6d89336015dccaa56f7d2b0c2` |
| `lean/Trial/Memory.lean`       | `fefb1d40ba9e5d08eb986d5c3174889e1f2f0b7127c94e12dce54230df729355` |
| `lean/Trial/Counted.lean`      | `fe299d069daf6be3cdce68633e891cd5133a35404ca5378ffbe93690594d26f2` |
| `lean/Trial/Broken.lean`       | `fb4f1f26a4584e217eea0be9c4c49f33eca946480c9ff23c79c6ee45fd046a5b` |
| `lean/Checks.lean`             | `6ffad427c10183edc8dc632786d57374b5a260488232290c6a7c69474d79a3ce` |
| `lean/Checks/Examples.lean`    | `02d0cbc814d9533211a0fc0010a8b2dffee16a44dc74f2206406ebb3fcd4e846` |
| `lean/Checks/Predictions.lean` | `c2c0f0b81c92bef06fa4ff3c803b602c01f44b2ba25c14fb9ef270a770d57408` |
| `lean/Checks/Run.lean`         | `92ec0acfbffc150a354aa7e74ef9ea91c5805c7b9678b7ac9ddeea0e8f48c24b` |
| `lean/Promises.lean`           | `d098140316a6aea6204c6c36eebedbdb28b44ebe8d55a122ceeee7f6ea3a6f0c` |
| `lean/Acceptance.lean`         | `28e7cd0738c2913b21e7b2c2de1173b3e3ea3d7ec74418828b453376166b2457` |

**Writable in phase 2.** Only `lean/Proofs.lean` and new files under
`lean/Proofs/`, by the builder (`PROOF-BRIEF.md`). The stub as locked, with its
four `sorry`s, has the fingerprint
`82459c04e7f2084930617314e7677e6c6ac4a799d59b19b845b10687a8a5aa61`; it is
recorded only as the starting point, and is expected to change.

The rows in the earlier sections record the approved documents as they stood
when the predictions were frozen. Where a file appears in both, this table is
the one in force; `PREDICTIONS.md`, `RULE.md`, `EXAMPLES.md`, `INTERFACE.md`,
`PLAN.md` and `PREDICTIONS-BRIEF.md` are unchanged since.

## Amended on 2 Oct 2026 UTC: phase-2 Amp operations

Robert approved D103 (the trial-only Amp workflow amendment) in the
[Lead thread](https://ampcode.com/threads/T-01a0f9e2-cd4f-7408-a467-ecdb636cdeb7),
recorded in Linear's live decision register. Only the operational documents
below change: visible Amp Builder, proof-path-only commits/pushes, separate
Lead/Tester acceptance runs, and automatic continuation after two-hour reports.
The four promises, all ten substantive checks, language, semantics, examples,
predictions and executable acceptance files do not change.

These three rows supersede only their corresponding rows above. All other
full-lock rows remain in force; prior fingerprints are deliberately preserved.
The Lead pins the commit containing this amendment as the acceptance baseline
before any proof work. It is not the later Builder plan or candidate commit.

| File | SHA-256 |
| ---- | ------- |
| `PLAN.md` | `246aab8585be561ac4262a7e3380736f8cfd92540de1c6b488edd83215d4370e` |
| `ACCEPTANCE.md` | `bff59be8a2f6867ea60cad2a984d02b45fc4f76523156c01f6505f055166de50` |
| `PROOF-BRIEF.md` | `602b5bc04a463e508e16da2eb008548857b99c8a8b2329da4dac5f98db4c7230` |
