"""Differential public protocol probes. Synthetic, not native evaluator controls.

Usage: python3 check_protocol.py OLD_PROBE NEW_PROBE NEW_OUTPUT_DIRECTORY
Both binaries compile the same example against different collector libraries.
Compare every emitted row and exact error, removing only the clock in the probe.
"""
import hashlib
import itertools
import json
from pathlib import Path
import subprocess
import sys


def snapshot(value, status='suspended'):
    return '{"step":0,"status":' + json.dumps(status) + ',"x":' + value + '}'


def probes():
    values = ['null', 'true', 'false', '0', '-0', '0.0', '-0.0', '1', '1.0', '1e0',
              '-1', '18446744073709551615', '18446744073709551616',
              '-9223372036854775808', '-9223372036854775809', '1e308', '1e309', '1e-400',
              '"A"', '"\\u0041"', '"é"', '"\\ud83d\\ude00"', '"\\uD800"', '"\\uDC00"',
              '[1,2]', '[2,1]', '{"a":1,"b":2}', '{"b":2,"a":1}', '{"a":0,"a":1}',
              '{"a":1}', 'NaN', 'Infinity', '01', '+1', '1.', '1e', '[1,]', '{"a":1,}',
              '"\\x41"', '"line\nfeed"', '{1:0}', '[', '{', '"', '']
    for value in values:
        for container in [value, '[' + value + ']', '{"nested":' + value + '}']:
            raw = snapshot(container)
            yield dict(snapshots=[raw])
            # Even a subsequently overwritten key must be parsed and validated.
            yield dict(snapshots=[raw[:-1] + ',"x":null}'])
    for left, right in itertools.product(values, repeat=2):
        yield dict(snapshots=[snapshot(left), snapshot(right)])
    base = snapshot('[1,"A",-0.0]')
    for size in range(len(base) + 1):
        yield dict(snapshots=[base[:size]])
    for suffix in ['', ' ', '\n\t', ' false', '{}', '\x00']:
        yield dict(snapshots=[base + suffix])
    for depth in range(123, 131):
        for opening, closing in [('[', ']'), ('{"a":', '}')]:
            yield dict(snapshots=[snapshot(opening * depth + '0' + closing * depth)])
    for value in values:
        yield dict(snapshots=[value])
        for field in ['step', 'status']:
            yield dict(snapshots=['{"step":0,"status":"suspended","' + field + '":' + value + '}'])
    for invalid in [b'\xff', b'\xc0\xaf', b'\xed\xa0\x80', b'\x80']:
        yield dict(snapshots=[list(b'{"step":0,"status":"suspended","x":"' + invalid + b'"}')])
    for status in ['suspended', 'finished', 'failed']:
        for budget in [0, 1, 9]:
            for after in [snapshot('0', status), snapshot('1', status), snapshot('0', 'suspended')]:
                yield dict(snapshots=[snapshot('0', status), after], budgets=[budget], advances=[dict(status=status)])
    for metadata in ['{}', '{"step":2,"event_end":0,"events_added":[]}',
                     '{"step":1,"event_end":1,"events_added":[]}',
                     '{"step":1,"event_end":0,"events_added":[]}']:
        for large in [False, True]:
            for budget in [0, 1]:
                yield dict(snapshots=[base, base.replace('"step":0', '"step":1')], large=large,
                           budgets=[budget], advances=[dict(step=1, callbacks=[metadata])])


def main(old, new, output):
    output.mkdir(parents=True, exist_ok=False)
    cases = list(probes())
    payload = b''.join(json.dumps(case).encode() + b'\n' for case in cases)
    (output / 'requests.jsonl').write_bytes(payload)
    replies = []
    for label, binary in [('old', old), ('new', new)]:
        result = subprocess.run([str(binary)], input=payload, capture_output=True, timeout=60, check=True)
        (output / f'{label}.rows.jsonl').write_bytes(result.stdout)
        (output / f'{label}.stderr').write_bytes(result.stderr)
        replies.append([json.loads(line) for line in result.stdout.splitlines()])
    assert len(replies[0]) == len(replies[1]) == len(cases)
    mismatches = [i for i, (a, b) in enumerate(zip(*replies)) if a != b]
    report = dict(probes=len(cases), passed=not mismatches, mismatches=mismatches,
                  accepted=sum(row['error'] is None for row in replies[0]),
                  rejected=sum(row['error'] is not None for row in replies[0]),
                  synthetic_protocol_only=True,
                  binaries={label: hashlib.sha256(path.read_bytes()).hexdigest() for label, path in [('old', old), ('new', new)]},
                  runner_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    (output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    assert not mismatches, 'collector protocol differs'


if __name__ == '__main__':
    main(*(Path(argument).resolve() for argument in sys.argv[1:]))
