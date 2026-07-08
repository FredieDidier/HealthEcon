# Born on Schedule: Physician Time and the World's Highest Cesarean Rate — Replication Package

**Author:** Fredie Didier (fdidier@terra.com.br)

## Repository layout

```
config/
  config.R              # <-- THE ONLY FILE TO EDIT (set DROPBOX_ROOT)
  00_master_build.R     # runs the data build
  00_master_analysis.R  # runs all analysis scripts
build/
  00_utils.R            # admission-count proxies, TUSS delivery codes
  01a_tiss.R            # one-time ANS TISS Hospitalar download (CONS + DET)
  01b_sinasc_cnes.R     # one-time SINASC (Base dos Dados) + CNES downloads/ingest
  01c_ieps.R            # IEPS municipality-year covariates
  02_deliveries.R       # TISS delivery events + municipality-month panel
  03_workfile.R         # merges everything into main_data.parquet
analysis/code/          # 00_utils.R, 01_descriptives.R … 14_neonatal_suggestive.R
analysis/output/        # tables/, graphs/, maps/ (committed)
latex/                  # paper.tex, model.tex (appendix), refs.bib
dictionary/             # ANS TISS dictionaries + variable_dictionary.xlsx (build_dictionary.R)
```

## Data

The microdata are **not** in this repository. They live in a (Dropbox) folder:

```
<DROPBOX_ROOT>/build/TISS/input/        raw ANS TISS claims (CONS/DET parquets, 2015–2025)
<DROPBOX_ROOT>/build/TISS/output/       delivery event workfiles + muni-month panel
<DROPBOX_ROOT>/build/SINASC/input/      sinasc_births.parquet (2010–2024) + daily extract
<DROPBOX_ROOT>/build/CNES/input/        hospital beds + obstetrician counts
<DROPBOX_ROOT>/build/IEPS/{input,output}/   municipality covariates
<DROPBOX_ROOT>/build/covariates/input/  Parto Adequado Fase-2 hospital list
<DROPBOX_ROOT>/build/workfile/output/   main_data.parquet (final muni-year dataset)
```

`main_data.parquet` covers 2015–2025 (11,567 municipality-years); the SINASC
extracts cover 2010–2024 (~42M births).

### Getting the data — all sources are public

- **ANS TISS Hospitalar** — open data, downloaded by `build/01a_tiss.R` from
  `https://dadosabertos.ans.gov.br/FTP/PDA/TISS/HOSPITALAR/`.
- **SINASC** — via [Base dos Dados](https://basedosdados.org/dataset/48ccef51-8207-40ee-af5b-134c8ac3fb8c)
  (BigQuery; the targeted 24-column query is documented in `build/01b_sinasc_cnes.R`;
  requires a Google Cloud billing project), then ingested by `ingest_sinasc()`.
- **CNES** (beds via `datazoom.saude`; professionals via `microdatasus`) —
  downloaded by `build/01b_sinasc_cnes.R`.
- **IEPS Data** — manual export from `https://iepsdata.org.br`, placed in
  `<DROPBOX_ROOT>/build/IEPS/input/ieps.csv`.
- **Parto Adequado hospital list** — scraped from the
  [ANS Fase-2 PDF](https://www.gov.br/ans/pt-br/arquivos/assuntos/prestadores/parto-adequado-1/projeto_parto_adequado_fase_2_hospitais_participantes.pdf)
  (snapshot 11/02/2019), stored as `parto_adequado_fase2_hospitais.csv`.

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
   `01c_ieps.R`) are commented out in the master script; uncomment them only to
   (re-)download the raw data.

3. **Run the analysis** (writes all tables and figures to `analysis/output/`):

   ```r
   source("config/00_master_analysis.R")
   ```
