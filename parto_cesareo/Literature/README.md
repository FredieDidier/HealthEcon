# Literature — Parto cesáreo vs. parto normal (economia)

Coletânea de papers de economia sobre cesárea, incentivos médicos e desfechos de parto.

**Nota importante sobre os arquivos `.txt`:** o ambiente onde esta coleta foi feita não
permite download de arquivos binários. Os `.txt` contêm o **texto integral extraído** dos
PDFs (versões working paper / open access) — servem para leitura, busca e citação, mas não
preservam tabelas, figuras e formatação. Para obter os PDFs originais, rode
`download_pdfs.sh` na sua máquina.

---

## Arquivos baixados (texto integral)

| # | Arquivo | Referência | Fonte |
|---|---------|-----------|-------|
| 1 | `1996_Gruber-Owings_...RAND.txt` | Gruber & Owings (1996), *RAND J. Econ.* 27(1):99-123 | NBER WP 4933 |
| 2 | `2008_Currie-MacLeod_...QJE.txt` | Currie & MacLeod (2008), *QJE* 123(2):795-830 | NBER WP 12478 |
| 3 | `2010_Almond-Doyle-Kowalski-Williams_...QJE.txt` | Almond, Doyle, Kowalski & Williams (2010), *QJE* 125(2):591-634 | NBER WP 14522 |
| 4 | `2014_Clemens-Gottlieb_...AER.txt` | Clemens & Gottlieb (2014), *AER* 104(4):1320-1349 | JMP version (UCSD) |
| 5 | `2016_Johnson-Rehavi_...AEJ-Policy.txt` | Johnson & Rehavi (2016), *AEJ: Econ. Policy* 8(1):115-141 | NBER WP 19242 |
| 6 | `2021_de-Elejalde-Giolito_...IZA-DP12297.txt` | de Elejalde & Giolito (2021), "A demand-smoothing incentive for cesarean deliveries", *JHE* 75:102411 | IZA DP 12297 |
| 7 | `2022_Costa-Ramon-et-al_...JHR.txt` | Costa-Ramón, Kortelainen, Rodríguez-González & Sääksvuori (2022), *JHR* 57(6):2048-2085 | JHR open PDF |
| 8 | `2023_Card-Fenizia-Silver_...AEJ-Policy.txt` | Card, Fenizia & Silver (2023), *AEJ: Econ. Policy* 15(2):42-81 | NBER WP 25986 |

## Adicionados na 2ª rodada (citados no `paper.tex`)

| # | Arquivo | Referência | Fonte |
|---|---------|-----------|-------|
| 9 | `2024_Bachner-Halla-Pruckner_...IZA-DP16981.txt` | Bachner, Halla & Pruckner (2024), "Do Empty Beds Cause Cesarean Deliveries?" | IZA DP 16981 |
| 10 | `2024_Melo-Menezes-Filho_...WP.txt` | Melo & Menezes-Filho (2024), *Health Economics* 33(9):2013-2058 | WP (Anais SBE) |
| 11 | `2025_Spinola-Rocha_...EJHE.txt` | Spinola & Rocha (2025), *Eur. J. Health Econ.* | Springer (OA) |
| 12 | `2026_Bensnes_...SSB-DP963.txt` | Bensnes (2026), *Health Economics* 35(2):175-211 | Statistics Norway DP 963 |

Ver `triagem_download.md` para o critério de priorização e o que ficou de fora.
Ver `verificacao_citacoes.md` para a checagem das 50 referências do `refs.bib`.

## Não obtidos (paywall / PDF sem texto)

| Referência | Motivo | Onde conseguir |
|-----------|--------|----------------|
| Gruber, Kim & Mayzlin (1999), *JHE* 18(4):473-490 | NBER WP 6744 é digitalização sem camada de texto (OCR ausente) | [NBER WP 6744](https://www.nber.org/papers/w6744) — baixar e rodar OCR |
| Costa-Ramón, Rodríguez-González, Serra-Burriel & Campillo-Artero (2018), *JHE* 59:46-59 | Elsevier, sem versão WP pública | [DOI](https://doi.org/10.1016/j.jhealeco.2018.03.004) — acesso institucional |
| Frakes (2013), *AER* 103(1):257-276 | AER paywall; SSRN exige login | [SSRN 1432559](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=1432559) |
| Kotsadam et al. (2022), *Scand. J. Econ.* 124(4):1056-1086 | Link DiVA retornou vazio | [DiVA](https://www.diva-portal.org/smash/get/diva2:1738710/FULLTEXT01.pdf) |

---

## Mapa da literatura

**Bloco 1 — Incentivos financeiros e demanda induzida**
Gruber & Owings (1996) · Gruber, Kim & Mayzlin (1999) · Johnson & Rehavi (2016) ·
Clemens & Gottlieb (2014) · Demand-smoothing (2021)

**Bloco 2 — Efeitos causais da cesárea sobre saúde**
Card, Fenizia & Silver (2023) · Costa-Ramón et al. (2018, 2022) · Almond et al. (2010) ·
Kotsadam et al. (2022)

**Bloco 3 — Litígio e regulação**
Currie & MacLeod (2008) · Frakes (2013)

## Estratégias de identificação usadas (para replicar com dados brasileiros)

| Estratégia | Paper | Viabilidade no Brasil (SINASC/SIH) |
|-----------|-------|------------------------------------|
| Choque de renda do médico (queda de fecundidade) | Gruber & Owings (1996) | Alta — variação municipal de fecundidade |
| Diferencial de honorário cesárea–normal | Gruber, Kim & Mayzlin (1999) | Alta — tabela SUS vs. tabelas de operadoras |
| Hora do dia / véspera de feriado | Costa-Ramón et al. (2018, 2022) | Alta — SINASC tem hora do nascimento |
| IV por distância a hospital de alta taxa | Card, Fenizia & Silver (2023) | Média — exige geocodificação |
| RD em limiar de peso ao nascer | Almond et al. (2010) | Alta — SINASC tem peso |
| Médicas como pacientes | Johnson & Rehavi (2016) | Baixa — sem identificação de ocupação |
| DiD de reforma regulatória | Currie & MacLeod (2008) | Alta — RN 368/2015 da ANS, Projeto Parto Adequado |
