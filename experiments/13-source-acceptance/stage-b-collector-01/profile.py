"""Profile the proposed collector on bounded public runs, checking frozen verdicts.

Usage: python3.14 profile.py NEW_EXTERNAL_DIRECTORY PROPOSAL_BINARY
No full resource execution, candidate changes, or replacement verdict logic.
"""
import gzip
import hashlib
import itertools
import json
from pathlib import Path
import sys
import time

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
sys.path.insert(0, str(BASE / 'stage-b-performance-01'))
import run_resources as frozen


def sources():
    return {str(path.relative_to(HERE)): frozen.sha(path)
            for part in ['driver', 'link'] for path in sorted((HERE / part).rglob('*')) if path.is_file()}


def compare_rows(old, new):
    def normalized(line):
        row = json.loads(line)
        row.pop('elapsed_ns', None)
        if row.get('graph') is not None:
            row['graph'] = [entry[:-1] for entry in row['graph']]
        for key in ['events', 'mutations']:
            if key in row:
                row[key] = [entry[:2] + entry[3:] for entry in row[key]]
        return json.dumps(row, sort_keys=True, separators=(',', ':')).encode()
    count = 0
    digest = hashlib.sha256()
    with gzip.open(old, 'rb') as baseline, gzip.open(new, 'rb') as proposed:
        for left, right in itertools.zip_longest(baseline, proposed):
            assert left is not None and right is not None, 'different stream lengths'
            left, right = normalized(left), normalized(right)
            assert left == right, f'row {count} changed'
            digest.update(left + b'\n')
            count += 1
    return dict(rows=count, normalized_sha256=digest.hexdigest(), exact_match=True,
                excluded_fields='elapsed_ns and native pointer addresses only; each complete stream independently verified')


def main(destination, binary):
    destination.mkdir(parents=True, exist_ok=False)
    baseline = Path('/home/user/rob1333-stage-b-performance-01/target/release/rob1333-stage-b-link')
    report = dict(preservation_before=frozen.verify(baseline), source_hashes=sources(),
                  binary_sha256=frozen.sha(binary), runner_sha256=frozen.sha(Path(__file__)), runs=[])
    start = time.monotonic()
    for depth in [10003, 20003, 40003]:
        current = int(Path('/sys/fs/cgroup/amp.slice/amp-workload.slice/memory.current').read_text())
        limit = int(Path('/sys/fs/cgroup/amp.slice/amp-workload.slice/memory.max').read_text())
        assert limit - current > 6 * 1024**3, 'diagnostic cgroup headroom'
        command = ['prlimit', '--as=4294967296', '--cpu=180', '--', str(binary)]
        folder = destination / f'sum-{depth}'
        result = frozen.orchestration.run(command, frozen.orchestration.NonTailSum(depth), folder,
                                          verifier_type=frozen.approved.LargeVerifier, decode=frozen.approved.load)
        assert result.get('exit_code') == 0 and result['deepest_photographed'], result
        assert result['committed_steps'] == 18 * depth + 14 and result['destroy_calls'] == 2
        assert result['error'] == 'AssertionError: resource completion/depth', result
        old = Path(f'/home/user/rob1333-stage-b-memory-01/probe-{depth}')
        comparison = compare_rows(old / 'rows.jsonl.gz', folder / 'rows.jsonl.gz')
        old_summary = json.loads((old / 'summary.json').read_text())
        report['runs'].append(dict(depth=depth, result=result, comparison=comparison,
                                  baseline_peak_rss_kib=old_summary['peak_rss_kib'],
                                  peak_rss_reduction=1 - result['peak_rss_kib'] / old_summary['peak_rss_kib']))
        report['preservation_after'] = frozen.verify(baseline)
        assert report['preservation_before'] == report['preservation_after']
        assert report['source_hashes'] == sources() and report['binary_sha256'] == frozen.sha(binary)
        report['elapsed_seconds'] = time.monotonic() - start
        (destination / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(dict(depth=depth, scaled_semantics_pass=True, rows_match=comparison['rows'],
                              old_peak_kib=old_summary['peak_rss_kib'], new_peak_kib=result['peak_rss_kib'])), flush=True)


if __name__ == '__main__':
    main(*(Path(argument).resolve() for argument in sys.argv[1:]))
