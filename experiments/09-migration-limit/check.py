"""Bound outstanding native migration workers; same-author verification."""
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


def trial(source, output, force_failure=False):
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
        with tempfile.TemporaryDirectory(prefix='mo-limit-') as tmp:
            tmp = Path(tmp).resolve()
            host = tmp/'host'
            unload = tmp/'unloads'
            loads, hangs = tmp/'loads', tmp/'hangs'
            build(['rustc','--edition','2024','-D','warnings',str(source),'-o',str(host)])
            paths = {v:tmp/f'v{v}.dylib' for v in range(1,13)}

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
                    stderr=err,text=True,env={**os.environ,'MO_UNLOAD_LOG':str(unload),'MO_LOAD_LOG':str(loads),'MO_HANG_LOG':str(hangs)})
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
                for version in range(2,13):
                    flags = ['-DCORRUPT=1'] if version==3 else ['-DABI=99'] if version==4 else ['-DNEVER_RETURN'] if version in (10,11) else []
                    library(version,*flags)

                def count_unload(version):
                    rows = markers()
                    require(all(row.endswith(':0') for row in rows), 'native queue state leaked at unload')
                    return rows.count(f'{version}:0')

                def drained(total):
                    s=wait(control,lambda s: len(s['completed'])==total,'all accepted work completed')
                    ledger(s)
                    return s

                def held_jobs(ids, version):
                    cmd(control,'hold_work')
                    for ident in ids: submit(control,ident,version)
                    return wait(control,lambda s: s['inside'] and s['flight'][1]==ids[0],'held old native job')

                def retire(version):
                    require(cmd(control,f'retire {version}')['status']=='retired','old code retirement refused')
                    s=cmd(control,'snapshot')
                    require(str(paths[version]) not in s['images'],'old image remains')
                    require(count_unload(version)==1,'old module lifetime/count wrong')

                # External observation, not a host-maintained worker counter.
                def threads():
                    r=subprocess.run(['ps','-M','-p',str(process.pid)],capture_output=True,text=True,timeout=3)
                    require(r.returncode==0,'external thread query failed')
                    lines=r.stdout.strip().splitlines()
                    require(lines and lines[0].startswith('USER'), 'unexpected ps output')
                    record(os_threads=len(lines)-1,ps_output=r.stdout)
                    return len(lines)-1

                def settled_threads(target):
                    end=time.monotonic()+3
                    while time.monotonic()<end:
                        n=threads()
                        if n==target: return n
                        time.sleep(.01)
                    raise AssertionError('external thread count did not settle')

                # Round trips ensure all five connection threads exist first.
                for f in [control,*producers]: require(cmd(f,'state')['status']=='ok','connection setup')
                baseline=threads()
                require(baseline==8,'unexpected baseline thread count') # main, worker, watchdog, five clients
                before=held_jobs([1,2,3],1)
                ident=start(control,paths[2],'normal')
                s=wait(control,lambda s: attempt(s,ident)['returned'],'normal migration return')
                require(attempt(s,ident)['status']=='activated' and s['active']==2,'normal migration failed')
                require(s['queue']==before['queue'] and s['layout']==2,'queue migration lost rows')
                submit(producers[0],4,2)
                cmd(control,'release_work');drained(4);retire(1)
                settled_threads(baseline)

                # Invalid and expired-but-returning attempts must also free capacity.
                for version in (3,4):
                    ident=start(control,paths[version],'normal')
                    s=wait(control,lambda s: attempt(s,ident)['returned'],'invalid return')
                    require(attempt(s,ident)['status']=='invalid' and s['active']==2,'invalid migration published')
                    require(count_unload(version)==1,'invalid candidate not unloaded')
                    settled_threads(baseline)
                held=start(control,paths[5],'hold')
                wait(control,lambda s: attempt(s,held)['entered'],'held entry')
                time.sleep(.3)
                s=cmd(control,'snapshot')
                require(attempt(s,held)['status']=='timeout' and not attempt(s,held)['returned'],'held timeout')
                newer=start(control,paths[6],'normal')
                s=wait(control,lambda s: attempt(s,newer)['returned'],'overlapping normal return')
                require(s['active']==6,'second slot unavailable')
                cmd(control,f'release {held}')
                s=wait(control,lambda s: attempt(s,held)['returned'],'expired native return')
                require(attempt(s,held)['discarded'] and s['active']==6,'expired native published')
                require(count_unload(5)==1,'expired native not freed')
                settled_threads(baseline);retire(2)
                for version in (7,8,9):
                    ident=start(control,paths[version],'normal')
                    s=wait(control,lambda s: attempt(s,ident)['returned'],'repeated migration return')
                    require(s['active']==version,'returning slot was not reusable')
                    settled_threads(baseline);retire(version-1)

                # Both permanent hangs are in C, after callback return, not host gates.
                for index,version in enumerate((10,11)):
                    ids=[20+index*10+j for j in range(3)]
                    before=held_jobs(ids,9)
                    ident=start(control,paths[version],'normal')
                    end=time.monotonic()+5
                    while (not hangs.exists() or str(version) not in hangs.read_text().splitlines()) and time.monotonic()<end:
                        time.sleep(.002)
                    require(hangs.exists() and str(version) in hangs.read_text().splitlines(),'native permanent entry not observed')
                    record(native_hangs=hangs.read_text().splitlines(),client_silence_begin=True)
                    time.sleep(.3)
                    s=cmd(control,'snapshot');a=attempt(s,ident)
                    require(a['status']=='timeout' and not a['returned'],'permanent native timeout failed')
                    require(200_000<=a['finished_us']-a['started_us']<=950_000,'permanent deadline missed')
                    require(s['active']==9 and s['frozen']==0 and s['queue']==before['queue'],'old queue not resumed after timeout')
                    require(cmd(control,f'retire {version}')['status']=='blocked','permanent native retired')
                    s=cmd(control,'snapshot')
                    require(str(paths[version]) in s['images'] and count_unload(version)==0,'executing migration unloaded')
                    require(cmd(control,f'release {ident}')['status']=='blocked','native hang has cooperative release')
                    cmd(control,'release_work');drained(7+index*3)
                    settled_threads(baseline+index+1)

                before=cmd(control,'snapshot');before_loads=loads.read_text()
                if force_failure: raise AssertionError('forced failure after two native hangs')
                def burst(index):
                    for _ in range(20):
                        r=cmd(producers[index],f'update {paths[12]} normal')
                        require(r['status']=='resource_limit','excess update not refused at resource limit')
                with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                    list(pool.map(burst,range(4)))
                s=cmd(control,'snapshot')
                require(s['attempts']==before['attempts'],'refusal consumed attempt state')
                require(s['loaded']==before['loaded'] and s['images']==before['images'],'refusal changed loaded images')
                require(loads.read_text()==before_loads,'refused candidate was loaded')
                settled_threads(baseline+2)

                def produce(index):
                    rows=[]
                    for j in range(20):
                        ident=100+index*20+j
                        end=time.monotonic()+5
                        while True:
                            r=cmd(producers[index],f'submit {ident} {ident*7}')
                            if r['status']=='accepted':
                                rows.append([r['seq'],ident,ident*7,9]);break
                            require(r['status']=='busy' and time.monotonic()<end,'producer refused/stalled')
                            time.sleep(.001)
                    return rows
                with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                    for rows in pool.map(produce,range(4)):
                        for row in rows: expected[row[0]]=row
                s=drained(90)
                require(s['active']==9 and s['loaded']==[9,10,11],'active/retained module set changed')
                require(all(a['status']=='timeout' and not a['returned'] for a in s['attempts'][-2:]),'permanent native state changed')
                require(count_unload(10)==count_unload(11)==0,'permanent native unloaded')
                require(cmd(control,'shutdown')['status']=='busy','unsafe shutdown accepted')
                for f in [control,*producers]: require(cmd(f,'state')['active']==9,'persistent connection unavailable')
                settled_threads(baseline+2)
                require(process.poll() is None,'same process not alive')
                record(verified_jobs=90,refused_updates=80,baseline_threads=baseline,saturated_threads=baseline+2,
                       markers=markers(),loads=loads.read_text().splitlines(),native_hangs=hangs.read_text().splitlines(),pid=process.pid,persistent_clients=5)
                (output/'final.json').write_text(json.dumps(s,indent=2)+'\n')
    except Exception:
        error=traceback.format_exc()
    finally:
        for sock,stream in clients:
            stream.close();sock.close()
        if process is not None and process.poll() is None:
            process.kill();process.wait(timeout=5)
        gone=True
        if process is not None:
            try: os.kill(process.pid,0);gone=False
            except ProcessLookupError: pass
        record(cleanup_exit=None if process is None else process.returncode,process_gone=gone)
        if not gone: error=(error or '')+' process survived cleanup'
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
    print('PASS: 3 trials, 270 jobs, 240 excess updates refused, permanent native threads bounded')
    return 0

if __name__=='__main__': sys.exit(main())
