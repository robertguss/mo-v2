"""Acceptance reference for the call-free historical ownership landmarks.

Reads input expression/fixture only. Never reads an expected snapshot/result.
Python recursion is intentional reference simplicity, not an execution proposal.
This is not the Stage B interpreter and cannot be used as the Mo implementation.
"""
from copy import deepcopy


class Environment(dict):
    """Nearest lookup plus every lexical binding, including shadowed spellings."""
    def __init__(self):
        super().__init__()
        self.order = []

    def __setitem__(self, name, ident):
        self.order.append(ident)
        super().__setitem__(name, ident)

    def __or__(self, bindings):
        result = Environment()
        dict.update(result, self)
        result.order = list(self.order)
        for name, ident in bindings.items(): result[name] = ident
        return result

    def values(self):
        return iter(self.order)


def decode(wire):
    words = iter(wire.split())
    cells = []
    for _ in range(int(next(words))):
        a, n, t, count = (int(next(words)) for _ in range(4))
        cells.append([a, str(n), t or None, count, "live"])
    inputs = []
    for _ in range(int(next(words))):
        name, kind, value = next(words), next(words), next(words)
        inputs.append((name, [kind, (int(value) or None) if kind == "l" else
                              (value == "1" if kind == "b" else value)]))
    outside = [(int(next(words)) or None) for _ in range(int(next(words)))]
    def expression():
        op = next(words)
        if op == "num": return (op, int(next(words)))
        if op == "var": return (op, next(words))
        if op == "nil": return (op,)
        if op == "let":
            name = next(words); return (op, name, expression(), expression())
        if op == "match":
            h, t = next(words), next(words)
            return (op, expression(), expression(), h, t, expression())
        arity = 3 if op == "if" else 2
        assert op in ("add", "sub", "eq", "lt", "le", "cons", "if"), op
        return (op, *(expression() for _ in range(arity)))
    expr = expression()
    assert next(words, None) is None, "trailing wire input"
    return expr, cells, inputs, outside


def uses(e, env, ident):
    op = e[0]
    if op in ("num", "bool", "nil"): return False
    if op == "var": return env.get(e[1]) == ident
    if op == "let":
        return uses(e[2], env, ident) or uses(e[3], env | {e[1]: None}, ident)
    if op == "match":
        return (uses(e[1], env, ident) or uses(e[2], env, ident) or
                uses(e[5], env | {e[3]: None, e[4]: None}, ident))
    if op == "call": return any(uses(arg, env, ident) for arg in e[2])
    return any(uses(child, env, ident) for child in e[1:])


class FiniteReference:
    def __init__(self, cells, inputs, outside):
        self.cells = deepcopy(cells)
        self.inputs, self.outside = deepcopy(inputs), list(outside)
        self.bindings, self.scope, self.pending, self.aside = [], [], [], []
        self.record, self.states, self.transitions = [], [], []
        self.next_cell = max([c[0] + 1 for c in cells] + [0])
        self.next_branch = 0

    def snapshot(self, kind, transition, branch=None):
        # Read reference memory at the transition; never copy a Lean snapshot.
        self.states.append(deepcopy(dict(kind=kind, memory=self.cells,
            bindings=[b for b in self.bindings if b[0] in self.scope or b[3] == "holding"],
            pending=self.pending, outside=self.outside, aside=self.aside, branch=branch)))
        self.transitions.append(transition)
        self.commit(transition, len(self.states) - 1)

    def commit(self, transition, landmark=None, value=None):
        """Optional fine-grained prediction hook; no runtime observation/resume API."""
        pass

    def cell(self, addr):
        return next(c for c in self.cells if c[0] == addr)

    def bind(self, name, value, status):
        ident = len(self.bindings)
        self.bindings.append([ident, name, value, status])
        return ident

    def enter(self, env):
        self.scope = list(env.values())

    def push(self, value):
        if value[0] == "l" and value[1] is not None: self.pending.insert(0, value)

    def pop(self, value):
        if value[0] == "l" and value[1] is not None:
            assert self.pending.pop(0) == value, "pending order"

    def release(self, addr):
        if addr is None: return
        c = self.cell(addr)
        assert c[3] > 0 and c[4] == "live"
        c[3] -= 1
        self.snapshot("holderGivenUp", "Give up holder")
        if c[3] == 0:
            tail = c[2]
            self.cells.remove(c)
            self.record.append(["free", addr])
            self.push(["l", tail])
            self.snapshot("cellFreed", "Free cell")
            self.pop(["l", tail])
            self.release(tail)

    def release_binding(self, ident):
        b = self.bindings[ident]; b[3] = "givenUp"
        if b[2][0] == "l": self.release(b[2][1])

    def later(self, rest, ident):
        return any(uses(e, env, ident) for e, env in rest)

    def dead(self, env, rest):
        for ident in env.values():
            b = self.bindings[ident]
            if b[3] == "holding" and not self.later(rest, ident): self.release_binding(ident)

    def finish_branch(self, bid, inner, outer, value):
        self.enter(inner)
        self.snapshot("branchValueWorkedOut", "Branch result/cleanup", value)
        while self.aside and self.aside[0][0] == bid:
            _, addr = self.aside.pop(0)
            self.cells.remove(self.cell(addr)); self.record.append(["free", addr])
            self.snapshot("cellFreed", "Free cell")
        assert all(b != bid for b, _ in self.aside)
        self.enter(outer)
        self.snapshot("branchValueHandedOn", "Handoff", value)
        return value

    def eval(self, e, env, rest, enclosing):
        op = e[0]
        if op in ("num", "bool", "nil"):
            self.commit("Leaf")
            if op == "num": return ["n", str(e[1])]
            if op == "bool": return ["b", e[1]]
            return ["l", None]
        if op == "var":
            ident = env[e[1]]; b = self.bindings[ident]; value = b[2]
            if value[0] == "l" and value[1] is not None:
                assert b[3] == "holding"
                if self.later(rest, ident):
                    self.cell(value[1])[3] += 1; kind = "newHolder"
                else:
                    b[3] = "movedOn"; kind = "holderMoved"
                self.push(value); self.enter(env); self.snapshot(kind, "Leaf")
            else: self.commit("Leaf")
            return value
        if op in ("add", "sub", "eq", "lt", "le", "cons"):
            self.commit("Dispatch compound")
            x = self.eval(e[1], env, [(e[2], env)] + rest, enclosing)
            self.commit("Operand capture")
            y = self.eval(e[2], env, rest, enclosing)
            self.commit("Operand capture")
            if op == "cons":
                self.enter(env); assert x[0] == "n" and y[0] == "l"
                if self.aside:
                    bid, addr = self.aside.pop(0); assert bid in enclosing
                    c = self.cell(addr); c[:] = [addr, x[1], y[1], 1, "live"]
                    self.record.append(["write", addr])
                else:
                    addr = self.next_cell; self.next_cell += 1
                    self.cells.append([addr, x[1], y[1], 1, "live"])
                    self.record.append(["create", addr])
                value = ["l", addr]; self.pop(y); self.push(value)
                self.snapshot("newCellBuilt", "Primitive result"); return value
            a, b = int(x[1]), int(y[1])
            if op == "add": value = ["n", str(a + b)]
            elif op == "sub": value = ["n", str(a - b)]
            else: value = ["b", {"eq": a == b, "lt": a < b, "le": a <= b}[op]]
            self.commit("Primitive result", value=value)
            return value
        if op == "let":
            self.commit("Dispatch compound")
            future = env | {e[1]: None}
            value = self.eval(e[2], env, [(e[3], future)] + rest, enclosing)
            status = "holding" if value[0] == "l" and value[1] is not None else "noHolder"
            ident = self.bind(e[1], value, status)
            # Preserve lexical binding order, including shadowed outer bindings.
            inner = env | {e[1]: ident}
            self.pop(value); self.enter(inner)
            if status == "holding": self.snapshot("nameBound", "Bind")
            else: self.commit("Bind")
            if status == "holding" and not uses(e[3], inner, ident): self.release_binding(ident)
            answer = self.eval(e[3], inner, rest, enclosing)
            self.commit("Handoff")
            return answer
        if op in ("if", "match"):
            self.commit("Dispatch compound")
            if op == "if":
                future = [(e[2], env), (e[3], env)] + rest
            else:
                future = [(e[2], env), (e[5], env | {e[3]: None, e[4]: None})] + rest
            value = self.eval(e[1], env, future, enclosing)
            self.enter(env)
            self.snapshot("branchChosen", "Choose branch")
            if op == "if":
                chosen = e[2] if value[1] else e[3]
                self.dead(env, [(chosen, env)] + rest)
                self.enter(env); self.snapshot("branchStarts", "Branch start")
                answer = self.eval(chosen, env, rest, enclosing)
                self.commit("Handoff")
                return answer
            bid = self.next_branch; self.next_branch += 1
            if value[1] is None:
                self.dead(env, [(e[2], env)] + rest)
                self.enter(env); self.snapshot("branchStarts", "Branch start")
                answer = self.eval(e[2], env, rest, [bid] + enclosing)
                return self.finish_branch(bid, env, env, answer)
            self.dead(env, [(e[5], env | {e[3]: None, e[4]: None})] + rest)
            c = self.cell(value[1]); tail = c[2]
            head_id = self.bind(e[3], ["n", c[1]], "noHolder")
            tail_id = self.bind(e[4], ["l", tail], "noHolder")
            inner = env | {e[3]: head_id, e[4]: tail_id}
            used = uses(e[5], inner, tail_id)
            if c[3] == 1:
                self.pop(value); c[2], c[3], c[4] = None, 0, "aside"
                self.aside.insert(0, [bid, c[0]])
                if tail is not None: self.bindings[tail_id][3] = "holding"
                self.enter(inner); self.snapshot("matchStep4Done", "Match decompose")
                if tail is not None and not used: self.release_binding(tail_id)
            else:
                if tail is not None and used:
                    self.cell(tail)[3] += 1; self.bindings[tail_id][3] = "holding"
                    self.enter(inner); self.snapshot("newHolder", "Match decompose")
                else: self.commit("Match decompose")
                self.pop(value); self.release(c[0]); self.enter(inner)
                self.snapshot("matchStep4Done", "Match complete")
            self.enter(inner); self.snapshot("branchStarts", "Branch start")
            answer = self.eval(e[5], inner, rest, [bid] + enclosing)
            return self.finish_branch(bid, inner, env, answer)
        raise AssertionError(op)

    def run(self, expr):
        env = Environment()
        for name, value in self.inputs:
            status = "holding" if value[0] == "l" and value[1] is not None else "noHolder"
            env[name] = self.bind(name, value, status)
        self.enter(env)
        for ident in env.values():
            if self.bindings[ident][3] == "holding" and not uses(expr, env, ident): self.release_binding(ident)
        self.snapshot("start", "Start")
        raw = self.eval(expr, env, [], [])
        self.snapshot("end", "Finish")
        if raw[0] == "l":
            items, addr = [], raw[1]
            while addr is not None:
                c = self.cell(addr); items.append(c[1]); addr = c[2]
            plain = ["l", items]
        else: plain = raw
        return dict(answer=raw, value=plain, memory=self.cells, record=self.record,
                    log=[list(event) for event in self.record], states=self.states)
