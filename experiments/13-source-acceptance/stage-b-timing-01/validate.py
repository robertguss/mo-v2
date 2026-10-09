"""Bounded timing validation, never million-element acceptance or private cases.

Usage: pinned-python validate.py NEW_EXTERNAL_DIRECTORY INSTRUMENTED_BINARY
Synthetic process probes test the harness, not evaluator sabotage controls.
"""
import ast
import copy
import gzip
import hashlib
import itertools
import json
import math
from pathlib import Path
import sys
import time

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import run_resources as runner
from run_timed import run, check_native_timing, NATIVE_PHASES
from envelope import ENVELOPE_SECONDS, check_amended_envelope


def ledger(result):
    row = result['parent_timing']
    assert sum(row['exclusive_wall_ns'].values()) == row['elapsed_ns'] == row['end_ns'] - row['start_ns']
    if 'native_timing' in result:
        check_native_timing(result['native_timing'])


def compare(old, new):
    # Same normalization as collector-01/profile.py: only clock and physical
    # addresses differ legitimately; IDs, rows and all semantic bytes remain.
    def normalized(line):
        row = json.loads(line)
        row.pop('elapsed_ns', None)
        if row.get('graph') is not None:
            row['graph'] = [entry[:-1] for entry in row['graph']]
        for key in ['events', 'mutations']:
            if key in row:
                row[key] = [entry[:2] + entry[3:] for entry in row[key]]
        return json.dumps(row, sort_keys=True, separators=(',', ':')).encode()
    digest = hashlib.sha256()
    count = 0
    with gzip.open(old, 'rb') as left, gzip.open(new, 'rb') as right:
        for a, b in itertools.zip_longest(left, right):
            assert a is not None and b is not None, 'stream lengths'
            a, b = normalized(a), normalized(b)
            assert a == b, f'semantic row mismatch {count}'
            digest.update(a + b'\n')
            count += 1
    return dict(rows=count, normalized_sha256=digest.hexdigest(), exact_match=True)


def resource_row(case='non-tail-sum', elapsed=0):
    return dict(case=case, depth=1000000, available_bytes=4*1024**3,
                stack_bytes=8*1024**2, transitions=100000000,
                remaining_owned_cells=0, peak_explicit_frames=1000000,
                evaluation_cell_counts=[0, 0, 1000000], status='finished',
                answer='1000000' if case == 'non-tail-sum' else '0', elapsed_seconds=elapsed)


def envelope_checks():
    old = ast.parse((HERE.parent / 'closeoutcheck.py').read_text())
    old = next(node for node in old.body if isinstance(node, ast.FunctionDef) and node.name == 'check_resource')
    new = ast.parse((HERE / 'envelope.py').read_text())
    new = next(node for node in new.body if isinstance(node, ast.FunctionDef) and node.name == 'check_amended_envelope')
    # Every non-time statement except case-domain syntax remains literally the
    # same AST. The split transition cap is checked independently below.
    for node in old.body[1:]:
        if 'elapsed_seconds' not in ast.unparse(node):
            assert any(ast.dump(node) == ast.dump(other) for other in new.body), ast.unparse(node)
    count = 0
    for case, limit in ENVELOPE_SECONDS.items():
        for elapsed in [0, 600, limit-0.001, limit]:
            row = resource_row(case, elapsed)
            before = copy.deepcopy(row)
            assert check_amended_envelope(row) is row and row == before
            count += 1
        for elapsed in [-1, limit+0.001, True, '1', math.inf, -math.inf, math.nan]:
            try:
                check_amended_envelope(resource_row(case, elapsed))
            except AssertionError:
                count += 1
            else:
                raise AssertionError(('invalid elapsed accepted', case, elapsed))
    for key, value in [('depth',999999), ('transitions',100000001), ('remaining_owned_cells',1),
                       ('stack_bytes',16*1024**2), ('available_bytes',4*1024**3-1),
                       ('peak_explicit_frames',999999), ('answer','999999'),
                       ('evaluation_cell_counts',[0,1,1000000]), ('status','suspended')]:
        row = resource_row(); row[key] = value
        try:
            check_amended_envelope(row)
        except AssertionError:
            count += 1
        else:
            raise AssertionError(('non-time defect accepted', key))
    return count


class SyntheticVerifier:
    """Harness probe only: its fabricated resource row is NOT scientific evidence."""
    step = 0
    def __init__(self, *_): pass
    def row(self, row):
        assert row == {'phase':'probe'}
        self.step += 1
    def finish(self):
        assert self.step == 1
        return dict(synthetic_pipeline_only=True)
    def resource_record(self, *, elapsed_seconds, **_):
        return resource_row(elapsed=elapsed_seconds)


SYNTHETIC_CHILD = '''import json, os, sys, time
json.loads(sys.stdin.readline())
mode=sys.argv[1]
if mode == 'stall': time.sleep(5)
print(json.dumps({'phase':'probe'}), flush=True)
if mode == 'abnormal': sys.exit(7)
if mode != 'missing':
    row={'format':'ROB-1333 native timing 01','unit':'ns','completed':True,'elapsed_ns':0,
         'exclusive_wall_ns':dict.fromkeys(['frontend','evaluation','cleanup','observation','collector','transport','approval_wait'],0)}
    if mode == 'incomplete': row['completed']=False
    if mode == 'reconcile': row['elapsed_ns']=1
    if mode == 'boolean': row['exclusive_wall_ns']['evaluation']=True
    if mode == 'extra': row['extra']=0
    if mode == 'impossible': row['exclusive_wall_ns']['evaluation']=10**20; row['elapsed_ns']=10**20
    raw=json.dumps(row)
    if mode == 'oversize': raw=' '*16385+raw
    if mode == 'duplicate': raw=raw.replace('"elapsed_ns": 0','"elapsed_ns": 0, "elapsed_ns": 0')
    with open(os.environ['ROB1333_TIMING_FILE'],'x') as f: f.write(raw)
'''


def main(root, binary):
    root.mkdir(parents=True, exist_ok=False)
    before = runner.prior.verify(runner.OLD_BINARY)
    report = dict(preservation_before=before, binary_sha256=runner.sha(binary),
                  envelope_assertions=envelope_checks(), probes=[], runs=[])
    def save():
        (root / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    save()
    Sum, Discard = runner.prior.orchestration.NonTailSum, runner.prior.orchestration.DiscardedList
    verifier, decode = runner.prior.approved.LargeVerifier, runner.prior.approved.load
    for mode in ['valid','missing','incomplete','reconcile','boolean','extra','impossible','oversize','duplicate','abnormal','stall']:
        result = run([sys.executable, '-c', SYNTHETIC_CHILD, mode], Sum(64), root / ('synthetic-'+mode),
                     verifier_type=SyntheticVerifier, decode=decode, timeout=0.2 if mode == 'stall' else 10)
        assert result['passed'] == (mode == 'valid'), (mode, result)
        if mode == 'stall': assert result['error_kind'] == 'timeout'
        elif mode == 'abnormal': assert result['exit_code'] == 7
        elif mode != 'valid': assert result['error_kind'] == 'sidecar', result
        assert json.loads((root / ('synthetic-'+mode) / 'summary.json').read_text())['passed'] == result['passed']
        ledger(result)
        report['probes'].append(dict(mode=mode, expected_outcome=True, result=result))
        save()
    for cls, depth in [(Sum,64),(Discard,64),(Sum,10003),(Sum,20003),(Sum,40003),(Discard,10003)]:
        workload = cls(depth)
        paired = []
        folders = []
        for label, executable, function in [('baseline',runner.OLD_BINARY,runner.prior.orchestration.run),('timed',binary,run)]:
            folder = root / f'{workload.name}-{depth}-{label}'
            started = time.monotonic_ns()
            result = function([str(executable)], workload, folder, verifier_type=verifier, decode=decode)
            elapsed = (time.monotonic_ns()-started)/1e9
            assert result['exit_code'] == 0 and result['deepest_photographed'] and result['destroy_calls'] == 2, result
            assert result['committed_steps'] == workload.transitions(), result
            assert not result['passed'] and result['error'] == 'AssertionError: resource completion/depth', result
            if label == 'timed': ledger(result)
            paired.append(dict(label=label, result=result, experiment_wall_seconds=elapsed))
            folders.append(folder)
        comparison = compare(*(folder / 'rows.jsonl.gz' for folder in folders))
        report['runs'].append(dict(case=workload.name, depth=depth, paired=paired, comparison=comparison))
        save()
        print(json.dumps(dict(case=workload.name, depth=depth, matching_rows=comparison['rows'])), flush=True)
    # Delay the real frozen verifier, not candidate execution. Pipe capacity is
    # exceeded by depth64 records while the first commit is held for 0.8 seconds.
    for phase in ['check','commit']:
        class Delayed(verifier):
            delayed = False
            def row(self, record):
                if record['phase'] == phase and not self.delayed:
                    self.delayed = True
                    time.sleep(0.8)
                return super().row(record)
        result = run([str(binary)], Sum(64), root / ('delay-'+phase), verifier_type=Delayed, decode=decode)
        assert result['semantic_completed'] and result['error'] == 'AssertionError: resource completion/depth', result
        times = result['native_timing']['exclusive_wall_ns']
        category = 'approval_wait' if phase == 'check' else 'transport'
        assert times[category] >= 600000000 and times['evaluation'] < 300000000, times
        assert result['parent_timing']['exclusive_wall_ns']['predicates'] >= 800000000
        ledger(result)
        report['probes'].append(dict(mode='delay-'+phase, expected_outcome=True, result=result))
        save()
        failed = run([str(binary)], Sum(64), root / ('timeout-'+phase), verifier_type=Delayed, decode=decode, timeout=0.2)
        assert not failed['passed'] and failed['error_kind'] == 'timeout', failed
        report['probes'].append(dict(mode='timeout-'+phase, expected_outcome=True, result=failed))
        save()
    report.update(preservation_after=runner.prior.verify(runner.OLD_BINARY), passed=True,
                  source_hashes={str(p.relative_to(HERE)):runner.sha(p) for p in HERE.rglob('*')
                                 if p.is_file() and '__pycache__' not in p.parts and 'evidence' not in p.parts})
    assert before == report['preservation_after'] and runner.sha(binary) == report['binary_sha256']
    save()
    print(json.dumps(dict(passed=True, envelope_assertions=report['envelope_assertions'],
                         harness_probes=len(report['probes']), matching_rows=sum(r['comparison']['rows'] for r in report['runs']))), flush=True)


if __name__ == '__main__':
    main(*(Path(arg).resolve() for arg in sys.argv[1:]))
