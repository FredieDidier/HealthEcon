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

## Environment
- R version and packages: see sessionInfo.txt and renv.lock.
- Random seeds: set.seed(1) in every script that bootstraps or permutes.

## AI-use disclosure
- Portions of the code and manuscript were drafted/edited with AI assistance;
  all results were verified by the authors against the source data.

## Checksums
- Run `shasum -a 256` on each raw extract and record the hashes here: <FILL>.
