"""Proposed JSON implementation optimization, not an approved frozen checker.

Keep canonical-JSON equality (including Boolean/number distinctions), duplicate
key rejection, non-JSON number rejection, and exact object field sets. Only
plain primitives and lists have an equality fast path; other shapes keep the
original canonical serialization. No expected value is cached or skipped.
"""
from functools import lru_cache
import json


def _unique(pairs):
    result = dict(pairs)
    assert len(result) == len(pairs), "duplicate JSON key"
    return result


def _invalid(value):
    raise AssertionError("non-JSON number")


_DECODER = json.JSONDecoder(object_pairs_hook=_unique, parse_constant=_invalid)
_ENCODER = json.JSONEncoder(sort_keys=True, separators=(",", ":"))
_PRIMITIVES = (str, int, bool, type(None))


def load(raw):
    if type(raw) is str and not raw.startswith('\ufeff'):
        return _DECODER.decode(raw)
    if type(raw) in (bytes, bytearray):
        # The same encoding detection and error mode used by json.loads.
        return _DECODER.decode(raw.decode(json.detect_encoding(raw), 'surrogatepass'))
    return json.loads(raw, object_pairs_hook=_unique, parse_constant=_invalid)


def _equal(actual, expected):
    kind = type(actual)
    if kind is type(expected):
        if kind in _PRIMITIVES:
            return actual == expected
        if kind is list:
            if len(actual) != len(expected):
                return False
            for a, b in zip(actual, expected):
                if not _equal(a, b):
                    return False
            return True
    # Floats deliberately use JSON, preserving e.g. 0.0 versus -0.0.
    return json.dumps(actual, sort_keys=True) == json.dumps(expected, sort_keys=True)


def exact(actual, expected, message):
    assert _equal(actual, expected), message


@lru_cache(maxsize=128)
def _field_names(names):
    return frozenset(names.split())


def fields(obj, names):
    assert type(obj) is dict and obj.keys() == _field_names(names), "schema fields"


def hash_item(digest, item):
    digest.update(_ENCODER.encode(item).encode() + b'\n')
