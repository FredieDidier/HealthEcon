# CLAUDE.md — HealthEcon Project Guide

## What the paper is

Empirical paper, *"Born on Schedule: Fees, Supply-Side Scheduling, and Cesarean
Delivery in Brazil."* It asks why Brazil's **for-profit maternity sector** runs
the highest cesarean rate documented for any large health system (~80% of
deliveries, vs a WHO reference of 10–15%), and answers by separating a **price
channel** (do relative fees drive it? no) from a **scheduling channel** (do
cesareans cluster on weekdays and dip on weekends and holidays? yes). Target
journal: **Journal of Health Economics** (decided 2026-07-16, after the Proof
Patrol round on Parfitt & Goulart 2026 JDE judged AEJ:Policy a long shot without
an exogenous organizational shock). The manuscript follows the JHE/Elsevier
guide: single-column .tex; title page with superscript-letter affiliations and a
marked corresponding author; JEL/keywords with semicolons; unnumbered
declarations sections before the references (CRediT — DRAFT roles, Fredie must
confirm; competing interests; funding; data availability; generative-AI use);
`latex/highlights.txt` (≤85 chars per bullet) uploaded as a separate file.
Author-year natbib references are acceptable at submission (Elsevier restyles at
proof), so `plainnat-rev.bst` stays.

**The paper's one recognizable design is Equation (3)**, a
within-municipality-day for-profit-versus-public differential; everything else is
mechanism, magnitude, or robustness around it. This structure (set 2026-07-10)
followed a detailed referee report; see "The 2026-07-10 revision" below for what
changed and why.

**Authors (in order):** Fredie Didier (IDP; corresponding, fdidier@terra.com.br),
Vinicius Mendes (UFBA), Pablo Castro (UFBA), Lucas Emanuel (UFBA). Written in the
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
- **Robson-group profile + term/preterm + maternal-age splits** (2026-07-22) =
  *corroboration, NOT a placebo*. Robson group and gestational age at birth are
  partly determined by the same decisions under study, so these are heuristic
  falsifications. Say "the excess for-profit gradient is concentrated where the
  delivery date can be chosen in advance"; never "preterm births are a clean
  control." Preterm ≠ unschedulable (preeclampsia, IUGR, elective late-preterm
  are all booked). The maternal-age split is exploratory and NOT in the
  pre-specified families A–E; always pair it with the ceiling caveat (a pp
  differential compresses mechanically as the base rate approaches 1).
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

**Organizational capacity (`09_org_capacity.R`, supplement Table D.8 = `tab_org_capacity`).**
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
operative (Table 1 nulls); P2 prelabor bunch weekday business hours, in-labor
inherit random onset (Table 2 cols 4–5); P3 dip larger where obstetric time
scarce (now the org-capacity extension, weaker than hoped); P4 booking before the
wk-39 hazard → early-term excess (Table 5, `tab09_health`).

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
                 10_supplement.R · 12_subgroups.R (Robson/gestation/age splits →
                 tab_subgroup_gradients + robson_grad.rds) · 11_body_figures.R
                 (merged panels; RUN AFTER 12)
          output/ {graphs, tables, maps}      committed to git
latex/    paper.tex · model.tex (App A) · appendix.tex (A+B) · supplement.tex
          (standalone) · sup_appendix.tex (shared C+D body) · refs.bib
dictionary/ ANS TISS dictionaries · build_dictionary.R · variable_dictionary.xlsx
```

Scripts are self-contained (each re-sources config + utils + its own data).
**Order matters at the tail:** 07/08/09 each save a hypothesis family
(`analysis/output/fam_{A,D,E}.rds`) that `10_supplement.R` reads for the
multiple-testing table; 08 also builds `fig_long_weekend_event`, the displacement
event study now shown in the supplement. **`12_subgroups.R` runs BEFORE `11`**
despite its number: it saves `robson_grad.rds`, the coefficients `11` draws as
Figure 3 panel (c) (`11` falls back to the old two-panel layout if the file is
absent). `11_body_figures.R` is otherwise self-contained (it reads
`sinasc_daily_muni` + `main_data`, no longer `evt_coefs.rds`).
**Do NOT run two 42M-row scripts (07, 08, 09, 03, 05, 06, 12) concurrently** —
each loads `sinasc_births.parquet` and two together exhaust memory (12 alone peaks
around 14GB of R vector cells). Run sequentially.

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

## Exhibit map (current body: 3 figures + 6 tables)

**The numbers below are the ones LaTeX actually prints** (verified against
`paper.aux`, 2026-07-22). Summary statistics used to be body Table 1 and moved to
the supplement, which shifted every body table down by one; the map had never been
renumbered. **If you move an exhibit, re-derive this map from `paper.aux`**
(`grep -o "newlabel{tab:[^}]*}{{[^}]*}" paper.aux`), do not renumber by hand.

| Exhibit | Label | Script | Content |
|---|---|---|---|
| Figure 1 `fig01_csection_trend` | `fig:trend` | 01 | Cesarean rate by sector over time |
| Figure 2 `fig_two_margins` | `fig:two_margins` | 11 | (a) price-margin binscatter (cesarean rate on log fee gap, muni+year FE removed); (b) scheduling margin: weekend/holiday/eve gradients for public + for-profit + the for-profit differential. The one exhibit showing both channels side by side. |
| Figure 3 `fig_calendar_fingerprints` | `fig:calendar` | 11 (+12) | (a) DOW × sector, (b) hour of birth, (c) weekend gradient by Robson group (coefficients from `12`; added 2026-07-22). Bridge-holiday event study MOVED to supplement. |
| Table 1 `tab_fees` | `tab:fees` | 02 | Fee evidence: Panel A levels (Eq 1) + Panel B state-year first-diff |
| Table 2 `tab_main_gradient` | `tab:main_gradient` | 07 | **Eq (3)**: Panel A for-profit differential (baseline / +predetermined / +Robson / prelabor / in-labor); Panel B each sector's own gradient |
| Table 3 `tab_prelabor_lowrisk` | `tab:prelabor_lowrisk` | 03 | Weekend dip by prelabor/in-labor × Robson 1–2 / Robson 1 |
| Table 4 `tab_long_weekends` | `tab:long_weekends` | 08 | Holiday taxonomy (Panel A) + displacement sums (Panel B) |
| Table 5 `tab09_health` | `tab:health` | 05 | Early-term / LBW / low-Apgar sector differences |
| Table 6 `tab11_decomposition` | `tab:decomposition` | 03 | Kitagawa + excess weekday cesareans |

**Body is exactly 6 tables + 3 figures**: figures = trend (Fig 1),
`fig_two_margins` (Fig 2, price binscatter + scheduling gradients — the summary
exhibit, added 2026-07-12 per the ECON-GPT suggestion; built in `11`), and
`fig_calendar_fingerprints` (Fig 3, 3 panels since 2026-07-22). The gestational-age
figure and the bridge-holiday displacement event study (former Fig-3 panel c) BOTH
moved to the supplement (2026-07-12); the body cites them via `\safig{fig:gestation}`
(now Figure C.4) / `\safig{fig:displacement_event}` (now Figure D.1, the standalone
`fig_long_weekend_event.pdf` from `08`). `tab_org_capacity` (the
organizational-capacity result, Section 6D) was **moved to the supplement**
(2026-07-10, review round 2), where it is Table D.8: it came back weak/null, so
featuring it in the body invited "why is this here"; Section 6D now carries a
one-paragraph summary that points to the supplement. The summary statistics
(`tab01_descriptives`, once body Table 1) live in the supplement as Table C.1; the
body just cites them. JHE publishes papers of any length and encourages short ones,
so the trimmed body is fine; do not re-inflate it.

**All table and figure captions are bold** (`\caption{\textbf{...}}`), matching
the house style. `postprocess_tex()` bolds the caption of every etable table on
re-run; hand-built `writeLines` tables include `\textbf` in source. If you add a
new table, keep the bold.

**Supplement** (`sup_appendix.tex`, built by 10_supplement + 06_robustness + moved
body exhibits). **Reorganized 2026-07-16 into three appendices so a reader can
tell robustness from description** (user request): **C = additional descriptive
figures/tables** (summary stats, map, business hours, Robson-DOW, daily counts,
mechanism-checks table, gestation panels, billed cost); **D = robustness,
validation, and inference** (D.1 weekend-dip alternatives/placebos incl.
neonatal-suggestive and `tab_subgroup_gradients` = Table D.3, the
term/preterm + maternal-age splits added 2026-07-22; D.2 long
weekends/displacement, D.3 org capacity, D.4
heterogeneity + demand-side alternatives, D.5 measurement validation +
few-cluster inference + sample flow, D.6 multiple testing); **E = the policy
record** (Parto Adequado Sun–Abraham event study + RN 368 timeline). Old labels
`app:robustness`/`app:referee` → now `app:descriptive`/`app:robustness`/
`app:policy`. Contents in detail: summary stats, for-profit-cesarean map, business-hours table,
Robson-DOW figure, daily-counts figure, gestational-age panels
(`fig_gestation_panels`, moved from body 2026-07-12), bridge-holiday displacement
event study (`fig_long_weekend_event`, the former Fig-2 panel c), full
mechanism-checks table (incl.
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
| Robson profile, for-profit vs public weekend dip (Fig 3c) | G1 −6.3/−3.7 · G2 −5.2/−3.8 · G3 −8.0/−3.0 · G4 −9.1/−4.2 · G5 −3.6/−5.8 · G10 **−5.1/−5.2 (identical)** |
| Eq (3) differential, term vs preterm | −2.5pp vs **+0.8pp**; difference +3.4pp, p<0.001 |
| Eq (3) differential, mother <35 vs 35+ | −3.0pp vs +1.3pp (diff +4.3, p<0.001); within Robson 1–2, −5.0 vs −1.4 (diff +3.6, p<0.001) |
| Long-weekend: bridge = isolated test | p≈0.68 (prelabor p≈0.95) — NO larger bridge effect |
| Pre-holiday prelabor bunching (bridge) | −0.46/day (deficit, NOT bunching) |
| Org capacity: weekend×log(beds) prelabor | +0.45pp n.s. (muni×date FE); scale +0.70pp* (col 2) |
| Zero-obstetrician maternities (CNES-PF, ≥50 deliv.) | 14% for-profit / 27% public (median 3/2), corrected CBO + full 27-UF download |
| Early-term (37–38wk) for-profit gap, maternal controls | +11.7pp*** |
| Kitagawa: 35.1pp gap | 28% case-mix / 72% practice style |
| Excess weekday cesareans | ~50k/yr for-profit (~10.5%) |
| `log_fee_gap` coef (UF / muni FE) | +0.017 / −0.014 (n.s.) |

## Compile

The `xr` dependency runs **BOTH ways** — `supplement.tex` needs `paper.aux` and
`paper.tex` needs `supplement.aux` (the ~29 `\satab`/`\safig` cross-references).
So the cycle must be run twice, paper → supplement → paper, and **the `.aux`
files must survive between passes** (never clean between). Running only
`paper → supplement` on a clean checkout is what makes every supplement
reference print as `??` in paper.pdf:
```
cd latex
pdflatex paper; bibtex paper
pdflatex supplement; bibtex supplement; pdflatex supplement
pdflatex paper; pdflatex paper
pdflatex supplement
```
Verify with `grep -c "Reference .* undefined" paper.log` → must be 0.
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

## The 2026-07-16 revision (Proof Patrol round 3: Parfitt positioning + JHE)

Two Proof Patrol reports (PDF in Downloads, "GPT Feedback") drove this round:
- **Parfitt & Goulart (2026 JDE, heatwaves in Brazilian maternity wards) is now
  cited and distinguished** in the intro contributions ("closest contemporaneous
  study"; our muni×date FE absorb temperature; different estimand), with a
  footnote that sector definitions are NOT comparable across Parfitt (public
  wards), Melo (bed-allocation classes), and us (natureza jurídica).
- **New literature block** (capacity/staffing/crowding): maibom2021 (JHE),
  bensnes2026 (Health Econ), facchini2022 (JEBO), bachner2024 (IZA DP 16981);
  timing lit expanded with cohen1983, spetz2001, spinola2025 (the published
  EJHE version of Rocha–Spinola 2016), gans2012, lo2003. All verified.
- **Language softened** (3 exact substitutions): "identifies supply-side
  scheduling without identifying whose convenience" → "documents an
  ownership-specific supply-side calendar pattern consistent with scheduling,
  without identifying the causal effect of scheduling or whose constraints
  generate it"; "If the operative margin is..." → "If, as the combined evidence
  suggests, an important margin is..."; conclusion's "The cesarean converts..."
  → "The observed patterns are consistent with cesareans being used to
  convert...".
- **Carnival reconciled**: "Neither prediction survives in our fixed-date
  holiday design" + explicit non-contradiction of Melo (Carnival is movable,
  long, salient, excluded from eq:blocks) + closing sentence that displacement
  may depend on holiday duration/salience. All long-weekend claims qualified as
  "ordinary fixed-date national holidays".
- **Contribution reframed as fees-versus-time joint diagnosis** (opens the
  contribution block); Sec 5 opens with the scope disclaimer (observed billed
  compensation only); educated-mothers sentence no longer "rules out" demand;
  org-capacity paragraph cites the crowding literature and disclaims causality.
- **Table cleanups (user request)**: tab_fees Panel B now shows the wild-cluster
  bootstrap p for BOTH columns (FD 0.210 / levels 0.145 — boottest needs the FE
  as formula dummies for the weighted levels model), FD and levels coefficients
  on separate labeled rows, State/Year FE rows; ", Equation (N)" removed from
  panel titles in tab_fees and tab_main_gradient; tab_main_gradient Panel B got
  Municipality/Year FE + Observations rows (public 3,480,217 / for-profit
  1,455,272); tab_long_weekends Panel B got DOW/muni/year-month FE rows;
  tab09_health rebuilt hand-made in the tab_prelabor_lowrisk layout, in pp
  (14.14/11.73/−2.99/−0.53), with a Maternal-controls row; fig_two_margins note
  no longer cites the fee table by column number. `clean_etable_header()` in
  `analysis/code/00_utils.R` (now part of `postprocess_tex()`) strips etable's
  "Dependent Variables:"/"Model:"/"\emph{Variables}"/"\emph{Fit statistics}"
  clutter from every etable table; applied to all 9 supplement etables.

## The 2026-07-22 revision (Vinicius's requests + numbering audit)

New script **`12_subgroups.R`** (runs BEFORE `11`, see the master), answering the
three coauthor requests. All three came back *supporting* the mechanism, which is
the opposite of the 2026-07-10 extensions:

- **Robson-group profile → body Figure 3 panel (c).** Each sector's own weekend
  gradient, estimated group by group (2014–2024). The for-profit *excess* dip is
  concentrated in groups 1–4 (term, singleton, cephalic, no previous cesarean =
  real discretion), vanishes in 6–9 (near-ceiling cesarean rates, no room for a
  gradient), and is exactly zero in group 10 (preterm: −5.1 vs −5.2). Coefficients
  cached slim in `analysis/output/robson_grad.rds`.
- **Term vs preterm → supplement Table D.3.** Eq (3) differential −2.5pp term vs
  +0.8pp preterm, difference +3.4pp (p<0.001). Much stronger than the old
  Robson-10 "placebo" (p=0.18), which stays in `tab_mechanism_checks`.
- **Maternal age → same table, Panels B–C.** Gradient concentrated among mothers
  under 35 (−3.0 vs +1.3 overall; −5.0 vs −1.4 within Robson 1–2). ALWAYS report
  with the ceiling caveat — the paper does not separate arithmetic compression
  from a genuinely larger discretionary margin.

**Answered directly (do not re-litigate):** there is no term/preterm split inside
Robson 1–2, because those groups are DEFINED as ≥37 weeks and group 10 as ≤36.
The term-vs-preterm contrast *is* Robson 1–2 vs Robson 10.

**Exhibit-numbering audit (same day).** Every body table number in CLAUDE.md,
README.md, and the script header comments was **off by one** (the map still
assumed summary stats were body Table 1, but they moved to the supplement long
ago), and several figure pointers named the wrong figure entirely
(`01_descriptives` and `03_mechanisms` said the hour-of-birth and DOW panels feed
Figure 2, they feed Figure 3; `05_cost` said the gestation panels are body Figure
3, they are supplement Figure C.4). All corrected against `paper.aux`. The `.tex`
sources were never affected — they use `\ref{}` throughout, so the compiled PDF
was always right.

**Compile-order bug found and documented.** `xr` runs both ways, so a
paper→supplement-only pass leaves all ~29 `\satab`/`\safig` references as `??` in
paper.pdf. See the Compile section for the corrected cycle.

## ACTION items for Fredie

- Verify the Tita et al. (2009) early-term neonatal-morbidity magnitudes cited in
  the Cost-section back-of-envelope and verify citations.
- **Temperature robustness (Proof Patrol R1 C4, still open):** acquire municipal
  daily temperature (INMET or ERA5) and re-estimate Eq (3) adding
  ForProfit×temperature-bin controls (+ precipitation if available; + dropping
  days above the local 95th percentile), reported next to the main spec in the
  supplement, to show the calendar gradient is not an unmodeled Parfitt climate
  channel. No temperature data exists in the repo yet, so this was NOT done.
- **Confirm the CRediT roles** drafted in paper.tex (marked TODO) before
  submission; Elsevier requires them to be accurate.
- Prepare the Elsevier declarations-tool entries (competing interests Word doc)
  and consider the free SSRN preprint option at submission.
