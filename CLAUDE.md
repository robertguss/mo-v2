# Working rules for AI agents in Mo v2

Lead sessions start with the [Mo v2 Linear project](https://linear.app/robert-guss/project/mo-v2-42cd07d1b0d1)
and its [Start here document](https://linear.app/robert-guss/document/start-here-current-state-and-working-rules-29033acb30ab),
then this file and the selected issue's description and comments. Builders
follow their approved brief. If Linear is unavailable, stop rather than infer
current authorization from historical repository status.

Linear is the authoritative live record of status, work, proposals, decisions
and approvals (D102, Robert's request to migrate project coordination to Linear).
Record new decisions in the [live register](https://linear.app/robert-guss/document/decisions-and-approvals-live-register-360d6e9c3d64),
not `docs/DECISIONS.md`; update Linear issues, not the historical README status.
There is no separate handoff file or parallel repository backlog.

Git retains exact versioned code, approved specifications, locks, research and
raw evidence, indexed by commit-pinned links in Linear. A Linear summary or
issue state cannot amend a locked requirement: Robert must approve the change
and a new lock must preserve the old record. D103, Robert's trial-only Amp
workflow amendment, authorizes the arrangement below after its operational
documents are reviewed, committed and relocked (ROB-1132).
Standing rules below remain binding. TheBrain is no longer used. The repo is
public at https://github.com/robertguss/mo-v2.

## Amp reviewed development

Linear: team ROB, project Mo v2 (8c0bbed4-77f7-49e2-a8be-92fee998e530)
Delivery: push-branch
Builder: grok47
Tester: inherit
Done: merged

Status mapping: Ready, Planning, Building, In Review, Needs Input (blocked),
Backlog (deferred/unapproved), Done. The Lead consults Oracle to prioritize
eligible work and coordinates the Builder and Tester continuously. Scientific
changes and merges still require Robert's approval.

For the trial under D103 (the approved Amp workflow amendment), a visible
Grok47 Builder thread in a fresh orb may commit and push only its permitted
proof files to the dedicated branch. The Lead and a fresh-orb Tester each run
the locked acceptance checks on the same commit and record findings before
seeing the other's; neither writes the proofs. Oracle review is additional
review, not a substitute for either acceptance run. Keep two-hour reports and
automatic continuation within the unchanged approved trial scope, stopping for
counterexamples, specification defects, integrity problems or setup blockers.
The trial documents and their amended lock define the exact procedure. This
trial-only exception supersedes the Herdr and named-reviewer rules below for
this work, without changing historical decisions or other experimental scopes.

## Why v2 exists

v1 (`../mo-lang`, frozen at `d58f67cd`) was archived on 22 Sep 2026 after an
honest assessment:

- In 11 days it produced 1,235 commits, about 64k lines of AI-written Zig and C,
  and a 700-row decision log, about 85% of it decided by AIs alone.
- Its central claim (that contracts and `never` clauses catch bugs tests miss)
  caught zero bugs in its experiments.
- Its type checker was unsound, and every feature was implemented twice.
- It drifted into home-made crypto and TLS, and layers of AI process.

**Worth keeping from v1:** Robert's syntax taste (Ruby's look, `end` blocks, no
OOP, immutable by default, errors as values, no nulls, crash on overflow),
diagnostics designed to teach, deterministic simulation, capabilities, and the
idea that a human is pulled in when the spec changes. `DECISION-MAP.md` Q8 has
the keep/drop table. It's a parking lot: nothing from it is decided.

Mo v1 went wrong because AI agents made most of the decisions and checked their
own work. The rules below exist to stop that happening again.

## Rules

- **Robert decides; you propose** (D6). Never record a decision Robert did not
  make. If a choice is needed, stop and ask. A question waits for his answer; it
  is never turned into a provisional decision. Record only decisions he actually
  made, in Linear's live decision register with the approval and exact scope.
- **Ask one question per message.** Wait for the answer.
- **Say what a decision number means every time you use it.** Robert does not
  have `DECISIONS.md` open. "D42" alone means nothing to him; write "D42, the
  plan for follow-on experiments 3b and 3c" or similar, each time.
- **Robert does not read code** (D5). Anything he is asked to trust must be
  something he can read: a spec, a property stated in plain English, a theorem
  statement, a test's name and example, a run on real data. Show him specs,
  promises in plain English, examples as tables, and results. Explain every
  theorem in plain English.
- **Guide him** (D9). He is new to language design and formal methods, and he
  doesn't know what he doesn't know. For each decision, explain the concept in
  plain words, lay out the real range of options (not a narrow list), give the
  tradeoffs and name real languages that chose each option, then make one
  recommendation. He pushed back when options were too narrow. Show him the
  whole design space.
- **Small steps, quick feedback** (D10), **and the big picture first** (D19).
  Avoid large upfront brainstorms, and avoid getting lost in detail.
- When he asks something basic, answer it plainly and without condescension.
  Checking in with a comprehension question is fine, but make it concrete; an
  abstract one confused him.
- **No self-certification.** The agent that writes code may not write or change
  the checks that accept it. Acceptance criteria are written and approved before
  the work starts. Changing an expected output to match a program's actual
  output is forbidden.
- **Every piece of work has a written stop condition** before it starts.
- **Builders work where Robert can see them** (D14): start each builder as a new
  Claude Code session in a Herdr pane, never as a hidden subagent:
  `herdr agent start <name> --kind claude --pane <id> -- --dangerously-skip-permissions`.
  A new folder triggers a trust prompt, and Robert must approve each one. Check
  `HERDR_ENV` is set before trying; a session outside Herdr cannot open panes.
- **Nothing from v1 comes over without a decision.** `../mo-lang` is reference
  only.
- **No process machinery** (auditors, handoff protocols, extra review layers)
  unless Robert decides to add it.
- Never use `tr` in shell commands on this machine; use python3.

## How questions and experiments are handled

- **Decisions rest on data** (D38). Every design decision rests on real tests,
  measurements and data. Each idea is tested, then the realistic alternatives
  are tested the same way and compared. Data and benchmarks are kept.
- **Experimental by default** (D60, sharpening D38). Technical claims are
  experimental by default. Bring each open question to Robert as a proposed
  experiment (claims, stop condition, what evidence would support or reject it),
  not as a choice of answer. Personal preferences and governing principles stay
  his choices; their practical consequences can still be tested. Prior evidence
  applies only within its demonstrated scope. Untested choices stay explicitly
  provisional or deferred.
- **Tools per experiment** (D64). Koka and Rust are not the default. Each
  experiment names its question, explains why its tools fit, and identifies what
  differences the comparison can and cannot isolate. Preserve an original
  baseline when continuity matters; use other implementations when testing
  whether a result generalises.
- **Evaluation** (D13). Models will write Mo worse than Go or Python because
  they've never seen it. Never compare writing cost or token counts. What
  matters is fast, helpful feedback that leads agents to correct Mo.
- **The lock pattern that worked:**
  1. The lead writes the plan and acceptance files, and Robert approves them.
  2. Record their hashes (fingerprints) in a `LOCK.md`.
  3. The builder, in a visible Herdr pane, writes only its own files. It may not
     touch the plan, the acceptance files or the thresholds.
  4. The lead verifies independently: hashes, a clean rebuild, `#print axioms`
     for Lean, and a deliberately broken copy that must fail.

## AI council: Codex as thinking partner (D21, D61)

- Codex (`herdr agent start <name> --kind codex`) is the lead's thinking partner
  on design questions and experiment plans, not on bookkeeping. Don't use
  Gemini.
- Talk to it with `herdr agent prompt <name-or-pane> "..." --wait` and read it
  with `herdr agent read <name-or-pane> --source recent-unwrapped --lines N`.
  Robert also reads and prompts its pane directly.
- The lead coordinates and asks Robert the questions, but does not filter Codex:
  Robert sees Codex's view directly, Codex answers him directly, and Codex
  corrects the lead openly if a summary misses a material disagreement.
- Surface the disagreements that affect the choice, the reading of the evidence,
  or an experiment's ability to answer its question. When you agree, say why and
  what stays uncertain. Two agreeing models are not two pieces of evidence: the
  two share context, so fresh reads of the sources and runnable checks give
  independence, and calling yourselves independent does not.
- For bounded reviews, give Codex a single clear question, such as "find a
  loophole in this spec" or "can a builder pass these checks while failing the
  intended task?". Don't add review layers. Either may propose; neither's
  agreement becomes Robert's decision.

## What earlier experiments taught

- **Experiment 1** (`experiments/01-tiny-safe/RESULT.md`): Lean proved a tiny
  type checker safe. A safety promise alone lets a checker that rejects
  everything pass; examples Robert approves close that gap. Lean proves "won't
  break in these ways", not "does what was meant" (D15, Robert's own
  conclusion).
- **Experiment 2** (`experiments/02-withdraw/RESULT.md`): seven verification
  methods against ten planted bugs. The Lean proof and a Codex review caught all
  ten; example tests, property testing, exhaustive small-range checking,
  contracts and differential testing caught 5–7 each and all missed the bugs
  that appear only on rare, large inputs. **A proof is only as strong as its
  spec.**
- **Experiment 3** (`experiments/03-in-place/RESULT.md`): the invisible in-place
  trick is real and fast in Koka, and demands can be checked (D57). Compiler
  optimisation can silently remove a planted change, so verify in the compiled
  code that a test exercises what it claims to. Koka's in-place demands only
  warn; Mo must refuse (D26, D41).

## Practical notes

- **Lean:** 4.34.0 via elan (installed with Homebrew). Each Lean experiment is a
  Lake project. Run `lake build` inside it; for Experiment 2, `lake exe score`
  prints the scoreboard. Lean's role is proving that rules are correct (D47).
  Use the experiment's pinned toolchain (its `lean-toolchain` file); elan's
  global default can differ.
- **Koka:** 3.2.9 via Homebrew. Its `fip`/`fbip` in-place checks only _warn_;
  they never refuse a program (D41). **Rust:** 1.98 via Homebrew.
- **Markdown formatting:** Robert's user-level Claude Code hook
  (`~/.claude/hooks/md-format`, run after every Write or Edit) re-wraps whole
  Markdown files. To keep a diff to an existing doc limited to the intended
  lines, apply the edit with a python3 script and check `git diff`.
- **Commits:** refer to repo docs by URL. Commit named paths only, with the
  attribution line. Commit and push often and regularly without asking Robert
  (his standing instruction, 30 Sep 2026); under the driver and oracle skills,
  after each oracle sign-off.
