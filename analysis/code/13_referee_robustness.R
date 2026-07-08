# =============================================================================
# 13_referee_robustness.R — referee-stage robustness for the scheduling result.
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
#   (7) BENEFICIARY-MUNICIPALITY not-a-price: the fee-gap regressions use the
#       provider municipality; here events are re-aggregated by the BENEFICIARY's
#       municipality and the null replicates.
#   Tables 13/13b/13c/13d
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
       title = "Referee-stage robustness: sector classification, rest-day definitions, newborn composition",
       label = "tab:referee_robustness",
       notes = paste("\\footnotesize\\textit{Notes:} Private-sector municipality-date",
         "cells, SINASC 2010--2024, weighted by births. Column 1 reclassifies each",
         "birth's establishment with the natureza jur\\'idica of its own year",
         "(2015--2024; earlier births use 2015). Columns 4--5 are composition checks:",
         "weekend (unscheduled) private births include fewer healthy scheduled",
         "term pregnancies, so newborn risk indicators shift mechanically. SE two-way",
         "clustered by municipality and date.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\footnotesize", tabcolsep = 3)
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
       title = "The private weekend dip: clean clinical sample, regions, and periods",
       label = "tab:dip_region_period",
       notes = paste("\\footnotesize\\textit{Notes:} Private-sector municipality-date",
         "cells, weighted by births. \\emph{Clean low-risk} keeps births with no",
         "recorded schedulable indication: cephalic presentation, singleton, term",
         "(37--41 weeks), no prior cesarean (multiparity allowed, unlike Robson 1--2).",
         "SE two-way clustered by municipality and date.", SIGNIF_NOTE))
postprocess_tex(fc, fontsize = "\\small", tabcolsep = 3, resize = TRUE)
# nine-column table: typeset in landscape
.txc <- readLines(fc)
.txc <- gsub("\\begin{table}[H]", "\\begin{sidewaystable}\\centering", .txc, fixed = TRUE)
.txc <- gsub("\\end{table}", "\\end{sidewaystable}", .txc, fixed = TRUE)
writeLines(.txc, fc)
etable(c(list(m_clean), m_reg, m_pd), dict = dict, fitstat = ~ n, digits = 4,
       headers = c("Clean", "N", "NE", "SE", "S", "CO", "10-14", "15-19", "20-24"))

# --- (7) beneficiary-municipality not-a-price (TISS) ----------------------------
OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
ev <- rbindlist(lapply(2015:2024, function(y)
  as.data.table(read_parquet(file.path(OUT, sprintf("delivery_events_%d.parquet", y)),
    col_select = c("cesarean", "type", "fee_delivery", "fee_vaginal_econ",
                   "muni_beneficiario", "year")))))
ev <- ev[!is.na(muni_beneficiario)]
ev[, muni_b := formatC(as.integer(muni_beneficiario), width = 6, flag = "0")]
by <- ev[, .(
  deliveries = .N,
  csec       = mean(cesarean),
  fee_ces    = mean(fee_delivery[type == "cesarean"], na.rm = TRUE),
  fee_vag    = mean(fee_vaginal_econ, na.rm = TRUE)
), by = .(muni_b, year)]
by[, `:=`(log_fee_gap = log(fee_ces / fee_vag), state = substr(muni_b, 1, 2))]
by <- by[deliveries >= 20 & is.finite(log_fee_gap)]
m_b1 <- feols(csec ~ log_fee_gap | state + year,  by, weights = ~deliveries, cluster = ~state)
m_b2 <- feols(csec ~ log_fee_gap | muni_b + year, by, weights = ~deliveries, cluster = ~muni_b)

fb2 <- file.path(TABLE, "tab13b_beneficiary_muni.tex")
etable(m_b1, m_b2, tex = TRUE, file = fb2, replace = TRUE,
       dict = c(csec = "Private cesarean rate",
                log_fee_gap = "Log economic fee gap (cesarean minus vaginal)",
                state = "State", muni_b = "Municipality", year = "Year"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("State + Year FE", "Municipality + Year FE"),
       title = "Not a price story: beneficiary-municipality aggregation",
       label = "tab:beneficiary_muni",
       notes = paste("\\footnotesize\\textit{Notes:} TISS delivery events 2015--2024",
         "aggregated by the BENEFICIARY's municipality of residence (the baseline",
         "uses the provider municipality), weighted by deliveries; cells with at",
         "least 20 deliveries. The fee-gap null replicates.", SIGNIF_NOTE))
postprocess_tex(fb2, fontsize = "\\small", tabcolsep = 5)
etable(m_b1, m_b2, fitstat = ~ n + r2, digits = 4, headers = c("UF+Yr", "Muni+Yr"))

message("13_referee_robustness.R done")
