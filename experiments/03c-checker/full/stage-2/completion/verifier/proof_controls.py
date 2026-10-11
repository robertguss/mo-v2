#!/usr/bin/env python3
"""Independent exact-target and proof-policy negative controls; scratch removed."""
from pathlib import Path
import subprocess
import re
import tempfile
import json

HERE = Path(__file__).resolve().parent
LEAN = HERE.parents[2] / 'lean'
ALLOW = {'propext', 'Classical.choice', 'Quot.sound'}
sources = {
    'baseline': 'theorem candidate : Full.Statements.Conditional Full.Demand.accepts := Full.Demand.Soundness.conditional',
    'invalid': 'theorem candidate : Full.Statements.Conditional Full.Demand.accepts := True.intro',
    'placeholder': 'theorem candidate : Full.Statements.Conditional Full.Demand.accepts := by sorry',
    'additional-axiom': 'axiom unsupported : Full.Statements.Conditional Full.Demand.accepts\ntheorem candidate : Full.Statements.Conditional Full.Demand.accepts := unsupported',
}
results = {}
with tempfile.TemporaryDirectory(prefix='conditional-verifier-') as tmp:
    for label, body in sources.items():
        source = 'import Full.Demand.Soundness\nnamespace IndependentControl\n' + body + '\n#print axioms candidate\nend IndependentControl\n'
        (HERE / (label + '.lean.txt')).write_text(source)
        path = Path(tmp) / (label + '.lean')
        path.write_text(source)
        args = ['lake', 'env', 'lean', str(path)]
        proc = subprocess.run(args, cwd=LEAN, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (HERE / (label + '.log')).write_text('$ ' + ' '.join(args) + '\n' + proc.stdout + f'\nEXIT={proc.returncode}\n')
        matches = re.findall(r'depends on axioms: \[([^\]]*)\]', proc.stdout)
        axioms = set(filter(None, map(str.strip, matches[-1].split(',')))) if matches else set()
        if label == 'invalid':
            assert proc.returncode != 0 and 'type mismatch' in proc.stdout.lower()
        else:
            assert proc.returncode == 0 and matches
            assert (axioms <= ALLOW) == (label == 'baseline')
        results[label] = {'exit': proc.returncode, 'axioms': sorted(axioms)}
(HERE / 'proof-controls.json').write_text(json.dumps(results, indent=2) + '\n')
print(json.dumps(results, indent=2))
