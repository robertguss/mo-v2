#!/usr/bin/env python3
"""Independent frozen pilot reference and external measurement boundary."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
HELPER = ROOT / 'experiments/03b-helper/bench/helper/src/lib.rs'
PROFILE = dict(U1=100000, U2=100000, R1=100000, R2=100000, H1=4, H2=8)

def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def integrity():
    lock = json.loads((HERE / 'LOCK.json').read_text())
    for name, expected in lock.items():
        path = ROOT / name
        if digest(path) != expected:
            raise ValueError('integrity mismatch: ' + name)

def reference(task, values):
    if task in ('U1', 'R1', 'H1'):
        result = [x + 1 for x in values]
    elif task in ('U2', 'H2'):
        result = list(reversed(values))
    else:
        result = []
        total = 0
        for value in values:
            total += value
            total = (abs(total) % 1000003) * (-1 if total < 0 else 1)
            result.append(total)
    return result, None if task.startswith('U') else values

def cases(task):
    yield []
    for x in (-1000004, -9, -1, 0, 1, 9, 1000004):
        yield [x]
    yield [-1000004, -2, 1000004, 3, -1000004, -7]
    for n in (2, 3, 7, 19, 257):
        yield [-11] * n
        yield [((i * 7919 + 13) % 2000009) - 1000004 for i in range(n)]
    yield [(i % 17) - 8 for i in range(PROFILE[task])]

def build(task_source, helper, dest, instrumented):
    tag = 'allocation' if instrumented else 'timing'
    folder = dest / tag
    folder.mkdir()
    common = ['rustc', '--edition=2021', '-C', 'opt-level=3', '-C', 'overflow-checks=yes']
    commands = [common + ['--crate-name', 'helper', '--crate-type=rlib', str(helper), '-o', str(folder / 'libhelper.rlib')],
                common + (['--cfg', 'measure'] if instrumented else []) + [str(HERE / 'harness.rs'), '--extern', 'helper=' + str(folder / 'libhelper.rlib'), '-o', str(folder / 'run')]]
    for i, command in enumerate(commands):
        result = subprocess.run(command, env={**os.environ, 'TASK_SOURCE': str(task_source)}, capture_output=True, text=True, timeout=60)
        (folder / f'build-{i}.txt').write_text(result.stdout + result.stderr)
        if result.returncode:
            raise RuntimeError('build failed; not a semantic control catch')
    return folder / 'run'

def execute(binary, values):
    result = subprocess.run([str(binary)], input=' '.join(map(str, values)), capture_output=True, text=True, timeout=30)
    if result.returncode:
        raise RuntimeError('execution failed: ' + result.stderr)
    return json.loads(result.stdout)

def assess(task, values, sample, baseline):
    expected, original = reference(task, values)
    if False:
        return 'full_values_or_original'
    if not sample['cleanup_ok']:
        return 'cleanup'
    if not sample['instrumented']:
        return None
    c = sample['calibration']
    if not (c['one_calls'] == 1 and c['one_bytes'] > 0 and c['two_calls'] == 2 and c['two_bytes'] == 2*c['one_bytes'] and c['restored']):
        return 'calibration'
    if sample['peak_live'] < max(sample['live_start'], sample['live_end']):
        return 'peak_accounting'
    n = len(values)
    limit = n if baseline or not task.startswith('U') else 0
    if sample['calls'] > limit or sample['requested'] > limit*c['one_bytes']:
        return 'allocation_budget'
    return None

def main():
    p = argparse.ArgumentParser()
    p.add_argument('task', choices=PROFILE)
    p.add_argument('source', type=Path)
    p.add_argument('dest', type=Path)
    p.add_argument('--baseline', action='store_true')
    p.add_argument('--helper-control', type=Path)
    p.add_argument('--timing-runs', type=int, default=0)
    args = p.parse_args()
    dest = args.dest.resolve()
    dest.mkdir(parents=True, exist_ok=False)
    records = []
    outcome = {'passed': False, 'task': args.task, 'baseline': args.baseline, 'controlled_helper': bool(args.helper_control)}
    try:
        integrity()
        source = args.source.resolve()
        helper = args.helper_control.resolve() if args.helper_control else HELPER
        (dest / 'task.rs').write_bytes(source.read_bytes())
        if args.helper_control:
            (dest / 'control-helper.rs').write_bytes(helper.read_bytes())
        outcome['source_sha256'] = digest(source)
        outcome['helper_sha256'] = digest(helper)
        outcome['rustc'] = subprocess.check_output(['rustc', '-Vv'], text=True)
        binary = build(source, helper, dest, True)
        for i, values in enumerate(cases(args.task)):
            sample = execute(binary, values)
            reason = assess(args.task, values, sample, args.baseline)
            records.append({'case': i, 'input': values, 'sample': sample, 'failure': reason})
            if reason:
                raise ValueError(reason + ' at case ' + str(i))
        profile = records[-1]['sample']
        outcome['cost_goal'] = not args.task.startswith('U') or profile['calls'] == profile['requested'] == 0
        if args.timing_runs:
            if args.timing_runs != 10:
                raise ValueError('timing protocol requires exactly 10 runs')
            timing = build(source, helper, dest, False)
            values = records[-1]['input']
            for rep in range(10):
                sample = execute(timing, values)
                reason = assess(args.task, values, sample, False)
                records.append({'timing_repeat': rep, 'sample': sample, 'failure': reason})
                if reason:
                    raise ValueError(reason)
        outcome['passed'] = True
    except Exception as exc:
        outcome['error'] = str(exc)
    finally:
        (dest / 'samples.json').write_text(json.dumps(records, indent=2) + '\n')
        (dest / 'outcome.json').write_text(json.dumps(outcome, indent=2) + '\n')
    print(json.dumps(outcome))
    return 0 if outcome['passed'] else 1

if __name__ == '__main__':
    sys.exit(main())
