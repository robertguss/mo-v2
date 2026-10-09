"""Package one explicit public evidence root with the established volume format.

Usage: python3 package_evidence.py PUBLIC_ROOT NEW_PACKAGE NEW_RESTORE
The root must contain only public evidence, no runtimes, caches or private data.
Archive readback and a full independent restore are required; originals stay put.
"""
import importlib.util
from pathlib import Path
import sys

source, destination, restored = (Path(arg).resolve() for arg in sys.argv[1:])
assert source.is_dir() and source.name.startswith('rob1333-stage-b-')
assert not destination.is_relative_to(source) and not restored.is_relative_to(source)
for path in source.rglob('*'):
    assert not path.is_symlink(), path
    assert not any(part in ('target', 'baseline-target', '__pycache__', '.git')
                   or 'private' in part.lower() for part in path.relative_to(source).parts), path
    assert path.is_dir() or path.is_file(), path
script = Path(__file__).resolve().parent.parent / 'stage-b-adaptation-01/package_continuation.py'
spec = importlib.util.spec_from_file_location('public_packaging', script)
packaging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packaging)
packaging.PERFORMANCE = source
packaging.main(destination, performance=True)
packaging.restore(destination, restored)
