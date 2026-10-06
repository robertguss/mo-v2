"""Supplemental source controls against probe.py, not a passing original trial."""
import hashlib
import json
from pathlib import Path
import sys
import probe

root=Path(__file__).resolve().parent
source=(root/'host.rs').read_text()
dest=Path(sys.argv[1]).resolve();dest.mkdir(parents=True,exist_ok=False)
controls=[
 ('no-watchdog', [('if id != 0 && Instant::now() >= s.attempts[id - 1].deadline {',
                   'if false && id != 0 && Instant::now() >= s.attempts[id - 1].deadline {')],
  'watchdog did not expire held preparation'),
 ('stale-publication', [('let authorized = s.pending == id && s.active == base;',
                         'let authorized = s.pending == id && s.active == base || s.attempts[id - 1].status == "timeout";'),
                        ('} else if Instant::now() >= s.attempts[id - 1].deadline {',
                         '} else if false && Instant::now() >= s.attempts[id - 1].deadline {')],
  'stale candidate overwrote newer activation'),
 ('premature-unload', [('if version == s.active || Arc::strong_count(module) != 1 {',
                        'if version != s.active { let _loader = LOADER.lock().unwrap(); assert_eq!(unsafe { dlclose(module.handle) }, 0); }\n            if version == s.active || Arc::strong_count(module) != 1 {')],
  'candidate unloaded while preparing'),
 ('bad-readiness', [('} else if ready != 42 {','} else if ready == u64::MAX {')],
  'bad readiness accepted'),
 ('lock-during-native', [('let ready = unsafe { (module.prepare)(preparing, &context as *const _ as *mut c_void) };',
                         'let _bad_lock = sh.state.lock().unwrap();\n        let ready = unsafe { (module.prepare)(preparing, &context as *const _ as *mut c_void) };')],
  'TimeoutError'),
]
summary=[]
for name,changes,expected in controls:
    mutated=source
    for old,new in changes:
        probe.require(mutated.count(old)==1,'mutation anchor count')
        mutated=mutated.replace(old,new)
    path=dest/(name+'.rs');path.write_text(mutated)
    error=probe.trial(path,dest/name)
    caught=error is not None and expected in error
    summary.append(dict(name=name,caught=caught,expected=expected,source_sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    (dest/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    probe.require(caught,f'control not caught for intended reason: {name}: {error}')
print('SUPPLEMENTAL: five source controls built and caught; original acceptance remains failed')
