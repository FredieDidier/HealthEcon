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
