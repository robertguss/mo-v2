"""Diagnostic-only profiling of retained public bytes; never runs a candidate.

Usage: python3.14 profile_terminal.py bounded RETAINED_COLLECTOR_ROOT NEW_OUTPUT
       python3.14 profile_terminal.py terminal RETAINED_APPROVED_ATTEMPT NEW_OUTPUT
Bounded mode replays every row with the frozen verifier. Terminal mode measures
isolated operations, not a semantic verdict: prior incremental state is absent.
"""
import cProfile
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import pstats
import resource
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
spec = importlib.util.spec_from_file_location('ownership_runner', BASE / 'stage-b-ownership-01/run_resources.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)
BINARY = Path('/home/user/rob1333-stage-b-collector-01/target/release/rob1333-stage-b-link')


def save(destination, report):
    (destination / 'report.json').write_text(json.dumps(report, indent=2) + '\n')


def bounded(root, destination, report):
    prior_index = json.loads((BASE / 'stage-b-collector-01/evidence/public/INDEX.json').read_text())
    inputs = {entry['path']: entry for entry in prior_index['sources']}
    report['runs'] = []
    for depth in (10003, 20003, 40003):
        folder = root / f'profiles-01/sum-{depth}'
        stream_path = folder / 'rows.jsonl.gz'
        expected_input = inputs[f'rob1333-stage-b-collector-01/profiles-01/sum-{depth}/rows.jsonl.gz']
        assert runner.sha(stream_path) == expected_input['sha256']
        workload = runner.orchestration.NonTailSum(depth)
        verifier = runner.approved.LargeVerifier(workload, [workload.deepest_step(), workload.transitions()-workload.deepest_step()])
        digest, replies = hashlib.sha256(), hashlib.sha256()
        profiles, boundaries = {}, []
        count = 0
        previous_native_clock = 0
        started = time.perf_counter()
        with gzip.open(stream_path, 'rb') as stream:
            for line in stream:
                digest.update(line)
                start = time.perf_counter()
                row = runner.approved.load(line)
                decode_seconds = time.perf_counter()-start
                phase = row['phase']
                native_clock = row.get('elapsed_ns', previous_native_clock)
                if phase in ('begin', 'advance', 'destroy', 'destroy-again'):
                    key = phase
                    if phase == 'advance':
                        key += '-terminal' if row['step'] == workload.transitions() else '-deepest'
                    profile = profiles.setdefault(key, cProfile.Profile())
                    start = time.perf_counter()
                    reply = profile.runcall(verifier.row, row)
                    check_seconds = time.perf_counter()-start
                    boundaries.append(dict(phase=key, step=row['step'], record_bytes=len(line),
                        snapshot_bytes=len(row['raw']['snapshot'].encode()),
                        decode_seconds=decode_seconds, profiled_check_seconds=check_seconds,
                        native_clock_delta_ns=native_clock-previous_native_clock))
                else:
                    reply = verifier.row(row)
                replies.update(json.dumps(reply, sort_keys=True).encode()+b'\n')
                previous_native_clock = native_clock
                count += 1
        result = verifier.finish()
        elapsed = time.perf_counter()-started
        original = json.loads((folder / 'summary.json').read_text())
        assert original['candidate_executed'] and not original['fixture_stub']
        assert all(result[k] == original[k] for k in result)
        assert digest.hexdigest() == original['streamed_rows_sha256']
        validated = json.loads((BASE / 'stage-b-ownership-01/evidence/report.json').read_text())
        prior = next(r['proposal'] for r in validated['runs'] if r['depth'] == depth)
        assert replies.hexdigest() == prior['replies_sha256'] and count == prior['rows']
        for key, profile in profiles.items():
            profile.dump_stats(str(destination / f'{depth}-{key}.prof'))
            with (destination / f'{depth}-{key}.txt').open('w') as out:
                pstats.Stats(profile, stream=out).sort_stats('cumulative').print_stats(25)
        item = dict(depth=depth, rows=count, diagnostic_seconds=elapsed,
            input=expected_input, boundaries=boundaries, result=result,
            decoded_sha256=digest.hexdigest(), replies_sha256=replies.hexdigest())
        report['runs'].append(item)
        save(destination, report)
        print(json.dumps(dict(depth=depth, rows=count, semantic_replay_matches=True)), flush=True)


def terminal(root, destination, report):
    post = json.loads((root / 'POSTMORTEM.json').read_text())
    committed_post = BASE / 'stage-b-ownership-01/evidence/approved-01/POSTMORTEM.json'
    assert runner.sha(root / 'POSTMORTEM.json') == runner.sha(committed_post)
    source = root / 'million/non-tail-sum/rows.jsonl.gz'
    assert runner.sha(source) == post['compressed_sha256']
    total = post['decoded_inspection']['decoded_bytes']
    length = post['final_retained_record_bytes']+1
    offset = total-length
    report['input'] = dict(compressed_sha256=post['compressed_sha256'], source=str(source),
        decoded_offset=offset, record_bytes=length, decoded_stream_bytes=total)
    # Extract the exact suffix while hashing the complete gzip, in bounded memory.
    digest, record_digest = hashlib.sha256(), hashlib.sha256()
    position = 0
    with tempfile.TemporaryFile() as extracted:
        with gzip.open(source, 'rb') as stream:
            while chunk := stream.read(1024*1024):
                digest.update(chunk)
                start = max(0, offset-position)
                selected = chunk[start:]
                extracted.write(selected)
                record_digest.update(selected)
                position += len(chunk)
        assert position == total and extracted.tell() == length
        assert digest.hexdigest() == post['decoded_inspection']['decoded_bytes_sha256']
        extracted.seek(0)
        raw = extracted.read()
    assert raw.endswith(b'\n') and raw.count(b'\n') == 1
    report['input']['record_sha256'] = record_digest.hexdigest()
    report['measurements'] = []

    def measure(name, function):
        start = time.perf_counter()
        result = function()
        report['measurements'].append(dict(operation=name, seconds=time.perf_counter()-start,
            process_peak_rss_kib=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss))
        save(destination, report)
        print(json.dumps(report['measurements'][-1]), flush=True)
        return result

    row = measure('strict outer record decode', lambda: runner.approved.load(raw))
    assert row['phase'] == 'advance' and row['step'] == 18000014
    del raw
    snapshot = measure('strict inner snapshot decode', lambda: runner.approved.load(row['raw']['snapshot']))
    measure('frozen snapshot_schema', lambda: runner.approved.snapshot_schema(snapshot))
    report['snapshot'] = dict(bytes=len(row['raw']['snapshot'].encode()),
        status=snapshot['status'], event_count=len(snapshot['events']), birth_count=len(snapshot['births']),
        binding_count=len(snapshot['state']['bindings']), control_count=len(snapshot['control']),
        graph_count=len(row['graph']), cleanup_count=len(snapshot['cleanup_events']))
    for field in ('births', 'events'):
        def hash_history():
            value = hashlib.sha256()
            for item in snapshot[field]:
                runner.approved.hash_item(value, item)
            return value.hexdigest()
        report['snapshot'][field+'_recomputed_sha256'] = measure('frozen '+field+' canonical hashing', hash_history)
    report['limitations'] = 'Isolated decode/schema/hash measurements only. No prior incremental digest/state, full-verifier verdict, native execution, cleanup run or inclusive acceptance timing.'


def main(mode, root, destination):
    assert mode in ('bounded', 'terminal')
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(mode=mode, candidate_executed=False, resource_acceptance=False,
        private_access=False, preservation_before=runner.verify(BINARY),
        source_sha256=runner.sha(Path(__file__)), python=sys.version,
        python_sha256=runner.sha(Path(sys.executable)), jit_enabled=sys._jit.is_enabled())
    save(destination, report)
    (bounded if mode == 'bounded' else terminal)(root, destination, report)
    report['preservation_after'] = runner.verify(BINARY)
    assert report['preservation_before'] == report['preservation_after']
    report['completed'] = True
    save(destination, report)
    print(json.dumps(dict(mode=mode, completed=True, resource_acceptance=False)), flush=True)


if __name__ == '__main__':
    main(sys.argv[1], Path(sys.argv[2]).resolve(), Path(sys.argv[3]).resolve())
