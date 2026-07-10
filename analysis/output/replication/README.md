# Replication package — Born on Schedule

## Data provenance
- SINASC births 2010-2024: Base dos Dados (BigQuery), query in build/01b_sinasc_cnes.R. Download date: <FILL>.
- TISS claims 2015-2025: ANS PDA FTP (https://dadosabertos.ans.gov.br/FTP/PDA/TISS/). Download date: <FILL>.
- CNES beds/obstetricians: datazoom.saude / microdatasus. Download date: <FILL>.
- IEPS muni-year covariates: https://iepsdata.org.br (manual export). Download date: <FILL>.
- Parto Adequado Fase-2 hospital list: ANS PDF snapshot 2019-02-11.

## How to reproduce
1. Edit config/config.R (set DROPBOX_ROOT).
2. Rscript config/00_master_build.R    # builds main_data.parquet and panels
3. Rscript config/00_master_analysis.R # regenerates every table and figure
4. Rscript analysis/code/07_referee_response.R  # referee-response exhibits

## Program-to-output inventory
| Script | Outputs |
|---|---|
| analysis/code/01_descriptives.R | fig01, fig02, map01, map02, tab01 |
| analysis/code/02_regressions.R  | tab02, tab06 |
| analysis/code/03_mechanisms.R   | fig03, fig07, fig08, tab03, tab04, tab07, tab08, tab11 |
| analysis/code/04_heterogeneity.R| tab10, tab10b |
| analysis/code/05_cost.R         | fig09, fig09b, tab09, tab12 |
| analysis/code/06_robustness.R   | fig04, fig04b, fig05, tab05, tab05b, tab13*, tab14, tab15* |
| analysis/code/07_referee_response.R | tab_pooled_did, tab_pooled_did_composition, tab_multiple_testing, tab_ref_* |

## Environment and runtime
- R version and packages: see sessionInfo.txt and renv.lock.
- Random seeds: set.seed(1) in every script that bootstraps or permutes.
- Expected runtime on a 2023 MacBook Pro (M2 Pro, 16 GB): build ~3 h (dominated
  by the TISS download); full analysis ~90 min; 07_referee_response.R ~40 min,
  of which the composition-adjusted municipality-by-date regression is ~25 min.
- Peak memory ~12 GB (the birth-level regressions on 24M records).

## AI-use disclosure
- Portions of the code and manuscript were drafted/edited with AI assistance;
  all results were verified by the authors against the source data.

## Checksums
- Run `shasum -a 256` on each raw extract and record the hashes here: <FILL>.
