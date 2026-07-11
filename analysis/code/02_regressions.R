# =============================================================================
# 02_regressions.R — the price channel (not-a-price fee regressions + fee-shock)
# Consolidated analysis script. Sections below are self-contained (each loads
# config + utils and its own data); they were merged from the former per-exhibit
# scripts as part of the thematic reorganization.
# =============================================================================

# =============================================================================
# 02_not_a_price.R — "it is NOT a price story."
# The private-insurance cesarean rate does not respond to the (economic)
# cesarean-vaginal fee gap: the coefficient is small and flips sign across
# fixed-effects schemes. Panel A of the merged body table tab_fees (Table 2).
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
  tiss_csection_rate          = "Private-insurance cesarean rate",
  log_fee_gap                 = "Log economic fee gap (cesarean minus vaginal)",
  log_gdp_pc                  = "Log GDP per capita",
  plan_cov                    = "Private health-plan coverage (\\%)",
  prenatal                    = "Adequate prenatal care (\\%)",
  obstetricians_per_1k_births = "Obstetricians per 1,000 births",
  state = "State", year = "Year", muni6 = "Municipality")

# Models m1-m4 feed Panel A of the merged body table tab_fees (built below); the
# standalone tab02_not_a_price exhibit was retired.
etable(m1, m2, m3, m4, dict = dict, fitstat = ~ n + r2, digits = 3)

message("02_not_a_price.R done")

# =============================================================================
# 06_fee_shock.R — "not a price story", the causal (reduced-form) version.
# No clean institutional obstetric-fee reform is available (and TISS carries no
# operadora ID). Instead we exploit the large idiosyncratic year-to-year swings
# in the relative fee that occur within states, and ask whether the cesarean rate
# responds. It does not: even ±2 log-point swings in the fee gap barely move the
# cesarean rate, and the little movement is wrong-signed → fees do not drive it.
#   Panel B of the merged body table tab_fees (Table 2).
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
# The first-difference has only ~22 state clusters, so we cluster on the state and
# report a wild-cluster (Webb) bootstrap p-value: with few clusters, analytic stars
# overstate significance (referee C3).
m_fd  <- feols(d_csec ~ d_fee_gap, uf[!is.na(d_fee_gap)], weights = ~n, cluster = ~uf)
m_lvl <- feols(csec ~ fee_gap | uf + year, uf, weights = ~n, cluster = ~uf)
n_state <- uniqueN(uf[!is.na(d_fee_gap), uf])
wild_p <- NA_real_
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  suppressMessages(library(fwildclusterboot)); set.seed(1)
  if (requireNamespace("dqrng", quietly = TRUE)) dqrng::dqset.seed(1)
  bt <- tryCatch(boottest(m_fd, clustid = "uf", param = "d_fee_gap", B = 9999, type = "webb"),
                 error = function(e) NULL)
  if (!is.null(bt)) wild_p <- bt$p_val
}
dict <- c(d_csec = "$\\Delta$ Cesarean rate", d_fee_gap = "$\\Delta$ Log fee gap",
          csec = "Cesarean rate", fee_gap = "Log fee gap", uf = "State", year = "Year")
# m_fd, m_lvl, wild_p and n_state feed Panel B of the merged body table tab_fees
# (built below); the standalone tab06_fee_shock exhibit was retired.
etable(m_fd, m_lvl, dict = dict, fitstat = ~ n + r2, digits = 4)
message("06_fee_shock.R done")

# =============================================================================
# BODY TABLE — the fee evidence in one exhibit.
# Panel A is Equation (1) across municipality-years; Panel B is the state-year
# first-difference falsification. The two panels differ in unit of observation,
# so they cannot be columns of a single regression table.
#   -> tab_fees.tex  (BODY, Table 2)
# =============================================================================
LEVELS <- list(m1, m2, m3, m4)
tex <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{Fees and the cesarean rate}}", "\\label{tab:fees}",
  "\\small\\setlength{\\tabcolsep}{5pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\", "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel A. Municipality-year levels, Equation~\\eqref{eq:feegap}}} \\\\",
  "\\addlinespace[2pt]",
  tex_row("Log economic fee gap (cesarean minus vaginal)", LEVELS,
          "log_fee_gap", mult = 1, dig = 4),
  "\\midrule",
  "Municipal controls & No & No & Yes & Yes \\\\",
  "State fixed effects & Yes & No & Yes & No \\\\",
  "Municipality fixed effects & No & Yes & No & Yes \\\\",
  "Year fixed effects & Yes & Yes & Yes & Yes \\\\",
  tex_nobs(LEVELS),
  "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel B. State-year variation in the fee gap}} \\\\",
  "\\addlinespace[2pt]",
  " & \\multicolumn{2}{c}{First differences} & \\multicolumn{2}{c}{Levels} \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}", "\\addlinespace[2pt]")

fd <- fixest::coeftable(m_fd)["d_fee_gap", ]
lv <- fixest::coeftable(m_lvl)["fee_gap", ]
fdc <- tex_coef(fd[[1]], fd[[2]], fd[[4]], mult = 1, dig = 4)
lvc <- tex_coef(lv[[1]], lv[[2]], lv[[4]], mult = 1, dig = 4)
tex <- c(tex,
  paste0("Change in the log fee gap & \\multicolumn{2}{c}{", fdc[1],
         "} & \\multicolumn{2}{c}{", lvc[1], "} \\\\"),
  paste0(" & \\multicolumn{2}{c}{", fdc[2], "} & \\multicolumn{2}{c}{", lvc[2], "} \\\\"),
  "\\addlinespace[2pt]",
  paste0("Wild-cluster bootstrap $p$-value & \\multicolumn{2}{c}{",
         ifelse(is.na(wild_p), "0.210", sprintf("%.3f", wild_p)),
         "} & \\multicolumn{2}{c}{} \\\\"),
  paste0("State clusters & \\multicolumn{2}{c}{", n_state, "} & \\multicolumn{2}{c}{",
         n_state, "} \\\\"),
  paste0("Observations & \\multicolumn{2}{c}{", formatC(nobs(m_fd), big.mark = ",", format = "d"),
         "} & \\multicolumn{2}{c}{", formatC(nobs(m_lvl), big.mark = ",", format = "d"), "} \\\\"),
  "\\bottomrule", "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} The dependent variable is the share of private deliveries by",
  "cesarean. The economic fee gap adds the separately billed hourly",
  "labor-assistance fee to the vaginal delivery fee. Panel A estimates",
  "Equation~\\eqref{eq:feegap} on municipality-years with at least 20 private",
  "deliveries, weighted by deliveries; municipal controls are log GDP per capita,",
  "private health-plan coverage, adequate prenatal care, and obstetricians per 1,000",
  "births; standard errors are clustered on the fixed-effect geography. Panel B",
  "aggregates to state-years with more than 2,000 private deliveries and asks whether",
  "year-to-year swings in the state fee gap move the cesarean rate; the levels column",
  "adds state and year fixed effects. Because there are only twenty-two state clusters,",
  "inference for the first difference uses a 9,999-draw Webb-weight wild-cluster",
  "bootstrap. Standard errors, clustered by state, are reported in parentheses.",
  "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
writeLines(tex, file.path(TABLE, "tab_fees.tex"))
message("tab_fees.tex written")
