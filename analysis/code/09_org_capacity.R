# =============================================================================
# 09_org_capacity.R — Organizational capacity and weekend scheduling
#
# WHAT THIS DOES AND DOES NOT SHOW. Establishment size does not separate "the
# individual physician's calendar" from "the hospital's staffing constraint":
# both stories predict a smaller weekend gradient at large establishments, since
# a large obstetric service supplies both call coverage and independence from any
# one physician's diary. What the exercise identifies is whether ORGANIZATIONAL
# REDUNDANCY attenuates the calendar gradient. The permitted reading is: "larger
# obstetric services attenuate the weekend gradient, consistent with
# organizational coverage mitigating calendar-based scheduling." The impermissible
# reading is that this proves the effect comes from the individual physician's
# calendar rather than from hospital capacity.
#
# CHOICE OF CAPACITY MEASURE (validation-driven; see build/01d_cnes_estab.R).
# The natural measure, the count of obstetricians registered at the establishment
# in CNES-PF, fails validation: among establishments with at least fifty
# deliveries in the previous year, 14 percent of for-profit and 27 percent of
# public maternities register ZERO obstetricians, and the medians are three and
# two. Brazilian obstetricians hold their CNES bond at their own practice, not
# at the maternity where they deliver, so the count measures registration rather
# than the on-call roster. We therefore measure capacity by the establishment's
# OBSTETRIC BEDS, with its annual DELIVERY VOLUME as a scale control, and report
# the obstetrician count only as a flagged, weak robustness check.
#
# Capacity is measured with a ONE-YEAR LAG, so it is predetermined with respect
# to the current year's scheduling.
#
# Specification (for-profit establishments only):
#   Y_hdy = alpha_hy + lambda_md
#           + beta  Weekend_d x log(1 + ObstetricBeds_{h,y-1})
#           + theta Holiday_d x log(1 + ObstetricBeds_{h,y-1})
#           + {Weekend, Holiday} x log(1 + Deliveries_{h,y-1}) + e_hdy
# alpha_hy = establishment x year, lambda_md = municipality x date. Standard
# errors two-way clustered by establishment and date. Primary outcome: the share
# of births delivered by prelabor cesarean.
#
# RESULT (weak, reported honestly). The interactions are positive (larger =
# flatter gradient) and none is significant under municipality x date fixed
# effects. The exhibit lives in the Supplement; Section 5 carries a one-paragraph
# summary pointing to it.
#
# Exhibits (BOTH in the Supplemental Appendix):
#   tab_org_capacity.tex        continuous + tercile heterogeneity
#   tab_org_capacity_valid.tex  link validation + alternative measures
#
# REQUIRES build/01d_cnes_estab.R to have been run (cnes_estab_year.parquet).
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, dplyr, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
CNES  <- file.path(DROPBOX_ROOT, "build", "CNES", "input")
TABLE <- here::here("analysis", "output", "tables")
ESTAB_PANEL <- file.path(CNES, "cnes_estab_year.parquet")

if (!file.exists(ESTAB_PANEL)) {
  message("cnes_estab_year.parquet not found; run build/01d_cnes_estab.R first. Skipping.")
} else {

YEARS <- 2015:2024

# easter_sunday() and holiday_dates() come from 00_utils.R (one calendar for every script)

# =============================================================================
# 1. Establishment x date cells of for-profit births (cached)
# =============================================================================
CELL_CACHE <- file.path(SIN, "sinasc_daily_estab.parquet")
if (!cache_fresh(CELL_CACHE, file.path(SIN, "sinasc_births.parquet"))) {
  message("building ", basename(CELL_CACHE), " from sinasc_births.parquet ...")
  ec <- open_dataset(file.path(SIN, "sinasc_births.parquet")) %>%
    filter(year >= 2015, year <= 2024, sector == "Private") %>%
    mutate(is_ces = if_else(cesarean == 1L, 1L, 0L),
           is_pre = if_else(cesarean == 1L & !is.na(cesarea_antes_parto) &
                              cesarea_antes_parto == 1L, 1L, 0L),
           is_lab = if_else(cesarean == 1L & !is.na(cesarea_antes_parto) &
                              cesarea_antes_parto == 2L, 1L, 0L)) %>%
    group_by(estab, muni, date) %>%
    summarise(births = n(), n_ces = sum(is_ces), n_pre = sum(is_pre),
              n_lab = sum(is_lab), .groups = "drop") %>%
    collect() %>% as.data.table()
  write_parquet(ec, CELL_CACHE)
  message("saved ", nrow(ec), " establishment-date cells")
}
ec <- as.data.table(read_parquet(CELL_CACHE))
ec[, `:=`(date = as.IDate(date), year = year(as.IDate(date)))]
ec[, dow := wday(date)]
hol <- holiday_dates(YEARS)
ec[, `:=`(weekend = as.integer(dow %in% c(1L, 7L)),
          holiday = as.integer(date %in% hol))]

# =============================================================================
# 2. Predetermined (one-year-lagged) capacity from CNES + link validation
# =============================================================================
cap <- as.data.table(read_parquet(ESTAB_PANEL))
cap <- cap[, .(estab = cnes, year, n_obstetricians, beds_obstetric, beds_total,
               obst_hours_hosp, sus_share, sus_share_obstetric)]
vol <- ec[, .(vol = sum(births)), by = .(estab, year)]          # own annual volume
cap <- merge(cap, vol, by = c("estab", "year"), all.x = TRUE)
cap[is.na(vol), vol := 0L]
cap[, year := year + 1L]                                        # becomes the LAG
setnames(cap, setdiff(names(cap), c("estab", "year")),
         paste0("lag_", setdiff(names(cap), c("estab", "year"))))

d <- merge(ec, cap, by = c("estab", "year"), all.x = TRUE)
link_rate  <- d[, mean(!is.na(lag_beds_obstetric))]
birth_link <- d[, sum(births[!is.na(lag_beds_obstetric)]) / sum(births)]
cat(sprintf("\n[2] CNES link: %.1f%% of establishment-days, %.1f%% of for-profit births\n",
            100 * link_rate, 100 * birth_link))
# The capacity measures are LAGGED and the CNES panel opens in 2015, so no 2015
# birth can link: that year is the whole of the gap. From 2016 the link is
# reported overall and separately for weekdays and weekends, the comparison a
# weekend design needs (a link that failed more on weekends would bias it).
d16 <- d[year >= 2016L]
d16[, wkend := wday(date) %in% c(1L, 7L)]
link16    <- d16[, sum(births[!is.na(lag_beds_obstetric)]) / sum(births)]
link16_wd <- d16[wkend == FALSE, sum(births[!is.na(lag_beds_obstetric)]) / sum(births)]
link16_we <- d16[wkend == TRUE,  sum(births[!is.na(lag_beds_obstetric)]) / sum(births)]
cat(sprintf("[2] CNES link 2016-2024: %.1f%% of for-profit births (weekdays %.1f%%, weekends %.1f%%)\n",
            100 * link16, 100 * link16_wd, 100 * link16_we))

# VALIDATION of the registered-obstetrician count, both sectors, one definition:
# establishment-years with at least fifty births in the year whose CNES-PF record
# lists no obstetrician. Quoted in the notes and in Section 5.
vv <- open_dataset(file.path(SIN, "sinasc_births.parquet")) %>%
  filter(year >= 2015, year <= 2024, sector %in% c("Private", "Public")) %>%
  count(estab, year, sector) %>% collect() %>% as.data.table()
vv <- vv[, .(n = sum(n), sector = sector[which.max(n)]), by = .(estab, year)][n >= 50]
pf <- as.data.table(read_parquet(ESTAB_PANEL))[, .(estab = cnes, year, n_obstetricians)]
vv <- merge(vv, pf, by = c("estab", "year"))
zero_obst_sector <- vv[, .(zero = 100 * mean(n_obstetricians == 0),
                           med = as.numeric(median(n_obstetricians))), by = sector]
cat("[2] Maternity-years (>= 50 births) registering no obstetrician:\n"); print(zero_obst_sector)
zfp  <- zero_obst_sector[sector == "Private", zero]
zpub <- zero_obst_sector[sector == "Public",  zero]

d <- d[!is.na(lag_beds_obstetric) & lag_vol >= 50]   # maternities with a prior year
zero_obst <- unique(d[, .(estab, year, lag_n_obstetricians)])[, mean(lag_n_obstetricians == 0)]
cat(sprintf("[2] Establishment-years registering zero obstetricians in CNES-PF: %.1f%%\n",
            100 * zero_obst))

d[, `:=`(pre_share = n_pre / births, ces_share = n_ces / births,
         log_beds  = log(1 + lag_beds_obstetric),
         log_vol   = log(1 + lag_vol),
         log_obst  = log(1 + lag_n_obstetricians),
         log_hours = log(1 + lag_obst_hours_hosp),
         sus_obst  = lag_sus_share_obstetric,
         sus_all   = lag_sus_share,
         beds_per100 = 100 * lag_beds_obstetric / pmax(lag_vol, 1))]

# CONTRACTED OBSTETRICIAN HOURS and PAYER EXPOSURE, both predetermined.
# Hours (CNES-PF HORAHOSP, summed over the establishment's obstetrician bonds)
# are a better-behaved measure of available obstetric time than a headcount:
# a physician registered for four hours a week and one registered for forty
# count the same in n_obstetricians. It inherits the same registration problem,
# so it stays a robustness column, not the main measure.
# The SUS share of obstetric beds is the project's only establishment-level
# measure of PAYER as opposed to ownership. Among for-profit maternities it is
# zero at the median, which is what licenses reading legal-entity type 2xxx as a
# private-payer population; the interaction asks whether the calendar gradient
# is concentrated in the for-profit establishments least exposed to the SUS.
sus_desc <- unique(d[!is.na(sus_obst), .(estab, year, sus_obst)])
setnames(sus_desc, "sus_obst", "sus_share")
cat(sprintf("[2] For-profit maternity-years: SUS obstetric-bed share mean %.3f, median %.3f, share above 0.5: %.3f\n",
            mean(sus_desc$sus_share), median(sus_desc$sus_share),
            mean(sus_desc$sus_share > 0.5)))
# Section 3 of the paper: the share of each sector's obstetric beds made
# available to the SUS, pooled over establishment-years (bed-weighted), and the
# median for-profit establishment's share.
bed_sus <- as.data.table(read_parquet(ESTAB_PANEL))[beds_obstetric > 0,
  .(pct = 100 * sum(beds_obstetric_sus) / sum(beds_obstetric),
    med = median(sus_share_obstetric)), by = sector]
cat("[2] SUS share of obstetric beds by sector (bed-weighted %, median establishment):\n")
print(bed_sus)
cat(sprintf("[2] Coverage: obstetric-bed share defined for %.1f%% of establishment-days, all-bed share for %.1f%%\n",
            100 * d[, mean(!is.na(sus_obst))], 100 * d[, mean(!is.na(sus_all))]))
cat(sprintf("[2] Contracted obstetrician hours per week: median %.0f, mean %.0f, share zero %.3f\n",
            median(d$lag_obst_hours_hosp), mean(d$lag_obst_hours_hosp),
            mean(d$lag_obst_hours_hosp == 0)))

# Terciles of the lagged obstetric-bed count across establishment-years. Ties at
# small counts make quantile breaks non-unique, so we split the ranked
# establishment-years into equal thirds, breaking ties by establishment id.
ey <- unique(d[, .(estab, year, lag_beds_obstetric)])
setorder(ey, lag_beds_obstetric, estab, year)
ey[, terc := cut(seq_len(.N), breaks = 3, labels = c("T1", "T2", "T3"))]
d <- merge(d, ey[, .(estab, year, terc)], by = c("estab", "year"), all.x = TRUE)

cat("\n[2] Obstetric-bed terciles (lagged), for-profit maternities:\n")
print(d[, .(estab_days = .N, births = sum(births),
            beds_min = min(lag_beds_obstetric), beds_max = max(lag_beds_obstetric),
            mean_beds = round(mean(lag_beds_obstetric), 1),
            mean_vol = round(mean(lag_vol)),
            pre_share = round(100 * weighted.mean(pre_share, births), 1)),
        by = terc][order(terc)])

# =============================================================================
# 3. Capacity table (Supplement): continuous + tercile heterogeneity
# =============================================================================
ctrl <- "weekend:log_vol + holiday:log_vol"
m1 <- feols(as.formula(paste("pre_share ~ weekend:log_beds + holiday:log_beds +", ctrl,
                             "| estab^year + date")),
            d, weights = ~births, cluster = ~estab + date)
m2 <- feols(as.formula(paste("pre_share ~ weekend:log_beds + holiday:log_beds +", ctrl,
                             "| estab^year + muni^date")),
            d, weights = ~births, cluster = ~estab + date)
m3 <- feols(as.formula(paste("pre_share ~ i(terc, weekend, ref = 'T1') +",
                             "i(terc, holiday, ref = 'T1') +", ctrl,
                             "| estab^year + muni^date")),
            d, weights = ~births, cluster = ~estab + date)
m4 <- feols(as.formula(paste("ces_share ~ weekend:log_beds + holiday:log_beds +", ctrl,
                             "| estab^year + muni^date")),
            d, weights = ~births, cluster = ~estab + date)
m5 <- feols(as.formula(paste("pre_share ~ weekend:log_obst + holiday:log_obst +", ctrl,
                             "| estab^year + muni^date")),
            d, weights = ~births, cluster = ~estab + date)

# fixest prints an interaction in whichever order it resolved it, so both orders
# are given a display name; otherwise a raw term such as "log_beds x holiday" leaks
# into the table.
dict <- c(pre_share = "Prelabor cesarean share", ces_share = "Cesarean share",
          "weekend:log_beds" = "Weekend $\\times$ log(1 + obstetric beds)",
          "log_beds:weekend" = "Weekend $\\times$ log(1 + obstetric beds)",
          "holiday:log_beds" = "National holiday $\\times$ log(1 + obstetric beds)",
          "log_beds:holiday" = "National holiday $\\times$ log(1 + obstetric beds)",
          "weekend:log_obst" = "Weekend $\\times$ log(1 + registered obstetricians)",
          "log_obst:weekend" = "Weekend $\\times$ log(1 + registered obstetricians)",
          "holiday:log_obst" = "National holiday $\\times$ log(1 + registered obstetricians)",
          "log_obst:holiday" = "National holiday $\\times$ log(1 + registered obstetricians)",
          "weekend:log_vol"  = "Weekend $\\times$ log(1 + annual deliveries)",
          "log_vol:weekend"  = "Weekend $\\times$ log(1 + annual deliveries)",
          "holiday:log_vol"  = "National holiday $\\times$ log(1 + annual deliveries)",
          "log_vol:holiday"  = "National holiday $\\times$ log(1 + annual deliveries)",
          "terc::T2:weekend" = "Weekend $\\times$ middle tercile of beds",
          "terc::T3:weekend" = "Weekend $\\times$ top tercile of beds",
          "terc::T2:holiday" = "National holiday $\\times$ middle tercile of beds",
          "terc::T3:holiday" = "National holiday $\\times$ top tercile of beds",
          estab = "Establishment", muni = "Municipality", date = "Date", year = "Year")

f <- file.path(TABLE, "tab_org_capacity.tex")
etable(m1, m2, m3, m4, m5, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("Prelabor", "Prelabor", "Prelabor (terciles)", "All cesareans",
                   "Prelabor (weak measure)"),
       title = "Organizational capacity and the weekend scheduling gradient",
       label = "tab:org_capacity",
       notes = paste("\\footnotesize\\textit{Notes:} Establishment-date cells at",
         "for-profit establishments with at least fifty deliveries in the previous year,",
         "SINASC 2016--2024 (the capacity measures are lagged one year and the facility",
         "panel opens in 2015), weighted by births. Obstetric beds and annual deliveries are",
         "measured at the establishment in the previous calendar year, so they are",
         "predetermined with respect to current scheduling. The municipality$\\times$date",
         "fixed effects of columns 2--5 restrict identification to municipality-days on",
         "which more than one for-profit establishment records a birth. Column 5 replaces",
         "obstetric beds with the count of obstetricians registered at the establishment",
         sprintf("in CNES-PF; %.0f percent of for-profit and %.0f percent of public maternities", zfp, zpub),
         "register none, because Brazilian obstetricians hold their bond at their own",
         "practice, so this is a weak proxy for the obstetric team and is",
         "reported for completeness only. Establishment size does not separate the",
         "individual physician's calendar from institutional staffing; both predict",
         "attenuation at larger establishments. Standard errors, two-way clustered by",
         "establishment and date, are reported in parentheses.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\footnotesize", tabcolsep = 3)
# wide table: shrunk to \\textwidth it prints at about 6pt, so typeset it in
# landscape, as tab08_mechanism_checks and tab13c_dip_by_region_period are
.tx <- readLines(f)
.tx <- gsub("\\begin{table}[H]", "\\begin{sidewaystable}\\centering", .tx, fixed = TRUE)
.tx <- gsub("\\end{table}", "\\end{sidewaystable}", .tx, fixed = TRUE)
writeLines(.tx, f)

cat("\n[3] Weekend x log(obstetric beds), prelabor share (pp per log point):\n")
print(round(100 * c(date_FE = coef(m1)[["weekend:log_beds"]],
                    munidate_FE = coef(m2)[["weekend:log_beds"]]), 3))
cat("[3] Tercile weekend interactions (pp):\n")
print(round(100 * coef(m3)[grep("weekend", names(coef(m3)))], 3))

# =============================================================================
# 4. Supplement: alternative measures and samples
# =============================================================================
m6 <- feols(pre_share ~ weekend:beds_per100 + holiday:beds_per100 + weekend:log_vol +
              holiday:log_vol | estab^year + muni^date, d,
            weights = ~births, cluster = ~estab + date)
m7 <- feols(pre_share ~ weekend:log_beds + holiday:log_beds + weekend:log_vol +
              holiday:log_vol | estab^year + muni^date, d[lag_vol >= 200],
            weights = ~births, cluster = ~estab + date)
m8 <- feols(pre_share ~ weekend:log_beds + holiday:log_beds + weekend:log_vol +
              holiday:log_vol | estab^year + muni^date, d,
            cluster = ~estab + date)   # unweighted
m9 <- feols(pre_share ~ weekend:log_beds + holiday:log_beds | estab^year + muni^date, d,
            weights = ~births, cluster = ~estab + date)   # no scale control

# Contracted obstetrician HOURS in place of the bed count (see the note above:
# a better-behaved measure of obstetric time than a headcount, same weak source).
m10 <- feols(pre_share ~ weekend:log_hours + holiday:log_hours + weekend:log_vol +
               holiday:log_vol | estab^year + muni^date, d,
             weights = ~births, cluster = ~estab + date)
# PAYER EXPOSURE. Adds the SUS share of the establishment's obstetric beds to the
# baseline capacity specification. A gradient generated by private-payer practice
# should be attenuated where a for-profit maternity serves the SUS, so the
# interaction is expected positive; a flat interaction says the calendar pattern
# is a property of the establishment rather than of the payer mix. Either way the
# level of the share is absorbed by the establishment x year fixed effects.
m11 <- feols(pre_share ~ weekend:sus_obst + holiday:sus_obst + weekend:log_beds +
               holiday:log_beds + weekend:log_vol + holiday:log_vol |
               estab^year + muni^date, d[!is.na(sus_obst)],
             weights = ~births, cluster = ~estab + date)
# Same specification on the SUS share of ALL beds, which is defined for every
# establishment carrying any bed and so does not drop the maternities that
# register no obstetric bed. Printed as a coverage check, not tabulated.
m12 <- feols(pre_share ~ weekend:sus_all + holiday:sus_all + weekend:log_beds +
               holiday:log_beds + weekend:log_vol + holiday:log_vol |
               estab^year + muni^date, d[!is.na(sus_all)],
             weights = ~births, cluster = ~estab + date)

k12w <- grep("^(weekend:sus_all|sus_all:weekend)$", rownames(coeftable(m12)), value = TRUE)
k12h <- grep("^(holiday:sus_all|sus_all:holiday)$", rownames(coeftable(m12)), value = TRUE)
dict2 <- c(dict, "weekend:beds_per100" = "Weekend $\\times$ obstetric beds per 100 deliveries",
           "beds_per100:weekend" = "Weekend $\\times$ obstetric beds per 100 deliveries",
           "holiday:beds_per100" = "National holiday $\\times$ obstetric beds per 100 deliveries",
           "beds_per100:holiday" = "National holiday $\\times$ obstetric beds per 100 deliveries",
           "weekend:log_hours" = "Weekend $\\times$ log(1 + contracted obstetrician hours)",
           "log_hours:weekend" = "Weekend $\\times$ log(1 + contracted obstetrician hours)",
           "holiday:log_hours" = "National holiday $\\times$ log(1 + contracted obstetrician hours)",
           "log_hours:holiday" = "National holiday $\\times$ log(1 + contracted obstetrician hours)",
           "weekend:sus_obst" = "Weekend $\\times$ SUS share of obstetric beds",
           "sus_obst:weekend" = "Weekend $\\times$ SUS share of obstetric beds",
           "holiday:sus_obst" = "National holiday $\\times$ SUS share of obstetric beds",
           "sus_obst:holiday" = "National holiday $\\times$ SUS share of obstetric beds")
f2 <- file.path(TABLE, "tab_org_capacity_valid.tex")
etable(m6, m7, m8, m9, m10, m11, tex = TRUE, file = f2, replace = TRUE, dict = dict2,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("Beds per 100 deliveries", "Larger maternities", "Unweighted",
                   "No scale control", "Contracted hours", "Payer exposure"),
       title = "Organizational capacity: alternative measures and samples",
       label = "tab:org_capacity_valid",
       notes = paste("\\footnotesize\\textit{Notes:} Variants of",
         "Table~\\ref{tab:org_capacity}, column 2. Column 1 replaces log obstetric beds",
         "with obstetric beds per 100 deliveries in the previous year. Column 2 restricts",
         "to establishments with at least 200 deliveries in the previous year. Column 3",
         "drops the birth weights. Column 4 drops the delivery-scale control. Column 5",
         "measures capacity by the obstetrician hours contracted at the establishment",
         "(CNES-PF), which distinguishes a four-hour registration from a forty-hour one",
         "and so is better behaved than the headcount, though it comes from the same",
         "registration source. Column 6 adds the SUS share of the establishment's",
         "obstetric beds, the only establishment-level measure of payer as distinct from",
         "ownership: it is",
         sprintf("%.2f at the median for-profit maternity-year, and %.1f percent of them",
                 median(sus_desc$sus_share), 100 * mean(sus_desc$sus_share > 0.5)),
         "place more than half of their obstetric beds with the SUS, so legal-entity",
         "type 2xxx identifies a predominantly private-payer population. Column 6 drops",
         "the establishments that register no obstetric bed, for which the share is",
         "undefined; measuring payer exposure by the SUS share of all beds keeps them",
         sprintf("and returns a weekend interaction of %.2f percentage points (standard error %.2f)",
                 100 * coeftable(m12)[k12w, 1], 100 * coeftable(m12)[k12w, 2]),
         sprintf("and a holiday interaction of %.2f (%.2f). All capacity",
                 100 * coeftable(m12)[k12h, 1], 100 * coeftable(m12)[k12h, 2]),
         "measures are lagged one year and their levels are absorbed by the",
         "establishment$\\times$year fixed effects. Because the measures are lagged and the",
         "facility panel opens in 2015, the sample starts in 2016; from then the CNES",
         sprintf("establishment code links %.1f percent of for-profit births (%.1f on weekdays,",
                 100 * link16, 100 * link16_wd),
         sprintf("%.1f on weekends), and", 100 * link16_we),
         sprintf("%.1f percent of the for-profit maternity-years in the estimation sample", 100 * zero_obst),
         "register no obstetrician in CNES-PF, which is why obstetric beds rather than",
         "registered obstetricians measure capacity. Standard errors, two-way clustered by",
         "establishment and date, are reported in parentheses.", SIGNIF_NOTE))
postprocess_tex(f2, fontsize = "\\footnotesize", tabcolsep = 3)
# wide table: shrunk to \\textwidth it prints at about 6pt, so typeset it in
# landscape, as tab08_mechanism_checks and tab13c_dip_by_region_period are
.tx <- readLines(f2)
.tx <- gsub("\\begin{table}[H]", "\\begin{sidewaystable}\\centering", .tx, fixed = TRUE)
.tx <- gsub("\\end{table}", "\\end{sidewaystable}", .tx, fixed = TRUE)
writeLines(.tx, f2)
unescape_refs(f2)

cat("\n[4] Payer exposure, weekend and holiday interactions (pp):\n")
pay <- function(m, v) {
  kk <- grep(sprintf("^(weekend:%s|%s:weekend|holiday:%s|%s:holiday)$", v, v, v, v),
             rownames(coeftable(m)), value = TRUE)
  ct <- coeftable(m)[kk, c(1, 2, 4), drop = FALSE]
  ct[, 1:2] <- 100 * ct[, 1:2]        # coefficient and SE in pp; the p-value is not scaled
  round(ct, 3)
}
cat("  SUS share of obstetric beds (column 6):\n"); print(pay(m11, "sus_obst"))
cat("  SUS share of all beds (coverage check):\n");  print(pay(m12, "sus_all"))
cat("[4] Contracted obstetrician hours, weekend and holiday interactions (pp):\n")
print(pay(m10, "log_hours"))

# fixest may order an interaction either way; look the terms up by name
kw <- grep("^(weekend:log_beds|log_beds:weekend)$", rownames(coeftable(m2)), value = TRUE)
kh <- grep("^(holiday:log_beds|log_beds:holiday)$", rownames(coeftable(m2)), value = TRUE)
# The delivery-scale interactions are in the family too: the paper
# reads the scale gradient as one of its fingerprints, so it has to face the
# same adjustment as the bed interactions.
vw <- grep("^(weekend:log_vol|log_vol:weekend)$", rownames(coeftable(m2)), value = TRUE)
vh <- grep("^(holiday:log_vol|log_vol:holiday)$", rownames(coeftable(m2)), value = TRUE)
fam_E <- data.table(
  family = "E. Organizational capacity",
  hypothesis = c("Weekend $\\times$ log(1 + obstetric beds)",
                 "National holiday $\\times$ log(1 + obstetric beds)",
                 "Weekend $\\times$ log(1 + annual deliveries)",
                 "National holiday $\\times$ log(1 + annual deliveries)"),
  estimate = c(coeftable(m2)[kw, 1], coeftable(m2)[kh, 1],
               coeftable(m2)[vw, 1], coeftable(m2)[vh, 1]),
  p = c(coeftable(m2)[kw, 4], coeftable(m2)[kh, 4],
        coeftable(m2)[vw, 4], coeftable(m2)[vh, 4]))
saveRDS(fam_E, file.path(here::here("analysis", "output"), "fam_E.rds"))

message("09_org_capacity.R done")
}
