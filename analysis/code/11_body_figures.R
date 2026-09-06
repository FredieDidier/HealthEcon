# =============================================================================
# 11_body_figures.R — the merged multi-panel figures of the main text.
#
# The body carries three figures. Figure 1 (sector trends) is built in
# 01_descriptives.R. This script builds the other two:
#
#   fig_two_margins.pdf            (Figure 2)
#     (a) price margin: binscatter of the private-insurance cesarean rate on the
#         log economic fee gap, municipality and year fixed effects removed
#     (b) scheduling margin: weekend / holiday / eve gradients for the public and
#         for-profit sectors and the within-municipality-day for-profit differential
#     The one exhibit that shows both channels side by side: fees flat, calendar steep.
#
#   fig_calendar_fingerprints.pdf  (Figure 3)
#     (a) cesarean rate by day of week and sector          [was fig02]
#     (b) hour-of-birth distribution by delivery mode      [was fig07]
#     (c) weekend gradient by Robson group and sector      [coefficients from 12]
#
# Panel (c) reads analysis/output/robson_grad.rds, the slim coefficient table
# saved by 12_subgroups.R, so RUN 12 BEFORE 11. If the file is absent the panel
# is skipped and the figure falls back to its two-panel layout.
#
# The gestational-age panels (fig_gestation_panels.pdf) are built here but now live
# in the Supplementary Appendix. The bridge-holiday displacement event study, which
# used to be panel (c) of the calendar figure, also moved to the supplement, where
# it is the standalone fig_long_weekend_event.pdf saved by 08_long_weekends.R.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, patchwork, here)
source(here::here("analysis", "code", "00_utils.R"))

# Panel titles for the merged figures. theme_paper() blanks plot.subtitle, so an
# element_text() override inherits vjust = 0.5 from `text` and the title floats
# in the middle of whatever vertical space patchwork allots the title row --
# which is padded to the tallest panel and therefore leaves a panel whose plot
# needs less headroom with its title drifting up, away from its own axes. Anchor
# it to the top (vjust = 1) so every panel title sits the same distance above
# its panel.
#
# Sizes are the sizes the reader sees: every figure here is saved at FIG_WIDTH
# (6.5in) and included at \textwidth, so \includegraphics places it at scale 1.
panel_title <- ggplot2::theme(
  plot.subtitle = ggplot2::element_text(size = 10.5, face = "bold", hjust = 0.5,
                                        vjust = 1, margin = ggplot2::margin(b = 6)))

SIN  <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
WFO  <- file.path(DROPBOX_ROOT, "build", "workfile", "output", "main_data.parquet")
AOUT <- here::here("analysis", "output")

# movable-holiday calendar, matching 07_main_specification.R / 08_long_weekends.R
easter_sunday <- function(y) {
  a <- y %% 19; b <- y %/% 100; c <- y %% 100
  d <- b %/% 4; e <- b %% 4; f <- (b + 8) %/% 25; g <- (b - f + 1) %/% 3
  h <- (19*a + b - d - g + 15) %% 30; i <- c %/% 4; k <- c %% 4
  l <- (32 + 2*e + 2*i - h - k) %% 7; m <- (a + 11*h + 22*l) %/% 451
  mo <- (h + l - 7*m + 114) %/% 31; da <- ((h + l - 7*m + 114) %% 31) + 1
  as.IDate(sprintf("%d-%02d-%02d", y, mo, da))
}
holiday_dates <- function(years) {
  fixed <- c("01-01","04-21","05-01","09-07","10-12","11-02","11-15","12-25")
  out <- as.IDate(character(0))
  for (y in years) {
    out <- c(out, as.IDate(paste0(y, "-", fixed)))
    e <- easter_sunday(y); out <- c(out, e - 2, e - 47, e - 48, e + 60)
  }
  sort(unique(out))
}
# weighted quantiles (type-7-style), used to build equal-mass binscatter bins
wq <- function(x, w, p) {
  o <- order(x); x <- x[o]; w <- w[o]
  cw <- (cumsum(w) - 0.5 * w) / sum(w)
  stats::approx(cw, x, xout = p, rule = 2, ties = "ordered")$y
}

# =============================================================================
# FIGURE 2 — the two margins of cesarean supply
# =============================================================================

# --- shared: municipality x date x sector cells (also feeds Figure 3a) --------
sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, date := as.IDate(date)]
sd[, `:=`(dow = wday(date), year = year(date))]
sd <- sd[year <= 2024]

# --- panel (b): scheduling gradients -----------------------------------------
# Public and for-profit own gradients (Equation 2) and the within-municipality-day
# for-profit differential (Equation 3), from the same cells as scripts 03 and 07.
hol <- holiday_dates(2010:2024)
sg <- sd[sector %in% c("Private", "Public") & births > 0]
sg[, `:=`(weekend = as.integer(dow %in% c(1, 7)),
          holiday = as.integer(date %in% hol),
          private = as.integer(sector == "Private"),
          rate    = cesarean / births)]
sg[, eve := as.integer((date + 1L) %in% hol | dow == 6L)]
m_pub  <- feols(rate ~ weekend + holiday + eve | muni + year,
                sg[private == 0], weights = ~births, cluster = ~muni + date)
m_priv <- feols(rate ~ weekend + holiday + eve | muni + year,
                sg[private == 1], weights = ~births, cluster = ~muni + date)
m_dif  <- feols(rate ~ i(private, weekend, ref = 0) + i(private, holiday, ref = 0) +
                  i(private, eve, ref = 0) | muni^date + muni^sector,
                sg, weights = ~births, cluster = ~muni + date)
pull <- function(m, keys, series) {
  ct <- fixest::coeftable(m)[keys, , drop = FALSE]
  data.table(series = series, margin = c("Weekend", "National holiday", "Eve of rest day"),
             b = 100 * ct[, 1], se = 100 * ct[, 2])
}
gd <- rbindlist(list(
  pull(m_pub,  c("weekend", "holiday", "eve"), "Public"),
  pull(m_priv, c("weekend", "holiday", "eve"), "For-profit"),
  pull(m_dif,  c("private::1:weekend", "private::1:holiday", "private::1:eve"),
       "For-profit differential")))
gd[, series := factor(series, levels = c("Public", "For-profit", "For-profit differential"))]
gd[, margin := factor(margin, levels = c("Weekend", "National holiday", "Eve of rest day"))]
rm(sg); gc()

pb <- ggplot(gd, aes(margin, b, colour = series, group = series)) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_errorbar(aes(ymin = b - 1.96 * se, ymax = b + 1.96 * se), width = 0.18,
                position = position_dodge(width = 0.55), linewidth = 0.5) +
  geom_point(aes(shape = series), position = position_dodge(width = 0.55), size = 2.4) +
  scale_colour_manual(values = c(Public = unname(PAL["blue"]),
                                 `For-profit` = unname(PAL["red"]),
                                 `For-profit differential` = unname(PAL["navy"]))) +
  scale_shape_manual(values = c(Public = 16, `For-profit` = 17, `For-profit differential` = 15)) +
  # Half of a 6.5in figure is 3.25in of panel: the tick labels are wrapped over two
  # lines and the three-series legend is stacked in two rows so neither the labels
  # nor the legend run past the panel.
  scale_x_discrete(labels = c(Weekend = "Weekend", `National holiday` = "National\nholiday",
                              `Eve of rest day` = "Eve of\nrest day")) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE),
         shape  = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(x = NULL, y = "Change in cesarean rate (pp)",
       subtitle = "(b) The scheduling margin") +
  theme_paper() + panel_title

# --- panel (a): price margin binscatter --------------------------------------
# Matches Table 1, Panel A, column 4: the private-insurance cesarean rate on the
# log economic fee gap, municipality and year fixed effects plus the municipal
# controls (log GDP per capita, plan coverage, prenatal care, obstetrician
# density), weighted by deliveries. The binscatter partials the controls and the
# fixed effects out of both axes (FWL), so the dashed line is that coefficient.
w <- as.data.table(read_parquet(WFO))
w[, log_gdp_pc := log(gdp_pc)]
CTRL <- c("log_gdp_pc", "plan_cov", "prenatal", "obstetricians_per_1k_births")
w <- w[year <= 2024 & tiss_deliveries >= 20 & is.finite(log_fee_gap) &
         is.finite(tiss_csection_rate) & stats::complete.cases(w[, ..CTRL]) &
         is.finite(rowSums(as.matrix(w[, ..CTRL])))]
rhs <- paste(CTRL, collapse = " + ")
my <- weighted.mean(w$tiss_csection_rate, w$tiss_deliveries)
mx <- weighted.mean(w$log_fee_gap, w$tiss_deliveries)
w[, yr := resid(feols(as.formula(paste("tiss_csection_rate ~", rhs, "| muni6 + year")),
                      w, weights = ~tiss_deliveries)) + my]
w[, xr := resid(feols(as.formula(paste("log_fee_gap ~", rhs, "| muni6 + year")),
                      w, weights = ~tiss_deliveries)) + mx]
slope <- coef(feols(as.formula(paste("tiss_csection_rate ~ log_fee_gap +", rhs, "| muni6 + year")),
                    w, weights = ~tiss_deliveries))["log_fee_gap"]
# equal-mass bins over the central 98 percent of the residualized fee gap
lo <- wq(w$xr, w$tiss_deliveries, 0.01); hi <- wq(w$xr, w$tiss_deliveries, 0.99)
wb <- w[xr >= lo & xr <= hi]
brks <- wq(wb$xr, wb$tiss_deliveries, seq(0, 1, length.out = 21)); brks[1] <- brks[1] - 1e-9
wb[, bin := cut(xr, breaks = brks, include.lowest = TRUE, labels = FALSE)]
bs <- wb[, .(x = weighted.mean(xr, tiss_deliveries),
             y = 100 * weighted.mean(yr, tiss_deliveries)), by = bin][order(bin)]
line <- data.table(x = c(lo, hi))[, y := 100 * (my + slope * (x - mx))]

pa <- ggplot() +
  geom_line(data = line, aes(x, y), colour = unname(PAL["grey"]),
            linewidth = 0.7, linetype = "22") +
  geom_point(data = bs, aes(x, y), colour = unname(PAL["red"]), size = 2.2) +
  scale_x_continuous(breaks = seq(-0.6, 0.6, 0.3)) +
  coord_cartesian(ylim = c(60, 90)) +
  labs(x = "Relative fee, cesarean vs vaginal (log)",
       y = "Private-insurance cesarean rate (%)",
       subtitle = "(a) The price margin") +
  theme_paper() + panel_title
rm(w, wb); gc()

# Plain composition. Do NOT add plot_layout(guides = "collect") here: the
# installed patchwork puts the collected guide on the RIGHT and there is no way
# to move it to the bottom without the `&` theme operator, which this patchwork
# does not define against a theme. Both were tried on 2026-07-27; the collected
# legend stole roughly a third of the width and the two panel titles overlapped.
# Panel (b) keeps its own two-row legend instead (see guides() above).
fig2 <- pa | pb
ggsave(file.path(AOUT, "graphs", "fig_two_margins.pdf"), fig2, width = FIG_WIDTH, height = 3.6)
ggsave(file.path(AOUT, "graphs", "fig_two_margins.png"), fig2, width = FIG_WIDTH, height = 3.6, dpi = 300)

# =============================================================================
# FIGURE 3 — calendar fingerprints
# =============================================================================

# --- panel (a): cesarean rate by day of week and sector ----------------------
dsec <- sd[sector %in% SECTOR_LEVELS]   # drop "Other" (unmatched estabs)
dow_tab <- dsec[, .(rate = sum(cesarean) / sum(births)), by = .(sector, dow)]
dow_tab[, `:=`(dow_lab = factor(dow, 1:7, c("Sun","Mon","Tue","Wed","Thu","Fri","Sat")),
               sector = sector_display(sector))]
pa3 <- ggplot(dow_tab, aes(dow_lab, 100 * rate, colour = sector, group = sector,
                           linetype = sector)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]),
                                 Nonprofit = unname(PAL["orange"]),
                                 Public = unname(PAL["blue"]))) +
  scale_linetype_manual(values = lty_for(c("For-profit", "Nonprofit", "Public"))) +
  scale_y_continuous(breaks = seq(30, 90, 10)) +
  labs(x = NULL, y = "Cesarean rate (%)", subtitle = "(a) Cesarean rate by day of week") +
  theme_paper() + panel_title
rm(sd, dsec); gc()

# --- panel (b): hour-of-birth distribution, for-profit vs public -------------
b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("hora_nascimento", "sector", "cesarean", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
b[, hour := suppressWarnings(as.integer(substr(hora_nascimento, 1, 2)))]
b <- b[!is.na(hour) & hour %between% c(0, 23)]
b[, `:=`(type = fifelse(cesarean == 1, "Cesarean", "Vaginal"),
         sector = sector_display(sector, c("Private", "Public")))]
hd <- b[, .N, by = .(sector, type, hour)]
hd[, share := N / sum(N), by = .(sector, type)]
# The sector strips go BELOW the panel: a strip above it would push this panel's
# title up relative to the unfaceted panels (a) and (c), which is exactly the
# asymmetry the shared `panel_title` element is there to avoid. The x-axis title
# is dropped because the panel title already names the axis.
pb3 <- ggplot(hd, aes(hour, 100 * share, colour = type, linetype = type)) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~sector, strip.position = "bottom") +
  scale_colour_manual(values = c(Cesarean = unname(PAL["red"]), Vaginal = unname(PAL["blue"]))) +
  scale_linetype_manual(values = lty_for(c("Cesarean", "Vaginal"))) +
  # drop the 24 break: next to the 0 of the neighbouring facet the two labels touch
  scale_x_continuous(breaks = seq(0, 18, 6)) +
  labs(x = NULL, y = "Share of births (%)", subtitle = "(b) Hour of birth") +
  theme_paper() + panel_title + theme(strip.placement = "outside")
rm(b, hd); gc()

# --- panel (c): weekend gradient by Robson group ------------------------------
# The dip should track schedulability: large in the nulliparous term groups (1-2)
# and in the previous-cesarean group (5), small in the preterm group (10).
# Coefficients come from 12_subgroups.R; skip the panel if it has not been run.
RG <- file.path(AOUT, "robson_grad.rds")
if (file.exists(RG)) {
  rg <- as.data.table(readRDS(RG))[!is.na(b)]
  rg[, `:=`(sector = sector_display(sector, c("Private", "Public")),
            g = factor(as.integer(robson), levels = 1:10))]
  pc3 <- ggplot(rg, aes(g, b, colour = sector, group = sector)) +
    geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
    geom_errorbar(aes(ymin = b - 1.96 * se, ymax = b + 1.96 * se), width = 0.18,
                  position = position_dodge(width = 0.45), linewidth = 0.5) +
    geom_point(aes(shape = sector), position = position_dodge(width = 0.45), size = 2.2) +
    scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]),
                                   Public = unname(PAL["blue"]))) +
    scale_shape_manual(values = c(`For-profit` = 17, Public = 16)) +
    labs(x = "Robson group", y = "Weekend change in cesarean rate (pp)",
         subtitle = "(c) Weekend gradient by Robson group") +
    theme_paper() + panel_title
  # Two rows, not three columns. The printed width is fixed at 6.5in, so a third
  # column would leave each panel 2.2in wide and force \includegraphics to scale
  # the whole figure down; stacking (c) on its own row keeps every panel legible
  # at scale 1 and gives the ten Robson groups the full width they need.
  fig3 <- (pa3 | pb3) / pc3
  fh <- 6.6
} else {
  message("11: robson_grad.rds not found — run 12_subgroups.R for Figure 3 panel (c).")
  fig3 <- pa3 | pb3
  fh <- 3.6
}
ggsave(file.path(AOUT, "graphs", "fig_calendar_fingerprints.pdf"), fig3, width = FIG_WIDTH, height = fh)
ggsave(file.path(AOUT, "graphs", "fig_calendar_fingerprints.png"), fig3, width = FIG_WIDTH, height = fh, dpi = 300)

# =============================================================================
# Gestational-age panels (Supplementary Appendix figure)
# =============================================================================
g <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "cesarea_antes_parto", "semana_gestacao", "year")))
g <- g[year <= 2024 & sector %in% c("Private", "Public") & semana_gestacao %between% c(32, 43)]
ga <- g[, .N, by = .(sector, week = semana_gestacao)]
ga[, share := N / sum(N), by = sector]
ga[, sector := sector_display(sector, c("Private", "Public"))]
qa <- ggplot(ga, aes(week, 100 * share, colour = sector, linetype = sector)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.4) +
  scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]), Public = unname(PAL["blue"]))) +
  scale_linetype_manual(values = lty_for(c("For-profit", "Public"))) +
  scale_x_continuous(breaks = seq(32, 43, 2)) +
  labs(x = "Gestational age at birth (weeks)", y = "Share of births (%)",
       subtitle = "(a) By establishment sector") +
  theme_paper() +
  theme(plot.subtitle = element_text(size = 10.5, face = "bold",
                                     margin = ggplot2::margin(b = 6)))

gp <- g[sector == "Private" & !(cesarean == 1 & !cesarea_antes_parto %in% c(1, 2))]
gp[, group := fcase(cesarean == 0, "Vaginal", cesarea_antes_parto == 1, "Prelabor cesarean",
                    cesarea_antes_parto == 2, "In-labor cesarean")]
gd2 <- gp[!is.na(group), .N, by = .(group, week = semana_gestacao)]
gd2[, share := N / sum(N), by = group]
qb <- ggplot(gd2, aes(week, 100 * share, colour = group, linetype = group)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.4) +
  scale_colour_manual(values = c("Prelabor cesarean" = unname(PAL["red"]),
                                 "In-labor cesarean" = unname(PAL["orange"]),
                                 "Vaginal" = unname(PAL["blue"]))) +
  scale_linetype_manual(values = lty_for(c("Prelabor cesarean", "In-labor cesarean",
                                           "Vaginal"))) +
  scale_x_continuous(breaks = seq(32, 43, 2)) +
  # three long labels in a 3.25in panel: one per row, otherwise the last is clipped
  guides(colour = guide_legend(ncol = 1), linetype = guide_legend(ncol = 1)) +
  labs(x = "Gestational age at birth (weeks)", y = "Share of births (%)",
       subtitle = "(b) For-profit, by delivery timing") +
  theme_paper() +
  theme(plot.subtitle = element_text(size = 10.5, face = "bold",
                                     margin = ggplot2::margin(b = 6)))

fig_gest <- qa | qb
ggsave(file.path(AOUT, "graphs", "fig_gestation_panels.pdf"), fig_gest, width = FIG_WIDTH, height = 4.0)
ggsave(file.path(AOUT, "graphs", "fig_gestation_panels.png"), fig_gest, width = FIG_WIDTH, height = 4.0, dpi = 300)

message("11_body_figures.R done")
