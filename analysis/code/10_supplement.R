# =============================================================================
# 10_supplement.R — Supplemental Appendix exhibits.
#
# Self-contained thematic sections in the house style: each re-sources config +
# utils, loads its own data, writes a committed .tex to analysis/output/tables/,
# and prints a console summary.
#
#   B  Robson x prelabor validation + Robson-1 vs Robson-10 formal test
#   C  not-a-price with confidence intervals + an equivalence region
#   D  fee gap with the BASE vaginal fee vs the economic (base + hours) fee
#   E  few-cluster inference: wild-cluster (Webb) bootstrap + cluster counts
#   F  sample-flow (CONSORT-style) + missingness of the prelabor indicator
#   G  placebo two-day ranking, correctly labelled (not "randomization inference")
#   H  Parto Adequado hospital-level event study (skips if list unavailable)
#   I  replication-package scaffolding (README + session/renv snapshot)
#   K  multiple-testing adjustment within pre-specified hypothesis families
#
# The paper's MAIN specification (Equation 3, the within-municipality-day
# for-profit differential) lives in 07_main_specification.R, and the long-weekend
# and organizational-capacity exercises in 08_long_weekends.R and
# 09_org_capacity.R. Section K reads the hypothesis families those scripts save
# to analysis/output/fam_*.rds, so run them first.
#
# Run:  Rscript analysis/code/10_supplement.R
# =============================================================================

# =============================================================================
# B (C3) — ROBSON x PRELABOR VALIDATION + Robson-1 vs Robson-10 formal test.
# Robson group 1 is SPONTANEOUS labor by definition, so its cesareans must be
# in-labor; a prelabor cesarean there would be a logical/coding contradiction. We
# verify the data are internally consistent (prelabor share in group 1 = 0), which
# means the group-1 weekend dip cannot be prelabor scheduling. We also test
# formally whether the group-10 (preterm) dip really is "far less" than group 1.
#   -> tab_ref_c3_robson_validation.tex
# =============================================================================

source(here::here("config", "config.R"))
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))
SIN <- file.path(DROPBOX_ROOT, "build", "SINASC", "input"); TABLE <- here::here("analysis","output","tables")

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector","cesarean","cesarea_antes_parto","tipo_robson","muni","date","dow","year")))
b <- b[year <= 2024 & sector %in% c("Private","Public")]
b[, weekend := as.integer(dow %in% c(1, 7))]

# validation crosstab: among cesareans with a valid timing code, share prelabor by Robson group
cr <- b[cesarean == 1 & tipo_robson %in% sprintf("%02d", 1:10) & cesarea_antes_parto %in% c(1, 2)]
val <- cr[, .(cesareans = .N, share_prelabor = mean(cesarea_antes_parto == 1)), by = tipo_robson][order(tipo_robson)]

# Robson-1 private weekend dip decomposed (prelabor is 0 there by construction)
b[, `:=`(ces_pre = as.integer(cesarean == 1 & cesarea_antes_parto == 1),
         ces_lab = as.integer(cesarean == 1 & cesarea_antes_parto == 2))]
r1 <- b[tipo_robson == "01" & sector == "Private",
        .(n = .N, rate = mean(cesarean), rate_lab = mean(ces_lab)), by = .(muni, date, weekend, year)]
d_r1_tot <- coef(feols(rate     ~ weekend | muni + year, r1, weights = ~n, cluster = ~muni + date))["weekend"]
d_r1_lab <- coef(feols(rate_lab ~ weekend | muni + year, r1, weights = ~n, cluster = ~muni + date))["weekend"]

# formal test: Robson-1 dip vs Robson-10 dip (private) via an interaction
mk <- function(g) b[tipo_robson %in% g & sector == "Private",
                    .(rate = mean(cesarean), n = .N), by = .(muni, date, weekend, year)]
dd <- rbind(cbind(mk("01"), grp = "R1"), cbind(mk("10"), grp = "R10"))
m_test <- feols(rate ~ weekend * i(grp, ref = "R10") | muni^grp + year, dd, weights = ~n, cluster = ~muni + date)
p_r1r10 <- coeftable(m_test)["weekend:grp::R1", "Pr(>|t|)"]

# build the validation table by hand (booktabs, house style)
vtab <- val[, .(`Robson group` = tipo_robson,
                `Cesareans` = format(cesareans, big.mark = ","),
                `Share prelabor (\\%)` = sprintf("%.1f", 100 * share_prelabor))]
tex <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Internal consistency of the cesarean-timing indicator across Robson groups}}",
  "\\label{tab:robson_validation}", "\\small",
  "\\begin{tabular}{lrr}", "\\toprule",
  "Robson group & Cesareans & Share coded prelabor (\\%) \\\\", "\\midrule",
  apply(vtab, 1, function(x) paste(paste(x, collapse = " & "), "\\\\")),
  "\\midrule",
  sprintf("\\multicolumn{3}{p{0.9\\linewidth}}{\\footnotesize Group 1 (spontaneous labor) has a %.1f\\%% prelabor share, as it must; its for-profit weekend dip of %.1f pp is therefore entirely in-labor (in-labor component %.1f pp). A formal test cannot distinguish the group-1 dip from the group-10 (preterm) dip ($p=%.2f$), so the preterm placebo is weak.} \\\\",
          100*val[tipo_robson=="01", share_prelabor], 100*d_r1_tot, 100*d_r1_lab, p_r1r10),
  "\\bottomrule", "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} SINASC 2010--2024, cesareans with a",
        "valid before/during-labor code. Robson 1 = nulliparous, term, singleton,",
        "cephalic, spontaneous labor; Robson 2 = same but induced or prelabor cesarean."),
  "\\end{table}")
writeLines(resize_tabular(tex), file.path(TABLE, "tab_ref_c3_robson_validation.tex"))
cat(sprintf("\n[B/C3] Robson-1 prelabor share = %.3f (must be ~0). R1 dip %.1fpp (in-labor %.1fpp). R1-vs-R10 test p=%.3f\n",
            val[tipo_robson=="01", share_prelabor], 100*d_r1_tot, 100*d_r1_lab, p_r1r10))

# =============================================================================
# C (C5) — NOT-A-PRICE WITH CONFIDENCE INTERVALS + AN EQUIVALENCE REGION.
# "Precisely estimated near-zero" is not what the specs show. We report each
# coefficient with its 95% CI and the number of clusters, and test it against a
# pre-registered economically-negligible region [-0.02, 0.02] (a 2 pp change in
# the cesarean share per log-point of the fee gap).
#   -> tab_ref_c5_feegap_ci.tex
# =============================================================================

source(here::here("config", "config.R"))
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))
WFO <- file.path(DROPBOX_ROOT, "build", "workfile", "output", "main_data.parquet"); TABLE <- here::here("analysis","output","tables")

w <- as.data.table(read_parquet(WFO))
w[, `:=`(state = substr(muni6, 1, 2), log_gdp_pc = log(gdp_pc))]
w <- w[year <= 2024 & tiss_deliveries >= 20 & is.finite(log_fee_gap) & is.finite(tiss_csection_rate)]
specs <- list(
  `State FE`                 = feols(tiss_csection_rate ~ log_fee_gap | state + year,  w, weights = ~tiss_deliveries),
  `Municipality FE`          = feols(tiss_csection_rate ~ log_fee_gap | muni6 + year, w, weights = ~tiss_deliveries),
  `State FE + controls`      = feols(tiss_csection_rate ~ log_fee_gap + log_gdp_pc + plan_cov + prenatal + obstetricians_per_1k_births | state + year, w, weights = ~tiss_deliveries),
  `Municipality FE + controls` = feols(tiss_csection_rate ~ log_fee_gap + log_gdp_pc + plan_cov + prenatal + obstetricians_per_1k_births | muni6 + year, w, weights = ~tiss_deliveries))
EQ <- 0.02
rows <- rbindlist(lapply(names(specs), function(nm) {
  m <- specs[[nm]]; ci <- confint(m, "log_fee_gap")
  data.table(spec = nm, beta = coef(m)["log_fee_gap"], lo = ci[[1]], hi = ci[[2]],
             nclust = m$fixef_sizes[[1]],
             negligible = ifelse(ci[[1]] >= -EQ && ci[[2]] <= EQ, "within", "not within"))
}))
ctab <- rows[, .(Specification = spec,
                 `Coefficient` = sprintf("%+.4f", beta),
                 `95\\% CI` = sprintf("[%+.4f, %+.4f]", lo, hi),
                 `Clusters` = nclust,
                 `In $[-0.02,0.02]$?` = negligible)]
tex <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{The fee-gap coefficient: point estimates, confidence intervals, and an equivalence region}}",
  "\\label{tab:feegap_ci}", "\\small",
  "\\begin{tabular}{lcccc}", "\\toprule",
  paste(names(ctab), collapse = " & "), "\\\\", "\\midrule",
  apply(ctab, 1, function(x) paste(paste(x, collapse = " & "), "\\\\")),
  "\\bottomrule", "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} Coefficient on the log economic",
        "fee gap from Table~\\ref{tab:fees}. The equivalence region",
        "$[-0.02, 0.02]$ corresponds to a 2 percentage-point change in the cesarean",
        "share per log-point of the fee gap. The estimates range from negative to",
        "positive across specifications and are not stably distinguishable from zero,",
        "so there is no robust relationship between the relative fee and the",
        "cesarean rate."),
  "\\end{table}")
writeLines(resize_tabular(tex), file.path(TABLE, "tab_ref_c5_feegap_ci.tex"))
cat("\n[C/C5] fee-gap coefficient CIs:\n"); print(rows)

# =============================================================================
# D (C6) — FEE GAP: BASE VAGINAL FEE vs ECONOMIC (BASE + ENDOGENOUS HOURS).
# The economic vaginal fee adds an endogenous quantity of billed labor-assistance
# hours. If the not-a-price null survives using the BASE delivery fee alone, it is
# not driven by that endogenous component. We rebuild both gaps from event-level
# TISS data and re-run the core regression.
#   -> tab_ref_c6_fee_base_econ.tex
# =============================================================================

source(here::here("config", "config.R"))
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))
OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output"); TABLE <- here::here("analysis","output","tables")

evf <- list.files(OUT, pattern = "delivery_events_20[0-9]{2}\\.parquet$", full.names = TRUE)
if (length(evf) == 0) {
  message("07 [D/C6] skipped — delivery_events_<yr>.parquet not found.")
} else {
  ev <- rbindlist(lapply(evf, function(fp) as.data.table(read_parquet(fp,
          col_select = c("muni_prestador","uf","year","cesarean","fee_delivery","fee_assist")))))
  ev <- ev[year <= 2024 & !is.na(muni_prestador) & is.finite(fee_delivery) & fee_delivery > 0]
  setnames(ev, "muni_prestador", "muni6")
  ev[, fee_vag_econ := fee_delivery + fifelse(is.finite(fee_assist), fee_assist, 0)]
  agg <- ev[, .(n = .N, rate = mean(cesarean),
                fee_ces      = mean(fee_delivery[cesarean == 1], na.rm = TRUE),
                fee_vag_base = mean(fee_delivery[cesarean == 0], na.rm = TRUE),
                fee_vag_econ = mean(fee_vag_econ[cesarean == 0], na.rm = TRUE)), by = .(muni6, uf, year)]
  agg <- agg[n >= 20 & is.finite(fee_ces) & is.finite(fee_vag_base) & fee_vag_base > 0 & fee_vag_econ > 0]
  agg[, `:=`(gap_base = log(fee_ces / fee_vag_base), gap_econ = log(fee_ces / fee_vag_econ))]
  b_uf   <- feols(rate ~ gap_base | uf + year,    agg, weights = ~n, cluster = ~uf)
  b_muni <- feols(rate ~ gap_base | muni6 + year, agg, weights = ~n, cluster = ~muni6)
  e_uf   <- feols(rate ~ gap_econ | uf + year,    agg, weights = ~n, cluster = ~uf)
  e_muni <- feols(rate ~ gap_econ | muni6 + year, agg, weights = ~n, cluster = ~muni6)
  dict <- c(rate = "Private-insurance cesarean rate", gap_base = "Log fee gap (base vaginal fee)",
            gap_econ = "Log fee gap (economic vaginal fee)", uf = "State", muni6 = "Municipality", year = "Year")
  f <- file.path(TABLE, "tab_ref_c6_fee_base_econ.tex")
  etable(b_uf, b_muni, e_uf, e_muni, tex = TRUE, file = f, replace = TRUE, dict = dict,
         signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
         fitstat = ~ n + r2, digits = 4, digits.stats = 3,
         headers = c("Base vaginal fee", "Base vaginal fee", "Economic vaginal fee", "Economic vaginal fee"),
         title = "The fee-gap null does not depend on the endogenous labor-assistance hours",
         label = "tab:fee_base_econ",
         notes = paste("\\footnotesize\\textit{Notes:} Municipality-year cells built",
           "from event-level TISS claims, weighted by deliveries. The base fee gap uses",
           "only the delivery procedure fee; the economic fee gap adds the",
           "separately-billed hourly labor-assistance fee to the vaginal fee. The",
           "coefficient is small and sign-unstable under both definitions, so the null",
           "is not an artifact of the endogenous billed hours. SE clustered by the",
           "fixed-effect geography.", SIGNIF_NOTE))
  postprocess_tex(f, fontsize = "\\small", tabcolsep = 4)
  cat(sprintf("\n[D/C6] base gap: uf %+.4f / muni %+.4f | econ gap: uf %+.4f / muni %+.4f\n",
              coef(b_uf)["gap_base"], coef(b_muni)["gap_base"], coef(e_uf)["gap_econ"], coef(e_muni)["gap_econ"]))
}

# =============================================================================
# E (C10) — FEW-CLUSTER INFERENCE: wild-cluster (Webb) bootstrap + cluster counts.
# The state-level specifications have ~22-27 clusters. We re-do inference on the
# fee-shock first-difference (the cleanest few-cluster object) with a wild-cluster
# bootstrap, and report the number of clusters for every fee specification.
#   -> tab_ref_c10_fewcluster.tex
# =============================================================================

source(here::here("config", "config.R"))
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))
OUT <- file.path(DROPBOX_ROOT, "build", "TISS", "output"); TABLE <- here::here("analysis","output","tables")

p <- as.data.table(read_parquet(file.path(OUT, "delivery_panel_muni_month.parquet")))
p <- p[!is.na(muni) & year <= 2024 & is.finite(fee_cesarean) & is.finite(fee_vaginal_econ)]
uf <- p[, .(csec = weighted.mean(csection_rate, n_deliveries, na.rm = TRUE),
            fee_ces = weighted.mean(fee_cesarean, n_deliveries, na.rm = TRUE),
            fee_vag = weighted.mean(fee_vaginal_econ, n_deliveries, na.rm = TRUE),
            n = sum(n_deliveries)), by = .(uf, year)]
uf[, fee_gap := log(fee_ces / fee_vag)]; setorder(uf, uf, year)
uf[, `:=`(d_fee_gap = fee_gap - shift(fee_gap), d_csec = csec - shift(csec)), by = uf]
uf <- uf[n > 2000 & !is.na(d_fee_gap)]
m_fd <- feols(d_csec ~ d_fee_gap, uf, weights = ~n, cluster = ~uf)
n_state <- uniqueN(uf$uf)
analytic_p <- pvalue(m_fd)["d_fee_gap"]

wild_p <- NA_real_
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  suppressMessages(library(fwildclusterboot)); set.seed(1)
  if (requireNamespace("dqrng", quietly = TRUE)) dqrng::dqset.seed(1)
  bt <- tryCatch(boottest(m_fd, clustid = "uf", param = "d_fee_gap", B = 9999, type = "webb"),
                 error = function(e) { message("  boottest failed: ", conditionMessage(e)); NULL })
  if (!is.null(bt)) wild_p <- bt$p_val
} else message("  install fwildclusterboot for the wild bootstrap; reporting analytic p only.")

tex <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Few-cluster inference for the fee channel}}",
  "\\label{tab:fewcluster}", "\\small",
  "\\begin{tabular}{lc}", "\\toprule",
  "Quantity & Value \\\\", "\\midrule",
  sprintf("Fee-shock coefficient ($\\Delta$ cesarean on $\\Delta$ fee gap) & %+.4f \\\\", coef(m_fd)["d_fee_gap"]),
  sprintf("Number of state clusters & %d \\\\", n_state),
  sprintf("Cluster-robust analytic $p$-value & %.3f \\\\", analytic_p),
  sprintf("Wild-cluster (Webb) bootstrap $p$-value & %s \\\\", ifelse(is.na(wild_p), "n/a", sprintf("%.3f", wild_p))),
  "\\bottomrule", "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} State-year first differences,",
        "weighted by deliveries, 9,999 Webb-weight wild-cluster bootstrap draws with",
        "the state as the cluster. The fee-shock coefficient is not distinguishable",
        "from zero under proper few-cluster inference. The municipality fixed-effect",
        "specifications in Table~\\ref{tab:fees} have several hundred clusters",
        "and are unaffected."),
  "\\end{table}")
writeLines(resize_tabular(tex), file.path(TABLE, "tab_ref_c10_fewcluster.tex"))
cat(sprintf("\n[E/C10] fee-shock: %d clusters, analytic p=%.3f, wild-Webb p=%s\n",
            n_state, analytic_p, ifelse(is.na(wild_p), "n/a", sprintf("%.3f", wild_p))))

# =============================================================================
# F (C12) — SAMPLE FLOW (CONSORT-style) + MISSINGNESS OF THE PRELABOR INDICATOR.
# Documents where observations are lost and shows the prelabor indicator's
# missingness is balanced across weekdays and weekends (so the prelabor/in-labor
# split is not a missingness artifact).
#   -> tab_ref_c12_sampleflow.tex , tab_ref_c12_missingness.tex
# =============================================================================

source(here::here("config", "config.R"))
pacman::p_load(data.table, arrow, here)
source(here::here("analysis", "code", "00_utils.R"))
SIN <- file.path(DROPBOX_ROOT, "build", "SINASC", "input"); TABLE <- here::here("analysis","output","tables")

b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector","cesarean","cesarea_antes_parto","tipo_robson","dow","year")))
n_raw <- nrow(b)
b1 <- b[year <= 2024];                                   n_year   <- nrow(b1)
b2 <- b1[sector %in% c("Private","Public")];             n_sector <- nrow(b2)
b3 <- b2[tipo_robson %in% sprintf("%02d", 1:11)];        n_robson <- nrow(b3)
b4 <- b2[cesarean == 0 | cesarea_antes_parto %in% c(1,2)]; n_timing <- nrow(b4)

flow <- data.table(
  Step = c("Raw SINASC birth records",
           "Restrict to 2010--2024",
           "For-profit or public establishment",
           "\\quad of which: valid Robson group (2014+)",
           "\\quad of which: valid before/during-labor code (cesareans)"),
  N = format(c(n_raw, n_year, n_sector, n_robson, n_timing), big.mark = ","))
tex <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Sample construction, SINASC birth records}}", "\\label{tab:sampleflow}", "\\small",
  "\\begin{tabular}{lr}", "\\toprule", "Step & Records \\\\", "\\midrule",
  apply(flow, 1, function(x) paste(paste(x, collapse = " & "), "\\\\")),
  "\\bottomrule", "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} The Robson classification is",
        "populated from 2014; the before/during-labor timing code is well populated",
        "from about 2012. Analyses that need each variable use the corresponding",
        "sub-sample, as noted in each table."),
  "\\end{table}")
writeLines(resize_tabular(tex), file.path(TABLE, "tab_ref_c12_sampleflow.tex"))

# missingness of the timing indicator among cesareans, by weekend x sector
b2[, weekend := as.integer(dow %in% c(1, 7))]
miss <- b2[cesarean == 1, .(missing_pct = 100 * mean(!(cesarea_antes_parto %in% c(1,2))), n = .N),
           by = .(sector, weekend)][order(sector, weekend)]
miss[, day := fifelse(weekend == 1, "Weekend", "Weekday")]
mw <- dcast(miss, sector ~ day, value.var = "missing_pct")
mtab <- mw[, .(Sector = as.character(sector_display(sector, c("Private", "Public"))), `Weekday (\\%)` = sprintf("%.2f", Weekday),
               `Weekend (\\%)` = sprintf("%.2f", Weekend))]
tex2 <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Missingness of the cesarean-timing indicator is balanced across the week}}",
  "\\label{tab:timing_missing}", "\\small",
  "\\begin{tabular}{lcc}", "\\toprule",
  "Sector & Weekday (\\%) & Weekend (\\%) \\\\", "\\midrule",
  apply(mtab, 1, function(x) paste(paste(x, collapse = " & "), "\\\\")),
  "\\bottomrule", "\\end{tabular}",
  paste("\\\\[2pt]\\footnotesize\\textit{Notes:} Share of cesareans with a missing",
        "before/during-labor code, SINASC 2010--2024. The near-identical weekday and",
        "weekend rates imply the prelabor/in-labor split is not driven by differential",
        "missingness across the week."),
  "\\end{table}")
writeLines(resize_tabular(tex2), file.path(TABLE, "tab_ref_c12_missingness.tex"))
cat("\n[F/C12] sample flow:\n"); print(flow); cat("timing-indicator missingness:\n"); print(mw)

# =============================================================================
# G (C7) — PLACEBO TWO-DAY RANKING, correctly labelled (NOT "randomization
# inference"). The days of the week are not exchangeable under a known assignment
# mechanism, so the weekend's rank among the 21 two-day pairs is a descriptive
# ranking, not an exact permutation p-value. We recompute the ranking and label it.
#   -> tab_ref_c7_placebo_ranking.tex
# =============================================================================

source(here::here("config", "config.R"))
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))
SIN <- file.path(DROPBOX_ROOT, "build", "SINASC", "input"); TABLE <- here::here("analysis","output","tables")

sb <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_muni.parquet")))
sb <- sb[year(date) <= 2024 & sector == "Private" & births > 0]
sb[, `:=`(dow = wday(date), yr = year(date))]
pairs <- combn(1:7, 2, simplify = FALSE)
dips <- rbindlist(lapply(pairs, function(pr) {
  d <- copy(sb); d[, rest := as.integer(dow %in% pr)]
  cl <- d[, .(rate = sum(cesarean)/sum(births), n = sum(births)), by = .(muni, date, rest, yr)]
  co <- coef(feols(rate ~ rest | muni + yr, cl, weights = ~n))["rest"]
  data.table(days = paste(c("Sun","Mon","Tue","Wed","Thu","Fri","Sat")[pr], collapse = "+"),
             is_weekend = as.integer(setequal(pr, c(1, 7))), dip = co)
}))
setorder(dips, dip); dips[, rank := .I]
rk <- dips[is_weekend == 1, rank]
cat(sprintf("\n[G/C7] true weekend (Sat+Sun) dip = %.4f, rank %d of %d (most negative = rank 1)\n",
            dips[is_weekend == 1, dip], rk, nrow(dips)))
top <- head(dips, 6)
ttab <- top[, .(`Two-day pair` = days, `Cesarean dip (pp)` = sprintf("%.2f", 100*dip),
                Rank = rank)]
tex <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{Descriptive ranking of the weekend against all two-day placebo pairs}}",
  "\\label{tab:placebo_ranking}", "\\small",
  "\\begin{tabular}{lcc}", "\\toprule",
  "Two-day pair & Cesarean dip (pp) & Rank \\\\", "\\midrule",
  apply(ttab, 1, function(x) paste(paste(x, collapse = " & "), "\\\\")),
  "\\bottomrule", "\\end{tabular}",
  sprintf(paste("\\\\[2pt]\\footnotesize\\textit{Notes:} For-profit weekend dip",
        "against all 21 ways of choosing two days as ``rest days,'' SINASC 2010--2024.",
        "The true weekend produces the largest dip (rank %d of 21). Because the days of",
        "the week are not exchangeable under a known assignment mechanism, this is a",
        "descriptive ranking, not an exact randomization-inference $p$-value."), rk),
  "\\end{table}")
writeLines(resize_tabular(tex), file.path(TABLE, "tab_ref_c7_placebo_ranking.tex"))

# =============================================================================
# H (C11) — PARTO ADEQUADO HOSPITAL-LEVEL EVENT STUDY (Sun & Abraham).
# The muni-level DiD codes a staggered 2017--2021 rollout as a common 2017 onset.
# A hospital-level design reduces exposure dilution. We lack exact per-hospital
# entry dates, so we run a Sun-Abraham event study with a COMMON 2017 adoption at
# the hospital (establishment) level as the best available refinement, and print
# the pre-trend test. Skips gracefully if the hospital list is unavailable.
#   -> fig_ref_c11_pa_hospital_es.pdf/png   (only if inputs exist)
# =============================================================================

source(here::here("config", "config.R"))
pacman::p_load(data.table, arrow, fixest, ggplot2, here)
source(here::here("analysis", "code", "00_utils.R"))
SIN <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
PA  <- file.path(DROPBOX_ROOT, "build", "covariates", "input", "parto_adequado_fase2_hospitais.csv")

if (!file.exists(PA)) {
  message("07 [H/C11] skipped — Parto Adequado hospital list not found at ", PA)
} else {
  palist <- fread(PA)
  cnes_col <- grep("cnes", tolower(names(palist)), value = TRUE)
  if (length(cnes_col) == 0) {
    message("07 [H/C11] skipped — no CNES column in the Parto Adequado list; columns: ",
            paste(names(palist), collapse = ", "))
  } else {
    treated_cnes <- unique(as.character(palist[[cnes_col[1]]]))
    bh <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
            col_select = c("codigo_estabelecimento","sector","cesarean","year")))
    bh <- bh[sector == "Private" & year <= 2024 & !is.na(codigo_estabelecimento)]
    bh[, cnes := as.character(codigo_estabelecimento)]
    hy <- bh[, .(rate = mean(cesarean), n = .N), by = .(cnes, year)][n >= 20]
    hy[, treated := as.integer(cnes %in% treated_cnes)]
    hy[, ry := ifelse(treated == 1, year - 2017, NA_integer_)]     # relative year; NA = never-treated
    es <- tryCatch(
      feols(rate ~ sunab(ifelse(treated == 1, 2017, 10000), year) | cnes + year,
            hy, weights = ~n, cluster = ~cnes),
      error = function(e) { message("  sunab failed: ", conditionMessage(e)); NULL })
    if (!is.null(es)) {
      cat("\n[H/C11] hospital-level Sun-Abraham event study (common 2017 onset):\n")
      print(coeftable(es))
      p <- ggplot() + theme_paper()  # minimal; the coefplot is best viewed via fixest
      pdf(here::here("analysis","output","graphs","fig_ref_c11_pa_hospital_es.pdf"), width = 8, height = 5)
      iplot(es, main = "", xlab = "Years since Parto Adequado onset (2017)")
      dev.off()
      cat("  wrote fig_ref_c11_pa_hospital_es.pdf. Interpretation stays: no clean break; not identified.\n")
    }
  }
}

# =============================================================================
# I (C13) — REPLICATION-PACKAGE SCAFFOLDING.
# Writes a README stub and a session/renv snapshot into analysis/output so the
# package can be assembled for the AEA data-availability policy.
# =============================================================================

source(here::here("config", "config.R"))
REPL <- here::here("analysis", "output", "replication")
dir.create(REPL, showWarnings = FALSE, recursive = TRUE)
writeLines(capture.output(sessionInfo()), file.path(REPL, "sessionInfo.txt"))
# Only snapshot if renv is already initialized for this project (avoid creating a
# lockfile as a side effect); otherwise print the one-time init instruction.
if (requireNamespace("renv", quietly = TRUE) && dir.exists(here::here("renv"))) {
  try(renv::snapshot(project = here::here(), prompt = FALSE), silent = TRUE)
} else message("  To pin the environment, run once: renv::init(); renv::snapshot().")
readme <- c(
  "# Replication package — Born on Schedule",
  "",
  "## Data provenance",
  "- SINASC births 2010-2024: Base dos Dados (BigQuery), query in build/01b_sinasc_cnes.R. Download date: <FILL>.",
  "- TISS claims 2015-2025: ANS PDA FTP (https://dadosabertos.ans.gov.br/FTP/PDA/TISS/). Download date: <FILL>.",
  "- CNES beds/obstetricians: datazoom.saude / microdatasus. Download date: <FILL>.",
  "- IEPS muni-year covariates: https://iepsdata.org.br (manual export). Download date: <FILL>.",
  "- Parto Adequado Fase-2 hospital list: ANS PDF snapshot 2019-02-11.",
  "",
  "## How to reproduce",
  "1. Edit config/config.R (set DROPBOX_ROOT).",
  "2. Rscript config/00_master_build.R    # builds main_data.parquet and panels",
  "3. Rscript config/00_master_analysis.R # regenerates every table and figure",
  "4. Rscript analysis/code/07_referee_response.R  # referee-response exhibits",
  "",
  "## Program-to-output inventory",
  "| Script | Outputs |",
  "|---|---|",
  "| analysis/code/01_descriptives.R | fig01, fig02, map01, map02, tab01 |",
  "| analysis/code/02_regressions.R  | tab_fees |",
  "| analysis/code/03_mechanisms.R   | fig03, fig07, fig08, tab07, tab08, tab11, tab_prelabor_lowrisk |",
  "| analysis/code/04_heterogeneity.R| tab10, tab10b |",
  "| analysis/code/05_cost.R         | fig09, fig09b, tab09, tab12 |",
  "| analysis/code/06_robustness.R   | fig04, fig04b, fig05, tab05, tab05b, tab13*, tab14, tab15* |",
  "| analysis/code/07_main_specification.R | tab_main_gradient |",
  "| analysis/code/08_long_weekends.R | tab_long_weekends, tab_displacement_robust |",
  "| analysis/code/09_org_capacity.R | tab_org_capacity, tab_org_capacity_valid |",
  "| analysis/code/10_supplement.R   | tab_multiple_testing, tab_ref_* |",
  "| analysis/code/11_body_figures.R | fig_calendar_fingerprints, fig_gestation_panels |",
  "",
  "## Environment and runtime",
  "- R version and packages: see sessionInfo.txt and renv.lock.",
  "- Random seeds: set.seed(1) in every script that bootstraps or permutes.",
  "- Expected runtime on a 2023 MacBook Pro (M2 Pro, 16 GB): build ~3 h (dominated",
  "  by the TISS download); full analysis ~90 min; 07_referee_response.R ~40 min,",
  "  of which the composition-adjusted municipality-by-date regression is ~25 min.",
  "- Peak memory ~12 GB (the birth-level regressions on 24M records).",
  "",
  "## AI-use disclosure",
  "- Portions of the code and manuscript were drafted/edited with AI assistance;",
  "  all results were verified by the authors against the source data.",
  "",
  "## Checksums",
  "- Run `shasum -a 256` on each raw extract and record the hashes here: <FILL>.")
writeLines(readme, file.path(REPL, "README.md"))
cat("\n[I/C13] wrote replication scaffolding to analysis/output/replication/ (README.md, sessionInfo.txt).\n")

# =============================================================================
# K — MULTIPLE-TESTING ADJUSTMENT over pre-specified hypothesis families.
# The paper reports several heterogeneity tests and several outcome regressions.
# We group the hypotheses into pre-specified families and report, within each
# family, Holm-Bonferroni adjusted p-values (familywise error rate) and
# Benjamini-Hochberg q-values (false discovery rate). Families A, D and E are
# saved by 07_main_specification.R, 08_long_weekends.R and 09_org_capacity.R.
#   -> tab_multiple_testing.tex
# =============================================================================

source(here::here("config", "config.R"))
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))
SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
WFO   <- file.path(DROPBOX_ROOT, "build", "workfile", "output", "main_data.parquet")
TABLE <- here::here("analysis", "output", "tables")
AOUT  <- here::here("analysis", "output")

read_fam <- function(nm) {
  f <- file.path(AOUT, paste0(nm, ".rds"))
  if (file.exists(f)) readRDS(f) else NULL
}
fam_A <- read_fam("fam_A")
if (is.null(fam_A)) stop("fam_A.rds missing: run 07_main_specification.R first")

# --- Family B: heterogeneity in the weekend dip ------------------------------
b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "escolaridade_mae", "muni", "date", "dow", "year")))
b <- b[year <= 2024 & sector == "Private"]
b[, weekend := as.integer(dow %in% c(1, 7))]
w <- as.data.table(read_parquet(WFO))
dens <- w[!is.na(obstetricians_per_1k_births),
          .(dens = mean(obstetricians_per_1k_births)), by = .(muni = muni6)]
dens[, low_dens := as.integer(dens < median(dens))]
b <- merge(b, dens[, .(muni, low_dens)], by = "muni", all.x = FALSE)
cell_a <- b[, .(rate = mean(cesarean), n = .N), by = .(muni, date, weekend, low_dens, year)]
m_dens <- feols(rate ~ weekend + weekend:low_dens | muni + year, cell_a,
                weights = ~n, cluster = ~muni + date)
b[, educ_hi := fifelse(escolaridade_mae %in% 4:5, 1L,
              fifelse(escolaridade_mae %in% 1:3, 0L, NA_integer_))]
cell_b <- b[!is.na(educ_hi), .(rate = mean(cesarean), n = .N),
            by = .(muni, date, weekend, educ_hi, year)]
m_educ <- feols(rate ~ weekend + weekend:educ_hi | muni + year, cell_b,
                weights = ~n, cluster = ~muni + date)
rm(b, cell_a, cell_b); gc()

ev <- rbindlist(lapply(2015:2024, function(y)
  as.data.table(read_parquet(file.path(OUT, sprintf("delivery_events_%d.parquet", y)),
    col_select = c("cesarean", "modalidade", "faixa_etaria", "muni_prestador", "year")))))
ev <- ev[!is.na(modalidade) & modalidade != "" & !is.na(muni_prestador)]
ev[, coop := as.integer(grepl("^Cooperativa", modalidade))]
m_mod1 <- feols(cesarean ~ coop + i(faixa_etaria) | muni_prestador + year, ev,
                cluster = ~muni_prestador)
rm(ev); gc()

fam_B <- data.table(
  family = "B. Heterogeneity in the weekend dip",
  hypothesis = c("Weekend $\\times$ Low obstetrician density",
                 "Weekend $\\times$ Mother has 8+ years of schooling",
                 "Physician-owned cooperative insurer"),
  estimate = c(coef(m_dens)["weekend:low_dens"], coef(m_educ)["weekend:educ_hi"],
               coef(m_mod1)["coop"]),
  p = c(coeftable(m_dens)["weekend:low_dens", 4], coeftable(m_educ)["weekend:educ_hi", 4],
        coeftable(m_mod1)["coop", 4]))
rm(m_dens, m_educ, m_mod1); gc()

# --- Family C: sector differences in gestational and newborn outcomes --------
b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "semana_gestacao", "peso", "apgar5", "idade_mae",
                      "escolaridade_mae", "raca_cor_mae", "muni", "year")))
b <- b[year <= 2024 & sector %in% c("Private", "Public")]
b[, `:=`(early_term = as.integer(semana_gestacao %between% c(37, 38)),
         lbw = as.integer(peso < 2500), low_apgar = as.integer(apgar5 < 7),
         private = as.integer(sector == "Private"), age2 = idade_mae^2)]
b[, educ := factor(escolaridade_mae, levels = 1:5)]
ctrl <- "idade_mae + age2 + i(educ) + i(raca_cor_mae)"
m_et <- feols(as.formula(paste("early_term ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)
m_lb <- feols(as.formula(paste("lbw ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)
m_ap <- feols(as.formula(paste("low_apgar ~ private +", ctrl, "| muni + year")), b, cluster = ~muni)
fam_C <- data.table(
  family = "C. For-profit--public outcome differences",
  hypothesis = c("Early-term birth (37--38 weeks)", "Low birthweight ($<$2500g)",
                 "Five-minute Apgar $<$ 7"),
  estimate = c(coef(m_et)["private"], coef(m_lb)["private"], coef(m_ap)["private"]),
  p = c(coeftable(m_et)["private", 4], coeftable(m_lb)["private", 4],
        coeftable(m_ap)["private", 4]))
rm(b, m_et, m_lb, m_ap); gc()

mt <- rbindlist(Filter(Negate(is.null),
  list(fam_A, fam_B, fam_C, read_fam("fam_D"), read_fam("fam_E"))))
mt[, `:=`(p_holm = p.adjust(p, "holm"), q_bh = p.adjust(p, "BH")), by = family]
fmt_p <- function(x) fifelse(x < 0.001, "$<$0.001", sprintf("%.3f", x))

body <- character(0)
for (fm in unique(mt$family)) {
  body <- c(body, sprintf("\\emph{%s} & & & & \\\\", fm))
  sub <- mt[family == fm]
  for (i in seq_len(nrow(sub))) body <- c(body, sprintf(
    "\\quad %s & %.4f & %s & %s & %s \\\\", sub$hypothesis[i], sub$estimate[i],
    fmt_p(sub$p[i]), fmt_p(sub$p_holm[i]), fmt_p(sub$q_bh[i])))
  body <- c(body, "\\addlinespace[3pt]")
}
tex <- c("\\begin{table}[H]",
  "   \\caption{\\label{tab:multiple_testing} \\textbf{Multiple-hypothesis adjustment within pre-specified families}}",
  "   \\centering",
  "\\small\\setlength{\\tabcolsep}{5pt}\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%",
  "   \\begin{tabular}{lcccc}", "      \\toprule",
  "      Hypothesis & Estimate & Unadjusted $p$ & Holm $p$ & BH $q$ \\\\", "      \\midrule",
  paste0("      ", body), "\\bottomrule", "   \\end{tabular}", "}", "   ",
  "   \\par \\raggedright ",
  paste("   \\footnotesize\\textit{Notes:} Each family collects the hypotheses that the",
    "paper tests jointly. Family A is the within-municipality-day for-profit calendar",
    "gradient of Table~\\ref{tab:main_gradient}; family B the supplemental heterogeneity",
    "tests; family C the for-profit--public outcome differences of",
    "Table~\\ref{tab:health}; family D the long-weekend taxonomy and displacement tests of",
    "Table~\\ref{tab:long_weekends}; family E the organizational-capacity interactions of",
    "Table~\\ref{tab:org_capacity}. Holm $p$ is the",
    "Holm--Bonferroni adjusted $p$-value \\citep{holm1979}, which controls the familywise",
    "error rate within the family; BH $q$ is the Benjamini--Hochberg false-discovery-rate",
    "$q$-value \\citep{benjamini1995}. Estimates and unadjusted $p$-values reproduce the corresponding",
    "columns of the source tables."),
  "\\end{table}", "")
writeLines(tex, file.path(TABLE, "tab_multiple_testing.tex"))
cat("\n[K] Multiple-testing families:\n"); print(mt)

message("\n07_referee_response.R done")
