"""Real source mutations, checked against unchanged behavioral expectations."""
import gzip
import hashlib
import json
from pathlib import Path
import sys
import check

root=Path(__file__).resolve().parent
source=(root/'host.rs').read_text()
dest=Path(sys.argv[1]).resolve();dest.mkdir(parents=True,exist_ok=False)
controls=[
 ('no-cap', [('if s.updaters.len() >= 2 {','if false && s.updaters.len() >= 2 {')],
  'excess update not refused at resource limit'),
 ('timeout-releases-capacity', [('if s.updaters.len() >= 2 {',
  'if s.attempts.iter().filter(|a| !a.returned && a.status != "timeout").count() >= 2 {')],
  'excess update not refused at resource limit'),
 ('never-reap', [('if s.updaters[i].is_finished() {','if false && s.updaters[i].is_finished() {')],
  'update refused'),
 ('unsafe-retire', [('if version == s.active || Arc::strong_count(module) != 1 {',
  'if version != s.active { let _loader = LOADER.lock().unwrap(); assert_eq!(unsafe { dlclose(module.handle) }, 0); }\n            if version == s.active || Arc::strong_count(module) != 1 {')],
  'executing migration unloaded'),
 ('timeout-no-resume', [('if s.frozen == id {','if s.frozen == id && status != "timeout" {')],
  'old queue not resumed after timeout'),
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
error=check.trial(root/'host.rs',dest/'forced-cleanup',force_failure=True)
check.require(error is not None and 'forced failure after two native hangs' in error,'forced failure not exercised')
trace=json.loads(gzip.decompress((dest/'forced-cleanup/trace.json.gz').read_bytes()))
check.require(trace[-1]['process_gone'] and trace[-1]['cleanup_exit']==-9,'forced failure cleanup failed')
(dest/'cleanup.json').write_text(json.dumps(trace[-1],indent=2)+'\n')
print('PASS: five real source controls caught; forced failure process teardown verified')
