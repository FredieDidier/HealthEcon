# =============================================================================
# config.R — machine-specific configuration.
#
# ***THE ONLY FILE TO EDIT before reproducing the project on a new machine.***
# Set DROPBOX_ROOT to the local path of the data folder that holds
#   build/TISS/input/   (raw ANS TISS parquet files, PLANOS.csv, auxiliares/)
#   build/TISS/output/  (main_data, the final analytical dataset)
# All GitHub-repo paths are resolved automatically with here::here(), so this
# single line is the only path that changes per machine. Sourced by every build
# and analysis script.
#
# Three ways to set it, checked in this order, so that the file distributed with
# the replication package never carries anybody's local path:
#   1. the environment variable HEALTHECON_DATA (e.g. in ~/.Renviron);
#   2. config/config_local.R, which is git-ignored and simply assigns
#      DROPBOX_ROOT <- "/your/path"; or
#   3. the placeholder below, edited in place.
#
# Packages install themselves: the master scripts (config/00_master_*.R) call
# pacman::p_load(), which installs any missing package automatically, so there
# is no need to run install.packages() by hand.
# =============================================================================

DROPBOX_ROOT <- "/PATH/TO/DATA/HealthEcon"   # <-- edit me (see options above)

.he_env <- Sys.getenv("HEALTHECON_DATA", unset = "")
if (nzchar(.he_env)) {
  DROPBOX_ROOT <- .he_env
} else if (file.exists(file.path("config", "config_local.R"))) {
  source(file.path("config", "config_local.R"))
} else if (requireNamespace("here", quietly = TRUE) &&
           file.exists(here::here("config", "config_local.R"))) {
  source(here::here("config", "config_local.R"))
}
rm(.he_env)

if (!dir.exists(file.path(DROPBOX_ROOT, "build"))) {
  stop("DROPBOX_ROOT does not contain a build/ directory: ", DROPBOX_ROOT,
       "\nSet it in config/config.R, in config/config_local.R, or via the",
       " HEALTHECON_DATA environment variable.")
}
