# Contexto da pesquisa — *Born on Schedule*

**Título:** *Born on Schedule: Fees, Supply-Side Scheduling, and Cesarean Delivery in Brazil*
**Alvo:** Journal of Health Economics (Elsevier) · submissão prevista **março/2027**
**Autores:** Fredie Didier (IDP, correspondente) · Vinicius Mendes (UFBA) · Pablo Castro (UFBA) · Lucas Emanuel (UFBA)
**Repositório:** `scripts_github/` · **Dados:** `dataset/` · **Documento vivo do projeto:** `scripts_github/CLAUDE.md`
*Atualizado em 20/08/2026.*

---

## 1. A pergunta

O setor de maternidade com fins lucrativos brasileiro realiza cerca de **80% dos partos por cesárea** — a maior taxa documentada em qualquer sistema de saúde de grande porte, contra a referência da OMS de 10–15%. O excesso não se restringe a gestações complicadas: entre primíparas a termo, com feto único, bem posicionado e **já em trabalho de parto espontâneo** (Robson 1), dois terços dos partos for-profit em dia útil terminam em cesárea, contra cerca de um terço no setor público.

O paper pergunta **o que sustenta cirurgia nessa escala** e responde separando dois canais:

| Canal | Mecanismo | Veredito |
|---|---|---|
| **Preço** | Médicos fazem mais do que paga mais (Gruber–Owings) | **Não sustenta** |
| **Agenda (tempo)** | A cesárea converte um evento longo, de início incerto e que bloqueia o calendário em um procedimento agendado de ~1h | **Sustenta** |

O insumo mais escasso do obstetra não é receita faturável, é **tempo**. Separar o canal tempo do canal preço exige observar honorários médicos efetivos e o horário exato dos nascimentos no mesmo contexto — combinação que dados administrativos raramente oferecem. Este paper faz isso em escala nacional.

---

## 2. Dados

### 2.1 As duas populações "privadas" — MANTER DISTINTAS

Sobrepõem-se (~79–82%) mas **não são a mesma população**, e o SINASC não tem flag de pagador.

- **SINASC** → propriedade do **estabelecimento** (natureza jurídica). Chamar de **"for-profit"** (2xxx), vs. "nonprofit" (3xxx) e "public" (1xxx). ~79% de cesárea.
- **TISS** → sinistros financiados por **seguro privado**, privado por construção. Chamar de **"private-insurance sector"**. ~82% de cesárea.

Nunca escrever "private" puro para o grupo SINASC, nunca "private for-profit" (mistura pagador e propriedade). Contraste-manchete = **for-profit (2xxx) vs. público (1xxx)**.

### 2.2 Natureza jurídica → setor (pelo PRIMEIRO dígito)

| 1º dígito | Grupo IBGE/CONCLA | Setor |
|---|---|---|
| 1 | Administração Pública | **Public** |
| 2 | Entidades Empresariais | **Private** (for-profit) |
| 3 | Entidades sem Fins Lucrativos | **Nonprofit** |
| 4 / 5 / não pareado | — | **Other** (excluído) |

Prioridade quando o estabelecimento aparece sob vários códigos: for-profit > nonprofit > public.
**`Public` tem de ser o conjunto EXPLÍCITO 1xxx, nunca o balde `else`.** O código pré-11/07/2026 mandava todo estabelecimento não pareado para Public (~1,17M nascimentos, 6,4% do "Public") — bug de rotulagem. Impacto numérico foi desprezível (42,73%→42,74%) porque os não pareados se comportam como SUS, mas o código corrigido os rotula `Other` e os exclui do contraste-manchete. **Não reintroduzir `else → Public`.**

### 2.3 O que existe na pasta `dataset/` (verificado)

| Fonte | Arquivo | Conteúdo |
|---|---|---|
| **SINASC** | `SINASC/input/sinasc_births.parquet` | **42.003.663 nascimentos**, 2010-01-01 a 2024-12-31, 32 colunas |
| | `sinasc_daily_muni.parquet` | 8.805.014 células muni × data × setor |
| | `sinasc_daily_timing_muni.parquet` | 4.217.907 células, com contagens pré-parto/intraparto/vaginal |
| | `sinasc_daily_estab.parquet` | 1.534.506 células estabelecimento × data (for-profit) |
| **TISS** | `TISS/input/Hospitalar/{CONS,DET}/Hosp_{2015..2025}_*.parquet` | 22 arquivos, 5,1 GB brutos |
| | `TISS/output/delivery_events_{2015..2025}.parquet` | eventos de parto com honorários |
| | `TISS/output/delivery_panel_muni_month.parquet` | 88.116 município-meses |
| **CNES** | `cnes_estab_year.parquet` | 84.213 estabelecimento-anos (leitos, obstetras, nat_jur) |
| | `cnes_beds_muni_year.parquet` | leitos por competência **MENSAL** — usar só dezembro ao agregar |
| **IEPS** | `ieps_muni_year.parquet` | covariáveis municipais |
| **workfile** | `workfile/output/main_data.parquet` | **11.567 município-anos, 26 colunas** — o arquivo analítico final |
| Auxiliares | 16 tabelas de terminologia TISS, `PLANOS.csv`, Parto Adequado Fase 2 | |

**Descompasso de caminho a resolver:** o código monta `file.path(DROPBOX_ROOT, "build", "TISS", ...)`, mas a pasta local é `dataset/TISS/...` — falta o nível `build/`. Ver `ROADMAP.md`, item R1.

### 2.4 Variáveis-chave

| Variável | Descrição | Fonte |
|---|---|---|
| `cesarean` | TISS: TUSS 31309054/31309208 vs. vaginal 31309127. SINASC: `tipo_parto==2` | TISS/SINASC |
| `sector` / `private` | Setor pelo 1º dígito de `nat_jur`; `private`=1 sse for-profit (2xxx) | SINASC×CNES |
| `cesarea_antes_parto` | 1=pré-parto, 2=intraparto. **Utilizável a partir de 2012** (98% missing em 2010, 53% em 2011, <15% de 2012 em diante) | SINASC |
| `fee_vaginal_econ` | Honorário vaginal **econômico** = honorário do parto + assistência horária ao trabalho de parto (TUSS 31309038) | TISS DET |
| `log_fee_gap` | log(fee_cesarean / fee_vaginal_econ). **Negativo nos grandes estados** | TISS |
| `tipo_robson` | Robson "01".."11" (01 = trabalho de parto espontâneo). Populado a partir de ~2014 | SINASC |
| `weekend`, `holiday`, `eve` | Feriados móveis via algoritmo gregoriano anônimo (Sexta-feira Santa, Carnaval seg+ter, Corpus Christi) | derivado |
| capacidade do estabelecimento | `beds_obstetric` (tipo_leito==4, competência dezembro), `beds_total`, `n_obstetricians`, `n_physicians`, `vol`, defasados em um ano | CNES via 01d |

**Classificadores CBO** (`build/00_utils.R`): **obstetra = exatamente {225250, 223132, 6149, 6145}** — o conjunto antigo `225250`+`225270` estava errado (225270 é estratégia de família). Médico (todos) = CBO-94 6105–6190, CBO-2002 223101–223157 e 225103–225350, mais 2231A1–2231G1.

---

## 3. Estratégia empírica

### Equação (1) — canal preço
$$\text{CesareanRate}_{mt} = \beta\,\text{LogFeeGap}_{mt} + X_{mt}'\gamma + \mu_m + \delta_t + \varepsilon_{mt}$$
Município-ano, ponderado por partos privados, EP com cluster na geografia do efeito fixo. A hipótese de demanda induzida prevê $\beta>0$. Complementada por uma falsificação em primeira diferença no gap estadual.

### Equação (2) — gradientes de calendário descritivos
$$\text{CesareanShare}_{mdt} = \beta_1\text{Weekend}_d + \beta_2\text{Holiday}_d + \beta_3\text{Eve}_d + \mu_m + \delta_t + \varepsilon_{mdt}$$
Estimada **separadamente** para for-profit e público. Cluster duplo (município, data).

### Equação (3) — **a especificação central**
$$\text{CesareanShare}_{mds} = \gamma_1(\text{ForProfit}_s\times\text{Weekend}_d) + \gamma_2(\text{ForProfit}_s\times\text{Holiday}_d) + \gamma_3(\text{ForProfit}_s\times\text{Eve}_d) + \lambda_{md} + \phi_{ms} + \varepsilon_{mds}$$

$\lambda_{md}$ = EF município×data (absorve **todo** choque comum aos dois setores naquele dia local — inclusive clima), $\phi_{ms}$ = EF município×setor. Ponderado por nascimentos, cluster duplo.

**Este é o único desenho reconhecível do paper.** Todo o resto é mecanismo, magnitude ou robustez em torno dele. Causal apenas sob a hipótese de gradiente comum: $E[\Delta Y^0_{md}\mid\text{for-profit}] = E[\Delta Y^0_{md}\mid\text{público}]$. **Chamar de *differential*, nunca de difference-in-differences.**

---

## 4. Taxonomia de evidência — manter a rotulagem em TODO lugar

Vale para abstract, introdução, seção de estratégia, notas de tabela e conclusão.

| Resultado | Rótulo obrigatório |
|---|---|
| Regressões de honorário | Associações condicionais, **sinal instável**. Dizer "no robust positive price relationship", nunca "fees don't matter" |
| Gradientes de fim de semana/feriado (Eq. 2) | **Ordenação de calendário** dos partos, NÃO o efeito causal de um fim de semana aleatório. Nunca escrever "o dia em que o parto cai é tão bom quanto aleatório em relação à necessidade médica" — a data observada é em parte escolhida |
| Eq. (3) | O **differential** for-profit–público dentro do município-dia; causal só sob gradiente comum |
| Split pré-parto vs. intraparto | Evidência de **mecanismo** (o dip se concentra nas cesáreas pré-parto; intraparto vai na direção oposta = deslocamento) |
| Taxonomia de feriado prolongado + event study | As previsões mais afiadas de lazer médico **NÃO se confirmam**. Reportar o nulo honestamente; ele delimita a alegação de "conveniência de quem" |
| Heterogeneidade de capacidade organizacional | "Redundância organizacional atenua o gradiente", NÃO "o calendário do médico individual vs. o hospital" |
| Perfil por grupo de Robson + termo/pré-termo + idade materna | **Corroboração, NÃO placebo.** Grupo de Robson e idade gestacional são em parte determinados pelas mesmas decisões sob estudo. Pré-termo ≠ não agendável (pré-eclâmpsia, RCIU, late-preterm eletivo são todos agendados) |
| Decomposição de Kitagawa | Contabilidade; 72% estilo de prática |
| ~50 mil cesáreas de dia útil em excesso | Benchmark mecânico, não cesáreas causadas |
| Early-term +11,7pp | Associação setor–idade gestacional |
| Parto Adequado | Falha de um **desenho** causal (pré-tendências), não efeito de programa |

**Frase-padrão de escopo:** *"The evidence identifies calendar sorting and a tightly controlled for-profit–public differential; it does not identify the total number of cesareans or neonatal outcomes caused by scheduling."*

---

## 5. Resultados centrais

1. **A epidemia é real e extrema** — cesárea for-profit ~82% (TISS) / ~79% (SINASC) vs. ~44% público; ~66% mesmo no Robson 1 em dia útil.
2. **Não é uma história de preço positivo** — com o honorário vaginal *econômico*, o gap é **negativo** nos grandes estados e eles rodam ~80% de cesárea; o coeficiente é pequeno e instável (+0,017 EF-UF / −0,014 EF-município, n.s.); oscilações de ±2 pontos log no estado não movem nada; a ordem judicial de 2015 nunca virou mudança de honorário.
3. **É uma história de agenda** — cesáreas se aglomeram em dias úteis e caem em fins de semana (−8,3pp for-profit / −6,7pp público) e feriados (−5,6 / −3,5); pico de centro cirúrgico às 8–11h; metade das cesáreas em horário comercial de dia útil, contra benchmark uniforme de 29,8%.
4. **Eq. (3), a estimativa central** — dentro do mesmo município-dia, o differential for-profit é **−2,3pp fim de semana / −2,9pp feriado**, praticamente inalterado (−2,2 / −2,6) após ajustar por composição materna predeterminada.
5. **O dip vive nas cesáreas pré-parto** — dip de fim de semana for-profit de −9,7pp pré-parto vs. **+1,7pp** intraparto; persiste em Robson 1–2 de baixo risco (−7,4pp) e em Robson 1 sozinho (−6,5pp).
6. **O custo** — +11,7pp de early-term (37–38 sem) com controles maternos; 72% estilo de prática (Kitagawa); ~50 mil cesáreas de dia útil em excesso por ano; quase paridade nos valores faturados.

### Números de referência (checagem de sanidade; SINASC = 2010–2024)

| Fato | Valor |
|---|---|
| Cesárea (todos / for-profit / nonprofit / público) | ~57% / **79,46%** / 59,24% / **42,74%** |
| Nascimentos totais SINASC | 42.003.663 |
| Dip de fim de semana (for-profit / público) | −8,3pp / −6,7pp |
| Dip de feriado (for-profit / público) | −5,6pp / −3,5pp |
| **Eq. (3) differential (EF muni×data)** | **fds −2,3pp / feriado −2,9pp**; +predeterminado −2,2 / −2,6; +Robson −1,9 / −2,3 |
| Dip de fds: pré-parto vs. intraparto (for-profit) | −9,7pp vs. +1,7pp |
| Robson 1–2 / Robson 1 (for-profit) | −7,4pp / −6,5pp |
| Perfil Robson, for-profit vs. público (Fig 3c) | G1 −6,3/−3,7 · G2 −5,2/−3,8 · G3 −8,0/−3,0 · G4 −9,1/−4,2 · G5 −3,6/−5,8 · G10 **−5,1/−5,2 (idêntico)** |
| Eq. (3), termo vs. pré-termo | −2,5pp vs. **+0,8pp**; diferença +3,4pp, p<0,001 |
| Eq. (3), mãe <35 vs. 35+ | −3,0pp vs. +1,3pp (dif +4,3, p<0,001); dentro de Robson 1–2, −5,0 vs. −1,4 |
| Feriado prolongado: teste bridge = isolated | p≈0,68 (pré-parto p≈0,95) — **sem** efeito bridge maior |
| Bunching pré-feriado (bridge) | −0,46/dia (**déficit**, não bunching) |
| Capacidade: fds×log(leitos) pré-parto | +0,45pp n.s.; escala +0,70pp* |
| Maternidades com zero obstetras (CNES-PF, ≥50 partos) | 14% for-profit / 27% público (mediana 3/2) |
| Early-term (37–38 sem), controles maternos | **+11,7pp*** |
| Kitagawa: gap de 35,1pp | 28% case-mix / **72% estilo de prática** |
| Cesáreas de dia útil em excesso | ~50 mil/ano for-profit (~10,5%) |
| `log_fee_gap` (EF UF / município) | +0,017 / −0,014 (n.s.) |

---

## 6. As duas extensões de 10/07/2026 e seus resultados honestos

**Feriados prolongados + deslocamento** (`08_long_weekends.R`, Tabela 4). Exercício pré-especificado único: desfecho primário = participação de cesárea pré-parto, janela [−3,+3], amostra = 8 feriados nacionais de data fixa, 2012–2024. Taxonomia por dia da semana: **Isolated = quarta-feira** (o caso verdadeiramente isolado — um feriado em seg/sex já cria um fim de semana de 3 dias), **ThreeDay = seg/sex**, **Bridge = ter/qui**, feriado que cai no fim de semana = placebo.
**RESULTADO = NULO na direção prevista.** O dip de bridge não é maior que o de isolated (p≈0,68); não há bunching pré-feriado (−0,46/dia, um déficit); partos vaginais também caem em torno de feriados → parte disso é **contração da atividade institucional**, não rearranjo de agenda. Isso **delimita** a alegação de "conveniência de quem": a evidência de calendário identifica agendamento pelo lado da oferta, mas não que seja o lazer do médico individual.

**Capacidade organizacional** (`09_org_capacity.R`, suplemento Tabela D.8). Painel estabelecimento-data de nascimentos for-profit; capacidade = **leitos obstétricos** (defasados um ano, predeterminados) + volume anual como controle de escala; EF `estab^year + muni^date`.
**Achado de validação:** a contagem de obstetras do CNES-PF é um proxy **fraco** — entre maternidades com ≥50 partos, **14% (for-profit) / 27% (público) registram ZERO obstetras** (mediana 3/2), porque o obstetra brasileiro mantém seu vínculo CNES no consultório próprio, não no hospital do parto. Leitos carregam a análise.
**RESULTADO fraco/misto:** todas as interações são positivas (maior = gradiente mais achatado) mas só a interação de **escala** é significativa (fds×log partos ≈ +0,70pp); leitos×fds ≈ +0,45pp n.s.
Permitido: "serviços obstétricos maiores atenuam o gradiente de fim de semana". Proibido: "prova que é o calendário do médico individual e não a capacidade do hospital".

---

## 7. O modelo (Apêndice A, `latex/model.tex`)

O médico pondera o gap de honorário $f_c - f_v$ contra um prêmio de conveniência $\Pi$ (valor de converter um evento não agendável, longo e bloqueador de calendário em um procedimento agendado de ~1h). Opera se e somente se $(f_c-f_v)+\Pi > \alpha\theta$. **$\Pi>0$ mesmo quando o gap de honorário é negativo** — exatamente o que os dados mostram.

Previsões: **P1** honorários não operativos (nulos da Tabela 1); **P2** pré-parto se aglomera em horário comercial de dia útil, intraparto herda início aleatório (Tabela 2, cols 4–5); **P3** dip maior onde o tempo obstétrico é escasso (extensão de capacidade, mais fraca do que se esperava); **P4** agendamento antes do risco da semana 39 → excesso de early-term (Tabela 5).

---

## 8. Estrutura do repositório e do pipeline

```
config/   config.R (DROPBOX_ROOT — a única edição por máquina)
          00_master_build.R · 00_master_analysis.R
build/    00_utils.R · 01a_tiss.R · 01b_sinasc_cnes.R · 01c_ieps.R
          01d_cnes_estab.R (RUN_01D=1) · 02_deliveries.R · 03_workfile.R
analysis/ code/ 00_utils.R · 01_descriptives · 02_regressions (preço) ·
                03_mechanisms · 04_heterogeneity · 05_cost · 06_robustness ·
                07_main_specification (Eq 3) · 08_long_weekends ·
                09_org_capacity · 10_supplement · 12_subgroups · 11_body_figures
          output/{graphs,tables,maps}  — versionado no git
latex/    paper.tex · model.tex · appendix.tex · supplement.tex ·
          sup_appendix.tex · refs.bib · highlights.txt
```

### Ordem de execução — importa na cauda

- **07 / 08 / 09** salvam cada um uma família de hipóteses (`fam_{A,D,E}.rds`) que **10** lê para a tabela de testes múltiplos.
- **12 roda ANTES de 11**, apesar do número: salva `robson_grad.rds`, os coeficientes que **11** desenha como painel (c) da Figura 3.
- **Não rodar dois scripts de 42M linhas em paralelo** (03, 05, 06, 07, 08, 09, 12) — cada um carrega `sinasc_births.parquet`; dois juntos esgotam a memória (12 sozinho chega a ~14 GB). Pico ~12 GB, análise completa ~90 min, `07` sozinho ~40 min.

### Mapa de exhibits (corpo: 3 figuras + 6 tabelas)

| Exhibit | Script | Conteúdo |
|---|---|---|
| **Figura 1** `fig01_csection_trend` | 01 | Taxa de cesárea por setor ao longo do tempo |
| **Figura 2** `fig_two_margins` | 11 | (a) binscatter da margem de preço; (b) margem de agenda. O único exhibit com os dois canais lado a lado |
| **Figura 3** `fig_calendar_fingerprints` | 11 (+12) | (a) DOW × setor, (b) hora do nascimento, (c) gradiente por grupo de Robson |
| **Tabela 1** `tab_fees` | 02 | Honorários: Painel A níveis (Eq 1) + Painel B primeira diferença estado-ano |
| **Tabela 2** `tab_main_gradient` | 07 | **Eq (3)**: Painel A differential; Painel B gradiente próprio de cada setor |
| **Tabela 3** `tab_prelabor_lowrisk` | 03 | Dip de fds por pré-parto/intraparto × Robson 1–2 / Robson 1 |
| **Tabela 4** `tab_long_weekends` | 08 | Taxonomia de feriado (A) + somas de deslocamento (B) |
| **Tabela 5** `tab09_health` | 05 | Early-term / baixo peso / Apgar baixo |
| **Tabela 6** `tab11_decomposition` | 03 | Kitagawa + cesáreas de dia útil em excesso |

**Se mover um exhibit, re-derivar o mapa de `paper.aux`** (`grep -o "newlabel{tab:[^}]*}{{[^}]*}" paper.aux`) — nunca renumerar à mão.

Suplemento reorganizado em três apêndices: **C** = figuras/tabelas descritivas adicionais · **D** = robustez, validação e inferência · **E** = o registro de política (Parto Adequado + linha do tempo da RN 368).

### Compilação — o `xr` roda nos DOIS sentidos

`supplement.tex` precisa de `paper.aux` **e** `paper.tex` precisa de `supplement.aux` (as ~29 referências `\satab`/`\safig`). O ciclo tem de rodar duas vezes e **os `.aux` precisam sobreviver entre as passadas** — nunca limpar no meio:

```bash
cd latex
pdflatex paper; bibtex paper
pdflatex supplement; bibtex supplement; pdflatex supplement
pdflatex paper; pdflatex paper
pdflatex supplement
```
Verificar com `grep -c "Reference .* undefined" paper.log` → tem de dar **0**.

---

## 9. Convenções de código

- **R** com `data.table`/`arrow`/`fixest`; `pacman::p_load`. Preferir subsets de coluna preguiçosos a carregar arquivos inteiros.
- Chave de município = **IBGE 6 dígitos** (SINASC dá 7 → primeiros 6).
- Figuras: `theme_paper()` + `PAL`, sem títulos, PDF+PNG via `save_fig()`. **Nunca `scale_y_continuous(limits=)`** — descarta pontos silenciosamente; usar `breaks` ou `coord_cartesian`.
- **Tamanho da figura = tamanho impresso (`FIG_WIDTH = 6.5`).** Salvar mais largo que a largura impressa faz o `\includegraphics` reduzir a figura *e a tipografia junto*. **Nunca passar de 6,5in — adicionar uma linha, não uma coluna.**
- Tabelas via `etable` + `dict`; `postprocess_tex()`; **todas as legendas em negrito**. Tabelas com ≥6 colunas → `sidewaystable`.
- **`fixest`**: uma interação pode resolver como `a:b` ou `b:a` — procurar em `rownames(coeftable(m))` ou dar entrada `dict` para as duas ordens. Em `i(x, ..., ref=0)`, passar `ref=0` quando o EF já contém o indicador, senão o termo fica colinear e a estimativa explode.
- Não cachear objetos `fixest` inteiros (carregam a matriz de desenho — um cache chegou a 1,1 GB). Reduzir a `list(ct=, V=, n=)`.
- **Nunca commitar dados**; commitar/dar push só quando pedido.

---

## 10. Bugs corrigidos — não reintroduzir

| Bug | Correção | Impacto |
|---|---|---|
| `else → Public` na classificação de `nat_jur` | Conjunto explícito 1xxx; não pareados vão para `Other` | 42,73%→42,74%; fortaleceu Eq (3) de −1,8/−2,4 para −2,3/−2,9 |
| `holiday_dates(2015:2024)` em `03_mechanisms.R` | → `holiday_dates(2010:2024)`; o arquivo diário cobre 2010–2024 | Coeficiente de feriado diluído de −5,6 para −5,3 |
| CBO de obstetra `225250`+`225270` | → `{225250, 223132, 6149, 6145}` + download completo de 27 UFs | "46%, igualmente, mediana 1" → 14%/27%, mediana 3/2 |
| DF codificado por região administrativa no CNES | `fix_muni_df()` em `build/00_utils.R`, aplicado em `01b` | Brasília: 451→857 obstetras em 2015. **Recodificar ANTES do `uniqueN()`, nunca depois** |
| Figura 3 salva com 15in e impressa em 6,5in | `FIG_WIDTH = 6.5` | Rótulos de 10pt renderizados a 4,3pt |
| `i(x, ...)` sem `ref=0` no script 08 | `ref=0` | Termo colinear com o EF, estimativa explodia |

**Projetos irmãos atingidos pelo bug do DF:** HealthHeat (SIH `MUNIC_RES` perde 86/92/93% das internações do DF em 2015/16/17) e WorldCupHealth (SIH quebrado 2008–2017). SIH se resolve em 2018, CNES em 2017 — não inferir um do outro.

---

## 11. Limites honestos (o teto de identificação)

- Sem IDs de operadora/hospital/médico no TISS; preços pagos ~5% populados; sem painel de adesão/prêmio.
- TISS é mensal (o SINASC dá o grão diário).
- **Sem choque de política com timing diferencial limpo**: o Parto Adequado falha tendências paralelas, os choques de honorário são nulos.
- A contagem de obstetras do CNES-PF não mede a equipe de plantão.
- Os nulos de feriado prolongado significam que a evidência de calendário identifica agendamento pelo lado da oferta, **mas não a conveniência de quem**.

### Posicionamento sobre custo clínico

**Não** construir novos programas empíricos sobre mortalidade materna / UTI neonatal / morbidade neonatal ampla — a seleção domina (o for-profit mostra baixo peso e Apgar baixo *menores*), o poder é inadequado. "Por que importa" = (a) o resultado próprio de early-term; (b) magnitudes; (c) precificar o dano com a literatura (Tita 2009 NEJM; Costa-Ramón 2018 JHE; Card, Fenizia & Silver 2023 AEJ:Policy; Sandall 2018 Lancet). A checagem neonatal sugestiva do TISS é nula e subdimensionada — manter por transparência, **não destacar**.

---

## 12. Posicionamento na literatura

**Suspeito natural e literatura de apoio:** agência imperfeita do médico (Dranove 1988; McGuire 2000); demanda induzida financeira (Gruber & Owings 1996; Gruber, Kim & Mayzlin 1999; Clemens & Gottlieb 2014). **Mas o canal financeiro não é universal**: Grant (2009) acha que incentivos de honorário explicam pouco; Alexander (2020) mostra respostas não intencionais.

**Parto como laboratório de agência:** Currie & MacLeod (2008, pressão de responsabilidade); Johnson & Rehavi (2016, médicos tratando médicos); Card, Fenizia & Silver (2023, propensão hospitalar prejudica o recém-nascido marginal).

**Contribuição:** ao longo dessa literatura a margem operativa é dinheiro. Este paper mostra que **o insumo escasso é tempo**, e faz o diagnóstico conjunto honorários-versus-tempo no mesmo cenário.

**Parfitt & Goulart (2026 JDE, ondas de calor em maternidades brasileiras)** é o estudo contemporâneo mais próximo, citado e distinguido: os EF município×data absorvem temperatura; o estimando é outro. Nota de rodapé registra que as definições de setor **não são comparáveis** entre Parfitt (enfermarias públicas), Melo (classes de alocação de leito) e este paper (natureza jurídica).

**Bloco de capacidade/pessoal/lotação:** Maibom (2021, JHE); Bensnes (2026, Health Econ); Facchini (2022, JEBO); Bachner (2024, IZA DP 16981). **Timing:** Cohen (1983); Spetz (2001); Spinola (2025, EJHE); Gans (2012); Lo (2003); Dickert-Conlin & Chandra (1999); Gans & Leigh (2009).

**Carnaval reconciliado:** "Neither prediction survives in our fixed-date holiday design" + não contradição explícita de Melo (o Carnaval é móvel, longo, saliente, e excluído da `eq:blocks`). Todas as alegações de feriado prolongado qualificadas como "ordinary fixed-date national holidays".

---

## 13. Histórico de revisões

| Data | O que mudou |
|---|---|
| **10/07/2026** | Eq (3) virou a espinha dorsal; corpo enxugado para 6–7 tabelas + 3 figuras; política desenfatizada; duas novas análises (feriados prolongados, capacidade) vieram nulas e foram reportadas honestamente; terminologia padronizada. `07_referee_response.R` dividido em `07_main_specification.R` + `10_supplement.R` |
| **11/07/2026** | Correção do `nat_jur` (`else → Public`); reconstrução CBO/CNES-PF |
| **12/07/2026** | `fig_two_margins` criada; figura de idade gestacional e event study de deslocamento movidos para o suplemento |
| **16/07/2026** | Proof Patrol round 3: Parfitt posicionado; JHE escolhido como alvo; novo bloco de literatura; linguagem suavizada em 3 substituições exatas; Carnaval reconciliado; limpeza de tabelas |
| **22/07/2026** | `12_subgroups.R` criado (Robson / termo-pré-termo / idade materna — os três **apoiam** o mecanismo); auditoria de numeração de exhibits (todos estavam off-by-one); bug de ordem de compilação documentado |
| **24/07/2026** | Bibliografia antes dos apêndices, layout Elsevier |
| **27/07/2026** | `FIG_WIDTH = 6.5` |
| **10/08/2026** | Correção do DF por região administrativa (`fix_muni_df()`); correções de linguagem e tipografia |

---

## 14. Estado atual em uma frase

O paper está **substantivamente completo e formatado para o JHE**. O que falta é (a) uma checagem de robustez empírica aberta — controles de temperatura para blindar contra o canal climático do Parfitt; (b) uma rodada formal de revisão interna dos quatro coautores; (c) a finalização editorial (CRediT, declarações, verificação de citações, pacote de replicação). Ver `ROADMAP.md`.
