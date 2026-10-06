"""Root-selected source sites under fixed ACCEPTANCE step 5; no new expectations."""
import difflib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

BASE=Path(__file__).resolve().parents[1]
OUT=BASE/"evidence/mutations"


def once(source,old,new):
    assert source.count(old)==1,(old,source.count(old))
    return source.replace(old,new)


def change(name,source):
    if name=="watchdog_disabled":
        return once(source,
            "if s.pending != 0 && Instant::now() >= s.attempts[s.pending - 1].deadline {",
            "if false && s.pending != 0 && Instant::now() >= s.attempts[s.pending - 1].deadline {")
    if name=="stale_publish":
        return once(source,
            "if s.pending != id || s.epoch != base {\n"
            "        s.attempts[id - 1].late_discarded = true;\n        return;\n    }",
            "if s.pending != id || s.epoch != base {\n"
            "        s.queue = candidate;\n        s.epoch = base + 1;\n        s.pending = id;\n"
            "        sh.terminal(&mut s, \"activated\", sh.now());\n        return;\n    }")
    if name=="duplicate_completion":
        needle="s.completed.push([job.seq, job.id, job.payload, epoch]);"
        return once(source,needle,needle+"\n        "+needle)
    if name=="lost_work":
        return once(source,"s.queue = candidate;", "s.queue = Queue::from_jobs(s.epoch + 1, Vec::new());")
    if name=="corrupt_activation":
        return once(source,"candidate.jobs() != source || ","")
    raise AssertionError(name)


def capture(name,cmd,cwd=None):
    p=subprocess.run(cmd,cwd=cwd,capture_output=True,text=True,timeout=120)
    (OUT/(name+".stdout")).write_text(p.stdout)
    (OUT/(name+".stderr")).write_text(p.stderr)
    return p,dict(command=cmd,exit=p.returncode)


def patch(name,source,mutant):
    (OUT/(name+".patch")).write_text("".join(difflib.unified_diff(source.splitlines(True),mutant.splitlines(True),fromfile="accepted-source",tofile=name)))


def main():
    OUT.mkdir(exist_ok=True)
    results={}
    source=(BASE/"runtime/src/main.rs").read_text()
    scenarios=dict(watchdog_disabled="stale",stale_publish="stale",duplicate_completion="conservation",lost_work="conservation",corrupt_activation="corrupt")
    for name,scenario in scenarios.items():
        mutant=change(name,source);patch(name,source,mutant)
        with tempfile.TemporaryDirectory(prefix="mo5-control-") as temp:
            root=Path(temp);(root/"src").mkdir();(root/"src/main.rs").write_text(mutant)
            for filename in ("Cargo.toml","Cargo.lock"):
                shutil.copyfile(BASE/"runtime"/filename,root/filename)
            p,build=capture(name+"-build",["cargo","build","--release","--locked","--offline","--manifest-path",str(root/"Cargo.toml")])
            assert p.returncode==0,(name,"build failure is not a detection")
            p,check=capture(name+"-check",[sys.executable,str(BASE/"acceptance/run.py"),"--binary",str(root/"target/release/mo-concurrent-updates"),"--scenario",scenario,"--output",str(OUT/(name+"-run"))])
            assert p.returncode!=0 and "AssertionError:" in p.stderr,(name,"mutant escaped or did not execute")
            teardown=json.loads(next((OUT/(name+"-run")).glob("*-teardown.json")).read_text())
            assert teardown["reaped"],"failed acceptance left process alive"
            results[name]=dict(build=build,check=check,detected=True,teardown=teardown)
            print(name+": rejected",flush=True)
    source=(BASE/"model/RepeatedUpdate.tla").read_text()
    mutant=once(source,"IF pending = 1","IF TRUE")
    patch("model-stale_publish",source,mutant)
    with tempfile.TemporaryDirectory(prefix="mo5-model-control-") as temp:
        root=Path(temp);(root/"RepeatedUpdate.tla").write_text(mutant)
        shutil.copyfile(BASE/"model/RepeatedUpdate.cfg",root/"RepeatedUpdate.cfg")
        p,check=capture("model-stale_publish",["java","-Xmx1g","-cp","/tmp/mo-live-update-tools/tla2tools-1.7.4.jar","tlc2.TLC","-workers","1","-config","RepeatedUpdate.cfg","RepeatedUpdate.tla"],cwd=root)
        assert p.returncode!=0 and "Invariant Safety is violated" in p.stdout
        results["model-stale_publish"]=dict(check=check,detected=True)
    (OUT/"results.json").write_text(json.dumps(results,indent=2)+"\n")
    print(json.dumps({name:data["detected"] for name,data in results.items()},indent=2))


if __name__=="__main__":
    main()
