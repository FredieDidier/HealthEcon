# =============================================================================
# 01d_sinasc_daily.R
# Build the SINASC analysis extracts behind the mechanism tests (physician
# convenience revealed by scheduling; low-risk Robson-group cesareans).
#
# DOWNLOAD (manual, run once by the collaborator, via Base dos Dados / BigQuery):
# microdatasus/datazoom proved unreliable (datazoom truncates the establishment
# CNES). Pull a TARGETED column set (not SELECT *, which is 66 cols / 6.4 GB) —
# only the ~24 variables used in the analysis:
#
#   library(basedosdados); set_billing_id("<your-gcp-project>")
#   query <- "SELECT ano, sigla_uf, id_municipio_nascimento, data_nascimento,
#     hora_nascimento, codigo_estabelecimento, local_nascimento, tipo_parto,
#     tipo_robson, semana_gestacao, gestacao_agr, tipo_gravidez, tipo_apresentacao,
#     inducao_parto, cesarea_antes_parto, idade_mae, escolaridade_mae,
#     raca_cor_mae, paridade, quantidade_parto_cesareo, quantidade_parto_normal,
#     gestacoes_ant, peso, apgar5
#     FROM basedosdados.br_ms_sinasc.microdados WHERE ano BETWEEN 2010 AND 2024"
#   download(query, path = file.path(DROPBOX_ROOT,
#            "/build/covariates/input/sinasc_births.csv"))
#   # dataset: https://basedosdados.org/dataset/48ccef51-8207-40ee-af5b-134c8ac3fb8c
#
# INGEST (this script): read the targeted CSV, add the private-sector flag,
# date parts and clean keys, and save:
#   * sinasc_births.parquet     — one row per birth (analysis base: Robson, hour,
#                                 gestation, presentation, induction, prior CS,
#                                 mother age/educ/race, birthweight, Apgar).
#   * sinasc_daily_muni.parquet — muni × date × sector aggregate (scheduling).
# The raw CSV is then DELETED (keep only the compact parquets).
#
# SECTOR of the birth establishment, from its natureza jurídica (nat_jur, CNES
#   beds): 2xxx (empresarial) → "Private" (for-profit, ~private-insurance heavy,
#   ~79% cesarean); 3xxx (sem fins lucrativos) → "Nonprofit" (filantrópico/Santas
#   Casas, SUS-heavy, intermediate); else → "Public" (1xxx public administration,
#   ~44%). `private` = 1 iff sector == "Private". Do NOT lump 3xxx into private —
#   it is SUS-heavy and inflates the "private" share to ~56%.
#
# PATHS: DROPBOX_ROOT from config/config.R.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, here)

COV_INPUT   <- file.path(DROPBOX_ROOT, "build", "covariates", "input")
SINASC_CSV  <- file.path(COV_INPUT, "sinasc_births.csv")
BIRTHS_OUT  <- file.path(COV_INPUT, "sinasc_births.parquet")
DAILY_OUT   <- file.path(COV_INPUT, "sinasc_daily_muni.parquet")

# CNES sets by natureza jurídica: for-profit (2xxx) and nonprofit (3xxx).
.cnes_sector_sets <- function() {
  beds <- data.table::as.data.table(
    arrow::read_parquet(file.path(COV_INPUT, "cnes_beds_muni_year.parquet")))
  beds[, `:=`(cnes7 = formatC(as.integer(cnes), width = 7, flag = "0"),
              nj = as.character(nat_jur))]
  list(forprofit = unique(beds[grepl("^2", nj), cnes7]),
       nonprofit = unique(beds[grepl("^3", nj), cnes7]))
}

ingest_sinasc <- function(delete_csv = TRUE) {
  s <- .cnes_sector_sets()
  dt <- data.table::fread(SINASC_CSV, showProgress = FALSE,
    colClasses = list(character = c("tipo_parto", "codigo_estabelecimento",
                                    "tipo_robson", "tipo_apresentacao")))

  dt <- dt[tipo_parto %in% c("1", "2")]
  dt[, `:=`(
    estab    = formatC(as.integer(codigo_estabelecimento), width = 7, flag = "0"),
    date     = as.IDate(data_nascimento),
    cesarean = as.integer(tipo_parto == "2"),
    muni     = formatC(as.integer(substr(as.character(id_municipio_nascimento), 1, 6)),
                       width = 6, flag = "0"))]
  dt[, sector := data.table::fifelse(estab %in% s$forprofit, "Private",
                 data.table::fifelse(estab %in% s$nonprofit, "Nonprofit", "Public"))]
  dt[, `:=`(private = as.integer(sector == "Private"),
            dow = data.table::wday(date), year = data.table::year(date))]

  arrow::write_parquet(dt, BIRTHS_OUT)
  message("saved sinasc_births.parquet — ", nrow(dt), " births, ", ncol(dt), " cols")

  daily <- dt[, .(births = .N, cesarean = sum(cesarean)), by = .(muni, date, sector)]
  arrow::write_parquet(daily, DAILY_OUT)
  message("saved sinasc_daily_muni.parquet — ", nrow(daily), " muni-date-sector rows")

  ok <- nrow(dt) > 1e6 && abs(sum(dt$cesarean) / nrow(dt) - 0.57) < 0.05
  if (isTRUE(delete_csv) && ok) { file.remove(SINASC_CSV); message("deleted raw CSV") }
  else if (!ok) warning("sanity check failed — CSV kept")
  invisible(dt)
}

# ingest_sinasc()
