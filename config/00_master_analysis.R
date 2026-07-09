# =============================================================================
# 00_master_analysis.R
# Master script for the analysis pipeline.
# Run this file after 00_master_build.R to reproduce all results.
#
# Each consolidated script is self-contained and loads the analytical files from
# Dropbox build/... . Scripts are organized thematically (one per paper theme),
# not one per exhibit.
#
# Pipeline:
#   00_utils.R          →  Shared analysis helpers (theme, palette, LaTeX post-processing).
#   01_descriptives.R   →  Trends, summary stats, hour-of-birth, choropleth maps.
#   02_regressions.R    →  Price channel: not-a-price fee regressions + fee-shock.
#   03_mechanisms.R     →  Scheduling, low-risk (Robson), prelabor split, decomposition.
#   04_heterogeneity.R  →  Theory-driven heterogeneity + operator modality.
#   05_cost.R           →  Cost of convenience: early-term shifting + newborn health.
#   06_robustness.R     →  Policy nulls, referee robustness, permutation, neonatal (suggestive).
#
# PATHS: set DROPBOX_ROOT once in config/config.R (the only path to change on a
#   new machine); every script sources it. GitHub-repo paths use here::here().
# =============================================================================

# Package management: pacman installs any missing package automatically, so
# there is no need to run install.packages() by hand.
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, arrow, data.table, dplyr, fixest, ggplot2, modelsummary)

source(here("analysis", "code", "00_utils.R"))
source(here("analysis", "code", "01_descriptives.R"))   # trends, summary stats, hours, maps
source(here("analysis", "code", "02_regressions.R"))    # price channel (not a price + fee shock)
source(here("analysis", "code", "03_mechanisms.R"))     # scheduling, Robson, prelabor, decomposition
source(here("analysis", "code", "04_heterogeneity.R"))  # heterogeneity + operator modality
source(here("analysis", "code", "05_cost.R"))           # early-term shifting + newborn health
source(here("analysis", "code", "06_robustness.R"))     # policy nulls, referee checks, permutation
