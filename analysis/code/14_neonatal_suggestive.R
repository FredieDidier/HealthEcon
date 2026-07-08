# =============================================================================
# 14_neonatal_suggestive.R — SUGGESTIVE check: does early-term shifting show up
# in neonatal hospital use?
# TISS records the admissions of privately insured INFANTS (age band "<1") with
# perinatal-condition diagnoses (ICD-10 chapter P). If scheduling-driven
# early-term delivery has a health footprint, municipality-years where private
# births concentrate at 37-38 weeks should also show more neonatal
# perinatal-condition admissions per private birth.
# This is CORROBORATIVE, not causal (no mother-baby linkage; ecological units;
# selection into sector) — framed as such in the paper. See CLAUDE.md
# "Clinical-cost positioning".
#   Table 14 → tab14_neonatal_suggestive
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, dplyr, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

HOSP  <- file.path(DROPBOX_ROOT, "build", "TISS", "input", "Hospitalar")
SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

# --- TISS: infant (<1) perinatal-condition admissions by provider muni-year ----
neo <- rbindlist(lapply(2015:2024, function(y) {
  arrow::open_dataset(file.path(HOSP, "CONS", sprintf("Hosp_%d_CONS.parquet", y))) |>
    dplyr::filter(FAIXA_ETARIA == "<1") |>
    dplyr::select(CD_MUNICIPIO_PRESTADOR, CID_1) |>
    dplyr::collect() |>
    as.data.table() |>
    (\(d) d[, .(neo_adm   = sum(substr(CID_1, 1, 1) == "P", na.rm = TRUE),
                inf_adm   = .N),
            by = .(muni = CD_MUNICIPIO_PRESTADOR)][, year := y])()
}))
neo <- neo[!is.na(muni)][, muni6 := formatC(as.integer(muni), width = 6, flag = "0")]

# --- SINASC: private births, early-term share, cesarean rate by muni-year ------
bb <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
        col_select = c("sector", "cesarean", "semana_gestacao", "muni", "year")))
sb <- bb[sector == "Private" & year %between% c(2015, 2024),
         .(priv_births = .N,
           early_term  = mean(semana_gestacao %between% c(37, 38), na.rm = TRUE),
           csec        = mean(cesarean)),
         by = .(muni6 = muni, year)]
rm(bb); gc()

# --- merge and estimate ---------------------------------------------------------
d <- merge(sb, neo[, .(muni6, year, neo_adm, inf_adm)],
           by = c("muni6", "year"), all.x = TRUE)
for (col in c("neo_adm", "inf_adm")) d[is.na(get(col)), (col) := 0]
d <- d[priv_births >= 50]
d[, `:=`(neo_rate = neo_adm / priv_births,     # perinatal admissions per private birth
         inf_rate = inf_adm / priv_births)]

m1 <- feols(neo_rate ~ early_term | muni6 + year, d, weights = ~priv_births, cluster = ~muni6)
m2 <- feols(neo_rate ~ csec       | muni6 + year, d, weights = ~priv_births, cluster = ~muni6)
m3 <- feols(inf_rate ~ early_term | muni6 + year, d, weights = ~priv_births, cluster = ~muni6)

dict <- c(neo_rate = "Perinatal-condition (ICD-10 P) infant admissions per private birth",
          inf_rate = "All infant ($<$1) admissions per private birth",
          early_term = "Share of private births at 37--38 weeks",
          csec = "Private cesarean rate", muni6 = "Municipality", year = "Year")
f <- file.path(TABLE, "tab14_neonatal_suggestive.tex")
etable(m1, m2, m3, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       title = "Suggestive: early-term shifting and neonatal hospital use",
       label = "tab:neonatal_suggestive",
       notes = paste("\\footnotesize\\textit{Notes:} Municipality-year cells,",
         "2015--2024, weighted by private births; cells with at least 50 private",
         "births. Infant admissions are TISS hospital events of beneficiaries in the",
         "$<$1 age band, at the provider municipality; perinatal conditions are",
         "ICD-10 chapter P primary diagnoses. Ecological and correlational — a",
         "corroboration of the early-term margin, not a causal estimate. SE",
         "clustered by municipality.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)
etable(m1, m2, m3, dict = dict, fitstat = ~ n, digits = 4)

message("14_neonatal_suggestive.R done")
