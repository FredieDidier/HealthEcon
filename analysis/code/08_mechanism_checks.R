# =============================================================================
# 08_mechanism_checks.R — referee-proofing the convenience mechanism.
# Three checks that the weekend/holiday dip reflects physician scheduling of
# cesareans, not hospital staffing or patient composition:
#   (a) PRELABOR vs IN-LABOR cesareans (cesarea_antes_parto: 1 = cesarean done
#       before labor started, 2 = during labor). Scheduling can only operate on
#       prelabor cesareans → they should carry (almost) all the weekday
#       clustering; in-labor cesareans respond to emergencies and should dip far
#       less.
#   (b) DAILY COUNTS, not shares: if weekends were just different (staffing,
#       admissions), vaginal counts would also crater; instead cesarean counts
#       fall on weekends while vaginal counts barely move.
#   (c) PLACEBO — Robson group 10 (preterm): preterm births cannot be freely
#       scheduled → much smaller weekend dip.
#   Table 8 → tab08_mechanism_checks ; Figure 8 → fig08_daily_counts
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "cesarea_antes_parto", "tipo_robson",
                      "muni", "date", "dow", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
b[, weekend := as.integer(dow %in% c(1, 7))]

# --- (a) prelabor vs in-labor cesarean, weekend dip in the cesarean SHARE -----
# outcome: among all births, share delivered by prelabor cesarean vs by in-labor
# cesarean (the two components of the cesarean rate).
b[, `:=`(ces_pre = as.integer(cesarean == 1 & cesarea_antes_parto == 1),
         ces_lab = as.integer(cesarean == 1 & cesarea_antes_parto == 2))]
cellsum <- b[, .(n = .N, pre = sum(ces_pre), lab = sum(ces_lab)),
             by = .(muni, date, weekend, year, sector)]
cellsum[, `:=`(rate_pre = pre / n, rate_lab = lab / n)]
m_pre_priv <- feols(rate_pre ~ weekend | muni + year, cellsum[sector == "Private"], weights = ~n, cluster = ~muni + date)
m_lab_priv <- feols(rate_lab ~ weekend | muni + year, cellsum[sector == "Private"], weights = ~n, cluster = ~muni + date)
m_pre_pub  <- feols(rate_pre ~ weekend | muni + year, cellsum[sector == "Public"], weights = ~n, cluster = ~muni + date)
m_lab_pub  <- feols(rate_lab ~ weekend | muni + year, cellsum[sector == "Public"], weights = ~n, cluster = ~muni + date)

# --- (c) placebo: Robson 10 (preterm) vs Robson 1-2 (schedulable low-risk) ----
cell_r <- function(dat) dat[, .(rate = mean(cesarean), n = .N),
                            by = .(muni, date, weekend, year)]
m_r10  <- feols(rate ~ weekend | muni + year,
                cell_r(b[tipo_robson == "10" & sector == "Private"]), weights = ~n, cluster = ~muni + date)
m_r12  <- feols(rate ~ weekend | muni + year,
                cell_r(b[tipo_robson %in% c("01", "02") & sector == "Private"]), weights = ~n, cluster = ~muni + date)

dict <- c(weekend = "Weekend", muni = "Municipality", year = "Year",
          rate_pre = "Prelabor cesarean share", rate_lab = "In-labor cesarean share",
          rate = "Cesarean share")
f <- file.path(TABLE, "tab08_mechanism_checks.tex")
etable(m_pre_priv, m_lab_priv, m_pre_pub, m_lab_pub, m_r12, m_r10,
       tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       extralines = list(
         "Sector" = c("Private", "Private", "Public", "Public", "Private", "Private"),
         "Sample" = c("All births", "All births", "All births", "All births",
                      "Robson groups 1--2", "Robson group 10 (preterm)")),
       title = "Mechanism checks: the weekend dip is scheduled, prelabor cesareans",
       label = "tab:mechanism_checks",
       notes = paste("\\footnotesize\\textit{Notes:} Municipality-date cells, weighted",
         "by births, SINASC 2010--2024. Columns 1--4 split the cesarean rate into its",
         "prelabor (cesarean performed before labor began) and in-labor components.",
         "Columns 5--6 contrast schedulable low-risk births (Robson groups 1--2)",
         "with preterm births (Robson group 10), which cannot be freely scheduled. SE",
         "two-way clustered by municipality and date.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 4, resize = TRUE)
# six-column table: typeset in landscape so it is readable at full size
.tx <- readLines(f)
.tx <- gsub("\\begin{table}[H]", "\\begin{sidewaystable}\\centering", .tx, fixed = TRUE)
.tx <- gsub("\\end{table}", "\\end{sidewaystable}", .tx, fixed = TRUE)
writeLines(.tx, f)

# --- (b) daily counts by day-of-week: cesarean vs vaginal, private vs public --
cnt <- b[, .(births = .N), by = .(type = fifelse(cesarean == 1, "Cesarean", "Vaginal"),
             sector, dow, date)][
       , .(mean_daily = mean(births)), by = .(type, sector, dow)]
cnt[, dow_lab := factor(dow, 1:7, c("Sun","Mon","Tue","Wed","Thu","Fri","Sat"))]
cnt[, idx := 100 * mean_daily / mean_daily[dow == 3], by = .(type, sector)]  # Tue = 100
fig8 <- ggplot(cnt, aes(dow_lab, idx, colour = type, group = type)) +
  geom_hline(yintercept = 100, colour = "grey70") +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  facet_wrap(~sector) +
  scale_colour_manual(values = c(Cesarean = unname(PAL["red"]),
                                 Vaginal = unname(PAL["blue"]))) +
  labs(x = NULL, y = "Mean daily births (Tuesday = 100)") +
  theme_paper()
save_fig(fig8, "fig08_daily_counts", width = 9, height = 4.8)

message("08_mechanism_checks.R done")
