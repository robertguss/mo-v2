"""Finite, independently authored call trees; not an AST interpreter.

Each node fixes function, raw arguments, raw result, and ordered children.
An integer child consumes that many cell events from the unchanged checkpoint
ledger at that exact position. No observed events enter this module.
"""


def call(name, args, result, *children):
    return (name, args, result, children)


def usefulness_tree(row):
    c = call
    cid = row[0]
    if cid == "U-reverse":
        return [c("reverse", ["A"], "C",
                  c("revAcc", ["A", "-"], "C", 1,
                    c("revAcc", ["B", "A"], "C", 1,
                      c("revAcc", ["C", "B"], "C", 1,
                        c("revAcc", ["-", "C"], "C")))))]
    if cid == "U-totals":
        return [c("totals", ["A"], "A",
                  c("totalsAcc", ["A", 0], "A",
                    c("totalsAcc", ["B", -2], "B",
                      c("totalsAcc", ["C", 3], "C",
                        c("totalsAcc", ["-", 4], "-"), 1), 1), 1))]
    if cid == "U-append":
        return [c("append", ["A", "D"], "A",
                  c("append", ["B", "D"], "B",
                    c("append", ["-", "D"], "D"), 1), 1)]
    if cid == "U-swap":
        return [c("swap", ["A"], "A", c("swap", ["C"], "C", 1), 2)]
    if cid == "U-rotate":
        return [c("rotate", ["A"], "B", 1,
                  c("append", ["B", "A"], "B",
                    c("append", ["C", "A"], "C",
                      c("append", ["-", "A"], "A"), 1), 1))]
    if cid == "U-merge":
        # Comparisons -3<=-1, 4>-1, 4>2, 4<=8. Reconstructing
        # the nonselected head consumes the newest reservation each time.
        return [c("merge", ["A", "D"], "A", 1,
                  c("merge", ["B", "D"], "B", 1,
                    c("merge", ["D", "E"], "D", 1,
                      c("merge", ["E", "F"], "E", 1,
                        c("merge", ["-", "F"], "F"), 1), 1), 1), 1)]
    if cid == "U-sort":
        # Sort tail first, preserving the earlier singleton argument.
        # Inserting 5 into [1] recurses with singleton C; -2 then takes
        # the opposite comparison branch and returns A without recursion.
        return [c("sort", ["A"], "A", 1,
                  c("sort", ["B"], "B", 1,
                    c("sort", ["C"], "C", 1,
                      c("sort", ["-"], "-"),
                      c("insertCell", ["C", "-"], "C", 1)),
                    c("insertCell", ["B", "C"], "B", 1,
                      c("insertCell", ["C", "-"], "C", 1), 1)),
                  c("insertCell", ["A", "B"], "A", 2))]
    if cid == "U-keep-first":
        return [c("keepFirst", ["A"], "A", 3)]
    if cid == "U-remove":
        return [c("remove", [5, "A"], "A", c("remove", [5, "B"], "C", 1), 1)]
    if cid == "U-positive":
        return [c("positive", ["A"], "B",
                  c("positive", ["B"], "B",
                    c("positive", ["C"], "C", c("positive", ["-"], "-"), 1), 1), 1)]
    if cid == "U-duplicate":
        return [c("duplicate", ["A"], "N2",
                  c("duplicate", ["B"], "N1",
                    c("duplicate", ["C"], "N0", c("duplicate", ["-"], "-"), 2), 2), 2)]
    if cid == "U-prepend":
        return [c("prepend", [-7, "A"], "N0", 1)]
    if cid == "U-insert-new":
        return [c("insertNew", [2, "A"], "A", c("insertNew", [2, "B"], "N0", 2), 1)]
    if cid == "U-build":
        return [c("build", [3], "N2", c("build", [2], "N1",
                  c("build", [1], "N0", c("build", [0], "-"), 1), 1), 1)]
    if cid == "U-twice":
        return [c("twice", ["A"], "A",
                  c("bump", ["A"], "N1", c("bump", ["B"], "N0", c("bump", ["-"], "-"), 1), 1),
                  c("append", ["A", "N1"], "A", c("append", ["B", "N1"], "B", c("append", ["-", "N1"], "N1"), 1), 1))]
    if cid == "U-ordinary-alloc":
        return [c("allocHelper", [-9], "N0", c("one", [-9], "N0", 1))]
    if cid == "U-ordinary-arithmetic":
        return [c("arithDemand", [-2], -6, c("arithmetic", [-2], -6))]
    if cid == "U-fresh-demand":
        return [2, c("bump", ["N1"], "N1", c("bump", ["N0"], "N0", c("bump", ["-"], "-"), 1), 1)]
    if cid == "U-chain":
        return [c("bump", ["A"], "A", c("bump", ["B"], "B", c("bump", ["C"], "C", c("bump", ["-"], "-"), 1), 1), 1),
                c("reverse", ["A"], "C", c("revAcc", ["A", "-"], "C", 1, c("revAcc", ["B", "A"], "C", 1, c("revAcc", ["C", "B"], "C", 1, c("revAcc", ["-", "C"], "C")))))]
    if cid == "U-alias-demand":
        return [c("both", ["A", "A"], "N1",
                  c("bump", ["A"], "N1", c("bump", ["B"], "N0", c("bump", ["-"], "-"), 1), 1),
                  c("bump", ["A"], "A", c("bump", ["B"], "B", c("bump", ["-"], "-"), 1), 1),
                  c("append", ["N1", "A"], "N1", c("append", ["N0", "A"], "N0", c("append", ["-", "A"], "A"), 1), 1))]
    if cid == "U-tail-demand":
        return [c("bump", ["A"], "A", c("bump", ["C"], "N0", c("bump", ["-"], "-"), 1), 1),
                c("first", ["A"], -1, 2),
                c("sum", ["B"], 13, c("sum", ["C"], 4, c("sum", ["-"], 0), 1), 1)]
    if cid == "U-drop-extra":
        return [c("first", ["A"], 1), c("bump", ["A"], "A", c("bump", ["B"], "B", c("bump", ["-"], "-"), 1), 1)]
    if cid == "U-forward":
        return [1, c("forward", ["N0"], "N0", c("bump", ["N0"], "N0", c("bump", ["-"], "-"), 1))]
    if cid.startswith("boundary-"):
        fn = row[3][1]
        single = cid.endswith("single")
        a = "A" if single else "-"
        if fn == "reverse":
            child = c("revAcc", [a, "-"], a, *([1, c("revAcc", ["-", "A"], "A")] if single else []))
            return [c(fn, [a], a, child)]
        if fn == "totals":
            child = c("totalsAcc", [a, 0], a, *([c("totalsAcc", ["-", -2], "-"), 1] if single else []))
            return [c(fn, [a], a, child)]
        if fn == "append":
            return [c(fn, [a, "-"], a, *([c(fn, ["-", "-"], "-"), 1] if single else []))]
        if fn in ("swap", "keepFirst"):
            return [c(fn, [a], a, *([1] if single else []))]
        if fn == "rotate":
            return [c(fn, [a], a, *([1, c("append", ["-", "A"], "A")] if single else []))]
        if fn == "merge":
            return [c(fn, [a, "-"], a, *([1] if single else []))]
        if fn == "sort":
            return [c(fn, [a], a, *([1, c(fn, ["-"], "-"), c("insertCell", ["A", "-"], "A", 1)] if single else []))]
        if fn == "remove":
            n = row[3][2]
            children = [] if not single else [1] if n == -2 else [c(fn, [n, "-"], "-"), 1]
            return [c(fn, [n, a], "-" if n == -2 else a, *children)]
        if fn == "positive":
            return [c(fn, [a], "-", *([c(fn, ["-"], "-"), 1] if single else []))]
    if cid.startswith("additional-"):
        i = int(cid.split("-")[1])
        return {
            0: [c("duplicate", ["-"], "-")],
            1: [c("duplicate", ["A"], "N0", c("duplicate", ["-"], "-"), 2)],
            2: [c("prepend", [-7, "-"], "N0", 1)],
            3: [c("insertNew", [2, "-"], "N0", 1)],
            4: [c("build", [0], "-")],
            5: [c("build", [1], "N0", c("build", [0], "-"), 1)],
            6: [c("build", [-1], "-")],
            7: [c("twice", ["-"], "-", c("bump", ["-"], "-"), c("append", ["-", "-"], "-"))],
        }[i]
    raise ValueError(f"No independently written call tree for {cid}")


def events(row, prior):
    if row[0].startswith("C"):
        return prior.predicted_events(row)
    if row[0] in ("U-ordinary-shared", "U-retained-demand"):
        # Exactly C4's syntax and start; demanded metadata does not change execution.
        return prior.predicted_events(prior.ROWS["C4"])
    ids = prior.identities(row)
    effects = prior.ledger(row)
    out, next_inv, next_effect = [], 1, 0

    def raw(kind, value):
        return [kind, ids[value] if kind == "L" else value]

    def emit(item, parent):
        nonlocal next_inv, next_effect
        if type(item) is int:
            prior.require(next_effect + item <= len(effects), "too many expected cell effects")
            out.extend(effects[next_effect:next_effect + item])
            next_effect += item
            return
        name, args, result, children = item
        params, result_kind, _ = prior.fx.FUNCTIONS[name]
        prior.eq(len(args), len(params), "prediction call arity")
        inv = next_inv
        next_inv += 1
        out.append(["E", name, inv, parent, [raw(k, a) for (_, k), a in zip(params, args)]])
        for child in children:
            emit(child, inv)
        out.append(["R", inv, raw(result_kind, result)])

    for item in usefulness_tree(row):
        emit(item, 0)
    prior.eq(next_effect, len(effects), "expected call tree must place every checkpoint cell event")
    return out
