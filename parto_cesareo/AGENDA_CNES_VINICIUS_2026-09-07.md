# Análise a nível de CNES: o que adotamos, o que não adotamos, e por quê

**De:** Fredie · 07/09/2026
**Para:** Vinicius (cc Pablo, Lucas)
**Assunto:** as ideias da call sobre ir mais fundo no nível do estabelecimento e da equipe médica

Vinicius, tuas anotações da call renderam. Três das ideias foram implementadas hoje
e já estão no repositório; três não entram, e vale registrar o porquê de cada uma
para não voltarmos ao assunto sem informação nova. O critério foi simples: entra o
que reforça o argumento que já está no paper e cabe no cronograma de março/2027;
não entra o que exige um dado que não temos ou que responde a uma pergunta
diferente da do paper.

---

## 1. As tuas ideias, uma a uma

### 1.1 ✅ ADOTADA: intensidade de cesárea por CNES, padronizada por Robson

> *"CNES-mês (intensidade cesárea — total de partos cesáreos/total de partos —
> grupos Robson — efeito fixo município)"*

**Por que entrou.** É a melhor da lista e a mais barata. Padronizar por Robson no
nível do estabelecimento é literalmente o que a declaração vigente da OMS
(WHO/RHR/15.02) recomenda para comparar instituições, e o paper já usa esse
argumento na correção do erro do "10–15%". O dado estava todo no disco: o
`sinasc_births.parquet` tem `estab` para os três setores, 2010–2024, com
`tipo_robson` de 2014.

**O que foi feito.** Script novo `analysis/code/14_estab_practice_style.R`. Constrói
células estabelecimento-ano × Robson (cacheadas em
`sinasc_estab_year_robson.parquet`), calcula para cada maternidade uma taxa de
cesárea **padronizada por Robson**, isto é, as taxas do próprio hospital dentro de
cada grupo reponderadas para a distribuição Robson nacional do mesmo ano, e reporta a
dispersão entre maternidades.

**Resultado (nova Tabela C.4 do suplemento):**

| Setor | Maternidade-anos | Taxa observada (média / DP / P90−P10) | Padronizada (média / DP / P90−P10) |
|---|---|---|---|
| For-profit | 6.392 | 78,8 / 16,2 / 40,8 | 72,1 / 14,5 / 38,1 |
| Nonprofit | 9.548 | 59,9 / 18,0 / 47,6 | 58,0 / 14,4 / 36,5 |
| Público | 9.927 | 44,8 / 14,8 / 36,3 | 47,9 / 12,7 / 31,0 |

⭐ **Duas coisas boas saíram daqui.**

Primeiro, **a padronização valida o Kitagawa por outro caminho.** O gap
for-profit−público cai de 34,0pp para 24,2pp quando se padroniza, ou seja, o
case-mix Robson explica 28,8% do gap. O Kitagawa do corpo (Tabela 6) diz 28%. Dois
métodos diferentes, mesma resposta.

Segundo, e é o que responde tua pergunta de verdade: **a padronização quase não
mexe na dispersão ENTRE hospitais.** O DP entre maternidades for-profit vai de 16,2
para 14,5pp, e o P90−P10 de 40,8 para 38,1pp. Case-mix explica o gap entre setores;
não explica por que dois hospitais privados são diferentes um do outro.

### 1.2 ✅ ADOTADA: "o que explica hospitais diferentes controlando por características similares?"

> *"INTRA CNES — o que faz/explica hospitais diferentes terem níveis de parto
> cesáreo diferentes controlando por características similares?"*

**Como foi respondida.** Painel B da mesma tabela: decomposição de variância da taxa
**padronizada**, ponderada por nascimentos, com blocos aninhados. Todas as linhas
rodam na mesma amostra (23.048 maternidade-anos) para os números serem comparáveis.

| Bloco | R² (todos os setores) | DP residual | % do bruto | R² (só for-profit) | DP residual | % do bruto |
|---|---|---|---|---|---|---|
| Nenhum (dispersão bruta) | | 16,26pp | 100% | | 14,44pp | 100% |
| Setor | 0,296 | 13,64 | 84% | — | — | — |
| + Município × ano | 0,749 | 8,15 | 50% | 0,670 | 8,30 | 57% |
| + Composição materna | 0,867 | 5,93 | 36% | 0,784 | 6,71 | 46% |
| + Capacidade obstétrica | 0,870 | 5,87 | 36% | 0,793 | 6,57 | 46% |

⭐ **A resposta:** depois de segurar o case-mix Robson, o mercado local, a composição
materna predeterminada (idade, escolaridade, raça) e a capacidade obstétrica (leitos
e volume), **sobram 6,6pp de desvio-padrão entre maternidades for-profit, 46% da
dispersão bruta.** E, sem regressão nenhuma: duas maternidades for-profit que
atendem no **mesmo município e no mesmo ano** diferem em média **13,4pp** na taxa
padronizada.

Isso é o análogo do "72% practice style" no nível onde a decisão é de fato tomada.
Entrou também no corpo, num acréscimo curto ao parágrafo do Kitagawa.

⚠️ **Uma armadilha que evitei e que vale tu saber.** A primeira versão rodava a
decomposição sobre a taxa **observada** com as dez participações Robson como
regressores. Isso dá R² de 0,95 e resíduo de 4,6pp, ou seja, atribui muito mais ao
case-mix. É viés para cima: as participações de grupo são livres para *proxiar* a
prática dentro do grupo com que se correlacionam (uma maternidade que atende muitas
mulheres com cesárea prévia também secciona mais as de trabalho de parto
espontâneo). A padronização não tem esse problema porque preserva as taxas do
próprio hospital. O número 0,95 está reportado na nota da tabela, rotulado como
limite superior.

⚠️ **E o que isso NÃO é.** Não é decomposição causal. O resíduo é o que essas
covariáveis não explicam, e contém case-mix não medido e capacidade não medida
junto com diferença de prática. A nota da tabela diz isso explicitamente. Não
escrever "6,6pp é o efeito do hospital".

### 1.3 ✅ ADOTADA: carga horária

> *"Carga horária?"*

**Por que entrou.** Porque a variável já existia e nunca tinha entrado em regressão
nenhuma: `obst_hours_hosp` no `cnes_estab_year.parquet`, a soma das horas contratadas
dos vínculos de obstetra no estabelecimento (campo HORAHOSP do CNES-PF). É melhor
comportada que o headcount, porque um médico registrado para 4h e um para 40h
contam igual em `n_obstetricians`.

**Resultado:** coluna 5 nova da Tabela D.9. **Zero preciso.** Fim de semana × log
horas = **−0,10pp (EP 0,17)**; feriado +0,16pp (EP 0,20). Descritivas: mediana 34
horas/semana, 16,9% com zero.

**Como ler.** A interação de **escala** (log de partos) continua em +1,21pp\*\*\*
enquanto a de horas é nula. Ou seja, a atenuação que encontramos acompanha o
**tamanho do serviço**, não o tempo obstétrico medido. Isso *reforça* a ressalva que
já estava no paper: o que o exercício identifica é redundância organizacional, não o
calendário do médico individual.

### 1.4 ✅ ADOTADA, numa forma diferente da que tu pediu: "100% SUS" como medida de PAGADOR

> *"tipo de CNES — publico, privado, 100% sus, for-profit"*

**Por que entrou, e por que é importante.** Isso ataca a objeção mais previsível de
parecerista contra o desenho: `nat_jur` é **propriedade**, e o paper a lê como proxy
de **pagador**. Descobri que o arquivo de leitos do CNES já traz `n_beds_sus` e
`n_beds_not_sus`, que somam exatamente `n_existing_beds`. Nunca tinham sido usados.

**O que foi feito.** `build/01d_cnes_estab.R` passou a agregar os leitos SUS, e o
painel ganhou `beds_sus`, `beds_obstetric_sus`, `sus_share` e `sus_share_obstetric`.
Só o `build_estab_panel()` foi re-rodado; **nenhum download novo**, e o painel
continua com as mesmas 84.213 linhas.

**Validação (leitos obstétricos, competência de dezembro):**

| Setor (`nat_jur`) | Share SUS dos leitos obstétricos | Mediana por estabelecimento |
|---|---|---|
| Público (1xxx) | 98,8% | 100% |
| **For-profit (2xxx)** | **22,2%** | **0%** |
| Nonprofit (3xxx) | 72,0% | 77,8% |

Ou seja: a maternidade for-profit mediana **não coloca um leito obstétrico sequer no
SUS**, e o nonprofit é majoritariamente SUS, que é exatamente por que ele fica fora
do contraste-manchete. Isso entrou no corpo, no parágrafo que define os setores.

⭐ **E o teste sério, que deu resultado.** Coluna 6 nova da Tabela D.9: interação do
gradiente com o share SUS de leitos obstétricos, dentro das for-profit, com EF
`estab^year + muni^date`.

| | Coef. | EP | p |
|---|---|---|---|
| Fim de semana × share SUS | **+2,12pp** | 1,04 | 0,041 |
| Feriado × share SUS | **+3,37pp** | 1,19 | 0,005 |

**Maternidade for-profit mais exposta ao SUS tem gradiente de calendário mais
PLANO.** É a direção prevista, e é a primeira evidência do paper baseada em
**pagador** e não em propriedade. Robustez: com o share SUS de **todos** os leitos
(que não perde os estabelecimentos sem leito obstétrico registrado) dá +2,08 e
+2,59, praticamente igual.

⚠️ **Como reportar.** Associação, não efeito causal. Exposição ao SUS não é sorteada,
e maternidade for-profit que atende SUS difere das outras de formas que o EF
`estab^year` segura só em nível. O que a coluna diz é que o padrão de calendário
**varia com o pagador dentro de um mesmo tipo de propriedade**, o que a propriedade
sozinha não conseguiria mostrar. Está redigido assim no suplemento.

---

### 1.5 ❌ NÃO ADOTADA: "saber se o efeito vem do estabelecimento ou da equipe de saúde"

**Essa é a ideia central da tua nota, e é a que não dá com esses dados.** Não é
escolha de especificação: é limite de dado, e o cabeçalho do `09_org_capacity.R` já
dizia isso desde julho.

**O problema.** Hospital e médico fazem a **mesma predição**: serviço obstétrico
grande = gradiente menor, tanto por cobertura de plantão quanto por independência da
agenda de qualquer médico. Tamanho não separa os dois.

**O desenho que separaria** é *movers*: médico que troca de hospital, com EF de
médico e de hospital simultâneos (Molitor 2018; Chandra–Staiger). Exige ligar
**médico a parto**. O SINASC não tem identificador de profissional. O TISS não tem
nem identificador de hospital. O desenho não existe aqui, e nenhuma quantidade de
trabalho no CNES cria o link.

**O que dá para fazer e por que não vale agora.** O CNES-PF tem `CNS_PROF` ×
estabelecimento × ano, então dá para montar o painel de vínculos e medir
**rotatividade** e **multi-vínculo**. Mas herda o problema da validação: entre
maternidades com ≥50 partos, **14% das for-profit e 27% das públicas registram zero
obstetras**, porque o obstetra brasileiro mantém o vínculo no consultório próprio.
Erro de medida em nível já é ruim; em **mudança** (rotatividade) é pior. Esperar
ruído.

⭐ **A exceção que eu levaria para um paper 2: multi-vínculo no nível de MUNICÍPIO.**
"Obstetra com muitos vínculos tem tempo mais escasso, logo agenda mais" é
literalmente o Π do modelo em `latex/model.tex`, não é só descrição. E medido por
município (share de obstetras com ≥2 vínculos) o erro de atribuição hospitalar se
cancela dentro do município. O pipeline já existe: é o mesmo do
`04_heterogeneity.R`, que já usa densidade de obstetras por município.

### 1.6 ❌ NÃO ADOTADA: CBO nos dados de produção do TISS

> *"DADOS DE PRODUÇÃO, CBO (TISS, SIH): será que municípios mais intensivos de
> cesáreo têm mais partos de obstetra (CBO) do que outros CBOs?"*

**Não é calculável no TISS.** Conferi os dois dicionários (`até 2022` e `a partir de
2023`, em `dictionary/`): o campo `CBO` existe **somente na aba
`Ambulatorial_DET`**, e não aparece em `Hospitalar_DET` nem em `Hospitalar_CONS`.
Parto é evento hospitalar. Não há CBO nas guias de internação, ponto.

No SIH existe CBO do responsável em alguns anos, mas o SIH é **100% SUS**, o setor
errado para a manchete do paper, que é for-profit. E o SIH não está neste projeto
(está no HealthHeat).

⭐ **Mas a pergunta tem uma versão bem-posta, e acho que tu chegou perto dela.** No
Brasil praticamente todo parto hospitalar é atendido por médico; a margem real não é
obstetra-versus-outro-médico, é **obstetra versus enfermeiro obstetra** (oferta de
parteira). Isso é mensurável pelo CNES-PF, é oferta e não atendimento, tem
literatura própria e instrumento de política óbvio. Os classificadores **já existem**
em `build/00_utils.R` (`is_enfermeiro_obstetra`, CBO 7145), com o comentário
"kept for a possible midwife-supply revision". Fica para o paper 2.

### 1.7 ❌ NÃO ADOTADA na forma proposta: o painel MENSAL

> *"CNES-mês … total de partos cesáreos/total de partos semanais"*

**O "mês" quebra o desenho do paper atual.** Toda a identificação da Equação (3) é
**diária**: fim de semana, feriado, EF município×data. Agregar a mês joga fora
exatamente a variação que é o desenho.

Um painel CNES-mês responde *"por que este hospital é mais cesarista que aquele"*,
que é pergunta de **nível**, não de agendamento. Não é robustez da Eq. (3). É outro
paper. O que dele cabia aqui, a intensidade padronizada e a dispersão, entrou como
**estabelecimento-ano**.

**E por que ANO e não MÊS, já que tu falaste em mês.** Não é preguiça, é a
padronização que não sobrevive ao mês. A taxa padronizada é
$\sum_g w_g \cdot \text{taxa}_{h,g}$: ela precisa de uma taxa **por grupo de Robson**
dentro de cada célula. Medido nos dados:

| | |
|---|---|
| Partos por maternidade-**ano** (p10 / mediana / p90) | 139 / 495 / 2.651 |
| O mesmo por **mês** | 11,6 / 41,2 / 220,9 |
| Grupos de Robson presentes numa maternidade-ano | mediana **9 de 10**; só 42,8% têm os 10 |
| Menor grupo não vazio de uma maternidade-ano | mediana de **2 partos no ano inteiro** (0,2 por mês) |
| Grupos com menos de 12 partos no ano (ou seja, <1/mês) | mediana de **3 de 10** |

Ou seja: no mês, três dos dez grupos de uma maternidade típica estão **vazios**, e os
que sobram têm um ou dois partos. A renormalização dos pesos passaria a jogar fora
grupos **diferentes em meses diferentes do mesmo hospital**, e a taxa "padronizada"
deixaria de ser comparável entre meses e entre hospitais, que é exatamente o que a
padronização existe para consertar.

O ruído binomial da taxa agregada, aliás, não é o problema principal: ele responde por
0,4% da variância medida no ano e 4,3% no mês. O problema é a taxa **por grupo**.

Dois motivos menores na mesma direção: (i) as covariáveis são anuais de qualquer
jeito, porque os leitos do CNES vêm da competência de dezembro, então um painel mensal
repetiria o mesmo valor doze vezes; (ii) mês é a unidade certa para pergunta de
**timing**, e o timing do paper já está coberto em frequência mais fina, diária na
Eq. (3) e
**estabelecimento-semana** no `13_demand_smoothing.R`. Se o que tu tinha em mente com
"partos semanais" era throughput e não nível, esse objeto já existe, é o teste (B) do
script 13.

**Também não adotada:** *"estabelecimentos que foram aumentando intensidade ao longo
do tempo — EF CNES"*. É genuinamente novo, nada no repositório faz trajetória por
estabelecimento, e é viável. Mas sem choque é descrição pura, e painel de taxas tem
reversão à média mais entrada e saída de maternidades mudando o perfil de risco.
Precisa de painel balanceado e de uma pergunta mais afiada que "quem subiu". Paper 2.

---

## 2. Resumo do que mudou no repositório

| Arquivo | Mudança | Re-rodado? |
|---|---|---|
| `build/01d_cnes_estab.R` | agrega leitos SUS; painel ganha `beds_sus`, `beds_obstetric_sus`, `sus_share`, `sus_share_obstetric`. Comentário de validação do CBO corrigido (dizia "roughly half … equally", texto pré-11/07) | `build_estab_panel()` sim, **sem download novo**; 84.213 linhas, iguais |
| `analysis/code/09_org_capacity.R` | duas colunas novas na Tabela D.9: horas contratadas e exposição ao pagador; console reporta ambas | sim (~2 min, lê o cache) |
| `analysis/code/14_estab_practice_style.R` | **novo**: dispersão padronizada por Robson entre maternidades → Tabela C.4 | sim |
| `config/00_master_analysis.R` | `14` entra depois do `09` | — |
| `latex/paper.tex` | validação do pagador no parágrafo dos setores; dispersão entre hospitais no parágrafo do Kitagawa | — |
| `latex/sup_appendix.tex` | Tabela C.4 nova em C; prosa sobre as colunas 5 e 6 de D.9 | — |
| `README.md` | inventário programa-saída | — |

**Números do paper que NÃO mudaram:** nenhum. Os coeficientes existentes do `09`
saíram idênticos (fim de semana × log leitos = +0,445pp sob EF muni×data, como antes).

**Build:** paper **37 páginas**, suplemento **28** (era 27, a tabela nova). Zero
referência indefinida e zero citação indefinida nos dois. 1 overfull hbox no paper e
1 overfull vbox no suplemento, ambos os pré-existentes documentados.

⚠️ **Renumeração:** a tabela nova é **C.4**, então `tab:cost` passou de C.4 para
**C.5**. Nada no apêndice D mudou. Como sempre, re-derivar de `supplement.aux`, nunca
renumerar na mão.

---

## 3. O que eu levaria para o paper 2, se quisermos

Existe um paper honesto aqui, e não é este. A pergunta seria **"practice style no
nível do hospital"**: por que maternidades semelhantes, no mesmo mercado, com o mesmo
case-mix, rodam taxas de cesárea 13pp diferentes? O fato já está estabelecido (Tabela
C.4). O que falta é o mecanismo, e o caminho seria:

1. painel de vínculos CNES-PF (`CNS_PROF` × estabelecimento × ano): multi-vínculo e
   rotatividade, medidos no nível de município para cancelar erro de atribuição;
2. composição da oferta obstétrica: obstetra versus enfermeiro obstetra
   (os classificadores já estão prontos em `build/00_utils.R`);
3. trajetórias de estabelecimento, com painel balanceado;
4. e o desenho que fecharia tudo, se algum dia aparecer um identificador de
   profissional ligado ao parto: *movers*.

Nada disso está no caminho crítico de março/2027. Os bloqueadores continuam sendo
R1 (reprodução end-to-end), T1 (revisão interna dos quatro), D1 (CRediT, já decidido)
e D5b (depósito do pacote).
