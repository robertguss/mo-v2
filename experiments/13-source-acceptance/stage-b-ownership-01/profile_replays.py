"""Measure/check old and proposed verifiers on existing public native streams.

Usage: python3.14 profile_replays.py RESTORED_COLLECTOR_ROOT NEW_OUTPUT_DIRECTORY
No candidate process or private data. Profile data is diagnostic, never a timed
resource verdict. The old verifier is the approved performance freeze.
"""
import cProfile
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import pstats
import sys
import time

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
sys.path.insert(0, str(BASE / 'stage-b-performance-01'))
spec = importlib.util.spec_from_file_location('collector_freeze', BASE / 'stage-b-collector-01/run_resources.py')
freeze = importlib.util.module_from_spec(spec)
spec.loader.exec_module(freeze)
old = freeze.previous.approved
sys.path.insert(0, str(HERE))
spec = importlib.util.spec_from_file_location('ownership_proposal', HERE / 'stage_b_large.py')
new = importlib.util.module_from_spec(spec)
spec.loader.exec_module(new)


def replay(folder, module, workload, budgets, profile=None):
    verifier = module.LargeVerifier(workload, budgets)
    digest = hashlib.sha256()
    replies = hashlib.sha256()
    count = 0
    start = time.monotonic()
    if profile is not None:
        profile.enable()
    with gzip.open(folder / 'rows.jsonl.gz', 'rb') as stream:
        for line in stream:
            digest.update(line)
            response = verifier.row(module.load(line))
            replies.update(json.dumps(response, sort_keys=True).encode() + b'\n')
            count += 1
    result = verifier.finish()
    if profile is not None:
        profile.disable()
    elapsed = time.monotonic() - start
    summary = json.loads((folder / 'summary.json').read_text())
    assert summary['candidate_executed'] and not summary['fixture_stub']
    assert all(result[k] == summary[k] for k in result)
    assert summary['streamed_rows_sha256'] == digest.hexdigest()
    return dict(seconds=elapsed, rows=count, stream_sha256=digest.hexdigest(),
                replies_sha256=replies.hexdigest(), result=result)


def main(root, destination):
    destination.mkdir(parents=True, exist_ok=False)
    binary = Path('/home/user/rob1333-stage-b-collector-01/target/release/rob1333-stage-b-link')
    report = dict(preservation_before=freeze.verify(binary), candidate_executed=False,
                  private_access=False, runs=[], source_hashes={
                      p.name: freeze.previous.sha(p) for p in HERE.glob('*.py')})
    # Separate cProfile run: locate cost, not an uninstrumented timing comparison.
    folder = root / 'profiles-01/sum-40003'
    workload = freeze.previous.orchestration.NonTailSum(40003)
    budgets = [workload.deepest_step(), workload.transitions() - workload.deepest_step()]
    profile = cProfile.Profile()
    report['profiled_baseline'] = replay(folder, old, workload, budgets, profile)
    profile.dump_stats(str(destination / 'baseline.prof'))
    with (destination / 'baseline-profile.txt').open('w') as out:
        pstats.Stats(profile, stream=out).sort_stats('cumulative').print_stats(35)
        pstats.Stats(profile, stream=out).sort_stats('tottime').print_stats(20)
    (destination / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print('Profiled frozen 40,003-element replay', flush=True)
    for depth in (10003, 20003, 40003):
        folder = root / f'profiles-01/sum-{depth}'
        workload = freeze.previous.orchestration.NonTailSum(depth)
        budgets = [workload.deepest_step(), workload.transitions() - workload.deepest_step()]
        pair = {name: replay(folder, module, workload, budgets)
                for name, module in (('old', old), ('proposal', new))}
        assert {k: v for k, v in pair['old'].items() if k != 'seconds'} == {
            k: v for k, v in pair['proposal'].items() if k != 'seconds'}
        report['runs'].append(dict(depth=depth, **pair))
        report['preservation_after'] = freeze.verify(binary)
        assert report['preservation_before'] == report['preservation_after']
        (destination / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(dict(depth=depth, old_seconds=pair['old']['seconds'],
                              proposal_seconds=pair['proposal']['seconds'], matched=True)), flush=True)


if __name__ == '__main__':
    main(*(Path(arg).resolve() for arg in sys.argv[1:]))
