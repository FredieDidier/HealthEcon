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
