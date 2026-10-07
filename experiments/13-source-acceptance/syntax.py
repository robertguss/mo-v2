"""Acceptance-owned source/tree contract. Experimental spelling, not approved syntax.

No cells or execution state exist in this module. Trees use immutable tuples;
source ranges are token offsets converted to 1-based half-open line/columns.
"""
import re
import sys
from dataclasses import dataclass

# Acceptance-only processes use exact decimal integers, without inheriting a
# host conversion guard as an unapproved language digit cap. This affects both
# int(decimal) and str(integer), not the user's Python installation/settings.
sys.set_int_max_str_digits(0)


class Refusal(Exception):
    def __init__(self, kind, start, end):
        self.kind, self.start, self.end = kind, start, end
        super().__init__(f"{kind}@{start}:{end}")


@dataclass(frozen=True)
class Token:
    word: str
    start: int
    end: int


TOKEN = re.compile(r"\s+|#[^\r\n]*|[A-Za-z_][A-Za-z_0-9]*|[0-9]+|<=|==|->|[+\-<()\[\]|,:;=]")
RESERVED = set("input def main let in if then else end match do Int ListInt Bool true false".split())


def lex(source, encoding=None):
    # Scan only as parsing requests tokens: a later lexical error must not mask
    # a syntax error already present in the consumed prefix (D142).
    pos = 0
    while pos < len(source):
        if encoding is not None and pos == encoding[0]:
            raise Refusal("encoding", encoding[1], encoding[2])
        # An invalid byte is not hidden by a comment or whitespace token.
        limit = len(source) if encoding is None else encoding[0]
        match = TOKEN.match(source, pos, limit)
        if not match:
            raise Refusal("lexical", pos, pos + 1)
        word = match.group()
        if not word.isspace() and not word.startswith("#"):
            if word.isdigit() and len(word) > 1 and word[0] == "0":
                raise Refusal("numeral", pos, match.end())
            yield Token(word, pos, match.end())
        pos = match.end()
    yield Token("EOF", len(source), len(source))


def position(source, offset):
    prefix = source[:offset].replace("\r\n", "\n")
    return [prefix.count("\n") + 1, len(prefix.rsplit("\n", 1)[-1]) + 1]


class Parser:
    def __init__(self, source, encoding=None):
        self.source, self.tokens, self.i = source, [], 0
        self.stream = iter(lex(source, encoding))
        self.spans = {}  # object identity -> original source range
        self.name_spans, self.annotations = {}, {}

    def current(self):
        if self.i == len(self.tokens): self.tokens.append(next(self.stream))
        return self.tokens[self.i]

    def peek(self):
        return self.current().word

    def take(self, wanted=None):
        tok = self.current()
        if wanted is not None and (tok.word != wanted or
                                  (wanted == "EOF" and tok.start != tok.end)):
            raise Refusal("syntax", tok.start, tok.end)
        self.i += 1
        return tok

    def name(self):
        tok = self.take()
        if tok.start == tok.end: raise Refusal("syntax", tok.start, tok.end)
        if tok.word in RESERVED or not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", tok.word):
            raise Refusal("identifier", tok.start, tok.end)
        return tok

    def node(self, start, *parts):
        node = tuple(parts)
        self.spans[id(node)] = (start, self.tokens[self.i - 1].end)
        return node

    def kind(self, declaration):
        tok = self.take()
        if tok.start == tok.end or not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", tok.word):
            raise Refusal("syntax", tok.start, tok.end)
        self.annotations[declaration] = (tok.start, tok.end)
        return tok.word

    def program(self):
        inputs, functions, decl_spans = [], [], []
        while self.peek() == "input":
            self.take(); name = self.name(); self.take(":")
            kind = self.kind(name.start); self.take(";")
            inputs.append((name.word, kind, name.start, name.end))
        while self.peek() == "def":
            start = self.take().start; name = self.name(); self.take("(")
            params = []
            if self.peek() != ")":
                while True:
                    p = self.name(); self.take(":"); kind = self.kind(p.start)
                    params.append((p.word, kind, p.start, p.end))
                    if self.peek() != ",": break
                    self.take(",")
            self.take(")"); self.take(":"); result = self.kind(name.start); self.take("=")
            body = self.expr(); end = self.take("end").end
            functions.append((name.word, tuple(params), result, body, name.start, name.end))
            decl_spans.append((start, end))
        self.take("main"); self.take("="); main = self.expr(); self.take("EOF")
        return {"inputs": inputs, "functions": functions, "main": main,
                "spans": self.spans, "name_spans": self.name_spans,
                "annotations": self.annotations, "decl_spans": decl_spans, "source": self.source}

    def expr(self):
        start = self.current().start
        if self.peek() == "let":
            self.take(); name = self.name(); self.take("="); value = self.expr()
            self.take("in"); body = self.expr()
            return self.node(start, "let", name.word, value, body)
        if self.peek() == "if":
            self.take(); condition = self.expr(); self.take("then"); yes = self.expr()
            self.take("else"); no = self.expr(); self.take("end")
            return self.node(start, "if", condition, yes, no)
        if self.peek() == "match":
            self.take(); value = self.expr(); self.take("do"); self.take("["); self.take("]")
            self.take("->"); empty = self.expr(); self.take(";"); self.take("[")
            head = self.name(); self.take("|"); tail = self.name(); self.take("]"); self.take("->")
            cell = self.expr(); self.take("end")
            node = self.node(start, "match", value, empty, head.word, tail.word, cell)
            self.name_spans[id(node)] = (tail.start, tail.end)
            return node
        left = self.sum()
        if self.peek() in ("==", "<", "<="):
            op = self.take().word; right = self.sum()
            left = self.node(start, {"==": "eq", "<": "lt", "<=": "le"}[op], left, right)
        return left

    def sum(self):
        start = self.current().start; left = self.atom()
        while self.peek() in ("+", "-"):
            op = self.take().word; right = self.atom()
            left = self.node(start, "add" if op == "+" else "sub", left, right)
        return left

    def atom(self):
        start = self.current().start; word = self.peek()
        if word == "-" or word.isdigit():
            negative = word == "-"
            if negative: self.take()
            tok = self.take()
            if not tok.word.isdigit(): raise Refusal("syntax", tok.start, tok.end)
            return self.node(start, "num", (-1 if negative else 1) * int(tok.word))
        if word in ("true", "false"):
            self.take(); return self.node(start, "bool", word == "true")
        if word == "(":
            self.take(); node = self.expr(); self.take(")")
            self.spans[id(node)] = (start, self.tokens[self.i - 1].end)
            return node
        if word == "[":
            self.take()
            if self.peek() == "]":
                self.take(); return self.node(start, "nil")
            head = self.expr()
            if self.peek() == "|":
                self.take(); tail = self.expr(); self.take("]")
                return self.node(start, "cons", head, tail)
            items = [head]
            while self.peek() == ",":
                self.take(); items.append(self.expr())
            self.take("]"); result = self.node(start, "nil")
            for item in reversed(items):
                result = self.node(start, "cons", item, result)
            return result
        name = self.name()
        if self.peek() != "(": return self.node(start, "var", name.word)
        self.take(); args = []
        if self.peek() != ")":
            args.append(self.expr())
            while self.peek() == ",": self.take(); args.append(self.expr())
        self.take(")")
        node = self.node(start, "call", name.word, tuple(args))
        self.name_spans[id(node)] = (name.start, name.end)
        return node


def parse(source):
    encoding = None
    if isinstance(source, bytes):
        try:
            source = source.decode("utf-8", errors="strict")
        except UnicodeDecodeError as error:
            # Discover the byte error, but expose it only when lazy scanning
            # reaches it (D146); an earlier syntax error still wins.
            prefix = source[:error.start].decode("utf-8")
            encoding = (len(prefix), error.start, error.end)
            source = source.decode("utf-8", errors="surrogateescape")
    return Parser(source, encoding).program()


def check(program, stage="B"):
    """Independent lexical kind reference, no memory/evaluation side effects."""
    spans = program["spans"]
    def refuse(kind, node):
        raise Refusal(kind, *spans[id(node)])
    def annotation(kind, declaration, input_only=False):
        if kind not in ("Int", "ListInt") + (() if input_only else ("Bool",)):
            raise Refusal("input-type" if input_only else "type", *program["annotations"][declaration])
    inputs, table = {}, {}
    for name, kind, a, b in program["inputs"]:
        if name in inputs: raise Refusal("duplicate-input", a, b)
        annotation(kind, a, True)
        inputs[name] = kind
    for name, params, result, body, a, b in program["functions"]:
        # Forward lookup does not diagnose later declarations ahead of an earlier body.
        table.setdefault(name, (params, result))
    def infer(e, env):
        op = e[0]
        if op in ("num", "bool", "nil"): return {"num": "Int", "bool": "Bool", "nil": "ListInt"}[op]
        if op == "var":
            if e[1] not in env: refuse("unbound-variable", e)
            return env[e[1]]
        if op in ("add", "sub", "eq", "lt", "le"):
            for child in e[1:]:
                if infer(child, env) != "Int": refuse("operand-kind", child)
            return "Int" if op in ("add", "sub") else "Bool"
        if op == "cons":
            if infer(e[1], env) != "Int": refuse("head-kind", e[1])
            if infer(e[2], env) != "ListInt": refuse("tail-kind", e[2])
            return "ListInt"
        if op == "let":
            kind = infer(e[2], env)
            return infer(e[3], env | {e[1]: kind})
        if op == "if":
            if infer(e[1], env) != "Bool": refuse("condition-kind", e[1])
            a, b = infer(e[2], env), infer(e[3], env)
            if a != b: refuse("branch-kind", e[3])
            return a
        if op == "match":
            if infer(e[1], env) != "ListInt": refuse("scrutinee-kind", e[1])
            a = infer(e[2], env)
            if e[3] == e[4]: raise Refusal("match-binders", *program["name_spans"][id(e)])
            b = infer(e[5], env | {e[3]: "Int", e[4]: "ListInt"})
            if a != b: refuse("branch-kind", e[5])
            return a
        if op == "call":
            if stage == "A": refuse("stage-unsupported", e)
            if e[1] not in table: raise Refusal("unknown-function", *program["name_spans"][id(e)])
            params, result = table[e[1]]
            if len(params) != len(e[2]): refuse("arity", e)
            for arg, (_, kind, _, _) in zip(e[2], params):
                if infer(arg, env) != kind: refuse("argument-kind", arg)
            return result
        raise AssertionError(op)
    if stage == "A" and program["functions"]:
        raise Refusal("stage-unsupported", *program["decl_spans"][0])
    seen = set()
    for name, params, result, body, start, end in program["functions"]:
        if name in seen: raise Refusal("duplicate-function", start, end)
        seen.add(name)
        env = {}
        for param, kind, a, b in params:
            if param in env: raise Refusal("duplicate-parameter", a, b)
            annotation(kind, a)
            env[param] = kind
        annotation(result, start)
        if infer(body, env) != result: refuse("result-kind", body)
    return infer(program["main"], inputs)


def pretty(e):
    op = e[0]
    if op == "num": return str(e[1])
    if op == "bool": return "true" if e[1] else "false"
    if op == "nil": return "[]"
    if op == "var": return e[1]
    if op in ("add", "sub", "eq", "lt", "le"):
        symbol = {"add": "+", "sub": "-", "eq": "==", "lt": "<", "le": "<="}[op]
        return f"({pretty(e[1])} {symbol} {pretty(e[2])})"
    if op == "cons": return f"[{pretty(e[1])} | {pretty(e[2])}]"
    if op == "let": return f"(let {e[1]} = {pretty(e[2])} in {pretty(e[3])})"
    if op == "if": return f"(if {pretty(e[1])} then {pretty(e[2])} else {pretty(e[3])} end)"
    if op == "match": return f"(match {pretty(e[1])} do [] -> {pretty(e[2])}; [{e[3]} | {e[4]}] -> {pretty(e[5])} end)"
    if op == "call": return f"{e[1]}({', '.join(map(pretty, e[2]))})"
    raise AssertionError(op)
