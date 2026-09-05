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
#   00_utils.R              →  Shared helpers (theme, palette, table/LaTeX tools).
#   01_descriptives.R       →  Trends, summary stats, hour-of-birth, choropleth maps.
#   02_regressions.R        →  Price channel: fee regressions + fee-shock (Table 1).
#   03_mechanisms.R         →  Scheduling, Robson, prelabor split, decomposition.
#   04_heterogeneity.R      →  Municipality heterogeneity + operator modality (supp).
#   05_cost.R               →  Early-term shifting + newborn health + billed cost.
#   06_robustness.R         →  Policy nulls, referee robustness, permutation, neonatal.
#   07_main_specification.R →  Equation (3), the main gradient table (Table 2).
#   08_long_weekends.R      →  Long-weekend taxonomy + displacement event study.
#   09_org_capacity.R       →  Organizational-capacity heterogeneity (needs 01d build).
#   13_demand_smoothing.R   →  The de Elejalde-Giolito demand-smoothing channel (null).
#   10_supplement.R         →  Supplemental Appendix exhibits + multiple testing.
#   12_subgroups.R          →  Robson / gestational-age / maternal-age subgroups.
#   11_body_figures.R       →  Merged multi-panel body figures (needs 08 + 12).
#
# ORDER MATTERS at the tail: 07, 08, 09 and 13 each save a hypothesis family
# (analysis/output/fam_*.rds) and 08 saves the event-study coefficients that
# 10_supplement.R and 11_body_figures.R read, so keep 10 and 11 last. 12 runs
# BEFORE 11 despite its number: it saves robson_grad.rds, the coefficients that
# 11 draws as panel (c) of Figure 3.
#
# PATHS: set DROPBOX_ROOT once in config/config.R (the only path to change on a
#   new machine); every script sources it. GitHub-repo paths use here::here().
# =============================================================================

# Package management: pacman installs any missing package automatically, so
# there is no need to run install.packages() by hand.
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(here, arrow, data.table, dplyr, fixest, ggplot2, patchwork, modelsummary)

source(here("analysis", "code", "00_utils.R"))
source(here("analysis", "code", "01_descriptives.R"))       # trends, summary stats, hours, maps
source(here("analysis", "code", "02_regressions.R"))        # price channel (Table 1)
source(here("analysis", "code", "03_mechanisms.R"))         # scheduling, Robson, prelabor, decomposition
source(here("analysis", "code", "04_heterogeneity.R"))      # heterogeneity + operator modality
source(here("analysis", "code", "05_cost.R"))               # early-term shifting + newborn health + cost
source(here("analysis", "code", "06_robustness.R"))         # policy nulls, referee checks, permutation
source(here("analysis", "code", "07_main_specification.R")) # Equation (3), main gradient table
source(here("analysis", "code", "08_long_weekends.R"))      # long-weekend taxonomy + displacement
source(here("analysis", "code", "09_org_capacity.R"))       # organizational-capacity heterogeneity
source(here("analysis", "code", "13_demand_smoothing.R"))   # demand-smoothing channel (family F)
source(here("analysis", "code", "10_supplement.R"))         # supplemental exhibits + multiple testing
source(here("analysis", "code", "12_subgroups.R"))          # Robson / gestational-age / maternal-age subgroups
source(here("analysis", "code", "11_body_figures.R"))       # merged body figures (needs 12)
