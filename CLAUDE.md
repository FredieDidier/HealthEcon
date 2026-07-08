# CLAUDE.md — HealthEcon Project Guide

## Project Overview

Empirical paper (working title *"When Money Doesn't Explain It: Physician
Convenience and the Cesarean Epidemic in Brazil's Private Health Sector"*) on why
Brazil's private-insurance sector performs the **highest cesarean rate in the
world** — **~82% of private deliveries** (TISS), against a WHO reference of 10–15%.

**Core result (built and verified, 2026-07-07):**
1. **The epidemic is real and extreme** — private cesarean ~82% (TISS claims) /
   ~79% (SINASC for-profit private births) vs ~44% public, national, 2015–2024.
   Even in **Robson group 1** (nulliparous, term, singleton, cephalic, in
   *spontaneous labor* — where a cesarean is least defensible) the private rate is
   **~66% on weekdays**.
2. **It is NOT a price story.** Once the vaginal fee includes the separately-billed
   hourly labor assistance (TUSS 31309038), the *economic* cesarean−vaginal fee gap
   is **negative** in the big states (cesarean pays less) yet they are ~80% cesarean;
   in muni-year regressions `csection_rate ~ log_fee_gap | FE` (+controls) the
   coefficient is **small and sign-unstable** (+0.017 UF-FE / −0.014 muni-FE, n.s.).
3. **It is a physician-convenience story.** In SINASC (all 27M births, exact date),
   cesareans **cluster on weekdays and dip on weekends and holidays** — the scheduling
   fingerprint of elective surgery — and the dip is larger in the for-profit private
   sector (weekend **−8.0pp private vs −6.6pp public**; holiday **−5.1 vs −3.4pp**;
   muni+year FE, p<0.001). It persists even within low-risk Robson 1 (**−5.9pp
   private**), where cesareans are least medically justified.

**Sector definition (SINASC/CNES):** birth-establishment natureza jurídica 2xxx →
**Private (for-profit)** (~21% of births, ~79% cesarean); 3xxx → **Nonprofit**
(filantrópico/Santas Casas, SUS-heavy, ~60%); else **Public** (~44%). Do NOT lump
3xxx into private (it inflates the private share to ~56%). Headline contrast uses
Private (2xxx) vs Public (1xxx).

**Author:** Fredie Didier. **Target journals:** **Journal of Health Economics**
(primary — the honest, achievable home); **AEJ: Applied / Journal of Human
Resources** as a stretch if the identification is tightened with a sharp shock.
QJE/AER is aspirational, gated by the identification ceiling of de-identified,
price-poor, monthly claims (see "Honest limits").

---

## Research question & motivation

**Question:** *If relative physician fees do not explain Brazil's private cesarean
epidemic, what does — and can the economics of physician time/convenience account
for it?*

### Global importance (the descriptive hook)
Cesarean section is the most common major surgery in the world, and Brazil is its
most extreme case: **~55–57% of all births and ~80% of private-sector births are
cesarean** (this project's numbers), among the highest national rates on record. The
WHO benchmark is **10–15%**; above it, cesareans carry higher maternal morbidity/
mortality, prematurity and NICU use, and cost — a first-order public-health and
health-spending problem in a country where **~25% of the population** holds private
insurance. Measuring it at national scale in the *private* sector — where the
incentives are sharpest and the data have never been assembled this way — is itself
a contribution.

**Sources for these claims:**
- **Global/Brazil cesarean rates:** Betrán et al. (2021), *BMJ Global Health*
  ("Trends and projections of caesarean section rates"); Boerma et al. (2018),
  *The Lancet* ("Global epidemiology of use of and disparities in caesarean
  sections"). Brazil consistently in the top handful of countries.
- **WHO 10–15% reference:** WHO (2015), *WHO Statement on Caesarean Section Rates*.
- **Health consequences of overuse:** Sandall et al. (2018), *The Lancet* ("Short-
  term and long-term effects of caesarean section on the health of women and
  children").
- **~80% private cesarean & ~25% private coverage:** ANS — Agência Nacional de
  Saúde Suplementar (Mapa Assistencial da Saúde Suplementar; "Taxas de partos
  cesáreos por operadora", https://www.ans.gov.br), corroborated here in TISS/SINASC.

  (Bib keys in `latex/refs.bib`: `betran2021`, `boerma2018`, `who2015cesarean`,
  `sandall2018`.)

### Economic-theory lens (matching the top-journal literature)
The natural frame is **physician agency / supplier-induced demand (SID)**: the
physician is an imperfect agent who can tilt the treatment decision (McGuire 2000,
*Handbook of Health Economics*). The canonical prediction is *financial* — providers
do more of what pays more (Gruber & Owings 1996; Gruber, Kim & Mayzlin 1999 on
cesarean fees; Clemens & Gottlieb 2014 *AER*; Johnson & Rehavi 2016 *AER*,
"Physicians treating physicians," on childbirth and information asymmetry).

**Our contribution turns this literature on its head with the actual fee data:** the
financial-SID channel is *rejected* — cesareans dominate even where they pay less —
and the binding margin is the physician's **scarce, lumpy time**: a vaginal delivery
is a long, unschedulable, on-call commitment; a cesarean is a ~1-hour scheduled
procedure. This reframes SID as a story about the **opportunity cost of physician
time and the value of scheduling/convenience**, not fees — and we *test* it directly
with the weekday/weekend clustering that only exact-date data can reveal. This
connects SID to the economics of physician labor supply and non-price rationing, and
uses two national administrative datasets to separate the money channel (TISS fees)
from the time channel (SINASC scheduling).

---

## Research design (three pillars + supporting reduced form)

1. **Descriptive** (`analysis/code/01_descriptives.R`) — the epidemic over
   2015–2024: TISS private vs SINASC private vs public cesarean rates; the enormous
   gap to the WHO benchmark; maternal-risk gradients.
2. **Not a price story** (`02_not_a_price.R`) — muni-year `tiss_csection_rate ~
   log_fee_gap` with UF/muni and year FE, plan coverage, GDP pc, prenatal care and
   obstetrician density controls, delivery-weighted. Coefficient small/sign-unstable.
3. **The convenience mechanism** (`03_scheduling.R`) — SINASC day-of-week (and,
   next, holiday/pre-holiday) cesarean clustering, private vs public; the weekend dip
   as revealed physician convenience.

**Supporting / robustness (`05_policy.R`, not the identification headline):**
- **Parto Adequado** treated-municipality exposure (Phase-2 hospital list mapped
  CNES→IBGE). With the extended SINASC pre-period (2010–2016), the event study
  **rejects parallel pre-trends** (2010–2015 joint test $F=4.5$, $p<0.001$): treated
  munis are on a **pre-existing differential downward trend** (+6.8pp in 2010 → 0 at
  2016 → −5.7pp in 2024, a straight line with **no break at the 2017 onset**). So the
  DiD (−6.6pp SINASC) is **not a treatment effect** — Parto Adequado does **not**
  survive as causal evidence. (Kept in the paper as a transparently-null event study,
  à la HomeOfficePNAD's maternity-leave figure.) This is exactly why the long
  pre-period mattered: the earlier short-window "effect" was a pre-trend artifact.
- **RN 368/2015** (national transparency + partogram) — shown as a national monthly
  timeline (`fig05`); underpowered as an event study (only ~6 months of pre-period).
- **Dec-2015 SP court ruling** ordering ANS to pay ≥3× for vaginal delivery —
  our fee series shows it **never became a real fee change** ("even a court order to
  triple vaginal pay moved nothing").
None is a clean DiD lever (no firm IDs; monthly TISS; short pre-2015) — hence
supporting, not identifying.

---

## Data infrastructure

**Code and final outputs live in Git; raw and intermediate data live in Dropbox
(never committed).** Every script does `source(here::here("config","config.R"))` for
`DROPBOX_ROOT`; repo paths via `here::here()`. Packages via `pacman::p_load()`.

### TISS Hospitalar (ANS private-insurance claims, 2015–2025)
FTP `https://dadosabertos.ans.gov.br/FTP/PDA/TISS/HOSPITALAR/`. Two parquet tables
linked by `ID_EVENTO_ATENCAO_SAUDE`: **CONS** (1 row/event: `ID_PLANO`,
`FAIXA_ETARIA`, `SEXO`, patient & provider municipality, LOS, `QT_DIARIA_UTI`,
`CID_1..4`, modality, `LG_VALOR_PREESTABELECIDO`); **DET** (1 row/item:
`CD_PROCEDIMENTO`+`CD_TABELA_REFERENCIA`, `QT`, `VL_ITEM_EVENTO_INFORMADO` charged,
`VL_ITEM_PAGO_FORNECEDOR` paid — only ~5% populated). Schema breaks across years;
dictionaries in `dictionary/`.

- **Delivery codes** (TUSS, `build/00_utils.R`): cesarean 31309054/31309208, vaginal
  31309127, hourly labor assist 31309038 (mean ~2.7h @ ~R$409/h → the *economic*
  vaginal fee).
- **Admission proxy**: distinct events undercount admissions; use
  `estimate_admissions_vinicius()` (per-event qt/LOS, ≈9.40M for 2023 vs ANS 9.2M).

### Municipality covariates (Dropbox `build/`)
- `IEPS/input/ieps.csv` (manual export, https://iepsdata.org.br) → `01c_ieps.R` →
  `IEPS/output/ieps_muni_year.parquet` (GDP pc, population, private-plan coverage,
  adequate prenatal, ESF, income; key `code_muni6`).
- `covariates/input/cnes_beds_muni_year.parquet` (datazoom.saude `load_hospital_beds`;
  establishment-level, `cnes`+`codufmun`+`nat_jur` → private/public flag).
- `covariates/input/cnes_obstetricians_muni_year.parquet` (microdatasus CNES-PF, CBO
  obstetrician counts; `01b`).
- SINASC (**all births, exact date**), pulled from **Base dos Dados** (BigQuery) with
  a *targeted* column set (microdatasus/datazoom truncate the establishment CNES),
  ingested by `01d_sinasc_daily.R` into two parquets (raw CSV deleted after):
  `covariates/input/sinasc_births.parquet` (one row per birth: Robson group, hour,
  gestation, presentation, induction, prior CS, mother age/educ/race, birthweight,
  Apgar, private flag) and `covariates/input/sinasc_daily_muni.parquet`
  (muni × date × sector → births, cesarean; the scheduling aggregate).
- `covariates/input/parto_adequado_fase2_hospitais.csv` (113 hospitals: nome, cnes,
  status, município, uf, **ibge6, ibge7**; ANS Fase-2 PDF snapshot 11/02/2019).

### Outputs (Dropbox)
```
build/TISS/output/delivery_events_<year>.parquet   one row per delivery (event workfile)
build/TISS/output/delivery_panel_muni_month.parquet muni × month aggregates
build/workfile/output/main_data.parquet             THE analytical file (muni-year, all sources)
```
`main_data.parquet` (muni-year, 11,567 rows): TISS deliveries + fees + LOS/ICU, IEPS
covariates, obstetrician density, SINASC all-births + private/public cesarean rates.
Rows with missing provider municipality are dropped (~0.06%); NaN from empty-subset
fee means in sparse cells are set to NA.

---

## Repository layout
```
config/   config.R (DROPBOX_ROOT only) · 00_master_build.R · 00_master_analysis.R
build/    00_utils.R (admission proxy, delivery codes)
          01_download_tiss.R · 01b_download_covariates.R · 01c_ieps.R · 01d_sinasc_daily.R
          02_deliveries.R (event + muni-month) · 03_workfile.R (→ main_data.parquet)
analysis/ code/ 00_utils.R (theme_paper, palette) · 01_descriptives.R ·
          02_not_a_price.R · 03_scheduling.R (weekend/holiday) · 04_robson.R (low-risk) ·
          05_policy.R (Parto Adequado event study + RN 368 timeline — support) ·
          06_fee_shock.R (cesareans don't respond to fee-gap swings — "not a price")
          output/ {graphs, tables, maps}   committed to git
          Figures use theme_paper() + PAL (no titles/notes); tables use etable +
          dict (clear names) + postprocess_tex (booktabs), mirroring HomeOfficePNAD.
dictionary/ ANS TISS variable dictionaries (.xlsx)
latex/    paper.tex · refs.bib   (PDF git-ignored)
CLAUDE.md · README.md · .gitignore · HealthEcon.Rproj
```

## Key facts / numbers (for sanity checks)
| Fact | Value |
|---|---|
| TISS private cesarean rate | ~82% (2023), 85%→80% over 2015–2025 |
| SINASC cesarean (all / for-profit private / public) | 57% / 79% / 44% |
| Economic fee gap (cesarean−vaginal, big states) | negative (~−8 to −25%) |
| `log_fee_gap` coef on csection (UF / muni FE) | +0.017 / −0.014 (n.s.) |
| Weekend cesarean dip (private / public) | −8.0pp / −6.6pp (p<0.001) |
| Holiday cesarean dip (private / public) | −5.1pp / −3.4pp (p<0.001) |
| Robson 1 cesarean, weekday (private / public) | ~66% / ~36%; weekend dip −5.9pp private |
| Deliveries/year (TISS) | ~406k; SINASC all ~2.7M/yr |

## Honest limits (the identification ceiling)
No operadora/hospital/physician IDs in TISS (rules out bargaining, vertical
integration, within-physician designs); paid prices ~5% (charged only); no
enrollment/premium/panel (weak selection/demand); TISS monthly (SINASC supplies the
daily grain for scheduling); no clean, differentially-timed policy shock found so
far. → JHE-grade is solid; higher requires a sharp exogenous lever we do not yet
have.

## Project status & diagnosis (2026-07-07)
**Has a future? Yes — a solid Journal of Health Economics paper.** The empirical
core is built, verified, and coherent.
- **What is causal / credible:** (1) the descriptive facts (national measurement);
  (2) *"not a price"* — a credible reduced-form falsification (within-muni and
  first-difference fee variation, and idiosyncratic UF fee swings, do not move the
  cesarean rate); (3) the **convenience mechanism** — because the day of the week is
  as-good-as-random with respect to medical need, the weekday clustering / weekend &
  holiday dips (largest in for-profit private, present even in Robson 1 at ~66%) are
  a **credible causal statement that cesarean *timing* is driven by physician
  convenience**, not need.
- **What is NOT causal (honest nulls, kept for rigor):** no policy lever moves the
  epidemic — Parto Adequado **fails parallel trends** (and neither covariates nor a
  treated linear trend rescue it: `tab05b`), fee shocks are null. There is no clean,
  sharply-timed exogenous shock in reach (no firm/physician IDs; diluted municipal
  exposure; monthly TISS; price-poor).
- **Publication read:** **JHE** (primary, realistic). *Health Economics / JHR /
  J. Population Economics* plausible. **AEJ:Applied a stretch** (needs a clean lever
  we don't have). **Not** a top-5 — the identification ceiling is set by the data.
- **The contribution** is the "why": two national datasets show the world's worst
  private cesarean epidemic is **not money and not a fixable-by-fees policy problem —
  it is physician time/convenience & norms**, framed through physician agency (SID).

## Conventions
- **R** with `data.table` / `arrow` / `fixest`; `pacman::p_load`. Prefer lazy
  `arrow`/`dplyr` (or `fread` column subsets) over loading full DET/CSV into memory.
- Municipality key is **6-digit IBGE** everywhere (TISS, IEPS, CNES, SINASC-6);
  SINASC/basedosdados give 7-digit → take first 6. `code_muni` can arrive as factor
  → `as.integer(as.character(x))`.
- **Never commit data** (`*.parquet/*.csv/*.dta/*.rds` gitignored); commit/push only
  when asked. macOS filesystem is case-insensitive.
