"""Compare proposed and frozen verdicts on retained PUBLIC native observations.

No process execution and no private corpus access. Synthetic corruptions test
checker equivalence; they are not compiled evaluator controls or acceptance.
Usage: python3 check_replays.py PUBLIC_ADAPTATION_ROOT NEW_REPORT_JSON
"""
from copy import deepcopy
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import time

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
sys.path[:0] = [str(BASE / 'stage-b-revision-02'), str(BASE), str(BASE / 'stage-b-adaptation-01')]
import stage_b_large as frozen
from check_revision import budgets_through, relabel
from stage_b_workloads import NonTailSum, DiscardedList
from validate_public import frozen as preservation

spec = importlib.util.spec_from_file_location('proposed_large', HERE / 'stage_b_large.py')
proposal = importlib.util.module_from_spec(spec)
spec.loader.exec_module(proposal)


def verdict(module, rows, workload, budgets):
    verifier = module.LargeVerifier(workload, budgets)
    index = -1
    try:
        for index, row in enumerate(rows):
            verifier.row(row)
        return dict(passed=True, result=verifier.finish())
    except Exception as error:
        return dict(passed=False, row=index, error=type(error).__name__, message=str(error))


def check_stream(path, workload, budgets):
    old = frozen.LargeVerifier(workload, budgets)
    new = proposal.LargeVerifier(workload, budgets)
    digest = hashlib.sha256()
    rows = 0
    with gzip.open(path, 'rb') as stream:
        for line in stream:
            digest.update(line)
            frozen.exact(old.row(frozen.load(line)), new.row(proposal.load(line)), 'reply differs')
            rows += 1
    result = old.finish()
    frozen.exact(result, new.finish(), 'completed verdict differs')
    return dict(rows=rows, commits=result['committed_steps'], stream_sha256=digest.hexdigest())


def main(root, output):
    assert not output.exists()
    start = time.monotonic()
    report = dict(passed=False, preservation_before=preservation(), native_streams=[], rejections={})
    for folder in sorted((root / 'small-01').iterdir()):
        if not folder.is_dir() or not folder.name.startswith(('NonTailSum-', 'DiscardedList-')):
            continue
        name, depth, cut = folder.name.split('-')
        workload = dict(NonTailSum=NonTailSum, DiscardedList=DiscardedList)[name](int(depth))
        summary = json.loads((folder / 'summary.json').read_text())
        assert summary['passed'] and summary['candidate_executed'] and not summary['fixture_stub']
        assert summary['committed_steps'] == int(cut)
        result = check_stream(folder / 'rows.jsonl.gz', workload, budgets_through(workload, int(cut)))
        report['native_streams'].append(dict(path=str(folder), **result))
    for cls, depth in ((NonTailSum, 2003), (DiscardedList, 10003)):
        for finish in (False, True):
            folder = root / 'public-01' / f'summary-{cls.__name__}-{finish}'
            summary = json.loads((folder / 'summary.json').read_text())
            assert summary['passed'] and summary['candidate_executed'] and not summary['fixture_stub']
            request = json.loads(folder.with_suffix('.request.json').read_text())
            result = check_stream(folder / 'rows.jsonl.gz', cls(depth), request['budgets'])
            report['native_streams'].append(dict(path=str(folder), **result))
    print(f"Matched {len(report['native_streams'])} retained native streams", flush=True)

    workload = NonTailSum(3)
    budgets = budgets_through(workload, workload.transitions())
    with gzip.open(root / 'small-01/NonTailSum-3-68/rows.jsonl.gz', 'rt') as stream:
        rows = [json.loads(line) for line in stream]
    baseline = verdict(frozen, rows, workload, budgets)
    assert baseline['passed'] and verdict(proposal, rows, workload, budgets) == baseline
    renamed = relabel(rows)
    assert verdict(frozen, renamed, workload, budgets) == verdict(proposal, renamed, workload, budgets) == baseline
    report['opaque_identity_replay'] = True
    # The five existing revision-02 corruptions, plus type/JSON-boundary probes
    # specific to the implementation fast paths. No candidate cases are added.
    probes = [
        (5, 'metadata', 'missing-enter-birth', lambda value: value['births_added'].pop()),
        (9, 'metadata', 'wrong-branch-owner', lambda value: value['births_added'][0].update(invocation=0)),
        (17, 'metadata', 'wrong-call-parent', lambda value: value['events_added'][0].__setitem__(2, 0)),
        (49, 'metadata', 'wrong-return-value', lambda value: value['events_added'][0].__setitem__(2, ['n', '99'])),
        (workload.deepest_step(), 'snapshot', 'rewritten-prefix', lambda value: value['events'][0].__setitem__(3, 'wrong')),
    ]
    for step, key, name, mutate in probes:
        bad = deepcopy(rows)
        target = next(row for row in bad if row.get('step') == step and row.get('raw', {}).get(key))
        value = json.loads(target['raw'][key])
        mutate(value)
        target['raw'][key] = json.dumps(value)
        report['rejections'][name] = compare_rejection(bad, workload, budgets)
    for name, value in (('cursor-boolean', False), ('cursor-float', 0.0), ('cursor-negative-zero', -0.0)):
        bad = deepcopy(rows)
        next(row for row in bad if 'from' in row)['from'][0] = value
        report['rejections'][name] = compare_rejection(bad, workload, budgets)
    for name, raw in (('duplicate-metadata', '{"step":1,"step":1}'), ('non-json-number', '{"step":NaN}')):
        bad = deepcopy(rows)
        next(row for row in bad if row.get('phase') == 'commit')['raw']['metadata'] = raw
        report['rejections'][name] = compare_rejection(bad, workload, budgets)
    workload = DiscardedList(10003)
    folder = root / 'public-01/summary-DiscardedList-True'
    budgets = json.loads(folder.with_suffix('.request.json').read_text())['budgets']
    with gzip.open(folder / 'rows.jsonl.gz', 'rt') as stream:
        rows = [json.loads(line) for line in stream]
    for field, wrong in (('depth', 1), ('live_cells', 0), ('cleanup_chain_length', 0),
                         ('changed_cells', []), ('counts', dict(create=1, write=0, free=5000))):
        bad = deepcopy(rows)
        target = next(row for row in bad if row.get('phase') == 'commit' and row['step'] == 10000)
        snapshot = json.loads(target['raw']['snapshot'])
        snapshot[field] = wrong
        target['raw']['snapshot'] = json.dumps(snapshot)
        report['rejections']['summary-' + field] = compare_rejection(bad, workload, budgets)
    report.update(passed=True, preservation_after=preservation(), elapsed_seconds=time.monotonic()-start,
                  helper_sha256=hashlib.sha256((HERE / 'fast_json.py').read_bytes()).hexdigest(),
                  verifier_sha256=hashlib.sha256((HERE / 'stage_b_large.py').read_bytes()).hexdigest())
    assert report['preservation_before'] == report['preservation_after']
    output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(dict(passed=True, streams=len(report['native_streams']),
                          matched_rejections=len(report['rejections']), seconds=report['elapsed_seconds'])))


def compare_rejection(rows, workload, budgets):
    old = verdict(frozen, rows, workload, budgets)
    new = verdict(proposal, rows, workload, budgets)
    assert not old['passed'] and new == old, (old, new)
    return old


if __name__ == '__main__':
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
