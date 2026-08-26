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
