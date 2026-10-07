"""Independent failure-prefix expectations for numeric/frame hook integration."""
from copy import deepcopy
import json
from pathlib import Path
import sys
import traceback


def check_failure(before, after, attempts, failure, domain, ordinal):
    assert json.dumps(after, sort_keys=True) == json.dumps(before, sort_keys=True), "fault changed last committed state/events"
    expected = dict(status="failed", **{"class": "resource-exhausted"}, step=before["step"], domain=domain)
    assert json.dumps(failure, sort_keys=True) == json.dumps(expected, sort_keys=True), "fault classification/step"
    counts = {}
    for kind, n, allowed in attempts:
        assert kind in ("number", "frame") and type(n) is int, "fault domain/ordinal kind"
        counts[kind] = counts.get(kind, 0) + 1
        assert n == counts[kind] and type(allowed) is bool, "fault ordinal sequence"
    denied = [(d, n) for d, n, allowed in attempts if not allowed]
    assert denied == [(domain, ordinal)] and attempts[-1] == [domain, ordinal, False], "fault denied attempt"


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, domains=0, controls={}, candidate_executed=False)
    try:
        before = dict(step=2, state=dict(pending=[["l", 7]], memory=[[7, "3", None, 1, "live"]]), events=[])
        for domain in ("number", "frame"):
            other = "frame" if domain == "number" else "number"
            attempts = [[domain, 1, True], [other, 1, True], [domain, 2, False]]
            failure = dict(status="failed", **{"class": "resource-exhausted"}, step=2, domain=domain)
            check_failure(before, deepcopy(before), attempts, failure, domain, 2)
            report["domains"] += 1
            for name in ("partial-effect", "Boolean-count", "suspended", "skipped-hook", "wrong-ordinal", "late-failure"):
                after, log, error = deepcopy(before), deepcopy(attempts), deepcopy(failure)
                if name == "partial-effect": after["state"]["memory"][0][1] = "9"
                elif name == "Boolean-count": after["state"]["memory"][0][3] = True
                elif name == "suspended": error["status"] = "suspended"
                elif name == "skipped-hook": log.pop()
                elif name == "wrong-ordinal": log[-1][1] = 3
                else: error["step"] = 3
                try: check_failure(before, after, log, error, domain, 2)
                except AssertionError as caught: report["controls"][domain + "/" + name] = str(caught)
                else: raise AssertionError("fault control accepted")
        report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
