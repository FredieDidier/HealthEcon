# =============================================================================
# 07_main_specification.R — the paper's main estimating equation.
#
# Equation (3): pooling for-profit and public municipality-date-sector cells,
#
#   CesareanShare_mds = gamma_1 ForProfit_s x Weekend_d
#                     + gamma_2 ForProfit_s x Holiday_d
#                     + gamma_3 ForProfit_s x Eve_d
#                     + lambda_md + phi_ms + e_mds,
#
# the municipality x date fixed effects absorb every shock common to both sectors
# on a given local day, so the interactions are the for-profit-specific calendar
# gradient, estimated from the SAME municipality and day. This is a
# within-municipality-day differential, causal only under a common-gradient
# assumption; it is not a difference-in-differences, because ownership is not
# assigned. Equation (2), each sector's own gradient, is reported below it as
# context.
#
# Columns of the body table:
#   (1) cesarean share, baseline
#   (2) + predetermined maternal composition (age, education, race, parity)
#   (3) + Robson-group shares (clinical standardization, POST-TREATMENT: the
#       classification encodes labor onset and gestational age, which scheduling
#       itself moves, so this is descriptive, not the preferred adjustment)
#   (4) prelabor cesarean share
#   (5) in-labor cesarean share
# Columns 4-5 use 2012-2024, the years in which the before/during-labor indicator
# is recorded for more than 85 percent of cesareans.
#
#   -> tab_main_gradient.tex  (BODY, Table 2)
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

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

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("muni", "date", "sector", "cesarean", "cesarea_antes_parto",
                      "tipo_robson", "idade_mae", "escolaridade_mae", "raca_cor_mae",
                      "paridade", "dow", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
b[, date := as.IDate(date)]
hol <- holiday_dates(2010:2024)
b[, `:=`(weekend = as.integer(dow %in% c(1, 7)), holiday = as.integer(date %in% hol))]
b[, eve := as.integer((date + 1L) %in% hol | dow == 6L)]
b[, private := as.integer(sector == "Private")]
b[, `:=`(ces_pre = as.integer(cesarean == 1L & cesarea_antes_parto == 1L),
         ces_lab = as.integer(cesarean == 1L & cesarea_antes_parto == 2L))]
b[is.na(ces_pre), ces_pre := 0L]; b[is.na(ces_lab), ces_lab := 0L]

# composition strata; an explicit "miss" category keeps every birth in its cell
b[, rob := fifelse(tipo_robson %in% sprintf("%02d", 1:11), tipo_robson, "miss")]
b[, age := fcase(is.na(idade_mae), "miss", idade_mae < 20, "a1", idade_mae < 25, "a2",
                 idade_mae < 30, "a3", idade_mae < 35, "a4", default = "a5")]
b[, edu := fcase(escolaridade_mae %in% 1:2, "e12", escolaridade_mae == 3L, "e3",
                 escolaridade_mae == 4L, "e4", escolaridade_mae == 5L, "e5", default = "miss")]
b[, rac := fcase(raca_cor_mae %in% 1:5, paste0("r", raca_cor_mae), default = "miss")]
b[, par := fcase(paridade == 0L, "p0", paridade == 1L, "p1", default = "miss")]

b[, cellid := .GRP, by = .(muni, date, sector)]
cells <- b[, .(rate = sum(cesarean) / .N, rate_pre = sum(ces_pre) / .N,
               rate_lab = sum(ces_lab) / .N, births = .N,
               muni = muni[1], date = date[1], sector = sector[1], private = private[1],
               weekend = weekend[1], holiday = holiday[1], eve = eve[1], year = year[1]),
           by = cellid]

shares_of <- function(gvar, prefix) {
  tmp <- b[, .N, by = c("cellid", gvar)]
  setnames(tmp, gvar, "g")
  w <- dcast(tmp, cellid ~ g, value.var = "N", fill = 0L)
  cols <- setdiff(names(w), "cellid")
  tot <- Reduce(`+`, lapply(cols, function(cc) w[[cc]]))
  for (cc in cols) set(w, j = cc, value = w[[cc]] / tot)
  setnames(w, cols, paste0(prefix, "_", cols))
  w[, (paste0(prefix, "_miss")) := NULL]
  w
}
for (s in list(c("rob", "sr"), c("age", "sa"), c("edu", "se"), c("rac", "sc"), c("par", "sp")))
  cells <- merge(cells, shares_of(s[1], s[2]), by = "cellid", all.x = TRUE)
predet_cols <- grep("^s[aecp]_", names(cells), value = TRUE)
robson_cols <- grep("^sr_", names(cells), value = TRUE)
rm(b); gc()

GRAD <- "i(private, weekend, ref = 0) + i(private, holiday, ref = 0) + i(private, eve, ref = 0)"
fml <- function(y, controls = character(0))
  as.formula(paste(y, "~", paste(c(GRAD, controls), collapse = " + "),
                   "| muni^date + muni^sector"))

m1 <- feols(fml("rate"), cells, weights = ~births, cluster = ~muni + date)
m2 <- feols(fml("rate", predet_cols), cells, weights = ~births, cluster = ~muni + date)
m3 <- feols(fml("rate", c(predet_cols, robson_cols)), cells, weights = ~births, cluster = ~muni + date)
m4 <- feols(fml("rate_pre"), cells[year >= 2012], weights = ~births, cluster = ~muni + date)
m5 <- feols(fml("rate_lab"), cells[year >= 2012], weights = ~births, cluster = ~muni + date)

# Panel B, context: each sector's own gradient (Equation 2)
m_pub  <- feols(rate ~ weekend + holiday + eve | muni + year, cells[private == 0],
                weights = ~births, cluster = ~muni + date)
m_priv <- feols(rate ~ weekend + holiday + eve | muni + year, cells[private == 1],
                weights = ~births, cluster = ~muni + date)

MAIN <- list(m1, m2, m3, m4, m5)
KG <- c(wk = "private::1:weekend", hl = "private::1:holiday", ev = "private::1:eve")

tex <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{For-profit calendar gradient within the municipality-day}}",
  "\\label{tab:main_gradient}",
  "\\small\\setlength{\\tabcolsep}{4pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "\\begin{tabular}{lccccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Cesarean & Cesarean & Cesarean & Prelabor & In-labor \\\\",
  " & share & share & share & cesarean share & cesarean share \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\emph{Panel A. For-profit differential}} \\\\",
  "\\addlinespace[2pt]",
  tex_row("For-profit $\\times$ Weekend", MAIN, KG[["wk"]]),
  tex_row("For-profit $\\times$ National holiday", MAIN, KG[["hl"]]),
  tex_row("For-profit $\\times$ Eve of rest day", MAIN, KG[["ev"]]),
  "\\midrule",
  "Predetermined maternal composition & No & Yes & Yes & No & No \\\\",
  "Robson-group shares & No & No & Yes & No & No \\\\",
  "Municipality $\\times$ date fixed effects & Yes & Yes & Yes & Yes & Yes \\\\",
  "Sample & 2010--2024 & 2010--2024 & 2010--2024 & 2012--2024 & 2012--2024 \\\\",
  tex_nobs(MAIN),
  "\\midrule",
  "\\multicolumn{6}{l}{\\emph{Panel B. Each sector's own gradient}} \\\\",
  "\\addlinespace[2pt]",
  " & \\multicolumn{2}{c}{Public} & \\multicolumn{2}{c}{For-profit} & \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}",
  "\\addlinespace[2pt]")

pb <- function(label, key) {
  cp <- fixest::coeftable(m_pub)[key, ]; cf <- fixest::coeftable(m_priv)[key, ]
  a <- tex_coef(cp[[1]], cp[[2]], cp[[4]]); bb <- tex_coef(cf[[1]], cf[[2]], cf[[4]])
  c(paste0(label, " & \\multicolumn{2}{c}{", a[1], "} & \\multicolumn{2}{c}{", bb[1], "} & \\\\"),
    paste0(" & \\multicolumn{2}{c}{", a[2], "} & \\multicolumn{2}{c}{", bb[2], "} & \\\\"),
    "\\addlinespace[2pt]")
}
tex <- c(tex,
  pb("Weekend", "weekend"), pb("National holiday", "holiday"), pb("Eve of rest day", "eve"),
  "\\midrule",
  "Municipality fixed effects & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} & \\\\",
  "Year fixed effects & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} & \\\\",
  paste0("Observations & \\multicolumn{2}{c}{",
         formatC(nobs(m_pub), big.mark = ",", format = "d"),
         "} & \\multicolumn{2}{c}{",
         formatC(nobs(m_priv), big.mark = ",", format = "d"), "} & \\\\"),
  "\\bottomrule", "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} Municipality-date-sector cells, SINASC, weighted by births;",
  "coefficients in percentage points. Panel A estimates",
  "Equation~\\eqref{eq:gradient}: municipality$\\times$date fixed effects absorb every",
  "shock common to the two sectors within a municipality-day, so the interactions are",
  "the for-profit-specific gradient. Predetermined maternal composition is the cell's",
  "share of births in each maternal age band, education category, race category, and",
  "parity category. Robson-group shares standardize clinically but may respond to",
  "scheduling, since the classification encodes labor onset and gestational age.",
  "Columns 4--5 split the cesarean share into cesareans performed before and during",
  "labor, on the years in which the timing indicator is recorded for more than 85",
  "percent of cesareans. Panel B reports each sector's own gradient from",
  "Equation~\\eqref{eq:scheduling}, with municipality and year fixed effects.",
  "Standard errors, two-way clustered by municipality and date, are reported in",
  "parentheses.",
  "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
writeLines(tex, file.path(TABLE, "tab_main_gradient.tex"))

cat("\n[07] For-profit differential (pp):\n")
print(round(100 * rbind(baseline = coef(m1)[KG], predetermined = coef(m2)[KG],
                        plus_robson = coef(m3)[KG], prelabor = coef(m4)[KG],
                        inlabor = coef(m5)[KG]), 3))
cat("\n[07] Sector gradients (pp): public\n"); print(round(100 * coef(m_pub), 3))
cat("[07] Sector gradients (pp): for-profit\n"); print(round(100 * coef(m_priv), 3))

fam_A <- data.table(
  family = "A. For-profit calendar gradient",
  hypothesis = c("For-profit $\\times$ Weekend", "For-profit $\\times$ National holiday",
                 "For-profit $\\times$ Eve of rest day"),
  estimate = coef(m1)[KG], p = coeftable(m1)[KG, 4])
saveRDS(fam_A, file.path(here::here("analysis", "output"), "fam_A.rds"))

message("07_main_specification.R done")
