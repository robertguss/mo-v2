"""Prepare one isolated task and serve baseline feedback; never launches a model."""
import hashlib
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from pathlib import Path
import secrets
import shutil
import sys
import threading

ROOT=Path(__file__).resolve().parent
HELPER=ROOT.parent/'03b-helper/bench/helper/src/lib.rs'
ARMS=['none','static-auto','static-request','actual-auto','actual-request']

class Delivery:
    def __init__(self,task,arm,workspace,state):
        if task not in ['U1','U2','R1','R2','H1','H2'] or arm not in ARMS:
            raise ValueError('unknown task or arm')
        workspace=Path(workspace).resolve();state=Path(state).resolve()
        workspace.mkdir(parents=True,exist_ok=False);state.mkdir(parents=True,exist_ok=False)
        feedback=json.loads((ROOT/'feedback.json').read_text())[task]
        self.payload='Copying feedback is unavailable in this condition.' if arm=='none' else feedback[arm.split('-')[0]]
        token=secrets.token_hex(16);self.events=[];self.state=state
        outer=self
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                if self.path!='/feedback/'+token:
                    self.send_error(404);return
                outer.events.append({'event':'request','ordinal':len(outer.events)+1})
                outer.save_events()
                data=outer.payload.encode()
                self.send_response(200);self.send_header('Content-Type','text/plain; charset=utf-8')
                self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
            def log_message(self,*args): pass
        self.server=HTTPServer(('127.0.0.1',0),Handler)
        self.url=f'http://127.0.0.1:{self.server.server_port}/feedback/{token}'
        try:
            shutil.copyfile(ROOT/f'tasks/{task}/task.rs',workspace/'task.rs')
            shutil.copyfile(HELPER,workspace/'helper.rs')
            shutil.copyfile(ROOT/f'tasks/{task}/TASK.md',workspace/'TASK.md')
            self.write_check(workspace,task)
            (workspace/'feedback').write_text('#!/usr/bin/env python3\nfrom urllib.request import urlopen\nprint(urlopen('+repr(self.url)+',timeout=5).read().decode())\n')
            (workspace/'feedback').chmod(0o755)
            prompt=(workspace/'TASK.md').read_text()+'\nUse ./check for common example correctness checks. Use ./feedback to request baseline copying feedback, if available.\n'
            if arm.endswith('-auto'):
                prompt+='\nBaseline copying feedback:\n'+self.payload+'\n'
                self.events.append({'event':'automatic_delivery','ordinal':1})
            (workspace/'PROMPT.md').write_text(prompt)
            self.save_events()
            (state/'manifest.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in workspace.iterdir() if p.is_file()},indent=2)+'\n')
            self.thread=threading.Thread(target=self.server.serve_forever,daemon=True);self.thread.start()
        except BaseException:
            self.server.server_close();raise
    def save_events(self):
        (self.state/'events.json').write_text(json.dumps(self.events,indent=2)+'\n')
    def close(self):
        self.server.shutdown();self.thread.join(timeout=5);self.server.server_close()
        if self.thread.is_alive(): raise RuntimeError('feedback server did not terminate')
    @staticmethod
    def write_check(workspace,task):
        # Public examples only; independent acceptance and cost results stay external.
        examples=[([],[]),([3,-2,7],[4,-1,8] if task in ['U1','R1','H1'] else [7,-2,3] if task in ['U2','H2'] else [3,1,8])]
        code='extern crate helper;\nmod task {include!(env!("TASK_SOURCE"));}\nfn main(){\n'
        for values,result in examples:
            old='None' if task.startswith('U') else 'Some(vec!'+repr(values)+')'
            code+=f'let mut input=helper::List::new(); for v in vec!{values}.into_iter().rev() {{input=input.push_front(v);}}\n'
            code+=f'let (out,old)=task::run(input); assert_eq!(out.iter().collect::<Vec<_>>(),vec!{result});assert_eq!(old.as_ref().map(|x|x.iter().collect::<Vec<_>>()),{old});\n'
        code+='println!("Example values and required original: PASS");}\n'
        (workspace/'check.rs').write_text(code)
        (workspace/'check').write_text('''#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import tempfile
r=Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix='mo-copy-examples-') as temp:
 t=Path(temp)
 base=['rustc','--edition=2021','-C','opt-level=3','-C','overflow-checks=yes']
 subprocess.run(base+['--crate-name','helper','--crate-type=rlib',str(r/'helper.rs'),'-o',str(t/'libhelper.rlib')],check=True)
 subprocess.run(base+[str(r/'check.rs'),'--extern','helper='+str(t/'libhelper.rlib'),'-o',str(t/'run')],env={**os.environ,'TASK_SOURCE':str(r/'task.rs')},check=True)
 subprocess.run([str(t/'run')],check=True)
''')
        (workspace/'check').chmod(0o755)

if __name__=='__main__':
    if len(sys.argv)!=5: raise SystemExit('usage: delivery.py TASK ARM NEW_WORKSPACE NEW_PRIVATE_STATE')
    d=Delivery(*sys.argv[1:]);print('Prepared workspace; feedback server active. No model launched.',flush=True)
    try: d.thread.join()
    except KeyboardInterrupt: pass
    finally: d.close()
