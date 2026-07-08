# =============================================================================
# 00_master_build.R
# Master script for the data build pipeline.
# Run this file to reproduce the analytical dataset from the raw data.
#
# Pipeline:
#   00_utils.R          →  Shared build helpers (admission-count proxies, TUSS
#                          delivery codes). Sourced, defines functions only.
#   01a_tiss.R          →  One-time ANS TISS Hospitalar downloader (CONS + DET,
#                          2015-2025) → Dropbox build/TISS/input. Already run;
#                          the download calls are commented out.
#   01b_sinasc_cnes.R   →  One-time SINASC (Base dos Dados, 2010-2024) + CNES
#                          beds/obstetricians downloads & ingestion → Dropbox
#                          build/SINASC/input and build/CNES/input. Already run.
#   01c_ieps.R          →  Prepares the IEPS municipality-year covariates
#                          (manual export) → Dropbox build/IEPS/output.
#   02_deliveries.R     →  Builds the TISS delivery event workfiles + the
#                          municipality-month panel → Dropbox build/TISS/output.
#   03_workfile.R       →  Merges everything into the muni-year analytical file
#                          → Dropbox build/workfile/output/main_data.parquet.
#
# PATHS: set DROPBOX_ROOT once in config/config.R (the only path to change on a
#   new machine); every script sources it. GitHub-repo paths use here::here().
# =============================================================================

# Package management: pacman installs any missing package automatically, so
# there is no need to run install.packages() by hand.
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, arrow, data.table, dplyr, readr, stringr)

source(here("build", "00_utils.R"))
# source(here("build", "01a_tiss.R"))        # one-time raw TISS download
# source(here("build", "01b_sinasc_cnes.R")) # one-time SINASC + CNES download/ingest
# source(here("build", "01c_ieps.R"))        # prepare IEPS muni-year covariates
source(here("build", "02_deliveries.R"))     # build delivery event + panel files
source(here("build", "03_workfile.R"))       # assemble main_data.parquet
