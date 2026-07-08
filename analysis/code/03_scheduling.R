# =============================================================================
# 03_scheduling.R — the mechanism: physician convenience revealed by scheduling.
# Using SINASC (all Brazilian births, exact date), cesarean rates cluster on
# weekdays and dip on weekends and holidays; the effect is larger in the private
# sector. Includes movable national holidays (Easter-based) and eve-of-rest-day
# "pull-forward" bunching.
#   Figure 2 → fig02_dow_cesarean ; Table 3 → tab03_scheduling
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

# --- Brazilian national holidays (fixed + Easter-based movable) ----------------
easter_sunday <- function(y) {            # Anonymous Gregorian algorithm
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
    e <- easter_sunday(y)
    out <- c(out, e - 2, e - 47, e - 48, e + 60)   # Good Friday, Carnival Tue+Mon, Corpus Christi
  }
  sort(unique(out))
}

# --- Load SINASC daily and classify each date ---------------------------------
sd <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sd[, `:=`(dow = wday(date), year = year(date))]
sd <- sd[year <= 2024]
hol <- holiday_dates(2015:2024)
sd[, `:=`(
  weekend = as.integer(dow %in% c(1, 7)),
  holiday = as.integer(date %in% hol))]
sd[, eve := as.integer((date + 1L) %in% hol | (dow == 6L))]   # Fri or day-before-holiday
sd[, day_type := fifelse(holiday == 1, "Holiday",
                 fifelse(weekend == 1, "Weekend",
                 fifelse(eve == 1, "Eve of rest day", "Regular weekday")))]
sd[, sector := factor(sector, levels = c("Private", "Nonprofit", "Public"))]

# --- Figure 2: cesarean rate by day-of-week, by sector ------------------------
dow_tab <- sd[, .(rate = sum(cesarean) / sum(births)), by = .(sector, dow)]
dow_tab[, dow_lab := factor(dow, 1:7, c("Sun","Mon","Tue","Wed","Thu","Fri","Sat"))]
fig2 <- ggplot(dow_tab, aes(dow_lab, 100 * rate, colour = sector, group = sector)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c(Private = unname(PAL["red"]),
                                 Nonprofit = unname(PAL["orange"]),
                                 Public = unname(PAL["blue"]))) +
  # no hard y-limits: scale_y_continuous(limits=) DROPS out-of-range points
  # (with the 2010-2024 sample private weekday rates exceed 75%, which erased
  # the private line); let the scale adapt instead.
  scale_y_continuous(breaks = seq(30, 90, 10)) +
  labs(x = NULL, y = "Cesarean rate (%)") +
  theme_paper()
save_fig(fig2, "fig02_dow_cesarean")

# --- Table 3: weekend + holiday dip, private vs public ------------------------
# Headline contrast: for-profit private (2xxx) vs public administration (1xxx);
# nonprofit (3xxx, SUS-heavy) is shown in the figure but excluded from the test.
cell <- sd[births > 0, .(rate = sum(cesarean) / sum(births), births = sum(births)),
           by = .(muni, date, sector, weekend, holiday, eve, year)]
# two-way clustering: weekend/holiday are DATE-level shocks common to all munis
r_pub  <- feols(rate ~ weekend + holiday + eve | muni + year, cell[sector == "Public"],
                weights = ~births, cluster = ~muni + date)
r_priv <- feols(rate ~ weekend + holiday + eve | muni + year, cell[sector == "Private"],
                weights = ~births, cluster = ~muni + date)

dict <- c(weekend = "Weekend", holiday = "National holiday",
          eve = "Eve of rest day", muni = "Municipality", year = "Year")
f <- file.path(TABLE, "tab03_scheduling.tex")
etable(r_pub, r_priv, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("Public", "Private"),
       title = "Cesareans dip on weekends and holidays, more so in the private sector",
       label = "tab:scheduling",
       notes = paste("\\footnotesize\\textit{Notes:} Municipality-date cells,",
         "weighted by births. The dependent variable is the cesarean share of births.",
         "\\emph{Eve of rest day} is a Friday or the day before a national holiday.",
         "Movable holidays (Good Friday, Carnival, Corpus Christi) are included.",
         "Standard errors two-way clustered by municipality and date.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)

# --- console summary ----------------------------------------------------------
cat("\nCesarean rate (%) by day type and sector:\n")
print(dcast(sd[, .(rate = round(100*sum(cesarean)/sum(births),1)), by = .(day_type, sector)],
            day_type ~ sector, value.var = "rate"))
etable(r_pub, r_priv, dict = dict, fitstat = ~ n + r2, digits = 4)

message("03_scheduling.R done")
