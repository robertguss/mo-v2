"""Frozen finite comparison; expectations come only from the accepted Lean model."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import traceback

ROOT=Path(__file__).resolve().parent

def require(ok,why):
    if not ok: raise AssertionError(why)

def walk(memory,root):
    cells={c[0]:c for c in memory};seen=set();values=[]
    require(len(cells)==len(memory),'duplicate cell identity')
    while root is not None:
        require(root not in seen and root in cells,'cycle or dangling holder')
        seen.add(root);c=cells[root]
        require(c[4]=='live','holder points to reserved cell')
        values.append(c[1]);root=c[2]
    return values,seen

def safety(case,o):
    initial=case['initial'];outside=case['outside'];held={}
    outside_values=[walk(initial,r)[0] for r in outside]
    require(o['states'],'missing snapshots')
    for s in o['states']:
        require(s['outside']==outside,'outside roots changed')
        require([walk(s['memory'],r)[0] for r in outside]==outside_values,'outside value changed')
        for ident,name,value,status in s['bindings']:
            if status=='holding':
                require(value[0]=='l','holding non-list')
                contents=walk(s['memory'],value[1])[0]
                require(ident not in held or held[ident]==contents,'held name value changed')
                held[ident]=contents
    last=o['states'][-1];require(last['kind']=='end','missing end')
    require(last['memory']==o['memory'],'end memory inconsistent')
    answer=o['answer'];root=answer[1] if answer[0]=='l' else None
    roots=[root]+outside;reached=set()
    for p in roots: reached.update(walk(o['memory'],p)[1])
    require(reached=={c[0] for c in o['memory']},'unreachable live memory or missing result')
    for a,_,_,count,status in o['memory']:
        actual=roots.count(a)+sum(c[2]==a for c in o['memory'])
        require(status=='live' and count==actual,'final holder count wrong')
    require(not last['aside'],'reservation leaked')
    if answer[0]=='l': require(o['value']==['l',walk(o['memory'],root)[0]],'answer readback wrong')
    else: require(o['value']==answer,'scalar readback wrong')
    require(o['record']==o['log'],'memory record disagrees with rule log')

def normalize(case,o):
    # Fixed initial order, then global creation order. Preserve mapping after free.
    ids={c[0]:i for i,c in enumerate(case['initial'])}
    for kind,a in o['record']:
        if kind=='create':
            require(a not in ids,'logical identity recycled')
            ids[a]=len(ids)
    def ptr(a):
        require(a is None or a in ids,'unknown identity in trace')
        return None if a is None else ids[a]
    def raw(v): return [v[0],ptr(v[1])] if v[0]=='l' else v
    def cells(cs): return sorted([[ptr(a),n,ptr(t),count,status] for a,n,t,count,status in cs])
    def snapshot(s): return dict(kind=s['kind'],memory=cells(s['memory']),
        bindings=[[i,n,raw(v),status] for i,n,v,status in s['bindings']],
        pending=[raw(v) for v in s['pending']],outside=[ptr(a) for a in s['outside']],
        aside=[[b,ptr(a)] for b,a in s['aside']],branch=None if s['branch'] is None else raw(s['branch']))
    return dict(answer=raw(o['answer']),value=o['value'],memory=cells(o['memory']),
        record=[[k,ptr(a)] for k,a in o['record']],log=[[k,ptr(a)] for k,a in o['log']],states=[snapshot(s) for s in o['states']])

def physical(case,result):
    events=result['physical'];live={};seen_fixture=0;logical=[]
    for kind,a,pointer in events:
        require(isinstance(pointer,int) and pointer>0,'missing native address')
        if kind in ('fixture','create'):
            require(a not in live and pointer not in live.values(),'physical cell alias')
            live[a]=pointer
            if kind=='fixture': seen_fixture+=1
        else:
            require(live.get(a)==pointer,'reuse/free changed physical object')
            if kind=='free': del live[a]
            else: require(kind=='write','unknown physical event')
        if kind!='fixture': logical.append([kind,a])
    require(seen_fixture==len(case['initial']),'fixture physical allocation count')
    require(logical==result['outcome']['record'],'physical operations differ from logical record')
    require(set(live)=={c[0] for c in result['outcome']['memory']},'physical live set differs')
    stats=result['alloc']
    require(stats['fixture_cells']==len(case['initial']),'fixture allocation interval wrong')
    require(stats['cell_allocs']==sum(k=='create' for k,a in logical),'physical allocation hidden from logical interval')
    require(stats['cell_frees']==sum(k=='free' for k,a in logical),'physical free hidden from logical interval')
    require(stats['system_allocs']>=stats['cell_allocs'] and stats['system_bytes']>=stats['cell_allocs'],'invalid allocator instrumentation')

def run(source,dest):
    dest=Path(dest);dest.mkdir(parents=True,exist_ok=False)
    source=Path(source).resolve();(dest/'source.rs').write_bytes(source.read_bytes())
    cases=[json.loads(x) for x in gzip.decompress((ROOT/'evidence/expected.jsonl.gz').read_bytes()).decode().splitlines()]
    require(len([c for c in cases if c['id'].startswith('original-')])==28,'original example count')
    require(all(c['depth']<=3 and len(c['initial'])<=3 for c in cases if c['id'].startswith('generated-')),'corpus bounds')
    error=None;checked=0;alloc=[]
    try:
        build=subprocess.run(['rustc','--edition','2024','-D','warnings',str(source),'-o',str(dest/'backend')],capture_output=True,text=True,timeout=60)
        (dest/'build.txt').write_text(build.stdout+build.stderr)
        require(build.returncode==0,'build failed')
        p=subprocess.run([str((dest/'backend').resolve())],input='\n'.join(c['input'] for c in cases)+'\n',capture_output=True,text=True,timeout=60)
        (dest/'stdout.jsonl.gz').write_bytes(gzip.compress(p.stdout.encode(),mtime=0));(dest/'stderr.txt').write_text(p.stderr)
        lines=p.stdout.splitlines()
        require(p.returncode==0,'runtime process failed')
        require(len(lines)==len(cases),'result count mismatch')
        for case,line in zip(cases,lines):
            result=json.loads(line);o=result['outcome']
            try:
                safety(case,o);physical(case,result)
                a,b=normalize(case,o),normalize(case,case['expected'])
                for field in b: require(a[field]==b[field],f'Lean/Rust mismatch: {field}')
            except Exception:
                (dest/'counterexample.json').write_text(json.dumps({'case':case,'actual':result},indent=2)+'\n')
                raise
            checked+=1;alloc.append(result['alloc'])
    except Exception: error=traceback.format_exc()
    finally:
        (dest/'backend').unlink(missing_ok=True)
    summary=dict(passed=error is None,checked=checked,total=len(cases),error=error,source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),allocator_samples=alloc)
    (dest/'outcome.json').write_text(json.dumps(summary,indent=2)+'\n')
    return summary

if __name__=='__main__':
    result=run(ROOT/'backend.rs',sys.argv[1]);print(json.dumps({k:v for k,v in result.items() if k!='allocator_samples'},indent=2));sys.exit(not result['passed'])
