# Buildkite CI

This directory holds the whole CI setup. There is no GitHub Actions workflow
and none should be added.

| File | What it is |
| --- | --- |
| `bootstrap.yml` | A record of the YAML to paste into Pipeline Settings → Steps in the Buildkite UI. Buildkite does not read it from the repository. |
| `pipeline.yml` | The pipeline the bootstrap step uploads: two parallel steps. |
| `checks.sh` | Runs one group of checks, `rust` or `lean`. |
| `toolchains.sh` | Installs the pinned Rust and Lean toolchains. Sourced by `checks.sh`. |

## What CI is for here

CI re-runs verification commands this repository already documents and
compares them against outputs this repository already commits. It does not
define, replace or extend any experiment's acceptance criteria, and it is not
an independent acceptance run. Every command is traceable to an experiment's
`RESULT.md` reproduction block, its frozen `ACCEPTANCE.md`, or `CLAUDE.md`;
`checks.sh` names the source beside each one.

Nothing CI runs writes inside an experiment, apart from Cargo `target/` and
Lake `.lake/` build directories that every experiment already gitignores.
Check output goes to `ci-evidence/` at the repository root and is uploaded as
build artifacts.

## What runs

Two steps, in parallel.

**`:rust: Rust builds and frozen corpora`**

| Check | Source |
| --- | --- |
| Experiment 4 runtime release build, `--locked --offline`, warnings denied | `04-live-update/RESULT.md` |
| Experiment 5 runtime release build, same | `05-concurrent-updates/RESULT.md` |
| Experiment 11 timing and allocator release builds, `--locked` | `11-integer-policies/RESULT.md` |
| Experiment 11: 12,563 frozen cases against each of the two builds | same |
| Experiment 11 allocator calibration | same |
| Experiment 10: 4,276 cases and 27,721 snapshots against the Lean model's frozen export | `10-finite-rust/RESULT.md` |

**`:lean: Lean proofs and kernel re-check`**

| Check | Source |
| --- | --- |
| Experiment 1 `lake build` (the safety and usefulness theorems) | `01-tiny-safe/RESULT.md` |
| Experiment 2 `lake build`, then `lake exe score` as a smoke run | `02-withdraw/RESULT.md`, `CLAUDE.md` |
| Experiment 3c trial: clean `lake build Trial Checks Promises Proofs Acceptance`, no errors and no warnings | `03c-checker/trial/ACCEPTANCE.md` check 4 |
| Experiment 3c trial: `Checks/Run.lean` reproduces `results/run-1.txt` exactly | same, check 8 |
| Experiment 3c trial: `lake env leanchecker --fresh Acceptance` | same, check 7 |
| Experiment 10: rebuild the Lean reference in a disposable copy, verify 270 tracked-file fingerprints, reproduce the frozen export byte for byte | `10-finite-rust/RESULT.md` |

`lake exe score` is labelled a smoke run on purpose: experiment 2's `main` has
type `IO Unit`, so it prints the scoreboard and always exits 0. It catches a
crash, not a wrong row. Read the table in the log.

The experiment 3c build log also carries the axioms each of the four accepted
theorems depends on (`ACCEPTANCE.md` check 6 asks a reader to judge those).
`checks.sh` refuses only `sorryAx`, which that check names as meaning not
accepted; it does not try to score the axiom list itself.

A branch is checked against the experiments it actually carries. A branch that
forked before an experiment landed skips it, loudly, with a line in the wall
clock summary; it does not fail and it does not pass over the gap quietly.

Both steps were shown to go red on deliberately broken copies, as `CLAUDE.md`'s
lock pattern asks: experiment 11's "saturate instead of wrap" control, a
`sorry` put back into experiment 3c's `promiseA`, `ACCEPTANCE.md`'s documented
"Running a broken copy" change in `Trial/Broken.lean`, and a tampered
`results/run-1.txt`. Each was planted in a disposable copy outside the
repository.

## What is deliberately left out

- **Every timing, allocation and load measurement.** Experiment 11's
  `check.py measure` (627 timed executions), experiment 3's and 3b's
  `./run.sh`, and experiment 10's allocator totals. They are observational and
  machine-dependent: `RESULT.md` reports them with the machine named, and a
  shared CI runner would produce different numbers without that meaning
  anything. Experiment 11's measurement also calls `/usr/bin/time -l`, which is
  BSD/macOS-only.
- **Experiments 6, 7 and 8** (`check.py` in each). They build shared libraries
  with `clang -dynamiclib` into `.dylib` files, which is macOS-only, and they
  turn on deadlines, stalls and `time.sleep` windows. Both reasons rule them
  out: they cannot run on a Linux agent, and they would be timing-flaky if they
  could.
- **Experiment 4's and 5's acceptance runs.** They need Java 21 and the TLA+
  TLC jar, which is downloaded by SHA-256 and not committed, and they drive a
  socket server against activation deadlines. Their release builds run; their
  timed acceptance runs do not.
- **Experiment 3's and 3b's Rust crates.** Their `build.rs` compiles mimalloc
  from a hard-coded `/opt/homebrew/Cellar/koka/3.2.9/...` path. `docs/README.md`
  already records that these runners "still assume macOS/Homebrew paths and
  measurement tools".
- **The mutation and control runners** (`mutate.py`, `controls.py` in
  experiments 4, 5, 6, 7, 8, 10, 11). They rewrite experiment sources to build
  deliberately broken variants and write into fixed evidence destinations. They
  belong to an experiment's one-time control record, not to a per-push check.
- **A formatting or lint check.** The repository is not clean under
  `cargo fmt --check`: experiments 4 and 5 pass, but
  `11-integer-policies/src/main.rs` is written in a dense hand style that
  rustfmt rewrites. Adding the check would either fail on main or quietly pick
  one experiment's style over another's, which is Robert's call, not CI's. No
  Rust crate in the repository has a `#[test]`, so there is no unit-test suite
  to run; the frozen `check.py` corpora are the equivalent.
- **The lock checks** (`ACCEPTANCE.md` checks 1 and 2, and
  `experiments/*/LOCK.*`). They compare a working tree against a named lock
  commit for one experiment's authorship boundary. That is a merge gate for a
  specific experiment, decided per experiment, not a property of every push.

## Toolchain pins

- **Rust 1.99.0.** The repository has no `rust-toolchain` file. 1.99.0 is the
  compiler recorded in `experiments/11-integer-policies/toolchain.json` (a file
  fingerprinted by that experiment's `LOCK.json`) and in
  `experiments/10-finite-rust/evidence/toolchain.json`. Override with `RUST_PIN`
  if that ever needs to move. Note that `.agents/setup` still pins 1.98.1,
  which predates experiments 10 and 11; both versions clear the edition-2024
  floor of 1.85.
- **Lean 4.34.0.** Not written in CI at all. `toolchains.sh` installs every
  distinct pin found in `experiments/**/lean-toolchain`, which is the file Lake
  obeys, so the pin stays in the experiments.
- **Python.** The agent's system `python3`. The frozen checks use only the
  standard library. `RESULT.md` files record Python 3.13.7; CI prints whatever
  it has.

`toolchains.sh` is modelled on `.agents/setup`, the repository's own installer,
so CI installs the same things the same way. It installs no Koka (no Koka
benchmark runs here) and no apt packages: Lean 4.34.0 for Linux needs only
glibc and ships its own `clang` and `ld.lld`.

## Changing the agent queue

`pipeline.yml` targets:

```yaml
agents:
  queue: "${MO_CI_QUEUE:-default}"
```

`default` is the queue name Buildkite creates with a new cluster. To use a
hosted queue under another name, set `MO_CI_QUEUE` in Pipeline Settings →
Environment Variables; no file needs editing. If a build sits waiting for an
agent, this is the first thing to check.

`bootstrap.yml` names no queue, so the upload step goes to the cluster's own
default queue. That keeps the step that reads `MO_CI_QUEUE` from also depending
on it being right.

## Branches without this directory

`bootstrap.yml` uploads `.buildkite/pipeline.yml` from the branch being built
when it is there, and otherwise takes main's copy. Each step in `pipeline.yml`
repeats the same restore, because a step can land on a different agent with its
own fresh checkout. The restore is written inline in both files on purpose: on
a branch with no `.buildkite/` directory there is no helper script to call.

This is what lets `codex/native-migration-resource-limit` (draft PR #2) build
without being rebased. The restore uses `git fetch origin main`, so it needs
main to be reachable from the build's remote; a pull request from a fork would
need the fork to carry main, or the fallback would have to point at an
upstream remote instead.
