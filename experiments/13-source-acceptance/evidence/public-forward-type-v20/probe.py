"""Public probe for one frozen Stage B question.

An earlier function may call a later one before that later declaration's
type names are validated. This probe asks the frozen name-and-type checker
which refusal is reported. It is not an acceptance case and it is not part
of the builder package.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
import syntax


CASES = {
    "bad-param": "def earlier(n: Int): Int = later(n) end def later(n: Bogus): Int = n end main = 0",
    "bad-result-body": "def earlier(): Int = later() end def later(): Bogus = 0 end main = 0",
    "bad-result-operand": "def earlier(): Int = later() + 1 end def later(): Bogus = 1 end main = 0",
    "bad-result-let-unused": "def earlier(): Int = let x = later() in 0 end def later(): Bogus = 0 end main = 0",
    "bad-result-let-used": "def earlier(): Int = let x = later() in x end def later(): Bogus = 0 end main = 0",
    "no-call-bad-param": "def earlier(): Int = 0 end def later(n: Bogus): Int = 0 end main = 0",
    "no-call-bad-result": "def earlier(): Int = 0 end def later(): Bogus = 0 end main = 0",
    "bad-result-only-in-main": "def later(): Bogus = 0 end main = later()",
    "bad-param-arity": "def earlier(): Int = later() end def later(n: Bogus): Int = 0 end main = 0",
    "bad-param-illtyped-arg": "def earlier(): Int = later(1 + true) end def later(n: Bogus): Int = 0 end main = 0",
    "earlier-result-also-bad": "def earlier(): Bogus = later(0) end def later(n: AlsoBad): Int = 0 end main = 0",
    "bad-result-condition": "def earlier(): Int = if later() then 0 else 1 end end def later(): Bogus = true end main = 0",
    "bad-result-passed-on": "def earlier(): Int = mid(later()) end def later(): Bogus = 0 end def mid(n: Int): Int = n end main = 0",
    "bad-result-both-branches": "def earlier(): Int = if true then later() else later() end end def later(): Bogus = 0 end main = 0",
    "valid-forward": "def earlier(n: Int): Int = later(n) end def later(n: Int): Int = n end main = earlier(1)",
    "bad-param-second": "def earlier(n: Int): Int = later(n, 0) end def later(n: Int, m: Bogus): Int = n end main = 0",
    "bad-result-scrutinee": "def earlier(): Int = match later() do [] -> 0; [h | t] -> h end end def later(): Bogus = [] end main = 0",
    "bad-result-head": "def earlier(): ListInt = [later() | []] end def later(): Bogus = 0 end main = []",
}


def run():
    rows = []
    for name, source in CASES.items():
        try:
            syntax.check(syntax.parse(source), stage="B")
            rows.append({"name": name, "kind": None, "text": None})
        except syntax.Refusal as exc:
            rows.append({"name": name, "kind": exc.kind, "text": source[exc.start:exc.end]})
    return rows


if __name__ == "__main__":
    for row in run():
        print(f"{row['name']}: {row['kind']} text={row['text']!r}")
