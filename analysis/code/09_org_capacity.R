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
# deliveries in the previous year, about half register ZERO obstetricians and the
# median of the remainder is one, equally in the public and the for-profit
# sector. Brazilian obstetricians hold their CNES bond at their own practice, not
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
# RESULT (weak/mixed, reported honestly). Every interaction is positive (larger =
# flatter gradient) but only the delivery-SCALE interaction is significant
# (weekend x log deliveries ~ +0.70pp); beds x weekend ~ +0.45pp n.s. under
# muni x date FE; terciles are flat. This exhibit was MOVED to the Supplement in
# review round 2 (it came back weak, so featuring it in the body invited "why is
# this here"); Section 6D now carries a one-paragraph summary pointing to it.
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

# =============================================================================
# 1. Establishment x date cells of for-profit births (cached)
# =============================================================================
CELL_CACHE <- file.path(SIN, "sinasc_daily_estab.parquet")
if (!file.exists(CELL_CACHE)) {
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
cap <- cap[, .(estab = cnes, year, n_obstetricians, beds_obstetric, beds_total)]
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

d <- d[!is.na(lag_beds_obstetric) & lag_vol >= 50]   # maternities with a prior year
zero_obst <- unique(d[, .(estab, year, lag_n_obstetricians)])[, mean(lag_n_obstetricians == 0)]
cat(sprintf("[2] Establishment-years registering zero obstetricians in CNES-PF: %.1f%%\n",
            100 * zero_obst))

d[, `:=`(pre_share = n_pre / births, ces_share = n_ces / births,
         log_beds  = log(1 + lag_beds_obstetric),
         log_vol   = log(1 + lag_vol),
         log_obst  = log(1 + lag_n_obstetricians),
         beds_per100 = 100 * lag_beds_obstetric / pmax(lag_vol, 1))]

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
         "SINASC 2015--2024, weighted by births. Obstetric beds and annual deliveries are",
         "measured at the establishment in the PREVIOUS calendar year, so they are",
         "predetermined with respect to current scheduling. The municipality$\\times$date",
         "fixed effects of columns 2--5 restrict identification to municipality-days on",
         "which more than one for-profit establishment records a birth. Column 5 replaces",
         "obstetric beds with the count of obstetricians registered at the establishment",
         "in CNES-PF; about half of these maternities register none, equally in the public",
         "and the for-profit sector, because Brazilian obstetricians hold their bond at",
         "their own practice, so this is a weak proxy for the obstetric team and is",
         "reported for completeness only. Establishment size does not separate the",
         "individual physician's calendar from institutional staffing; both predict",
         "attenuation at larger establishments. Standard errors, two-way clustered by",
         "establishment and date, are reported in parentheses.", SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\footnotesize", tabcolsep = 3)

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

dict2 <- c(dict, "weekend:beds_per100" = "Weekend $\\times$ obstetric beds per 100 deliveries",
           "beds_per100:weekend" = "Weekend $\\times$ obstetric beds per 100 deliveries",
           "holiday:beds_per100" = "National holiday $\\times$ obstetric beds per 100 deliveries",
           "beds_per100:holiday" = "National holiday $\\times$ obstetric beds per 100 deliveries")
f2 <- file.path(TABLE, "tab_org_capacity_valid.tex")
etable(m6, m7, m8, m9, tex = TRUE, file = f2, replace = TRUE, dict = dict2,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2, digits = 4, digits.stats = 3,
       headers = c("Beds per 100 deliveries", "Larger maternities", "Unweighted",
                   "No scale control"),
       title = "Organizational capacity: alternative measures and samples",
       label = "tab:org_capacity_valid",
       notes = paste("\\footnotesize\\textit{Notes:} Variants of",
         "Table~\\ref{tab:org_capacity}, column 2. Column 1 replaces log obstetric beds",
         "with obstetric beds per 100 deliveries in the previous year. Column 2 restricts",
         "to establishments with at least 200 deliveries in the previous year. Column 3",
         "drops the birth weights. Column 4 drops the delivery-scale control. The CNES",
         "establishment code links",
         sprintf("%.1f percent of for-profit births in 2015--2024, and", 100 * birth_link),
         sprintf("%.1f percent of the for-profit maternity-years in the estimation sample", 100 * zero_obst),
         "register no obstetrician in CNES-PF, which is why obstetric beds rather than",
         "registered obstetricians measure capacity. Standard errors, two-way clustered by",
         "establishment and date, are reported in parentheses.", SIGNIF_NOTE))
postprocess_tex(f2, fontsize = "\\small", tabcolsep = 4)
unescape_refs(f2)

# fixest may order an interaction either way; look the terms up by name
kw <- grep("^(weekend:log_beds|log_beds:weekend)$", rownames(coeftable(m2)), value = TRUE)
kh <- grep("^(holiday:log_beds|log_beds:holiday)$", rownames(coeftable(m2)), value = TRUE)
fam_E <- data.table(
  family = "E. Organizational capacity",
  hypothesis = c("Weekend $\\times$ log(1 + obstetric beds)",
                 "National holiday $\\times$ log(1 + obstetric beds)"),
  estimate = c(coeftable(m2)[kw, 1], coeftable(m2)[kh, 1]),
  p = c(coeftable(m2)[kw, 4], coeftable(m2)[kh, 4]))
saveRDS(fam_E, file.path(here::here("analysis", "output"), "fam_E.rds"))

message("09_org_capacity.R done")
}
