"""Small counted acceptance predictor; NOT the explicit-state Mo interpreter.

Host recursion, logical cells and historical landmarks deliberately simplify this
reference. It cannot prove physical reuse, no-host-stack execution, all fine-grained
suspension steps, or allocator failure recovery. Those require the future builder.
Predictions in cases.py are written separately, before comparison with this model.
"""
from copy import deepcopy
from finite_reference import Environment, FiniteReference, uses


class ObservationEnd(Exception):
    pass


class Records(list):
    def __init__(self, owner):
        self.owner = owner
        super().__init__()

    def append(self, event):
        super().append(event)
        self.owner.events.append([*event])


class CallReference(FiniteReference):
    def __init__(self, program, cells, inputs, outside, landmark_limit=10000):
        super().__init__(cells, inputs, outside)
        self.table = {f[0]: f for f in program["functions"]}
        self.events, self.frames, self.spilled = [], [], []
        self.next_frame = 1
        self.record = Records(self)
        self.limit = landmark_limit

    def snapshot(self, kind, transition, branch=None):
        super().snapshot(kind, transition, branch)
        self.states[-1]["aside"] = deepcopy([a for group in self.spilled for a in group] + self.aside)
        self.states[-1]["frames"] = list(self.frames)
        if len(self.states) >= self.limit:
            raise ObservationEnd()

    def eval(self, e, env, rest, enclosing):
        if e[0] != "call": return super().eval(e, env, rest, enclosing)
        self.commit("Dispatch compound")
        args = []
        for index, arg in enumerate(e[2]):
            later = [(a, env) for a in e[2][index + 1:]] + rest
            args.append(self.eval(arg, env, later, enclosing))
            self.commit("Operand capture")
        name, params, _, body, _, _ = self.table[e[1]]
        frame = self.next_frame; self.next_frame += 1
        parent = self.frames[-1] if self.frames else 0
        self.events.append(["enter", frame, parent, name])
        self.frames.append(frame)
        inner = Environment()
        # Pending values are a stack; transfer in reverse, bind in declaration order.
        for value in reversed(args): self.pop(value)
        for (param, _, _, _), value in zip(params, args):
            status = "holding" if value[0] == "l" and value[1] is not None else "noHolder"
            inner[param] = self.bind(param, value, status)
        caller_aside = self.aside
        self.spilled.append(caller_aside); self.aside = []
        self.enter(inner); self.snapshot("callEntered", "Enter")
        for ident in inner.values():
            if self.bindings[ident][3] == "holding" and not uses(body, inner, ident):
                self.release_binding(ident)
        answer = self.eval(body, inner, [], [])
        assert not self.aside, "callee reservation survived return"
        self.aside = self.spilled.pop()
        self.frames.pop(); self.enter(env)
        self.events.append(["return", frame])
        self.snapshot("callReturned", "Return")
        return answer

    def observe(self, main):
        try:
            outcome = self.run(main)
            return dict(status="finished", outcome=outcome, events=self.events)
        except ObservationEnd:
            return dict(status="reference-prefix", events=self.events,
                        states=self.states, memory=self.cells)


def immutable_answer(program, values, limit=10000, acquisitions=None):
    """Tuple reference; optional binding predictions never read ownership dumps.

    Binding numbers follow source evaluation: inputs, completed let initializers,
    matched head/tail, and parameters after all explicit arguments finish.
    """
    table = {f[0]: f for f in program["functions"]}
    visits = 0
    next_binding = 0
    def acquire(value):
        nonlocal next_binding
        if acquisitions is not None: acquisitions[next_binding] = value
        next_binding += 1
        return value
    for name, *_ in program["inputs"]: acquire(values[name])
    def evaluate(e, env):
        nonlocal visits
        visits += 1
        if visits > limit: raise ObservationEnd()
        op = e[0]
        if op in ("num", "bool"): return e[1]
        if op == "nil": return ()
        if op == "var": return env[e[1]]
        if op == "let": return evaluate(e[3], env | {e[1]: acquire(evaluate(e[2], env))})
        if op == "if": return evaluate(e[2] if evaluate(e[1], env) else e[3], env)
        if op == "match":
            xs = evaluate(e[1], env)
            return evaluate(e[2], env) if not xs else evaluate(e[5], env | {e[3]: acquire(xs[0]), e[4]: acquire(xs[1:])})
        if op == "call":
            _, params, _, body, _, _ = table[e[1]]
            args = [evaluate(arg, env) for arg in e[2]]
            return evaluate(body, {p[0]: acquire(v) for p, v in zip(params, args)})
        a, b = evaluate(e[1], env), evaluate(e[2], env)
        if op == "cons": return (a,) + b
        if op == "add": return a + b
        if op == "sub": return a - b
        if op == "eq": return a == b
        if op == "lt": return a < b
        if op == "le": return a <= b
        raise AssertionError(op)
    return evaluate(program["main"], values)
