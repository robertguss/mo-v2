"""Exact integer reference and frozen correctness/measurement expectations."""
import hashlib
import json
from pathlib import Path
import random
import re
import subprocess
import sys
import traceback

ROOT=Path(__file__).resolve().parent
LOW,HIGH=-(1<<63),(1<<63)-1

def require(ok,msg):
    if not ok: raise AssertionError(msg)

def wrap(x): return (x+(1<<63))%(1<<64)-(1<<63)
def quot(a,b): return (abs(a)//abs(b))*(-1 if (a<0)!=(b<0) else 1)

def expected(line):
    p,op,*args=line.split()
    try:
        vals=[];tags=[]
        for a in args:
            tag='b' if p=='big' else 'f'
            if p=='explicit':
                if not a.startswith(('f:','b:')): return 'err type_required'
                tag,a=a.split(':',1)
            if a=='~': a=''
            if re.fullmatch('[+-]?[0-9]+',a) is None: return 'err invalid_literal'
            x=int(a)
            if tag=='f' and not LOW<=x<=HIGH: return 'err range'
            vals.append(x);tags.append(tag)
        a=vals[0];tag=tags[0]
        if op=='asfixed':
            if p!='explicit': return 'err invalid_op'
            if not LOW<=a<=HIGH: return 'err narrowing'
            return f'ok f:{a}'
        if op=='asbig':
            if p!='explicit': return 'err invalid_op'
            return f'ok b:{a}'
        if len(set(tags))>1: return 'err type_mismatch'
        def apply(op,a,b=0):
            if op in ('div','rem'):
                if b==0: raise ValueError('divide_by_zero')
                if tag=='f' and a==LOW and b==-1:
                    if p!='wrapping': raise ValueError('overflow')
                    return LOW if op=='div' else 0
                q=quot(a,b);v=q if op=='div' else a-q*b
            else: v={'add':lambda:a+b,'sub':lambda:a-b,'mul':lambda:a*b,'neg':lambda:-a}[op]()
            if tag=='f':
                if p=='wrapping': v=wrap(v)
                elif not LOW<=v<=HIGH: raise ValueError('overflow')
            return v
        if op=='parse': r=a
        elif op=='roundtrip': r=apply('sub',apply('add',a,1),1)
        elif op=='cancel': r=apply('div',apply('mul',a,vals[1]),vals[1])
        else: r=apply(op,a,vals[1] if len(vals)>1 else 0)
        return 'ok '+(tag+':' if p=='explicit' else '')+str(r)
    except ValueError as e: return 'err '+str(e)

def cases():
    ns=[LOW-1,LOW,LOW+1,-(1<<32),-(1<<31),-7,-1,0,1,3,7,(1<<31)-1,1<<31,(1<<32)-1,1<<32,HIGH-1,HIGH,HIGH+1,(1<<127)+17,(1<<1023)+17]
    lines=[]
    for p,tag in [('checked',''),('wrapping',''),('big',''),('explicit','f:'),('explicit','b:')]:
        for a in ns:
            for op in ('parse','neg','roundtrip'): lines.append(f'{p} {op} {tag}{a}')
            for b in ns:
                for op in ('add','sub','mul','div','rem','cancel'): lines.append(f'{p} {op} {tag}{a} {tag}{b}')
        for a in ['~','+','-','1.2','1e3','1_000','--1','abc','+0','-0','00012','+12']:
            lines.append(f'{p} parse {tag}{a}')
    for a in ns:
        for tag in ['f','b']:
            for op in ['asfixed','asbig']: lines.append(f'explicit {op} {tag}:{a}')
        for op in ['add','sub','mul','div','rem','cancel']: lines.append(f'explicit {op} f:1 b:{a}')
    lines+=['explicit add 1 2','explicit add f:1 2','checked asbig 1']
    return [{'input':s,'expected':expected(s)} for s in lines]

def correctness(binary,dest):
    dest=Path(dest);dest.mkdir(parents=True,exist_ok=False)
    corpus=json.loads((ROOT/'expected.json').read_text())
    p=subprocess.run([str(Path(binary).resolve()),'cases'],input='\n'.join(c['input'] for c in corpus)+'\n',text=True,capture_output=True,timeout=30)
    (dest/'stdout.txt').write_text(p.stdout);(dest/'stderr.txt').write_text(p.stderr)
    error=None;checked=0
    try:
        require(p.returncode==0,'case process failed')
        lines=p.stdout.splitlines();require(len(lines)==len(corpus),'case count mismatch')
        for c,a in zip(corpus,lines):
            if a!=c['expected']:
                (dest/'counterexample.json').write_text(json.dumps(dict(c,actual=a),indent=2)+'\n')
                raise AssertionError(f"policy mismatch: {c['input']}: expected {c['expected']}, got {a}")
            checked+=1
    except Exception: error=traceback.format_exc()
    out=dict(passed=error is None,checked=checked,total=len(corpus),error=error)
    (dest/'outcome.json').write_text(json.dumps(out,indent=2)+'\n');return out

def bench_expected(work,n):
    if work=='total': return sum((i%1000)+1 for i in range(n))
    if work=='parse': return sum(i%1000 for i in range(n))
    if work.startswith('wide'): return n*((1<<(int(work[4:])-1))+17)
    x=1
    for _ in range(n): x=(x*1664525+1013904223)%1000003
    return x

def measure(timing,instrumented,dest):
    dest=Path(dest);dest.mkdir(parents=True,exist_ok=False)
    combos=[(p,w,n) for p in ['checked','wrapping','big','explicit-fixed','explicit-big'] for w in ['total','parse','counter','wide128','wide1024'] for n in [1000,100000,1000000] if not (w.startswith('wide') and p in ['checked','wrapping','explicit-fixed'])]
    answers={(w,n):str(bench_expected(w,n)) for p,w,n in combos}
    samples=[];jobs=[]
    for rep in range(10):
        order=combos.copy();random.Random(1142+rep).shuffle(order)
        jobs.extend(('timing',rep,*c) for c in order)
    jobs.extend(('allocator',0,*c) for c in combos)
    try:
        for kind,rep,p,w,n in jobs:
            binary=instrumented if kind=='allocator' else timing
            command=['/usr/bin/time','-l',str(Path(binary).resolve()),'bench',p,w,str(n)]
            r=subprocess.run(command,capture_output=True,text=True,timeout=30)
            row=dict(kind=kind,rep=rep,policy=p,work=w,n=n,stdout=r.stdout,stderr=r.stderr,returncode=r.returncode)
            samples.append(row)
            require(r.returncode==0,'benchmark process failed')
            data=json.loads(r.stdout);row['data']=data
            rss=re.search(r'(\d+)\s+maximum resident set size',r.stderr)
            require(rss is not None,'missing process RSS');row['rss_bytes']=int(rss[1])
            require(row['rss_bytes']<=2*1024**3,'process RSS cap exceeded')
            require(data['answer']==answers[w,n],'benchmark answer mismatch')
            require(data['instrumented']==(kind=='allocator'),'wrong benchmark build')
            if kind=='allocator':
                for phase in ['setup','parse','arithmetic']:
                    m=data[phase]['memory'];require(m['peak_live']<=512*1024**2,'requested live cap exceeded')
                    require(m['peak_live']>=max(m['live_start'],m['live_end']),'allocator peak invalid')
                require(data['cleanup_live']==data['setup']['memory']['live_start'],'benchmark owned allocation leaked')
            print(f'{len(samples)}/{len(jobs)} {kind} {p} {w} {n}',flush=True) if len(samples)%50==0 else None
    finally: (dest/'samples.json').write_text(json.dumps(samples,indent=2)+'\n')
    (dest/'outcome.json').write_text(json.dumps(dict(passed=True,samples=len(samples),combinations=len(combos)),indent=2)+'\n')
    return samples

if __name__=='__main__':
    if sys.argv[1]=='generate':
        data=cases();(ROOT/'expected.json').write_text(json.dumps(data,indent=2)+'\n');print(len(data),'frozen cases')
    elif sys.argv[1]=='cases':
        r=correctness(sys.argv[2],sys.argv[3]);print(json.dumps(r,indent=2));sys.exit(not r['passed'])
    else: measure(*sys.argv[2:])
