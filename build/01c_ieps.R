# =============================================================================
# 01c_ieps.R
# Prepare the IEPS municipality-year covariates for merging onto the delivery
# data. IEPS is NOT downloaded programmatically — it is a manual export from the
# IEPS data portal, copied into Dropbox from the Arms project.
#
# DATA SOURCE (manual download): IEPS Data — https://iepsdata.org.br/home/
#   The full municipality-year panel `ieps.csv` (~135 MB, 98 columns) lives in
#   Dropbox build/IEPS/input/ieps.csv (never committed).
#
# This script reads it, keeps the columns relevant to the C-section project, and
# writes a small tidy municipality-year file (build/IEPS/output/ieps_muni_year.parquet)
# with an IBGE 6-digit key (`code_muni6`) matching TISS CD_MUNICIPIO_*.
#
# PATHS: DROPBOX_ROOT from config/config.R. Packages from config/00_master_build.R.
# =============================================================================

source(here::here("config", "config.R"))

IEPS_IN  <- file.path(DROPBOX_ROOT, "build", "IEPS", "input", "ieps.csv")
IEPS_OUT <- file.path(DROPBOX_ROOT, "build", "IEPS", "output")
dir.create(IEPS_OUT, recursive = TRUE, showWarnings = FALSE)

# Column names carry accents; select by matching to avoid encoding mismatches.
prepare_ieps <- function() {
  nm <- names(data.table::fread(IEPS_IN, nrows = 1, encoding = "UTF-8"))
  pick <- function(pattern) nm[grep(pattern, nm)[1]]
  cols <- c(
    ano        = pick("^Ano$"),
    code_muni  = pick("digo IBGE"),               # 6-digit IBGE
    uf         = pick("^UF$"),
    gdp_pc     = pick("PIB P.C"),                  # PIB per capita real
    pop_total  = pick("Popula.*Total"),           # população total
    plan_cov   = pick("Cobertura de Planos"),      # % com plano de saúde (private coverage)
    prenatal   = pick("Pr.-Natal Adequado"),       # % pré-natal adequado
    esf_cov    = pick("Cobertura ESF"),
    inc_pc     = pick("Renda Domiciliar")
  )
  cols <- cols[!is.na(cols)]
  dt <- data.table::fread(IEPS_IN, select = unname(cols), encoding = "UTF-8")
  data.table::setnames(dt, unname(cols), names(cols))
  dt[, code_muni6 := formatC(as.integer(code_muni), width = 6, flag = "0")]
  arrow::write_parquet(dt, file.path(IEPS_OUT, "ieps_muni_year.parquet"))
  message("saved ieps_muni_year.parquet — ", nrow(dt), " muni-year rows, ",
          ncol(dt), " cols")
  invisible(dt)
}

prepare_ieps()
