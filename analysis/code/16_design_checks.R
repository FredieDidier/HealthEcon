# =============================================================================
# 16_design_checks.R — three checks requested in the 2026-09-28 referee round.
#
#   A. FEES PER HOUR OF PHYSICIAN TIME (TISS). The fee comparison of Section 5 is
#      per delivery. Per hour of physician time the ranking reverses, because the
#      labor that a vaginal delivery requires is paid by the hour at a far lower
#      rate than a cesarean pays for about an hour of surgery. The table reports,
#      for the country and the five largest states, the fees, the billed labor
#      hours, the price of a billed labor hour, and the BREAK-EVEN physician time
#      of a vaginal delivery: the hours at which the economic vaginal fee per hour
#      equals the cesarean fee per hour, for a cesarean taking one or two hours.
#      Physician hours are not observed; billed hours are a floor on the time a
#      vaginal delivery takes (62% of vaginal deliveries bill none), so every
#      per-hour comparison here is tilted IN FAVOUR of the vaginal delivery.
#      -> tab_fee_per_hour.tex (Supplement)
#
#   B. BALANCE OF PREDETERMINED CHARACTERISTICS IN EQUATION (3). Each cell share
#      of a maternal characteristic fixed before the delivery date is chosen is
#      put on the left of Equation (3). Coefficients are in standard deviations
#      of the birth-level indicator. CAUTION, stated in the note: scheduling itself
#      moves births across days, so a composition difference on the weekend is
#      what the hypothesis predicts, not only what selection would produce; the
#      table bounds how much composition the differential could be carrying, and
#      Table 2 column 2 already conditions on these shares.
#      -> tab_balance.tex (Supplement)
#
#   C. THE IDENTIFYING SAMPLE OF EQUATION (3). Only municipality-days on which both
#      sectors record a birth identify the differential. The table reports how
#      many municipalities and what share of each sector's births those days hold,
#      and re-estimates each sector's own gradient (Equation 2) on them.
#      -> tab_ident_sample.tex (Supplement)
#
# MEMORY: B and C load sinasc_births.parquet (a few columns). Do not run
# concurrently with 03, 05, 07, 08, 09 or 12.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
TABLE <- here::here("analysis", "output", "tables")

# =============================================================================
# A. Fees per hour of physician time
# =============================================================================
ev <- rbindlist(lapply(2015:2024, function(y)
  as.data.table(read_parquet(file.path(OUT, sprintf("delivery_events_%d.parquet", y)),
    col_select = c("type", "uf", "fee_delivery", "fee_assist", "assist_hours",
                   "fee_vaginal_econ")))))
# the same five states as the Section 5 facts in 02_regressions.R
big <- ev[, .N, by = uf][order(-N)][1:5, uf]

fee_hour <- function(d) {
  v  <- d[type == "vaginal"]
  va <- v[is.finite(fee_assist) & is.finite(assist_hours) & assist_hours > 0]
  fc <- mean(d[type == "cesarean", fee_delivery], na.rm = TRUE)
  fv <- mean(v$fee_vaginal_econ, na.rm = TRUE)
  # The economic vaginal fee is an EXPECTED fee: delivery fee plus the labor-
  # assistance fee, counted as zero where none is billed, averaged over every
  # vaginal delivery with a delivery fee. The split by whether labor assistance
  # is billed, and the delivery fee alone, are printed so the reader can see
  # that a vaginal delivery billing no labor hours pays less than a cesarean
  # (external check, 2026-09-28).
  ve <- v[is.finite(fee_vaginal_econ)]
  data.table(fc = fc, fb = mean(ve$fee_delivery), fv = fv,
             fvb = mean(ve[!is.na(fee_assist), fee_vaginal_econ]),
             fvn = mean(ve[is.na(fee_assist), fee_vaginal_econ]),
             bill = 100 * nrow(va) / nrow(v),
             hrs = mean(va$assist_hours), rate = mean(va$fee_assist / va$assist_hours),
             be1 = fv / fc, be2 = 2 * fv / fc)
}
fh <- rbind(cbind(uf = "Brazil", fee_hour(ev)),
            rbindlist(lapply(big, function(u) cbind(uf = u, fee_hour(ev[uf == u])))))
rm(ev); gc()
cat("\n[16A] fees per hour of physician time:\n"); print(fh)

rowf <- function(label, x, fmt) paste0(label, " & ", paste(sprintf(fmt, x), collapse = " & "), " \\\\")
rowm <- function(label, x) paste0(label, " & ",
  paste(formatC(round(x), big.mark = ",", format = "d"), collapse = " & "), " \\\\")
tex <- c("\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{Physician fees per delivery and per hour of physician time}}",
  "\\label{tab:fee_per_hour}",
  "\\small\\setlength{\\tabcolsep}{5pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  sprintf("\\begin{tabular}{l%s}", strrep("c", nrow(fh))), "\\toprule",
  paste0(" & ", paste(fh$uf, collapse = " & "), " \\\\"), "\\midrule",
  "\\multicolumn{7}{l}{\\emph{Panel A. Fees per delivery (R\\$)}} \\\\", "\\addlinespace[2pt]",
  rowm("Cesarean fee", fh$fc),
  rowm("Vaginal delivery fee alone", fh$fb),
  rowm("Economic vaginal fee, all vaginal deliveries", fh$fv),
  rowm("\\quad deliveries billing labor assistance", fh$fvb),
  rowm("\\quad deliveries billing none", fh$fvn),
  "\\midrule",
  "\\multicolumn{7}{l}{\\emph{Panel B. Labor assistance}} \\\\", "\\addlinespace[2pt]",
  rowf("Vaginal deliveries billing labor assistance (\\%)", fh$bill, "%.1f"),
  rowf("Billed hours, when billed", fh$hrs, "%.1f"),
  rowm("Fee per billed labor hour (R\\$)", fh$rate),
  "\\midrule",
  "\\multicolumn{7}{l}{\\emph{Panel C. Break-even physician time of a vaginal delivery (hours)}} \\\\",
  "\\addlinespace[2pt]",
  rowf("If a cesarean takes one hour", fh$be1, "%.2f"),
  rowf("If a cesarean takes two hours", fh$be2, "%.2f"),
  "\\bottomrule", "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} TISS private-insurance deliveries, 2015--2024; the five largest",
  "states by deliveries, as in Section~\\ref{sec:notprice}. Fees are means over the",
  "deliveries that bill them: the cesarean fee over cesareans with a positive",
  "delivery fee, the vaginal fees over vaginal deliveries with a positive delivery",
  "fee. The economic vaginal fee is, for each such delivery, the delivery fee plus",
  "the hourly labor-assistance fee billed with it, counted as zero where none is",
  "billed, averaged over all of them. It is the expected pay of a vaginal delivery",
  "when the mode of delivery is chosen, not the pay of a typical one: the two rows",
  "below it split it by whether labor assistance is billed, and a vaginal delivery",
  "that bills none pays less than a cesarean in Brazil as a whole. The fee per",
  "billed labor hour is the mean, over the deliveries that bill labor assistance, of",
  "that fee divided by its billed hours. Panel C reports the physician time of a",
  "vaginal delivery at which the economic vaginal fee per hour equals the cesarean",
  "fee per hour: the economic vaginal fee divided by the cesarean fee, times the",
  "hours of a cesarean. A vaginal delivery that occupies the physician for longer",
  "pays less per hour than a cesarean. Physician time is not observed; billed hours",
  "are a floor on it, since the vaginal deliveries that bill no labor hours still",
  sprintf("take time (%.0f percent of them nationally, between %.0f and %.0f percent in",
          100 - fh[uf == "Brazil", bill], 100 - max(fh[uf != "Brazil", bill]),
          100 - min(fh[uf != "Brazil", bill])),
  "the five states), so the comparison is tilted in favor of the vaginal delivery.",
  "\\end{minipage}", "\\end{table}")
write_table_tex(tex, file.path(TABLE, "tab_fee_per_hour.tex"))

# =============================================================================
# B and C share one read of the birth file and the cells of 07.
# =============================================================================
b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("muni", "date", "sector", "cesarean", "idade_mae", "escolaridade_mae",
                      "raca_cor_mae", "paridade", "quantidade_parto_cesareo",
                      "tipo_gravidez", "sexo", "consultas_prenatal_cat",
                      "mes_inicio_prenatal", "dow", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
b[, date := as.IDate(date)]
hol <- holiday_dates(2010:2024)
b[, `:=`(weekend = as.integer(dow %in% c(1, 7)), holiday = as.integer(date %in% hol))]
b[, eve := as.integer((date + 1L) %in% hol | dow == 6L)]
b[, private := as.integer(sector == "Private")]
b[, idade_mae := valid_idade(idade_mae)]
cat("\n[16B] paridade codes:\n"); print(b[, .N, by = paridade][order(paridade)])

# predetermined indicators; NA where the field is missing or ignored
b[, `:=`(
  x_age35  = fifelse(is.na(idade_mae), NA_integer_, as.integer(idade_mae >= 35)),
  x_age20  = fifelse(is.na(idade_mae), NA_integer_, as.integer(idade_mae < 20)),
  x_educ8  = fifelse(escolaridade_mae %in% 1:5, as.integer(escolaridade_mae %in% 4:5), NA_integer_),
  x_educ12 = fifelse(escolaridade_mae %in% 1:5, as.integer(escolaridade_mae == 5L), NA_integer_),
  x_white  = fifelse(raca_cor_mae %in% 1:5, as.integer(raca_cor_mae == 1L), NA_integer_),
  x_nullip = fifelse(paridade %in% 0:1, as.integer(paridade == 0L), NA_integer_),
  x_prevcs = fifelse(!is.na(quantidade_parto_cesareo) & quantidade_parto_cesareo < 99,
                     as.integer(quantidade_parto_cesareo >= 1), NA_integer_),
  x_multi  = fifelse(tipo_gravidez %in% 1:3, as.integer(tipo_gravidez %in% 2:3), NA_integer_),
  # DATASUS SEXO: 1 male, 2 female, 0/9 ignored (some years carry M/F)
  x_male   = fcase(sexo %in% c("1", "M"), 1L, sexo %in% c("2", "F"), 0L, default = NA_integer_),
  # CONSULTAS: 1 none, 2 1-3, 3 4-6, 4 7+ (9 ignored)
  x_prenat7 = fifelse(consultas_prenatal_cat %in% 1:4, as.integer(consultas_prenatal_cat == 4L), NA_integer_),
  x_prenat1t = fifelse(mes_inicio_prenatal %in% 1:9, as.integer(mes_inicio_prenatal <= 3L), NA_integer_))]
cat("\n[16B] sexo codes:\n"); print(b[, .N, by = sexo][order(-N)])
XV <- c(x_age35 = "Mother aged 35 or older", x_age20 = "Mother under 20",
        x_educ8 = "Mother has 8+ years of schooling", x_educ12 = "Mother has 12+ years of schooling",
        x_white = "Mother is white", x_nullip = "First birth",
        x_prevcs = "Previous cesarean", x_multi = "Multiple pregnancy",
        x_prenat1t = "Prenatal care began in the first trimester",
        x_prenat7 = "Seven or more prenatal visits", x_male = "Newborn is male")
sds   <- sapply(names(XV), function(v) sd(b[[v]], na.rm = TRUE))
sd_cs <- sd(b$cesarean)
means_fp <- sapply(names(XV), function(v) b[private == 1 & weekend == 0, mean(get(v), na.rm = TRUE)])

cells <- b[, c(list(births = .N, rate = mean(cesarean)),
               lapply(.SD, function(x) mean(x, na.rm = TRUE)),
               lapply(.SD, function(x) sum(!is.na(x)))),
           by = .(muni, date, sector, private, weekend, holiday, eve, year),
           .SDcols = names(XV)]
setnames(cells, (ncol(cells) - length(XV) + 1):ncol(cells), paste0("n_", names(XV)))

GRAD <- "i(private, weekend, ref = 0) + i(private, holiday, ref = 0) + i(private, eve, ref = 0)"
eq3 <- function(y, d, w = "births")
  feols(as.formula(paste(y, "~", GRAD, "| muni^date + muni^sector")), d,
        weights = as.formula(paste0("~", w)), cluster = ~muni + date)
KW <- "private::1:weekend"; KH <- "private::1:holiday"

bal <- rbindlist(lapply(names(XV), function(v) {
  d <- cells[get(paste0("n_", v)) > 0 & is.finite(get(v))]
  m <- eq3(v, d, paste0("n_", v))
  ct <- coeftable(m)
  data.table(v = v, mean = means_fp[[v]], sd = sds[[v]],
             bw = ct[KW, 1], sw = ct[KW, 2], pw = ct[KW, 4],
             bh = ct[KH, 1], sh = ct[KH, 2], ph = ct[KH, 4], n = nobs(m))
}))
m_cs <- eq3("rate", cells)
ctc <- coeftable(m_cs)
bal <- rbind(bal, data.table(v = "cesarean", mean = b[private == 1 & weekend == 0, mean(cesarean)],
  sd = sd_cs, bw = ctc[KW, 1], sw = ctc[KW, 2], pw = ctc[KW, 4],
  bh = ctc[KH, 1], sh = ctc[KH, 2], ph = ctc[KH, 4], n = nobs(m_cs)))
cat("\n[16B] balance, Equation (3), in SD units:\n")
print(bal[, .(v, mean = round(mean, 3), w_sd = round(bw / sd, 4), w_se = round(sw / sd, 4),
              h_sd = round(bh / sd, 4), h_se = round(sh / sd, 4), n)])

star <- function(p) if (p < 0.01) "$^{***}$" else if (p < 0.05) "$^{**}$" else if (p < 0.10) "$^{*}$" else ""
brow <- function(lab, r) c(
  sprintf("%s & %.3f & %.4f%s & %.4f%s \\\\", lab, r$mean, r$bw / r$sd, star(r$pw), r$bh / r$sd, star(r$ph)),
  sprintf(" & & (%.4f) & (%.4f) \\\\", r$sw / r$sd, r$sh / r$sd), "\\addlinespace[2pt]")
body <- unlist(lapply(seq_len(nrow(bal) - 1L), function(i) brow(XV[[bal$v[i]]], bal[i])))
tex <- c("\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{Predetermined maternal characteristics in the within-municipality-day comparison}}",
  "\\label{tab:balance}",
  "\\small\\setlength{\\tabcolsep}{5pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "\\begin{tabular}{lccc}", "\\toprule",
  " & Mean, for-profit & For-profit $\\times$ & For-profit $\\times$ \\\\",
  " & weekdays & Weekend & National holiday \\\\", "\\midrule",
  "\\multicolumn{4}{l}{\\emph{Panel A. Predetermined characteristics (standard deviations)}} \\\\",
  "\\addlinespace[2pt]", body, "\\midrule",
  "\\multicolumn{4}{l}{\\emph{Panel B. Benchmark: the outcome of Table~\\ref{tab:main_gradient}, column 1 (standard deviations)}} \\\\",
  "\\addlinespace[2pt]", brow("Cesarean", bal[.N]),
  "\\bottomrule", "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} SINASC 2010--2024, for-profit and public municipality-date cells.",
  "Each row estimates Equation~\\eqref{eq:gradient} with the cell share of the",
  "characteristic as the outcome, municipality$\\times$date and",
  "municipality$\\times$sector fixed effects, and the eve-of-rest-day interaction;",
  "cells are weighted by the births with the field recorded (maternal race and the",
  "month prenatal care began are sparsely recorded in 2010--2011). Coefficients are divided by the",
  "standard deviation of the birth-level indicator, so Panel B puts the cesarean",
  "differential on the same scale. The first column is the share among for-profit",
  "births on weekdays. The characteristics are fixed before the delivery date is",
  "chosen (the count of prenatal visits only partly, since a pregnancy delivered",
  "earlier has had less time to accumulate visits), but the set of women delivering",
  "on a given day is not: scheduling moves",
  "births off weekends, so a weekend composition difference is predicted by the",
  "scheduling hypothesis as well as by selection. The table therefore measures how",
  "much composition the differential could carry, not whether mothers are",
  "comparable across days. The sex of the newborn is the exception: scheduling",
  "cannot sort on it, so it is a placebo outcome. Table~\\ref{tab:main_gradient},",
  "column 2, conditions on the cell shares of age, schooling, race, and parity.",
  "Standard errors, two-way clustered by municipality and date, are reported in parentheses.",
  "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
write_table_tex(tex, file.path(TABLE, "tab_balance.tex"))

# =============================================================================
# C. The identifying sample of Equation (3)
# =============================================================================
both <- cells[, .(both = uniqueN(private) == 2L), by = .(muni, date)]
cells <- merge(cells, both, by = c("muni", "date"))
cov <- cells[, .(births = sum(births)), by = .(private, both)]
share_fp  <- 100 * cov[private == 1 & both == TRUE, births] / cov[private == 1, sum(births)]
share_pub <- 100 * cov[private == 0 & both == TRUE, births] / cov[private == 0, sum(births)]
n_muni_both <- cells[both == TRUE, uniqueN(muni)]
n_muni_fp   <- cells[private == 1, uniqueN(muni)]
n_muni_all  <- cells[, uniqueN(muni)]
# a municipality-day with one sector only carries no information on gamma: the
# estimate on the identifying cells must equal the full-sample estimate
m_full <- m_cs
m_id   <- eq3("rate", cells[both == TRUE])
stopifnot(abs(coef(m_full)[KW] - coef(m_id)[KW]) < 1e-6)

own <- function(p, d) feols(rate ~ weekend + holiday + eve | muni + year, d[private == p],
                            weights = ~births, cluster = ~muni + date)
OWN <- list(own(1, cells), own(1, cells[both == TRUE]), own(0, cells), own(0, cells[both == TRUE]))
cat(sprintf("\n[16C] munis with both sectors on some day: %d of %d with a for-profit birth (%d in all);",
            n_muni_both, n_muni_fp, n_muni_all))
cat(sprintf(" births on identifying days: for-profit %.1f%%, public %.1f%%\n", share_fp, share_pub))
print(etable(OWN, digits = 4))

tex <- c("\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{The sample that identifies the within-municipality-day differential}}",
  "\\label{tab:ident_sample}",
  "\\small\\setlength{\\tabcolsep}{5pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "\\begin{tabular}{lcccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & \\multicolumn{2}{c}{For-profit} & \\multicolumn{2}{c}{Public} \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}",
  " & All days & Identifying days & All days & Identifying days \\\\", "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel A. Coverage}} \\\\", "\\addlinespace[2pt]",
  sprintf("Share of the sector's births (\\%%) & 100.0 & %.1f & 100.0 & %.1f \\\\", share_fp, share_pub),
  sprintf("Municipalities & %s & %s & %s & %s \\\\",
          format(n_muni_fp, big.mark = ","), format(n_muni_both, big.mark = ","),
          format(cells[private == 0, uniqueN(muni)], big.mark = ","), format(n_muni_both, big.mark = ",")),
  "\\midrule",
  "\\multicolumn{5}{l}{\\emph{Panel B. Each sector's own gradient, Equation~\\eqref{eq:scheduling} (percentage points)}} \\\\",
  "\\addlinespace[2pt]",
  tex_row("Weekend", OWN, "weekend", dig = 2),
  tex_row("National holiday", OWN, "holiday", dig = 2),
  tex_row("Eve of rest day", OWN, "eve", dig = 2),
  tex_nobs(OWN),
  "\\bottomrule", "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} SINASC 2010--2024, municipality-date cells by sector, weighted by",
  "births. Identifying days are the municipality-days on which both sectors record at",
  "least one birth; with municipality$\\times$date fixed effects, only these days",
  "contribute to the for-profit differential of Equation~\\eqref{eq:gradient}, and",
  "re-estimating it on them reproduces Table~\\ref{tab:main_gradient}, column 1,",
  "exactly. Municipalities counts those with at least one birth in the sector",
  "(columns 1 and 3) and those with at least one identifying day (columns 2 and 4).",
  "Standard errors, two-way clustered by municipality and date, are reported in parentheses.",
  "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
write_table_tex(tex, file.path(TABLE, "tab_ident_sample.tex"))
message("16_design_checks.R done")
