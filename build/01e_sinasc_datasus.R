# =============================================================================
# 01e_sinasc_datasus.R
# The birth records from the Ministry of Health's own repository (DATASUS FTP),
# the same files the sibling WorldCupHealth project reads.
#
# Features of the source that the analysis has to respect: the Robson group is
# partly filled in 2011-2012 and empty in 2013 (every Robson analysis uses
# 2014-2024), the cesarean-timing field is usable from 2012, and the time of
# birth is filled for 99.7 percent or more of births in every year.
#
# Output (Dropbox):
#   build/SINASC/input/datasus/dn_<year>.parquet   one lean file per year, the
#                                                  fields below, all character
#   build/SINASC/input/sinasc_births.parquet       via ingest_datasus(), with the
#                                                  column names and types the
#                                                  analysis scripts already use
#   build/SINASC/input/sinasc_daily_muni.parquet
#
# Files are the 27 state files DN<UF><YYYY>.DBC of the consolidated DNRES
# directory. Two traps, both from WorldCupHealth/build/11: the extension is not
# consistently cased on the FTP, and some years also carry a national file
# (DNBR2014, DNBR2015) and a file of births abroad (DNEX2021); reading them with
# the state files counts births twice or adds births with no Brazilian
# municipality. The state codes are enumerated, and a year with fewer than 27
# state files, or a file that fails to download or parse, STOPS the build.
# =============================================================================

source(here::here("config", "config.R"))
source(here::here("build", "00_utils.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, curl, RCurl, stringr, read.dbc, here)

SIN_IN  <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
DN_DIR  <- file.path(SIN_IN, "datasus")
RAW_DIR <- file.path(path.expand("~/Library/Caches/HealthEcon"), "sinasc_raw_dbc")
dir.create(DN_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(RAW_DIR, recursive = TRUE, showWarnings = FALSE)

FTP   <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SINASC/1996_/Dados/DNRES/"
UFS   <- c("AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG",
           "PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO")
YEARS <- 2010:2024

# DATASUS field -> the name the analysis uses
MAP <- c(DTNASC = "data_nascimento", HORANASC = "hora_nascimento",
         CODMUNNASC = "id_municipio_nascimento", CODESTAB = "codigo_estabelecimento",
         LOCNASC = "local_nascimento", PARTO = "tipo_parto", TPROBSON = "tipo_robson",
         SEMAGESTAC = "semana_gestacao", GESTACAO = "gestacao_agr",
         GRAVIDEZ = "tipo_gravidez", TPAPRESENT = "tipo_apresentacao",
         STTRABPART = "inducao_parto", STCESPARTO = "cesarea_antes_parto",
         IDADEMAE = "idade_mae", ESCMAE = "escolaridade_mae",
         RACACORMAE = "raca_cor_mae", PARIDADE = "paridade",
         QTDPARTCES = "quantidade_parto_cesareo", QTDPARTNOR = "quantidade_parto_normal",
         QTDGESTANT = "gestacoes_ant", PESO = "peso", APGAR5 = "apgar5",
         # added 2026-09-28 for the balance table (16_design_checks.R): newborn sex
         # is predetermined and cannot be sorted on by scheduling; prenatal fields
         # describe care before the delivery date is chosen
         SEXO = "sexo", CONSULTAS = "consultas_prenatal_cat",
         CONSPRENAT = "consultas_prenatal", MESPRENAT = "mes_inicio_prenatal")

listing <- function(u) {
  for (a in 1:4) {
    l <- tryCatch(RCurl::getURL(u, ftp.use.epsv = TRUE, dirlistonly = TRUE),
                  error = function(e) NULL)
    if (!is.null(l)) return(unlist(stringr::str_split(l, "\r*\n")))
    Sys.sleep(5 * a)
  }
  stop("the DATASUS FTP listing failed four times: ", u)
}

download_datasus <- function(years = YEARS) {
  pool <- listing(FTP)
  for (yr in years) {
    out <- file.path(DN_DIR, sprintf("dn_%d.parquet", yr))
    if (file.exists(out)) { message("[", yr, "] already built - skip"); next }
    f <- pool[stringr::str_detect(pool, stringr::regex(sprintf("^DN[A-Z]{2}%d[.]dbc$", yr),
                                                       ignore_case = TRUE))]
    f <- f[toupper(substr(f, 3, 4)) %in% UFS]
    if (length(f) != 27L) stop(sprintf("[%d] %d state files on the FTP, not 27", yr, length(f)))
    dests <- file.path(RAW_DIR, f)
    for (a in 1:4) {
      still <- !(file.exists(dests) & file.size(dests) > 0)
      if (!any(still)) break
      tryCatch(curl::multi_download(paste0(FTP, f[still]), dests[still], resume = TRUE,
                                    progress = FALSE, timeout = 900, multiplex = FALSE,
                                    connecttimeout = 30, low_speed_limit = 2000,
                                    low_speed_time = 60),
               error = function(e) message("  download error: ", conditionMessage(e)))
      Sys.sleep(5 * a)
    }
    parts <- lapply(seq_along(f), function(i) {
      d <- tryCatch(as.data.table(read.dbc::read.dbc(dests[i], as.is = TRUE)),
                    error = function(e) NULL)
      if (is.null(d) || !nrow(d)) stop(sprintf("[%d] %s failed to download or parse", yr, f[i]))
      for (v in setdiff(names(MAP), names(d))) d[, (v) := NA_character_]
      d <- d[, names(MAP), with = FALSE]
      d[, (names(d)) := lapply(.SD, function(x) trimws(as.character(x)))]
      d[, uf_file := toupper(substr(f[i], 3, 4))]
      d
    })
    z <- rbindlist(parts, use.names = TRUE)
    z[, ano := yr]
    write_parquet(z, out, compression = "zstd")
    message(sprintf("[%d] %s births from 27 state files", yr, format(nrow(z), big.mark = ",")))
    unlink(dests); rm(z, parts); gc()
  }
}

# The analysis file, in the column names and types the analysis already reads.
# Sector is assigned by establishment and year exactly as before (01b).
ingest_datasus <- function(years = YEARS) {
  source(here::here("build", "01b_cnes.R"), local = TRUE)   # assign_sector_year()
  ii <- function(x) suppressWarnings(as.integer(x))
  dt <- rbindlist(lapply(years, function(yr)
    as.data.table(read_parquet(file.path(DN_DIR, sprintf("dn_%d.parquet", yr))))))
  setnames(dt, names(MAP), unname(MAP))
  dt[, date := as.IDate(as.Date(data_nascimento, format = "%d%m%Y"))]
  dt <- dt[!is.na(date) & year(date) %in% years]
  dt <- dt[tipo_parto %in% c("1", "2")]
  for (v in c("semana_gestacao", "tipo_gravidez", "inducao_parto", "cesarea_antes_parto",
              "idade_mae", "escolaridade_mae", "raca_cor_mae", "paridade",
              "quantidade_parto_cesareo", "quantidade_parto_normal", "gestacoes_ant",
              "peso", "apgar5", "gestacao_agr", "local_nascimento",
              "consultas_prenatal_cat", "consultas_prenatal", "mes_inicio_prenatal"))
    set(dt, j = v, value = ii(dt[[v]]))
  # Robson as the two-digit code the analysis matches ("01".."10"); blank -> NA
  dt[, tipo_robson := fifelse(!is.na(ii(tipo_robson)), sprintf("%02d", ii(tipo_robson)), NA_character_)]
  dt[tipo_apresentacao == "", tipo_apresentacao := NA_character_]
  # time of birth HHMM; the analysis reads the hour from its first two characters
  dt[, hora_nascimento := fifelse(grepl("^[0-9]{4}$", hora_nascimento), hora_nascimento, NA_character_)]
  dt[, `:=`(
    estab    = fifelse(grepl("^[0-9]+$", codigo_estabelecimento),
                       formatC(ii(codigo_estabelecimento), width = 7, flag = "0"), NA_character_),
    cesarean = as.integer(tipo_parto == "2"),
    muni     = formatC(ii(substr(id_municipio_nascimento, 1, 6)), width = 6, flag = "0"),
    dow      = wday(date), year = year(date))]
  assign_sector_year(dt)
  out <- file.path(SIN_IN, "sinasc_births.parquet")
  # The join inside assign_sector_year() leaves a secondary index on dt, and
  # arrow writes R attributes into the file metadata: 42M index positions made a
  # footer that arrow then refused to read ("Exceeded size limit"). Drop it.
  setindex(dt, NULL); setattr(dt, "sorted", NULL)
  write_parquet(dt, out)
  daily <- dt[, .(births = .N, cesarean = sum(cesarean)), by = .(muni, date, sector)]
  write_parquet(daily, file.path(SIN_IN, "sinasc_daily_muni.parquet"))
  message(sprintf("sinasc_births.parquet: %s births, %s daily cells",
                  format(nrow(dt), big.mark = ","), format(nrow(daily), big.mark = ",")))
  invisible(dt)
}

if (identical(Sys.getenv("RUN_01E"), "1")) {
  download_datasus()
  ingest_datasus()
}
