"""Lossless evidence packaging only. Never imports or executes acceptance code."""
import argparse
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import stat
import tarfile
import time

HERE = Path(__file__).resolve().parent
BASE = Path("experiments/13-source-acceptance")
RUNS = BASE / "candidate-runs"
STAGES = [f"stage-a-{n:02d}" for n in range(1, 9)] + ["stage-a-08-continuation"]
LIMIT = 20 * 1024 * 1024
RAW_TARGET = 128 * 1024 * 1024
LOCK_SHA = "09c64493ba65f94451dc17c5bde7c4b54554d6990b23b8c877f2f9741f120c9e"
SKIP_DIRS = {"target", "__pycache__"}


def digest(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def write_json(path, value):
    with path.open("x") as f:
        json.dump(value, f, indent=2)
        f.write("\n")


def safe_path(name):
    p = Path(name)
    assert not p.is_absolute() and ".." not in p.parts and str(p) == name, name
    return p


def allowed(name):
    p = safe_path(name)
    r = p.relative_to(RUNS)
    assert len(r.parts) > 1 and r.parts[0] in STAGES, name
    assert not (set(r.parts) & SKIP_DIRS), name
    return p


def scan(root):
    files, links, excluded = [], [], []
    for base, dirs, names in os.walk(root, followlinks=False):
        for name in list(dirs):
            p = Path(base) / name
            if p.is_symlink():
                links.append(p)
                dirs.remove(name)
            elif name in SKIP_DIRS:
                excluded.append(p)
                dirs.remove(name)
        for name in names:
            p = Path(base) / name
            if p.is_symlink():
                links.append(p)
            else:
                assert stat.S_ISREG(p.lstat().st_mode), p
                files.append(p)
    return sorted(files), sorted(links), sorted(excluded)


def frozen(root):
    lock = root / BASE / "STAGE_A_LOCK.json"
    assert digest(lock) == LOCK_SHA
    data = json.loads(lock.read_text())
    expected = {str(BASE / p): h for p, h in data["files"].items()}
    expected.update(data["historical_dependencies"])
    expected[str(BASE / "STAGE_A_LOCK.json")] = LOCK_SHA
    for p, h in expected.items():
        assert digest(root / p) == h, p
    return expected


def preserved_archives(root):
    paths = sorted(root.glob("rob1333-stage-a-candidate-final-*.tar.gz"))
    paths += sorted((root / ".amp/in/artifacts").glob("*.tar.gz"))
    return [{"path": str(p.relative_to(root)), "bytes": p.stat().st_size,
             "sha256": digest(p)} for p in paths]


def build(root):
    start = time.time()
    assert not (HERE / "INDEX.json").exists()
    (HERE / "volumes").mkdir()
    (HERE / "indexes").mkdir()
    locked = frozen(root)
    archives = preserved_archives(root)
    # Only names, inode identities, sizes and manifest fingerprint are inspected.
    # No private request, row, corpus or seed contents are read.
    private = Path("/home/user/rob-1333-candidate-runs/stage-a-08")
    private_files, private_links, _ = scan(private)
    assert not private_links
    private_inodes = {(p.stat().st_dev, p.stat().st_ino) for p in private_files}
    private_meta = {"regular_files": len(private_files),
                    "regular_file_bytes": sum(p.stat().st_size for p in private_files),
                    "manifest_sha256": digest(private / "EVIDENCE.sha256"),
                    "private_contents_or_seeds_read": False,
                    "archive_members_from_private_tree": 0,
                    "shared_inodes_with_included_files": 0}
    assert private_meta["manifest_sha256"] == "5baa77cee600f7bceebbce265ca1e414a5800b8135e1cd4d64e620e75a728a63"
    parts, roots, omitted, chunk = [], [], [], []
    raw_size = 0

    def save(rows):
        number = len(parts) + 1
        name = f"evidence-{number:04d}"
        archive = HERE / "volumes" / (name + ".tar.gz")
        with archive.open("xb") as raw:
            with gzip.GzipFile(fileobj=raw, filename="", mode="wb", mtime=0,
                               compresslevel=6) as zipped:
                with tarfile.open(fileobj=zipped, mode="w|", format=tarfile.PAX_FORMAT) as tar:
                    for row in rows:
                        p = root / allowed(row["path"])
                        assert not p.is_symlink()
                        data = p.read_bytes()
                        assert len(data) == row["bytes"]
                        assert hashlib.sha256(data).hexdigest() == row["sha256"], p
                        info = tarfile.TarInfo(row["path"])
                        info.size, info.mode = len(data), row["mode"]
                        info.mtime = row["mtime_ns"] // 1000000000
                        tar.addfile(info, io.BytesIO(data))
        if archive.stat().st_size >= LIMIT:
            assert len(rows) > 1, "A single file exceeds compressed-volume limit"
            archive.unlink()  # Only this new, unaccepted packaging attempt.
            mid = len(rows) // 2
            save(rows[:mid])
            save(rows[mid:])
            return
        index = HERE / "indexes" / (name + ".jsonl.gz")
        with index.open("xb") as raw:
            with gzip.GzipFile(fileobj=raw, filename="", mode="wb", mtime=0) as zipped:
                for row in rows:
                    zipped.write((json.dumps(row, separators=(",", ":")) + "\n").encode())
        assert index.stat().st_size < LIMIT
        item = {"archive": str(archive.relative_to(HERE)),
                "archive_bytes": archive.stat().st_size, "archive_sha256": digest(archive),
                "index": str(index.relative_to(HERE)), "index_bytes": index.stat().st_size,
                "index_sha256": digest(index), "regular_files": len(rows),
                "content_bytes": sum(r["bytes"] for r in rows)}
        parts.append(item)
        print(json.dumps(item), flush=True)

    for stage in STAGES:
        directory = root / RUNS / stage
        manifest = directory / "EVIDENCE.sha256"
        sealed = {}
        for line in manifest.read_text().splitlines():
            h, name = line.split("  ", 1)
            safe_path(name)
            assert name not in sealed
            sealed[name] = h
        manifest_sha = digest(manifest)
        sealed["EVIDENCE.sha256"] = manifest_sha
        files, links, skipped = scan(directory)
        assert {str(p.relative_to(directory)) for p in files} == set(sealed), stage
        assert not skipped, "Unexpected build/cache directory requires explicit inventory"
        for p in links:
            target = p.resolve(strict=True)
            target_name = str(target.relative_to(root))
            assert target_name in {str(BASE / x) for x in ("cells", "runtime", "driver")}
            original = os.readlink(p)
            assert not Path(original).is_absolute(), "Document relocation of absolute link first"
            target_files, target_links, target_skips = scan(target)
            assert not target_links
            target_hashes = {str(f.relative_to(root)): digest(f) for f in target_files}
            assert all(locked.get(n) == h for n, h in target_hashes.items()), p
            omitted.append({"path": str(p.relative_to(root)), "kind": "symlink",
                            "original_target": original, "frozen_target": target_name,
                            "frozen_target_files": target_hashes,
                            "unneeded_target_build_cache_directories":
                            [str(f.relative_to(root)) for f in target_skips]})
        roots.append({"path": str(directory.relative_to(root)), "regular_files": len(files),
                      "sealed_entries": len(sealed) - 1, "manifest_sha256": manifest_sha})
        for p in files:
            st = p.stat()
            assert (st.st_dev, st.st_ino) not in private_inodes, p
            name = str(p.relative_to(root))
            allowed(name)
            row = {"path": name, "bytes": st.st_size,
                   "sha256": sealed[str(p.relative_to(directory))],
                   "mode": stat.S_IMODE(st.st_mode), "mtime_ns": st.st_mtime_ns}
            size = 512 + ((st.st_size + 511) // 512) * 512
            if chunk and raw_size + size > RAW_TARGET:
                save(chunk)
                chunk, raw_size = [], 0
            chunk.append(row)
            raw_size += size
        print("SEALED ROOT", stage, len(files), flush=True)
    if chunk:
        save(chunk)
    assert sum(p["regular_files"] for p in parts) == 831636
    assert sum(p["content_bytes"] for p in parts) == 4946455087
    assert preserved_archives(root) == archives
    assert frozen(root) == locked
    write_json(HERE / "EXCLUSIONS.json", {
        "rule": "Only nine explicit non-private candidate-run roots; no symlinks followed.",
        "private": private_meta, "private_scope": "524 refusals, not private execution coverage",
        "symlinks": omitted, "omitted_build_cache_directories": [],
        "all_regular_files_in_source_roots_included": True,
        "aggregate_private_counts_in_existing_reports_retained": True})
    write_json(HERE / "INDEX.json", {
        "format": "ROB-1333 lossless non-private Stage A evidence package 1",
        "scope": "Packaging only; no candidate execution, result or criterion changes",
        "source_prefix": str(RUNS), "source_roots": roots,
        "scientific_lock_sha256": LOCK_SHA,
        "max_individual_compressed_bytes_exclusive": LIMIT,
        "volumes": parts, "regular_files": sum(p["regular_files"] for p in parts),
        "content_bytes": sum(p["content_bytes"] for p in parts),
        "archive_bytes": sum(p["archive_bytes"] for p in parts),
        "compressed_index_bytes": sum(p["index_bytes"] for p in parts),
        "preserved_small_archives_not_duplicated_in_volumes": archives,
        "build_elapsed_seconds": round(time.time() - start, 3)})


def verify(root=None, restore=None):
    start = time.time()
    index = json.loads((HERE / "INDEX.json").read_text())
    seen, hashes, manifests = set(), {}, {}
    count = size = 0
    for volume in index["volumes"]:
        archive = HERE / safe_path(volume["archive"])
        rows_path = HERE / safe_path(volume["index"])
        for p, key in ((archive, "archive"), (rows_path, "index")):
            assert p.stat().st_size == volume[key + "_bytes"] < LIMIT
            assert digest(p) == volume[key + "_sha256"], p
        with gzip.open(rows_path, "rt") as f:
            rows = [json.loads(line) for line in f]
        assert len(rows) == volume["regular_files"]
        volume_bytes = 0
        with tarfile.open(archive, "r|gz") as tar:
            for row in rows:
                member = tar.next()
                assert member is not None and member.isfile() and member.name == row["path"]
                rel = allowed(member.name)
                assert member.name not in seen
                seen.add(member.name)
                data = tar.extractfile(member).read()
                assert len(data) == member.size == row["bytes"]
                assert hashlib.sha256(data).hexdigest() == row["sha256"], member.name
                assert member.mode == row["mode"]
                hashes[member.name] = row["sha256"]
                if rel.name == "EVIDENCE.sha256" and rel.parent.parent == RUNS:
                    manifests[str(rel.parent)] = data.decode()
                if root is not None:
                    original = root / rel
                    assert not original.is_symlink() and original.is_file(), original
                    assert digest(original) == row["sha256"], original
                if restore is not None:
                    dest = restore / rel
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    assert dest.resolve().is_relative_to(restore.resolve()), dest
                    with dest.open("xb") as out:
                        out.write(data)
                    os.chmod(dest, row["mode"])
                    os.utime(dest, ns=(row["mtime_ns"], row["mtime_ns"]))
                    assert digest(dest) == row["sha256"], dest
                count += 1
                size += len(data)
                volume_bytes += len(data)
            assert tar.next() is None, "Extra archive member"
        assert volume_bytes == volume["content_bytes"]
        print("VERIFIED", volume["archive"], len(rows), flush=True)
    manifest_entries = 0
    assert set(manifests) == {str(RUNS / s) for s in STAGES}
    for entry in index["source_roots"]:
        name = entry["path"]
        expected = {name + "/EVIDENCE.sha256": entry["manifest_sha256"]}
        for line in manifests[name].splitlines():
            h, local = line.split("  ", 1)
            safe_path(local)
            full = name + "/" + local
            assert full not in expected
            expected[full] = h
            manifest_entries += 1
        actual = {n: h for n, h in hashes.items() if n.startswith(name + "/")}
        assert actual == expected and len(actual) == entry["regular_files"], name
        if root is not None:
            files, _, skipped = scan(root / name)
            assert not skipped
            assert {str(p.relative_to(root)) for p in files} == set(expected), name
    assert count == index["regular_files"] and size == index["content_bytes"]
    if root is not None:
        frozen(root)
        assert preserved_archives(root) == index["preserved_small_archives_not_duplicated_in_volumes"]
    report = {"passed": True, "volumes": len(index["volumes"]),
              "regular_files": count, "content_bytes": size,
              "sealed_entries_matched": manifest_entries, "sealed_manifests": len(manifests),
              "compared_with_originals": root is not None, "restored_and_rehashed": restore is not None,
              "elapsed_seconds": round(time.time() - start, 3)}
    print(json.dumps(report), flush=True)
    return report


def links(root):
    frozen(root)
    exclusions = json.loads((HERE / "EXCLUSIONS.json").read_text())
    for link in exclusions["symlinks"]:
        p = root / allowed(link["path"])
        for target, h in link["frozen_target_files"].items():
            assert digest(root / safe_path(target)) == h, target
        assert (p.parent / link["original_target"]).resolve() == (root / link["frozen_target"]).resolve()
        assert p.parent.is_dir() and not p.exists() and not p.is_symlink(), p
        p.symlink_to(link["original_target"], target_is_directory=True)
    print("RESTORED FROZEN LINKS", len(exclusions["symlinks"]))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["build", "verify", "restore", "restore-links"])
    parser.add_argument("--root", type=Path, help="Original/restored repository root")
    parser.add_argument("--destination", type=Path, help="New, nonexistent restore directory")
    parser.add_argument("--report", type=Path, help="New JSON report, never an existing result")
    args = parser.parse_args()
    if args.action == "build":
        assert args.root is not None
        build(args.root.resolve())
    elif args.action == "restore-links":
        assert args.root is not None
        links(args.root.resolve())
    else:
        destination = None
        if args.action == "restore":
            assert args.destination is not None and not args.destination.exists()
            destination = args.destination.resolve()
            destination.mkdir(parents=True)
        result = verify(args.root.resolve() if args.root else None, destination)
        if args.report:
            write_json(args.report, result)
