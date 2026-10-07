"""Acceptance-only v13 boundary. No interpreter, fixture predictions or native
observations are supplied to a candidate. Fixed legacy checks stay unchanged.
"""
from copy import deepcopy
import json

from bridgecheck import Normalizer
from cleanupcheck import check_destroy
from fixturecheck import validate_fixture
from predicates import physical_events, protection, walk
from structurecheck import canonical
from syntax import Refusal, check, lex, parse, position
from transition_reference import TransitionReference, children
from wirecheck import DECIMAL, check_public, public_bytes


def load(raw):
    def unique(pairs):
        assert len(dict(pairs)) == len(pairs), "duplicate JSON key"
        return dict(pairs)
    def invalid(value): raise AssertionError("non-JSON number")
    return json.loads(raw, object_pairs_hook=unique, parse_constant=invalid)


def exact(actual, expected, message):
    assert json.dumps(actual, sort_keys=True) == json.dumps(expected, sort_keys=True), message


def fields(obj, names):
    assert type(obj) is dict and set(obj) == set(names.split()), "schema fields"


def natural(value):
    assert type(value) is int and 0 <= value <= 2**64 - 1, "unsigned integer kind/range"
    return value


def tagged(value):
    assert type(value) is list and len(value) == 2, "tagged value"
    tag, payload = value
    if tag == "n": assert type(payload) is str and DECIMAL.fullmatch(payload), "decimal value"
    elif tag == "b": assert type(payload) is bool, "Boolean value"
    else:
        assert tag == "l", "value tag"
        if payload is not None: natural(payload)


def spans(program):
    source = program["source"]
    rows = []
    def add(path, bounds):
        a,b = bounds
        rows.append(dict(path=path, span=dict(start=position(source,a), end=position(source,b))))
    def expression(e, path):
        add(path, program["spans"][id(e)])
        for i,child in enumerate(children(e)): expression(child, f"{path}/{i}")
    add("root", (0,len(source)))
    tokens = list(lex(source)); cursor = 0
    for i,_ in enumerate(program["inputs"]):
        start = tokens[cursor].start
        while tokens[cursor].word != ";": cursor += 1
        add(f"input/{i}", (start,tokens[cursor].end)); cursor += 1
    for i,(_,params,_,body,*_) in enumerate(program["functions"]):
        add(f"function/{i}", program["decl_spans"][i])
        for j,(_,_,start,_) in enumerate(params):
            add(f"function/{i}/parameter/{j}", (start,program["annotations"][start][1]))
        expression(body,f"function/{i}/body")
    expression(program["main"],"main")
    return rows


def checked(source, dump, ranges, stage="B"):
    program = parse(source); check(program,stage)
    exact(load(dump),canonical(program),"checked structure/resolution")
    exact(load(ranges),spans(program),"source span map")
    return program


class Origins(TransitionReference):
    """Additional source-derived provenance expectations, not candidate data.

    Existing execution/trace/outcome predictions are inherited without changing
    them. New metadata observes their bind/counter/commit hooks; checked against
    hand-derived examples and the unchanged base trace before use.
    """
    def __init__(self, program, cells, inputs, outside, **kwargs):
        self.births, self.birth_steps, self.extended = [], [], []
        self.frame_seen, self.branch_seen, self.cell_seen, self.event_seen = 1,0,{c[0] for c in cells},0
        self.program = program
        super().__init__(program,cells,inputs,outside,**kwargs)
        self.initial_births = []

    def origin(self):
        return self.sites[id(self.context[-1]["expr"])] if self.context else "root"

    def add_birth(self, domain, ident, origin, invocation):
        self.births.append(dict(domain=domain,id=ident,origin=origin,invocation=invocation))

    def sync(self):
        while self.frame_seen < self.next_frame:
            self.add_birth("frame",self.frame_seen,self.origin(),self.frames[-2] if len(self.frames)>1 else 0)
            self.frame_seen += 1
        while self.branch_seen < self.next_branch:
            self.add_birth("branch",self.branch_seen,self.origin(),self.frames[-1] if self.frames else 0)
            self.branch_seen += 1

    def bind(self, name, value, status):
        self.sync()
        ident = super().bind(name,value,status)
        if not self.context: origin = f"input/{ident}"
        else:
            expr = self.context[-1]["expr"]
            if expr[0] == "let": origin = self.origin()+"/binding"
            elif expr[0] == "match": origin = self.origin()+("/head" if name == expr[3] else "/tail")
            else:
                assert expr[0] == "call", "binding origin context"
                fi = next(i for i,f in enumerate(self.program["functions"]) if f[0]==expr[1])
                pi = next(i for i,p in enumerate(self.program["functions"][fi][1]) if p[0]==name)
                origin = f"function/{fi}/parameter/{pi}"
        self.add_birth("binding",ident,origin,self.frames[-1] if self.frames else 0)
        if not self.context: self.initial_births = deepcopy(self.births)
        return ident

    def commit(self, transition, landmark=None, value=None):
        self.sync()
        for cell in self.cells:
            if cell[0] not in self.cell_seen:
                self.add_birth("cell",cell[0],self.origin(),self.frames[-1] if self.frames else 0)
                self.cell_seen.add(cell[0])
        super().commit(transition,landmark,value)
        for event in self.events[self.event_seen:]:
            if event[0]=="enter": self.extended.append([*event,self.origin()])
            elif event[0]=="return": self.extended.append([*event,deepcopy(self.trace[-1]["ready"])])
            else: self.extended.append(list(event))
        self.event_seen = len(self.events)
        self.birth_steps.append(deepcopy(self.births))


def snapshot_schema(s):
    fields(s,"step status state control ready release event_end events births failure cleanup_events")
    natural(s["step"]); natural(s["event_end"])
    assert s["status"] in ("suspended","finished","failed"), "snapshot status"
    fields(s["state"],"kind bindings pending aside branch frames")
    state=s["state"]
    assert state["kind"] is None or type(state["kind"]) is str, "state kind"
    for row in state["bindings"]:
        assert type(row) is list and len(row)==4, "binding row"
        ident,name,value,status=row; natural(ident); tagged(value)
        assert type(name) is str and status in ("holding","movedOn","noHolder","givenUp"), "binding kind/status"
    for value in state["pending"]: tagged(value)
    for pair in state["aside"]:
        assert type(pair) is list and len(pair)==2, "reservation row"
        for ident in pair: natural(ident)
    if state["branch"] is not None: tagged(state["branch"])
    for ident in state["frames"]: natural(ident)
    for row in s["control"]:
        fields(row,"site scope invocation operands"); natural(row["invocation"])
        assert type(row["site"]) is str, "control site"
        for name,ident in row["scope"]:
            assert type(name) is str, "scope name"
            natural(ident)
        for value in row["operands"]: tagged(value)
    if s["ready"] is not None: tagged(s["ready"])
    for ident in s["release"]: natural(ident)
    assert type(s["events"]) is list and len(s["events"])==s["event_end"], "snapshot event prefix"
    assert type(s["births"]) is list and type(s["cleanup_events"]) is list, "snapshot lists"
    if s["failure"] is not None:
        fields(s["failure"],"class step domain aborts"); natural(s["failure"]["step"])
        assert type(s["failure"]["class"]) is str and s["failure"]["domain"] in (None,"cell","number","frame"), "failure class/domain"
        assert s["status"]=="failed", "failure status"
    else: assert s["status"]!="failed", "missing failure"


class Observation(Normalizer):
    def __init__(self, fixtures, outside):
        super().__init__(dict(cell=[(c[0],c[0]) for c in fixtures],frame=[(0,0)]))
        self.outside=list(outside)
        self.registered=[]

    def register(self, rows, expected):
        assert len(rows)==len(expected), "birth coverage"
        assert len(rows)>=len(self.registered), "birth prefix shortened"
        exact(rows[:len(self.registered)],self.registered,"birth prefix rewritten")
        for row,want in zip(rows[len(self.registered):],expected[len(self.registered):]):
            fields(row,"domain id origin invocation")
            natural(row["id"]); natural(row["invocation"])
            assert row["domain"]==want["domain"] and row["origin"]==want["origin"], "birth origin/domain/order"
            assert self.ident("frame",row["invocation"])==want["invocation"], "birth owning invocation"
            self.birth(row["domain"],row["id"],want["id"])
            self.registered.append(deepcopy(row))

    def state(self, raw, graph):
        fields(raw,"kind bindings pending aside branch frames")
        return dict(kind=raw["kind"],memory=self.memory([r[:5] for r in graph]),outside=[self.cell(r) for r in self.outside],
            bindings=[[self.ident("binding",i),n,self.value(v),status] for i,n,v,status in raw["bindings"]],
            pending=[self.value(v) for v in raw["pending"]],aside=[[self.ident("branch",b),self.cell(c)] for b,c in raw["aside"]],
            branch=self.value(raw["branch"]),frames=[self.ident("frame",i) for i in raw["frames"]])

    def extended_events(self, events):
        result=[]
        for e in events:
            assert type(e) is list and e, "event row"
            if e[0] in ("create","write","free"):
                assert len(e)==2, "cell event fields"; natural(e[1])
                result.append([e[0],self.cell(e[1])])
            elif e[0]=="enter":
                assert len(e)==5 and type(e[3]) is str and type(e[4]) is str, "enter fields"
                natural(e[1]); natural(e[2])
                result.append([e[0],self.ident("frame",e[1]),self.ident("frame",e[2]),e[3],e[4]])
            else:
                assert e[0]=="return" and len(e)==3, "return fields"
                natural(e[1]); tagged(e[2])
                result.append([e[0],self.ident("frame",e[1]),self.value(e[2])])
        return result

    def failure(self, raw, active, step):
        if raw is None: return None
        fields(raw,"class step domain aborts")
        assert raw["step"]==step, "failure committed step"
        aborts=[]
        for record in raw["aborts"]:
            assert type(record) is list and len(record)==2 and record[0]=="abort", "abort fields"
            natural(record[1]); aborts.append(["abort",self.ident("frame",record[1])])
        exact(aborts,[["abort",i] for i in reversed(active)],"failure abort stack")
        return dict(raw,aborts=aborts)


def composed(snapshot, graph, outside):
    """Raw evidence composition only. No reference/expected parameter exists."""
    snapshot_schema(snapshot)
    state=deepcopy(snapshot["state"])
    state["memory"]=[list(row[:5]) for row in graph]
    state["outside"]=list(outside)
    return dict(snapshot,state=state)


def fixture_approval(program, case):
    try: validate_fixture(program,case["cells"],case["inputs"],case["outside"])
    except AssertionError as error:
        message=str(error)
        path="fixture"
        classes={"root dangling":"dangling","tail dangling":"dangling","cell identities":"cell-identities",
                 "holder counts":"holder-count","input names/order":"input-names","input kind":"input-kind",
                 "integer input":"integer","cell integer":"integer","initial live/count":"initial-live-count",
                 "unreachable initial cell":"unreachable","dangling/cycle":"cycle"}
        if message=="root dangling":
            ids={r[0] for r in case["cells"]}
            roots=[(f"inputs/{i}",v[1]) for i,(_,v) in enumerate(case["inputs"]) if v[0]=="l"]
            roots += [(f"outside/{i}",r) for i,r in enumerate(case["outside"])]
            path=next(p for p,r in roots if r is not None and (type(r) is not int or r not in ids))
        return dict(status="invalid-fixture",**{"class":classes[message]},path=path)
    return dict(status="install")


class Verifier:
    """Streaming small-case observation checker. Actual native graph comes ONLY
    from driver records; references supply expectations, never observations.
    Keeps one run-wide identity map and distinguishes execution/destroy/teardown.
    """
    def __init__(self, case, budgets, deny=None, stage="B"):
        self.case, self.budgets, self.deny, self.stage = case,list(budgets),deny,stage
        self.program=self.ref=self.outcome=None; self.refusal=None
        try:
            self.program=parse(case["source"]); check(self.program,stage)
        except Refusal as error:
            span=dict(bytes=[error.start,error.end]) if error.kind=="encoding" else dict(
                start=position(self.program["source"] if self.program else case["source"].decode("utf-8",errors="surrogateescape") if isinstance(case["source"],bytes) else case["source"],error.start),
                end=position(self.program["source"] if self.program else case["source"].decode("utf-8",errors="surrogateescape") if isinstance(case["source"],bytes) else case["source"],error.end))
            self.refusal=dict(status="refused",**{"class":error.kind},span=span)
        self.approval=fixture_approval(self.program,case) if self.program and self.refusal is None else None
        if self.approval and self.approval["status"]=="install":
            self.ref=Origins(self.program,case["cells"],case["inputs"],case["outside"],landmark_limit=60 if case.get("value",0) is None else 20000)
            self.outcome=self.ref.observe(self.program["main"])
        self.norm=Observation(case["cells"],case["outside"])
        self.cursor=[0,0,0,0]; self.clock=0; self.step=0; self.events=[]; self.births=[]
        self.physical=[]; self.attempts={}; self.denials=[]; self.native_by_phase={}
        self.last_snapshot=None; self.last_observation=None; self.last_graph=None
        self.advance_index=0; self.advance_start=0; self.destroyed=0; self.ended=False
        self.seen_check=False; self.seen_fixture=False; self.seen_begin=False

    def frontend(self, row):
        assert not self.seen_check and self.program is not None and self.refusal is None, "unexpected checked source"
        checked(self.case["source"],row["checked"],row["spans"],self.stage)
        self.seen_check=True
        return self.approval

    def initial(self):
        bindings=[[i,n,v,"holding" if v[0]=="l" and v[1] is not None else "noHolder"] for i,(n,v) in enumerate(self.case["inputs"])]
        return dict(step=0,event_end=0,state=dict(kind=None,memory=self.case["cells"],outside=self.case["outside"],
            bindings=bindings,pending=[],aside=[],branch=None,frames=[]),control=[],ready=None,release=[])

    def expected(self):
        assert self.ref is not None and self.step<=len(self.ref.trace), "unexpected execution prefix"
        return self.ref.trace[self.step-1] if self.step else self.initial()

    def prefix(self, s, graph):
        expected=self.expected()
        expected_births=self.ref.birth_steps[self.step-1] if self.step else self.ref.initial_births
        self.norm.register(s["births"],expected_births)
        actual=self.norm.transition({k:s[k] for k in ("step","event_end","state","control","ready","release")},graph)
        exact(actual,{k:expected[k] for k in actual},"full committed execution/physical state")
        exact(self.norm.extended_events(s["events"]),self.ref.extended[:s["event_end"]],"extended call/event prefix")
        # The complete native graph, not a candidate shadow graph, is also
        # checked by the existing ownership/outside-value predicates.
        protection([actual["state"]],self.case["cells"],self.case["outside"])
        return actual

    def physical_check(self, graph):
        # Normalize only after birth registration; keep retired identities mapped.
        stream=[[kind,self.norm.cell(i),pointer] for kind,i,pointer,_ in self.physical]
        primitive=[[e[0],self.norm.cell(e[1])] for e in self.events if e[0] in ("create","write","free")]
        cleanup=[[kind,self.norm.cell(i)] for kind,i,_,phase in self.physical if phase=="destroy"]
        teardown=[[kind,self.norm.cell(i)] for kind,i,_,phase in self.physical if phase=="teardown"]
        memory=self.norm.memory([r[:5] for r in graph])
        live=physical_events(self.case["cells"],stream,primitive+cleanup+teardown,memory)
        assert live=={self.norm.cell(r[0]):r[5] for r in graph}, "physical graph/event continuity"
        return live

    def row(self, row):
        assert not self.ended, "evidence after process completion"
        phase=row["phase"]
        if phase=="check": return self.frontend(row)
        fields(row,"phase elapsed_ns step raw graph outside from to events mutations resources creates")
        natural(row["step"]); natural(row["elapsed_ns"])
        assert row["elapsed_ns"]>=self.clock, "phase clock went backwards"
        self.clock=row["elapsed_ns"]
        exact(row["outside"],self.case["outside"],"host external roots")
        exact(row["from"],self.cursor,"native cursor continuity")
        assert len(row["to"])==4, "native cursor arity"
        for i,key in enumerate(("events","mutations","resources","creates")):
            natural(row["to"][i]); assert row["to"][i]==self.cursor[i]+len(row[key]), "native cursor length"
        self.cursor=list(row["to"])
        self.physical.extend(row["events"])
        native_phase={"frontend":"frontend","pre-run":"frontend","fixture":"fixture","begin":"begin",
            "commit":"execution","advance":"execution","destroy":"destroy","destroy-again":"destroy","drop":"destroy","teardown":"teardown","invalid-fixture":"frontend"}[phase]
        for event in row["events"]+row["mutations"]:
            assert len(event)==4 and event[3]==native_phase, "native event phase"
            natural(event[1]); natural(event[2]); assert event[2]>0, "native pointer"
        for domain,ordinal,allowed,p in row["resources"]+[["cell",*a] for a in row["creates"]]:
            assert domain in ("number","frame","cell") and type(allowed) is bool and p==native_phase, "resource phase/domain"
            natural(ordinal); self.attempts[domain]=self.attempts.get(domain,0)+1
            assert ordinal==self.attempts[domain], "resource ordinal continuity"
            if not allowed: self.denials.append([domain,ordinal])
        self.native_by_phase[phase]=self.native_by_phase.get(phase,0)+len(row["events"])
        raw=row["raw"]; graph=row["graph"]
        if phase in ("frontend","pre-run","invalid-fixture"):
            assert graph==[] and not row["events"] and not row["mutations"] and row["step"]==0, "pre-run managed effects"
            if phase=="frontend": assert self.seen_check, "missing frontend approval"
            elif phase=="invalid-fixture":
                check_public(raw["public"].encode(),public_bytes(self.approval)); self.ended=True
            else:
                if self.denials:
                    assert self.denials==[self.deny] and self.deny[0]=="number", "pre-run denial"
                    exact(raw["failure"],dict(kind="failed",**{"class":"resource-exhausted"},domain="number"),"typed pre-run failure")
                    expected=dict(status="failed",**{"class":"resource-exhausted"},step="0")
                else:
                    assert self.refusal is not None and raw["failure"]=={"kind":"refused"}, "unexpected refusal"
                    expected=self.refusal
                check_public(raw["public"].encode(),public_bytes(expected)); self.ended=True
            return
        if phase=="fixture":
            assert self.seen_check and not self.seen_fixture and row["step"]==0, "fixture phase order"
            exact(self.norm.memory([r[:5] for r in graph]),self.case["cells"],"installed actual fixture")
            self.seen_fixture=True; self.physical_check(graph); return
        if phase in ("drop","teardown"):
            assert self.destroyed==2, "missing repeated destroy"
            if phase=="drop":
                exact(graph,self.last_graph,"Drop postponed cleanup"); assert not row["events"] and not row["mutations"], "Drop cell effects"
            else: assert graph==[], "host teardown leak"; self.ended=True
            self.physical_check(graph); return
        assert self.seen_fixture and not self.ended, "execution phase order"
        if phase=="commit":
            assert self.seen_begin and not self.destroyed, "callback outside execution"
            meta=load(raw["metadata"])
            fields(meta,"step transition site event_end landmark events_added births_added")
            natural(meta["step"]); natural(meta["event_end"])
            if meta["landmark"] is not None: natural(meta["landmark"])
            assert meta["step"]==self.step+1, "callback step continuity"
            self.step+=1; self.events.extend(meta["events_added"]); self.births.extend(meta["births_added"])
            expected=self.expected()
            exact({k:meta[k] for k in ("step","transition","site","event_end","landmark")},
                  {k:expected[k] for k in ("step","transition","site","event_end","landmark")},"commit metadata")
            assert len(self.events)==meta["event_end"], "callback event suffix"
        assert row["step"]==self.step, "collector step provenance"
        assert raw["snapshot"] is not None and graph is not None, "small full observation missing"
        s=load(raw["snapshot"]); snapshot_schema(s)
        exact(s["events"],self.events,"snapshot/callback events")
        if phase=="begin":
            assert not self.seen_begin and self.step==0, "begin step/coverage"
            self.seen_begin=True; self.births=deepcopy(s["births"])
        exact(s["births"],self.births,"snapshot/callback births")
        assert s["step"]==self.step, "snapshot committed step"
        if phase.startswith("destroy"):
            assert phase==("destroy" if self.destroyed==0 else "destroy-again"), "destroy ordering"
            assert self.advance_index==len(self.budgets), "missing budget calls"
            actual=self.norm.transition({k:s[k] for k in ("step","event_end","state","control","ready","release")},graph)
            exact(s["events"],self.last_snapshot["events"],"destroy altered committed event prefix")
            exact(s["failure"],self.last_snapshot["failure"],"destroy altered failure evidence")
            all_cleanup=self.norm.extended_events(s["cleanup_events"])
            native_cleanup=[[kind,self.norm.cell(i)] for kind,i,_,p in self.physical if p=="destroy"]
            exact(all_cleanup,native_cleanup,"logical/native cleanup events")
            new_cleanup=all_cleanup[len(self.last_snapshot["cleanup_events"]):]
            check_destroy(self.last_observation["state"],actual["state"],new_cleanup,
                {self.norm.cell(r[0]):r[5] for r in self.last_graph},{self.norm.cell(r[0]):r[5] for r in graph})
            assert actual["control"]==[] and actual["ready"] is None and actual["release"]==[], "destroy execution temporaries"
            self.destroyed+=1
        else:
            actual=self.prefix(s,graph)
            assert not s["cleanup_events"], "cleanup folded into execution"
            if s["status"]=="failed":
                assert self.denials==[self.deny], "failure without requested denial"
                failure=self.norm.failure(s["failure"],actual["state"]["frames"],self.step)
                assert failure["class"]=="resource-exhausted" and failure["domain"]==self.deny[0], "controlled failure classification"
                if phase=="advance": assert not row["events"] and not row["mutations"], "failed allocation partial effect"
            else:
                assert not self.denials, "denial ignored"
                terminal=self.step>0 and self.expected().get("transition")=="Finish"
                assert s["status"]==("finished" if terminal else "suspended"), "exact-boundary terminal classification"
            if phase=="advance":
                assert self.advance_index<len(self.budgets), "extra advance"
                budget=self.budgets[self.advance_index]
                assert self.step-self.advance_start<=budget, "advance overshot budget"
                if s["status"]=="suspended": assert self.step-self.advance_start==budget, "advance undershot budget"
                if budget==0:
                    exact(s,self.last_snapshot,"zero-budget changed state");exact(graph,self.last_graph,"zero-budget live identity")
                    assert not row["events"] and not row["mutations"], "zero-budget native work"
                    assert not row["resources"] and not row["creates"], "zero-budget allocation attempt"
                if self.last_snapshot["status"]!="suspended":
                    exact(s,self.last_snapshot,"terminal state changed")
                    assert not row["events"] and not row["mutations"], "terminal native work"
                    assert not row["resources"] and not row["creates"], "terminal allocation attempt"
                self.advance_index+=1;self.advance_start=self.step
            if phase!="commit":
                if s["status"]=="suspended": expected=dict(status="suspended",steps=str(self.step))
                elif s["status"]=="failed": expected=dict(status="failed",**{"class":"resource-exhausted"},step=str(self.step))
                else:
                    value=actual["ready"]
                    plain=[str(n) for n in walk(actual["state"]["memory"],value[1])[0]] if value[0]=="l" else value[1]
                    exact([value[0],plain],self.outcome["outcome"]["value"],"independent answer/native readback")
                    expected=dict(status="finished",type={"l":"ListInt","n":"Int","b":"Bool"}[value[0]],value=plain)
                check_public(raw["public"].encode(),public_bytes(expected))
        self.physical_check(graph)
        self.last_snapshot=deepcopy(s); self.last_observation=actual; self.last_graph=deepcopy(graph)

    def finish(self):
        assert self.ended, "incomplete process evidence"
        if self.deny: assert self.denials==[self.deny], "requested denial not exercised"
        return dict(committed_steps=self.step,advances=self.advance_index,destroy_calls=self.destroyed,
                    events_by_phase=self.native_by_phase,resource_attempts=self.attempts)
