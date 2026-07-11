# =============================================================================
# 00_utils.R — shared helpers for the build pipeline.
#
# Sourced by config/00_master_build.R (defines functions only, runs nothing).
# Packages (arrow, data.table, dplyr) are loaded by the master script.
# =============================================================================

# -----------------------------------------------------------------------------
# HOSPITAL-ADMISSION PROXY
# -----------------------------------------------------------------------------
# In the ANS TISS micro-data a single `ID_EVENTO_ATENCAO_SAUDE` does NOT map
# one-to-one onto a hospital admission (internação): as stated in the data
# dictionary, one event/row can accumulate several daily inpatient visits, so a
# plain `n_distinct(ID_EVENTO_ATENCAO_SAUDE)` UNDER-counts admissions (≈7.6M for
# 2023, vs the ≈9.2M the ANS reports in the 2023 Mapa Assistencial, which is
# built from SIP, not TISS).
#
# We therefore proxy the number of admissions from the inpatient daily-visit
# procedure, whose informed quantity reflects the accumulated number of
# inpatient days/visits of the admission:
#
#     reference table  CD_TABELA_REFERENCIA == 22
#     procedure code   CD_PROCEDIMENTO      == 10102019  ("visita hospitalar a
#                                                          paciente internado")
#
# For each such item, the implied number of admissions is the informed quantity
# divided by the length of stay:
#
#     admissions_i = QT_ITEM_EVENTO_INFORMADO / TEMPO_DE_PERMANENCIA
#
# guarded so that an event with a non-positive length of stay counts as one
# admission. Summing over all items reproduces ≈8.9M for 2023, close to the ANS
# figure. Use this whenever a COUNT OF ADMISSIONS is needed; for admission-level
# analysis of a specific condition (e.g. deliveries) prefer the clinical
# identifiers (procedure / CID) at the event level.

ADMISSION_PROXY_TABLE <- "22"        # CD_TABELA_REFERENCIA (character in DET)
ADMISSION_PROXY_PROC  <- "10102019"  # CD_PROCEDIMENTO — inpatient daily visit

#' Per-item admission weight.
#' @param qt  informed quantity (QT_ITEM_EVENTO_INFORMADO)
#' @param los length of stay in days (TEMPO_DE_PERMANENCIA)
#' @return numeric admission weight; events with los <= 0 (or NA) count as 1.
admission_weight <- function(qt, los) {
  data.table::fifelse(is.na(los) | los <= 0, 1, qt / los)
}

#' Estimate total admissions — AGGREGATE ratio (Fredie's method).
#'
#' admissions = sum(QT_ITEM_EVENTO_INFORMADO) / mean(TEMPO_DE_PERMANENCIA),
#' over the inpatient daily-visit items with a positive length of stay.
#' Works lazily on an {arrow} Dataset so the ~50-66M-row DET files never need to
#' be fully loaded into memory. Reproduces ≈8.89M for 2023.
#'
#' @param det_path path to a Hosp_<year>_DET.parquet file (or an arrow Dataset).
#' @return a one-row data.table with total_items, mean_los and est_admissions.
estimate_admissions <- function(det_path) {
  ds <- if (inherits(det_path, "Dataset")) det_path else arrow::open_dataset(det_path)
  ds |>
    dplyr::filter(CD_TABELA_REFERENCIA == ADMISSION_PROXY_TABLE,
                  CD_PROCEDIMENTO      == ADMISSION_PROXY_PROC,
                  !is.na(TEMPO_DE_PERMANENCIA), TEMPO_DE_PERMANENCIA > 0) |>
    dplyr::summarise(
      total_items = sum(QT_ITEM_EVENTO_INFORMADO, na.rm = TRUE),
      mean_los    = mean(TEMPO_DE_PERMANENCIA,     na.rm = TRUE)
    ) |>
    dplyr::collect() |>
    data.table::as.data.table() |>
    (\(x) x[, est_admissions := total_items / mean_los][])()
}

#' Estimate total admissions — PER-EVENT ratio (Vinicius's method).
#'
#' Row-level weight w = QT_ITEM_EVENTO_INFORMADO / TEMPO_DE_PERMANENCIA, with a
#' same-day guard (a length of stay in [-1, 0] counts as one admission); then
#' average w within each event and sum over events. This method came CLOSER to
#' the ANS Mapa Assistencial figure (≈9.2M for 2023) than the aggregate method,
#' so treat it as the preferred admission count (2023: ≈9.40M vs ANS ≈9.2M, while
#' the aggregate method gives ≈8.89M). Lazy on {arrow}.
#'
#' @param det_path path to a Hosp_<year>_DET.parquet file (or an arrow Dataset).
#' @return numeric scalar: estimated number of admissions.
estimate_admissions_vinicius <- function(det_path) {
  ds <- if (inherits(det_path, "Dataset")) det_path else arrow::open_dataset(det_path)
  ds |>
    dplyr::filter(CD_TABELA_REFERENCIA == ADMISSION_PROXY_TABLE,
                  CD_PROCEDIMENTO      == ADMISSION_PROXY_PROC) |>
    dplyr::mutate(w = dplyr::if_else(
      TEMPO_DE_PERMANENCIA >= -1 & TEMPO_DE_PERMANENCIA <= 0,
      1, QT_ITEM_EVENTO_INFORMADO / TEMPO_DE_PERMANENCIA)) |>
    dplyr::group_by(ID_EVENTO_ATENCAO_SAUDE) |>
    dplyr::summarise(event_adm = mean(w, na.rm = TRUE)) |>
    dplyr::summarise(admissions = sum(event_adm, na.rm = TRUE)) |>
    dplyr::collect() |>
    (\(x) x$admissions)()
}

# -----------------------------------------------------------------------------
# DELIVERY (CHILDBIRTH) IDENTIFIERS — TISS Tabela 22 (TUSS professional fees)
# -----------------------------------------------------------------------------
# Preferred over CID for counting deliveries and for the cesarean-vs-vaginal
# charged-fee gap (VL_ITEM_EVENTO_INFORMADO, ~97% populated).
DELIV_CESAREAN <- c("31309054",   # Cesariana
                    "31309208")   # Cesariana com histerectomia
DELIV_VAGINAL  <- c("31309127")   # Parto (via vaginal)
DELIV_ALL      <- c(DELIV_CESAREAN, DELIV_VAGINAL)

# -----------------------------------------------------------------------------
# CNES-PF OCCUPATION CLASSIFIERS — CBO (Classificação Brasileira de Ocupações)
# -----------------------------------------------------------------------------
# The CNES professional file (CNES-PF) records each bond's occupation in a CBO
# code that MIXES two vintages: the old 4-digit CBO-94 codes (e.g. 6145) and the
# current 6-digit CBO-2002 codes (e.g. 225250), plus a handful of alphanumeric
# residual codes (e.g. "2231A1"). The classifiers therefore coerce to numeric
# for the range tests and fall back to an exact string match for the
# alphanumeric ones. Pass the RAW CBO column (they coerce to character first, so
# a character/integer/factor column is handled the same way).

#' TRUE for any physician ("médico"), across CBO-94 and CBO-2002 vintages.
is_medico <- function(cbo) {
  cbo <- as.character(cbo)
  cbo_num <- suppressWarnings(as.numeric(cbo))
  (data.table::between(cbo_num, 6105,   6190)   |
     data.table::between(cbo_num, 223101, 223157) |
     data.table::between(cbo_num, 225103, 225350) |
     cbo %in% c("2231A1","2231A2","2231F3","2231F4","2231F5",
                "2231F6","2231F7","2231F8","2231F9","2231G1"))
}

#' TRUE for obstetricians / gynecologist-obstetricians only. The four codes are
#' the CBO-2002 gineco-obstetra (225250) and clinical-obstetra (223132) plus
#' their CBO-94 predecessors (6149, 6145).
is_obstetra <- function(cbo) {
  cbo_num <- suppressWarnings(as.numeric(as.character(cbo)))
  cbo_num %in% c(225250, 223132, 6149, 6145)
}

#' TRUE for any nurse ("enfermeiro"). Not used in the current paper — kept as a
#' reference classifier alongside is_enfermeiro_obstetra (the obstetric-nurse
#' specialty, CBO 7145) in case midwife supply enters a later revision.
is_enfermeiro <- function(cbo) {
  cbo <- as.character(cbo)
  cbo_num <- suppressWarnings(as.numeric(cbo))
  (data.table::between(cbo_num, 7110,   7165)   |
     data.table::between(cbo_num, 223505, 223565) |
     cbo %in% c("2235C1","2235C2","2235C3"))
}
is_enfermeiro_obstetra <- function(cbo)
  suppressWarnings(as.numeric(as.character(cbo))) == 7145
