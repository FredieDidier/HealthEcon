# CLAUDE.md — HealthEcon Project Guide

> **2026-09-27 — every number below was re-estimated.** The sector is now the
> establishment's legal nature in the birth's own year (CNES 2012-2024; 2010-2011
> take 2012), not "ever for-profit"; the prelabor/in-labor split uses 2012+ in
> every script; Table 2 col 3 uses 2014+; family E has four tests; a July-10 model
> cache (`m_tax_slim.rds`) had frozen the long-weekend Panel A. The headline
> differential fell from −2.3 to −1.8pp (weekend) and −2.9 to −2.5pp (holiday);
> the capacity interactions are no longer significant with muni×date FE. Full
> record: `parto_cesareo/REVISION_LOG.md`, entry of 2026-09-27. Where this file
> and the generated tables disagree, the tables win.


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
followed a detailed referee report; see "The 2026-07-10 revision" in `parto_cesareo/REVISION_LOG.md` for what
changed and why.

**Authors (in order):** Fredie Didier (IDP; corresponding, fdidier@terra.com.br),
Vinicius Mendes (UFBA), Pablo Castro (UFBA), Lucas Emanuel (UFBA). Written in the
first person plural. No acknowledgments footnote (removed 2026-07-10).

## Evidence taxonomy (hold this labeling everywhere)

The paper is *structured descriptive and mechanism evidence organized around one
tightly controlled quasi-experimental contrast*. Per-result labels, which must
hold in abstract, intro, strategy section, table notes, and conclusion:

- **fee regressions** = conditional associations, sign-unstable, and NOT an
  equivalence result (fixed 2026-09-05; see "The 2026-09-05 revision" in `parto_cesareo/REVISION_LOG.md`). The
  intervals do not fit inside the pre-registered negligible region, so never say
  "there is no relationship" or "fees don't matter." Say: the sign is unstable
  across fixed-effect schemes, and the canonical magnitude
  (\citet{gruber1999physician}, ~1pp per US$1,000 = ~0.72pp per log point at our
  fee levels) is too small to matter at this scale, predicting ~0.25pp against a
  35pp gap. The RAW FACT leads, the regression follows.
- **demand smoothing** (Eq. de Elejalde-Giolito) = tested and NOT supported. The
  pull-forward null is weak (say so); the throughput result points the other way
  but is only marginally significant and dies under the family adjustment, so
  report it as an ABSENCE of levelling, never as evidence that scheduling makes
  the flow lumpier.
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
- **Kitagawa decomposition** = accounting; 73% practice style.
- **~35k excess weekday cesareans/yr** (own-municipality-year benchmark) = mechanical benchmark, not cesareans caused.
- **early-term +12.2pp** = sector–gestational-age association.
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
for-profit" (conflates payer and ownership). The rule binds figure legends too:
`fig09_gestation` (from `05_cost.R`) labelled its series "Private"/"Public" until
2026-09-06 and now calls `sector_display()` like everywhere else. Relabel the
AGGREGATE, not the source table -- the block right after it subsets on
`sector == "Private"`. That figure and `fig09b_gestation_by_timing` are orphan
outputs, included in no `.tex` (so are `tab_ref_c7_placebo_ranking.tex`, whose
content the included `tab15_permutation` carries, `map01_csection_all`,
`fig_long_weekend_event_blocks`, and the two single-panel figures named in the
colour note below; 30 of the 31 generated tables are included, and every exhibit
that IS included is cited in the text -- verified 2026-09-09): the supplement's Figure C.4 is
`fig_gestation_panels`, built by `11_body_figures.R`. Headline contrast is **for-profit
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
   negative in the big states yet they are ~80% cesarean; the coefficient is
   sign-unstable (+0.017 UF FE / −0.014 muni FE, n.s.; +0.047 UF FE without
   controls, marginally significant — do NOT call it "small"); ±2 log-point state
   swings move nothing; the 2015 court order never became an actual fee change.
   The claim is calibrated, not an equivalence result: see the taxonomy above.
3. **A scheduling story** — cesareans cluster on weekdays and dip on weekends
   (−7.9pp for-profit / −6.7 public) and holidays (−5.3 / −3.5); 8–11am OR spike;
   half of cesareans in weekday business hours vs 29.8% uniform benchmark.
   NB: the holiday coefficient must use `holiday_dates(2010:2024)` — the daily file
   spans 2010–2024, so an earlier `holiday_dates(2015:2024)` in `03_mechanisms.R`
   left 2010–2014 holidays unflagged and diluted the coefficient to −5.3/−3.5.
4. **Eq. (3), the central estimate** — within the same municipality-day the
   for-profit differential is **−1.8pp weekend / −2.5pp holiday**, essentially
   unchanged (−2.2 / −2.6) after adjusting for predetermined maternal composition.
   (Strengthened from −1.8/−2.4 by the 2026-07-11 nat_jur fix, which removed
   misclassified unmatched clinics from Public; verified by fold-back.)
5. **The dip lives in prelabor cesareans** — for-profit weekend dip −8.9pp
   prelabor vs +1.7pp in-labor; persists in low-risk Robson 1–2 (−7.4pp) and
   Robson 1 alone (−6.5pp, all intrapartum).
6. **The cost** — +12.2pp early-term (37–38wk) with maternal controls; 73%
   practice style (Kitagawa); ~35k excess weekday cesareans/yr against the
   OWN-MUNICIPALITY weekend benchmark (10.0% of weekday cesareans); near-parity in
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
download; both fixed. Prose softened, do NOT reintroduce "half"/"equally".
⚠️ That softening had reached the paper body and `tab_org_capacity_valid` but NOT
the note of `tab_org_capacity` itself, which still said "about half … equally" in
both `09_org_capacity.R` and the generated `.tex` until 2026-09-04; it now reads
"14 percent of for-profit and 27 percent of public maternities register none".
`09` was not re-run — the change is text only.) Beds
carry the analysis; obstetrician count is col 5 only. **RESULT is weak/mixed:**
every interaction is positive (larger = flatter gradient) but, since the
2026-09-27 re-estimation, NONE is significant under muni×date FE (scale +0.64pp,
SE 0.41; beds +0.57pp, SE 0.38); the scale term is precise only with date FE
(col 1, +1.49pp***); terciles flat; family E has four tests, none significant
even unadjusted. Permitted: "the point estimates suggest a flatter gradient at
larger services, but none is distinguishable from zero with municipality-by-date
fixed effects." No longer a 'fingerprint' of the paper. Forbidden: "proves it is the individual physician's
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
                 tex_nobs, postprocess_tex, standardize_notes, write_table_tex,
                 unescape_refs) · 01_descriptives.R ·
                 02_regressions.R (price channel → tab_fees) · 03_mechanisms.R
                 (scheduling/Robson/prelabor → tab_prelabor_lowrisk; decomposition) ·
                 04_heterogeneity.R (supp) · 05_cost.R · 06_robustness.R (policy
                 nulls, permutation, neonatal) · 07_main_specification.R (Eq 3 →
                 tab_main_gradient) · 08_long_weekends.R · 09_org_capacity.R ·
                 10_supplement.R · 12_subgroups.R (Robson/gestation/age splits →
                 tab_subgroup_gradients + robson_grad.rds) ·
                 13_demand_smoothing.R (de Elejalde-Giolito channel →
                 tab_demand_smoothing + fam_F.rds; RUN BEFORE 10) ·
                 14_estab_practice_style.R (Robson-standardized dispersion across
                 maternities → tab_estab_practice_style) ·
                 11_body_figures.R (merged panels; RUN AFTER 12)
          output/ {graphs, tables, maps}      committed to git
latex/    paper.tex · model.tex (App A) · appendix.tex (A+B) · supplement.tex
          (standalone) · sup_appendix.tex (shared C+D body) · refs.bib
dictionary/ ANS TISS dictionaries · build_dictionary.R · variable_dictionary.xlsx
```

Scripts are self-contained (each re-sources config + utils + its own data).
**Order matters at the tail:** 07/08/09/13 each save a hypothesis family
(`analysis/output/fam_{A,D,E,F}.rds`) that `10_supplement.R` reads for the
multiple-testing table; 08 also builds `fig_long_weekend_event`, the displacement
event study now shown in the supplement. **`12_subgroups.R` runs BEFORE `11`**
despite its number: it saves `robson_grad.rds`, the coefficients `11` draws as
Figure 3 panel (c) (`11` falls back to the old two-panel layout if the file is
absent). `11_body_figures.R` is otherwise self-contained (it reads
`sinasc_daily_muni` + `main_data`, no longer `evt_coefs.rds`).
`13_demand_smoothing.R` is cheap (~1 min, reads only the cached
`sinasc_daily_estab.parquet`), so it is outside the memory constraint below.
**Do NOT run two 42M-row scripts (07, 08, 09, 03, 05, 06, 12, 14) concurrently** —
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
         (establishment×date for-profit cells, cached by 09) ·
         sinasc_estab_year_robson.parquet (establishment-year × Robson cells with
         case-mix sums, all three sectors, cached by 14)
  CNES/input/cnes_beds_muni_year.parquet (MONTHLY — 12 competências/yr; take
         December only when aggregating) · cnes_obstetricians_muni_year.parquet ·
         cnes_obstetricians_estab_year.parquet · cnes_estab_year.parquet (the
         establishment capacity panel from 01d; carries beds_sus /
         beds_obstetric_sus / sus_share / sus_share_obstetric since 2026-09-07)
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
new table, keep the bold. The **figure** captions in `paper.tex` and
`sup_appendix.tex` were the exception until 2026-09-04 (they were plain while all
29 tables were bold) and are now bold too, so the rule finally holds literally.
Note that in an etable table the `\label` comes *first*
(`\caption{\label{tab:x} \textbf{Title}}`), so a grep for `caption{\textbf`
misses ten of them and will tell you they are unbolded — they are not.

**Body subsections carry no letter** (since 2026-09-04, user request): write
`\subsection{The price channel}`, not `\subsection{A. The price channel}`, so the
heading prints as "4.1", not "4.1 A". The organizational-capacity subsection
carries `\label{sec:capacity}` because two cross-references used to point at it
as `Section~\ref{sec:mechanism}\,D`; reference subsections by label, never by
letter.

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
(6 families A–F, incl. long weekends D, capacity E and demand smoothing F).
**`tab_estab_practice_style` (added 2026-09-07) is Table C.4**, which pushed
`tab12_cost` from C.4 to C.5; appendix D is unchanged. Re-derive from
`supplement.aux`, never renumber by hand.
D.10 is `tab_demand_smoothing` (added 2026-09-05, inside the organizational-capacity
block); it pushed heterogeneity to D.11 and everything after down one — re-derive
from `supplement.aux`, never renumber by hand.

## Key numbers (sanity checks; SINASC = 2010–2024)

| Fact | Value |
|---|---|
| Cesarean (all / for-profit / nonprofit / public) | ~56% / 81% / 60% / 43% |
| Weekend dip (for-profit / public) | −7.9pp / −6.7pp |
| Holiday dip (for-profit / public) | −5.6pp / −3.5pp (full 2010–2024 holiday range) |
| **Eq (3) for-profit differential (muni×date FE)** | **weekend −1.8pp / holiday −2.5pp**; +predetermined −1.8 / −2.4; +Robson (2014+) −1.5 / −1.7 |
| Weekend dip: prelabor vs in-labor (for-profit) | −8.9pp vs +1.9pp |
| Robson 1–2 / Robson 1 weekend dip (for-profit) | −7.4pp / −6.5pp |
| Robson profile, for-profit vs public weekend dip (Fig 3c) | G1 −6.3/−3.7 · G2 −5.2/−3.8 · G3 −8.0/−3.0 · G4 −9.1/−4.2 · G5 −3.6/−5.8 · G10 **−5.1/−5.2 (identical)** |
| Eq (3) differential, term vs preterm | −2.5pp vs **+0.8pp**; difference +3.4pp, p<0.001 |
| Eq (3) differential, mother <35 vs 35+ | −3.0pp vs +1.3pp (diff +4.3, p<0.001); within Robson 1–2, −5.0 vs −1.4 (diff +3.6, p<0.001) |
| Long-weekend: bridge = isolated test | p≈0.68 (prelabor p≈0.95) — NO larger bridge effect |
| Pre-holiday prelabor bunching (bridge) | −0.46/day (deficit, NOT bunching) |
| Org capacity: weekend×log(beds) prelabor | +0.57pp n.s. (muni×date FE); scale +0.64pp n.s. (col 2); scale +1.49pp*** only with date FE (col 1) |
| Zero-obstetrician maternities (CNES-PF, ≥50 deliv.) | 14% for-profit / 27% public (median 3/2), corrected CBO + full 27-UF download |
| Early-term (37–38wk) for-profit gap, maternal controls | +12.2pp*** |
| Kitagawa: 36.2pp gap | 27% case-mix / 73% practice style |
| Robson-standardized rate by sector (estab-year, births-weighted) | for-profit 72.1 / nonprofit 58.0 / public 47.9 (observed 78.8 / 59.9 / 44.8) |
| Standardization removes of the 34.0pp for-profit–public gap | 9.8pp = 28.8%, matching the Kitagawa's 28% by another route |
| Dispersion ACROSS for-profit maternities, standardized | SD 14.4pp; 6.6pp survives muni×year + maternal composition + capacity (46% of raw) |
| Two for-profit maternities, same municipality-year | 13.4pp mean absolute gap in the standardized rate |
| SUS share of obstetric beds by nat_jur | public 98.8% / for-profit 22.2% (median 0) / nonprofit 72.0% |
| Weekend × SUS share of obstetric beds (for-profit) | +2.12pp (SE 1.04, p=0.041); holiday +3.37pp (SE 1.19, p=0.005) |
| Weekend × log contracted obstetrician hours | −0.16pp (SE 0.17) — a precise zero, while scale is +1.31pp*** in that column |
| Excess weekday cesareans (own-municipality benchmark) | 39,135/yr for-profit = 10.0% of weekday cesareans (national sector-year benchmark would give 50,073; do NOT mix them) |
| Same benchmark, municipality pooled over years (NOT what the code does) | 41,535/yr = 10.6% -- this is the 41.5k of the internal review; the script benchmarks municipality x YEAR, which is tighter and gives 39,135. Both are "own-municipality"; the difference is the year-specific weekend rate. Verified 2026-09-06 |
| Reconciliation of the two counterfactuals | 7.9pp gross × 463k weekday births = ~37k/yr; Eq. (3) 1.8pp × 463k = ~8k/yr |
| GKM benchmark in our units | ~0.72pp per log point of the fee gap (R$1,941 mean cesarean fee) |
| Demand smoothing, pull-forward δ | −0.21pp (SE 0.29) n.s.; forecast slope 0.065 out of sample; MDE 0.80pp |
| Demand smoothing, throughput | prelabor share → log VMR of weekly births +0.27 (p=0.065, Holm 0.196) |
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
`paper.tex` puts the bibliography FIRST and \inputs `appendix.tex` (A model +
B data) after it, per the Elsevier/JHE layout (changed 2026-07-24); the
Supplemental Appendix is a separate document.

## Conventions

- **R** with `data.table`/`arrow`/`fixest`; `pacman::p_load`. Prefer lazy
  `arrow`/`fread` column subsets over loading full files.
- Municipality key = **6-digit IBGE**; SINASC gives 7-digit → first 6.
- Figures: `theme_paper()` + `PAL`, no titles/subtitles/captions, PDF+PNG via
  `save_fig()`. **Never `scale_y_continuous(limits=)`** — it silently drops
  out-of-range points; use `breaks` or `coord_cartesian`. Multi-panel body figures
  use `patchwork`.
- **Colour accessibility (checked 2026-09-06, roadmap Part IX).** `PAL` passes
  dichromat simulation: the worst pair that ever shares a figure is red/orange at
  Delta-E 24 under tritanopia, far above the ~10 confusion threshold, so the
  palette needs no change. What it does NOT survive is greyscale: red, blue and
  grey are near-isoluminant (0.143 / 0.148 / 0.139), so a black-and-white printout
  collapses for-profit and public in Figure 1, Figure 3(a), Figure 3(b) and the
  supplement's gestational-age panels. Figures 2(b) and 3(c) already carry a
  redundant `shape`. **Fixed the same day**: `LTY` + `lty_for()` in
  `analysis/code/00_utils.R`, and every colour-only line figure now maps
  `linetype` to the SAME variable as `colour`, with the series names passed in the
  SAME order, so the two guides merge into one legend (pass them out of order and
  you get two legends). Seven figures changed -- Figure 1, Figure 3(a), Figure
  3(b), the standalone `fig02_dow_cesarean` and `fig07_hour_of_birth` (the
  single-panel versions that `11` re-draws into Figure 3, included in no `.tex`
  themselves), and the supplement's `fig03_robson_dow`, `fig08_daily_counts` and
  `fig_gestation_panels`. Scripts 01,
  03, 05, 11 were re-run (7.5 minutes total) and NO table changed a byte.
- **Figure size = printed size (`FIG_WIDTH = 6.5` in `analysis/code/00_utils.R`).**
  Both documents are 12pt `article` with 1in margins, so the text block is exactly
  6.5in and every ggplot figure is included at `width=\textwidth` (the maps at
  `0.8\textwidth` = 5.2in, and `save_map()` matches). Saving wider than the printed
  width makes `\includegraphics` scale the figure DOWN and the type with it: before
  2026-07-27 Figure 3 was saved 15in wide and printed at 6.5in, rendering its 10pt
  labels at 4.3pt. `theme_paper(base = 10)` then means exactly 10pt on the page.
  **Never widen a `\textwidth` figure past 6.5in — add a row instead of a column**
  (this is why Figure 3 is `(a|b)/c` and supplement Figure D.1 is 2x2), and keep a
  half-width panel's subtitle under ~35 characters and its legend to items that fit
  in 3.25in (wrap with `guide_legend(nrow=)`/`ncol=`, or collect the guides when
  only one panel has a legend, as Figure 2 does).
- Tables via `etable` + `dict` (full names, never abbreviate; always `dict` the
  outcome). For hand-built multi-panel tables use `tex_row`/`tex_coef`/`tex_nobs`
  from `00_utils.R`. `postprocess_tex()` (booktabs + shrink-only `\resizebox`);
  `unescape_refs()` on any table whose note cites a `\ref{}` with an underscore in
  the label. Very wide tables (≥6 cols) → `sidewaystable` (needs `rotating`).
  **This rule is about type size, not column count**: `\resizebox` is shrink-only,
  so a table wider than the 6.5in text block is scaled DOWN and its type with it,
  exactly as an over-wide figure is (see the `FIG_WIDTH` note above). Measured on
  2026-09-09, the six landscape tables are `tab08_mechanism_checks` (C.3),
  `tab13_referee_robustness` (D.1), `tab13c_dip_by_region_period` (D.2),
  `tab_org_capacity` (D.8), `tab_org_capacity_valid` (D.9) and
  `tab_ref_c5_feegap_ci` (D.14); every other table prints at 9.9-10.9pt, and the
  only upright exception is `tab14_neonatal_suggestive` (D.6) at 8.1pt, whose
  width comes from three long `dict` outcome labels and which is left alone.
  Rotation is applied as a `gsub` on the generated `.tex` right after
  `postprocess_tex()`; never convert a regression table into a figure.
- **House wording inside tables** (standardized 2026-09-09; 17 tables already
  followed it). Fixed-effect rows spell out **"fixed effects"**, never "FE"
  (the abbreviation survives only in prose, where it is a listed acronym).
  The standard-error sentence is **"Standard errors, clustered by X, are reported
  in parentheses."** -- never "SE clustered by X", and never omit the
  parentheses clause when the table shows them. **"pp" is allowed only as a
  column-header unit** (`Cesarean dip (pp)`); in any sentence write
  "percentage points". Interaction row labels are lowercase after the times sign
  (`Weekend $\times$ low obstetrician density`).
- **One note style for every exhibit in both documents** (2026-09-04). A note is
  a full-width justified block:
  `\begin{minipage}{\linewidth}\footnotesize` / `\textit{Notes:} ...` /
  `\end{minipage}`. The minipage matters: its `\@parboxrestore` cancels the
  float's `\centering`, so the note is justified instead of centred. A note
  written straight into the float as `\\[2pt]\footnotesize\textit{Notes:} ...`
  comes out **centred**, and one behind a `\par \raggedright` comes out
  **ragged** — that is what made the notes look misaligned from table to table.
  `standardize_notes(file)` in `analysis/code/00_utils.R` rewrites any of the old
  forms into the canonical block; it is idempotent, runs at the end of
  `postprocess_tex()`, and is applied to hand-built tables through
  **`write_table_tex(tx, file)`**. *Write every `.tex` table with
  `write_table_tex()`, never with bare `writeLines()`* — that is what stops a
  re-run from silently reverting the style.
- **Figure notes match the table notes.** `\fignotes` in BOTH `paper.tex` and
  `supplement.tex` is the same full-width justified minipage. **This is the
  Monasterio form**, the one his round on the sibling WorldCupHealth paper
  settled on ("padronizar o alinhamento das notas... tem umas que estao
  desalinhadas, nao justificadas"). Do not narrow it, do not wrap it in
  `\centerline`, and do not re-add `\centering`.
  ⚠️ **It was changed to a centred `0.9\textwidth` block on 2026-09-07 and
  reverted the same day, at Fredie's instruction.** The motivation for trying it
  was real (a one-line note at full width sits flush left under a centred caption
  and reads as misaligned, Figure C.2 being the example) and it is not a reason to
  try again. If it ever comes back, the change is three places that must agree:
  `NOTE_OPEN`/`NOTE_CLOSE` in `00_utils.R`, `\fignotes` in `paper.tex`, and
  `\fignotes` in `supplement.tex`, plus a migration over the 31 generated tables.
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
Borra et al. 2019; Sandall 2018 Lancet). Card, Fenizia & Silver (2023) are the
tradeoff reference, not a harm citation: higher-cesarean-propensity delivery helps
the low-risk newborn at birth and costs it later in respiratory problems. The suggestive TISS
neonatal check (`06_robustness.R` → `tab14`) is null and underpowered — keep for
transparency, do NOT feature.

## Guardrails from past revisions

Each rule below came out of a dated revision; the evidence and the full story are in
`parto_cesareo/REVISION_LOG.md` (entry date in brackets). Rules already stated in the
sections above are not repeated here.

**Data and code**
- CNES codes the Distrito Federal by administrative region (530010...530180) through
  2016 (the beds file through 2017), while IBGE, TISS and SINASC use 530010 alone.
  Recode with `fix_muni_df()` BEFORE `uniqueN()`, because counting per key and summing
  double-counts professionals with bonds in two regions. Apply it to any new
  municipality-level CNES aggregate, including `cnes_beds_muni_year` if it ever becomes
  a municipality covariate. SINASC, TISS and the establishment-level `09` need no
  recode; do not re-check them. [2026-08-10]
- In `13_demand_smoothing.R`, normalize the leave-one-out expected demand by the
  establishment's own annual mean before averaging across years; without it the
  forecast is mechanically negative for trending establishments. [2026-09-05]
- In `14_estab_practice_style.R`, Panel B's outcome is the Robson-STANDARDIZED rate.
  Regressing the observed rate on the ten Robson shares is an upper bound on case-mix
  and belongs in the note, never as a row. [2026-09-07]
- The excess-weekday count uses the own-municipality-year benchmark (39,135/yr), the
  one the text describes. Do not swap in the national sector-year benchmark. [2026-09-05]
- The state fee gap is `log(mean fee_cesarean / mean fee_vaginal_econ)` within the
  state, never the delivery-weighted mean of municipality log gaps (Jensen-biased
  toward zero). [2026-09-07 audit]
- `tab_fees` Panel B reports the wild-cluster bootstrap p for BOTH columns; `boottest`
  on the weighted levels model needs the fixed effects as formula dummies. [2026-07-16]
- `inc_pc`, `pop_total` and `esf_cov` are built into `main_data` but enter no
  regression. The fee-regression controls are exactly four (log GDP per capita, plan
  coverage, adequate prenatal care, obstetricians per 1,000 births), and the data
  section and Table C.1 must list exactly those. Do not re-add orphan rows such as
  `mean_los` or `any_uti_share` to Table C.1. [2026-09-09]

**Tables and build**
- When a text-only fix touches a generated table, apply the identical string to the R
  source AND to the generated `.tex`, so no 42M-row script needs re-running and a
  future re-run cannot revert it. [2026-08-10, 2026-09-09]
- Escape `$` as `US\$` inside R-generated table notes; a bare `$` opens math mode and
  breaks the supplement. [2026-09-05]
- No shouting caps in notes or prose; the only all-caps tokens are real acronyms
  (ICD, BH, TUSS, DOW, FP, DATASUS, UFBA, RAND). [2026-08-10, 2026-09-07 audit]
- Something external deletes `latex/*.aux`/`.log`/`.bbl` between commands. Grep the logs
  in the same command as the compile, and suspect this first if references print as
  `??`. [2026-09-04]
- One overfull hbox in `paper` (the generative-AI declaration) and one overfull box in
  `supplement` are pre-existing. Do not hunt for them as regressions. [2026-09-04]
- The working paper `Born_on_Schedule.pdf` is generated by `latex/build_wp.sh`; never
  edit it or its `.tex` by hand. Its two differences from `paper.tex` (dated title
  page, data-availability wording) live under `WP_EDITS` and fail loudly if a pattern
  stops matching. After a revision, re-run it and re-post to SSRN as a new version.
  [2026-09-09, 2026-09-14]

**Claims and citations**
- Do not reintroduce "10-15% reference range" or attribute it to `who2015cesarean`, and
  do not re-add a sentence naming the 1985 statement as its source. [2026-09-05]
- Price calibration: ~1 pp per US$1,000 is Grant (2009); Gruber-Kim-Mayzlin is about 4.
  At our fee levels that is 0.72 and 2.87 pp per log point. Calibrate against the
  larger one. `gruber1996physician` (Gruber-Owings) is the fertility/income-shock paper;
  `gruber1999physician` (GKM) is the fee-differential paper. [2026-09-07 audit]
- Cite `elejalde2021` at 8.6 pp (published JHE), not the 4.6 pp of the IZA DP. [2026-09-05]
- `card2023` is a tradeoff result, never an unqualified harm citation; `costaramon2018`
  and `borra2019` carry the harm claim. `molitor2018` finds the practice ENVIRONMENT
  explains 60-80% of regional variation. `spinola2026` studies inconvenient dates, not
  bridge days. `gans2009` does not support "holiday incentives". `fischer2026` is
  forthcoming: fill in volume and pages before submitting. [2026-09-07 audit]
- Demand-smoothing throughput (p=0.065, Holm 0.196) is never "a lumpier flow".
  [2026-09-07 audit]
- Keep the softened scope language: the paper "documents an ownership-specific
  supply-side calendar pattern consistent with scheduling", not "identifies
  supply-side scheduling". Long-weekend claims are about "ordinary fixed-date national
  holidays"; Carnival is movable and excluded, so there is no contradiction with Melo.
  [2026-07-16]
- No "policy failure" framing: the court order is an implementation failure, Parto
  Adequado an identification failure; both motivate, neither identifies. [2026-07-10]
- Figure C.4: both sectors peak at week 39; for-profit is SHIFTED earlier (40.1% vs
  26.2% at 37-38 weeks), not massed at 37-38. In-labor cesareans sit closer to
  prelabor than to vaginal; never group them with vaginal births. [2026-09-07]
- Weekend x SUS share is an association (payer mix is not assigned). Weekend x
  obstetrician hours is a precise zero: the attenuation tracks service scale, not
  measured obstetric time. [2026-09-07]
- No admission count appears in the paper, so do not re-add the admission-proxy
  sentence to Appendix B (the proxy is a build-time check only), and call the neonatal
  outcome "neonatal hospital use", not "admissions". Do not claim a fee series around
  the 2015 court order (none is plotted) or a six-hour cap on labor assistance (the
  data do not show one). "Costs" is out of the abstract only (billed amounts are near
  parity); the intro keeps it, cited. [2026-09-09]

**Settled; do not "fix" or re-audit**
- "twenty-two states" (Panel B) and "twenty-seven clusters" (Panel A) are both right:
  different samples. [2026-09-07 audit]
- There is no term/preterm split inside Robson 1-2 (those groups are term by
  definition); the term-vs-preterm contrast IS Robson 1-2 vs Robson 10. [2026-07-22]
- Figure C.4 and Table C.4 coexist legally (separate counters). [2026-09-07]
- Every `--` in the sources is a numeric range, an en-dashed compound, Elsevier's CRediT
  term or the absent-marker in fixed-effect rows; there are no em dashes to remove.
  [2026-09-07]
- Dataset citations keep their Portuguese titles. The ANS footnote keeps its inline
  `\href`; if converted, match `data_ans_tiss` in `refs.bib`. [2026-08-10, 2026-09-07]
- Verified 2026-09-07: every bib entry cited and resolving, the holiday list matches
  `holiday_dates()`, highlights under 85 characters. Re-check only what was added since.

**Prose**
- No two-to-five-word drumbeat sentences, no meta voice ("Panel B shows why", "deserves
  emphasis"), no grandiose openers, "natural" only as the clinical term, American
  spelling, "legal-entity type" (never natureza jurídica or "legal nature") in English
  text. No italics or bold in body prose (front-matter labels, CRediT names and
  in-table panel headers excepted). [2026-09-04, 2026-09-07 audit]

**Declined, do not re-litigate without new data** (reasons in
`parto_cesareo/AGENDA_CNES_VINICIUS_2026-09-07.md`): establishment versus care team (needs a
physician-to-birth link), CBO in TISS (absent from hospital files), a monthly
establishment panel (throws away the daily design). [2026-09-07]

## ACTION items for Fredie

- ~~Verify the Tita et al. (2009) early-term neonatal-morbidity magnitudes~~ —
  **done 2026-09-06.** Checked against the Europe PMC record: NEJM 360(2):111--120,
  title and pages in `refs.bib` are right; elective repeat cesarean at 37 vs 39
  weeks carries an adjusted OR of 2.1 (95% CI 1.7--2.5) for the composite adverse
  neonatal outcome and 1.5 (1.3--1.7) at 38 weeks, with respiratory morbidity,
  ventilation, sepsis, hypoglycemia and NICU admission each elevated. The body
  quotes NO magnitude from Tita, only the direction, and the direction is correct;
  nothing to change. (If a referee wants the number, the ORs are the ones to add.)
- ~~**Temperature robustness (Proof Patrol R1 C4)**~~ — **OUT OF SCOPE**, user
  decision 2026-09-05. The muni×date FE already absorb temperature common to both
  sectors; the residual threat requires the two sectors to respond *differently*
  to heat in a calendar-correlated way, which nobody has articulated. Kept as a
  referee-response item only; the execution plan survives in
  `parto_cesareo/ROADMAP.md` Part VI. Do not put it back on the critical path.
- **Reproduce end-to-end** (`config/00_master_analysis.R` in full, 13 before 10).
  The blocks touched on 2026-09-05 were re-run individually and check out, but the
  whole pipeline has not been run since. Prerequisite for the deposit checklist.
- **Deposit the replication package** (Zenodo/openICPSR) and replace the
  placeholder sentence in the Data availability section with the DOI. The package
  is assembled; `README.md` now carries the compile cycle and a deposit checklist.
  Three checklist items closed 2026-09-06: `LICENSE` (MIT, the four authors);
  `config/config.R` now ships a placeholder `DROPBOX_ROOT` and resolves the real
  path from `HEALTHECON_DATA` or from the git-ignored `config/config_local.R`
  (which is where Fredie's own path now lives), erroring out if the directory has
  no `build/`; and the two-way compile verified (37 + 27 pages, 0 undefined refs,
  0 undefined citations).
- ~~**Confirm the CRediT roles**~~ — **CLOSED 2026-09-07.** The allocation printed
  in `paper.tex` is final: Fredie (Conceptualization, Methodology, Software, Formal
  analysis, Data curation, Writing original draft, Writing review & editing);
  Vinicius, Pablo and Lucas (Conceptualization, Methodology, Writing review &
  editing). The `% TODO (Fredie)` comment has been removed and replaced with a
  note recording the confirmation. Do not reallocate roles or reopen this.
- **Elsevier declarations**: `latex/submission/declaration_of_interest.docx`
  (written 2026-09-06) carries the signed-interest form plus the funding, data
  availability, generative-AI and CRediT statements copied verbatim from
  `paper.tex`, so the entries typed into Elsevier's tool match the manuscript.
  Fredie signs and dates it.
- ~~Consider the free SSRN preprint option at submission~~ — **done 2026-09-14.**
  Posted as a working paper: <https://papers.ssrn.com/sol3/papers.cfm?abstract_id=7437660>
  (the `build_wp.sh` single-document edition). See "The 2026-09-14 revision"
  in `parto_cesareo/REVISION_LOG.md`. **Suggesting referees is out of scope** (Fredie, 2026-09-06).
