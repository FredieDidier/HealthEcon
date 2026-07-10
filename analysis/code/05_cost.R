# =============================================================================
# 05_cost.R — the cost of convenience: gestational-age shifting and newborn health
# Consolidated analysis script. Sections below are self-contained (each loads
# config + utils and its own data); they were merged from the former per-exhibit
# scripts as part of the thematic reorganization.
# =============================================================================

# =============================================================================
# 09_gestation_health.R — the cost of convenience: gestational-age shifting and
# newborn health. Scheduled (prelabor) cesareans are performed before labor
# starts, mechanically shifting births to earlier gestational ages (37-38 weeks,
# "early term") — which carries known neonatal risks. We document:
#   (a) the gestational-age distribution by sector (private mass at 37-38 vs
#       public at 39-40) and by cesarean timing (prelabor vs in-labor);
#   (b) sector gaps in early-term birth, low birthweight and low Apgar, with and
#       without maternal controls (age, education, race) and muni+year FE.
# Associational (mothers differ across sectors), but the maternal controls and
# the prelabor-cesarean channel make the scheduling interpretation concrete.
#   Figure 9 → fig09_gestation ; Table 9 → tab09_health
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "cesarea_antes_parto", "semana_gestacao",
                      "peso", "apgar5", "idade_mae", "escolaridade_mae", "raca_cor_mae",
                      "muni", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]

# --- (a) Figure 9: gestational-age distribution -------------------------------
g <- b[semana_gestacao %between% c(32, 43)]
ga <- g[, .N, by = .(sector, week = semana_gestacao)]
ga[, share := N / sum(N), by = sector]
fig9a <- ggplot(ga, aes(week, 100 * share, colour = sector)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c(Private = unname(PAL["red"]), Public = unname(PAL["blue"]))) +
  scale_x_continuous(breaks = seq(32, 43, 1)) +
  labs(x = "Gestational age at birth (weeks)", y = "Share of births (%)") +
  theme_paper()
save_fig(fig9a, "fig09_gestation")

# same distribution, private only, by cesarean timing (the channel)
gp <- g[sector == "Private" & !(cesarean == 1 & !cesarea_antes_parto %in% c(1, 2))]
gp[, group := fcase(cesarean == 0, "Vaginal",
                    cesarea_antes_parto == 1, "Prelabor cesarean",
                    cesarea_antes_parto == 2, "In-labor cesarean")]
gd <- gp[!is.na(group), .N, by = .(group, week = semana_gestacao)]
gd[, share := N / sum(N), by = group]
fig9b <- ggplot(gd, aes(week, 100 * share, colour = group)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c("Prelabor cesarean" = unname(PAL["red"]),
                                 "In-labor cesarean" = unname(PAL["orange"]),
                                 "Vaginal" = unname(PAL["blue"]))) +
  scale_x_continuous(breaks = seq(32, 43, 1)) +
  labs(x = "Gestational age at birth (weeks)", y = "Share of births (%)") +
  theme_paper()
save_fig(fig9b, "fig09b_gestation_by_timing")

# --- (b) Table 9: sector gaps in newborn-health margins -----------------------
b[, `:=`(
  early_term = as.integer(semana_gestacao %between% c(37, 38)),
  lbw        = as.integer(peso < 2500),
  low_apgar  = as.integer(apgar5 < 7),
  private    = as.integer(sector == "Private"),
  age2       = idade_mae^2
)]
b[, educ := factor(escolaridade_mae, levels = 1:5)]   # 9/NA dropped by factor
ctrl <- "idade_mae + age2 + i(educ) + i(raca_cor_mae)"

m_et0 <- feols(early_term ~ private | muni + year, b, cluster = ~muni)
m_et1 <- feols(as.formula(paste("early_term ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)
m_lb1 <- feols(as.formula(paste("lbw ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)
m_ap1 <- feols(as.formula(paste("low_apgar ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)

dict <- c(private = "For-profit establishment",
          early_term = "Early-term birth (37--38 weeks)", lbw = "Low birthweight ($<$2500g)",
          low_apgar = "Five-minute Apgar $<$ 7", idade_mae = "Mother's age",
          muni = "Municipality", year = "Year")
f <- file.path(TABLE, "tab09_health.tex")
etable(m_et0, m_et1, m_lb1, m_ap1, tex = TRUE, file = f, replace = TRUE, dict = dict,
       keep = "%private",
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       extralines = list("Maternal controls" = c("No", "Yes", "Yes", "Yes")),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       title = "For-profit--public differences in early-term birth and newborn outcomes",
       label = "tab:health",
       notes = paste("\\footnotesize\\textit{Notes:} Birth-level regressions, SINASC",
         "2010--2024, private (for-profit) vs public establishments, municipality and",
         "year fixed effects. Maternal controls: age, age$^2$, education, race.",
         "Mothers differ across sectors, so the early-term coefficient is an",
         "associational difference between establishment sectors and is not",
         "interpreted as the causal effect of prelabor scheduling.",
         "Standard errors, clustered by municipality, are reported in parentheses.",
         SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)
etable(m_et0, m_et1, m_lb1, m_ap1, dict = dict, keep = "%private", fitstat = ~ n, digits = 4)

message("09_gestation_health.R done")

# =============================================================================
# Financial cost of the epidemic (TISS billed amounts) -> tab12_cost
# Total billed cost per delivery hospitalization = sum of ALL billed items
# (procedures, materials/OPME, drugs, daily rates) under the delivery event,
# built in build/02_deliveries.R as `total_billed`. It is the CHARGED/informed
# value, not the negotiated price paid (paid value is <5% populated), so it is a
# gross, order-of-magnitude cost. Reports the cesarean-vaginal cost gap and,
# applying the ~50k scheduling-attributable private cesareans/yr from the
# decomposition, the aggregate annual cost of scheduling.
# NB: requires 02_deliveries.R to have been re-run so delivery_events carry
# `total_billed`; skipped gracefully otherwise.
# =============================================================================
OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
have_cost <- "total_billed" %in% names(read_parquet(
  file.path(OUT, "delivery_events_2023.parquet"), as_data_frame = FALSE)$schema)
if (!have_cost) {
  message("tab12_cost skipped: re-run build/02_deliveries.R to add total_billed.")
} else {
  ce <- rbindlist(lapply(2015:2024, function(y)
    as.data.table(read_parquet(file.path(OUT, sprintf("delivery_events_%d.parquet", y)),
      col_select = c("type", "total_billed")))))
  ce <- ce[is.finite(total_billed) & total_billed > 0 & !is.na(type)]
  qw  <- ce[, quantile(total_billed, c(0.005, 0.995), na.rm = TRUE)]   # trim billing outliers
  ce  <- ce[total_billed %between% qw]
  cst <- ce[, .(mean_cost = mean(total_billed), med_cost = as.numeric(median(total_billed)),
                n = .N), by = type]
  c_ces <- cst[type == "cesarean", mean_cost]; c_vag <- cst[type == "vaginal", mean_cost]
  m_ces <- cst[type == "cesarean", med_cost];  m_vag <- cst[type == "vaginal", med_cost]
  message(sprintf("Billed cost mean cesarean R$%.0f vs vaginal R$%.0f (gap %.1f%%); median %.0f vs %.0f (gap %.1f%%) -> near-parity",
                  c_ces, c_vag, 100 * (c_ces - c_vag) / c_vag, m_ces, m_vag, 100 * (m_ces - m_vag) / m_vag))

  fmt <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
  tex <- c(
    "\\begin{table}[H]\\centering",
    "\\caption{\\textbf{Total amount billed per delivery, by mode}}",
    "\\label{tab:cost}",
    "\\small",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    " & Cesarean & Vaginal \\\\",
    "\\midrule",
    sprintf("Mean billed cost (R\\$) & %s & %s \\\\",   fmt(c_ces), fmt(c_vag)),
    sprintf("Median billed cost (R\\$) & %s & %s \\\\",  fmt(m_ces), fmt(m_vag)),
    sprintf("Deliveries, 2015--2024 & %s & %s \\\\",
            fmt(cst[type == "cesarean", n]), fmt(cst[type == "vaginal", n])),
    "\\bottomrule",
    "\\end{tabular}",
    paste0("\\\\[2pt]\\footnotesize\\textit{Notes:} TISS delivery hospitalizations, 2015--2024. ",
      "Total billed cost sums all billed items (procedures, materials, drugs, daily rates) under each ",
      "delivery event; it is the charged/informed value, not the negotiated price paid, so it is a gross ",
      "order-of-magnitude figure. The top and bottom 0.5\\% of the cost distribution are trimmed. A cesarean ",
      "and a vaginal delivery bill nearly the same total amount, so the epidemic is not explained by higher ",
      "cesarean billing."),
    "\\end{table}")
  writeLines(resize_tabular(tex), file.path(TABLE, "tab12_cost.tex"))
  message("financial-cost table (tab12_cost) done")
}
