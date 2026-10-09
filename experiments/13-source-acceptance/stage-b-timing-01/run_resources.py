"""Frozen timing-01 selection; sum1800 then discard600 only after passing sum."""
import importlib.util
import json
from pathlib import Path
import shutil
import sys

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
spec = importlib.util.spec_from_file_location('timing_prior_ownership', BASE / 'stage-b-ownership-01/run_resources.py')
prior = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prior)
sys.path.insert(0, str(HERE))
from run_timed import run
from envelope import ENVELOPE_SECONDS

OLD_BINARY = Path('/home/user/rob1333-stage-b-collector-01/target/release/rob1333-stage-b-link')
sha = prior.sha


def verify(binary):
    previous = prior.verify(OLD_BINARY)
    lock = json.loads((HERE / 'LOCK.json').read_text())
    assert __debug__ and lock['status'] == 'frozen'
    assert previous['ownership_lock'] == lock['ownership_lock']
    assert lock['limits_seconds'] == ENVELOPE_SECONDS
    for name, record in lock['files'].items():
        path = HERE / name
        assert path.stat().st_size == record['bytes'] and sha(path) == record['sha256'], name
    assert sha(binary) == lock['binary_sha256'], 'instrumented binary fingerprint'
    return dict(timing_lock=sha(HERE / 'LOCK.json'), binary_sha256=sha(binary), prior=previous)


def main(destination, binary):
    before = verify(binary)
    cgroup = Path('/sys/fs/cgroup/amp.slice/amp-workload.slice')
    assert int((cgroup / 'memory.max').read_text()) == 45097156608, 'authorized 42-GiB workload cap'
    assert shutil.disk_usage(destination.parent).free >= 16 * 1024**3, 'retained evidence disk headroom'
    destination.mkdir(parents=True, exist_ok=False)
    shutil.copyfile(HERE / 'LOCK.json', destination / 'LOCK.json')
    report = dict(preservation_before=before, python=sys.version, runs=[],
                  disk_free_bytes=shutil.disk_usage(destination).free,
                  cgroup={name: (cgroup / name).read_text() for name in
                          ['memory.max', 'memory.current', 'memory.peak', 'memory.events', 'memory.stat', 'cpu.max']})
    (destination / 'preflight.json').write_text(json.dumps(report, indent=2) + '\n')
    for cls in (prior.orchestration.NonTailSum, prior.orchestration.DiscardedList):
        workload = cls(prior.orchestration.APPROVED_DEPTH)
        print(json.dumps(dict(starting=workload.name, depth=workload.depth,
                              limit_seconds=ENVELOPE_SECONDS[workload.name])), flush=True)
        result = run([str(binary)], workload, destination / workload.name,
                     verifier_type=prior.approved.LargeVerifier, decode=prior.approved.load)
        report['runs'].append(result)
        report['preservation_after'] = verify(binary)
        assert before == report['preservation_after']
        (destination / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(result), flush=True)
        if not result['passed']:
            raise SystemExit('Resource obligation did not pass; stopped with evidence preserved.')


if __name__ == '__main__':
    main(*(Path(arg).resolve() for arg in sys.argv[1:]))
