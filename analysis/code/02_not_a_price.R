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
       title = "The private cesarean rate does not respond to the relative fee",
       label = "tab:not_a_price",
       notes = paste("\\footnotesize\\textit{Notes:} Municipality-year regressions,",
         "weighted by the number of private deliveries. The dependent variable is the",
         "share of private deliveries by cesarean. The economic fee gap adds the",
         "separately-billed hourly labor-assistance fee to the vaginal fee. Standard",
         "errors clustered by the fixed-effect geography.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)
etable(m1, m2, m3, m4, dict = dict, fitstat = ~ n + r2, digits = 3)

message("02_not_a_price.R done")
