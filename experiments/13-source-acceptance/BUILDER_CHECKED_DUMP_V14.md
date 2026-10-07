# Checked-program JSON field contract — public supplement v14

This supplies the exact field names omitted from the v13 public handoff. It
documents the unchanged checked-program contract; it changes no grammar, type
rule, prediction or acceptance check. Both delivered v13 archives remain history.
This supplement is requirements text, not acceptance code or case output.

`Candidate::checked_dump` returns one UTF-8 JSON object. The discriminant key is
**`node`**, not `tag` or `kind`. Its string value is exactly the spelling in the
table. Every object has **exactly** its listed keys: do not add fields or use null
placeholders for omitted fields. Object key order is immaterial for this checked
dump; array order is significant. Duplicate keys are forbidden. The separately
specified public outcome format still requires its fixed key order and LF line.

| Object / `node` value | Complete key set | Field meaning / child order |
| --- | --- | --- |
| `Program` | `node`, `inputs`, `functions`, `main` | `inputs` and `functions` are declaration arrays in source order; `main` is one expression object. **No `path` or `type`.** |
| Input or parameter declaration (no `node`) | `name`, `type`, `binding` | Name, declared type string, static declaration path. **No `node`, `path`, `children` or `value`.** |
| Function declaration (no `node`) | `name`, `function`, `parameters`, `result`, `body` | Function name, static function path, ordered parameter declarations, declared result type string, expression body. **No `node`, `path`, `type` or `binding`.** |
| `Int` | `node`, `path`, `type`, `value` | `type` is `Int`; `value` is a canonical decimal **string**. No `children`. |
| `Bool` | `node`, `path`, `type`, `value` | `type` is `Bool`; `value` is a JSON **Boolean**. No `children`. |
| `Nil` | `node`, `path`, `type` | `type` is `ListInt`. **No `children` or `value`.** |
| `Var` | `node`, `path`, `type`, `name`, `binding` | Resolved variable name and declaration path; `type` is its checked kind. **No `children` or `value`.** |
| `Add`, `Sub` | `node`, `path`, `type`, `children` | `type` is `Int`; exactly two children, left then right. |
| `Eq`, `Lt`, `Le` | `node`, `path`, `type`, `children` | `type` is `Bool`; exactly two children, left then right. |
| `Cons` | `node`, `path`, `type`, `children` | `type` is `ListInt`; exactly two children, head then tail. |
| `If` | `node`, `path`, `type`, `children` | Exactly three children: condition, then branch, else branch. `type` is the common branch kind. |
| `Let` | `node`, `path`, `type`, `name`, `binding`, `children` | Introduced name and declaration path; exactly two children, initializer then body. `type` is the body's kind. |
| `Match` | `node`, `path`, `type`, `head`, `tail`, `children` | `head` and `tail` are binder objects below. Exactly three children: scrutinee, empty branch, nonempty branch. `type` is the common branch kind. |
| Match binder object (no `node`) | `name`, `binding` | Binder name and declaration path. **No `node`, `path` or `type`**, even though head is statically Int and tail ListInt. |
| `Call` | `node`, `path`, `type`, `name`, `function`, `children` | Resolved function name/path; children are all explicit arguments in source order, including `[]` for zero arguments. `type` is the declared result kind. |

All compound-node `children` entries are expression objects, not values or paths;
compound nodes have no `value` key. All expressions have `node`, `path`, `type`.
Only Int/Bool expressions have `value`; only compound expressions have `children`.
`inputs`, `functions`, `parameters` and `children` remain arrays when empty, not
objects, strings or null. Type/result strings are `Int`, `Bool` or `ListInt`,
subject to the existing input-type restriction. Names and paths are strings.

Static paths retain the existing scheme: `input/i`, `function/i`,
`function/i/parameter/j`, `main`, `function/i/body`, child suffix `/j`,
let suffix `/binding`, match suffix `/head` or `/tail`. `Var.binding` points to
the resolved declaration; `Call.function` points to the resolved function.
These are static source identities, not runtime birth/lifetime numbers. List
literals are expanded into Cons/Nil expression objects; original source ranges
remain in the separate `source_spans` result, not extra checked-dump keys.
