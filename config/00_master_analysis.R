# =============================================================================
# 00_master_analysis.R
# Master script for the analysis pipeline.
# Run this file after 00_master_build.R to reproduce all results.
#
# Each script is self-contained and loads the analytical dataset from
# Dropbox build/TISS/output.
#
# Pipeline (to be written as the research design is finalised):
#   00_utils.R          →  Shared analysis helpers (LaTeX table post-processing).
#   01_descriptives.R   →  Summary statistics and descriptive figures.
#   ...
#
# PATHS: set DROPBOX_ROOT once in config/config.R (the only path to change on a
#   new machine); every script sources it. GitHub-repo paths use here::here().
# =============================================================================

# Package management: pacman installs any missing package automatically, so
# there is no need to run install.packages() by hand.
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, arrow, data.table, dplyr, fixest, ggplot2, modelsummary)

source(here("analysis", "code", "00_utils.R"))
source(here("analysis", "code", "01_descriptives.R"))   # trends + descriptive table
source(here("analysis", "code", "02_not_a_price.R"))    # fee-gap regressions (not a price)
source(here("analysis", "code", "03_scheduling.R"))     # SINASC scheduling (weekend/holiday)
source(here("analysis", "code", "04_robson.R"))         # low-risk (Robson 1-2) cesareans
source(here("analysis", "code", "05_policy.R"))         # Parto Adequado + RN 368 (support)
source(here("analysis", "code", "06_fee_shock.R"))      # fee changes don't move cesareans
source(here("analysis", "code", "07_hours.R"))          # hour-of-birth (within-day fingerprint)
source(here("analysis", "code", "08_mechanism_checks.R")) # prelabor split, counts, placebo
source(here("analysis", "code", "09_gestation_health.R")) # early-term shifting + newborn health
source(here("analysis", "code", "10_heterogeneity.R"))  # theory-driven heterogeneity
source(here("analysis", "code", "11_decomposition.R"))  # Kitagawa + excess-cesarean counts
