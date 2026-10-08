#!/usr/bin/env bash
# Toolchain installers for the Buildkite checks. Source this, then call
# install_rust and/or install_lean.
#
# Pins come from the repository, not from this file where that is possible:
# Lean versions are read from each experiment's `lean-toolchain`, which is the
# file Lake itself obeys. Only the Rust version needs a literal, because no
# `rust-toolchain` file exists; see RUST_PIN below.
#
# Modelled on `.agents/setup`, the repository's own tool installer, so CI
# installs the same things the same way. It is not a copy: CI installs no Koka
# (no Koka benchmark runs here) and no apt packages (Lean 4.34.0 for Linux
# needs only glibc, and ships its own clang and ld.lld).

set -euo pipefail

# rustc 1.99.0 (b940084d7 2026-09-28) is the compiler recorded in
# experiments/11-integer-policies/toolchain.json (a LOCK.json-fingerprinted
# file) and in experiments/10-finite-rust/evidence/toolchain.json. Experiments
# 04, 05, 10 and 11 all need edition 2024, so the floor is 1.85.
RUST_PIN="${RUST_PIN:-1.99.0}"

# elan installer pinned to the release `.agents/setup` uses.
ELAN_INSTALLER="https://raw.githubusercontent.com/leanprover/elan/v4.1.2/elan-init.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step() { printf '\n--- %s\n' "$*"; }

install_rust() {
  step ":rust: Rust ${RUST_PIN}"
  export PATH="$HOME/.cargo/bin:$PATH"
  if ! command -v rustup >/dev/null; then
    local scratch
    scratch="$(mktemp -d)"
    curl -fsSL https://sh.rustup.rs -o "$scratch/rustup-init.sh"
    bash "$scratch/rustup-init.sh" -y --no-modify-path --profile minimal --default-toolchain none
    rm -rf "$scratch"
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  rustup toolchain install "$RUST_PIN" --profile minimal
  # Select the pin by environment rather than by writing a rustup override, so
  # nothing in the checkout or in ~/.rustup/settings.toml records state.
  export RUSTUP_TOOLCHAIN="$RUST_PIN"
  rustc --version
  cargo --version
}

install_lean() {
  step ":lean: Lean toolchains from the experiment pins"
  export PATH="$HOME/.elan/bin:$PATH"
  if ! command -v elan >/dev/null; then
    local scratch
    scratch="$(mktemp -d)"
    curl -fsSL "$ELAN_INSTALLER" -o "$scratch/elan-init.sh"
    bash "$scratch/elan-init.sh" -y --no-modify-path --default-toolchain none
    rm -rf "$scratch"
    export PATH="$HOME/.elan/bin:$PATH"
  fi
  local pin
  while IFS= read -r pin; do
    elan toolchain install "$pin"
  done < <(find "$REPO_ROOT/experiments" -name lean-toolchain -not -path '*/.lake/*' -exec cat {} + | sort -u)
  elan toolchain list
}
