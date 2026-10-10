# Exact command/evidence record

Commands executed from `experiments/03c-checker/full` unless noted. Reads included BRIEF.md, rank-amendment-01/FREEZE.md, ACCEPTANCE.md, lean/ProofGate.lean, lean/Full/Statements.lean, completion/reproduce.sh and the main proof/contract/dependency modules described in REVIEW.md.

Before and after, identical command loop (outputs inventories-before.log and inventories-after.log):

```sh
for x in stage-1/completion/PROOFS.sha256 stage-1/rank-amendment-01/FREEZE.sha256 stage-1/rank-amendment-01/PREPARATION.sha256 BASELINE.sha256 FREEZE.sha256; do
  echo "COMMAND sha256sum -c $x"
  sha256sum -c "$x"
done
cmp stage-1/completion/verifier/inventories-before.log stage-1/completion/verifier/inventories-after.log
```

From lean/, separately logged with command echo and `echo "EXIT=$?"`:

```sh
lake env lean -o .lake/build/lib/lean/ProofGate.olean ProofGate.lean
lake env leanchecker --fresh ProofGate
lake env lean --version
```

Scratch controls: exact sources and results in mutations.log. From lean/:

```sh
for name in Baseline Invalid Placeholder AdditionalAxiom; do
  echo "COMMAND lake env lean ../stage-1/completion/verifier/$name.lean"
  cat "../stage-1/completion/verifier/$name.lean"
  lake env lean "../stage-1/completion/verifier/$name.lean" > "../stage-1/completion/verifier/$name.log" 2>&1
  status=$?
  cat "../stage-1/completion/verifier/$name.log"
  echo "$name EXIT=$status"
done
```

Exact Python policy audit run from lean/, output axiom-policy.log:

```python
import re,pathlib
root=pathlib.Path('../stage-1/completion/verifier')
allowed={'propext','Classical.choice','Quot.sound'}
def audit(name,count,expected):
 text=(root/name).read_text()
 rows=re.findall(r"'([^']+)' depends on axioms: \[([^]]*)\]",text)
 assert len(rows)==count,(name,len(rows))
 ok=True
 for theorem,raw in rows:
  found={s.strip() for s in raw.split(',') if s.strip()}
  bad=found-allowed; ok &= not bad
  print(name,theorem,'axioms=',sorted(found),'forbidden=',sorted(bad))
 assert ok==expected
 print('PASS expected policy outcome',name,'ACCEPT' if ok else 'REJECT')
audit('gate.log',8,True)
audit('Baseline.log',1,True)
audit('Placeholder.log',1,False)
audit('AdditionalAxiom.log',1,False)
assert 'Type mismatch' in (root/'Invalid.log').read_text()
print('PASS invalid concrete term rejected by elaboration')
```

Integrity inspection commands (output integrity.log, declarations.log, source-scan.log):

```sh
git diff --name-only
rg -n '\b(axiom|sorry|admit|unsafe|partial|opaque|native_decide|implemented_by|extern|csimp|elab|syntax|macro|attribute)\b' lean/Full/Proofs lean/Full/Proofs.lean
rg -n '^(namespace|def|abbrev|theorem f[1-6]|theorem l[12])' lean/Full/Proofs lean/Full/Proofs.lean
```

Exact coverage assertion:

```python
from pathlib import Path
manifest=Path('stage-1/completion/PROOFS.sha256')
listed={line.split(None,1)[1].strip() for line in manifest.read_text().splitlines()}
actual={str(p) for p in Path('lean/Full/Proofs').glob('*.lean')}|{'lean/Full/Proofs.lean'}
print('listed',len(listed),'actual',len(actual),'missing',sorted(actual-listed),'extra',sorted(listed-actual))
assert listed==actual
```

Scratch Lean files removed with `rm stage-1/completion/verifier/{Baseline,Invalid,Placeholder,AdditionalAxiom}.lean` after preserving their sources/output. No mutation was made inside lean/Full/Proofs or any model source.
