# Manuscript checks (added 2026-10-02)

Each check exists because reading missed something and the defect was found
another way (see `REVISION_LOG.md`, 2026-10-02). They need no data: they read
the `.tex` sources in `latex/` and the generated tables in
`analysis/output/tables/`. Run from anywhere:

```bash
python3 parto_cesareo/audit/abstract.py
python3 parto_cesareo/audit/claims.py
python3 parto_cesareo/audit/numcheck.py
python3 parto_cesareo/audit/sweep.py --v
```

| check | what it asks | exit |
|---|---|---|
| `abstract.py` | the abstract against the JHE cap of 250 words (markup replaced by a space, delimiters matched as markup) | 1 over the cap |
| `claims.py` | the claim inventory: each claim the evidence limits, the wording it may not take and why (taxonomy of `CLAUDE.md` plus the 2026-10-02 findings). A claim that changes is edited here first | 1 on any hit |
| `numcheck.py` | every decimal or thousands number in a paragraph against the tables that paragraph cites (x100 and sign-free, matched by rounding at the prose's precision), and every number against all tables for orphans. Exceptions are listed with their reason | 1 on any unlisted mismatch or orphan |
| `sweep.py` | prose counters: sentence-length distribution, sentences long AND chained, pseudo-clefts, repeated openers, short and numeric paragraph openings, `rather than`, British spellings. Counts only; read the diff for the rest | always 0 |

Probed on 2026-10-02: each of 16 banned claim forms injected into a copy makes
`claims.py` exit 1; an orphan number (`-1.24` changed to `-1.34`) makes
`numcheck.py` exit 1; four words over the cap make `abstract.py` exit 1.

Known limit of `numcheck.py`: a paragraph that cites no table (only an equation,
or nothing) is checked only for orphans, so a wrong number that happens to equal
some cell of some table passes. The fix is the cross-reference: name the table in
the paragraph that quotes it.

Take each check's exit status directly (`python3 x.py; echo $?`), never through a
pipe: `| tail` returns the status of `tail`.
