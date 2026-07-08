# =============================================================================
# 07_hours.R — the within-day fingerprint: hour of birth.
# If cesareans are scheduled around the physician's agenda, private cesareans
# should bunch in business hours (morning block) while vaginal births spread
# around the clock (labor is uniform in the hour of onset). SINASC records the
# exact time of birth (hora_nascimento, "HH:MM:SS").
#   Figure 7 → fig07_hour_of_birth ; Table 7 → tab07_business_hours
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("hora_nascimento", "sector", "cesarean", "dow", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
b[, hour := suppressWarnings(as.integer(substr(hora_nascimento, 1, 2)))]
b <- b[!is.na(hour) & hour %between% c(0, 23)]
b[, `:=`(type    = fifelse(cesarean == 1, "Cesarean", "Vaginal"),
         weekday = dow %in% 2:6)]

# --- Figure 7: hour-of-birth distribution, by type × sector -------------------
hd <- b[, .N, by = .(sector, type, hour)]
hd[, share := N / sum(N), by = .(sector, type)]
fig7 <- ggplot(hd, aes(hour, 100 * share, colour = type)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.2) +
  facet_wrap(~sector) +
  scale_colour_manual(values = c(Cesarean = unname(PAL["red"]),
                                 Vaginal = unname(PAL["blue"]))) +
  scale_x_continuous(breaks = seq(0, 24, 4)) +
  labs(x = "Hour of birth", y = "Share of births (%)") +
  theme_paper()
save_fig(fig7, "fig07_hour_of_birth", width = 9, height = 4.8)

# --- Table 7: share of births in business hours (weekday, 8h-17h59) -----------
b[, business := as.integer(weekday & hour %between% c(8, 17))]
bh <- b[, .(share = mean(business)), by = .(sector, type)]
bh_w <- dcast(bh, sector ~ type, value.var = "share")
# a birth at a uniformly random moment falls in weekday-business hours with prob
# (5/7) * (10/24) = 29.8% — the "no scheduling" benchmark.
bench <- 5 / 7 * 10 / 24
tex <- c(
  "\\begin{table}[H]\\centering",
  "\\caption{Share of births occurring in business hours (weekdays, 8am--6pm)}",
  "\\label{tab:business_hours}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Sector & Cesarean & Vaginal \\\\",
  "\\midrule",
  sprintf("%s & %.1f\\%% & %.1f\\%% \\\\", bh_w$sector, 100 * bh_w$Cesarean, 100 * bh_w$Vaginal),
  "\\midrule",
  sprintf("Uniform-timing benchmark & \\multicolumn{2}{c}{%.1f\\%%} \\\\", 100 * bench),
  "\\bottomrule",
  "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} SINASC 2010--2024, births with a",
        "valid time of birth. Business hours are Monday--Friday, 8:00--17:59. A birth",
        "occurring at a uniformly random moment of the week would fall in business",
        "hours with probability 29.8\\%."),
  "\\end{table}")
writeLines(tex, file.path(TABLE, "tab07_business_hours.tex"))

cat("\nShare of births in weekday business hours (benchmark 29.8%):\n")
print(bh_w[, .(sector, Cesarean = round(100 * Cesarean, 1), Vaginal = round(100 * Vaginal, 1))])

message("07_hours.R done")
