"""Run the owner-approved performance freeze with unchanged resource obligations.

Usage: python3.14 run_resources.py NEW_EXTERNAL_DIRECTORY VERIFIED_RELEASE_BINARY
The two reviewed helper/verifier files remain byte-identical to the proposal.
Selection is explicit; no frozen module globals or criteria are replaced.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import shutil
import sys

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
sys.path[:0] = [str(BASE / 'stage-b-adaptation-01'), str(BASE / 'stage-b-revision-02'), str(BASE)]
import run_approved_large as orchestration
from validate_public import frozen

spec = importlib.util.spec_from_file_location('performance_verifier', HERE / 'stage_b_large.py')
approved = importlib.util.module_from_spec(spec)
spec.loader.exec_module(approved)


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verify(binary):
    lock = json.loads((HERE / 'LOCK.json').read_text())
    assert lock['status'] == 'frozen' and __debug__
    assert platform.python_implementation() == 'CPython' and platform.python_version() == lock['python_version']
    assert not sys._jit.is_enabled(), 'unreviewed JIT mode'
    assert sha(Path(sys.executable)) == lock['python_executable_sha256']
    for name, record in lock['files'].items():
        path = BASE / name
        assert path.stat().st_size == record['bytes'] and sha(path) == record['sha256'], name
    assert sha(binary) == lock['binary_sha256'], 'release binary fingerprint'
    return dict(performance_lock=sha(HERE / 'LOCK.json'), binary_sha256=sha(binary), **frozen())


def main(destination, binary):
    before = verify(binary)
    destination.mkdir(parents=True, exist_ok=False)
    shutil.copyfile(HERE / 'LOCK.json', destination / 'LOCK.json')
    report = dict(preservation_before=before, python=sys.version, runs=[])
    (destination / 'preflight.json').write_text(json.dumps(report, indent=2) + '\n')
    for cls in (orchestration.NonTailSum, orchestration.DiscardedList):
        workload = cls(orchestration.APPROVED_DEPTH)
        print(json.dumps(dict(starting=workload.name, depth=workload.depth,
                              limit_seconds=orchestration.ENVELOPE_SECONDS[workload.name])), flush=True)
        result = orchestration.run([str(binary)], workload, destination / workload.name,
                                   verifier_type=approved.LargeVerifier, decode=approved.load)
        report['runs'].append(result)
        report['preservation_after'] = verify(binary)
        assert report['preservation_before'] == report['preservation_after']
        (destination / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(result), flush=True)
        if not result['passed']:
            raise SystemExit('Resource obligation did not pass; stopped with evidence preserved.')


if __name__ == '__main__':
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
