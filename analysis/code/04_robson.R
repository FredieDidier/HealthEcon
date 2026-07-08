# =============================================================================
# 04_robson.R — the cleanest convenience signal: low-risk (Robson 1-2) cesareans.
# Robson groups 1-2 are nulliparous, single, cephalic, term pregnancies — the
# births where a cesarean is least likely to be medically necessary. If even
# these cluster on weekdays / dip on weekends, the driver is scheduling, not need.
#   Figure 3 → fig03_robson_dow ; Table 4 → tab04_robson
#
# REQUIRES build/covariates/input/sinasc_births.parquet (from the richer SINASC
# pull; see build/01d_sinasc_daily.R). Skips gracefully if not yet built.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

COV   <- file.path(DROPBOX_ROOT, "build", "covariates", "input")
TABLE <- here::here("analysis", "output", "tables")
BIRTHS <- file.path(COV, "sinasc_births.parquet")

if (!file.exists(BIRTHS)) {
  message("04_robson.R skipped — sinasc_births.parquet not built yet ",
          "(run the richer SINASC pull + ingest_sinasc() in build/01d).")
} else {
  b <- as.data.table(read_parquet(BIRTHS))
  b <- b[year <= 2024]
  b[, `:=`(weekend = as.integer(dow %in% c(1, 7)),
           robson  = as.character(tipo_robson))]
  low <- b[robson %in% c("01", "02")]     # nulliparous, term, singleton, cephalic

  # --- Figure 3: cesarean rate by day-of-week, Robson 1-2, private vs public ---
  dow_tab <- low[sector %in% c("Private", "Public"),
                 .(rate = mean(cesarean, na.rm = TRUE)), by = .(sector, dow)]
  dow_tab[, dow_lab := factor(dow, 1:7, c("Sun","Mon","Tue","Wed","Thu","Fri","Sat"))]
  fig3 <- ggplot(dow_tab, aes(dow_lab, 100 * rate, colour = sector, group = sector)) +
    geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
    scale_colour_manual(values = c(Private = unname(PAL["red"]), Public = unname(PAL["blue"]))) +
    labs(x = NULL, y = "Cesarean rate (%), Robson groups 1-2") +
    theme_paper()
  save_fig(fig3, "fig03_robson_dow")

  # --- Table 4: weekend dip within Robson 1-2 (and Robson 1 alone) ------------
  cell <- function(dat) dat[, .(rate = mean(cesarean, na.rm = TRUE), n = .N),
                            by = .(muni, date, weekend, year)]
  r12_pub  <- feols(rate ~ weekend | muni + year, cell(low[sector == "Public"]),  weights = ~n)
  r12_priv <- feols(rate ~ weekend | muni + year, cell(low[sector == "Private"]), weights = ~n)
  r1_priv  <- feols(rate ~ weekend | muni + year,
                    cell(b[robson == "01" & sector == "Private"]), weights = ~n)

  dict <- c(weekend = "Weekend", muni = "Municipality", year = "Year")
  f <- file.path(TABLE, "tab04_robson.tex")
  etable(r12_pub, r12_priv, r1_priv, tex = TRUE, file = f, replace = TRUE, dict = dict,
         signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
         fitstat = ~ n + r2, digits = 4, digits.stats = 3,
         headers = c("Robson 1-2, Public", "Robson 1-2, Private", "Robson 1, Private"),
         title = "Weekend dip among low-risk (Robson 1-2) cesareans",
         label = "tab:robson",
         notes = paste("\\footnotesize\\textit{Notes:} Municipality-date cells,",
           "weighted by births, within Robson groups 1-2 (nulliparous, term,",
           "singleton, cephalic). The dependent variable is the cesarean share.",
           "Standard errors clustered by municipality.", SIGNIF_NOTE))
  postprocess_tex(f, fontsize = "\\small", tabcolsep = 4)
  etable(r12_pub, r12_priv, r1_priv, dict = dict, fitstat = ~ n + r2, digits = 4)

  message("04_robson.R done")
}
