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
