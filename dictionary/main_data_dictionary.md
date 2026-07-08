# Variable dictionary — `main_data.parquet`

The municipality-year analytical work-file, built by `build/03_workfile.R`. One
row per **municipality (6-digit IBGE) × year**, 2015–2024/25. The TISS private-
delivery panel is the spine; IEPS, CNES and SINASC covariates are left-joined.
Rows with a missing provider municipality are dropped; empty-subset means are `NA`.

| Variable | Type | Description | Unit | Source |
|---|---|---|---|---|
| `muni6` | string | Municipality identifier, 6-digit IBGE code (join key). | code | TISS `CD_MUNICIPIO_PRESTADOR` |
| `year` | int | Calendar year. | year | TISS `ANO_MES_EVENTO` |
| `tiss_deliveries` | int | Private deliveries (cesarean + vaginal) identified by TUSS codes. | count | TISS |
| `tiss_cesarean` | int | Private cesarean deliveries (TUSS 31309054/31309208). | count | TISS |
| `fee_cesarean` | double | Mean charged physician fee for cesarean, delivery-weighted. | R$ | TISS `VL_ITEM_EVENTO_INFORMADO` |
| `fee_vaginal_econ` | double | Mean *economic* vaginal fee = vaginal fee + hourly labor-assistance fee (TUSS 31309038). | R$ | TISS |
| `mean_los` | double | Mean length of stay of deliveries. | days | TISS `TEMPO_DE_PERMANENCIA` |
| `any_uti_share` | double | Share of deliveries with at least one ICU day. | 0–1 | TISS `QT_DIARIA_UTI` |
| `tiss_csection_rate` | double | Private cesarean rate = `tiss_cesarean` / `tiss_deliveries`. | 0–1 | TISS |
| `log_fee_gap` | double | Log economic fee gap = `log(fee_cesarean / fee_vaginal_econ)`. | log-ratio | TISS |
| `gdp_pc` | double | Real GDP per capita (municipal). | R$ thousands | IEPS |
| `pop_total` | int | Total resident population. | persons | IEPS |
| `plan_cov` | double | Private health-plan coverage. | % | IEPS |
| `prenatal` | double | Adequate prenatal care. | % | IEPS |
| `esf_cov` | double | Family Health Strategy (ESF) coverage. | % | IEPS |
| `inc_pc` | double | Mean household income per capita. | R$ | IEPS |
| `n_obstetricians` | int | Obstetricians registered (CBO obstetrician codes). | count | CNES-PF (microdatasus) |
| `sinasc_births` | int | All live births (every sector: public, nonprofit, private). | count | SINASC |
| `sinasc_cesarean` | int | All cesarean live births (every sector). | count | SINASC |
| `sinasc_priv_births` | int | Live births in **private (for-profit, nat. jurídica 2xxx)** establishments. | count | SINASC + CNES |
| `sinasc_priv_ces` | int | Cesarean live births in private establishments. | count | SINASC + CNES |
| `sinasc_csection_rate` | double | All-sector cesarean rate = `sinasc_cesarean` / `sinasc_births`. | 0–1 | SINASC |
| `sinasc_private_csection_rate` | double | Private-sector cesarean rate = `sinasc_priv_ces` / `sinasc_priv_births`. | 0–1 | SINASC + CNES |
| `obstetricians_per_1k_births` | double | `1000 * n_obstetricians / sinasc_births`. | per 1,000 | CNES + SINASC |
| `private_share_proxy` | double | Private-share proxy = `tiss_deliveries / sinasc_births`. | ratio | TISS + SINASC |

**Notes.**
- Missing values are `NA` (not `NaN`): a municipality-year with no vaginal (or no
  cesarean) delivery yields an empty-subset fee mean, set to `NA`.
- Sector definition (SINASC): establishment natureza jurídica **2xxx → Private
  (for-profit)**, **3xxx → Nonprofit (SUS-heavy filantrópico)**, else **Public**.
  The `sinasc_priv_*` columns use the for-profit (2xxx) definition only.
- Related dictionaries: TISS raw variables in `dictionary/Dicionario_de_variaveis_*.xlsx`;
  the SINASC individual-level base is `sinasc_births.parquet` (see `build/01d_sinasc_daily.R`).
