"""Execute the approved collector freeze with the unchanged resource checker.

Usage: python3.14 run_resources.py NEW_EXTERNAL_DIRECTORY VERIFIED_COLLECTOR_BINARY
"""
import importlib.util
import json
from pathlib import Path
import shutil
import sys

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
sys.path.insert(0, str(BASE / 'stage-b-performance-01'))
spec = importlib.util.spec_from_file_location('previous_performance_runner', BASE / 'stage-b-performance-01/run_resources.py')
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)


def verify(binary):
    lock = json.loads((HERE / 'LOCK.json').read_text())
    assert lock['status'] == 'frozen' and __debug__
    prior = previous.verify(Path(lock['baseline_binary']))
    assert prior['performance_lock'] == lock['performance_lock']
    for name, record in lock['files'].items():
        path = BASE / name
        assert path.stat().st_size == record['bytes'] and previous.sha(path) == record['sha256'], name
    assert previous.sha(binary) == lock['binary_sha256'], 'collector binary fingerprint'
    return dict(collector_lock=previous.sha(HERE / 'LOCK.json'), binary_sha256=previous.sha(binary), prior=prior)


def main(destination, binary):
    before = verify(binary)
    assert shutil.disk_usage(destination.parent).free >= 4 * 1024**3, 'evidence disk headroom'
    destination.mkdir(parents=True, exist_ok=False)
    shutil.copyfile(HERE / 'LOCK.json', destination / 'LOCK.json')
    cgroup = Path('/sys/fs/cgroup/amp.slice/amp-workload.slice')
    report = dict(preservation_before=before, python=sys.version, runs=[],
                  disk_free_bytes=shutil.disk_usage(destination).free,
                  cgroup={name: (cgroup / name).read_text() for name in ['memory.max', 'memory.current', 'memory.stat', 'memory.events']})
    (destination / 'preflight.json').write_text(json.dumps(report, indent=2) + '\n')
    for cls in (previous.orchestration.NonTailSum, previous.orchestration.DiscardedList):
        workload = cls(previous.orchestration.APPROVED_DEPTH)
        print(json.dumps(dict(starting=workload.name, depth=workload.depth,
                              limit_seconds=previous.orchestration.ENVELOPE_SECONDS[workload.name])), flush=True)
        result = previous.orchestration.run([str(binary)], workload, destination / workload.name,
                                            verifier_type=previous.approved.LargeVerifier, decode=previous.approved.load)
        report['runs'].append(result)
        report['preservation_after'] = verify(binary)
        assert report['preservation_before'] == report['preservation_after']
        (destination / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(result), flush=True)
        if not result['passed']:
            raise SystemExit('Resource obligation did not pass; stopped with evidence preserved.')


if __name__ == '__main__':
    main(*(Path(argument).resolve() for argument in sys.argv[1:]))
