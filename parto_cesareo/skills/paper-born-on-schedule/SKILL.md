---
name: "paper-born-on-schedule"
description: "Gerencia o paper \"Born on Schedule\" (cesáreas no Brasil, alvo Journal of Health Economics, submissão março/2027) do Vinicius com Fredie Didier, Pablo Castro e Lucas Emanuel. Use quando ele perguntar sobre o projeto de parto cesáreo/cesárea, o paper do JHE, status ou próximos passos da pesquisa, a robustez de temperatura, a Equação (3), os dados TISS/SINASC/CNES, quiser rodar ou revisar scripts do repositório HealthEcon, compilar o LaTeX, checar números do paper, atualizar o Notion do projeto, preparar a revisão interna dos coautores, ou pedir para editar qualquer parte do manuscrito."
---

# Gerenciamento do paper *Born on Schedule*

Você coordena o paper **"Born on Schedule: Fees, Supply-Side Scheduling, and Cesarean Delivery in Brazil"** — Fredie Didier (IDP, correspondente), Vinicius Mendes (UFBA), Pablo Castro (UFBA), Lucas Emanuel (UFBA). Alvo: **Journal of Health Economics**, submissão prevista **março/2027**.

Responda em **português**. O manuscrito é em inglês; ao editar `.tex`, escreva em inglês.

---

## 1. Primeiro passo, sempre

Leia, na pasta do projeto (tipicamente `parto_cesareo/`):

1. `CONTEXTO_PESQUISA.md` — contexto completo: pergunta, dados, estratégia, resultados, taxonomia de evidência, bugs corrigidos, limites.
2. `ROADMAP.md` — o que está feito, o que falta, cronograma até março/2027, divisão de tarefas.
3. `scripts_github/CLAUDE.md` — o documento vivo do repositório, mais detalhado e mais atualizado que os dois acima em questões de código.

**Em caso de conflito, `CLAUDE.md` vence** para código e números; `ROADMAP.md` vence para prazos e responsáveis. Se encontrar uma divergência real, aponte-a em vez de escolher silenciosamente.

Estrutura da pasta:

```
parto_cesareo/
  CONTEXTO_PESQUISA.md    contexto da pesquisa
  ROADMAP.md              plano até a submissão
  scripts_github/         o repositório (código + LaTeX + outputs)
  dataset/                os microdados (TISS, SINASC, CNES, IEPS, workfile)
  Literature/             papers de referência + verificacao_citacoes.md
```

## 2. O Notion do projeto

Existe uma página Notion espelhando este projeto: **"Born on Schedule — Cesáreas no Brasil (JHE)"** (ícone 🍼), com duas bases relacionadas:

- **Metas — Born on Schedule** — 10 entregas com prazo, código (E1, R1, T1, D1, D3, D5, T2, O1, S1, TR1), Frente, Trilha, Risco, checkbox "Bloqueia submissão" e `% concluído` por rollup. Views: `Kanban` (por status), `Por frente`, `Cronograma`, `Bloqueia submissão`.
- **Tarefas — Born on Schedule** — as tarefas do dia a dia, cada uma ligada a uma meta, com Responsável, Prazo, Prioridade. Views: `Kanban`, `Por trilha`, `Minhas tarefas`, `Cronograma`.

**Quando concluir qualquer trabalho, atualize os três lugares:** o `ROADMAP.md`, a tarefa no Notion e — se o número mudou — o `CLAUDE.md`. Deixar um dos três rançoso é como o erro entra. Use os códigos (E1, D3...) para casar item do roadmap com meta do Notion.

Ao adicionar trabalho novo, crie a tarefa no Notion ligada à meta certa, não solta.

---

## 3. As dez regras que não se renegociam

Aplique-as em qualquer edição de texto, tabela, figura ou código. Se um pedido as violar, **diga isso antes de executar**.

1. **Eq. (3) é um *differential***, nunca um difference-in-differences.
2. **"for-profit" (SINASC, natureza jurídica 2xxx) ≠ "private-insurance sector" (TISS).** Nunca "private" puro, nunca "private for-profit".
3. **Os nulos ficam.** Feriados prolongados e capacidade organizacional vieram fracos/nulos. Reportar honestamente é o que delimita a alegação de "conveniência de quem". Não enterrar, não reformular como positivo.
4. **Robson e idade gestacional são corroboração, não placebo.** Pré-termo não é não agendável (pré-eclâmpsia, RCIU, late-preterm eletivo são agendados).
5. **Nunca reintroduzir `else → Public`** na classificação de `nat_jur`. `Public` é o conjunto explícito 1xxx; não pareados vão para `Other`.
6. **Nunca passar de 6,5in** numa figura de `\textwidth` — adicionar uma linha, não uma coluna.
7. **Compilar nos dois sentidos**, sem limpar os `.aux` no meio (ver §7).
8. **Não rodar dois scripts de 42M linhas em paralelo** (03, 05, 06, 07, 08, 09, 12).
9. **Não commitar dados.** Commitar/dar push só quando pedido.
10. **Se mover um exhibit, re-derivar o mapa de `paper.aux`** — nunca renumerar à mão.

---

## 4. Taxonomia de evidência

O paper é *evidência descritiva e de mecanismo estruturada em torno de um contraste quase-experimental fortemente controlado*. Os rótulos abaixo valem em abstract, introdução, seção de estratégia, notas de tabela e conclusão.

- **Regressões de honorário** → associações condicionais, sinal instável. "No robust positive price relationship", nunca "fees don't matter".
- **Gradientes de fim de semana/feriado (Eq. 2)** → ordenação de calendário dos partos. Nunca escrever que o dia do parto é tão bom quanto aleatório em relação à necessidade médica.
- **Eq. (3)** → o differential for-profit–público dentro do município-dia; causal só sob gradiente comum.
- **Pré-parto vs. intraparto** → evidência de mecanismo.
- **Feriados prolongados** → previsões não confirmadas; o nulo delimita a alegação.
- **Capacidade organizacional** → "redundância organizacional atenua o gradiente", nunca "o calendário do médico individual vs. o hospital".
- **Kitagawa** → contabilidade; 72% estilo de prática.
- **~50 mil cesáreas em excesso** → benchmark mecânico, não cesáreas causadas.
- **Parto Adequado** → falha de desenho causal, não efeito de programa.

**Frase-padrão de escopo:** *"The evidence identifies calendar sorting and a tightly controlled for-profit–public differential; it does not identify the total number of cesareans or neonatal outcomes caused by scheduling."*

---

## 5. Números-âncora

Use-os para checar qualquer alegação. Divergiu, investigue antes de escrever.

| Fato | Valor |
|---|---|
| Cesárea (todos / for-profit / nonprofit / público) | ~57% / 79,46% / 59,24% / 42,74% |
| Nascimentos SINASC 2010–2024 | 42.003.663 |
| Dip de fim de semana (for-profit / público) | −8,3pp / −6,7pp |
| Dip de feriado | −5,6pp / −3,5pp |
| **Eq. (3): fds / feriado** | **−2,3pp / −2,9pp**; +predeterminado −2,2 / −2,6; +Robson −1,9 / −2,3 |
| Pré-parto vs. intraparto (for-profit, fds) | −9,7pp vs. +1,7pp |
| Robson 1–2 / Robson 1 | −7,4pp / −6,5pp |
| Termo vs. pré-termo (Eq. 3) | −2,5pp vs. +0,8pp; diferença +3,4pp, p<0,001 |
| Bridge = isolated | p≈0,68 (pré-parto p≈0,95) — sem efeito bridge |
| Early-term (37–38 sem) | +11,7pp*** |
| Kitagawa (gap de 35,1pp) | 28% case-mix / 72% estilo de prática |
| `log_fee_gap` (EF UF / município) | +0,017 / −0,014 (n.s.) |

---

## 6. Pipeline

```
config/00_master_build.R    → build/ 00_utils · 01a_tiss · 01b_sinasc_cnes ·
                              01c_ieps · 01d_cnes_estab (RUN_01D=1) ·
                              02_deliveries · 03_workfile
config/00_master_analysis.R → analysis/code/ 00_utils · 01_descriptives ·
                              02_regressions · 03_mechanisms · 04_heterogeneity ·
                              05_cost · 06_robustness · 07_main_specification ·
                              08_long_weekends · 09_org_capacity ·
                              10_supplement · 12_subgroups · 11_body_figures
```

- **07/08/09** salvam `fam_{A,D,E}.rds` que **10** lê para os testes múltiplos.
- **12 roda antes de 11** apesar do número: salva `robson_grad.rds` para o painel (c) da Figura 3.
- Pico de memória ~12 GB; análise completa ~90 min; `07` sozinho ~40 min.
- **`DROPBOX_ROOT` em `config/config.R` é a única edição por máquina.** O código monta `file.path(DROPBOX_ROOT, "build", ...)`, então `DROPBOX_ROOT` precisa apontar para um diretório que contenha `build/`. A pasta local se chama `dataset/`, não `build/` — resolva isso antes de tentar rodar qualquer coisa (meta R1).

### Mapa de exhibits (corpo: 3 figuras + 6 tabelas)

| Exhibit | Script |
|---|---|
| Fig 1 `fig01_csection_trend` | 01 |
| Fig 2 `fig_two_margins` | 11 |
| Fig 3 `fig_calendar_fingerprints` | 11 (+12) |
| Tab 1 `tab_fees` | 02 |
| Tab 2 `tab_main_gradient` (Eq. 3) | 07 |
| Tab 3 `tab_prelabor_lowrisk` | 03 |
| Tab 4 `tab_long_weekends` | 08 |
| Tab 5 `tab09_health` | 05 |
| Tab 6 `tab11_decomposition` | 03 |

---

## 7. Compilar o LaTeX

O `xr` roda nos **dois** sentidos: `supplement.tex` precisa de `paper.aux` e `paper.tex` precisa de `supplement.aux` (~29 referências `\satab`/`\safig`). Os `.aux` têm de sobreviver entre as passadas.

```bash
cd latex
pdflatex paper; bibtex paper
pdflatex supplement; bibtex supplement; pdflatex supplement
pdflatex paper; pdflatex paper
pdflatex supplement
```

Verificar: `grep -c "Reference .* undefined" paper.log` → **0**.

---

## 8. Convenções de código

- R com `data.table`/`arrow`/`fixest`; `pacman::p_load`. Subsets de coluna preguiçosos, não arquivos inteiros.
- Município = IBGE 6 dígitos (SINASC dá 7 → primeiros 6).
- Figuras: `theme_paper()` + `PAL`, `save_fig()`, `FIG_WIDTH = 6.5`. **Nunca `scale_y_continuous(limits=)`** — descarta pontos silenciosamente.
- Tabelas: `etable` + `dict`, `postprocess_tex()`, legendas em negrito. ≥6 colunas → `sidewaystable`.
- `fixest`: interação pode resolver como `a:b` ou `b:a` — procurar em `rownames(coeftable(m))` ou dar `dict` para as duas ordens. Em `i(x, ..., ref=0)`, passar `ref=0` quando o EF já contém o indicador.
- Não cachear objetos `fixest` inteiros — reduzir a `list(ct=, V=, n=)`.

**O sandbox não tem R.** Verificações e réplicas se fazem em Python (`pyarrow`, `pandas`, `pyfixest`); os `.R` rodam na máquina do Vinicius. Diga isso quando for relevante, em vez de tentar rodar R e falhar.

---

## 9. Bugs corrigidos — não reintroduzir

| Bug | Correção |
|---|---|
| `else → Public` em `nat_jur` | Conjunto explícito 1xxx; não pareados → `Other` |
| `holiday_dates(2015:2024)` | → `holiday_dates(2010:2024)` (o arquivo diário cobre 2010–2024) |
| CBO de obstetra com `225270` | → `{225250, 223132, 6149, 6145}` |
| DF por região administrativa no CNES | `fix_muni_df()`, **antes do `uniqueN()`, nunca depois** |
| Figura salva mais larga que o impresso | `FIG_WIDTH = 6.5` |
| `i(x, ...)` sem `ref=0` no script 08 | `ref=0` |

---

## 10. O que fazer conforme o pedido

**"Qual o status?" / "O que falta?"** → Leia `ROADMAP.md` e consulte as metas no Notion. Dê o marco do mês corrente, os bloqueadores abertos e o que está atrasado. Seja específico sobre quem é o dono de cada item pendente.

**Robustez de temperatura (meta E1)** → É o único item empírico aberto e o de maior lead time. Plano em `ROADMAP.md` Parte III. Pontos a lembrar: os EF município×data **já absorvem** a temperatura comum aos dois setores, então isto é cinto-e-suspensório, não conserto; a ameaça residual exigiria resposta *diferencial* dos setores à temperatura. ERA5-Land é preferível ao INMET por cobertura. Novo script `13_temperature.R`, depois de 07.

**Editar o manuscrito** → Leia a seção inteira antes de editar. Cheque a taxonomia de evidência (§4) e as dez regras (§3). Evite travessões longos e frases sinuosas — é o estilo da casa. Depois de editar, recompile e confirme zero referência indefinida.

**Checar um número** → Recalcule do `dataset/` em Python e compare com §5 e com `CLAUDE.md`. Se divergir, investigue antes de reportar; a causa mais provável é filtro de amostra ou período diferente.

**Revisão interna dos coautores (meta T1)** → Pablo lê seções 4–5 (identificação e honorários); Lucas lê 6–7 + suplemento (nulos e consistência de números); Fredie lê integral. Consolide comentários em uma lista única priorizada, não numa colagem.

**Bibliografia (meta D3)** → A verificação das 50 entradas já foi feita (20/08/2026, achados em `Literature/verificacao_citacoes.md`). O que falta são as correções no `.bib` e duas decisões do Fredie: incluir `melo2023` na seção institucional e resolver `curriemacleod2016`.

**Ao terminar qualquer bloco de trabalho** → Atualize `ROADMAP.md`, a tarefa no Notion e o `CLAUDE.md` se um número mudou. Diga o que mudou.

