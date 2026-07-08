# =============================================================================
# build_dictionary.R
# Generates the variable dictionary for main_data.parquet as an Excel file.
# Output: dictionary/variable_dictionary.xlsx
# =============================================================================

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(openxlsx, here)

# ---- Variable definitions ---------------------------------------------------

dict <- data.frame(stringsAsFactors = FALSE,

  variable_name = c(
    # Keys
    "muni6", "year",
    # TISS deliveries and fees
    "tiss_deliveries", "tiss_cesarean", "tiss_csection_rate",
    "fee_cesarean", "fee_vaginal_econ", "log_fee_gap",
    "mean_los", "any_uti_share",
    # IEPS covariates
    "gdp_pc", "pop_total", "plan_cov", "prenatal", "esf_cov", "inc_pc",
    # CNES
    "n_obstetricians",
    # SINASC benchmark
    "sinasc_births", "sinasc_cesarean", "sinasc_priv_births", "sinasc_priv_ces",
    "sinasc_csection_rate", "sinasc_private_csection_rate",
    # Project-derived
    "obstetricians_per_1k_births", "private_share_proxy", "treated_parto_adequado"
  ),

  source = c(
    "Project-derived", "Project-derived",
    "TISS (ANS)", "TISS (ANS)", "TISS (ANS)",
    "TISS (ANS)", "TISS (ANS)", "TISS (ANS)",
    "TISS (ANS)", "TISS (ANS)",
    "IEPS", "IEPS", "IEPS", "IEPS", "IEPS", "IEPS",
    "CNES",
    "SINASC", "SINASC", "SINASC", "SINASC",
    "SINASC", "SINASC",
    "Project-derived", "Project-derived", "Project-derived"
  ),

  type = c(
    "character", "integer",
    "integer", "integer", "numeric",
    "numeric", "numeric", "numeric",
    "numeric", "numeric",
    "numeric", "integer", "numeric", "numeric", "numeric", "numeric",
    "integer",
    "integer", "integer", "integer", "integer",
    "numeric", "numeric",
    "numeric", "numeric", "integer"
  ),

  description_pt = c(
    "Código IBGE do município com 6 dígitos (chave de junção em todas as bases). Derivado de CD_MUNICIPIO_PRESTADOR (TISS) e dos códigos de 7 dígitos do SINASC/IEPS (primeiros 6 dígitos).",
    "Ano-calendário (2015-2025; TISS de 2025 é parcial — as análises usam year <= 2024).",
    "Número de partos privados (cesáreo + vaginal) identificados pelos códigos TUSS nos eventos TISS do município-ano.",
    "Número de partos cesáreos privados (TUSS 31309054 = cesariana; 31309208 = cesariana com histerectomia).",
    "Taxa de cesárea privada = tiss_cesarean / tiss_deliveries.",
    "Honorário médio informado (cobrado) da cesariana, ponderado pelo número de partos do município-mês. Em R$ correntes.",
    "Honorário ECONÔMICO médio do parto vaginal = honorário do parto (TUSS 31309127) + cobrança de assistência ao trabalho de parto por hora (TUSS 31309038; média ~2,7h a ~R$409/h). É a comparação de incentivo correta, pois o parto vaginal remunera horas adicionais que a cesárea agendada não gera.",
    "Log da razão de honorários = log(fee_cesarean / fee_vaginal_econ). O deslocador de incentivo financeiro. Negativo nos grandes estados (a cesárea paga MENOS que o parto vaginal econômico).",
    "Tempo médio de permanência dos partos (dias), ponderado por partos.",
    "Fração dos partos com pelo menos uma diária de UTI (QT_DIARIA_UTI > 0).",
    "PIB municipal per capita real (R$ mil). Coluna 'PIB P.C. Mun. Real' do IEPS.",
    "População residente total do município.",
    "Cobertura de planos de saúde privados (% da população).",
    "Pré-natal adequado (% dos nascidos vivos com acompanhamento adequado).",
    "Cobertura da Estratégia Saúde da Família (%).",
    "Renda domiciliar média per capita (R$).",
    "Número de obstetras registrados no município (CNES-PF, competência de dezembro; CBO 225250 médico ginecologista-obstetra e 225270).",
    "Total de nascidos vivos no município-ano, TODOS os setores (público + filantrópico + privado). Denominador-ouro do SINASC.",
    "Total de nascimentos por cesariana no município-ano (todos os setores).",
    "Nascidos vivos em estabelecimentos PRIVADOS com fins lucrativos (natureza jurídica 2xxx no CNES). NÃO inclui filantrópicos (3xxx).",
    "Nascimentos por cesariana em estabelecimentos privados com fins lucrativos.",
    "Taxa de cesárea de todos os nascimentos = sinasc_cesarean / sinasc_births.",
    "Taxa de cesárea do setor privado com fins lucrativos = sinasc_priv_ces / sinasc_priv_births.",
    "Obstetras por 1.000 nascidos vivos = 1000 × n_obstetricians / sinasc_births. Proxy da escassez de tempo obstétrico (usada na heterogeneidade do custo de tempo).",
    "Proxy da participação privada nos partos = tiss_deliveries / sinasc_births.",
    "=1 se o município possui hospital PRIVADO participante da Fase 2 do Projeto Parto Adequado (lista ANS de 11/02/2019, CNES→IBGE). Flag de exposição diluída, usada apenas como evidência de apoio (o event study rejeita tendências paralelas — ver 05_policy.R)."
  ),

  description_en = c(
    "6-digit IBGE municipality code (join key across all sources). Derived from CD_MUNICIPIO_PRESTADOR (TISS) and from the 7-digit SINASC/IEPS codes (first 6 digits).",
    "Calendar year (2015-2025; 2025 TISS is partial — analyses use year <= 2024).",
    "Number of private deliveries (cesarean + vaginal) identified by TUSS procedure codes in the municipality-year TISS events.",
    "Number of private cesarean deliveries (TUSS 31309054 = cesarean; 31309208 = cesarean with hysterectomy).",
    "Private cesarean rate = tiss_cesarean / tiss_deliveries.",
    "Mean charged physician fee for a cesarean, weighted by the municipality-month number of deliveries. Current R$.",
    "Mean ECONOMIC vaginal fee = delivery fee (TUSS 31309127) + separately-billed hourly labor assistance (TUSS 31309038; mean ~2.7h at ~R$409/h). The correct incentive comparison, since a vaginal delivery pays additional hours a scheduled cesarean does not generate.",
    "Log fee ratio = log(fee_cesarean / fee_vaginal_econ). The financial incentive shifter. Negative in the largest states (a cesarean pays LESS than the economic vaginal delivery).",
    "Mean length of stay of deliveries (days), delivery-weighted.",
    "Share of deliveries with at least one ICU day (QT_DIARIA_UTI > 0).",
    "Real municipal GDP per capita (R$ thousands). IEPS column 'PIB P.C. Mun. Real'.",
    "Total resident population.",
    "Private health-plan coverage (% of population).",
    "Adequate prenatal care (% of live births with adequate follow-up).",
    "Family Health Strategy (ESF) coverage (%).",
    "Mean household income per capita (R$).",
    "Number of obstetricians registered in the municipality (CNES-PF, December reference month; CBO 225250 gynecologist-obstetrician and 225270).",
    "Total live births in the municipality-year, ALL sectors (public + nonprofit + private). The SINASC gold-standard denominator.",
    "Total cesarean births in the municipality-year (all sectors).",
    "Live births in for-profit PRIVATE establishments (CNES natureza jurídica 2xxx). Does NOT include nonprofits (3xxx).",
    "Cesarean births in for-profit private establishments.",
    "All-births cesarean rate = sinasc_cesarean / sinasc_births.",
    "For-profit private-sector cesarean rate = sinasc_priv_ces / sinasc_priv_births.",
    "Obstetricians per 1,000 live births = 1000 × n_obstetricians / sinasc_births. Proxy for the scarcity of obstetric time (used in the time-cost heterogeneity).",
    "Private share proxy = tiss_deliveries / sinasc_births.",
    "= 1 if the municipality has a PRIVATE hospital participating in Phase 2 of the Parto Adequado project (ANS list of 11/02/2019, CNES→IBGE mapped). Diluted exposure flag, used as supporting evidence only (the event study rejects parallel trends — see 05_policy.R)."
  ),

  values_notes = c(
    "6-character zero-padded string (e.g. '355030' = São Paulo-SP). Always non-missing.",
    "2015-2025 (integer). Restrict to <= 2024 in analysis.",
    "Positive integer. Fee regressions require >= 20.",
    "Non-negative integer, <= tiss_deliveries.",
    "0-1 (share). ~0.82 delivery-weighted national mean.",
    "Positive R$ or NA (no cesarean with positive fee in the cell).",
    "Positive R$ or NA (no vaginal delivery in the cell — sparse munis).",
    "Real number or NA. Distribution: p10 ~ -0.34, median ~ 0.23, p90 ~ 0.82.",
    "Positive days. Long right tail (p90 = 3).",
    "0-1 (share). Median 0, p90 ~ 0.01.",
    "Positive (R$ thousands) or NA (~13% of muni-years unmatched to IEPS).",
    "Positive integer or NA.",
    "0-100 (%) or NA.",
    "0-100 (%) or NA.",
    "0-100 (%) or NA.",
    "Positive R$ or NA.",
    "Non-negative integer or NA (~7% unmatched).",
    "Positive integer or NA (~8% of TISS munis without SINASC match).",
    "Non-negative integer or NA.",
    "Non-negative integer or NA. Zero where no for-profit establishment delivers.",
    "Non-negative integer or NA.",
    "0-1 (share) or NA. ~0.57 national.",
    "0-1 (share) or NA (no private births in the muni-year). ~0.79 weighted.",
    "Positive or NA. Median ~30; long tail in small-birth munis.",
    "Positive or NA. Can exceed 1 when provider municipality attracts births of residents elsewhere (TISS uses provider muni; SINASC uses muni of occurrence).",
    "0 or 1 (integer). 58 treated municipalities (87 private Fase-2 hospitals)."
  )
)

# ---- Build workbook ---------------------------------------------------------

wb <- createWorkbook()
addWorksheet(wb, "Variables")

# Header style
header_style <- createStyle(
  fontSize    = 11,
  fontColour  = "#FFFFFF",
  fgFill      = "#1F3864",
  halign      = "CENTER",
  valign      = "CENTER",
  textDecoration = "bold",
  wrapText    = TRUE,
  border      = "Bottom",
  borderColour = "#FFFFFF"
)

# Body style — default
body_style <- createStyle(
  fontSize  = 10,
  valign    = "TOP",
  wrapText  = TRUE,
  border    = "TopBottomLeftRight",
  borderColour = "#D9D9D9"
)

# Source color styles
src_tiss    <- createStyle(fgFill = "#EBF3E8", fontSize = 10, valign = "TOP", wrapText = TRUE, border = "TopBottomLeftRight", borderColour = "#D9D9D9")
src_sinasc  <- createStyle(fgFill = "#FFF2CC", fontSize = 10, valign = "TOP", wrapText = TRUE, border = "TopBottomLeftRight", borderColour = "#D9D9D9")
src_cnes    <- createStyle(fgFill = "#FCE4D6", fontSize = 10, valign = "TOP", wrapText = TRUE, border = "TopBottomLeftRight", borderColour = "#D9D9D9")
src_ieps    <- createStyle(fgFill = "#DDEBF7", fontSize = 10, valign = "TOP", wrapText = TRUE, border = "TopBottomLeftRight", borderColour = "#D9D9D9")
src_project <- createStyle(fgFill = "#EDE7F6", fontSize = 10, valign = "TOP", wrapText = TRUE, border = "TopBottomLeftRight", borderColour = "#D9D9D9")

# Write header
writeData(wb, "Variables",
          x = data.frame(
            "Variable Name"     = "variable_name",
            "Source"            = "source",
            "Type"              = "type",
            "Description (PT)"  = "description_pt",
            "Description (EN)"  = "description_en",
            "Values / Notes"    = "values_notes",
            check.names = FALSE
          ),
          startRow = 1, colNames = TRUE
)
addStyle(wb, "Variables", header_style, rows = 1, cols = 1:6, gridExpand = TRUE)

# Write data rows with source-colored styles
for (i in seq_len(nrow(dict))) {
  r <- i + 1  # row 1 is header
  writeData(wb, "Variables",
            x       = dict[i, c("variable_name","source","type",
                                "description_pt","description_en","values_notes")],
            startRow = r, colNames = FALSE
  )
  sty <- switch(dict$source[i],
                "TISS (ANS)"      = src_tiss,
                "SINASC"          = src_sinasc,
                "CNES"            = src_cnes,
                "IEPS"            = src_ieps,
                "Project-derived" = src_project,
                body_style
  )
  addStyle(wb, "Variables", sty, rows = r, cols = 1:6, gridExpand = TRUE)
}

# Column widths
setColWidths(wb, "Variables", cols = 1, widths = 28)
setColWidths(wb, "Variables", cols = 2, widths = 18)
setColWidths(wb, "Variables", cols = 3, widths = 12)
setColWidths(wb, "Variables", cols = 4, widths = 50)
setColWidths(wb, "Variables", cols = 5, widths = 50)
setColWidths(wb, "Variables", cols = 6, widths = 55)

# Freeze header row
freezePane(wb, "Variables", firstRow = TRUE)

# ---- Legend sheet -----------------------------------------------------------
addWorksheet(wb, "Legend")
legend_df <- data.frame(
  Source = c("TISS (ANS)", "SINASC", "CNES", "IEPS", "Project-derived"),
  Color  = c("Green", "Yellow", "Orange", "Blue", "Purple"),
  Description = c(
    "ANS TISS Hospitalar private-insurance claims (open data): delivery counts, physician fees, length of stay, ICU days. Built by build/02_deliveries.R.",
    "SINASC live-birth registry via Base dos Dados (all births, exact date; sector from establishment CNES). Built by build/01b_sinasc_cnes.R.",
    "CNES establishment/professional registries: natureza jurídica (sector classifier) and obstetrician counts (CNES-PF via microdatasus).",
    "IEPS Data municipality-year covariates (manual export from iepsdata.org.br). Prepared by build/01c_ieps.R.",
    "Variable created in build/03_workfile.R for this research project (keys, ratios, the Parto Adequado exposure flag)."
  )
)
writeData(wb, "Legend", legend_df, startRow = 1)
addStyle(wb, "Legend", header_style, rows = 1, cols = 1:3)
addStyle(wb, "Legend", src_tiss,    rows = 2, cols = 1:3, gridExpand = TRUE)
addStyle(wb, "Legend", src_sinasc,  rows = 3, cols = 1:3, gridExpand = TRUE)
addStyle(wb, "Legend", src_cnes,    rows = 4, cols = 1:3, gridExpand = TRUE)
addStyle(wb, "Legend", src_ieps,    rows = 5, cols = 1:3, gridExpand = TRUE)
addStyle(wb, "Legend", src_project, rows = 6, cols = 1:3, gridExpand = TRUE)
setColWidths(wb, "Legend", cols = 1:3, widths = c(20, 12, 70))

# ---- Save -------------------------------------------------------------------
out_path <- here("dictionary", "variable_dictionary.xlsx")
saveWorkbook(wb, out_path, overwrite = TRUE)
message("Dictionary saved: ", out_path)
