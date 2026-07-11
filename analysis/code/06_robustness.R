# =============================================================================
# 06_robustness.R — robustness, policy nulls, permutation, neonatal (Supplement).
#
# WHAT THIS SCRIPT DOES. Four self-contained blocks, ALL of whose exhibits live
# in the Supplemental Appendix:
#   (a) POLICY, as motivation not identification: the Parto Adequado SINASC event
#       study (fails parallel trends) and the RN 368/2015 timeline.
#   (b) REFEREE ROBUSTNESS for the scheduling result (time-varying sector flag,
#       alternative rest-day definitions, composition, clean sample, region/period).
#   (c) PERMUTATION inference for the weekend dip + no-indication share.
#   (d) NEONATAL suggestive check (null, underpowered — do NOT feature).
#
# LABELING. Parto Adequado is the failure of a causal DESIGN (pre-trends), not a
# program effect; the court order is an implementation failure. Both MOTIVATE,
# they do not identify. Honest limits: TISS has no hospital ID, so policy
# treatment is a diluted municipal exposure; Phase-2 adoption dates (2017-2021)
# are unobserved, so onset is dated to 2017.
# =============================================================================

# =============================================================================
# BLOCK (a) — policy as motivation (NOT the identification headline): the RN
# 368/2015 national cesarean timeline. The Parto Adequado event study is estimated
# at the hospital level with the Sun-Abraham estimator in 10_supplement.R (H/C11);
# the earlier municipality-level TWFE and TISS event studies and the DiD tables
# were removed (only the Sun-Abraham figure appears in the Supplement).
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
COV   <- file.path(DROPBOX_ROOT, "build", "covariates", "input")   # parto_adequado list
SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

# daily SINASC file, used by the RN 368/2015 national timeline below
sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, year := year(date)]

# =============================================================================
# RN 368/2015 — national SINASC monthly cesarean series (2010-2024)
# =============================================================================
sd[, ym := as.IDate(sprintf("%d-%02d-01", year(date), month(date)))]
natm <- sd[, .(all = sum(cesarean) / sum(births),
               priv = sum(cesarean[sector == "Private"]) / sum(births[sector == "Private"])),
           by = ym]
natl <- melt(natm, id.vars = "ym", variable.name = "series", value.name = "rate")
natl[, series := factor(series, c("priv", "all"), c("For-profit establishments", "All births"))]
fig5 <- ggplot(natl, aes(ym, 100 * rate, colour = series)) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = as.IDate("2015-07-01"), linetype = "dashed", colour = "grey40") +
  scale_colour_manual(values = c("For-profit establishments" = unname(PAL["red"]),
                                 "All births" = unname(PAL["blue"]))) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(x = NULL, y = "Cesarean rate (%)") +
  theme_paper()
save_fig(fig5, "fig05_rn368_timeline")

message("06_robustness.R: Block (a) policy done")

# =============================================================================
# BLOCK (b) — referee-stage robustness for the scheduling result.
#   (1) TIME-VARYING sector classification: the baseline private flag uses the
#       pooled CNES natureza jurídica; here each birth's establishment is
#       classified with the nat_jur of its own year (2015-2024; births 2010-2014
#       use the earliest available, 2015), so privatizations/reclassifications
#       do not contaminate the sector split.
#   (2) ALTERNATIVE rest-day definitions: Sunday only; and a single "rest day"
#       dummy pooling weekends and national holidays.
#   (3) NEWBORN COMPOSITION by day: among private births, weekend babies are the
#       unscheduled ones; if scheduling selects healthy, term pregnancies for
#       weekdays, weekend births should look (compositionally) worse. This is a
#       composition check, not a causal claim.
#   (4) CLINICALLY CLEAN SAMPLE: births with no recorded schedulable indication
#       (cephalic, singleton, term 37-41wk, no prior cesarean) — addresses the
#       "some scheduled cesareans are medically indicated" concern beyond Robson.
#   (5) BY REGION and (6) BY PERIOD: the weekend dip is a national, stable
#       phenomenon, not one region/era.
#   -> tab13 / tab13c robustness tables (Supplement).
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
CNES  <- file.path(DROPBOX_ROOT, "build", "CNES", "input")
TABLE <- here::here("analysis", "output", "tables")

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "estab", "cesarean", "apgar5", "peso",
                      "tipo_apresentacao", "tipo_gravidez", "semana_gestacao",
                      "quantidade_parto_cesareo", "muni", "date", "dow", "year")))
b <- b[year <= 2024]
b[, weekend := as.integer(dow %in% c(1, 7))]

# --- (1) time-varying sector flag ----------------------------------------------
beds <- as.data.table(read_parquet(file.path(CNES, "cnes_beds_muni_year.parquet")))
beds[, `:=`(cnes7 = formatC(as.integer(cnes), width = 7, flag = "0"),
            nj1 = substr(as.character(nat_jur), 1, 1))]
xw <- unique(beds[!is.na(nj1), .(estab = cnes7, byear = year, nj1)], by = c("estab", "byear"))
b[, byear := pmax(year, 2015L)]                      # births 2010-14 → 2015 classification
b <- merge(b, xw, by = c("estab", "byear"), all.x = TRUE)
b[, private_tv := as.integer(nj1 == "2")]
b[is.na(private_tv), private_tv := 0L]

cell_tv <- b[private_tv == 1, .(rate = mean(cesarean), n = .N),
             by = .(muni, date, weekend, year)]
m_tv <- feols(rate ~ weekend | muni + year, cell_tv, weights = ~n, cluster = ~muni + date)

# --- (2) alternative rest-day definitions (baseline pooled sector, private) ----
hol_dates <- {  # same holiday set as 03_scheduling.R
  easter <- function(y) { a<-y%%19; bq<-y%/%100; c<-y%%100; d<-bq%/%4; e<-bq%%4
    f<-(bq+8)%/%25; g<-(bq-f+1)%/%3; h<-(19*a+bq-d-g+15)%%30; i<-c%/%4; k<-c%%4
    l<-(32+2*e+2*i-h-k)%%7; m<-(a+11*h+22*l)%/%451; mo<-(h+l-7*m+114)%/%31
    da<-((h+l-7*m+114)%%31)+1; as.IDate(sprintf("%d-%02d-%02d",y,mo,da)) }
  fixed <- c("01-01","04-21","05-01","09-07","10-12","11-02","11-15","12-25")
  out <- as.IDate(character(0))
  for (y in 2010:2024) { e <- easter(y)
    out <- c(out, as.IDate(paste0(y, "-", fixed)), e - 2, e - 47, e - 48, e + 60) }
  sort(unique(out))
}
bp <- b[sector == "Private"]
bp[, `:=`(sunday   = as.integer(dow == 1),
          rest_day = as.integer(weekend == 1 | date %in% hol_dates))]
cell_sun  <- bp[, .(rate = mean(cesarean), n = .N), by = .(muni, date, sunday, year)]
cell_rest <- bp[, .(rate = mean(cesarean), n = .N), by = .(muni, date, rest_day, year)]
m_sun  <- feols(rate ~ sunday   | muni + year, cell_sun,  weights = ~n, cluster = ~muni + date)
m_rest <- feols(rate ~ rest_day | muni + year, cell_rest, weights = ~n, cluster = ~muni + date)

# --- (3) newborn composition by day of week (private births) -------------------
bp[, `:=`(low_apgar = as.integer(apgar5 < 7), lbw = as.integer(peso < 2500))]
cell_ap <- bp[!is.na(low_apgar), .(y = mean(low_apgar), n = .N), by = .(muni, date, weekend, year)]
cell_lb <- bp[!is.na(lbw),       .(y = mean(lbw),       n = .N), by = .(muni, date, weekend, year)]
m_ap <- feols(y ~ weekend | muni + year, cell_ap, weights = ~n, cluster = ~muni + date)
m_lb <- feols(y ~ weekend | muni + year, cell_lb, weights = ~n, cluster = ~muni + date)

dict <- c(weekend = "Weekend", sunday = "Sunday", rest_day = "Rest day (weekend or holiday)",
          rate = "Cesarean rate", y = "Newborn outcome", muni = "Municipality", year = "Year")
f <- file.path(TABLE, "tab13_referee_robustness.tex")
etable(m_tv, m_sun, m_rest, m_ap, m_lb, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       headers = c("Cesarean rate, time-varying sector", "Cesarean rate, Sunday only",
                   "Cesarean rate, rest days", "Low Apgar (5-minute)", "Low birthweight"),
       title = "Robustness of the weekend dip: sector classification, rest-day definitions, and newborn composition",
       label = "tab:referee_robustness",
       notes = paste("\\footnotesize\\textit{Notes:} For-profit municipality-date",
         "cells, SINASC 2010--2024, weighted by births. Column 1 reclassifies each",
         "birth's establishment with the natureza jur\\'idica of its own year",
         "(2015--2024; earlier births use 2015). Columns 4--5 are composition checks:",
         "weekend (unscheduled) for-profit births include fewer healthy scheduled",
         "term pregnancies, so newborn risk indicators shift mechanically.",
         "Standard errors, two-way clustered by municipality and date, are reported in parentheses.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\footnotesize", tabcolsep = 3)
# bracket the two dependent-variable groups so the column mapping is explicit
.t13 <- readLines(f)
.i13 <- grep("multicolumn\\{3\\}\\{c\\}\\{Cesarean rate\\}", .t13)
if (length(.i13))
  .t13 <- append(.t13, "      \\cmidrule(lr){2-4}\\cmidrule(lr){5-6}", after = .i13[1])
writeLines(.t13, f)
etable(m_tv, m_sun, m_rest, m_ap, m_lb, dict = dict, fitstat = ~ n, digits = 4,
       headers = c("TV sector", "Sunday", "Rest", "Apgar", "LBW"))

# --- (4) clinically clean sample: no recorded schedulable indication -----------
# cephalic, singleton, term (37-41 wk), no prior cesarean. Unlike Robson 1-2 it
# keeps multiparous women; unlike a "spontaneous labor" restriction it does NOT
# condition on labor (prelabor cesareans never labor — conditioning would drop
# the outcome of interest).
clean <- bp[tipo_apresentacao == "1" & tipo_gravidez == 1 &
            semana_gestacao %between% c(37, 41) &
            quantidade_parto_cesareo == 0]
cell_cl <- clean[, .(rate = mean(cesarean), n = .N), by = .(muni, date, weekend, year)]
m_clean <- feols(rate ~ weekend | muni + year, cell_cl, weights = ~n, cluster = ~muni + date)

# --- (5) by region and (6) by period (private, baseline weekend definition) ----
bp[, region := factor(substr(muni, 1, 1), 1:5,
                      c("North", "Northeast", "Southeast", "South", "Center-West"))]
cell_rg <- bp[!is.na(region), .(rate = mean(cesarean), n = .N),
              by = .(muni, date, weekend, year, region)]
m_reg <- lapply(levels(cell_rg$region), function(r)
  feols(rate ~ weekend | muni + year, cell_rg[region == r], weights = ~n, cluster = ~muni + date))

bp[, period := fcase(year <= 2014, "2010-2014", year <= 2019, "2015-2019",
                     default = "2020-2024")]
cell_pd <- bp[, .(rate = mean(cesarean), n = .N), by = .(muni, date, weekend, year, period)]
m_pd <- lapply(c("2010-2014", "2015-2019", "2020-2024"), function(p)
  feols(rate ~ weekend | muni + year, cell_pd[period == p], weights = ~n, cluster = ~muni + date))

fc <- file.path(TABLE, "tab13c_dip_by_region_period.tex")
etable(c(list(m_clean), m_reg, m_pd), tex = TRUE, file = fc, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       headers = c("Clinically clean low-risk", "North", "Northeast", "Southeast", "South",
                   "Center-West", "2010--2014", "2015--2019", "2020--2024"),
       title = "The for-profit weekend dip: clean clinical sample, regions, and periods",
       label = "tab:dip_region_period",
       notes = paste("\\footnotesize\\textit{Notes:} For-profit municipality-date",
         "cells, weighted by births. \\emph{Clean low-risk} keeps births with no",
         "recorded schedulable indication: cephalic presentation, singleton, term",
         "(37--41 weeks), no prior cesarean (multiparity allowed, unlike Robson 1--2).",
         "Standard errors, two-way clustered by municipality and date, are reported in parentheses.", SIGNIF_NOTE))
postprocess_tex(fc, fontsize = "\\small", tabcolsep = 3, resize = TRUE)
# nine-column table: typeset in landscape
.txc <- readLines(fc)
.txc <- gsub("\\begin{table}[H]", "\\begin{sidewaystable}\\centering", .txc, fixed = TRUE)
.txc <- gsub("\\end{table}", "\\end{sidewaystable}", .txc, fixed = TRUE)
writeLines(.txc, fc)
etable(c(list(m_clean), m_reg, m_pd), dict = dict, fitstat = ~ n, digits = 4,
       headers = c("Clean", "N", "NE", "SE", "S", "CO", "10-14", "15-19", "20-24"))

message("06_robustness.R: Block (b) referee robustness done")

# =============================================================================
# BLOCK (c) — permutation inference + no-indication share.
#   (c1) RANDOMIZATION INFERENCE for the weekend dip. Day-of-week is discrete, so
#        we enumerate ALL 21 two-day "pseudo rest-day" pairs and re-estimate the
#        for-profit cesarean dip for each. The true weekend (Sat+Sun) should be the
#        most negative; the exact permutation p-value is its rank among the 21.
#   (c2) DESCRIPTIVE: share of private-insurance cesareans with NO recorded
#        clinical indication (primary diagnosis is a delivery-outcome ICD-10 code
#        O80-O84, or blank, rather than a recognized cesarean indication). Coding
#        is imperfect, so this is descriptive, not a clean "avoidable" count.
#   -> tab15_permutation ; tab15b_no_indication (Supplement).
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
TABLE <- here::here("analysis", "output", "tables")

# --- (a) exact 2-day permutation of the weekend dip ---------------------------
b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "dow", "muni", "date", "year")))
b <- b[year <= 2024 & sector == "Private"]
md <- b[, .(ces = sum(cesarean), n = .N), by = .(muni, date, year, dow)]

combos <- combn(7L, 2L)                                   # 21 unordered pairs
res <- rbindlist(lapply(seq_len(ncol(combos)), function(j) {
  days <- combos[, j]
  md[, pw := as.integer(dow %in% days)]
  cell <- md[, .(rate = sum(ces) / sum(n), n = sum(n)), by = .(muni, date, pw, year)]
  m <- feols(rate ~ pw | muni + year, cell, weights = ~n)
  data.table(days = paste(c("Sun","Mon","Tue","Wed","Thu","Fri","Sat")[days], collapse = "+"),
             coef = 100 * coef(m)[["pw"]])
}))
res <- res[order(coef)]
obs <- res[days == "Sun+Sat", coef]
pval <- mean(res$coef <= obs)
cat(sprintf("\nTrue weekend (Sun+Sat) dip = %.2f pp; rank %d/21; exact permutation p = %.3f\n",
            obs, which(res$days == "Sun+Sat"), pval))
print(res)

tex <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Descriptive ranking: the weekend dip across all 21 two-day placebos}}",
  "\\label{tab:permutation}\\small",
  "\\begin{tabular}{lc}", "\\toprule",
  "Pseudo rest-day pair & For-profit cesarean dip (pp) \\\\", "\\midrule",
  res[, sprintf("%s%s & %.2f \\\\", days, ifelse(days == "Sun+Sat", " (true weekend)", ""), coef)],
  "\\bottomrule", "\\end{tabular}",
  "\\\\[2pt]\\footnotesize\\textit{Notes:} Each row re-estimates the for-profit cesarean dip treating a different pair of weekdays as the ``rest days'' (SINASC 2010--2024, municipality-date cells, municipality and year fixed effects, weighted by births). The true weekend (Sun+Sat) is the most negative of all 21 placebos (rank 1 of 21). Because the days of the week are not exchangeable under a known assignment mechanism, this is a descriptive ranking, not an exact randomization-inference $p$-value.",
  "\\end{table}")
writeLines(tex, file.path(TABLE, "tab15_permutation.tex"))

# --- (b) private cesareans with no recorded clinical indication ---------------
# ICD-10 3-char prefixes that RECORD a cesarean-relevant indication:
IND <- c("O30","O31","O32","O33","O34","O35","O36","O40","O41","O42","O43","O44",
         "O45","O46","O47","O48","O60","O61","O62","O63","O64","O65","O66","O67",
         "O68","O69","O71","O75","P01","P02","P03","P05","P07","P20","P95")
ev <- rbindlist(lapply(2015:2024, function(y)
  as.data.table(read_parquet(file.path(OUT, sprintf("delivery_events_%d.parquet", y)),
    col_select = c("type", "cid_1", "year")))))
ces <- ev[type == "cesarean"]
ces[, cid3 := toupper(substr(cid_1, 1, 3))]
ces[, no_indication := as.integer(is.na(cid_1) | cid_1 == "" |
                                  cid3 %in% c("O80","O81","O82","O83","O84") |
                                  !(cid3 %in% IND))]
byyr <- ces[, .(no_indication_pct = round(100 * mean(no_indication), 1), n = .N), by = year][order(year)]
cat("\nPrivate-insurance cesareans with NO recorded clinical indication (primary CID), by year:\n")
print(byyr)

tex2 <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Private-insurance cesareans with no recorded clinical indication}}",
  "\\label{tab:no_indication}\\small",
  "\\begin{tabular}{cc}", "\\toprule",
  "Year & Share with no indication ICD-10 code (\\%) \\\\", "\\midrule",
  byyr[, sprintf("%d & %.1f \\\\", year, no_indication_pct)],
  "\\bottomrule", "\\end{tabular}",
  "\\\\[2pt]\\footnotesize\\textit{Notes:} TISS private cesarean deliveries, 2015--2024. A delivery is coded ``no indication'' when the primary diagnosis (ICD-10 code) is a delivery-outcome code (O80--O84) or blank, rather than an ICD-10 code recording a recognized cesarean indication (malpresentation, disproportion, placental or fetal complications, obstructed labor, etc.). Diagnosis coding in claims is incomplete, so this describes recorded indications, not clinical necessity.",
  "\\end{table}")
writeLines(tex2, file.path(TABLE, "tab15b_no_indication.tex"))

message("06_robustness.R: Block (c) permutation + no-indication done")

# =============================================================================
# BLOCK (d) — SUGGESTIVE neonatal check: does early-term shifting show up
# in neonatal hospital use? (Null and underpowered — do NOT feature.)
# TISS records the admissions of privately insured INFANTS (age band "<1") with
# perinatal-condition diagnoses (ICD-10 chapter P). If scheduling-driven
# early-term delivery has a health footprint, municipality-years where private
# births concentrate at 37-38 weeks should also show more neonatal
# perinatal-condition admissions per private birth.
# This is CORROBORATIVE, not causal (no mother-baby linkage; ecological units;
# selection into sector) — framed as such in the paper. See CLAUDE.md
# "Clinical-cost positioning".
#   -> tab14_neonatal_suggestive (Supplement; null, kept only for transparency).
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

dict <- c(neo_rate = "Perinatal-condition admissions per private birth",
          inf_rate = "All infant admissions per private birth",
          early_term = "Share of private births at 37--38 weeks",
          csec = "For-profit cesarean rate", muni6 = "Municipality", year = "Year")
f <- file.path(TABLE, "tab14_neonatal_suggestive.tex")
etable(m1, m2, m3, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       title = "Early-term shifting and neonatal hospital use",
       label = "tab:neonatal_suggestive",
       notes = paste("\\footnotesize\\textit{Notes:} Municipality-year cells,",
         "2015--2024, weighted by private births; cells with at least 50 private",
         "births. Infant admissions are TISS hospital events of beneficiaries in the",
         "$<$1 age band, at the provider municipality; perinatal conditions are",
         "primary diagnoses of conditions originating in the perinatal period.",
         "Ecological and correlational, a corroboration of the early-term margin,",
         "not a causal estimate. SE clustered by municipality.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)
etable(m1, m2, m3, dict = dict, fitstat = ~ n, digits = 4)

message("06_robustness.R: Block (d) neonatal suggestive done")
