"""Owner-approved staged boundary, no retries; same-author verification."""
import concurrent.futures
import gzip
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


def require(value, message):
    if not value:
        raise AssertionError(message)


def trial(source, output):
    output.mkdir(parents=True, exist_ok=False)
    events, clients, expected = [], [], {}
    mutex = threading.Lock()
    origin = time.monotonic()
    process = None
    error = None

    def record(**fields):
        with mutex:
            events.append(dict(t=time.monotonic()-origin, **fields))

    def build(args):
        r = subprocess.run(args, text=True, capture_output=True, timeout=30)
        record(build=args, returncode=r.returncode, stdout=r.stdout, stderr=r.stderr)
        require(r.returncode == 0, 'build failed')

    def connect(port):
        s = socket.create_connection(('127.0.0.1', port), timeout=2)
        f = s.makefile('rwb', buffering=0)
        clients.append((s, f))
        return f

    def cmd(f, text):
        begin = time.monotonic()
        f.write((text+'\n').encode())
        response = json.loads(f.readline())
        record(command=text, response=response, duration_ms=(time.monotonic()-begin)*1000)
        return response

    def wait(f, predicate, label, state=False):
        end = time.monotonic()+5
        while time.monotonic() < end:
            s = cmd(f, 'state' if state else 'snapshot')
            if predicate(s):
                return s
            time.sleep(.002)
        raise AssertionError('timeout: '+label)

    def attempt(s, ident):
        return s['attempts'][ident-1]

    def start(f, path, mode):
        r = cmd(f, f'update {path} {mode}')
        require(r['status'] == 'started', 'update refused')
        return r['attempt']

    def activation(f, ident, version):
        s = wait(f, lambda s: attempt(s, ident)['status'] in ('activated', 'timeout', 'invalid'), 'activation')
        a = attempt(s, ident)
        require(a['status'] == 'activated' and s['active'] == version, 'new activation failed')
        require(a['finished_us'] < a['deadline_us'], 'activation after deadline')
        return s

    def submit(f, ident, version):
        r = cmd(f, f'submit {ident} {ident*7}')
        require(r['status'] == 'accepted', 'admission blocked during preparation')
        expected[r['seq']] = [r['seq'], ident, ident*7, version]

    def ledger(s):
        require(s['accepted'] == [expected[i] for i in sorted(expected)], 'acknowledged work lost/changed')
        require(len(s['completed']) == len(expected), 'missing/duplicate completion')
        require(not s['queue'] and s['flight'] is None, 'unfinished work')
        for row, accepted in zip(s['completed'], s['accepted']):
            require(row[:4] == accepted, 'FIFO or pinned-version mismatch')
            x, version = row[2:4]
            first = x+1 if version == 1 else 3*x+7
            result = first+1 if version == 1 else 3*first+7
            require(row[4:] == [first, result], 'mixed native job')

    try:
        with tempfile.TemporaryDirectory(prefix='mo-stalled-') as tmp:
            tmp = Path(tmp).resolve()
            host = tmp/'host'
            unload = tmp/'unloads'
            build(['rustc','--edition','2024','-D','warnings',str(source),'-o',str(host)])
            paths = {v:tmp/f'v{v}.dylib' for v in range(1,9)}

            def library(version, *flags):
                path = paths[version]
                build(['clang','-dynamiclib','-O0','-Wall','-Wextra','-Werror',f'-DVERSION={version}',
                       *flags,str(ROOT/'module.c'),'-o',str(path)])
                record(artifact=path.name, sha256=hashlib.sha256(path.read_bytes()).hexdigest())

            def markers():
                return unload.read_text().splitlines() if unload.exists() else []

            library(1)
            with (output/'server.stderr').open('w') as err:
                process = subprocess.Popen([str(host),str(paths[1])],stdout=subprocess.PIPE,
                    stderr=err,text=True,env={**os.environ,'MO_UNLOAD_LOG':str(unload)})
                # The outer finally owns teardown before this first fallible wait.
                with selectors.DefaultSelector() as sel:
                    sel.register(process.stdout,selectors.EVENT_READ)
                    require(sel.select(5),'startup timeout')
                line = process.stdout.readline().strip()
                require(line.startswith('LISTEN 127.0.0.1:'),'server announcement')
                record(pid=process.pid, announcement=line, v2_exists=paths[2].exists())
                require(not paths[2].exists(),'candidate compiled before startup')
                port = int(line.rsplit(':',1)[1])
                control = connect(port)
                producers = [connect(port) for _ in range(4)]
                for version in range(2,7):
                    library(version,*(['-DSTAGE_MS=400'] if version==2 else ['-DPREPARE_MS=800'] if version==4 else ['-DREADY=99'] if version==6 else []))

                library(7, '-DABI=99')
                library(8, '-DMISSING_STEP')
                held = start(control,paths[2],'hold')
                s = cmd(control, 'state')
                a = attempt(s, held)
                require(a['status'] == 'staging' and a['started_us'] is None and a['deadline_us'] is None, 'clock armed during staging')
                for i,f in enumerate(producers): submit(f,i+40,1)
                s = wait(control,lambda s: len(s['completed'])==4,'work during slow staging',state=True)
                require(attempt(s,held)['status']=='staging' and not attempt(s,held)['entered'], 'staging progress not demonstrated')
                require(attempt(s,held)['started_us'] is None, 'clock armed before staging completed')
                s = wait(control,lambda s: attempt(s,held)['entered'],'held native entry')
                require(str(paths[2]) in s['images'],'candidate not mapped')
                a = attempt(s,held)
                require(a['started_us']-a['requested_us'] >= 400_000, 'slow staging not measured')
                require(a['deadline_us']-a['started_us'] == 200_000, 'wrong preparation budget')
                for i,f in enumerate(producers): submit(f,i+1,1)
                wait(control,lambda s: len(s['completed'])==8,'service while held')
                record(client_silence_begin=True)
                time.sleep(.3)
                s = cmd(control,'snapshot')
                a = attempt(s,held)
                require(a['status']=='timeout','watchdog did not expire held preparation')
                require(a['entered'] and not a['returned'],'held code returned prematurely')
                require(200_000 <= a['finished_us']-a['started_us'] <= 950_000,'timeout budget violated')
                held_terminal = (a['status'],a['finished_us'])
                require(cmd(control,'retire 2')['status']=='blocked','premature candidate retirement')
                s=cmd(control,'snapshot')
                require(str(paths[2]) in s['images'] and '2' not in markers(),'candidate unloaded while preparing')
                new = start(control,paths[3],'normal')
                activation(control,new,3)
                for i,f in enumerate(producers): submit(f,i+10,3)
                s=wait(control,lambda s: len(s['completed'])==12,'new-version progress before old return')
                ledger(s)
                require(not attempt(s,held)['returned'],'old returned before newer activation')
                require(cmd(control,f'release {held}')['status']=='ok','release')
                s=wait(control,lambda s: attempt(s,held)['returned'],'stale return')
                require(s['active']==3,'stale candidate overwrote newer activation')
                require((attempt(s,held)['status'],attempt(s,held)['finished_us'])==held_terminal,'terminal outcome rewritten')
                require(attempt(s,held)['discarded'],'late return not fenced')
                require(str(paths[2]) not in s['images'] and markers().count('2')==1,'late candidate not unloaded after return')
                ledger(s)

                sleeping=start(control,paths[4],'normal')
                wait(control,lambda s: attempt(s,sleeping)['entered'],'native sleep entry')
                for i,f in enumerate(producers): submit(f,i+20,3)
                wait(control,lambda s: len(s['completed'])==16,'service during native sleep')
                record(client_silence_begin=True)
                time.sleep(.3)
                s=cmd(control,'snapshot')
                a=attempt(s,sleeping)
                require(a['status']=='timeout' and not a['returned'],'native blocking timeout failed')
                require(200_000 <= a['finished_us']-a['started_us'] <= 950_000,'native timeout budget violated')
                sleep_terminal=(a['status'],a['finished_us'])
                require(str(paths[4]) in s['images'] and '4' not in markers(),'sleeping native code unloaded')
                newest=start(control,paths[5],'normal')
                s=activation(control,newest,5)
                require(not attempt(s,sleeping)['returned'],'new activation waited for stale native sleep')
                for i,f in enumerate(producers): submit(f,i+30,5)
                s=wait(control,lambda s: attempt(s,sleeping)['returned'],'native sleep return')
                require(s['active']==5 and attempt(s,sleeping)['discarded'],'stale sleeping candidate published')
                require((attempt(s,sleeping)['status'],attempt(s,sleeping)['finished_us'])==sleep_terminal,'sleep terminal rewritten')
                require(str(paths[4]) not in s['images'] and markers().count('4')==1,'sleep candidate not unloaded')
                wrong=start(control,paths[6],'normal')
                s=wait(control,lambda s: attempt(s,wrong)['returned'],'invalid preparation return')
                require(attempt(s,wrong)['status']=='invalid' and s['active']==5,'bad readiness accepted')
                require(str(paths[6]) not in s['images'] and markers().count('6')==1,'bad preparation retained')
                wait(control,lambda s: len(s['completed'])==20,'pre-load completions')
                before = cmd(control,'snapshot')
                for path in (tmp/'absent.dylib',paths[7],paths[8]):
                    rejected=start(control,path,'normal')
                    s=wait(control,lambda s: attempt(s,rejected)['returned'],'rejected staging')
                    a=attempt(s,rejected)
                    require(a['status']=='invalid' and not a['entered'], 'incompatible staging accepted')
                    require(a['started_us'] is None and a['deadline_us'] is None, 'rejected staging armed clock')
                    require(s['active']==5 and s['accepted']==before['accepted'] and s['completed']==before['completed'], 'staging refusal changed work')
                for version in (1,3):
                    require(cmd(control,f'retire {version}')['status']=='retired','old active-version retirement')
                s=cmd(control,'snapshot')
                require(s['loaded']==[5],'stale native owners remain')
                require(all(str(paths[v]) not in s['images'] for v in (1,2,3,4,6)),'stale native image remains')

                def produce(index):
                    rows=[]
                    for j in range(20):
                        ident=100+index*20+j
                        end=time.monotonic()+5
                        while True:
                            r=cmd(producers[index],f'submit {ident} {ident*7}')
                            if r['status']=='accepted':
                                rows.append([r['seq'],ident,ident*7,5]);break
                            require(r['status']=='busy' and time.monotonic()<end,'producer refused/stalled')
                            time.sleep(.001)
                    return rows
                with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                    for rows in pool.map(produce,range(4)):
                        for row in rows: expected[row[0]]=row
                s=wait(control,lambda s: len(s['completed'])==100,'final work')
                ledger(s)
                require(process.poll() is None,'same PID not alive')
                record(verified_jobs=100,markers=markers(),pid=process.pid,persistent_clients=5)
                (output/'final.json').write_text(json.dumps(s,indent=2)+'\n')
                require(cmd(control,'shutdown')['status']=='ok','shutdown')
                require(process.wait(timeout=5)==0,'server exit')
    except Exception:
        error=traceback.format_exc()
    finally:
        for sock,stream in clients:
            stream.close();sock.close()
        if process is not None and process.poll() is None:
            process.kill();process.wait(timeout=5)
        record(cleanup_exit=None if process is None else process.returncode)
        (output/'trace.json.gz').write_bytes(gzip.compress(json.dumps(events,indent=2).encode(),mtime=0))
        (output/'outcome.json').write_text(json.dumps({'passed':error is None,'error':error},indent=2)+'\n')
    return error


def main():
    dest=Path(sys.argv[1]).resolve();dest.mkdir(parents=True,exist_ok=False)
    (dest/'environment.json').write_text(json.dumps({'platform':platform.platform(),'python':sys.version,
        'sources':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'host.rs',ROOT/'module.c',ROOT/'SPEC.md',Path(__file__)]}},indent=2)+'\n')
    for i in range(3):
        error=trial(ROOT/'host.rs',dest/f'trial-{i+1}')
        if error: print(error);return 1
    print('PASS: 3 no-retry trials, 300 jobs, slow staging progress, preparation deadlines, late disposal')
    return 0

if __name__=='__main__': sys.exit(main())
