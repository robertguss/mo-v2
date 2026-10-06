"""Rebuild/export the unchanged Lean reference in a disposable directory."""
import gzip
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parent
REPO=ROOT.parents[1]
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
reference=json.loads((ROOT/'evidence/reference-sha256.json').read_text())
assert all(hashlib.sha256((REPO/p).read_bytes()).hexdigest()==h for p,h in reference.items())
with tempfile.TemporaryDirectory(prefix='mo-finite-reference-') as tmp:
    project=Path(tmp)/'lean'
    shutil.copytree(REPO/'experiments/03c-checker/trial/lean',project,ignore=shutil.ignore_patterns('.lake'))
    shutil.copyfile(ROOT/'Export.lean',project/'Export.lean')
    for name,cmd in [('build',['lake','build','Checks']),('export',['lake','env','lean','Export.lean'])]:
        p=subprocess.run(cmd,cwd=project,text=True,capture_output=True,timeout=120)
        (out/(name+'.stdout.gz')).write_bytes(gzip.compress(p.stdout.encode(),mtime=0))
        (out/(name+'.stderr.gz')).write_bytes(gzip.compress(p.stderr.encode(),mtime=0))
        assert p.returncode==0,(name,p.returncode)
    expected=gzip.decompress((ROOT/'evidence/expected.jsonl.gz').read_bytes())
    assert p.stdout.encode()==expected,'fresh reference differs from frozen expectations'
    (out/'outcome.json').write_text(json.dumps({'passed':True,'cases':len(p.stdout.splitlines()),'expected_uncompressed_sha256':hashlib.sha256(expected).hexdigest()},indent=2)+'\n')
print('PASS: fresh reference reproduces all 4276 frozen expectations exactly')
