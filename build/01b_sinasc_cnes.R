# =============================================================================
# 01b_sinasc_cnes.R
# One-time download / ingestion of the SINASC and CNES data:
#   * CNES hospital beds (establishment level, carries natureza jurídica —
#     the private/nonprofit/public sector classifier) ... datazoom.saude
#   * CNES-PF obstetrician counts (CBO occupation file) .. microdatasus
#   * SINASC all-births micro-data 2010-2024 ............ Base dos Dados (manual)
#
# Outputs (Dropbox):
#   build/CNES/input/cnes_beds_muni_year.parquet
#   build/CNES/input/cnes_obstetricians_muni_year.parquet
#   build/SINASC/input/sinasc_births.parquet      (one row per birth)
#   build/SINASC/input/sinasc_daily_muni.parquet  (muni × date × sector)
#
# --- SINASC download (manual, run once, via Base dos Dados / BigQuery) -------
# microdatasus/datazoom proved unreliable for SINASC (datazoom truncates the
# establishment CNES). Pull a TARGETED column set (not SELECT *):
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
#            "build/SINASC/input/sinasc_births.csv"))
#   # dataset: https://basedosdados.org/dataset/48ccef51-8207-40ee-af5b-134c8ac3fb8c
# then run ingest_sinasc() below (aggregates + deletes the raw CSV).
#
# --- SECTOR of the birth establishment ---------------------------------------
# From its natureza jurídica (nat_jur, CNES beds): 2xxx (empresarial) →
# "Private" (for-profit, private-insurance heavy, ~79% cesarean); 3xxx (sem fins
# lucrativos) → "Nonprofit" (filantrópico/Santas Casas, SUS-heavy); else →
# "Public". `private` = 1 iff sector == "Private". Do NOT lump 3xxx into private
# — it is SUS-heavy and inflates the private share to ~56%.
#
# MEMORY: sources pulled one UF/year at a time and aggregated immediately; the
# SINASC CSV is read with a column subset and deleted after the parquets exist.
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

SINASC_CSV <- file.path(SINASC_INPUT, "sinasc_births.csv")
BIRTHS_OUT <- file.path(SINASC_INPUT, "sinasc_births.parquet")
DAILY_OUT  <- file.path(SINASC_INPUT, "sinasc_daily_muni.parquet")

UF_LIST <- c("AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG",
             "PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO")

# =============================================================================
# CNES hospital beds (datazoom.saude). Signature:
#   load_hospital_beds(time_period, states = "all", raw_data, language)
# raw_data = FALSE returns the treated establishment-level table; we bind years.
# =============================================================================
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
  arrow::write_parquet(res, file.path(CNES_INPUT, "cnes_beds_muni_year.parquet"))
  message("saved cnes_beds_muni_year.parquet (", nrow(res), " rows)")
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
    if (!is.na(id_col)) {
      agg <- dt[, .(n_obstetricians = uniqueN(get(id_col))), by = .(muni = get(muni_col))]
    } else {
      agg <- dt[, .(n_obstetricians = .N), by = .(muni = get(muni_col))]
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
# establishment) is labeled "Other" in ingest_sinasc(), NOT Public — the former
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
  # Priority: for-profit (2xxx) > nonprofit (3xxx) > public (1xxx); an
  # establishment matching none (unmatched / 4xxx-5xxx) is "Other", not Public.
  dt[, sector := data.table::fifelse(estab %in% s$forprofit, "Private",
                 data.table::fifelse(estab %in% s$nonprofit, "Nonprofit",
                 data.table::fifelse(estab %in% s$public,    "Public", "Other")))]
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

# -----------------------------------------------------------------------------
# Run ONCE to populate Dropbox (already done):
# -----------------------------------------------------------------------------
# download_cnes_beds(years = 2015:2024)
# download_cnes_obstetricians(years = 2015:2024)
# ingest_sinasc()          # after the manual Base-dos-Dados download above
