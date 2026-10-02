#!/usr/bin/env python3
"""Claim inventory for "Born on Schedule": each claim the evidence limits, with the
forms it may NOT take and why. A claim that changes is edited HERE first and the
documents are brought to it. Reads the four manuscript sources, the generated
table notes and the highlights. Exit 1 on any hit.
Usage: claims.py [ROOT]   (ROOT = repository root; default: the HealthEcon repo)"""
import re, sys, glob, os
from pathlib import Path
ROOT = sys.argv[1] if len(sys.argv) > 1 else str(Path(__file__).resolve().parents[2])
DOCS = [os.path.join(ROOT, "latex", f) for f in ("paper.tex", "appendix.tex", "model.tex", "sup_appendix.tex", "highlights.txt")]
DOCS += sorted(glob.glob(os.path.join(ROOT, "analysis", "output", "tables", "*.tex")))
CLAIMS = [
 dict(name="Eq. (3) is a differential", why="never a difference-in-differences (CLAUDE.md taxonomy)",
      bad=r"difference-in-differences?\b|\bdiff-in-diff"),
 dict(name="the date is chosen", why="the observed delivery date is partly chosen; never as good as random (only in the negated form)",
      bad=r"(?<!an )(?<!than as )\bas[- ]good[- ]as[- ]random\b(?![- ]weekend assignment)"),
 dict(name="fee regressions are not an equivalence result", why="intervals do not fit the negligible region",
      bad=r"fees? (do not|don't) matter|\bno relationship between\b|small in every specification|\bstays small\b|coefficient is small and changes|consistent with (the|that) calibration"),
 dict(name="beds and scale", why="corr 0.48; too little variation within municipality-days, not collinearity",
      bad=r"too collinear|(?<!not )\bcollinear to separate"),
 dict(name="Robson 10 / preterm", why="corroboration, not a placebo; preterm is not unschedulable",
      bad=r"cannot be (freely )?scheduled|cannot be booked|whose date is not (open|chosen)"),
 dict(name="demand smoothing", why="an absence of levelling, never a lumpier flow",
      bad=r"(?<!evidence that )\bscheduling makes the flow lumpier|lumpiest flow"),
 dict(name="naming", why="for-profit (SINASC) vs private-insurance sector (TISS); never 'private for-profit'",
      bad=r"private for-profit"),
 dict(name="WHO benchmark", why="no 10-15 percent reference range",
      bad=r"10\s*(--|-|to)\s*15\s*(\\%|%|percent)"),
 dict(name="Robson group 1 timing", why="1.3 of the 6.0 points are uncoded and may include prelabor cesareans",
      bad=r"cesareans are intrapartum by construction|therefore has no prelabor component"),
 dict(name="the neonatal check is null", why="early-term coefficients are not distinguishable from zero",
      bad=r"corroboration of the early-term margin|suggestive, and statistically weak"),
 dict(name="Kitagawa is accounting", why="within the same Robson group, not the same women or identical groups",
      bad=r"the same women managed|identical clinical groups"),
 dict(name="the price of time and the common gradient", why="the common gradient is read as organizational; the price of time speaks to the for-profit increment only",
      bad=r"price of time leaves its mark|price of the physician's time can\b|the convenience is associated|convenience is also associated"),
 dict(name="the model does not imply a small fee response", why="Appendix A, P1: f(theta*) must be near zero; the conclusion rests on the calibration",
      bad=r"model also explains why levers|act on a margin the fee data suggest is not operative"),
 dict(name="the fee response is not established as small", why="Section 5: the regressions do not establish that the response is small",
      bad=r"the small relative-fee response"),
 dict(name="units of the event-time sum", why="a sum of three per-municipality-day coefficients is per municipality over the window",
      bad=r"-?0\.47\$? prelabor cesareans per municipality-day"),
 dict(name="calendar fingerprints", why="the physician-leisure predictions are not confirmed, so not 'every fingerprint'",
      bad=r"every fingerprint"),
 dict(name="who attracts which citation", why="Clemens-Gottlieb find LARGE fee responses; Alexander finds no change in procedure use given patient health",
      bad=r"documented magnitude is too small to matter here\s*\\citep\{clemens2014|alexander2020\}\s*shows that paying physicians\s+to economize can move treatment"),
 dict(name="the court order is not evidence", why="it never became a rule",
      bad=r"court order[^.]{0,60}(changed nothing|produced no movement)"),
 dict(name="SUS continuity", why="cite domingues2014; never the uncited 'whoever is on duty'",
      bad=r"whoever is on duty"),
 dict(name="read as organizational", why="'which we read as organizational', never 'is organizational'",
      bad=r"\bgradient is organizational\b"),
 dict(name="within-establishment share", why="0.95/1.79 with birth weights, 1.26/1.79 with fixed weights: 'half or more', never 'about half' with 'the other half'",
      bad=r"\babout half of the (headline|weekend) differential|\bthe other half is (the )?reallocation"),
 dict(name="naming the birth establishment", why="prose says hospital, tables say establishment; 'maternities' reads as a calque of 'maternidades'",
      bad=r"\bmaternities\b|\bmaternity(-years?|'s)|\ba maternity (that|delivered)\b"),
 dict(name="language", why="calques and 'insignificant'",
      bad=r"\binsignificant\b|\bdiary\b|charged/informed"),
]
bad = 0
for doc in DOCS:
    if not os.path.exists(doc): continue
    s = re.sub(r'(?m)^\s*%.*$', '', open(doc).read())
    s = re.sub(r'\\(label|input|includegraphics|ref|eqref|satab|safig)\*?(\[[^\]]*\])?\{[^}]*\}', ' ', s)
    s = ' '.join(s.split())
    for c in CLAIMS:
        for m in re.finditer(c['bad'], s, re.I):
            print(f'  {os.path.basename(doc)}: {c["name"]} -- {c["why"]}\n      "...{s[max(0,m.start()-60):m.end()+40]}..."')
            bad += 1
print('claims stated in a form the evidence does not license: %d' % bad)
sys.exit(1 if bad else 0)
