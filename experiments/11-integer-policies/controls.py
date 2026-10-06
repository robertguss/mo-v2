"""Compile four broken variants and require semantic counterexamples."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from check import ROOT, correctness, require

changes=[
 ('wrong-wrap','"add"=>a.wrapping_add(b)','"add"=>a.saturating_add(b)','wrapping '),
 ('unchecked-overflow','"add"=>a.checked_add(b)','"add"=>Some(a.wrapping_add(b))','checked '),
 ('silent-narrowing','x.to_i64().ok_or("narrowing")?','x.to_i64().unwrap_or(0)','explicit asfixed '),
 ('mixed-types','if matches!((&a,&b)','if false && matches!((&a,&b)','explicit '),
]
dest=ROOT/'evidence/controls-01';dest.mkdir(exist_ok=False)
source=(ROOT/'src/main.rs').read_text()
for name,old,new,prefix in changes:
    require(source.count(old)==1,'mutation anchor ambiguous')
    out=dest/name;out.mkdir();mutated=source.replace(old,new)
    (out/'main.rs').write_text(mutated)
    with tempfile.TemporaryDirectory(prefix='mo-integer-control-') as tmp:
        tmp=Path(tmp);(tmp/'src').mkdir();(tmp/'src/main.rs').write_text(mutated)
        for f in ['Cargo.toml','Cargo.lock']: shutil.copyfile(ROOT/f,tmp/f)
        env=dict(os.environ,RUSTFLAGS='-D warnings',CARGO_TARGET_DIR=str(ROOT/'target/controls'))
        p=subprocess.run(['cargo','build','--release','--locked','--offline'],cwd=tmp,env=env,text=True,capture_output=True)
        (out/'build.txt').write_text(p.stdout+p.stderr);require(p.returncode==0,'control did not compile')
        r=correctness(ROOT/'target/controls/release/integer-policies',out/'check')
        require(not r['passed'],'control escaped')
        c=json.loads((out/'check/counterexample.json').read_text())
        require(c['input'].startswith(prefix),'wrong control caught')
        print(name,c,flush=True)
(dest/'outcome.json').write_text(json.dumps(dict(passed=True,compiled_and_caught=len(changes)),indent=2)+'\n')
