# =============================================================================
# 10_heterogeneity.R — heterogeneity as theory tests (not decoration).
# The time-cost model predicts WHERE the scheduling motive binds hardest:
#   (a) OBSTETRICIAN SCARCITY: where obstetricians per birth are scarce, the
#       opportunity cost of an unschedulable delivery is higher → larger weekend
#       dip in the private sector.
#   (b) MOTHER'S EDUCATION (demand-side check): if scheduling reflected educated
#       mothers' own requests, the dip should be concentrated among them; similar
#       dips across education groups point to a supply-side (physician) driver.
#   (c) OPERATOR MODALITY (TISS): cooperativas médicas are physician-owned —
#       agency predicts (weakly) higher cesarean use than in insurer-run plans,
#       conditional on risk composition (maternal age band, muni, year).
#   Table 10 → tab10_heterogeneity (panels a-b) ; Table 10b → tab10b_modality
# =============================================================================

source(here::here("config", "config.R"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(data.table, arrow, fixest, here)
source(here::here("analysis", "code", "00_utils.R"))

SIN   <- file.path(DROPBOX_ROOT, "build", "SINASC", "input")
OUT   <- file.path(DROPBOX_ROOT, "build", "TISS", "output")
WFO   <- file.path(DROPBOX_ROOT, "build", "workfile", "output", "main_data.parquet")
TABLE <- here::here("analysis", "output", "tables")

# --- (a) weekend dip × obstetrician scarcity (private cells) ------------------
b <- as.data.table(read_parquet(file.path(SIN, "sinasc_births.parquet"),
       col_select = c("sector", "cesarean", "escolaridade_mae", "muni", "date",
                      "dow", "year")))
b <- b[year <= 2024 & sector == "Private"]
b[, weekend := as.integer(dow %in% c(1, 7))]

w <- as.data.table(read_parquet(WFO))
dens <- w[!is.na(obstetricians_per_1k_births),
          .(dens = mean(obstetricians_per_1k_births)), by = .(muni = muni6)]
dens[, low_dens := as.integer(dens < median(dens))]
b <- merge(b, dens[, .(muni, low_dens)], by = "muni", all.x = FALSE)

cell_a <- b[, .(rate = mean(cesarean), n = .N),
            by = .(muni, date, weekend, low_dens, year)]
m_dens <- feols(rate ~ weekend + weekend:low_dens | muni + year,
                cell_a, weights = ~n, cluster = ~muni)

# --- (b) weekend dip × mother's education (private births) --------------------
b[, educ_hi := fifelse(escolaridade_mae %in% 4:5, 1L,
              fifelse(escolaridade_mae %in% 1:3, 0L, NA_integer_))]
cell_b <- b[!is.na(educ_hi), .(rate = mean(cesarean), n = .N),
            by = .(muni, date, weekend, educ_hi, year)]
m_educ <- feols(rate ~ weekend + weekend:educ_hi | muni + year,
                cell_b, weights = ~n, cluster = ~muni)

dict <- c(weekend = "Weekend", "weekend:low_dens" = "Weekend $\\times$ Low obstetrician density",
          "weekend:educ_hi" = "Weekend $\\times$ Mother has 8+ years of schooling",
          muni = "Municipality", year = "Year", rate = "Cesarean share")
f <- file.path(TABLE, "tab10_heterogeneity.tex")
etable(m_dens, m_educ, tex = TRUE, file = f, replace = TRUE, dict = dict,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       headers = c("By obstetrician density", "By mother's education"),
       title = "Where the scheduling motive binds: theory-driven heterogeneity",
       label = "tab:heterogeneity",
       notes = paste("\\footnotesize\\textit{Notes:} Private-sector municipality-date",
         "cells, SINASC 2010--2024, weighted by births. Low obstetrician density =",
         "below-median obstetricians per 1,000 births (CNES professionals file). Education splits",
         "mothers at 8+ years of schooling. Standard errors clustered by municipality.",
         SIGNIF_NOTE))
postprocess_tex(f, fontsize = "\\small", tabcolsep = 5)
etable(m_dens, m_educ, dict = dict, fitstat = ~ n, digits = 4)

# --- (c) modality (TISS event workfiles): cooperativa vs insurer-run ----------
ev <- rbindlist(lapply(2015:2024, function(y)
  as.data.table(read_parquet(file.path(OUT, sprintf("delivery_events_%d.parquet", y)),
    col_select = c("cesarean", "modalidade", "faixa_etaria", "muni_prestador", "year")))))
ev <- ev[!is.na(modalidade) & modalidade != "" & !is.na(muni_prestador)]
ev[, coop := as.integer(grepl("^Cooperativa", modalidade))]
m_mod0 <- feols(cesarean ~ coop | muni_prestador + year, ev, cluster = ~muni_prestador)
m_mod1 <- feols(cesarean ~ coop + i(faixa_etaria) | muni_prestador + year, ev, cluster = ~muni_prestador)

f2 <- file.path(TABLE, "tab10b_modality.tex")
etable(m_mod0, m_mod1, tex = TRUE, file = f2, replace = TRUE,
       dict = c(coop = "Cooperativa m\\'edica (physician-owned operator)",
                cesarean = "Cesarean", muni_prestador = "Municipality", year = "Year"),
       keep = "%coop",
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       extralines = list("Maternal age-band controls" = c("No", "Yes")),
       fitstat = ~ n, digits = 4, digits.stats = 3,
       title = "Physician-owned operators (cooperativas) and cesarean use",
       label = "tab:modality",
       notes = paste("\\footnotesize\\textit{Notes:} TISS delivery events 2015--2024,",
         "municipality and year fixed effects. Cooperativas m\\'edicas (e.g.\\ Unimed)",
         "are physician-owned; agency predicts more discretion over the delivery",
         "decision than in insurer-run plans. Standard errors clustered by municipality.",
         SIGNIF_NOTE))
postprocess_tex(f2, fontsize = "\\small", tabcolsep = 5)
etable(m_mod0, m_mod1, keep = "%coop", fitstat = ~ n, digits = 4)

message("10_heterogeneity.R done")
