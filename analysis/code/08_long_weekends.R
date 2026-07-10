# =============================================================================
# 08_long_weekends.R — Long weekends and the displacement of scheduled cesareans
#
# A single exercise, pre-specified before looking at the results, that asks one
# economic question: are scheduled procedures moved across dates so as to build
# longer blocks of leisure?
#
# PRE-SPECIFICATION (fixed before estimation; see paper Section "Long weekends
# and the displacement of scheduled cesareans"):
#   * primary outcome  : share of births delivered by PRELABOR cesarean
#   * primary window   : [-3, +3] days around the holiday
#   * primary sample   : FIXED-DATE national holidays, 2012-2024
#                        (the prelabor indicator is < 15% missing only from 2012)
#   * primary parameters: the long-block effect and the sum of the pre-holiday
#                        event-time coefficients
#   * secondary outcomes: counts of prelabor cesareans, in-labor cesareans,
#                        vaginal births, and total births
#   Null or wrong-signed results are reported.
#
# HOLIDAY TAXONOMY (by the day of week on which the fixed-date holiday falls):
#   Isolated_h    = 1{Wednesday}            -> one day off, no attached weekend
#   ThreeDay_h    = 1{Monday, Friday}       -> automatic three-day weekend
#   Bridge_h      = 1{Tuesday, Thursday}    -> one bridging workday buys four days
#   WeekendHol_h  = 1{Saturday, Sunday}     -> placebo: adds no workday of rest
# A Wednesday holiday, not a Monday or Friday one, is the isolated case.
#
# Movable holidays (Carnival, Good Friday, Corpus Christi) fall on structurally
# fixed weekdays, so comparing them across the taxonomy would confound "bridge"
# with holiday identity. They are excluded from the main sample and enter only as
# a robustness check. Consciencia Negra (20 November) became a national holiday
# only in 2024 and is excluded throughout. We have no state-holiday calendar.
#
# Exhibits:
#   tab_long_weekends.tex        (BODY)       taxonomy + displacement sums
#   fig_long_weekend_event.pdf   (BODY)       event study around bridge holidays
#   tab_displacement_robust.tex  (SUPPLEMENT) shares, isolated blocks, movable
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, dplyr, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

YEARS      <- 2012:2024        # prelabor indicator usable from 2012
EVENT_HALF <- 4L               # event window half-width in days

# =============================================================================
# 1. Holiday calendar with names
# =============================================================================
easter_sunday <- function(y) {
  a <- y %% 19; b <- y %/% 100; c <- y %% 100
  d <- b %/% 4; e <- b %% 4; f <- (b + 8) %/% 25; g <- (b - f + 1) %/% 3
  h <- (19*a + b - d - g + 15) %% 30; i <- c %/% 4; k <- c %% 4
  l <- (32 + 2*e + 2*i - h - k) %% 7; m <- (a + 11*h + 22*l) %/% 451
  mo <- (h + l - 7*m + 114) %/% 31; da <- ((h + l - 7*m + 114) %% 31) + 1
  as.IDate(sprintf("%d-%02d-%02d", y, mo, da))
}

FIXED_HOLIDAYS <- c("01-01" = "New Year", "04-21" = "Tiradentes",
                    "05-01" = "Labour Day", "09-07" = "Independence",
                    "10-12" = "Our Lady Aparecida", "11-02" = "All Souls",
                    "11-15" = "Republic", "12-25" = "Christmas")

fixed_holiday_table <- function(years) {
  rbindlist(lapply(years, function(y)
    data.table(date = as.IDate(paste0(y, "-", names(FIXED_HOLIDAYS))),
               holname = unname(FIXED_HOLIDAYS))))
}
movable_holiday_dates <- function(years) {
  out <- as.IDate(character(0))
  for (y in years) { e <- easter_sunday(y); out <- c(out, e - 2, e - 47, e - 48, e + 60) }
  sort(unique(out))
}
# 20 November (Consciencia Negra): national only from 2024; excluded throughout.
excluded_dates <- function(years) as.IDate(paste0(years[years >= 2024], "-11-20"))

hol_fixed <- fixed_holiday_table(YEARS)
hol_fixed[, dow := wday(date)]
hol_fixed[, block := fcase(dow == 4L,          "Isolated",
                           dow %in% c(2L, 6L), "ThreeDay",
                           dow %in% c(3L, 5L), "Bridge",
                           default             = "WeekendHol")]
hol_move <- movable_holiday_dates(YEARS)
hol_excl <- excluded_dates(YEARS)
all_holidays <- sort(unique(c(hol_fixed$date, hol_move, hol_excl)))

cat("\n[1] Fixed-date national holidays ", min(YEARS), "-", max(YEARS), ":\n", sep = "")
print(hol_fixed[, .N, by = block][order(-N)])

# =============================================================================
# 2. Municipality x date x sector cells with delivery-timing counts
#    (cached: the birth-level file is 42M rows)
# =============================================================================
CELL_CACHE <- file.path(SIN, "sinasc_daily_timing_muni.parquet")
if (!file.exists(CELL_CACHE)) {
  message("building ", basename(CELL_CACHE), " from sinasc_births.parquet ...")
  cells <- open_dataset(file.path(SIN, "sinasc_births.parquet")) %>%
    filter(year >= 2012, year <= 2024, sector %in% c("Private", "Public")) %>%
    mutate(is_ces = if_else(cesarean == 1L, 1L, 0L),
           is_pre = if_else(cesarean == 1L & !is.na(cesarea_antes_parto) &
                              cesarea_antes_parto == 1L, 1L, 0L),
           is_lab = if_else(cesarean == 1L & !is.na(cesarea_antes_parto) &
                              cesarea_antes_parto == 2L, 1L, 0L)) %>%
    group_by(muni, date, sector) %>%
    summarise(births  = n(),
              n_ces   = sum(is_ces),
              n_pre   = sum(is_pre),
              n_lab   = sum(is_lab),
              .groups = "drop") %>%
    collect() %>% as.data.table()
  cells[, n_vag := births - n_ces]
  write_parquet(cells, CELL_CACHE)
  message("saved ", nrow(cells), " cells")
}
cells <- as.data.table(read_parquet(CELL_CACHE))
cells[, `:=`(date = as.IDate(date), dow = wday(as.IDate(date)),
             year = year(as.IDate(date)), private = as.integer(sector == "Private"))]

# =============================================================================
# 3. PANEL A — the holiday taxonomy as an extension of Equation (3)
#    Y_mds = lambda_md + phi_ms
#            + gamma_I ForProfit x Isolated + gamma_3 ForProfit x ThreeDay
#            + gamma_B ForProfit x Bridge   + gamma_W ForProfit x WeekendHol
#            + sum_w eta_w ForProfit x DOW_w  [+ sum_h kappa_h ForProfit x Name_h]
# =============================================================================
tax <- copy(cells)
tax <- tax[!(date %in% c(hol_move, hol_excl))]        # movable holidays: robustness only
tax <- merge(tax, hol_fixed[, .(date, holname, block)], by = "date", all.x = TRUE)
tax[is.na(block), `:=`(block = "None", holname = "None")]
tax[, `:=`(iso  = as.integer(block == "Isolated"),
           d3   = as.integer(block == "ThreeDay"),
           brg  = as.integer(block == "Bridge"),
           wknd = as.integer(block == "WeekendHol"))]
tax <- tax[births > 0]
tax[, `:=`(rate     = n_ces / births,
           rate_pre = n_pre / births,
           rate_lab = n_lab / births)]
tax[, `:=`(dowf = factor(dow), holf = factor(holname, levels = c("None", unname(FIXED_HOLIDAYS))))]

# Note on collinearity. Each taxonomy dummy enters interacted with ForProfit only
# (ref = 0), because the day-level main effect is absorbed by the
# municipality x date fixed effects. The four taxonomy dummies sum to the holiday
# indicator, which is also the sum of the eight holiday-name dummies, so
# specifications that include ForProfit x HolidayName omit WeekendHol, which
# becomes the reference category: a holiday that adds no workday of rest.
tax_terms  <- paste("i(private, iso, ref = 0) + i(private, d3, ref = 0) +",
                    "i(private, brg, ref = 0)")
fml_base   <- function(y) as.formula(paste0(
  y, " ~ ", tax_terms, " + i(private, wknd, ref = 0) + i(dowf, private, ref = 1)",
  " | muni^date + muni^sector"))
fml_holfe  <- function(y) as.formula(paste0(
  y, " ~ ", tax_terms, " + i(dowf, private, ref = 1) + i(holf, private, ref = 'None')",
  " | muni^date + muni^sector"))

# Cache only what the exhibits need: the fitted fixest objects carry the full
# 4.5m-row design and run to gigabytes on disk.
slim <- function(m) list(ct = fixest::coeftable(m), V = stats::vcov(m), n = stats::nobs(m))
TAX_CACHE <- here::here("analysis", "output", "m_tax_slim.rds")
if (file.exists(TAX_CACHE)) {
  m_tax <- readRDS(TAX_CACHE)
} else {
  m_tax <- list(
    ces_base = slim(feols(fml_base("rate"),      tax, weights = ~births, cluster = ~muni + date)),
    ces_hol  = slim(feols(fml_holfe("rate"),     tax, weights = ~births, cluster = ~muni + date)),
    pre_hol  = slim(feols(fml_holfe("rate_pre"), tax, weights = ~births, cluster = ~muni + date)),
    lab_hol  = slim(feols(fml_holfe("rate_lab"), tax, weights = ~births, cluster = ~muni + date)))
  saveRDS(m_tax, TAX_CACHE)
}
has_key <- function(s, k) k %in% rownames(s$ct)

# equality tests gamma_B = gamma_I and gamma_B = gamma_3
lincom <- function(s, a, b) {
  if (!has_key(s, a) || !has_key(s, b)) return(c(estimate = NA, se = NA, p = NA))
  est <- s$ct[a, 1] - s$ct[b, 1]
  se  <- sqrt(s$V[a, a] + s$V[b, b] - 2 * s$V[a, b])
  c(estimate = est, se = se, p = 2 * pnorm(-abs(est / se)))
}
K <- c(iso = "private::1:iso", d3 = "private::1:d3", brg = "private::1:brg",
       wknd = "private::1:wknd")
tests <- lapply(m_tax, function(s)
  list(B_vs_I = lincom(s, K[["brg"]], K[["iso"]]),
       B_vs_3 = lincom(s, K[["brg"]], K[["d3"]])))
cat("\n[3] Holiday taxonomy, for-profit differential (percentage points):\n")
for (nm in names(m_tax)) {
  ks <- intersect(unname(K), rownames(m_tax[[nm]]$ct))
  cat("  ", formatC(nm, width = 9), ": ",
      paste(sprintf("%s=%+.3f", sub("private::1:", "", ks),
                    100 * m_tax[[nm]]$ct[ks, 1]), collapse = "  "), "\n", sep = "")
}
cat("\n    Equality tests (p-values):\n")
for (nm in names(tests))
  cat("  ", formatC(nm, width = 9), ": B=I p=", sprintf("%.4f", tests[[nm]]$B_vs_I[["p"]]),
      "   B=3day p=", sprintf("%.4f", tests[[nm]]$B_vs_3[["p"]]), "\n", sep = "")

# =============================================================================
# 4. EVENT STUDY — displacement of procedures around a rest block
#
# Every municipality-day carries exactly one for-profit and one public cell once
# zeros are filled in, so the municipality x date fixed effects of Equation (3)
# are algebraically equivalent to differencing the two sectors within the day.
# We therefore estimate the differenced form, which makes the count outcomes
# tractable on the full 2012-2024 panel:
#
#   (Y^k_mdPriv - Y^k_mdPub) = alpha_m + sum_w eta_w DOW_w + tau_{ym}
#                              + sum_{type, l} theta^k_{type,l} 1{d in window(type), l}
#                              + e_md,
#
# with l = d - H in [-4, +4] and NON-WINDOW days as the omitted category, so
# theta^k_l is the excess of for-profit over public activity on event day l
# relative to an ordinary day of the same week day. Two-way clustered by
# municipality and date, because the identifying variation is the holiday date.
# =============================================================================

# --- 4a. event windows: one holiday per window, no contamination -------------
win <- rbindlist(lapply(seq_len(nrow(hol_fixed)), function(i) {
  H <- hol_fixed$date[i]
  data.table(date = H + (-EVENT_HALF:EVENT_HALF), ell = -EVENT_HALF:EVENT_HALF,
             H = H, block = hol_fixed$block[i])
}))
win <- win[block != "WeekendHol"]                    # blocks that add no rest day
# drop a window if any OTHER holiday falls inside it
bad <- win[ell != 0 & date %in% all_holidays, unique(H)]
win <- win[!H %in% bad]
# a date can still sit in two windows: keep the nearest holiday, drop exact ties
win[, adist := abs(ell)]
win[, `:=`(mind = min(adist), ntie = sum(adist == min(adist))), by = date]
win <- win[adist == mind & ntie == 1L]
win[, c("adist", "mind", "ntie") := NULL]
win[, evt := paste0(block, "_", sprintf("%+d", ell))]
cat("\n[4a] Event windows: ", uniqueN(win$H), " holidays, ", nrow(win), " holiday-days\n", sep = "")
print(win[, .(holidays = uniqueN(H)), by = block])

# --- 4b. balanced two-sector municipality-date panel, zeros filled -----------
vol <- cells[, .(b = sum(births)), by = .(muni, sector)]
vol <- dcast(vol, muni ~ sector, value.var = "b", fill = 0)
both <- vol[Private >= 1000 & Public >= 1000, muni]
cat("[4b] municipalities with both sectors and >= 1000 births each: ", length(both), "\n", sep = "")

dates <- seq(as.IDate(sprintf("%d-01-01", min(YEARS))),
             as.IDate(sprintf("%d-12-31", max(YEARS))), by = "day")
grid <- CJ(muni = both, date = dates, sector = c("Private", "Public"))
p <- merge(grid, cells[muni %in% both,
             .(muni, date, sector, births, n_pre, n_lab, n_vag, n_ces)],
           by = c("muni", "date", "sector"), all.x = TRUE)
for (cc in c("births", "n_pre", "n_lab", "n_vag", "n_ces"))
  set(p, i = which(is.na(p[[cc]])), j = cc, value = 0L)
rm(grid); gc()

# difference the two sectors within municipality-day (equivalent to muni x date FE)
d <- dcast(p, muni + date ~ sector,
           value.var = c("births", "n_pre", "n_lab", "n_vag", "n_ces"))
for (v in c("births", "n_pre", "n_lab", "n_vag", "n_ces"))
  d[, (paste0("dif_", v)) := get(paste0(v, "_Private")) - get(paste0(v, "_Public"))]
d[, `:=`(dow = factor(wday(date)), ym = paste0(year(date), "-", month(date)))]
d <- merge(d, win[, .(date, evt, ell, block)], by = "date", all.x = TRUE)
d[is.na(evt), evt := "none"]
d[, evt := relevel(factor(evt), ref = "none")]
rm(p); gc()

evt_fml <- function(y) as.formula(paste0("dif_", y, " ~ evt + dow | muni + ym"))
OUTC <- c(n_pre = "Prelabor cesareans", n_lab = "In-labor cesareans",
          n_vag = "Vaginal births", births = "Total births")
m_evt <- lapply(names(OUTC), function(y)
  feols(evt_fml(y), d, cluster = ~muni + date))
names(m_evt) <- names(OUTC)

# --- 4c. displacement sums: pre-holiday excess and window conservation -------
sum_test <- function(m, block, lo, hi) {
  nm <- paste0("evt", block, "_", sprintf("%+d", lo:hi))
  nm <- intersect(nm, names(coef(m)))
  if (!length(nm)) return(c(estimate = NA, se = NA, p = NA))
  cf <- coef(m)[nm]; V <- vcov(m)[nm, nm, drop = FALSE]
  est <- sum(cf); se <- sqrt(sum(V))
  c(estimate = est, se = se, p = 2 * pnorm(-abs(est / se)))
}
mk_disp <- function(models, y, label, bk) {
  a <- sum_test(models[[y]], bk, -3, -1); b <- sum_test(models[[y]], bk, -3, 3)
  data.table(outcome = label, block = bk,
             pre.estimate = a[["estimate"]], pre.se = a[["se"]], pre.p = a[["p"]],
             full.estimate = b[["estimate"]], full.se = b[["se"]], full.p = b[["p"]])
}
disp <- rbindlist(lapply(names(OUTC), function(y)
  rbindlist(lapply(c("Bridge", "ThreeDay", "Isolated"),
                   function(bk) mk_disp(m_evt, y, OUTC[[y]], bk)))))
cat("\n[4c] Displacement sums (for-profit minus public, births per municipality-day):\n")
print(disp[, .(outcome, block,
               pre_sum = round(pre.estimate, 4), pre_p = round(pre.p, 4),
               win_sum = round(full.estimate, 4), win_p = round(full.p, 4))])

# =============================================================================
# 5. FIGURE — event study around bridge holidays
# =============================================================================
evt_coefs <- rbindlist(lapply(names(OUTC), function(y) {
  ct <- as.data.table(coeftable(m_evt[[y]]), keep.rownames = "term")
  ct <- ct[grepl("^evt(Bridge|Isolated)_", term)]
  ct[, `:=`(block = sub("^evt([A-Za-z]+)_.*$", "\\1", term),
            ell   = as.integer(sub("^evt[A-Za-z]+_", "", term)),
            outcome = OUTC[[y]])]
  ct
}))
setnames(evt_coefs, c("Estimate", "Std. Error"), c("b", "se"))
evt_coefs[, outcome := factor(outcome, levels = unname(OUTC))]
# 11_body_figures.R assembles these into the merged calendar-fingerprints figure
saveRDS(evt_coefs, file.path(here::here("analysis", "output"), "evt_coefs.rds"))

fig_evt <- ggplot(evt_coefs[block == "Bridge"], aes(ell, b)) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.3) +
  geom_errorbar(aes(ymin = b - 1.96 * se, ymax = b + 1.96 * se), width = 0.12,
                colour = unname(PAL["red"]), linewidth = 0.4) +
  geom_point(colour = unname(PAL["red"]), size = 1.6) +
  facet_wrap(~ outcome, scales = "free_y", nrow = 1) +
  scale_x_continuous(breaks = -4:4) +
  labs(x = "Days relative to the holiday", y = "For-profit minus public (births per municipality-day)") +
  theme_paper()
save_fig(fig_evt, "fig_long_weekend_event", width = 11, height = 3.6)

fig_evt_iso <- ggplot(evt_coefs, aes(ell, b, colour = block, group = block)) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.3) +
  geom_errorbar(aes(ymin = b - 1.96 * se, ymax = b + 1.96 * se), width = 0.12,
                position = position_dodge(width = 0.35), linewidth = 0.35) +
  geom_point(position = position_dodge(width = 0.35), size = 1.5) +
  scale_colour_manual(values = c(Bridge = unname(PAL["red"]), Isolated = unname(PAL["navy"]))) +
  facet_wrap(~ outcome, scales = "free_y", nrow = 2) +
  scale_x_continuous(breaks = -4:4) +
  labs(x = "Days relative to the holiday", y = "For-profit minus public (births per municipality-day)") +
  theme_paper()
save_fig(fig_evt_iso, "fig_long_weekend_event_blocks", width = 9, height = 6)

# =============================================================================
# 6. BODY TABLE — taxonomy (Panel A) + displacement sums (Panel B)
# =============================================================================
fmt <- tex_coef                                     # shared helper (00_utils.R)
row_from_model <- function(models, key, mult = 100) {
  cells <- lapply(models, function(s) {
    if (!has_key(s, key)) return(c("", ""))
    ct <- s$ct[key, ]
    fmt(ct[[1]], ct[[2]], ct[[4]], mult)
  })
  list(est = sapply(cells, `[`, 1), se = sapply(cells, `[`, 2))
}

lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{\\textbf{Long weekends and the displacement of scheduled cesareans}}",
  "\\label{tab:long_weekends}",
  "\\small\\setlength{\\tabcolsep}{5pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Cesarean & Cesarean & Prelabor cesarean & In-labor cesarean \\\\",
  " & share & share & share & share \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel A. Holiday taxonomy, for-profit differential}} \\\\",
  "\\addlinespace[2pt]")

add_row <- function(label, key) {
  r <- row_from_model(m_tax, key)
  c(paste0(label, " & ", paste(r$est, collapse = " & "), " \\\\"),
    paste0(" & ", paste(r$se, collapse = " & "), " \\\\"),
    "\\addlinespace[2pt]")
}
lines <- c(lines,
  add_row("For-profit $\\times$ Bridge holiday (Tue/Thu)", K[["brg"]]),
  add_row("For-profit $\\times$ Three-day holiday (Mon/Fri)", K[["d3"]]),
  add_row("For-profit $\\times$ Isolated holiday (Wed)", K[["iso"]]),
  add_row("For-profit $\\times$ Weekend holiday (placebo)", K[["wknd"]]))

pvals <- function(which) sapply(tests, function(t) {
  p <- t[[which]]["p"]
  if (is.na(p)) "" else formatC(p, format = "f", digits = 3) })
lines <- c(lines,
  "\\midrule",
  paste0("$p$-value: Bridge $=$ Isolated & ", paste(pvals("B_vs_I"), collapse = " & "), " \\\\"),
  paste0("$p$-value: Bridge $=$ Three-day & ", paste(pvals("B_vs_3"), collapse = " & "), " \\\\"),
  "\\addlinespace[2pt]",
  paste0("For-profit $\\times$ day-of-week & Yes & Yes & Yes & Yes \\\\"),
  paste0("For-profit $\\times$ holiday identity & No & Yes & Yes & Yes \\\\"),
  paste0("Municipality $\\times$ date fixed effects & Yes & Yes & Yes & Yes \\\\"),
  paste0("Observations & ", paste(sapply(m_tax, function(s)
    formatC(s$n, big.mark = ",", format = "d")), collapse = " & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel B. Displacement around bridge holidays (counts, for-profit minus public)}} \\\\",
  "\\addlinespace[2pt]",
  " & Prelabor & In-labor & Vaginal & Total \\\\",
  " & cesareans & cesareans & births & births \\\\",
  "\\addlinespace[2pt]")

pb_row <- function(label, col) {
  vals <- sapply(unname(OUTC), function(o) {
    r <- disp[outcome == o & block == "Bridge"]
    fmt(r[[paste0(col, ".estimate")]], r[[paste0(col, ".se")]], r[[paste0(col, ".p")]], mult = 1, dig = 4)
  })
  c(paste0(label, " & ", paste(vals[1, ], collapse = " & "), " \\\\"),
    paste0(" & ", paste(vals[2, ], collapse = " & "), " \\\\"),
    "\\addlinespace[2pt]")
}
lines <- c(lines,
  pb_row("Pre-holiday excess, $\\sum_{\\ell=-3}^{-1}\\theta_\\ell$", "pre"),
  pb_row("Window total, $\\sum_{\\ell=-3}^{+3}\\theta_\\ell$", "full"),
  "\\bottomrule",
  "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} SINASC 2012--2024, the years in which the prelabor indicator is",
  "recorded for more than 85 percent of cesareans. Panel A: municipality-date-sector",
  "cells with at least one birth, weighted by births; movable holidays are excluded.",
  "Each fixed-date national holiday is classified by the day of week on which it falls.",
  "Columns 2--4 add for-profit $\\times$ holiday-identity indicators, so the weekend-",
  "falling holiday is the omitted category and the coefficients are identified within",
  "holiday and within day of week. Coefficients are in percentage points.",
  "Panel B: balanced municipality-date panel of the two sectors, counts in births,",
  "event time $\\ell$ measured in days from the holiday, non-window days omitted;",
  "$\\theta_\\ell$ is the for-profit minus public difference on event day $\\ell$",
  "relative to an ordinary day of the same week day. Standard errors, two-way",
  "clustered by municipality and date, are reported in parentheses.",
  "\\newline", SIGNIF_NOTE,
  "\\end{minipage}",
  "\\end{table}")
writeLines(lines, file.path(TABLE, "tab_long_weekends.tex"))
cat("\n[6] wrote tab_long_weekends.tex\n")

# =============================================================================
# 7. SUPPLEMENT — robustness: shares in event time, isolated blocks, movable
# =============================================================================
# (a) share outcomes in event time (unweighted difference in sector rates,
#     municipality-days in which both sectors record at least one birth)
ds <- d[births_Private > 0 & births_Public > 0]
ds[, `:=`(dif_r_pre = n_pre_Private / births_Private - n_pre_Public / births_Public,
          dif_r_ces = n_ces_Private / births_Private - n_ces_Public / births_Public)]
m_share <- list(
  pre = feols(dif_r_pre ~ evt + dow | muni + ym, ds, cluster = ~muni + date),
  ces = feols(dif_r_ces ~ evt + dow | muni + ym, ds, cluster = ~muni + date))
share_sums <- rbindlist(lapply(names(m_share), function(y)
  rbindlist(lapply(c("Bridge", "Isolated"),
                   function(bk) mk_disp(m_share, y, y, bk)))))
cat("\n[7a] Share-outcome displacement sums (percentage points):\n")
print(share_sums[, .(outcome, block, pre_pp = round(100 * pre.estimate, 3),
                     pre_p = round(pre.p, 3), win_pp = round(100 * full.estimate, 3),
                     win_p = round(full.p, 3))])

# (b) taxonomy with movable holidays added to their day-of-week class
tax_mv <- copy(cells)[!(date %in% hol_excl)]
mv <- data.table(date = hol_move)[, `:=`(holname = "Movable", dow = wday(date))]
mv[, block := fcase(dow == 4L, "Isolated", dow %in% c(2L, 6L), "ThreeDay",
                    dow %in% c(3L, 5L), "Bridge", default = "WeekendHol")]
allh <- rbind(hol_fixed[, .(date, holname, block)], mv[, .(date, holname, block)])
tax_mv <- merge(tax_mv, allh, by = "date", all.x = TRUE)
tax_mv[is.na(block), `:=`(block = "None", holname = "None")]
tax_mv[, `:=`(iso = as.integer(block == "Isolated"), d3 = as.integer(block == "ThreeDay"),
              brg = as.integer(block == "Bridge"), wknd = as.integer(block == "WeekendHol"))]
tax_mv <- tax_mv[births > 0]
tax_mv[, `:=`(rate = n_ces / births, rate_pre = n_pre / births,
              dowf = factor(dow), holf = factor(holname))]
m_mv <- feols(rate_pre ~ i(private, iso, ref = 0) + i(private, d3, ref = 0) +
                i(private, brg, ref = 0) +
                i(dowf, private, ref = 1) + i(holf, private, ref = "None") |
                muni^date + muni^sector, tax_mv, weights = ~births, cluster = ~muni + date)
cat("\n[7b] Prelabor share taxonomy including movable holidays (pp):\n")
print(round(100 * coef(m_mv)[intersect(unname(K), names(coef(m_mv)))], 3))

sup <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{Long weekends: share outcomes, isolated blocks, and movable holidays}}",
  "\\label{tab:displacement_robust}",
  "\\small\\setlength{\\tabcolsep}{5pt}",
  "\\begin{tabular}{lcccc}", "\\toprule",
  "\\multicolumn{5}{l}{\\emph{Panel A. Event-time sums, share outcomes (percentage points)}} \\\\",
  "\\addlinespace[2pt]",
  " & \\multicolumn{2}{c}{Prelabor cesarean share} & \\multicolumn{2}{c}{Cesarean share} \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}",
  " & Bridge & Isolated & Bridge & Isolated \\\\", "\\midrule")
sr <- function(col, label) {
  cells <- lapply(list(share_sums[outcome == "pre" & block == "Bridge"],
                       share_sums[outcome == "pre" & block == "Isolated"],
                       share_sums[outcome == "ces" & block == "Bridge"],
                       share_sums[outcome == "ces" & block == "Isolated"]),
                  function(r) fmt(r[[paste0(col, ".estimate")]], r[[paste0(col, ".se")]],
                                  r[[paste0(col, ".p")]], mult = 100, dig = 3))
  c(paste0(label, " & ", paste(sapply(cells, `[`, 1), collapse = " & "), " \\\\"),
    paste0(" & ", paste(sapply(cells, `[`, 2), collapse = " & "), " \\\\"),
    "\\addlinespace[2pt]")
}
sup <- c(sup,
  sr("pre",  "Pre-holiday excess, $\\sum_{\\ell=-3}^{-1}\\theta_\\ell$"),
  sr("full", "Window total, $\\sum_{\\ell=-3}^{+3}\\theta_\\ell$"),
  "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel B. Prelabor-share taxonomy including movable holidays}} \\\\",
  "\\addlinespace[2pt]")
mvrow <- function(label, key) {
  if (!key %in% names(coef(m_mv))) return(character(0))
  ct <- coeftable(m_mv)[key, ]; f <- fmt(ct[1], ct[2], ct[4])
  c(paste0(label, " & \\multicolumn{4}{c}{", f[1], "} \\\\"),
    paste0(" & \\multicolumn{4}{c}{", f[2], "} \\\\"), "\\addlinespace[2pt]")
}
sup <- c(sup,
  mvrow("For-profit $\\times$ Bridge holiday", K[["brg"]]),
  mvrow("For-profit $\\times$ Three-day holiday", K[["d3"]]),
  mvrow("For-profit $\\times$ Isolated holiday", K[["iso"]]),
  "\\bottomrule", "\\end{tabular}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} SINASC 2012--2024. Panel A repeats the event study of",
  "Table~\\ref{tab:long_weekends}, Panel B, with sector cesarean shares in place of",
  "counts, on the municipality-days in which both sectors record at least one birth;",
  "outcomes are unweighted differences between the for-profit and the public share.",
  "Panel B re-estimates the prelabor-share taxonomy after assigning the movable",
  "national holidays (Carnival, Good Friday, Corpus Christi) to their day-of-week",
  "class; because these holidays fall on structurally fixed week days, they are",
  "excluded from the main specification. Standard errors, two-way clustered by",
  "municipality and date, are reported in parentheses.",
  "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
writeLines(sup, file.path(TABLE, "tab_displacement_robust.tex"))

# hand the hypothesis family to the multiple-testing table (Section K of 07_*.R)
ph <- m_tax$pre_hol$ct
fam_D <- data.table(
  family = "D. Long weekends",
  hypothesis = c("For-profit $\\times$ Bridge holiday",
                 "For-profit $\\times$ Three-day holiday",
                 "For-profit $\\times$ Isolated holiday",
                 "Pre-holiday excess, prelabor cesareans"),
  estimate = c(ph[K[["brg"]], 1], ph[K[["d3"]], 1], ph[K[["iso"]], 1],
               disp[outcome == "Prelabor cesareans" & block == "Bridge", pre.estimate]),
  p = c(ph[K[["brg"]], 4], ph[K[["d3"]], 4], ph[K[["iso"]], 4],
        disp[outcome == "Prelabor cesareans" & block == "Bridge", pre.p]))
saveRDS(fam_D, file.path(here::here("analysis", "output"), "fam_D.rds"))

message("08_long_weekends.R done")
