"""Combined native code and native queue migration; same-author verification."""
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
            paths = {v:tmp/f'v{v}.dylib' for v in range(1,10)}

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
                for version in range(2,10):
                    flags = ['-DCORRUPT=1'] if version==3 else ['-DMIGRATE_MS=800'] if version==6 else ['-DABI=99'] if version==8 else ['-DMISSING_STEP'] if version==9 else []
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

                before=held_jobs([1,2,3],1)
                require(before['layout']==1 and len(before['queue'])==2,'initial array queue not exercised')
                first=start(control,paths[2],'normal')
                s=activation(control,first,2)
                require(s['layout']==2 and s['queue']==before['queue'],'native representation migration lost rows')
                require(s['inside'] and s['flight']==before['flight'],'old job not retained across commit')
                submit(producers[0],4,2)
                require(cmd(control,'retire 1')['status']=='blocked','old executing code retired')
                s=cmd(control,'snapshot')
                require(str(paths[1]) in s['images'] and count_unload(1)==0,'old executing module unloaded')
                cmd(control,'release_work')
                drained(4)
                retire(1)

                before=held_jobs([10,11,12],2)
                corrupt=start(control,paths[3],'normal')
                s=wait(control,lambda s: attempt(s,corrupt)['returned'],'corrupt migration return')
                require(attempt(s,corrupt)['status']=='invalid','corrupt migration accepted')
                require(s['active']==2 and s['queue']==before['queue'] and s['frozen']==0,'corrupt refusal changed live queue')
                require(str(paths[3]) not in s['images'] and count_unload(3)==1,'corrupt candidate not destroyed')
                cmd(control,'release_work');drained(7)
                empty=start(control,paths[3],'normal')
                s=wait(control,lambda s: attempt(s,empty)['returned'],'empty corrupt migration')
                require(attempt(s,empty)['status']=='invalid' and s['queue']==[] and s['active']==2,'empty corrupt migration accepted')
                require(count_unload(3)==2,'empty corrupt candidate lifetime')

                before=held_jobs([20,21,22],2)
                stalled=start(control,paths[4],'hold')
                s=wait(control,lambda s: attempt(s,stalled)['entered'],'held migration entry')
                require(s['frozen']==stalled and s['queue']==before['queue'],'migration snapshot not frozen')
                require(cmd(control,'submit 21 147')['status']=='duplicate','duplicate during freeze')
                require(cmd(control,'submit 23 161')['status']=='busy','admission while migrating')
                record(client_silence_begin=True);time.sleep(.3)
                s=cmd(control,'snapshot');a=attempt(s,stalled)
                require(a['status']=='timeout' and not a['returned'],'held migration not timed out')
                require(200_000 <= a['finished_us']-a['started_us'] <= 950_000,'held migration deadline')
                terminal=(a['status'],a['finished_us'])
                require(s['frozen']==0 and s['queue']==before['queue'],'old queue not resumed after timeout')
                require(cmd(control,'retire 4')['status']=='blocked','executing migration retired')
                s=cmd(control,'snapshot')
                require(str(paths[4]) in s['images'] and count_unload(4)==0,'executing migration unloaded')
                cmd(control,'step_work')
                s=wait(control,lambda s: s['inside'] and s['flight'][1]==21,'old queue dequeues after timeout')
                require(s['completed'][-1][1]==20 and not attempt(s,stalled)['returned'],'old queue did not resume while migration held')
                submit(producers[0],23,2)
                newer=start(control,paths[5],'normal')
                s=activation(control,newer,5)
                submit(producers[1],24,5)
                before=cmd(control,'snapshot')
                require(not attempt(before,stalled)['returned'],'held migration already returned')
                cmd(control,f'release {stalled}')
                s=wait(control,lambda s: attempt(s,stalled)['returned'],'late held migration')
                require(s['active']==5 and s['queue']==before['queue'] and s['frozen']==0,'stale migration changed newer authority')
                require((attempt(s,stalled)['status'],attempt(s,stalled)['finished_us'])==terminal and attempt(s,stalled)['discarded'],'late terminal rewritten')
                require(str(paths[4]) not in s['images'] and count_unload(4)==1,'late candidate disposal')
                cmd(control,'release_work');drained(12);retire(2)

                before=held_jobs([30,31,32],5)
                sleeping=start(control,paths[6],'normal')
                wait(control,lambda s: attempt(s,sleeping)['entered'],'native sleeping migration')
                record(client_silence_begin=True);time.sleep(.3)
                s=cmd(control,'snapshot');a=attempt(s,sleeping)
                require(a['status']=='timeout' and not a['returned'],'native sleep migration timeout')
                require(200_000 <= a['finished_us']-a['started_us'] <= 950_000,'sleep migration deadline')
                terminal=(a['status'],a['finished_us'])
                require(s['queue']==before['queue'] and s['frozen']==0,'sleep timeout damaged queue')
                cmd(control,'step_work')
                s=wait(control,lambda s: s['inside'] and s['flight'][1]==31,'old queue dequeues after native-sleep timeout')
                require(s['completed'][-1][1]==30 and not attempt(s,sleeping)['returned'],'native sleep stopped old-queue progress')
                submit(producers[0],33,5)
                newest=start(control,paths[7],'normal')
                s=activation(control,newest,7)
                require(not attempt(s,sleeping)['returned'],'new migration waited for expired sleep')
                submit(producers[1],34,7)
                before=cmd(control,'snapshot')
                s=wait(control,lambda s: attempt(s,sleeping)['returned'],'late sleeping migration')
                require(s['active']==7 and s['queue']==before['queue'] and s['frozen']==0,'sleeping stale migration published')
                require((attempt(s,sleeping)['status'],attempt(s,sleeping)['finished_us'])==terminal and attempt(s,sleeping)['discarded'],'sleep terminal rewritten')
                require(str(paths[6]) not in s['images'] and count_unload(6)==1,'sleep candidate disposal')
                cmd(control,'release_work');drained(17);retire(5)

                before=cmd(control,'snapshot')
                for path in (paths[8],paths[9],tmp/'absent.dylib'):
                    bad=start(control,path,'normal')
                    s=wait(control,lambda s: attempt(s,bad)['returned'],'incompatible staging')
                    a=attempt(s,bad)
                    require(a['status']=='invalid' and a['started_us'] is None and not a['entered'],'bad interface staged')
                    require(s['active']==7 and s['accepted']==before['accepted'] and s['completed']==before['completed'],'bad staging changed authority')
                require(s['loaded']==[7],'unused modules remain')

                def produce(index):
                    rows=[]
                    for j in range(20):
                        ident=100+index*20+j
                        end=time.monotonic()+5
                        while True:
                            r=cmd(producers[index],f'submit {ident} {ident*7}')
                            if r['status']=='accepted':
                                rows.append([r['seq'],ident,ident*7,7]);break
                            require(r['status']=='busy' and time.monotonic()<end,'producer refused/stalled')
                            time.sleep(.001)
                    return rows
                with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                    for rows in pool.map(produce,range(4)):
                        for row in rows: expected[row[0]]=row
                s=wait(control,lambda s: len(s['completed'])==97,'final work')
                ledger(s)
                require(s['layout']==2 and count_unload(7)==0,'active queue/module lifetime')
                require(process.poll() is None,'same PID not alive')
                record(verified_jobs=97,markers=markers(),pid=process.pid,persistent_clients=5)
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
    print('PASS: 3 trials, 291 jobs, actual native state migration, corruption refusal and late disposal')
    return 0

if __name__=='__main__': sys.exit(main())
