# Buildkite CI

This directory holds the whole CI setup. There is no GitHub Actions workflow
and none should be added.

| File | What it is |
| --- | --- |
| `pipeline.yml` | The pipeline the upload step reads: two parallel steps. |
| `checks.sh` | Runs one group of checks, `rust` or `lean`. |
| `toolchains.sh` | Installs the pinned Rust and Lean toolchains. Sourced by `checks.sh`. |
| `coverage.txt` | Every experiment, named `checked` or `excluded`, with a reason. Enforced. |

The pipeline is `robert-guss/mo-v2`, connected to `robertguss/mo-v2` by GitHub
webhook. It builds branch pushes and pull requests and publishes commit
statuses back to GitHub. Its whole Steps setting is one line,
`buildkite-agent pipeline upload`, so everything that decides what a build does
lives in this directory and is reviewed with the code.

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

A branch is checked against the experiments it actually carries. A branch cut
before an experiment landed skips it, loudly, with a line in the wall clock
summary; it does not fail and it does not pass over the gap quietly.

Both steps were shown to go red on deliberately broken copies, as `CLAUDE.md`'s
lock pattern asks: experiment 11's "saturate instead of wrap" control, a
`sorry` put back into experiment 3c's `promiseA`, `ACCEPTANCE.md`'s documented
"Running a broken copy" change in `Trial/Broken.lean`, and a tampered
`results/run-1.txt`. Each was planted in a disposable copy outside the
repository.

## Every experiment is decided about

`coverage.txt` names every directory under `experiments/` as `checked` or
`excluded`, with a reason. `checks.sh` reads it during preflight and **fails**
when `experiments/` holds a directory the file does not mention. A new
experiment therefore turns CI red until someone records which it is, rather
than being quietly ignored.

`excluded` means "not run on a Linux CI agent". It is not a claim that an
experiment is unverified: the excluded ones were verified on Robert's macOS
machine and their evidence is committed. A `coverage.txt` entry for an
experiment a branch does not carry is fine; that branch skips it.

## What is deliberately left out, and why

- **Experiments 6, 7, 8 and 9** (`check.py` in each). Three independent
  reasons, each sufficient:
  1. They build shared libraries with `clang -dynamiclib` into `.dylib` files.
     On Linux, `clang -dynamiclib` is rejected outright: `argument unused
     during compilation: '-dynamiclib' [-Werror,-Wunused-command-line-argument]`.
  2. Their `host.rs` does not even link on Linux. It calls `_dyld_image_count`
     and `_dyld_get_image_name`, so
     `rustc --edition 2024 -D warnings host.rs` fails at
     `rust-lld: error: undefined symbol: _dyld_image_count`. A
     type-check-only variant would pass, but that is a weaker check than the
     documented command and would not be the repository's own.
  3. They turn on deadlines, stalls and `time.sleep` windows, which would be
     timing-flaky on a shared runner even if they could run. Experiment 9 also
     reads thread counts from `ps -M`, which on Linux prints SELinux labels
     rather than Mach threads — so it would report something meaningless
     instead of failing.
- **Every timing, allocation and load measurement.** Experiment 11's
  `check.py measure` (627 timed executions), experiment 3's and 3b's
  `./run.sh`, and experiment 10's allocator totals. They are observational and
  machine-dependent: `RESULT.md` reports them with the machine named, and a
  shared CI runner would produce different numbers without that meaning
  anything. Experiment 11's measurement also calls `/usr/bin/time -l`, which is
  BSD/macOS-only.
- **Experiment 4's and 5's acceptance runs.** They need Java 21 and the TLA+
  TLC jar, which is downloaded by SHA-256 and not committed, and they drive a
  socket server against activation deadlines. Their release builds run; their
  timed acceptance runs do not.
- **Experiment 3's and 3b's Rust crates.** Their `build.rs` compiles mimalloc
  from a hard-coded `/opt/homebrew/Cellar/koka/3.2.9/...` path. `docs/README.md`
  already records that these runners "still assume macOS/Homebrew paths and
  measurement tools".
- **The mutation and control runners** (`mutate.py`, `controls.py` in
  experiments 4, 5, 6, 7, 8, 9, 10, 11). They rewrite experiment sources to
  build deliberately broken variants and write into fixed evidence
  destinations. They belong to an experiment's one-time control record, not to
  a per-push check.
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

If the native experiments should be checked rather than excluded, that needs a
macOS agent. The Default cluster already has `macos-medium` and `macos-large`,
so it would be a third step with `agents: queue: macos-medium` running
`check.py` for experiments 6 to 9, and four `coverage.txt` lines changed from
`excluded` to `checked`. Two reasons it is not here: it costs macOS minutes on
every push, and those trials hinge on 200ms–950ms deadline windows and
deliberately stalled threads, so they may be too timing-sensitive for per-push
CI even on the right operating system. That is a decision for Robert, not
something CI should assume.

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

## The agent queue

`pipeline.yml` targets `queue: "${MO_CI_QUEUE:-linux-small}"`. To move the work
to another queue in the Default cluster — `linux-medium`, `linux-large` — set
`MO_CI_QUEUE` in Pipeline Settings → Environment Variables; no file needs
editing.

`linux-small` fits, measured rather than assumed:

| | Rust step | Lean step |
| --- | --- | --- |
| Wall clock, cold | 14.9s | 1m54s |
| Peak resident memory | 625 MB | 535 MB |
| CPU used ÷ wall clock | 1.23× | 1.06× |
| Disk, mostly toolchain | ~640 MB | ~3.1 GB |

Neither step is limited by cores or memory. The single longest command in the
whole build is `lake env leanchecker --fresh Acceptance` at about 50s, and it
runs at exactly 1.00× CPU — strictly single-threaded. A larger queue would cost
more per minute without shortening the critical path, so the queue is not the
lever here; if a two-minute build ever becomes the constraint, the Lean step's
shape is what to look at.

## Branches without this directory

There is no fallback, on purpose. Every branch cut from main carries
`.buildkite/`, and a branch old enough to lack it fails with
`buildkite-agent pipeline upload` reporting the missing file — which says what
to do (merge or rebase main) more plainly than a fallback would.

A fallback would also run *main's* CI definition against a branch's code, which
hides the case where a branch needs different CI, and it would need the same
restore repeated in every step, since a step can land on a different agent with
its own checkout. The stale remote branches that predate this directory are
only affected if someone pushes to them, and merging main is the right answer
then anyway.
