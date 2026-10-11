# Gzip evidence archive

The `.gz` evidence files (3.5 GB) were removed from git history on 10 Oct 2026
to keep clones small. Every byte is kept as assets of the GitHub release
[`gz-evidence-archive`](https://github.com/robertguss/mo-v2/releases/tag/gz-evidence-archive):
every `experiments/13-source-acceptance/**/*.gz` file, plus the history-only
`experiments/03c-checker/full/verification/evidence/raw.json.gz`.
The stage-1 amended-rank trace is stored separately in
`gz-03c-checker-rank-amendment-01.tar`, preserving its original path and bytes.
`GZ_ARCHIVE.sha256` in this checkout lists the sha256 of all 721 files, so the existing
`PACKAGE.sha256`, `INDEX.json` and lock records still verify once restored.
The release's original checksum asset covers the first 720 files; use the
checked-in manifest for the additional amended-rank trace.

The rewrite changed every commit SHA from the first commit that added one of
these files. The release's `commit-map.txt` maps each old SHA to its new one, for
SHAs quoted in evidence and docs.

Restore, from the repository root:

```sh
gh release download gz-evidence-archive -R robertguss/mo-v2 -p '*.tar' -D /tmp/mo-gz
for t in /tmp/mo-gz/*.tar; do tar -xf "$t"; done
shasum -a 256 -c experiments/GZ_ARCHIVE.sha256
```

`.gitignore` excludes the restored files so they are not committed again. New
large evidence goes into a release asset with its checksum committed here.
