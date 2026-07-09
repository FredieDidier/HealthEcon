# =============================================================================
# 06_robustness.R — policy nulls, referee robustness, permutation, neonatal (suggestive)
# Consolidated analysis script. Sections below are self-contained (each loads
# config + utils and its own data); they were merged from the former per-exhibit
# scripts as part of the thematic reorganization.
# =============================================================================

# =============================================================================
# 05_policy.R — supporting reduced-form evidence (NOT the identification headline).
#   (a) Parto Adequado, SINASC event study — annual, 2010-2024 (long pre-period,
#       2010-2016), treated = muni with a participating private hospital.
#   (b) Parto Adequado, TISS event study — QUARTERLY, 2015-2024 (pre = 8 quarters).
#       TISS is monthly, so the pre-trend has many points despite the short 2-year
#       pre-window (TISS coverage starts 2015).
#   (c) RN 368/2015 — national SINASC monthly cesarean series (now with a real
#       2010-2015 pre-period), interrupted-time-series style.
#   Figures 4/4b/5 ; Table 5.
# Honest limits: TISS has no hospital ID → treatment is a diluted municipal
# exposure. Parto-Adequado adoption dates within Phase 2 (2017-2021) are not
# observed, so onset is dated to 2017.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
COV   <- file.path(DROPBOX_ROOT, "build", "covariates", "input")   # parto_adequado list
SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

pa <- fread(file.path(COV, "parto_adequado_fase2_hospitais.csv"),
            colClasses = list(character = "ibge6"))
treated_set <- unique(pa[status == "Privado" & !is.na(ibge6),
                         formatC(as.integer(ibge6), width = 6, flag = "0")])

# extract i(time, treated) coefficients (+ a zero at the reference) for plotting
es_coefs <- function(mod, tv, ref) {
  ct <- as.data.table(mod$coeftable, keep.rownames = "term")[grepl(paste0(tv, "::"), term)]
  ct[, t := as.numeric(sub(paste0(".*", tv, "::(-?[0-9.]+):.*"), "\\1", term))]
  setnames(ct, c("Estimate", "Std. Error"), c("b", "se"))
  rbind(ct[, .(t, b, se)], data.table(t = ref, b = 0, se = 0))[order(t)]
}

# =============================================================================
# (a) SINASC event study — annual, long pre-period
# =============================================================================
sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, year := year(date)]
sy <- sd[sector == "Private", .(births = sum(births), ces = sum(cesarean)),
         by = .(muni, year)]
sy[, `:=`(rate = ces / births, treated = as.integer(muni %in% treated_set))]
sy <- sy[births >= 10]
es_sin <- feols(rate ~ i(year, treated, ref = 2016) | muni + year, sy,
                weights = ~births, cluster = ~muni)

# PARALLEL-TRENDS TEST (the payoff of the long 2010-2016 pre-period): treated munis
# are on a pre-existing differential downward trend, so Parto Adequado does NOT
# survive as causal evidence — the "effect" is a continuation of that trend.
pt <- wald(es_sin, keep = "year::201[0-5]:treated")
message(sprintf("Parto Adequado SINASC pre-trend test (2010-2015): F=%.2f, p=%.5f",
                pt$stat, pt$p))

c_sin <- es_coefs(es_sin, "year", 2016)
fig4 <- ggplot(c_sin, aes(t, 100 * b)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_vline(xintercept = 2016.5, linetype = "dashed", colour = "grey40") +
  geom_pointrange(aes(ymin = 100*(b-1.96*se), ymax = 100*(b+1.96*se)),
                  colour = unname(PAL["navy"])) +
  scale_x_continuous(breaks = seq(2010, 2024, 2)) +
  labs(x = NULL, y = "Private cesarean rate: treated vs control (pp)") +
  theme_paper()
save_fig(fig4, "fig04_parto_adequado_es_sinasc")

# =============================================================================
# (b) TISS event study — QUARTERLY (addresses the "only 1 pre-point" issue)
# =============================================================================
p <- as.data.table(read_parquet(file.path(OUT, "delivery_panel_muni_month.parquet")))
p <- p[!is.na(muni) & ano_mes <= 202412]
p[, `:=`(y = ano_mes %/% 100, m = ano_mes %% 100)]
p[, q := (y - 2015L) * 4L + ceiling(m / 3)]           # 2015Q1 = 1, 2016Q4 = 8 (ref)
pq <- p[, .(ces = sum(n_cesarean), del = sum(n_deliveries)), by = .(muni, q)]
pq[, `:=`(rate = ces / del, treated = as.integer(muni %in% treated_set))]
pq <- pq[del >= 5]
es_tiss <- feols(rate ~ i(q, treated, ref = 8) | muni + q, pq, weights = ~del)

c_tiss <- es_coefs(es_tiss, "q", 8)
c_tiss[, yr := 2015 + (t - 1) / 4]
fig4b <- ggplot(c_tiss, aes(yr, 100 * b)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_vline(xintercept = 2016.875, linetype = "dashed", colour = "grey40") +   # 2017Q1
  geom_pointrange(aes(ymin = 100*(b-1.96*se), ymax = 100*(b+1.96*se)),
                  colour = unname(PAL["red"]), size = 0.3) +
  scale_x_continuous(breaks = seq(2015, 2024, 1)) +
  labs(x = NULL, y = "Private cesarean rate: treated vs control (pp), quarterly") +
  theme_paper()
save_fig(fig4b, "fig04b_parto_adequado_es_tiss")

# DiD summary (post = 2017+), both sources
sy[, post := as.integer(year >= 2017)]
pq[, post := as.integer(q >= 9)]
did_sin  <- feols(rate ~ i(treated, post, ref = 0) | muni + year, sy, weights = ~births)
did_tiss <- feols(rate ~ i(treated, post, ref = 0) | muni + q,    pq, weights = ~del)
f <- file.path(TABLE, "tab05_parto_adequado.tex")
etable(did_sin, did_tiss, tex = TRUE, file = f, replace = TRUE,
       dict = c(rate = "Cesarean rate", treated = "Treated municipality",
                post = "Post (2017+)",
                "treated::1:post" = "Treated municipality $\\times$ Post (2017+)",
                muni = "Municipality", year = "Year", q = "Year-quarter"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("Private (SINASC, annual)", "Private (TISS, quarterly)"),
       title = "The \\emph{Parto Adequado} difference-in-differences does not survive the parallel-trends test",
       label = "tab:parto_adequado",
       notes = paste("\\footnotesize\\textit{Notes:} Treated = municipality with a",
         "participating \\emph{Parto Adequado} 2017--2021 dissemination-phase private hospital (a diluted",
         "exposure; TISS has no hospital identifier). Weighted by private births",
         "(SINASC) / deliveries (TISS). Standard errors, clustered by municipality, are reported in parentheses. \\emph{The",
         "SINASC event study rejects parallel pre-trends} (2010--2015 joint test",
         "$F=4.5$, $p<0.001$): treated municipalities are on a pre-existing differential",
         "downward trend, so this difference-in-differences is not interpreted as causal.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)
etable(did_sin, did_tiss, dict = c(treated = "Treated", post = "Post"), fitstat = ~ n + r2, digits = 4)

# --- Robustness: can covariates or a treated linear trend rescue causality? ---
# (i) time-varying covariates, (ii) treated-cohort linear trend, (iii) both.
# Answer: (i) does NOT flatten the pre-trend (still rejected); (ii) makes the 2017
# break vanish (it was a linear trend all along). Neither rescues identification.
ie <- as.data.table(read_parquet(
  file.path(DROPBOX_ROOT, "build", "IEPS", "output", "ieps_muni_year.parquet")))
ie <- ie[, .(muni = code_muni6, year = ano, gdp_pc, plan_cov, inc_pc, lpop = log(pop_total))]
syx <- merge(sy, ie, by = c("muni", "year"), all.x = TRUE)
syx[, year_c := year - 2016]
r_base  <- feols(rate ~ i(treated, post, ref = 0) | muni + year, syx, weights = ~births, cluster = ~muni)
r_cov   <- feols(rate ~ i(treated, post, ref = 0) + gdp_pc + plan_cov + inc_pc + lpop | muni + year, syx, weights = ~births, cluster = ~muni)
r_trend <- feols(rate ~ i(treated, post, ref = 0) + treated:year_c | muni + year, syx, weights = ~births, cluster = ~muni)
r_both  <- feols(rate ~ i(treated, post, ref = 0) + treated:year_c + gdp_pc + plan_cov + inc_pc + lpop | muni + year, syx, weights = ~births, cluster = ~muni)
fb <- file.path(TABLE, "tab05b_pretrend_robustness.tex")
etable(r_base, r_cov, r_trend, r_both, tex = TRUE, file = fb, replace = TRUE,
       keep = c("treated", "year_c"),
       dict = c(rate = "Cesarean rate", "treated::1:post" = "Treated $\\times$ Post (2017+)",
                "treated:year_c" = "Treated $\\times$ Year (linear trend)",
                gdp_pc = "GDP per capita", plan_cov = "Plan coverage",
                inc_pc = "Income p.c.", lpop = "Log population",
                muni = "Municipality", year = "Year"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       headers = c("Baseline", "+ Covariates", "+ Treated trend", "+ Both"),
       title = "Neither covariates nor a treated linear trend rescues the difference-in-differences",
       label = "tab:pretrend_robustness",
       notes = paste("\\footnotesize\\textit{Notes:} SINASC private (for-profit)",
         "cesarean rate, municipality-year 2010--2024, weighted by births. Column 1",
         "is the baseline difference-in-differences; column 2 adds time-varying",
         "municipal covariates; column 3 adds a treated-cohort linear time trend;",
         "column 4 adds both. Covariates leave the differential pre-trend intact",
         "(joint 2010--2015 test still rejects, $p<0.01$); the treated linear trend",
         "absorbs the 2017 ``break'' entirely, confirming it is a pre-existing trend,",
         "not a treatment effect. Standard errors, clustered by municipality, are reported in parentheses.", SIGNIF_NOTE))
postprocess_tex(fb, fontsize = "\\small", tabcolsep = 5)

# =============================================================================
# (c) RN 368/2015 — national SINASC monthly cesarean series (2010-2024)
# =============================================================================
sd[, ym := as.IDate(sprintf("%d-%02d-01", year(date), month(date)))]
natm <- sd[, .(all = sum(cesarean) / sum(births),
               priv = sum(cesarean[sector == "Private"]) / sum(births[sector == "Private"])),
           by = ym]
natl <- melt(natm, id.vars = "ym", variable.name = "series", value.name = "rate")
natl[, series := factor(series, c("priv", "all"), c("Private (for-profit)", "All births"))]
fig5 <- ggplot(natl, aes(ym, 100 * rate, colour = series)) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = as.IDate("2015-07-01"), linetype = "dashed", colour = "grey40") +
  scale_colour_manual(values = c("Private (for-profit)" = unname(PAL["red"]),
                                 "All births" = unname(PAL["blue"]))) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(x = NULL, y = "Cesarean rate (%)") +
  theme_paper()
save_fig(fig5, "fig05_rn368_timeline")

message("05_policy.R done")

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
       title = "Robustness of the weekend dip: sector classification, rest-day definitions, and newborn composition",
       label = "tab:referee_robustness",
       notes = paste("\\footnotesize\\textit{Notes:} Private-sector municipality-date",
         "cells, SINASC 2010--2024, weighted by births. Column 1 reclassifies each",
         "birth's establishment with the natureza jur\\'idica of its own year",
         "(2015--2024; earlier births use 2015). Columns 4--5 are composition checks:",
         "weekend (unscheduled) private births include fewer healthy scheduled",
         "term pregnancies, so newborn risk indicators shift mechanically.",
         "Standard errors, two-way clustered by municipality and date, are reported in parentheses.", SIGNIF_NOTE))
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
         "Standard errors, two-way clustered by municipality and date, are reported in parentheses.", SIGNIF_NOTE))
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
       title = "Not a price story: beneficiary-municipality aggregation",
       label = "tab:beneficiary_muni",
       notes = paste("\\footnotesize\\textit{Notes:} TISS delivery events 2015--2024",
         "aggregated by the beneficiary's municipality of residence (the baseline",
         "uses the provider municipality), weighted by deliveries; cells with at",
         "least 20 deliveries. The fee-gap null replicates.", SIGNIF_NOTE))
postprocess_tex(fb2, fontsize = "\\small", tabcolsep = 5)
etable(m_b1, m_b2, fitstat = ~ n + r2, digits = 4, headers = c("UF+Yr", "Muni+Yr"))

message("13_referee_robustness.R done")

# =============================================================================
# 15_permutation_indication.R
#   (a) RANDOMIZATION INFERENCE for the weekend dip. Day-of-week is discrete, so
#       we enumerate ALL 21 two-day "pseudo rest-day" pairs and re-estimate the
#       private cesarean dip for each. The true weekend (Sat+Sun) should be the
#       most negative; the exact permutation p-value is its rank among the 21.
#   (b) DESCRIPTIVE: share of private cesareans with NO recorded clinical
#       indication (primary diagnosis is a delivery-outcome ICD-10 code O80-O84,
#       or blank, rather than a recognized cesarean indication). Coding is
#       imperfect, so this is descriptive, not a clean "avoidable" count.
#   Table 15 → tab15_permutation ; tab15b_no_indication
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
  "\\caption{Randomization inference: the weekend dip across all 21 two-day placebos}",
  "\\label{tab:permutation}\\small",
  "\\begin{tabular}{lc}", "\\toprule",
  "Pseudo rest-day pair & Private cesarean dip (pp) \\\\", "\\midrule",
  res[, sprintf("%s%s & %.2f \\\\", days, ifelse(days == "Sun+Sat", " (true weekend)", ""), coef)],
  "\\bottomrule", "\\end{tabular}",
  sprintf("\\\\[2pt]\\footnotesize\\textit{Notes:} Each row re-estimates the private cesarean dip treating a different pair of weekdays as the ``rest days'' (SINASC 2010--2024, municipality-date cells, municipality and year fixed effects, weighted by births). The true weekend (Sun+Sat) is the most negative of all 21 placebos; exact permutation $p = %.3f$.", pval),
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
cat("\nPrivate cesareans with NO recorded clinical indication (primary CID), by year:\n")
print(byyr)

tex2 <- c("\\begin{table}[H]\\centering",
  "\\caption{Private cesareans with no recorded clinical indication}",
  "\\label{tab:no_indication}\\small",
  "\\begin{tabular}{cc}", "\\toprule",
  "Year & Share with no indication ICD-10 code (\\%) \\\\", "\\midrule",
  byyr[, sprintf("%d & %.1f \\\\", year, no_indication_pct)],
  "\\bottomrule", "\\end{tabular}",
  "\\\\[2pt]\\footnotesize\\textit{Notes:} TISS private cesarean deliveries, 2015--2024. A delivery is coded ``no indication'' when the primary diagnosis (ICD-10 code) is a delivery-outcome code (O80--O84) or blank, rather than an ICD-10 code recording a recognized cesarean indication (malpresentation, disproportion, placental or fetal complications, obstructed labor, etc.). Diagnosis coding in claims is incomplete, so this describes recorded indications, not clinical necessity.",
  "\\end{table}")
writeLines(tex2, file.path(TABLE, "tab15b_no_indication.tex"))

message("15_permutation_indication.R done")

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
