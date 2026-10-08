#!/usr/bin/env python3
"""Synthetic delivery checks only: no model invocation."""
import importlib.util
import itertools
import json
from pathlib import Path
import socket
import subprocess
import sys
from urllib.error import HTTPError
from urllib.request import urlopen

EXP = Path(__file__).resolve().parent.parent
s = importlib.util.spec_from_file_location('delivery', EXP / 'delivery.py')
delivery = importlib.util.module_from_spec(s)
s.loader.exec_module(delivery)

def closed(d, port):
    assert not d.thread.is_alive() and d.server.fileno() == -1
    with socket.socket() as sock:
        sock.settimeout(1)
        assert sock.connect_ex(('127.0.0.1', port)) != 0

def main():
    dest=Path(sys.argv[1]).resolve();dest.mkdir(parents=True,exist_ok=False)
    feedback=json.loads((EXP/'feedback.json').read_text())
    order=json.loads((EXP/'RUN_ORDER.json').read_text())['trials']
    expected=set(itertools.product(feedback,delivery.ARMS))
    assert len(order)==30 and {(x['task'],x['arm']) for x in order}==expected
    results=[]; payloads={}
    allowed={'task.rs','helper.rs','TASK.md','check.rs','check','feedback','PROMPT.md'}
    for task,arm in sorted(expected):
        folder=dest/(task+'-'+arm);work=folder/'workspace';state=folder/'private'
        d=delivery.Delivery(task,arm,work,state);port=d.server.server_port
        try:
            assert {p.name for p in work.iterdir()}==allowed
            prompt=(work/'PROMPT.md').read_text()
            auto=arm.endswith('-auto')
            typ=None if arm=='none' else arm.split('-')[0]
            wanted='Copying feedback is unavailable in this condition.' if typ is None else feedback[task][typ]
            for p in work.iterdir():
                text=p.read_text()
                for value in feedback[task].values():
                    assert (value in text)==(auto and p.name=='PROMPT.md' and value==wanted)
            assert len(d.events)==int(auto)
            if auto: assert d.events==[{'event':'automatic_delivery','ordinal':1}]
            try:
                urlopen(d.url+'/wrong',timeout=3)
                raise AssertionError('wrong URL accepted')
            except HTTPError as error:
                assert error.code==404
            assert len(d.events)==int(auto)
            fetched=subprocess.run([str(work/'feedback')],cwd=work,capture_output=True,text=True,timeout=5)
            assert fetched.returncode==0 and fetched.stdout.rstrip('\n')==wanted
            assert d.events[-1]=={'event':'request','ordinal':int(auto)+1}
            assert json.loads((state/'events.json').read_text())==d.events
            # Repeated direct requests are equally explicit and logged.
            assert urlopen(d.url,timeout=3).read().decode()==wanted
            assert d.events[-1]=={'event':'request','ordinal':int(auto)+2}
            if typ:
                key=(task,typ)
                assert payloads.setdefault(key,wanted)==wanted
            if arm=='none':
                r=subprocess.run([str(work/'check')],cwd=work,capture_output=True,text=True,timeout=60)
                (folder/'check-output.txt').write_text(r.stdout+r.stderr)
                assert r.returncode==0 and 'PASS' in r.stdout
            results.append({'task':task,'arm':arm,'passed':True,'requests':2,'automatic_delivery':auto})
        finally:
            d.close()
        closed(d,port)
    # Exercise the caller's required teardown path after a failure inside a trial.
    d=delivery.Delivery('U1','static-request',dest/'forced/workspace',dest/'forced/private');port=d.server.server_port
    try:
        try:
            raise RuntimeError('deliberate post-setup failure')
        finally:
            d.close()
    except RuntimeError as error:
        assert str(error)=='deliberate post-setup failure'
    closed(d,port)
    # Also exercise constructor failure after listener acquisition, before thread start.
    servers=[];original_server=delivery.HTTPServer;original_check=delivery.Delivery.write_check
    def capture_server(*args,**kwargs):
        server=original_server(*args,**kwargs);servers.append(server);return server
    def fail_check(*args): raise RuntimeError('deliberate setup failure')
    delivery.HTTPServer=capture_server;delivery.Delivery.write_check=staticmethod(fail_check)
    try:
        try:
            delivery.Delivery('U1','none',dest/'setup-failure/workspace',dest/'setup-failure/private')
            raise AssertionError('setup control did not fail')
        except RuntimeError as error:
            assert str(error)=='deliberate setup failure'
        assert len(servers)==1 and servers[0].fileno()==-1
    finally:
        delivery.HTTPServer=original_server;delivery.Delivery.write_check=staticmethod(original_check)
    (dest/'outcome.json').write_text(json.dumps({'passed':True,'setups':results,'public_checks':6,'forced_cleanup':True,'constructor_cleanup':True,'model_calls':0},indent=2)+'\n')
    print('PASS: 30 delivery setups, six public checks, two forced cleanup paths, zero model calls')

if __name__=='__main__': main()
