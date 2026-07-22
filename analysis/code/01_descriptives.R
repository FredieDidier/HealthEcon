# =============================================================================
# 01_descriptives.R — descriptive facts on Brazil's cesarean epidemic.
#
# WHAT THIS SCRIPT DOES. Three self-contained blocks (each re-loads config +
# utils and its own data), producing:
#   1. Figure 1 (body): cesarean rate by sector over time (TISS private-insurance
#      claims, SINASC for-profit establishments, SINASC public births).
#   2. Summary statistics (moved to the Supplemental Appendix, Table C.1):
#      municipality-year statistics; the body only cites them.
#   3. Hour-of-birth fingerprint and the business-hours table (Supplement); the
#      hour-of-birth panel is also re-drawn merged into body Figure 3(b) by
#      11_body_figures.R.
#   4. Municipal choropleth maps of the cesarean share (Supplement).
#
# WHY. Establish that the epidemic is real and extreme (for-profit ~79% vs public
# ~44%) and that cesareans bunch in weekday business hours — the raw pattern the
# scheduling channel then formalizes. Outputs → analysis/output/{graphs,tables,maps}.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
WFO   <- file.path(DROPBOX_ROOT, "build", "workfile", "output", "main_data.parquet")
TABLE <- here::here("analysis", "output", "tables")

# =============================================================================
# BLOCK 1 — Figure 1 (body): cesarean rate by sector over time.
# Three series on one axis: TISS private-insurance claims (~82%), SINASC
# for-profit establishments (~79%), SINASC public births (~44%). Establishes the
# for-profit-vs-public gap that the rest of the paper explains.
# =============================================================================
panel <- as.data.table(read_parquet(file.path(OUT, "delivery_panel_muni_month.parquet")))
tiss_yr <- panel[!is.na(muni) & year <= 2024,
  .(rate = sum(n_cesarean) / sum(n_deliveries)), by = year][
  , series := "Private insurance (TISS claims)"]

sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, year := year(date)]
sin_yr <- sd[year <= 2024, .(
  priv = sum(cesarean[sector == "Private"]) / sum(births[sector == "Private"]),
  pub  = sum(cesarean[sector == "Public"])  / sum(births[sector == "Public"])), by = year]

trend <- rbind(
  tiss_yr[, .(year, rate, series)],
  sin_yr[, .(year, rate = priv, series = "For-profit establishments (SINASC)")],
  sin_yr[, .(year, rate = pub,  series = "Public establishments (SINASC)")])
trend[, series := factor(series, levels = c(
  "Private insurance (TISS claims)", "For-profit establishments (SINASC)",
  "Public establishments (SINASC)"))]

pal_sector <- c("Private insurance (TISS claims)"    = unname(PAL["red"]),
                "For-profit establishments (SINASC)" = unname(PAL["orange"]),
                "Public establishments (SINASC)"     = unname(PAL["blue"]))

fig1 <- ggplot(trend, aes(year, 100 * rate, colour = series)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = pal_sector) +
  scale_x_continuous(breaks = seq(2010, 2024, 2)) +   # SINASC now starts in 2010
  scale_y_continuous(breaks = seq(0, 90, 15)) +
  coord_cartesian(ylim = c(0, 90)) +                  # zoom, never drop points
  labs(x = NULL, y = "Cesarean rate (%)") +
  # three long series labels: wrap the bottom legend to 2 rows so none is clipped
  guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
  theme_paper()
save_fig(fig1, "fig01_csection_trend", width = 9, height = 5.4)

# =============================================================================
# BLOCK 2 — summary statistics (Supplement, Table C.1): municipality-year.
# One row per municipality-year; the body cites this table but prints it in the
# Supplemental Appendix. Fees, rates, ICU use, obstetrician density, covariates.
# =============================================================================
w <- as.data.table(read_parquet(WFO))
vars <- c(
  tiss_csection_rate           = "Cesarean rate, private (TISS)",
  sinasc_private_csection_rate = "Cesarean rate, for-profit (SINASC)",
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

# --- write as a booktabs LaTeX table (house style: bold caption) --------------
hdr <- c("Variable", "Mean", "Std.\\ dev.", "10th pct.", "Median", "90th pct.", "$N$")
body <- apply(desc, 1, function(r) paste(r, collapse = " & "))
tex <- c(
  "\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Municipality-year summary statistics}}\\label{tab:descriptives}",
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

# =============================================================================
# BLOCK 3 — the within-day fingerprint: hour of birth (Supplement + body Fig 3b).
# If cesareans are scheduled around the physician's agenda, for-profit cesareans
# should bunch in business hours (morning block) while vaginal births spread
# around the clock (labor onset is uniform over the hour). SINASC records the
# exact time of birth (hora_nascimento, "HH:MM:SS").
#   fig07_hour_of_birth  — re-drawn into body Figure 3(b) by 11_body_figures.R
#   tab07_business_hours — Supplement (business-hours share vs uniform benchmark)
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

# --- hour-of-birth distribution, by delivery type × sector --------------------
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

# --- share of births in business hours (weekday, 8h-17h59) --------------------
b[, business := as.integer(weekday & hour %between% c(8, 17))]
bh <- b[, .(share = mean(business)), by = .(sector, type)]
bh_w <- dcast(bh, sector ~ type, value.var = "share")
# a birth at a uniformly random moment falls in weekday-business hours with prob
# (5/7) * (10/24) = 29.8% — the "no scheduling" benchmark.
bench <- 5 / 7 * 10 / 24
tex <- c(
  "\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Share of births occurring in business hours (weekdays, 8am--6pm)}}",
  "\\label{tab:business_hours}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Sector & Cesarean & Vaginal \\\\",
  "\\midrule",
  sprintf("%s & %.1f\\%% & %.1f\\%% \\\\",
          as.character(sector_display(bh_w$sector, c("Private", "Public"))),
          100 * bh_w$Cesarean, 100 * bh_w$Vaginal),
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

message("01_descriptives.R: hour-of-birth block done")

# =============================================================================
# BLOCK 4 — municipal choropleth maps of the cesarean epidemic (Supplement).
#   Map 1: cesarean share of ALL births by municipality (SINASC, 2020-2024 avg).
#   Map 2: cesarean share of PRIVATE-INSURANCE deliveries by municipality (TISS,
#          2020-2024, municipalities with >= 100 private deliveries in the window).
# Shows the epidemic is national, not a big-city artifact. Municipality polygons
# from geobr (IBGE 2020, simplified). Outputs → analysis/output/maps/ (PDF + PNG).
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, ggplot2, sf, geobr, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
MAP <- here::here("analysis", "output", "maps")
dir.create(MAP, recursive = TRUE, showWarnings = FALSE)

# elegant diverging-warm gradient (navy → sand → deep red)
GRAD <- c("#1A3A5C", "#2E6F9E", "#8FBBD9", "#F4E9D8", "#EFB366", "#D35D3F", "#8E1E20")

save_map <- function(plot, name, width = 7.5, height = 7.5) {
  ggsave(file.path(MAP, paste0(name, ".pdf")), plot, width = width, height = height, bg = "white")
  ggsave(file.path(MAP, paste0(name, ".png")), plot, width = width, height = height, dpi = 300, bg = "white")
}

theme_map <- function() {
  theme_void(base_size = 13) +
    theme(legend.position = "bottom",
          legend.key.width = unit(1.6, "cm"), legend.key.height = unit(0.35, "cm"),
          legend.title = element_text(size = 11), legend.text = element_text(size = 10))
}

# --- municipality polygons (7-digit code → 6-digit key) ------------------------
mu <- geobr::read_municipality(year = 2020, simplified = TRUE, showProgress = FALSE)
mu <- sf::st_as_sf(mu)
mu$muni6 <- substr(as.character(mu$code_muni), 1, 6)

# --- Map 1: all-births cesarean share (SINASC 2020-2024) -----------------------
sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, year := year(date)]
m1 <- sd[year %between% c(2020, 2024),
         .(births = sum(births), rate = sum(cesarean) / sum(births)), by = muni]
m1 <- m1[births >= 50]
mp1 <- merge(mu, m1[, .(muni6 = muni, rate)], by = "muni6", all.x = TRUE)

map1 <- ggplot(mp1) +
  geom_sf(aes(fill = 100 * rate), colour = NA) +
  scale_fill_gradientn(colours = GRAD, limits = c(15, 100),
                       na.value = "grey92",
                       name = "Cesarean rate (%), all births") +
  theme_map()
save_map(map1, "map01_csection_all")

# --- Map 2: private-insurance (TISS) cesarean share (2020-2024) ----------------
p <- as.data.table(read_parquet(file.path(OUT, "delivery_panel_muni_month.parquet")))
m2 <- p[!is.na(muni) & year %between% c(2020, 2024),
        .(del = sum(n_deliveries), rate = sum(n_cesarean) / sum(n_deliveries)),
        by = .(muni6 = formatC(as.integer(muni), width = 6, flag = "0"))]
m2 <- m2[del >= 100]
mp2 <- merge(mu, m2[, .(muni6, rate)], by = "muni6", all.x = TRUE)

map2 <- ggplot(mp2) +
  geom_sf(aes(fill = 100 * rate), colour = NA) +
  scale_fill_gradientn(colours = GRAD, limits = c(15, 100),
                       na.value = "grey92",
                       name = "Cesarean rate (%), private deliveries") +
  theme_map()
save_map(map2, "map02_csection_private")

message("01_descriptives.R: maps block done")
