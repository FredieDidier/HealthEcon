#!/usr/bin/env python3
"""Word count of the abstract against the journal's cap (JHE: 250).

Markup is replaced by a SPACE, never deleted (deleting joins the words on either
side), and the delimiters are matched as markup, never as a substring of a line
(a filter on "end" would also drop "depend", "trend", "calendar").
Usage: abstract.py [paper.tex] [cap]"""
import re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
p = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / "latex" / "paper.tex")
CAP = int(sys.argv[2]) if len(sys.argv) > 2 else 250
m = re.search(r'\\begin\{abstract\}(.*?)\\end\{abstract\}', open(p).read(), re.S)
if not m:
    print('abstract not found in ' + p); sys.exit(1)
t = re.sub(r'(?m)^\s*%.*$', ' ', m.group(1))
t = re.sub(r'\\[a-zA-Z]+\*?(\[[^\]]*\])?\{?|[{}$\\~]', ' ', t)
n = len(t.split())
print('abstract words %d of %d' % (n, CAP))
sys.exit(0 if n <= CAP else 1)
