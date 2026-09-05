# Born on Schedule: Fees, Supply-Side Scheduling, and Cesarean Delivery in Brazil — Replication Package

**Authors:** Fredie Didier (IDP; corresponding author, fdidier@terra.com.br),
Vinicius Mendes (UFBA, vdmendes@ufba.br), Pablo Castro (UFBA, pablocastro@ufba.br),
Lucas Emanuel (UFBA, lucasemanuel@ufba.br)

## Repository layout

```
config/
  config.R              # <-- THE ONLY FILE TO EDIT (set DROPBOX_ROOT)
  00_master_build.R     # runs the data build
  00_master_analysis.R  # runs all analysis scripts, in order
build/
  00_utils.R            # admission-count proxies, TUSS delivery codes
  01a_tiss.R            # one-time ANS TISS Hospitalar download (CONS + DET)
  01b_sinasc_cnes.R     # one-time SINASC (Base dos Dados) + CNES downloads
  01c_ieps.R            # IEPS municipality-year covariates
  01d_cnes_estab.R      # establishment-year CNES capacity panel (beds + obstetricians)
  02_deliveries.R       # TISS delivery events + municipality-month panel
  03_workfile.R         # merges everything into main_data.parquet
analysis/code/          # 00_utils.R, 01_descriptives.R … 06_robustness.R,
                        #   07_main_specification.R  (Equation 3, the main gradient)
                        #   08_long_weekends.R       (holiday taxonomy + displacement)
                        #   09_org_capacity.R        (establishment-capacity heterogeneity)
                        #   13_demand_smoothing.R    (the de Elejalde-Giolito channel)
                        #   10_supplement.R          (Supplemental Appendix exhibits)
                        #   12_subgroups.R           (Robson / gestational-age / maternal-age splits)
                        #   11_body_figures.R        (merged multi-panel body figures; needs 12)
analysis/output/        # tables/, graphs/, maps/ (committed)
latex/                  # paper.tex, model.tex (Appendix A), appendix.tex (A+B),
                        #   sup_appendix.tex (shared body of Appendices C+D),
                        #   supplement.tex (standalone Supplemental Appendix), refs.bib
dictionary/             # ANS TISS dictionaries + variable_dictionary.xlsx (build_dictionary.R)
```

## Data

The microdata are **not** in this repository. They live in a (Dropbox) folder:

```
<DROPBOX_ROOT>/build/TISS/input/        raw ANS TISS claims (CONS/DET parquets, 2015–2025)
<DROPBOX_ROOT>/build/TISS/output/       delivery event workfiles + muni-month panel
<DROPBOX_ROOT>/build/SINASC/input/      sinasc_births.parquet (2010–2024) + daily extract
<DROPBOX_ROOT>/build/CNES/input/        hospital beds, obstetrician counts, establishment panel
<DROPBOX_ROOT>/build/IEPS/{input,output}/   municipality covariates
<DROPBOX_ROOT>/build/covariates/input/  Parto Adequado Fase-2 hospital list
<DROPBOX_ROOT>/build/workfile/output/   main_data.parquet (final muni-year dataset)
```

`main_data.parquet` covers 2015–2025 (11,567 municipality-years); the SINASC
extracts cover 2010–2024 (~42M births).

### Data availability statement

All data used in this paper are **public** and were obtained from open government
and open-data sources. None are proprietary or subject to a restricted-use
agreement; access requires only a (free) Google Cloud account for the SINASC
BigQuery query. The raw microdata are redistributed by their original providers,
not by us, so we do not host them in this repository; the build scripts download
them programmatically from the URLs below. The intermediate and final workfiles
live in the Dropbox tree above and are regenerated end-to-end by the build.

### Getting the data — all sources are public

- **ANS TISS Hospitalar** — open data, downloaded by `build/01a_tiss.R` from
  `https://dadosabertos.ans.gov.br/FTP/PDA/TISS/HOSPITALAR/`.
- **SINASC** — via [Base dos Dados](https://basedosdados.org/dataset/48ccef51-8207-40ee-af5b-134c8ac3fb8c)
  (BigQuery; the targeted 24-column query is documented in `build/01b_sinasc_cnes.R`;
  requires a Google Cloud billing project), then ingested by `ingest_sinasc()`.
- **CNES** (beds via `datazoom.saude`; professionals via `microdatasus`) —
  downloaded by `build/01b_sinasc_cnes.R`. The establishment-year capacity panel
  used by the organizational-capacity analysis is built by `build/01d_cnes_estab.R`
  (run once with the environment variable `RUN_01D=1`).
- **IEPS Data** — manual export from `https://iepsdata.org.br`, placed in
  `<DROPBOX_ROOT>/build/IEPS/input/ieps.csv`.
- **Parto Adequado hospital list** — scraped from the
  [ANS Fase-2 PDF](https://www.gov.br/ans/pt-br/arquivos/assuntos/prestadores/parto-adequado-1/projeto_parto_adequado_fase_2_hospitais_participantes.pdf)
  (snapshot 11/02/2019), stored as `parto_adequado_fase2_hospitais.csv`.

### Data citations

The same six sources are mirrored as BibTeX entries in `latex/refs.bib`
(`\cite` keys in brackets) so they appear in the paper's reference list.

- Agência Nacional de Saúde Suplementar (ANS). *Padrão TISS — Troca de Informação
  em Saúde Suplementar, base Hospitalar (CONS e DET), 2015–2025.* Dados Abertos
  ANS. https://dadosabertos.ans.gov.br/FTP/PDA/TISS/HOSPITALAR/ (accessed July
  2026). `[data_ans_tiss]`
- Ministério da Saúde (Brasil), DATASUS. *Sistema de Informações sobre Nascidos
  Vivos (SINASC), 2010–2024.* Accessed via Base dos Dados (dataset
  `br_ms_sinasc`). https://basedosdados.org/dataset/48ccef51-8207-40ee-af5b-134c8ac3fb8c
  (accessed July 2026). `[data_sinasc]`
- Base dos Dados. *Mecanismo de acesso a dados públicos brasileiros (BigQuery).*
  https://basedosdados.org (accessed July 2026). `[data_basedosdados]`
- Ministério da Saúde (Brasil). *Cadastro Nacional de Estabelecimentos de Saúde
  (CNES): leitos e profissionais, 2010–2024.* Accessed via the `datazoom.saude`
  and `microdatasus` R packages (accessed July 2026). `[data_cnes]`
- Instituto de Estudos para Políticas de Saúde (IEPS). *IEPS Data.*
  https://iepsdata.org.br (accessed July 2026). `[data_ieps]`
- Agência Nacional de Saúde Suplementar (ANS). *Projeto Parto Adequado — Fase 2:
  hospitais participantes.* PDF snapshot 2019-02-11.
  https://www.gov.br/ans/pt-br/arquivos/assuntos/prestadores/parto-adequado-1/projeto_parto_adequado_fase_2_hospitais_participantes.pdf
  (accessed July 2026). `[data_parto_adequado]`

## Reproducing the results

First, clone this repository and enter it:

```
git clone https://github.com/FredieDidier/HealthEcon.git
cd HealthEcon
```

Then:

1. **Open the project, then set the data path.** Open `HealthEcon.Rproj` in RStudio
   (or otherwise set the working directory to the repository root) **before running
   anything** — this is what lets `here::here()` and the `source()` calls below
   resolve paths correctly. Then edit the single line in `config/config.R`:

   ```r
   DROPBOX_ROOT <- "/path/to/your/HealthEcon"
   ```

   This is the only path that changes per machine; all repository paths are
   resolved automatically with `here::here()`.

2. **Build the dataset** (skip if `main_data.parquet` already exists):

   ```r
   source("config/00_master_build.R")
   ```

   The two master scripts install any missing R packages automatically (via
   `pacman::p_load()`) before `source()`-ing the individual `build/` and
   `analysis/code/*.R` files, so there is no need to run `install.packages()` by
   hand. The one-time raw downloads (`01a_tiss.R`, `01b_sinasc_cnes.R`,
   `01c_ieps.R`, `01d_cnes_estab.R`) are commented out (or gated behind
   `RUN_01D=1`) in the master script; uncomment them only to (re-)download the
   raw data.

3. **Run the analysis** (writes all tables and figures to `analysis/output/`):

   ```r
   source("config/00_master_analysis.R")
   ```

## Environment and runtime

- **R version and packages:** developed under R 4.4.2 (macOS, aarch64). See
  `sessionInfo.txt` (the attached packages and their versions) and `renv.lock`
  (the full dependency tree with exact versions and sources) at the repository
  root. A fresh machine can restore the exact library with
  `renv::restore()`. If `renv` is not used, the master scripts install any
  missing packages via `pacman::p_load()` at run time.
- **Random seeds:** `set.seed(1)` at the top of every script that bootstraps or
  permutes, so the permutation, few-cluster bootstrap, and any resampling
  exhibits reproduce bit-for-bit.
- **Expected runtime** on a 2021 MacBook Pro (M2 Pro, 16 GB RAM): the data build
  is ~3 h (dominated by the raw TISS download); the full analysis is ~90 min. The
  slowest single script is `07_main_specification.R` at ~40 min, dominated by
  reading and aggregating the 42M-row `sinasc_births.parquet` into
  municipality × date × sector cells; the `fixest` regressions themselves run on
  those aggregated cells and are fast. `13_demand_smoothing.R` is cheap (~1 min):
  it reads only the cached `sinasc_daily_estab.parquet`.
- **Peak memory** ~12 GB, driven by loading the birth-level SINASC file (42M
  records) into memory before aggregation. Do **not** run two of the large
  birth-level scripts (`03`, `05`, `06`, `07`, `08`, `09`, `12`) concurrently — each
  loads `sinasc_births.parquet` and two together exhaust memory. The master
  analysis script runs them sequentially.

## Program-to-output inventory

Every script re-sources `config/config.R` and its utils, so scripts can also be
run individually. **Order matters at the tail:** `07`/`08`/`09`/`13` each save a
hypothesis family (`analysis/output/fam_{A,D,E,F}.rds`) that `10_supplement.R`
reads for the multiple-testing table; run them in that order (`13` before `10`). `08` also builds
`graphs/fig_long_weekend_event`, the displacement event study now shown in the
Supplementary Appendix. `12_subgroups.R` runs **before** `11` despite its number:
it saves `analysis/output/robson_grad.rds`, the coefficients `11` draws as panel
(c) of Figure 3.

Body exhibits are **bold**. Everything else is Supplemental Appendix.

| Script (`analysis/code/`) | Paper exhibit(s) | Output file(s) in `analysis/output/` |
|---|---|---|
| `01_descriptives.R` | **Figure 1** | `graphs/fig01_csection_trend`; `graphs/fig07_hour_of_birth`; `maps/map01_csection_all`, `maps/map02_csection_private`; `tables/tab01_descriptives.tex`, `tables/tab07_business_hours.tex` |
| `02_regressions.R` | **Table 1** | `tables/tab_fees.tex` |
| `03_mechanisms.R` | **Table 3, Table 6** | `tables/tab_prelabor_lowrisk.tex`, `tables/tab11_decomposition.tex`, `tables/tab08_mechanism_checks.tex`; `graphs/fig02_dow_cesarean`, `graphs/fig03_robson_dow`, `graphs/fig08_daily_counts` |
| `04_heterogeneity.R` | (supplement) | `tables/tab10_heterogeneity.tex`, `tables/tab10b_modality.tex` |
| `05_cost.R` | **Table 5** | `tables/tab09_health.tex`; `tables/tab12_cost.tex`; `graphs/fig09_gestation`, `graphs/fig09b_gestation_by_timing` |
| `06_robustness.R` | (supplement) | `tables/tab13_referee_robustness.tex`, `tab13c_dip_by_region_period.tex`, `tab14_neonatal_suggestive.tex`, `tab15_permutation.tex`, `tab15b_no_indication.tex`; `graphs/fig05_rn368_timeline` |
| `07_main_specification.R` | **Table 2** | `tables/tab_main_gradient.tex`; `fam_A.rds` |
| `08_long_weekends.R` | **Table 4** | `tables/tab_long_weekends.tex`; `tables/tab_displacement_robust.tex`; `graphs/fig_long_weekend_event`, `fig_long_weekend_event_blocks`; `fam_D.rds`, `evt_coefs.rds` |
| `09_org_capacity.R` | (supplement) | `tables/tab_org_capacity.tex`, `tables/tab_org_capacity_valid.tex`; `fam_E.rds` |
| `13_demand_smoothing.R` | (supplement) | `tables/tab_demand_smoothing.tex`; `fam_F.rds` |
| `10_supplement.R` | (supplement) | `tables/tab_multiple_testing.tex`, `tab_ref_c3_robson_validation.tex`, `tab_ref_c5_feegap_ci.tex`, `tab_ref_c6_fee_base_econ.tex`, `tab_ref_c7_placebo_ranking.tex`, `tab_ref_c10_fewcluster.tex`, `tab_ref_c12_missingness.tex`, `tab_ref_c12_sampleflow.tex`; `graphs/fig_ref_c11_pa_hospital_es` |
| `12_subgroups.R` | (supplement) | `tables/tab_subgroup_gradients.tex` (gestational-age + maternal-age splits of Equation 3), `graphs/fig_robson_gradient`, `robson_grad.rds` (feeds **Figure 3** panel c) |
| `11_body_figures.R` | **Figure 2, Figure 3** | `graphs/fig_two_margins` (**Figure 2**: price binscatter + scheduling gradients), `graphs/fig_calendar_fingerprints` (**Figure 3**: day-of-week + hour of birth + Robson gradient), `graphs/fig_gestation_panels` (Supplementary Appendix) |

Figures are written as both `.pdf` and `.png`. The LaTeX in `latex/` `\input`s the
`.tex` tables and `\includegraphics`es the `.pdf` figures to produce `paper.pdf`
and `supplement.pdf`.

## Compiling the manuscript

The `xr` package cross-references run **both ways**: `supplement.tex` reads
`paper.aux` and `paper.tex` reads `supplement.aux` for the ~30 `\satab`/`\safig`
pointers into the Supplemental Appendix. The cycle therefore has to be run twice,
paper to supplement and back, and **the `.aux` files must survive between passes**
(never clean in the middle). Running only paper then supplement on a fresh
checkout is what makes every supplement reference print as `??`.

```
cd latex
pdflatex paper;      bibtex paper
pdflatex supplement; bibtex supplement; pdflatex supplement
pdflatex paper;      pdflatex paper
pdflatex supplement
```

The supplement needs its own `bibtex` pass because it cites Holm (1979) and
Benjamini and Hochberg (1995) in Appendix D. Verify with

```
grep -c "Reference .* undefined" latex/paper.log      # must be 0
grep -c "Citation .* undefined" latex/paper.log       # must be 0
```

`latex/highlights.txt` holds the Highlights, uploaded to the journal as a
separate file (at most 85 characters per bullet).

## Deposit checklist

The package is assembled here and is deposited in a trusted open repository
(Zenodo or openICPSR) before acceptance; the DOI then replaces the placeholder in
the Data availability statement of `latex/paper.tex`. Before depositing, confirm:

- [ ] `config/config.R` ships with a placeholder `DROPBOX_ROOT`, not a local path.
- [ ] `renv.lock` and `sessionInfo.txt` are current for the R version used in the
      final run.
- [ ] The full pipeline has been run end to end on a clean checkout, and every
      file in the program-to-output inventory above was regenerated.
- [ ] `analysis/output/` in the deposit matches the exhibits in the compiled
      `paper.pdf` and `supplement.pdf`.
- [ ] No microdata are included. Every source is public and is reached by the
      `build/01*` download scripts; the data citations above give the archived
      versions.
- [ ] The one-time download scripts run against the current source URLs.
- [ ] A `LICENSE` for the code (MIT or BSD-2) is present.
