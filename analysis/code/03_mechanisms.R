# =============================================================================
# 03_mechanisms.R — scheduling, low-risk (Robson), prelabor split, decomposition
# Consolidated analysis script. Sections below are self-contained (each loads
# config + utils and its own data); they were merged from the former per-exhibit
# scripts as part of the thematic reorganization.
# =============================================================================

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
# holidays must span the FULL sample (2010-2024); using 2015-2024 left 2010-2014
# holidays flagged as ordinary days and diluted the holiday coefficient.
hol <- holiday_dates(2010:2024)
sd[, `:=`(
  weekend = as.integer(dow %in% c(1, 7)),
  holiday = as.integer(date %in% hol))]
sd[, eve := as.integer((date + 1L) %in% hol | (dow == 6L))]   # Fri or day-before-holiday
sd[, day_type := fifelse(holiday == 1, "Holiday",
                 fifelse(weekend == 1, "Weekend",
                 fifelse(eve == 1, "Eve of rest day", "Regular weekday")))]
# NB: the `sector` column keeps its raw SINASC levels (Private/Nonprofit/Public)
# because the regressions below subset on them; display labels are applied to the
# plotting and table objects only (see sector_display() in 00_utils.R).

# --- Figure 2: cesarean rate by day-of-week, by sector ------------------------
dow_tab <- sd[, .(rate = sum(cesarean) / sum(births)), by = .(sector, dow)]
dow_tab[, sector := sector_display(sector)]
dow_tab[, dow_lab := factor(dow, 1:7, c("Sun","Mon","Tue","Wed","Thu","Fri","Sat"))]
fig2 <- ggplot(dow_tab, aes(dow_lab, 100 * rate, colour = sector, group = sector)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]),
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

dict <- c(rate = "Cesarean rate", weekend = "Weekend", holiday = "National holiday",
          eve = "Eve of rest day", muni = "Municipality", year = "Year")
f <- file.path(TABLE, "tab03_scheduling.tex")
etable(r_pub, r_priv, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("Public", "For-profit"),
       title = "Weekend, holiday, and eve-of-rest-day effects on the cesarean rate",
       label = "tab:scheduling",
       notes = paste("\\footnotesize\\textit{Notes:} Municipality-date cells,",
         "weighted by births. The dependent variable is the cesarean share of births.",
         "\\emph{Eve of rest day} is a Friday or the day before a national holiday.",
         "Movable holidays (Good Friday, Carnival, Corpus Christi) are included.",
         "Standard errors, two-way clustered by municipality and date, are reported in parentheses.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)

# --- console summary ----------------------------------------------------------
cat("\nCesarean rate (%) by day type and sector:\n")
print(dcast(sd[, .(rate = round(100*sum(cesarean)/sum(births),1)), by = .(day_type, sector)],
            day_type ~ sector, value.var = "rate"))
etable(r_pub, r_priv, dict = dict, fitstat = ~ n + r2, digits = 4)

message("03_scheduling.R done")

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

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")
BIRTHS <- file.path(SIN, "sinasc_births.parquet")

if (!file.exists(BIRTHS)) {
  message("04_robson.R skipped — sinasc_births.parquet not built yet ",
          "(run the SINASC pull + ingest_sinasc() in build/01b_sinasc_cnes.R).")
} else {
  # column subset: the extended file has ~42M rows × 31 cols — read only what we use
  b <- as.data.table(read_parquet(BIRTHS,
         col_select = c("tipo_robson", "sector", "cesarean", "muni", "date", "dow", "year")))
  b <- b[year <= 2024]
  b[, `:=`(weekend = as.integer(dow %in% c(1, 7)),
           robson  = as.character(tipo_robson))]
  low <- b[robson %in% c("01", "02")]     # nulliparous, term, singleton, cephalic

  # --- Figure 3: cesarean rate by day-of-week, Robson 1-2, private vs public ---
  dow_tab <- low[sector %in% c("Private", "Public"),
                 .(rate = mean(cesarean, na.rm = TRUE)), by = .(sector, dow)]
  dow_tab[, sector := sector_display(sector, c("Private", "Public"))]
  dow_tab[, dow_lab := factor(dow, 1:7, c("Sun","Mon","Tue","Wed","Thu","Fri","Sat"))]
  fig3 <- ggplot(dow_tab, aes(dow_lab, 100 * rate, colour = sector, group = sector)) +
    geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
    scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]), Public = unname(PAL["blue"]))) +
    labs(x = NULL, y = "Cesarean rate (%), Robson groups 1-2") +
    theme_paper()
  save_fig(fig3, "fig03_robson_dow")

  # --- Table 4: weekend dip within Robson 1-2 (and Robson 1 alone) ------------
  cell <- function(dat) dat[, .(rate = mean(cesarean, na.rm = TRUE), n = .N),
                            by = .(muni, date, weekend, year)]
  r12_pub  <- feols(rate ~ weekend | muni + year, cell(low[sector == "Public"]),
                    weights = ~n, cluster = ~muni + date)
  r12_priv <- feols(rate ~ weekend | muni + year, cell(low[sector == "Private"]),
                    weights = ~n, cluster = ~muni + date)
  r1_priv  <- feols(rate ~ weekend | muni + year,
                    cell(b[robson == "01" & sector == "Private"]),
                    weights = ~n, cluster = ~muni + date)

  dict <- c(rate = "Cesarean rate", weekend = "Weekend",
            muni = "Municipality", year = "Year")
  f <- file.path(TABLE, "tab04_robson.tex")
  etable(r12_pub, r12_priv, r1_priv, tex = TRUE, file = f, replace = TRUE, dict = dict,
         signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
         fitstat = ~ n + r2, digits = 4, digits.stats = 3,
         headers = c("Robson groups 1--2, public", "Robson groups 1--2, for-profit",
                     "Robson group 1, for-profit"),
         title = "Weekend dip among low-risk (Robson 1-2) cesareans",
         label = "tab:robson",
         notes = paste("\\footnotesize\\textit{Notes:} Municipality-date cells,",
           "weighted by births, within Robson groups 1-2 (nulliparous, term,",
           "singleton, cephalic). The dependent variable is the cesarean share.",
           "Standard errors, two-way clustered by municipality and date, are reported in parentheses.", SIGNIF_NOTE))
  postprocess_tex(f, fontsize = "\\small", tabcolsep = 4)
  etable(r12_pub, r12_priv, r1_priv, dict = dict, fitstat = ~ n + r2, digits = 4)

  message("04_robson.R done")
}

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
         "Sector" = c("For-profit", "For-profit", "Public", "Public", "For-profit", "For-profit"),
         "Sample" = c("All births", "All births", "All births", "All births",
                      "Robson groups 1--2", "Robson group 10 (preterm)")),
       title = "The weekend dip by cesarean timing and Robson group",
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
cnt[, sector := sector_display(sector, c("Private", "Public"))]
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

# =============================================================================
# BODY TABLE — where the weekend dip lives: delivery timing and clinical risk.
# Merges the prelabor/in-labor split with the low-risk (Robson) restriction, the
# two pieces of evidence that locate the mechanism.
#   -> tab_prelabor_lowrisk.tex  (BODY, Table 5)
# =============================================================================
if (exists("r1_priv")) {
  MECH <- list(m_pre_priv, m_lab_priv, m_pre_pub, m_lab_pub, m_r12, r1_priv)
  tex <- c(
    "\\begin{table}[H]", "\\centering",
    "\\caption{\\textbf{The weekend dip by delivery timing and clinical risk}}",
    "\\label{tab:prelabor_lowrisk}",
    "\\small\\setlength{\\tabcolsep}{4pt}",
    "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
    "\\begin{tabular}{lcccccc}", "\\toprule",
    " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
    " & \\multicolumn{4}{c}{Components of the cesarean share} & \\multicolumn{2}{c}{Cesarean share, low risk} \\\\",
    "\\cmidrule(lr){2-5}\\cmidrule(lr){6-7}",
    " & Prelabor & In-labor & Prelabor & In-labor & Robson 1--2 & Robson 1 \\\\",
    "\\midrule",
    tex_row("Weekend", MECH, "weekend"),
    "\\midrule",
    "Sector & For-profit & For-profit & Public & Public & For-profit & For-profit \\\\",
    "Municipality fixed effects & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
    "Year fixed effects & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
    tex_nobs(MECH),
    "\\bottomrule", "\\end{tabular}}",
    "\\begin{minipage}{\\linewidth}\\footnotesize",
    "\\textit{Notes:} Estimates of Equation~\\eqref{eq:scheduling}, restricted to the",
    "weekend indicator. Municipality-date cells, SINASC 2010--2024, weighted by births;",
    "coefficients in percentage points. Columns 1--4 split the cesarean share of births",
    "into cesareans performed before labor began and cesareans performed during labor.",
    "Columns 5--6 restrict to Robson groups 1--2 (nulliparous, term, singleton,",
    "cephalic) and to Robson group 1 alone, which requires spontaneous labor, so that",
    "its cesareans are intrapartum by construction. Standard errors, two-way clustered",
    "by municipality and date, are reported in parentheses.",
    "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
  writeLines(tex, file.path(TABLE, "tab_prelabor_lowrisk.tex"))
  message("tab_prelabor_lowrisk.tex written")
}

message("08_mechanism_checks.R done")

# =============================================================================
# 11_decomposition.R — quantification.
#   (a) KITAGAWA/OAXACA: how much of the private-public cesarean gap is Robson
#       CASE-MIX (composition) vs WITHIN-GROUP practice style? If it is practice
#       style, the epidemic is about how medicine is practiced, not who gives
#       birth where.
#   (b) EXCESS WEEKDAY CESAREANS: a transparent scheduling counterfactual — hold
#       each municipality's weekend cesarean propensity as the "unscheduled"
#       benchmark and count weekday cesareans above it. A lower bound on
#       scheduling-driven cesareans per year.
#   Table 11 → tab11_decomposition (+ headline numbers printed for the text)
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "tipo_robson", "dow", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]

# --- (a) Kitagawa decomposition over Robson groups (2014+, when Robson exists) -
r <- b[year >= 2014 & tipo_robson %in% sprintf("%02d", 1:10)]
tab <- r[, .(n = .N, rate = mean(cesarean)), by = .(sector, g = tipo_robson)]
tab[, share := n / sum(n), by = sector]
wide <- dcast(tab, g ~ sector, value.var = c("share", "rate"))
wide[is.na(wide)] <- 0
gap  <- r[sector == "Private", mean(cesarean)] - r[sector == "Public", mean(cesarean)]
wide[, `:=`(share_bar = (share_Private + share_Public) / 2,
            rate_bar  = (rate_Private + rate_Public) / 2)]
composition <- wide[, sum((share_Private - share_Public) * rate_bar)]
practice    <- wide[, sum(share_bar * (rate_Private - rate_Public))]
cat(sprintf("\nKitagawa: gap %.1fpp = composition %.1fpp (%.0f%%) + practice %.1fpp (%.0f%%)\n",
            100*gap, 100*composition, 100*composition/gap, 100*practice, 100*practice/gap))

kt <- wide[order(g), .(
  `Robson group` = g,
  `Share private` = sprintf("%.1f", 100*share_Private),
  `Share public`  = sprintf("%.1f", 100*share_Public),
  `Rate private`  = sprintf("%.1f", 100*rate_Private),
  `Rate public`   = sprintf("%.1f", 100*rate_Public))]
tex <- c(
  "\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Decomposing the private--public cesarean gap (Kitagawa, Robson groups)}}",
  "\\label{tab:decomposition}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Robson group & Share private (\\%) & Share public (\\%) & Cesarean private (\\%) & Cesarean public (\\%) \\\\",
  "\\midrule",
  apply(kt, 1, function(x) paste(paste(x, collapse = " & "), "\\\\")),
  "\\midrule",
  sprintf("\\multicolumn{5}{l}{Gap %.1fpp $=$ case-mix %.1fpp (%.0f\\%%) $+$ practice style %.1fpp (%.0f\\%%)} \\\\",
          100*gap, 100*composition, 100*composition/gap, 100*practice, 100*practice/gap),
  "\\bottomrule",
  "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} SINASC 2014--2024 (Robson",
        "classification available from 2014). Kitagawa decomposition of the",
        "private--public cesarean gap into Robson-group composition and",
        "within-group rate differences."),
  "\\end{table}")
writeLines(resize_tabular(tex), file.path(TABLE, "tab11_decomposition.tex"))

# --- (b) excess weekday cesareans (scheduling counterfactual) ------------------
# benchmark: each sector-year's WEEKEND cesarean rate; excess = weekday births ×
# (weekday rate − weekend rate), summed. Reported per year, private and public.
b[, weekend := as.integer(dow %in% c(1, 7))]
ex <- b[, .(births = .N, ces = sum(cesarean)), by = .(sector, year, weekend)]
exw <- dcast(ex, sector + year ~ weekend, value.var = c("births", "ces"))
exw[, `:=`(rate_wd = ces_0 / births_0, rate_we = ces_1 / births_1)]
exw[, excess := births_0 * (rate_wd - rate_we)]
cat("\nExcess weekday cesareans per year (scheduling counterfactual):\n")
print(exw[, .(mean_per_year = format(round(mean(excess)), big.mark = ","),
              share_of_cesareans = sprintf("%.1f%%", 100 * sum(excess) / sum(ces_0 + ces_1))),
          by = sector])

message("11_decomposition.R done")
