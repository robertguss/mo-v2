"""Actual host source controls; original behavior checks are reused unchanged."""
import hashlib
import json
from pathlib import Path
import sys
import check

root=Path(__file__).resolve().parent
source=(root/'host.rs').read_text()
dest=Path(sys.argv[1]).resolve();dest.mkdir(parents=True,exist_ok=False)
controls=[
 ('corrupt-accepted', [('} else if !valid || s.queue.rows() != source {',
                       '} else if false && (!valid || s.queue.rows() != source) {')],
  'corrupt migration accepted'),
 ('stale-publication', [('let authorized = s.pending == id && s.active == base && s.frozen == id;',
                         'let authorized = s.pending == id && s.active == base && s.frozen == id || s.attempts[id - 1].status == "timeout";'),
                        ('} else if Instant::now() >= s.attempts[id - 1].deadline.unwrap() {',
                         '} else if false && Instant::now() >= s.attempts[id - 1].deadline.unwrap() {'),
                        ('} else if !valid || s.queue.rows() != source {',
                         '} else if s.attempts[id - 1].status != "timeout" && (!valid || s.queue.rows() != source) {')],
  'stale migration changed newer authority'),
 ('timeout-no-resume', [('if s.frozen == id {','if s.frozen == id && status != "timeout" {')],
  'old queue not resumed after timeout'),
 ('premature-unload', [('if version == s.active || Arc::strong_count(module) != 1 {',
                        'if version != s.active { let _loader = LOADER.lock().unwrap(); assert_eq!(unsafe { dlclose(module.handle) }, 0); }\n            if version == s.active || Arc::strong_count(module) != 1 {')],
  'old executing module unloaded'),
 ('rebind-old-jobs', [('s.active = module.version;',
                      'for owner in s.owners.values_mut() { *owner = Arc::clone(&module); }\n            s.active = module.version;')],
  'mixed native job'),
 ('leak-native-state', [('unsafe { (self.code.free)(self.handle) };',
                       'let _ = self.code.free; // deliberately leak the native queue')],
  'native queue state leaked at unload'),
]
summary=[]
for name,changes,expected in controls:
    mutated=source
    for old,new in changes:
        check.require(mutated.count(old)==1,'mutation anchor count')
        mutated=mutated.replace(old,new)
    path=dest/(name+'.rs');path.write_text(mutated)
    error=check.trial(path,dest/name)
    caught=error is not None and expected in error
    summary.append(dict(name=name,caught=caught,expected=expected,source_sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    (dest/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    check.require(caught,f'control not caught for intended reason: {name}: {error}')
print('PASS: six real source controls built and caught')
