"""Reuse the established lossless public packager with an explicit new allowlist.

Usage: pinned-python package.py validation|result NEW_RESTORE_DIRECTORY
Originals stay external; target/cache/private paths are never included.
"""
import importlib.util
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('public_packager', HERE.parent / 'stage-b-adaptation-01/package_continuation.py')
pack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pack)

if __name__ == '__main__':
    kind, destination = sys.argv[1:]
    roots = {'validation': Path('/home/user/rob1333-stage-b-timing-validation-01'),
             'result': Path('/home/user/rob1333-stage-b-timing-approved-01')}
    # This changes only the packaging allowlist, never any frozen predicate.
    pack.PERFORMANCE = roots[kind]
    package = HERE / 'evidence' / kind / 'public'
    pack.main(package, performance=True)
    pack.restore(package, Path(destination).resolve())
