# Parecer interno — *Born on Schedule*

**Data:** 20/08/2026 · **Base:** `latex/paper.tex` (versão de 10/08/2026), suplemento, `analysis/code/`, `dataset/`
**Ótica:** parecerista de JHE / AEJ:Policy. Onde afirmo um número, ele foi recalculado no dataset local.

---

## 1. Veredito

O paper está **acima da barra de desk-reject do JHE** e o desenho central resiste às
objeções padrão do campo. A contribuição está corretamente identificada: o diagnóstico
*conjunto* preço-versus-tempo no mesmo cenário, viabilizado por uma base (TISS) que
observa honorário efetivamente faturado — algo que a literatura internacional
raramente tem. O parágrafo de portabilidade na conclusão (o que é extremo no Brasil,
o que viaja) é exatamente o que um editor precisa ler para não classificar o trabalho
como estudo de país.

**Probabilidade realista:** R&R no JHE é plausível, não provável — o campo rejeita a
maioria sem revisão. O cenário modal é rejeição no JHE e aceitação em *Health
Economics* ou *EJHE* com revisões moderadas. **O que separa os dois cenários não é
mais robustez: são as três correções da Seção 3 abaixo.**

---

## 2. O que está sólido (não mexer)

| Item | Por quê passa |
|---|---|
| **Eq. (3)** com EF município×data | É a resposta canônica às objeções O2 e O5 do campo. Contraste dentro da unidade mais fina disponível; absorve clima, epidemia, feriado local e choque de demanda. Sem experimento, não há argumento mais forte |
| **Camadas de controle estáveis** (−2,3 → −2,2 → −1,9) | Formato exato que o campo cobra: as três colunas lado a lado, não só a final. E vocês rotulam Robson como padronização descritiva, não como ajuste preferido — correto, porque Robson é parcialmente pós-tratamento |
| **Split pré-parto × intraparto** (−9,7 vs. +1,7) | A evidência de mecanismo mais persuasiva disponível no campo. E o sinal invertido no intraparto é uma assinatura de deslocamento, não um resíduo |
| **Nulos reportados** (feriados prolongados, capacidade) | Delimitam a alegação de "conveniência de quem" e compram credibilidade. Pareceristas experientes desconfiam de papers em que tudo dá certo. Manter |
| **Robson e termo/pré-termo rotulados como corroboração, não placebo** | Vocês anteciparam a objeção O9 (controle pós-tratamento) antes que ela fosse feita. Isso desarma o parecerista |
| **SUTVA discutida explicitamente** | Raro e valorizado. A frase "a cesárea evitada no domingo é em parte a cesárea feita na sexta" é o tipo de honestidade que muda a leitura do referee |
| **Magnitudes** | −2,3pp num nível de 79% (≈3% da média) e dip bruto de 8,3pp (≈10% da média) estão na faixa da literatura de conveniência (1–2pp, ~10% da média). Nenhum coeficiente implausivelmente grande — sinal de que não há contaminação por composição |

Reprodução: os números-âncora fecham no dataset local. For-profit 7.127.004/8.968.808
= **79,46%**; público 7.281.504/17.036.207 = **42,74%**. Confere com
`CONTEXTO_PESQUISA.md`.

---

## 3. Os três riscos reais, em ordem de custo esperado

### 🔴 R-A. A alegação de preço é mais forte do que a tabela de equivalência sustenta

Esse é **o maior risco do paper**, e não está no ROADMAP.

`tab_ref_c5_feegap_ci.tex` reporta quatro especificações. Em **nenhuma** o IC cabe na
região de equivalência $[-0,02;\,0,02]$ — a coluna diz "not within" quatro vezes. Ainda
assim a nota da tabela conclui *"there is no robust relationship between the relative
fee and the cesarean rate"*, e o abstract diz *"the financial explanation does not fit"*.

A tabela não sustenta essa inferência. O que ela sustenta é: **o sinal é instável e o
dado não é informativo o bastante para estabelecer equivalência.** São coisas
diferentes, e a distinção é exatamente o objeto da objeção O4 do campo aplicada a um
nulo.

Dois agravantes concretos:

1. **A linha "State FE" é +0,0469, IC [−0,0020; +0,0958].** Marginalmente positiva e
   grande. O texto (linha ~680) descreve as especificações sem controles como
   *"small but again switches sign"* — 4,7pp por ponto log não é "small". Um
   parecerista que abra o suplemento vai encontrar essa linha.
2. **O IC não descarta a magnitude de Gruber-Kim-Mayzlin.** Referência do campo:
   ~1 p.p. por US$1.000 de diferencial. Um ponto log do gap, com honorários da ordem
   de R$1.800–2.300, equivale a algo perto de US$600 → previsão GKM ≈ 0,6pp. A
   meia-largura dos ICs é de 2 a 5pp. **Vocês não conseguem rejeitar o efeito
   canônico da literatura que estão dizendo não se aplicar.**

**Correção (barata, e melhora o paper):** reescrever a alegação como *"the observed
billed fee variation is not informative enough to support the price channel, and the
sign is unstable across specifications"*, e calibrar explicitamente a região de
equivalência contra a magnitude de GKM convertida para reais, dizendo o que o IC
descarta e o que não descarta. Isso é uma virada de meia página. Feita, ela transforma
a objeção mais provável do referee numa demonstração de rigor. Não feita, ela é o
primeiro parágrafo do parecer negativo.

> Observação de posicionamento: o *fato bruto* — a cesárea paga menos nos estados
> grandes e mesmo assim eles rodam 80% — é forte e não depende de nenhuma regressão.
> Ele carrega a seção sozinho. A regressão é o elo fraco; deixe o fato na frente.

### 🔴 R-B. de Elejalde & Giolito (2021, *JHE* 75:102411) não é citado em lugar nenhum

Verificado: zero ocorrências em `refs.bib`, `paper.tex`, `sup_appendix.tex`,
`appendix.tex`, `model.tex`. O texto está baixado em `Literature/` — foi lido e não
entrou.

Por que isso é sério, em três camadas:

1. **É um paper do periódico-alvo.** Submeter ao JHE sem citar o artigo do JHE mais
   próximo da sua pergunta é um risco editorial concreto, inclusive porque a chance de
   o autor ser sorteado como parecerista não é pequena.
2. **É a contra-hipótese direta da alegação central.** No Chile, o preço da cesárea e
   do parto vaginal era **o mesmo**, e a cesárea subiu +4,6pp mesmo assim. A conclusão
   deles: *ausência de diferencial de preço não implica ausência de incentivo de
   oferta* — porque a cesárea é agendável, e agendar permite **suavizar demanda** e
   aumentar volume total. Isto é, o mecanismo alternativo ao de vocês, publicado, no
   mesmo periódico, com o mesmo achado de partida.
3. **E ao mesmo tempo é o maior aliado do paper.** O paper de vocês é a confirmação
   independente e em escala nacional da tese deles: o incentivo sobrevive à ausência
   de preço, via agendabilidade. Citado corretamente, ele deixa de ser ameaça e vira
   ancoragem — "our setting provides the sharper version of the de Elejalde–Giolito
   mechanism: the fee gap is not merely zero, it is negative."

**Correção:** um parágrafo na Seção 1 (bloco de agência/SID) e uma frase na conclusão.
Custo: uma hora. **Prioridade máxima do projeto — acima de E1.**

**Extensão implicada, de alto retorno.** A previsão testável de de Elejalde & Giolito
é *demand smoothing*: prestadores reagendam antecipando semanas de alta demanda. Vocês
têm SINASC diário por estabelecimento (`sinasc_daily_estab.parquet`, 1,5M células) —
é dos poucos datasets no mundo onde isso se testa. Se der positivo, é uma quinta
"calendar fingerprint" e sobe o teto do paper. Se der nulo, entra ao lado dos outros
nulos. **Avaliar como substituto de E1, não como adição.**

### 🟠 R-C. O erro da OMS 10–15%

Aparece três vezes: abstract (`paper.tex:72`), introdução (`:109`) e background
(`:394`). E na introdução vem atribuído a `who2015cesarean` — que diz o oposto.

A declaração vigente (WHO/RHR/15.02, 2015) afirma que (a) **não se deve perseguir
taxa-alvo alguma**; (b) acima de ~10% em nível **populacional** não há evidência de
ganho adicional em mortalidade materna e neonatal; (c) a **classificação de Robson**
é o padrão proposto para comparar instituições. O intervalo 10–15% é da declaração de
**1985**.

Um parecerista com formação médica — e o JHE usa esse perfil — pega isso na primeira
leitura, e o custo é desproporcional: sinaliza que os autores não leram a fonte que
citam. Pior, é gratuito: vocês já usam Robson como espinha dorsal da análise, ou seja,
já fazem exatamente o que a declaração de 2015 recomenda. Basta dizer isso.

**Correção sugerida (abstract):** trocar *"far above the World Health Organization's
10–15% reference range"* por algo como *"far above the roughly 10% population-level
threshold above which the WHO finds no further gains in maternal and newborn survival,
and which the WHO's current guidance frames through the Robson classification rather
than a target rate."* Ajustar as três ocorrências. Custo: vinte minutos. Ganho:
elimina o único erro factual do manuscrito.

---

## 4. Achados de verificação numérica

### 4.1 As ~50 mil cesáreas de dia útil — texto e código não batem

O corpo (`paper.tex:227` e `:1051`) diz: *"Benchmarking **each municipality's** weekday
cesarean propensity against **its own** weekend rate places about 50,000 for-profit
weekday cesareans per year above that mechanical benchmark, roughly one in ten."*

O código (`03_mechanisms.R:396–406`) faz outra coisa: o benchmark é a taxa de fim de
semana **nacional por setor-ano**, não por município.

Recalculado no dataset:

| Benchmark | Excesso/ano | Como fração |
|---|---|---|
| **Setor-ano nacional** (o que o código faz) | **50.073** | 10,5% de *todas* as cesáreas; **12,8%** das cesáreas de dia útil |
| **Município** (o que o texto diz) | **41.535** | 10,6% das cesáreas de dia útil |

Três consequências:

1. O número 50.073 está correto **para o que o código calcula**, mas a descrição no
   corpo está errada. Escolher uma das duas e alinhar.
2. O "roughly one in ten" é 10,5% de **todas** as cesáreas (dia útil + fim de semana),
   mas a frase o pendura em "50.000 **weekday** cesareans", o que lê como um em dez
   dos partos de dia útil — que é 12,8%. Denominador trocado na redação.
3. A versão por município é a mais defensável (absorve composição geográfica) e dá
   41,5 mil. Se migrarem para ela, a manchete cai ~17%.

> **Isso é uma checagem de trinta segundos que um parecerista faz** — é a coerência
> aritmética entre coeficiente e contagem (objeção O7 do campo). Nesse caso o paper
> passa no essencial, porque vocês rotulam explicitamente como *mechanical benchmark*
> e dizem que não é "cesáreas causadas". Mas a discrepância texto-código, se
> descoberta na fase de replicação do periódico, é cara.

### 4.2 Reconciliação com o coeficiente principal — vale explicitar

O benchmark de 50 mil usa o contrafactual "própria taxa de fim de semana" (dip bruto
de 8,3pp). O coeficiente-manchete usa outro contrafactual: o setor público no mesmo
dia (−2,3pp). Aplicado às ~482 mil cesáreas for-profit de dia útil por ano, o
diferencial de 2,3pp daria **~11 mil/ano**, não 50 mil.

Os dois números são legítimos porque respondem a perguntas diferentes. Mas o paper
apresenta os dois sem reconciliá-los, e um leitor atento vai perguntar por que a
manchete é a maior das duas. **Uma nota de rodapé de duas frases resolve** e converte
uma vulnerabilidade em demonstração de disciplina.

### 4.3 Sem problemas encontrados em

- Classificação de setor (`nat_jur` 1xxx/2xxx/3xxx) — o bug `else → Public` não
  reapareceu; taxas reproduzem exatamente.
- Objeção do denominador endógeno (O10): coberta por `fig08_daily_counts`, que mostra
  contagens de cesárea colapsando enquanto vaginais mal se movem. **Mas está só no
  suplemento** — o argumento de que o resultado vem do numerador merece uma frase no
  corpo, na Seção 6A.
- Cesárea prévia como covariável predeterminada: coberta via categorias de paridade
  na coluna 2 e via Robson 5. Adequado.
- Inferência: cluster duplo, wild bootstrap para poucos clusters, testes múltiplos com
  famílias declaradas ex ante. Nada a criticar.

---

## 5. Leitura do ROADMAP — reordenação proposta

O roadmap é bom e o cronograma é realista. Minha discordância é de **prioridade**, não
de conteúdo: ele coloca no topo o item de maior esforço e menor retorno esperado, e
não contém os três itens de maior retorno.

### O que discordo: E1 (temperatura) não é bloqueador de submissão

O próprio ROADMAP já argumenta contra E1 melhor do que eu argumentaria (Parte III,
"Por que o argumento já é forte"), e a recomendação da Parte IV — submeter em março de
qualquer jeito — está certa. Sendo assim, **E1 não é bloqueador; é robustez de resposta
a parecerista.** O EF município×data já absorve toda a temperatura comum aos dois
setores. A ameaça residual exige que for-profit e público respondam *diferentemente* ao
calor, de modo correlacionado com o calendário — hipótese estreita e não articulada por
ninguém.

Custo de mantê-lo no topo: ele consome ago–out (o trecho de maior lead time), e os três
itens da Seção 3 acima — que custam somados menos de uma semana e mexem no *conteúdo*
das alegações — ficam para depois.

**Proposta:** rebaixar E1 de 🔴 para 🟡, com gatilho explícito: *executar se o
demand-smoothing (R-B) sair nulo ou se sobrar tempo em novembro; caso contrário, guardar
para a resposta ao referee.* Manter a aquisição de dados começando cedo — o argumento de
lead time é válido —, mas sem que ela bloqueie a agenda de texto.

### Prioridade revisada

| Ordem | Item | Origem | Esforço | Por quê aqui |
|---|---|---|---|---|
| 1 | **R-B** — citar de Elejalde & Giolito | novo | 1h | Paper do periódico-alvo, contra-hipótese direta, risco editorial |
| 2 | **R-C** — corrigir OMS 10–15% (3 ocorrências) | novo | 20min | Único erro factual; custo desproporcional se pego |
| 3 | **R-A** — recalibrar a alegação de preço + região de equivalência vs. GKM | novo | 1 dia | Objeção mais provável do referee; transforma fraqueza em rigor |
| 4 | **4.1/4.2** — alinhar texto e código das 50 mil; nota de reconciliação | novo | 2h | Coerência aritmética; barato |
| 5 | **D3** — aplicar correções do `.bib` e decidir `melo2023` | ROADMAP | 1h | Já diagnosticado em `verificacao_citacoes.md`, falta executar. `melo2023` avalia a própria política que a Seção 2 descreve sem citar ninguém |
| 6 | **R1** — reprodução end-to-end (`DROPBOX_ROOT`) | ROADMAP | baixo | Pré-requisito de D5 e de qualquer re-estimação |
| 7 | **Demand smoothing** (extensão de R-B) | novo | médio-alto | Único item que pode *subir o teto* do paper. Dados já existem |
| 8 | **T1** — revisão interna dos coautores | ROADMAP | médio | Manter dez–jan. Adicionar os itens 1–4 ao roteiro de leitura |
| 9 | **D1, D2, D4** — CRediT, Tita, declarações | ROADMAP | baixo | Fredie, conforme cronograma |
| 10 | **D5** — pacote de replicação | ROADMAP | médio | Fev, como planejado |
| 11 | ~~E1~~ **temperatura** | ROADMAP (era #1) | alto | Rebaixado. Gatilho na Seção 5 acima |

### Sobre os desejáveis (O1–O5)

Concordo com todos. Duas notas:

- **O3 (sugestão de referees)** sobe de importância depois de R-B. Com de Elejalde
  citado e bem posicionado, ele passa a ser um nome *sugerível* em vez de um risco.
  Vale montar a lista pensando assim: quem é aliado natural da tese de agendabilidade.
- **O4 (revisão de inglês)** — a prosa está boa, mas há períodos longos na introdução
  (o parágrafo de contribuição tem sentenças de 60+ palavras) que destoam do modelo
  declarado no cabeçalho do `.tex` (Johnson & Rehavi). Uma passada de encurtamento vale
  mais que revisão nativa.

### Sobre a escolha de periódico

JHE continua sendo o alvo certo — mecanismo, dados administrativos, tolerância a nulos
bem reportados. Duas observações:

- **AEJ:Policy é uma alternativa séria**, não um plano B. Card-Fenizia-Silver e
  Johnson-Rehavi saíram lá, e a seção de política organizacional da conclusão é o tipo
  de implicação que o AEJ:Policy quer. O custo de reformatar é baixo.
- O plano de queda (Health Economics → EJHE) está certo. Acrescentaria **JDE** à lista:
  se o enquadramento virar "organização de sistemas de saúde em país de renda média" em
  vez de "parto", o paper compete bem lá — e Parfitt & Goulart saiu no JDE, o que
  mostra que o editor tem apetite pelo contexto brasileiro.

---

## 6. Resumo executivo

**O empírico está pronto. O que falta não é robustez, é calibragem de alegação.**

Três correções de baixo custo (citação de de Elejalde, OMS, região de equivalência) e
duas de consistência (50 mil, `.bib`) valem mais para o destino do paper do que o item
que hoje ocupa o topo do roadmap. Somadas, custam menos de uma semana de trabalho.

A extensão de *demand smoothing* é a única coisa na mesa capaz de aumentar o teto do
paper, e os dados para fazê-la já estão na pasta.

**A recomendação de submeter em março independentemente da temperatura está correta e
deve ser mantida.**
