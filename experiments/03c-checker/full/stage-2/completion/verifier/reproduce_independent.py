#!/usr/bin/env python3
"""Execute inspected runner with verifier gate fixing missing command import.

Does not modify builder runner/gate/evidence or scientific expectations.
"""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
runner = HERE.parent / 'reproduce.py'
source = runner.read_text()
old = 'shutil.copy2(HERE / "Gate.lean", lean / "DemandGate.lean")'
assert source.count(old) == 1
source = source.replace(old, f'shutil.copy2(Path({str(HERE / "Inventory.lean")!r}), lean / "DemandGate.lean")')
sys.argv = [str(runner), str(HERE / 'independent-reproduction')]
exec(compile(source, str(runner), 'exec'), {'__file__': str(runner), '__name__': '__main__'})
