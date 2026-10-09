"""Differential checks of the proposed helpers on synthetic JSON, not private data."""
import hashlib
import itertools
import json
from pathlib import Path
import random
import sys

BASE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE))
import integration as frozen
import fast_json as proposal


def outcome(function, *args):
    try:
        result = function(*args)
        return ('ok', json.dumps(result, sort_keys=True))
    except Exception as error:
        return (type(error).__name__, str(error))


report = dict(exact=0, load=0, fields=0, digests=0)
values = [None, False, True, 0, 1, -1, 2**128, 0.0, -0.0, 1.0,
          1.25, float('nan'), float('inf'), '', '1', '\u0000\ud800', [],
          [True], [1], [[0.0]], [[-0.0]], {}, {'a': 1}, {'a': True}]
for a, b in itertools.product(values, repeat=2):
    for actual, expected in ((a, b), ([a], [b]), ({'a': a}, {'a': b})):
        assert outcome(frozen.exact, actual, expected, 'equality') == outcome(
            proposal.exact, actual, expected, 'equality')
        report['exact'] += 1

rng = random.Random(1333)  # Synthetic helper test only; not a private-corpus seed.


def tree(depth=0):
    choices = 2 if depth == 5 else 4
    kind = rng.randrange(choices)
    if kind < 2:
        return rng.choice(values[:17])
    if kind == 2:
        return [tree(depth+1) for _ in range(rng.randrange(5))]
    return {str(i): tree(depth+1) for i in range(rng.randrange(5))}


for _ in range(5000):
    a, b = tree(), tree()
    for actual, expected in ((a, a), (a, b)):
        assert outcome(frozen.exact, actual, expected, 'equality') == outcome(
            proposal.exact, actual, expected, 'equality')
        report['exact'] += 1
    raw = json.dumps(a)
    for encoded in (raw, raw.encode(), raw.encode('utf-16'), raw.encode('utf-32')):
        assert outcome(frozen.load, encoded) == outcome(proposal.load, encoded)
        report['load'] += 1
    old, new = hashlib.sha256(), hashlib.sha256()
    old.update(json.dumps(a, sort_keys=True, separators=(',', ':')).encode() + b'\n')
    proposal.hash_item(new, a)
    assert old.digest() == new.digest()
    report['digests'] += 1

for raw in ('', '\ufeff{}', '{"a":1,"a":2}', '{"a":{"b":1,"b":2}}',
            '{', '[1,]', 'NaN', 'Infinity', '-Infinity', '{} trailing',
            '"\\ud800"', '1e400', '\n  {} \t', b'\xef\xbb\xbf{}', b'\xff'):
    for _ in range(3):
        assert outcome(frozen.load, raw) == outcome(proposal.load, raw)
        assert outcome(frozen.load, '{"ok":[]}') == outcome(proposal.load, '{"ok":[]}')
        report['load'] += 2
for obj in ({}, {'a': 1}, {'b': 2, 'a': 1}, {'c': 0, 'a': 1}, {1: 0}, [], None):
    for names in ('', 'a', 'a b', 'b a', 'a a', 'a c'):
        assert outcome(frozen.fields, obj, names) == outcome(proposal.fields, obj, names)
        report['fields'] += 1
report.update(passed=True, helper_sha256=hashlib.sha256(Path(proposal.__file__).read_bytes()).hexdigest())
print(json.dumps(report, indent=2))
