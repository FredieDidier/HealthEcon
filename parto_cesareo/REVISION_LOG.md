# Revision log — Born on Schedule

The dated revision history that used to live in `CLAUDE.md`, moved here verbatim on
2026-09-26 so that `CLAUDE.md` holds only the current rules. The rules these entries
produced are summarized in `CLAUDE.md` under "Guardrails from past revisions"; read
the entry here when you need the evidence behind one. References below to sections
"above" (Conventions, Exhibit map, Key numbers, Clinical-cost positioning, the
nat_jur table) point to `CLAUDE.md`.

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

## The 2026-07-16 revision (Proof Patrol round 3: Parfitt positioning + JHE)

Two Proof Patrol reports (PDF in Downloads, "GPT Feedback") drove this round:
- **Parfitt & Goulart (2026 JDE, heatwaves in Brazilian maternity wards) is now
  cited and distinguished** in the intro contributions ("closest contemporaneous
  study"; our muni×date FE absorb temperature; different estimand), with a
  footnote that sector definitions are NOT comparable across Parfitt (public
  wards), Melo (bed-allocation classes), and us (natureza jurídica).
- **New literature block** (capacity/staffing/crowding): maibom2021 (JHE),
  bensnes2026 (Health Econ), facchini2022 (JEBO), bachner2024 (IZA DP 16981);
  timing lit expanded with cohen1983, spetz2001, spinola2026 (the published
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

## The 2026-08-10 fix: DATASUS codes the Distrito Federal by administrative region

**The bug.** CNES codes the DF by ADMINISTRATIVE REGION — 530010 (Brasília),
530020, 530030 ... 530180 — while IBGE, TISS and SINASC all use 530010 alone. Any
municipality-level CNES aggregate therefore splits Brasília across up to 19 keys,
and the merge onto the TISS spine picks up only the 530010 slice. Nothing is
dropped and nothing errors; the number is just wrong.

**Where it bit.** `cnes_obstetricians_muni_year.parquet` only:

| year | DF keys | obstetricians, all keys | under 530010 | share lost |
|---|---|---|---|---|
| 2015 | 18 | 1,138 | 451 | 60% |
| 2016 | 19 | 1,167 | 470 | 60% |
| 2017+ | 1 | — | — | 0% |

CNES switched to a single code in 2017, so only 2015 and 2016 are affected —
**which is worse than a constant bias**, because it produced a spurious +76% jump
in Brasília's obstetrician count between 2016 and 2017 that municipality fixed
effects read as genuine within-municipality variation.

**⚠️ The recode must happen BEFORE `uniqueN()`, never after.** An obstetrician
practising in two administrative regions appears under two keys, so summing the
per-key distinct counts double-counts: the naive 2015 sum of 1,138 overstates just
as the 451 understates. Recoding first and counting once gives **857**. The fix is
`fix_muni_df()` in `build/00_utils.R`, applied in `01b_sinasc_cnes.R`.

Brasília's corrected series, now smooth: 857, 862, 826, 865, 895, 971, 1012,
1078, 1070, 1122 (was 451, 470, 826, ...).

**What was re-run:** the DF rows of 2015 and 2016 were rebuilt surgically from
`PFDF1512`/`PFDF1612` (a full re-run of `download_cnes_obstetricians()` reproduces
exactly this and nothing else, since `fix_muni_df()` is a no-op for every other
state; the 530010-only recomputation reproduced the stored 451 and 470 exactly,
which is what proves the two pipelines are equivalent). Then `03_workfile.R` and
every script that touches the variable: **01, 02, 04, 10, 11**.

**Impact on the paper: negligible, and that is the honest finding.** Body Table 1
(`tab_fees`) is byte-identical. The only number that moved anywhere is the mean
obstetricians per 1,000 births in the summary statistics, **115.44 → 115.45**. Two
municipality-years out of 11,567, in regressions weighted by TISS deliveries and
carrying municipality fixed effects, cannot move much. The data file is now right
and the spurious jump is gone; the results did not depend on it.

**Verified NOT affected, so do not re-check:**
- `09_org_capacity.R` — takes `muni` from SINASC (`sinasc_daily_estab.parquet`) and
  reads only `cnes, year, n_obstetricians, beds_obstetric, beds_total` from the
  establishment panel. It never touches `codufmun`, and establishment-level counts
  are immune to municipality coding.
- `cnes_beds_muni_year.parquet` — carries 16 DF keys in 2015–2017, but is used
  keyed by establishment CNES for the `nat_jur` sector classification, never by
  municipality. If it ever becomes a municipality covariate, apply `fix_muni_df()`.
- **SINASC** — one DF code (530010) in every year 2010–2024, 0% lost. Checked.
- **TISS** — one DF code in BOTH `CD_MUNICIPIO_BENEFICIARIO` and
  `CD_MUNICIPIO_PRESTADOR`, every year 2015–2025, 0% lost. Checked.

Sibling projects hit by the same bug: **HealthHeat** (SIH `MUNIC_RES` loses 86/92/93%
of DF admissions in 2015/2016/2017; CNES establishments ~49% in 2015–2016) and
**WorldCupHealth** (SIH broken 2008–2017, CNES 2008–2016; fixed there by
`fix_muni6()`). SIH cleans up in 2018, CNES in 2017 — do not infer one from the other.

## Language and typography fixes (2026-08-10)

- **`natureza jurídica` → "legal-entity type"** in the note of
  `tab13_referee_robustness` (supplement). Source: `06_robustness.R`.
- **`PREVIOUS` → `previous`** in the note of `tab_org_capacity` (supplement
  Table D.8) — an ordinary word shouting in caps. Source: `09_org_capacity.R`.

Both were fixed **in the R source and in the generated `.tex` with the identical
string**, so a re-run cannot silently revert them. `09` and `06` were not re-run
(they are the 42M-row scripts and their numbers are untouched by the DF fix).

Everything else that looks Portuguese in the PDF is correct and must stay: dataset
citations keep their **original Portuguese titles** (`refs.bib`: TISS Padrão,
SINASC), institution names are given in English with the Portuguese in parentheses
(ANS, IBGE, IEPS, SUS, CNES), and `HOSPITALAR` appears only inside a literal URL.
The remaining all-caps tokens in the compiled PDF are DATASUS, UFBA and RAND (the
journal) — all legitimate.

## The 2026-09-04 revision (AI-tic copy-edit + one note style)

Applying the `MONASTERIO.md` logic from the sibling **WorldCupHealth** repo (his
handwritten-PDF + WhatsApp round on that paper) to this manuscript. Nothing
numerical changed; 36 files, no re-run of any 42M-row script.

**Prose (34 edits in `paper.tex`, 4 in `sup_appendix.tex`).** Three tics, all his:
- ⭐ **The two-to-five-word sentence used as a drumbeat.** "Second, the calendar
  does." · "Panel B shows why." · "This shift is not costless." · "Two facts
  emerge." · "We therefore turn to counts." · "Two cautions apply." — all
  dissolved into the neighbouring sentence, none of the content dropped.
- **The meta voice, the text commenting on the text** (what Fredie cut in
  WorldCup as "…deserves naming"): "Two features of the estimand deserve
  emphasis" · "Two extensions discipline the reading" · "We read this as follows"
  · "Table 1 makes this precise" · "Panel B supplies the context" · "We are
  deliberate about what this comparison can and cannot do" · "we report these
  honestly" · "The next two sections develop each panel in turn" · "previews the
  two designs on a single canvas".
- **The grandiose opener he struck out** ("Economics has a name for…"): here
  "Economic theory offers a natural suspect and a large literature to back it."
  — deleted outright. Also the repeated crutch "natural" (5 uses: suspect /
  concern / threat / explanation / question) down to the clinical term only, and
  "not confined to" from 3 uses to 1.
- Antithesis and cleft tics: "is not X. It is Y" · "What the data reveal instead
  is…" · "What is portable is…" rewritten as direct statements.
- `behaviour`/`behavioural` → `behavior`/`behavioral` — the only two British
  spellings in the manuscript.

**No italics or bold in body prose** (user request). 11 `\emph{}` removed from
`paper.tex`, 1 from `sup_appendix.tex`. KEPT, deliberately: the front-matter
labels (`\textbf{JEL classification:}`, `\textbf{Keywords:}`), the CRediT author
names (Elsevier convention), and the `\emph{Panel A. ...}` headers inside tables
(structural, not emphasis — without them a panel header reads as a data row).

**Subsection letters dropped and one note style everywhere** — see the Exhibit map
and Conventions sections above for the rules that now bind.

**Build after all of it:** paper 35 pages, supplement 23; 0 undefined refs and 0
undefined citations in both. The one overfull hbox in `paper` (2.8pt, the
generative-AI declaration) and the one overfull vbox in `supplement` (46pt, at
`tab15_permutation`) are BOTH pre-existing — verified by stashing the changes and
recompiling the baseline. Do not go hunting for them as regressions.

⚠️ **Something external clears `latex/*.aux`.** Twice during this session the
`.aux`/`.log`/`.bbl` files vanished from `latex/` between two commands.
(Confirmed again 2026-09-06: a full clean cycle finished, the greps on `paper.log`
and `supplement.log` ran fine inside the same command, and by the next command
every `.aux`/`.log`/`.bbl` was gone while both PDFs survived. Consequence: capture
the log greps in the SAME command as the compile, and never run a single
`pdflatex` pass expecting the previous run's `.aux` to still be there.) Because
`xr` runs both ways, a clean in the middle of the cycle turns all ~29
`\satab`/`\safig` references into `??`. If the references print as `??`, suspect
this before suspecting the source.

## The 2026-09-05 revision (internal-review items 1-5, 7, 10 and O4)

Executing the "Prioridade Revisada" of `parto_cesareo/PARECER_INTERNO_2026-08-20.md`.
Roadmap rewritten in that order; temperature robustness dropped from scope.

**1. de Elejalde & Giolito (2021, JHE 75:102411) is now cited** — it was absent
from the whole manuscript, which was an editorial risk at the target journal and
left the direct counter-hypothesis unaddressed. Their Chilean private hospitals
were paid the SAME price for either delivery mode and the cesarean rate rose 8.6pp
anyway; the mechanism is schedulability used to smooth demand. Added to the agency
block of the intro, the contribution block, Section 6D, the conclusion, and a new
Supplemental Appendix subsection. ⚠️ Cite **8.6pp** (the published JHE version),
not the 4.6pp of the IZA DP in `parto_cesareo/Literature/`.

**2. The WHO 10-15% error is fixed** (3 occurrences: abstract, intro, background).
That band is from the **1985** statement; it was attributed to `who2015cesarean`,
which says the opposite. The current declaration (WHO/RHR/15.02) sets NO target
rate, says population-level survival gains stop appearing above ~10%, and directs
institutional comparison through the Robson classification. The text now says all
three, and points out that we use Robson throughout. Do not reintroduce "10-15%
reference range". ⚠️ The sentence naming the 1985 statement as the source of the
10-15% band was written and then **cut at Fredie's request** (2026-09-05): the
correction stands on what the current guidance says, and does not need to litigate
where the old number came from. Do not re-add it.

**3. The price claim is recalibrated, and this is the substantive change.**
`tab_ref_c5_feegap_ci` said "not within" four times while its note concluded "there
is no robust relationship" — the table never supported that. It now carries a fifth
column, the Gruber-Kim-Mayzlin magnitude (~1pp per US$1,000, converted at our own
fee levels to **0.72pp per log point**). Result: the two municipality-FE intervals
EXCLUDE the canonical magnitude, the two state-FE intervals (27 clusters) do not,
and none establishes equivalence. Section 5 now reports the two schemes separately
and drops the false "small" applied to the +0.047 state-FE coefficient. **The
argument now rests on calibration, not on the regression**: applied to the 0.10 to
0.35 log-point negative gap of the big states, the canonical response predicts
~0.25pp against a 35pp gap. Abstract, intro, Section 5, conclusion and
`highlights.txt` all reworded to match.

**4. The ~50,000 excess weekday cesareans: text and code now agree.** The body
described an own-municipality benchmark; `03_mechanisms.R` computed a national
sector-year one. The code was migrated to the municipality version (the one the
text claims and the more defensible one, since it absorbs geographic composition)
and now reads `sinasc_daily_muni.parquet` instead of the birth-level file:
**39,135/yr, 10.0% of for-profit weekday cesareans**. The denominator in the prose
was also wrong (10.5% is the share of ALL cesareans, not weekday ones). A new
footnote reconciles the two counterfactuals: the benchmark prices the gross 8.3pp
gradient (~40k/yr on 482k weekday births), Eq. (3) prices only the 2.3pp for-profit
differential (~11k/yr).

**5. `.bib` corrections applied** — `johnson2016` title ("Information and
incentives", not "Information asymmetry and incentives"), `melo2024` (33(9):2013-2058),
`parfitt2026` (art. 103725 + DOI), `elejalde2021` added, **`melo2023` added and
cited** in Section 2 (the published evaluation of the very policy the section
describes: -1.6pp, +0.07 weeks, +10g). `curriemacleod2016` was already cited.
`spinola2025` was renamed **`spinola2026`** and now carries its published volume
(EJHE 27:1117--1148, 2026; online 29 Dec 2025), supplied by Fredie the same day.

**7. Demand smoothing tested: `analysis/code/13_demand_smoothing.R`.** Two
pre-specified tests on establishment-week cells of for-profit births, 2015-2024
(672 establishments, 281,748 cells), from the cached `sinasc_daily_estab.parquet`.
(A) **Pull-forward**: the prelabor cesarean share of week w against expected demand
in w+1, where expected demand is the leave-one-out mean of the establishment's own
births in that week of the year across other years. **Null** (-0.21pp, SE 0.29) —
but the forecast is weak (out-of-sample slope 0.065, MDE 0.80pp), so report it as
bounding only large responses, NOT as a rejection.
⚠️ **The leave-one-out mean must be normalized by the establishment's own annual
mean before averaging across years.** Without it the LOO mean is mechanically
NEGATIVE against the value it omits whenever the establishment trends, and the
forecast validation comes out at -0.44. The first version of the script had this
bug.
(B) **Throughput**: log variance-to-mean ratio of weekly births on the
establishment-year prelabor share. +0.27 within establishments (p=0.065, Holm
0.196) — the OPPOSITE sign to levelling. Report as an absence of levelling, not as
evidence that scheduling makes the flow lumpier. Becomes **family F** in
`tab_multiple_testing` (now six families) and Supplement Table **D.10**.
Net effect on positioning: we confirm their headline (the incentive survives the
absence of a price gap) and locate the margin elsewhere (weekly and
ownership-specific, not seasonal and throughput-levelling).

**10. Replication package assembled.** `README.md` gained a **Compiling the
manuscript** section (the two-way `xr` cycle, verbatim, with the `grep -c` checks)
and a **Deposit checklist**. Script 13 wired into `config/00_master_analysis.R`
(before 10) and into the program-to-output inventory. Two stale facts corrected:
the birth file is **42M** rows, not 24M, and `12` belongs in the do-not-run-in-parallel
list. The deposit itself and a `LICENSE` file are still open.

**O4. Prose pass** (the parecer's note was that the intro carries 60+ word
sentences, off-model for Johnson & Rehavi). Meta voice removed: "Panel B gives the
context", "Panel B shows why", "The raw gradients supply the context", "previews
the two designs", "and two facts emerge". Long sentences broken: the 97-word data
sentence, the 96-word four-defenses sentence, the 79-word capacity sentence, the
72-word conclusion opener. The remaining 60+ word sentences are equation-variable
definitions and citation lists, which are conventional. One drumbeat I had
introduced myself ("The margin differs, however.") was folded back in.

**Build after all of it:** paper **37 pages** (was 35), supplement **27** (was 23);
0 undefined refs and 0 undefined citations in both; 1 overfull hbox in paper and 1
overfull vbox in supplement, BOTH the documented pre-existing ones. The body
exhibit map is unchanged (6 tables + 3 figures, same numbers).
⚠️ A `$` written unescaped inside an R-generated table note ("US$1,000") opens math
mode and produced four overfull hboxes of ~300pt in the supplement. Escape it as
`US\$` in the R source. Caught and fixed the same day.

## The 2026-09-07 revision (Vinicius's CNES-level agenda: three items adopted)

From a call in which Vinicius proposed going deeper at the establishment and
care-team level. Six ideas; three adopted, three declined. The full memo, with the
reasoning for every one of them, is `parto_cesareo/AGENDA_CNES_VINICIUS_2026-09-07.md`
— read it before reopening any of this.

**1. `14_estab_practice_style.R` (new) → Table C.4, `tab_estab_practice_style`.**
The body's Kitagawa is a BETWEEN-SECTOR statement on two national aggregates; this
makes the same statement BETWEEN HOSPITALS, where the decision is taken. One arrow
pass over the birth file builds establishment-year × Robson cells (cached as
`sinasc_estab_year_robson.parquet`), and each maternity gets a **Robson-standardized**
cesarean rate: its own group-specific rates reweighted to the national Robson
distribution of the same year, which is the institutional comparison WHO/RHR/15.02
directs. Sample: 2014–2024, groups 01–10, establishment-years with ≥100 births,
coverage ≥90% of the reference weight.
- Panel A: standardization removes 28.8% of the for-profit–public gap (34.0→24.2pp),
  **independently reproducing the Kitagawa's 28%**, and almost none of the
  between-hospital dispersion (for-profit SD 16.2→14.5, P90−P10 40.8→38.1).
- Panel B: outcome is the STANDARDIZED rate. 6.6pp of SD survives municipality×year,
  maternal composition and obstetric capacity = 46% of the raw dispersion.
- ⚠️ **Panel B must NOT use the observed rate with the ten Robson shares as
  regressors.** That gives R²=0.951 / residual 4.6pp because the shares proxy the
  within-group practice they correlate with. It is an UPPER BOUND on case-mix and is
  reported as such in the note, never as a row. The first version of the script had
  it as a row; the standardization is the conservative accounting.
- Label it accounting, not a causal decomposition: the residual holds unmeasured
  case-mix and unmeasured capacity alongside practice.

**2. `obst_hours_hosp` finally used → `tab_org_capacity_valid` column 5.** The
variable had been built by `01d` since July and never entered a regression. Sum of
HORAHOSP over the establishment's obstetrician bonds; distinguishes a 4-hour
registration from a 40-hour one. **Result is a precise zero** (weekend × log hours
−0.10pp, SE 0.17) while the delivery-SCALE interaction is unchanged at +1.21pp***.
This STRENGTHENS the existing caveat: the attenuation tracks the size of the service,
not measured obstetric time. Median 34 h/week, 16.9% zero.

**3. SUS bed shares → the payer-versus-ownership check.** `cnes_beds_muni_year.parquet`
carries `n_beds_sus` / `n_beds_not_sus`, which sum to `n_existing_beds` exactly and
had never been read. `01d` now aggregates them; only `build_estab_panel()` was
re-run (**no CNES-PF re-download**), and the panel still has 84,213 rows.
- Validation, obstetric beds: public 98.8% SUS, for-profit 22.2% (median 0),
  nonprofit 72.0%. The median for-profit maternity places NO obstetric bed with the
  SUS, which is what licenses reading 2xxx as a private-payer population, and the
  nonprofit number is why 3xxx stays out of the headline. This went into the body's
  sector-definition paragraph.
- `tab_org_capacity_valid` column 6: **weekend × SUS share +2.12pp (p=0.041), holiday
  +3.37pp (p=0.005)** — a for-profit maternity more exposed to the SUS has a FLATTER
  calendar gradient. Same answer with the all-bed share (+2.08 / +2.59), which keeps
  the establishments with no registered obstetric bed.
- ⚠️ Report as an ASSOCIATION. Payer exposure is not assigned and `estab^year` holds
  the level only. Permitted: "the calendar pattern varies with payer within a single
  ownership type, which ownership alone cannot show." Forbidden: the causal effect of
  a payer mix.

**Declined, with reasons (do not re-litigate without new data):**
- **"Establishment versus care team"** — the two make the SAME prediction, and the
  separating design is *movers* (physician switching hospitals; Molitor 2018,
  Chandra–Staiger), which needs a physician-to-birth link. SINASC has no professional
  identifier and TISS has no hospital identifier. Turnover and multi-bond ARE
  computable from CNES-PF (`CNS_PROF` × establishment × year) but inherit the
  zero-obstetrician measurement failure, which is worse in changes than in levels.
  The one piece worth a paper 2 is multi-bond at the MUNICIPALITY level (the
  attribution error cancels within municipality), which is directly the model's Π.
- **CBO in TISS** — verified in both dictionary vintages: `CBO` exists ONLY in
  `Ambulatorial_DET`, never in `Hospitalar_DET`/`Hospitalar_CONS`. Deliveries are
  hospital events, so the field does not exist for them. SIH has it but is 100% SUS,
  the wrong sector, and is not in this project. The well-posed version is obstetrician
  versus **nurse-midwife** supply, for which `is_enfermeiro_obstetra` (CBO 7145) is
  already sitting in `build/00_utils.R`.
- **A MONTHLY establishment panel** — the identification is DAILY (weekend, holiday,
  muni×date); aggregating to month throws away the design. A monthly panel answers a
  LEVELS question, not a scheduling one. What of it belonged here entered as
  establishment-YEAR. Establishment trajectories over time are new and feasible but
  descriptive without a shock, and exposed to mean reversion plus entry/exit.

**No existing number moved.** `09`'s coefficients reproduced exactly (weekend × log
obstetric beds +0.445pp under muni×date FE). Build: paper 37 pages, supplement 28
(was 27), 0 undefined refs and 0 undefined citations in both, and the same two
documented pre-existing overfull boxes.

**Note style audited the same day** (Monastério's "padronizar o alinhamento das
notas", from the WorldCupHealth round): all 31 generated tables carry the canonical
`\begin{minipage}{\linewidth}\footnotesize` block, and all 10 figures in both
documents use `\fignotes`, which is the same block. There is no exception. A SHORT
note (Figure C.2's is one line) sits flush left under a centered caption and reads as
misaligned, but that is what full-width justification looks like on one line, and it
is identical to the table notes. A centred `0.9\textwidth` block was tried the
same day and **reverted the same day** at Fredie's instruction: the notes stay in
the Monasterio full-width justified form. Do not narrow it or re-add
`\centering`.

**Source upgrade in the background section.** The footnote behind "About a quarter
of Brazilians hold private health insurance" (`paper.tex:420`) cited a **Fenacor**
news page, a broker federation reporting on ANS, and was the manuscript's ONLY
inline `\href`. It now cites **ANS (2026)** directly, the regulator's own sector
dashboard at
`https://www.gov.br/ans/pt-br/acesso-a-informacao/perfil-do-setor/dados-gerais`.
Verified against the live page the same day: 53,080,809 beneficiaries of
medical-hospital plans (June 2026) and a stated coverage rate of **25.0 percent**
(July 2026), so "about a quarter" is exactly what the primary source says. The
footnote keeps the inline-`\href` form rather than becoming a `@misc` entry; if it
is ever converted, match the `data_ans_tiss` pattern in `refs.bib`.

⚠️ **Figure C.4 (gestational age) was being described wrongly, and the fix is text
only.** Both the body sentence and the figure note said "for-profit births mass at
37--38 weeks, public births at 39--40" and that "in-labor cesareans and vaginal
births mass at 39--40". Checked against the data on 2026-09-07: **both sectors peak
at week 39**. For-profit puts 40.1 percent of births at 37--38 against public's 26.2,
and 17.3 percent at 40--41 against 32.5, so the for-profit distribution is SHIFTED
earlier rather than massed at 37--38. Panel (b) is a three-way ORDERING, not a
prelabor-versus-rest split: at 37--38 weeks, prelabor cesarean 44.6 percent, in-labor
39.6, vaginal 30.4, all three peaking at week 39. In-labor sits much closer to
prelabor than to vaginal, so never group it with vaginal births. The substantive
result is untouched (the +11.7pp early-term gap of Table 5 is the 40.1-versus-26.2
contrast with controls); only the verbal description was wrong. Corrected in
`paper.tex`, in the `\fignotes` of `sup_appendix.tex` and in the header of
`05_cost.R`; no script was re-run, because the figure itself was always right.

**Note on the two C.4s.** Appendix C now holds Figure C.4 (gestational age) and
Table C.4 (`tab_estab_practice_style`). Figures and tables carry separate counters,
so this is legal and every cross-reference names one or the other; the overlap
already existed before 2026-09-07 (four figures against four tables) and is not a
numbering bug.

**No em dashes as punctuation.** Checked across `paper.tex`, `sup_appendix.tex`,
`model.tex`, `appendix.tex` and all 31 table files: the only `--` occurrences are
numeric ranges (2014--2024), en-dashed compounds (for-profit--public,
physician--patient, Sun--Abraham), Elsevier's own CRediT terms ("Writing -- original
draft") and the absent-marker dash in fixed-effect rows. All correct; keep them.

## The 2026-09-07 audit (citations, magnitudes, terminology)

A full sweep of `paper.tex`, `appendix.tex`, `model.tex` and `sup_appendix.tex` for
wrong numbers, misattributed citations, overclaims and Portuguese left in English
prose. Six real defects, all pre-existing. **No estimate changed; two exhibits were
regenerated (`tab_ref_c5_feegap_ci`, `tab_org_capacity_valid`).**

**1. 🚨 `card2023` was cited backwards, in four places.** Card, Fenizia and Silver
(2023 AEJ:Policy) find that among LOW-RISK FIRST BIRTHS, infants quasi-randomly
delivered at a HIGHER-cesarean-propensity hospital are born in BETTER condition and
are less likely to be readmitted, because prolonged labor is averted, with the
tradeoff that they present more often later for respiratory problems. The paper said
they "show that being delivered in a hospital with a high cesarean propensity harms
the marginal newborn" and cited them three more times for "cesareans harm newborn
health". The claim they were carrying is supported by `costaramon2018` and
`borra2019`, which now carry it alone; `card2023` is cited for what it actually
finds. **Never cite card2023 for unqualified cesarean harm.**

**2. 🚨 The price calibration was attributed to the wrong paper, and the magnitude
was the small one.** "About one percentage point per US$1,000" is **Grant's (2009)**
re-estimate on corrected data, which he describes as "one-quarter of the effect
estimated originally" by Gruber, Kim and Mayzlin. GKM's own magnitude is therefore
about **four** points per US$1,000. `10_supplement.R` now carries both, converted at
our fee levels to **0.72 pp (Grant) and 2.87 pp (GKM) per log point**, and
`tab_ref_c5_feegap_ci` has two verdict columns. The verdict is the SAME for both
(municipality FE excludes them, state FE does not), and the calibration sentence now
quotes the range: the 0.10--0.35 log-point gap of the largest states moves the rate
by a quarter of a point at Grant's magnitude and **about one point at GKM's**,
against 35. Calibrate against the LARGER one; it is the conservative choice against
our own claim and the claim survives it.

**3. `gruber1996physician` and `gruber1999physician` were described as each other.**
Gruber and Owings (1996 RAND) is the FERTILITY-DECLINE/income-shock paper, not
"substitute toward cesareans when fee differentials widen"; Gruber, Kim and Mayzlin
(1999 JHE) is the fee-differential paper, not a "confirmation" of it.

**4. `spinola2026` does not study bridge weekdays.** Spinola and Rocha study birth
timing around INCONVENIENT DATES (bank holidays, Carnival, medical congresses),
finding manipulation markedly stronger in the private sector and among white
mothers. Verified against the local copy in `parto_cesareo/Literature/`; the words
"bridge" and "long weekend" do not appear in it.

**5. The demand-smoothing overclaim reached the manuscript in three places** (intro,
Section 6D, conclusion), saying establishments that schedule more "show a lumpier
weekly delivery flow" or "have the lumpiest weekly flow". That is exactly what the
evidence taxonomy above forbids: p=0.065, Holm 0.196. All three now say the levelling
prediction is not supported and flag the point estimate as marginal.

**6. Smaller numeric and wording fixes.** "roughly five times wider" for the
state-versus-municipality intervals was **2.6x** (now "about three times");
"one in ten of all weekday cesareans" is one in ten of the SECTOR's;
"prelabor cesareans mass exactly at [37--38 weeks]" is false (their mode is 39, see
the Figure C.4 entry above); Robson-1 public weekday rate is **36.8 percent**, not
"roughly one third"; `gans2009` is a transfer/bonus paper, so it no longer supports
"holiday incentives".

**Verified correct, do NOT "fix" these:**
- **"twenty-two states" and "twenty-seven clusters" are BOTH right.** Panel A (levels,
  municipality-year, TISS deliveries >= 20) has 27 state clusters; Panel B (state-year
  first difference, n > 2000) has 22. Different samples.
- **The fee facts are right.** The state gap must be computed as
  `log(mean fee_cesarean / mean fee_vaginal_econ)` WITHIN the state, not as the
  delivery-weighted mean of the municipality log gaps, which is Jensen-biased toward
  zero and gives about -2% for SP. Done correctly: SP -15.1%, MG -27.7%, PR -13.2%,
  RJ -9.3%, SC -11.6%, RS -13.8%, i.e. the "10 to 30 percent" and the "0.10 to 0.35
  log point" of the text.
- `parfitt2026` is described exactly right, "conditional on physician attendance"
  included (verified against the published abstract).
- Public cesarean 36.9% (2010) to 51.3% (2024); no-indication share 87.2--91.2%;
  timing missing 16.0%; displacement window -8.33 pp prelabor share against -0.05 for
  the overall cesarean share; median cesarean bills 4.6% more. All match the text.

**7. `molitor2018` was cited for the opposite of what it finds, in the policy
conclusion.** Molitor (2018) exploits cardiologist MIGRATION and finds that a
physician's behavior adjusts 0.6--0.8 percentage points for each point of change
in the practice environment, so the ENVIRONMENT explains 60 to 80 percent of
regional variation. The conclusion cited him for "practice styles travel with
providers rather than with patients", which is the reverse. The sentence now states
his actual estimate, and the policy argument is STRONGER for it: if the environment
dominates, organizational arrangements are exactly the lever. Note that the two
OTHER uses of `molitor2018` (contribution block and Section 7, "supply-side
practice patterns dominate patient case-mix") are accurate and were left alone.

**8. Model appendix.** P3's cross-reference pointed at `sec:mechanism`, the whole
section, instead of `sec:capacity`; it now points at the label and states that the
prediction is supported for obstetrician density and only weakly for establishment
capacity. P4 said scheduling shifts prelabor cesareans "to 37--38 weeks" (their
mode is 39; the shift is relative, see the Figure C.4 entry). P5's heading
"Supply, not demand" claimed more than the education split delivers and now matches
the body's hedge.

**Verified clean, so do not re-audit:** all 52 bib entries are cited and all 52
citations resolve, with zero orphans and zero bibtex warnings in both documents;
`costaramon2018` (time-of-day instrument driven by physician leisure, causal
negative effect on Apgar and cord pH) and `borra2019` support the newborn-harm
claim they now carry alone; metadata on `currie2008`, `finkelstein2016`,
`cutler2019`, `betran2021`, `sun2021`, `clemens2014`, `maibom2021` all check out;
the eight fixed and four Easter-based movable holidays match `holiday_dates()`;
21 two-day placebo pairs is C(7,2); highlights are all under 85 characters; the
declarations block is complete in the Elsevier order. The metadata sweep of
2026-08-20 (`parto_cesareo/Literature/verificacao_citacoes.md`) covered titles,
volumes and pages; THIS sweep covered what the papers actually say, which is where
every defect above was hiding.

**9. `fischer2026` added (2026-09-07).** Fischer, Kaneko, Royer and White,
"Disentangling sources of variation in C-section rates", AEJ:Policy forthcoming
(NBER WP 34469, doi:10.1257/pol.20260196). US birth records 1989--2019, with the
delivery location instrumented by closures of a county's LAST obstetric unit,
which push mothers to counties with different baseline rates. **A one percentage
point higher cesarean rate in the delivery county raises a mother's own cesarean
probability by about one point**, so the delivery environment passes through nearly
one for one. This is the cesarean-specific causal version of the paper's own
practice-style claim, it is in a journal a JHE referee reads, and it was missing.
Cited in three places: the geographic-variation list in the contribution block,
the Kitagawa paragraph of Section 7 (with the magnitude), and the conclusion's
policy argument alongside the corrected `molitor2018`.
⚠️ **It is FORTHCOMING.** The entry carries `year={2026}` and a `note` saying so;
fill in volume, issue and pages before submitting, since it will very likely have
appeared by March 2027.

**Terminology.** `natureza jur\'idica` is now **"legal-entity type"** everywhere, in
prose and in generated notes; the calque "legal nature" was also replaced (paper
twice, appendix twice). Shouting caps swept from every note and from the prose: the
only survivors are real acronyms (ICD, BH, TUSS, DOW, FP).

## The 2026-09-09 revision (orphan claims and dangling pointers)

A sweep for statements the manuscript makes but never shows, prompted by two of
Fredie's own catches. Seven defects, all pre-existing, all text except the last.
**No estimate changed. One exhibit regenerated (`tab01_descriptives`), and only
block 2 of `01_descriptives.R` was re-run.**

**1. The two bare "Supplemental Appendix" pointers in the model.** P5's
`[Tested: maternal-education interaction, Supplemental Appendix.]` named no
exhibit, and **P3 had the same defect** ("municipality obstetrician density in the
Supplemental Appendix"). Both point at the same table and now use
`\satab{tab:heterogeneity}`, which prints "Supplementary Appendix Table D.11".
These were the manuscript's ONLY exhibit-less appendix pointers; the ones in
`paper.tex` all name their table or figure. Note that `model.tex` reaches the
build only through `paper.tex` -> `appendix.tex`, so `\satab` is defined there.

**2. 🚨 The admission-count sentence was describing machinery the paper never
uses, and it is gone.** Appendix B said "Because a TISS event can bundle several
inpatient days, a plain event count understates admissions; where an admission
count is needed we use the ratio of the billed daily-visit items to the mean
length of stay, which reproduces the regulator's published figure." **No admission
count appears anywhere in the paper, the appendix, or the supplement.** Deliveries
are counted one event per delivery (`n_deliveries = .N` in `02_deliveries.R`), and
the suggestive neonatal check counts CONS rows (`.N`), not weighted admissions --
its own table note already says "TISS hospital events". The proxy is real but is a
BUILD-TIME validation only: `admission_weight()` / `estimate_admissions()` in
`build/00_utils.R` reconstruct about 8.9M (aggregate ratio) and 9.4M (per-event
ratio) hospital admissions for 2023 against the roughly 9.2M the ANS publishes.
That check belongs in the replication package, not in the manuscript. Proof the
sentence was orphan: after removing it, "length of stay" appears nowhere in any
`.tex`. Do NOT reintroduce it unless an admission count actually enters a result.

**3. The covariate list named two variables that enter nothing.** The data section
said IEPS supplies "gross domestic product per capita, household income per
capita, population ... which enter the fee regressions as controls for local
income, market size, insurance penetration, and health-system quality".
`inc_pc`, `pop_total` and `esf_cov` are built into `main_data.parquet` and are
**used by no analysis script**, while obstetrician density, which IS a control,
was missing from the list. The sentence now names exactly the four controls of
`02_regressions.R` (log GDP per capita, plan coverage, adequate prenatal care,
obstetricians per 1,000 births), which is also exactly what Table C.1 reports.

**4. "No jump in the fee series" had no exhibit.** Section 5 closed with "the 2015
court order to triple vaginal pay produced no jump in the fee series and no change
in the cesarean rate". It is TRUE in the data (delivery-weighted log fee gap
-0.069 in 2015, -0.061 in 2016, -0.090 in 2017), but **no figure or table in
either document plots a fee series over time**, and no script tests the court
order. The sentence now rests on the institutional fact Section 2 already
documents: "The 2015 court order to triple vaginal pay never became a price shock
at all: the agency appealed, no rule issued, and relative fees never changed." If
a referee wants the series, the numbers above are the ones to plot.

**5. The six-hour cap on labor assistance is not in the data.** Section 2 said the
hourly labor-assistance fee is "billed up to six hours". Checked in the TISS DET
files, code 31309038: the maximum billed quantity is 6 in 2015, 2020 and 2022 and
**4 in the other seven years**, the 99th percentile is 4 in every year, and the
mean is 2.74 hours (which is the ~2.7h the dictionary records). The text now says
"a separately billed labor assistance fee for each hour spent attending labor",
which is what the schedule does and what the data support.

**6. "Neonatal admissions" -> "neonatal hospital use"** in `paper.tex` and
`sup_appendix.tex`. The outcome counts TISS hospital events, as the table's own
note and title already said; with defect 2 removed, "admissions" was the last
loose usage.

**7. The abstract claimed a cost the paper does not find.** It said unnecessary
cesareans "raise maternal morbidity, neonatal respiratory complications, and
costs", while Table C.5 finds near-parity in billed amounts (median cesarean bill
4.6% higher) and the conclusion locates the cost "in earlier, riskier births
rather than in spending". "and costs" was dropped FROM THE ABSTRACT ONLY. The
intro keeps it, because there it is the system-level claim and is cited
(`sandall2018`, `boerma2018`).

**8. Table C.1 lost two orphan rows.** `mean_los` ("Length of stay (days)") and
`any_uti_share` ("Share of deliveries with any ICU day") were reported in the
summary statistics and appeared in no regression and no sentence. Removed from
`vars` in `01_descriptives.R` block 2. Only block 2 was re-run (it reads the
11.5k-row `main_data`, never the 42M-row birth file), and `tab01_descriptives.tex`
came back **2 deletions, 0 insertions**: every remaining number byte-identical.
"ICU" now appears in no `.tex` in the project.

**Build after all of it:** paper 37 pages, supplement 28; 0 undefined references
and 0 undefined citations in both; the same two documented pre-existing overfull
boxes. Exhibit numbering unchanged (`tab:descriptives` C.1,
`tab:estab_practice_style` C.4, `tab:heterogeneity` D.11).

**Typographic sweep the same day (Fredie's three questions).** All three were real
inconsistencies, and the sweep found two more. Everything below was applied **to
the R source AND to the generated `.tex` with the identical string**, so no
42M-row script was re-run and a re-run cannot silently revert any of it.
- **"FE" vs "fixed effects."** 15 tables spelled it out, 2 did not
  (`tab_demand_smoothing` D.10, `tab_ref_c5_feegap_ci` D.14). Both now spell it
  out. In `10_supplement.R` the strings are the NAMES of the `specs` list, which
  become the row labels; they are consumed generically through `names(specs)`,
  so renaming them is safe.
- **"SE" vs "Standard errors."** 13 tables used the full sentence, 3 used "SE"
  (`tab08_mechanism_checks` C.3, `tab14_neonatal_suggestive` D.6,
  `tab_ref_c6_fee_base_econ` D.15) -- and those same 3 were the only ones that
  never said the errors are **in parentheses**, which they are. One rewrite fixed
  both. ("SEs" appears nowhere; the note Fredie saw was one of these three.)
- **Table type size.** Measured from the PDF word boxes rather than by eye:
  against a 10.9pt baseline, `tab_org_capacity_valid` (D.9) was printing at
  **6.3pt**, `tab13_referee_robustness` (D.1) at 6.5, `tab_org_capacity` (D.8) at
  7.8 and `tab_ref_c5_feegap_ci` (D.14) at 8.5, all because `\resizebox` had
  shrunk them to the text width. All four are ≥6 columns, so the repo's own
  convention already called for landscape; they are now `sidewaystable` and print
  at full size. The supplement went 28 → 29 pages. **A regression table never
  becomes a figure**; rotation is the fix.
- Two more found in the same pass: `-6.5 pp` written out as "percentage points"
  in the inline note of `tab_ref_c3_robson_validation` (D.13), and the two
  capitalized interaction labels of `tab10_heterogeneity` (D.11) lowercased.
- After it: every table prints at 9.9-10.9pt except D.6 at 8.1pt; paper 37 pages,
  supplement 29; 0 undefined references and 0 undefined citations in both; one
  overfull box each, the documented pre-existing ones; every exhibit number
  unchanged.

**Working-paper build added.** `latex/build_wp.sh` produces
`latex/Born_on_Schedule.pdf`, a SINGLE document = paper + Appendices A/B +
Supplementary Appendix C/D/E, for circulation as a working paper. It is
GENERATED, never hand-edited: the script derives `Born_on_Schedule.tex` from
`paper.tex` at build time (preamble minus `xr`/`\externaldocument`, with
`\satab`/`\safig` redefined as plain `Table~\ref`/`Figure~\ref` since the
supplement is now internal), then appends `\input{sup_appendix}` after
`\input{appendix}` so the section counter continues into C, D and E on its own.
One bibliography serves all of it (`holm1979` and `benjamini1995` are cited in
the body as well as in Appendix D). Editing `paper.tex` or `sup_appendix.tex` and
re-running the script is the only supported way to update the working paper.

**The working paper differs from the submission in exactly two places, and both
live in `build_wp.sh` under the `WP_EDITS` marker** (added 2026-09-09, Fredie's
request): a dated title page (`\date{This version: September 2026}`, overridable
with the `WP_VERSION` environment variable; `paper.tex` carries a bare `\date{}`,
which is right for the journal), and a data-availability sentence that offers the
replication package "from the corresponding author on request" rather than "to
editors and referees", who do not exist for a working paper. The commitment
itself is unchanged. Both are applied by a `perl -0777` pass over the GENERATED
`.tex`, never to `paper.tex`, and both are **guarded**: the script dies with a
non-zero exit if either pattern fails to match, so a future edit that moves the
text cannot silently produce a working paper without them (tested).

## The 2026-09-14 revision: posted as a working paper on SSRN

The `build_wp.sh` edition, `Born_on_Schedule.pdf`, is now circulating as a
working paper on SSRN:
<https://papers.ssrn.com/sol3/papers.cfm?abstract_id=7437660>. This is a
distribution event, not a content revision — nothing in `paper.tex`,
`sup_appendix.tex`, the code, or any exhibit changed. `paper.tex` (the journal
submission) carries no date and no SSRN reference; only the working-paper
edition does, via the dated title page in `build_wp.sh`'s `WP_EDITS` (see
above). If the manuscript is revised before or during JHE review, re-run
`build_wp.sh` and re-post to SSRN as a new version rather than editing the
posted PDF by hand.


## 2026-09-27 — code audit: two open decisions (Claude, nothing changed yet)

Audit for wrong variables and wrong samples, on the same patterns as HeatCrime,
HealthHeat and WorldCupHealth. **Nothing was edited or re-run here**; both items
move the paper's numbers and are Fredie's call.

1. **Sector is time-invariant and "ever for-profit" wins.** `.cnes_sector_sets()`
   in `build/01b_sinasc_cnes.R` puts an establishment in the for-profit set if it
   EVER appeared with a 2xxx legal nature, and the priority is for-profit >
   nonprofit > public. 5.9% of births are in establishments whose legal nature
   changed over 2015-2024. **430,348 births labelled Private (4.8% of the group)
   took place in a year the CNES listed the establishment as public (267,116) or
   nonprofit (163,232)**; 387,052 labelled Nonprofit were in public years. Public
   has no contamination (the priority protects it). Likely effect: a lower
   for-profit cesarean rate and a slightly attenuated Eq. (3) differential.
   Fix: sector by establishment AND year, with the ever-set only for years the
   CNES file does not cover (before 2015, 3.3M Private births have no same-year
   record).
2. **Prelabor vs in-labor: the missing field is handled two different ways, both
   wrong.** `cesarea_antes_parto` is missing for 97.2% of cesareans in 2010,
   45.6% in 2011 and 1-7% afterwards. `03_mechanisms.R` and `10_supplement.R`
   build `ces_pre` with `==`, so one missing value makes the whole
   municipality-day-sector cell NA and fixest drops it: **10.6% of cells and
   21.4% of births** vanish from Table 8, almost all of 2010-2011 and the largest
   cells. `07_main_specification.R` sets the NA to 0 but estimates the prelabor and
   in-labor columns on 2012+ only (lines 114-115), as does `08`; so the 2010-2011
   concern applies to `03` and `10`, not to the main specification (corrected
   the same day). Within 2012+ the open question is what to do with the 1-7%
   missing and 3-7% ignored (code 9), which every script counts as neither
   prelabor nor in-labor. Fix, one of: drop births
   with a missing field from the prelabor/in-labor outcomes only (share among
   cesareans with the field recorded), or restrict the decomposition to 2012+.
   Either way the three scripts must use the same rule.

Checked and right: cesarean = `tipo_parto == 2` among vaginal/cesarean births,
Robson codes stored as "01"-"10" (the filters match), no subset `.I`, no
`cbind` of model output.

## 2026-09-27 — fixes applied (code) and text pending the re-run

Fredie approved: sector by establishment-year; prelabor/in-labor on 2012+ with the
07 convention (missing or ignored timing counts in neither numerator).

Code changed (not yet run; queued after HealthHeat and WorldCupHealth):
- `build/01b_sinasc_cnes.R`: `assign_sector_year()` and `reassign_sector_births()`
  (sector = legal nature at the last competencia of the birth's year; nearest
  covered year otherwise; caches of 08, 09, 14 removed so they rebuild).
- `03_mechanisms.R`, `10_supplement.R`: `%in%` and `year >= 2012` for the timing
  outcomes; Robson-1 decomposition note no longer says "entirely in-labor" (the
  remainder is missing-timing cesareans); missingness table on 2012+; Table 8 note
  gives each column's years.
- `07_main_specification.R`: Table 2 column 3 (Robson shares) on 2014+, the years
  the classification exists; the sample row says so.
- `10_supplement.R`: sample-flow row counted every vaginal birth plus the valid-code
  cesareans (23.6M) under a "cesareans" label; now "cesareans" and "valid code,
  2012+" as two rows.
- `09_org_capacity.R`: family E now includes the two delivery-scale interactions.

Text changed now: Section 6.3 (reference category of columns 2-4; the 1.7-point
weekend-holiday dip is column 1 and not significant, s.e. 1.2); "highest documented
for any large health system" replaced by the Boerma et al. (2018) fact (only the
Dominican Republic has a higher national rate among the 85 countries with >95%
facility births), introduction (the abstract keeps Fredie's original sentence, at his request, 2026-09-27).

Text to rewrite AFTER the re-run (numbers move): Table D.19 paragraph in
`sup_appendix.tex` (family D: bridge 0.031 -> Holm 0.092, three-day 0.015 -> 0.061,
isolated and pre-holiday lose 10% significance; and family E now has four tests);
"delivery-scale margin is estimated precisely/sharply" (pp. 24 and 35; the preferred
column has 0.0070, s.e. 0.0039, 10% only); Table 2 column 3 sentence; the 80%/79%
for-profit rate; the ~39k excess weekday cesareans (and CONTEXTO_PESQUISA.md, which
still says ~50k and "a maior taxa documentada").

## 2026-09-27 — re-run done; numbers and text updated

Run: CNES beds 2012-2014 downloaded state by state (`cnes_beds_2012_2014.parquet`;
all 27 states x 12 months; NAT_JUR exists from June 2012, so 2010-2011 take 2012);
`reassign_sector_births()` (1.65M births, 3.9%, changed sector against the "ever"
rule); `03_workfile`; analysis 01-14 in master order. **A July-10 model cache,
`analysis/output/m_tax_slim.rds`, had frozen Panel A of the long-weekend table**:
removed (copy in the session scratch) and 08 and 10 re-run. `03_mechanisms.R` no
longer types the 8.3 and 2.3 of the counterfactual reconciliation; it reads them.

What moved (old -> new):
- Eq. (3), for-profit x weekend / holiday: -2.29 / -2.85 -> **-1.78 / -2.49**
  (col 2: -1.82 / -2.36; col 3, 2014+: -1.49 / -1.68; prelabor -4.74, in-labor +2.88).
- Own gradients, for-profit weekend / holiday: -8.3 / -5.6 -> -7.9 / -5.3 (public
  unchanged). Prelabor / in-labor dip: -9.7 / +1.7 -> -8.9 / +1.9.
- Early-term +11.7 -> +12.2; Kitagawa 35.1pp, 72% -> 36.2pp, 73%; excess weekday
  cesareans ~39k -> ~35k (9.3% of ~380k); for-profit SINASC rate 79% -> 80.7%.
- Organizational capacity (preferred col 2): scale 0.0070* -> 0.0064 (n.s.); beds
  n.s. **No capacity interaction is significant with muni x date FE**; text no
  longer calls capacity a "fingerprint" (three fingerprints now) and says so in the
  introduction, Section 6 and the conclusion.
- Demand smoothing: forward demand on the cesarean share -0.41** (was n.s.); flow
  dispersion 0.27 (p 0.065) -> 0.32 (p 0.033). Both at 10% after Holm.
- Long weekends, Panel A (re-estimated): bridge / three-day / isolated, col 2:
  -0.8 / -1.4 / -1.8; prelabor 3.4-4.0 lower; equality p 0.55, 0.69; weekend holiday
  -1.8 (1.4). Family D: unadjusted p 0.049-0.072, Holm 0.198.
- Preterm for-profit weekend differential +0.8 (n.s.) -> +1.5 (p<0.05); mothers 35+
  +1.3 (n.s.) -> +1.7 (p<0.10). Supplement text rewritten.

Text: paper.tex (abstract, introduction, Sections 5-7, conclusion), sup_appendix.tex
(subgroups, capacity variants, demand smoothing, D.19 paragraph), highlights.
Compile: paper 37 pp, supplement 29 pp, 0 undefined. One overfull vbox (46pt) in the
supplement and one 2.8pt hbox in the paper's AI declaration were already there
with the old tables and text (checked by compiling the committed version).

RESOLVED (Fredie, 2026-09-27): the abstract now reads "among the highest rates
recorded in any health system". No comparative footnote: the official Egypt (CAPMAS
EFHS 2021) and Dominican (EnHogar-MICS 2025) reports could not be retrieved and
verified, and a footnote on press figures would invite the referee question it is
meant to prevent. Earlier note, kept for the record: the abstract kept "the highest rate documented for any large
health system" at his request; Egypt (2021: 72% national, ~80% private, a large
system) contradicts it even with "large". Proposed: "among the highest rates
recorded in any health system".

## 2026-09-27 (second pass) — full code audit, SINASC from DATASUS

A line-by-line read of every build and analysis script, tests against the data,
and a number-by-number reconciliation of the text. Everything below is fixed in
code and rerun.

| Finding | Size | Fix |
|---|---|---|
| TISS deliveries typed by fee > 0 | ~15% of delivery events dropped (49,215 in 2016); TISS cesarean rate 82% → 84% | type from the TUSS code (`build/02`), fee NA when absent; fee means weighted by the deliveries they average |
| Wild bootstrap of Table 1 never ran (inline subset in `boottest`); table printed a typed 0.210 | p is 0.32 | sample as an object; no fallback |
| Robson used in 2011–2012 (the field is partly filled there in the source) | Robson 1–2 dip 7.1 → 7.0, Robson 1 6.4 → 6.0 | every Robson analysis 2014+ |
| Apgar 99, weight 9999, mother's age 99 read as values | 22,771 / 66 / 449 births | `valid_*()` in `00_utils.R` |
| Base dos Dados has no time of birth in 2022 | whole year absent from the hour exhibits | SINASC now from the DATASUS FTP (`build/01e_sinasc_datasus.R`); every other field agrees with the old extract to the second decimal |
| Demand smoothing: weeks with no birth missing | 6% of establishment-weeks | zeros within each establishment-year; Panel A's −0.41** on the cesarean share disappears; dispersion 0.31 (0.16), 10% only, not after Holm |
| Holiday calendar copied into 7 scripts, none with 20 Nov 2024 | one day | one `holiday_dates()` in `00_utils.R` |
| Notes and text with numbers no code computed | "2.7 hours at R$409" (2.9 h at R$420), "10–30% less" (18–38%), "two log points" (1.4), "unchanged at 2.08" (2.83), "cannot distinguish" next to p = 0.04 (now p = 0.006), "87–91% no indication" (77–81% under the stated rule) | computed in the scripts, text updated |
| Robustness column "time-varying sector" redundant once the sector is by year | — | now the "for-profit in any year" rule |
| Map C.2 captioned as SINASC for-profit, drawn from TISS | — | caption and text say private-insurance |
| Parto Adequado hospitals with a leading zero unmatched | 3 of 112 | match on the 7-digit code |
| Caches without invalidation (08, 09, 14) | — | rebuilt when the birth file is newer |

Body numbers: Equation (3) −1.8/−2.5 (unchanged), own gradients −7.9/−5.3 vs
−6.7/−3.5, prelabor −8.9 vs in-labor +1.9, early-term +12.2, Kitagawa 73% of 36.2pp,
~35,000 excess weekday cesareans. Table 1: +0.049** / −0.014* without controls,
+0.019 / −0.013 with them; bootstrap p 0.32 and 0.17.

## 2026-09-28 — external referee comments on the old draft; new analyses (Claude, approved by Fredie)

- **Robson timing table** (`tab:robson_validation`): the 0% prelabor share in groups 1 and 3 is by construction (DATASUS derives the Robson group from the labor-onset and prelabor fields; 2020 crosstab: exactly zero prelabor cesareans and zero inductions in G1/G3). Caption, in-table sentence, note (`10`), supplement paragraph and the body pointer no longer call it a validation.
- **Table C.1**: now the fee-regression sample (≥20 private deliveries, defined gap), weighted by deliveries, weighted percentiles; note gives the unweighted mean (+0.21) and that 57% of deliveries sit where the cesarean pays less. No filter error: the old +0.23/0.24 was the unweighted mean over all muni-years. Sentence added in Section 5.
- **CNES link**: the 84% was all of 2015 (lagged capacity, panel opens 2015); 2016–2024 95.4%, weekdays 95.3 / weekends 95.4. Note in `09` now says so.
- **Eq. (3) within the establishment** (`15_estab_gradient.R`, new supplement table `tab:estab_gradient`): −0.95 / −1.26 weekend (birth / fixed weights) vs −1.79 on the same births in cells; about half is reallocation across establishments (any birth −8.7pp; prelabor count −34 lp; vaginal −6 lp). Intro sentence, body paragraph in 5.1, supplement subsection, and the abstract ("about half of it within establishments").
- **Early-term share inside Eq. (3)**: −1.35pp (Robson 1–2 −0.69, 10%). Section 7.
- **LBW / low Apgar within Robson 1–2 at term** (Table 5 cols 5–6): −1.06 / −0.39 against −3.47 / −0.63. Section 7.
- **Availability fee** (CFM Parecer 39/2012; ANS 407th board meeting, 7/10/2014, item 5, and the ANS consumer page): paragraph in Section 2, two sentences in Section 5 with the 4.5% of TISS deliveries carrying no physician fee (new block in `01`), three new references.
- **Framing**: contribution paragraph moved to the 3rd paragraph of the introduction with Spinola & Rocha and Melo & Menezes-Filho; conclusion separates relative price from the structure of pay.
- Abstract 247 words (trimmed "maternal and newborn survival" to "survival gain" to stay under 250). Build: paper 39 pp, supplement 31, WP 67, 0 undefined, 0 overfull hbox.
- Independent re-implementation of Table 2 col 1 (own holiday calendar, own aggregation): −1.789 (0.623), −2.549 (0.507), −1.059 (0.336), N 5,038,435 — exact.

## 2026-09-28 — external consistency check: 19 items (Claude, requested by Fredie)

Fredie supplied a list of 19 inconsistencies read off the compiled PDFs. Each was
checked against the tables, the code and the data. 18 were real; one (item 8)
was right in the paper and wrong in the `birth-health-econ` skill.

| # | Item | Verdict | Fix |
|---|---|---|---|
| 1 | 35k (text) vs 37k (footnote) | real: two different computations, footnote presented 37k as "the benchmark" | footnote now gives both and says why they differ |
| 2 | 2.9 h vs 2.7 h | real: `model.tex` missed by the 09-27 fix (recomputed: 2.93 h, R$420, 38.3%) | 2.9 |
| 3 | "group 10 ... cannot" be scheduled | real: Fig 3 note, intro, Sec 6.2, Table C.3 note, a code comment in `12` | rewritten as "less often chosen in advance"; not a placebo |
| 4 | Fig C.2 "2010–2024" | real: code uses 2014–2024 | note |
| 5 | capacity "precise" (App A) vs "none significant" (Sec 6.4) | real, and the body was the wrong one: beds and scale are collinear; each alone is significant under muni×date FE (D.9 col 5; D.10 cols 1, 4, 5) | intro, Sec 6.4, P3, family-E sentence |
| 6 | Robson 1: −1.3 of −6.0 is uncoded | real: missingness inside G1 is 11.2% weekday vs 9.8% weekend (the D.19 balance is sector-level) | body, D.14 note, D.19 note (computed in `10`) |
| 7 | −20pp low-education dip | **code bug**: cells split by education, no education main effect; the level gap leaked into the weekend terms | `04` and `10` family B: add `educ_hi`; dips −11.2 / −7.2; family B estimate 0.1356 → 0.0401 (p still <0.001) |
| 8 | Elejalde 8.6 vs 4.6 | paper right: JHE 2021 (v.75) abstract says 8.6pp; 4.6/8.7 are the 2019 IZA DP | skill map corrected |
| 9 | Robson 5 goes the other way | real: 95.3% vs 79.9% weekday rate (ceiling) | Sec 6.2 and intro name it; printout added to `12` (not re-run; same numbers computed ad hoc) |
| 10 | sample flow implies 78% | real: the cesarean row (all years) was indented under the 2014+ Robson row, introduced by the 09-27 fix | rows un-nested, 2012+ row added (12,823,213) |
| 11 | D.16 ≠ Table 1 | real: D.16 rebuilt its own cells from event files | D.16 cols 3–4 now ARE Table 1 (0.0488 / −0.0141, N 5,198); base cols on the same sample: 0.0366* / −0.0176**; title no longer says "null" |
| 12 | Table 5 N | real: maternal race is missing on the same 2010–11 schedule as gestational age (3% / 58% recorded) | note (computed in `05`) |
| 13 | court order as evidence | real | intro and P1 no longer use it; App E no longer claims a fee series |
| 14 | "did not move" vs Melo −1.6pp; "municipal trend seven years" | real | third contribution rewritten |
| 15 | composition check | real | Sec 4.4: a weaker fourth check, cannot bound selection |
| 16 | clean-sample cross-ref | real | D.2 |
| 17 | D.9 2015 vs D.10 2016 | real: lag makes 2015 unlinkable | D.9 note 2016–2024 |
| 18 | holidays | real: four DATES, three holidays; Carnival and Corpus Christi are federal optional days, Good Friday a municipal religious holiday (Law 9,093/1995) | App B, D.8 note, Sec 6.3, `00_utils.R` comment |
| 19 | rounding and "aggregate" | real | 81% for-profit in abstract, intro and highlights; TISS 82–86% by year; "at for-profit establishments" |

Re-run: `04_heterogeneity.R` in full; `10_supplement.R` blocks B, D, F and K.
Tables changed: tab10_heterogeneity, tab_multiple_testing (family B row 2),
tab_ref_c3, tab_ref_c6, tab_ref_c12_sampleflow, tab_ref_c12_missingness; text-only
edits applied to both the R source and the generated .tex of tab08, tab09,
tab_org_capacity and tab_displacement_robust. Build: paper 40 pp, supplement 32,
WP 70, 0 undefined; the supplement's pre-existing overfull vbox is now 58pt (was 46).

Why the earlier audits missed them: see the "classes that survived" section added
to the `manuscript-audit` and `code-audit` skills the same day. In short: fixes
applied to the body but not to every carrier (model appendix, figure notes, table
notes, code comments); a pending-rewrite list (09-27, "pp. 24 and 35") closed only
in part; exhibits that claim to reproduce each other never diffed; stated sample
windows never compared with the estimation sample; nested accounting rows never
tested as subsets; an implausible implied magnitude (−20pp against a −7.9pp mean)
never compared with the raw contrast; figures never read group by group against
the claim they support; and CLAUDE.md itself carrying stale numbers (39,135;
"scale only with date FE") that steered the audit.

## 2026-09-28 (second referee round) — price of time, balance, identifying sample

Referee points 1, 3, 4 and 6 (point 5's non-obstetric surgery placebo deferred by
Fredie). Approved by Fredie: new abstract, introduction and highlights; title kept.

- **Fees per hour** (`16_design_checks.R` block A, new Table D.19
  `tab_fee_per_hour`): cesarean R$1,939 per procedure; labor hour R$420; a vaginal
  delivery pays less per hour than a one-hour cesarean beyond 1.25 h (1.22–1.62 in
  the five largest states; 2.5 h if the cesarean takes two). Section 5 rewritten:
  per delivery vs per hour, calibration first, regressions "consistent but less
  precise", measurement-error attenuation stated, sign flip demoted.
- **Balance** (block B, `tab_balance`): 10 predetermined characteristics plus
  newborn sex on the left of Eq. (3), in SD units. All |b| <= 0.040 SD (multiple
  pregnancy); previous cesarean −0.022, first birth +0.023, i.e. the direction
  scheduling predicts; male newborn +0.0055 SD (0.3 pp), significant only through
  5M cells. Cesarean benchmark −0.036 SD. Sentence in Section 4.4.
- **Identifying sample** (block C, `tab_ident_sample`): 461 of 733 municipalities
  with a for-profit birth; 74.1% of for-profit and 56.4% of public births; own
  gradients there −7.1 / −5.3 vs −7.9 / −6.7 on all days; Eq. (3) on those days
  reproduces Table 2 col 1 exactly (asserted). Paragraph in Section 4.3; the
  supplement's "339 municipalities" sentence now says it is the ≥50-birth
  establishment panel.
- **SINASC rebuild** (`build/01e`): SEXO, CONSULTAS, CONSPRENAT, MESPRENAT added;
  42,006,849 rows, the 32 existing columns and `sinasc_daily_muni` byte-identical
  to the backup in `build/SINASC/input/_backup_2026-09-28`.
- **Full read of paper.tex and sup_appendix.tex** after the reframing: 17 sentences
  aligned (ownership-specific → common to both sectors with a for-profit increment;
  "lumpier/lumpiest flow" → "no smoother flow", per the guardrail; conclusion,
  roadmap, strategy subsection title "relative-fee channel", business hours equal
  across sectors 50.1/50.9, billed amounts "per delivery", "movable holidays").
- Build: paper 41 pp, supplement 35, WP 74, 0 undefined; abstract 249 words.

## 2026-09-28 (third referee round) — 13 consistency items A–M (Claude, requested by Fredie)

All 13 checked against the code, the generated tables and the compiled PDFs.
Twelve were right and are fixed. M was a reasonable worry that turned out
unfounded (explained in the note now).

- **A. Cesarean fee R$1,963 vs R$1,939.** Both right, different bases: 1,963 is
  the delivery-weighted mean over the fee-regression municipality-years (`10`,
  `fee_c`), 1,939 the mean over delivery events (`16`, D.19, text). The D.17 note
  now reconciles them (`fee_c_ev`, computed in `10`): at 1,939 the benchmarks
  would be 0.72 / 2.87 instead of 0.73 / 2.90.
- **B.** "This split is not an artifact" is now "At the level of the sector...;
  within Robson group 1 ... the balance does not hold."
- **C.** Intro, Parfitt paragraph: "persistent weekly calendar gradient, common
  to both ownership sectors and stronger in the for-profit one".
- **D. Economic vaginal fee definition.** Confirmed in `build/02_deliveries.R`:
  delivery fee + labor-assistance fee, with the assist fee counted as ZERO where
  none is billed, averaged over all vaginal deliveries with a delivery fee (the
  "diluted" reading). D.19 now prints the vaginal fee alone (1,893), and
  splits the economic fee into deliveries billing labor assistance (3,355) and
  billing none (1,778, BELOW the cesarean's 1,939). The note, Section 5 and the
  Appendix B definition say it is an EXPECTED fee. Abstract/highlights say "on
  average per delivery".
- **E. Price of time vs the public gradient.** The abstract no longer says the common
  gradient is "priced by the physician time". Now: most of the gradient is
  common to both sectors and organizational, and the for-profit increment is
  consistent with a price of physician time. Conclusion: shift-based coverage
  "should not be expected to remove the weekly gradient itself"; public
  maternities (on-duty obstetrician) show most of it too. Intro fingerprints
  sentence softened the same way.
- **F/H. Collinearity.** It was wrong. Beds and scale correlate at 0.48 across
  establishment-years. Net of the fixed effects, the weekend interactions
  correlate at 0.64 (col 1) and 0.56 (col 2), a VIF of about 1.4. Column 1 separates the
  two (scale 1.49***, beds 0.47 n.s.). Muni×date FE cut the residual SD of
  the bed interaction by 33% and of the scale interaction by 51%. In col 2 the two are jointly
  significant (Wald p = 0.021). So there is too little variation left, not
  collinearity. `09` now computes all of this and prints it in the D.11 note. The
  text in the intro, Section 6.4 and model P3 is rewritten. `09` re-run: only the
  D.11 note changed; D.12 and `fam_E.rds` are identical.
- **G.** "small in every specification" / "consistent with that calibration" is
  removed from the intro, Section 5 and the supplement text. Now: the estimates
  disagree and do not discipline the magnitude. The within-municipality intervals
  exclude both literature responses from below, and state col 1 (4.9 pp per log
  point) lies above GKM. Even 0.049 × 0.49 = 2.4pp.
- **I. "Unpriced time".** The schedule pays billed labor hours (R$420/h). What
  goes unpriced is on-call availability, uncertain onset and unbilled hours. The
  intro, Section 5 and the conclusion now say so. They also name the hourly
  labor-assistance fee as the one fee lever on the time margin, which the data do not evaluate.
- **J.** Dangling "instead" removed from the conclusion.
- **K.** "Most vaginal deliveries bill none" now reads "62 percent nationally,
  between 30 and 82 percent in the five largest states" (text and D.19 note).
- **L.** `placeins` + `\FloatBarrier` after the sideways D.2 and D.17 (both
  preambles; the WP inherits paper.tex's). Order is now D.1 p11 → D.3 p13 and
  D.17 p29 → D.18 p30.
- **M. D.14 density main effect.** Not the education bug. The density measure is one
  value per municipality (mean over years), so its level is absorbed by the
  municipality FE. The note and a code comment now say so.
- Abstract trimmed back to 247 words (limit 250).

## 2026-09-28 (fourth referee round) — abstract wording, ex ante fee, SUS source

- **Break-even per type of vaginal delivery.** The 1.25 h holds for the expected
  fee only. D.19 Panel C gains two rows, computed in `16` block A: 1.73 h
  (billing labor assistance) and 0.92 h (billing none), matching the referee's
  arithmetic. The abstract says "pays more, on average, than a vaginal delivery
  lasting over about 1.25 hours". The intro, Section 5 and the conclusion say
  "average" or "on average" at every per-delivery claim.
- **Ex ante argument + billing norms (Section 5).** The expected fee is the price
  because the mode is chosen before the length of labor is known. The billing
  share runs from 18% (SP) to 70% (MG), and where labor is billed often the base
  vaginal fee is lower. In SP and RJ the base fee exceeds the cesarean's; it is
  about equal in MG and below it in PR and SC. So the expected fee reflects
  billing norms as well as the length of labor, and the paper now says so.
- **Abstract:** "common to both ownership sectors, which we read as
  organizational". The abstract is 247 words. "or protocols" is dropped from the last sentence, and
  "rates recorded" became "recorded".
- **SUS sentence.** "Typically whoever is on duty" is replaced by
  `domingues2014` (CSP 30 Suppl 1: S101–S116, Nascer no Brasil 2011–12), checked in
  the article's PDF. The same professional did prenatal care and the delivery in
  9.1% (primiparas, Table 1) and 9.4% (multiparas, Table 2) of publicly paid births,
  against 77.6% and 76.8% of privately paid ones. The introduction says SUS maternities work with teams "em regime de
  plantão". Cited in the institutional background and the conclusion. Its sectors
  are PAYER (delivery payment source), and the text says "publicly/privately paid".
