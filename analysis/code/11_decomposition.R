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
  "\\caption{Decomposing the private--public cesarean gap (Kitagawa, Robson groups)}",
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
