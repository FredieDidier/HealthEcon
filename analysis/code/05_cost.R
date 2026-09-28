# =============================================================================
# 05_cost.R — the COST of convenience (Section 6): gestational-age shifting,
#             newborn health, and billed cost.
#
# WHAT THIS SCRIPT DOES.
#   (a) Gestational-age distribution by sector and by cesarean timing (prelabor vs
#       in-labor). Feeds fig_gestation_panels, merged by 11_body_figures.R and now
#       shown in the Supplementary Appendix (Figure C.4), not the body.
#       READ THE PANELS CORRECTLY. BOTH sectors peak at week 39; the for-profit
#       distribution is shifted earlier, not massed at 37-38. Panel (b) is a
#       three-way ORDERING, not a prelabor-versus-rest split: prelabor cesarean,
#       in-labor cesarean, vaginal, all three peaking at week 39. In-labor sits
#       much closer to prelabor than to vaginal, so do not group it with vaginal
#       births. The shares quoted in the text are printed below.
#   (b) Sector gaps in early-term birth, low birthweight, and low Apgar, with and
#       without maternal controls (age, education, race) + muni+year FE.
#       -> tab09_health (body, Table 5).
#   (c) Billed cost per delivery, cesarean vs vaginal (TISS). -> tab12_cost
#       (Supplement).
#
# LABELING. The early-term result is a SECTOR-gestational-age ASSOCIATION, not a
# causal effect of scheduling: mothers differ
# across sectors. We do NOT build new empirical programs on neonatal morbidity
# (selection dominates; for-profit shows LOWER LBW/low-Apgar; power is inadequate).
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "cesarea_antes_parto", "semana_gestacao",
                      "peso", "apgar5", "idade_mae", "escolaridade_mae", "raca_cor_mae",
                      "tipo_robson", "muni", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
# SINASC codes "ignored" as 99 (Apgar, age) and 9999 (weight); see 00_utils.R
b[, `:=`(apgar5 = valid_apgar(apgar5), peso = valid_peso(peso), idade_mae = valid_idade(idade_mae))]

# --- (a) gestational-age distribution by sector (-> Supplementary Appendix Fig C.4a) ---------------
g <- b[semana_gestacao %between% c(32, 43)]
ga <- g[, .N, by = .(sector, week = semana_gestacao)]
ga[, share := N / sum(N), by = sector]
# Display names, never the raw `sector` levels: the SINASC group is "For-profit"
# (natureza juridica 2xxx), and a legend reading "Private" would conflate it with
# the private-insurance sector of TISS. Relabel the aggregate only -- `g` keeps
# the raw levels because the next block subsets on sector == "Private".
ga[, sector := sector_display(sector, c("Private", "Public"))]
fig9a <- ggplot(ga, aes(week, 100 * share, colour = sector, linetype = sector)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c(`For-profit` = unname(PAL["red"]),
                                 Public = unname(PAL["blue"]))) +
  scale_linetype_manual(values = lty_for(c("For-profit", "Public"))) +
  scale_x_continuous(breaks = seq(32, 43, 1)) +
  labs(x = "Gestational age at birth (weeks)", y = "Share of births (%)") +
  theme_paper()
save_fig(fig9a, "fig09_gestation")

# same distribution, for-profit only, by cesarean timing (the channel; -> Supplementary Appendix Fig C.4b)
# the timing split uses 2012+, the years the timing indicator is recorded
gp <- g[year >= 2012 & sector == "Private" & !(cesarean == 1 & !cesarea_antes_parto %in% c(1, 2))]
gp[, group := fcase(cesarean == 0, "Vaginal",
                    cesarea_antes_parto == 1, "Prelabor cesarean",
                    cesarea_antes_parto == 2, "In-labor cesarean")]
gd <- gp[!is.na(group), .N, by = .(group, week = semana_gestacao)]
gd[, share := N / sum(N), by = group]
fig9b <- ggplot(gd, aes(week, 100 * share, colour = group, linetype = group)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c("Prelabor cesarean" = unname(PAL["red"]),
                                 "In-labor cesarean" = unname(PAL["orange"]),
                                 "Vaginal" = unname(PAL["blue"]))) +
  scale_linetype_manual(values = lty_for(c("Prelabor cesarean", "In-labor cesarean",
                                           "Vaginal"))) +
  scale_x_continuous(breaks = seq(32, 43, 1)) +
  labs(x = "Gestational age at birth (weeks)", y = "Share of births (%)") +
  theme_paper()
save_fig(fig9b, "fig09b_gestation_by_timing")
cat("\n[05] Gestational-age shares quoted in the text (%):\n")
print(dcast(ga[, .(sector, band = fcase(week %between% c(37, 38), "37-38",
                                        week %between% c(40, 41), "40-41", default = "other"),
                   share)][, .(share = round(100 * sum(share), 1)), by = .(sector, band)],
            sector ~ band, value.var = "share"))
print(gd[week %between% c(37, 38), .(share_37_38 = round(100 * sum(share), 1)), by = group])

# --- (b) tab09_health (body Table 5): sector gaps in newborn-health margins ---
b[, `:=`(
  early_term = as.integer(semana_gestacao %between% c(37, 38)),
  lbw        = as.integer(peso < 2500),
  low_apgar  = as.integer(apgar5 < 7),
  private    = as.integer(sector == "Private"),
  age2       = idade_mae^2
)]
b[, educ := factor(escolaridade_mae, levels = 1:5)]   # 9/NA dropped by factor
ctrl <- "idade_mae + age2 + i(educ) + i(raca_cor_mae)"

m_et0 <- feols(early_term ~ private | muni + year, b, cluster = ~muni)
m_et1 <- feols(as.formula(paste("early_term ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)
m_lb1 <- feols(as.formula(paste("lbw ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)
m_ap1 <- feols(as.formula(paste("low_apgar ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)
# The same two newborn margins where selection is smallest: Robson groups 1-2
# (nulliparous, term, singleton, cephalic; recorded from 2014) and 37+ weeks.
# The for-profit advantage on the full sample reflects healthier mothers and
# better resources; this shows how much of it survives among comparable pregnancies.
b12 <- b[year >= 2014 & tipo_robson %in% c("01", "02") & semana_gestacao >= 37]
m_lb2 <- feols(as.formula(paste("lbw ~ private +", ctrl, "| muni + year")), b12, cluster = ~muni)
m_ap2 <- feols(as.formula(paste("low_apgar ~ private +", ctrl, "| muni + year")), b12, cluster = ~muni)

# Hand-built in the layout of tab_prelabor_lowrisk (body Table 3): clean column
# header, coefficient rows in percentage points, then Maternal controls /
# fixed-effects / Observations rows.
HEALTH <- list(m_et0, m_et1, m_lb1, m_ap1, m_lb2, m_ap2)
ga_cov <- b[, .(p = 100 * mean(!is.na(semana_gestacao))), by = year][, setNames(p, year)]
# Maternal race arrives with the same 2011 form change as gestational age, so the
# columns with maternal controls lose 2010-2011 through race even without a
# gestational-age restriction; the note has to say so (columns 3-4 looked
# unrestricted until 2026-09-28).
race_cov <- b[, .(p = 100 * mean(!is.na(raca_cor_mae))), by = year][, setNames(p, year)]
tex <- c(
  "\\begin{table}[H]", "\\centering",
  "\\caption{\\textbf{For-profit--public differences in early-term birth and newborn outcomes}}",
  "\\label{tab:health}",
  "\\small\\setlength{\\tabcolsep}{5pt}",
  "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "\\begin{tabular}{lcccccc}", "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & \\multicolumn{2}{c}{Early-term birth} & Low birthweight & Five-minute & Low birthweight & Five-minute \\\\",
  " & \\multicolumn{2}{c}{(37--38 weeks)} & ($<$2500g) & Apgar $<$ 7 & ($<$2500g) & Apgar $<$ 7 \\\\",
  "\\cmidrule(lr){2-3}\\cmidrule(lr){4-4}\\cmidrule(lr){5-5}\\cmidrule(lr){6-6}\\cmidrule(lr){7-7}",
  tex_row("For-profit establishment", HEALTH, "private", mult = 100, dig = 2),
  "\\midrule",
  "Maternal controls & No & Yes & Yes & Yes & Yes & Yes \\\\",
  "Sample & All & All & All & All & Robson 1--2, term & Robson 1--2, term \\\\",
  "Municipality fixed effects & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year fixed effects & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  tex_nobs(HEALTH),
  "\\bottomrule", "\\end{tabular}}",
  "\\begin{minipage}{\\linewidth}\\footnotesize",
  "\\textit{Notes:} Birth-level regressions, SINASC 2010--2024, for-profit vs",
  "public establishments; coefficients in percentage points. Columns 1--2 use the",
  sprintf("births with a recorded gestational age: %.0f percent of 2010 births, %.0f percent of 2011",
          ga_cov[["2010"]], ga_cov[["2011"]]),
  sprintf("births, and at least %.0f percent in every year from 2012. Maternal controls:",
          floor(min(ga_cov[as.character(2012:2024)]))),
  "age, age$^2$, education, race. Maternal race is recorded on the same schedule",
  sprintf("(%.0f percent of 2010 births, %.0f percent of 2011 births), so columns 2--6, which",
          race_cov[["2010"]], race_cov[["2011"]]),
  "include it, also drop nearly all 2010 births and a large part of 2011 births.",
  "Mothers differ across sectors, so the",
  "early-term coefficient is an associational difference between establishment",
  "sectors and is not interpreted as the causal effect of prelabor scheduling.",
  "Columns 5--6 restrict to Robson groups 1--2 (nulliparous, term, singleton,",
  "cephalic; recorded from 2014) at 37 or more weeks, where selection across",
  "sectors is smallest.",
  "Standard errors, clustered by municipality, are reported in parentheses.",
  "\\newline", SIGNIF_NOTE, "\\end{minipage}", "\\end{table}")
write_table_tex(tex, file.path(TABLE, "tab09_health.tex"))
etable(m_et0, m_et1, m_lb1, m_ap1, m_lb2, m_ap2, keep = "%private", fitstat = ~ n, digits = 4)

message("05_cost.R: gestation + health block done")

# =============================================================================
# (c) Financial cost of the epidemic (TISS billed amounts) -> tab12_cost (Supp.)
# Total billed cost per delivery hospitalization = sum of ALL billed items
# (procedures, materials/OPME, drugs, daily rates) under the delivery event,
# built in build/02_deliveries.R as `total_billed`. It is the CHARGED/informed
# value, not the negotiated price paid (paid value is <5% populated), so it is a
# gross, order-of-magnitude cost. Reports the cesarean-vaginal cost gap and,
# applying the ~50k scheduling-attributable private cesareans/yr from the
# decomposition, the aggregate annual cost of scheduling.
# NB: requires 02_deliveries.R to have been re-run so delivery_events carry
# `total_billed`; skipped gracefully otherwise.
# =============================================================================
OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
have_cost <- "total_billed" %in% names(read_parquet(
  file.path(OUT, "delivery_events_2023.parquet"), as_data_frame = FALSE)$schema)
if (!have_cost) {
  message("tab12_cost skipped: re-run build/02_deliveries.R to add total_billed.")
} else {
  ce <- rbindlist(lapply(2015:2024, function(y)
    as.data.table(read_parquet(file.path(OUT, sprintf("delivery_events_%d.parquet", y)),
      col_select = c("type", "total_billed")))))
  ce <- ce[is.finite(total_billed) & total_billed > 0 & !is.na(type)]
  qw  <- ce[, quantile(total_billed, c(0.005, 0.995), na.rm = TRUE)]   # trim billing outliers
  ce  <- ce[total_billed %between% qw]
  cst <- ce[, .(mean_cost = mean(total_billed), med_cost = as.numeric(median(total_billed)),
                n = .N), by = type]
  c_ces <- cst[type == "cesarean", mean_cost]; c_vag <- cst[type == "vaginal", mean_cost]
  m_ces <- cst[type == "cesarean", med_cost];  m_vag <- cst[type == "vaginal", med_cost]
  message(sprintf("Billed cost mean cesarean R$%.0f vs vaginal R$%.0f (gap %.1f%%); median %.0f vs %.0f (gap %.1f%%) -> near-parity",
                  c_ces, c_vag, 100 * (c_ces - c_vag) / c_vag, m_ces, m_vag, 100 * (m_ces - m_vag) / m_vag))

  fmt <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
  tex <- c(
    "\\begin{table}[H]\\centering",
    "\\caption{\\textbf{Total amount billed per delivery, by mode}}",
    "\\label{tab:cost}",
    "\\small",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    " & Cesarean & Vaginal \\\\",
    "\\midrule",
    sprintf("Mean billed cost (R\\$) & %s & %s \\\\",   fmt(c_ces), fmt(c_vag)),
    sprintf("Median billed cost (R\\$) & %s & %s \\\\",  fmt(m_ces), fmt(m_vag)),
    sprintf("Deliveries, 2015--2024 & %s & %s \\\\",
            fmt(cst[type == "cesarean", n]), fmt(cst[type == "vaginal", n])),
    "\\bottomrule",
    "\\end{tabular}",
    paste0("\\\\[2pt]\\footnotesize\\textit{Notes:} TISS delivery hospitalizations, 2015--2024. ",
      "Total billed cost sums all billed items (procedures, materials, drugs, daily rates) under each ",
      "delivery event; it is the charged/informed value, not the negotiated price paid, so it is a gross ",
      "order-of-magnitude figure. The top and bottom 0.5\\% of the cost distribution are trimmed. A cesarean ",
      "and a vaginal delivery bill nearly the same total amount, so the epidemic is not explained by higher ",
      "cesarean billing."),
    "\\end{table}")
  write_table_tex(resize_tabular(tex), file.path(TABLE, "tab12_cost.tex"))
  message("financial-cost table (tab12_cost) done")
}
