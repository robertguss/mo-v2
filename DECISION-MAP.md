# Decision map

The questions Mo v2 has to answer, in the order to answer them: each depends on
the ones above it. Every question has options, what the v1 evidence says, and a
recommendation. The recommendations are Claude's; none of them is a decision
until Robert records it in `DECISIONS.md`.

Already decided: D1–D8 (own language, built for AI authors, verification at the
center, general purpose, Robert never reads code, Robert makes every decision).

## The shape of the problem

D5 is the hard constraint. If Robert never reads code, everything he trusts has
to be:

1. **readable by him**, and
2. **checked by something the code-writing AI cannot quietly change.**

v1 failed on the second point. The same AI wrote the code and the tests that
judged it, and re-pinned expectations to the program's own output. Its type
checker was also unsound: `mo check` approved a 10-line program that then
crashed both runtimes. "Verified" meant "an AI said so."

The strongest checker available that no AI can talk its way past is a proof
kernel. Lean's kernel accepts a proof or rejects it; it can't be persuaded, and
it can't grade on a curve. That is why Lean appears throughout this map. A
proof, though, is only as good as the statement it proves. Q3 is about that gap,
and it is the hardest question here.

## Q1. What does v2 guarantee?

This is the one promise the language makes that tests alone don't give. The
evidence makes it the first question: in v1, contracts and `never` clauses
caught **zero** bugs that the agents' own tests missed (the threshold agreed in
advance was two), and with good specs frontier models wrote nearly defect-free
code in Go, Python and Elixir. A v2 whose guarantee is "we also run checks" has
nothing to offer.

Options (they can be combined):

- **(a) Safety:** a program the checker accepts cannot crash from a type error,
  a missing case, a null, or memory corruption. Provable once, for the whole
  language, in Lean.
- **(b) Authority:** a piece of code can only touch what it is handed: files,
  network, clock, money. This is v1's capability idea. Also provable once, for
  the whole language.
- **(c) Determinism:** every run can be replayed exactly from a seed. That makes
  simulation testing and bug reports trustworthy.
- **(d) Behavior:** each program meets properties Robert approved, such as
  "never refunds more than was charged." These are proven or checked per
  program, not once for the language.

(a)–(c) are properties **of the language**: proven once, they hold for every
program ever written in it, with no per-program effort. (d) is where the real
value is for Robert's premise, and it is also the part v1 could not show
working.

**Recommendation:** make (a) + (b) + (c) the foundation, proven in Lean before
the language grows. Treat (d) as the experiment v2 exists to run (Q6). This
hands the language its first honest claim early: "the language itself is proven
safe", which v1 claimed and got wrong.

## Q2. What does Robert read?

This is D5's other half. It decides what the "human surface" of a program is.

Options:

- **(a) Plain-English properties:** a short list per program ("never charge
  twice", "a refund never exceeds its charge"). This is v1's `never` idea.
- **(b) Formal statements:** the Lean or Mo text of each property. Precise, but
  Robert would have to learn to read them.
- **(c) Examples:** tests shown as input → expected output tables.
- **(d) Behavior reports:** what simulation did (runs, faults injected, failures
  found, with a replayable seed).

v1's best idea belongs here. "A human is pulled in when the shape changes": an
agent can change anything inside a program freely, but weakening or removing a
property needs Robert.

**Recommendation:** (a) + (c) + (d), with one rule carried from v1: **Robert's
approved properties and examples are locked**. An agent can add to them but can
only weaken or remove one with Robert's approval. This is also the concrete fix
for v1's re-pinned tests.

## Q3. How does a plain-English property become a checked one?

This is the hardest question in the map. Robert reads "never refunds more than
was charged." The machine checks a formal statement. Something translates one
into the other, and if the translation is wrong, the proof is worthless and
nobody will notice.

Options:

- **(a) Robert reads the formal statement.** The most trustworthy option. Formal
  statements for properties like these can be short, and could be made close to
  readable English by the language's design. Robert learns to read, not write.
- **(b) Independent back-translation.** One AI writes the formal statement; a
  second AI, never shown the English, translates it back; Robert compares the
  two. Cheap, but the two AIs aren't truly independent.
- **(c) Examples as the anchor.** Robert approves concrete examples; the formal
  property must accept every good example and reject every bad one. This catches
  a wrong translation in the same way a test catches wrong code.

**Recommendation:** design the property language so that (a) is realistic, and
use (c) as the automatic safety net. Don't rely on (b) alone. v1 shows that
layers of AI checking AI give the feeling of independence without the reality.

## Q4. What is Lean's role?

Options, from lightest to heaviest:

- **(a) Lean as the blueprint.** Write a small model of the language's core in
  Lean and prove the Q1 guarantees about the model. Build the real
  implementation separately, in another language, and test it against the model.
  The risk: the implementation can drift from the model, and the proof says
  nothing about the real code.
- **(b) Lean as the implementation.** Write the core type checker and
  interpreter in Lean itself, and prove the guarantees about **that code**.
  There's no gap between the model and the thing that runs. Lean 4 is a real
  programming language and compiles to C. The cost: slower to build, a smaller
  ecosystem, and performance is unproven for this use.
- **(c) Lean inside Mo programs.** Programs carry proofs of their own properties
  (Q1d). v1 rejected dependent types on the evidence that models write them at
  ~27% success, against ~82% for contract style. That figure came from v1's
  research and should be rechecked, not assumed.

**Recommendation:** (b) for the core: the checker and a reference interpreter.
It fits D5 best, because Robert never reads the code, and he doesn't need to:
the proof is about the code. Keep (c) as a later, measured experiment. A fast
production backend can come later and be tested against the proven core, which
is v1's own plan (interpreter as the reference semantics), made trustworthy this
time.

## Q5. What is TLA+'s role?

TLA+ is for concurrency and state over time: processes, supervisors, the
scheduler, crash recovery. It doesn't help with types or syntax.

Options: (a) model the process and supervisor design in TLA+ before any
concurrency is built; (b) skip TLA+ and model concurrency in Lean too; (c) skip
concurrency in the first versions of v2.

**Recommendation:** (c) now, then (a) once the core is proven. v1 built
processes, HTTP and TLS before its core was sound. Concurrency waits until
there's something solid to put it on, and when it comes, its design is checked
in TLA+ first. Mixing both tools (Lean for data and logic, TLA+ for
interleavings) is what Boris Cherny described using on the Agent SDK.

## Q6. How will we know v2 works?

v1 never ran the experiment that could have ended it, and when its tests came
close to failing, the thesis moved. v2 writes its test down first, with a result
that counts as failure.

Options:

- **(a) Language-level:** the Q1 guarantees are proven in Lean, and fuzzing the
  real implementation finds no crash the proof says is impossible. Pass/fail is
  clear, but it only shows the language is sound, not that it helps.
- **(b) The premise test:** give agents the same tasks with seeded bugs in v2
  and in a mainstream language using its best tools. Does v2 catch bugs the
  other misses, at a cost that's acceptable? The margin is set in advance, and
  someone other than the building agent writes the tests.
- **(c) A real program:** Robert uses something built in v2 on real data, and it
  holds up.

**Recommendation:** all three, in that order, each with its pass line written
before work starts. (a) gates growing the language. (b) is the honest answer to
whether v2 is worth continuing, and Robert decides in advance what he'll do if
it fails. That doesn't have to be stopping (D1 says the language is worth
building anyway), but it does mean saying so plainly.

## Q7. What is the first milestone?

Options: (a) a tiny core: integers, booleans, structs, enums, `match`,
functions, `Result`; no loops beyond iterating a collection, no I/O, no
concurrency; (b) the same core plus capabilities (I/O through handed-in values)
so Q1b is real from day one; (c) something larger.

**Recommendation:** (a), then (b) as the second milestone. Done means: the
safety guarantee is proven in Lean about the real checker and interpreter, the
pure part of v1's refund example runs, and one property Robert wrote in English
("a refund never exceeds its charge") is checked by the Q3 method. Small enough
to finish, and enough to test every link in the chain.

## Q8. What comes over from v1?

Each item is keep, defer or drop, decided one at a time. The evidence notes come
from the 22 Sep assessment.

| From v1                                                                      | Evidence                                        | Suggested                     |
| ---------------------------------------------------------------------------- | ----------------------------------------------- | ----------------------------- |
| Robert's syntax picks (Ruby look, `end` blocks, `#` comments, etc.)          | Best part of v1; reads well                     | Keep                          |
| No OOP, immutable by default, `Result` and exhaustive matching, no try/catch | Robert's; sound choices                         | Keep                          |
| Crash on overflow in every build                                             | Robert's                                        | Keep                          |
| Capabilities as the permission system                                        | Never tested against a real attack; strong idea | Keep, as Q1b                  |
| Deterministic simulation with replayable seeds                               | Rated good work                                 | Keep, as Q1c; later milestone |
| Diagnostics with stable codes, "why" and fixes                               | Good, but Go/Python tools scored as well        | Keep the design; build later  |
| `never` clauses, `requires`/`ensures`                                        | Caught zero bugs as runtime checks              | Rethink as Q2/Q3 properties   |
| Processes, supervisors                                                       | Built before the core was sound                 | Defer (Q5)                    |
| Editing by declaration ID                                                    | Robert: "fascinating"; never built              | Defer                         |
| Refinement types                                                             | Never built well                                | Defer; revisit after Q4       |
| Laws that count lines, minimum contract density                              | Measured cost, no measured benefit              | Drop                          |
| Home-made crypto, TLS, HTTP, harness, executor                               | Scope drift; TLS had a real security bug        | Drop                          |
| Zig/C dual runtime                                                           | Unsound, every feature built twice              | Drop                          |
| Auditor, lead/worker/Oracle machinery                                        | Process became the product                      | Drop                          |

## Q9. How is v2 built?

Robert doesn't read code, so how agents work is part of the design.

**Recommendation**, to be decided as a set:

- One agent works at a time, on one bounded task.
- Every task starts with an acceptance check Robert approved (a Lean theorem
  that must be proven, examples that must pass, a real run) and a stop
  condition.
- A Lean proof checked by the kernel counts as acceptance. An AI's say-so never
  does.
- The agent that writes code never edits the checks that accept it.
- A short status note, one screen, updated at the end of each session. No wiki,
  audit protocol or evidence folders unless Robert decides to add them.

## Order of play

Q1 → Q2 → Q3 → Q4 are the foundation and are best decided together in one
session. Q5–Q9 follow from them. Once Q1–Q4 and Q7 are decided, the first build
task can be written.
