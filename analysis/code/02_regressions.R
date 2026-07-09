# =============================================================================
# 02_regressions.R — the price channel (not-a-price fee regressions + fee-shock)
# Consolidated analysis script. Sections below are self-contained (each loads
# config + utils and its own data); they were merged from the former per-exhibit
# scripts as part of the thematic reorganization.
# =============================================================================

# =============================================================================
# 02_not_a_price.R — "it is NOT a price story."
# The private cesarean rate does not respond to the (economic) cesarean-vaginal
# fee gap: the coefficient is small and flips sign across fixed-effects schemes.
# Table 2 → analysis/output/tables/tab02_not_a_price.tex.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

WFO   <- file.path(DROPBOX_ROOT, "build", "workfile", "output", "main_data.parquet")
TABLE <- here::here("analysis", "output", "tables")

w <- as.data.table(read_parquet(WFO))
w[, `:=`(state = substr(muni6, 1, 2), log_gdp_pc = log(gdp_pc))]
w <- w[year <= 2024 & tiss_deliveries >= 20 & is.finite(log_fee_gap)]

m1 <- feols(tiss_csection_rate ~ log_fee_gap | state + year,  w, weights = ~tiss_deliveries)
m2 <- feols(tiss_csection_rate ~ log_fee_gap | muni6 + year, w, weights = ~tiss_deliveries)
m3 <- feols(tiss_csection_rate ~ log_fee_gap + log_gdp_pc + plan_cov + prenatal +
              obstetricians_per_1k_births | state + year, w, weights = ~tiss_deliveries)
m4 <- feols(tiss_csection_rate ~ log_fee_gap + log_gdp_pc + plan_cov + prenatal +
              obstetricians_per_1k_births | muni6 + year, w, weights = ~tiss_deliveries)

dict <- c(
  tiss_csection_rate          = "Private cesarean rate",
  log_fee_gap                 = "Log economic fee gap (cesarean minus vaginal)",
  log_gdp_pc                  = "Log GDP per capita",
  plan_cov                    = "Private health-plan coverage (\\%)",
  prenatal                    = "Adequate prenatal care (\\%)",
  obstetricians_per_1k_births = "Obstetricians per 1,000 births",
  state = "State", year = "Year", muni6 = "Municipality")

f <- file.path(TABLE, "tab02_not_a_price.tex")
etable(m1, m2, m3, m4, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 3, digits.stats = 3,
       title = "The private cesarean rate and the economic fee gap",
       label = "tab:not_a_price",
       notes = paste("\\footnotesize\\textit{Notes:} Municipality-year regressions,",
         "weighted by the number of private deliveries. The dependent variable is the",
         "share of private deliveries by cesarean. The economic fee gap adds the",
         "separately-billed hourly labor-assistance fee to the vaginal fee. Standard",
         "errors clustered by the fixed-effect geography.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)
etable(m1, m2, m3, m4, dict = dict, fitstat = ~ n + r2, digits = 3)

message("02_not_a_price.R done")

# =============================================================================
# 06_fee_shock.R — "not a price story", the causal (reduced-form) version.
# No clean institutional obstetric-fee reform is available (and TISS carries no
# operadora ID). Instead we exploit the large idiosyncratic year-to-year swings
# in the relative fee that occur within states, and ask whether the cesarean rate
# responds. It does not: even ±2 log-point swings in the fee gap barely move the
# cesarean rate, and the little movement is wrong-signed → fees do not drive it.
#   Table 6 → tab06_fee_shock  (the former Figure 6 scatter was dropped as
#   redundant with the table).
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
TABLE <- here::here("analysis", "output", "tables")

p <- as.data.table(read_parquet(file.path(OUT, "delivery_panel_muni_month.parquet")))
p <- p[!is.na(muni) & year <= 2024 & is.finite(fee_cesarean) & is.finite(fee_vaginal_econ)]

# state-year fee gap and cesarean rate (delivery-weighted)
uf <- p[, .(csec = weighted.mean(csection_rate, n_deliveries, na.rm = TRUE),
            fee_ces = weighted.mean(fee_cesarean, n_deliveries, na.rm = TRUE),
            fee_vag = weighted.mean(fee_vaginal_econ, n_deliveries, na.rm = TRUE),
            n = sum(n_deliveries)), by = .(uf, year)]
uf[, fee_gap := log(fee_ces / fee_vag)]
setorder(uf, uf, year)
uf[, `:=`(d_fee_gap = fee_gap - shift(fee_gap),
          d_csec    = csec - shift(csec)), by = uf]
uf <- uf[n > 2000]

# --- Table 6: cesarean rate does not respond to fee-gap changes ---------------
m_fd  <- feols(d_csec ~ d_fee_gap, uf[!is.na(d_fee_gap)], weights = ~n)
m_lvl <- feols(csec ~ fee_gap | uf + year, uf, weights = ~n, cluster = ~uf)
dict <- c(d_csec = "$\\Delta$ Cesarean rate", d_fee_gap = "$\\Delta$ Log fee gap",
          csec = "Cesarean rate", fee_gap = "Log fee gap", uf = "State", year = "Year")
f <- file.path(TABLE, "tab06_fee_shock.tex")
etable(m_fd, m_lvl, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("First differences", "Levels"),
       title = "Changes in the cesarean rate and changes in the fee gap",
       label = "tab:fee_shock",
       notes = paste("\\footnotesize\\textit{Notes:} State-year observations, weighted",
         "by private deliveries. Column 1 first-differences both variables; column 2",
         "is in levels with state and year fixed effects. Even large idiosyncratic",
         "swings in the relative fee leave the cesarean rate essentially unchanged.",
         SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)

# NB: the companion scatter (former Figure 6, fig06_fee_shock) was dropped as
# redundant with Table 6 (tab06_fee_shock); the table is the exhibit of record.

etable(m_fd, m_lvl, dict = dict, fitstat = ~ n + r2, digits = 4)
message("06_fee_shock.R done")
