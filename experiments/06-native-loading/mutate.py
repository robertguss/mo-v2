"""Build real broken host copies and require the specified observable failure."""
import hashlib
import json
from pathlib import Path
import sys
import check

root = Path(__file__).resolve().parent
source = (root / 'host.rs').read_text()
dest = Path(sys.argv[1]).resolve()
dest.mkdir(parents=True, exist_ok=False)
controls = [
    ('premature-retirement', 'Arc::strong_count(module) != 1', 'Arc::strong_count(module) == 0',
     'premature retirement allowed'),
    ('force-unload-inflight', 'if version == s.active || Arc::strong_count(module) != 1 {',
     'if version != s.active { assert_eq!(unsafe { dlclose(module.handle) }, 0); }\n            if version == s.active || Arc::strong_count(module) != 1 {',
     'old image unloaded while executing'),
    ('never-unload', 'assert_eq!(unsafe { dlclose(self.handle) }, 0, "dlclose failed");',
     'let _ = self.handle;', 'old image not unloaded'),
    ('mixed-version', 'let result = job.code.call(first, None, &sh);',
     'let code = { let s = sh.state.lock().unwrap(); Arc::clone(&s.modules[&s.active]) };\n        let result = code.call(first, None, &sh);',
     'mixed or wrong code behavior'),
    ('drop-queue', 's.active = module.version;', 's.queue.clear();\n            s.active = module.version;',
     'timeout: queued old job still pinned'),
    ('wrong-abi', 'if unsafe { abi() } != 1 {', 'if unsafe { abi() } == u64::MAX {',
     'incompatible artifact accepted'),
]
summary = []
for name, old, new, expected in controls:
    check.require(source.count(old) == 1, 'mutation anchor count')
    path = dest / (name + '.rs')
    path.write_text(source.replace(old, new))
    error = check.run_trial(path, dest / name)
    caught = error is not None and ('AssertionError: ' + expected) in error
    summary.append(dict(name=name, caught=caught, expected=expected,
                        source_sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    (dest / 'summary.json').write_text(json.dumps(summary, indent=2)+'\n')
    check.require(caught, f'control not caught as intended: {name}: {error}')
print('PASS: six actual source controls built and caught for intended observable failures')
