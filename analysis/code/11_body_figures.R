# =============================================================================
# 11_body_figures.R — the merged multi-panel figures of the main text.
#
# The body carries three figures. Figure 1 (sector trends) is built in
# 01_descriptives.R. This script builds the other two by combining panels that
# used to be separate exhibits:
#
#   fig_calendar_fingerprints.pdf  (Figure 2)
#     (a) cesarean rate by day of week and sector          [was fig02]
#     (b) hour-of-birth distribution by delivery mode      [was fig07]
#     (c) event study around bridge holidays               [new, from 08]
#
#   fig_gestation_panels.pdf       (Figure 3)
#     (a) gestational age by sector                        [was fig09]
#     (b) gestational age by delivery timing, for-profit   [was fig09b]
#
# REQUIRES 08_long_weekends.R to have saved analysis/output/evt_coefs.rds.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, ggplot2, patchwork, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN  <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
AOUT <- here::here("analysis", "output")

# --- panel (a): cesarean rate by day of week and sector ----------------------
sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, `:=`(dow = wday(as.IDate(date)), year = year(as.IDate(date)))]
sd <- sd[year <= 2024]
dow_tab <- sd[, .(rate = sum(cesarean) / sum(births)), by = .(sector, dow)]
dow_tab[, `:=`(dow_lab = factor(dow, 1:7, c("Sun","Mon","Tue","Wed","Thu","Fri","Sat")),
               sector = sector_display(sector))]
pa <- ggplot(dow_tab, aes(dow_lab, 100 * rate, colour = sector, group = sector)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]),
                                 Nonprofit = unname(PAL["orange"]),
                                 Public = unname(PAL["blue"]))) +
  scale_y_continuous(breaks = seq(30, 90, 10)) +
  labs(x = NULL, y = "Cesarean rate (%)", subtitle = "(a) Cesarean rate by day of week") +
  theme_paper(base = 12) + theme(plot.subtitle = element_text(size = 11, face = "bold"))
rm(sd); gc()

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
pb <- ggplot(hd, aes(hour, 100 * share, colour = type)) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~sector) +
  scale_colour_manual(values = c(Cesarean = unname(PAL["red"]), Vaginal = unname(PAL["blue"]))) +
  scale_x_continuous(breaks = seq(0, 24, 6)) +
  labs(x = "Hour of birth", y = "Share of births (%)", subtitle = "(b) Hour of birth") +
  theme_paper(base = 12) + theme(plot.subtitle = element_text(size = 11, face = "bold"))
rm(b, hd); gc()

# --- panel (c): event study around bridge holidays ---------------------------
evt <- readRDS(file.path(AOUT, "evt_coefs.rds"))
pc <- ggplot(evt[block == "Bridge"], aes(ell, b)) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.3) +
  geom_errorbar(aes(ymin = b - 1.96 * se, ymax = b + 1.96 * se), width = 0.12,
                colour = unname(PAL["red"]), linewidth = 0.35) +
  geom_point(colour = unname(PAL["red"]), size = 1.3) +
  facet_wrap(~ outcome, scales = "free_y", nrow = 1) +
  scale_x_continuous(breaks = seq(-4, 4, 2)) +
  labs(x = "Days relative to a bridge holiday",
       y = "For-profit minus public\n(births per municipality-day)",
       subtitle = "(c) Displacement of deliveries around a bridge holiday") +
  theme_paper(base = 12) +
  theme(plot.subtitle = element_text(size = 11, face = "bold",
                                     margin = ggplot2::margin(t = 10, b = 6)),
        plot.margin = ggplot2::margin(t = 20, r = 6, b = 4, l = 6))

# a thin spacer row keeps panel (c)'s title clear of the (a)/(b) legends above
spacer <- patchwork::plot_spacer()
fig2 <- (pa | pb) / spacer / pc +
  patchwork::plot_layout(heights = c(1, 0.06, 1))
ggsave(file.path(AOUT, "graphs", "fig_calendar_fingerprints.pdf"), fig2, width = 11, height = 8.4)
ggsave(file.path(AOUT, "graphs", "fig_calendar_fingerprints.png"), fig2, width = 11, height = 8.4, dpi = 300)

# --- Figure 3: gestational age -----------------------------------------------
g <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "cesarea_antes_parto", "semana_gestacao", "year")))
g <- g[year <= 2024 & sector %in% c("Private", "Public") & semana_gestacao %between% c(32, 43)]
ga <- g[, .N, by = .(sector, week = semana_gestacao)]
ga[, share := N / sum(N), by = sector]
ga[, sector := sector_display(sector, c("Private", "Public"))]
qa <- ggplot(ga, aes(week, 100 * share, colour = sector)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.4) +
  scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]), Public = unname(PAL["blue"]))) +
  scale_x_continuous(breaks = seq(32, 43, 2)) +
  labs(x = "Gestational age at birth (weeks)", y = "Share of births (%)",
       subtitle = "(a) By establishment sector") +
  theme_paper(base = 12) + theme(plot.subtitle = element_text(size = 11, face = "bold"))

gp <- g[sector == "Private" & !(cesarean == 1 & !cesarea_antes_parto %in% c(1, 2))]
gp[, group := fcase(cesarean == 0, "Vaginal", cesarea_antes_parto == 1, "Prelabor cesarean",
                    cesarea_antes_parto == 2, "In-labor cesarean")]
gd <- gp[!is.na(group), .N, by = .(group, week = semana_gestacao)]
gd[, share := N / sum(N), by = group]
qb <- ggplot(gd, aes(week, 100 * share, colour = group)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.4) +
  scale_colour_manual(values = c("Prelabor cesarean" = unname(PAL["red"]),
                                 "In-labor cesarean" = unname(PAL["orange"]),
                                 "Vaginal" = unname(PAL["blue"]))) +
  scale_x_continuous(breaks = seq(32, 43, 2)) +
  labs(x = "Gestational age at birth (weeks)", y = "Share of births (%)",
       subtitle = "(b) For-profit births, by delivery timing") +
  theme_paper(base = 12) + theme(plot.subtitle = element_text(size = 11, face = "bold"))

fig3 <- qa | qb
ggsave(file.path(AOUT, "graphs", "fig_gestation_panels.pdf"), fig3, width = 11, height = 4.4)
ggsave(file.path(AOUT, "graphs", "fig_gestation_panels.png"), fig3, width = 11, height = 4.4, dpi = 300)

message("11_body_figures.R done")
