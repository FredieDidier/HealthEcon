# Roadmap — *Born on Schedule* até a submissão no JHE

**Meta:** submeter ao Journal of Health Economics em **março/2027**.
**Ordem de prioridade:** a do parecer interno de 20/08/2026, Seção 5
(`PARECER_INTERNO_2026-08-20.md`). O que mudou em relação à versão anterior deste
arquivo: **calibragem de alegação subiu; robustez de temperatura desceu.**
*Atualizado em 05/09/2026. Contexto completo em `CONTEXTO_PESQUISA.md`.*

---

## Parte 0 — O que foi feito em 05/09/2026 (itens 1–5, 7, 10 e O4 do parecer)

| # | Item | Status |
|---|---|---|
| 1 | **R-B — citar de Elejalde & Giolito (2021, JHE 75:102411)** | ✅ `elejalde2021` no `.bib`; parágrafo no bloco de agência da introdução; posicionamento no bloco de contribuição; parágrafo na Seção 6D; parágrafo na conclusão; subseção D nova no suplemento |
| 2 | **R-C — corrigir a referência da OMS** | ✅ As três ocorrências (abstract, introdução, background). O texto agora diz que a OMS **não fixa taxa-alvo**, que os ganhos de sobrevivência param de aparecer acima de ~10% populacional, que a comparação institucional deve passar pela classificação de Robson (que o paper já usa), e que a faixa 10–15% é da declaração de 1985 |
| 3 | **R-A — recalibrar a alegação de preço** | ✅ Ver Parte I abaixo. A alegação passou de "não há relação" para "os dados não estabelecem equivalência, o sinal é instável, e a magnitude canônica da literatura é pequena demais para importar nesta escala" |
| 4 | **4.1/4.2 — as 50 mil cesáreas** | ✅ Código e texto alinhados na versão **por município** (a que o texto sempre descreveu): **39.135/ano**, **10,0% das cesáreas de dia útil**. Nota de rodapé nova reconcilia com o coeficiente-manchete (2,3pp × 482 mil = ~11 mil/ano) |
| 5 | **D3 — correções do `.bib`** | ✅ `johnson2016` (título), `melo2024` (33(9):2013–2058), `parfitt2026` (pp. 103725 + DOI), `melo2023` **incluído** e citado na Seção 2. `spinola2025` renomeado **`spinola2026`** e completo com o volume publicado (EJHE 27:1117–1148, 2026), passado pelo Fredie no mesmo dia |
| 7 | **Demand smoothing** | ✅ `analysis/code/13_demand_smoothing.R`. Resultado: **não sustenta o canal**. Ver Parte II |
| 10 | **D5 — pacote de replicação** | ✅ Montado. `README.md` ganhou seção de compilação (o ciclo `xr` nos dois sentidos) e um **checklist de depósito**. O depósito em si (Zenodo/openICPSR) é passo do Fredie |
| O4 | **Revisão de inglês / vícios de linguagem** | ✅ Ver Parte III |
| 11 | ~~E1 — robustez de temperatura~~ | ❌ **Retirado do escopo** por decisão do Fredie (05/09/2026). Ver Parte VI |

**Não feito de propósito:** item 6 (R1, reprodução end-to-end) — os blocos tocados
foram re-rodados individualmente e conferem, mas a passagem completa do pipeline
continua pendente e é pré-requisito do checklist de depósito.

---

## Parte I — A alegação de preço, como ficou

O problema apontado pelo parecer: `tab_ref_c5_feegap_ci` dizia "not within" quatro
vezes e a nota concluía *"there is no robust relationship"*. Não sustentava.

**O que a tabela diz agora.** Ela ganhou uma quinta coluna, a magnitude canônica de
Gruber, Kim e Mayzlin (1999): ~1 p.p. por US\$1.000 de diferencial, que convertida
aos nossos níveis de honorário (cesárea média R\$1.941) dá **0,72 p.p. por ponto
log** do fee gap. O resultado é honesto e mais interessante do que se esperava:

| Especificação | Coef. | IC 95% | Cabe em [−0,02; 0,02]? | Exclui GKM? |
|---|---|---|---|---|
| State FE | +0,0469 | [−0,0020; +0,0958] | não | **não** |
| Municipality FE | −0,0163 | [−0,0340; +0,0015] | não | **sim** |
| State FE + controles | +0,0166 | [−0,0306; +0,0638] | não | **não** |
| Municipality FE + controles | −0,0143 | [−0,0321; +0,0036] | não | **sim** |

Ou seja: **as especificações dentro de município excluem a magnitude canônica; as
estaduais, com 27 clusters, não.** Nenhuma estabelece equivalência.

**O argumento que carrega a seção agora não é a regressão.** É aritmética: aplicada
ao gap negativo de 0,10 a 0,35 ponto log dos estados grandes, a resposta canônica
prevê movimento de **cerca de um quarto de ponto percentual**, contra um gap
for-profit–público de 35 pontos e uma taxa for-profit perto de 80%. Um canal de
preço do tamanho documentado na literatura não sustenta uma epidemia desta escala
mesmo que esteja operando. O fato bruto — a cesárea paga menos onde a taxa é mais
alta — não depende de regressão nenhuma, e o texto o coloca na frente.

O erro concreto que o parecer pegou (o texto chamava a linha State FE de "small",
sendo 4,7 p.p. por ponto log) foi corrigido: a Seção 5 agora reporta os dois
esquemas separadamente e diz que a precisão difere tanto quanto o sinal.

---

## Parte II — Demand smoothing: o que foi testado e o que deu

`13_demand_smoothing.R`, painel estabelecimento×semana de nascimentos for-profit,
2015–2024, 672 estabelecimentos, 281.748 células. **Dois testes, ambos
pré-especificados antes da estimação.**

**(A) Antecipação (*pull-forward*).** Se o estabelecimento tira partos de uma
semana que espera cheia, a participação de cesáreas pré-parto na semana *w* sobe
com a demanda esperada em *w+1*. Demanda esperada = média leave-one-out dos
próprios nascimentos naquela semana do ano nos **outros** anos, com cada semana
normalizada pela média semanal do estabelecimento *no próprio ano*.
⚠️ **A normalização não é detalhe.** Sem ela, a média leave-one-out fica
mecanicamente **negativa** em relação ao valor que omite sempre que o
estabelecimento cresce (nos primeiros anos ele está abaixo e nos últimos acima da
média dos outros anos). A primeira versão do script tinha esse bug e a validação
do forecast saía −0,44.

**Resultado: nulo**, coeficiente pequeno e negativo em todas as colunas
(−0,21 p.p., EP 0,29). **E o nulo vale pouco, e a tabela diz isso**: fora da
amostra o forecast recupera só **0,065 ponto log** de demanda relativa realizada
por ponto log, e o desenho só rejeitaria respostas acima de **0,80 p.p. por ponto
log**. O volume semanal de uma maternidade individual é quase imprevisível a
partir da própria sazonalidade. *Aplicamos aqui a mesma disciplina de R-A: não
lemos um nulo fraco como rejeição.*

**(B) Nivelamento de fluxo.** É o primitivo do modelo deles — agendar **nivela** o
fluxo. Então um estabelecimento-ano que agenda mais deveria ter fluxo semanal mais
liso. Desfecho = log da razão variância/média das contagens semanais (zero sob
Poisson puro). **Bem potente, e o sinal é o contrário**: dentro do estabelecimento,
maior participação de cesárea pré-parto anda com razão variância/média **maior**
(+0,27 log, p=0,065).

**Leitura para o paper.** O mecanismo que opera sem gap de preço no Chile não é o
que se vê no Brasil. O nosso é **semanal e específico à propriedade**, não sazonal
e de nivelamento de capacidade. Isso *fortalece* o posicionamento: confirmamos a
manchete de de Elejalde–Giolito (o incentivo sobrevive à ausência de preço) e
localizamos a margem em outro lugar. Vira **família F** na tabela de testes
múltiplos (agora seis famílias, A–F) e uma subseção nova no Apêndice D.

---

## Parte III — O que foi mexido na prosa (O4)

Aplicando a lógica do `MONASTERIO.md` do repositório irmão WorldCupHealth, e
continuando a passada de 04/09/2026.

- **Voz meta removida** (o texto comentando o texto): "Panel B gives the context",
  "Panel B shows why:", "The raw gradients supply the context",
  "Figure 2 previews the two designs", "and two facts emerge".
- **Períodos longos quebrados**, que era a observação específica do parecer sobre a
  introdução: a frase de dados de **97 palavras** virou três; a das quatro defesas
  do desenho, de **96 palavras**, virou quatro; a de capacidade organizacional, de
  **79 palavras**, virou quatro; a primeira frase da conclusão, de **72 palavras**,
  virou duas.
- **Alegações calibradas** onde o adjetivo não se sustentava: "tiny" saiu (o
  coeficiente State FE é 4,7 p.p. por ponto log), "no robust positive association"
  virou a formulação de duas partes descrita na Parte I, nos quatro lugares em que
  aparecia (abstract, introdução, Seção 5, conclusão) e no `highlights.txt`.
- **Abstract:** 246 palavras (limite JHE 250).

---

## Parte IV — O que falta

### 🔴 Bloqueadores de submissão

| # | Item | Trilha | Esforço |
|---|---|---|---|
| **R1** | Reprodução end-to-end com o dataset local (`config/00_master_analysis.R` inteiro, na ordem, com `13` antes de `10`) | Claude | Baixo |
| **T1** | Rodada formal de revisão interna dos quatro coautores. **Acrescentar ao roteiro de leitura os itens 1–4 do parecer**, que mudaram o *conteúdo* das alegações | Coautores | Médio |
| **D1** | Confirmar os papéis CRediT (hoje um rascunho marcado TODO em `paper.tex`) | Fredie | Baixo |
| **D2** | Verificar as magnitudes de Tita et al. (2009) citadas no back-of-envelope de custo | Fredie | Baixo |
| **D4** | Entradas da ferramenta de declarações da Elsevier (conflito de interesse em Word) | Fredie | Baixo |
| **D5b** | **Depositar** o pacote (Zenodo ou openICPSR) e trocar o placeholder do Data availability por DOI. O pacote está montado; falta o depósito e o checklist do `README.md` | Vinicius + Fredie | Baixo |

### 🟡 Desejáveis, não bloqueantes

| # | Item | Nota |
|---|---|---|
| O3 | Sugestão de referees | **Subiu de importância depois de R-B.** Com de Elejalde citado e bem posicionado, ele vira nome *sugerível* em vez de risco. Montar a lista pensando em quem é aliado natural da tese de agendabilidade |
| O1 | Cover letter para o JHE | Escrever em janeiro |
| O2 | Preprint SSRN gratuito na submissão | Decisão do Fredie |
| O5 | Checagem de acessibilidade das figuras (daltonismo) | `PAL` já é razoável; vale confirmar |

---

## Parte V — Cronograma revisado

O calendário antigo era organizado em torno da aquisição de temperatura, que abria
o cronograma por ter o maior lead time. Sem ela, **a agenda de texto sai de setembro
em vez de novembro e sobra folga de dois meses.**

| Mês | Marco | Entregável verificável |
|---|---|---|
| **Set/2026** | Reprodução e congelamento | `00_master_analysis.R` roda end-to-end; todos os números do corpo reconferidos; paper e suplemento compilam com zero referência indefinida |
| **Out/2026** | Manuscrito circulado | Versão congelada enviada aos quatro coautores, com prazo e roteiro de leitura por seção |
| **Nov–Dez/2026** | Comentários consolidados | Comentários dos quatro recebidos e consolidados em lista única e priorizada |
| **Jan/2027** | Revisões incorporadas | Comentários endereçados um a um; CRediT confirmado; declarações prontas; Tita conferido; cover letter escrita; lista de referees fechada |
| **Fev/2027** | Pacote depositado | DOI do repositório no Data availability; checklist do `README.md` todo marcado |
| **Mar/2027** | **Submissão** | Submissão no editorial manager do JHE |

**Folga.** Cerca de dois meses. Se sobrar tempo em novembro ou dezembro, o candidato
óbvio é E1 (Parte VI). Se não sobrar, submete-se em março de qualquer jeito — que é
a recomendação do parecer e continua valendo.

---

## Parte VI — E1 (temperatura): fora do escopo, e por quê

Retirado em 05/09/2026 a pedido do Fredie, e o parecer interno já argumentava pelo
rebaixamento. As razões, para o caso de um parecerista puxar o assunto:

- **Os EF município×data da Eq. (3) já absorvem toda a temperatura comum aos dois
  setores naquele dia local.** O paper diz isso textualmente.
- A ameaça residual exige que for-profit e público respondam **diferentemente** ao
  calor, de modo correlacionado com o calendário. É hipótese estreita, e ninguém a
  articulou.
- Custo alto e lead time longo (fila do CDS, 15 anos × 5.570 municípios), num item
  que é cinto-e-suspensório e não conserto.

**Se voltar à mesa** (sobra de tempo, ou pedido de parecerista): ERA5-Land via
Copernicus CDS, 0,1°, temperatura horária a 2m, agregada a média e máxima diárias
por município ponderando pela malha do IBGE; bins ao estilo Deschênes–Greenstone;
três especificações lado a lado no Apêndice D — Eq. (3) + ForProfit×bin,
+ ForProfit×precipitação, e Eq. (3) descartando dias acima do percentil 95 local.
Novo script `14_temperature.R`, rodando depois de `07` e reusando
`sinasc_daily_muni.parquet`. Resultado esperado: γ₁ essencialmente inalterado.

---

## Parte VII — Divisão de tarefas

### Fredie (correspondente, dono do editorial)

- Confirmar os papéis CRediT dos quatro autores → remove o TODO de `paper.tex` *(set)*
- Verificar as magnitudes de Tita et al. (2009) no back-of-envelope de custo *(set)*
- Ler a nova Seção 5 e a Parte I acima, e assinar a formulação da alegação de preço *(set)*
- Preparar as entradas da ferramenta de declarações da Elsevier *(jan)*
- Decidir sobre o preprint SSRN *(fev)*
- Cover letter e submissão *(mar)*

### Vinicius (dono do empírico)

- Ler `13_demand_smoothing.R` e julgar se o nulo (A) e o sinal invertido (B) estão
  reportados como devem *(set)*
- Coordenar a rodada de revisão interna, prazos e consolidação *(out–dez)*
- Preparar e executar o depósito do pacote de replicação *(fev)*
- Decidir se um resultado inesperado vira achado ou nota de rodapé *(conforme surgir)*

### Pablo e Lucas

- Leitura crítica da versão congelada, com foco atribuído para não sobrepor *(out–dez)*
  - **Pablo:** seções 4–5 (estratégia e honorários) — alvo: a lógica de identificação,
    e se a nova formulação da alegação de preço se sustenta
  - **Lucas:** seções 6–7 (agenda e custo) + suplemento — alvo: se os nulos estão
    reportados honestamente e se os números batem entre corpo e suplemento
- Sugerir nomes de referees *(dez)*

### Todos os quatro

- Aprovar a versão final antes da submissão *(mar)*

---

## Parte VIII — Regras que não se renegociam

Valem para qualquer pessoa (ou agente) que edite o paper. Detalhamento em
`CONTEXTO_PESQUISA.md`, seções 4 e 10.

1. **Eq. (3) é um *differential*, nunca um difference-in-differences.**
2. **"for-profit" (SINASC) ≠ "private-insurance sector" (TISS).** Nunca "private" puro.
3. **Os nulos ficam.** Feriados prolongados, capacidade organizacional e agora
   demand smoothing vieram fracos ou invertidos — reportar honestamente é o que
   delimita a alegação. Não enterrar, não reformular como positivo.
4. **Um nulo fraco não é uma rejeição.** Vale para o canal de preço e para o teste
   de antecipação: se o IC não exclui a magnitude relevante, o texto diz isso.
5. **Robson e idade gestacional são corroboração, não placebo.** Pré-termo não é
   não agendável.
6. **Nunca reintroduzir `else → Public`** na classificação de `nat_jur`.
7. **Nunca passar de 6,5in** numa figura de `\textwidth` — adicionar uma linha, não
   uma coluna.
8. **Compilar nos dois sentidos**, sem limpar os `.aux` no meio.
9. **Não rodar dois scripts de 42M linhas em paralelo.**
10. **Não commitar dados.**
11. **Se mover um exhibit, re-derivar o mapa de `paper.aux`** — nunca renumerar à mão.
