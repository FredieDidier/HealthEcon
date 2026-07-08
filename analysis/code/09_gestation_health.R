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

dict <- c(private = "Private (for-profit) establishment",
          early_term = "Early-term birth (37--38 weeks)", lbw = "Low birthweight ($<$2500g)",
          low_apgar = "Five-minute Apgar $<$ 7", idade_mae = "Mother's age",
          muni = "Municipality", year = "Year")
f <- file.path(TABLE, "tab09_health.tex")
etable(m_et0, m_et1, m_lb1, m_ap1, tex = TRUE, file = f, replace = TRUE, dict = dict,
       keep = "%private",
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       extralines = list("Maternal controls" = c("No", "Yes", "Yes", "Yes")),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       title = "The health footprint: early-term shifting in the private sector",
       label = "tab:health",
       notes = paste("\\footnotesize\\textit{Notes:} Birth-level regressions, SINASC",
         "2010--2024, private (for-profit) vs public establishments, municipality and",
         "year fixed effects. Maternal controls: age, age$^2$, education, race.",
         "Estimates are associational (mothers differ across sectors) and quantify",
         "the epidemic's health margins, with early-term shifting the direct",
         "consequence of prelabor scheduling. Standard errors clustered by municipality.",
         SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)
etable(m_et0, m_et1, m_lb1, m_ap1, dict = dict, keep = "%private", fitstat = ~ n, digits = 4)

message("09_gestation_health.R done")
