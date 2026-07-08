# =============================================================================
# 00_master_build.R
# Master script for the data build pipeline.
# Run this file to reproduce the analytical dataset from the raw ANS TISS data.
#
# Pipeline:
#   00_utils.R          →  Shared build helpers (code decoders, the hospital-
#                          admission proxy). Sourced, defines functions only.
#   01_download_tiss.R  →  Downloads ANS TISS Hospitalar micro-data from the ANS
#                          open-data FTP and writes one parquet per year and type
#                          (CONS, DET) to Dropbox build/TISS/input. Run ONCE — the
#                          download call is commented out; all 2015-2025 files are
#                          already present in Dropbox.
#   01b_download_covariates.R → One-time download of SINASC + CNES beds via
#                          datazoom.saude → Dropbox build/covariates/input. Run ONCE.
#   02_deliveries.R     →  Builds the delivery analytical files from CONS/DET:
#                          per-year event workfiles + a municipality-month panel.
#
# PATHS: set DROPBOX_ROOT once in config/config.R (the only path to change on a
#   new machine); every script sources it. GitHub-repo paths use here::here().
# =============================================================================

# Package management: pacman installs any missing package automatically, so
# there is no need to run install.packages() by hand.
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, arrow, data.table, dplyr, readr, stringr)

source(here("build", "00_utils.R"))
# source(here("build", "01_download_tiss.R"))       # one-time raw TISS download
# source(here("build", "01b_download_covariates.R")) # one-time SINASC/CNES download
# source(here("build", "01c_ieps.R"))                # prepare IEPS muni-year covariates
# source(here("build", "01d_sinasc_daily.R"))        # one-time SINASC daily extract (microdatasus)
source(here("build", "02_deliveries.R"))            # build delivery event + panel files
source(here("build", "03_workfile.R"))              # assemble muni-year analytical work-file
