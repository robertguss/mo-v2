#!/usr/bin/env bash
# Reconstruct frozen source + D191 + proof-only additions. No build cache copied.
set -euo pipefail
repo=$(git rev-parse --show-toplevel)
full=$repo/experiments/03c-checker/full
evidence=$full/stage-1/completion/evidence
clean=$(mktemp -d /tmp/rob1139-stage1-complete.XXXXXX)
printf '%s\n' "$clean" > "$evidence/clean-directory.txt"
exec > >(tee "$evidence/reproduction.log") 2>&1
cd "$full"
for inventory in stage-1/rank-amendment-01/FREEZE.sha256 \
  stage-1/rank-amendment-01/PREPARATION.sha256 BASELINE.sha256 FREEZE.sha256 \
  stage-1/rank-amendment-01/EVIDENCE.sha256 stage-1/completion/PROOFS.sha256; do
  sha256sum -c "$inventory"
done
git -C "$repo" archive f427d0fe1a4badb9d1fd470e6e3ef83a06f2f6a5 \
  experiments/03c-checker/full experiments/03c-checker/trial | tar -x -C "$clean"
cf=$clean/experiments/03c-checker/full
git -C "$repo" show ca4a020a6c66ea54aead82c63662a9edb7220bf0:experiments/03c-checker/full/lean/Full/Control.lean > "$cf/lean/Full/Control.lean"
cp lean/Full/Proofs.lean "$cf/lean/Full/Proofs.lean"
cp -R lean/Full/Proofs "$cf/lean/Full/Proofs"
# Restore only archived historical data needed by the frozen inventory.
cp verification/evidence/raw.json.gz "$cf/verification/evidence/raw.json.gz"
cd "$cf"
sha256sum -c "$full/stage-1/rank-amendment-01/PREPARATION.sha256"
sha256sum -c BASELINE.sha256
sha256sum -c FREEZE.sha256
sha256sum -c "$full/stage-1/completion/PROOFS.sha256"
test -z "$(find "$clean" -name .lake -type d -print -quit)"
cd lean
lake env lean --version
lake build Full Full.Proofs > "$evidence/clean-build.log" 2>&1
tail -1 "$evidence/clean-build.log"
lake env lean -o .lake/build/lib/lean/ProofGate.olean ProofGate.lean > "$evidence/clean-gate.log" 2>&1
cat "$evidence/clean-gate.log"
lake env leanchecker --fresh ProofGate > "$evidence/clean-kernel.log" 2>&1
echo 'PASS clean ProofGate fresh kernel (exit 0)'
python3 "$cf/run_spec.py" "$clean/observations" > "$evidence/finite-suite.log" 2>&1
python3 "$cf/acceptance/supplemental-v2/check_expanded.py" "$clean/observations" \
  --report "$evidence/expanded-results.json" > "$evidence/expanded.log" 2>&1
python3 "$cf/verification/check_final.py" "$clean/observations" \
  --report "$evidence/boundary-results.json" > "$evidence/boundaries.log" 2>&1
lake -d ../../trial/lean build Checks > "$evidence/trial-checks-build.log" 2>&1
lake env lean --run TrialCompatibility.lean > "$evidence/trial-compatibility.log" 2>&1
lake env lean --run ../verification/ReviewCases.lean > "$evidence/review-cases.log" 2>&1
lake env lean -o .lake/build/lib/lean/Export.olean Export.lean > "$evidence/export-build.log" 2>&1
FULL3C_INPUTS="$clean/observations/inputs.json" lake env lean ../verification/Controls.lean > "$evidence/controls.log" 2>&1
sha256sum "$clean/observations/inputs.json" "$clean/observations/raw.json" \
  "$clean/observations/summary.json" > "$evidence/observations.sha256"
cp "$clean/observations/inputs.json" "$clean/observations/summary.json" "$evidence/"
cd "$cf"
sha256sum -c "$full/stage-1/rank-amendment-01/PREPARATION.sha256"
sha256sum -c BASELINE.sha256
sha256sum -c "$full/stage-1/completion/PROOFS.sha256"
cd "$full"
sha256sum -c stage-1/completion/PROOFS.sha256
echo 'PASS clean reconstruction, exact gate, fresh kernel, finite suite, and controls'
