"""Verify retained proposal evidence/identities; not a scientific freeze or verdict.

Usage: python3.14 verify.py EXTERNAL_EVIDENCE_DIRECTORY
"""
import json
from pathlib import Path
import subprocess
import sys
import tomllib

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import profile as proposal


def main(root):
    baseline = Path('/home/user/rob1333-stage-b-performance-01/target/release/rob1333-stage-b-link')
    binary = root / 'target/release/rob1333-stage-b-link'
    profiles = json.loads((root / 'profiles-01/report.json').read_text())
    public = json.loads((root / 'public-01/report.json').read_text())
    protocol = json.loads((root / 'protocol-01/report.json').read_text())
    current = proposal.frozen.verify(baseline)
    assert current == profiles['preservation_before'] == profiles['preservation_after']
    assert public['preservation_before'] == public['preservation_after']
    assert proposal.sources() == profiles['source_hashes']
    assert proposal.frozen.sha(binary) == profiles['binary_sha256'] == public['binary_sha256']
    assert public['passed'] and public['private_cases'] == public['million_element_runs'] == 0
    assert protocol['passed'] and protocol['mismatches'] == []
    assert protocol['runner_sha256'] == proposal.frozen.sha(HERE / 'check_protocol.py')
    assert profiles['runner_sha256'] == proposal.frozen.sha(HERE / 'profile.py')
    original_lock = tomllib.loads((HERE.parent / 'stage-b-adaptation-01/link/Cargo.lock').read_text())
    proposed_lock = tomllib.loads((HERE / 'link/Cargo.lock').read_text())
    # The only lock change is the collector's new direct edge to existing serde.
    for package in proposed_lock['package']:
        if package['name'] == 'mo-acceptance-driver':
            package['dependencies'].remove('serde')
    assert proposed_lock == original_lock
    metadata = json.loads(subprocess.check_output([
        'cargo', '+1.98.1', 'metadata', '--format-version=1', '--locked', '--offline',
        '--manifest-path', str(HERE / 'link/Cargo.toml')]))
    serde_id = next(p['id'] for p in metadata['packages'] if p['name'] == 'serde_json')
    features = next(node['features'] for node in metadata['resolve']['nodes'] if node['id'] == serde_id)
    assert features == ['default', 'std'], 'unreviewed serde_json features'
    identity = dict(status='unfrozen proposal', preservation=current,
                    binary_sha256=proposal.frozen.sha(binary), source_hashes=proposal.sources(),
                    serde_json_features=features, registry_dependencies_unchanged=True,
                    reports={name: proposal.frozen.sha(root / name) for name in
                             ['profiles-01/report.json', 'public-01/report.json', 'protocol-01/report.json']},
                    strict_clippy='Same three pre-existing failures in frozen and proposed collectors; see both logs.')
    (root / 'IDENTITY.json').write_text(json.dumps(identity, indent=2) + '\n')
    print(json.dumps(dict(preservation_passed=True, public_passed=True, protocol_passed=True,
                         sources_match_executed_build=True, registry_dependencies_unchanged=True), indent=2))


if __name__ == '__main__':
    main(Path(sys.argv[1]).resolve())
