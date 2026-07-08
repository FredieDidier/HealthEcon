# =============================================================================
# 03_workfile.R
# Assemble the municipality-year analytical work-file for the C-section project:
# the TISS private-delivery panel (the spine) + municipality covariates.
#
# Spine: TISS delivery panel (build/02_deliveries.R) collapsed to muni-year.
# Merges (all on 6-digit IBGE municipality × year):
#   - IEPS      (build/01c_ieps.R)      GDP pc, population, private-plan coverage,
#                                       adequate prenatal care, ESF coverage, income
#   - CNES-PF   (build/01b …)           obstetrician counts
#   - SINASC    (build/01d …)           all-births + private/public cesarean rates
#
# Output: Dropbox build/workfile/output/main_data.parquet
#   Rows with a missing provider municipality (NA, ~0.06% of TISS deliveries) are
#   dropped — they cannot be geo-merged. Sparse muni-years with no vaginal (or no
#   cesarean) delivery yield empty-subset fee means; these NaN are converted to NA.
#
# PATHS: DROPBOX_ROOT from config/config.R. Packages from config/00_master_build.R.
# =============================================================================

source(here::here("config", "config.R"))

OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
COV <- file.path(DROPBOX_ROOT, "build", "covariates", "input")
IEO <- file.path(DROPBOX_ROOT, "build", "IEPS", "output")
WFO <- file.path(DROPBOX_ROOT, "build", "workfile", "output")
dir.create(WFO, recursive = TRUE, showWarnings = FALSE)

m6 <- function(x) formatC(as.integer(as.character(x)), width = 6, flag = "0")

build_workfile <- function() {
  # --- spine: TISS deliveries, muni-month → muni-year ------------------------
  p <- data.table::as.data.table(arrow::read_parquet(
    file.path(OUT, "delivery_panel_muni_month.parquet")))
  p <- p[!is.na(muni)]                                   # drop missing-municipality rows
  tiss <- p[, .(
    tiss_deliveries = sum(n_deliveries),
    tiss_cesarean   = sum(n_cesarean),
    fee_cesarean     = weighted.mean(fee_cesarean,     n_deliveries, na.rm = TRUE),
    fee_vaginal_econ = weighted.mean(fee_vaginal_econ, n_deliveries, na.rm = TRUE),
    mean_los         = weighted.mean(mean_los,         n_deliveries, na.rm = TRUE),
    any_uti_share    = weighted.mean(any_uti_share,    n_deliveries, na.rm = TRUE)
  ), by = .(muni6 = m6(muni), year)]
  tiss[, `:=`(tiss_csection_rate = tiss_cesarean / tiss_deliveries,
              log_fee_gap = log(fee_cesarean / fee_vaginal_econ))]

  # --- IEPS covariates -------------------------------------------------------
  ieps <- data.table::as.data.table(arrow::read_parquet(
    file.path(IEO, "ieps_muni_year.parquet")))
  ieps <- ieps[, .(muni6 = m6(code_muni6), year = ano, gdp_pc, pop_total,
                   plan_cov, prenatal, esf_cov, inc_pc)]

  # --- CNES obstetricians ----------------------------------------------------
  obs <- data.table::as.data.table(arrow::read_parquet(
    file.path(COV, "cnes_obstetricians_muni_year.parquet")))
  obs <- obs[, .(muni6 = m6(muni), year, n_obstetricians)]

  # --- SINASC all-births + private/public cesarean (from daily extract) ------
  sd <- data.table::as.data.table(arrow::read_parquet(
    file.path(COV, "sinasc_daily_muni.parquet")))
  sd[, year := data.table::year(date)]
  sin <- sd[, .(
    sinasc_births      = sum(births),
    sinasc_cesarean    = sum(cesarean),
    sinasc_priv_births = sum(births[sector == "Private"]),
    sinasc_priv_ces    = sum(cesarean[sector == "Private"])
  ), by = .(muni6 = m6(muni), year)]
  sin[, `:=`(
    sinasc_csection_rate         = sinasc_cesarean / sinasc_births,
    sinasc_private_csection_rate = sinasc_priv_ces / sinasc_priv_births
  )]

  # --- merge (TISS spine, left joins) ---------------------------------------
  w <- Reduce(function(a, b) merge(a, b, by = c("muni6", "year"), all.x = TRUE),
              list(tiss, ieps, obs, sin))
  w[, `:=`(
    obstetricians_per_1k_births = 1000 * n_obstetricians / sinasc_births,
    private_share_proxy         = tiss_deliveries / sinasc_births
  )]

  # --- clean: NaN → NA (empty-subset means in sparse cells) ------------------
  num <- names(w)[vapply(w, is.numeric, logical(1))]
  for (col in num) data.table::set(w, i = which(is.nan(w[[col]])), j = col, value = NA_real_)

  cat(sprintf("main_data rows: %d | IEPS %.0f%% | obst %.0f%% | SINASC %.0f%% | NA muni: %d\n",
              nrow(w), 100*mean(!is.na(w$gdp_pc)), 100*mean(!is.na(w$n_obstetricians)),
              100*mean(!is.na(w$sinasc_births)), sum(w$muni6 == "    NA")))
  arrow::write_parquet(w, file.path(WFO, "main_data.parquet"))
  message("saved main_data.parquet — ", nrow(w), " muni-year rows")
  invisible(w)
}

build_workfile()
