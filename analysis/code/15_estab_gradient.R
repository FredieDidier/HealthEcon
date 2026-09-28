# =============================================================================
# 15_estab_gradient.R — Equation (3) at the establishment, and the early-term
# share inside Equation (3).
#
# WHY. Equation (3) is estimated on municipality-date-sector cells, and a
# sector's cesarean share on a day is a birth-weighted mean of its
# establishments' shares. A weekend fall in the cell can therefore come from
# each establishment changing its practice, or from births moving on weekends
# towards establishments that operate at lower cesarean rates, with no
# establishment changing anything (a referee's composition objection). Panel A
# re-estimates the differential on establishment-date cells with
# establishment-by-year fixed effects, so it is identified only from each
# establishment's own weekday-weekend variation, still against the other sector
# in the same municipality-day:
#
#   CesareanShare_hd = g1 FP_h x Weekend_d + g2 FP_h x Holiday_d + g3 FP_h x Eve_d
#                    + lambda_{m(h)d} + alpha_{h,y(d)} + e_hd
#
# It stays a within-municipality-day DIFFERENTIAL, never a difference-in-
# differences: ownership is not assigned.
#
# Three choices, each reported rather than settled by assumption:
#   * weights: births in the cell reproduce the paper's weighting, but a
#     hospital's weight then falls on exactly the days being compared; column 3
#     holds each establishment's weight fixed at its mean daily births in the
#     year, so the estimand is the average change of practice per establishment;
#   * empty days: an establishment with no birth on a Sunday has no share and
#     leaves the share regressions, a selection the extensive-margin column
#     measures (an indicator for any birth, on the zero-filled panel);
#   * the endogenous denominator: counts of prelabor cesareans and of vaginal
#     births by Poisson, with the same fixed effects, on the zero-filled panel.
# The zero-filled panel keeps establishment-years with at least 50 births and
# the municipalities that have both a for-profit and a public such
# establishment in the year. Only those municipalities identify the
# differential (elsewhere the municipality x date effect absorbs every
# observation), so the restriction leaves the estimate unchanged and keeps the
# panel within the machine.
#
# Panel B puts the gestational-age margin inside the same design: the share of
# births at 37-38 weeks as the outcome of Equation (3), on all births with a
# recorded gestational age (2012-2024) and on Robson groups 1-2 (2014-2024).
# This remains calendar ordering, not the causal effect of scheduling on a
# pregnancy.
#
#   -> tab_estab_gradient.tex (Supplementary Appendix)
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")
MIN_BIRTHS <- 50L

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("muni", "date", "estab", "sector", "cesarean", "cesarea_antes_parto",
                      "semana_gestacao", "tipo_robson", "dow", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
b[, date := as.IDate(date)]
hol <- holiday_dates(2010:2024)
b[, `:=`(weekend = as.integer(dow %in% c(1, 7)), holiday = as.integer(date %in% hol))]
b[, eve := as.integer((date + 1L) %in% hol | dow == 6L)]
b[, private := as.integer(sector == "Private")]
b[, ces_pre := as.integer(cesarean %in% 1L & cesarea_antes_parto %in% 1L)]
b[, vag := as.integer(cesarean %in% 0L)]
b[, has_ga := !is.na(semana_gestacao) & semana_gestacao %between% c(20, 45)]
b[, early := as.integer(has_ga & semana_gestacao %between% c(37, 38))]
cat(sprintf("[15] births 2010-2024, for-profit or public: %s; with an establishment code: %.2f%%\n",
            format(nrow(b), big.mark = ","), 100 * b[, mean(!is.na(estab))]))

GRAD <- "i(private, weekend, ref = 0) + i(private, holiday, ref = 0) + i(private, eve, ref = 0)"
KG   <- c(wk = "private::1:weekend", hl = "private::1:holiday", ev = "private::1:eve")
f_h  <- function(y) as.formula(paste(y, "~", GRAD, "| muni^date + estab^year"))
f_m  <- function(y) as.formula(paste(y, "~", GRAD, "| muni^date + muni^sector"))

# ── Panel A: establishment-date cells ────────────────────────────────────────
bh <- b[!is.na(estab)]
# an establishment sits in one municipality; guard it rather than assume it
em <- bh[, .N, by = .(estab, muni)][order(-N)][, .SD[1], by = estab]
cat(sprintf("[15] establishments whose births carry more than one municipality code: %d of %d\n",
            bh[, uniqueN(muni), by = estab][V1 > 1, .N], uniqueN(bh$estab)))
bh[em, muni := i.muni, on = "estab"]
# sector is assigned by establishment and year; a within-year conflict would
# put one hospital on both sides of the comparison
stopifnot(bh[, uniqueN(sector), by = .(estab, year)][, max(V1)] == 1L)

ch <- bh[, .(births = .N, rate = mean(cesarean), n_ces = sum(cesarean),
             n_pre = sum(ces_pre), n_vag = sum(vag)),
         by = .(estab, muni, date, year, sector, private, weekend, holiday, eve)]
ch[, nbar := sum(births) / fifelse(year %% 4L == 0L, 366, 365), by = .(estab, year)]

# the same births aggregated to municipality-date-sector cells: the paper's
# specification on exactly this sample, for the composition comparison
cm <- bh[, .(births = .N, rate = mean(cesarean)),
         by = .(muni, date, year, sector, private, weekend, holiday, eve)]

a1 <- feols(f_m("rate"), cm, weights = ~births, cluster = ~muni + date)
a2 <- feols(f_h("rate"), ch, weights = ~births, cluster = ~estab + date)
a3 <- feols(f_h("rate"), ch, weights = ~nbar,   cluster = ~estab + date)

# zero-filled panel: establishment-years with >= MIN_BIRTHS births, every day of
# the year, in municipality-years that have both sectors
ey <- ch[, .(nb = sum(births)), by = .(estab, muni, year, sector, private)][nb >= MIN_BIRTHS]
mixed <- ey[, .(both = uniqueN(private) == 2L), by = .(muni, year)][both == TRUE, .(muni, year)]
ey <- ey[mixed, on = c("muni", "year"), nomatch = NULL]
days <- data.table(date = seq(as.IDate("2010-01-01"), as.IDate("2024-12-31"), by = 1L))
days[, year := year(date)]
z <- ey[days, on = "year", allow.cartesian = TRUE, nomatch = NULL]
z[, nbar := nb / fifelse(year %% 4L == 0L, 366, 365)]
z <- ch[, .(estab, date, births, n_pre, n_vag)][z, on = c("estab", "date")]
for (v in c("births", "n_pre", "n_vag")) set(z, which(is.na(z[[v]])), v, 0L)
z[, dw := wday(date)]
z[, `:=`(weekend = as.integer(dw %in% c(1, 7)), holiday = as.integer(date %in% hol))]
z[, eve := as.integer((date + 1L) %in% hol | dw == 6L)]
z[, any_birth := as.integer(births > 0L)]
cat(sprintf("[15] zero-filled panel: %s establishment-days, %s establishment-years, %d municipalities\n",
            format(nrow(z), big.mark = ","), format(nrow(ey), big.mark = ","), uniqueN(ey$muni)))
rm(bh); gc()

a4 <- feols(f_h("any_birth"), z, weights = ~nbar, cluster = ~estab + date)
a5 <- fepois(f_h("n_pre"), z[year >= 2012], cluster = ~estab + date)
a6 <- fepois(f_h("n_vag"), z, cluster = ~estab + date)

# share rows on the zero-filled sample as well, so the reader can see that the
# restriction to mixed municipalities does not move the share estimate
a2z <- feols(f_h("rate"), ch[ey[, .(estab, year)], on = c("estab", "year"), nomatch = NULL],
             weights = ~births, cluster = ~estab + date)

# ── Panel B: the early-term share inside Equation (3) ───────────────────────
cg <- b[has_ga == TRUE & year >= 2012,
        .(births = .N, early = mean(early)),
        by = .(muni, date, year, sector, private, weekend, holiday, eve)]
cr <- b[has_ga == TRUE & year >= 2014 & tipo_robson %in% c("01", "02"),
        .(births = .N, early = mean(early)),
        by = .(muni, date, year, sector, private, weekend, holiday, eve)]
g1 <- feols(f_m("early"), cg, weights = ~births, cluster = ~muni + date)
g2 <- feols(f_m("early"), cr, weights = ~births, cluster = ~muni + date)

# ── printout ─────────────────────────────────────────────────────────────────
pp <- function(m, k = KG[["wk"]]) { ct <- coeftable(m)[k, ]; sprintf("%+.3f (%.3f)", 100 * ct[[1]], 100 * ct[[2]]) }
cat("\n[15] For-profit x weekend, percentage points (s.e.):\n")
cat("  municipality-date-sector cells, same births :", pp(a1), "\n")
cat("  establishment-date cells, birth weights     :", pp(a2), "\n")
cat("  establishment-date cells, fixed weights     :", pp(a3), "\n")
cat("  establishment-date, zero-filled sample      :", pp(a2z), "\n")
cat("  any birth that day (extensive margin)       :", pp(a4), "\n")
cat("  prelabor cesareans, PPML (log points x 100) :", pp(a5), "\n")
cat("  vaginal births, PPML (log points x 100)     :", pp(a6), "\n")
cat("  early-term share, all births 2012+          :", pp(g1), "\n")
cat("  early-term share, Robson 1-2, 2014+         :", pp(g2), "\n")
comp <- 100 * (coef(a1)[[KG[["wk"]]]] - coef(a2)[[KG[["wk"]]]])
cat(sprintf("[15] composition across establishments (cell minus establishment estimate): %+.2f pp of %+.2f\n",
            comp, 100 * coef(a1)[[KG[["wk"]]]]))
cat(sprintf("[15] mean early-term share: all births 2012+ %.1f%%, Robson 1-2 2014+ %.1f%%\n",
            100 * cg[, weighted.mean(early, births)], 100 * cr[, weighted.mean(early, births)]))

# ── table ────────────────────────────────────────────────────────────────────
PA  <- list(a1, a2, a3, a4, a5, a6)
PB  <- list(g1, g2)
tex <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{The for-profit calendar gradient within the establishment, and the early-term share}}",
  "\\label{tab:estab_gradient}",
  "\\small\\setlength{\\tabcolsep}{3pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  "\\multicolumn{7}{l}{\\emph{Panel A. Cesarean delivery, municipality-day cells against establishment-day cells}} \\\\",
  "\\addlinespace[2pt]",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Cesarean & Cesarean & Cesarean & Any birth & Prelabor & Vaginal \\\\",
  " & share & share & share & that day & cesareans & births \\\\",
  "\\midrule",
  tex_row("For-profit $\\times$ Weekend", PA, KG[["wk"]]),
  tex_row("For-profit $\\times$ National holiday", PA, KG[["hl"]]),
  tex_row("For-profit $\\times$ Eve of rest day", PA, KG[["ev"]]),
  "\\midrule",
  "Unit & Municipality-sector & Establishment & Establishment & Establishment & Establishment & Establishment \\\\",
  "Estimator & OLS & OLS & OLS & OLS & Poisson & Poisson \\\\",
  "Weights & Births & Births & Fixed & Fixed & -- & -- \\\\",
  "Municipality $\\times$ date fixed effects & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Municipality $\\times$ sector fixed effects & Yes & No & No & No & No & No \\\\",
  "Establishment $\\times$ year fixed effects & No & Yes & Yes & Yes & Yes & Yes \\\\",
  "Sample & 2010--2024 & 2010--2024 & 2010--2024 & 2010--2024 & 2012--2024 & 2010--2024 \\\\",
  tex_nobs(PA),
  "\\midrule",
  "\\multicolumn{7}{l}{\\emph{Panel B. Share of births at 37--38 weeks, municipality-day cells}} \\\\",
  "\\addlinespace[2pt]",
  " & (7) & (8) & & & & \\\\",
  " & All births & Robson 1--2 & & & & \\\\",
  "\\midrule",
  sub("\\\\\\\\$", "& & & & \\\\\\\\", tex_row("For-profit $\\times$ Weekend", PB, KG[["wk"]])[1:2]), "\\addlinespace[2pt]",
  sub("\\\\\\\\$", "& & & & \\\\\\\\", tex_row("For-profit $\\times$ National holiday", PB, KG[["hl"]])[1:2]), "\\addlinespace[2pt]",
  sub("\\\\\\\\$", "& & & & \\\\\\\\", tex_row("For-profit $\\times$ Eve of rest day", PB, KG[["ev"]])[1:2]), "\\addlinespace[2pt]",
  "\\midrule",
  "Sample & 2012--2024 & 2014--2024 & & & & \\\\",
  sub("\\\\\\\\$", "& & & & \\\\\\\\", tex_nobs(PB)),
  "\\bottomrule", "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} SINASC, for-profit and public establishments; coefficients in",
  "percentage points, and in log points $\\times$ 100 in the Poisson columns. Column 1",
  "estimates Equation~\\eqref{eq:gradient} on municipality-date-sector cells built from",
  "the births that carry an establishment code. Columns 2--6 use establishment-date",
  "cells with establishment$\\times$year fixed effects, so the differential is",
  "identified from each establishment's own weekday-weekend variation against the",
  "other sector in the same municipality-day. Column 2 weights by the cell's births,",
  "as the paper does; columns 3--4 hold each establishment's weight fixed at its mean",
  "daily births in the year. Columns 4--6 use a panel with every day of each",
  sprintf("establishment-year with at least %d births, in the municipality-years with", MIN_BIRTHS),
  "both sectors, the only ones that identify the differential; days with no birth",
  "enter as zeros. Column 4 is the probability that the establishment records any",
  "birth that day; columns 5--6 are counts. Panel B uses births with a recorded",
  "gestational age, and column 8 Robson groups 1--2 (nulliparous, term, singleton,",
  "cephalic). Standard errors are two-way clustered by municipality and date in",
  "columns 1, 7 and 8 and by establishment and date in columns 2--6.",
  "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
write_table_tex(tex, file.path(TABLE, "tab_estab_gradient.tex"))
message("15_estab_gradient.R done")
