use mo_acceptance_runtime::{CheckFailure, Diagnostic, Kind, Span};
use serde::{Serialize, Serializer, ser::SerializeMap};
use serde_json::{Value as Json, json};
use std::collections::BTreeSet;
use std::sync::Arc;

pub(crate) type NodeId = usize;
pub(crate) type DeclId = usize;

#[derive(Clone, Copy, Debug)]
pub(crate) struct Range {
    pub start: usize,
    pub end: usize,
}

#[derive(Clone, Debug)]
pub(crate) enum Expr {
    Int(Arc<String>),
    Bool(bool),
    Nil,
    Var {
        name: String,
        binding: DeclId,
        name_range: Range,
    },
    Add,
    Sub,
    Eq,
    Lt,
    Le,
    Cons,
    Let(DeclId),
    Match(DeclId, DeclId),
    If,
    Call,
}

pub(crate) struct Node {
    pub expr: Expr,
    pub children: Vec<NodeId>,
    pub range: Range,
    pub path: String,
    pub kind: Kind,
    pub uses: BTreeSet<DeclId>,
}

pub(crate) struct Declaration {
    pub name: String,
    pub range: Range,
    pub kind: Kind,
    pub path: String,
}

pub(crate) struct Input {
    pub declaration: DeclId,
    annotation: String,
    annotation_range: Range,
    range: Range,
}

pub(crate) struct Program {
    pub nodes: Vec<Node>,
    pub declarations: Vec<Declaration>,
    pub inputs: Vec<Input>,
    pub main: NodeId,
    source: String,
}

pub(crate) fn kind_name(kind: &Kind) -> &'static str {
    match kind {
        Kind::Int => "Int",
        Kind::Bool => "Bool",
        Kind::ListInt => "ListInt",
    }
}

impl Program {
    pub fn dump(&self) -> Vec<u8> {
        // Serialize borrowed numerals straight into output bytes. Do not create
        // extra owned numeric Strings outside the Number allocation boundary.
        serde_json::to_vec(self).unwrap()
    }

    pub fn spans(&self) -> Vec<u8> {
        let mut rows = vec![
            json!({"path":"root", "span":text_span(&self.source, Range { start:0, end:self.source.len() })}),
        ];
        for input in &self.inputs {
            rows.push(json!({"path":self.declarations[input.declaration].path, "span":text_span(&self.source, input.range)}));
        }
        let mut pending = vec![self.main];
        while let Some(id) = pending.pop() {
            let node = &self.nodes[id];
            rows.push(json!({"path":node.path, "span":text_span(&self.source, node.range)}));
            pending.extend(node.children.iter().rev().copied());
        }
        serde_json::to_vec(&rows).unwrap()
    }
}

#[derive(Serialize)]
struct DeclarationDump<'a> {
    name: &'a str,
    r#type: &'static str,
    binding: &'a str,
}
#[derive(Serialize)]
struct BinderDump<'a> {
    name: &'a str,
    binding: &'a str,
}
struct NodeDump<'a>(&'a Program, NodeId);

impl Serialize for Program {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut map = serializer.serialize_map(Some(4))?;
        map.serialize_entry("node", "Program")?;
        let inputs: Vec<_> = self
            .inputs
            .iter()
            .map(|input| {
                let decl = &self.declarations[input.declaration];
                DeclarationDump {
                    name: &decl.name,
                    r#type: kind_name(&decl.kind),
                    binding: &decl.path,
                }
            })
            .collect();
        map.serialize_entry("inputs", &inputs)?;
        map.serialize_entry("functions", &[] as &[()])?;
        map.serialize_entry("main", &NodeDump(self, self.main))?;
        map.end()
    }
}

impl Serialize for NodeDump<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let program = self.0;
        let node = &program.nodes[self.1];
        let tag = match &node.expr {
            Expr::Int(_) => "Int",
            Expr::Bool(_) => "Bool",
            Expr::Nil => "Nil",
            Expr::Var { .. } => "Var",
            Expr::Add => "Add",
            Expr::Sub => "Sub",
            Expr::Eq => "Eq",
            Expr::Lt => "Lt",
            Expr::Le => "Le",
            Expr::Cons => "Cons",
            Expr::Let(_) => "Let",
            Expr::Match(..) => "Match",
            Expr::If => "If",
            Expr::Call => unreachable!("checked Stage A cannot contain calls"),
        };
        let mut map = serializer.serialize_map(None)?;
        map.serialize_entry("node", tag)?;
        map.serialize_entry("path", &node.path)?;
        map.serialize_entry("type", kind_name(&node.kind))?;
        match &node.expr {
            Expr::Int(value) => map.serialize_entry("value", value.as_str())?,
            Expr::Bool(value) => map.serialize_entry("value", value)?,
            Expr::Var { name, binding, .. } => {
                map.serialize_entry("name", name)?;
                map.serialize_entry("binding", &program.declarations[*binding].path)?;
            }
            Expr::Let(binding) => {
                map.serialize_entry("name", &program.declarations[*binding].name)?;
                map.serialize_entry("binding", &program.declarations[*binding].path)?;
            }
            Expr::Match(head, tail) => {
                for (field, id) in [("head", head), ("tail", tail)] {
                    let decl = &program.declarations[*id];
                    map.serialize_entry(
                        field,
                        &BinderDump {
                            name: &decl.name,
                            binding: &decl.path,
                        },
                    )?;
                }
            }
            _ => {}
        }
        if !node.children.is_empty() {
            let children: Vec<_> = node
                .children
                .iter()
                .map(|&id| NodeDump(program, id))
                .collect();
            map.serialize_entry("children", &children)?;
        }
        map.end()
    }
}

fn position(source: &str, offset: usize) -> (u64, u64) {
    let (mut line, mut column) = (1, 1);
    let mut chars = source[..offset].chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\r' && chars.peek() == Some(&'\n') {
            chars.next();
            line += 1;
            column = 1;
        } else if c == '\n' {
            line += 1;
            column = 1;
        } else {
            column += 1;
        }
    }
    (line, column)
}

fn span(source: &str, range: Range) -> Span {
    Span::Text {
        start: position(source, range.start),
        end: position(source, range.end),
    }
}

fn text_span(source: &str, range: Range) -> Json {
    json!({"start":position(source, range.start), "end":position(source, range.end)})
}

fn refused(source: &str, class: &str, range: Range) -> CheckFailure {
    CheckFailure::Refused(Diagnostic {
        class: class.into(),
        span: span(source, range),
    })
}

#[derive(Clone, Debug)]
enum TokenKind {
    Word,
    Number,
    Punctuation,
    Bad(&'static str),
    Encoding(usize),
    Eof,
}
#[derive(Clone, Debug)]
struct Token {
    kind: TokenKind,
    range: Range,
}

fn lex(bytes: &[u8]) -> (String, Vec<Token>) {
    let (valid, encoding) = match std::str::from_utf8(bytes) {
        Ok(s) => (s, None),
        Err(e) => (
            std::str::from_utf8(&bytes[..e.valid_up_to()]).unwrap(),
            Some((
                e.valid_up_to(),
                e.error_len().unwrap_or(bytes.len() - e.valid_up_to()),
            )),
        ),
    };
    let mut tokens = Vec::new();
    let mut i = 0;
    let b = valid.as_bytes();
    while i < b.len() {
        if matches!(b[i], b' ' | b'\t' | b'\n' | b'\r') {
            i += 1;
            continue;
        }
        if b[i] == b'#' {
            while i < b.len() && b[i] != b'\n' {
                i += 1;
            }
            continue;
        }
        let start = i;
        let kind = if b[i].is_ascii_alphabetic() || b[i] == b'_' {
            i += 1;
            while i < b.len() && (b[i].is_ascii_alphanumeric() || b[i] == b'_') {
                i += 1;
            }
            TokenKind::Word
        } else if b[i].is_ascii_digit() {
            i += 1;
            while i < b.len() && (b[i].is_ascii_alphanumeric() || b[i] == b'_' || b[i] == b'.') {
                i += 1;
            }
            let s = &b[start..i];
            if (s.len() > 1 && s[0] == b'0') || s.iter().any(|c| !c.is_ascii_digit()) {
                TokenKind::Bad("numeral")
            } else {
                TokenKind::Number
            }
        } else if ["<=", "->", "=="].iter().any(|s| valid[i..].starts_with(s)) {
            i += 2;
            TokenKind::Punctuation
        } else if b";:()[]=|,+-<".contains(&b[i]) {
            i += 1;
            TokenKind::Punctuation
        } else {
            i += valid[i..].chars().next().unwrap().len_utf8();
            TokenKind::Bad("lexical")
        };
        tokens.push(Token {
            kind,
            range: Range { start, end: i },
        });
    }
    if let Some((start, length)) = encoding {
        tokens.push(Token {
            kind: TokenKind::Encoding(start + length),
            range: Range { start, end: start },
        });
    }
    tokens.push(Token {
        kind: TokenKind::Eof,
        range: Range { start: i, end: i },
    });
    (valid.into(), tokens)
}

fn reserved(text: &str) -> bool {
    matches!(
        text,
        "input"
            | "def"
            | "main"
            | "let"
            | "in"
            | "if"
            | "then"
            | "else"
            | "end"
            | "match"
            | "do"
            | "true"
            | "false"
            | "Int"
            | "Bool"
            | "ListInt"
    )
}

type AllocateNumber<'a> = &'a mut dyn FnMut(&str, bool) -> Result<String, CheckFailure>;

struct Parser<'a> {
    program: Program,
    tokens: Vec<Token>,
    at: usize,
    allocate: AllocateNumber<'a>,
}

pub(crate) fn check(bytes: &[u8], allocate: AllocateNumber<'_>) -> Result<Program, CheckFailure> {
    let (source, tokens) = lex(bytes);
    let mut p = Parser {
        program: Program {
            source,
            nodes: Vec::new(),
            declarations: Vec::new(),
            inputs: Vec::new(),
            main: 0,
        },
        tokens,
        at: 0,
        allocate,
    };
    while p.is("input") {
        let start = p.take()?.range.start;
        let name = p.identifier()?;
        p.expect(":")?;
        let annotation = p.annotation()?;
        let end = p.expect(";")?.range.end;
        let declaration = p.declaration(&name);
        p.program.inputs.push(Input {
            declaration,
            annotation: p.text(&annotation).into(),
            annotation_range: annotation.range,
            range: Range { start, end },
        });
    }
    let mut first_function = None;
    while p.is("def") {
        let start = p.take()?.range.start;
        p.identifier()?;
        p.expect("(")?;
        if !p.is(")") {
            loop {
                p.identifier()?;
                p.expect(":")?;
                p.annotation()?;
                if !p.eat(",")? {
                    break;
                }
            }
        }
        p.expect(")")?;
        p.expect(":")?;
        p.annotation()?;
        p.expect("=")?;
        p.expression()?;
        let end = p.expect("end")?.range.end;
        first_function.get_or_insert(Range { start, end });
    }
    p.expect("main")?;
    p.expect("=")?;
    p.program.main = p.expression()?;
    if !matches!(p.current().kind, TokenKind::Eof) {
        return Err(p.error());
    }
    let mut scope = Vec::new();
    for (i, input) in p.program.inputs.iter().enumerate() {
        let declaration = &p.program.declarations[input.declaration];
        if scope
            .iter()
            .any(|&id: &usize| p.program.declarations[id].name == declaration.name)
        {
            return Err(refused(
                &p.program.source,
                "duplicate-input",
                declaration.range,
            ));
        }
        let kind = match input.annotation.as_str() {
            "Int" => Kind::Int,
            "ListInt" => Kind::ListInt,
            _ => {
                return Err(refused(
                    &p.program.source,
                    "input-type",
                    input.annotation_range,
                ));
            }
        };
        let declaration = &mut p.program.declarations[input.declaration];
        declaration.kind = kind;
        declaration.path = format!("input/{i}");
        scope.push(input.declaration);
    }
    if let Some(range) = first_function {
        return Err(refused(&p.program.source, "stage-unsupported", range));
    }
    let main = p.program.main;
    p.paths(main, "main".into());
    p.check_node(main, &mut scope)?;
    Ok(p.program)
}

impl Parser<'_> {
    fn current(&self) -> &Token {
        &self.tokens[self.at]
    }
    fn text<'s>(&'s self, token: &Token) -> &'s str {
        &self.program.source[token.range.start..token.range.end]
    }
    fn is(&self, text: &str) -> bool {
        !matches!(self.current().kind, TokenKind::Encoding(_) | TokenKind::Eof)
            && self.text(self.current()) == text
    }
    fn error(&self) -> CheckFailure {
        let token = self.current();
        match token.kind {
            TokenKind::Encoding(end) => CheckFailure::Refused(Diagnostic {
                class: "encoding".into(),
                span: Span::Bytes {
                    start: token.range.start as u64,
                    end: end as u64,
                },
            }),
            TokenKind::Bad(class) => refused(&self.program.source, class, token.range),
            _ => refused(&self.program.source, "syntax", token.range),
        }
    }
    fn take(&mut self) -> Result<Token, CheckFailure> {
        if matches!(
            self.current().kind,
            TokenKind::Bad(_) | TokenKind::Encoding(_) | TokenKind::Eof
        ) {
            return Err(self.error());
        }
        let token = self.current().clone();
        self.at += 1;
        Ok(token)
    }
    fn expect(&mut self, text: &str) -> Result<Token, CheckFailure> {
        if !self.is(text) {
            // Present tokens keep their width; EOF already has an empty range.
            return Err(self.error());
        }
        self.take()
    }
    fn eat(&mut self, text: &str) -> Result<bool, CheckFailure> {
        if self.is(text) {
            self.take()?;
            Ok(true)
        } else {
            Ok(false)
        }
    }
    fn identifier(&mut self) -> Result<Token, CheckFailure> {
        if !matches!(self.current().kind, TokenKind::Word) || reserved(self.text(self.current())) {
            return Err(self.error());
        }
        self.take()
    }
    fn annotation(&mut self) -> Result<Token, CheckFailure> {
        if !matches!(self.current().kind, TokenKind::Word) {
            return Err(self.error());
        }
        self.take()
    }
    fn declaration(&mut self, name: &Token) -> DeclId {
        let id = self.program.declarations.len();
        self.program.declarations.push(Declaration {
            name: self.text(name).into(),
            range: name.range,
            kind: Kind::Int,
            path: String::new(),
        });
        id
    }
    fn node(&mut self, expr: Expr, children: Vec<NodeId>, range: Range) -> NodeId {
        let id = self.program.nodes.len();
        self.program.nodes.push(Node {
            expr,
            children,
            range,
            path: String::new(),
            kind: Kind::Int,
            uses: BTreeSet::new(),
        });
        id
    }
    fn expression(&mut self) -> Result<NodeId, CheckFailure> {
        let start = self.current().range.start;
        if self.eat("let")? {
            let name = self.identifier()?;
            let decl = self.declaration(&name);
            self.expect("=")?;
            let init = self.expression()?;
            self.expect("in")?;
            let body = self.expression()?;
            return Ok(self.node(
                Expr::Let(decl),
                vec![init, body],
                Range {
                    start,
                    end: self.program.nodes[body].range.end,
                },
            ));
        }
        if self.eat("if")? {
            let condition = self.expression()?;
            self.expect("then")?;
            let yes = self.expression()?;
            self.expect("else")?;
            let no = self.expression()?;
            let end = self.expect("end")?.range.end;
            return Ok(self.node(Expr::If, vec![condition, yes, no], Range { start, end }));
        }
        if self.eat("match")? {
            let scrutinee = self.expression()?;
            self.expect("do")?;
            self.expect("[")?;
            self.expect("]")?;
            self.expect("->")?;
            let empty = self.expression()?;
            self.expect(";")?;
            self.expect("[")?;
            let head = self.identifier()?;
            self.expect("|")?;
            let tail = self.identifier()?;
            self.expect("]")?;
            self.expect("->")?;
            let head = self.declaration(&head);
            let tail = self.declaration(&tail);
            let nonempty = self.expression()?;
            let end = self.expect("end")?.range.end;
            return Ok(self.node(
                Expr::Match(head, tail),
                vec![scrutinee, empty, nonempty],
                Range { start, end },
            ));
        }
        let lhs = self.sum()?;
        let op = if self.is("==") {
            Some(Expr::Eq)
        } else if self.is("<") {
            Some(Expr::Lt)
        } else if self.is("<=") {
            Some(Expr::Le)
        } else {
            None
        };
        if let Some(op) = op {
            self.take()?;
            let rhs = self.sum()?;
            Ok(self.node(
                op,
                vec![lhs, rhs],
                Range {
                    start,
                    end: self.program.nodes[rhs].range.end,
                },
            ))
        } else {
            Ok(lhs)
        }
    }
    fn sum(&mut self) -> Result<NodeId, CheckFailure> {
        let mut lhs = self.atom()?;
        while self.is("+") || self.is("-") {
            let op = if self.eat("+")? {
                Expr::Add
            } else {
                self.expect("-")?;
                Expr::Sub
            };
            let rhs = self.atom()?;
            lhs = self.node(
                op,
                vec![lhs, rhs],
                Range {
                    start: self.program.nodes[lhs].range.start,
                    end: self.program.nodes[rhs].range.end,
                },
            );
        }
        Ok(lhs)
    }
    fn atom(&mut self) -> Result<NodeId, CheckFailure> {
        let start = self.current().range.start;
        if self.eat("(")? {
            let id = self.expression()?;
            let end = self.expect(")")?.range.end;
            self.program.nodes[id].range = Range { start, end };
            return Ok(id);
        }
        if self.eat("[")? {
            if self.eat("]")? {
                return Ok(self.node(
                    Expr::Nil,
                    vec![],
                    Range {
                        start,
                        end: self.tokens[self.at - 1].range.end,
                    },
                ));
            }
            let first = self.expression()?;
            if self.eat("|")? {
                let tail = self.expression()?;
                let end = self.expect("]")?.range.end;
                return Ok(self.node(Expr::Cons, vec![first, tail], Range { start, end }));
            }
            let mut items = vec![first];
            while self.eat(",")? {
                items.push(self.expression()?);
            }
            let end = self.expect("]")?.range.end;
            let range = Range { start, end };
            let mut tail = self.node(Expr::Nil, vec![], range);
            for head in items.into_iter().rev() {
                tail = self.node(Expr::Cons, vec![head, tail], range);
            }
            return Ok(tail);
        }
        let negative = self.eat("-")?;
        if matches!(self.current().kind, TokenKind::Number) {
            let token = self.take()?;
            let digits = &self.program.source[token.range.start..token.range.end];
            let value = (self.allocate)(digits, negative)?;
            return Ok(self.node(
                Expr::Int(Arc::new(value)),
                vec![],
                Range {
                    start,
                    end: token.range.end,
                },
            ));
        }
        if negative {
            return Err(self.error());
        }
        if self.is("true") || self.is("false") {
            let value = self.is("true");
            let token = self.take()?;
            return Ok(self.node(Expr::Bool(value), vec![], token.range));
        }
        let name = self.identifier()?;
        if self.eat("(")? {
            let mut args = Vec::new();
            if !self.is(")") {
                loop {
                    args.push(self.expression()?);
                    if !self.eat(",")? {
                        break;
                    }
                }
            }
            let end = self.expect(")")?.range.end;
            Ok(self.node(Expr::Call, args, Range { start, end }))
        } else {
            Ok(self.node(
                Expr::Var {
                    name: self.text(&name).into(),
                    binding: usize::MAX,
                    name_range: name.range,
                },
                vec![],
                name.range,
            ))
        }
    }
    fn paths(&mut self, id: NodeId, path: String) {
        match self.program.nodes[id].expr {
            Expr::Let(decl) => self.program.declarations[decl].path = format!("{path}/binding"),
            Expr::Match(head, tail) => {
                self.program.declarations[head].path = format!("{path}/head");
                self.program.declarations[tail].path = format!("{path}/tail");
            }
            _ => {}
        }
        let children = self.program.nodes[id].children.clone();
        for (i, child) in children.into_iter().enumerate() {
            self.paths(child, format!("{path}/{i}"));
        }
        self.program.nodes[id].path = path;
    }
    fn require(&self, id: NodeId, kind: Kind, class: &str) -> Result<(), CheckFailure> {
        if self.program.nodes[id].kind != kind {
            Err(refused(
                &self.program.source,
                class,
                self.program.nodes[id].range,
            ))
        } else {
            Ok(())
        }
    }
    fn check_node(&mut self, id: NodeId, scope: &mut Vec<DeclId>) -> Result<Kind, CheckFailure> {
        let children = self.program.nodes[id].children.clone();
        let expr = self.program.nodes[id].expr.clone();
        let old_len = scope.len();
        let kind = match expr {
            Expr::Int(_) => Kind::Int,
            Expr::Bool(_) => Kind::Bool,
            Expr::Nil => Kind::ListInt,
            Expr::Call => {
                return Err(refused(
                    &self.program.source,
                    "stage-unsupported",
                    self.program.nodes[id].range,
                ));
            }
            Expr::Var {
                name, name_range, ..
            } => {
                let Some(&binding) = scope
                    .iter()
                    .rev()
                    .find(|&&decl| self.program.declarations[decl].name == name)
                else {
                    return Err(refused(
                        &self.program.source,
                        "unbound-variable",
                        name_range,
                    ));
                };
                self.program.nodes[id].expr = Expr::Var {
                    name,
                    binding,
                    name_range,
                };
                self.program.nodes[id].uses.insert(binding);
                self.program.declarations[binding].kind.clone()
            }
            Expr::Add | Expr::Sub | Expr::Eq | Expr::Lt | Expr::Le | Expr::Cons => {
                let cons = matches!(expr, Expr::Cons);
                self.check_node(children[0], scope)?;
                self.require(
                    children[0],
                    Kind::Int,
                    if cons { "head-kind" } else { "operand-kind" },
                )?;
                self.check_node(children[1], scope)?;
                self.require(
                    children[1],
                    if cons { Kind::ListInt } else { Kind::Int },
                    if cons { "tail-kind" } else { "operand-kind" },
                )?;
                if cons {
                    Kind::ListInt
                } else if matches!(expr, Expr::Add | Expr::Sub) {
                    Kind::Int
                } else {
                    Kind::Bool
                }
            }
            Expr::Let(decl) => {
                let kind = self.check_node(children[0], scope)?;
                self.program.declarations[decl].kind = kind;
                scope.push(decl);
                self.check_node(children[1], scope)?
            }
            Expr::If => {
                self.check_node(children[0], scope)?;
                self.require(children[0], Kind::Bool, "condition-kind")?;
                let kind = self.check_node(children[1], scope)?;
                self.check_node(children[2], scope)?;
                self.require(children[2], kind.clone(), "branch-kind")?;
                kind
            }
            Expr::Match(head, tail) => {
                self.check_node(children[0], scope)?;
                self.require(children[0], Kind::ListInt, "scrutinee-kind")?;
                let kind = self.check_node(children[1], scope)?;
                if self.program.declarations[head].name == self.program.declarations[tail].name {
                    return Err(refused(
                        &self.program.source,
                        "match-binders",
                        self.program.declarations[tail].range,
                    ));
                }
                self.program.declarations[head].kind = Kind::Int;
                self.program.declarations[tail].kind = Kind::ListInt;
                scope.extend([head, tail]);
                self.check_node(children[2], scope)?;
                self.require(children[2], kind.clone(), "branch-kind")?;
                kind
            }
        };
        scope.truncate(old_len);
        for child in children {
            let uses = self.program.nodes[child].uses.clone();
            self.program.nodes[id].uses.extend(uses);
        }
        match self.program.nodes[id].expr {
            Expr::Let(decl) => {
                self.program.nodes[id].uses.remove(&decl);
            }
            Expr::Match(head, tail) => {
                self.program.nodes[id].uses.remove(&head);
                self.program.nodes[id].uses.remove(&tail);
            }
            _ => {}
        }
        self.program.nodes[id].kind = kind.clone();
        Ok(kind)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::number;
    use mo_acceptance_runtime::Resource;

    pub(super) fn parse(source: &[u8]) -> Result<Program, CheckFailure> {
        check(source, &mut |digits, negative| {
            Ok(number::literal(digits, negative))
        })
    }
    fn diagnostic(source: &[u8], class: &str, start: (u64, u64), end: (u64, u64)) {
        let actual = match parse(source) {
            Ok(_) => panic!("expected refusal"),
            Err(e) => e,
        };
        assert_eq!(
            actual,
            CheckFailure::Refused(Diagnostic {
                class: class.into(),
                span: Span::Text { start, end }
            })
        );
    }
    fn dump(source: &str) -> Json {
        serde_json::from_slice(&parse(source.as_bytes()).unwrap().dump()).unwrap()
    }

    #[test]
    fn left_association_and_grouping_use_one_tree() {
        let left = dump("main = 23 - 8 - 6");
        assert_eq!(left["main"]["node"], "Sub");
        assert_eq!(left["main"]["children"][0]["node"], "Sub");
        assert_eq!(left["main"]["children"][0]["children"][1]["value"], "8");
        assert_eq!(left["main"]["children"][1]["value"], "6");
        let right = dump("main = 23 - (8 - 6)");
        assert_eq!(right["main"]["children"][0]["value"], "23");
        assert_eq!(right["main"]["children"][1]["node"], "Sub");
    }

    #[test]
    fn shadowing_and_initializer_resolution() {
        let value = dump("input v: Int; main = let v = v + 1 in let v = v - 2 in v");
        let outer = &value["main"];
        assert_eq!(outer["binding"], "main/binding");
        assert_eq!(outer["children"][0]["children"][0]["binding"], "input/0");
        let inner = &outer["children"][1];
        assert_eq!(
            inner["children"][0]["children"][0]["binding"],
            "main/binding"
        );
        assert_eq!(inner["children"][1]["binding"], "main/1/binding");
        assert!(value.get("path").is_none());
        assert!(value["inputs"][0].get("node").is_none());
    }

    #[test]
    fn literal_expansion_keys_and_ranges() {
        let program = parse(b"main = [42,- 7]").unwrap();
        let value: Json = serde_json::from_slice(&program.dump()).unwrap();
        assert_eq!(value["main"]["node"], "Cons");
        assert_eq!(value["main"]["children"][1]["children"][0]["value"], "-7");
        let nil = &value["main"]["children"][1]["children"][1];
        assert_eq!(nil.as_object().unwrap().len(), 3);
        assert_eq!(nil["node"], "Nil");
        let spans: Json = serde_json::from_slice(&program.spans()).unwrap();
        assert_eq!(
            spans[1],
            json!({"path":"main","span":{"start":[1,8],"end":[1,16]}})
        );
        assert_eq!(
            spans[2],
            json!({"path":"main/0","span":{"start":[1,9],"end":[1,11]}})
        );
        assert_eq!(spans[3]["span"], spans[1]["span"]);
        assert_eq!(spans[5]["span"], spans[1]["span"]);
    }

    #[test]
    fn stage_a_call_is_whole_grouped_expression() {
        diagnostic(
            b"main = ((zap(missing)))",
            "stage-unsupported",
            (1, 8),
            (1, 24),
        );
        diagnostic(
            b"main = missing + zap()",
            "unbound-variable",
            (1, 8),
            (1, 15),
        );
        diagnostic(b"main = true + zap()", "operand-kind", (1, 8), (1, 12));
        diagnostic(
            b"main = zap(unknown())",
            "stage-unsupported",
            (1, 8),
            (1, 22),
        );
    }

    #[test]
    fn stage_a_declaration_phase_and_full_syntax() {
        diagnostic(
            b"def f(x: Bool): Int = missing end main = nope",
            "stage-unsupported",
            (1, 1),
            (1, 34),
        );
        diagnostic(
            b"input x: Bool; def f(): Int = 0 end main = 1",
            "input-type",
            (1, 10),
            (1, 14),
        );
        diagnostic(
            b"input x: Int; input x: Bool; main = 1",
            "duplicate-input",
            (1, 21),
            (1, 22),
        );
        diagnostic(
            b"def f(): Int = 0 end main = [1,]",
            "syntax",
            (1, 32),
            (1, 33),
        );
    }

    #[test]
    fn unreachable_branches_are_checked_in_order() {
        diagnostic(
            b"main = if true then 1 else missing end",
            "unbound-variable",
            (1, 28),
            (1, 35),
        );
        diagnostic(
            b"main = if 1 then zap() else 0 end",
            "condition-kind",
            (1, 11),
            (1, 12),
        );
        diagnostic(
            b"main = if false then [] else true end",
            "branch-kind",
            (1, 30),
            (1, 34),
        );
        diagnostic(b"main = [false | zap()]", "head-kind", (1, 9), (1, 14));
    }

    #[test]
    fn match_binders_and_shadowing() {
        let value = dump("input h: ListInt; main = match h do [] -> 3; [h|t] -> h end");
        assert_eq!(
            value["main"]["head"],
            json!({"name":"h","binding":"main/head"})
        );
        assert_eq!(value["main"]["children"][2]["binding"], "main/head");
        assert_eq!(value["main"]["children"][0]["binding"], "input/0");
        let bad = parse(b"main = match [] do [] -> missing; [h|h] -> zap() end");
        assert!(
            matches!(bad,Err(CheckFailure::Refused(Diagnostic {class,..})) if class == "unbound-variable")
        );
    }

    #[test]
    fn encoding_does_not_override_an_earlier_syntax_error() {
        diagnostic(b"main = ) \xff", "syntax", (1, 8), (1, 9));
        let bad = match parse(b"main = 1\xff") {
            Ok(_) => panic!(),
            Err(e) => e,
        };
        assert_eq!(
            bad,
            CheckFailure::Refused(Diagnostic {
                class: "encoding".into(),
                span: Span::Bytes { start: 8, end: 9 }
            })
        );
    }

    #[test]
    fn scalar_columns_and_crlf_with_comments() {
        diagnostic(
            "# λ\r\n\tmain = x".as_bytes(),
            "unbound-variable",
            (2, 9),
            (2, 10),
        );
        let p = parse("# λ\r\nmain = -0".as_bytes()).unwrap();
        assert_eq!(
            serde_json::from_slice::<Json>(&p.dump()).unwrap()["main"]["value"],
            "0"
        );
    }

    #[test]
    fn invalid_lexical_and_numeral_forms() {
        for source in ["main = 01", "main = 0x3", "main = 2.5", "main = 8e2"] {
            assert!(
                matches!(parse(source.as_bytes()),Err(CheckFailure::Refused(Diagnostic {class,..})) if class == "numeral")
            );
        }
        for source in ["main = \"hi\"", "main = λ"] {
            assert!(
                matches!(parse(source.as_bytes()),Err(CheckFailure::Refused(Diagnostic {class,..})) if class == "lexical")
            );
        }
        assert!(parse(b"main = 1 < 2 < 3").is_err());
        assert!(parse(b"main = -(1)").is_err());
    }

    #[test]
    fn missing_token_uses_an_insertion_span() {
        diagnostic(b"main = (3", "syntax", (1, 10), (1, 10));
        diagnostic(b"", "syntax", (1, 1), (1, 1));
        diagnostic(b"main", "syntax", (1, 5), (1, 5));
        diagnostic(b"main =", "syntax", (1, 7), (1, 7));
        diagnostic(b"input x: Int", "syntax", (1, 13), (1, 13));
        diagnostic(b"main = [5", "syntax", (1, 10), (1, 10));
        diagnostic(b"main = f(5", "syntax", (1, 11), (1, 11));
        diagnostic(b"main = if true", "syntax", (1, 15), (1, 15));
        diagnostic(b"main = (5\r\n\t", "syntax", (2, 2), (2, 2));
    }

    #[test]
    fn expected_delimiter_mismatch_covers_the_present_token() {
        // Half-open columns counted from these source strings, independently
        // of lexer/parser output. Missing punctuation does not erase a token
        // that is actually present at the failed expectation.
        for (source, start, end) in [
            ("main = (5 nope)", 11, 15),
            ("main = (5 -> 6)", 11, 13),
            ("main = [5 )", 11, 12),
            ("main = f(5 ]", 12, 13),
            ("input x Int; main = 0", 9, 12),
            ("input x: Int main = x", 14, 18),
            ("def f(x Int): Int = 0 end main = 0", 9, 12),
            ("main then 7", 6, 10),
            ("main = if true false else 0 end", 16, 21),
            ("main = match [] then [] -> 0; [h|t] -> h end", 17, 21),
        ] {
            diagnostic(source.as_bytes(), "syntax", (1, start), (1, end));
        }
        diagnostic(
            "# λ\r\n\tmain = (5 nope)".as_bytes(),
            "syntax",
            (2, 12),
            (2, 16),
        );
    }

    #[test]
    fn expectation_errors_keep_classification_and_earliest_source_priority() {
        for source in [
            &b"main = (5 nope) \xff"[..],
            &b"main = (5 nope) @"[..],
            &b"main = (5 nope) 03"[..],
        ] {
            diagnostic(source, "syntax", (1, 11), (1, 15));
        }
        diagnostic(b"main = (5 03) nope", "numeral", (1, 11), (1, 13));
        diagnostic("main = (5 λ) nope".as_bytes(), "lexical", (1, 11), (1, 12));
        assert!(matches!(
            parse(b"main = (5 \xff) nope"),
            Err(CheckFailure::Refused(Diagnostic {
                class,
                span: Span::Bytes { start: 10, end: 11 },
            })) if class == "encoding"
        ));
    }

    #[test]
    fn denied_numeric_buffer_is_not_a_source_refusal() {
        let mut calls = 0;
        let result = check(b"main = 987654321987654321", &mut |_, _| {
            calls += 1;
            Err(CheckFailure::Failed {
                class: "resource-exhausted".into(),
                domain: Some(Resource::Number),
            })
        });
        assert_eq!(calls, 1);
        assert!(matches!(
            result,
            Err(CheckFailure::Failed {
                domain: Some(Resource::Number),
                ..
            })
        ));
    }
}
