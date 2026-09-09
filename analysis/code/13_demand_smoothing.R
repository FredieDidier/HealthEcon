# =============================================================================
# 13_demand_smoothing.R -- the de Elejalde-Giolito (2021, JHE) demand-smoothing
# channel, tested on Brazilian for-profit maternities.
#
# THE HYPOTHESIS. de Elejalde & Giolito (2021) show that Chilean cesarean rates
# rose 8.6pp at private hospitals paid the SAME price for a vaginal delivery and
# a cesarean, and argue the incentive is capacity rather than price: a cesarean
# is schedulable, so a hospital can move a delivery off a week it expects to be
# crowded and raise the total number of deliveries it can take. It is the sibling
# mechanism to ours and the leading alternative reading of our own results: both
# produce prelabor cesareans with no fee gap, but theirs is a SEASONAL capacity
# pattern and ours a WEEKLY calendar one. Our setting is the sharper version of
# theirs, because the fee gap here is not merely zero but negative.
#
# TWO TESTS, BOTH PRE-SPECIFIED BEFORE ESTIMATION AND BOTH REPORTED WHATEVER
# THEY SHOW.
#
# (A) PULL-FORWARD. If deliveries are moved off weeks the establishment expects
#     to be crowded, the prelabor cesarean share in week w rises with expected
#     demand in week w+1, holding expected demand in week w fixed. Primary
#     outcome = prelabor cesarean share; primary parameter = delta, the
#     coefficient on expected demand in the following week; prediction delta > 0.
#     Expected demand is the leave-one-out mean of the establishment's births in
#     the same week of the year across all OTHER years, each week first
#     normalized by the establishment's own average week in its own year so the
#     forecast carries seasonality and not the establishment's growth. Without
#     that normalization the leave-one-out mean is mechanically NEGATIVELY
#     related to the value it leaves out whenever the establishment trends.
#
# (B) THROUGHPUT. The primitive of the demand-smoothing model is that scheduling
#     LEVELS the flow of deliveries. Then an establishment-year with a higher
#     prelabor cesarean share should show a SMOOTHER weekly delivery flow. We
#     measure smoothness by the variance-to-mean ratio of weekly birth counts,
#     which equals one under a purely Poisson arrival process, and regress its
#     log on the establishment-year prelabor cesarean share.
#
# RESULT (reported honestly, and it does not support the channel).
#   (A) delta is a small negative and never distinguishable from zero. But the
#       forecast is WEAK: out of sample a log point of forecast demand predicts
#       only 0.06 log points of realized relative demand, because an individual
#       maternity's week-to-week volume is close to unforecastable from its own
#       seasonal history. The exercise therefore bounds only large responses, and
#       we say so rather than reading the null as a rejection. This is the same
#       discipline we apply to the fee null in Section 5.
#   (B) is well powered and runs the OTHER way: within an establishment, a
#       higher prelabor cesarean share goes with a LUMPIER weekly flow, not a
#       smoother one.
# Together the two say the Brazilian pattern is not the Chilean capacity margin
# re-appearing: it is weekly and ownership-specific, not seasonal and
# throughput-levelling. That distinction is the reason to run this at all.
#
# LABELING. Both estimates are associations. (A) relates a predetermined seasonal
# demand forecast to prelabor timing; (B) relates two choices of the same
# establishment-year and cannot be read as the causal effect of scheduling on
# throughput. Same evidence class as the organizational-capacity exercise.
#
# Exhibit: tab_demand_smoothing.tex (Supplemental Appendix D).
# Saves analysis/output/fam_F.rds for the multiple-testing table built in 10.
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
TABLE <- here::here("analysis", "output", "tables")
OUT   <- here::here("analysis", "output")
YEARS <- 2015:2024

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
    e <- easter_sunday(y)
    out <- c(out, e - 2, e - 47, e - 48, e + 60)
  }
  sort(unique(out))
}

# =============================================================================
# 1. Establishment x week panel of for-profit births
# =============================================================================
ec <- as.data.table(read_parquet(file.path(SIN, "sinasc_daily_estab.parquet")))
ec[, date := as.IDate(date)]
ec <- ec[year(date) %in% YEARS]
ec[, is_hol := as.integer(date %in% holiday_dates(YEARS))]

ORIGIN <- as.IDate("2015-01-05")                       # a Monday
ec[, widx := as.integer(floor(as.integer(date - ORIGIN) / 7))]
ec <- ec[widx >= 0]
ec[, `:=`(year = year(date), woy = as.integer(strftime(date, "%V")))]

wk <- ec[, .(births = sum(births), n_ces = sum(n_ces), n_pre = sum(n_pre),
             n_lab = sum(n_lab), n_hol = sum(is_hol),
             year = year[1L], woy = woy[1L], muni = muni[1L]),
         by = .(estab, widx)]
wk <- wk[widx > min(widx) & widx < max(widx)]          # drop the truncated ends

sz <- wk[, .(births_y = sum(births)), by = .(estab, year)]
sz <- sz[, .(mean_births = mean(births_y), n_years = uniqueN(year)), by = estab]
wk <- wk[estab %chin% sz[mean_births >= 100 & n_years >= 5, estab]]
cat(sprintf("sample: %s establishments, %s establishment-weeks\n",
            format(uniqueN(wk$estab), big.mark = ","),
            format(nrow(wk), big.mark = ",")))

# =============================================================================
# 2. (A) Expected demand and the pull-forward test
# =============================================================================
setorder(wk, estab, widx)
wk[, mean_ey := mean(births), by = .(estab, year)]
wk[, rel := births / mean_ey]                          # week relative to its own year
wk[, `:=`(tot_ek = sum(rel), n_ek = .N), by = .(estab, woy)]
wk[, exp_dem := log((tot_ek - rel) / pmax(n_ek - 1L, 1L))]
wk[n_ek < 3L | !is.finite(exp_dem), exp_dem := NA_real_]

key <- wk[, .(estab, widx, exp_dem, n_hol, rel)]
setkey(key, estab, widx)
wk[, `:=`(exp_next = key[.(estab, widx + 1L), exp_dem],
          exp_prev = key[.(estab, widx - 1L), exp_dem],
          hol_next = key[.(estab, widx + 1L), n_hol],
          rel_next = key[.(estab, widx + 1L), rel])]
wk[, `:=`(pre_share = n_pre / births, ces_share = n_ces / births,
          lab_share = n_lab / births)]

est <- wk[!is.na(exp_dem) & !is.na(exp_next) & !is.na(exp_prev) &
            !is.na(rel_next) & births > 0 & rel_next > 0]

fitA <- function(y, fe) feols(as.formula(sprintf(
  "%s ~ exp_next + exp_dem + exp_prev + n_hol + hol_next | %s", y, fe)),
  data = est, weights = ~births, cluster = ~estab + widx)

m_pre1 <- fitA("pre_share", "estab + woy + year")
m_pre2 <- fitA("pre_share", "estab^year + woy")
m_pre3 <- fitA("pre_share", "estab^year + muni^widx")
m_ces  <- fitA("ces_share", "estab^year + woy")
m_lab  <- fitA("lab_share", "estab^year + woy")
modsA  <- list(m_pre1, m_pre2, m_pre3, m_ces, m_lab)
for (m in modsA) print(coeftable(m)[c("exp_next", "exp_dem", "exp_prev"), , drop = FALSE])

# Out-of-sample check that the forecast forecasts anything. It has to be out of
# sample: a leave-one-out mean is mechanically related to the value it omits, so
# only the omitted realization is a fair target.
m_val  <- feols(log(rel_next) ~ exp_next + hol_next | estab^year + woy,
                data = est, weights = ~births, cluster = ~estab + widx)
val_b  <- coeftable(m_val)["exp_next", 1]
val_se <- coeftable(m_val)["exp_next", 2]
mde    <- 2.802 * coeftable(m_pre2)["exp_next", 2]     # 80% power, 5% size
cat(sprintf("\nforecast slope out of sample: %.3f (%.3f)\nMDE on delta: %.2f pp per log point\n",
            val_b, val_se, 100 * mde))

# =============================================================================
# 3. (B) Does scheduling level the weekly flow?
# =============================================================================
ey <- wk[, .(nw = .N, mean_w = mean(births), var_w = var(births),
             tot = sum(births), ces = sum(n_ces), pre = sum(n_pre),
             muni = muni[1L]), by = .(estab, year)]
ey <- ey[nw >= 45 & mean_w >= 2]
ey[, `:=`(vmr = var_w / mean_w, pre_share = pre / tot,
          ces_share = ces / tot, lb = log(tot))]

m_vmr1 <- feols(log(vmr) ~ pre_share + lb | muni^year,          ey, weights = ~tot, cluster = ~estab)
m_vmr2 <- feols(log(vmr) ~ pre_share + lb | estab + muni^year,  ey, weights = ~tot, cluster = ~estab)
m_vmr3 <- feols(log(vmr) ~ ces_share + lb | muni^year,          ey, weights = ~tot, cluster = ~estab)
m_vmr4 <- feols(log(vmr) ~ ces_share + lb | estab + muni^year,  ey, weights = ~tot, cluster = ~estab)
modsB  <- list(m_vmr1, m_vmr2, m_vmr3, m_vmr4)
for (m in modsB) print(coeftable(m)[1:2, , drop = FALSE])

# =============================================================================
# 4. Table
# =============================================================================
tx <- c("\\begin{table}[H]\\centering",
  "\\caption{\\textbf{The demand-smoothing channel: pull-forward and throughput}}",
  "\\label{tab:demand_smoothing}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "\\multicolumn{6}{l}{\\emph{Panel A. Prelabor timing and expected demand in the following week}} \\\\",
  "\\addlinespace[2pt]",
  " & \\multicolumn{3}{c}{Prelabor cesarean share} & Cesarean share & In-labor share \\\\",
  "\\cmidrule(lr){2-4}\\cmidrule(lr){5-5}\\cmidrule(lr){6-6}",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  tex_row("Expected demand, following week", modsA, "exp_next"),
  tex_row("Expected demand, current week",   modsA, "exp_dem"),
  tex_row("Expected demand, preceding week", modsA, "exp_prev"),
  "\\midrule",
  "Establishment fixed effects & Yes & $\\times$ year & $\\times$ year & $\\times$ year & $\\times$ year \\\\",
  "Week-of-year fixed effects & Yes & Yes & -- & Yes & Yes \\\\",
  "Year fixed effects & Yes & -- & -- & -- & -- \\\\",
  "Municipality $\\times$ week fixed effects & -- & -- & Yes & -- & -- \\\\",
  tex_nobs(modsA, "Establishment-weeks"),
  sprintf("Forecast slope, out of sample & \\multicolumn{5}{c}{%.3f (%.3f)} \\\\",
          val_b, val_se),
  sprintf("Minimum detectable $\\delta$ (pp) & \\multicolumn{5}{c}{%.2f} \\\\", 100 * mde),
  "\\midrule",
  "\\multicolumn{6}{l}{\\emph{Panel B. Prelabor scheduling and the dispersion of the weekly delivery flow}} \\\\",
  "\\addlinespace[2pt]",
  " & \\multicolumn{4}{c}{Log variance-to-mean ratio of weekly births} & \\\\",
  "\\cmidrule(lr){2-5}",
  " & (1) & (2) & (3) & (4) & \\\\",
  "\\midrule",
  sub(" \\\\\\\\$", " & \\\\\\\\", tex_row("Prelabor cesarean share", modsB, "pre_share", mult = 1)),
  sub(" \\\\\\\\$", " & \\\\\\\\", tex_row("Cesarean share",          modsB, "ces_share", mult = 1)),
  "Establishment fixed effects & -- & Yes & -- & Yes & \\\\",
  "Municipality $\\times$ year fixed effects & Yes & Yes & Yes & Yes & \\\\",
  paste0(sub(" \\\\\\\\$", "", tex_nobs(modsB, "Establishment-years")), " & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  paste(
    "\\\\[2pt]\\footnotesize\\textit{Notes:} SINASC, for-profit establishments,",
    "2015--2024. The sample keeps establishments averaging at least one hundred",
    "births a year and observed in at least five years. \\emph{Panel A} tests the",
    "pull-forward prediction of \\citet{elejalde2021}: a maternity that expects a",
    "crowded week should book deliveries out of it in advance, so the coefficient",
    "on expected demand in the following week should be positive. Expected demand",
    "for an establishment in a given week of the year is the leave-one-out mean of",
    "its births in that week of the year across all other years, each week first",
    "expressed relative to the establishment's own average week in its own year;",
    "leaving out the current year breaks the mechanical link with the births that",
    "form the outcome. Coefficients are in percentage points of the outcome share",
    "per log point of expected demand, and every column also controls for the",
    "number of national holidays in the current and the following week. The",
    "forecast slope is the out-of-sample regression of realized relative demand in",
    "the following week on the forecast, and the minimum detectable $\\delta$ is",
    "the effect this design would reject at 80 percent power and 5 percent size.",
    "\\emph{Panel B} tests the primitive of the same model, that scheduling levels",
    "the flow of deliveries: the outcome is the log of the variance-to-mean ratio",
    "of the establishment-year's weekly birth counts, which is zero under a purely",
    "Poisson arrival process, and coefficients are log points per unit of the share.",
    "Cells are weighted by births; standard errors are two-way clustered by",
    "establishment and week in Panel A and clustered by establishment in Panel B.",
    "Both panels report associations, not the causal effect of crowding or of",
    "scheduling."),
  "\\end{table}")
write_table_tex(resize_tabular(tx), file.path(TABLE, "tab_demand_smoothing.tex"))

# family F for the multiple-testing table built in 10_supplement.R
saveRDS(data.table(
  family = "F. Demand smoothing",
  hypothesis = c("Expected demand next week $\\times$ prelabor cesarean share",
                 "Expected demand next week $\\times$ cesarean share",
                 "Prelabor cesarean share $\\times$ weekly flow dispersion"),
  estimate = c(coeftable(m_pre2)["exp_next", 1], coeftable(m_ces)["exp_next", 1],
               coeftable(m_vmr2)["pre_share", 1]),
  p = c(coeftable(m_pre2)["exp_next", 4], coeftable(m_ces)["exp_next", 4],
        coeftable(m_vmr2)["pre_share", 4])),
  file.path(OUT, "fam_F.rds"))

message("13_demand_smoothing.R: done")
