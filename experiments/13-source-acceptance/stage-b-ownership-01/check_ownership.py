"""Differential public-state and retained-stream checks; no candidate execution.

Usage: python3.14 check_ownership.py RESTORED_COLLECTOR_ROOT NEW_OUTPUT_DIRECTORY
Synthetic predicate probes are not compiled evaluator controls or acceptance.
"""
from collections import Counter
from copy import deepcopy
import gzip
import hashlib
import inspect
import json
from pathlib import Path
import random
import sys
import time

from profile_replays import HERE, freeze, old, new


def outcome(function, state):
    before = deepcopy(state)
    try:
        function(state)
        result = 'accepted'
    except Exception as error:
        result = type(error).__name__ + ': ' + str(error)
    assert state == before, 'predicate mutated input'
    return result


def check(state, expected, report):
    original = outcome(old.state_ownership, state)
    proposed = outcome(new.state_ownership, state)
    assert original == proposed == expected, (state, expected, original, proposed)
    report['outcomes'][original] += 1


def valid_state(rng):
    # DAG tails point to later live cells. Every head is independently rooted;
    # extra roots and shared tails exercise nontrivial holder counts.
    ids = rng.sample(range(10, 10000), rng.randrange(2, 12))
    ids[0] += 2**128
    aside = {ids[0]}
    aside.update(i for i in ids[2:] if rng.randrange(2))
    live = [i for i in ids if i not in aside]
    tails = {i: rng.choice([None] + live[n+1:]) for n, i in enumerate(live)}
    counts = Counter(t for t in tails.values() if t is not None)
    roots = [i for i in live if counts[i] == 0] + rng.choices(live, k=3)
    outside, pending, bindings = [], [], []
    for n, root in enumerate(roots):
        counts[root] += 1
        if n % 3 == 0:
            outside.append(root)
        elif n % 3 == 1:
            pending.append(['l', root])
        else:
            bindings.append([n, f'v{n}', ['l', root], 'holding'])
    memory = [[i, str(-i), None, 0, 'aside'] if i in aside else
              [i, str(i), tails[i], counts[i], 'live'] for i in ids]
    reservations = [[n+7, i] for n, i in enumerate(ids) if i in aside]
    rng.shuffle(memory)
    rng.shuffle(reservations)
    return dict(memory=memory, outside=outside, pending=pending, bindings=bindings,
                aside=reservations, kind=None)


def main(root, destination):
    destination.mkdir(parents=True, exist_ok=False)
    binary = Path('/home/user/rob1333-stage-b-collector-01/target/release/rob1333-stage-b-link')
    report = dict(preservation_before=freeze.verify(binary), outcomes=Counter(),
                  candidate_executed=False, private_access=False, native_streams=[],
                  native_full_states=0, predicate_timings=[], source_hashes={
                      p.name: freeze.previous.sha(p) for p in HERE.glob('*.py')})
    # This is also a source-drift check: one insertion, not a rewritten predicate.
    assert inspect.getsource(new.state_ownership).replace('    reserved = set(reserved)\n', '', 1) == inspect.getsource(old.state_ownership)
    rng = random.Random(133301)  # Public synthetic-test seed, not private corpus.
    fixtures = []
    for _ in range(250):
        state = valid_state(rng)
        cases = [('valid', state, 'accepted')]
        def bad(name, message, mutate):
            copy = deepcopy(state)
            mutate(copy)
            cases.append((name, copy, 'AssertionError: ' + message))
        bad('duplicate-cell', 'duplicate identity', lambda s: s['memory'].append(deepcopy(s['memory'][0])))
        bad('dangling-root', 'holder/link dangling', lambda s: s['outside'].append(2**160))
        bad('duplicate-reservation', 'duplicate reservation', lambda s: s['aside'].append(deepcopy(s['aside'][0])))
        bad('holder-count', 'holder count mismatch', lambda s: s['memory'][0].__setitem__(3, s['memory'][0][3]+1))
        bad('missing-reservation', 'invalid reservation', lambda s: s['aside'].pop())
        bad('reserved-tail', 'invalid reservation', lambda s: next(c for c in s['memory'] if c[4]=='aside').__setitem__(2, s['memory'][0][0]))
        bad('reserved-live', 'invalid live status', lambda s: next(c for c in s['memory'] if c[4]=='aside').__setitem__(4, 'live'))
        bad('dangling-reservation', 'reservation dangling', lambda s: s['aside'].append([99, 2**160]))
        # Duplicate rejection must precede any accidental set-based deduplication.
        duplicate = deepcopy(state)
        duplicate['aside'].append(deepcopy(duplicate['aside'][0]))
        deduplicated = deepcopy(duplicate)
        deduplicated['aside'] = list({a: [b, a] for b, a in duplicate['aside']}.values())
        assert outcome(new.state_ownership, deduplicated) == 'accepted'
        for name, sample, expected in cases:
            check(sample, expected, report)
            fixtures.append(dict(name=name, state=sample, expected=expected))
    empty = dict(memory=[], outside=[], pending=[], bindings=[], aside=[], kind=None)
    check(empty, 'accepted', report)
    unowned = dict(empty, memory=[[17, '4', None, 0, 'live']])
    check(unowned, 'AssertionError: unowned cell outside pending free', report)
    check(dict(unowned, kind='holderGivenUp'), 'accepted', report)
    cycle = dict(empty, memory=[[17, '1', 29, 2, 'live'], [29, '-3', 17, 1, 'live']], outside=[17])
    check(cycle, 'AssertionError: dangling/cycle', report)
    with gzip.open(destination / 'synthetic-states.json.gz', 'wt') as output:
        json.dump(fixtures, output, separators=(',', ':'))
    report['synthetic_fixture_sha256'] = freeze.previous.sha(destination / 'synthetic-states.json.gz')
    # Replay every row and reply, including zero-work/resume/destruction, in the
    # four existing real evaluator summary streams. No fixture-stub results.
    for cls, depth in ((freeze.previous.orchestration.NonTailSum, 2003),
                       (freeze.previous.orchestration.DiscardedList, 10003)):
        for finish in (False, True):
            folder = root / 'public-01' / f'summary-{cls.__name__}-{finish}'
            request = json.loads(folder.with_suffix('.request.json').read_text())
            summary = json.loads((folder / 'summary.json').read_text())
            assert summary['passed'] and summary['candidate_executed'] and not summary['fixture_stub']
            verifiers = [m.LargeVerifier(cls(depth), request['budgets']) for m in (old, new)]
            digest = hashlib.sha256()
            rows = 0
            with gzip.open(folder / 'rows.jsonl.gz', 'rb') as stream:
                for line in stream:
                    digest.update(line)
                    row = old.load(line)
                    assert verifiers[0].row(row) == verifiers[1].row(new.load(line))
                    rows += 1
                    if row.get('raw', {}).get('snapshot'):
                        snapshot = old.load(row['raw']['snapshot'])
                        if 'state' in snapshot and row.get('graph') is not None:
                            state = dict(snapshot['state'], memory=[c[:-1] for c in row['graph']], outside=row['outside'])
                            check(state, 'accepted', report)
                            report['native_full_states'] += 1
            a, b = (v.finish() for v in verifiers)
            assert a == b and all(a[k] == summary[k] for k in a)
            report['native_streams'].append(dict(source=str(folder), rows=rows,
                stream_sha256=digest.hexdigest(), result=a))
    # Isolate the suspect predicate on already-retained deepest states. Timings
    # exclude reading/decoding; three samples per implementation, alternating.
    for depth in (10003, 20003, 40003):
        folder = root / f'profiles-01/sum-{depth}'
        with gzip.open(folder / 'rows.jsonl.gz', 'rb') as stream:
            for line in stream:
                row = old.load(line)
                if row.get('phase') == 'advance' and row['step'] == 12*depth+5:
                    break
            else:
                raise AssertionError('deepest native observation absent')
        snapshot = old.load(row['raw']['snapshot'])
        state = dict(snapshot['state'], memory=[c[:-1] for c in row['graph']], outside=row['outside'])
        assert len(state['aside']) == len(state['memory']) == depth
        assert not state['outside'] and not state['pending']
        assert all(b[3] != 'holding' for b in state['bindings'])
        timings = {'old': [], 'proposal': []}
        for _ in range(3):
            for name, module in (('old', old), ('proposal', new)):
                start = time.perf_counter()
                module.state_ownership(state)
                timings[name].append(time.perf_counter()-start)
        report['predicate_timings'].append(dict(depth=depth, samples_seconds=timings,
            successful_list_search_positions=depth*(depth+1)//2))
        print(json.dumps(report['predicate_timings'][-1]), flush=True)
    report['preservation_after'] = freeze.verify(binary)
    assert report['preservation_before'] == report['preservation_after']
    report['passed'] = True
    (destination / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(dict(passed=True, predicate_cases=sum(report['outcomes'].values()),
                          native_streams=len(report['native_streams']))), flush=True)


if __name__ == '__main__':
    main(*(Path(arg).resolve() for arg in sys.argv[1:]))
