"""Compile real broken variants; reuse the frozen comparison unchanged."""
import json
from pathlib import Path
import sys
import check

root=Path(__file__).resolve().parent
source=(root/'backend.rs').read_text()
dest=Path(sys.argv[1]).resolve();dest.mkdir(parents=True,exist_ok=False)
controls=[
    ('shared-mutation','if c.count==1 {','if c.count>=1 {',('outside value changed','holder points to reserved cell','runtime process failed')),
    ('early-free','if n==0 {','if true {',('cycle or dangling holder','runtime process failed')),
    ('leak-tail','self.give_up(c.link);','let _=c.link;',('unreachable live memory or missing result',)),
    ('always-allocate','if c.count==1 {','if false && c.count==1 {',('Lean/Rust mismatch:',)),
    ('hidden-precopy','// The measured interval begins before all evaluation preparation.',
     '// The measured interval begins before all evaluation preparation.\n    if let Some(c)=s.cells.first() { let hidden=Box::new(LiveCell::new(c.0.clone())); std::hint::black_box(&hidden); drop(hidden); }',
     ('physical allocation hidden from logical interval',)),
]
summary=[]
for name,old,new,reasons in controls:
    check.require(source.count(old)==1,'mutation anchor not unique')
    path=dest/(name+'.rs');path.write_text(source.replace(old,new))
    result=check.run(path,dest/name)
    error=result['error'] or ''
    caught=not result['passed'] and any(r in error for r in reasons) and 'build failed' not in error
    # Runtime rejection must be the expected native-state defect, not any crash.
    if 'runtime process failed' in error:
        stderr=(dest/name/'stderr.txt').read_text()
        caught=caught and ('reserved cell read' in stderr if name=='shared-mutation' else 'cell not allocated' in stderr)
        caught=caught and 'failed input index 4' in stderr
    summary.append(dict(name=name,caught=caught,checked_before_rejection=result['checked'],error=error,source_sha256=result['source_sha256']))
    (dest/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    check.require(caught,f'control not rejected for expected defect: {name}: {error}')
print('PASS: five real compiled source controls rejected')
