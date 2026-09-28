# CLAUDE.md — HealthEcon Project Guide

> **2026-09-27 — full code audit; SINASC now from the DATASUS FTP.** The sector
> is the establishment's legal nature in the birth's own year; TISS deliveries
> are typed by the TUSS code (15% had been dropped); timing analyses 2012+,
> Robson 2014+; SINASC "ignored" codes handled; Table 1's bootstrap actually
> runs (p 0.32); demand-smoothing weeks include zeros. Headline: −1.8pp weekend /
> −2.5pp holiday. Full record: `parto_cesareo/REVISION_LOG.md`. Where this file
> and the generated tables disagree, the tables win.
>
> **2026-09-28 — external consistency check (19 items).** 18 confirmed and fixed,
> one (Elejalde 8.6pp) was right in the paper and wrong in a skill. Code: the
> education heterogeneity model had no education main effect (low-education dip
> −20.0 → −11.2pp); D.16 now reproduces Table 1 exactly; sample-flow rows
> un-nested; notes on years (Fig C.2 2014+, D.9 2016+, Table 5 race 2011+).
> Text: preterm/group-5 framing, capacity collinearity, court order and policy
> record, composition check, 35k/37k footnote. See REVISION_LOG.
>
> **2026-09-28 (referee round 2) — price of time.** The fee argument is now
> per-delivery vs per-hour: a cesarean pays less per delivery but more per hour
> once a vaginal delivery takes >~1.25 h (Table `tab_fee_per_hour`). Calibration
> leads; our regressions (superseded in round 3: "do not discipline the magnitude"); the sign flip is no
> longer an argument. Scheduling is common to both sectors, the for-profit
> differential an increment. New `16_design_checks.R`: fee per hour, balance of
> predetermined characteristics + newborn sex in Eq. (3), identifying sample (461
> munis, 74% FP / 56% public births). SINASC rebuilt with SEXO, CONSULTAS,
> CONSPRENAT, MESPRENAT (old 32 columns byte-identical).
>
> **2026-09-28 (referee round 3) — 13 consistency items A–M.** Beds and scale
> are NOT collinear (corr 0.48; the weekend interactions net of the FE correlate
> at 0.56; col 1 separates them; muni×date FE remove the variation; joint p 0.021).
> The economic vaginal fee is an EXPECTED fee (assist = 0 when unbilled); a vaginal
> delivery billing no labor hours pays R$1,778 < the cesarean's R$1,939. Our fee
> regressions "do not discipline the magnitude" (never "consistent with the
> calibration"). The common gradient is organizational, and the price of time speaks to the
> for-profit increment only. The schedule pays billed labor hours; what goes unpriced is
> on-call/unbilled time. Abstract ≤250 words (now 245). See REVISION_LOG.


## What the paper is

Empirical paper, *"Born on Schedule: Fees, Supply-Side Scheduling, and Cesarean
Delivery in Brazil."* It asks why Brazil's **for-profit maternity sector** runs
one of the highest cesarean rates recorded in any health system (~80% of
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
  "there is no relationship" or "fees don't matter." Since 2026-09-28 the
  regressions only "fail to contradict" the calibration; do not lead with the sign
  flip, and never oppose "price" to "scheduling": time is the price the fee
  schedule omits (per delivery the cesarean pays less ON AVERAGE, per hour more). Since
  round 3 the regressions "disagree and do not discipline the magnitude": muni-FE
  intervals exclude both literature responses from below, state col 1 (4.9 pp/log
  point) lies above GKM; never "small in every specification" or "consistent with
  the calibration". "Time the schedule leaves out" means on-call availability,
  uncertain onset, unbilled hours: the schedule DOES pay billed labor hours
  (R$420/h), and that hourly fee is a lever the data do not evaluate. The canonical magnitude
  (\citet{grant2009}, ~1pp per US$1,000 = ~0.73pp per log point at our fee levels;
  \citet{gruber1999physician} four times that) is too small to matter at this
  scale, predicting at most ~0.36pp and ~1.4pp against a 36pp gap. The RAW FACT leads, the regression follows.
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
  Beds and delivery scale are related but NOT collinear (round 3: corr of logs
  0.48; weekend interactions net of FE 0.64 col 1 / 0.56 col 2, VIF ~1.4). With
  date FE and both entered (D.11 col 1) scale is 1.49*** and beds 0.47 n.s.; under
  muni×date FE (D.11 col 2, family E) the FE cut the residual SD by 33% (beds) /
  51% (scale) and the two are jointly (Wald p 0.021) but not individually
  significant; each WITHOUT the other is (scale 1.3–1.4pp***, beds 0.80**).
  Never write "too collinear"; write "too little variation left within
  municipality-days". Never "neither is distinguishable from zero" without
  "entered together", and never "only across municipalities".
- **Robson-group profile + term/preterm + maternal-age splits** (2026-07-22) =
  *corroboration, NOT a placebo*. Robson group and gestational age at birth are
  partly determined by the same decisions under study, so these are heuristic
  falsifications. Say "the excess for-profit gradient is concentrated where the
  choice between labor and surgery is still open" (groups 1–4); never "preterm
  births are a clean control", never "group 10 cannot be scheduled / whose date is
  not / cannot be freely scheduled" (figure notes and table notes included).
  Preterm ≠ unschedulable (preeclampsia, IUGR, elective late-preterm are all
  booked). Group 5 (previous cesarean, 28.6% of for-profit births) goes the OTHER
  way (for-profit −3.3 vs public −5.8) because it sits at the ceiling (95.3% vs
  79.9% on weekdays); the text must name it, not list it among the bookable groups
  that carry the excess. The maternal-age split is exploratory and NOT in the
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

They overlap (~81–84%) but are not the same population, and SINASC has no payer
flag. Enforced in code via `sector_display()` / `SECTOR_DISPLAY` in
`analysis/code/00_utils.R`:

- **SINASC** → ownership of the birth **establishment** (natureza jurídica 2xxx).
  Call it **"for-profit"** (vs "nonprofit" 3xxx, "public" 1xxx). ~79% cesarean.
  The `sector` column keeps raw levels `Private/Nonprofit/Public/Other` because
  regressions subset on them; relabel only display/plot objects with
  `sector_display()`.
- **TISS** → claims financed by **private insurance**, private by construction.
  Call it the **"private-insurance sector"**. ~84% cesarean.

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

1. **The epidemic is real and extreme** — cesarean ~84% in the private-insurance
   sector (TISS) / ~81% for-profit (SINASC) vs ~43% public; 68% even in Robson 1
   (spontaneous labor) on weekdays, against 36% public.
2. **Not a positive price story** — with the *economic* vaginal fee (labor
   assistance billed on 38% of vaginal deliveries, 2.9 h at ~R$420/h), a cesarean
   pays 18–38% less in each of the five largest states, which run ~80% cesarean.
   The coefficient is sign-unstable: +0.049** UF FE / −0.014* muni FE without
   controls, +0.019 / −0.013 (n.s.) with them; state swings of up to 1.4 log
   points move nothing (wild bootstrap p 0.32); the 2015 court order never became
   a fee change. Calibrated, not an equivalence result.
3. **A scheduling story** — weekend dips −7.9pp for-profit / −6.7 public, holidays
   −5.3 / −3.5; half of cesareans in weekday business hours vs 29.8% uniform.
4. **Eq. (3), the central estimate** — within the same municipality-day the
   for-profit differential is **−1.8pp weekend / −2.5pp holiday**; −1.8 / −2.4
   with predetermined composition; −1.5 / −1.7 with Robson shares (2014+).
   **About half is within the establishment** (establishment-day cells,
   establishment×year FE, `15_estab_gradient.R`): −0.9 / −1.3 (birth / fixed
   weights) on weekends, −1.3 / −1.8 on holidays; the other half is weekend births
   moving across establishments (any-birth −8.7pp, prelabor count −34 lp,
   vaginal −6 lp). Never write the 1.8 as a within-hospital change of practice.
5. **The dip lives in prelabor cesareans** — −8.9pp prelabor vs +1.9pp in-labor
   (2012+); Robson 1–2 −7.0pp, Robson 1 −6.0pp (2014+; of the −6.0, −4.7 is coded
   in-labor and −1.3 is cesareans without a timing code, which DATASUS leaves in
   group 1 by default and which are MORE often uncoded on weekdays, 11.2% vs 9.8%;
   so only the −4.7 is intrapartum by construction, and D.19's balance holds for
   the sector split, not inside group 1).
6. **The cost** — +12.2pp early-term with maternal controls; 73% practice style
   (Kitagawa, 36.2pp gap); ~35k excess weekday cesareans/yr (9.3% of ~380k)
   against the own-municipality-year weekend benchmark; billed amounts near parity
   (mean cesarean 1% lower, median 4% higher).

## Key numbers (sanity checks; SINASC = 2010–2024 from DATASUS)

| Fact | Value |
|---|---|
| Cesarean (all / for-profit / nonprofit / public) | 56.4% / 80.7% / 59.9% / 43.0% |
| Weekend dip (for-profit / public) | −7.9pp / −6.7pp |
| Holiday dip (for-profit / public) | −5.3pp / −3.5pp |
| **Eq (3) for-profit differential (muni×date FE)** | **weekend −1.8pp / holiday −2.5pp**; +predetermined −1.8 / −2.4; +Robson (2014+) −1.5 / −1.7 |
| Eq (3) within establishment (estab×year FE) | weekend −0.95 (births) / −1.26 (fixed wts); holiday −1.31 / −1.75; any birth −8.7pp; prelabor count −34 lp; vaginal −6 lp; zero-filled panel 339 munis |
| Early-term share inside Eq (3) | −1.35pp*** (2012+); Robson 1–2 −0.69pp* (2014+) |
| LBW / low Apgar, Robson 1–2 at term (Table 5 cols 5–6) | −1.06pp / −0.39pp (full sample −3.47 / −0.63) |
| Deliveries with no physician fee billed to the plan (TISS) | 4.5% (1.6–7.3% by year); upper bound on availability-fee deliveries |
| Log fee gap, Table C.1 (delivery-weighted, ≥20 deliveries) | weighted −0.04; unweighted +0.21; 57% of deliveries where cesarean pays less |
| CNES link (capacity analysis) | 2016–2024 95.4% (weekdays 95.3 / weekends 95.4); 2015 cannot link (lagged, panel opens 2015) |
| Weekend dip: prelabor vs in-labor (for-profit, 2012+) | −8.9pp vs +1.9pp |
| Robson 1–2 / Robson 1 weekend dip (for-profit, 2014+) | −7.0pp / −6.0pp |
| Robson profile, for-profit vs public (Fig 3c) | G1 −6.2/−3.6 · G2 −5.0/−3.7 · G3 −7.9/−3.0 · G4 −8.9/−4.2 · G5 −3.3/−5.8 · G10 −4.8/−5.3 |
| Robson 1 vs 10 (for-profit) | G1 dip 1.3pp larger, p = 0.006; still not a placebo. G1/G3 have 0 prelabor cesareans BY CONSTRUCTION (DATASUS derives Robson from the labor-onset and prelabor fields): the timing table is a definition, never a validation |
| Eq (3), term vs preterm | −2.1pp vs +1.5pp; difference +3.6pp |
| Eq (3), mother <35 vs 35+ | −2.5pp vs +1.7pp*; within Robson 1–2, −4.8 vs −1.4 |
| Long weekends: bridge = isolated | p 0.55 (prelabor p 0.70); family D Holm 0.202 |
| Pre-holiday prelabor bunching (bridge) | −0.47/day (deficit, not bunching); window −1.24 |
| Org capacity, muni×date FE (prelabor) | together: beds +0.58 (0.38), scale +0.64 (0.41), n.s. individually, joint p 0.021; scale alone/with non-bed measures +1.30 to +1.43***; beds alone +0.80**; date FE together: scale +1.49***, beds +0.47 n.s. |
| Beds vs scale | corr of logs 0.48 (estab-years); weekend interactions net of FE 0.64 (date) / 0.56 (muni×date) |
| Fees per delivery (TISS events, D.19) | cesarean 1,939; vaginal fee alone 1,893; economic vaginal 2,417 (expected); billing labor 3,355 / billing none 1,778; 62% bill none (30–82% in big-5) |
| Cesarean fee for the calibration (D.17) | 1,963 = delivery-weighted over regression muni-years; 1,939 would give 0.72 / 2.87 |
| Education heterogeneity (D.12, with education main effect) | weekend dip −11.2pp (<8 yrs) / −7.2pp (8+); weekday rates 67% / 85% |
| Fee gap with the base vaginal fee (D.16, Table 1 sample) | +0.0366* UF / −0.0176** muni; econ columns = Table 1 exactly |
| Zero-obstetrician maternities (CNES-PF, ≥50 births) | 14% for-profit / 26% public (median 3/2) |
| Weekend × SUS share of obstetric beds | +2.58pp**; holiday +2.85pp*** |
| Weekend × log contracted obstetrician hours | −0.16pp (0.17); scale +1.31pp*** in that column |
| Early-term (37–38wk) gap, maternal controls | +12.2pp*** |
| Kitagawa, 36.2pp gap | 27% case-mix / 73% practice style |
| Robson-standardized dispersion across for-profit maternities | SD 14.1pp; 6.3pp survives muni×year + composition + capacity (44%); same-municipality pairs differ by 11.9pp |
| SUS share of obstetric beds by nat_jur | public 98.8% / for-profit 22.2% (median 0) / nonprofit 72.0% |
| Excess weekday cesareans (own-municipality-year) | 35,330/yr for-profit = 9.3% of weekday cesareans |
| Footnote reconciliation | 7.9pp × 463k = ~37k/yr; Eq. (3) 1.8pp × 463k = ~8k/yr |
| Price benchmarks in our units | Grant 0.73 / GKM 2.90 pp per log point (R$1,963 mean cesarean fee) |
| Demand smoothing | next-week coefficients small, either sign, none significant; forecast slope 0.050; MDE 0.63pp; dispersion +0.31 (0.16), Holm 0.173 |
| Private-insurance cesareans with no recorded indication | 77–81% a year (blank or O80–O84 only) |
| `log_fee_gap` (UF / muni FE, no controls) | +0.049** / −0.014* |

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
- The excess-weekday count uses the own-municipality-year benchmark (35,330/yr since
  the 2026-09-27 re-run; 39,135 before), the one the text describes. The footnote's
  37k is the 7.9pp regression gradient x 463k and must be presented as a second,
  similar number, not as the benchmark itself. Do not swap in the national sector-year benchmark. [2026-09-05]
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

**Added 2026-09-28 (external consistency check)**
- Any model whose cells are split by a subgroup (education, age band) must include
  the subgroup's level (main effect or muni×group FE) next to its weekend
  interaction; `04` and the family-B copy in `10` must stay identical.
- An exhibit described as reproducing another ("columns 3–4 reproduce Table 1")
  is built from the same sample object and must match to the last digit and N.
- The 2015 court order is never evidence ("changed nothing", "produced no
  movement"); it never became a rule. The policy record is: Melo & Menezes-Filho
  −1.6pp for the national package; Parto Adequado a hospital-level pre-trend. Never
  "the cesarean rate did not move", never "municipal trend seven years earlier".
- The weekend-newborn composition check is mechanical under scheduling; it cannot
  bound selection and may not be listed as one of the design's defenses.
- Holidays: eight fixed-date national + 20 Nov from 2024 + three Easter-based
  movable holidays on four dates (Carnival Mon/Tue, Good Friday, Corpus Christi),
  which are not national holidays under federal law. The long-weekend design uses
  the eight fixed-date holidays only.
- Level numbers print at one rounding everywhere: for-profit 81%, private
  insurance 84% (82–86% by year).

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
