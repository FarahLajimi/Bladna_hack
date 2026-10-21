"""Lightweight static checks for a Dart project when no Dart SDK is available.

Not a compiler. Catches: unresolved relative/package imports, unbalanced
brackets, project symbols used without importing their file, unknown static
members on project classes, duplicate ids, and unused relative imports.
"""
import os
import re
import sys

ROOT = sys.argv[1]
PKG = sys.argv[2] if len(sys.argv) > 2 else 'bladna'
LIB = os.path.join(ROOT, 'lib')


def strip(src):
    """Return code with strings and comments blanked (keeps interpolation code)."""
    out = []
    i, n = 0, len(src)
    stack = []  # string contexts for interpolation
    def code_char(c):
        out.append(c)
    while i < n:
        c = src[i]
        if src.startswith('//', i):
            j = src.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i)); i = j; continue
        if src.startswith('/*', i):
            j = src.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r'[^\n]', ' ', src[i:j])); i = j; continue
        if c in '\'"':
            raw = i > 0 and src[i - 1] == 'r' and (i < 2 or not (src[i-2].isalnum() or src[i-2]=='_'))
            triple = src[i:i + 3] in ("'''", '"""')
            q = src[i:i + 3] if triple else c
            out.append('"'); i += len(q)
            # scan string body
            while i < n:
                if not raw and src[i] == '\\':
                    out.append('  '); i += 2; continue
                if src.startswith(q, i):
                    out.append('"' + ' ' * (len(q) - 1)); i += len(q); break
                if not raw and src.startswith('${', i):
                    # interpolation: copy code until matching brace
                    depth = 0; out.append('  '); i += 2; depth = 1
                    start = i
                    # recursive handling: find matching brace accounting nested strings
                    j = i
                    while j < n and depth:
                        ch = src[j]
                        if ch in '\'"':
                            # skip nested string simply
                            qq = ch; j += 1
                            while j < n and src[j] != qq:
                                j += 2 if src[j] == '\\' else 1
                            j += 1; continue
                        if ch == '{': depth += 1
                        elif ch == '}': depth -= 1
                        j += 1
                    inner = src[start:j - 1]
                    out.append(strip(inner).replace('\n', ' '))
                    out.append(' ')
                    i = j; continue
                out.append(' ' if src[i] != '\n' else '\n'); i += 1
            continue
        out.append(c); i += 1
    return ''.join(out)


files = {}
for dp, _, fns in os.walk(ROOT):
    if '/.dart_tool' in dp or '/build' in dp:
        continue
    for fn in fns:
        if fn.endswith('.dart'):
            p = os.path.join(dp, fn)
            files[p] = open(p, encoding='utf-8').read()

errors = []

# 1. imports + 2. brackets
imports = {}
for p, src in files.items():
    imps = []
    for m in re.finditer(r"^import\s+'([^']+)'", src, re.M):
        u = m.group(1)
        if u.startswith('package:' + PKG + '/'):
            t = os.path.join(LIB, u[len('package:' + PKG + '/'):])
        elif u.startswith('package:') or u.startswith('dart:'):
            continue
        else:
            t = os.path.normpath(os.path.join(os.path.dirname(p), u))
        if not os.path.exists(t):
            errors.append(f'{p}: unresolved import {u}')
        imps.append(os.path.normpath(t))
    imports[p] = imps
    code = strip(src)
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    line = 1
    for ch in code:
        if ch == '\n':
            line += 1
        elif ch in '([{':
            st.append((ch, line))
        elif ch in ')]}':
            if not st or st[-1][0] != pairs[ch]:
                errors.append(f'{p}:{line}: unbalanced {ch}')
                break
            st.pop()
    else:
        if st:
            errors.append(f'{p}: unclosed {st[-1][0]} from line {st[-1][1]}')

# 3. top-level declarations in lib
decl_re = re.compile(r'^(?:abstract\s+|sealed\s+|final\s+|base\s+)*(?:class|enum|mixin|extension|typedef)\s+([A-Za-z_]\w*)', re.M)
top_var_re = re.compile(r'^(?:const|final)\s+(?:[\w<>,?\s()]+\s+)?([A-Za-z_]\w*)\s*=', re.M)
top_fn_re = re.compile(r'^(?:Future<[^>]+>|[A-Z]\w*(?:<[^>]*>)?\??|void|bool|int|double|String)\s+([a-z_]\w*)\s*\(', re.M)
defined = {}
for p, src in files.items():
    if not p.startswith(LIB):
        continue
    code = strip(src)
    names = set(decl_re.findall(code)) | set(top_var_re.findall(code)) | set(top_fn_re.findall(code))
    for nm in names:
        if nm.startswith('_'):
            continue
        defined.setdefault(nm, set()).add(os.path.normpath(p))

for nm, where in defined.items():
    if len(where) > 1:
        errors.append(f'duplicate top-level {nm}: {sorted(where)}')

ident = re.compile(r'(?<![\w.$])([A-Za-z_]\w*)')
for p, src in files.items():
    code = strip(src)
    body = re.sub(r"^(import|export|part)\s.*$", '', code, flags=re.M)
    used = set(ident.findall(body))
    mine = os.path.normpath(p)
    for nm in used:
        if nm in defined and mine not in defined[nm]:
            if not any(t in defined[nm] for t in imports[p]):
                errors.append(f'{p}: uses {nm} without importing {sorted(defined[nm])[0]}')
    # unused relative imports
    for t in imports[p]:
        if not t.startswith(LIB):
            continue
        exported = {nm for nm, w in defined.items() if t in w}
        if exported and not (exported & used):
            errors.append(f'{p}: possibly unused import {os.path.relpath(t, LIB)}')

# 4. static member typos on project classes
class_bodies = {}
for p, src in files.items():
    code = strip(src)
    for m in re.finditer(r'(?:class|enum)\s+([A-Z]\w*)[^{;]*\{', code):
        name = m.group(1)
        start = m.end(); depth = 1; j = start
        while j < len(code) and depth:
            if code[j] == '{': depth += 1
            elif code[j] == '}': depth -= 1
            j += 1
        class_bodies.setdefault(name, '')
        class_bodies[name] += code[start:j]

def members(name):
    b = class_bodies.get(name, '')
    found = set(re.findall(r'static\s+(?:const|final)?\s*(?:[\w<>,?\s()]+\s+)?([a-zA-Z_]\w*)\s*(?:=|\(|=>|;)', b))
    found |= set(re.findall(r'static\s+[\w<>,?\s()]*?\s(?:get\s+)?([a-zA-Z_]\w*)\s*(?:\(|=>|\{)', b))
    return found

def enum_values(name):
    b = class_bodies.get(name, '')
    m = re.split(r';', b, maxsplit=1)[0]
    return set(re.findall(r'(?:^|,)\s*([a-z]\w*)\s*(?=\(|,|\}|\s*$)', m, re.S))

project_classes = [c for c in class_bodies if c in defined]
enums = set()
for p, src in files.items():
    enums |= set(re.findall(r'^enum\s+(\w+)', strip(src), re.M))

for p, src in files.items():
    code = strip(src)
    for m in re.finditer(r'(?<![\w.])([A-Z]\w*)\.([a-zA-Z_]\w*)', code):
        cls, mem = m.groups()
        if cls not in project_classes:
            continue
        if cls in enums:
            vals = enum_values(cls) | members(cls) | {'values', 'fromId'}
            if mem not in vals:
                line = code[:m.start()].count('\n') + 1
                errors.append(f'{p}:{line}: {cls}.{mem} is not a known enum value/static')
            continue
        st = members(cls)
        # named constructors
        ctors = set(re.findall(r'\b' + cls + r'\.(\w+)\s*\(', class_bodies.get(cls, '')))
        if st or ctors:
            if mem not in st and mem not in ctors:
                line = code[:m.start()].count('\n') + 1
                errors.append(f'{p}:{line}: {cls}.{mem} not found among statics {sorted(st)[:6]}...')

print('\n'.join(errors) if errors else 'OK: no issues found')
print(f'{len(files)} dart files checked')
