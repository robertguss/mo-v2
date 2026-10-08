# Stage B acceptance package — prepared for your review

Robert: this is the acceptance side of Stage B, ready for you to read. Nobody
has built Stage B. Nobody has run the million-element tests. Nothing has been
merged. What exists now is the measuring equipment, checked as far as it can be
checked before there is anything to measure.

You authorized this on 8 October 2026 (D157: "Yes, prepare the Stage B
acceptance package for my review. No build yet.").

You have since decided the open items. This revision carries them out. Each
name is the entry in the decisions register.

- **D159, summaries between boundaries.** Keep a look every 10,000 steps, but
  make that look a summary: how deep the program is, how many cells are alive,
  how many have been created, written and freed, and which cells changed. Take
  a full photograph only at the start, the deepest moment, a pause or a failure
  or the finish, and around cleanup. Every individual cell operation is still
  recorded.
- **D160, the cleanup chain.** At those same photographs, record the whole list
  of cells part-way through being released. Between photographs, record only
  how long that list is.
- **D162, the recursive sum's clock.** The million-element recursive sum gets
  900 seconds (15 minutes). The million-element discard stays at 600 seconds
  (10 minutes). The record of every step stays. This amends D151's envelope for
  the sum only. D151 is the resource envelope: those clocks, 8 MiB of stack, at
  least 4 GiB available, and at most 100 million steps.
- **D164, one sabotage test does not apply.** `omitted-entry-create` is recorded
  as not applicable under the frozen rules, because the frozen predictor never
  allocates memory at the moment a call begins. Nine of the ten sabotage tests
  stay active. This supersedes the D161 fallback, which was to add a public
  example that allocates at that moment. Adding one would not create that
  allocation without editing a frozen file, and no frozen file was edited.

Both workloads now fit their limits on the projection below. What is still
gated, and has not been done: freezing this package, sending it to a builder,
running the private cases, executing the nine active sabotage tests, and
running either workload at a million elements.

## What Stage B will demonstrate

Stage A showed that a program written as ordinary text can be read, checked and
run, one visible step at a time, with every piece of memory accounted for — but
only for programs with no functions in them. Stage B adds the part that makes a
language a language: you can name a piece of work, give it typed inputs and a
typed output, and call it, including calling it from inside itself.

Here is what Stage B is meant to show, in the form of the programs that show it.

**Adding up a list, by recursion.** `total` takes a list. If the list is empty
the answer is 0; otherwise the answer is the first number plus the total of the
rest. Asking for the total of a million ones must give 1,000,000. The
interesting part is not the arithmetic. It is that a million nested calls are
all alive at once and the machine does not fall over.

**Changing a list while keeping the original.** `bump` adds one to every
element. Given `[3, -2, 8]` it gives `[4, -1, 9]`. If nothing else is holding
the original, Mo may reuse the same three pieces of storage and allocate
nothing. If something outside the program is still holding the original, Mo
must leave `[3, -2, 8]` untouched and build three new pieces. Both behaviours
have to be visible in the actual memory, not just claimed in a report.

**An argument that is prepared and then waits.** When a function takes two
arguments, the first one is finished before the second one starts. While the
second is being worked out, the first one has to stay readable and must not be
quietly recycled. Stage B has to keep that promise even if the program pauses
in the middle.

**Two functions that call each other.** `even(n)` says "if n is at most zero,
true; otherwise ask `odd(n-1)`", and `odd` says the mirror image. `even(2)` is
true, `even(7)` is false. Neither function can be understood on its own, so
this shows that Mo resolves names across the whole file rather than in order.

**Pausing in the middle of a recursion and carrying on.** Stop the program
after any one step, look at everything it is holding, then let it continue. The
answer has to be the same as if it had never stopped, and it has to continue
from where it was, not start the step again.

**Recursion that never ends, staying honest about it.** `spin(n)` calls
`spin(n)` forever. Mo must not pretend it finished and must not pretend it
proved the program never finishes. It reports "still running, here is the
state", and that state can be thrown away cleanly.

## What passing will and will not prove

Passing will show that, for the programs actually tested, Mo's functions and
recursion behave as the written rules say: right answers, honest memory, values
that outlive a pause, cleanup that leaves nothing behind, and four clearly
different outcomes — finished, paused, refused, failed.

Passing will not show that Mo is correct for every program. The tested set is
4,276 historical cases, 21 public examples, 24 reserved examples and 500
generated ones, all within small bounds: expressions nested at most five deep,
at most three functions, at most four arguments, starting lists of at most four
elements. It will not show anything about speed, about recovering when the
operating system itself runs out of memory, about how helpful Mo is to an
agent, or about what Mo's permanent syntax or number handling should be. It is
evidence, not proof.

## Inventory

### What is frozen, and still is

All 496 frozen files, the five historical dependencies and the four preserved
archives still match their recorded fingerprints exactly. I changed none of
them. Everything in this package is a new file. The full list and every
fingerprint are in `evidence/stage-b-03/inventory/inventory.json`.

I also checked two numbers the Stage A report states in words. It says ten
control paths and sixteen expectations about Stage B were deferred. Rather than
copy those numbers, I had a program work them out again from the frozen check
files: it found exactly ten and exactly sixteen, and they agree. Of those ten,
nine are active tests. One is not applicable, for the reason under "Why one
sabotage test does not apply".

### What was missing

The Stage A freeze and result record six gaps for Stage B. Where this package
leaves each one:

| Gap | Now |
| --- | --- |
| Large streaming equipment not implemented | Implemented and exercised at seven sizes |
| No Stage B candidate had ever been linked or run | Linked and run, fifteen times, against a stand-in |
| No sanitized Stage B builder package | Assembled, scanned and fingerprinted |
| Ten sabotage tests deferred | Nine prepared and still not run; one not applicable under the frozen rules |
| No Stage B private execution | Still blocked on the separate acceptance machine |
| Neither million-element workload run | Still not run. Both now fit their time limits on the projection |

### What is proposed new

| File | SHA256 |
| --- | --- |
| `STAGE_B_PREPARATION.md` | this file |
| `BUILDER_STAGE_B_V18.md` | `5be9136fb83e632aee8f4dbe451dde3fa62cd405b251d9162fd6934d188f15b4` |
| `stage_b_inventory.py` | `a5e8af032a51eb8981ed97451848d0520b9bc348a10994727c1dc33bd787104e` |
| `stage_b_workloads.py` | `88a1d17a92d27c634d42ea9642916b44a591d066be059f3e0cd2a57773b8462b` |
| `stage_b_large.py` | `8da36b2f8a64e0e4687f536008806ed498b42649d7c69d529ca269fe88694640` |
| `stage_b_link.py` | `d12c7064433690ad603151c12c11cb73abcf2937af72f67007d95361c156adb4` |
| `stage_b_controls.py` | `2834ac725982eba0024fc1c0b30469a640b2c96cf9ff37c1f9ed31a005b663e7` |
| `stage_b_delivery.py` | `8779e99645ed66dcf6b33fdefdd8a1d731e92b280a2bfe3c325333ea24ada984` |
| `stage_b_check.py` | `9dcaa6614d607a4802c373cdd4a17c593d47f4a752cc6c74fef0388c980c3ed1` |
| `stage-b-stub/Cargo.toml` | `58761dee9c8acb728bf12c36e6f0506418480e8f05208899cec87f3e55dfa623` |
| `stage-b-stub/Cargo.lock` | `ea010bb20deb61ec3b859d28e17c682ebc55a1559bcbe50d8375ba40e3c6cdf5` |
| `stage-b-stub/call_stub.rs` | `4e36b774ac4895fb95b8e731003b798bd477245626ee2f5d23798112d3cfde7a` |
| `stage-b-stub/large_stub.rs` | `e9f9882ad4383a02d0ae92b4c42379da6e21e3c222495730e7d5073714ebe301` |

These are review fingerprints, not a scientific lock. A lock comes after you
approve the package.

## What I did

### The large-scale measuring equipment now exists

The Stage A freeze recorded that the equipment for watching a very large run
"is not implemented". It was right, and in two ways. The existing watcher asks
the program under test to send a complete photograph of its state after every
single step, and it works out the entire expected history in advance before the
run even starts. For a run of twenty-seven steps that is fine. For a run of
eighteen million steps it is impossible twice over.

I wrote the large-run version. Two changes make it work. First, expectations
are now worked out one step at a time from a rule, instead of being listed in
advance; the rule was checked by comparing it, action for action, against the
existing trusted predictor on small runs, and it matches exactly. Second, the
watcher now checks each report as it arrives and then forgets it, so what it
holds on to depends on how much memory the program is using, not on how long it
has been running. That is enforced by the code, not just intended: if the
watcher's own bookkeeping ever grows past the size of the program's live
memory, it stops and says so.

I ran it against a stand-in program — not a Mo interpreter, a deliberately
simple fixture — at seven sizes up to 200,000 elements and 400,003 steps. Every
run passed, and at every size the watcher finished holding two rows.

### Stage B has now been linked and run, for the first time

Until today nothing with a function in it had ever reached the Stage B
machinery; Stage A rejects such programs outright. I ran the program
`def f(): Int = 7 end main = f()` through the unchanged Stage A plumbing and
the unchanged Stage A checker, in Stage B mode: fifteen runs, including
stopping and resuming at all seven possible points and destroying at all seven.
All passed. Then I deliberately broke the stand-in four different ways — losing
the record that a function was entered, naming the wrong place as the caller,
attributing the function's frame to the wrong place, and leaving a finished
call on the stack — and the unchanged checks caught all four, each for the
right reason.

### The control harness is ready; no control has run

Ten deliberate-sabotage tests were deferred from Stage A because a language
without functions cannot reach the behaviour they target. I prepared all ten:
which frozen check decides each one, what the interpreter must be able to do
before the test means anything, and which public example actually exercises the
path.

Nine of the ten are active. Each of those nine has a public example that
reaches it. The tenth, `omitted-entry-create`, is not applicable under the
frozen rules. The reason is under "Why one sabotage test does not apply".

**None of the nine has run, and none can run until Stage B is built.** To stop
a prepared plan ever being mistaken for a passed test, I ran fifty checks that
confirm the frozen acceptance of sabotage evidence still rejects a record that
claims a test was run when it was not. Those fifty include the test that is
not applicable: a record claiming it ran is still rejected.

I also re-ran the sixteen deferred expectations in Stage B mode. All sixteen
pass, so they are ready to use the moment a candidate exists.

### The builder package is assembled and sealed

The package a Stage B builder would receive is thirteen files: the eight Stage A
requirement documents and the four runtime files, all byte-identical to what
Stage A shipped, plus one new Stage B addendum. It is built from an explicit
list rather than by copying a folder, it rebuilds to identical bytes, it was
scanned for anything that must never reach a builder, and the public runtime in
it compiles on its own with the pinned Rust 1.98.1.

Archive `rob-1333-stage-b-public-v18.tar.gz`, 28,229 bytes, SHA256
`0e30809545c3114012c69cceaf024e22f69c08a9b9721eb0a199e35a5d76b997`. The file
list and every fingerprint are in `evidence/stage-b-03/delivery/summary.json`.

The scan reported two places where a sabotage test's name appears as ordinary
English inside already-approved public documents ("tail-call/early-cleanup
alternatives", "fixture-provenance information"). I judged both to be prose,
not leaks, and recorded that judgement in the evidence so you can disagree with
it. I did not edit the frozen documents.

### Everything that was checked

Produced by one command, `python3 stage_b_check.py evidence/stage-b-03
/tmp/rob1333-stage-b/debug`, which passed.

| What | Result |
| --- | --- |
| Frozen files, dependencies and archives rehashed | 496 + 5 + 4, all unchanged |
| Deferred control paths and expectations re-derived | 10 and 16, both agree with the Stage A record |
| Active sabotage tests, and tests that do not apply | 9 active; `omitted-entry-create` not applicable |
| Closed-form schedule against the frozen predictor | 873 actions compared, exact, depths 0–8, both workloads |
| Closed-form full states against the frozen predictor | 873 states compared, exact, depths 0–8, both workloads |
| Large runs through the adapter | 7 sizes, 12 to 200,000 elements, up to 400,003 steps |
| Pause and resume during a large run | 1 run, stopped at step 10,000, resumed with no work, then finished |
| Full photograph at the deepest point of a discard run | 1 run, stopped at step 9,999, chain of 5,000, the last cell still to be freed |
| Destroy part-way through a large run | 1 run, 3,000 cells released by destruction, nothing left after teardown |
| Deliberate faults the adapter caught | 3: a claimed-but-not-performed release, too few photographs, and an attempt to run at the approved size |
| Stage B linked runs through the frozen checker | 15, all passing, including all 7 pause points and all 7 destroy points |
| Deliberate faults the frozen Stage B checks caught | 4, each by a different check |
| Deferred expectations re-run in Stage B mode | 16, all passing |
| Checks that reject a sabotage record claiming a test ran | 50, including the test that is not applicable |
| Amended clock: sum at 900 seconds, discard at 600 | accepted; one second over each limit rejected |
| Builder package assembled, scanned and rebuilt identically | 13 files, 28,229 bytes |
| Public runtime compiled on its own | `cargo +1.98.1 check --locked --offline` |
| Sabotage tests executed | 0 |
| Mo interpreters run | 0 |
| Million-element workloads run | 0 |
| Private reserved or generated cases used | 0 |

## What your decisions changed

**D159, summaries between boundaries.** Keep a look every 10,000 steps, but make
that look a summary: how deep the program is, how many cells are alive, how
many cells have been created, written and freed, and which cells changed since
the last look. Take a full photograph only at the boundaries: the start, the
deepest moment, a pause or a failure or the finish, and around cleanup. Every
individual cell operation is still recorded, all the way through. This also
settles the protocol's open item about how a large photograph is written out.

**D160, the cleanup chain.** At those same photographs, record the whole list of
cells part-way through being released. Between photographs, record only how
long that list is.

The recursive sum now has a complete rule for the full content of its state,
which D159 made writable: the only enormous photograph is the one at the
bottom of the recursion, and the rule for that photograph was checked, step by
step, against the existing trusted predictor at every depth from 0 through 8.
It matches exactly. The discard workload's rule was already complete and still
matches.

**D162, fifteen minutes for the recursive sum.** D151 gave both workloads 600
seconds. After the photographs were made cheap, the sum's projected time was
still about 12 minutes, almost all of it the cost of writing down its 18
million steps. You gave that workload 900 seconds and left the discard at 600.
The step-by-step record stays. The frozen file that still says 600 seconds for
both workloads was not edited. The package's own check is the one that applies
900 seconds to the sum and 600 to the discard, and it rejects a record one
second over either limit.

**D164, the tenth test does not apply.** Explained in the next section but one.
It supersedes the D161 fallback. D161 had said: ask the acceptance machine, and
if nothing reserved allocates at the start of a call, add one public example
that does. The machine answered no. Adding the example turned out to be
impossible without editing a frozen file, so you recorded the test as not
applicable instead.

## The new projections

Same measured rates as last time, from `evidence/stage-b-01/adapter.json`:
about 37 microseconds to check one step, and about 7.6 microseconds per row
written out. Those rates were measured on this checking equipment, not on a Mo
interpreter. The row counts are exact consequences of the D159 and D160 rules,
checked at small depths. The cost of checking each step is still in the total.
That is the per-step record D162 keeps.

| | Adding a million ones | Discarding a million-element list |
| --- | ---: | ---: |
| Steps in the run | 18,000,014 | 2,000,003 |
| Summary looks, every 10,000 steps | 1,800 | 200 |
| Rows in the deepest photograph | 5,000,003 | 1,000,002 |
| Rows in all the photographs and summaries | 7,010,803 | 3,001,204 |
| Projected time, the steps | about 11 minutes | about 75 seconds |
| Projected time, the rows | about 54 seconds | about 23 seconds |
| Projected time, together | about 12 minutes | about 98 seconds |
| Time limit (D162 amends D151 for the sum only) | 15 minutes | 10 minutes |
| Fits | yes | yes |

The deepest photograph of the recursive sum is the moment the millionth call
begins. It holds a million frames, about three million rows describing where
each call is, and a million cells. One such photograph is cheap. The previous
schedule took about 1,800 of them, which was the eleven hours.

The discard's deepest moment is the step where the cleanup chain is longest,
one million cells. That chain is written out once. Between photographs only
its length is written, which is what D160 is for. The cells that actually get
freed are still listed, once each, in the summaries.

**Both workloads now fit their limits.** The sum's projected twelve minutes is
inside the fifteen you approved. The discard's projected 98 seconds is inside
its ten minutes. Almost all of the sum's time is still the cost of checking
its eighteen million steps. The photographs add under a minute.

I did not run either workload at a million elements.

One detail of the equipment, so you know what was actually exercised. The
collector that receives a run is frozen, and it can attach a mid-run snapshot
only every 10,000 steps. The discard's deepest step is 1,999,999, one step off
that grid. Pausing there is already something the collector does, and a pause
is one of the photographs D159 requires, so that is how the deepest photograph
is taken. I paused a 5,000-element discard at step 9,999. The photograph
matched the rule, including a cleanup chain of 5,000, and the one cell still
allocated was released by cleanup. I did not edit the frozen collector.

## Why one sabotage test does not apply

`omitted-entry-create` was meant to catch an interpreter that skips a piece of
memory a call should allocate at the moment the call begins. Under the frozen
rules, a call never allocates at that moment.

The frozen predictor records the call and binds arguments the caller has
already finished. It does not allocate a cell. Every allocation the language
makes is its own step: either while an argument is being prepared, which is
before the call begins, or inside the function, which is after the call has
begun. I checked the 21 public examples, including a function whose whole job
is to build a one-element list. The predictor records zero allocations at the
start of a call for all of them. The acceptance machine's answer for the
private corpus was the same kind of zero: no reserved example and no generated
example allocates there either.

D161's fallback was to add one public example that does allocate at that
moment. Adding the program would change a frozen file, and the frozen predictor
would still count zero allocations at the start of the call, so the test would
still have nothing to catch. Making the predictor allocate there would also
mean editing a frozen file. I changed neither file.

D164 records the test as not applicable for that reason, and supersedes the
fallback. Nine of the ten sabotage tests stay active. The gap is this: Stage B
will not be sabotaged for a skipped allocation at the exact moment a call
begins, because the frozen rules say that moment never allocates. The other
nine tests, including the ones about allocations inside a call and about
copies at entry, remain. None of the nine has been run.

## Limitations

- Nothing here ran a Mo interpreter. Every run used a deliberately simple
  stand-in that replays a hand-written schedule. The stand-ins prove the
  equipment works; they prove nothing about Mo.
- Neither million-element workload ran. The adapter refuses to run at the
  approved size, by design, so a test cannot quietly become the real thing.
- Both workloads now have a complete state rule, checked exactly against the
  frozen predictor at depths 0 through 8. The million-element figures are that
  rule applied at the approved size, not a run at that size.
- The projections use the rates measured on the previous, heavier schedule
  (`evidence/stage-b-01/adapter.json`) multiplied by the new row counts, and
  they still include the cost of checking every step. They are not a fresh
  fit, and they are not a measurement of a Mo interpreter.
- The frozen file that checks a finished resource record still requires 600
  seconds for both workloads. D162's 900-second limit for the sum is checked
  by this package. That frozen file was not edited.
- The frozen collector still attaches the list of live cells every 10,000
  steps. D159 does not require that list between boundaries. The projection
  counts the record D159 requires. The extra list is a property of the frozen
  collector.
- The private 24 reserved examples and 500 generated ones live on the separate
  acceptance machine, not in this repository. I did not use them, recreate
  them, regenerate them or substitute anything for them. The machine's yes/no
  answer on entry allocation is what D161 asked for, and no example content
  came back with it. D164 is what was done with that answer.
- Nine of the ten sabotage tests are active and none of them ran.
  `omitted-entry-create` is not applicable, for the reason above.
- The large-run watcher checks that a cell identity is never reused by
  requiring each new one to be larger than any seen before, rather than by
  remembering every retired identity as the small-run watcher does. That is a
  slightly weaker check, adopted so memory stays bounded.
- Separating the builder from acceptance stays a procedure, not a technical
  barrier. Assembling the package does not verify any future builder's context.

## What is still gated

| Gated on | What it is |
| --- | --- |
| A scientific freeze | This package is prepared. It is not frozen |
| A Stage B builder | Delivering the package and starting the build |
| The acceptance machine | Private execution of the 24 reserved and 500 generated cases |
| A Stage B interpreter | The nine active sabotage tests; the real resume, destroy and failure cuts; the Stage A regression under Stage B |
| Separate authorization | Either million-element run. Both fit their limits on the projection; neither has been run |

## Effort ledger (D152)

Elapsed contributor time, counted from the explicit start of a session to its
stop, including tool, build and test waits, excluding owner-wait and stopped
periods. One contributor, no concurrency.

The earlier preparation rows are unchanged and are not added again.

- `evidence/stage-b-01/effort.json`: 3,059 seconds, of which the check run was
  73 seconds, from 10:56 to 11:47 UTC on 8 October 2026.
- `evidence/stage-b-02/effort.json`: the D159 and D160 revision.

This revision's check run is in `evidence/stage-b-03/effort.json`.

## How to reproduce

From the repository root, with Rust 1.98.1 installed:

```sh
export CARGO_TARGET_DIR=/tmp/rob1333-stage-b
cargo +1.98.1 build --locked \
    --manifest-path experiments/13-source-acceptance/stage-b-stub/Cargo.toml
cd experiments/13-source-acceptance
python3 stage_b_check.py evidence/stage-b-03 /tmp/rob1333-stage-b/debug
```

Use a new evidence directory; the existing one is refused rather than
overwritten. The run takes a couple of minutes and starts no Mo interpreter.

## Boundaries

This package is a review candidate. It is not a scientific freeze, not a builder
dispatch, not authorization to run either million-element workload, and not a
merge, release or deployment. The frozen Stage A criteria, the original failed
attempts and every existing prediction are unchanged. The author of this package
does not implement Mo.
