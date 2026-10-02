from run import ROOT, E, PROJECT, run
import shutil, pathlib, difflib, hashlib, json

if __name__ == '__main__':
    run('counterexamples', ['lake', 'env', 'lean', '--run', str(ROOT / 'Counterexamples.lean')])
    for variant in ['reusesShared', 'forgetsRest', 'freesHeld', 'neverReuses']:
        dest = ROOT / ('control-' + variant)
        shutil.copytree(PROJECT, dest, ignore=shutil.ignore_patterns('.lake'))
        assert not (dest / '.lake').exists()
        broken = dest / 'Trial/Broken.lean'
        before = broken.read_text()
        old = '  | .approved => Variant.approved'
        new = '  | .approved => { Variant.approved with ' + variant + ' := true }'
        assert before.count(old) == 1
        assert '  | .' + variant + ' => { Variant.approved with ' + variant + ' := true }' in before
        after = before.replace(old, new)
        broken.write_text(after)
        (E / (variant + '-mutation.diff')).write_text(''.join(difflib.unified_diff(
            before.splitlines(True), after.splitlines(True), fromfile='Trial/Broken.lean original',
            tofile='Trial/Broken.lean ' + variant)))
        changed = []
        for file in dest.rglob('*'):
            if file.is_file():
                rel = file.relative_to(dest)
                if file.read_bytes() != (PROJECT / rel).read_bytes():
                    changed.append(str(rel))
        assert changed == ['Trial/Broken.lean'], changed
        (E / (variant + '-copy-validation.json')).write_text(json.dumps(dict(
            fresh_lake_absent=True, changed_paths=changed,
            old_hash=hashlib.sha256(before.encode()).hexdigest(),
            new_hash=hashlib.sha256(after.encode()).hexdigest()), indent=2) + '\n')
        if variant != 'neverReuses':
            run(variant + '-acceptance', ['lake', 'build', 'Acceptance'], dest)
        else:
            run(variant + '-checks-build', ['lake', 'build', 'Checks'], dest)
            run(variant + '-examples', ['lake', 'env', 'lean', '--run', 'Checks/Run.lean'], dest)
