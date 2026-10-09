"""Verifier-owned read-only full-boundary/view checks, not a source evaluator."""
import argparse
import copy
import hashlib
import json
import re
from pathlib import Path


def require(ok, message):
    if not ok:
        raise AssertionError(message)


def view(state):
    entered = {pair[1] for pair in state['entered']}
    expected = [b[0] for b in state['bindings']
                if b[0] in entered or b[3] == 'Trial.BStatus.holding']
    require(state['visibleBindings'] == expected, 'exact entered/holding ordered view')


def boundary(after):
    require(after['internal']['completeState'] == after['commitMetadataRestored'],
            'complete internal equality against actual metadata-restored commit')


def run(raw):
    counts = {'traces': len(raw), 'internalEqualities': 0, 'visibleViews': 0}
    def walk(value):
        if isinstance(value, dict):
            if 'visibleBindings' in value:
                view(value)
                counts['visibleViews'] += 1
            for child in value.values():
                walk(child)
        elif isinstance(value, list):
            for child in value:
                walk(child)
    walk(raw)
    for case, observation in raw.items():
        for after in observation['trace'][1:]:
            if after['internal'] is not None:
                boundary(after)
                counts['internalEqualities'] += 1
            else:
                require(after['correspondence'] == 'denial', case + ': absent internal')
    return counts


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('evidence', type=Path)
    parser.add_argument('--report', required=True, type=Path)
    args = parser.parse_args()
    path = args.evidence / 'raw.json'
    raw = json.loads(path.read_text())
    counts = run(raw)
    sample = next(s for o in raw.values() for s in o['trace'][1:] if s['internal'])
    hidden = copy.deepcopy(sample)
    old = hidden['internal']['completeState']
    changed, n = re.subn(r'(nextBinding := )(\d+)',
                         lambda m: m[1] + str(int(m[2]) + 1), old, count=1)
    require(n == 1, 'hidden nextBinding mutation reached')
    hidden['internal']['completeState'] = changed
    visible = next(s for o in raw.values() for s in o['trace']
                   if len(s['visibleBindings']) >= 2)
    omitted, reordered = copy.deepcopy(visible), copy.deepcopy(visible)
    omitted['visibleBindings'].pop()
    reordered['visibleBindings'].reverse()
    negatives = []
    for name, check, value in [('hidden nextBinding', boundary, hidden),
                               ('omitted visible entry', view, omitted),
                               ('reordered visible entries', view, reordered)]:
        try:
            check(value)
        except AssertionError as error:
            negatives.append({'name': name, 'status': 'REJECTED', 'reason': str(error)})
        else:
            raise AssertionError(name + ' escaped')
    report = {'status': 'PASS', 'counts': counts, 'controls': negatives,
              'rawSha256': hashlib.sha256(path.read_bytes()).hexdigest(),
              'limits': ['Repr equality, not kernel equality proof',
                         'View formula checked from exposed IDs; active-scope correctness is a separate source/spec question',
                         'Data corruption controls, not executed machine mutants']}
    args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
