"""Acceptance trace predictor, not an explicit-state/resumable Mo interpreter.

This host-recursive logical reference records proposed committed action boundaries.
It has no candidate storage, resume/destroy API, or resource-envelope capability.
Control dumps are normalized predictions, not a prescribed host frame layout.
"""
from copy import deepcopy

from call_reference import CallReference


def children(e):
    if e[0] in ("num", "bool", "nil", "var"): return []
    if e[0] == "call": return list(e[2])
    if e[0] == "let": return list(e[2:])
    if e[0] == "match": return [e[1], e[2], e[5]]
    return list(e[1:])


class TransitionReference(CallReference):
    def __init__(self, program, cells, inputs, outside, landmark_limit=10000):
        super().__init__(program, cells, inputs, outside, landmark_limit)
        self.trace, self.sites, self.context = [], {}, []
        self.releasing, self.root_value = [], None
        def index(e, path):
            self.sites[id(e)] = path
            for i, child in enumerate(children(e)): index(child, f"{path}/{i}")
        index(program["main"], "main")
        for i, f in enumerate(program["functions"]): index(f[3], f"function/{i}/body")

    def eval(self, e, env, rest, enclosing):
        entry = dict(expr=e, scope=[list(item) for item in env.items()], invocation=self.frames[-1] if self.frames else 0, completed=[])
        self.context.append(entry)
        try:
            value = super().eval(e, env, rest, enclosing)
        finally:
            self.context.pop()
        if self.context: self.context[-1]["completed"].append(value)
        else: self.root_value = value
        return value

    def release(self, addr):
        if addr is None: return
        self.releasing.append(addr)
        try: super().release(addr)
        finally: self.releasing.pop()

    def commit(self, transition, landmark=None, value=None):
        current = self.context[-1] if self.context else None
        ready = value
        if current:
            e = current["expr"]
            if transition == "Leaf":
                if e[0] == "num": ready = ["n", str(e[1])]
                elif e[0] == "bool": ready = ["b", e[1]]
                elif e[0] == "nil": ready = ["l", None]
                else: ready = self.bindings[dict(current["scope"])[e[1]]][2]
            if transition == "Primitive result" and e[0] == "cons": ready = self.pending[0]
            if transition in ("Handoff", "Return") and current["completed"]: ready = current["completed"][-1]
            if transition in ("Bind", "Enter", "Primitive result", "Match decompose", "Branch start", "Handoff", "Return"):
                current["completed"] = []
        if transition == "Finish": ready = self.root_value
        control = [dict(site=self.sites[id(c["expr"])], scope=c["scope"], invocation=c["invocation"],
                        operands=c["completed"]) for c in self.context]
        aside = [a for group in self.spilled for a in group] + self.aside
        state = dict(kind=None if landmark is None else self.states[landmark]["kind"],
                     memory=self.cells, bindings=[b for b in self.bindings if b[0] in self.scope or b[3] == "holding"],
                     pending=self.pending, outside=self.outside, aside=aside,
                     branch=None if landmark is None else self.states[landmark]["branch"], frames=self.frames)
        self.trace.append(deepcopy(dict(step=len(self.trace) + 1, transition=transition,
                           site=self.sites[id(current["expr"])] if current else "root",
                           event_end=len(self.events), landmark=landmark, state=state,
                           control=control, ready=ready, release=self.releasing)))


def trace_projection(reference):
    """Every mandatory logical landmark occurs once in order, with every field."""
    projected = [t["state"] for t in reference.trace if t["landmark"] is not None]
    assert projected == reference.states, "fine trace/historical landmark disagreement"
    assert [t["landmark"] for t in reference.trace if t["landmark"] is not None] == list(range(len(reference.states)))
    assert [t["step"] for t in reference.trace] == list(range(1, len(reference.trace) + 1))
    ends = [t["event_end"] for t in reference.trace]
    assert ends == sorted(ends), "event prefix went backwards"
    if reference.trace[-1]["transition"] == "Finish": assert ends[-1] == len(reference.events)
