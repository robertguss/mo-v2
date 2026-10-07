"""Draft byte/diagnostic contract; candidate-independent fixtures, not Mo output."""
import json
from pathlib import Path
import re
import sys
import traceback

from syntax import Refusal, check, parse, position


DECIMAL = re.compile(r"0|-?[1-9][0-9]*")
NATURAL = re.compile(r"0|[1-9][0-9]*")


def public_bytes(record):
    return (json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")


def check_public(actual, expected):
    assert type(actual) is bytes and actual.endswith(b"\n") and actual.count(b"\n") == 1, "one LF line"
    def unique(pairs):
        assert len(dict(pairs)) == len(pairs), "duplicate output key"
        return dict(pairs)
    record = json.loads(actual.decode("utf-8", errors="strict"), object_pairs_hook=unique)
    status = record["status"]
    keys = {"finished": ["status", "type", "value"], "suspended": ["status", "steps"],
            "failed": ["status", "class", "step"], "refused": ["status", "class", "span"],
            "invalid-fixture": ["status", "class", "path"]}
    assert status in keys and list(record) == keys[status], "output fields/order"
    if status == "finished":
        kind, value = record["type"], record["value"]
        if kind == "Bool": assert type(value) is bool, "Boolean output kind"
        elif kind == "Int": assert type(value) is str and DECIMAL.fullmatch(value), "integer output"
        else:
            assert kind == "ListInt" and type(value) is list, "list output kind"
            assert all(type(v) is str and DECIMAL.fullmatch(v) for v in value), "integer list output"
    if status in ("suspended", "failed"):
        step = record["steps" if status == "suspended" else "step"]
        assert type(step) is str and NATURAL.fullmatch(step), "cumulative step output"
    assert actual == public_bytes(record), "compact canonical output"
    assert actual == expected, "independent public bytes"
    return record


# Counts/spans stated before running; encoding offsets are bytes, all others
# below are scalar offsets converted to 1-based columns by the reporter.
ENCODING = [
    (b"main = (1 2) \xff", ("syntax", 10, 11)),
    (b"main = (1 \xff 2)", ("encoding", 10, 11)),
    (b"\xffmain = (1 2)", ("encoding", 0, 1)),
    (b"main = @ \xff", ("lexical", 7, 8)),
    (b"main = 01 \xff", ("numeral", 7, 9)),
    (b"main = ghost \xff", ("encoding", 13, 14)),
    (b"main = 3 # \xff", ("encoding", 11, 12)),
    (b"main = \xe2\x82", ("encoding", 7, 9)),
    (b"# \xc3\xa9\nmain = \xff", ("encoding", 12, 13)),
    (b"main = (1 2) # \xff", ("syntax", 10, 11)),
    (b"main = true + 1 \xff", ("encoding", 16, 17)),
    (b"input n: Int; input n: Int; main = \xff", ("encoding", 35, 36)),
]


def run(destination):
    destination.mkdir(parents=True, exist_ok=False)
    report = dict(passed=False, encoding=0, output=0, controls=0, candidate_executed=False)
    try:
        for source, expected in ENCODING:
            try: check(parse(source))
            except Refusal as error: assert (error.kind, error.start, error.end) == expected, source.hex()
            else: raise AssertionError("malformed source accepted")
            report["encoding"] += 1
        assert position("main = (1 2) ", 10) == [1, 11]
        assert check(parse(b"# \xc3\xa9\r\nmain = true")) == "Bool"
        records = [
            ({"status": "finished", "type": "Int", "value": "-9"}, b'{"status":"finished","type":"Int","value":"-9"}\n'),
            ({"status": "finished", "type": "Bool", "value": False}, b'{"status":"finished","type":"Bool","value":false}\n'),
            ({"status": "finished", "type": "ListInt", "value": ["7", "-2"]}, b'{"status":"finished","type":"ListInt","value":["7","-2"]}\n'),
            ({"status": "suspended", "steps": "17"}, b'{"status":"suspended","steps":"17"}\n'),
            ({"status": "failed", "class": "resource-exhausted", "step": "2"}, b'{"status":"failed","class":"resource-exhausted","step":"2"}\n'),
            ({"status": "refused", "class": "syntax", "span": {"start": [1, 11], "end": [1, 12]}}, b'{"status":"refused","class":"syntax","span":{"start":[1,11],"end":[1,12]}}\n'),
            ({"status": "refused", "class": "encoding", "span": {"bytes": [13, 14]}}, b'{"status":"refused","class":"encoding","span":{"bytes":[13,14]}}\n'),
            ({"status": "invalid-fixture", "class": "dangling", "path": "inputs/0"}, b'{"status":"invalid-fixture","class":"dangling","path":"inputs/0"}\n'),
        ]
        for record, expected in records:
            check_public(public_bytes(record), expected); report["output"] += 1
        wide = "1" + "0" * 5000
        expected = ('{"status":"finished","type":"Int","value":"' + wide + '"}\n').encode()
        check_public(public_bytes(dict(status="finished", type="Int", value=wide)), expected)
        report["output"] += 1
        valid = records[0][1]
        for broken in [valid[:-1], valid + b"\n", valid.replace(b'"-9"', b'-9'),
                       valid.replace(b'"-9"', b'"-09"'), valid.replace(b',', b', '),
                       b'{"status":"finished","status":"suspended","steps":"17"}\n',
                       public_bytes(dict(status="finished", type="Bool", value=0))]:
            try: check_public(broken, valid)
            except (AssertionError, ValueError, KeyError): report["controls"] += 1
            else: raise AssertionError("bad public output accepted")
        report["passed"] = True
    except Exception: report["error"] = traceback.format_exc()
    (destination / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2)); return report["passed"]


if __name__ == "__main__": sys.exit(not run(Path(sys.argv[1])))
