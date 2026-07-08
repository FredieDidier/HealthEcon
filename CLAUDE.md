# CLAUDE.md — HealthEcon Project Guide

## Project Overview

Empirical paper (working title *"When Money Doesn't Explain It: Physician
Convenience and the Cesarean Epidemic in Brazil's Private Health Sector"*) asking
why Brazil's private-insurance sector performs the **highest cesarean rate in the
world** — **~82% of private deliveries** (TISS), against a WHO reference of 10–15%.

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

**Author:** Fredie Didier. **Target journals:** **Journal of Health Economics**
(primary); *AEJ: Applied / JHR* as a stretch (see "Status & diagnosis").

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

### Pillar 2 — Not a price story (`02_not_a_price.R`, `06_fee_shock.R`)
Muni-year, delivery-weighted: `tiss_csection_rate ~ log_fee_gap | {UF, muni} + year`
(+ GDP pc, plan coverage, prenatal, obstetrician density). `log_fee_gap =
log(fee_cesarean / fee_vaginal_econ)`, where the **economic vaginal fee adds the
hourly labor-assistance billing** (mean ~2.7h @ ~R$409/h) — the correct incentive
comparison. Coefficient: **+0.017 (UF FE) / −0.014 (muni FE), n.s./sign-unstable**.
`06_fee_shock.R`: state-year first differences — even ±2 log-point fee-gap swings
leave the cesarean rate unchanged (a reduced-form falsification).

### Pillar 3 — The convenience mechanism (`03_scheduling.R`)
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
  in-labor cesareans** — the dip is entirely scheduled sections (the positive
  in-labor term is displacement: unscheduled women labor and some convert). Daily
  *counts*: cesarean counts crater on weekends while vaginal counts barely move
  (rules out staffing/admission composition). Robson 10 (preterm) dips less
  (−6.0), a weak placebo (preterm cesareans are also medically scheduled).
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
- **Parto Adequado** (treated = muni with a participating Fase-2 private hospital,
  CNES→IBGE mapped): with the long SINASC pre-period, the event study **rejects
  parallel pre-trends** (2010–2015 joint F=4.5, p<0.001) — treated munis are on a
  straight pre-existing downward trend (+6.8pp 2010 → −5.7pp 2024, **no break at
  2017**). Neither time-varying covariates nor a treated linear trend rescue it
  (`tab05b`): covariates leave the pre-trend rejected; the treated trend absorbs the
  "effect" entirely (+0.3pp n.s.). **Not causal evidence** — kept as a transparent
  null. TISS version is quarterly (8 pre-quarters) but the pre-window is short.
- **RN 368/2015** (transparency + partogram): national monthly series only
  (underpowered pre-period).
- **Dec-2015 SP court ruling** ordering ANS to make plans pay ≥3× for vaginal
  delivery: our fee series shows **no jump** — never became a real fee change.

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
| Writing | LaTeX (`latex/paper.tex`, JHE draft) |

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
analysis/ code/  00_utils.R (theme_paper, PAL, postprocess_tex) · 01_descriptives.R ·
                 02_not_a_price.R · 03_scheduling.R · 04_robson.R · 05_policy.R ·
                 06_fee_shock.R
          output/ {graphs, tables, maps}      committed to git
dictionary/ ANS TISS dictionaries (.xlsx) · main_data_dictionary.md
latex/    paper.tex · refs.bib   (PDF git-ignored)
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
| `treated` | Muni has a Parto-Adequado Fase-2 private hospital. | ANS list × CNES |
| `obstetricians_per_1k_births` | CNES-PF obstetrician count / SINASC births ×1000. | CNES-PF |
| `estimate_admissions_vinicius()` | Admission-count proxy (per-event qt/LOS; 2023: 9.40M vs ANS 9.2M — preferred). | build/00_utils.R |
| Full main_data codebook | `dictionary/main_data_dictionary.md` | — |

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
| `fig06_fee_shock` / `tab06_fee_shock` | 06 | Fee-gap swings vs cesarean changes | Fees don't move cesareans (falsification) |
| `fig07_hour_of_birth` / `tab07_business_hours` | 07 | Hour-of-day distribution; business-hours shares | The OR-schedule fingerprint (50% vs 29.8% benchmark) |
| `fig08_daily_counts` / `tab08_mechanism_checks` | 08 | Prelabor vs in-labor dips; daily counts; Robson-10 placebo | Dip = scheduled prelabor cesareans (−9.7 vs +1.7pp) |
| `fig09_gestation` / `fig09b` / `tab09_health` | 09 | Gestational-age distributions; early-term/LBW/Apgar gaps | Cost of convenience: +10.9pp early-term |
| `tab10_heterogeneity` / `tab10b_modality` | 10 | Dip × obstetrician density / mother's educ; cooperativas | Binds where time is scarce; supply-side |
| `tab11_decomposition` | 11 | Kitagawa (Robson) + excess weekday cesareans | 71% practice style; ~50k excess/yr private |

## Key facts / numbers (sanity checks; SINASC = 2010–2024 sample)
| Fact | Value |
|---|---|
| TISS private cesarean rate | ~82% (2023), 85%→80% over 2015–2025 |
| SINASC cesarean (all / private / nonprofit / public) | ~57% / 79% / 60% / 44% |
| Weekday cesarean % (private / nonprofit / public) | 81.9 / 62.5 / 45.0 |
| Weekend dip (private / public) | −8.3pp / −7.0pp (p<0.001) |
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
| Excess weekday cesareans (scheduling counterfactual) | ~50k/yr private (10.5%) |
| Deliveries/yr: TISS ~406k · SINASC all ~2.7M | |

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
- **Publication read:** **JHE solid**; with the full mechanism chain +
  quantification + health-cost margin, **AEJ:Policy / AEJ:Applied become a real
  (if still uphill) shot** — the bottleneck remains no sharply-timed exogenous
  shock. Not top-5.
- **Contribution:** two national datasets show the world's worst private cesarean
  epidemic is not money — it is physician time/convenience & norms (SID reframed
  as the opportunity cost of physician time), with its health cost quantified.
- **Model: DONE** (`latex/model.tex`, §"The model" above — 5 predictions all
  matched to evidence; compiles into `paper.tex`). **Pending (writing stage):**
  the introduction and prose sections — on Fredie's go.

## Conventions & working agreements
- **R** with `data.table` / `arrow` / `fixest`; `pacman::p_load` in master scripts.
  Prefer lazy `arrow` / `fread` column subsets over loading full DET/CSV in memory.
- Municipality key is **6-digit IBGE** everywhere; SINASC/basedosdados give 7-digit
  → take first 6. `code_muni` can arrive as factor → `as.integer(as.character(x))`.
- Figures: `theme_paper()` + `PAL` (no titles/subtitles/captions), saved PDF+PNG via
  `save_fig()`. **Never set `scale_y_continuous(limits=)`** — it silently drops
  out-of-range points (this erased the private line in fig02 once); use breaks only
  or `coord_cartesian`. Tables: `etable` + `dict` (clear names, no abbreviations) +
  `postprocess_tex()` (booktabs).
- **Never commit data** (`*.parquet/*.csv/*.dta/*.rds` gitignored). Commit/push only
  when asked. macOS filesystem is case-insensitive.
- When adding a variable to `main_data`, update `dictionary/main_data_dictionary.md`.
