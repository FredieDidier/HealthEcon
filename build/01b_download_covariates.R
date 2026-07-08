# =============================================================================
# 01b_download_covariates.R
# Download municipality-level covariates that will be merged onto the TISS
# delivery panel:
#   * SINASC — all live births (public + private) ...... datazoom.saude::load_births
#   * CNES hospital beds .............................. datazoom.saude::load_hospital_beds
#   * CNES-PF obstetrician counts (professionals file)  microdatasus::fetch_datasus("CNES-PF")
# datazoom.saude (PUC-Rio): https://github.com/datazoompuc/datazoom.saude
# microdatasus (CNES-PF, not covered by datazoom): https://github.com/rfsaldanha/microdatasus
#
# MEMORY STRATEGY (important — keep the footprint tiny):
#   Both sources are pulled ONE STATE (and, for SINASC, one year) at a time and
#   AGGREGATED to a municipality-year table immediately; the heavy micro-data is
#   discarded (rm + gc) before moving on. Only the small aggregates are written
#   to Dropbox, never the raw micro. Run ONCE; calls are commented at the bottom.
#
# PATHS: DROPBOX_ROOT from config/config.R. Packages loaded here (datazoom.saude
# is on GitHub → p_load_gh).
# =============================================================================

source(here::here("config", "config.R"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, dplyr, arrow, here)
pacman::p_load_gh("datazoompuc/datazoom.saude")
if (!requireNamespace("microdatasus", quietly = TRUE))   # CNES-PF (obstetricians)
  pacman::p_load_gh("rfsaldanha/microdatasus")

COV_INPUT <- file.path(DROPBOX_ROOT, "build", "covariates", "input")
dir.create(COV_INPUT, recursive = TRUE, showWarnings = FALSE)

UF_LIST <- c("AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG",
             "PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO")

# -----------------------------------------------------------------------------
# SINASC — live births. raw_data = TRUE returns the canonical, stable DATASUS
# column names (CODMUNRES = municipality of residence, CODMUNNASC = municipality
# of birth, PARTO = 1 vaginal / 2 cesarean / 9 unknown, IDADEMAE, DTNASC ...).
# We collapse to municipality-of-birth × year × delivery-type counts.
# -----------------------------------------------------------------------------
download_sinasc <- function(years = 2015:2024, ufs = UF_LIST) {
  out <- vector("list", 0L)
  for (uf in ufs) for (y in years) {
    message("SINASC ", uf, " ", y)
    raw <- tryCatch(
      datazoom.saude::load_births(time_period = y, states = uf, raw_data = TRUE),
      error = function(e) { message("  skip: ", conditionMessage(e)); NULL })
    if (is.null(raw)) next
    dt <- as.data.table(raw)
    # ---- VERIFY column names on the first pull; adjust the two lines below if
    #      your datazoom version returns different names (print(names(dt))). ----
    keep <- intersect(c("CODMUNNASC","CODMUNRES","PARTO"), names(dt))
    dt <- dt[, ..keep]
    dt[, `:=`(year = y, parto = as.integer(PARTO))]
    agg <- dt[, .(births = .N), by = .(muni = CODMUNNASC, year, parto)]
    out[[length(out) + 1L]] <- agg
    rm(raw, dt, agg); gc()
  }
  res <- rbindlist(out, use.names = TRUE, fill = TRUE)
  # wide: vaginal (1), cesarean (2), and public C-section share
  res <- dcast(res, muni + year ~ parto, value.var = "births", fill = 0)
  arrow::write_parquet(res, file.path(COV_INPUT, "sinasc_muni_year.parquet"))
  message("saved sinasc_muni_year.parquet (", nrow(res), " rows)")
}

# -----------------------------------------------------------------------------
# CNES hospital beds (datazoom.saude). Signature is
#   load_hospital_beds(time_period, states = "all", raw_data, language)
# — there is NO keep_all argument. raw_data = FALSE returns the treated table;
# we bind years and save. Inspect names(res) on the first run and, if it is
# establishment-level, aggregate to municipality-year before use.
# -----------------------------------------------------------------------------
download_cnes_beds <- function(years = 2015:2024, ufs = "all") {
  out <- vector("list", 0L)
  for (y in years) {
    message("CNES beds ", y)
    raw <- tryCatch(
      datazoom.saude::load_hospital_beds(time_period = y, states = ufs,
                                         raw_data = FALSE),
      error = function(e) { message("  skip: ", conditionMessage(e)); NULL })
    if (is.null(raw)) next
    dt <- as.data.table(raw); dt[, year := y]
    out[[length(out) + 1L]] <- dt
    rm(raw, dt); gc()
  }
  res <- rbindlist(out, use.names = TRUE, fill = TRUE)
  arrow::write_parquet(res, file.path(COV_INPUT, "cnes_beds_muni_year.parquet"))
  message("saved cnes_beds_muni_year.parquet (", nrow(res), " rows)")
}

# -----------------------------------------------------------------------------
# OBSTETRICIAN DENSITY — CNES-PF (professionals file) via microdatasus.
# datazoom.saude does not expose CNES-PF, so we pull it directly. CNES-PF is
# monthly; obstetrician stock moves slowly, so we take ONE competência per year
# (December) per UF, keep obstetrician CBOs, and count distinct professionals per
# municipality. Everything is aggregated per (UF, year) before the next pull, so
# peak memory stays low.
#
# CBO (2002) obstetrician codes — adjust/extend after inspecting the data:
OBSTETRIC_CBO <- c("225250",   # Médico ginecologista e obstetra
                   "225270")   # Médico da estratégia de saúde da família (drop if noisy)
download_cnes_obstetricians <- function(years = 2015:2024, ufs = UF_LIST,
                                        cbo = OBSTETRIC_CBO) {
  out <- vector("list", 0L)
  for (uf in ufs) for (y in years) {
    message("CNES-PF ", uf, " ", y)
    raw <- tryCatch(
      microdatasus::fetch_datasus(year_start = y, month_start = 12,
                                  year_end = y, month_end = 12,
                                  uf = uf, information_system = "CNES-PF"),
      error = function(e) { message("  skip: ", conditionMessage(e)); NULL })
    if (is.null(raw)) next
    dt <- tryCatch(as.data.table(microdatasus::process_cnes(raw, information_system = "CNES-PF")),
                   error = function(e) as.data.table(raw))  # fall back to raw names
    # ---- VERIFY column names on the first pull (print(names(dt))). CNES-PF raw
    #      carries CODUFMUN (6-digit municipality), CBO, and a professional id
    #      (CNS_PROF / CPF_PROF). Adjust the three names below if needed. ----
    muni_col <- intersect(c("CODUFMUN","municipio_code","COD_MUN"), names(dt))[1]
    cbo_col  <- intersect(c("CBO","cbo"), names(dt))[1]
    id_col   <- intersect(c("CNS_PROF","CPF_PROF","cns_prof"), names(dt))[1]
    if (is.na(muni_col) || is.na(cbo_col)) { rm(raw, dt); gc(); next }
    dt <- dt[substr(as.character(get(cbo_col)), 1, 6) %in% cbo]
    if (!is.na(id_col)) {
      agg <- dt[, .(n_obstetricians = uniqueN(get(id_col))), by = .(muni = get(muni_col))]
    } else {                                   # no professional id → count rows
      agg <- dt[, .(n_obstetricians = .N), by = .(muni = get(muni_col))]
    }
    agg[, `:=`(uf = uf, year = y)]
    out[[length(out) + 1L]] <- agg
    rm(raw, dt, agg); gc()
  }
  res <- rbindlist(out, use.names = TRUE, fill = TRUE)
  arrow::write_parquet(res, file.path(COV_INPUT, "cnes_obstetricians_muni_year.parquet"))
  message("saved cnes_obstetricians_muni_year.parquet (", nrow(res), " rows)")
}

# -----------------------------------------------------------------------------
# Run ONCE to populate Dropbox build/covariates/input.
# -----------------------------------------------------------------------------
# download_sinasc(years = 2015:2024)
# download_cnes_beds(years = 2015:2024)
# download_cnes_obstetricians(years = 2015:2024)
