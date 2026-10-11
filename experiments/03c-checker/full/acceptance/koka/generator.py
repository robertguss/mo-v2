#!/usr/bin/env python3
"""Translate the recorded slice-1 trees; retain exact Koka source/diagnostics.

This is a syntax translator, not a model evaluator. It never changes predictions.
Run only after verifying PREDICTIONS.sha256. Requires Koka exactly 3.2.9.
"""
import ast
import datetime
import json
import re
import subprocess
import tempfile
from pathlib import Path

from check import HERE, STARTS, all_cases, function_table, walk


def fname(name):
    return "mo-" + re.sub(r"([A-Z])", r"-\1", name).lower()


def expression(expr):
    if type(expr) is bool:
        return str(expr).lower()
    if type(expr) is int:
        return str(expr) if expr >= 0 else f"({expr})"
    if type(expr) is str:
        return expr
    if not expr:
        return "Nil"
    op, *args = expr
    if op in ("add", "sub", "eq", "lt", "le"):
        symbol = {"add": "+", "sub": "-", "eq": "==", "lt": "<", "le": "<="}[op]
        return f"({expression(args[0])} {symbol} {expression(args[1])})"
    if op == "cons":
        return f"Cons({expression(args[0])}, {expression(args[1])})"
    if op == "call":
        return f"{fname(args[0])}({', '.join(expression(a) for a in args[1:])})"
    if op == "let":
        return f"{{ val {args[0]} = {expression(args[1])}; {expression(args[2])} }}"
    if op == "if":
        return f"(if {expression(args[0])} then {expression(args[1])} else {expression(args[2])})"
    if op == "match":
        scrutinee, empty, head, tail, cell = args
        return (f"match {expression(scrutinee)} {{ Nil -> {expression(empty)}; "
                f"Cons({head},{tail}) -> {expression(cell)} }}")
    raise ValueError(op)


def source(rows, principal):
    kinds = {"I": "int", "L": "list<int>", "B": "bool"}
    lines = ["// Generated syntax translation of checkpointed public trees; no algorithm rewrite."]
    for name, (params, result, body) in function_table(principal[3]).items():
        annotation = "fbip " if name in principal[4] else ""
        arguments = ", ".join(f"{n} : {kinds[k]}" for n, k in params)
        lines.extend([f"{annotation}fun {fname(name)}({arguments}) : {kinds[result]}",
                      f"  {expression(body)}", ""])
    lines.append("fun main() {")
    for row in rows:
        start = STARTS[row[2]]
        cells = {a: (n, t) for a, n, t, _ in start["cells"]}
        # Construction outside demanded calls is intentional; no outside roots
        # occur in these slice-1 comparison rows.
        assert not start["outside"]
        lines.append("  {")
        for name, kind, value in start["inputs"]:
            literal = json.dumps(walk(cells, value)[1]) if kind == "L" else str(value)
            lines.append(f"    val {name} = {literal}")
        lines.append(f'    println("{row[0]}=" ++ ({expression(row[3])}).show)')
        lines.append("  }")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main():
    subprocess.run(["sha256sum", "-c", "PREDICTIONS.sha256"], cwd=HERE, check=True)
    out = HERE / "koka"
    out.mkdir(exist_ok=True)
    # Do not replace earlier comparison evidence on an accidental rerun.
    if (out / "results.json").exists():
        raise SystemExit("comparison evidence already exists; use a separately named revision")
    version = subprocess.run(["koka", "--version"], capture_output=True, text=True, check=True)
    (out / "version.txt").write_text(version.stdout + version.stderr)
    if not re.search(r"^Koka 3\.2\.9,", version.stdout):
        raise SystemExit("Koka 3.2.9 required")
    rows = all_cases()
    categories = [f"S1A{i:02d}" for i in range(1, 13)] + [f"S1R{i:02d}" for i in range(1, 7)] + ["S1O01"]
    results = []
    with tempfile.TemporaryDirectory(prefix="full3c-koka-") as build:
        for category in categories:
            selected = [r for r in rows if category in r[1]]
            principal = selected[0]
            # The first increment/total entries are empty, but have the same
            # declaration/call closure and demand metadata as their mixed run.
            path = out / f"{category.lower()}.kk"
            path.write_text(source(selected, principal))
            executable = str(Path(build) / category.lower())
            command = ["koka", "-O2", "-c", "--console=raw", f"--builddir={build}/cache",
                       "-o", executable, str(path)]
            compiled = subprocess.run(command, capture_output=True, text=True)
            (out / f"{category}.compile.stdout").write_text(compiled.stdout)
            (out / f"{category}.compile.stderr").write_text(compiled.stderr)
            result = {"category": category, "utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                      "command": command, "compile_exit": compiled.returncode,
                      "cases": [r[0] for r in selected], "run_exit": None, "answers_match": None}
            if compiled.returncode == 0:
                ran = subprocess.run([executable], capture_output=True, text=True, timeout=30)
                (out / f"{category}.run.stdout").write_text(ran.stdout)
                (out / f"{category}.run.stderr").write_text(ran.stderr)
                expected = {r[0]: r[6] for r in selected}
                actual = {}
                for line in ran.stdout.splitlines():
                    key, value = line.split("=", 1)
                    actual[key] = ast.literal_eval(value.strip())
                result.update(run_exit=ran.returncode, answers_match=actual == expected)
            results.append(result)
            print(category, "compile", result["compile_exit"], "answers", result["answers_match"], flush=True)
    (out / "results.json").write_text(json.dumps(results, indent=2) + "\n")


if __name__ == "__main__":
    main()
