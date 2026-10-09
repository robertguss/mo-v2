"""Preserve public adaptation evidence; private raw evidence is never traversed.

Usage: python3 package_continuation.py NEW_PACKAGE_DIRECTORY
       python3 package_continuation.py --performance NEW_PACKAGE_DIRECTORY
       python3 package_continuation.py --resources NEW_PACKAGE_DIRECTORY
Only the named public roots and logs below are allowed. Every archived byte is
read back and compared with its source hash. Independent volumes must be under
20 MiB; a fresh destination is required, and originals are never changed.
"""
import hashlib
import io
import json
from pathlib import Path
import shutil
import tarfile
import sys

PUBLIC = Path("/home/user/rob1333-stage-b-adaptation-checks")
CLOSEOUT = Path("/home/user/rob1333-stage-b-closeout-01")
PERFORMANCE = Path("/home/user/rob1333-stage-b-performance-01")


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main(destination, *, performance=False, resources=False):
    destination.mkdir(parents=True, exist_ok=False)
    roots = [PUBLIC / "public-01", PUBLIC / "small-01",
             CLOSEOUT / "controls", CLOSEOUT / "controls-02",
             CLOSEOUT / "large-runner-validation", CLOSEOUT / "million"]
    paths = list(PUBLIC.glob("*.log"))
    paths += [CLOSEOUT / name for name in (
        "controls.log", "controls-02.log", "control-review.json", "million.log",
        "ci-build.log", "ci-candidate-test.log", "ci-driver-test.log")]
    allowed = [PUBLIC, CLOSEOUT]
    if performance:
        roots, paths, allowed = [PERFORMANCE], [], [PERFORMANCE]
    elif resources:
        roots, paths, allowed = [PERFORMANCE / "approved-01"], [], [PERFORMANCE]
    links = []
    for root in roots:
        assert root.is_dir(), root
        for path in root.rglob("*"):
            if any(part in ("target", "__pycache__") for part in path.relative_to(root).parts):
                continue
            if path.is_symlink():
                links.append(dict(source=str(path), target=str(path.resolve())))
            elif path.is_file():
                paths.append(path)
    paths = sorted(paths)
    assert len(paths) == len(set(paths))
    inventory, sources, volumes = [], [], []
    out = None
    uncompressed = 0
    try:
        for path in paths:
            assert path.is_file() and not path.is_symlink()
            assert any(path.is_relative_to(root) for root in allowed)
            assert "private" not in str(path)
            size = path.stat().st_size
            root = next(root for root in allowed if path.is_relative_to(root))
            name = root.name + "/" + path.relative_to(root).as_posix()
            sources.append(dict(path=name, source=str(path), bytes=size, sha256=sha(path)))
            # Bound input bytes even for already-compressed data. Large files
            # are rejoined by checked offset; small files share volumes.
            with path.open("rb") as source:
                for offset in range(0, max(size, 1), 16 * 1024 ** 2):
                    data = source.read(16 * 1024 ** 2)
                    if out is None or uncompressed + len(data) > 16 * 1024 ** 2:
                        if out is not None:
                            out.close()
                        archive = destination / f"public-{len(volumes):03d}.tar.gz"
                        volumes.append(archive)
                        out = tarfile.open(archive, "w:gz", compresslevel=6)
                        uncompressed = 0
                    member_name = name if size <= 16 * 1024 ** 2 else f"{name}.chunk-{offset:012d}"
                    record = dict(path=member_name, logical_path=name, source=str(path), offset=offset,
                                  bytes=len(data), sha256=hashlib.sha256(data).hexdigest(), volume=archive.name)
                    info = tarfile.TarInfo(member_name)
                    info.size = len(data)
                    info.mode = 0o644
                    out.addfile(info, io.BytesIO(data))
                    inventory.append(record)
                    uncompressed += len(data)
    finally:
        if out is not None:
            out.close()
    indexed = {entry["path"]: entry for entry in inventory}
    seen = set()
    volume_records = []
    for archive in volumes:
        assert archive.stat().st_size < 20 * 1024 ** 2, "volume too large; not deliverable"
        with tarfile.open(archive, "r:gz") as stream:
            for member in stream:
                assert member.isfile() and member.name not in seen
                expected = indexed[member.name]
                assert expected["volume"] == archive.name and expected["bytes"] == member.size
                data = stream.extractfile(member)
                assert hashlib.file_digest(data, "sha256").hexdigest() == expected["sha256"]
                seen.add(member.name)
        volume_records.append(dict(path=archive.name, bytes=archive.stat().st_size, sha256=sha(archive)))
    assert seen == set(indexed)
    assert all(sha(Path(item["source"])) == item["sha256"] for item in sources), "original changed"
    index = dict(public_roots=[str(root) for root in roots], files=inventory, sources=sources, volumes=volume_records,
                 omitted_dependency_links=links, build_cache_omitted=True, private_raw_included=False,
                 readback_verified=True, original_files_preserved=True)
    (destination / "INDEX.json").write_text(json.dumps(index, indent=2) + "\n")
    print(json.dumps(dict(files=len(inventory), volumes=len(volumes),
                          compressed_bytes=sum(item["bytes"] for item in volume_records),
                          index_sha256=sha(destination / "INDEX.json")), indent=2))


def restore(package, destination):
    destination.mkdir(parents=True, exist_ok=False)
    index = json.loads((package / "INDEX.json").read_text())
    entries = {entry["path"]: entry for entry in index["files"]}
    for volume in index["volumes"]:
        archive = package / volume["path"]
        assert sha(archive) == volume["sha256"]
        with tarfile.open(archive, "r:gz") as stream:
            for member in stream:
                entry = entries[member.name]
                target = destination / entry["logical_path"]
                assert target.resolve().is_relative_to(destination)
                target.parent.mkdir(parents=True, exist_ok=True)
                offset = entry["offset"]
                assert offset == 0 or target.stat().st_size == offset
                with target.open("xb" if offset == 0 else "ab") as output:
                    shutil.copyfileobj(stream.extractfile(member), output)
    for source in index["sources"]:
        target = destination / source["path"]
        assert target.stat().st_size == source["bytes"] and sha(target) == source["sha256"]
    print(f"Restored and content-verified {len(index['sources'])} original public files; links remain omitted")


if __name__ == "__main__":
    if sys.argv[1] == "--restore":
        restore(Path(sys.argv[2]).resolve(), Path(sys.argv[3]).resolve())
    elif sys.argv[1] == "--performance":
        main(Path(sys.argv[2]).resolve(), performance=True)
    elif sys.argv[1] == "--resources":
        main(Path(sys.argv[2]).resolve(), resources=True)
    else:
        main(Path(sys.argv[1]).resolve())
