# =============================================================================
# 02_deliveries.R
# Build the delivery analytical files from ANS TISS Hospitalar. Produces TWO
# outputs in Dropbox build/TISS/output:
#   1. delivery_events_<year>.parquet  — ONE ROW PER DELIVERY (the workfile for
#      risk-adjusted / mechanism regressions). Written per year to cap memory.
#   2. delivery_panel_muni_month.parquet — municipality × month aggregates (for
#      aggregate event-studies). Small.
#
# Geography: PROVIDER municipality (CD_MUNICIPIO_PRESTADOR) — where the delivery
#   decision and physician fee sit; beneficiary municipality kept for robustness.
# Time grain: month (collapsible to year).
#
# Delivery identification: TUSS codes (build/00_utils.R) — cesarean 31309054/
#   31309208, vaginal 31309127, hourly labor assist 31309038.
# ECONOMIC vaginal fee = vaginal fee + hourly assist fee (money AND time).
#
# MECHANISM variables (why cesarean, if not price): maternal age band, primary
#   CID (risk), operator modality (organisational norms), length of stay and ICU
#   days (intensity), admission character. Plus a post-RN 368/2015 time flag.
#   The Parto-Adequado treated-municipality flag is NOT built here: it is added
#   at the muni-year level by build/03_workfile.R (as `treated_parto_adequado`),
#   using the CNES→IBGE mapping already embedded in
#   build/covariates/input/parto_adequado_fase2_hospitais.csv (ibge6 column).
#
# MEMORY: DET is filtered to ~4 procedure codes inside {arrow}; CONS is inner-
#   joined to just the delivery events; processed one year at a time with gc().
#
# PATHS: DROPBOX_ROOT from config/config.R. Packages from config/00_master_build.R.
# =============================================================================

source(here::here("config", "config.R"))
source(here::here("build", "00_utils.R"))

HOSP_IN  <- file.path(DROPBOX_ROOT, "build", "TISS", "input", "Hospitalar")
TISS_OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
dir.create(TISS_OUT, recursive = TRUE, showWarnings = FALSE)

ASSIST_CODE <- "31309038"
GEO_COL     <- "CD_MUNICIPIO_PRESTADOR"
RN368_YM    <- 201507L          # RN 368/2015 in force ≈ July 2015
YEARS       <- 2015:2025

# CONS covariates we want (selected defensively — schema varies across years).
CONS_WANT <- c("ID_EVENTO_ATENCAO_SAUDE", GEO_COL, "CD_MUNICIPIO_BENEFICIARIO",
               "UF_PRESTADOR", "ANO_MES_EVENTO", "NM_MODALIDADE", "FAIXA_ETARIA",
               "CID_1", "TEMPO_DE_PERMANENCIA", "QT_DIARIA_UTI",
               "CD_CARATER_ATENDIMENTO")

build_deliveries <- function(years = YEARS, geo_col = GEO_COL) {
  month_panels <- vector("list", 0L)

  for (y in years) {
    message("Deliveries — ", y)

    # --- DET: event-level delivery / assist fees ------------------------------
    det <- arrow::open_dataset(file.path(HOSP_IN, "DET", sprintf("Hosp_%d_DET.parquet", y))) |>
      dplyr::filter(CD_TABELA_REFERENCIA == "22",
                    CD_PROCEDIMENTO %in% c(DELIV_ALL, ASSIST_CODE)) |>
      dplyr::select(ID_EVENTO_ATENCAO_SAUDE, CD_PROCEDIMENTO, VL_ITEM_EVENTO_INFORMADO) |>
      dplyr::collect() |>
      data.table::as.data.table()
    det[, ID_EVENTO_ATENCAO_SAUDE := as.numeric(ID_EVENTO_ATENCAO_SAUDE)]
    det[, vl := as.numeric(VL_ITEM_EVENTO_INFORMADO)]
    det[, cat := data.table::fifelse(CD_PROCEDIMENTO %in% DELIV_CESAREAN, "ces",
                 data.table::fifelse(CD_PROCEDIMENTO %in% DELIV_VAGINAL,  "vag", "assist"))]

    ev <- data.table::dcast(det, ID_EVENTO_ATENCAO_SAUDE ~ cat,
                            value.var = "vl", fun.aggregate = sum, fill = 0)
    for (col in c("ces", "vag", "assist")) if (!col %in% names(ev)) ev[[col]] <- 0
    ev[, type := data.table::fifelse(ces > 0, "cesarean",
                 data.table::fifelse(vag > 0, "vaginal", NA_character_))]
    ev <- ev[!is.na(type)]
    ev[, `:=`(
      fee_delivery     = data.table::fifelse(type == "cesarean", ces, vag),
      fee_assist       = assist,
      fee_vaginal_econ = data.table::fifelse(type == "vaginal", vag + assist, NA_real_)
    )]
    ev[, c("ces", "vag", "assist") := NULL]
    rm(det); gc()

    # --- DET (2nd pass): TOTAL billed cost of the delivery hospitalization -----
    # Sum ALL item values (procedures, materials/OPME, drugs, daily rates) under
    # each delivery event, not just the delivery procedure, to get the total
    # amount billed for the hospitalization. This is the CHARGED/informed value
    # (VL_ITEM_EVENTO_INFORMADO), NOT the negotiated price paid (paid value is
    # <5% populated), so it is a gross, order-of-magnitude cost. Same arrow
    # inner-join-on-event-id pattern used for CONS below.
    det_cost <- arrow::open_dataset(file.path(HOSP_IN, "DET", sprintf("Hosp_%d_DET.parquet", y))) |>
      dplyr::select(ID_EVENTO_ATENCAO_SAUDE, VL_ITEM_EVENTO_INFORMADO) |>
      dplyr::inner_join(ev[, .(ID_EVENTO_ATENCAO_SAUDE)], by = "ID_EVENTO_ATENCAO_SAUDE") |>
      dplyr::collect() |>
      data.table::as.data.table()
    det_cost[, ID_EVENTO_ATENCAO_SAUDE := as.numeric(ID_EVENTO_ATENCAO_SAUDE)]
    tot <- det_cost[, .(total_billed = sum(as.numeric(VL_ITEM_EVENTO_INFORMADO), na.rm = TRUE)),
                    by = ID_EVENTO_ATENCAO_SAUDE]
    ev <- merge(ev, tot, by = "ID_EVENTO_ATENCAO_SAUDE", all.x = TRUE)
    rm(det_cost, tot); gc()

    # --- CONS: mechanism covariates for those events (defensive select) -------
    cons_ds <- arrow::open_dataset(file.path(HOSP_IN, "CONS", sprintf("Hosp_%d_CONS.parquet", y)))
    have <- intersect(CONS_WANT, names(cons_ds$schema))
    cons <- cons_ds |>
      dplyr::select(dplyr::all_of(have)) |>
      dplyr::inner_join(ev[, .(ID_EVENTO_ATENCAO_SAUDE)], by = "ID_EVENTO_ATENCAO_SAUDE") |>
      dplyr::collect() |>
      data.table::as.data.table()
    for (col in setdiff(CONS_WANT, have)) cons[[col]] <- NA   # fill schema gaps

    d <- merge(ev, cons, by = "ID_EVENTO_ATENCAO_SAUDE")
    data.table::setnames(d, geo_col, "muni_prestador")
    # ANO_MES_EVENTO is formatted "YYYY-MM" (e.g. "2023-01").
    d[, `:=`(
      cesarean   = as.integer(type == "cesarean"),
      year       = as.integer(substr(ANO_MES_EVENTO, 1, 4)),
      month      = as.integer(substr(ANO_MES_EVENTO, 6, 7)),
      los        = as.numeric(TEMPO_DE_PERMANENCIA),
      uti_days   = as.numeric(QT_DIARIA_UTI)
    )]
    d[, ano_mes := year * 100L + month]          # integer YYYYMM
    d[, post_rn368 := as.integer(ano_mes >= RN368_YM)]
    data.table::setnames(d,
      c("UF_PRESTADOR", "CD_MUNICIPIO_BENEFICIARIO", "NM_MODALIDADE",
        "FAIXA_ETARIA", "CID_1", "CD_CARATER_ATENDIMENTO"),
      c("uf", "muni_beneficiario", "modalidade", "faixa_etaria", "cid_1", "carater"),
      skip_absent = TRUE)

    keep <- c("ID_EVENTO_ATENCAO_SAUDE", "year", "month", "ano_mes",
              "muni_prestador", "uf", "muni_beneficiario", "modalidade",
              "faixa_etaria", "cid_1", "carater", "type", "cesarean",
              "fee_delivery", "fee_assist", "fee_vaginal_econ", "total_billed",
              "los", "uti_days", "post_rn368")
    d <- d[, intersect(keep, names(d)), with = FALSE]

    # --- OUTPUT 1: event-level workfile (one file per year) -------------------
    arrow::write_parquet(d, file.path(TISS_OUT, sprintf("delivery_events_%d.parquet", y)))

    # --- OUTPUT 2: municipality × month aggregate ----------------------------
    mm <- d[, .(
      n_deliveries = .N,
      n_cesarean   = sum(cesarean),
      csection_rate = mean(cesarean),
      fee_cesarean      = mean(fee_delivery[type == "cesarean"], na.rm = TRUE),
      fee_vaginal_econ  = mean(fee_vaginal_econ, na.rm = TRUE),
      cost_cesarean     = mean(total_billed[type == "cesarean"], na.rm = TRUE),
      cost_vaginal      = mean(total_billed[type == "vaginal"],  na.rm = TRUE),
      mean_los          = mean(los, na.rm = TRUE),
      mean_uti_days     = mean(uti_days, na.rm = TRUE),
      any_uti_share     = mean(uti_days > 0, na.rm = TRUE)
    ), by = .(muni = muni_prestador, uf, ano_mes, year, month)]
    mm[, log_fee_gap := log(fee_cesarean / fee_vaginal_econ)]
    month_panels[[length(month_panels) + 1L]] <- mm

    rm(ev, cons, d, mm); gc()
  }

  panel <- data.table::rbindlist(month_panels, use.names = TRUE, fill = TRUE)
  arrow::write_parquet(panel, file.path(TISS_OUT, "delivery_panel_muni_month.parquet"))
  message("done — event files per year + delivery_panel_muni_month.parquet (",
          nrow(panel), " muni-month rows)")
  invisible(panel)
}

build_deliveries()
