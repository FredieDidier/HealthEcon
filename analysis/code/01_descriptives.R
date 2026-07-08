# =============================================================================
# 01_descriptives.R — descriptive facts on Brazil's private cesarean epidemic.
# Figure 1: cesarean rate by sector over time. Table 1: municipality-year
# summary statistics. Outputs to analysis/output/{graphs,tables}.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
WFO   <- file.path(DROPBOX_ROOT, "build", "workfile", "output", "main_data.parquet")
TABLE <- here::here("analysis", "output", "tables")

# --- Figure 1: cesarean rate by sector over time ------------------------------
panel <- as.data.table(read_parquet(file.path(OUT, "delivery_panel_muni_month.parquet")))
tiss_yr <- panel[!is.na(muni) & year <= 2024,
  .(rate = sum(n_cesarean) / sum(n_deliveries)), by = year][
  , series := "Private (TISS claims)"]

sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, year := year(date)]
sin_yr <- sd[year <= 2024, .(
  priv = sum(cesarean[sector == "Private"]) / sum(births[sector == "Private"]),
  pub  = sum(cesarean[sector == "Public"])  / sum(births[sector == "Public"])), by = year]

trend <- rbind(
  tiss_yr[, .(year, rate, series)],
  sin_yr[, .(year, rate = priv, series = "Private (SINASC births)")],
  sin_yr[, .(year, rate = pub,  series = "Public (SINASC births)")])
trend[, series := factor(series, levels = c(
  "Private (TISS claims)", "Private (SINASC births)", "Public (SINASC births)"))]

pal_sector <- c("Private (TISS claims)"    = unname(PAL["red"]),
                "Private (SINASC births)"  = unname(PAL["orange"]),
                "Public (SINASC births)"   = unname(PAL["blue"]))

fig1 <- ggplot(trend, aes(year, 100 * rate, colour = series)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = pal_sector) +
  scale_x_continuous(breaks = seq(2010, 2024, 2)) +   # SINASC now starts in 2010
  scale_y_continuous(breaks = seq(0, 90, 15)) +
  coord_cartesian(ylim = c(0, 90)) +                  # zoom, never drop points
  labs(x = NULL, y = "Cesarean rate (%)") +
  theme_paper()
save_fig(fig1, "fig01_csection_trend")

# --- Table 1: municipality-year summary statistics ----------------------------
w <- as.data.table(read_parquet(WFO))
vars <- c(
  tiss_csection_rate           = "Cesarean rate, private (TISS)",
  sinasc_private_csection_rate = "Cesarean rate, private (SINASC)",
  log_fee_gap                  = "Log economic fee gap (cesarean minus vaginal)",
  mean_los                     = "Length of stay (days)",
  any_uti_share                = "Share of deliveries with any ICU day",
  obstetricians_per_1k_births  = "Obstetricians per 1,000 births",
  gdp_pc                       = "GDP per capita (R\\$ thousands)",
  plan_cov                     = "Private health-plan coverage (\\%)",
  prenatal                     = "Adequate prenatal care (\\%)")

desc <- rbindlist(lapply(names(vars), function(v) {
  x <- w[[v]]
  data.table(Variable = vars[[v]],
             Mean   = mean(x, na.rm = TRUE),  `Std. dev.` = sd(x, na.rm = TRUE),
             `10th pct.` = quantile(x, .10, na.rm = TRUE),
             Median = median(x, na.rm = TRUE),
             `90th pct.` = quantile(x, .90, na.rm = TRUE),
             `N` = sum(!is.na(x)))
}))
num <- setdiff(names(desc), c("Variable", "N"))
desc[, (num) := lapply(.SD, function(x) formatC(x, format = "f", digits = 2, big.mark = ",")), .SDcols = num]
desc[, N := formatC(N, format = "d", big.mark = ",")]

# --- write as a booktabs LaTeX table (house style) ----------------------------
hdr <- c("Variable", "Mean", "Std.\\ dev.", "10th pct.", "Median", "90th pct.", "$N$")
body <- apply(desc, 1, function(r) paste(r, collapse = " & "))
tex <- c(
  "\\begin{table}[H]\\centering",
  "\\caption{Municipality-year summary statistics}\\label{tab:descriptives}",
  "\\small",
  "\\begin{tabular}{lrrrrrr}",
  "\\toprule",
  paste(paste(hdr, collapse = " & "), "\\\\"),
  "\\midrule",
  paste0(body, " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} One observation per municipality-year",
        "(2015--2024). TISS variables from ANS private-insurance claims; SINASC and",
        "covariates as described in the text."),
  "\\end{table}")
writeLines(resize_tabular(tex), file.path(TABLE, "tab01_descriptives.tex"))
print(desc)

message("01_descriptives.R done")
