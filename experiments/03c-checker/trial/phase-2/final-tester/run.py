import subprocess, pathlib, json, datetime, hashlib, re

ROOT = pathlib.Path('/tmp/rob1137-test')
E = ROOT / 'evidence'
PROJECT = ROOT / 'reconstructed/experiments/03c-checker/trial/lean'

def run(label, command, cwd=PROJECT):
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    with (E / (label + '.stdout')).open('wb') as out, (E / (label + '.stderr')).open('wb') as err:
        p = subprocess.run(command, cwd=cwd, stdout=out, stderr=err)
    record = dict(label=label, command=command, cwd=str(cwd), started=started,
                  finished=datetime.datetime.now(datetime.timezone.utc).isoformat(), exit=p.returncode)
    with (E / 'commands.jsonl').open('a') as f:
        f.write(json.dumps(record) + '\n')
    print(json.dumps(record), flush=True)
    return p.returncode

if __name__ == '__main__':
    assert not (PROJECT / '.lake').exists()
    trial = PROJECT.parent
    locks = dict(re.findall(r'^\| `([^`]+)`\s*\| `([a-f0-9]{64})`', (trial / 'LOCK.md').read_text(), re.M))
    assert len(locks) == 25, len(locks)
    rows = []
    for name, expected in locks.items():
        actual = hashlib.sha256((trial / name).read_bytes()).hexdigest()
        rows.append(dict(file=name, expected=expected, actual=actual, passed=actual == expected))
    (E / 'hashes.json').write_text(json.dumps(rows, indent=2) + '\n')
    assert all(x['passed'] for x in rows)
    print('25/25 effective last-row fingerprints match; .lake absent', flush=True)
    run('toolchain', ['lake', 'env', 'lean', '--version'])
    build = run('clean-build', ['lake', 'build', 'Trial', 'Checks', 'Promises', 'Proofs', 'Acceptance'])
    if build == 0:
        run('types', ['lake', 'env', 'lean', str(ROOT / 'Types.lean')])
        run('kernel', ['lake', 'env', 'leanchecker', '--fresh', 'Acceptance'])
        run('examples', ['lake', 'env', 'lean', '--run', 'Checks/Run.lean'])
        run('example-byte-comparison', ['cmp', str(E / 'examples.stdout'), str(trial / 'results/run-1.txt')])
