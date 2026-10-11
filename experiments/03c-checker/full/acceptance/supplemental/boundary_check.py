#!/usr/bin/env python3
"""Consume exported evidence, not a source evaluator, proof, or demand checker.

Assertions come from unchanged BOUNDARIES/DERIVATIONS and checkpoint ledgers.
Repr parsing is deliberately limited; missing full/control evidence is reported.
"""
import argparse
import copy
import hashlib
import importlib.util
import json
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("fixtures", HERE.parent / "check.py")
fx = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fx)
ROWS = {r[0]: r for r in fx.all_cases()}
HOLD = "Trial.BStatus.holding"


def eq(actual, expected, why="mismatch"):
    if json.dumps(actual, sort_keys=True) != json.dumps(expected, sort_keys=True):
        raise ValueError(f"{why}: actual={actual!r}; expected={expected!r}")


def require(ok, why):
    if not ok:
        raise ValueError(why)


def addr(a):
    return None if a is None else ord(a) - ord("A")


def identities(row):
    names = {a: addr(a) for a, *_ in fx.STARTS[row[2]]["cells"]}
    fresh = max(names.values(), default=-1) + 1
    for e in row[8]:
        if e.startswith("C "):
            names[e.split()[1]] = fresh
            fresh += 1
    names["-"] = None
    return names


def ledger(row):
    ids = identities(row)
    return [[p[0], ids[p[1]]] + ([int(p[2]), ids[p[3]]] if len(p) == 4 else [])
            for p in (e.split() for e in row[8])]


def cells(s):
    out = {c[0]: c[1:] for c in s["cells"]}
    eq(len(out), len(s["cells"]), "duplicate cell")
    return out


def read(s, raw):
    if raw[0] != "L":
        return raw[1]
    heap, seen, value, root = cells(s), set(), [], raw[1]
    while root is not None:
        require(root in heap and root not in seen, "dangling or cyclic readable root")
        n, tail, count, status = heap[root]
        require(status == "live" and count > 0, "holder reaches unreadable cell")
        seen.add(root)
        value.append(n)
        root = tail
    return value


def normalized(s):
    return {k: v for k, v in s.items() if k != "completeState"}


def call_sites(expr, site):
    if not isinstance(expr, list) or not expr:
        return {}
    op = expr[0]
    result = {site: expr[1]} if op == "call" else {}
    children = (expr[2:] if op == "call" else expr[2:] if op == "let" else
                [expr[1], expr[2], expr[5]] if op == "match" else expr[1:])
    for i, child in enumerate(children):
        result.update(call_sites(child, f"{site}/{i}"))
    return result


def event_wellformed(row, s):
    sites = call_sites(row[3], "main")
    for name, (_, _, body) in fx.function_table(row[3]).items():
        sites.update(call_sites(body, name))
    active, next_id = [], 1
    for e in s["events"]:
        if e[0] == "E":
            _, name, inv, parent, args, site = e
            eq(inv, next_id, "invocation sequence")
            next_id += 1
            eq(parent, active[-1][0] if active else 0, "dynamic parent")
            eq(sites.get(site), name, "source call site")
            eq([r[0] for r in args], [p[1] for p in fx.FUNCTIONS[name][0]], "argument kinds")
            active.append([inv, name, parent])
        elif e[0] == "R":
            require(bool(active), "Return without Enter")
            eq(e[1], active[-1][0], "nested Return")
            eq(e[2][0], fx.FUNCTIONS[active[-1][1]][1], "return kind")
            active.pop()
    eq(s["frames"], list(reversed(active)), "frames equal unreturned entries")


def snapshot(row, s):
    heap = cells(s)
    eq(s["steps"], len(s["actions"]), "cumulative action count")
    eq(s["memoryOperations"], [e[:2] for e in s["events"] if e[0] in "CWF"], "primitive provenance")
    eq(s["outside"], [addr(a) for a in fx.STARTS[row[2]]["outside"]], "outside multiset")
    expected = []
    for b in s["bindings"]:
        if b[3] == HOLD:
            require(b[2][0] == "L" and b[2][1] is not None, "non-list counted binder")
            expected.append(("binding", b[0], b[2], b[4]))
    for i, (raw, value) in enumerate(s["slots"]):
        eq(read(s, raw), value, "slot immutable value")
        if raw[0] == "L" and raw[1] is not None:
            role = "answer" if s["actions"][-1:] == ["Finish"] else "cleanup" if i == 0 and s["tasks"].startswith("[Full.Counted.Task.givePending") else "operand"
            expected.append((role, len(s["slots"])-1-i, raw, value))
    for a, (_, tail, _, status) in heap.items():
        if status == "live" and tail is not None:
            expected.append(("edge", a, ["L", tail], read(s, ["L", tail])))
    initial = {addr(a): (n, addr(t)) for a, n, t, _ in fx.STARTS[row[2]]["cells"]}
    for i, a in enumerate(s["outside"]):
        if a is not None:
            expected.append(("outside", i, ["L", a], fx.walk(initial, a)[1]))
    actual = [(h["role"], h["id"], h["raw"], h["value"]) for h in s["holders"]]
    eq(actual, expected, "holder inventory/order (frame args are nonowning)")
    counts = Counter()
    for _, _, raw, value in actual:
        eq(read(s, raw), value, "protected readback")
        counts[raw[1]] += 1
    reserved = [r[2] for r in s["reservations"]]
    eq(len(set(reserved)), len(reserved), "duplicate reservation")
    eq(set_as_list(reserved), sorted(a for a, c in heap.items() if c[3] == "aside"), "aside/reservation bijection")
    for a, (_, tail, count, status) in heap.items():
        eq(count, counts[a], f"holder multiplicity at {a}")
        if status == "aside":
            eq([tail, count], [None, 0], "reservation detached")
        elif count == 0:
            require(s["tasks"].startswith(f"[Full.Counted.Task.free {a},"), "zero-live lacks next cleanup task")
    event_wellformed(row, s)


def set_as_list(xs):
    return sorted(set(xs))


def trajectory(row, obs):
    trace = obs["trace"]
    if not trace:
        snapshot(row, obs["state"])
        return
    eq(trace[0]["steps"], 0, "begun state")
    eq(normalized(obs["state"]), trace[-1], "trace reaches exported state")
    for s in trace:
        snapshot(row, s)
    for before, after in zip(trace, trace[1:]):
        if after == before:
            require(obs["status"] == "failed" and after == trace[-1], "unexpected no-op action")
            continue
        eq(after["steps"], before["steps"]+1, "one committed action")
        eq(after["actions"][:-1], before["actions"], "history prefix")
        eq(after["events"][:len(before["events"])], before["events"], "event prefix")
        eq(after["memoryOperations"][:len(before["memoryOperations"])], before["memoryOperations"], "memory prefix")
        old = {b[0]: b for b in before["bindings"]}
        for b in after["bindings"]:
            if b[0] in old:
                eq(b[:3]+b[4:], old[b[0]][:3]+old[b[0]][4:], "immutable binding association")
        eq([b[0] for b in after["bindings"]], list(range(len(after["bindings"]))), "binding acquisition order")
        delta = after["events"][len(before["events"]):]
        require(len(delta) <= 1, "multiple events in one committed action")
        aheap, bheap = cells(after), cells(before)
        created = {e[1] for e in delta if e[0] == "C"}
        freed = {e[1] for e in delta if e[0] == "F"}
        written = {e[1] for e in delta if e[0] == "W"}
        eq(sorted(aheap), sorted((set(bheap) | created) - freed), "no unlogged allocation/free")
        for a in set(aheap) & set(bheap) - written:
            eq(aheap[a][0], bheap[a][0], "no unlogged item write")
            if aheap[a][1] != bheap[a][1]:
                eq(after["actions"][-1], "Decompose", "only unique detach changes link without Write")
                eq(aheap[a][1:], [None, 0, "aside"], "unique detach")
        for e in delta:
            if e[0] in "CW":
                eq(after["actions"][-1], "Primitive", "construction action")
                eq(aheap[e[1]][:2], e[2:], "recorded item/link")
                if e[0] == "C":
                    require(e[1] not in bheap, "Create must be fresh")
                else:
                    eq(bheap[e[1]][1:], [None, 0, "aside"], "Write requires aside")
                    current = before["frames"][0][0] if before["frames"] else 0
                    require(any(r[0] == current and r[2] == e[1] for r in before["reservations"]), "cross-call reservation Write")
            if e[0] == "F":
                require(e[1] in bheap and e[1] not in aheap, "Free must remove allocated cell")
                eq(bheap[e[1]][2], 0, "Free after release, not before")
            if e[0] == "E":
                params = fx.FUNCTIONS[e[1]][0]
                new = after["bindings"][len(before["bindings"]):]
                eq([[b[1], b[2][0]] for b in new], params, "Enter creates all parameters before drops")
                eq([b[2] for b in new], e[4], "argument transfer")
                eq([b[4] for b in new], [v[1] for v in reversed(before["slots"][:len(params)])], "parameter plain values")
                for b in new:
                    eq(b[5:], [e[2], f"{e[1]}/parameter/{b[1]}"], "parameter identity origin")
                    if b[2][0] == "L" and b[2][1] is not None:
                        eq(b[3], HOLD, "unused parameter still held at Enter")
            if e[0] == "R":
                require(not any(r[0] == e[1] for r in after["reservations"]), "Return before branch cleanup")
                require(not any(b[5] == e[1] and b[3] == HOLD for b in after["bindings"]), "Return leaves binding owner")


def predicted_events(row):
    """Handwritten interleavings transcribed from checkpoint BOUNDARIES.

    C10 recursion tables are length-indexed arithmetic, not AST evaluation.
    C11 argument chains are the explicit DERIVATIONS chains.
    """
    cid, ids = row[0], identities(row)
    def L(x): return ["L", ids[x] if isinstance(x, str) else x]
    def I(x): return ["I", x]
    def E(n, i, p, *args): return ["E", n, i, p, list(args)]
    def R(i, x): return ["R", i, x]
    effects = iter(ledger(row))
    def C(): return next(effects)
    if cid in ("C1", "C2"):
        return [E("one",1,0,I(1)), C(), R(1,L("N0")), C()]
    if cid in ("C3", "C4", "C6"):
        head = [E("bump",1,0,L("A")), E("bump",2,1,L("B")), E("bump",3,2,L(None)), R(3,L(None)), C(), R(2,L("N0")), C(), R(1,L("A" if cid == "C6" else "N1"))]
        if cid == "C3":
            return head + [E("choose",4,0,L("A"),L("N1")), C(), C(), R(4,L("A"))]
        return head + [E("first",4,0,L("A" if cid == "C6" else "N1")), C(), C(), R(4,I(2)), E("first",5,0,L("B" if cid == "C6" else "A"))] + ([C()] if cid == "C6" else [C(),C()]) + [R(5,I(2 if cid == "C6" else 1))]
    if cid == "C5":
        return [E("readBoth",1,0,L("A"),L("A")),E("first",2,1,L("A")),R(2,I(1)),E("first",3,1,L("A")),C(),C(),R(3,I(1)),R(1,I(2))]
    if cid == "C7":
        return [E("makeThenDrop",1,0,I(-6)),E("one",2,1,I(-6)),C(),R(2,L("N0")),C(),R(1,I(0))]
    if cid == "C8": return [C(),E("identity",1,0,L("N0")),R(1,L("N0"))]
    if cid == "C9": return [E("outer",1,0,I(-6)),C(),E("identity",2,1,L("N0")),R(2,L("N0")),R(1,L("N0"))]
    if cid.startswith("C10-"):
        fn = row[3][1]
        initial = fx.STARTS[row[2]]
        source = {a:(n,t) for a,n,t,_ in initial["cells"]}
        roots, values, a = [], [], initial["inputs"][0][2]
        while a is not None:
            roots.append(a); n,a = source[a]; values.append(n)
        n = len(roots)
        out = [E(fn,i+1,i,L(a)) for i,a in enumerate(roots+[None])]
        out.append(R(n+1,L(None) if fn == "bump" else I(0)))
        for i in reversed(range(n)):
            if fn == "bump" or not initial["outside"]: out.append(C())
            raw = L(f"N{n-1-i}" if initial["outside"] else roots[i]) if fn == "bump" else I(sum(values[i:]))
            out.append(R(i+1,raw))
        return out
    if cid.startswith("C11-"):
        if cid == "C11-bool": return [E("notFlag",1,0,["B",True]),R(1,["B",False]),E("notFlag",2,0,["B",False]),R(2,["B",True])]
        chain = [("odd",-3)] if cid.endswith("negative") else [("even" if i%2 == 0 else "odd",int(cid[-1])-i) for i in range(int(cid[-1])+1)]
        return [E(f,i+1,i,I(n)) for i,(f,n) in enumerate(chain)] + [R(i,I(row[6])) for i in range(len(chain),0,-1)]
    if cid in ("C12","C13","C14"):
        fn, n, arg = ("spin",7,0) if cid == "C12" else ("spin",3,1) if cid == "C14" else ("allocateForever",2,0)
        if cid == "C13": return [E(fn,1,0,I(0)),C(),C(),E(fn,2,1,I(0)),C(),C()]
        return [E(fn,i+1,i,I(arg)) for i in range(n)]
    if cid == "C15": return [E("one",1,0,I(9)),C(),R(1,L("N0")),E("choose",2,0,L("A"),L("N0")),C(),R(2,L("A"))]
    if cid == "C16": return ledger(row)
    if cid in ("C17","C17-alias"):
        return [E("choose",1,0,L("A"),L("Y" if cid == "C17" else "A"))] + ledger(row) + [R(1,L("A"))]
    if cid == "C18":
        return [E("shadow",1,0,L("A")),E("bump",2,1,L("A")),E("bump",3,2,L("B")),E("bump",4,3,L(None)),R(4,L(None)),C(),R(3,L("N0")),C(),R(2,L("N1")),R(1,L("N1")),E("first",5,0,L("A")),C(),C(),R(5,I(1)),E("first",6,0,L("N1")),C(),C(),R(6,I(2))]
    if cid == "C19": return [E("one",1,0,I(7)),C(),R(1,L("N0")),E("identity",2,0,L("N0")),R(2,L("N0"))]
    if cid.startswith("C20-"):
        out = [E("outerFail",1,0,L("A"))]
        if cid in ("C20-create","C20-control"): out.append(E("one",2,1,I(23)))
        if cid == "C20-control": out += [C(),R(2,L("N0")),E("choose",3,1,L("A"),L("N0")),C(),R(3,L("A")),R(1,L("A"))]
        return out
    if cid == "C21":
        out = [E("weave",i+1,i,L(a)) for i,a in enumerate(["A","B","C",None])] + [R(4,L(None))]
        for i in (3,2,1): out += [C(),C(),R(i,L(f"N{3-i}"))]
        return out
    raise ValueError(f"missing prediction for {cid}")


def at_event(obs, tag, inv):
    for s in obs["trace"]:
        if s["actions"][-1:] == [{"E":"Enter","R":"Return"}[tag]] and s["events"][-1][0] == tag and s["events"][-1][2 if tag == "E" else 1] == inv:
            return s
    raise ValueError(f"missing {tag}{inv}")


def at(obs, n):
    matches = [s for s in obs["trace"] if s["steps"] == n]
    require(bool(matches), f"missing action {n}")
    return matches[0]


def binding(s, i, raw, value, status=HOLD):
    found = [b for b in s["bindings"] if b[0] == i]
    eq(len(found), 1, "required binder exists independently of flags")
    eq(found[0][2:5], [raw,status,value], "required binder/value/status")


def selected(raw):
    for cid in ("C1","C2"):
        end = at_event(raw[cid],"R",1)["steps"]
        start = at_event(raw[cid],"E",1)["steps"]
        for n in range(start,end+1):
            s=at(raw[cid],n); eq(cells(s)[0], [1,None,0,"aside"], "caller reservation preserved")
            eq(s["reservations"], [[0,0,0]], "caller branch ownership")
    s=at(raw["C3"],4)
    binding(s,0,["L",0],[1,2]); eq(s["slots"], [[["L",0],[1,2]]]); eq(cells(s)[0][2],2)
    # Earlier argument is independently required until choose, not merely while
    # the candidate advertises it. Check every intervening exported action.
    for n in range(4,at_event(raw["C3"],"E",4)["steps"]):
        s=at(raw["C3"],n)
        require([["L",0],[1,2]] in s["slots"], "earlier completed argument lost")
        eq(read(s,["L",0]),[1,2])
    s=next(s for s in raw["C3"]["trace"] if s["actions"][-1:] == ["MatchComplete"])
    eq([cells(s)[a][2] for a in (0,1)], [1,2], "shared tail acquisition")
    s=at(raw["C3"],at_event(raw["C3"],"E",4)["steps"]-1)
    eq(s["slots"], [[["L",3],[2,3]],[["L",0],[1,2]]]); eq([c[2] for c in cells(s).values()],[1,1,1,1])
    for cid,ret in (("C4",4),("C18",1)):
        for n in range(at_event(raw[cid],"E",1)["steps"],at_event(raw[cid],"R",ret)["steps"]+1):
            binding(at(raw[cid],n),0,["L",0],[1,2])
    s=at_event(raw["C5"],"R",2); eq([cells(s)[a][2] for a in (0,1)],[1,1]); eq(s["slots"][0],[["I",1],1])
    binding(s,2,["L",0],[1,2])
    s=at_event(raw["C6"],"E",2); eq(cells(s)[1][2],2); eq(cells(s)[0][1:],[None,0,"aside"])
    for cid,root,value,end in (("C6",1,[2],4),("U-tail-demand",1,[9,4],4)):
        for n in range(at_event(raw[cid],"E",1)["steps"],at_event(raw[cid],"R",end)["steps"]+1):
            binding(at(raw[cid],n),1,["L",root],value)
    s=raw["C14"]["state"]; eq(s["cells"],[[0,1,None,0,"aside"]]); eq(s["reservations"],[[0,0,0]]); eq(s["holders"],[])
    s=at_event(raw["C15"],"E",2); binding(s,2,["L",0],[1]); binding(s,3,["L",1],[9])
    for n in range(at_event(raw["C15"],"E",1)["steps"],at_event(raw["C15"],"R",1)["steps"]+1):
        require([["L",0],[1]] in at(raw["C15"],n)["slots"], "C15 earlier argument lost")
    s=at_event(raw["C18"],"E",2)
    binding(s,0,["L",0],[1,2]); binding(s,1,["L",0],[1,2],"Trial.BStatus.movedOn"); binding(s,2,["L",0],[1,2]); eq(s["visibleBindings"],[0,2])
    for n in range(s["steps"],at_event(raw["C18"],"R",2)["steps"]+1):
        require(not any(b[6] == "shadow/binding" for b in at(raw["C18"],n)["bindings"]), "inner shadow binder born before initializer returns")
    for inv,values in ((2,[8]),(3,[15,8]),(4,[11,15,8])):
        s=at_event(raw["C21"],"E",inv)
        eq(s["slots"],[[["I",v],v] for v in values],"distinct ancestor saved scalars")
        eq(sorted([r[0],r[2]] for r in s["reservations"]), [[i,i-1] for i in range(1,inv)])
    for inv,root,value in ((4,None,[]),(3,3,[11,-9]),(2,4,[15,-5,11,-9])):
        s=at_event(raw["C21"],"R",inv)
        eq(s["slots"][0],[["L",root],value],"recursive result pending at Return")
        following=at(raw["C21"],s["steps"]+1)
        eq(following["actions"][-1],"Bind")
        eq(following["bindings"][-1][2], ["L",root])
    s=at_event(raw["U-drop-extra"],"E",2)
    eq([cells(s)[a][2] for a in (0,1)],[1,1]); require(not any(b[1]=="alias" and b[3]==HOLD for b in s["bindings"]),"alias still held")
    s=at_event(raw["U-tail-demand"],"E",2); eq(cells(s)[2][2],2); eq(read(s,["L",1]),[9,4])


def cleanup_pauses(raw):
    eq(raw["C16"]["state"]["actions"], ["Start","Dispatch","Leaf","Bind","GiveUp","Free","GiveUp","Free","Leaf","Handoff","Finish"])
    expected = {5:[[0,1,1,0,"live"],[1,2,None,1,"live"]],6:[[1,2,None,1,"live"]],7:[[1,2,None,0,"live"]],8:[]}
    for n,table in expected.items(): eq(at(raw["C16"],n)["cells"],table)
    eq(at(raw["C16"],6)["holders"],[{"role":"cleanup","id":0,"raw":["L",1],"value":[2]}])
    eq(at(raw["C16"],6)["release"],[0]); eq(at(raw["C16"],7)["release"],[0,1])
    eq(raw["C17"]["state"]["actions"],["Start","Dispatch","Leaf","Capture","Leaf","Capture","Enter","GiveUp","Free","GiveUp","Free","Leaf","Return","Finish"])
    s=at(raw["C17"],7); binding(s,2,["L",0],[1]); binding(s,3,["L",24],[9,-4]); eq(s["frames"],[[1,"choose",0]])
    eq(cells(at(raw["C17"],8))[24],[9,25,0,"live"])
    s=at_event(raw["C17-alias"],"E",1); eq(cells(s)[0][2],2)
    binding(s,1,["L",0],[1]); binding(s,2,["L",0],[1])


def finite_prefixes(raw):
    eq([s["steps"] for s in raw["C12"]["trace"] if s["actions"][-1:]==["Enter"]],list(range(5,30,4)))
    for cid,n in (("C12",7),("C13",2)):
        s=raw[cid]["state"]; eq(s["steps"],29); eq(len(s["frames"]),n); eq(s["cells"],[]); eq(raw[cid]["status"],"suspended"); eq(raw[cid]["raw"],None)
        eq(s["holders"],[]); eq(s["reservations"],[])
        params=[b for b in s["bindings"] if "/parameter/" in b[6]]
        eq([b[2] for b in params],[["I",0]]*n)
    s=at(raw["C13"],28); eq(s["cells"],[[1,0,None,0,"live"]])
    eq([s["steps"] for s in raw["C13"]["trace"] if s["actions"][-1:]==["Enter"]],[5,19])
    eq([s["steps"] for s in raw["C13"]["trace"] if s["actions"][-1:]==["Primitive"]],[12,26])


def accounting(row, obs):
    active, totals, byname, before_demand = [], {}, {}, 0
    for e in obs["state"]["events"]:
        if e[0]=="E": active.append((e[2],e[1])); totals[e[2]]=0; byname.setdefault(e[1],[]).append(e[2])
        elif e[0]=="R": active.pop()
        elif e[0]=="C":
            if not any(name in row[4] for _,name in active): before_demand+=1
            for inv,_ in active: totals[inv]+=1
    cid=row[0]
    if cid in {"C7","C9","C13"}: eq(totals,{"C7":{1:1,2:1},"C9":{1:1,2:0},"C13":{1:2,2:1}}[cid],"inclusive descendant accounting")
    if cid=="C8": eq(totals,{1:0})
    if cid=="C12": eq(list(totals.values()),[0]*7)
    if any(c.startswith(("S1A","S2A")) for c in row[1]):
        eq([totals[i] for name in row[4] for i in byname.get(name,[])], [0]*sum(len(byname.get(name,[])) for name in row[4]),"mandated ideal zero-create intervals")
    if cid in ("U-fresh-demand","U-forward"): eq(before_demand,2 if cid=="U-fresh-demand" else 1)
    if cid in ("U-fresh-demand","U-forward"):
        first = next(i for i,e in enumerate(obs["state"]["events"]) if e[0]=="E" and e[1] in row[4])
        require(all(i < first for i,e in enumerate(obs["state"]["events"]) if e[0]=="C"), "construction must precede first demanded entry")
    if cid in ("U-twice","U-alias-demand"):
        eq(totals[1],2)
        eq(totals[byname["bump"][0]],2)


def budget_checks(raw):
    o=raw["C19"]
    eq(o["state"]["actions"],["Start","Dispatch","Dispatch","Leaf","Capture","Enter","Dispatch","Leaf","Capture","Leaf","Capture","Primitive","Return","Capture","Enter","Leaf","Return","Finish"])
    groups=[[0],[17],[18],[23],[6,6,3,2,1],[0,6,0,11,0,1],[17,1],[18,0,1,23]]
    eq([[p["budget"] for p in g] for g in o["resumes"]],groups)
    for group in o["resumes"]:
        total=0
        for p in group:
            total+=p["budget"]; eq(p["total"],total)
            eq(p["split"],p["whole"],"resume vs uninterrupted exported projection")
            eq(p["whole"],at(o,min(total,18)),"resume vs independently fixed action cut")
    eq(at(o,17)["slots"],[[["L",0],[7]]]); eq(at(o,17)["tasks"],"[Full.Counted.Task.finish]")
    eq(at(o,18)["tasks"],"[]"); eq(at(o,18)["holders"],[{"role":"answer","id":0,"raw":["L",0],"value":[7]}])


def lifecycle(row, obs):
    s,d=obs["state"],obs["destroyed"]
    for key in ("events","actions","steps","memoryOperations","outside"): eq(d[key],s[key],f"destroy preserves {key}")
    for key in ("bindings","slots","holders","frames","reservations","release"):
        if key != "holders": eq(d[key],[],f"destroy clears {key}")
    eq(d["tasks"],"[]")
    initial=fx.STARTS[row[2]]
    graph={addr(a):(n,addr(t)) for a,n,t,_ in initial["cells"]}
    roots=[addr(a) for a in initial["outside"]]
    reached=set().union(*(fx.walk(graph,a)[0] for a in roots)) if roots else set()
    retained={a:graph[a] for a in reached}
    counts=fx.graph(retained,roots)
    eq(sorted(d["cells"]),sorted([a,*graph[a],counts[a],"live"] for a in reached),"exact outside-only destroyed graph")
    eq(sorted(obs["cleanup"]),sorted(set(cells(s))-reached),"separate cleanup frees all nonoutside cells")
    eq(obs["destroyTwiceEqual"],True,"reported internal idempotence flag (not independent second state)")
    expected_roles={"outside","edge"} if reached else set()
    require(all(h["role"] in expected_roles for h in d["holders"]),"destroy leaves run-owned holder")
    for h in d["holders"]: eq(read(d,h["raw"]),h["value"])


def denial_checks(raw):
    for cid,domain,site,count,abort in [("C20-number","number","outerFail/1/0",14,'[(1, "outerFail")]'),("C20-frame","frame","one",16,'[(1, "outerFail")]'),("C20-create","cell","one",22,'[(2, "one"), (1, "outerFail")]')]:
        o=raw[cid]; s=o["state"]
        eq(o["status"],"failed"); eq(s["steps"],count)
        expected=f'some {{ request := {{ domain := Full.Lifecycle.Domain.{domain}, site := "{site}" }}, ordinal := 1, abort := {abort} }}'
        eq(" ".join(o["failure"].split()),expected,"failure domain/site/ordinal/abort")
        eq(o["trace"][-1],o["trace"][-2],"denial preserves projected pre-request execution")
        eq(s["cells"],[[0,1,1,3,"live"],[1,2,None,1,"live"]])
        eq(s["slots"], {"number":[[["I",3],3],[["I",20],20],[["L",0],[1,2]]],"frame":[[["I",23],23],[["L",0],[1,2]]],"cell":[[["L",None],[]],[["I",23],23],[["L",0],[1,2]]]}[domain],"request boundary saved operands")
        head=" ".join(s["tasks"].split())
        require(head.startswith('[Full.Counted.Task.enter "one" 1' if domain=="frame" else f'[Full.Counted.Task.primitive (Full.Op.{"add" if domain=="number" else "cons"})'),"denied action still pending")
        eq(o["cleanup"],[])
    eq(raw["C14"]["cleanup"],[0],"destroy actually frees aside reservation")


def result(row, obs):
    eq(obs["status"],row[9].split(":")[0],"actual status, not adapter label")
    eq(obs["answer"],row[6],"checkpoint answer")
    if row[9] == "finished":
        raw = [row[5], identities(row)[row[7]] if row[5]=="L" and row[7] is not None else None if row[5]=="L" else row[6]]
        eq(obs["raw"],raw,"checkpoint raw result")
        eq(obs["plainAnswer"],row[6],"independent plain final answer vs checkpoint")
        require(obs["state"]["actions"][-1:] == ["Finish"],"finished action missing")
        for key in ("frames","reservations","release"): eq(obs["state"][key],[])
        require(not any(b[3]==HOLD for b in obs["state"]["bindings"]),"Finish leaves binder owner")
        eq(obs["state"]["tasks"],"[]")
    else:
        eq(obs["raw"],None)
        require("Finish" not in obs["state"]["actions"],"nonterminal labeled Finish")


GAPS = {
    "C16-pause-destroy-resume": "No destroy/second-destroy at cuts 5 and 6, or fresh resumed executions at each cleanup cut; continuous trace is not resume evidence.",
    "C12-extra-budget4": "No resume from action29 by budget4; seven-entry finite prefix only.",
    "C19-full-state-observation": "Split/whole omit completeState (next IDs, entered scopes, edge associations, landmarks). No repeated observer operation transcript. Partial equality and fixed budgets checked, not complete F5.",
    "C20-full-transaction": "Pre-denial trace omits completeState; projected equality checked, not all Counted.State fields. Request history is not exported.",
    "second-destroy": "Only destroyTwiceEqual Bool supplied; second lifecycle state, destroyed/status flag, failure retention and second cleanup stream absent.",
    "independent-F2-F3": "requiredBindings and decodedPlain derive from counted tasks. Independent plain successive states, required-value lifetimes/correspondence and administrative rank transitions absent. Selected source-derived owners are checked directly; no universal F2/F3 claim.",
    "all-usefulness-call-predictions": "All 90 call logs checked for source site, kinds, invocation nesting and inclusive accounting; complete independently predicted call sequences only for 35 C rows. Usefulness-only traces missing except U-drop-extra/U-tail-demand, so not all internal usefulness boundaries checked.",
    "proof-checker-mutants": "No proofs, axiom audit, demand checker, executed machine mutants or fresh Lean/trial reconstruction run by acceptance author. Export-consumer negative tests are not machine mutants. Parent-reported trial comparison not independently rerun.",
}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("observations",type=Path)
    p.add_argument("--report",type=Path,required=True)
    args=p.parse_args()
    raw=json.loads((args.observations/"raw.json").read_text(),object_pairs_hook=fx.unique_object)
    inputs=json.loads((args.observations/"inputs.json").read_text(),object_pairs_hook=fx.unique_object)
    results=[]
    def test(name, operation):
        try: operation()
        except (ValueError,KeyError,IndexError,StopIteration,TypeError) as error:
            results.append({"name":name,"status":"FAIL","detail":str(error)})
        else: results.append({"name":name,"status":"PASS"})
    test("case set",lambda:eq(sorted(raw),sorted(ROWS)))
    test("input IDs",lambda:eq([i["id"] for i in inputs],list(ROWS)))
    for inp in inputs:
        row=ROWS[inp["id"]]; start=fx.STARTS[row[2]]
        expected={"cells":[[addr(a),n,addr(t),c] for a,n,t,c in start["cells"]],"inputs":[[n,k,addr(v) if k=="L" else v] for n,k,v in start["inputs"]],"outside":[addr(a) for a in start["outside"]]}
        test(row[0]+" exact input",lambda inp=inp,row=row,expected=expected: eq([inp["main"],inp["start"],inp["functions"]],[row[3],expected,[[n,*f,n in row[4]] for n,f in fx.function_table(row[3]).items()]]))
    for cid,row in ROWS.items():
        o=raw[cid]
        test(cid+" status/result",lambda row=row,o=o:result(row,o))
        test(cid+" primitive ledger",lambda row=row,o=o:eq([e for e in o["state"]["events"] if e[0] in "CWF"],ledger(row)))
        test(cid+" snapshots",lambda row=row,o=o:trajectory(row,o))
        test(cid+" accounting",lambda row=row,o=o:accounting(row,o))
        test(cid+" destruction",lambda row=row,o=o:lifecycle(row,o))
        if cid.startswith("C"):
            test(cid+" exact interleaving",lambda row=row,o=o:eq([e[:5] if e[0]=="E" else e for e in o["state"]["events"]],predicted_events(row)))
    for name,fn in [("selected source-required lifetime cuts",selected),("C16/C17 cleanup schedule",cleanup_pauses),("C12/C13/C22 finite prefixes",finite_prefixes),("C19 budgets (projection)",budget_checks),("C20 denial (projection)",denial_checks)]:
        test(name,lambda fn=fn:fn(raw))
    # Deliberately corrupt exported observations; no machine variant executes.
    negatives=[]
    def negative(name, mutate, checker):
        data=copy.deepcopy(raw); mutate(data)
        try: checker(data)
        except (ValueError,KeyError,IndexError) as error: negatives.append({"name":name,"status":"REJECTED","reason":str(error)})
        else: negatives.append({"name":name,"status":"MISSED"})
    negative("lost required suspended root",lambda d:d["C4"]["trace"][6]["bindings"][0].__setitem__(3,"Trial.BStatus.movedOn"),selected)
    negative("changed pending argument value",lambda d:d["C3"]["trace"][4]["slots"][0].__setitem__(1,[9,2]),selected)
    negative("wrong queued count",lambda d:d["C16"]["trace"][5]["cells"][0].__setitem__(3,1),cleanup_pauses)
    negative("reset saved scalar",lambda d:at_event(d["C21"],"E",4)["slots"][1].__setitem__(1,11),selected)
    negative("restart after suspension",lambda d:d["C19"]["resumes"][4][-1]["split"].__setitem__("steps",1),budget_checks)
    negative("denial commits an action",lambda d:d["C20-number"]["trace"][-1].__setitem__("steps",15),denial_checks)
    negative("no-op destroy",lambda d:d["C14"].__setitem__("destroyed",d["C14"]["state"]),lambda d:lifecycle(ROWS["C14"],d["C14"]))
    negative("destroy frees outside graph",lambda d:d["C20-control"]["destroyed"].__setitem__("cells",[]),lambda d:lifecycle(ROWS["C20-control"],d["C20-control"]))
    negative("omitted descendant Create provenance",lambda d:d["C7"]["state"]["memoryOperations"].pop(0),lambda d:snapshot(ROWS["C7"],d["C7"]["state"]))
    report={"source":"uploaded parent uncommitted exports, not origin/main","inputHashes":{f:hashlib.sha256((args.observations/f).read_bytes()).hexdigest() for f in ("inputs.json","raw.json","summary.json")},"cases":len(raw),"tracedCases":sum(bool(o["trace"]) for o in raw.values()),"traceSnapshots":sum(len(o["trace"]) for o in raw.values()),"checks":results,"consumerNegatives":negatives,"gaps":GAPS}
    args.report.write_text(json.dumps(report,indent=2)+"\n")
    failures=[r for r in results if r["status"]=="FAIL"]
    missed=[r for r in negatives if r["status"]=="MISSED"]
    for r in failures: print("FAIL",r["name"],r["detail"])
    print(f"CHECKS: {len(results)-len(failures)} passed; {len(failures)} failed; {len(negatives)-len(missed)}/{len(negatives)} consumer corruptions rejected")
    print(f"COVERAGE: {len(raw)} cases; {report['tracedCases']} traced; {report['traceSnapshots']} snapshots; {len(GAPS)} evidence-gap groups remain")
    print("NOT a scientific freeze, proof, independent plain simulation, or executed machine-mutant test")
    raise SystemExit(1 if failures or missed else 0)


if __name__=="__main__":
    main()
