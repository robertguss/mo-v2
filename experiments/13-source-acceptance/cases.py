"""Public example inputs and English-derived draft predictions. Not a lock.

These C-family totals were derived in the plan, before this Python predictor.
Exact private holdouts/control triggers are not in this public example file.
"""
DEFINITIONS = """
def identity(xs: ListInt): ListInt = xs end
def one(n: Int): ListInt = [n | []] end
def first(xs: ListInt): Int = match xs do [] -> 0; [h | t] -> h end end
def bump(xs: ListInt): ListInt = match xs do [] -> []; [h | t] -> [h + 1 | bump(t)] end end
def sum(xs: ListInt): Int = match xs do [] -> 0; [h | t] -> h + sum(t) end end
def choose(a: ListInt, b: ListInt): ListInt = a end
def readBoth(a: ListInt, b: ListInt): Int = first(a) + first(b) end
def makeThenDrop(n: Int): Int = let unused = one(n) in 0 end
def outer(n: Int): ListInt = identity([n | []]) end
def even(n: Int): Bool = if n <= 0 then true else odd(n - 1) end end
def odd(n: Int): Bool = if n <= 0 then false else even(n - 1) end end
def spin(n: Int): Int = spin(n) end
def allocateForever(n: Int): Int = let ignored = one(n) in allocateForever(n) end
"""


def fixture(items, outside=False, tail=False):
    cells = [[i + 1, str(n), i + 2 if i + 1 < len(items) else None, 1, "live"]
             for i, n in enumerate(items)]
    roots = [1] if items and outside else []
    if tail and len(items) > 1: cells[1][3] += 1
    if roots: cells[0][3] += 1
    inputs = [("xs", ["l", 1 if items else None])]
    if tail: inputs.append(("ys", ["l", 2]))
    return cells, inputs, roots


def examples():
    def case(name, main, items, value, counts, retained=False, tail=False):
        cells, inputs, outside = fixture(items, retained, tail)
        declarations = "input xs: ListInt;\n" + ("input ys: ListInt;\n" if tail else "")
        return dict(name=name, source=declarations + DEFINITIONS + "main = " + main,
                    cells=cells, inputs=inputs, outside=outside,
                    value=value, counts=counts)
    # Counts: creates, writes, frees during evaluation; fixture/destroy excluded.
    rows = [
        case("C1", "match xs do [] -> []; [h | t] -> one(h) end", [1], [1], [1, 0, 1]),
        case("C2", "match xs do [] -> []; [h | t] -> [h | one(h)] end", [1], [1, 1], [1, 1, 0]),
        case("C3", "choose(xs, bump(xs))", [1, 2], [1, 2], [2, 0, 2]),
        case("C4", "let changed = bump(xs) in first(changed) + first(xs)", [1, 2], 3, [2, 0, 4]),
        case("C5", "readBoth(xs, xs)", [1, 2], 2, [0, 0, 2]),
        case("C6", "let changed = bump(xs) in first(changed) + first(ys)", [1, 2], 4, [1, 1, 3], tail=True),
        case("C7", "makeThenDrop(8)", [], 0, [1, 0, 1]),
        case("C8", "identity([1])", [], [1], [1, 0, 0]),
        case("C9", "outer(8)", [], [8], [1, 0, 0]),
        case("C10-unique", "bump(xs)", [3, -2, 8], [4, -1, 9], [0, 3, 0]),
        case("C10-retained", "bump(xs)", [3, -2, 8], [4, -1, 9], [3, 0, 0], retained=True),
        case("C10-sum", "sum(xs)", [3, -2, 8], 9, [0, 0, 3]),
        case("C10-empty", "bump(xs)", [], [], [0, 0, 0]),
        case("C10-single", "bump(xs)", [-4], [-3], [0, 1, 0]),
    ]
    for n, value in [(0, True), (1, False), (2, True), (7, False)]:
        rows.append(case(f"C11-{n}", f"even({n})", [], value, [0, 0, 0]))
    # Prefixes are not called Mo suspension or a divergence proof.
    for name, main, items in [("C12", "spin(0)", []),
                              ("C13", "allocateForever(0)", []),
                              ("C14", "match xs do [] -> 0; [h | t] -> spin(h) end", [1])]:
        rows.append(case(name, main, items, None, None))
    return rows
