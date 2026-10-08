# Independent acceptance review — preparation

Verdict: the proposed preparation package passes independent acceptance and
delivery checks. No blocking correctness or information-boundary finding was
found in the reviewed package. This is not owner approval to run participant
sessions; launcher isolation and process-group teardown remain explicit future
operational gates in PROTOCOL.md.

The acceptance author froze `acceptance/check.py`, `acceptance/harness.rs`, and
the unchanged helper hash before the task author wrote any baseline. The author
then inspected the retained task sources and re-evaluated every saved result
against the frozen reference: 160 allocation-run cases across six baselines and
two legal repairs. Inputs include empty/singleton lists, negative values, repeated
values, non-profile lengths, signed modulo boundary crossings, and each profile.
Every full output and required original matched; teardown restored requested
live memory after accounting for the verification vectors.

The current helper calibrated at 32 requested bytes per cell. U1/U2 baselines
perform 100,000 allocation requests / 3,200,000 bytes; both legal repairs require
zero requests / zero bytes. R1/R2 preserve the old full list within the permitted
100,000-cell budget. H1 and H2 preserve their original versions using 4 cells /
128 bytes and 8 cells / 256 bytes respectively. These are requested allocator
bytes, not resident memory or total process footprint. See `review.json`.

The acceptance author independently ran four negative controls:

- Discarding the required old version compiles, then fails the full-value/Option
  contract. Even an empty input requires `Some(empty)` for a retained task.
- The previous shared-mutation mutant compiles, then changes the retained original
  on `[-4, 0, 9]`; the frozen semantic check rejects it. Its different cell
  representation makes the ordinary allocation calibration inapplicable, so this
  explicit controlled-helper test checks semantics only.
- Copying before a participant-chosen inner timing interval compiles, then fails
  the unique-task allocation budget. The external boundary covers all of `run`.
- A disposable checker copy with its comparison disabled fails integrity before
  compilation. This is an integrity catch, not a semantic or build-failure catch.

Frozen acceptance identity was checked again after these controls. The added
`controls_check.py` is a post-freeze control driver, not a replacement checker.

Not checked here: participant model behavior, subscription usage, performance
benefits on other hardware, arbitrary programs, or hostile-code containment.
The cooperative source restrictions require review; the checker is not a sandbox.
There were no participant sessions. Initial baseline/repair evidence has no timing
samples; the separate baseline-timed-01 evidence was subsequently reviewed below.


## Completed delivery and timing review

The acceptance author re-evaluated all 120 allocation cases and 60 uninstrumented
profile timing results in baseline-timed-01. Every full value/original comparison
passes, and retained task hashes match outcomes. Feedback requested allocations,
bytes, absolute live/peak values, representative input size, and timing ranges
match that evidence. Displayed medians round to whole nanoseconds using Python round-to-nearest-even
formatting; exact medians are in timed-review.json.
Tiny H1/H2 durations are noisy descriptive observations, not performance gates or
general performance claims. These repeats were reported by the driver as separate
from controls compilation; no additional timings were run by this author.

Static notes correctly describe the helper's possible copying when another holder
remains alive; they are explicitly manual prototype messages about baseline source.
Measured profiles are limited to the unchanged baseline and stated input, distinguish
requested bytes from RSS, and remind participants to preserve required values.
Task requirements and PROTOCOL.md keep reference repairs/categories and independent
acceptance outside each participant workspace. The 30-entry frozen run order has
one occurrence of every task/condition pair. The protocol defers actual launcher
isolation, subscription/model pinning, and process-group forced-failure proof until
before any approved model trials; the delivery utility cannot launch a model.

The independent delivery_check.py exercised all 30 setups and two requests per
setup. It verified identical payloads between automatic/request arms of each
information type; automatic-only initial delivery; no payload stored in request
workspaces; neutral unavailable responses in the none arm; wrapper and direct
request logging; 404 for a wrong endpoint; and exactly the seven intended public
workspace files with no reference repairs or private acceptance files. All six
public example check commands compiled and passed. Every listener and thread
closed after normal teardown. A deliberate post-setup exception exercised finally
cleanup and proved a refused connection/closed listener/terminated thread; a
constructor failure after listener creation also closed the listener. All outcomes
are retained under evidence/delivery-01. No model calls occurred.

The delivery tests establish the local cooperative information boundary. They do
not establish OS isolation from the repository or prevent a deliberately hostile
participant from inspecting other files; the protocol correctly reserves that
launcher boundary for later implementation and proof.
