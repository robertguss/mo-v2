# Stage B acceptance package — prepared for your review

Robert: this is the acceptance side of Stage B, ready for you to read. Nobody
has built Stage B. Nobody has run the million-element tests. Nothing has been
merged. What exists now is the measuring equipment, checked as far as it can be
checked before there is anything to measure.

You authorized this on 8 October 2026 (D157: "Yes, prepare the Stage B
acceptance package for my review. No build yet.").

**Three things need your decision before Stage B can start. They are in
"Decisions I need from you", and the first one is serious: as the observation
schedule stands today, one of the two approved million-element tests cannot
finish inside the time limit you approved, and it is the measuring equipment,
not the language, that runs out of time.**

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
fingerprint are in `evidence/stage-b-01/inventory/inventory.json`.

I also checked two numbers the Stage A report states in words. It says ten
control paths and sixteen expectations about Stage B were deferred. Rather than
copy those numbers, I had a program work them out again from the frozen check
files: it found exactly ten and exactly sixteen, and they agree.

### What was missing

The Stage A freeze and result record six gaps for Stage B. Where this package
leaves each one:

| Gap | Now |
| --- | --- |
| Large streaming equipment not implemented | Implemented and exercised at seven sizes |
| No Stage B candidate had ever been linked or run | Linked and run, fifteen times, against a stand-in |
| No sanitized Stage B builder package | Assembled, scanned and fingerprinted |
| Ten sabotage tests deferred | Prepared; none run, and none can run yet |
| No Stage B private execution | Still blocked on the separate acceptance machine |
| Neither million-element workload run | Still not run; see decision 1 |

### What is proposed new

| File | SHA256 |
| --- | --- |
| `STAGE_B_PREPARATION.md` | this file |
| `BUILDER_STAGE_B_V18.md` | `5be9136fb83e632aee8f4dbe451dde3fa62cd405b251d9162fd6934d188f15b4` |
| `stage_b_inventory.py` | `f98483f7f109461164a34b8ecd2fe47286244dac14e50c03568fdaf4c36d4f59` |
| `stage_b_workloads.py` | `7230d08b51e21a76b00c080525ec2755a0db8474170262497c3a4f6629a26b7f` |
| `stage_b_large.py` | `06a4bde6ed6b26448ee6814c4f6fd64a22313c2a07a93cf33ae2a28a2e6056cf` |
| `stage_b_link.py` | `d12c7064433690ad603151c12c11cb73abcf2937af72f67007d95361c156adb4` |
| `stage_b_controls.py` | `5a3df0ba2775a4fddae096f3bd6a66b4b01da8f5def5d5532499d41b36237856` |
| `stage_b_delivery.py` | `8779e99645ed66dcf6b33fdefdd8a1d731e92b280a2bfe3c325333ea24ada984` |
| `stage_b_check.py` | `61a1ef4ca27fb40abad110fe73196b6916b5f5f285b311903d1d1bd3c97b4d19` |
| `stage-b-stub/Cargo.toml` | `58761dee9c8acb728bf12c36e6f0506418480e8f05208899cec87f3e55dfa623` |
| `stage-b-stub/Cargo.lock` | `ea010bb20deb61ec3b859d28e17c682ebc55a1559bcbe50d8375ba40e3c6cdf5` |
| `stage-b-stub/call_stub.rs` | `4e36b774ac4895fb95b8e731003b798bd477245626ee2f5d23798112d3cfde7a` |
| `stage-b-stub/large_stub.rs` | `e81bd4fedabfbec6f860d672d18e69e23573250998c184769d97dd96b94bc02c` |

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
path. Nine of the ten have a public example that reaches them. One,
`omitted-entry-create`, has none — no public example makes an invocation
allocate memory at the moment it starts — so that one currently has no way to
be run on public evidence. That is the third decision below.

**Zero of the ten ran, and none can run until Stage B is built.** To stop a
prepared plan ever being mistaken for a passed test, I ran fifty checks that
confirm the frozen acceptance of sabotage evidence still rejects a record that
claims a test was run when it was not.

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
list and every fingerprint are in `evidence/stage-b-01/delivery/summary.json`.

The scan reported two places where a sabotage test's name appears as ordinary
English inside already-approved public documents ("tail-call/early-cleanup
alternatives", "fixture-provenance information"). I judged both to be prose,
not leaks, and recorded that judgement in the evidence so you can disagree with
it. I did not edit the frozen documents.

### Everything that was checked

Produced by one command, `python3 stage_b_check.py evidence/stage-b-01
/tmp/rob1333-stage-b/debug`, which passed.

| What | Result |
| --- | --- |
| Frozen files, dependencies and archives rehashed | 496 + 5 + 4, all unchanged |
| Deferred control paths and expectations re-derived | 10 and 16, both agree with the Stage A record |
| Closed-form schedule against the frozen predictor | 873 actions compared, exact, depths 0–8, both workloads |
| Closed-form full states against the frozen predictor | 99 states compared, exact, discard workload |
| Large runs through the adapter | 7 sizes, 12 to 200,000 elements, up to 400,003 steps |
| Pause and resume during a large run | 1 run, stopped at step 10,000, resumed with no work, then finished |
| Destroy part-way through a large run | 1 run, 3,000 cells released by destruction, nothing left after teardown |
| Deliberate faults the adapter caught | 3: a claimed-but-not-performed release, too few photographs, and an attempt to run at the approved size |
| Stage B linked runs through the frozen checker | 15, all passing, including all 7 pause points and all 7 destroy points |
| Deliberate faults the frozen Stage B checks caught | 4, each by a different check |
| Deferred expectations re-run in Stage B mode | 16, all passing |
| Checks that reject a sabotage record claiming a test ran | 50 |
| Builder package assembled, scanned and rebuilt identically | 13 files, 28,229 bytes |
| Public runtime compiled on its own | `cargo +1.98.1 check --locked --offline` |
| Sabotage tests executed | 0 |
| Mo interpreters run | 0 |
| Million-element workloads run | 0 |
| Private reserved or generated cases used | 0 |

## Decisions I need from you

### 1. The observation schedule does not fit the time limit

This is the important one.

You approved (D151) that a large run records its full state at the start, after
every 10,000 steps, at every pause or failure or finish, and around cleanup.
Separately you approved a 600-second limit per workload, covering everything.

Working out what that schedule actually asks for, I get:

| | Adding a million ones | Discarding a million-element list |
| --- | ---: | ---: |
| Steps in the run | 18,000,014 | 2,000,003 |
| Full photographs required | 1,806 | 206 |
| Largest single photograph | about 5 million rows | about 2 million rows |
| Total rows across all photographs | about 5.1 billion | about 100 million |
| Projected time on this machine | about 11 hours | about 14 minutes |
| Time limit you approved | 10 minutes | 10 minutes |

The reason is not slowness. It is that a photograph of a recursion a million
levels deep genuinely contains a million levels: a million frames and about
three million rows describing where each one is. Taking 1,800 such photographs
means writing out, sending and checking billions of rows. No reasonable speed-up
rescues that; even at twenty bytes a row it is hundreds of gigabytes.

The measured basis for the projection: seven runs at sizes from twelve to
200,000, giving about 38 microseconds per step plus about 7.6 microseconds per
row of state written out. Both numbers and the raw runs are in
`evidence/stage-b-01/adapter.json`. This measures my equipment on this machine,
not a Mo interpreter; the row counts, though, are a property of the schedule you
approved and do not depend on the machine.

Your options:

- **(a) Keep the schedule and drop the time limit for large runs.** Honest, but
  it turns a bounded test into an open-ended one, and "it eventually finished"
  is weak evidence. I do not recommend it.
- **(b) Keep full photographs, but take far fewer of them.** For example, every
  millionth step instead of every ten-thousandth, plus start, pause, finish and
  cleanup. For the recursive sum that is 18 photographs instead of 1,800, which
  fits comfortably. You see less of the middle of the run.
- **(c) Keep the frequency, but make most photographs a summary.** Every 10,000
  steps record the counts and the boundaries — how deep, how many cells alive,
  which cells changed — and take the full photograph only at the start, the
  deepest point, the finish and around cleanup. Every individual cell operation
  is still recorded throughout, so nothing about memory goes unwatched.
- **(d) Shrink the workload.** Test 100,000 elements instead of a million. This
  keeps everything else intact but weakens the claim you wanted to make.

**My recommendation is (c), with (b) as the fallback.** What the large tests are
for is showing that a deep recursion does not overflow the stack and does not
leak, and both of those are visible in the cell-by-cell record and the boundary
photographs. The thousand intermediate photographs cost enormously and tell you
very little that the counts do not. Choosing (c) also settles "large snapshot
serialization", which the protocol already lists as still awaiting your
approval, so this is filling in a gap rather than reopening a decision.

### 2. The cleanup chain in a photograph grows without limit

A smaller version of the same problem, and it needs its own answer because it
affects the simpler of the two workloads.

When a million-element list is discarded, the rules say releasing the first cell
releases the second, and so on. The state of the program therefore contains a
list of everything currently part-way through being released, and near the end
that list has close to a million entries. Over the whole run, recording it adds
up to about 100 million rows — the 14 minutes in the table above is mostly this.

Your options:

- **(a) Record the chain in full every time.** Faithful, and the reason the
  discard test does not fit.
- **(b) Record the chain's length and its two ends.** Cheap, and still catches a
  chain that is the wrong length or is being worked in the wrong order.
- **(c) Record the chain in full only at the start, the finish and around
  cleanup, and its length in between.**

**My recommendation is (c).** It keeps the exact evidence where the cleanup
rules are most likely to be violated and makes the middle of the run cheap. This
is a reporting-detail choice; it changes nothing about what Mo must do.

### 3. One sabotage test has no example that reaches it

`omitted-entry-create` is meant to catch an interpreter that fails to allocate
memory the start of a call genuinely needs. No public example reaches that
situation: in every one of the 21 public examples, no invocation allocates
anything at the moment it starts. So as things stand the test cannot be run on
public evidence.

Your options:

- **(a) Add one public example that allocates at entry**, and keep the test. I
  would add it to the frozen public set, which needs your approval because the
  frozen set is frozen.
- **(b) Check whether one of the 24 reserved examples reaches it.** They live
  outside this repository and I have not looked at them; the acceptance machine
  can check and report yes or no without revealing them.
- **(c) Retire the test** and record honestly that this particular mistake is
  not covered.

**My recommendation is (b) first, then (a) if the answer is no.** Using a
reserved example is better, because an example the builder has never seen is
stronger evidence than one it has. Option (c) loses real coverage.

## Limitations

- Nothing here ran a Mo interpreter. Every run used a deliberately simple
  stand-in that replays a hand-written schedule. The stand-ins prove the
  equipment works; they prove nothing about Mo.
- Neither million-element workload ran. The adapter refuses to run at the
  approved size, by design, so a test cannot quietly become the real thing.
- Of the two workloads, only the discard one has a complete state rule and has
  actually been driven through the adapter. The recursive sum has a validated
  rule for its actions, its sites, its depth and its sizes, but not yet for the
  full content of its states, because how a state that large should be written
  out is decision 1 above.
- The private 24 reserved examples and 500 generated ones live on the separate
  acceptance machine, not in this repository. I did not use them, recreate
  them, regenerate them or substitute anything for them. Everything that needs
  them is marked as waiting for that machine.
- Zero of the ten deferred sabotage tests ran.
- The projections to a million elements are projections. They rest on seven
  measured runs and on row counts derived from the rules, not on a run at that
  size.
- The large-run watcher checks that a cell identity is never reused by requiring
  each new one to be larger than any seen before, rather than by remembering
  every retired identity as the small-run watcher does. That is a slightly
  weaker check, adopted so memory stays bounded.
- Separating the builder from acceptance stays a procedure, not a technical
  barrier. Assembling the package does not verify any future builder's context.

## What is still blocked

| Blocked on | What it is |
| --- | --- |
| The acceptance machine | Running the 24 reserved and 500 generated cases against a Stage B candidate; answering decision 3(b) |
| A Stage B interpreter | All ten sabotage tests; the real resume, destroy and failure cuts; the Stage A regression under Stage B |
| Your decision 1 | The full state rule for the recursive sum, and both million-element runs |
| Your approval | Freezing this package, delivering it to a builder, starting Stage B |

## Effort ledger (D152)

Elapsed contributor time, counted from the explicit start of this session to its
stop, including tool, build and test waits, excluding owner-wait and stopped
periods. One contributor, no concurrency.

| Row | Seconds |
| --- | ---: |
| Stage B acceptance preparation (this session) | 3,059 |
| of which, the final evidence run | 73 |
| Recorded owner-wait | 0 |

That is 51 minutes, from 10:56 to 11:47 UTC on 8 October 2026. The machine
figures are in `evidence/stage-b-01/effort.json`. Earlier preparation and Stage
A effort are recorded in their own files and are not restated or reconstructed
here. Host wall time, processor time and memory use are different measurements
and are reported separately in the run summaries.

## How to reproduce

From the repository root, with Rust 1.98.1 installed:

```sh
export CARGO_TARGET_DIR=/tmp/rob1333-stage-b
cargo +1.98.1 build --locked \
    --manifest-path experiments/13-source-acceptance/stage-b-stub/Cargo.toml
cd experiments/13-source-acceptance
python3 stage_b_check.py evidence/stage-b-02 /tmp/rob1333-stage-b/debug
```

Use a new evidence directory; the existing one is refused rather than
overwritten. The run takes about seventy-five seconds and starts no Mo
interpreter.

## Boundaries

This package is a review candidate. It is not a scientific freeze, not a builder
dispatch, not authorization to run either million-element workload, and not a
merge, release or deployment. The frozen Stage A criteria, the original failed
attempts and every existing prediction are unchanged. The author of this package
does not implement Mo.
