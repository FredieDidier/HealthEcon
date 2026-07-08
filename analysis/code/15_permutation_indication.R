# =============================================================================
# 15_permutation_indication.R
#   (a) RANDOMIZATION INFERENCE for the weekend dip. Day-of-week is discrete, so
#       we enumerate ALL 21 two-day "pseudo rest-day" pairs and re-estimate the
#       private cesarean dip for each. The true weekend (Sat+Sun) should be the
#       most negative; the exact permutation p-value is its rank among the 21.
#   (b) DESCRIPTIVE: share of private cesareans with NO recorded clinical
#       indication (primary diagnosis is a delivery-outcome ICD-10 code O80-O84,
#       or blank, rather than a recognized cesarean indication). Coding is
#       imperfect, so this is descriptive, not a clean "avoidable" count.
#   Table 15 → tab15_permutation ; tab15b_no_indication
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
TABLE <- here::here("analysis", "output", "tables")

# --- (a) exact 2-day permutation of the weekend dip ---------------------------
b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "dow", "muni", "date", "year")))
b <- b[year <= 2024 & sector == "Private"]
md <- b[, .(ces = sum(cesarean), n = .N), by = .(muni, date, year, dow)]

combos <- combn(7L, 2L)                                   # 21 unordered pairs
res <- rbindlist(lapply(seq_len(ncol(combos)), function(j) {
  days <- combos[, j]
  md[, pw := as.integer(dow %in% days)]
  cell <- md[, .(rate = sum(ces) / sum(n), n = sum(n)), by = .(muni, date, pw, year)]
  m <- feols(rate ~ pw | muni + year, cell, weights = ~n)
  data.table(days = paste(c("Sun","Mon","Tue","Wed","Thu","Fri","Sat")[days], collapse = "+"),
             coef = 100 * coef(m)[["pw"]])
}))
res <- res[order(coef)]
obs <- res[days == "Sun+Sat", coef]
pval <- mean(res$coef <= obs)
cat(sprintf("\nTrue weekend (Sun+Sat) dip = %.2f pp; rank %d/21; exact permutation p = %.3f\n",
            obs, which(res$days == "Sun+Sat"), pval))
print(res)

tex <- c("\\begin{table}[H]\\centering",
  "\\caption{Randomization inference: the weekend dip across all 21 two-day placebos}",
  "\\label{tab:permutation}\\small",
  "\\begin{tabular}{lc}", "\\toprule",
  "Pseudo rest-day pair & Private cesarean dip (pp) \\\\", "\\midrule",
  res[, sprintf("%s%s & %.2f \\\\", days, ifelse(days == "Sun+Sat", " (true weekend)", ""), coef)],
  "\\bottomrule", "\\end{tabular}",
  sprintf("\\\\[2pt]\\footnotesize\\textit{Notes:} Each row re-estimates the private cesarean dip treating a different pair of weekdays as the ``rest days'' (SINASC 2010--2024, municipality-date cells, municipality and year fixed effects, weighted by births). The true weekend (Sun+Sat) is the most negative of all 21 placebos; exact permutation $p = %.3f$.", pval),
  "\\end{table}")
writeLines(tex, file.path(TABLE, "tab15_permutation.tex"))

# --- (b) private cesareans with no recorded clinical indication ---------------
# ICD-10 3-char prefixes that RECORD a cesarean-relevant indication:
IND <- c("O30","O31","O32","O33","O34","O35","O36","O40","O41","O42","O43","O44",
         "O45","O46","O47","O48","O60","O61","O62","O63","O64","O65","O66","O67",
         "O68","O69","O71","O75","P01","P02","P03","P05","P07","P20","P95")
ev <- rbindlist(lapply(2015:2024, function(y)
  as.data.table(read_parquet(file.path(OUT, sprintf("delivery_events_%d.parquet", y)),
    col_select = c("type", "cid_1", "year")))))
ces <- ev[type == "cesarean"]
ces[, cid3 := toupper(substr(cid_1, 1, 3))]
ces[, no_indication := as.integer(is.na(cid_1) | cid_1 == "" |
                                  cid3 %in% c("O80","O81","O82","O83","O84") |
                                  !(cid3 %in% IND))]
byyr <- ces[, .(no_indication_pct = round(100 * mean(no_indication), 1), n = .N), by = year][order(year)]
cat("\nPrivate cesareans with NO recorded clinical indication (primary CID), by year:\n")
print(byyr)

tex2 <- c("\\begin{table}[H]\\centering",
  "\\caption{Private cesareans with no recorded clinical indication}",
  "\\label{tab:no_indication}\\small",
  "\\begin{tabular}{cc}", "\\toprule",
  "Year & Share with no indication ICD-10 code (\\%) \\\\", "\\midrule",
  byyr[, sprintf("%d & %.1f \\\\", year, no_indication_pct)],
  "\\bottomrule", "\\end{tabular}",
  "\\\\[2pt]\\footnotesize\\textit{Notes:} TISS private cesarean deliveries, 2015--2024. A delivery is coded ``no indication'' when the primary diagnosis (ICD-10 code) is a delivery-outcome code (O80--O84) or blank, rather than an ICD-10 code recording a recognized cesarean indication (malpresentation, disproportion, placental or fetal complications, obstructed labor, etc.). Diagnosis coding in claims is incomplete, so this describes recorded indications, not clinical necessity.",
  "\\end{table}")
writeLines(tex2, file.path(TABLE, "tab15b_no_indication.tex"))

message("15_permutation_indication.R done")
