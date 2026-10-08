"""Package this revision's public validation only, preserving every attempt.

Usage: python3 package_revision.py EXTERNAL_VALIDATION_ROOT
Writes a new evidence directory and a prepared (not scientific) revision index.
"""
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tarfile

HERE = Path(__file__).resolve().parent


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main(source):
    destination = HERE / "evidence"
    destination.mkdir(exist_ok=False)
    # Exact public-work roots created by this repair. Never walk /home/user or
    # the corpus directory. Build products and dependency caches are excluded.
    roots = [source / name for name in ("NonTailSum", "DiscardedList", "validation-02", "validation-03",
                                        "controls-01", "controls-02")]
    paths = sorted(source.glob("*.log"))
    for root in roots:
        assert root.is_dir(), root
        paths.extend(path for path in root.rglob("*") if path.is_file() and not path.is_symlink()
                     and not any(part in ("target", "__pycache__") for part in path.relative_to(root).parts))
    inventory = []
    archive = destination / "public-validation.tar.gz"
    with tarfile.open(archive, "w:gz") as out:
        for path in sorted(paths):
            name = path.relative_to(source).as_posix()
            data = path.read_bytes()
            inventory.append(dict(path=name, bytes=len(data), sha256=digest(data)))
            out.add(path, arcname=name, recursive=False)
    with tarfile.open(archive, "r:gz") as check:
        members = check.getmembers()
        assert len(members) == len(inventory)
        for member, expected in zip(members, inventory):
            assert member.isfile() and member.name == expected["path"]
            data = check.extractfile(member).read()
            assert len(data) == expected["bytes"] and digest(data) == expected["sha256"]
    for src, dst in (("validation-03/validation.json", "validation.json"),
                     ("controls-02/scoring.json", "scoring.json")):
        shutil.copyfile(source / src, destination / dst)
    index = dict(archive=archive.name, bytes=archive.stat().st_size, sha256=digest(archive.read_bytes()),
                 source_root=str(source), files=inventory, private_data_included=False,
                 restore="mkdir restored && tar -xzf public-validation.tar.gz -C restored",
                 verify="Compare every restored path's size/SHA256 with files in this index.",
                 omitted="Only build/cache trees and three dependency symlinks in each control source tree.",
                 link_reconstruction="In controls-*/source/, link runtime, driver and cells to the corresponding revision-02 directories.",
                 readback_verified=True)
    (destination / "INDEX.json").write_text(json.dumps(index, indent=2) + "\n")
    files = {}
    for path in sorted(HERE.rglob("*")):
        if path.is_file() and path.name != "REVISION.json":
            assert not path.is_symlink() and "__pycache__" not in path.parts
            files[path.relative_to(HERE).as_posix()] = dict(bytes=path.stat().st_size, sha256=digest(path.read_bytes()))
    revision = dict(status="prepared-not-frozen", files=files,
                    original_stage_b_lock=digest((HERE.parent / "STAGE_B_LOCK.json").read_bytes()),
                    source_base="e5d30f81bd8b73fa2e11c73489f77a91963367f0",
                    original_files_modified=False, candidate_modified=False,
                    private_cases_executed=0, million_element_runs=0)
    (HERE / "REVISION.json").write_text(json.dumps(revision, indent=2) + "\n")
    print(json.dumps(dict(archive_bytes=index["bytes"], archived_files=len(inventory),
                         archive_sha256=index["sha256"], revision_files=len(files),
                         revision_sha256=digest((HERE / "REVISION.json").read_bytes())), indent=2))


if __name__ == "__main__":
    main(Path(sys.argv[1]).resolve())
