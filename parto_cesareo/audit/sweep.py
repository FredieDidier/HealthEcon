#!/usr/bin/env python3
"""Mechanical prose sweep over the manuscript sources (adapted from the
WorldCupHealth audit). Counts only; judgments are made by reading the diff.
Explicit paths win, so a baseline copy can be swept for comparison.
Usage: sweep.py [file.tex ...] [--v]"""
import re, sys, statistics, os
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2] / "latex"
FILES = ["paper.tex", "appendix.tex", "model.tex", "sup_appendix.tex"]
ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
if ARGS:
    ROOT, FILES = Path(""), ARGS

def body(p):
    s = open(p).read()
    if '\\begin{document}' in s: s = s.split('\\begin{document}', 1)[1]
    s = re.sub(r'(?m)^\s*%.*$', '', s)
    s = re.sub(r'\\input\{[^}]*\}', '', s)
    s = re.sub(r'\\(begin|end)\{[^}]*\}', '\n', s)
    s = re.sub(r'\\[a-zA-Z@]+\*?(\[[^\]]*\])?', ' ', s)
    s = re.sub(r'[{}$&~^_\\]', ' ', s)
    return s

def paras(s):
    return [re.sub(r'\s+', ' ', p).strip() for p in re.split(r'\n\s*\n', s)
            if len(re.sub(r'\s+', ' ', p).strip()) > 40]

def sents(p):
    return [x.strip() for x in re.split(r'(?<=[.!?])\s+(?=[A-Z0-9])', p) if x.strip()]

JOIN = re.compile(r';|,\s+(and|so|but|which|because|while)\b')
PSEUDO = re.compile(r'\b(What|Where|Why|How) (the|a|an|this|these|our|their|it|they|we)\b[^.]{0,70}\bis\b')
NUMWORD = r'(One|Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten|\d)'

for f in FILES:
    p = os.path.join(ROOT, f)
    if not os.path.exists(p): continue
    S = body(p); P = paras(S)
    allsent = [x for q in P for x in sents(q)]
    L = [len(x.split()) for x in allsent]
    short_open = [q for q in P if len(sents(q)[0].split()) <= 5]
    num_open = [q for q in P if re.match(r'^%s\b' % NUMWORD, q)]
    pseudo = [x for x in allsent if PSEUDO.search(x)]
    rep = []
    for q in P:
        ss = sents(q)
        for a, b in zip(ss, ss[1:]):
            wa, wb = a.split()[0], b.split()[0]
            if wa == wb and wa.lower() not in ('the','a','an','this','that','it','they','in','and','on'):
                rep.append((wa, a[:70], b[:70]))
    chained = [x for x in allsent if len(x.split()) > 45 and len(JOIN.findall(x)) >= 3]
    words = len(S.split())
    rt = len(re.findall(r'\brather than\b', S))
    brit = re.findall(r'\b(towards|cancelled|behaviour|theatre|per cent|whilst|organis|analyse\b|favour(?!ite)|labour|centre)\w*', S)
    print(f"== {f} ==  words {words}  sentences {len(allsent)}")
    print(f"   median {statistics.median(L)}  p90 {int(statistics.quantiles(L,n=10)[8])}  "
          f"p95 {int(statistics.quantiles(L,n=20)[18])}  >40w {sum(1 for x in L if x>40)}  >55w {sum(1 for x in L if x>55)}")
    print(f"   short paragraph openings {len(short_open)}   numeric openings {len(num_open)}")
    print(f"   pseudo-clefts {len(pseudo)}   repeated openers {len(rep)} {sorted(set(r[0] for r in rep))}")
    print(f"   long AND chained {len(chained)}")
    print(f"   'rather than' {rt}" + (f" = 1 per {words//rt}" if rt else ""))
    print(f"   british spellings {len(brit)} {sorted(set(brit))}")
    if '--v' in sys.argv:
        for x in chained: print("      CHAINED:", x[:150])
        for q in short_open: print("      SHORTOPEN:", sents(q)[0])
        for q in num_open: print("      NUMOPEN:", sents(q)[0][:90])
        for x in pseudo: print("      PSEUDO:", x[:120])
        for r in rep: print("      REPEAT:", r[0], "|", r[1], "||", r[2])
