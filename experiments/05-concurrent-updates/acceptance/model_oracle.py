"""Lead-authored two-attempt authority model, fixed before builder code."""
import copy
import json
import re
from collections import deque
from pathlib import Path


def initial():
    return dict(issued=0, pending=0, running=[], expired=[], committed=[], ignored=[], epoch=0)


def key(s):
    return json.dumps(s, sort_keys=True, separators=(",", ":"))


def step(before, action):
    s = copy.deepcopy(before)
    if action.startswith("Begin"):
        n = int(action[-1])
        if s["pending"] == 0 and s["issued"] == n - 1:
            s.update(issued=n, pending=n, running=sorted(s["running"] + [n]))
    elif action == "Timeout":
        if s["pending"]:
            s["expired"] = sorted(s["expired"] + [s["pending"]])
            s["pending"] = 0
    else:
        n = int(action[-1])
        if n in s["running"]:
            s["running"].remove(n)
            if s["pending"] == n:
                s["committed"].append(n)
                s["epoch"] += 1
                s["pending"] = 0
            else:
                s["ignored"] = sorted(s["ignored"] + [n])
    return s


def explore():
    states = {key(initial())}
    todo = deque([initial()])
    edges = set()
    while todo:
        before = todo.popleft()
        for action in ("Begin1", "Begin2", "Timeout", "Return1", "Return2"):
            after = step(before, action)
            a, b = key(before), key(after)
            if a == b:
                continue
            edges.add((a, action, b))
            if b not in states:
                states.add(b)
                todo.append(after)
    return states, edges


def check(path):
    states, edges = explore()
    nodes, actual, initial_nodes = {}, [], []
    for line in Path(path).read_text().splitlines():
        match = re.match(r'^(-?\d+) -> (-?\d+) \[label="([^"]+)"', line)
        if match:
            actual.append(match.groups())
            continue
        match = re.match(r'^(-?\d+) \[label="((?:\\.|[^"\\])*)"', line)
        if not match:
            continue
        fingerprint, raw = match.groups()
        data = {}
        for field in json.loads('"' + raw + '"').splitlines():
            name, value = field.removeprefix("/\\ ").split(" = ", 1)
            if value.startswith(("{", "<<")):
                body = value[1:-1] if value.startswith("{") else value[2:-2]
                data[name] = [int(n.strip()) for n in body.split(",") if n.strip()]
                if name != "committed":
                    data[name].sort()
            else:
                data[name] = int(value)
        nodes[fingerprint] = key(data)
        if "style = filled" in line:
            initial_nodes.append(fingerprint)
    assert len(initial_nodes) == 1 and nodes[initial_nodes[0]] == key(initial())
    assert set(nodes.values()) == states, "model state-set mismatch"
    observed = {(nodes[a], op, nodes[b]) for a, b, op in actual if nodes[a] != nodes[b]}
    assert observed == edges, "model edge-set mismatch"
    return {"states": len(states), "edges": len(edges)}


if __name__ == "__main__":
    s = initial()
    for op in ["Begin1", "Timeout", "Begin2", "Return2", "Return1"]:
        s = step(s, op)
    assert s == dict(issued=2, pending=0, running=[], expired=[1], committed=[2], ignored=[1], epoch=1)
    states, edges = explore()
    print(json.dumps({"states": len(states), "edges": len(edges)}))
