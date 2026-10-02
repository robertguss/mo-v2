from run import ROOT, E, PROJECT, run
import re, json, hashlib, subprocess, pathlib, collections

repo = pathlib.Path('/home/user/workspace/repo')
base = '787e0427244837fd0f44b76c4a648d07938c3bcc'
tip = 'baf1d52649bc7a50ff7df19d0368d182efdb3fbd'
prefix = 'experiments/03c-checker/trial/lean/'
paths = subprocess.check_output(['git', 'diff', '--name-only', base, tip], cwd=repo, text=True).splitlines()
assert all(p == prefix + 'Proofs.lean' or p.startswith(prefix + 'Proofs/') for p in paths)
assert len(paths) == 59

def uncomment(text):
    # Preserve line positions while removing nested Lean block/line comments and strings.
    out = list(text)
    i = depth = 0
    string = False
    while i < len(text):
        if depth:
            if text.startswith('/-', i):
                out[i:i+2] = '  '; depth += 1; i += 2
            elif text.startswith('-/', i):
                out[i:i+2] = '  '; depth -= 1; i += 2
            else:
                if text[i] != '\n': out[i] = ' '
                i += 1
        elif string:
            if text[i] == '\\' and i + 1 < len(text):
                out[i:i+2] = '  '; i += 2
            else:
                if text[i] == '"': string = False
                if text[i] != '\n': out[i] = ' '
                i += 1
        elif text.startswith('/-', i):
            out[i:i+2] = '  '; depth = 1; i += 2
        elif text.startswith('--', i):
            j = text.find('\n', i)
            if j == -1: j = len(text)
            out[i:j] = ' ' * (j-i); i = j
        elif text[i] == '"':
            out[i] = ' '; string = True; i += 1
        else:
            i += 1
    assert not depth and not string
    return ''.join(out)

banned = r'\b(sorry|admit|axiom|partial|unsafe|opaque|native_decide|implemented_by|extern|csimp|notation|macro|macro_rules|syntax|elab|infix|prefix|postfix|attribute|export|renaming|set_option|initialize|builtin_initialize|run_elab|run_tac)\b|debug\.skipKernelTC'
inventory = []
heads = collections.Counter()
for p in paths:
    file = repo / p
    text = file.read_text()
    code = uncomment(text)
    hits = [(code.count('\n', 0, m.start())+1, m.group()) for m in re.finditer(banned, code)]
    assert not hits, (p, hits)
    assert '#eval' not in code and '#reduce' not in code and '#check' not in code
    assert re.search(r'\b_root_\.', code) is None
    commands = []
    for n, line in enumerate(code.splitlines(), 1):
        if line.strip():
            heads[line.strip().split()[0]] += 1
        if line and not line[0].isspace():
            commands.append([n, line])
    inventory.append(dict(file=p, sha256=hashlib.sha256(file.read_bytes()).hexdigest(),
                          lines=len(text.splitlines()), banned_executable_hits=hits, commands=commands))
(E / 'source-inventory.json').write_text(json.dumps(inventory, indent=2) + '\n')
(E / 'source-line-heads.json').write_text(json.dumps(heads, indent=2) + '\n')
tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=repo).decode().split('\0')[:-1]
assert all((repo / p).read_bytes() == (ROOT / 'reconstructed' / p).read_bytes() for p in tracked)
locks = dict(re.findall(r'^\| `([^`]+)`\s*\| `([a-f0-9]{64})`', (PROJECT.parent / 'LOCK.md').read_text(), re.M))
assert all(hashlib.sha256((repo / prefix / '..' / p).read_bytes()).hexdigest() == h for p, h in locks.items())
print('59 changed proof files; all executable banned-token scans empty; all tracked reconstructed bytes match candidate; 25 candidate hashes match.')
print('Line-head tokens: ' + repr(heads))
for row in inventory:
    print(row['file'].removeprefix(prefix), ':', len(row['commands']), 'top-level lines;', row['lines'], 'total lines')
run('final-head', ['git', 'rev-parse', 'HEAD'], repo)
run('final-status', ['git', 'status', '--porcelain=v1', '--untracked-files=all'], repo)
run('final-ignored', ['git', 'ls-files', '--others', '--ignored', '--exclude-standard'], repo)
