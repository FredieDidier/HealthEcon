# =============================================================================
# 12_subgroups.R — subgroup gradients: Robson group, gestational age, maternal age.
#
# WHAT THIS SCRIPT DOES. Three subgroup cuts of the calendar gradient, all built
# on the same municipality-date-sector cell structure as Equation (3):
#   A. GRADIENT BY ROBSON GROUP (1-10), each sector's own weekend dip.
#      -> robson_grad.rds, read by 11_body_figures.R as Figure 3 panel (c);
#         standalone fig_robson_gradient for inspection.
#   B. TERM vs PRETERM. Preterm cesareans are harder to schedule, so the
#      for-profit weekend differential should be smaller among them.
#   C. MATERNAL AGE (<35 vs 35+), overall and within low-risk Robson 1-2.
#      -> tab_subgroup_gradients.tex (Supplement, Appendix D).
#
# LABELING (hold everywhere). These are EXPLORATORY SUBGROUP SPLITS of the
# Equation (3) differential, not pre-specified hypotheses, and they are not part
# of the five multiple-testing families (A-E). Two further cautions:
#
#   - GESTATIONAL AGE AT BIRTH IS PARTLY AN OUTCOME of the behaviour we study
#     (Table 5 shows a +11.7pp for-profit early-term gap), so the term/preterm
#     split conditions on a partly post-treatment variable. It is a HEURISTIC
#     FALSIFICATION in the same class as the Robson-10 check, NOT a clean
#     placebo. Preterm delivery is also not synonymous with unschedulable:
#     preeclampsia, growth restriction and elective late-preterm delivery are
#     all scheduled, so a surviving dip among preterm births refutes nothing.
#   - MATERNAL AGE IS GENUINELY PREDETERMINED (scheduling cannot move it), so
#     unlike gestational age it is a legitimate conditioning variable. Note that
#     the LEVEL concern (older mothers have more cesareans) is already answered
#     by column 2 of Table 2, where maternal age bands enter as predetermined
#     composition and move the differential only from -2.3 to -2.2pp. What is
#     new here is whether the GRADIENT itself differs by age.
#
# NOTE ON ROBSON x PRETERM. There is no term/preterm split to be had inside
# Robson groups 1-2: those groups are DEFINED as >=37 weeks, and Robson 10 is
# defined as <=36 weeks. The term-vs-preterm contrast simply IS Robson 1-2 vs
# Robson 10, which panel A displays directly.
#
# Robson is populated from 2014, so Blocks A and C's low-risk panel use 2014-2024.
#
# MEMORY: loads sinasc_births.parquet (~42M rows). Do NOT run concurrently with
# 03, 05, 06, 07, 08 or 09.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")
AOUT  <- here::here("analysis", "output")

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

# --- one read of the birth file, all three blocks aggregate from it -----------
b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("muni", "date", "sector", "cesarean", "tipo_robson",
                      "semana_gestacao", "idade_mae", "dow", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
b[, date := as.IDate(date)]
hol <- holiday_dates(2010:2024)
b[, `:=`(weekend = as.integer(dow %in% c(1, 7)),
         holiday = as.integer(date %in% hol),
         private = as.integer(sector == "Private"))]
b[, eve := as.integer((date + 1L) %in% hol | dow == 6L)]

# cell builder: one municipality-date-sector cell per extra key `by`
cells_by <- function(dat, extra = character(0))
  dat[, .(rate = mean(cesarean), n = .N),
      by = c("muni", "date", "sector", "private", "weekend", "holiday", "eve",
             "year", extra)]

# =============================================================================
# BLOCK A — each sector's weekend gradient, by Robson group.
# Robson 1-2 (nulliparous term) and 5 (previous cesarean) are the schedulable
# groups; group 10 is preterm and cannot be freely booked. If the dip tracks
# schedulability, it should be large in 1-2 and small in 10.
# =============================================================================
rb <- b[year >= 2014 & tipo_robson %in% sprintf("%02d", 1:10)]
cr <- cells_by(rb, "tipo_robson")
rm(rb); gc()

grad_one <- function(dat) {
  if (nrow(dat) < 500L || uniqueN(dat$weekend) < 2L) return(c(NA_real_, NA_real_))
  m <- feols(rate ~ weekend + holiday + eve | muni + year, dat,
             weights = ~n, cluster = ~muni + date, notes = FALSE)
  ct <- coeftable(m)["weekend", ]
  c(ct[[1]], ct[[2]])
}

rg <- rbindlist(lapply(sprintf("%02d", 1:10), function(g) {
  out <- rbindlist(lapply(c("Private", "Public"), function(s) {
    e <- grad_one(cr[tipo_robson == g & sector == s])
    data.table(robson = g, sector = s, b = e[1], se = e[2])
  }))
  cat(sprintf("[12A] Robson %s done\n", g)); out
}))
rg[, `:=`(b = 100 * b, se = 100 * se)]
saveRDS(rg, file.path(AOUT, "robson_grad.rds"))

rgp <- copy(rg)[!is.na(b)]
rgp[, `:=`(sector = sector_display(sector, c("Private", "Public")),
           g = factor(as.integer(robson), levels = 1:10))]
fig_rob <- ggplot(rgp, aes(g, b, colour = sector, group = sector)) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_errorbar(aes(ymin = b - 1.96 * se, ymax = b + 1.96 * se), width = 0.18,
                position = position_dodge(width = 0.45), linewidth = 0.5) +
  geom_point(aes(shape = sector), position = position_dodge(width = 0.45), size = 2.4) +
  scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]),
                                 Public = unname(PAL["blue"]))) +
  scale_shape_manual(values = c(`For-profit` = 17, Public = 16)) +
  labs(x = "Robson group", y = "Weekend change in cesarean rate (pp)") +
  theme_paper()
save_fig(fig_rob, "fig_robson_gradient")
rm(cr, rgp); gc()

cat("\n[12A] Weekend dip by Robson group (pp):\n")
print(dcast(rg, robson ~ sector, value.var = "b"))

# =============================================================================
# BLOCKS B & C — Equation (3) differentials split by a binary subgroup.
#
# For a binary split S, the pooled specification is
#
#   rate_mdsS = pi_1 ForProfit x Weekend + pi_2 ForProfit x Weekend x S + ...
#             + lambda_{md,S} + phi_{ms,S} + e,
#
# with municipality x date x S and municipality x sector x S fixed effects. Those
# absorb the S main effect, the Weekend x S interaction and the ForProfit x S
# interaction, so this is exactly Equation (3) estimated separately within each
# level of S, with pi_2 the formal test of equality across levels. Columns 2-3 of
# each panel report the level-specific fits (identical coefficients, run
# separately for readability); column 4 reports pi_2.
# =============================================================================
eq3 <- function(dat, sub = NULL) {
  f <- if (is.null(sub))
    rate ~ pw + ph + pe | muni^date + muni^sector
  else
    rate ~ pw + ph + pe + pwS + phS + peS | muni^date^S + muni^sector^S
  feols(f, dat, weights = ~n, cluster = ~muni + date, notes = FALSE)
}
prep <- function(dat) {
  dat[, `:=`(pw = private * weekend, ph = private * holiday, pe = private * eve)]
  if ("S" %in% names(dat))
    dat[, `:=`(pwS = pw * S, phS = ph * S, peS = pe * S)]
  dat[]
}

# --- B: term (>=37 weeks) vs preterm (<37) ------------------------------------
gb <- b[semana_gestacao %between% c(22, 44)]
gb[, S := as.integer(semana_gestacao < 37)]     # S = 1 -> preterm
cg <- prep(cells_by(gb, "S"))
rm(gb); gc()
mB_all  <- eq3(prep(cells_by(b)))
mB_term <- eq3(cg[S == 0]); mB_pre <- eq3(cg[S == 1]); mB_int <- eq3(cg, sub = TRUE)
rm(cg); gc()

# --- C: maternal age <35 vs 35+ ----------------------------------------------
ab <- b[!is.na(idade_mae) & idade_mae %between% c(10, 60)]
ab[, S := as.integer(idade_mae >= 35)]
ca <- prep(cells_by(ab, "S"))
mC_all <- eq3(prep(cells_by(ab)))
mC_yng <- eq3(ca[S == 0]); mC_old <- eq3(ca[S == 1]); mC_int <- eq3(ca, sub = TRUE)
rm(ca); gc()

# --- C2: the same split inside low-risk Robson 1-2 ---------------------------
lb <- ab[year >= 2014 & tipo_robson %in% c("01", "02")]
cl <- prep(cells_by(lb, "S"))
mL_all <- eq3(prep(cells_by(lb)))
mL_yng <- eq3(cl[S == 0]); mL_old <- eq3(cl[S == 1]); mL_int <- eq3(cl, sub = TRUE)
rm(ab, lb, cl, b); gc()

# =============================================================================
# tab_subgroup_gradients.tex  (Supplement)
# =============================================================================
# Row across four (model, key) pairs: cols 1-3 read the level coefficient, col 4
# the interaction, so the key differs by column and tex_row cannot be used.
row4 <- function(label, pairs) {
  cells <- lapply(pairs, function(p) {
    ct <- fixest::coeftable(p[[1]])
    if (!p[[2]] %in% rownames(ct)) return(c("", ""))
    tex_coef(ct[p[[2]], 1], ct[p[[2]], 2], ct[p[[2]], 4])
  })
  c(paste0(label, " & ", paste(sapply(cells, `[`, 1), collapse = " & "), " \\\\"),
    paste0(" & ",        paste(sapply(cells, `[`, 2), collapse = " & "), " \\\\"),
    "\\addlinespace[2pt]")
}
panel <- function(models, keys = c("pw", "ph", "pe"), ikeys = c("pwS", "phS", "peS")) {
  unlist(lapply(seq_along(keys), function(i)
    row4(c("For-profit $\\times$ Weekend",
           "For-profit $\\times$ National holiday",
           "For-profit $\\times$ Eve of rest day")[i],
         list(list(models[[1]], keys[i]), list(models[[2]], keys[i]),
              list(models[[3]], keys[i]), list(models[[4]], ikeys[i])))))
}
nobs_row <- function(models)
  paste0("Observations & ", paste(sapply(models, function(m)
    formatC(stats::nobs(m), big.mark = ",", format = "d")), collapse = " & "), " \\\\")

tex <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{The for-profit calendar gradient by gestational age and maternal age}}",
  "\\label{tab:subgroup_gradients}",
  "\\small\\setlength{\\tabcolsep}{4pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel A. Gestational age at birth}} \\\\",
  "\\addlinespace[2pt]",
  " & All births & Term & Preterm & Preterm \\\\",
  " &  & ($\\geq$37 weeks) & ($<$37 weeks) & $-$ term \\\\",
  "\\addlinespace[3pt]",
  panel(list(mB_all, mB_term, mB_pre, mB_int)),
  "\\midrule",
  nobs_row(list(mB_all, mB_term, mB_pre, mB_int)),
  "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel B. Maternal age, all births}} \\\\",
  "\\addlinespace[2pt]",
  " & All births & Under 35 & 35 or older & 35+ \\\\",
  " &  &  &  & $-$ under 35 \\\\",
  "\\addlinespace[3pt]",
  panel(list(mC_all, mC_yng, mC_old, mC_int)),
  "\\midrule",
  nobs_row(list(mC_all, mC_yng, mC_old, mC_int)),
  "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel C. Maternal age, low-risk births (Robson groups 1--2)}} \\\\",
  "\\addlinespace[2pt]",
  " & All Robson 1--2 & Under 35 & 35 or older & 35+ \\\\",
  " &  &  &  & $-$ under 35 \\\\",
  "\\addlinespace[3pt]",
  panel(list(mL_all, mL_yng, mL_old, mL_int)),
  "\\midrule",
  nobs_row(list(mL_all, mL_yng, mL_old, mL_int)),
  "\\midrule",
  "Municipality $\\times$ date fixed effects & Yes & Yes & Yes & Yes \\\\",
  "Sample & \\multicolumn{3}{c}{2010--2024 (Panel C: 2014--2024)} & \\\\",
  "\\bottomrule", "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} Municipality-date-sector cells, SINASC, weighted by births;",
  "coefficients in percentage points. Every column estimates the for-profit",
  "differential of Equation~\\eqref{eq:gradient}. Columns 2--3 fit it separately",
  "within each subgroup; column 4 reports the interaction of each term with the",
  "subgroup indicator, estimated jointly with municipality$\\times$date$\\times$subgroup",
  "and municipality$\\times$sector$\\times$subgroup fixed effects, and is the formal",
  "test that the two subgroups share a gradient. Panel A splits births at 37",
  "completed weeks. Gestational age at birth is partly an outcome of the scheduling",
  "we study, so Panel A is a heuristic falsification test rather than a clean",
  "placebo, and preterm delivery is not synonymous with unschedulable delivery.",
  "Maternal age in Panels B and C is predetermined. Panel C restricts to Robson",
  "groups 1--2 (nulliparous, term, singleton, cephalic), the births least likely to",
  "require surgery; Robson groups are recorded from 2014. These are exploratory",
  "subgroup splits and are not among the pre-specified hypothesis families of",
  "Table~\\ref{tab:multiple_testing}. Standard errors, two-way clustered by",
  "municipality and date, are in parentheses.",
  "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
writeLines(tex, file.path(TABLE, "tab_subgroup_gradients.tex"))
unescape_refs(file.path(TABLE, "tab_subgroup_gradients.tex"))

cat("\n[12B] Term vs preterm for-profit differential (pp):\n")
print(round(100 * c(all = coef(mB_all)[["pw"]], term = coef(mB_term)[["pw"]],
                    preterm = coef(mB_pre)[["pw"]], diff = coef(mB_int)[["pwS"]]), 3))
cat(sprintf("      test p = %.3f\n", coeftable(mB_int)["pwS", 4]))
cat("\n[12C] Maternal age for-profit differential (pp):\n")
print(round(100 * c(under35 = coef(mC_yng)[["pw"]], over35 = coef(mC_old)[["pw"]],
                    diff = coef(mC_int)[["pwS"]]), 3))
cat(sprintf("      test p = %.3f\n", coeftable(mC_int)["pwS", 4]))
cat("\n[12C] Same, within Robson 1-2 (pp):\n")
print(round(100 * c(under35 = coef(mL_yng)[["pw"]], over35 = coef(mL_old)[["pw"]],
                    diff = coef(mL_int)[["pwS"]]), 3))
cat(sprintf("      test p = %.3f\n", coeftable(mL_int)["pwS", 4]))

message("12_subgroups.R done")
