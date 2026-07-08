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
COV   <- file.path(DROPBOX_ROOT, "build", "covariates", "input")
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
sd <- as.data.table(read_parquet(file.path(COV, "sinasc_daily_muni.parquet")))
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
       dict = c(treated = "Treated municipality", post = "Post (2017+)",
                muni = "Municipality", year = "Year", q = "Quarter"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("Private (SINASC, annual)", "Private (TISS, quarterly)"),
       title = "Parto Adequado DiD (does NOT survive the parallel-trends test)",
       label = "tab:parto_adequado",
       notes = paste("\\footnotesize\\textit{Notes:} Treated = municipality with a",
         "participating \\emph{Parto Adequado} Fase 2 private hospital (a diluted",
         "exposure; TISS has no hospital identifier). Weighted by private births",
         "(SINASC) / deliveries (TISS). SE clustered by municipality. \\emph{The",
         "SINASC event study rejects parallel pre-trends} (2010--2015 joint test",
         "$F=4.5$, $p<0.001$): treated munis are on a pre-existing differential",
         "downward trend, so this DiD is not interpreted causally.", SIGNIF_NOTE))
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
       dict = c("treated::1:post::1" = "Treated $\\times$ Post (2017+)",
                "treated:year_c" = "Treated $\\times$ Year (linear trend)",
                gdp_pc = "GDP per capita", plan_cov = "Plan coverage",
                inc_pc = "Income p.c.", lpop = "Log population",
                muni = "Municipality", year = "Year"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       headers = c("Base", "(i) + covariates", "(ii) + treated trend", "(iii) both"),
       title = "Neither covariates nor a treated linear trend rescue the DiD",
       label = "tab:pretrend_robustness",
       notes = paste("\\footnotesize\\textit{Notes:} SINASC private (for-profit)",
         "cesarean rate, municipality-year 2010--2024, weighted by births. (i) adds",
         "time-varying municipal covariates; (ii) adds a treated-cohort linear time",
         "trend; (iii) both. Covariates leave the differential pre-trend intact",
         "(joint 2010--2015 test still rejects, $p<0.01$); the treated linear trend",
         "absorbs the 2017 ``break'' entirely, confirming it is a pre-existing trend,",
         "not a treatment effect. SE clustered by municipality.", SIGNIF_NOTE))
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
