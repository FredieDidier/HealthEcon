# =============================================================================
# 01_download_tiss.R
# Download ANS TISS Hospitalar micro-data and store it as yearly parquet files.
#
# Project: HealthEcon
# Description: Empirical health-economics project on Brazil's private health-
#   insurance (saúde suplementar) sector, using ANS TISS hospital-admission data.
#
# DATA SOURCE:
#   ANS open data (PDA), FTP directory:
#   https://dadosabertos.ans.gov.br/FTP/PDA/TISS/HOSPITALAR/<year>/<UF>/
#     <UF>_<YYYYMM>_HOSP_<TYPE>.zip
#   One zipped ';'-delimited CSV per UF × year × month. Two record types linked
#   by ID_EVENTO_ATENCAO_SAUDE:
#     CONS = consolidado (one row per hospitalisation event)
#     DET  = detalhado   (one row per item/procedure within the event)
#
# PIPELINE:
#   download_tiss(): loops over all 27 UFs × 12 months of each requested year,
#     downloads and unzips each monthly CSV, appends UF/year/month columns, binds
#     the year, and writes Hosp_<year>_<TYPE>.parquet to
#     DROPBOX_ROOT/build/TISS/input/Hospitalar/<TYPE>.
#     Run ONCE per type — years 2015-2025 (CONS and DET) are already in Dropbox.
#
# PATHS: DROPBOX_ROOT is set in config/config.R; here::here() resolves repo paths.
# Packages (arrow, readr, dplyr) are loaded by config/00_master_build.R.
# =============================================================================

source(here::here("config", "config.R"))

INPUT_PATH <- file.path(DROPBOX_ROOT, "build", "TISS", "input", "Hospitalar")

UF_LIST <- c(
  "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO",
  "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI",
  "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"
)

# -----------------------------------------------------------------------------
# download_tiss(): download and assemble yearly parquet files for one record type
#   type  — "CONS" or "DET"
#   years — integer vector of years to download (ANS coverage starts in 2015)
#   ufs   — vector of UF codes (default: all 27)
# -----------------------------------------------------------------------------
download_tiss <- function(type = c("CONS", "DET"),
                          years = 2015:2025,
                          ufs   = UF_LIST) {
  type    <- match.arg(type)
  out_dir <- file.path(INPUT_PATH, type)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  for (year in years) {
    message("==== Downloading TISS HOSPITALAR ", type, " — ", year, " ====")

    tmp_dir <- file.path(out_dir, "tmp")
    dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
    year_chunks <- list()

    for (uf in ufs) {
      for (mm in sprintf("%02d", 1:12)) {
        base_name <- paste0(uf, "_", year, mm, "_HOSP_", type)
        url <- paste0(
          "https://dadosabertos.ans.gov.br/FTP/PDA/TISS/HOSPITALAR/",
          year, "/", uf, "/", base_name, ".zip"
        )
        zip_file <- file.path(tmp_dir, paste0(base_name, ".zip"))
        csv_file <- file.path(tmp_dir, paste0(base_name, ".csv"))

        # Not every UF × month exists; skip missing files gracefully.
        ok <- tryCatch({
          download.file(url, destfile = zip_file, mode = "wb", quiet = TRUE)
          TRUE
        }, error = function(e) FALSE)
        if (!ok) next

        tryCatch(unzip(zip_file, exdir = tmp_dir),
                 error = function(e) message("  unzip failed: ", base_name))

        if (file.exists(csv_file)) {
          df <- readr::read_delim(
            csv_file, delim = ";", escape_double = FALSE,
            locale = readr::locale(decimal_mark = ","),
            trim_ws = TRUE, show_col_types = FALSE
          )
          df$uf <- uf; df$ano <- year; df$mes <- mm
          year_chunks[[length(year_chunks) + 1L]] <- df
          rm(df); gc()
        }
        if (file.exists(zip_file)) file.remove(zip_file)
        if (file.exists(csv_file)) file.remove(csv_file)
      }
    }

    if (length(year_chunks) > 0) {
      year_df  <- dplyr::bind_rows(year_chunks)
      out_file <- file.path(out_dir, paste0("Hosp_", year, "_", type, ".parquet"))
      arrow::write_parquet(year_df, out_file)
      message("  saved: ", out_file)
      rm(year_df, year_chunks); gc()
    } else {
      message("  no data found for ", year)
    }
    unlink(tmp_dir, recursive = TRUE, force = TRUE)
  }
}

# -----------------------------------------------------------------------------
# Run ONCE to (re-)populate Dropbox input. Already done for 2015-2025.
# -----------------------------------------------------------------------------
# download_tiss("CONS", years = 2015:2025)
# download_tiss("DET",  years = 2015:2025)
