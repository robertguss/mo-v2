#!/usr/bin/env python3
"""Experiment 3 measurement and scoring. Written by the lead; the builder may not change it.

Builds every version from the builder's sources, runs each benchmark 10 times,
checks every output against the expected lines, and scores claims A to D as
ACCEPTANCE.md describes. Writes data/timings.csv and data/summary.json.

Usage (from experiments/03-in-place):  python3 acceptance/measure.py [--runs N] [--only a,b,c,d]
"""
import argparse, csv, json, os, platform, re, shutil, statistics, subprocess, sys, tempfile, time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent          # experiments/03-in-place
ACC = ROOT / "acceptance"
BENCH = ROOT / "bench"
BUILD = ROOT / "build"
DATA = ROOT / "data"

EXPECTED = {
    "b1": ["sum 500100500000", "first 101", "last 1000100"],
    "b2": ["count 1000000", "sum 499999547508", "smallest 0", "largest 1000002"],
    "b3": ["first 1000000", "last 1", "weighted 166667166667000000"],
    "b4": ["first 37", "last 554962791", "sum-mod 491625299"],
}
BENCHES = list(EXPECTED)
CHANGES = ["keep", "box", "helper"]
RUST_VERSIONS = [("rust-same", "mimalloc"), ("rust-same", "std"), ("rust-best", "mimalloc"), ("rust-best", "std")]
PASS_BASELINE = "rust-same-mimalloc"
CLAIM_D_FUNCTIONS = ["invoice-total", "apply-price-change", "update-stock", "rotate-queue", "tree-insert",
                     "tree-remove", "parse-csv-line", "merge-sorted", "sort-ints", "set-city"]
# Which example names (in acceptance/claim-d/examples.kk) belong to which function.
EXAMPLE_PREFIX = {"invoice-total": "invoice-total", "apply-price-change": "price-change", "update-stock": "update-stock",
                  "rotate-queue": "rotate-queue", "tree-insert": "tree-insert", "tree-remove": "tree-remove",
                  "parse-csv-line": "parse-csv-line", "merge-sorted": "merge-sorted", "sort-ints": "sort-ints",
                  "set-city": "set-city"}
FORBIDDEN_KOKA = [r"\bvar\b", r"\bref\s*\(", r"\bvector\b", r"unsafe"]


def sh(cmd, cwd=None):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def koka_build(src, out, includes=()):
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = ["koka", "-O2", "-c", f"--builddir={BUILD / '.koka'}", "-o", str(out)]
    cmd += [f"-i{d}" for d in includes] + [str(src)]
    code, log = sh(cmd)
    warnings = [l for l in log.splitlines() if "warning" in l]
    return code == 0 and out.exists(), log, warnings


def forbidden_in(path):
    text = re.sub(r"//[^\n]*", "", path.read_text())   # ignore comments
    return [pat for pat in FORBIDDEN_KOKA if re.search(pat, text)]


def time_runs(exe, bench, runs):
    rows = []
    for i in range(runs):
        t0 = time.perf_counter()
        p = subprocess.run([str(exe)], capture_output=True, text=True)
        dt = time.perf_counter() - t0
        ok = p.returncode == 0 and p.stdout.strip().splitlines() == EXPECTED[bench]
        rows.append({"run": i + 1, "seconds": round(dt, 6), "output_ok": ok,
                     "output": p.stdout.strip().replace("\n", " | ")[:200]})
    return rows


def summarize(rows):
    secs = [r["seconds"] for r in rows]
    return {"median": statistics.median(secs), "fastest": min(secs), "slowest": max(secs),
            "all_outputs_ok": all(r["output_ok"] for r in rows)}


def build_all():
    builds, problems = {}, []
    for b in BENCHES:
        src = BENCH / "koka" / f"{b}.kk"
        if not src.exists():
            problems.append(f"missing {src.relative_to(ROOT)}"); continue
        bad = forbidden_in(src)
        if bad: problems.append(f"{src.relative_to(ROOT)} uses forbidden {bad}")
        ok, log, warns = koka_build(src, BUILD / "koka" / b)
        builds[("koka", b)] = {"ok": ok and not bad, "exe": BUILD / "koka" / b, "warnings": warns, "log": log[-2000:]}
        for c in CHANGES:
            src = BENCH / "koka-b" / f"{b}-{c}.kk"
            if not src.exists():
                problems.append(f"missing {src.relative_to(ROOT)}"); continue
            bad = forbidden_in(src)
            if bad: problems.append(f"{src.relative_to(ROOT)} uses forbidden {bad}")
            ok, log, warns = koka_build(src, BUILD / "koka-b" / f"{b}-{c}", includes=[BENCH / "koka-b"])
            builds[(f"koka-{c}", b)] = {"ok": ok and not bad, "exe": BUILD / "koka-b" / f"{b}-{c}",
                                        "warnings": warns, "log": log[-2000:]}
    for proj, alloc in RUST_VERSIONS:
        manifest = BENCH / proj / "Cargo.toml"
        name = f"{proj}-{alloc}"
        if not manifest.exists():
            problems.append(f"missing {manifest.relative_to(ROOT)}"); continue
        target = BUILD / f"cargo-{name}"
        cmd = ["cargo", "build", "--release", "--manifest-path", str(manifest), "--target-dir", str(target)]
        if alloc == "mimalloc": cmd += ["--features", "mimalloc"]
        code, log = sh(cmd)
        for b in BENCHES:
            exe = target / "release" / b
            builds[(name, b)] = {"ok": code == 0 and exe.exists(), "exe": exe, "warnings": [], "log": log[-2000:]}
    return builds, problems


def mimalloc_version():
    for lock in BENCH.glob("*/Cargo.lock"):
        m = re.search(r'name = "mimalloc"\nversion = "([^"]+)"', lock.read_text())
        if m: return m.group(1)
    return "unknown"


def claim_c():
    results = []
    for src in sorted((ACC / "claim-c").glob("*.kk")):
        code, log = sh(["koka", "-c", f"--builddir={BUILD / '.koka-c'}", "-o", str(BUILD / "claim-c" / src.stem), str(src)])
        warns = [l for l in log.splitlines() if "warning: fip" in l]
        expected = "accepted" if src.stem.startswith("good-") else "warned"
        got = "accepted" if (code == 0 and not warns) else ("warned" if warns else f"failed to compile (exit {code})")
        results.append({"test": src.stem, "expected": expected, "got": got, "as_expected": got == expected,
                        "warnings": warns})
    return {"tests": results, "passed": bool(results) and all(r["as_expected"] for r in results)}


def claim_d():
    src = BENCH / "claim-d" / "functions.kk"
    if not src.exists():
        return {"error": f"missing {src.relative_to(ROOT)}", "passed": False}
    text = src.read_text()
    unsafe = "unsafe" in re.sub(r"//[^\n]*", "", text)

    def compile_run(fn_text):
        tmp = Path(tempfile.mkdtemp(prefix="exp3-d-"))
        for f in ["types.kk", "examples.kk"]:
            shutil.copy(ACC / "claim-d" / f, tmp / f)
        (tmp / "functions.kk").write_text(fn_text)
        code, log = sh(["koka", "-e", f"--builddir={tmp / '.koka'}", "examples.kk"], cwd=tmp)
        shutil.rmtree(tmp, ignore_errors=True)
        return code, log

    code, log = compile_run(text)
    strict_text = re.sub(r"\bfbip(\s+fun)", r"fip\1", text)
    _, strict_log = compile_run(strict_text)
    rows = []
    for fn in CLAIM_D_FUNCTIONS:
        marked = re.search(r"\bfbip\s+fun\s+" + re.escape(fn) + r"\b", text) is not None
        warns = [l for l in log.splitlines() if re.search(r"warning: fbip fun " + re.escape(fn) + r"\b", l)]
        strict_warns = [l for l in strict_log.splitlines() if re.search(r"warning: fip fun " + re.escape(fn) + r"\b", l)]
        prefix = EXAMPLE_PREFIX[fn]
        ex = [l for l in log.splitlines() if re.match(r"(ok|FAIL)\s+" + re.escape(prefix) + r"\b", l)]
        examples_ok = bool(ex) and all(l.startswith("ok") for l in ex)
        success = code == 0 and marked and not warns and examples_ok and not unsafe
        rows.append({"function": fn, "marked_fbip": marked, "fbip_warnings": warns, "examples": ex,
                     "examples_ok": examples_ok, "success": success,
                     "passes_strict_fip": marked and not strict_warns, "strict_warnings": strict_warns})
    n = sum(r["success"] for r in rows)
    return {"compiled": code == 0, "uses_unsafe": unsafe, "functions": rows, "successes": n,
            "passed": n >= 7, "log_tail": log[-3000:]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=10)
    ap.add_argument("--only", default="a,b,c,d")
    args = ap.parse_args()
    only = set(args.only.split(","))
    DATA.mkdir(exist_ok=True)
    summary = {"machine": {"os": f"macOS {platform.mac_ver()[0]}", "cpu": sh(["sysctl", "-n", "machdep.cpu.brand_string"])[1].strip(),
                           "koka": sh(["koka", "--version"])[1].splitlines()[0],
                           "rustc": sh(["rustc", "--version"])[1].strip()},
               "runs_per_version": args.runs}
    if only & {"a", "b"}:
        if BUILD.exists():
            shutil.rmtree(BUILD)
        builds, problems = build_all()
        summary["machine"]["mimalloc"] = mimalloc_version()
        summary["build_problems"] = problems
        timings = {}
        with open(DATA / "timings.csv", "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["version", "benchmark", "run", "seconds", "output_ok", "output"])
            w.writeheader()
            for (version, b), info in sorted(builds.items()):
                if not info["ok"]:
                    timings[(version, b)] = None; continue
                rows = time_runs(info["exe"], b, args.runs)
                for r in rows: w.writerow({"version": version, "benchmark": b, **r})
                timings[(version, b)] = summarize(rows)
        a = []
        for b in BENCHES:
            k, base = timings.get(("koka", b)), timings.get((PASS_BASELINE, b))
            row = {"benchmark": b, "koka": k, "baseline": base}
            for v in [f"{p}-{al}" for p, al in RUST_VERSIONS]:
                row[v] = timings.get((v, b))
            valid = bool(k and base and k["all_outputs_ok"] and base["all_outputs_ok"])
            row["ratio"] = round(k["median"] / base["median"], 3) if valid else None
            row["within_2x"] = valid and row["ratio"] <= 2.0
            a.append(row)
        summary["claim_a"] = {"benchmarks": a, "passed": all(r["within_2x"] for r in a)}
        bres = []
        for b in BENCHES:
            base = timings.get(("koka", b))
            for c in CHANGES:
                t = timings.get((f"koka-{c}", b))
                info = builds.get((f"koka-{c}", b), {})
                bres.append({"benchmark": b, "change": c, "timing": t,
                             "slowdown": round(t["median"] / base["median"], 3) if (t and base) else None,
                             "koka_warnings": info.get("warnings", []),
                             "output_ok": bool(t and t["all_outputs_ok"])})
        summary["claim_b"] = bres
    if "c" in only:
        summary["claim_c"] = claim_c()
    if "d" in only:
        summary["claim_d"] = claim_d()
    (DATA / "summary.json").write_text(json.dumps(summary, indent=2, default=str))

    print("Experiment 3 results")
    if "claim_a" in summary:
        print(f"Claim A (within 2x of {PASS_BASELINE}): {'PASS' if summary['claim_a']['passed'] else 'FAIL'}")
        for r in summary["claim_a"]["benchmarks"]:
            km = r["koka"]["median"] if r["koka"] else None
            bm = r["baseline"]["median"] if r["baseline"] else None
            print(f"  {r['benchmark']}: koka median {km}, baseline median {bm}, ratio {r['ratio']}")
        if summary["build_problems"]:
            print("  build problems:", *summary["build_problems"], sep="\n    ")
        print("Claim B (observational):")
        for r in summary["claim_b"]:
            print(f"  {r['benchmark']}-{r['change']}: slowdown {r['slowdown']}, output ok {r['output_ok']}, "
                  f"koka warnings {len(r['koka_warnings'])}")
    if "claim_c" in summary:
        c = summary["claim_c"]
        print(f"Claim C (all 12 as expected): {'PASS' if c['passed'] else 'FAIL'}")
        for r in c["tests"]:
            print(f"  {r['test']}: expected {r['expected']}, got {r['got']}")
    if "claim_d" in summary:
        d = summary["claim_d"]
        if "error" in d:
            print(f"Claim D: FAIL ({d['error']})")
        else:
            print(f"Claim D (at least 7 of 10): {'PASS' if d['passed'] else 'FAIL'} ({d['successes']} of 10)")
            for r in d["functions"]:
                print(f"  {r['function']}: success {r['success']}, strict fip {r['passes_strict_fip']}")
    print(f"Wrote {DATA / 'timings.csv'} and {DATA / 'summary.json'}")


if __name__ == "__main__":
    main()
