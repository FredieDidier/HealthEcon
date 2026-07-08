# =============================================================================
# 06_fee_shock.R — "not a price story", the causal (reduced-form) version.
# No clean institutional obstetric-fee reform is available (and TISS carries no
# operadora ID). Instead we exploit the large idiosyncratic year-to-year swings
# in the relative fee that occur within states, and ask whether the cesarean rate
# responds. It does not: even ±2 log-point swings in the fee gap barely move the
# cesarean rate, and the little movement is wrong-signed → fees do not drive it.
#   Figure 6 → fig06_fee_shock ; Table 6 → tab06_fee_shock
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
       title = "The cesarean rate does not respond to changes in the relative fee",
       label = "tab:fee_shock",
       notes = paste("\\footnotesize\\textit{Notes:} State-year observations, weighted",
         "by private deliveries. Column 1 first-differences both variables; column 2",
         "is in levels with state and year fixed effects. Even large idiosyncratic",
         "swings in the relative fee leave the cesarean rate essentially unchanged.",
         SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)

# --- Figure 6: scatter of the fee-gap change vs the cesarean-rate change -------
fig6 <- ggplot(uf[!is.na(d_fee_gap)], aes(d_fee_gap, 100 * d_csec)) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_point(colour = unname(PAL["navy"]), alpha = 0.5, size = 1.6) +
  geom_smooth(method = "lm", se = TRUE, colour = unname(PAL["red"]), linewidth = 0.9) +
  labs(x = "Change in log fee gap (cesarean minus vaginal)",
       y = "Change in cesarean rate (pp)") +
  theme_paper()
save_fig(fig6, "fig06_fee_shock")

etable(m_fd, m_lvl, dict = dict, fitstat = ~ n + r2, digits = 4)
message("06_fee_shock.R done")
