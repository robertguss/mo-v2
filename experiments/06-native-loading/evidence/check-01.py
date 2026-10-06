"""Same-author verification; macOS, Python stdlib, rustc and clang only."""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import platform
import selectors
import socket
import subprocess
import sys
import tempfile
import threading
import time
import traceback

ROOT = Path(__file__).resolve().parent


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def run_trial(source, output):
    output.mkdir(parents=True, exist_ok=False)
    trace = []
    lock = threading.Lock()
    sockets = []
    process = None
    start = time.monotonic()

    def event(**fields):
        with lock:
            trace.append(dict(t=time.monotonic() - start, **fields))

    def build(args):
        p = subprocess.run(args, capture_output=True, text=True, timeout=30)
        event(build=args, returncode=p.returncode, stdout=p.stdout, stderr=p.stderr)
        require(p.returncode == 0, 'build failed')

    def connect(port):
        s = socket.create_connection(('127.0.0.1', port), timeout=2)
        f = s.makefile('rwb', buffering=0)
        sockets.append((s, f))
        return f

    def command(f, text):
        f.write((text + '\n').encode())
        result = json.loads(f.readline())
        event(command=text, response=result)
        return result

    def wait(f, predicate, label):
        end = time.monotonic() + 5
        while time.monotonic() < end:
            s = command(f, 'snapshot')
            if predicate(s):
                return s
            time.sleep(.002)
        raise AssertionError('timeout: ' + label)

    def check_ledger(s, expected):
        require(s['accepted'] == [expected[i] for i in sorted(expected)], 'acknowledged work changed')
        require(len(s['completed']) == len(expected), 'completion count')
        require(not s['queue'] and s['flight'] is None, 'unfinished work')
        for row, accepted in zip(s['completed'], s['accepted']):
            require(row[:4] == accepted, 'FIFO/payload/version mismatch')
            x, version = row[2:4]
            first = x + 1 if version == 1 else 3*x + 7
            result = first + 1 if version == 1 else 3*first + 7
            require(row[4:] == [first, result], 'mixed or wrong code behavior')

    error = None
    try:
        with tempfile.TemporaryDirectory(prefix='mo-native-') as tmp:
            tmp = Path(tmp)
            host, v1, v2 = [tmp / x for x in ('host', 'v1.dylib', 'v2.dylib')]
            unload = tmp / 'unloaded.txt'
            build(['rustc', '--edition', '2024', '-D', 'warnings', str(source), '-o', str(host)])

            def library(path, *flags):
                build(['clang', '-dynamiclib', '-O0', '-Wall', '-Wextra', '-Werror',
                       *flags, str(ROOT / 'module.c'), '-o', str(path)])
                event(artifact=path.name, sha256=hashlib.sha256(path.read_bytes()).hexdigest())

            library(v1, '-DVERSION=1')
            require(not v2.exists(), 'v2 exists before server start')
            with (output / 'server.stderr').open('w') as err:
                process = subprocess.Popen([str(host), str(v1)], stdout=subprocess.PIPE,
                                           stderr=err, text=True, env={**os.environ, 'MO_UNLOAD_LOG': str(unload)})
                # Cleanup is registered by the outer finally before any startup wait.
                with selectors.DefaultSelector() as sel:
                    sel.register(process.stdout, selectors.EVENT_READ)
                    require(sel.select(5), 'server startup timeout')
                announcement = process.stdout.readline().strip()
                event(started_pid=process.pid, announcement=announcement, v2_exists=v2.exists())
                require(announcement.startswith('LISTEN 127.0.0.1:'), 'server announcement')
                port = int(announcement.rsplit(':', 1)[1])
                client = connect(port)
                producers = [connect(port) for _ in range(4)]
                expected = {}
                require(command(client, 'hold_work')['status'] == 'ok', 'hold')
                for ident in (1, 2):
                    r = command(client, f'submit {ident} 10')
                    require(r['status'] == 'accepted', 'old admission')
                    expected[r['seq']] = [r['seq'], ident, 10, 1]
                old = wait(client, lambda s: s['inside'] and s['flight'][1] == 1, 'inside v1')
                require(len(old['queue']) == 1, 'old queued reference absent')
                require(str(v1) in old['images'], 'v1 not in real image inventory')
                # Actual later compile, after PID and persistent clients already exist.
                library(v2, '-DVERSION=2')
                bad = tmp / 'bad.dylib'
                missing = tmp / 'missing.dylib'
                malformed = tmp / 'malformed.dylib'
                library(bad, '-DVERSION=3', '-DABI=99')
                library(missing, '-DVERSION=4', '-DMISSING_STEP')
                malformed.write_text('not a Mach-O library')
                for path in (tmp/'absent.dylib', malformed, bad, missing, v1):
                    r = command(client, f'update {path}')
                    require(r['status'] == 'invalid', 'incompatible artifact accepted')
                    s = command(client, 'snapshot')
                    require(s['active'] == 1 and s['accepted'] == old['accepted'], 'refusal changed authority/work')
                    require(s['queue'] == old['queue'] and s['flight'] == old['flight'], 'refusal changed pending work')
                    require(s['loaded'] == [1], 'rejected module retained')
                require(command(client, f'update {v2}')['status'] == 'activated', 'activation')
                s = command(client, 'snapshot')
                require(s['inside'] and s['active'] == 2 and s['loaded'] == [1, 2], 'old/new overlap')
                require(str(v1) in s['images'] and str(v2) in s['images'], 'both native images not loaded')
                for version in (1, 2):
                    require(command(client, f'retire {version}')['status'] == 'blocked', 'premature retirement allowed')
                require(command(client, 'submit 1 10')['status'] == 'duplicate', 'dedup across activation')
                require(command(client, 'submit 1 11')['status'] == 'conflict', 'conflicting retry')
                r = command(producers[0], 'submit 3 10')
                require(r['status'] == 'accepted', 'new admission while old held')
                expected[r['seq']] = [r['seq'], 3, 10, 2]
                require(command(client, 'step_work')['status'] == 'ok', 'one callback release')
                s = wait(client, lambda s: s['inside'] and s['flight'][1] == 2, 'queued old job still pinned')
                require(s['completed'][0] == [1, 1, 10, 1, 11, 12], 'mixed or wrong code behavior')
                require(command(client, 'retire 1')['status'] == 'blocked', 'queued old lifetime lost')
                require('1' not in unload.read_text().splitlines(), 'old destructor ran while code referenced')
                require(command(client, 'shutdown')['status'] == 'busy', 'shutdown lost acknowledged work')
                command(client, 'release_work')
                s = wait(client, lambda s: len(s['completed']) == 3, 'initial completions')
                check_ledger(s, expected)
                require(command(client, 'retire 1')['status'] == 'retired', 'old retirement')
                s = command(client, 'snapshot')
                require(s['loaded'] == [2], 'old owner remains')
                require(str(v1) not in s['images'], 'old image not unloaded')
                require(unload.read_text().splitlines().count('1') == 1, 'missing/duplicate old destructor')
                require(command(client, 'retire 1')['status'] == 'missing', 'double retirement')
                require(command(client, f'update {v1}')['status'] == 'invalid', 'old version reacquired')
                require(command(client, f'update {v2}')['status'] == 'invalid', 'same version reactivated')

                def produce(index):
                    rows = []
                    for j in range(20):
                        ident = 100 + index*20 + j
                        payload = ident * 7
                        deadline = time.monotonic() + 5
                        while True:
                            r = command(producers[index], f'submit {ident} {payload}')
                            if r['status'] == 'accepted':
                                rows.append([r['seq'], ident, payload, 2])
                                break
                            require(r['status'] == 'busy' and time.monotonic() < deadline, 'producer refused/stalled')
                            time.sleep(.001)
                    return rows

                with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                    for rows in pool.map(produce, range(4)):
                        for row in rows:
                            expected[row[0]] = row
                s = wait(client, lambda s: len(s['completed']) == 83, 'all completions')
                check_ledger(s, expected)
                require(str(v1) not in s['images'] and str(v2) in s['images'], 'post-retirement images')
                require(process.poll() is None, 'service PID exited')
                (output / 'final.json').write_text(json.dumps(s, indent=2) + '\n')
                event(verified_jobs=83, unchanged_pid=process.pid, persistent_clients=5,
                      unload_log=unload.read_text().splitlines())
                require(command(client, 'shutdown')['status'] == 'ok', 'shutdown')
                require(process.wait(timeout=5) == 0, 'server exit')
    except Exception:
        error = traceback.format_exc()
    finally:
        for sock, stream in sockets:
            stream.close()
            sock.close()
        if process is not None and process.poll() is None:
            process.kill()
            process.wait(timeout=5)
        event(cleanup_exit=None if process is None else process.returncode)
        (output / 'trace.json').write_text(json.dumps(trace, indent=2) + '\n')
        (output / 'outcome.json').write_text(json.dumps({'passed': error is None, 'error': error}, indent=2) + '\n')
    return error


def main():
    dest = Path(sys.argv[1]).resolve()
    dest.mkdir(parents=True, exist_ok=False)
    (dest / 'environment.json').write_text(json.dumps({'platform': platform.platform(), 'python': sys.version,
        'sources': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'host.rs', ROOT/'module.c', ROOT/'SPEC.md', Path(__file__)]}}, indent=2)+'\n')
    for i in range(3):
        error = run_trial(ROOT/'host.rs', dest/f'trial-{i+1}')
        if error:
            print(error)
            return 1
    print('PASS: three trials, 249 jobs, late compilation, five persistent clients per trial, real unloading')
    return 0


if __name__ == '__main__':
    sys.exit(main())
