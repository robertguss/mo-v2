#!/usr/bin/env bash
# Fail when the history of the checked-out commit holds .gz evidence that was
# moved to the gz-evidence-archive release (experiments/GZ_ARCHIVE.md). A branch
# still built on the pre-rewrite history, or a new commit of such a file, would
# bring the 3.5 GB back.
#
# The Buildkite pipeline's Steps setting runs main's copy of this script before
# the pipeline upload, so a branch cannot skip it by carrying an older
# pipeline.yml. See README.md "History guard".

set -euo pipefail

# A shallow checkout cannot see old commits. The stripped history is ~10 MB.
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  git fetch --quiet --unshallow
fi

found=$(git rev-list --objects HEAD | awk '
  $2 ~ /^experiments\/13-source-acceptance\/.*\.gz$/ ||
  $2 == "experiments/03c-checker/full/verification/evidence/raw.json.gz" { print $2 }' | sort -u)

if [ -n "$found" ]; then
  echo "The history of this commit contains .gz evidence that belongs in the gz-evidence-archive release:" >&2
  echo "$found" | sed -n '1,20s/^/  /p' >&2
  echo "Rebase onto the rewritten origin/main; see experiments/GZ_ARCHIVE.md." >&2
  exit 1
fi
echo "No archived .gz evidence in the history of $(git rev-parse --short HEAD)."
