# CLAUDE.md — HealthEcon Project Guide

## What the paper is

Empirical paper, *"Born on Schedule: Fees, Supply-Side Scheduling, and Cesarean
Delivery in Brazil."* It asks why Brazil's **for-profit maternity sector** runs
the highest cesarean rate documented for any large health system (~80% of
deliveries, vs a WHO reference of 10–15%), and answers by separating a **price
channel** (do relative fees drive it? no) from a **scheduling channel** (do
cesareans cluster on weekdays and dip on weekends and holidays? yes). Target
journal: **AEJ: Economic Policy** (fallback: Journal of Health Economics).

**The paper's one recognizable design is Equation (3)**, a
within-municipality-day for-profit-versus-public differential; everything else is
mechanism, magnitude, or robustness around it. This structure (set 2026-07-10)
followed a detailed referee report; see "The 2026-07-10 revision" below for what
changed and why.

**Authors (in order):** Fredie Didier (IDP; corresponding, fdidier@terra.com.br),
Pablo Castro (UFBA), Vinicius Mendes (UFBA), Lucas Emanuel (UFBA). Written in the
first person plural. No acknowledgments footnote (removed 2026-07-10).

## Evidence taxonomy (hold this labeling everywhere)

The paper is *structured descriptive and mechanism evidence organized around one
tightly controlled quasi-experimental contrast*. Per-result labels, which must
hold in abstract, intro, strategy section, table notes, and conclusion:

- **fee regressions** = conditional associations, sign-unstable. Say "no robust
  positive price relationship," never "fees don't matter."
- **weekend/holiday gradients** (Eq. 2) = calendar sorting of deliveries, NOT the
  causal effect of a random weekend. Never write "the day a birth falls is as
  good as random w.r.t. medical need" — the observed date is partly chosen.
- **Eq. (3), the within-municipality-day for-profit differential** = the central
  estimate; causal only under a common-gradient assumption
  (E[ΔY⁰|for-profit]=E[ΔY⁰|public] within a municipality-day). Call it a
  *differential*, never a difference-in-differences.
- **prelabor vs in-labor split** = mechanism evidence (the dip is concentrated in
  prelabor cesareans; in-labor moves the other way = displacement).
- **long-weekend taxonomy + displacement event study** = the sharper
  physician-leisure predictions are **not confirmed** (see below). Report the
  null honestly; it bounds the "whose convenience" claim.
- **organizational-capacity heterogeneity** = "organizational redundancy
  attenuates the gradient," NOT "individual physician's calendar vs hospital."
- **Kitagawa decomposition** = accounting; 72% practice style.
- **~50k excess weekday cesareans** = mechanical benchmark, not cesareans caused.
- **early-term +11.7pp** = sector–gestational-age association.
- **Parto Adequado** = failure of a causal *design* (pre-trends), not a program
  effect; lives entirely in the Supplemental Appendix, one paragraph in the body.

Standard scope sentence: *"The evidence identifies calendar sorting and a tightly
controlled for-profit–public differential; it does not identify the total number
of cesareans or neonatal outcomes caused by scheduling."*

## Naming: the two "private" populations (KEEP DISTINCT)

They overlap (~79–82%) but are not the same population, and SINASC has no payer
flag. Enforced in code via `sector_display()` / `SECTOR_DISPLAY` in
`analysis/code/00_utils.R`:

- **SINASC** → ownership of the birth **establishment** (natureza jurídica 2xxx).
  Call it **"for-profit"** (vs "nonprofit" 3xxx, "public" 1xxx). ~79% cesarean.
  The `sector` column keeps raw levels `Private/Nonprofit/Public/Other` because
  regressions subset on them; relabel only display/plot objects with
  `sector_display()`.
- **TISS** → claims financed by **private insurance**, private by construction.
  Call it the **"private-insurance sector"**. ~82% cesarean.

Never write bare "private" as the SINASC group name, and never "private
for-profit" (conflates payer and ownership). Headline contrast is **for-profit
(2xxx) vs public (1xxx)**; nonprofit (3xxx, SUS-heavy) shows in figures, excluded
from headline tests. Do NOT lump 3xxx into for-profit (inflates the share to
~56%).

**Natureza jurídica (`nat_jur`) → sector, by FIRST DIGIT** (built as explicit
establishment sets from the CNES beds file in `01b`/`01d`):

| first digit | IBGE/CONCLA group | sector |
|---|---|---|
| 1 | Administração Pública | **Public** |
| 2 | Entidades Empresariais | **Private** (for-profit) |
| 3 | Entidades sem Fins Lucrativos | **Nonprofit** |
| 4 (Pessoas Físicas), 5 (Org. Internacionais), or unmatched | — | **Other** (excluded) |

Priority for an establishment seen under several codes across competências:
for-profit > nonprofit > public. Establishments *with beds* only carry 1/2/3, so
4xxx/5xxx never appear; the real trap is the residual. **`Public` must be the
EXPLICIT 1xxx set, never the `else` bucket** — the pre-2026-07-11 code sent every
unmatched establishment to Public (~1.17M births, 6.4% of "Public"), which was a
labeling bug. Impact on numbers was negligible (Public cesarean 42.73%→42.74%,
because the unmatched behave like public/SUS facilities), but the corrected code
labels them `Other` and drops them from the Private-vs-Public headline. Do NOT
reintroduce `else → Public`.

## Core results

1. **The epidemic is real and extreme** — for-profit cesarean ~82% (TISS) / ~79%
   (SINASC) vs ~44% public; ~66% even in Robson 1 (spontaneous labor) on weekdays.
2. **Not a positive price story** — with the *economic* vaginal fee (delivery fee
   + separately billed hourly labor assistance, TUSS 31309038), the fee gap is
   negative in the big states yet they are ~80% cesarean; the coefficient is small
   and sign-unstable (+0.017 UF FE / −0.014 muni FE, n.s.); ±2 log-point state
   swings move nothing; the 2015 court order never became an actual fee change.
3. **A scheduling story** — cesareans cluster on weekdays and dip on weekends
   (−8.3pp for-profit / −6.7 public) and holidays (−5.6 / −3.5); 8–11am OR spike;
   half of cesareans in weekday business hours vs 29.8% uniform benchmark.
   NB: the holiday coefficient must use `holiday_dates(2010:2024)` — the daily file
   spans 2010–2024, so an earlier `holiday_dates(2015:2024)` in `03_mechanisms.R`
   left 2010–2014 holidays unflagged and diluted the coefficient to −5.3/−3.5.
4. **Eq. (3), the central estimate** — within the same municipality-day the
   for-profit differential is **−2.3pp weekend / −2.9pp holiday**, essentially
   unchanged (−2.2 / −2.6) after adjusting for predetermined maternal composition.
   (Strengthened from −1.8/−2.4 by the 2026-07-11 nat_jur fix, which removed
   misclassified unmatched clinics from Public; verified by fold-back.)
5. **The dip lives in prelabor cesareans** — for-profit weekend dip −9.7pp
   prelabor vs +1.7pp in-labor; persists in low-risk Robson 1–2 (−7.4pp) and
   Robson 1 alone (−6.5pp, all intrapartum).
6. **The cost** — +11.7pp early-term (37–38wk) with maternal controls; 72%
   practice style (Kitagawa); ~50k excess weekday cesareans/yr; near-parity in
   billed amounts.

## The two new extensions (2026-07-10) and their honest results

**Long weekends + displacement (`08_long_weekends.R`, Table 4 = `tab_long_weekends`).**
A single pre-specified exercise (primary outcome = prelabor cesarean share,
window [−3,+3], sample = 8 fixed-date national holidays 2012–2024). Holiday
taxonomy by day of week: **Isolated = Wednesday** (the truly isolated case, per
referee — a Mon/Fri holiday auto-creates a 3-day weekend), **ThreeDay = Mon/Fri**,
**Bridge = Tue/Thu**, weekend-falling = placebo. Eq. (`eq:blocks`) adds
ForProfit×DOW and ForProfit×HolidayName controls; event study (`eq:event`) on
counts (prelabor/in-labor/vaginal/total), differencing for-profit minus public
within municipality-day (algebraically = the muni×date FE), two-way clustered.
**RESULT = NULL in the predicted direction, reported honestly:** bridge dip is NOT
larger than isolated (γ_B=γ_I p≈0.68, prelabor p≈0.95); NO pre-holiday bunching
(pre-window prelabor sum −0.46/day, a deficit); vaginal births also fall around
holidays → some of it is a contraction of institutional activity, not diary
rearrangement. This **bounds** the "whose convenience" claim: the calendar
evidence identifies supply-side scheduling but not that it is the individual
physician's leisure. (`tab_displacement_robust` = supplement.)

**Organizational capacity (`09_org_capacity.R`, Table 6 = `tab_org_capacity`).**
Establishment-date panel of for-profit births, capacity = **obstetric beds**
(lagged one year, predetermined) + annual delivery volume as scale control,
`estab^year + muni^date` FE, clustered estab+date, primary outcome prelabor
cesarean share. **VALIDATION FINDING (revised 2026-07-11 after the CBO/CNES-PF
rebuild):** the CNES-PF obstetrician count is a WEAK proxy — among maternities
with ≥50 deliveries, **14% (for-profit) / 27% (public) register ZERO
obstetricians** (median 3/2), because Brazilian obstetricians hold their CNES bond
at their own practice, not the delivery hospital, so the count reflects
registration not the on-call roster. (The earlier "46%, equally, median 1" was an
artifact of the wrong CBO set — only 225250, no 223132 — plus a 17-of-27-UF
download; both fixed. Prose softened, do NOT reintroduce "half"/"equally".) Beds
carry the analysis; obstetrician count is col 5 only. **RESULT is weak/mixed:**
every interaction is positive (larger = flatter gradient) but only the
delivery-**scale** interaction is significant (weekend×log deliveries ≈ +0.70pp);
beds×weekend ≈ +0.45pp n.s. under muni×date FE; terciles flat. Permitted:
"larger obstetric services attenuate the weekend gradient, consistent with
organizational coverage." Forbidden: "proves it is the individual physician's
calendar rather than hospital capacity."

## The model (`latex/model.tex`, Appendix A)

Physician weighs fee gap $f_c-f_v$ against a convenience premium $\Pi$ (value of
converting an unschedulable, long, calendar-blocking event into a ~1h scheduled
procedure). Sections iff $(f_c-f_v)+\Pi > \alpha\theta$. $\Pi>0$ even when the
fee gap is negative — exactly what the data show. Predictions: P1 fees not
operative (Table 2 nulls); P2 prelabor bunch weekday business hours, in-labor
inherit random onset (Table 3 cols 4–5); P3 dip larger where obstetric time
scarce (now the org-capacity extension, weaker than hoped); P4 booking before the
wk-39 hazard → early-term excess (Table 5).

## Repository layout

```
config/   config.R (DROPBOX_ROOT — the only per-machine edit)
          00_master_build.R · 00_master_analysis.R (ordered 01→11)
build/    00_utils.R          admission proxies + TUSS delivery codes
          01a_tiss.R          one-time ANS TISS downloader (CONS+DET)
          01b_sinasc_cnes.R   one-time SINASC (Base dos Dados) + CNES beds/PF
          01c_ieps.R          IEPS muni-year covariates
          01d_cnes_estab.R    establishment-year CNES capacity panel (RUN_01D=1)
          02_deliveries.R     TISS delivery events + muni-month panel
          03_workfile.R       → main_data.parquet
analysis/ code/  00_utils.R (theme_paper, PAL, sector_display, tex_row/tex_coef/
                 tex_nobs, postprocess_tex, unescape_refs) · 01_descriptives.R ·
                 02_regressions.R (price channel → tab_fees) · 03_mechanisms.R
                 (scheduling/Robson/prelabor → tab_prelabor_lowrisk; decomposition) ·
                 04_heterogeneity.R (supp) · 05_cost.R · 06_robustness.R (policy
                 nulls, permutation, neonatal) · 07_main_specification.R (Eq 3 →
                 tab_main_gradient) · 08_long_weekends.R · 09_org_capacity.R ·
                 10_supplement.R · 11_body_figures.R (merged panels)
          output/ {graphs, tables, maps}      committed to git
latex/    paper.tex · model.tex (App A) · appendix.tex (A+B) · supplement.tex
          (standalone) · sup_appendix.tex (shared C+D body) · refs.bib
dictionary/ ANS TISS dictionaries · build_dictionary.R · variable_dictionary.xlsx
```

Scripts are self-contained (each re-sources config + utils + its own data).
**Order matters at the tail:** 07/08/09 each save a hypothesis family
(`analysis/output/fam_{A,D,E}.rds`) that `10_supplement.R` reads for the
multiple-testing table; 08 saves `evt_coefs.rds` that `11_body_figures.R` reads.
**Do NOT run two 42M-row scripts (07, 08, 09, 03, 05, 06) concurrently** — each
loads `sinasc_births.parquet` and two together exhaust memory. Run sequentially.

## Data (Dropbox, not git)

```
<DROPBOX_ROOT>/build/
  TISS/input/Hospitalar/{CONS,DET}/...              raw ANS claims 2015–2025
  TISS/output/delivery_events_<yr>.parquet · delivery_panel_muni_month.parquet
  SINASC/input/sinasc_births.parquet (~42M, 2010–2024) · sinasc_daily_muni.parquet
         (muni×date×sector) · sinasc_daily_timing_muni.parquet (adds prelabor/
         in-labor/vaginal counts, cached by 08) · sinasc_daily_estab.parquet
         (establishment×date for-profit cells, cached by 09)
  CNES/input/cnes_beds_muni_year.parquet (MONTHLY — 12 competências/yr; take
         December only when aggregating) · cnes_obstetricians_muni_year.parquet ·
         cnes_obstetricians_estab_year.parquet · cnes_estab_year.parquet (the
         establishment capacity panel from 01d)
  IEPS/output/ieps_muni_year.parquet
  covariates/input/parto_adequado_fase2_hospitais.csv
  workfile/output/main_data.parquet                 THE muni-year analytical file
```

Sources: ANS TISS PDA; SINASC via Base dos Dados (24-col query in
`01b_sinasc_cnes.R`, needs a GCP billing project); CNES beds via `datazoom.saude`,
CNES-PF via `microdatasus`; IEPS manual export; Parto Adequado Fase-2 PDF.

## Key variables

| Variable | Description | Source |
|---|---|---|
| `cesarean` | =1 if cesarean. TISS: TUSS 31309054/31309208 vs vaginal 31309127. SINASC: `tipo_parto==2`. | TISS/SINASC |
| `sector`/`private` | Establishment sector by `nat_jur` first digit: 1→Public, 2→Private (for-profit), 3→Nonprofit, else (4/5/unmatched)→Other. `private`=1 iff for-profit (2xxx). See the nat_jur table above. | SINASC×CNES |
| `cesarea_antes_parto` | 1=prelabor, 2=in-labor. **Usable from 2012** (98% missing 2010, 53% 2011, <15% from 2012). | SINASC |
| `fee_vaginal_econ` | Economic vaginal fee = delivery fee + hourly labor-assist (31309038). | TISS DET |
| `log_fee_gap` | log(fee_cesarean/fee_vaginal_econ). Negative in big states. | TISS |
| `tipo_robson` | Robson "01".."11" (01=spontaneous labor). Populated from ~2014. | SINASC |
| `weekend`,`holiday`,`eve` | Easter-based movable holidays via the anonymous Gregorian algorithm (Good Friday, Carnival Mon+Tue, Corpus Christi). | derived |
| establishment capacity | `beds_obstetric` (tipo_leito==4, December competência), `beds_total`, `n_obstetricians` (CBO via `is_obstetra`, WEAK — see above), `n_physicians` (CBO via `is_medico`), `vol` (own deliveries), one-year-lagged. | CNES via 01d |

**CBO (occupation) classifiers** — canonical definitions live in `build/00_utils.R`
(`is_medico` / `is_obstetra` / `is_enfermeiro` / `is_enfermeiro_obstetra`); the
CNES-PF field mixes 4-digit CBO-94 and 6-digit CBO-2002 codes, so they coerce to
numeric for range tests and string-match the alphanumeric residuals. Used in
`01b` (muni-year obstetrician count) and `01d` (establishment obstetrician +
physician counts). **Obstetra = exactly {225250 gineco-obstetra, 223132 obstetra,
6149, 6145}** (the old `225250`+`225270` set was wrong — `225270` is
family-strategy, not obstetrics). **Médico (all)** = CBO-94 6105–6190, CBO-2002
223101–223157 and 225103–225350, plus 2231A1–2231G1. **Enfermeiro (all)** =
7110–7165, 223505–223565, 2235C1–2235C3; **enfermeiro obstetra = 7145** (nurses
are not used in the current paper — kept for a possible midwife-supply revision).

## Exhibit map (current body: 3 figures + ~8 tables)

| Exhibit | Script | Content |
|---|---|---|
| Figure 1 `fig01_csection_trend` | 01 | Cesarean rate by sector over time |
| Table 2 `tab_fees` | 02 | Fee evidence: Panel A levels (Eq 1) + Panel B state-year first-diff |
| Table 3 `tab_main_gradient` | 07 | **Eq (3)**: Panel A for-profit differential (baseline / +predetermined / +Robson / prelabor / in-labor); Panel B each sector's own gradient |
| Figure 2 `fig_calendar_fingerprints` | 11 | (a) DOW × sector, (b) hour of birth, (c) bridge-holiday event study |
| Table 4 `tab_long_weekends` | 08 | Holiday taxonomy (Panel A) + displacement sums (Panel B) |
| Table 5 `tab_prelabor_lowrisk` | 03 | Weekend dip by prelabor/in-labor × Robson 1–2 / Robson 1 |
| Figure 3 `fig_gestation_panels` | 11 | (a) gestational age by sector, (b) by delivery timing |
| Table 6 `tab09_health` | 05 | Early-term / LBW / low-Apgar sector differences |
| Table 7 `tab11_decomposition` | 03 | Kitagawa + excess weekday cesareans |

**Body is exactly 6 tables + 3 figures** (paper ≈29pp). `tab_org_capacity` (the
organizational-capacity result, Section 6D) was **moved to the supplement**
(2026-07-10, review round 2): it came back weak/null, so featuring it in the body
invited "why is this here"; Section 6D now carries a one-paragraph summary that
points to the supplement. Table 1 (summary stats) lives in the
supplement; the body just cites it. AEJ:Policy targets ~40pp/11pt or 45pp/12pt;
the journal averages 33–34 typeset pages, so 45 is a ceiling, not a goal.

**All table and figure captions are bold** (`\caption{\textbf{...}}`), matching
the house style. `postprocess_tex()` bolds the caption of every etable table on
re-run; hand-built `writeLines` tables include `\textbf` in source. If you add a
new table, keep the bold.

**Supplement** (`sup_appendix.tex`, built by 10_supplement + 06_robustness + moved
body exhibits): summary stats, for-profit-cesarean map, business-hours table,
Robson-DOW figure, daily-counts figure, full mechanism-checks table (incl.
Robson-10, which is NOT a clean placebo — interaction p=0.18), billed-cost table,
`tab_displacement_robust`, `tab_org_capacity_valid`, municipality heterogeneity
(`tab10_heterogeneity` — obstetrician density, education), `tab10b_modality`
(cooperativas), referee robustness, region/period
stability, permutation ranking, no-indication share, neonatal (null, underpowered
— do NOT feature), fee CI/equivalence, base-vs-economic fee, few-cluster
bootstrap, sample flow, timing missingness, Robson validation, **the Parto
Adequado hospital-level Sun–Abraham event study only** (`fig_ref_c11`, from
`10_supplement.R` H/C11, styled: x-axis in years, dashed line at the 2017 onset,
y = "For-profit cesarean rate") **plus the RN 368 timeline `fig05`**. `tab_multiple_testing`
(5 families A–E, incl. long weekends D and capacity E).

## Key numbers (sanity checks; SINASC = 2010–2024)

| Fact | Value |
|---|---|
| Cesarean (all / for-profit / nonprofit / public) | ~57% / 79% / 60% / 44% |
| Weekend dip (for-profit / public) | −8.3pp / −6.7pp |
| Holiday dip (for-profit / public) | −5.6pp / −3.5pp (full 2010–2024 holiday range) |
| **Eq (3) for-profit differential (muni×date FE)** | **weekend −2.3pp / holiday −2.9pp**; +predetermined −2.2 / −2.6; +Robson −1.9 / −2.3 |
| Weekend dip: prelabor vs in-labor (for-profit) | −9.7pp vs +1.7pp |
| Robson 1–2 / Robson 1 weekend dip (for-profit) | −7.4pp / −6.5pp |
| Long-weekend: bridge = isolated test | p≈0.68 (prelabor p≈0.95) — NO larger bridge effect |
| Pre-holiday prelabor bunching (bridge) | −0.46/day (deficit, NOT bunching) |
| Org capacity: weekend×log(beds) prelabor | +0.45pp n.s. (muni×date FE); scale +0.70pp* (col 2) |
| Zero-obstetrician maternities (CNES-PF, ≥50 deliv.) | 14% for-profit / 27% public (median 3/2), corrected CBO + full 27-UF download |
| Early-term (37–38wk) for-profit gap, maternal controls | +11.7pp*** |
| Kitagawa: 35.1pp gap | 28% case-mix / 72% practice style |
| Excess weekday cesareans | ~50k/yr for-profit (~10.5%) |
| `log_fee_gap` coef (UF / muni FE) | +0.017 / −0.014 (n.s.) |

## Compile

`paper.tex` first (supplement uses `xr`/`\externaldocument{paper}`, needs
`paper.aux`; do not clean it between):
```
cd latex
pdflatex paper; bibtex paper; pdflatex paper; pdflatex paper
pdflatex supplement; bibtex supplement; pdflatex supplement; pdflatex supplement
```
Supplement needs its OWN bibtex pass (cites holm1979 + benjamini1995 in App D).
`paper.tex` \inputs `appendix.tex` (A model + B data) before the bibliography;
the Supplemental Appendix is a separate document.

## Conventions

- **R** with `data.table`/`arrow`/`fixest`; `pacman::p_load`. Prefer lazy
  `arrow`/`fread` column subsets over loading full files.
- Municipality key = **6-digit IBGE**; SINASC gives 7-digit → first 6.
- Figures: `theme_paper()` + `PAL`, no titles/subtitles/captions, PDF+PNG via
  `save_fig()`. **Never `scale_y_continuous(limits=)`** — it silently drops
  out-of-range points; use `breaks` or `coord_cartesian`. Multi-panel body figures
  use `patchwork`.
- Tables via `etable` + `dict` (full names, never abbreviate; always `dict` the
  outcome). For hand-built multi-panel tables use `tex_row`/`tex_coef`/`tex_nobs`
  from `00_utils.R`. `postprocess_tex()` (booktabs + shrink-only `\resizebox`);
  `unescape_refs()` on any table whose note cites a `\ref{}` with an underscore in
  the label. Very wide tables (≥6 cols) → `sidewaystable` (needs `rotating`).
- **fixest interaction naming**: an interaction may resolve as `a:b` or `b:a`;
  when building rows by name, look the term up in `rownames(coeftable(m))` or give
  BOTH orders a `dict` entry (see `09_org_capacity.R`).
- **fixest `i(x, ..., ref=0)`**: when interacting a dummy with a treated indicator
  inside a model that already has that indicator's FE (muni×date), pass `ref=0` so
  only the treated-level interaction enters; omitting it makes the term collinear
  with the FE and blows the estimate up (this happened in 08, since fixed).
- Don't cache full fitted `fixest` objects to disk (they carry the design matrix —
  one cache hit 1.1GB). Slim to `list(ct=coeftable, V=vcov, n=nobs)`.
- **Never commit data** (`*.parquet/*.csv/*.rds` gitignored). Commit/push only when
  asked. macOS filesystem is case-insensitive.

## The 2026-07-10 revision (what changed, and why)

Following a referee report (GPT "Proof Patrol"), the paper was reorganized:
- **Eq (3) became the backbone.** Section 4 has subheads A price / B descriptive
  gradients / C main within-muni-day spec ("our main estimating equation") / D
  estimands. Section 6 leads with the merged gradient table (`tab_main_gradient`).
- **Body trimmed** toward 6–7 tables + 3 figures; map, Robson-DOW figure,
  daily-counts figure, cooperativas, billed cost, full summary stats, education
  heterogeneity, region/period, ALL Parto Adequado → supplement. Figures 2 and 3
  are merged multi-panel (`11_body_figures.R`).
- **Caveats trimmed, not hidden.** The long descriptive-not-causal paragraphs in
  intro and conclusion were replaced with precise estimand names; the detailed
  identification discussion stays only in Section 4.
- **Policy de-emphasized.** No "policy failure" framing; the court order = an
  implementation failure, Parto Adequado = an identification failure; both
  motivate, not identify. One paragraph in the body.
- **Two new analyses** (long weekends, org capacity) came back weaker/null than
  the mechanism hoped, and are reported honestly. This is a feature: they mark the
  boundary of what the calendar evidence identifies.
- **Terminology standardized**: "for-profit" (SINASC ownership) vs
  "private-insurance sector" (TISS), never bare "private" or "private for-profit".

**Former `07_referee_response.R` was split**: its pooled-DiD/composition sections
became `07_main_specification.R` (now producing `tab_main_gradient`), and its
robustness sections became `10_supplement.R`.

## Honest limits (the identification ceiling)

No operadora/hospital/physician IDs in TISS; paid prices ~5% populated; no
enrollment/premium panel; TISS monthly (SINASC gives the daily grain); no clean
differentially-timed policy shock (Parto Adequado fails parallel trends, fee
shocks null). The CNES-PF obstetrician count does not measure the on-call team.
The long-weekend nulls mean the calendar evidence identifies supply-side
scheduling but not whose convenience it serves.

## Clinical-cost positioning

We do NOT build new empirical programs on maternal mortality/NICU/broad neonatal
morbidity (selection dominates — for-profit shows LOWER LBW/low-Apgar; power is
inadequate; the causal harm is better identified elsewhere). "Why it matters" =
(a) our own early-term result + weekend-composition corroboration; (b) magnitudes;
(c) price the harm with the literature (Tita 2009 NEJM; Costa-Ramón 2018 JHE;
Card, Fenizia & Silver 2023 AEJ:Policy; Sandall 2018 Lancet). The suggestive TISS
neonatal check (`06_robustness.R` → `tab14`) is null and underpowered — keep for
transparency, do NOT feature.

## ACTION items for Fredie

- Verify the Tita et al. (2009) early-term neonatal-morbidity magnitudes cited in
  the Cost-section back-of-envelope and verify citations.
