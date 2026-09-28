# =============================================================================
# 01b_cnes.R
# One-time download of the CNES data, and the sector rule for the births:
#   * CNES hospital beds (establishment level, carries natureza jurídica —
#     the private/nonprofit/public sector classifier) ... datazoom.saude
#   * CNES-PF obstetrician counts (CBO occupation file) .. microdatasus
#   * the sector of each birth by establishment and year, assign_sector_year(),
#     used by build/01e_sinasc_datasus.R, which downloads and assembles SINASC
#
# Outputs (Dropbox):
#   build/CNES/input/cnes_beds_muni_year.parquet
#   build/CNES/input/cnes_obstetricians_muni_year.parquet
#
# --- SECTOR of the birth establishment ---------------------------------------
# From its natureza jurídica (nat_jur, CNES beds): 2xxx (empresarial) →
# "Private" (for-profit, private-insurance heavy, ~79% cesarean); 3xxx (sem fins
# lucrativos) → "Nonprofit" (filantrópico/Santas Casas, SUS-heavy); else →
# "Public". `private` = 1 iff sector == "Private". Do NOT lump 3xxx into private
# — it is SUS-heavy and inflates the private share to ~56%.
#
# MEMORY: sources pulled one UF/year at a time and aggregated immediately.
#
# PATHS: DROPBOX_ROOT from config/config.R.
# =============================================================================

source(here::here("config", "config.R"))
source(here::here("build", "00_utils.R"))   # occupation classifiers (is_obstetra)
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, dplyr, arrow, here)
pacman::p_load_gh("datazoompuc/datazoom.saude")
if (!requireNamespace("microdatasus", quietly = TRUE))   # CNES-PF (obstetricians)
  pacman::p_load_gh("rfsaldanha/microdatasus")

CNES_INPUT   <- file.path(DROPBOX_ROOT, "build", "CNES", "input")
SINASC_INPUT <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
dir.create(CNES_INPUT,   recursive = TRUE, showWarnings = FALSE)
dir.create(SINASC_INPUT, recursive = TRUE, showWarnings = FALSE)

BIRTHS_OUT <- file.path(SINASC_INPUT, "sinasc_births.parquet")
DAILY_OUT  <- file.path(SINASC_INPUT, "sinasc_daily_muni.parquet")

UF_LIST <- c("AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG",
             "PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO")

# =============================================================================
# CNES hospital beds (datazoom.saude). Signature:
#   load_hospital_beds(time_period, states = "all", raw_data, language)
# raw_data = FALSE returns the treated establishment-level table; we bind years.
# =============================================================================
# `out_file`: the 2012-2014 extension goes to its own file so that the main
# 2015-2024 file, which other steps read, is never overwritten.
# NAT_JUR exists in the CNES from June 2012; 2010-2011 have only the old NATUREZA
# code, whose "07" mixes for-profit and nonprofit, so those two years take the
# nearest covered year in .cnes_sector_year().
download_cnes_beds <- function(years = 2015:2024, ufs = "all",
                               out_file = "cnes_beds_muni_year.parquet") {
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
  arrow::write_parquet(res, file.path(CNES_INPUT, out_file))
  message("saved ", out_file, " (", nrow(res), " rows)")
}

# =============================================================================
# CNES-PF obstetricians (microdatasus). CNES-PF is monthly; the stock moves
# slowly, so take ONE competência per year (December) per UF, keep obstetrician
# CBOs (is_obstetra: gineco-obstetra 225250 / obstetra 223132 and their CBO-94
# codes 6149/6145), count distinct professionals per municipality.
# =============================================================================
download_cnes_obstetricians <- function(years = 2015:2024, ufs = UF_LIST) {
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
                   error = function(e) as.data.table(raw))
    muni_col <- intersect(c("CODUFMUN","municipio_code","COD_MUN"), names(dt))[1]
    cbo_col  <- intersect(c("CBO","cbo"), names(dt))[1]
    id_col   <- intersect(c("CNS_PROF","CPF_PROF","cns_prof"), names(dt))[1]
    if (is.na(muni_col) || is.na(cbo_col)) { rm(raw, dt); gc(); next }
    dt <- dt[is_obstetra(get(cbo_col))]
    # Collapse the DF administrative regions onto 530010 BEFORE the distinct
    # count — see fix_muni_df() in build/00_utils.R. Recoding after the count
    # would double-count anyone practising in two regions.
    dt[, muni_fix := fix_muni_df(get(muni_col))]
    if (!is.na(id_col)) {
      agg <- dt[, .(n_obstetricians = uniqueN(get(id_col))), by = .(muni = muni_fix)]
    } else {
      agg <- dt[, .(n_obstetricians = .N), by = .(muni = muni_fix)]
    }
    agg[, `:=`(uf = uf, year = y)]
    out[[length(out) + 1L]] <- agg
    rm(raw, dt, agg); gc()
  }
  res <- rbindlist(out, use.names = TRUE, fill = TRUE)
  arrow::write_parquet(res, file.path(CNES_INPUT, "cnes_obstetricians_muni_year.parquet"))
  message("saved cnes_obstetricians_muni_year.parquet (", nrow(res), " rows)")
}

# =============================================================================
# SINASC ingest: targeted CSV → birth-level + daily parquets, CSV deleted after.
# =============================================================================
# CNES establishment sets by natureza jurídica (nat_jur), first digit:
#   1xxx Administração Pública            -> "Public"
#   2xxx Entidades Empresariais           -> "Private" (for-profit)
#   3xxx Entidades sem Fins Lucrativos    -> "Nonprofit"
#   4xxx Pessoas Físicas / 5xxx Org. Int. -> NEITHER; must not fall into Public.
# Each of the three sectors is built as an EXPLICIT establishment set (an estab
# that has appeared under a given first digit in any competência). A SINASC
# birth whose establishment matches none of them (unmatched, or a 4xxx/5xxx
# establishment) is labeled "Other", NOT Public — the former
# code sent every unmatched establishment to Public, contaminating it.
.cnes_sector_sets <- function() {
  beds <- data.table::as.data.table(
    arrow::read_parquet(file.path(CNES_INPUT, "cnes_beds_muni_year.parquet")))
  beds[, `:=`(cnes7 = formatC(as.integer(cnes), width = 7, flag = "0"),
              nj = as.character(nat_jur))]
  list(forprofit = unique(beds[grepl("^2", nj), cnes7]),
       nonprofit = unique(beds[grepl("^3", nj), cnes7]),
       public    = unique(beds[grepl("^1", nj), cnes7]))
}

# -----------------------------------------------------------------------------
# SECTOR BY ESTABLISHMENT AND YEAR. The sets above are "ever" sets
# with for-profit priority, so an establishment that was for-profit in any
# competencia was Private in every year: 430,348 births labelled Private (4.8% of
# the group) took place in a year the CNES listed the establishment as public or
# nonprofit. The sector is now the legal nature of the establishment in the
# birth's own year, read at the last competencia of that year; a year the CNES
# does not cover for that establishment (all of 2010-2014, or a gap) takes the
# nearest year it does cover. An establishment never in the file stays "Other".
# -----------------------------------------------------------------------------
.cnes_sector_year <- function() {
  rd <- function(f) data.table::as.data.table(arrow::read_parquet(
    file.path(CNES_INPUT, f), col_select = c("cnes", "nat_jur", "competence", "year")))
  beds <- rd("cnes_beds_muni_year.parquet")
  if (file.exists(file.path(CNES_INPUT, "cnes_beds_2012_2014.parquet")))
    beds <- data.table::rbindlist(list(rd("cnes_beds_2012_2014.parquet"), beds))
  beds[, `:=`(estab = formatC(as.integer(cnes), width = 7, flag = "0"),
              d1 = substr(as.character(nat_jur), 1, 1))]
  beds <- beds[!is.na(d1) & d1 != ""]
  data.table::setorder(beds, estab, year, competence)
  ey <- beds[, .(d1 = d1[.N]), by = .(estab, year)]          # last competencia of the year
  ey[, sector := data.table::fcase(d1 == "2", "Private", d1 == "3", "Nonprofit",
                                   d1 == "1", "Public", default = "Other")]
  ey[, .(estab, cnes_year = year, sector)]
}

#' Sector of each birth from its establishment and year, nearest CNES year when
#' the birth's own year is not covered. `dt` needs `estab` and `year`.
assign_sector_year <- function(dt) {
  ey <- .cnes_sector_year()
  key <- unique(dt[, .(estab, year)])
  key[, cnes_year := year]
  data.table::setkey(ey, estab, cnes_year); data.table::setkey(key, estab, cnes_year)
  m <- ey[key, roll = "nearest"]                      # nearest covered year, same estab
  m <- m[, .(estab, year, sector)]
  dt[m, sector := i.sector, on = .(estab, year)]
  dt[is.na(sector), sector := "Other"]
  dt[, private := as.integer(sector == "Private")]
  invisible(dt)
}

#' Re-derive the sector of the existing birth file (the raw CSV was deleted after
#' ingest) and rewrite the files that carry it. The per-cell caches built by 08,
#' 09 and 14 are removed so the next run rebuilds them on the new sector.
reassign_sector_births <- function() {
  dt <- data.table::as.data.table(arrow::read_parquet(BIRTHS_OUT))
  old <- dt$sector
  dt[, sector := NULL]
  assign_sector_year(dt)
  message(sprintf("sector changed for %s of %s births (%.2f%%)",
                  format(sum(old != dt$sector), big.mark = ","),
                  format(nrow(dt), big.mark = ","), 100 * mean(old != dt$sector)))
  print(data.table::data.table(old = old, new = dt$sector)[, .N, by = .(old, new)][order(old, -N)])
  data.table::setindex(dt, NULL)             # see 01e: an index in the footer breaks the file
  arrow::write_parquet(dt, BIRTHS_OUT)
  daily <- dt[, .(births = .N, cesarean = sum(cesarean)), by = .(muni, date, sector)]
  arrow::write_parquet(daily, DAILY_OUT)
  for (f in c("sinasc_daily_timing_muni.parquet", "sinasc_daily_estab.parquet",
              "sinasc_estab_year_robson.parquet"))
    if (file.exists(file.path(SINASC_INPUT, f))) {
      file.remove(file.path(SINASC_INPUT, f)); message("removed cache ", f) }
  invisible(dt)
}


# -----------------------------------------------------------------------------
# Run ONCE to populate Dropbox (already done):
# -----------------------------------------------------------------------------
# download_cnes_beds(years = 2015:2024)
# download_cnes_obstetricians(years = 2015:2024)
# download_cnes_beds(2012:2014, out_file = "cnes_beds_2012_2014.parquet")
# reassign_sector_births(): re-derive sector by establishment-year in place
