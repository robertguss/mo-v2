"""Unadopted ownership implementation proposal; all frozen predicates remain.

This copies predicates.state_ownership, adding only conversion of the already
duplicate-checked reservation list to a set. Snapshot/graph validation requires
natural integer identities. No state, expected value or verdict is cached.
"""
from collections import Counter

from predicates import require, walk


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
    reserved = set(reserved)
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
