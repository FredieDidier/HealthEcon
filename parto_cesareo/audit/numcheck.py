#!/usr/bin/env python3
"""Numbers against exhibits, per manuscript-audit section 0.
  A) each paragraph's numbers against ONLY the exhibits that paragraph cites;
  B) numbers that match no exhibit at all (orphans: printed for reading).
A prose figure matches when a table figure, or that figure x 100 (shares quoted
as percentage points), rounds to it at the prose's own precision, sign ignored
("falls by 1.8" quotes -1.789). A sentence carrying a citation is skipped: its
numbers belong to the cited work. Exit 1 on any A item not in ALLOW_A or B item not in ALLOW_B.
Usage: numcheck.py [latex_dir] [tables_dir]"""
import re, os, glob, sys
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
TEX = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / "latex")
TABD = sys.argv[2] if len(sys.argv) > 2 else str(ROOT / "analysis" / "output" / "tables")
NUM = re.compile(r'(?<![\w.])(\d{1,3}(?:,\d{3})+|\d+\.\d+)(?![\w])')

# Numbers no cited exhibit prints, each with the reason it may stand. An entry
# without a reason is a suppression.
ALLOW_A = {
    ("paper.tex", "1.8"): "derived: 7.05 - 5.27 on the identifying days (Table D, ident sample); "
                          "and the Eq. (3) differential quoted in the 35k footnote",
    ("paper.tex", "4.5"): "console: deliveries with no physician fee billed to the plan (01 block)",
    ("paper.tex", "8.9"): "Figure 3(c) value (analysis/output/robson_grad.rds)",
    ("paper.tex", "3.0"): "Figure 3(c) value (robson_grad.rds)",
    ("paper.tex", "3.3"): "Figure 3(c) value (robson_grad.rds)",
    ("paper.tex", "5.8"): "Figure 3(c) value (robson_grad.rds)",
    ("paper.tex", "5.3"): "Figure 3(c) value (robson_grad.rds)",
    ("paper.tex", "7.9"): "Table 2 Panel B weekend gradient, quoted in the 35k footnote",
    ("appendix.tex", "1,000"): "a unit (per 1,000 births), not an estimate",
    ("sup_appendix.tex", "0.16"): "standard error of the demand-smoothing Panel B coefficient, "
                                  "the table named in the previous paragraph",
}

# Numbers that match no exhibit at all, each with its reason. A stale number that
# matches nothing is otherwise only printed, so an unlisted orphan fails the check.
ALLOW_B = {
    ("appendix.tex", "14,759"): "Law 14,759 of 2023 (20 November holiday)",
    ("paper.tex", "1,940"): "the cesarean fee R$1,939 of Table D.19, rounded in prose",
    ("paper.tex", "35,000"): "console: excess weekday cesareans, own-municipality-year benchmark (35,330)",
    ("paper.tex", "37,000"): "derived: 7.9 pp x 463,000 weekday births (footnote)",
    ("paper.tex", "380,000"): "console: for-profit weekday cesareans per year",
    ("paper.tex", "463,000"): "console: for-profit weekday births per year",
    ("paper.tex", "95.5"): "derived: 100 - 4.5 percent of deliveries without a physician fee",
}

def parse(t):
    out = []
    for m in NUM.finditer(t):
        try:
            v = Decimal(m.group(1).replace(',', '')); out += [v, v * 100]
        except Exception: pass
    return out

def rounds_to(v, target):
    q = Decimal(1).scaleb(-(len(str(target).split('.')[1]) if '.' in str(target) else 0))
    try: return abs(v).quantize(q, rounding=ROUND_HALF_UP) == target
    except Exception: return False

cache = {}
def hay(f):
    if f not in cache: cache[f] = parse(open(f).read())
    return cache[f]

FILES = sorted(glob.glob(os.path.join(TABD, "*.tex")))
LAB = {}
for f in FILES:
    for m in re.finditer(r'\\label\{([^}]*)\}', open(f).read()): LAB[m.group(1)] = f
ALLNUM = [v for f in FILES for v in hay(f)]
present = lambda t, vals: any(rounds_to(v, t) for v in vals)

def paras(p):
    s = re.sub(r'(?m)^\s*%.*$', '', open(p).read())
    return re.split(r'\n\s*\n', s)

A, B, EXT = [], [], []
for doc in ["paper.tex", "appendix.tex", "model.tex", "sup_appendix.tex"]:
    for q in paras(os.path.join(TEX, doc)):
        if '\\usepackage' in q: continue
        labs = re.findall(r'\\(?:satab|safig|ref|eqref)\*?\{([^}]*)\}', q)
        files = {LAB[l] for l in labs if l in LAB}
        cited = [v for f in files for v in hay(f)]
        for sent in re.split(r'(?<=[.!?])\s+(?=[A-Z\\$])', q):
            external = re.search(r'\\cite[a-z]*\*?[\[{]', sent) is not None
            txt = re.sub(r'\\(?:label|ref|eqref|satab|safig|cite[a-z]*|input|includegraphics)\*?(\[[^\]]*\])?\{[^}]*\}', ' ', sent)
            for m in NUM.finditer(txt):
                raw = m.group(1)
                try: t = Decimal(raw.replace(',', ''))
                except Exception: continue
                ctx = re.sub(r'\s+', ' ', txt[max(0, m.start()-70):m.start()+40])
                if external: EXT.append((doc, raw, ctx)); continue
                if not present(t, ALLNUM):
                    if (doc, raw) not in ALLOW_B: B.append((doc, raw, ctx))
                elif files and not present(t, cited) and (doc, raw) not in ALLOW_A:
                    A.append((doc, raw, sorted(os.path.basename(f) for f in files), ctx))

print("=== A. number absent from the exhibits its own paragraph cites: %d ===" % len(A))
for x in A: print("  %-16s %-8s %s\n     ...%s..." % (x[0], x[1], x[2], x[3]))
print("\n=== B. orphans, matching no exhibit and not allowed: %d ===" % len(set(B)))
for x in sorted(set(B)): print("  %-16s %-8s ...%s..." % x)
print("\n(%d + %d allowed exceptions with reasons; %d numbers in sentences citing outside work skipped)"
      % (len(ALLOW_A), len(ALLOW_B), len(set(EXT))))
print("numbers absent from the exhibit their own paragraph cites: %d | unlisted orphans: %d" % (len(A), len(set(B))))
sys.exit(1 if (A or B) else 0)
