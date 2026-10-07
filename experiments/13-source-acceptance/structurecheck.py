"""Proposed canonical checked structure and acceptance-derived static identities.

Declaration paths, not candidate identities, determine lexical resolution. The
tagged tuple parser remains the common syntax tree; this dump adds checked kinds.
"""
import json
from pathlib import Path
import sys
import traceback

from syntax import check, parse


TAGS = dict(num="Int", bool="Bool", var="Var", nil="Nil", cons="Cons", add="Add", sub="Sub",
            eq="Eq", lt="Lt", le="Le", let="Let", match="Match", call="Call", **{"if": "If"})


def canonical(program):
    check(program)
    functions = {f[0]: (f"function/{i}", f[2]) for i, f in enumerate(program["functions"])}
    def node(e, path, env):
        op = e[0]; result = dict(node=TAGS[op], path=path)
        child = lambda expr, index, scope=env: node(expr, f"{path}/{index}", scope)
        if op in ("num", "bool", "nil"):
            result["type"] = {"num": "Int", "bool": "Bool", "nil": "ListInt"}[op]
            if op != "nil": result["value"] = str(e[1]) if op == "num" else e[1]
        elif op == "var":
            binding, kind = env[e[1]]
            result.update(name=e[1], binding=binding, type=kind)
        elif op == "call":
            ident, kind = functions[e[1]]
            result.update(name=e[1], function=ident, type=kind,
                          children=[child(arg, i) for i, arg in enumerate(e[2])])
        elif op == "let":
            value = child(e[2], 0); ident = path + "/binding"
            body = child(e[3], 1, env | {e[1]: (ident, value["type"])})
            result.update(name=e[1], binding=ident, children=[value, body], type=body["type"])
        elif op == "match":
            head, tail = path + "/head", path + "/tail"
            children = [child(e[1], 0), child(e[2], 1),
                        child(e[5], 2, env | {e[3]: (head, "Int"), e[4]: (tail, "ListInt")})]
            result.update(head=dict(name=e[3], binding=head), tail=dict(name=e[4], binding=tail),
                          children=children, type=children[1]["type"])
        else:
            children = [child(arg, i) for i, arg in enumerate(e[1:])]
            kind = (children[1]["type"] if op == "if" else "ListInt" if op == "cons" else
                    "Bool" if op in ("eq", "lt", "le") else "Int")
            result.update(children=children, type=kind)
        return result
    def declaration(name, kind, ident): return dict(name=name, type=kind, binding=ident)
    inputs = [declaration(n, k, f"input/{i}") for i, (n, k, *_) in enumerate(program["inputs"])]
    definitions = []
    for i, (name, params, kind, body, *_) in enumerate(program["functions"]):
        parameters = [declaration(n, k, f"function/{i}/parameter/{j}") for j, (n, k, *_) in enumerate(params)]
        definitions.append(dict(name=name, function=f"function/{i}", parameters=parameters, result=kind,
                                body=node(body, f"function/{i}/body", {p["name"]: (p["binding"], p["type"]) for p in parameters})))
    return dict(node="Program", inputs=inputs, functions=definitions,
                main=node(program["main"], "main", {p["name"]: (p["binding"], p["type"]) for p in inputs}))


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, cases=0); dumps = []
    try:
        for source, expected in [("main = true", True), ("main = false", False)]:
            dump = canonical(parse(source)); assert dump["main"] == dict(node="Bool", path="main", type="Bool", value=expected)
            dumps.append(dump); report["cases"] += 1
        dump = canonical(parse("main = let n = 5 in let n = n - 2 in n"))
        inner = dump["main"]["children"][1]
        assert inner["children"][0]["children"][0]["binding"] == "main/binding"
        assert inner["children"][1]["binding"] == "main/1/binding"
        dumps.append(dump); report["cases"] += 1
        dump = canonical(parse("def f(f: Int): Int = f + 2 end main = f(9)"))
        assert dump["main"]["function"] == "function/0"
        assert dump["functions"][0]["body"]["children"][0]["binding"] == "function/0/parameter/0"
        dumps.append(dump); report["cases"] += 1
        dump = canonical(parse("def f(): Bool = g() end def g(): Bool = true end main = f()"))
        assert dump["functions"][0]["body"]["function"] == "function/1"
        dumps.append(dump); report["cases"] += 1
        dump = canonical(parse("main = match [7] do [] -> 0; [h | t] -> h end"))
        assert dump["main"]["children"][2]["binding"] == "main/head"
        assert dump["main"]["tail"] == dict(name="t", binding="main/tail")
        dumps.append(dump); report["cases"] += 1
        report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "dumps.json").write_text(json.dumps(dumps, indent=2) + "\n")
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
