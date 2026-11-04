#!/usr/bin/env python3
"""What a reader outside the subfield stops on, in the forms a machine can see.

A paragraph that opens by announcing an exhibit, a section cited in the
conclusion, "equation" set lower case beside capitalized Table and Figure, and
words that drew a question from that reader. The diagnosis behind each is in the
applied-micro-paper-writing skill; this file only holds the forms that recur.
WCH_LATEX points the check at a copy of the latex directory.
"""
import glob
import os
import re
import sys

LATEX = os.environ.get(
    "WCH_LATEX",
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "latex"))
# An exhibit opening a paragraph as its agent, with a verb that only announces it.
# A sentence saying how to read the exhibit stays.
ANNOUNCE = re.compile(
    r"^(Tables?|Figures?|Panels?)[~ ]\S*(?:\s+[^.]{0,60}?)?\s*\b"
    r"(reports? (?:the|our)|collects?|turns? to|shows? which|shows? where|estimates)\b")
WORDS = ["administrative universes", "from below", "discipline the magnitude", "discipline that magnitude", "non-price margin", "potentially"]


def read(name):
    return re.sub(r"(?m)(?<!\\)%.*$", "", open(os.path.join(LATEX, name)).read())


bad = []
paper = read("paper.tex")
body = paper[paper.index("\\begin{document}"):]
for name, text in (("paper", body), ("supplement", read("sup_appendix.tex"))):
    flat = re.sub(r"\s+", " ", text)
    for m in re.finditer(r"\bequations?\s*~?\(?\\(eq)?ref|\bequation \(\d", flat):
        bad.append(f"{name}: lower-case equation: ...{flat[m.start():m.end()+20]}")
for f in sorted(glob.glob(os.path.join(LATEX, "..", "analysis", "output", "tables", "*.tex"))):
    t = open(f).read()
    if re.search(r"\bequations?(~|\s*\()", t):
        bad.append(f"{os.path.basename(f)}: lower-case equation in the note")
    if re.search(r"(?<![$\\\w])p\$<\$", t):
        bad.append(f"{os.path.basename(f)}: roman p in the note")
for para in re.split(r"\n\s*\n", body):
    flat = re.sub(r"\s+", " ", para).strip()
    if ANNOUNCE.match(flat):
        bad.append(f"paper: paragraph announces an exhibit: {flat[:80]}")
m = re.search(r"\\section\{Conclusion\}(.*?)\\section\*", body, re.S)
if not m:
    bad.append("paper: conclusion not found")
elif re.search(r"Section~?\s*\\ref", m.group(1)):
    bad.append("paper: the conclusion cites a section")
flat = re.sub(r"\s+", " ", body)
for w in WORDS:
    if w in flat:
        bad.append(f"paper: '{w}'")
for b in bad:
    print("  " + b)
print(f"reader: {len(bad)} finding(s)")
sys.exit(1 if bad else 0)
