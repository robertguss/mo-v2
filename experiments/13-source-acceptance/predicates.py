"""Acceptance predicates for logical ownership, call accounting and physical evidence.

Reported pointers alone are not physical verification. The eventual harness must
obtain the physical stream from the sole cell API and inspect the real object graph.
These functions check such observations; synthetic controls validate the checks,
not an unbuilt allocator/runtime. Continuous protection still needs every committed
state and acceptance-derived expected acquisitions, not only historical landmarks.
"""
from collections import Counter


def require(condition, message):
    if not condition: raise AssertionError(message)


def walk(memory, root):
    cells = {c[0]: c for c in memory}
    require(len(cells) == len(memory), "duplicate identity")
    items, seen = [], set()
    while root is not None:
        require(root in cells and root not in seen, "dangling/cycle")
        seen.add(root); c = cells[root]
        require(c[4] == "live" and c[3] > 0, "unreadable held cell")
        items.append(int(c[1])); root = c[2]
    return items, seen


def state_ownership(state):
    memory = state["memory"]
    cells = {c[0]: c for c in memory}
    require(len(cells) == len(memory), "duplicate identity")
    roots = list(state["outside"])
    roots += [v[1] for _, _, v, status in state["bindings"] if status == "holding"]
    roots += [v[1] for v in state["pending"] if v[0] == "l"]
    counts = Counter(r for r in roots if r is not None)
    for c in memory:
        if c[4] == "live" and c[2] is not None: counts[c[2]] += 1
    require(set(counts) <= set(cells), "holder/link dangling")
    reserved = [a for _, a in state["aside"]]
    require(len(reserved) == len(set(reserved)), "duplicate reservation")
    for a, _, tail, count, status in memory:
        require(count == counts[a], "holder count mismatch")
        if status == "aside":
            require(a in reserved and count == 0 and tail is None, "invalid reservation")
        else:
            require(status == "live" and a not in reserved, "invalid live status")
            # The split give-up landmark deliberately has an allocated zero-count cell.
            if count == 0: require(state["kind"] == "holderGivenUp", "unowned cell outside pending free")
    require(set(reserved) <= set(cells), "reservation dangling")
    for root in roots: walk(memory, root)


def final_memory(outcome, outside):
    memory, answer = outcome["memory"], outcome["answer"]
    roots = list(outside) + ([answer[1]] if answer[0] == "l" else [])
    reachable = set()
    for root in roots: reachable.update(walk(memory, root)[1])
    require(reachable == {c[0] for c in memory}, "final reachability")
    for a, _, _, count, status in memory:
        require(status == "live" and count == roots.count(a) + sum(c[2] == a for c in memory), "final counts")
    if answer[0] == "l":
        require(outcome["value"] == ["l", [str(n) for n in walk(memory, answer[1])[0]]], "answer readback")
    else: require(outcome["value"] == answer, "scalar answer readback")


def protection(states, initial, outside, binding_expectations=None):
    """Outside expectations fixed from initial data; binding baselines may be explicit.

    Passing binding_expectations from the independent reference avoids trusting a
    candidate's first corrupted acquisition. Acquisitions missing in that reference
    cannot be claimed independently validated by this predicate.
    """
    old = [walk(initial, r)[0] for r in outside]
    held = {} if binding_expectations is None else dict(binding_expectations)
    for state in states:
        require(state["outside"] == outside, "outside root identity")
        require([walk(state["memory"], r)[0] for r in outside] == old, "outside mutation")
        state_ownership(state)
        for ident, _, value, status in state["bindings"]:
            if status == "holding":
                contents = walk(state["memory"], value[1])[0]
                if binding_expectations is not None: require(ident in held, "unpredicted acquisition")
                if ident in held: require(contents == held[ident], "live binding mutation")
                else: held[ident] = contents


def invocation_creates(events, finished=True):
    stack, counts, functions = [], {}, {}
    seen = set()
    for event in events:
        kind = event[0]
        if kind == "enter":
            _, ident, parent, name = event
            require(ident not in seen and parent == (stack[-1] if stack else 0), "call identity/parent")
            seen.add(ident); stack.append(ident); counts[ident] = 0; functions[ident] = name
        elif kind == "return":
            require(stack and stack[-1] == event[1], "return identity/order")
            stack.pop()
        elif kind == "create":
            for ident in stack: counts[ident] += 1
        else: require(kind in ("write", "free"), "event kind")
    if finished: require(not stack, "missing return")
    return [(ident, functions[ident], counts[ident]) for ident in counts]


def physical_events(initial, events, logical, final):
    """Events (kind,lifetime-id,pointer), with monotonic lifetime IDs, recycled pointers allowed."""
    seen, live, primitive = set(), {}, []
    fixtures = []
    for kind, ident, pointer in events:
        require(type(pointer) is int and pointer > 0, "invalid physical pointer")
        if kind in ("fixture", "create"):
            require(ident not in seen and pointer not in live.values(), "physical identity recycled/aliased")
            seen.add(ident); live[ident] = pointer
            if kind == "fixture": fixtures.append(ident)
        else:
            require(live.get(ident) == pointer, "physical continuity")
            require(kind in ("write", "free"), "physical event kind")
            if kind == "free": del live[ident]
        if kind != "fixture": primitive.append([kind, ident])
    require(fixtures == [c[0] for c in initial], "fixture construction count/order")
    require(primitive == logical, "physical/logical disagreement")
    require(set(live) == {c[0] for c in final}, "physical final set")
    return live


def resume_join(before, after, suffix, before_live, after_live):
    require(after[:len(before)] == before, "resume rewrote prefix")
    require(after[len(before):] == suffix, "resume replay/wrong suffix")
    for ident in before_live.keys() & after_live.keys():
        require(before_live[ident] == after_live[ident], "resume replaced live object")
