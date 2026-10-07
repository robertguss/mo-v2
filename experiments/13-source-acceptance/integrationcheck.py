"""Bounded integration validation: canned native callbacks and independent
metadata expectations. Does not execute Mo or claim evaluator controls ran.
"""
from copy import deepcopy
import gzip
import json
from pathlib import Path
import subprocess
import sys
import traceback

from cases import examples
from integration import Origins, Observation, Verifier, exact, load, snapshot_schema
from linked import check_clock, run_linked
from syntax import parse
from transition_reference import TransitionReference


COMMAND=["/tmp/rob1333integration/debug/examples/fixture_stub"]
CASE=dict(source="input xs: ListInt; main = xs",cells=[[9,"37",2,2,"live"],[2,"-4",None,2,"live"]],inputs=[["xs",["l",9]]],outside=[9,2])


def reject(fn, message):
    try: fn()
    except (AssertionError,ValueError,KeyError,TypeError) as error:
        assert message in str(error),(message,str(error))
        return str(error)
    raise AssertionError("control accepted: "+message)


def run(destination, private):
    destination.mkdir(parents=True,exist_ok=False)
    report=dict(passed=False,linked_stub_runs=0,controls={},reference_regressions=0,candidate_executed=False)
    try:
        # Hand derivations BEFORE observing metadata: one Cons at main/0, then
        # invocation entry at main, then one parameter binding in invocation 1.
        source="def f(a: ListInt): ListInt = a end main = f([7])"
        program=parse(source); reference=Origins(program,[],[],[]);reference.observe(program["main"])
        births=[dict(domain="cell",id=0,origin="main/0",invocation=0),
                dict(domain="frame",id=1,origin="main",invocation=0),
                dict(domain="binding",id=0,origin="function/0/parameter/0",invocation=1)]
        exact(reference.births,births,"hand-derived birth order/origin")
        exact(reference.extended,[["create",0],["enter",1,0,"f","main"],["return",1,["l",0]]],"hand-derived call metadata")
        rawbirths=[dict(births[0],id=81),dict(births[1],id=91),dict(births[2],id=71,invocation=91)]
        norm=Observation([],[]);norm.register(rawbirths,births)
        exact(norm.extended_events([["create",81],["enter",91,0,"f","main"],["return",91,["l",81]]]),reference.extended,"cross-domain normalization")
        for name, events in (("call-site",[["create",81],["enter",91,0,"f","main/0"],["return",91,["l",81]]]),
                             ("return-value",[["create",81],["enter",91,0,"f","main"],["return",91,["l",None]]])):
            report["controls"][name]=reject(lambda:exact(norm.extended_events(events),reference.extended,"call metadata differs"),"call metadata differs")
        fault=dict(**{"class":"resource-exhausted"},step=7,domain="number",aborts=[["abort",91]])
        assert norm.failure(fault,[1],7)["aborts"]==[["abort",1]]
        report["controls"]["abort-order"]=reject(lambda:norm.failure(dict(fault,aborts=[]),[1],7),"failure abort stack")
        wrong=deepcopy(rawbirths);wrong[2]["origin"]="main/binding"
        report["controls"]["birth-origin"]=reject(lambda:Observation([],[]).register(wrong,births),"birth origin/domain/order")
        alias=deepcopy(rawbirths);alias.append(dict(rawbirths[0]))
        report["controls"]["identity-rebirth"]=reject(lambda:Observation([],[]).register(alias,births+[dict(births[0],id=1)]),"identity rebirth")
        report["controls"]["duplicate-JSON"]=reject(lambda:load('{"step":1,"step":2}'),"duplicate JSON key")
        # Fixed original reference outputs must remain byte-structurally identical
        # after provenance annotation. Private sources/results are not exported.
        cases=list(examples())
        private_cases=[json.loads(line) for line in gzip.open(private/"cases.jsonl.gz","rt")]
        for case in cases+private_cases:
            program=parse(case["source"])
            opts=dict(landmark_limit=60 if case.get("value",0) is None else 20000)
            a=Origins(program,case["cells"],case["inputs"],case["outside"],**opts)
            b=TransitionReference(program,case["cells"],case["inputs"],case["outside"],**opts)
            actual=a.observe(program["main"]);expected=b.observe(program["main"])
            exact(actual,expected,"unchanged reference outcome");exact(a.trace,b.trace,"unchanged reference trace")
            report["reference_regressions"]+=1
        # No new language-case campaign: reuse the existing interface witness,
        # bridge shape and every cut of its three prescribed commits.
        retained_rows=None
        for variant,outside in enumerate(([9,2],[2,9])):
            case=dict(CASE,outside=outside)
            for cut in range(4):
                for mode,budgets in (("resume",[cut,0,3-cut,0,9]),("destroy",[cut])):
                    folder=destination/f"native-{variant}-{mode}-{cut}"
                    result=run_linked(COMMAND,case,budgets,folder,fixture_stub=True)
                    assert result["destroy_calls"]==2
                    report["linked_stub_runs"]+=1
                    if variant==0 and mode=="resume" and cut==1:
                        retained_rows=[load(line) for line in (folder/"rows.jsonl").read_bytes().splitlines()]
        for domain,ordinal in (("number",1),("number",2),("frame",1)):
            result=run_linked(COMMAND,CASE,[1,9,0,1],destination/f"denied-{domain}-{ordinal}",deny=[domain,ordinal],fixture_stub=True)
            assert result["committed_steps"]==(0 if ordinal==1 and domain=="number" else 1)
            report["linked_stub_runs"]+=1
        result=run_linked(COMMAND,CASE,[1,9,0,1],destination/"denied-cell-1",deny=["cell",1],
                          env={"ROB_STUB_CONTROL":"cell-denial-probe"},fixture_stub=True)
        assert result["committed_steps"]==1;report["linked_stub_runs"]+=1
        bad=dict(CASE,inputs=[["xs",["l",999]]])
        result=run_linked(COMMAND,bad,[3],destination/"invalid-fixture",fixture_stub=True)
        assert result["committed_steps"]==0;report["linked_stub_runs"]+=1
        # A denied frontend allocation must beat fixture validation because
        # no checked program exists. Its ignored-denial twin was accepted by
        # the pre-repair verifier; preserve that witness in review-defects.
        result=run_linked(COMMAND,bad,[3],destination/"denial-before-invalid-fixture",deny=["number",1],fixture_stub=True)
        assert result["committed_steps"]==0;report["linked_stub_runs"]+=1
        report["controls"]["compiled-stub/ignored-frontend-denial"]=reject(
            lambda:run_linked(COMMAND,bad,[3],destination/"broken-ignored-frontend-denial",deny=["number",1],
                env={"ROB_STUB_CONTROL":"ignored-frontend-denial"},fixture_stub=True),
            "frontend denial must return typed failed outcome")
        bad=dict(source="main = @",cells=[],inputs=[],outside=[])
        result=run_linked(COMMAND,bad,[],destination/"refused",fixture_stub=True)
        assert result["committed_steps"]==0;report["linked_stub_runs"]+=1
        # The same three-state stub with large scheduling: events are retained,
        # but the three nonperiodic callbacks request no graph/snapshot. Full
        # observations still occur at begin/suspend/finish/two destroys/teardown.
        request=dict(CASE,source=list(CASE["source"].encode()),budgets=[1,2],large=True,deny=None)
        result=subprocess.run(COMMAND,input=json.dumps(request)+"\n"+'{"status":"install"}\n',text=True,capture_output=True,timeout=10)
        (destination/"large-schedule-stub.jsonl").write_text(result.stdout)
        assert result.returncode==0,result.stderr
        for row in map(load,result.stdout.splitlines()):
            if row["phase"]=="check": continue
            assert (row["graph"] is None)==(row["phase"]=="commit"),"large full-observation schedule"
            if row["phase"]=="commit": assert row["raw"]["snapshot"] is None
        report["large_schedule_stub"]=True
        # Actual executable STUB controls target the bridge, not a Mo evaluator.
        for name,message in (("counter","abnormal termination"),("shadow-state","full committed execution/physical state"),("leak","destroy outside graph/counts")):
            report["controls"]["compiled-stub/"+name]=reject(lambda:run_linked(COMMAND,CASE,[3],destination/f"broken-{name}",env={"ROB_STUB_CONTROL":name},fixture_stub=True),message)
        # Mutate only observation copies; never rewrite a saved valid capture.
        def replay(rows):
            v=Verifier(CASE,[1,0,2,0,9])
            for row in rows: v.row(row)
            v.finish()
        replay(retained_rows)
        paths=[("state",name) for name in ("bindings","pending","aside","frames")]
        paths += [(name,) for name in ("control","release","events","births","cleanup_events")]
        paths += [("control",0,"scope"),("control",0,"operands"),("control",0,"scope",0)]
        for path in paths:
            for bad_array in ({},""):
                rows=deepcopy(retained_rows)
                row=next(r for r in rows if r["phase"]=="commit" and r["step"]==2)
                s=load(row["raw"]["snapshot"]); target=s
                for key in path[:-1]: target=target[key]
                target[path[-1]]=bad_array;row["raw"]["snapshot"]=json.dumps(s)
                name="array/"+"/".join(map(str,path))+"/"+type(bad_array).__name__
                report["controls"][name]=reject(lambda:replay(rows),"schema array type")
        for bad_array in ({},""):
            s=load(next(r for r in retained_rows if r["phase"]=="commit" and r["step"]==2)["raw"]["snapshot"])
            s.update(status="failed",failure=dict(**{"class":"resource-exhausted"},step=2,domain="number",aborts=bad_array))
            report["controls"]["array/aborts/"+type(bad_array).__name__]=reject(lambda:snapshot_schema(s),"schema array type")
        for name,message in (("physical-content","full committed execution/physical state"),
                             ("physical-pointer","physical graph/event continuity"),
                             ("candidate-external-field","schema fields"),
                             ("Boolean-step","unsigned integer kind/range"),
                             ("event-omission","native cursor length"),
                             ("clock-reset","phase clock went backwards"),
                             ("missing-binding","full committed execution/physical state"),
                             ("missing-control","full committed execution/physical state"),
                             ("missing-pending","full committed execution/physical state"),
                             ("outside-order","host external roots")):
            rows=deepcopy(retained_rows)
            row=next(r for r in rows if r["phase"]=="commit" and r["step"]==2)
            if name=="physical-content": row["graph"][0][1]="999"
            elif name=="physical-pointer": row["graph"][0][5]+=64
            elif name=="candidate-external-field":
                s=load(row["raw"]["snapshot"]);s["state"]["outside"]=[9,2];row["raw"]["snapshot"]=json.dumps(s)
            elif name=="Boolean-step": row["step"]=True
            elif name=="event-omission": next(r for r in rows if r["phase"]=="fixture")["events"].pop()
            elif name=="clock-reset": row["elapsed_ns"]=0
            elif name.startswith("missing-"):
                s=load(row["raw"]["snapshot"])
                if name=="missing-control": s["control"]=[]
                else: s["state"]["bindings" if name=="missing-binding" else "pending"]=[]
                row["raw"]["snapshot"]=json.dumps(s)
            else: row["outside"]=[2,9]
            report["controls"][name]=reject(lambda:replay(rows),message)
        phases=[dict(phase="launch",start_ns=10,end_ns=110),dict(phase="destroy",start_ns=110,end_ns=610)]
        check_clock(10,610,phases,600)
        report["controls"]["cleanup-clock-cap"]=reject(lambda:check_clock(10,611,[phases[0],dict(phases[1],end_ns=611)],600),"inclusive watchdog")
        report["controls"]["clock-gap"]=reject(lambda:check_clock(10,610,[phases[0],dict(phases[1],start_ns=111)],600),"phase clock gap/reset")
        try: run_linked([sys.executable,"-c","import time; time.sleep(10)"],CASE,[3],destination/"watchdog",timeout=0.05,fixture_stub=True)
        except TimeoutError: report["controls"]["actual-watchdog"]="inclusive watchdog killed only its owned stub process"
        else: raise AssertionError("watchdog did not interrupt process")
        report["passed"]=True
    except Exception:
        report["error"]=traceback.format_exc()
    (destination/"summary.json").write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report,indent=2));return report["passed"]


if __name__=="__main__": sys.exit(not run(Path(sys.argv[1]),Path(sys.argv[2])))
