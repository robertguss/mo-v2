#!/usr/bin/env bash
# Run one group of the repository's own verification commands.
#
#   .buildkite/checks.sh rust
#   .buildkite/checks.sh lean
#
# Every command below is taken from this repository: an experiment's
# `RESULT.md` reproduction block, its frozen `ACCEPTANCE.md`, or `CLAUDE.md`.
# This script does not define acceptance criteria for any experiment and does
# not replace or extend one. It re-runs commands that are already approved and
# compares them against outputs that are already committed, so that a push can
# show whether they still pass. Scientific acceptance stays where the locks
# put it.
#
# Nothing here writes inside an experiment except Cargo `target/` and Lake
# `.lake/` build directories, which every experiment already gitignores. Check
# evidence goes to `ci-evidence/` at the repository root.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE="$REPO_ROOT/ci-evidence"
TIMINGS="$EVIDENCE/timings.txt"

# shellcheck source=.buildkite/toolchains.sh
source "$REPO_ROOT/.buildkite/toolchains.sh"

mkdir -p "$EVIDENCE"
: >"$TIMINGS"

now() { date +%s.%N; }

# Fail early and by name, rather than part-way through a check, when the agent
# image is missing something the installers or the frozen checks need.
preflight() {
  printf '\n--- :mag: agent preflight\n'
  local tool missing=()
  for tool in curl git python3 tar diff; do
    command -v "$tool" >/dev/null || missing+=("$tool")
  done
  if ((${#missing[@]})); then
    echo "This agent image is missing: ${missing[*]}" >&2
    return 1
  fi
  python3 --version
  git --version
  uname -srm
}

# run <label> <command...>: announce the command, run it, record wall clock.
run() {
  local label="$1"
  shift
  printf '\n+++ %s\n$ %s\n' "$label" "$*"
  local start elapsed
  start=$(now)
  "$@"
  elapsed=$(python3 -c 'import sys; print("%.1f" % (float(sys.argv[1]) - float(sys.argv[2])))' "$(now)" "$start")
  printf '%8ss  %s\n' "$elapsed" "$label" >>"$TIMINGS"
  printf '\n(%ss) %s\n' "$elapsed" "$label"
}

summary() {
  printf '\n--- :stopwatch: wall clock\n'
  cat "$TIMINGS"
}

# have <experiment-dir>: true when the branch being built carries that
# experiment. Branches that predate an experiment -- for example
# codex/native-migration-resource-limit, which forked before experiments 10 and
# 11 landed -- are checked against what they actually contain, and the skip is
# printed rather than passed over quietly.
have() {
  if [ -d "$REPO_ROOT/experiments/$1" ]; then
    return 0
  fi
  printf '\n--- :fast_forward: skipping %s: not on this branch\n' "$1"
  printf '%8s  %s (not on this branch)\n' "skip" "$1" >>"$TIMINGS"
  return 1
}

# --------------------------------------------------------------------------
# Rust: release builds of the experiment crates, plus the two frozen Rust
# correctness corpora. No timing, allocation or load measurement runs here.
# --------------------------------------------------------------------------

rust_checks() {
  preflight
  install_rust

  # Experiment 4, RESULT.md "Reproduction and retained files" (build only; its
  # acceptance run needs Java and the TLA+ TLC jar). RESULT.md's check table
  # requires no compiler warnings, so warnings are denied.
  if have 04-live-update; then
    cd "$REPO_ROOT/experiments/04-live-update"
    run "04-live-update: release build" env RUSTFLAGS='-D warnings' \
      cargo build --release --locked --offline --manifest-path runtime/Cargo.toml
  fi

  # Experiment 5, same shape as experiment 4.
  if have 05-concurrent-updates; then
    cd "$REPO_ROOT/experiments/05-concurrent-updates"
    run "05-concurrent-updates: release build" env RUSTFLAGS='-D warnings' \
      cargo build --release --locked --offline --manifest-path runtime/Cargo.toml
  fi

  # Experiment 11, RESULT.md "Reproduction": both release builds, both frozen
  # case runs (12,563 cases each) and the allocator calibration. The `measure`
  # subcommand is deliberately left out; see .buildkite/README.md.
  if have 11-integer-policies; then
    cd "$REPO_ROOT/experiments/11-integer-policies"
    run "11-integer-policies: timing build" \
      env RUSTFLAGS='-D warnings' CARGO_TARGET_DIR=target/timing \
      cargo build --release --locked
    run "11-integer-policies: allocator build" \
      env RUSTFLAGS='-D warnings' CARGO_TARGET_DIR=target/allocator \
      cargo build --release --locked --features measure
    run "11-integer-policies: 12,563 frozen cases (timing build)" \
      python3 check.py cases target/timing/release/integer-policies "$EVIDENCE/11-cases-timing"
    run "11-integer-policies: 12,563 frozen cases (allocator build)" \
      python3 check.py cases target/allocator/release/integer-policies "$EVIDENCE/11-cases-allocator"
    run "11-integer-policies: allocator calibration" \
      target/allocator/release/integer-policies calibrate
  fi

  # Experiment 10, RESULT.md "Reproduction and evidence": compiles backend.rs
  # with `rustc --edition 2024 -D warnings` and compares 4,276 cases and 27,721
  # snapshots against the Lean model's frozen export.
  if have 10-finite-rust; then
    cd "$REPO_ROOT"
    run "10-finite-rust: 4,276 cases against the Lean model" \
      python3 experiments/10-finite-rust/check.py "$EVIDENCE/10-correspondence"
  fi

  summary
}

# --------------------------------------------------------------------------
# Lean: the proof builds, the kernel re-check and the one Lean run whose
# expected output is committed.
# --------------------------------------------------------------------------

lean_checks() {
  preflight
  install_lean

  # Experiment 1, RESULT.md: the Lake build kernel-checks the safety and
  # usefulness theorems and prints the axioms each depends on.
  if have 01-tiny-safe; then
    cd "$REPO_ROOT/experiments/01-tiny-safe"
    run "01-tiny-safe: lake build" lake build
  fi

  # Experiment 2, RESULT.md and CLAUDE.md "Practical notes": the build checks
  # the two proofs; `lake exe score` prints the seven-method scoreboard.
  if have 02-withdraw; then
    cd "$REPO_ROOT/experiments/02-withdraw"
    run "02-withdraw: lake build" lake build
    # Smoke run only: `main : IO Unit`, so this reports and always exits 0. It
    # catches a crash or a build that produced no runnable scoreboard, nothing
    # more. Read the printed table; do not treat exit 0 as a scored result.
    run "02-withdraw: lake exe score (smoke run, prints the scoreboard)" lake exe score
  fi

  if have 03c-checker; then
    cd "$REPO_ROOT/experiments/03c-checker/trial/lean"
    rm -rf .lake
    run "03c trial: clean lake build Trial Checks Promises Proofs Acceptance" build_03c
    run "03c trial: Checks/Run.lean reproduces results/run-1.txt" run1_03c
    run "03c trial: lake env leanchecker --fresh Acceptance" \
      lake env leanchecker --fresh Acceptance
  fi

  # Experiment 10, RESULT.md "Reproduction and evidence": verifies the 270
  # tracked-file fingerprints in evidence/reference-sha256.json, rebuilds the
  # accepted Lean model in a disposable copy, and requires the fresh export to
  # equal the frozen expectations byte for byte.
  if have 10-finite-rust; then
    cd "$REPO_ROOT"
    run "10-finite-rust: rebuild the Lean reference and reproduce the export" \
      python3 experiments/10-finite-rust/reproduce_reference.py "$EVIDENCE/10-reference"
  fi

  summary
}

# Experiment 3c trial, ACCEPTANCE.md "How a proof is checked" check 4: a clean
# rebuild succeeds "with no errors and no warnings". Lake exits 0 on warnings,
# so the log is inspected. The axiom lines that check 6 asks a reader to judge
# are echoed; this refuses only `sorryAx`, which check 6 names as meaning not
# accepted. Run from the Lake directory.
build_03c() {
  local log="$EVIDENCE/03c-build.log"
  lake build Trial Checks Promises Proofs Acceptance 2>&1 | tee "$log"

  if grep -qi 'warning' "$log"; then
    echo "ACCEPTANCE.md check 4 requires no warnings; the build log has some:" >&2
    grep -i 'warning' "$log" >&2
    return 1
  fi
  if grep -q 'sorryAx' "$log"; then
    echo "ACCEPTANCE.md check 6: sorryAx means not accepted." >&2
    grep -n 'sorryAx' "$log" >&2
    return 1
  fi
  printf '\nAxioms the four accepted theorems depend on:\n'
  grep 'depends on axioms:' "$log" || {
    echo "Acceptance.lean printed no axiom lines; expected four." >&2
    return 1
  }
}

# Experiment 3c trial, ACCEPTANCE.md check 8: the checks of run 1 "give the
# same report as results/run-1.txt". The committed file is the expectation; it
# is read, never written. Run from the Lake directory.
run1_03c() {
  local actual="$EVIDENCE/03c-run-1.txt"
  lake env lean --run Checks/Run.lean >"$actual"
  diff -u ../results/run-1.txt "$actual"
}

case "${1-}" in
  rust) rust_checks ;;
  lean) lean_checks ;;
  *)
    echo "usage: $0 {rust|lean}" >&2
    exit 64
    ;;
esac
