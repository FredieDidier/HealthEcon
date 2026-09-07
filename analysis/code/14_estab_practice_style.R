# =============================================================================
# 14_estab_practice_style.R — practice style at the ESTABLISHMENT level
#
# WHAT THIS IS. The body's Kitagawa decomposition (Table 6) splits the
# for-profit--public cesarean gap into Robson case-mix and within-group practice
# style, and attributes 72 percent to practice style. That statement is made
# BETWEEN SECTORS, on two national aggregates. This script makes the same
# statement BETWEEN HOSPITALS, which is where the decision is actually taken:
# how much of the dispersion in cesarean intensity across maternities survives
# once the comparison holds the local market, the Robson case-mix, predetermined
# maternal composition, and obstetric capacity fixed?
#
# It answers the coauthor question "what makes otherwise similar hospitals run
# different cesarean rates?" in the form the data can support. This is ACCOUNTING
# AND DESCRIPTION, not a mechanism and not a causal decomposition: the residual
# dispersion is what the observed covariates do not explain, which includes
# unmeasured case-mix and unmeasured capacity alongside practice style. Say
# "dispersion that survives observed case-mix and capacity", never "the causal
# contribution of the hospital".
#
# ROBSON STANDARDIZATION. The WHO's current guidance (WHO/RHR/15.02) sets no
# target cesarean rate and directs institutional comparison through the Robson
# classification, which is what the standardized rate below implements: each
# establishment's own group-specific rates are reweighted to the national Robson
# distribution of the same year, so two maternities are compared as if they saw
# the same mix of women. Establishments are kept when the groups they cover
# account for at least 90 percent of the reference weight, and the weights are
# renormalized over the covered groups.
#
# SAMPLE. SINASC 2014--2024 (Robson populated from 2014), Robson groups 01--10 as
# in the body decomposition, establishment-years with at least 100 births, the
# three named sectors (Other excluded, as everywhere).
#
# Exhibit (Supplemental Appendix, descriptive):
#   tab_estab_practice_style.tex
#
# Capacity comes from build/01d_cnes_estab.R (cnes_estab_year.parquet); the block
# is skipped, with a message, if that file is absent.
#
# COST: one pass over sinasc_births.parquet (42M rows), aggregated inside arrow,
# then cached as an establishment-year x Robson cell file. Do not run it
# alongside another 42M-row script.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, dplyr, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
CNES  <- file.path(DROPBOX_ROOT, "build", "CNES", "input")
TABLE <- here::here("analysis", "output", "tables")

YEARS      <- 2014:2024
YEAR_MIN   <- min(YEARS)   # arrow cannot evaluate min() inside filter(): pass scalars
YEAR_MAX   <- max(YEARS)
ROBSON     <- sprintf("%02d", 1:10)
MIN_BIRTHS <- 100L     # an establishment-year has to be a maternity
MIN_COVER  <- 0.90     # reference weight covered by the groups the maternity has

CELL_CACHE  <- file.path(SIN, "sinasc_estab_year_robson.parquet")
ESTAB_PANEL <- file.path(CNES, "cnes_estab_year.parquet")

# =============================================================================
# 1. Establishment-year x Robson cells (cached)
#
# One scan of the birth file carries both ingredients: the group-specific
# cesarean counts that the standardization needs, and the predetermined maternal
# composition. Missing values are handled explicitly (a summed indicator plus a
# non-missing count) rather than through mean(na.rm =), so a cell's denominator
# is the number of births where the variable is actually recorded.
#
# The case-mix block deliberately holds only variables that are NOT part of the
# Robson classification: age, education, race. Parity, previous cesarean,
# multiplicity, presentation and preterm status are Robson's own inputs, so
# adding them would double-count the composition block rather than test it.
# =============================================================================
if (!file.exists(CELL_CACHE)) {
  message("building ", basename(CELL_CACHE), " from sinasc_births.parquet ...")
  cells <- open_dataset(file.path(SIN, "sinasc_births.parquet")) %>%
    filter(year >= YEAR_MIN, year <= YEAR_MAX,
           sector %in% c("Private", "Nonprofit", "Public"),
           tipo_robson %in% ROBSON) %>%
    mutate(ces      = if_else(cesarean == 1L, 1L, 0L),
           i_teen   = if_else(!is.na(idade_mae) & idade_mae < 20L, 1L, 0L),
           i_age35  = if_else(!is.na(idade_mae) & idade_mae >= 35L, 1L, 0L),
           i_loweduc = if_else(!is.na(escolaridade_mae) & escolaridade_mae <= 3L, 1L, 0L),
           i_nonwhite = if_else(!is.na(raca_cor_mae) & raca_cor_mae != 1L, 1L, 0L),
           nn_age   = if_else(is.na(idade_mae), 0L, 1L),
           nn_educ  = if_else(is.na(escolaridade_mae) | escolaridade_mae == 9L, 0L, 1L),
           nn_race  = if_else(is.na(raca_cor_mae), 0L, 1L),
           age_val  = if_else(is.na(idade_mae), 0L, idade_mae)) %>%
    group_by(estab, muni, sector, year, tipo_robson) %>%
    summarise(n = n(), n_ces = sum(ces),
              s_age = sum(age_val), nn_age = sum(nn_age),
              s_teen = sum(i_teen), s_age35 = sum(i_age35),
              s_loweduc = sum(i_loweduc), nn_educ = sum(nn_educ),
              s_nonwhite = sum(i_nonwhite), nn_race = sum(nn_race),
              .groups = "drop") %>%
    collect() %>% as.data.table()
  write_parquet(cells, CELL_CACHE)
  message("saved ", nrow(cells), " establishment-year x Robson cells")
}
cells <- as.data.table(read_parquet(CELL_CACHE))

# =============================================================================
# 2. Robson-standardized cesarean intensity by establishment-year
# =============================================================================
# Reference distribution: the national Robson mix of the same year, all sectors.
ref <- cells[, .(n = sum(n)), by = .(year, tipo_robson)]
ref[, w := n / sum(n), by = year]

# An establishment-year can carry more than one recorded municipality of birth or
# sector code across its records, so (estab, year) is NOT unique in `cells` and
# joining on it duplicates rows. Collapse to the establishment-year and attach the
# modal municipality and sector, by births, which makes (estab, year) the key that
# everything below merges on.
key <- cells[, .(n = sum(n)), by = .(estab, year, muni, sector)]
setorder(key, estab, year, -n)
key <- key[, .(muni = muni[1L], sector = sector[1L]), by = .(estab, year)]

cg <- cells[, .(n = sum(n), n_ces = sum(n_ces)), by = .(estab, year, tipo_robson)]

ey <- cells[, .(births = sum(n), n_ces = sum(n_ces),
                s_age = sum(s_age), nn_age = sum(nn_age),
                s_teen = sum(s_teen), s_age35 = sum(s_age35),
                s_loweduc = sum(s_loweduc), nn_educ = sum(nn_educ),
                s_nonwhite = sum(s_nonwhite), nn_race = sum(nn_race)),
            by = .(estab, year)]
ey <- merge(ey, key, by = c("estab", "year"))
ey <- ey[births >= MIN_BIRTHS]

# Direct standardization over the groups the establishment actually delivers,
# with the reference weights renormalized over those groups.
st <- merge(cg, ref[, .(year, tipo_robson, w)], by = c("year", "tipo_robson"))
st[, rate := n_ces / n]
std <- st[, .(cover = sum(w), std_rate = sum(w * rate) / sum(w)),
          by = .(estab, year)]
ey <- merge(ey, std, by = c("estab", "year"), all.x = TRUE)

# Robson composition shares, the block that the standardization implements as a
# reweighting and the decomposition below enters as controls.
sh <- dcast(cg, estab + year ~ tipo_robson, value.var = "n", fill = 0)
gcols <- setdiff(names(sh), c("estab", "year"))
sh[, tot := rowSums(.SD), .SDcols = gcols]
for (g in gcols) sh[, (paste0("sh_", g)) := get(g) / tot]
ey <- merge(ey, sh[, c("estab", "year", paste0("sh_", gcols)), with = FALSE],
            by = c("estab", "year"), all.x = TRUE)

ey[, `:=`(ces_rate = n_ces / births,
          mean_age = s_age / pmax(nn_age, 1L),
          sh_teen  = s_teen / births,
          sh_age35 = s_age35 / births,
          sh_loweduc = s_loweduc / pmax(nn_educ, 1L),
          sh_nonwhite = s_nonwhite / pmax(nn_race, 1L))]
stopifnot(!anyDuplicated(ey[, .(estab, year)]))

cat(sprintf("\n[2] Establishment-years with >= %d births, 2014--2024: %s (%s establishments, %s births)\n",
            MIN_BIRTHS, format(nrow(ey), big.mark = ","),
            format(uniqueN(ey$estab), big.mark = ","),
            format(sum(ey$births), big.mark = ",")))
cat(sprintf("[2] Reference-weight coverage: median %.3f, share above %.2f: %.3f\n",
            median(ey$cover), MIN_COVER, mean(ey$cover >= MIN_COVER)))

es <- ey[cover >= MIN_COVER]          # the standardization sample

# =============================================================================
# 3. Panel A — dispersion of observed and Robson-standardized intensity
# =============================================================================
wq <- function(x, w, p) {            # births-weighted quantile
  o <- order(x); x <- x[o]; w <- w[o]
  cw <- cumsum(w) / sum(w)
  x[which(cw >= p)[1L]]
}
disp <- es[, .(
  ey_n    = .N,
  births  = sum(births),
  obs_m   = 100 * weighted.mean(ces_rate, births),
  obs_sd  = 100 * sqrt(sum(births * (ces_rate - weighted.mean(ces_rate, births))^2) / sum(births)),
  obs_sp  = 100 * (wq(ces_rate, births, 0.90) - wq(ces_rate, births, 0.10)),
  std_m   = 100 * weighted.mean(std_rate, births),
  std_sd  = 100 * sqrt(sum(births * (std_rate - weighted.mean(std_rate, births))^2) / sum(births)),
  std_sp  = 100 * (wq(std_rate, births, 0.90) - wq(std_rate, births, 0.10))),
  by = sector]
disp <- disp[match(SECTOR_LEVELS, sector)][!is.na(sector)]
cat("\n[3] Dispersion of establishment-year cesarean intensity (pp):\n")
print(disp[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])

# =============================================================================
# 4. Panel B — how much dispersion survives each block
#
# THE OUTCOME IS THE ROBSON-STANDARDIZED RATE, not the observed one, and that
# choice matters. Regressing the OBSERVED rate on the ten group shares absorbs far
# more than the standardization does, because the shares are free to proxy the
# within-group practice they correlate with: a maternity delivering many women
# with a previous cesarean also sections more of its spontaneous-labor women. That
# R2 is therefore an UPPER BOUND on what case-mix explains, and it is reported in
# the table note rather than as a row. Standardizing first holds each maternity's
# own group-specific rates and reweights them to a common mix, which is the
# conservative accounting and the comparison the WHO guidance directs, so Panel B
# starts from it and asks what the local market, the maternal composition that
# Robson does not encode, and obstetric capacity add.
#
# Weighted by births, so the numbers describe the experience of a birth rather
# than of a maternity. The residual standard deviation is the weighted RMSE, and
# the last column expresses it against the raw dispersion of row 1.
# =============================================================================
cap_ok <- file.exists(ESTAB_PANEL)
if (cap_ok) {
  cap <- as.data.table(read_parquet(ESTAB_PANEL))
  cap <- cap[, .(estab = cnes, year, beds_obstetric, beds_total)]
  es <- merge(es, cap, by = c("estab", "year"), all.x = TRUE)
  es[, `:=`(log_beds = log(1 + beds_obstetric), log_vol = log(births))]
  cat(sprintf("[4] CNES capacity links %.1f%% of establishment-years, %.1f%% of births\n",
              100 * es[, mean(!is.na(beds_obstetric))],
              100 * es[, sum(births[!is.na(beds_obstetric)]) / sum(births)]))
} else {
  message("cnes_estab_year.parquet not found; the capacity row is omitted.")
}

ROB_SH  <- paste0("sh_", ROBSON[-1])                       # one group is the base
CASEMIX <- c("mean_age", "sh_teen", "sh_age35", "sh_loweduc", "sh_nonwhite")

wsd <- function(x, w) sqrt(sum(w * (x - weighted.mean(x, w))^2) / sum(w))

# Every row of Panel B has to be read against the same denominator, so the panel
# runs on one sample: the establishment-years with no missing value on any of the
# regressors, capacity included. Panel A stays on the full standardization sample,
# where no regressor is needed.
need <- c("ces_rate", "std_rate", "births", "muni", "sector", ROB_SH, CASEMIX,
          if (cap_ok) c("log_beds", "log_vol"))
esB <- es[stats::complete.cases(es[, ..need])]
cat(sprintf("[4] Panel B sample: %s of %s establishment-years (%.1f%% of births)\n",
            format(nrow(esB), big.mark = ","), format(nrow(es), big.mark = ","),
            100 * sum(esB$births) / sum(es$births)))

# Each specification is (rhs, fe); the residual SD is the weighted RMSE.
specs <- list(
  list(lab = "None (raw dispersion)",           rhs = "1", fe = ""),
  list(lab = "Sector",                          rhs = "1", fe = "sector"),
  list(lab = "$+$ Municipality $\\times$ year", rhs = "1", fe = "sector + muni^year"),
  list(lab = "$+$ Maternal case-mix",           rhs = paste(CASEMIX, collapse = " + "),
       fe = "sector + muni^year"))
if (cap_ok)
  specs <- c(specs, list(list(lab = "$+$ Obstetric capacity",
                              rhs = paste(c(CASEMIX, "log_beds", "log_vol"), collapse = " + "),
                              fe = "sector + muni^year")))

fit_block <- function(dat, drop_sector, y = "std_rate") {
  raw <- wsd(dat[[y]], dat$births)
  out <- vector("list", length(specs))
  for (k in seq_along(specs)) {
    sp <- specs[[k]]
    fe <- sp$fe
    if (drop_sector) fe <- trimws(sub("^sector \\+?", "", fe))
    if (drop_sector && identical(sp$lab, "Sector")) {         # nothing to absorb
      out[[k]] <- list(lab = sp$lab, r2 = NA_real_, sd = NA_real_, pct = NA_real_)
      next
    }
    fml <- as.formula(paste(y, "~", sp$rhs, if (nzchar(fe)) paste("|", fe) else ""))
    m  <- feols(fml, dat, weights = ~births, warn = FALSE, notes = FALSE)
    sd <- wsd(residuals(m), dat$births)
    r2 <- 1 - (sd / raw)^2
    out[[k]] <- list(lab = sp$lab, r2 = r2, sd = 100 * sd, pct = 100 * sd / raw)
  }
  list(raw = 100 * raw, rows = out, n = nrow(dat))
}

all_b <- fit_block(esB, drop_sector = FALSE)
fp_b  <- fit_block(esB[sector == "Private"], drop_sector = TRUE)

# The upper bound quoted in the note: the ten Robson shares entered as regressors
# on the OBSERVED rate, on top of sector and municipality x year.
ub     <- feols(as.formula(paste("ces_rate ~", paste(ROB_SH, collapse = " + "),
                                 "| sector + muni^year")),
                esB, weights = ~births, warn = FALSE, notes = FALSE)
ub_raw <- wsd(esB$ces_rate, esB$births)
ub_sd  <- wsd(residuals(ub), esB$births)
ub_r2  <- 1 - (ub_sd / ub_raw)^2
cat(sprintf("[4] Upper bound, Robson shares as regressors on the observed rate: R2 %.3f, residual SD %.2fpp (%.0f%% of raw)\n",
            ub_r2, 100 * ub_sd, 100 * ub_sd / ub_raw))

cat("\n[4] Dispersion surviving each block (weighted by births):\n")
for (k in seq_along(specs))
  cat(sprintf("  %-32s all: R2 %5.3f  SD %5.2fpp (%3.0f%%)   for-profit: R2 %5.3f  SD %5.2fpp (%3.0f%%)\n",
              gsub("\\$|\\\\times", "", specs[[k]]$lab),
              all_b$rows[[k]]$r2, all_b$rows[[k]]$sd, all_b$rows[[k]]$pct,
              fp_b$rows[[k]]$r2,  fp_b$rows[[k]]$sd,  fp_b$rows[[k]]$pct))

# The same fact without a regression: how far apart are two for-profit
# maternities delivering in the same municipality and year? Mean absolute
# pairwise difference in the standardized rate, over municipality-years with at
# least two of them, weighted by the births in the cell.
pw <- esB[sector == "Private", if (.N >= 2L) {
  cb <- combn(.N, 2L)
  .(mad = mean(abs(std_rate[cb[1, ]] - std_rate[cb[2, ]])), w = sum(births), k = .N)
}, by = .(muni, year)]
pair_mad <- 100 * weighted.mean(pw$mad, pw$w)
cat(sprintf("[4] For-profit maternities in the same municipality-year: mean absolute pairwise gap in the standardized rate %.1fpp (%s municipality-years, %s births)\n",
            pair_mad, format(nrow(pw), big.mark = ","), format(sum(pw$w), big.mark = ",")))

# =============================================================================
# 5. Table (Supplemental Appendix)
# =============================================================================
fm <- function(x, d = 1) if (is.na(x)) "" else formatC(x, format = "f", digits = d)

rowA <- function(r) paste(c(
  as.character(SECTOR_DISPLAY[[r$sector]]),
  format(r$ey_n, big.mark = ","), format(r$births, big.mark = ","),
  fm(r$obs_m), fm(r$obs_sd), fm(r$obs_sp),
  fm(r$std_m), fm(r$std_sd), fm(r$std_sp)), collapse = " & ")

# The first row has no model, so its R2 cell stays empty and its residual IS the
# raw dispersion. The nine cells are assembled directly: splitting a joined string
# would drop the trailing empty fields and print NA in the last column.
rowB <- function(k) {
  a <- all_b$rows[[k]]; f <- fp_b$rows[[k]]
  raw <- identical(k, 1L)
  paste(c(specs[[k]]$lab,
          if (raw) "" else fm(a$r2, 3), fm(a$sd, 2), fm(a$pct, 0), "",
          if (raw) "" else fm(f$r2, 3), fm(f$sd, 2), fm(f$pct, 0), ""),
        collapse = " & ")
}

tex <- c(
  "\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Practice style at the establishment level: dispersion in cesarean intensity across maternities}}",
  "\\label{tab:estab_practice_style}",
  "\\begin{tabular}{lrrrrrrrr}",
  "\\toprule",
  " & & & \\multicolumn{3}{c}{Observed rate (\\%)} & \\multicolumn{3}{c}{Robson-standardized (\\%)} \\\\",
  "\\cmidrule(lr){4-6}\\cmidrule(lr){7-9}",
  " & Maternity- & & & & P90$-$ & & & P90$-$ \\\\",
  " & years & Births & Mean & SD & P10 & Mean & SD & P10 \\\\",
  "\\midrule",
  "\\multicolumn{9}{l}{\\emph{Panel A. Dispersion across maternities, by sector}} \\\\",
  "\\addlinespace[2pt]",
  unlist(lapply(seq_len(nrow(disp)), function(i) paste(rowA(disp[i]), "\\\\"))),
  "\\addlinespace[4pt]",
  "\\midrule",
  paste("\\multicolumn{9}{l}{\\emph{Panel B. Dispersion of the standardized rate surviving each block}}",
        "\\\\"),
  "\\addlinespace[2pt]",
  " & \\multicolumn{3}{c}{All sectors} & & \\multicolumn{3}{c}{For-profit only} & \\\\",
  "\\cmidrule(lr){2-4}\\cmidrule(lr){6-8}",
  paste(" & $R^2$ & Residual SD & \\% of raw & & $R^2$ & Residual SD & \\% of raw &",
        "\\\\"),
  "\\midrule",
  unlist(lapply(seq_along(specs), function(k) paste(rowB(k), "\\\\"))),
  "\\bottomrule",
  "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} SINASC 2014--2024 (Robson",
        "classification populated from 2014), Robson groups 01--10, establishment-years",
        sprintf("with at least %d births, weighted by births throughout.", MIN_BIRTHS),
        "The Robson-standardized rate reweights each maternity's own group-specific",
        "cesarean rates to the national Robson distribution of the same year, the",
        "institutional comparison the World Health Organization's current guidance",
        "directs \\citep{who2015cesarean}. Maternities are kept when the groups they",
        sprintf("deliver cover at least %.0f percent of the reference weight,", 100 * MIN_COVER),
        "with the weights renormalized over the covered groups. Panel B takes the",
        "standardized rate as the outcome, so the Robson case-mix is already held, and",
        "reports for nested sets of the remaining determinants the share of its weighted",
        "variance they explain, the residual standard deviation in percentage points, and",
        "that residual as a percentage of the raw dispersion in the first row.",
        sprintf("It runs on the %s establishment-years carrying no missing regressor, so",
                format(nrow(esB), big.mark = ",")),
        "every row shares one sample. Maternal case-mix is the mother's mean age and the",
        "shares under 20, 35 or older, with at most seven years of schooling, and not",
        "recorded as white, none of which is an input to the Robson classification.",
        "Obstetric capacity is the establishment's obstetric beds and delivery volume",
        "from CNES. The sector row is empty in the for-profit columns, which hold one",
        "sector by construction. Entering the ten Robson group shares as regressors on",
        "the observed rate instead of standardizing absorbs more",
        sprintf("($R^2$ of %.2f, residual %.1f percentage points), but it is an upper bound",
                ub_r2, 100 * ub_sd),
        "on what case-mix explains, because a maternity's group shares also proxy the",
        "within-group practice they correlate with. Two for-profit maternities delivering",
        sprintf("in the same municipality and year differ by %.1f percentage points on", pair_mad),
        "average in the standardized rate. This is accounting rather than a causal",
        "decomposition: the residual dispersion is what these covariates do not explain,",
        "and it contains unmeasured case-mix and unmeasured capacity alongside",
        "differences in practice."),
  "\\end{table}")

write_table_tex(resize_tabular(tex, fontsize = "\\footnotesize", tabcolsep = 4),
                file.path(TABLE, "tab_estab_practice_style.tex"))

message("14_estab_practice_style.R done")
