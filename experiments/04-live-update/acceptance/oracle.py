"""Lead-authored finite public contract; independent of builder implementation."""
import copy
import json
from collections import deque

COMMANDS = ["enqueue 1", "enqueue 2", "enqueue 3", "start", "finish", "begin",
            "prepare", "copy", "corrupt", "validate", "activate", "fail", "tick"]
ACTIONS = dict(zip(["Enqueue1", "Enqueue2", "Enqueue3", "Start", "Finish", "Begin",
                    "Prepare", "Copy", "Corrupt", "Validate", "Activate", "Fail", "Tick"],
                   COMMANDS))


def initial():
    return dict(version=1, phase="running", queue=[], flight=0, flight_version=0,
                accepted=[], completed=[], completed_values=[], candidate=[], corrupt=False, remaining=0,
                attempted=False, outcome="none")


def key(state):
    return json.dumps(state, sort_keys=True, separators=(",", ":"))


def step(before, command):
    s = copy.deepcopy(before)
    status = "ok"

    def refuse():
        s.update(phase="running", outcome="refused", remaining=0,
                 candidate=[], corrupt=False)

    if command == "reset":
        s = initial()
    elif command == "snapshot":
        pass
    elif command.startswith("enqueue ") and command in COMMANDS[:3]:
        job = int(command[-1])
        if job in s["accepted"]:
            status = "duplicate"
        elif s["phase"] in ("copying", "ready") or len(s["queue"]) + bool(s["flight"]) >= 2:
            status = "busy"
        else:
            s["queue"].append(job)
            s["accepted"] = sorted(s["accepted"] + [job])
    elif command == "start":
        if s["phase"] == "running" and not s["flight"] and s["queue"]:
            s["flight"] = s["queue"].pop(0)
            s["flight_version"] = s["version"]
        else:
            status = "blocked"
    elif command == "finish":
        if s["flight"]:
            s["completed"].append(s["flight"])
            s["completed_values"].append(s["flight"] * 10)
            s.update(flight=0, flight_version=0)
        else:
            status = "blocked"
    elif command == "begin":
        if s["phase"] == "running" and s["version"] == 1 and not s["attempted"]:
            s.update(phase="draining", attempted=True, remaining=3, outcome="pending")
        else:
            status = "blocked"
    elif command == "prepare":
        if s["phase"] == "draining" and not s["flight"]:
            s.update(phase="copying", candidate=[])
        else:
            status = "blocked"
    elif command == "copy":
        if s["phase"] == "copying" and len(s["candidate"]) < len(s["queue"]):
            s["candidate"].append(s["queue"][len(s["candidate"])])
        else:
            status = "blocked"
    elif command == "corrupt":
        if s["phase"] in ("copying", "ready") and not s["corrupt"]:
            s["corrupt"] = True
        else:
            status = "blocked"
    elif command == "validate":
        if s["phase"] == "copying":
            if s["candidate"] == s["queue"] and not s["corrupt"]:
                s["phase"] = "ready"
            else:
                refuse()
        else:
            status = "blocked"
    elif command == "activate":
        if s["phase"] == "ready":
            if s["corrupt"] or s["flight"] or s["candidate"] != s["queue"]:
                refuse()
            else:
                s.update(version=2, phase="running", outcome="activated", remaining=0,
                         candidate=[], corrupt=False)
        else:
            status = "blocked"
    elif command == "fail":
        if s["outcome"] == "pending":
            refuse()
        else:
            status = "blocked"
    elif command == "tick":
        if s["outcome"] == "pending":
            if s["remaining"] == 1:
                refuse()
            else:
                s["remaining"] -= 1
        else:
            status = "blocked"
    else:
        status = "invalid"
    return {"status": status, "state": s}


def explore():
    first = initial()
    paths = {key(first): []}
    states = {key(first): first}
    edges = set()
    todo = deque([first])
    while todo:
        before = todo.popleft()
        source = key(before)
        for command in COMMANDS:
            after = step(before, command)["state"]
            target = key(after)
            if source == target:
                continue
            edges.add((source, command, target))
            if target not in states:
                states[target] = after
                paths[target] = paths[source] + [command]
                todo.append(after)
    return states, paths, edges


# Explicit hand-written examples prevent an empty or all-rejecting oracle from
# accepting everything merely by internal agreement.
EXAMPLES = {
    "successful non-ID FIFO order": (
        ["enqueue 3", "enqueue 1", "begin", "prepare", "copy", "copy", "validate", "activate",
         "start", "finish", "start", "finish"],
        dict(version=2, phase="running", queue=[], flight=0, flight_version=0,
             accepted=[1, 3], completed=[3, 1], completed_values=[30, 10], candidate=[], corrupt=False,
             remaining=0, attempted=True, outcome="activated")),
    "drain timeout keeps active job": (
        ["enqueue 2", "start", "begin", "tick", "tick", "tick"],
        dict(version=1, phase="running", queue=[], flight=2, flight_version=1,
             accepted=[2], completed=[], completed_values=[], candidate=[], corrupt=False,
             remaining=0, attempted=True, outcome="refused")),
    "partial copy is refused": (
        ["enqueue 3", "enqueue 1", "begin", "prepare", "copy", "validate"],
        dict(version=1, phase="running", queue=[3, 1], flight=0, flight_version=0,
             accepted=[1, 3], completed=[], completed_values=[], candidate=[], corrupt=False,
             remaining=0, attempted=True, outcome="refused")),
}

CONTROL_TRACES = {
    "lost_work": ["enqueue 2", "begin", "prepare", "copy", "validate", "activate"],
    "duplicate_completion": ["enqueue 1", "start", "finish"],
    "premature_activation": ["enqueue 1", "start", "begin", "activate"],
    "corrupt_activation": ["enqueue 3", "begin", "prepare", "copy", "validate", "corrupt", "activate"],
    "expired_activation": ["begin", "prepare", "validate", "tick", "tick", "tick", "activate"],
}


def control_mutation(name, expected):
    """Known-wrong public transition applied only to last response of a trace."""
    actual = copy.deepcopy(expected)
    s = actual["state"]
    if name == "lost_work":
        s["queue"] = []
    elif name == "duplicate_completion":
        s["completed"] *= 2
    elif name in ("premature_activation", "corrupt_activation", "expired_activation"):
        actual["status"] = "ok"
        s.update(version=2, outcome="activated", phase="running", remaining=0)
    else:
        raise AssertionError(name)
    return actual


def check_oracle():
    for name, (commands, expected) in EXAMPLES.items():
        s = initial()
        for command in commands:
            reply = step(s, command)
            assert reply["status"] == "ok", (name, command, reply)
            s = reply["state"]
        assert s == expected, (name, s, expected)
    for name, commands in CONTROL_TRACES.items():
        s = initial()
        for command in commands:
            reply = step(s, command)
            s = reply["state"]
        assert control_mutation(name, reply) != reply, name
    return list(EXAMPLES), list(CONTROL_TRACES)


if __name__ == "__main__":
    check_oracle()
    states, paths, edges = explore()
    print(json.dumps({"states": len(states), "edges": len(edges),
                      "max_shortest_path": max(map(len, paths.values()))}))
