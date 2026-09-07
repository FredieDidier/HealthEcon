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
| ~~**D1**~~ | ~~Confirmar os papéis CRediT~~ | ✅ **Fechado em 07/09/2026.** A alocação impressa no `paper.tex` é a final; o comentário `% TODO` saiu. Não realocar | Fredie |
| **D5b** | **Depositar** o pacote (Zenodo ou openICPSR) e trocar o placeholder do Data availability por DOI. O pacote está montado e o checklist do `README.md` está fechado exceto pelos itens que dependem de R1 | Vinicius + Fredie | Baixo |

**Resolvidos em 06/09/2026:** D2 (Tita conferido contra o registro do Europe PMC —
NEJM 360(2):111–120; OR ajustada 2,1 a 37 semanas e 1,5 a 38, contra 39; o corpo não
cita magnitude nenhuma, só direção, e a direção está certa), D4 (`latex/submission/
declaration_of_interest.docx`, com as declarações-companheiras copiadas literalmente
do `paper.tex`), O5 (ver Parte IX) e três itens do checklist de depósito: `LICENSE`
(MIT), `config/config.R` com placeholder + `config_local.R` git-ignorado, e a
compilação nos dois sentidos verificada (37 e 27 páginas, zero referência e zero
citação indefinidas). **D1 fica como está** — os papéis CRediT do rascunho são os
definitivos, por decisão do Fredie (06/09/2026); o TODO no `paper.tex` pode sair na
véspera da submissão.

### 🟡 Desejáveis, não bloqueantes

| # | Item | Nota |
|---|---|---|
| ~~O3~~ | ~~Sugestão de referees~~ | **Retirado do escopo** por decisão do Fredie (06/09/2026): não sugeriremos pareceristas |
| O1 | Cover letter para o JHE | Escrever em janeiro |
| O2 | Preprint SSRN gratuito na submissão | Decisão do Fredie |
| ~~O5~~ | ~~Acessibilidade das figuras~~ | ✅ Feito em 06/09/2026. Ver Parte IX |

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


---

## Parte IX — O5: acessibilidade das figuras (06/09/2026)

**Daltonismo: passa.** Simulação dicromática de Viénot–Brettel–Mollon das cinco
cores do `PAL` (`analysis/code/00_utils.R`), com distância ΔE em CIE-Lab de todos
os pares que aparecem juntos em alguma figura:

| Par | Normal | Protanopia | Deuteranopia | Tritanopia |
|---|---|---|---|---|
| vermelho/azul (for-profit vs. público) | 93 | 68 | 91 | 91 |
| vermelho/laranja | 35 | 33 | 27 | 24 |
| azul/laranja | 105 | 95 | 114 | 79 |
| vermelho/cinza | 70 | 35 | 54 | 67 |
| azul/navy | 29 | 30 | 31 | 28 |

O pior caso é vermelho/laranja sob tritanopia, ΔE 24 — bem acima do limiar de ~10
em que duas séries começam a se confundir. **Nenhuma mudança de cor é necessária.**

**O que a checagem achou de fato: impressão em preto e branco.** Vermelho, azul e
cinza são quase isoluminantes (luminâncias relativas 0,143, 0,148 e 0,139; razão de
contraste 1,03). Em fotocópia, as séries for-profit e pública viram a mesma linha
cinza. As figuras que dependem só de cor são a Figura 1 (tendência), a Figura 3(a)
(dia da semana), a 3(b) (hora do parto) e os painéis de idade gestacional do
suplemento; a Figura 2(b) e a 3(c) já trazem `shape` redundante.

**Corrigido no mesmo dia**, a pedido do Fredie. `analysis/code/00_utils.R` ganhou
`LTY` e `lty_for()`, e as sete figuras que dependiam só de cor passaram a mapear
`linetype` para a mesma variável de `colour`, na mesma ordem, o que faz o ggplot
fundir os dois guides numa legenda única: Figura 1, Figura 3(a) e 3(b) no corpo;
`fig02_dow_cesarean`, `fig03_robson_dow`, `fig07_hour_of_birth`,
`fig08_daily_counts` e os dois painéis de idade gestacional no suplemento. A
Figura 2(b) e a 3(c) já traziam `shape` redundante e ficaram como estavam.

Os scripts 01, 03, 05 e 11 foram re-rodados em sequência (7min30 no total) e
**nenhuma tabela mudou um byte** — o que, de quebra, é a primeira verificação
parcial de R1: os números de 01, 03, 05 e 11 se reproduzem exatamente. Paper e
suplemento recompilados depois disso.

---

## Parte X — A agenda de CNES do Vinicius (07/09/2026)

Da call em que ele propôs descer ao nível do estabelecimento e da equipe médica.
Seis ideias, **três adotadas e três recusadas**. O memorando completo, com a razão
de cada uma, está em `parto_cesareo/AGENDA_CNES_VINICIUS_2026-09-07.md`; aqui fica
só o placar.

### Adotadas

| # | Ideia | Onde ficou | Resultado |
|---|---|---|---|
| **C1** | Intensidade de cesárea por CNES padronizada por Robson, e o que sobra depois de controlar mercado, case-mix e capacidade | `14_estab_practice_style.R` → **Tabela C.4** + um acréscimo curto ao parágrafo do Kitagawa no corpo | Padronizar remove **28,8%** do gap for-profit−público (34,0→24,2pp), reproduzindo o Kitagawa por outro caminho, e quase nada da dispersão **entre** hospitais. Sobram **6,6pp de DP** entre maternidades for-profit depois de município×ano, composição materna e capacidade (46% do bruto); duas for-profit no mesmo município-ano diferem **13,4pp** |
| **C2** | Carga horária | `09_org_capacity.R` → **Tabela D.9, coluna 5** | **Zero preciso** (−0,10pp, EP 0,17) enquanto a interação de escala fica em +1,21pp\*\*\*. Reforça a ressalva: a atenuação acompanha o tamanho do serviço, não o tempo obstétrico medido |
| **C3** | "100% SUS" como medida de **pagador** (e não de propriedade) | `01d_cnes_estab.R` passa a agregar leitos SUS; validação no corpo; **Tabela D.9, coluna 6** | Leitos obstétricos SUS: público 98,8%, for-profit 22,2% (**mediana 0**), nonprofit 72,0%. E o gradiente é **mais plano** onde a for-profit atende SUS: fim de semana **+2,12pp** (p=0,041), feriado **+3,37pp** (p=0,005). Primeira evidência do paper baseada em pagador |

### Recusadas

| # | Ideia | Por quê |
|---|---|---|
| **C4** | Separar "efeito do estabelecimento" de "efeito da equipe" | Limite de dado, não de especificação: as duas histórias fazem a **mesma** predição, e o desenho que separaria é *movers*, que exige ligar **médico a parto**. SINASC não tem identificador de profissional; TISS não tem nem de hospital. Rotatividade e multi-vínculo são calculáveis pelo CNES-PF mas herdam a falha de medida do zero-obstetra, que é pior em diferenças que em nível |
| **C5** | CBO nos dados de produção (TISS, SIH) | Verificado nos dois dicionários: `CBO` existe **só** em `Ambulatorial_DET`, nunca em `Hospitalar_DET`/`CONS`. Parto é evento hospitalar. SIH tem, mas é 100% SUS, o setor errado, e não está neste projeto. A versão bem-posta é **obstetra versus enfermeiro obstetra**, cujos classificadores já existem em `build/00_utils.R` |
| **C6** | Painel CNES-**mensal** e trajetórias de estabelecimento | O desenho do paper é **diário**; agregar a mês joga fora a variação que identifica. Responde pergunta de **nível**, não de agendamento — é paper 2. O que dele cabia aqui entrou como estabelecimento-**ano** |

**Nenhum número existente do paper mudou.** Os coeficientes do `09` reproduziram
exatamente (fim de semana × log leitos = +0,445pp sob EF muni×data). Build: paper
**37** páginas, suplemento **28** (era 27), zero referência e zero citação
indefinida nos dois, e os mesmos dois overfull pré-existentes documentados.

⚠️ **Renumeração:** a tabela nova é **C.4**, o que empurrou `tab12_cost` de C.4 para
**C.5**. O apêndice D não mudou.

**Paper 2, se quisermos.** O fato já está estabelecido pela Tabela C.4; falta o
mecanismo. O caminho seria (i) painel de vínculos CNES-PF com multi-vínculo medido
por município, que é diretamente o Π do modelo, (ii) composição obstetra versus
enfermeiro obstetra, (iii) trajetórias com painel balanceado, e (iv) *movers*, se
algum dia aparecer identificador de profissional ligado ao parto. Nada disso está no
caminho crítico de março/2027.

---

## Parte XI — Notas de tabela e figura: bloco centrado (07/09/2026)

Auditoria pedida pelo Fredie, aplicando a lógica do `MONASTERIO.md` do
WorldCupHealth ("padronizar o alinhamento das notas") a este manuscrito.

**O que a auditoria achou.** As notas **já estavam padronizadas**: as 31 tabelas
geradas carregavam todas o bloco canônico `\begin{minipage}{\linewidth}` e as 10
figuras dos dois documentos usavam todas `\fignotes`, que é o mesmo bloco. Nenhuma
exceção. O que o Fredie viu na Figura C.2 é uma nota de **uma linha só**: em largura
total ela encosta na margem esquerda debaixo de uma legenda centrada, e lê como
desalinhada, embora seja exatamente o que justificação em largura total faz numa
linha.

**O que foi tentado, e desfeito no mesmo dia.** A geometria chegou a mudar para
**bloco centrado a 0,9\textwidth** com o texto ainda justificado por dentro, aplicada
uniformemente em `00_utils.R`, nas 31 tabelas geradas e no `\fignotes` dos dois
documentos. **O Fredie mandou voltar**, e voltou: as notas estão de novo no bloco
justificado em largura total, que é a **forma do Monasterio** e a que a rodada dele
no WorldCup fixou. A migração de volta cobriu os mesmos três lugares e as 31 tabelas.

⚠️ **Não tentar de novo.** A motivação era real (nota de uma linha em largura total
encosta na margem esquerda debaixo de legenda centrada) e ainda assim a decisão é
manter a largura total. Se algum dia mudar, são três lugares que têm de bater:
`NOTE_OPEN`/`NOTE_CLOSE` em `analysis/code/00_utils.R`, `\fignotes` em `paper.tex` e
`\fignotes` em `supplement.tex`, mais a migração das tabelas já geradas.

**Build depois de voltar:** paper **37** páginas, suplemento **28**, zero referência e
zero citação indefinida nos dois, e os dois overfull pré-existentes de volta aos
valores documentados (hbox de 2,8pt no paper, vbox de 46pt no suplemento; com o bloco
estreito o vbox tinha ido a 58pt). Os PDFs voltaram ao mesmo tamanho em bytes de
antes da mudança.

**Travessões:** conferido em `paper.tex`, `sup_appendix.tex`, `model.tex`,
`appendix.tex` e nos 31 arquivos de tabela. Não há travessão usado como pontuação. As
únicas ocorrências de `--` são intervalos numéricos (2014--2024), compostos com
en-dash (for-profit--public, physician--patient, Sun--Abraham), os termos CRediT da
própria Elsevier ("Writing -- original draft") e o traço de ausência nas linhas de
efeito fixo. Todas corretas, manter.
