# CLAUDE.md — HealthEcon Project Guide

## Project Overview

Empirical paper (title *"Born on Schedule: Physician Time and the World's Highest
Private Cesarean Rate"*) asking why Brazil's private sector performs the **highest
cesarean rate documented for any large health system**, against a WHO reference of
10–15%. **"Private" is measured two ways that agree** (~79–82%): insurance-financed
deliveries in **TISS** (~82%) and for-profit-establishment births (nat. jurídica
2xxx) in **SINASC** (~79%); they are overlapping, not identical, populations, and
their agreement is itself reassuring. NB: Brazil *overall* is ~57% (top-tier but not
uniquely #1 — Egypt/Dominican Republic are comparable), so the "world's highest"
claim is defensible **only for the private sector** — hence "Private" in the title
and "any large health system" in the abstract. Introduction is WRITTEN
(`latex/paper.tex`; abstract ≤100 words per AEJ; 3-paragraph literature
contribution). Appendix: **A** = model, **B** = data/variables, **C** = robustness
(tables numbered C.1–C.7 via `\numberwithin`). Citations = natbib `[round]` +
`plainnat` (Chicago author-date, matches HomeOfficePNAD). **Target = AEJ:Policy**
(guidelines: abstract ≤100w, ≤40–45pp incl. appendices, Chicago author-date,
essential material in-paper vs supplemental appendix). Style exemplar = Johnson &
Rehavi 2016 AEJ:Policy (memory `style-exemplar-johnson-rehavi`; no em-dashes,
moderate sentences).

**Core result (built and verified):**
1. **The epidemic is real and extreme** — private cesarean ~82% (TISS claims) /
   ~79% (SINASC for-profit births) vs ~44% public. Even in **Robson group 1**
   (nulliparous, term, singleton, cephalic, *spontaneous labor* — where a cesarean
   is least defensible) the private rate is **~66% on weekdays**.
2. **It is NOT a price story.** With the *economic* vaginal fee (delivery fee +
   separately-billed hourly labor assistance, TUSS 31309038), the cesarean−vaginal
   fee gap is **negative** in the big states yet they are ~80% cesarean; the fee-gap
   coefficient is small and sign-unstable across FE schemes, and large idiosyncratic
   fee swings do not move the cesarean rate.
3. **It is a physician-convenience story.** In SINASC (all births 2010–2024, exact
   date), cesareans **cluster on weekdays and dip on weekends (−8.3pp private vs
   −7.0pp public) and national holidays (−5.3 vs −3.5pp)** — the scheduling
   fingerprint of elective surgery — and the dip persists within low-risk Robson 1–2
   (**−7.4pp private**), where cesareans are least medically justified.

**Authors (in order):** Fredie Didier (IDP; corresponding, fdidier@terra.com.br),
Vinicius Mendes (UFBA, vdmendes@ufba.br), Lucas Emanuel (UFBA, lucasemanuel@ufba.br),
Pablo Castro (UFBA, pablocastro@ufba.br). The paper is written in the first-person plural ("we"). **Target journal: AEJ: Economic Policy** (primary; the
paper is written and formatted to its guidelines — abstract ≤100 words, Chicago
author-date, ≤40–45pp, essential material in-paper vs supplemental appendix).
**Journal of Health Economics is the solid fallback**; JHR/AEJ:Applied also fit.

---

## Research question & motivation

**Question:** *If relative physician fees do not explain Brazil's private cesarean
epidemic, what does — and can the economics of physician time/convenience account
for it?*

### Global importance (the descriptive hook)
Cesarean section is the most common major surgery in the world, and Brazil is its
most extreme case: **~55–61% of all births and ~80% of private-sector births are
cesarean** (this project's numbers), among the highest national rates on record. The
WHO benchmark is **10–15%**; above it, cesareans carry higher maternal morbidity/
mortality, prematurity and NICU use, and cost — a first-order public-health problem
in a country where **~25% of the population** holds private insurance.

**Sources:** Betrán et al. (2021, *BMJ Global Health*); Boerma et al. (2018,
*The Lancet*); WHO (2015), *WHO Statement on Caesarean Section Rates*; Sandall et
al. (2018, *The Lancet*) on health consequences; ANS (Mapa Assistencial; "Taxas de
partos cesáreos por operadora", https://www.ans.gov.br). Bib keys: `betran2021`,
`boerma2018`, `who2015cesarean`, `sandall2018`.

### Economic-theory lens
The frame is **physician agency / supplier-induced demand** (McGuire 2000,
*Handbook*). The canonical prediction is *financial* — providers do more of what
pays more (Gruber & Owings 1996; Gruber, Kim & Mayzlin 1999; Clemens & Gottlieb
2014 *AER*; Johnson & Rehavi 2016 on childbirth). **Our contribution inverts it
with the actual fee data**: the financial channel is *rejected*, and the binding
margin is the physician's **scarce, lumpy time** — a vaginal delivery is a long,
unschedulable on-call commitment; a cesarean is a ~1-hour scheduled procedure. We
test the time channel directly with the weekday/weekend/holiday clustering that
only exact-date data reveal, separating the money channel (TISS fees) from the
time channel (SINASC scheduling) with two national administrative datasets.

---

## The model (`latex/model.tex`, compiled into the paper)

A physician chooses between attending a vaginal delivery — which happens at a
**random time** $\tilde t$ (labor onset is uniform over the week: the identifying
assumption), lasts long ($E[\tau_v] \approx 2.7$h billed), and blocks the calendar
(on-call cost $\kappa$) — and a **prelabor scheduled cesarean**: a ~1h block at a
time of her choosing. With opportunity cost of time $w(t)$ = $w_0$ in weekday
business hours and $w_0 + \Delta$ on nights/weekends/holidays, she sections iff

$$ (f_c - f_v) + \Pi > \alpha\theta, \qquad
   \Pi \equiv E[w(\tilde t)]\,E[\tau_v] + \kappa - w_0\tau_c > 0, $$

where $\theta$ is the patient's net clinical benefit of vaginal delivery and
$\alpha$ the degree of agency. The **convenience premium $\Pi$ is positive even
when the fee gap is negative** — which is exactly what the data show. Predictions
→ evidence:

| Prediction | Evidence |
|---|---|
| **P1** fees not the operative margin ($\Pi$ dominates) | tab02, tab06 nulls; 3× court order moved nothing |
| **P2** prelabor cesareans bunch at $\arg\min w(t)$; in-labor inherit $\tilde t$ | fig02/07, tab03, tab08 (−9.7 vs **+1.7pp**) |
| **P3** dip larger where obstetricians scarce ($\Delta,\kappa$ ↑) | tab10 (−2.2pp extra) |
| **P4** booking before the wk-39 hazard → early-term excess | fig09b, tab09 (+10.9pp) |
| **P5** supply-side, not mothers' demand (education split) | tab10 |

Policy corollary: fee levers don't bind (the wedge is $\Pi$, time); levers that
reduce $\Pi$ (laborist/shift coverage, midwife continuity, scheduling norms) are
the relevant class.

## The narrative arc (how the results fit together)

1. **The fact** — Brazil's private sector runs the world's most extreme cesarean
   epidemic: ~80% of private deliveries, ~66% even among low-risk women already in
   spontaneous labor (Robson 1). *(fig01, tab01, fig03)*
2. **The usual suspect fails** — the literature's default (fee incentives, Gruber
   & Owings) is rejected three ways: the *economic* fee gap is negative in the big
   states; within-muni fee variation doesn't move the rate; large fee swings and
   even a court-ordered 3× vaginal fee changed nothing. **It is not the money.**
   *(tab02, tab06, fig06)*
3. **The mechanism** — a simple model says the binding margin is the physician's
   *time*: the cesarean converts an unschedulable, long, calendar-blocking event
   into a one-hour business-hours appointment (premium $\Pi$). Its fingerprints
   are all there: weekday/weekend/holiday clustering (~2× stronger in private),
   the 8–11am operating-room spike, and — decisively — the dip lives **entirely in
   prelabor scheduled cesareans** (+ displacement into in-labor on weekends), is
   larger where obstetrician time is scarce, and is not driven by educated
   mothers' requests. **It is the doctor's time.** *(fig02/07/08, tab03/04/08/10)*
4. **The cost** — scheduling shifts births to 37–38 weeks (+10.9pp early-term with
   maternal controls); 71% of the 35pp private–public gap is practice style, not
   case-mix; ~50k weekday cesareans/yr in the private sector are attributable to
   scheduling. **Convenience is paid in earlier births.** *(fig09, tab09, tab11)*
5. **Why the observed policy levers show no causal traction** — two precise
   statements, not a blanket "policy failed": **(a) the fee lever failed twice
   over** — the 2015 court order (3× vaginal pay) *never became an actual fee
   change* (our fee series shows no jump), and *when fees genuinely move*
   (±2 log-point state swings) cesareans still don't respond — so it failed both
   in implementation and, counterfactually, in concept; **(b) Parto Adequado is
   not "small" — it is unidentifiable**: treated municipalities were falling at
   the same pace since 2010, seven years before the program, with **no slope
   break at the 2017 onset** (adding a treated trend leaves +0.3pp n.s.). The
   decline is real; its attribution to the program is not supported. Caveat: our
   exposure is municipality-diluted (no hospital ID), so a hospital-level effect
   could be masked — but the published short-window DiD "effects" are exactly
   what a pre-trend masquerading as treatment looks like. Both facts are what the
   model predicts if the wedge is $\Pi$ (time), not $f$. *(fig04/05, tab05/05b/06)*

**One-sentence thesis:** *Brazil's private cesarean epidemic is what physician
agency looks like when the binding constraint is the doctor's time rather than
the fee schedule — the cesarean is the technology that converts an unschedulable
liability into a one-hour appointment, and mothers pay for it in earlier births.*

---

## Research Design

### Comparison groups (sector of the birth establishment)
| Group | Definition (CNES natureza jurídica) | Share of births | Cesarean |
|---|---|---|---|
| **Private (for-profit)** | 2xxx (entidades empresariais) | ~21% | **~79%** |
| Nonprofit | 3xxx (filantrópico / Santas Casas — SUS-heavy) | ~35% | ~60% |
| **Public** | else (1xxx public administration) | ~44% | ~44% |

The **headline contrast is Private (2xxx) vs Public (1xxx)**; Nonprofit is shown in
figures but excluded from the headline tests. **Do NOT lump 3xxx into private** (it
inflates the private share to ~56%). In TISS, every event is private by construction
(insurance claims). The SINASC sector flag comes from the birth-establishment CNES
(`codigo_estabelecimento`) matched to the CNES beds file.

### Pillar 1 — Descriptives (`01_descriptives.R`)
National cesarean rates by sector over time (TISS 2015–2025; SINASC 2010–2024);
muni-year summary statistics from `main_data.parquet`.

### Pillar 2 — Not a price story (`02_regressions.R`)
Muni-year, delivery-weighted: `tiss_csection_rate ~ log_fee_gap | {UF, muni} + year`
(+ GDP pc, plan coverage, prenatal, obstetrician density). `log_fee_gap =
log(fee_cesarean / fee_vaginal_econ)`, where the **economic vaginal fee adds the
hourly labor-assistance billing** (mean ~2.7h @ ~R$409/h) — the correct incentive
comparison. Coefficient: **+0.017 (UF FE) / −0.014 (muni FE), n.s./sign-unstable**.
`06_fee_shock.R`: state-year first differences — even ±2 log-point fee-gap swings
leave the cesarean rate unchanged (a reduced-form falsification).

### Pillar 3 — The convenience mechanism (`03_mechanisms.R`)
SINASC muni × date × sector cells, 2010–2024: `cesarean_share ~ weekend + holiday +
eve | muni + year`, weighted by births, **two-way clustered by muni AND date**
(weekend/holiday are date-level shocks; SEs virtually unchanged vs muni-only),
estimated separately by sector. Robust to excluding 2020 (COVID; −8.1pp) and to
dropping weights (−9.5pp). **Identification:** the day of the week is as-good-as-random w.r.t. medical
need, so weekday clustering is a credible causal statement about *timing driven by
convenience*. Movable holidays (Carnival, Good Friday, Corpus Christi) computed from
the Easter algorithm. Results: weekend **−8.3pp private / −7.0 public**; holiday
**−5.3 / −3.5**; eve-of-rest-day small negative (avoidance, no pull-forward bunching).

### Pillar 4 — Low-risk (Robson) cesareans (`04_robson.R`)
Same weekend spec within **Robson groups 1–2** (nulliparous, term, singleton,
cephalic; group 1 = spontaneous labor): weekend dip **−7.4pp private / −5.0 public**;
Robson 1 private alone **−6.5pp**. `tipo_robson` is zero-padded ("01".."11") and
populated from ~2014 on.

### Mechanism reinforcement & quantification (`07`–`11`)
- **Hour of birth** (`07_hours.R`): cesareans crater overnight and spike at 8–11am
  (the operating-room schedule); vaginal births are nearly uniform around the
  clock. **50% of cesareans happen in weekday business hours vs a 29.8%
  uniform-timing benchmark** (vaginal ~32%).
- **Prelabor split** (`08_mechanism_checks.R`, `cesarea_antes_parto`): the private
  weekend dip is **−9.7pp for prelabor (scheduled) cesareans and +1.7pp for
  in-labor cesareans** — the AGGREGATE dip is concentrated in scheduled sections
  (the positive in-labor term is displacement: unscheduled women labor and some
  convert). **CAVEAT (referee C3, verified 2026-07-09):** do NOT write "the ENTIRE
  dip is prelabor." Robson 1 (spontaneous labor) has prelabor=0 by construction,
  yet its private weekend dip is −6.5pp (all in-labor) — so intrapartum
  decision-making / weekend selection ALSO drives a dip; the mechanism is broader
  than pure prelabor scheduling. Prelabor-indicator missingness ~16%, balanced
  weekday vs weekend (0.1604 vs 0.1609 private), so the split is not an artifact.
  Daily *counts*: cesarean counts crater on weekends while vaginal counts barely
  move (rules out staffing/admission composition). Robson 10 (preterm) dip
  (−5.9/−6.0) is **NOT statistically distinguishable** from the Robson-1 dip
  (interaction p=0.18) → the preterm "placebo" is weak; the "dips far less" claim
  was REMOVED from the paper.
- **The cost of convenience** (`09_gestation_health.R`): private births are
  **+10.9pp more likely to be early-term (37–38 wk)** with maternal controls
  (age, education, race) + muni/year FE — the gestational-age shift that prelabor
  scheduling mechanically produces (fig09b: prelabor cesareans mass at 37–38 wk).
  Private shows *lower* low-birthweight/low-Apgar (better-resourced hospitals +
  selection) — report honestly, the health margin is early-term shifting.
- **Theory-driven heterogeneity** (`10_heterogeneity.R`): weekend dip is **2.2pp
  larger where obstetricians are scarce** (below-median per-1k-births — higher
  opportunity cost of unschedulable time, the model's cross-sectional prediction).
  The dip is NOT concentrated among educated mothers (argues supply-side, not
  patient demand). Cooperativa (physician-owned) operators: +1.0pp n.s.
- **Quantification** (`11_decomposition.R`): Kitagawa over Robson groups — the
  **35.4pp private–public gap = 29% case-mix + 71% practice style**. Scheduling
  counterfactual (weekend rate as benchmark): **~50k excess weekday cesareans/yr
  in the private sector** (~10.5% of private cesareans; ~73k public).

### Supporting nulls (kept for rigor, NOT identification) (`05_policy.R`)
Institutional scope of each policy (be precise in the paper):
- **Parto Adequado** — **national program** run by the ANS (federal regulator) with
  Hospital Israelita Albert Einstein and the IHI, but **adoption is voluntary and
  hospital-level**: Phase 1 pilot 2015–16 (35 hospitals), **Phase 2 2017–2021 (our
  list: 113 hospitals in 60 municipalities across ~15 states)**, Phase 3 national
  campaign (no hospital list). Treated = muni with a participating Fase-2 private
  hospital (CNES→IBGE). With the long SINASC pre-period, the event study **rejects
  parallel pre-trends** (2010–2015 joint F=4.5, p<0.001) — treated munis are on a
  straight pre-existing downward trend (+6.8pp 2010 → −5.7pp 2024, **no break at
  2017**). Neither time-varying covariates nor a treated linear trend rescue it
  (`tab05b`). **Not causal evidence** — kept as a transparent null. TISS version is
  quarterly (8 pre-quarters) but the pre-window is short.
- **RN 368/2015** — **national**: an ANS normative resolution binding on ALL
  private health plans in Brazil (in force July 2015; right to operator/hospital/
  physician cesarean rates on request, mandatory partogram, informed-consent term
  for elective cesareans). National and single-dated → only an underpowered
  monthly time series, no cross-sectional contrast.
- **Dec-2015 court ruling** — decision by the **Federal Court in São Paulo**
  (ação civil do Ministério Público in SP) ordering the **ANS — a national
  regulator — to issue rules** making plans pay ≥3× more for vaginal delivery
  (60-day deadline, R$10k/day fine). So: issued by a court in SP, but aimed at a
  **national** fee rule; ANS appealed and **it never became an actual fee change**
  — our fee series shows no jump in the cesarean−vaginal gap in 2015–16.
- **RN 465/2021** — **national** (ANS coverage list update; elective cesarean
  covered upon signed consent). Context only, not used for identification.

---

## Sample

| Dataset | Unit | Coverage | N |
|---|---|---|---|
| SINASC births (`sinasc_births.parquet`) | birth | 2010–2024, all Brazil | ~42M |
| SINASC daily (`sinasc_daily_muni.parquet`) | muni × date × sector | 2010–2024 | ~8.6M rows |
| TISS deliveries (`delivery_events_<yr>.parquet`) | delivery | 2015–2025 | ~406k/yr |
| TISS panel (`delivery_panel_muni_month.parquet`) | muni × month | 2015–2025 | ~88k rows |
| **`main_data.parquet`** (the analytical file) | muni × year | 2015–2025 | 11,567 rows |

Standard filters: analysis uses `year <= 2024` (2025 TISS is partial); muni-year
fee regressions require `tiss_deliveries >= 20`; muni-date cells require
`births > 0` (Robson cells `>= 10` where noted). Rows with missing provider
municipality (~0.06% of TISS) are dropped in the build.

---

## Stack

| Layer | Tools |
|---|---|
| Download | R (`arrow` for ANS FTP TISS; **Base dos Dados**/BigQuery for SINASC; `datazoom.saude` for CNES beds; `microdatasus` for CNES-PF) |
| Build & analysis | R (`data.table`, `arrow`, `fixest`, `ggplot2`) |
| Writing | LaTeX (`latex/paper.tex`, AEJ:Policy draft) |

## Repository layout
```
config/   config.R (DROPBOX_ROOT — the only per-machine edit)
          00_master_build.R · 00_master_analysis.R
build/    00_utils.R          admission proxies + TUSS delivery codes
          01a_tiss.R          one-time ANS TISS downloader (CONS+DET)
          01b_sinasc_cnes.R   one-time SINASC (Base dos Dados) + CNES downloads/ingest
          01c_ieps.R          IEPS muni-year covariates
          02_deliveries.R     TISS delivery events + muni-month panel
          03_workfile.R       → main_data.parquet
analysis/ code/  00_utils.R (theme_paper, PAL, postprocess_tex) · 01_descriptives.R
                 (trends/stats/hours/maps) · 02_regressions.R (price channel) ·
                 03_mechanisms.R (scheduling/Robson/prelabor/decomposition) ·
                 04_heterogeneity.R · 05_cost.R · 06_robustness.R (policy nulls,
                 referee checks, permutation, neonatal). NB: scripts were consolidated
                 (2026-07-09) from 15 per-exhibit files into 6 thematic ones; each
                 file is a concatenation of self-contained sections (each re-loads
                 config + utils + its own data), so the "Script" column below (01–15)
                 now names the SECTION/theme, not a standalone file.
          output/ {graphs, tables, maps}      committed to git
dictionary/ ANS TISS dictionaries (.xlsx) · main_data_dictionary.md
latex/    paper.tex · model.tex (Appendix A) · appendix.tex (Appendix A input +
          Appendix B data/variables) · sup_appendix.tex (Supplemental Appendix C
          robustness) · refs.bib   (PDF git-ignored). paper.tex \inputs appendix.tex
          then sup_appendix.tex after \appendix.
CLAUDE.md · README.md · .gitignore · HealthEcon.Rproj
```

## Data (Dropbox, not git)
```
<DROPBOX_ROOT>/build/
  TISS/input/Hospitalar/{CONS,DET}/Hosp_<yr>_<type>.parquet   raw ANS claims 2015–2025
  TISS/input/Planos/PLANOS.csv · TISS/input/auxiliares/       lookups
  TISS/output/delivery_events_<yr>.parquet · delivery_panel_muni_month.parquet
  SINASC/input/sinasc_births.parquet · sinasc_daily_muni.parquet
  CNES/input/cnes_beds_muni_year.parquet · cnes_obstetricians_muni_year.parquet
  IEPS/input/ieps.csv (manual export) · IEPS/output/ieps_muni_year.parquet
  covariates/input/parto_adequado_fase2_hospitais.csv         113 hospitals (ibge6/7)
  workfile/output/main_data.parquet                           THE analytical file
```
Data sources & links: ANS TISS PDA (`https://dadosabertos.ans.gov.br/FTP/PDA/TISS/`);
SINASC via Base dos Dados (`https://basedosdados.org/dataset/48ccef51-8207-40ee-af5b-134c8ac3fb8c`,
targeted 24-column query in `01b_sinasc_cnes.R`); IEPS (`https://iepsdata.org.br`);
Parto Adequado Fase-2 hospital list scraped from the ANS PDF (snapshot 11/02/2019,
113 hospitals = 87 private + 26 public in 60 munis):
`https://www.gov.br/ans/pt-br/arquivos/assuntos/prestadores/parto-adequado-1/projeto_parto_adequado_fase_2_hospitais_participantes.pdf`.
Phases: 1 pilot 2015–16 (35 hospitals); **2 dissemination 2017–2021 (this list)**;
3 national campaign (no discrete hospital list).

## Key variables

| Variable | Description | Source |
|---|---|---|
| `cesarean` | =1 if delivery/birth is cesarean. TISS: TUSS 31309054/31309208 (vs vaginal 31309127). SINASC: `tipo_parto == 2`. | TISS DET / SINASC |
| `sector` / `private` | Birth-establishment sector: Private (nat_jur 2xxx) / Nonprofit (3xxx) / Public. `private` = Private only. | SINASC×CNES |
| `fee_vaginal_econ` | Economic vaginal fee = vaginal delivery fee + hourly labor-assist billing (31309038). The correct incentive benchmark. | TISS DET |
| `log_fee_gap` | log(fee_cesarean / fee_vaginal_econ) — the incentive shifter. Negative in big states. | TISS |
| `tiss_csection_rate` / `sinasc_private_csection_rate` | Private cesarean shares (claims / births). | main_data |
| `tipo_robson` | Robson group "01".."11" (01–02 = low risk; 01 = spontaneous labor). From ~2014. | SINASC |
| `dow`, `weekend`, `holiday`, `eve` | Day-of-week (1=Sun), weekend, national holiday (fixed + Easter-based movable), eve-of-rest-day. | derived |
| `treated_parto_adequado` | Muni has a Parto-Adequado Fase-2 private hospital (58 munis; in `main_data` via `03_workfile.R`). | ANS list × CNES |
| `obstetricians_per_1k_births` | CNES-PF obstetrician count / SINASC births ×1000. | CNES-PF |
| `estimate_admissions_vinicius()` | Admission-count proxy (per-event qt/LOS; 2023: 9.40M vs ANS 9.2M — preferred; Fredie's aggregate method 8.89M). **No exhibit depends on either proxy** (deliveries are TUSS-identified), so it needs no robustness table — it is a data-validation tool. | build/00_utils.R |
| Full main_data codebook | `dictionary/variable_dictionary.xlsx` (regenerate via `dictionary/build_dictionary.R`) | — |

## Results guide & exhibit map

| Exhibit | Script | Content | Takeaway |
|---|---|---|---|
| `fig01_csection_trend` | 01 | Cesarean rate by sector, TISS + SINASC over time | Epidemic: private ~80% vs public ~44%, stable |
| `tab01_descriptives` | 01 | Muni-year summary stats | Sample overview |
| `tab02_not_a_price` | 02 | csection ~ log_fee_gap, 4 FE/controls specs | Fee gap doesn't explain it (sign-unstable, tiny) |
| `fig02_dow_cesarean` | 03 | Cesarean % by day-of-week × sector | Weekday clustering, ordered by sector |
| `tab03_scheduling` | 03 | Weekend/holiday/eve dips, public vs private | Convenience fingerprint, ~2× in private |
| `fig03_robson_dow` | 04 | Day-of-week within Robson 1–2 | Persists among low-risk births |
| `tab04_robson` | 04 | Weekend dip, Robson 1–2 & Robson 1 | −7.4pp private (low risk) |
| `fig04_parto_adequado_es_sinasc` | 05 | Event study 2010–2024, treated munis | **Pre-trend, no 2017 break — not causal** |
| `fig04b_parto_adequado_es_tiss` | 05 | Quarterly TISS event study | Same, short pre-window |
| `tab05_parto_adequado` / `tab05b` | 05 | DiD + covariate/trend robustness | Null is robust; trend absorbs "effect" |
| `fig05_rn368_timeline` | 05 | National monthly series 2010–2024 | RN 368 context |
| `tab06_fee_shock` | 06 | Fee-gap swings vs cesarean changes | Fees don't move cesareans (falsification). NB: the companion scatter `fig06_fee_shock` was REMOVED (redundant with the table); its plotting code is deleted from `06_fee_shock.R` and the PDF/PNG are gone. |
| `fig07_hour_of_birth` / `tab07_business_hours` | 07 | Hour-of-day distribution; business-hours shares | The OR-schedule fingerprint (50% vs 29.8% benchmark) |
| `fig08_daily_counts` / `tab08_mechanism_checks` | 08 | Prelabor vs in-labor dips; daily counts; Robson-10 placebo | Dip = scheduled prelabor cesareans (−9.7 vs +1.7pp) |
| `fig09_gestation` / `fig09b` / `tab09_health` | 09 | Gestational-age distributions; early-term/LBW/Apgar gaps | Cost of convenience: +10.9pp early-term |
| `tab10_heterogeneity` / `tab10b_modality` | 10 | Dip × obstetrician density / mother's educ; cooperativas | Binds where time is scarce; supply-side |
| `tab11_decomposition` | 11 | Kitagawa (Robson) + excess weekday cesareans | 71% practice style; ~50k excess/yr private |
| `map01_csection_all` / `map02_csection_private` | 12 | Municipal choropleths (2020–24; navy→sand→red gradient) | Geography: North low, Center-South/private high |
| `tab13_referee_robustness` | 13 | Time-varying sector (−7.7); Sunday-only (−10.8); rest days (−8.1); weekend newborn composition (+1.3pp LBW, +0.19pp low Apgar) | Scheduling result robust; weekend births are the unscheduled, riskier ones |
| `tab13b_beneficiary_muni` | 13 | Not-a-price with BENEFICIARY-muni aggregation | Fee-gap null replicates (+0.029 n.s. / −0.013) |
| `tab13c_dip_by_region_period` | 13 | Clean clinical sample (cephalic, singleton, term, no prior CS): **−8.9**; all 5 regions (−6.7 to −10.7); 3 periods (−8.1/−7.8/−7.6) | Dip survives strictest clinical cleaning; national and stable |
| `tab14_neonatal_suggestive` | 14 | Infant ICD-P admissions per private birth vs early-term share (muni-year) | **Null, underpowered** — do NOT feature; harm pricing stays literature-based |
| `tab15_permutation` | 15 | Weekend dip vs all 21 two-day placebos | True weekend −8.11pp = **most negative of 21** (rank 1/21, exact p=0.048) |
| `tab15b_no_indication` | 15 | Share of private cesareans with no indication CID | **~88–91%** have only a delivery-outcome code, rising over time |

## Key facts / numbers (sanity checks; SINASC = 2010–2024 sample)
| Fact | Value |
|---|---|
| TISS private cesarean rate | ~82% (2023), 85%→80% over 2015–2025 |
| SINASC cesarean (all / private / nonprofit / public) | ~57% / 79% / 60% / 44% |
| Weekday cesarean % (private / nonprofit / public) | 81.9 / 62.5 / 45.0 |
| Weekend dip (private / public) | −8.3pp / −7.0pp (p<0.001) |
| **Private-SPECIFIC increment (pooled DiD, muni×sector + date FE)** | **weekend −1.6pp*** (SE .0053) / holiday −2.1pp*** (SE .0044)** — the number that survives the sector-contrast test (referee C2). Most of the 8.3pp is common to both sectors; this is the honest headline. |
| Holiday dip (private / public) | −5.3pp / −3.5pp (p<0.001) |
| Robson 1–2 weekend dip (private / public) | −7.4pp / −5.0pp; Robson 1 private −6.5pp |
| Economic fee gap (big states) | negative (~−8 to −25%) |
| `log_fee_gap` coef (UF / muni FE) | +0.017 / −0.014 (n.s.) |
| Parto Adequado pre-trend test | F=4.48, p=0.00016 → rejected |
| Cesareans in weekday business hours (vs uniform 29.8%) | ~50% (vaginal ~32%) |
| Weekend dip: prelabor vs in-labor cesareans (private) | −9.7pp vs **+1.7pp** |
| Early-term (37–38wk) private gap, with maternal controls | +10.9pp*** |
| Weekend dip × low obstetrician density | −2.2pp** extra |
| Kitagawa: private–public gap 35.4pp | 29% case-mix, **71% practice style** |
| Clean clinical sample weekend dip (cephalic/singleton/term/no prior CS) | −8.9pp*** |
| Weekend dip by region / by period | all regions −6.7 to −10.7; stable −8.1/−7.8/−7.6 |
| Beneficiary-muni fee-gap coef (UF / muni FE) | +0.029 n.s. / −0.013 (null replicates) |
| Excess weekday cesareans (scheduling counterfactual) | ~50k/yr private (10.5%) |
| Total billed cost per delivery (cesarean vs vaginal, TISS 2015–24, trimmed) | R$6,739 vs R$6,743 mean (gap −R$5, −0.1%); median R$5,417 vs R$5,178 (+R$238, +4.6%) → **near-parity** |
| Deliveries/yr: TISS ~406k · SINASC all ~2.7M | |

## Financial cost (built 2026-07-09, `tab12_cost` / Table 10)
`build/02_deliveries.R` now sums ALL DET items per delivery event →
**`total_billed`** (event-level, in `delivery_events_<yr>.parquet`; the muni-month
panel also gets `cost_cesarean`/`cost_vaginal`). It is the CHARGED/informed value
(`VL_ITEM_EVENTO_INFORMADO`, summed directly — VL is the line total; do NOT ×QT,
which overcounts ~50×), not the price paid. Result: a cesarean and a vaginal
delivery bill **almost the same total** → reinforces "not a price" at the payer
level and locates the epidemic's cost in health (early-term), not billing.
`05_cost.R` regenerates `tab12_cost.tex` (skips gracefully if `total_billed`
absent). **Dictionary:** `total_billed` is event-level, NOT in `main_data`, so the
`main_data` codebook (`dictionary/build_dictionary.R`) needs no change; only add it
if cost is ever pulled up to `main_data`. **Map added:** `map02_csection_private`
is now Figure 2 (Background). **ACTION FOR FREDIE:** verify the Tita et al. (2009)
neonatal-morbidity gradient numbers used in the back-of-envelope in the Cost
section ("roughly one half to one hundred percent" increase at 37–38 vs 39 wk) —
I stated it conservatively but the exact figures should be checked against the paper.

## Clinical-cost positioning ("why does convenience matter?")
Deliberate scope decision (2026-07-08): we do **NOT** build new empirical programs
on maternal mortality/complications, NICU admission, or broad neonatal morbidity.
Three reasons: (i) **selection dominates** — private mothers are healthier and
private hospitals better resourced, so cross-sector outcome regressions come out
"wrong-signed" (we already see LOWER low-birthweight/low-Apgar in private:
tab09) and would hand referees our weakest front; (ii) **power** — maternal deaths
(~1.5–2k/yr nationwide) cannot support muni-date designs, and there is no public
mother–baby linkage for individual follow-up; (iii) the causal harm of
non-indicated cesareans/early-term birth is **already established with better
identification than we could achieve** — cite it, don't re-estimate it.
**How the paper answers "why it matters":** (a) our own early-term result
(+10.9pp at 37–38wk, the margin mechanically produced by prelabor scheduling —
tab09/fig09b) + weekend-composition corroboration (tab13); (b) magnitudes (~50k
excess weekday cesareans/yr; 71% practice style — tab11); (c) **price the harm
with the literature**: Tita et al. (2009 *NEJM*, early-term elective cesarean →
neonatal respiratory morbidity/NICU), Costa-Ramón et al. (2018 *JHE*, unplanned
cesareans harm neonatal health), Card, Fenizia & Silver (2023 *AEJ:Policy*,
cesareans for marginal low-risk mothers worsen outcomes), Sandall et al. (2018
*Lancet*). The suggestive TISS check WAS implemented (`14_neonatal_suggestive.R`, tab14):
infant (<1) admissions with ICD-10 chapter-P primary diagnoses per private
birth, muni-year, vs the share of private births at 37–38 weeks. **It came out
null and is underpowered by design** (newborn admissions are billed under the
mother's plan in the first 30 days with uneven coding; provider-muni vs
occurrence-muni mismatch; little within-muni variation in early-term share
after FE). Keep the table for transparency but do NOT feature it — the harm
pricing stays literature-based, which was the plan.

**Why 09(b) is associational and what causal would take:** `private` (sector of
birth) is chosen — mothers differ in unobserved pregnancy health, income and
preferences; muni/year FE + age/education/race controls cannot absorb that
selection. (Direction: healthier private mothers should if anything carry
LONGER, biasing the early-term gap toward zero, so +10.9pp is plausibly
conservative — an argument, not identification.) Causal upgrades would need:
(i) **mother fixed effects** (same mother across sectors) — requires identified
SINASC linkage (CIDACS/Fiocruz 100M-cohort style data agreement; no public
mother ID); (ii) **IV for private access** — local formal-employment/plan-loss
shocks (shift-share), exclusion debatable; (iii) Costa-Ramón-style timing
instruments identify the cesarean→health effect, not the sector→early-term
effect. With public de-identified data it stays associational by design.

## Honest limits (the identification ceiling)
No operadora/hospital/physician IDs in TISS (rules out bargaining, vertical
integration, within-physician designs); paid prices ~5% populated (charged only);
no enrollment/premium panel (weak selection/demand); TISS monthly (SINASC supplies
the daily grain); no clean differentially-timed policy shock found (Parto Adequado
fails parallel trends; fee shocks null; RN 368 national with short pre-period).

## Project status & diagnosis (2026-07-08, after the mechanism build-out)
**Has a future? Yes — and stronger than the first diagnosis.**
- **Causal/credible:** the descriptive facts; the "not a price" falsification;
  the convenience mechanism — now a *chain*: weekday/weekend/holiday clustering →
  hour-of-day OR-schedule fingerprint → entirely driven by **prelabor (scheduled)
  cesareans** (in-labor dips ~zero/positive) → persists in low-risk Robson 1–2 →
  larger where obstetrician time is scarce → not concentrated among educated
  mothers (supply-side). Quantified: 71% of the private–public gap is practice
  style; ~50k excess weekday cesareans/yr; +10.9pp early-term shifting (the cost).
- **Not causal (honest nulls):** Parto Adequado (pre-trends), fee shocks.
- **Publication read:** **target AEJ: Economic Policy** — the full mechanism chain
  + quantification + health-cost margin + honest policy nulls make it a real (if
  uphill) shot; the bottleneck is no sharply-timed exogenous shock. **JHE is the
  solid fallback.** Not top-5.
- **Contribution:** two national datasets show the world's worst private cesarean
  epidemic is not money — it is physician time/convenience & norms (SID reframed
  as the opportunity cost of physician time), with its health cost quantified.
- **Model: DONE** (`latex/model.tex`, §"The model" above — 5 predictions all
  matched to evidence; Appendix A of `paper.tex`).
- **Full paper draft: DONE (2026-07-08; revised 2026-07-09)** — `latex/paper.tex`
  compiles clean (bibtex, 0 undefined refs, 0 overfull hboxes, ~31 pp). Sections:
  Intro, Background, Data, **Empirical strategy** (new — presents the two core
  estimating equations `eq:feegap` (fee/price channel) and `eq:scheduling`
  (weekend/holiday timing channel), plus the identification logic; table notes now
  reference these via `\eqref`), Not-a-price, Mechanism, Cost, Policy, Conclusion
  (expanded with a grounded "what policy could work" discussion — laborist/shift
  coverage, salaried/integrated vs private-office FFS, outcome-based regulation —
  cited to finkelstein2016/molitor2018/cutler2019/clemens2014/alexander2020/card2023).
  Appendix has a centered "Appendix" divider before Appendix A (the model).
  **Figure 2 (`fig06_fee_shock`) was removed** (redundant with tab06). Prose in
  AEJ voice, no em-dashes (paper.tex AND model.tex clean). Acronyms defined on
  first use with the Portuguese name + English gloss (ANS, SUS, TISS, SINASC=MoH
  registry, CNES, IEPS=consolidates multi-source data into a muni-year panel;
  covariates listed). Body-section \input paths use ../analysis/output/... (compile
  from latex/). refs.bib = 24 entries (added dranove1988, grant2009, alexander2020,
  epstein2009, finkelstein2016, molitor2018, cutler2019, curriemacleod2016,
  dickertconlin1999, gans2009, borra2019).
- **Table-note house standard (matches HomeOfficePNAD):** every regression-table
  note opens with "Estimates of Equation~\eqref{eq:...}." (or a first-difference/
  placebo variant), states sample + weights + variable/units, then "Standard
  errors, clustered by <geog>, are reported in parentheses." and ends
  "Significance levels: *** p$<$0.01, ...". `SIGNIF_NOTE` in `analysis/code/00_utils.R`
  carries the "Significance levels:" phrasing. Figure `\fignotes` uses `\centerline`
  + a 0.85\textwidth minipage with only `\vspace{1pt}` so notes sit tight and
  centered under the title.

## Conventions & working agreements
- **R** with `data.table` / `arrow` / `fixest`; `pacman::p_load` in master scripts.
  Prefer lazy `arrow` / `fread` column subsets over loading full DET/CSV in memory.
- Municipality key is **6-digit IBGE** everywhere; SINASC/basedosdados give 7-digit
  → take first 6. `code_muni` can arrive as factor → `as.integer(as.character(x))`.
- Figures: `theme_paper()` + `PAL` (no titles/subtitles/captions), saved PDF+PNG via
  `save_fig()`. **Never set `scale_y_continuous(limits=)`** — it silently drops
  out-of-range points (this erased the private line in fig02 once); use breaks only
  or `coord_cartesian`. Tables: `etable` + `dict` (clear names, **never
  abbreviate** — full column/variable names; always `dict` the outcome so it is not
  a bare var name like "rate"), no numeric `headers=c("(1)"...)` (etable already
  prints a Model number row — passing them duplicates it), use `extralines` for
  column attributes; `postprocess_tex()` (booktabs + shrink-only `\resizebox` via
  `resize_tabular()`). Very wide tables (≥6 cols: tab08, tab13c) are typeset
  `landscape` (`sidewaystable`, needs `\usepackage{rotating}`) with `resize=FALSE`.
  Figures: the `\caption{}` holds ONLY the short bold title; the notes go on a
  separate block below it via the `\fignotes{...}` macro (defined in `paper.tex` —
  small, `\textit{Notes:}` lead-in, centered in a 0.85\textwidth minipage so the
  block sits balanced under the figure). Do NOT fold notes back into `\caption{}`
  (that produced a run-on "title Notes: ..." blob). Keep exhibits in English (no
  `natureza jur\'idica` etc.). NB: several committed `.tex` tables have been
  hand-edited after generation and diverge from their R sources (e.g. "legal
  nature" in the `.tex` vs "natureza jur\'idica" still in `13_referee_robustness.R`);
  the `.tex` files are the source of truth for the paper, so when re-running an
  analysis script re-check its table against the committed `.tex`.
- **Never commit data** (`*.parquet/*.csv/*.dta/*.rds` gitignored). Commit/push only
  when asked. macOS filesystem is case-insensitive.
- When adding a variable to `main_data`, update `dictionary/build_dictionary.R`
  and re-run it (regenerates `variable_dictionary.xlsx`, HomeOfficePNAD format).
