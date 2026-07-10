# =============================================================================
# 01d_cnes_estab.R
# Establishment-level CNES capacity panel (the input to the organizational-
# capacity heterogeneity in analysis/code/09_org_capacity.R).
#
# Two ingredients, both keyed on the 7-digit establishment CNES code that SINASC
# records for the birth establishment (`codigo_estabelecimento` -> `estab`):
#
#   (a) BEDS. Aggregated from the CNES beds file already on disk
#       (build/CNES/input/cnes_beds_muni_year.parquet). That file carries ONE ROW
#       PER MONTHLY COMPETENCIA, so summing over a year multiplies every bed
#       count by twelve; we keep the DECEMBER competencia only, which also lines
#       up with the CNES-PF month used below. Bed types (`tipo_leito`):
#       1 surgical, 2 clinical, 3 complementary (ICU), 4 OBSTETRIC,
#       5 pediatric, 6 other specialties, 7 day hospital.
#
#   (b) OBSTETRICIANS. CNES-PF (professional bonds), one competencia per year
#       (December), pulled UF by UF and aggregated immediately. We count
#       DISTINCT professionals (CNS_PROF) per establishment, not bonds, because
#       a physician can hold several bonds at the same hospital.
#
#       VALIDATION RESULT (do not treat this variable as the obstetric team).
#       Among establishments with at least fifty deliveries in the year, roughly
#       half register ZERO obstetricians (CBO 225250) and the median of the rest
#       is one, in the public sector as much as in the for-profit one. Brazilian
#       obstetricians hold their CNES bond at their own practice rather than at
#       the maternity where they deliver, so this count measures registration,
#       not the on-call roster. The analysis therefore uses OBSTETRIC BEDS and
#       delivery scale as the capacity measures and reports the obstetrician
#       count only as a flagged, weak robustness check.
#
# Output (Dropbox):
#   build/CNES/input/cnes_estab_year.parquet
#     cnes, codufmun, year, nat_jur, beds_total, beds_obstetric,
#     n_obstetricians, n_obst_bonds, obst_hours_hosp, n_physicians
#
# CAVEAT carried into the paper: a CNES-registered obstetrician is not
# necessarily an obstetrician physically on call. The measure captures the size
# of the establishment's obstetric team, not its on-call roster.
#
# PATHS: DROPBOX_ROOT from config/config.R.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, here)
if (!requireNamespace("microdatasus", quietly = TRUE))
  pacman::p_load_gh("rfsaldanha/microdatasus")

CNES_INPUT <- file.path(DROPBOX_ROOT, "build", "CNES", "input")
BEDS_IN    <- file.path(CNES_INPUT, "cnes_beds_muni_year.parquet")
PF_OUT     <- file.path(CNES_INPUT, "cnes_obstetricians_estab_year.parquet")
ESTAB_OUT  <- file.path(CNES_INPUT, "cnes_estab_year.parquet")

UF_LIST <- c("AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG",
             "PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO")

OBST_CBO <- "225250"   # Medico ginecologista e obstetra
PHYS_CBO <- "2251"     # all "medicos" 2251xx-2252xx families start 225

# =============================================================================
# (a) Establishment-year beds
# =============================================================================
build_estab_beds <- function() {
  b <- as.data.table(arrow::read_parquet(
    BEDS_IN, col_select = c("competence", "cnes", "codufmun", "nat_jur", "tipo_leito",
                            "n_existing_beds", "year")))
  for (cc in c("competence", "cnes", "codufmun", "nat_jur", "tipo_leito"))
    set(b, j = cc, value = as.character(b[[cc]]))
  set(b, j = "n_existing_beds", value = as.integer(as.character(b$n_existing_beds)))
  b <- b[!is.na(n_existing_beds)]
  b <- b[substr(competence, 5, 6) == "12"]   # December only: the file is monthly
  b[, cnes7 := formatC(as.integer(cnes), width = 7, flag = "0")]
  out <- b[, .(beds_total     = sum(n_existing_beds),
               beds_obstetric = sum(n_existing_beds[tipo_leito == "4"]),
               nat_jur        = nat_jur[1],
               codufmun       = codufmun[1]),
           by = .(cnes = cnes7, year)]
  message("establishment-year beds: ", nrow(out), " rows")
  out
}

# =============================================================================
# (b) Establishment-year obstetricians (CNES-PF, December competencia)
# =============================================================================
download_estab_obstetricians <- function(years = 2013:2024, ufs = UF_LIST) {
  out <- vector("list", 0L)
  for (uf in ufs) for (y in years) {
    message("CNES-PF ", uf, " ", y)
    raw <- tryCatch(
      microdatasus::fetch_datasus(year_start = y, month_start = 12,
                                  year_end = y, month_end = 12,
                                  uf = uf, information_system = "CNES-PF"),
      error = function(e) { message("  skip: ", conditionMessage(e)); NULL })
    if (is.null(raw)) next
    dt <- as.data.table(raw)
    need <- c("CNES", "CBO", "CNS_PROF")
    if (!all(need %in% names(dt))) { rm(raw, dt); gc(); next }
    dt[, cbo6 := substr(as.character(CBO), 1, 6)]
    dt[, cnes7 := formatC(as.integer(CNES), width = 7, flag = "0")]
    hh <- if ("HORAHOSP" %in% names(dt)) as.integer(dt$HORAHOSP) else NA_integer_
    dt[, hours := fifelse(is.na(hh), 0L, hh)]

    obst <- dt[cbo6 == OBST_CBO,
               .(n_obstetricians  = uniqueN(CNS_PROF),
                 n_obst_bonds     = .N,
                 obst_hours_hosp  = sum(hours, na.rm = TRUE)),
               by = .(cnes = cnes7)]
    phys <- dt[substr(cbo6, 1, 4) %in% c(PHYS_CBO, "2252"),
               .(n_physicians = uniqueN(CNS_PROF)), by = .(cnes = cnes7)]
    agg <- merge(obst, phys, by = "cnes", all = TRUE)
    agg[, `:=`(uf = uf, year = y)]
    out[[length(out) + 1L]] <- agg
    rm(raw, dt, obst, phys, agg); gc()
  }
  res <- rbindlist(out, use.names = TRUE, fill = TRUE)
  for (cc in c("n_obstetricians", "n_obst_bonds", "obst_hours_hosp", "n_physicians"))
    set(res, i = which(is.na(res[[cc]])), j = cc, value = 0L)
  arrow::write_parquet(res, PF_OUT)
  message("saved cnes_obstetricians_estab_year.parquet (", nrow(res), " rows)")
  invisible(res)
}

# =============================================================================
# (c) Merge into the establishment-year capacity panel
# =============================================================================
build_estab_panel <- function() {
  beds <- build_estab_beds()
  pf   <- as.data.table(arrow::read_parquet(PF_OUT))
  panel <- merge(beds, pf[, .(cnes, year, n_obstetricians, n_obst_bonds,
                              obst_hours_hosp, n_physicians)],
                 by = c("cnes", "year"), all.x = TRUE)
  for (cc in c("n_obstetricians", "n_obst_bonds", "obst_hours_hosp", "n_physicians"))
    set(panel, i = which(is.na(panel[[cc]])), j = cc, value = 0L)
  panel[, sector := fifelse(grepl("^2", nat_jur), "Private",
                    fifelse(grepl("^3", nat_jur), "Nonprofit", "Public"))]
  arrow::write_parquet(panel, ESTAB_OUT)
  message("saved cnes_estab_year.parquet (", nrow(panel), " rows, ",
          uniqueN(panel$cnes), " establishments)")
  invisible(panel)
}

# -----------------------------------------------------------------------------
# Run ONCE to populate Dropbox:
# -----------------------------------------------------------------------------
if (identical(Sys.getenv("RUN_01D"), "1")) {
  download_estab_obstetricians(years = 2014:2024)   # 2014 supplies the lag for 2015
  build_estab_panel()
}
