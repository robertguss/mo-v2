# Lossless Stage A evidence package 01

This is storage packaging, not new acceptance evidence or a scientific change.
The originals remain in `experiments/13-source-acceptance/candidate-runs/`.
All regular files from `stage-a-01` through `stage-a-08`, plus
`stage-a-08-continuation`, are included unchanged: attempts, failed runs,
requests, outputs, commands, scripts, candidate and control sources, manifests,
and reports. No candidate, control, checker or predicate replay runs during
packaging or verification. The package is not a builder delivery.

## Inventory and fingerprints

- `INDEX.json` lists every volume and compressed index, its exact byte size and
  SHA256, the source roots, sealed-manifest fingerprints and total counts.
- `volumes/evidence-NNNN.tar.gz` are independent tar/gzip archives, not pieces of
  a split stream. Every volume is strictly below 20 MiB (20,971,520 bytes).
- `indexes/evidence-NNNN.jsonl.gz` gives one record for each matching volume
  member: original repository-relative path, exact content bytes, SHA256,
  permission mode and original nanosecond modification time. The indexes are
  separately compressed to keep them below the same size limit.
- `PACKAGE.sha256` fingerprints the package files other than itself.
- `restore-verification.json` and its log record the actual full restoration,
  archived-content comparison to originals, and sealed-manifest reconciliation.

Tar headers retain file permissions and whole-second modification times;
`package.py restore` restores the recorded nanosecond times. File contents are
lossless. Ownership, access times and directory timestamps are not claimed as
filesystem-backup metadata. No regular file is deduplicated or rewritten.
Historical paths inside saved commands remain exactly as recorded; restoration
does not make old absolute binary paths executable or portable.

The original nine `EVIDENCE.sha256` files are included verbatim. Each lists its
own root's content files, excluding itself; `INDEX.json` records those nine
manifest fingerprints. Nested candidate provenance manifests are also retained
verbatim, including those in deliberately modified control copies. They are not
rewritten to describe the controls as unchanged candidate submissions.

## Exclusions and separate small archives

`EXCLUSIONS.json` records all omitted symlinks, their original relative link text,
their frozen repository targets and the targets' locked content fingerprints.
No symlink is followed into an archive. Build/cache directories may be omitted;
none were present inside the nine source roots when packaged. Frozen targets
are already versioned and are not redundantly copied into these volumes.

Private cases, corpus, seeds and the 524 private-refusal runs stay outside this
package and the public repository. The source allowlist contains only the nine
non-private roots. Their regular-file inventory is checked exactly against the
sealed manifests; private-evidence inode identities are checked for overlap
without reading private requests or rows. Zero private-tree members or shared
inodes are included. Existing aggregate private counts and custody statements
inside public reports remain unchanged; those are not private raw evidence and
do not establish private execution coverage.

Small exact candidate and public delivery archives stay at their original
locations, byte-identical. `INDEX.json` records their preservation fingerprints
(and the other pre-existing small review archives); these volumes do not
duplicate them. The separately supplied parent-review archive is not expanded
into the sealed trees or included as original acceptance-author evidence;
`parent-review-archive.json` records its verified receipt fingerprint.

## Verify and restore without executing any candidate

Use Python 3.11 or newer, without `-O`. Start at the repository root and set an
absolute package path. Nothing below imports acceptance code.

```sh
REPO="$PWD"
PKG="$REPO/experiments/13-source-acceptance/evidence/stage-a-durable-01"
(cd "$PKG" && sha256sum -c PACKAGE.sha256)
python3 -B "$PKG/package.py" verify
```

`verify` hashes each volume/index, checks exact ordered member inventory, hashes
every decompressed member, rejects duplicate/extra/unsafe paths and compares the
complete contents with all nine archived sealed manifests. It needs no original
tree, frozen host, binary or private data. To additionally rehash the original
acceptance workspace, verify its unchanged frozen files, and check the original
small archives at their recorded locations:

```sh
python3 -B "$PKG/package.py" verify --root "$REPO"
```

Restore into a **new, nonexistent** destination. Existing files are never
overwritten. Allow at least 12 GiB of file data/metadata space and 1.2 million
free inodes, with a filesystem that supports the original approximately 65,000
immediate subdirectories in `stage-a-08` (as this orb's filesystem does).
Extraction is followed by a fresh hash of every written file. If interrupted,
keep the partial destination separately and choose another new destination.

```sh
RESTORE=/tmp/rob1333-stage-a-restored
python3 -B "$PKG/package.py" restore --destination "$RESTORE"
```

Individual volumes can also be inspected or extracted independently. The
Python restore command is preferred because it validates the complete inventory
and does not overwrite files:

```sh
tar -tzf "$PKG/volumes/evidence-0001.tar.gz"
```

Optional link reconstruction requires the unchanged frozen source tree in the
restored repository root. The reviewed documentation commit already contains
it: [reviewed v17 source](https://github.com/robertguss/mo-v2/commit/5ded95ff12c737a1c6d85409ed99534f05100b70).
After restoring the evidence as above, populate that tracked snapshot and
reconstruct exactly the recorded links:

```sh
git -C "$REPO" archive 5ded95ff12c737a1c6d85409ed99534f05100b70 |
  tar -x -C "$RESTORE"
python3 -B "$PKG/package.py" restore-links --root "$RESTORE"
```

`restore-links` verifies the scientific lock, all frozen files and dependencies,
and every target fingerprint before creating links. It refuses existing links
or destinations. No build or execution is required.

## Packaging commands and scope

The original packing command was:

```sh
python3 -B experiments/13-source-acceptance/evidence/stage-a-durable-01/package.py \
  build --root /home/user/workspace/repo
```

`build.log` retains its output. Building is a one-time operation in a new package
directory and requires the original workspace and private custody metadata for
the exclusion check; use `verify` or `restore` on a delivered package instead.

The full storage-validation command, with output retained in
`restore-verification.log`, was:

```sh
python3 -B experiments/13-source-acceptance/evidence/stage-a-durable-01/package.py \
  restore --root /home/user/workspace/repo \
  --destination /tmp/rob1333-stage-a-durable-01-restore \
  --report experiments/13-source-acceptance/evidence/stage-a-durable-01/restore-verification.json
```

The optional frozen-snapshot/link reconstruction commands above are also tested
on that disposable restoration, with output in `restore-links.log`. The
disposable restored copy is removed afterward; originals and package stay.

This directory is disjoint from the parent's `candidate/`, `stage-a-link/` and
`stage-a-delivery/` integration paths. Parent review/delivery approval remains
required. No commit, push, merge, deployment, Stage B or resource workload is
authorized by this package.
