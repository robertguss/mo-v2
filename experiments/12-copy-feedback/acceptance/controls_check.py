#!/usr/bin/env python3
"""Post-freeze negative-control driver; never substitutes pilot acceptance."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
EXP = HERE.parent
spec = importlib.util.spec_from_file_location('frozen_check', HERE / 'check.py')
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)

def main():
    dest = Path(sys.argv[1]).resolve()
    dest.mkdir(parents=True, exist_ok=False)
    outcomes = []
    check.integrity()
    for name, task, reason in [('discard-old', 'R1', 'full_values_or_original'),
                                ('outside-inner-interval', 'U1', 'allocation_budget')]:
        target = dest / name
        r = subprocess.run([sys.executable, str(HERE / 'check.py'), task,
                            str(EXP / 'controls' / (name + '.rs')), str(target)], capture_output=True, text=True)
        (target / 'driver.txt').write_text(r.stdout + r.stderr)
        result = json.loads((target / 'outcome.json').read_text())
        records = json.loads((target / 'samples.json').read_text())
        assert r.returncode == 1 and result['error'].startswith(reason) and records[-1]['failure'] == reason, result
        outcomes.append({'control': name, 'caught': True, 'reason': reason, 'compiled': True})
    # The old mutant uses a different cell representation; this deliberately tests
    # preservation semantics alone, not its incompatible allocation calibration.
    target = dest / 'shared-mutation'
    target.mkdir()
    helper = ROOT / 'experiments/03b-helper/acceptance/mutants/shared-mutation/src/lib.rs'
    task = EXP / 'tasks/R1/task.rs'
    shutil.copyfile(helper, target / 'helper.rs')
    shutil.copyfile(task, target / 'task.rs')
    binary = check.build(task, helper, target, True)
    values = [-4, 0, 9]
    sample = check.execute(binary, values)
    reason = check.assess('R1', values, sample, False)
    (target / 'sample.json').write_text(json.dumps({'input': values, 'sample': sample, 'failure': reason}, indent=2)+'\n')
    assert reason == 'full_values_or_original', reason
    outcomes.append({'control':'shared-mutation','caught':True,'reason':reason,'compiled':True,
                     'helper_sha256':check.digest(helper),'allocation_calibration':'excluded: mutant representation differs'})
    # Disposable complete-relative-path mirror: changed checks must fail identity
    # before a compiler or participant task can execute.
    target = dest / 'weakened-check'
    mirror = target / 'mirror'
    for relative in json.loads((HERE / 'LOCK.json').read_text()):
        path = mirror / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / relative, path)
    copied = mirror / HERE.relative_to(ROOT)
    shutil.copyfile(HERE / 'LOCK.json', copied / 'LOCK.json')
    path = copied / 'check.py'
    source = path.read_text()
    needle = "if sample['result'] != expected or sample['original'] != original:"
    assert source.count(needle) == 1
    path.write_text(source.replace(needle, 'if False:'))
    r = subprocess.run([sys.executable,str(path),'R1',str(EXP / 'tasks/R1/task.rs'),str(target / 'result')],capture_output=True,text=True)
    (target / 'driver.txt').write_text(r.stdout+r.stderr)
    result = json.loads((target / 'result/outcome.json').read_text())
    assert r.returncode == 1 and result['error'].startswith('integrity mismatch:'),result
    outcomes.append({'control':'weakened-check','caught':True,'reason':result['error'],'compiled':False,
                     'boundary':'integrity rejection before build'})
    check.integrity()
    (dest / 'outcome.json').write_text(json.dumps(outcomes,indent=2)+'\n')
    print(json.dumps(outcomes,indent=2))

if __name__ == '__main__':
    main()
