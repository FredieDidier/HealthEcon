# Born on Schedule — pacote de replicação do ambiente de trabalho

**Para:** Fredie Didier, Pablo Castro, Lucas Emanuel
**De:** Vinicius Mendes · 20/08/2026
**O que é:** tudo o que foi montado no Claude Cowork para tocar o paper *Born on Schedule: Fees, Supply-Side Scheduling, and Cesarean Delivery in Brazil* (alvo: **Journal of Health Economics**, submissão **março/2027**), num arquivo só, de forma que cada um de vocês reconstrua o mesmo ambiente na própria máquina.

Este documento tem quatro partes:

| Parte | Conteúdo |
|---|---|
| **I** | Como criar uma skill — o método, passo a passo, com os erros que já cometemos |
| **II** | As duas skills do projeto, com o código-fonte integral para copiar |
| **III** | A organização do projeto: pastas, arquivos vivos, pipeline |
| **IV** | Os resultados já encontrados — o que o paper afirma e com que rótulo |

No fim tem um **checklist de 20 minutos** para quem quiser só rodar e não ler.

---

## 0. Antes de qualquer coisa

**O que você precisa ter:**

1. **Claude Desktop com Cowork ativado.** É o modo em que o Claude enxerga uma pasta do seu computador e roda código num Linux isolado.
2. **Uma pasta local do projeto.** Chame de `parto_cesareo/`. Ela vai ser a pasta que você conecta no Cowork.
3. **Os arquivos vivos do projeto** — `CONTEXTO_PESQUISA.md`, `ROADMAP.md`, `scripts_github/CLAUDE.md`. Sem eles as skills funcionam, mas ficam cegas: elas mandam o Claude *ler* esses arquivos antes de responder.
4. **Opcional:** conector do Notion, se você quiser que o Claude atualize as bases *Metas* e *Tarefas — Born on Schedule*.

**O que você NÃO precisa:** os 12 GB de microdados. Só quem for rodar o pipeline empírico precisa da pasta `dataset/`. Para ler, comentar e editar o manuscrito, os três `.md` vivos bastam.

**Limite do ambiente, avisado logo:** o sandbox do Cowork tem Python, **não tem R**. Os `.R` do repositório rodam na sua máquina. Verificações numéricas dentro do Cowork se fazem em Python (`pyarrow`, `pandas`, `pyfixest`). Isso está escrito dentro da skill para o Claude não tentar rodar R e falhar.

---

# PARTE I — Como criar uma skill

## 1. O que é uma skill, em uma frase

Uma skill é uma pasta com um arquivo `SKILL.md` dentro. O Claude lê a `description` do arquivo, decide sozinho se aquilo se aplica ao que você pediu, e — se sim — carrega o resto do arquivo como instrução. É memória de projeto que se ativa sozinha, não um comando que você digita.

Anatomia:

```
nome-da-skill/
├── SKILL.md              (obrigatório)
│   ├── frontmatter YAML  → name + description
│   └── corpo em markdown → as instruções
└── references/           (opcional)
    ├── um-tema.md
    └── outro-tema.md
```

O corpo do `SKILL.md` é sempre carregado quando a skill dispara. Os arquivos em `references/` **não** — o Claude só os abre quando o próprio `SKILL.md` manda ("leia `references/x.md` antes de escolher o desenho"). É assim que se coloca 800 linhas de conhecimento numa skill sem inchar toda conversa.

## 2. A regra mais importante: a `description` é tudo

O corpo da skill só é lido **depois** que ela dispara. Quem faz disparar é a `description`. Se ela estiver vaga, a skill nunca é usada e você não entende por quê.

Três regras que valem ouro:

**(a) Toda informação de "quando usar" vai na `description`, nenhuma no corpo.** O Claude não lê o corpo para decidir.

**(b) Seja explícito e um pouco insistente.** O Claude tende a *sub-disparar* skills. Compare:

- ❌ `"Ajuda com o paper de cesárea."`
- ✅ `"Use quando ele perguntar sobre o projeto de parto cesáreo/cesárea, o paper do JHE, status ou próximos passos, a robustez de temperatura, a Equação (3), os dados TISS/SINASC/CNES, quiser rodar ou revisar scripts do repositório HealthEcon, compilar o LaTeX, checar números do paper..."`

**(c) Liste os gatilhos como o usuário fala, não como você catalogaria.** A skill `birth-health-econ` dispara em "taxa de cesárea", "Robson", "SINASC", "demanda induzida", "referee report" — e termina com *"mesmo que o usuário não peça 'economia da saúde' explicitamente"*, porque ninguém pede isso explicitamente.

## 3. O passo-a-passo que usamos

### Passo 1 — Decidir o que a skill carrega que a conversa não carrega

Uma skill boa responde a: *"o que eu tenho que reexplicar toda vez que abro uma conversa nova?"* Se a resposta é "nada", não faça skill.

No nosso caso as respostas foram duas, e por isso saíram duas skills:

- "que Eq. (3) é um *differential*, não um DiD; que os nulos ficam; que for-profit ≠ private-insurance; quais são os números-âncora" → virou **`paper-born-on-schedule`** (conhecimento *deste* projeto).
- "que este campo tem convenções fortes, que o parecerista vai cobrar balanço em predeterminadas, que Gruber–Owings acha +0,97pp" → virou **`birth-health-econ`** (conhecimento *do campo*, serve para qualquer paper de parto, inclusive o de orientando).

**Essa separação foi deliberada e vale copiar.** Conhecimento de projeto envelhece a cada rodada; conhecimento de campo não. Misturar os dois obriga a reescrever tudo quando um número muda.

### Passo 2 — Escrever o rascunho

Estrutura que funcionou nas duas:

```
1. Primeiro passo, sempre     → que arquivos ler antes de responder, e qual vence em caso de conflito
2. As regras inegociáveis     → em lista numerada, curta, com "se um pedido violar isso, diga antes de executar"
3. Taxonomia / vocabulário    → como chamar cada coisa
4. Números-âncora             → tabela de valores para checagem de sanidade
5. Pipeline / mecânica        → ordem de execução, comandos, armadilhas
6. Bugs corrigidos            → "não reintroduzir"
7. O que fazer conforme o pedido → roteiro por tipo de solicitação
```

O item 1 é o que faz a skill não envelhecer: em vez de congelar o status do projeto dentro dela, ela manda ler `ROADMAP.md`. E o item 7 é o que a transforma de documento em agente — sem ele o Claude sabe as regras mas não sabe o que entregar.

### Passo 3 — Codificar a hierarquia de fontes

Quando existem três documentos vivos, é preciso dizer qual manda. Está literalmente escrito na skill:

> *Em caso de conflito, `CLAUDE.md` vence para código e números; `ROADMAP.md` vence para prazos e responsáveis. Se encontrar uma divergência real, aponte-a em vez de escolher silenciosamente.*

A segunda frase é a que importa: sem ela, o Claude resolve o conflito sozinho e você nunca fica sabendo que os arquivos divergiram.

### Passo 4 — Colocar os números dentro da skill

Uma tabela de números-âncora (§5 da `paper-born-on-schedule`) transforma o Claude em conferente. Ele passa a comparar qualquer valor que apareça no texto com a tabela e reclamar quando diverge — que foi como pegamos a numeração de exhibits off-by-one em julho.

### Passo 5 — Registrar os bugs corrigidos

Cada bug do projeto virou uma linha numa tabela "não reintroduzir". O `else → Public` da classificação de `nat_jur` é o caso exemplar: o impacto numérico foi desprezível (42,73% → 42,74%), mas a correção **fortaleceu** a Eq. (3) de −1,8/−2,4 para −2,3/−2,9. Sem esse registro, alguém "simplifica" o código daqui a seis meses e o coeficiente muda sem explicação.

### Passo 6 — Testar disparando

Abra uma conversa nova e faça três perguntas realistas — não perguntas montadas para a skill. Ex.: *"qual o status?"*, *"esse número de early-term tá certo?"*, *"o que falta pra submeter?"*. Se a skill não carregar sozinha, o problema é a `description`, não o corpo.

### Passo 7 — Salvar

No Cowork, peça: **"salve isso como uma skill"** — o Claude usa a ferramenta `save_skill`. Ou instale a pasta pronta (é o que vai no `.zip` que acompanha este documento).

Existe ainda a skill oficial **`skill-creator`**, que automatiza o ciclo inteiro (rascunho → casos de teste → avaliação quantitativa → reescrita) e tem um otimizador de `description`. Vale para skill que muitas pessoas vão usar; para skill de projeto como as nossas, escrever à mão foi mais rápido.

## 4. Os erros que cometemos, para vocês não repetirem

| Erro | Sintoma | Correção |
|---|---|---|
| `description` genérica | A skill existe e nunca dispara | Listar os gatilhos como o usuário fala; ser insistente |
| Congelar status dentro da skill | Skill vira mentira em duas semanas | Skill aponta para `ROADMAP.md`; não repete o conteúdo |
| Misturar campo com projeto | Toda mudança de número obriga a reescrever tudo | Duas skills separadas |
| Enfiar tudo no `SKILL.md` | Contexto inchado em toda conversa | Mover o volume para `references/` e mandar ler sob demanda |
| Só regras, sem roteiro de entrega | Claude sabe as regras, não sabe o que produzir | Seção "o que fazer conforme o pedido" |
| Não dizer o limite do ambiente | Claude tenta rodar R, falha, você perde 10 minutos | "O sandbox não tem R" escrito na skill |

---

# PARTE II — As duas skills, na íntegra

Copie cada bloco para um arquivo com o nome indicado. O `.zip` que acompanha este documento já tem as pastas montadas — o texto abaixo existe para conferência e para quem preferir colar à mão.

**Estrutura final:**

```
skills/
├── paper-born-on-schedule/
│   └── SKILL.md
└── birth-health-econ/
    ├── SKILL.md
    └── references/
        ├── identification-designs.md
        ├── literature-map.md
        ├── referee-playbook.md
        └── data-brazil.md
```

**Como instalar:** no Cowork, arraste o `.zip`, ou peça *"instale estas skills"*. Alternativamente, copie as pastas para o diretório de skills do seu Claude Desktop.

---

### Skill 1 — `paper-born-on-schedule`

**O que carrega:** o conhecimento *deste* projeto. Dispara em perguntas sobre o paper, status, próximos passos, Eq. (3), dados TISS/SINASC/CNES, scripts do HealthEcon, compilação do LaTeX, checagem de números, Notion do projeto, revisão interna, ou edição de qualquer parte do manuscrito.

**Um arquivo só, sem `references/`.** Ela não guarda o status do projeto — manda ler `ROADMAP.md`. É o que impede a skill de envelhecer.


## Fonte integral

**Arquivo:** `paper-born-on-schedule/SKILL.md` · 196 linhas

`````markdown
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
`````

---

### Skill 2 — `birth-health-econ`

**O que carrega:** o conhecimento *do campo* — economia da saúde do parto no padrão de JHE, AEJ:Policy, QJE, JHR, Health Economics, JDE. Dispara em taxa de cesárea, modo de parto, timing de nascimento, honorários médicos, demanda induzida, lotação de maternidade, medicina defensiva, desfechos neonatais, classificação de Robson, microdados de nascimento — e também em "avalie a viabilidade desta ideia", "critique este paper", "prepare um referee report", "que periódico mirar".

**Serve para além deste paper:** orientação de aluno, parecer, projeto novo.

**Um `SKILL.md` + quatro arquivos em `references/`.** Os arquivos de referência só são abertos quando o `SKILL.md` manda — é assim que se carrega ~830 linhas de conhecimento sem inchar toda conversa.


## Fonte integral — SKILL.md

**Arquivo:** `birth-health-econ/SKILL.md` · 208 linhas

`````markdown
---
name: birth-health-econ
description: Especialista em economia da saúde do parto — cesárea vs. parto normal — no padrão de periódicos de alto impacto (JHE, AEJ:Policy, QJE, JHR, Health Economics, JDE). Use sempre que o trabalho envolver taxa de cesárea, modo de parto, agendamento ou timing de nascimento, incentivos e honorários médicos, demanda induzida, lotação ou capacidade de maternidade, medicina defensiva, desfechos neonatais, classificação de Robson, ou microdados de nascimento (SINASC, birth certificates, altas hospitalares). Cobre desenho de identificação, magnitudes de referência da literatura, escolha de amostra e desfechos, redação no estilo do campo, e antecipação de objeções de parecerista. Acione também quando o pedido for avaliar a viabilidade de uma ideia de pesquisa sobre parto, ler ou criticar um paper da área, preparar um referee report, orientar aluno em tema de cesárea, ou decidir qual periódico mirar — mesmo que o usuário não peça "economia da saúde" explicitamente.
---

# Economia da saúde do parto: cesárea vs. parto normal

Este é um campo pequeno, denso e com convenções fortes. Um paper que ignora essas
convenções é rejeitado no desk mesmo com dados excelentes. A skill existe para
carregar o que os bons papers da área fazem por padrão — e o que os pareceristas
cobram por padrão.

Responda no idioma do usuário. Manuscritos em inglês.

## O problema central do campo

A cesárea é o exemplo canônico de tratamento cuja variação **não é explicada por
necessidade médica**. Taxas variam de 15% a 80% entre países, entre hospitais da
mesma cidade, e entre horas do mesmo dia. Isso cria a pergunta que organiza toda a
literatura:

> Quanto da variação em cesárea vem do lado da oferta — incentivos, conveniência,
> capacidade, estilo de prática, risco jurídico — e não do lado da paciente?

Três coisas tornam o parto um laboratório privilegiado, e vale dizê-las
explicitamente na introdução de qualquer paper da área:

1. **O timing é manipulável, a gravidez não.** A data de concepção é fixa; a data
   do parto é escolhida. Isso gera variação de curto prazo que não se correlaciona
   com a saúde subjacente.
2. **A margem é binária e bem medida.** Cesárea vs. vaginal aparece em registro
   administrativo universal, sem erro de medida relevante.
3. **A população é jovem e majoritariamente saudável.** Diferente de infarto ou
   câncer, o *case-mix* é comparativamente homogêneo — o que torna a variação
   residual mais difícil de atribuir a necessidade.

## Como trabalhar

### 1. Antes de qualquer coisa: qual é o estimando?

O erro mais comum e mais caro do campo é confundir três objetos diferentes:

| Estimando | O que responde | Desenho típico |
|---|---|---|
| **Efeito do incentivo sobre o tratamento** | Médico responde a preço/conveniência/capacidade? | Choque de honorário, DiD de política, hora do dia, ocupação de leito |
| **Efeito do tratamento sobre a saúde** | A cesárea marginal faz bem ou mal ao bebê/mãe? | IV (distância, hora do dia, véspera de feriado), RD em limiar clínico |
| **Contabilidade da variação** | Quanto do gap é case-mix vs. estilo de prática? | Decomposição (Kitagawa/Oaxaca), efeitos fixos de médico/hospital |

Um paper pode fazer os três, mas precisa dizer qual tabela responde a qual. Misturar
os rótulos é o que faz o parecerista escrever "the authors overclaim". Se o usuário
está escrevendo, force essa clareza antes de discutir especificação.

### 2. Escolha do desenho

Leia `references/identification-designs.md` — catálogo dos desenhos que funcionaram
em publicação de alto impacto, com a variação explorada, a hipótese de identificação,
a ameaça residual, e o que cada um **não** identifica.

Regra prática: o campo já não aceita variação transversal entre hospitais ou entre
áreas sem uma fonte exógena. "Controlamos por um conjunto rico de covariáveis" é
motivo de rejeição — a literatura demonstrou repetidamente que controles observáveis
não resolvem a endogeneidade do modo de parto.

### 3. Amostra, covariáveis e desfechos

**Restrinja a amostra a partos de baixo risco.** Quase todo paper sério usa alguma
versão de *low-risk first births* — nulípara, termo, feto único, cefálico; nos EUA a
sigla é NTSV, no vocabulário da OMS é Robson 1. É o grupo onde há discricionariedade
real. Sem isso, o efeito fica diluído por partos em que a cesárea é inequivocamente
indicada.

**Cuidado com bad controls.** Idade gestacional, peso ao nascer e número de consultas
de pré-natal são **posteriores ao tratamento** ou determinados conjuntamente com ele —
controlar por eles condiciona em desfecho e enviesa. Use-os como desfecho ou como
recorte de amostra, não como covariável. A covariável predeterminada que realmente
importa e que papers fracos esquecem é **cesárea prévia**: é o preditor dominante do
modo de parto e cria dependência de trajetória entre setores.

**O denominador é endógeno.** Regredir a *taxa* de cesárea sobre variação diária tem
um problema mecânico: numerador e denominador são determinados pelo mesmo
comportamento. Se num dia chegam muitas parturientes espontâneas, a fração de cesáreas
cai sem que ninguém tenha mudado de conduta. Estime no nível individual (probabilidade
de cesárea dado que a mulher pariu) ou modele contagens de cesárea e vaginal
separadamente. Um efeito grande e negativo de "movimento" sobre a taxa é quase sempre
isso.

**Com amostras de milhões, p-valor não disciplina nada.** Tudo é significante. A
disciplina tem de vir da magnitude comparada à literatura e do tamanho do intervalo de
confiança — não de estrelinhas.

**Separe cesárea pré-parto de intraparto.** Essa é a distinção de mecanismo mais
informativa do campo: agendamento por conveniência aparece na margem pré-parto;
resposta a intercorrência aparece na intraparto. Se os dados permitem, essa é
frequentemente a tabela mais persuasiva do paper.

**Desfechos com hierarquia de credibilidade:**
- Alta: Apgar, peso, idade gestacional, readmissão, mortalidade neonatal
- Média: morbidade materna, tempo de internação
- Baixa: desfechos de longo prazo autorreportados

Cuidado com desfechos raros. Mortalidade neonatal tem média de 3–5 por mil; um nulo
aí frequentemente é falta de potência, não ausência de efeito. Reporte o intervalo
de confiança e diga o que ele descarta, em vez de escrever "no effect".

### 4. Magnitudes de referência

Antes de acreditar num coeficiente próprio, compare com `references/literature-map.md`.
Ele traz as estimativas centrais publicadas, com desenho e contexto. Ordens de
grandeza que servem de sanidade:

- Resposta a honorário: **~1 p.p. por US$1.000** de diferencial (Gruber-Kim-Mayzlin)
- Gradiente de conveniência (hora do dia, véspera de feriado): **1–2 p.p.**, ~10% da média
- Capacidade / leito vazio: **~1 p.p. por desvio-padrão** de ocupação (Bachner et al.)
- Choque de acesso a hospital privado: **4,6 p.p.** (Chile, de Elejalde & Giolito)
- Gap público–privado no Brasil: **~35 p.p.** bruto — mas ~30% é composição

Se seu efeito é muito maior que isso, quase sempre há contaminação por composição
ou por seleção de hospital. Investigue antes de escrever.

### 5. Antecipe o parecerista

Leia `references/referee-playbook.md`. As objeções da área são previsíveis e há
respostas canônicas — cada uma associada a uma tabela ou figura específica. Papers
que embutem essas respostas no desenho passam; papers que as tratam como apêndice
defensivo, não.

As três que sempre vêm:
1. "A variação temporal que vocês exploram não é aleatória em relação à necessidade."
2. "O efeito é composição de pacientes, não mudança de comportamento."
3. "O que isso identifica é um LATE de um subgrupo estreito — e daí?"

### 6. Dados brasileiros

Se o trabalho usa Brasil, leia `references/data-brazil.md`. O Brasil é um caso de
alto retorno — segunda maior taxa do mundo, contraste institucional forte entre SUS
e saúde suplementar, microdados universais desde os anos 1990 — e ao mesmo tempo
cheio de armadilhas de codificação que já geraram erros publicados.

## Ao ler ou criticar um paper da área

Percorra nesta ordem, porque é a ordem em que os problemas aparecem:

1. **O estimando está nomeado?** Ou o paper desliza entre "efeito do incentivo" e
   "efeito da cesárea"?
2. **A variação é plausivelmente exógena à necessidade médica?** Peça o teste de
   balanço em características predeterminadas. Se não houver, é um alerta forte.
3. **A amostra isola discricionariedade?** Se inclui todos os partos, o efeito está
   diluído e a interpretação fica ambígua.
4. **Os nulos estão reportados?** Um paper que só mostra o que deu certo está
   escondendo o que delimita a alegação.
5. **A magnitude é compatível com a literatura?** Divergência grande exige explicação
   institucional, não só robustez.
6. **A conclusão excede o desenho?** Especialmente: LATE apresentado como ATE, e
   "cesáreas em excesso" apresentado como "cesáreas causadas".

## Redação no estilo do campo

O campo tem um registro próprio — sóbrio, quantitativo, com o mecanismo à frente da
técnica. Alguns padrões que valem imitar:

- **Abstract com número.** Os melhores abstracts da área trazem a magnitude central
  na terceira ou quarta frase. "We find that X increases c-sections by N percentage
  points (M percent)."
- **Institucional antes de econométrico.** Uma seção curta explicando como o
  pagamento e o agendamento funcionam naquele sistema faz mais pelo paper do que uma
  robustez adicional. Os pareceristas do campo são institucionalmente exigentes.
- **Mecanismo declarado, não insinuado.** Se você acha que é conveniência, teste
  conveniência (pré-parto vs. intraparto, hora, véspera). Não deixe implícito.
- **Escopo explícito no fim da introdução.** Uma frase dizendo o que o desenho
  identifica e o que não identifica. Isso desarma o parecerista em vez de irritá-lo.

Evite: "we control for a rich set of covariates" como argumento de identificação;
"unnecessary cesareans" sem definir o contrafactual; e — importante — **não trate
10–15% como "a recomendação da OMS"**. Esse número é de 1985. A declaração vigente
(WHO/RHR/15.02, 2015) diz o oposto: que não se deve perseguir taxa-alvo alguma, que
o esforço deve ser atender quem precisa, e que acima de ~10% ao nível populacional
não há evidência de ganho em mortalidade materna e neonatal. A mesma declaração
propõe a classificação de Robson como padrão de comparação entre instituições.
Citar o alvo de 1985 como se fosse a posição atual é o tipo de erro que um
parecerista com formação médica pega na primeira leitura.

## Escolha de periódico

- **Journal of Health Economics** — casa natural. Quer mecanismo, dados
  administrativos, e uma contribuição de identificação clara. Tolera nulos bem
  reportados.
- **AEJ: Economic Policy** — quer implicação de política e desenho forte. Card,
  Fenizia & Silver e Johnson & Rehavi saíram aqui.
- **Health Economics** — mais tolerante a desenhos descritivos bem executados e a
  contextos de país específico.
- **Journal of Human Resources** — se o desfecho é de longo prazo (capital humano,
  saúde na infância).
- **Journal of Development Economics** — se a contribuição é sobre sistemas de saúde
  em país em desenvolvimento, não sobre parto per se.
- **QJE / AER** — só com desenho excepcional *e* uma pergunta que transcenda o parto
  (retornos marginais ao cuidado, responsabilidade civil, variação geográfica).

## Arquivos de referência

- `references/identification-designs.md` — catálogo de desenhos, com o que cada um
  identifica e não identifica. Leia antes de propor especificação.
- `references/literature-map.md` — quem fez o quê, com magnitudes e contexto. Leia
  antes de posicionar um paper ou checar se um coeficiente é plausível.
- `references/referee-playbook.md` — objeções recorrentes e as respostas canônicas.
  Leia antes de submeter ou ao preparar um referee report.
- `references/data-brazil.md` — SINASC, SIH, TISS, CNES, Robson, e as armadilhas.
  Leia ao trabalhar com dados brasileiros.
`````

---

## Referência 1 — catálogo de desenhos de identificação

**Arquivo:** `birth-health-econ/references/identification-designs.md` · 324 linhas · cada desenho com a variação explorada, a hipótese de identificação, o que **não** identifica e a ameaça residual

`````markdown
# Catálogo de desenhos de identificação

Cada entrada: a variação explorada, a hipótese de identificação, o que identifica,
o que **não** identifica, e a ameaça residual. Ordenados por família.

## Índice

1. [Conveniência temporal](#1-conveniência-temporal)
2. [Capacidade e lotação](#2-capacidade-e-lotação)
3. [Preço e incentivo financeiro](#3-preço-e-incentivo-financeiro)
4. [Informação do paciente](#4-informação-do-paciente)
5. [Distância e prática do hospital](#5-distância-e-prática-do-hospital)
6. [Descontinuidade clínica](#6-descontinuidade-clínica)
7. [Responsabilidade civil](#7-responsabilidade-civil)
8. [Decomposição contábil](#8-decomposição-contábil)
9. [Desenhos que já não passam](#9-desenhos-que-já-não-passam)

---

## 1. Conveniência temporal

A família mais produtiva do campo. A ideia: o médico prefere não trabalhar de
madrugada, no fim de semana ou na véspera de feriado, e a cesárea é o instrumento
que permite realocar o parto no tempo.

### 1a. Hora do dia
**Referência:** Costa-Ramón, Rodríguez-González, Serra-Burriel & Campillo-Artero
(2018), *JHE* 59:46-59. Espanha.

**Variação:** probabilidade de cesárea não planejada por hora de nascimento —
elevada no fim do turno diurno, mínima na madrugada (1h–7h).

**Identificação:** condicional a efeitos fixos de hospital, mês e ano, a hora em que
o trabalho de parto progride é independente da gravidade do caso.

**Identifica:** efeito da cesárea *evitável* sobre saúde neonatal (LATE nas
compliers — mulheres cuja cesárea foi determinada pelo relógio).

**Não identifica:** efeito da cesárea medicamente indicada; nada sobre cesárea
programada.

**Ameaça residual:** seleção de quem chega à maternidade em cada hora. Responda com
balanço de características predeterminadas por hora e mostre que o instrumento não
prediz risco observável.

### 1b. Véspera de feriado / fim de semana
**Referência:** Costa-Ramón, Kortelainen, Rodríguez-González & Sääksvuori (2022),
*JHR* 57(6):2048-2085. Finlândia.

**Variação:** excesso de cesáreas não planejadas em horário regular nos dias que
antecedem um feriado ou fim de semana. Instrumento = interação `turno normal ×
véspera de lazer`.

**Primeiro estágio:** +1,4 p.p. na cesárea não planejada (≈ +9,6% sobre a média).

**Identifica:** efeito de longo prazo da cesárea evitável. Encontram aumento em asma;
descartam efeitos sobre diabetes tipo 1 e obesidade.

**Sofisticação que vale copiar:** eles complementam o IV com um DiD de efeitos fixos
de família comparando irmãos com modos de parto diferentes. Duas estratégias com
hipóteses distintas convergindo é muito mais persuasivo que uma só.

**Ameaça residual:** se mães de maior risco evitam dar à luz em vésperas de feriado.
Testável e testado.

### 1c. Feriado móvel / janela de manipulação
**Referência:** Melo & Menezes-Filho (2024), *Health Economics* 33(9):2013-2058.
Brasil, Carnaval.

**Variação:** deslocamento de nascimentos em torno do Carnaval — antecipação e
postergação. Definem uma "janela ótima de manipulação" (20 dias antes a 14 depois).

**Achado contraintuitivo:** o feriado *melhora* desfechos. Partos postergados que
teriam sido cesárea programada acabam vaginais; ganho de 0,09 semana de gestação e
queda em mortalidade neonatal.

**Lição de desenho:** restrição à cesárea agendada pode ser benéfica. Não presuma que
mais intervenção é o dano.

**Cuidado:** feriado móvel confunde com estação. Carnaval é sempre verão. Se você usa
feriados fixos, o problema é o inverso — cada feriado tem sua estação. Efeitos fixos
de município×data resolvem se você tem um contraste dentro do dia.

### 1d. Manipulação por incentivo externo ao médico
**Referências:** Dickert-Conlin & Chandra (1999), *JPE* — incentivo tributário;
Gans & Leigh (2009), *JPubE* — mudança de política em data conhecida;
Jacobson, Kogelnik & Royer (2021), *JOLE* — feriados.

**Uso:** demonstra que a data do parto responde a incentivos *da família*, não só do
médico. Serve de contraponto: se você quer atribuir o gradiente ao lado da oferta,
precisa descartar o lado da demanda. O teste padrão é mostrar que o gradiente
aparece onde o médico decide (pré-parto, setor privado) e não onde a família decide.

---

## 2. Capacidade e lotação

Família em expansão, e onde os resultados mais divergem — o que a torna terreno fértil
e perigoso.

### 2a. Ocupação de leito obstétrico
**Referência:** Bachner, Halla & Pruckner (2024), IZA DP 16981. Áustria,
1,28 milhão de partos, 2002–2018.

**Variação:** ocupação diária idiossincrática de leitos de maternidade, dentro de
hospital×mês.

**Achado:** leito vazio *aumenta* cesárea. −1 d.p. de ocupação → +1,07 p.p. de
cesárea (+3,95%) e +0,24 p.p. de readmissão (+5,84%).

**Interpretação dos autores:** hospital cheio protege contra sobretratamento.

**Checagens que fazem o paper:** excluem cesáreas programadas; repetem em fins de
semana e feriados (quando não se agenda); repetem em maternidades com baixa proporção
de programadas; usam cirurgias notoriamente agendadas (câncer de mama) como
comparação.

### 2b. Congestionamento instrumentado por coorte de data provável
**Referência:** Bensnes (2026), *Health Economics* 35(2):175-211 (SSB DP 963).
Noruega.

**Instrumento:** número de mulheres na área de captação com a mesma data provável de
parto. Elegante porque é predeterminado na concepção.

**Achado:** congestionamento reduz intervenção e *melhora* desfechos — mesma direção
que Bachner.

**Contribuição metodológica importante:** ele mostra que o arcabouço usual de efeitos
fixos de ala×data **falha** quando a alocação de pacientes a hospitais é endógena, e
que o viés tem sinal previsível. Se você usa efeitos fixos de hospital como
identificação, precisa responder a esse argumento.

### 2c. Staffing
**Referência:** Facchini (2022), *JEBO* 197:370-394. Espanha.

**Achado de sinal oposto:** menos pessoal → *mais* cesárea, a taxa decrescente. A
cesárea economiza tempo de parteira.

**Como reconciliar com 2a/2b:** margens diferentes. Facchini varia pessoal com leitos
constantes (cesárea poupa trabalho); Bachner e Bensnes variam ocupação com pessoal
constante (leito vazio libera sala de cirurgia). Se você reporta nulo em capacidade,
essa distinção é a sua defesa: diga qual margem você mede.

Ver também Maibom, Sievertsen, Simonsen & Wüst (2021), *JHE* 75:102399.

---

## 3. Preço e incentivo financeiro

### 3a. Choque de renda do médico
**Referência:** Gruber & Owings (1996), *RAND* 27(1):99-123. EUA, 1970–1982.

**Variação:** queda de 13,5% na fecundidade por estado — choque negativo de renda
para obstetras.

**Achado:** −10% na fecundidade → +0,97 p.p. na taxa de cesárea. Explica 1,45 p.p. do
aumento observado no período.

**Por que ainda importa:** é o paper fundador da demanda induzida aplicada. A
estrutura do argumento — choque exógeno à *renda*, não ao *preço*, para separar efeito
renda de efeito substituição — continua sendo o padrão-ouro conceitual.

**Fraqueza pelos padrões de hoje:** variação em nível de estado, poucos controles.
Não seria publicado assim agora.

### 3b. Diferencial de honorário
**Referência:** Gruber, Kim & Mayzlin (1999), *JHE* 18(4):473-490.

**Achado:** +US$100 no diferencial cesárea–vaginal → +3,9% na taxa de cesárea
(≈ 1 p.p. por US$1.000).

**Nota prática:** o PDF do NBER WP 6744 é digitalização sem OCR.

### 3c. Choque de preço administrativo
**Referência:** Clemens & Gottlieb (2014), *AER* 104(4):1320-1349.

**Variação:** consolidação de 210 para 89 áreas de pagamento do Medicare em 1997.

**Achado:** elasticidade de oferta de longo prazo ≈ 2,5. Procedimentos eletivos
respondem o dobro dos não discricionários. Sem efeito detectável sobre saúde.

**Uso no campo do parto:** referência de magnitude para resposta a preço e para o
padrão "eletivo responde mais" — que é exatamente a previsão testável para cesárea.

### 3d. Choque de acesso / demand smoothing
**Referência:** de Elejalde & Giolito (2021), *JHE* 75:102411 (IZA DP 12297). Chile.

**Variação:** política que reduziu o custo de parto em hospital privado para
seguradas do sistema público. DiD por elegibilidade.

**Achados:** +8,7 p.p. de partos em hospital privado; +4,6 p.p. de cesárea (+15%);
piora em peso e tamanho ao nascer.

**A contribuição conceitual mais importante do paper:** o preço da cesárea e do parto
vaginal era **o mesmo**. Ainda assim a cesárea subiu. O modelo deles mostra por quê:
cesárea é agendável, e agendar permite suavizar demanda ao longo do tempo,
aumentando o volume total e compensando a margem perdida.

**Implicação que muda desenhos:** ausência de diferencial de preço **não** implica
ausência de incentivo de oferta. Se seu paper encontra "no robust price relationship",
esse é o mecanismo alternativo a testar — e a previsão é verificável: hospitais com
taxa de cesárea mais alta reagendam mais quando esperam semana de alta demanda.

---

## 4. Informação do paciente

**Referência:** Johnson & Rehavi (2016), *AEJ: Economic Policy* 8(1):115-141.
Califórnia e Texas.

**Desenho:** compara médicas grávidas com não médicas comparáveis, via merge
confidencial de registros vitais com dados de licenciamento.

**Achados:** médicas têm 2,13 p.p. (≈7%) menos cesárea; só um quarto disso é seleção
de hospital/obstetra. Em hospitais de HMO — onde o incentivo financeiro some — o gap
desaparece. Médicas também têm desfechos melhores.

**Por que o desenho é tão forte:** a interação. Não é só "pacientes informadas recebem
menos"; é "o efeito da informação some exatamente onde o incentivo some". Isso
descarta explicações alternativas que um contraste simples não descartaria.

**Limite que os próprios autores reconhecem:** cortesia profissional entre médicos é
uma alternativa que eles não conseguem excluir totalmente.

---

## 5. Distância e prática do hospital

**Referência:** Card, Fenizia & Silver (2023), *AEJ: Economic Policy* 15(2):42-81.
Califórnia, 491.604 partos de baixo risco, 2007–2011.

**Instrumento:** distância relativa ao hospital de alta taxa de cesárea mais próximo
vs. o de baixa taxa mais próximo, com efeitos fixos de área de serviço de saúde.

**Primeiro estágio:** morar mais perto de um hospital H → +13,04 p.p. de probabilidade
de parir num H.

**Achados:** bebês em hospitais H nascem em melhor estado (−0,82 p.p. de Apgar baixo),
menos readmissão, indício de menor mortalidade — via evitação de trabalho de parto
prolongado. **Mas** mais idas ao pronto-socorro por problema respiratório no primeiro
ano.

**Por que é o paper mais importante da década no campo:** é o primeiro a mostrar que o
trade-off tem os dois lados com desenho quase-experimental, e que "reduzir cesárea"
não é inequivocamente bom.

**Teste de falsificação que vale copiar:** apresentação pélvica. Nesses casos a
cesárea é indicada independentemente do estilo do hospital, então o efeito deve
sumir — e some (estimativa ≈ −0,002).

**Ameaça residual que eles tratam explicitamente:** *correlated beneficial care*
(McClellan et al. 1994) — hospitais de alta cesárea podem ser melhores em outras
dimensões. Endereçam com instrumentos múltiplos por domínio de qualidade.

---

## 6. Descontinuidade clínica

**Referência:** Almond, Doyle, Kowalski & Williams (2010), *QJE* 125(2):591-634.

**Variação:** limiar de "muito baixo peso" em 1500g. Classificação administrativa
gera salto no tratamento sem salto na saúde subjacente.

**Achados:** mortalidade em um ano cai ~1 p.p. logo abaixo de 1500g (média de 5,5%
logo acima); tratamento sobe 10–15%. Custo por vida estatística salva ≈ US$550 mil.

**Checagens obrigatórias:** McCrary para manipulação do *running variable*; ausência
de efeito em limiares falsos (1600g).

**Aplicação a parto:** o desenho é transferível a qualquer limiar clínico que dispara
protocolo — 37 semanas (termo), 34 semanas, limiares de peso. No Brasil o SINASC tem
peso e idade gestacional, então é viável.

---

## 7. Responsabilidade civil

**Referências:** Currie & MacLeod (2008), *QJE* 123(2):795-830; Frakes (2013), *AER*
103(1):257-276.

**Achado de Currie & MacLeod que surpreende:** reformas diferentes têm **sinais
opostos**. Reforma da regra de *deep pockets* (responsabilidade solidária) *reduz*
cesárea e complicações; teto para danos não econômicos *aumenta*.

**Lição transferível:** "medicina defensiva" não é um parâmetro único. A direção
depende de qual margem do risco jurídico a reforma altera. Papers que tratam risco de
litígio como escalar tendem a achar nulo por agregação de efeitos opostos.

---

## 8. Decomposição contábil

**Kitagawa (1955) / Oaxaca-Blinder.** Não é identificação causal — é contabilidade.
Decompõe um gap bruto entre setores ou hospitais em composição de pacientes vs.
estilo de prática.

**Uso legítimo:** estabelecer que o gap não é case-mix, motivando o exercício causal
que vem depois.

**Uso ilegítimo:** chamar o resíduo de "efeito". O resíduo é tudo que não está nas
covariáveis observadas, incluindo seleção não observada.

**Como reportar:** "X% do gap é atribuível à composição observável de pacientes; o
restante é consistente com diferenças de estilo de prática, mas não identificado
como tal."

---

## 9. Desenhos que já não passam

- **Transversal entre áreas com controles.** A literatura demonstrou que controles
  observáveis ricos não removem a endogeneidade do modo de parto. Costa-Ramón et al.
  (2018) fazem esse ponto explicitamente.
- **Densidade de médicos como choque de renda.** Locação de médico é endógena.
  Gruber & Owings já discutiam isso em 1996 e preferiram fecundidade.
- **Efeitos fixos de hospital como estratégia de identificação.** Bensnes (2026)
  mostra que falha sob alocação endógena de pacientes, com viés de sinal previsível.
- **Comparar setor público e privado sem contraste dentro do mesmo dia/mercado.**
  Confunde composição, tecnologia, preferência e incentivo.
- **Usar "10–15% da OMS" como contrafactual.** Esse alvo é da declaração de 1985. A
  vigente (WHO/RHR/15.02, 2015) recomenda explicitamente **não** perseguir taxa-alvo,
  aponta ~10% populacional como o ponto acima do qual não há ganho de mortalidade, e
  propõe Robson para comparações. Ver `referee-playbook.md`, O7.
`````

---

## Referência 2 — mapa da literatura

**Arquivo:** `birth-health-econ/references/literature-map.md` · 142 linhas · magnitudes conferidas contra os textos originais, para checar se um coeficiente é plausível

`````markdown
# Mapa da literatura — economia do parto

Use para posicionar um paper, checar se um coeficiente é plausível, ou montar a
seção de literatura. Magnitudes conferidas contra os textos originais.

## Índice

1. [Incentivos financeiros e demanda induzida](#1-incentivos-financeiros-e-demanda-induzida)
2. [Conveniência e timing](#2-conveniência-e-timing)
3. [Capacidade, lotação e staffing](#3-capacidade-lotação-e-staffing)
4. [Efeitos da cesárea sobre saúde](#4-efeitos-da-cesárea-sobre-saúde)
5. [Litígio e regulação](#5-litígio-e-regulação)
6. [Estilo de prática e variação geográfica](#6-estilo-de-prática-e-variação-geográfica)
7. [Brasil e América Latina](#7-brasil-e-américa-latina)
8. [Fronteira aberta](#8-fronteira-aberta)

---

## 1. Incentivos financeiros e demanda induzida

| Trabalho | Contexto | Magnitude central |
|---|---|---|
| Gruber & Owings (1996), *RAND* 27(1):99-123 | EUA 1970–82, queda de fecundidade | −10% fecundidade → +0,97 p.p. cesárea |
| Gruber, Kim & Mayzlin (1999), *JHE* 18(4):473-490 | Diferencial Medicaid | +US$100 diferencial → +3,9% cesárea |
| Grant (2009), *JHE* 28(1):244-250 | HCUP, reanálise | Revisa conclusões acima |
| Clemens & Gottlieb (2014), *AER* 104(4):1320-1349 | Medicare, choque de preço | Elasticidade de oferta ≈2,5; eletivo responde 2× |
| Alexander (2020), *JPE* 128(11):4046-4096 | Pagar médico para reduzir custo | Consequências não intencionais |
| de Elejalde & Giolito (2021), *JHE* 75:102411 | Chile, acesso a privado | +8,7 p.p. privado; +4,6 p.p. cesárea |
| Foo, Lee & Fong (2017), *AJHE* 3(3):422-453 | Preço de médico vs. hospital | Separa as duas margens |

**O ponto teórico que organiza o bloco:** McGuire (2000) e Dranove (1988) formalizam
a agência médico-paciente. Gruber & Owings testam com choque de renda; Gruber-Kim-
Mayzlin com choque de preço; de Elejalde & Giolito mostram que o incentivo sobrevive
*sem* diferencial de preço, via agendabilidade.

## 2. Conveniência e timing

| Trabalho | Contexto | Magnitude |
|---|---|---|
| Brown III (1996), *JHE* 15(2):233-242 | Demanda do médico por lazer | Fundador do mecanismo |
| Spetz, Smith & Ennis (2001), *Medical Care* 39(6):536-550 | Califórnia | Timing de cesárea |
| Dickert-Conlin & Chandra (1999), *JPE* 107(1):161-177 | Incentivo tributário | Manipulação pela família |
| Gans & Leigh (2009), *JPubE* 93(1-2):246-263 | Austrália, mudança de política | Deslocamento em torno de data |
| Gans & Leigh (2012), *Economic Record* 88(281):182-194 | Poder de barganha da paciente | |
| Fabbri et al. (2016), *Health Policy* 120(7):780-789 | Itália | Manipulação da hora exata |
| Costa-Ramón et al. (2018), *JHE* 59:46-59 | Espanha, hora do dia | Cesárea evitável piora saúde neonatal |
| Jacobson, Kogelnik & Royer (2021), *JOLE* 39(S2) | Feriados EUA | Timing e desfechos pós-natais |
| Costa-Ramón et al. (2022), *JHR* 57(6):2048-2085 | Finlândia, véspera de feriado | 1º estágio +1,4 p.p. (+9,6%); asma ↑ |

## 3. Capacidade, lotação e staffing

Bloco com **resultados de sinal oposto** — trate com cuidado e diga qual margem você mede.

| Trabalho | Margem | Sinal |
|---|---|---|
| Freedman (2016), *AEJ:EP* 8(2):154-185 | Leitos de UTI neonatal vazios | Leito vazio → mais internação |
| Marks & Choi (2019), *AJHE* 5(3):376-406 | Lotação como IV para gasto | |
| Maibom, Sievertsen, Simonsen & Wüst (2021), *JHE* 75:102399 | Lotação de maternidade | Menos procedimento sob lotação |
| Facchini (2022), *JEBO* 197:370-394 | Pessoal (parteiras) | Menos pessoal → **mais** cesárea |
| Bachner, Halla & Pruckner (2024), IZA DP 16981 | Ocupação de leito | −1 d.p. ocupação → **+1,07 p.p.** cesárea |
| Bensnes (2026), *Health Economics* 35(2):175-211 | Congestionamento (IV por data provável) | Congestão → menos intervenção, melhor saúde |

**Reconciliação:** Facchini varia *pessoal* (cesárea poupa trabalho de parteira);
Bachner e Bensnes variam *ocupação de leito* (leito vazio libera capacidade cirúrgica).
Não são contraditórios; são margens distintas. Um paper que reporta nulo em capacidade
deve dizer explicitamente qual das duas mede.

## 4. Efeitos da cesárea sobre saúde

| Trabalho | Desenho | Achado |
|---|---|---|
| Card, Fenizia & Silver (2023), *AEJ:EP* 15(2):42-81 | IV por distância relativa | Melhor no nascimento (−0,82 p.p. Apgar baixo, menos readmissão); **pior** respiratório no 1º ano |
| Costa-Ramón et al. (2018), *JHE* 59:46-59 | IV hora do dia | Cesárea evitável piora saúde neonatal |
| Costa-Ramón et al. (2022), *JHR* 57(6) | IV véspera + DiD irmãos | Asma ↑; sem efeito em diabetes tipo 1, obesidade |
| Almond, Doyle, Kowalski & Williams (2010), *QJE* 125(2):591-634 | RD em 1500g | Mortalidade −1 p.p.; US$550 mil/vida |
| Jensen & Wüst (2015), *JHE* 39:289-302 | Bebês pélvicos | Cesárea pode melhorar |
| Halla, Mayr, Pruckner & García-Gómez (2020), *JHE* 72 | Áustria | Cesárea reduz fecundidade subsequente |
| Norberg & Pantano (2016), *J. Pop. Econ.* 29(1):5-37 | | Cesárea e fecundidade |
| Borra, González & Sevilla (2019), *JEEA* 17(1):30-78 | Antecipação de parto | Efeito sobre saúde infantil |

**Estado da arte:** o trade-off é real e tem os dois lados. Card et al. é a referência
de que "reduzir cesárea" não é inequivocamente bom. Qualquer paper que trate cesárea
como puro dano está desatualizado.

## 5. Litígio e regulação

| Trabalho | Achado |
|---|---|
| Currie & MacLeod (2008), *QJE* 123(2):795-830 | Reformas de sinais **opostos**: *deep pockets* ↓ cesárea; teto de danos ↑ |
| Frakes (2013), *AER* 103(1):257-276 | Padrão nacional reduz 30–50% do gap de utilização |
| Frakes & Gruber (2020), *JELS* 17(1):4-37 | Sistema de saúde militar |
| Dubay, Kaestner & Waidmann (1999), *JHE* 18(4):491-522 | Medo de má prática e taxa de cesárea |
| Amaral-Garcia, Bertoli & Grembi (2015) | Itália, descontinuidade geográfica |
| Chen, Richards & Shriver (2025), *JPAM* 44(4):1194-1210 | Regulação de risco e decisão médica |

## 6. Estilo de prática e variação geográfica

Epstein & Nicholson (2009), *JHE* 28(6):1126-1140 — formação de estilo em cesárea,
o mais diretamente aplicável. Molitor (2018), *AEJ:EP* 10(1):326-356 — migração de
cardiologistas. Finkelstein, Gentzkow & Williams (2016), *QJE* 131(4):1681-1726 —
migração de pacientes; decomposição oferta/demanda. Cutler, Skinner, Stern &
Wennberg (2019), *AEJ:EP* 11(1):192-221 — crenças do médico vs. preferência do
paciente. Currie, MacLeod & Van Parys (2016), *JHE* 47:64-80 — estilo e desfechos.
Robinson, Royer & Silver (2023), NBER WP 31871 — variação geográfica de cesárea nos EUA.

## 7. Brasil e América Latina

| Trabalho | Contexto |
|---|---|
| Melo & Menezes-Filho (2023), *Health Economics* 32(2):501-517 | Avaliação da política nacional de redução de cesárea; −1,6 p.p., +0,07 semana, +10 g |
| Melo & Menezes-Filho (2024), *Health Economics* 33(9):2013-2058 | Carnaval; classificam hospitais por % de leitos obstétricos SUS/privado |
| Spinola & Rocha (2025/26), *EJHE* 27(5):1117-1148 | ~37 milhões de nascimentos; manipulação saliente no privado e entre brancas; gradiente racial |
| Parfitt & Goulart (2026), *JDE* 181, DOI 10.1016/j.jdeveco.2026.103725 | Ondas de calor, 25 mi de partos em hospitais **públicos** 2008–19; calor → menos parto conduzido por médico, mais por enfermagem, **queda** na cesárea; entre partos com médico, mais cesárea pré-parto; sem efeito em Apgar |
| de Elejalde & Giolito (2021), *JHE* 75:102411 | Chile |
| Herrera-Almanza, Marquez-Padilla & Prina (2024), *WBER* 38(1):139-160 | México; cesárea, obesidade, especialização |
| Oliveira, Lee & Quintana-Domeque (2022), *Health Economics* 31(8):1800-1804 | Brasil; autonomia da mulher e cesárea |
| Pilvar & Yousefi (2021), *JHE* 79 | Irã; reforma de incentivos |

**Fatos de contexto do Brasil** (úteis em introdução, cheque a fonte antes de citar):
taxa geral ~56–57%, segunda maior do mundo depois da República Dominicana; setor
suplementar >80%, SUS 20–30%; SINASC cobre ~42 milhões de nascimentos 2010–2024.

## 8. Fronteira aberta

Onde há espaço para contribuição:

- **Clima e prática obstétrica.** Parfitt & Goulart abriram; só hospitais públicos,
  só até 2019. Setor privado e mecanismo de alocação de tarefas estão em aberto.
- **Gradiente racial na manipulação de timing.** Spinola & Rocha documentaram no
  Brasil; pouco explorado em outros contextos.
- **Demand smoothing fora do Chile.** A previsão de de Elejalde & Giolito —
  reagendamento antecipando semanas de alta demanda — é testável em qualquer país com
  microdados diários e é raramente testada.
- **Efeitos de longo prazo além de asma.** Costa-Ramón et al. (2022) descartam
  vários canais; capital humano e escolaridade seguem pouco estudados fora da
  Escandinávia.
- **Interação preço × agendabilidade.** Se o preço não move a cesárea mas a
  agendabilidade move, qual é o desenho que separa os dois? Poucos papers atacam.
- **Avaliação de programas de redução de cesárea.** A maioria não tem desenho causal
  crível — adesão voluntária no nível do hospital gera seleção que a maior parte dos
  trabalhos não trata.
`````

---

## Referência 3 — manual do parecerista

**Arquivo:** `birth-health-econ/references/referee-playbook.md` · 211 linhas · as objeções recorrentes do campo e a resposta canônica de cada uma. Serve nas duas direções: blindar um manuscrito e estruturar um referee report

`````markdown
# Manual do parecerista — objeções recorrentes e respostas canônicas

As objeções deste campo são previsíveis. Cada uma tem uma resposta que a literatura
já estabeleceu, e cada resposta corresponde a uma tabela ou figura específica. Papers
que embutem essas respostas no desenho passam; papers que as tratam como apêndice
defensivo, não.

Use nas duas direções: para blindar um manuscrito antes de submeter, e para estruturar
um referee report.

---

## O1. "A variação temporal não é aleatória em relação à necessidade médica"

A objeção número um contra qualquer desenho de conveniência. Se cesáreas se concentram
no fim do turno, talvez trabalhos de parto difíceis simplesmente demorem mais.

**Resposta canônica — balanço em predeterminadas.** Regrida características fixadas
antes do parto (idade materna, escolaridade, paridade, pré-natal, sexo do bebê) sobre
o instrumento. Padronize cada uma para média 0 e d.p. 1 e reporte todas num painel
único. Costa-Ramón et al. (2022) fazem exatamente isso.

**Reforço 1 — margem sem discricionariedade.** Mostre que o gradiente some onde não há
espaço para escolha. Multíparas (trabalho de parto mais rápido), cesárea de repetição,
apresentação pélvica.

**Reforço 2 — dias em que não se agenda.** Repita em fins de semana e feriados, quando
o hospital não programa cirurgia. Bachner et al. usam esse teste.

**Reforço 3 — procedimento-placebo.** Um procedimento notoriamente agendado e sem
relação com obstetrícia deve mostrar o padrão oposto ou nenhum. Bachner et al. usam
cirurgia de câncer de mama.

**O que não funciona:** afirmar que o horário é "as good as random". Não escreva isso.
O campo aprendeu a desconfiar da frase, e ela convida hostilidade.

---

## O2. "Isso é composição de pacientes, não mudança de comportamento"

**Resposta canônica — camadas de controle com o coeficiente estável.** Reporte o mesmo
coeficiente sob: (a) especificação básica, (b) + covariáveis predeterminadas, (c) +
composição clínica (grupos de Robson ou equivalente). Se o coeficiente cai pouco, a
composição não explica. Mostre as três colunas lado a lado, não só a final.

**Reforço — decomposição.** Kitagawa ou Oaxaca separando o gap bruto em composição
observável e resíduo. Reporte a fração, não o "efeito".

**Reforço — contraste dentro da unidade mais fina possível.** Efeitos fixos de
município×data, ou hospital×mês, absorvem tudo que é comum localmente naquele dia:
clima, epidemia, feriado local, choque de demanda. É o argumento mais forte disponível
sem experimento, e vale dizê-lo explicitamente.

---

## O3. "Isso é um LATE de um subgrupo estreito — e daí?"

Objeção legítima e frequentemente subestimada. Um IV de hora do dia identifica o efeito
nas mulheres cuja cesárea foi determinada pelo relógio — um grupo pequeno e atípico.

**Resposta:** não fuja, caracterize. Descreva as *compliers*: quantas são, como se
comparam à média amostral, em que grupo de Robson estão. Depois argumente por que
*esse* grupo é o relevante para política — geralmente porque é exatamente a margem
que uma intervenção conseguiria mover.

Card et al. (2023) fazem isso bem: descrevem as "hospital compliers" antes de
interpretar.

**Não escreva** "our LATE is likely close to the ATE" sem evidência. Se você tem
modelos de coeficiente aleatório correlacionado, mostre; senão, assuma o LATE.

---

## O4. "Por que não há efeito sobre saúde? Vocês têm potência?"

Desfechos neonatais graves são raros — mortalidade neonatal 3–5 por mil, asfixia ~3
por mil, histerectomia não planejada 1 em 10 mil.

**Resposta:** reporte o intervalo de confiança e diga o que ele **descarta**. "Nossas
estimativas descartam efeitos maiores que X p.p." é uma afirmação informativa;
"não encontramos efeito" não é.

Card et al. fazem isso explicitamente para asfixia e histerectomia, admitindo baixa
precisão em vez de alegar nulo.

**Corolário — não enterre os nulos.** Um nulo bem reportado delimita a alegação e
aumenta a credibilidade do resto. Pareceristas experientes desconfiam de papers em que
tudo dá certo.

---

## O5. "O gap público–privado é tecnologia e paciente, não incentivo"

**Resposta — contraste dentro do mesmo mercado e mesmo dia.** Compare estabelecimentos
de propriedades diferentes no mesmo município na mesma data. Isso absorve preferência
local, clima, choque de demanda e sazonalidade.

**Reforço — margem de agendabilidade.** Se o mecanismo é conveniência, o diferencial
deve estar na cesárea pré-parto e não na intraparto. Essa separação é frequentemente
a evidência de mecanismo mais persuasiva disponível.

**Reforço — composição de risco.** Mostre que o diferencial sobrevive dentro do grupo
de Robson 1 (nulípara, termo, único, cefálico, espontâneo) — a população com menos
justificativa clínica para cesárea.

---

## O6. "Isso não é canal climático / sazonal não modelado?"

Objeção nova, ganhando força depois de Parfitt & Goulart (2026).

**Resposta de primeira linha:** efeitos fixos de município×data já absorvem toda a
temperatura comum aos dois setores naquele dia local. A ameaça residual exige que os
setores respondam **diferentemente** à temperatura, de forma correlacionada com o
calendário. Diga isso explicitamente — é um argumento forte e frequentemente
suficiente.

**Cinto e suspensórios, se houver tempo:** painel município-dia de temperatura
(ERA5-Land é preferível a estações do INMET por cobertura uniforme), bins ao estilo
Deschênes-Greenstone / Barreca, e a especificação principal interagida com os bins.
Adicione as referências metodológicas ao `.bib` junto com a rodada, não depois.

---

## O7. "Vocês chamam de 'cesáreas desnecessárias' sem definir o contrafactual"

**Resposta:** não use "unnecessary" como se fosse observável. Se você calcula um
benchmark de excesso, chame de benchmark mecânico e diga a aritmética. A diferença
entre "cesáreas em excesso relativas a um contrafactual" e "cesáreas causadas por X" é
exatamente onde o parecerista vai apertar.

**Erro factual associado, comum e caro:** citar "10–15%" como recomendação da OMS.
Esse alvo é da declaração de **1985**. A declaração vigente — WHO/RHR/15.02 (2015) —
afirma que se deve atender quem precisa em vez de perseguir uma taxa específica, que
acima de ~10% ao nível populacional não há evidência de redução adicional de
mortalidade materna e neonatal, e propõe a **classificação de Robson** como o padrão
para comparar instituições. Um paper que usa 10–15% como contrafactual individual
comete dois erros de uma vez: usa referência populacional no nível individual, e usa
uma referência que a própria OMS abandonou.

**Teste de coerência aritmética.** Quando um paper reporta um coeficiente *e* uma
contagem de "excesso", confira se os dois batem. Frequentemente o coeficiente usa um
contrafactual (o setor público, por exemplo) e a contagem usa outro (a referência da
OMS), sem reconciliação — e a manchete acaba sendo múltiplos do que a própria
regressão sustenta. É uma checagem de trinta segundos que rende um comentário maior.

---

## O8. "Efeitos fixos de hospital resolvem a seleção"

Não resolvem, e desde Bensnes (2026) há demonstração formal. Se pacientes escolhem
hospital com base em características não observadas correlacionadas com o desfecho,
efeitos fixos de instituição não removem o viés — e o sinal do viés é previsível.

**Se você usa efeitos fixos de hospital como identificação**, precisa responder a esse
argumento diretamente. Se usa como *controle* dentro de um desenho que tem outra fonte
de variação exógena, diga isso claramente para não ser confundido.

---

## O9. "Vocês controlaram por variáveis pós-tratamento"

Objeção silenciosa mas fatal, e frequente em papers de parto porque as covariáveis
mais disponíveis são justamente as contaminadas.

- **Idade gestacional e peso ao nascer** são desfechos do agendamento. Controlar por
  eles condiciona no canal que você quer medir.
- **Número de consultas de pré-natal** é escolhido conjuntamente com o prestador e
  pode ser colisor.
- **Cesárea prévia** é predeterminada e legítima — e é o preditor dominante do modo de
  parto. Sua ausência na lista de controles é um sinal de trabalho apressado.

**Resposta:** mova as contaminadas para a coluna de desfechos ou para a definição de
amostra, e mostre que o coeficiente principal não depende delas.

## O10. "O efeito é mecânico, não comportamental"

Quando o desfecho é uma *taxa* e a variação explicativa move o denominador, parte do
coeficiente é identidade contábil. Chegam mais parturientes espontâneas num dia
movimentado → a fração de cesáreas cai sem que ninguém mude de conduta.

**Resposta:** estime no nível individual, ou modele contagens de cesárea e de parto
vaginal separadamente e mostre que o resultado vem do numerador. Se o coeficiente
sobrevive em nível individual com efeitos fixos finos, o argumento mecânico morre.

## O11. "Erros-padrão"

Convenções do campo:

- Cluster no nível da variação do tratamento — hospital, hospital×ano, ou município.
- Poucos clusters (< ~40) → wild bootstrap (Cameron, Gelbach & Miller 2008; Webb 2023).
- Muitas hipóteses → correção de testes múltiplos por família de desfechos
  (Benjamini-Hochberg ou Holm), com as famílias declaradas *ex ante*.
- Event study com adoção escalonada → estimador robusto a efeitos heterogêneos
  (Sun & Abraham 2021 e sucessores). TWFE simples atrai objeção automática.

---

## Checklist antes de submeter

- [ ] O estimando de cada tabela está nomeado, e nenhuma frase desliza entre eles
- [ ] Balanço em predeterminadas reportado, não só mencionado
- [ ] Amostra restrita a partos de baixo risco, com a definição explícita
- [ ] Pré-parto vs. intraparto separados, se os dados permitem
- [ ] Nulos reportados com o que o IC descarta
- [ ] Magnitudes comparadas com a literatura, e divergências explicadas
- [ ] Uma seção institucional que explica pagamento e agendamento no sistema estudado
- [ ] Frase de escopo no fim da introdução dizendo o que o desenho não identifica
- [ ] Cluster e testes múltiplos justificados
- [ ] Referências conferidas contra as fontes — títulos, volumes, coautores
`````

---

## Referência 4 — dados brasileiros de parto

**Arquivo:** `birth-health-econ/references/data-brazil.md` · 152 linhas · SINASC, SIH, CNES, TISS: variáveis, convenções e armadilhas de codificação que já produziram resultados errados

`````markdown
# Dados brasileiros de parto — fontes, convenções e armadilhas

O Brasil é um dos melhores laboratórios do mundo para esta literatura: taxa entre as
mais altas do planeta, contraste institucional forte entre SUS e saúde suplementar,
e microdados universais desde os anos 1990. Também é cheio de armadilhas de
codificação que já produziram resultados errados.

## Fontes

### SINASC — Sistema de Informações sobre Nascidos Vivos
Registro universal de nascidos vivos (DATASUS). ~42 milhões de nascimentos 2010–2024.

**Variáveis que sustentam desenhos:**
- `PARTO` — modo de parto (1 vaginal, 2 cesárea)
- `DTNASC` e `HORANASC` — **data e hora do nascimento**. A hora é o que viabiliza
  desenhos de conveniência temporal no Brasil.
- `PESO` — peso ao nascer, em gramas. Viabiliza RD em limiares clínicos.
- `SEMAGESTAC` / `GESTACAO` — idade gestacional. Permite separar termo, early-term
  (37–38 sem) e pré-termo.
- `CODESTAB` — código CNES do estabelecimento. Chave para juntar com o cadastro.
- `CODMUNNASC` / `CODMUNRES` — município de nascimento e de residência
- `APGAR1`, `APGAR5` — Apgar
- `STTRABPART`, `STCESPARTO` — trabalho de parto e cesárea antes do trabalho de parto.
  **Estas duas permitem separar cesárea pré-parto de intraparto**, que é a distinção de
  mecanismo mais informativa do campo.
- `TPROBSON` — grupo de Robson, disponível em anos recentes
- `PARIDADE`, `QTDPARTCES`, `QTDPARTNOR` — paridade e histórico

### SIH/SUS — internações
Autorizações de Internação Hospitalar. Cobre só o SUS. Útil para procedimento,
diagnóstico e custo pago pelo SUS. Não cobre saúde suplementar.

### TISS — Troca de Informação em Saúde Suplementar (ANS)
Base hospitalar do setor privado. É a fonte que permite observar **honorário
efetivamente pago** por parto — raro internacionalmente e o que torna possível testar
resposta a preço diretamente em vez de por proxy.

### CNES — Cadastro Nacional de Estabelecimentos de Saúde
Leitos, profissionais, natureza jurídica do estabelecimento. Mensal.

### SIM — mortalidade
Para mortalidade neonatal. **Não há identificador que permita casar perfeitamente SIM
com SINASC no dado público** — limita análise de heterogeneidade em mortalidade. Melo
& Menezes-Filho reconhecem essa limitação explicitamente.

### Outras
IEPS Data (indicadores municipais consolidados); Base dos Dados (acesso via BigQuery);
lista de hospitais do Projeto Parto Adequado (ANS).

---

## Classificação de Robson

Sistema da OMS que agrupa partos em 10 grupos por características obstétricas
(paridade, cesárea prévia, número de fetos, apresentação, idade gestacional, início
do trabalho de parto).

**Por que importa:** é a linguagem que o público médico aceita para "ajustar por
composição". Uma tabela de Robson faz mais pela credibilidade junto a um parecerista
clínico do que várias robustezes econométricas.

**Grupos que interessam à economia:**
- **Robson 1** — nulípara, feto único, cefálico, ≥37 semanas, trabalho de parto
  espontâneo. É a população com menos justificativa clínica para cesárea, e por isso o
  melhor teste de discricionariedade.
- **Robson 2** — nulípara, mesmas condições, mas induzida ou cesárea antes do trabalho
  de parto. Comparar 1 e 2 isola a margem de agendamento.
- **Robson 5** — cesárea prévia. Grande, mas com pouca discricionariedade.

**Uso correto:** Robson é corroboração de que o efeito não é composição. Não é placebo
— cesárea em Robson 1 pode ser clinicamente indicada.

---

## Armadilhas conhecidas

### Natureza jurídica no CNES
Códigos `1xxx` são administração pública, `2xxx` entidades empresariais, `3xxx`
entidades sem fins lucrativos.

**Erro que já apareceu em código:** mapear com `else → Público`. Estabelecimentos não
pareados acabam classificados como públicos e contaminam a comparação. Use conjuntos
explícitos e mande não pareados para `Outros`.

**Erro conceitual mais grave:** tratar "com fins lucrativos" (natureza jurídica do
estabelecimento, no SINASC) como sinônimo de "setor de saúde suplementar" (fonte de
pagamento, no TISS). São dimensões diferentes: um hospital privado atende SUS, e um
hospital filantrópico atende planos. Se seu paper compara os dois, nomeie qual está
usando em cada tabela.

Note também que estudos brasileiros usam definições setoriais **não comparáveis entre
si**: Melo & Menezes-Filho classificam por percentual de leitos obstétricos alocados a
cada sistema; Parfitt & Goulart analisam apenas hospitais públicos; outros usam
natureza jurídica. Ao comparar coeficientes entre papers, compare mecanismos, não
magnitudes.

### Código de município
SINASC traz IBGE de 7 dígitos; a maior parte das bases auxiliares usa 6. Use os 6
primeiros. O Distrito Federal aparece por região administrativa em algumas bases do
CNES — corrija **antes** de qualquer contagem de unidades distintas, não depois.

### CBO de obstetra
O código `225270` não é o conjunto certo. Use `{225250, 223132, 6149, 6145}`.

### Cobertura temporal de feriados
Arquivos de calendário de feriados frequentemente cobrem menos anos que a amostra.
Confira o intervalo antes de gerar as variáveis — um desalinhamento silencioso zera
feriados nos primeiros anos.

### Indução de trabalho de parto
A variável entrou no SINASC em 2010 mas foi mal preenchida no início — só 27% dos
nascimentos em 2010–11, subindo para ~95% a partir de 2012. Restrinja o período se
usar essa variável.

### Idade gestacional
Existe em versão categórica e contínua conforme o ano. Confira qual está no seu
arquivo antes de definir termo/pré-termo. **Pré-termo não é "não agendável"** —
pré-eclâmpsia, restrição de crescimento e cesárea eletiva late-preterm são agendadas.
Usar pré-termo como placebo é erro de interpretação clínica.

---

## Choques institucionais utilizáveis

- **RN 368/2015 (ANS)** — regra nacional obrigando planos a informar taxas de cesárea
  por operadora, hospital e médico mediante solicitação, e tornando partograma e termo
  de consentimento obrigatórios para cesárea eletiva.
- **Ação civil pública de dezembro/2015 (SP)** — decisão determinando que a ANS
  criasse regra de pagar ao menos 3× mais por parto vaginal. A agência recorreu e a
  regra **nunca entrou em vigor**. Útil como placebo — anúncio sem implementação.
- **Projeto Parto Adequado (ANS + IHI)** — programa de qualidade, adesão **voluntária
  no nível do hospital**, piloto 2015–16 e fase de disseminação 2017–2021 com ~113
  hospitais em 60 municípios.

**Alerta de desenho:** adesão voluntária a nível de hospital gera seleção. Um DiD
ingênuo compara hospitais que escolheram aderir com os que não escolheram. A maioria
das avaliações publicadas do Parto Adequado não trata isso. Se você for usar, precisa
de uma fonte de variação na adesão, ou tratar explicitamente como descritivo.

Para a avaliação com desenho causal da política nacional, ver **Melo & Menezes-Filho
(2023), *Health Economics* 32(2):501-517** — encontram −1,6 p.p. na taxa de cesárea,
+0,07 semana de gestação e +10 g de peso.

---

## Ferramentas

Sem R no ambiente de sandbox: verificações e réplicas em Python com `pyarrow`,
`pandas`, `pyfixest`. Para volumes na casa de dezenas de milhões de linhas, leia
subconjuntos de colunas em parquet em vez de arquivos inteiros, e evite rodar dois
scripts pesados em paralelo.
`````

---


# PARTE III — A organização do projeto

## 1. A pasta que você conecta no Cowork

```
parto_cesareo/                     ← conecte ESTA pasta no Cowork
├── CONTEXTO_PESQUISA.md           contexto completo da pesquisa (310 linhas)
├── ROADMAP.md                     plano até março/2027, cronograma, divisão de tarefas
├── PARECER_INTERNO_2026-08-20.md  parecer simulado de JHE/AEJ:Policy sobre a versão atual
├── scripts_github/                O REPOSITÓRIO (código + LaTeX + outputs)
├── dataset/                       OS MICRODADOS (12 GB — fora do git, não versionar)
└── Literature/                    papers de referência em texto integral + verificações
```

**Os três arquivos vivos e a hierarquia entre eles:**

| Arquivo | Do que é dono | Vence quando |
|---|---|---|
| `scripts_github/CLAUDE.md` | Código e números | Conflito sobre resultado, especificação, convenção de código |
| `ROADMAP.md` | Prazos e responsáveis | Conflito sobre quem faz o quê e até quando |
| `CONTEXTO_PESQUISA.md` | Visão geral | É o ponto de entrada; em conflito, perde para os dois acima |

Divergência real entre eles **é para ser apontada, não resolvida em silêncio** — está codificado na skill.

## 2. Dentro de `scripts_github/`

```
config/     config.R              ← O ÚNICO ARQUIVO A EDITAR POR MÁQUINA (DROPBOX_ROOT)
            00_master_build.R · 00_master_analysis.R
build/      00_utils.R · 01a_tiss.R · 01b_sinasc_cnes.R · 01c_ieps.R
            01d_cnes_estab.R (RUN_01D=1) · 02_deliveries.R · 03_workfile.R
analysis/   code/   00_utils · 01_descriptives · 02_regressions (preço) ·
                    03_mechanisms · 04_heterogeneity · 05_cost · 06_robustness ·
                    07_main_specification (Eq. 3) · 08_long_weekends ·
                    09_org_capacity · 10_supplement · 12_subgroups · 11_body_figures
            output/ {graphs, tables, maps}   ← versionado no git
latex/      paper.tex · model.tex (Apêndice A) · appendix.tex · sup_appendix.tex ·
            supplement.tex · refs.bib · highlights.txt · plainnat-rev.bst
dictionary/ dicionários TISS da ANS + variable_dictionary.xlsx
renv.lock · sessionInfo.txt        ← reprodução exata do ambiente R
CLAUDE.md                          ← o documento vivo do repositório (650 linhas)
```

**Três armadilhas de execução:**

1. **`12` roda ANTES de `11`**, apesar do número. O `12_subgroups.R` salva `robson_grad.rds`, que o `11_body_figures.R` desenha como painel (c) da Figura 3.
2. **`07`, `08` e `09`** salvam cada um uma família de hipóteses (`fam_A`, `fam_D`, `fam_E`) que o **`10`** lê para a tabela de testes múltiplos.
3. **Nunca rodar dois scripts de 42M linhas em paralelo** (03, 05, 06, 07, 08, 09, 12). Cada um carrega `sinasc_births.parquet`; dois juntos estouram a memória (o `12` sozinho chega a ~14 GB). Pico ~12 GB · análise completa ~90 min · `07` sozinho ~40 min.

## 3. Dentro de `dataset/` (verificado)

| Fonte | Arquivo | Conteúdo |
|---|---|---|
| **SINASC** | `SINASC/input/sinasc_births.parquet` | **42.003.663 nascimentos**, 2010-01-01 a 2024-12-31, 32 colunas |
| | `sinasc_daily_muni.parquet` | 8.805.014 células município × data × setor |
| | `sinasc_daily_timing_muni.parquet` | 4.217.907 células, com contagens pré-parto/intraparto/vaginal |
| | `sinasc_daily_estab.parquet` | 1.534.506 células estabelecimento × data (for-profit) |
| **TISS** | `TISS/input/Hospitalar/{CONS,DET}/Hosp_{2015..2025}_*.parquet` | 22 arquivos, 5,1 GB brutos |
| | `TISS/output/delivery_events_{2015..2025}.parquet` | eventos de parto com honorários |
| | `TISS/output/delivery_panel_muni_month.parquet` | 88.116 município-meses |
| **CNES** | `cnes_estab_year.parquet` | 84.213 estabelecimento-anos (leitos, obstetras, `nat_jur`) |
| | `cnes_beds_muni_year.parquet` | leitos por competência **mensal** — usar só dezembro ao agregar |
| **IEPS** | `ieps_muni_year.parquet` | covariáveis municipais |
| **workfile** | `workfile/output/main_data.parquet` | **11.567 município-anos, 26 colunas** — o arquivo analítico final |

**Descompasso conhecido (meta R1, aberta):** o código monta `file.path(DROPBOX_ROOT, "build", "TISS", ...)`, mas a pasta local se chama `dataset/`, sem o nível `build/`. Resolver antes de tentar rodar qualquer coisa.

## 4. Dentro de `Literature/`

12 papers em **texto integral extraído** (`.txt`, não PDF — o ambiente da coleta não baixava binário), mais:

- `README.md` — o que foi baixado, o que ficou de fora e por quê, mapa da literatura por bloco
- `triagem_download.md` — critério de priorização
- `verificacao_citacoes.md` — a checagem das 50 entradas do `refs.bib` (feita em 20/08/2026)
- `refs.bib` e `download_pdfs.sh` (para baixar os PDFs originais na sua máquina)

## 5. O Notion

Página **"Born on Schedule — Cesáreas no Brasil (JHE)"** 🍼, com duas bases relacionadas:

- **Metas** — 10 entregas com prazo, código (E1, R1, T1, D1, D3, D5, T2, O1, S1, TR1), Frente, Trilha, Risco, checkbox "Bloqueia submissão", `% concluído` por rollup. Views: Kanban, Por frente, Cronograma, Bloqueia submissão.
- **Tarefas** — o dia a dia, cada uma ligada a uma meta, com Responsável, Prazo, Prioridade.

**Regra:** ao concluir qualquer bloco de trabalho, atualizar **três** lugares — `ROADMAP.md`, a tarefa no Notion e o `CLAUDE.md` (se um número mudou). Deixar um dos três rançoso é exatamente como o erro entra.

## 6. Compilar o LaTeX — o `xr` roda nos DOIS sentidos

`supplement.tex` precisa de `paper.aux` **e** `paper.tex` precisa de `supplement.aux` (as ~29 referências `\satab`/`\safig`). O ciclo roda duas vezes e **os `.aux` têm de sobreviver entre as passadas — nunca limpar no meio**:

```bash
cd latex
pdflatex paper; bibtex paper
pdflatex supplement; bibtex supplement; pdflatex supplement
pdflatex paper; pdflatex paper
pdflatex supplement
```

Conferir: `grep -c "Reference .* undefined" paper.log` → tem de dar **0**.

---

# PARTE IV — Os resultados já encontrados

## 1. A pergunta, em duas linhas

O setor de maternidade for-profit brasileiro faz ~80% dos partos por cesárea — a maior taxa documentada em qualquer sistema de saúde de grande porte, contra a referência da OMS de 10–15%. Entre primíparas a termo, feto único, bem posicionado e **já em trabalho de parto espontâneo** (Robson 1), dois terços dos partos for-profit em dia útil terminam em cesárea, contra cerca de um terço no setor público.

O paper separa dois canais:

| Canal | Mecanismo | Veredito |
|---|---|---|
| **Preço** | Médico faz mais do que paga mais (Gruber–Owings) | **Não sustenta** |
| **Agenda (tempo)** | A cesárea converte um evento longo, de início incerto e que bloqueia o calendário num procedimento agendado de ~1h | **Sustenta** |

A contribuição é o **diagnóstico conjunto** preço-versus-tempo no mesmo cenário — viabilizado pelo TISS, que observa honorário efetivamente faturado, algo que a literatura internacional raramente tem.

## 2. As três equações

**Eq. (1) — canal preço.** `CesareanRate_mt = β·LogFeeGap_mt + X'γ + μ_m + δ_t + ε`. Município-ano, ponderado por partos privados, cluster na geografia do efeito fixo. Demanda induzida prevê β>0.

**Eq. (2) — gradientes de calendário descritivos.** `CesareanShare_mdt = β₁Weekend + β₂Holiday + β₃Eve + μ_m + δ_t + ε`, estimada **separadamente** para for-profit e público, cluster duplo (município, data).

**Eq. (3) — a especificação central.**

```
CesareanShare_mds = γ₁(ForProfit_s × Weekend_d)
                  + γ₂(ForProfit_s × Holiday_d)
                  + γ₃(ForProfit_s × Eve_d)
                  + λ_md + φ_ms + ε_mds
```

`λ_md` = EF município×data (absorve **todo** choque comum aos dois setores naquele dia local — inclusive clima), `φ_ms` = EF município×setor. Ponderado por nascimentos, cluster duplo.

**É o único desenho reconhecível do paper.** Todo o resto é mecanismo, magnitude ou robustez em torno dele. Causal apenas sob a hipótese de gradiente comum. **Chamar de *differential*, nunca de difference-in-differences.**

## 3. Os seis resultados

1. **A epidemia é real e extrema.** Cesárea for-profit ~82% (TISS) / ~79% (SINASC) vs. ~44% público; ~66% mesmo no Robson 1 em dia útil.
2. **Não é uma história de preço positivo.** Com o honorário vaginal *econômico* (parto + assistência horária ao trabalho de parto, TUSS 31309038), o gap é **negativo** nos grandes estados — e eles rodam ~80% de cesárea. O coeficiente é pequeno e instável (+0,017 com EF-UF, −0,014 com EF-município, ambos n.s.); oscilações de ±2 pontos log no estado não movem nada; a ordem judicial de 2015 nunca virou mudança de honorário.
3. **É uma história de agenda.** Cesáreas se aglomeram em dia útil e caem em fim de semana (−8,3pp for-profit / −6,7pp público) e feriado (−5,6 / −3,5); pico de centro cirúrgico às 8–11h; metade das cesáreas em horário comercial de dia útil, contra benchmark uniforme de 29,8%.
4. **Eq. (3), a estimativa central.** Dentro do mesmo município-dia, o differential for-profit é **−2,3pp fim de semana / −2,9pp feriado**, praticamente inalterado (−2,2 / −2,6) após ajustar por composição materna predeterminada, e −1,9 / −2,3 com Robson.
5. **O dip vive nas cesáreas pré-parto.** Dip de fim de semana for-profit de −9,7pp pré-parto vs. **+1,7pp** intraparto — o sinal invertido é assinatura de deslocamento, não resíduo. Persiste em Robson 1–2 de baixo risco (−7,4pp) e em Robson 1 sozinho (−6,5pp).
6. **O custo.** +11,7pp de early-term (37–38 sem) com controles maternos; 72% do gap é estilo de prática (Kitagawa); ~50 mil cesáreas de dia útil em excesso por ano; quase paridade nos valores faturados.

## 4. Números-âncora — use para checar qualquer alegação

SINASC = 2010–2024. Divergiu, investigue antes de escrever.

| Fato | Valor |
|---|---|
| Cesárea (todos / for-profit / nonprofit / público) | ~57% / **79,46%** / 59,24% / **42,74%** |
| Nascimentos totais SINASC | 42.003.663 |
| Dip de fim de semana (for-profit / público) | −8,3pp / −6,7pp |
| Dip de feriado (for-profit / público) | −5,6pp / −3,5pp |
| **Eq. (3) differential (EF muni×data)** | **fds −2,3pp / feriado −2,9pp**; +predeterminado −2,2 / −2,6; +Robson −1,9 / −2,3 |
| Dip de fds: pré-parto vs. intraparto (for-profit) | −9,7pp vs. +1,7pp |
| Robson 1–2 / Robson 1 (for-profit) | −7,4pp / −6,5pp |
| Perfil Robson, for-profit vs. público (Fig. 3c) | G1 −6,3/−3,7 · G2 −5,2/−3,8 · G3 −8,0/−3,0 · G4 −9,1/−4,2 · G5 −3,6/−5,8 · G10 **−5,1/−5,2 (idêntico)** |
| Eq. (3), termo vs. pré-termo | −2,5pp vs. **+0,8pp**; diferença +3,4pp, p<0,001 |
| Eq. (3), mãe <35 vs. 35+ | −3,0pp vs. +1,3pp (dif. +4,3, p<0,001); dentro de Robson 1–2, −5,0 vs. −1,4 |
| Feriado prolongado: teste bridge = isolated | p≈0,68 (pré-parto p≈0,95) — **sem** efeito bridge maior |
| Bunching pré-feriado (bridge) | −0,46/dia (**déficit**, não bunching) |
| Capacidade: fds×log(leitos) pré-parto | +0,45pp n.s.; escala +0,70pp* |
| Maternidades com zero obstetras (CNES-PF, ≥50 partos) | 14% for-profit / 27% público (mediana 3/2) |
| Early-term (37–38 sem), controles maternos | **+11,7pp*** |
| Kitagawa: gap de 35,1pp | 28% case-mix / **72% estilo de prática** |
| Cesáreas de dia útil em excesso | ~50 mil/ano for-profit (~10,5%) |
| `log_fee_gap` (EF UF / município) | +0,017 / −0,014 (n.s.) |

**Reprodução conferida no dataset local:** for-profit 7.127.004 / 8.968.808 = **79,46%**; público 7.281.504 / 17.036.207 = **42,74%**.

## 5. A taxonomia de evidência — o rótulo certo em TODO lugar

Vale para abstract, introdução, seção de estratégia, notas de tabela e conclusão. É o que separa "R&R" de "the authors overclaim".

| Resultado | Rótulo obrigatório |
|---|---|
| Regressões de honorário | Associações condicionais, **sinal instável**. Dizer *"no robust positive price relationship"*, nunca *"fees don't matter"* |
| Gradientes de fds/feriado (Eq. 2) | **Ordenação de calendário** dos partos, não o efeito causal de um fim de semana aleatório. Nunca escrever que o dia em que o parto cai é tão bom quanto aleatório em relação à necessidade médica — a data observada é em parte escolhida |
| Eq. (3) | O **differential** for-profit–público dentro do município-dia; causal só sob gradiente comum |
| Pré-parto vs. intraparto | Evidência de **mecanismo** |
| Feriado prolongado + event study | As previsões mais afiadas de lazer médico **não se confirmam**. O nulo delimita a alegação de "conveniência de quem" |
| Capacidade organizacional | "Redundância organizacional atenua o gradiente", **não** "o calendário do médico individual vs. o hospital" |
| Robson + termo/pré-termo + idade materna | **Corroboração, não placebo.** São em parte determinados pelas mesmas decisões sob estudo. Pré-termo ≠ não agendável (pré-eclâmpsia, RCIU, late-preterm eletivo são todos agendados) |
| Kitagawa | Contabilidade; 72% estilo de prática |
| ~50 mil cesáreas em excesso | Benchmark mecânico, não cesáreas causadas |
| Early-term +11,7pp | Associação setor–idade gestacional |
| Parto Adequado | Falha de um **desenho** causal (pré-tendências), não efeito de programa |

**Frase-padrão de escopo:**

> *"The evidence identifies calendar sorting and a tightly controlled for-profit–public differential; it does not identify the total number of cesareans or neonatal outcomes caused by scheduling."*

## 6. Os dois nulos — e por que eles ficam

**Feriados prolongados** (`08_long_weekends.R`, Tabela 4). Exercício pré-especificado: desfecho primário = participação de cesárea pré-parto, janela [−3,+3], 8 feriados nacionais de data fixa, 2012–2024. Taxonomia por dia da semana: **Isolated = quarta** (o único caso verdadeiramente isolado — feriado em seg/sex já cria fim de semana de 3 dias), **ThreeDay = seg/sex**, **Bridge = ter/qui**, feriado no fim de semana = placebo.
**Resultado nulo na direção prevista.** O dip de bridge não é maior que o de isolated (p≈0,68); não há bunching pré-feriado (−0,46/dia, um déficit); partos vaginais também caem em torno de feriados → parte disso é **contração da atividade institucional**, não rearranjo de agenda.

**Capacidade organizacional** (`09_org_capacity.R`, suplemento D.8). Painel estabelecimento-data; capacidade = leitos obstétricos defasados um ano + volume anual como controle de escala; EF `estab^year + muni^date`.
**Achado de validação:** a contagem de obstetras do CNES-PF é proxy **fraco** — entre maternidades com ≥50 partos, 14% (for-profit) e 27% (público) registram **zero** obstetras, porque o obstetra brasileiro mantém o vínculo CNES no consultório próprio, não no hospital do parto. Leitos carregam a análise.
**Resultado fraco/misto:** todas as interações positivas, mas só a de escala é significativa (fds×log partos ≈ +0,70pp); leitos×fds ≈ +0,45pp n.s.

**Por que ficam:** os dois nulos são o que **delimita** a alegação. A evidência de calendário identifica agendamento pelo lado da oferta, mas não a *conveniência de quem*. Pareceristas experientes desconfiam de papers em que tudo dá certo. Não enterrar, não reformular como positivo.

## 7. O mapa de exhibits (corpo: 3 figuras + 6 tabelas)

| Exhibit | Script | Conteúdo |
|---|---|---|
| **Fig. 1** `fig01_csection_trend` | 01 | Taxa de cesárea por setor ao longo do tempo |
| **Fig. 2** `fig_two_margins` | 11 | (a) binscatter da margem de preço; (b) margem de agenda — o único exhibit com os dois canais lado a lado |
| **Fig. 3** `fig_calendar_fingerprints` | 11 (+12) | (a) DOW × setor, (b) hora do nascimento, (c) gradiente por grupo de Robson |
| **Tab. 1** `tab_fees` | 02 | Honorários: Painel A níveis (Eq. 1) + Painel B primeira diferença estado-ano |
| **Tab. 2** `tab_main_gradient` | 07 | **Eq. (3)**: Painel A differential; Painel B gradiente próprio de cada setor |
| **Tab. 3** `tab_prelabor_lowrisk` | 03 | Dip de fds por pré-parto/intraparto × Robson 1–2 / Robson 1 |
| **Tab. 4** `tab_long_weekends` | 08 | Taxonomia de feriado (A) + somas de deslocamento (B) |
| **Tab. 5** `tab09_health` | 05 | Early-term / baixo peso / Apgar baixo |
| **Tab. 6** `tab11_decomposition` | 03 | Kitagawa + cesáreas de dia útil em excesso |

Suplemento em três apêndices: **C** descritivo · **D** robustez, validação e inferência · **E** o registro de política (Parto Adequado + linha do tempo da RN 368).

**Se mover um exhibit, re-derivar o mapa de `paper.aux`** (`grep -o "newlabel{tab:[^}]*}{{[^}]*}" paper.aux`) — nunca renumerar à mão.

## 8. Os limites honestos (o teto de identificação)

- Sem IDs de operadora/hospital/médico no TISS; preços pagos ~5% populados; sem painel de adesão/prêmio.
- TISS é mensal; o grão diário vem do SINASC.
- **Sem choque de política com timing diferencial limpo:** o Parto Adequado falha tendências paralelas, os choques de honorário são nulos.
- A contagem de obstetras do CNES-PF não mede a equipe de plantão.
- Os nulos de feriado prolongado significam que a evidência identifica agendamento pelo lado da oferta, **mas não a conveniência de quem**.
- **Não** construir novos programas empíricos sobre mortalidade materna / UTI neonatal / morbidade neonatal ampla — a seleção domina (o for-profit mostra baixo peso e Apgar baixo *menores*) e o poder é inadequado.

## 9. O que falta até março/2027

🔴 **Bloqueadores de submissão**

| # | Item | Dono |
|---|---|---|
| **E1** | Robustez de temperatura (ERA5-Land → bins → Eq. 3 + ForProfit×bin) — maior lead time | Vinicius + Claude |
| **R1** | Reprodução end-to-end local (resolver `dataset/` vs. `build/`) | Claude |
| **T1** | Rodada formal de revisão interna dos quatro | Coautores |
| **D1** | Confirmar papéis CRediT (TODO em `paper.tex:1140`) | **Fredie** |
| **D2** | Verificar magnitudes de Tita et al. (2009) no back-of-envelope de custo | **Fredie** |
| **D3** | ✅ Verificação das 50 citações feita em 20/08/2026. Pendente: aplicar correções no `.bib` e decidir sobre `melo2023` e `curriemacleod2016` | **Fredie** |
| **D4** | Entradas da ferramenta de declarações da Elsevier | **Fredie** |
| **D5** | Pacote de replicação depositado | Vinicius + Claude |

**Roteiro de leitura da revisão interna (T1, dez/2026–jan/2027):**

- **Pablo** — seções 4–5 (estratégia empírica e resultados de honorário). Alvo: a lógica de identificação e se a taxonomia de evidência se sustenta.
- **Lucas** — seções 6–7 (agenda e custo) + suplemento. Alvo: se os nulos estão reportados honestamente e se os números batem entre corpo e suplemento.
- **Fredie** — leitura integral, mais o editorial (CRediT, declarações, cover letter, submissão).

**O risco que o parecer interno de 20/08/2026 levantou e que não está no roadmap (R-A):** a tabela de equivalência (`tab_ref_c5_feegap_ci.tex`) reporta quatro especificações e em **nenhuma** o IC cabe na região de equivalência [−0,02; 0,02]. Ainda assim a nota conclui *"there is no robust relationship"* e o abstract diz *"the financial explanation does not fit"*. A tabela sustenta que **o sinal é instável e o dado não é informativo o bastante para estabelecer equivalência** — não a mesma coisa. Ver `PARECER_INTERNO_2026-08-20.md` §3.

---

# Checklist de 20 minutos

1. Instale o **Claude Desktop** e ative o **Cowork**.
2. Crie a pasta `parto_cesareo/` na sua máquina.
3. Copie para dentro dela: `CONTEXTO_PESQUISA.md`, `ROADMAP.md`, `PARECER_INTERNO_2026-08-20.md`, `scripts_github/` e `Literature/`. (`dataset/` só se for rodar o pipeline.)
4. Instale as skills — arraste o `.zip` no Cowork, ou copie as duas pastas para o diretório de skills.
5. Conecte a pasta `parto_cesareo/` no Cowork.
6. Abra uma conversa nova e teste o disparo: **"qual o status do paper?"** — a skill `paper-born-on-schedule` deve carregar sozinha, ler o `ROADMAP.md` e responder com o marco do mês, os bloqueadores abertos e o que está atrasado.
7. Segundo teste: **"o dip de fim de semana no for-profit é de quanto mesmo?"** — deve responder −8,3pp direto da tabela de números-âncora.
8. Terceiro teste, para a outra skill: **"que desenho eu usaria para identificar efeito de honorário sobre cesárea?"** — a `birth-health-econ` deve carregar e abrir `references/identification-designs.md`.

Se algum dos três não disparar, o problema está na `description` — não no corpo da skill.

---

*Documento gerado em 20/08/2026 a partir de `CONTEXTO_PESQUISA.md`, `ROADMAP.md`, `PARECER_INTERNO_2026-08-20.md`, `scripts_github/CLAUDE.md`, `scripts_github/README.md`, `Literature/README.md` e do código-fonte das duas skills.*
