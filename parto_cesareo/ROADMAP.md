# Roadmap — *Born on Schedule* até a submissão no JHE

**Meta:** submeter ao Journal of Health Economics em **março/2027**.
**Escopo acordado antes da submissão:** (1) robustez de temperatura; (2) rodada formal de revisão interna dos coautores; (3) finalização editorial.
**Horizonte:** ~7 meses a partir de agosto/2026.
*Atualizado em 20/08/2026. Contexto completo em `CONTEXTO_PESQUISA.md`.*

---

## Parte I — O que já está feito

### Empírico ✅

| Bloco | Status |
|---|---|
| Canal preço (Eq. 1 + primeira diferença estado-ano) | Completo. Nulo robusto, honorário econômico corretamente construído |
| Gradientes de calendário descritivos (Eq. 2) | Completo, for-profit e público separadamente |
| **Eq. (3), a especificação central** | Completo. −2,3pp fds / −2,9pp feriado; robusto a composição materna e a Robson |
| Split pré-parto vs. intraparto | Completo. −9,7pp vs. +1,7pp — o mecanismo |
| Robson 1–2 e Robson 1 isolado | Completo. −7,4pp / −6,5pp |
| Feriados prolongados + event study de deslocamento | Completo. **Nulo**, reportado honestamente |
| Capacidade organizacional | Completo. **Fraco/misto**, movido para o suplemento (D.8) |
| Perfil por grupo de Robson (Fig 3c) | Completo. Concentrado em G1–G4, zero em G10 |
| Termo vs. pré-termo; idade materna | Completo (22/07/2026). Ambos **apoiam** o mecanismo |
| Custo: early-term, Kitagawa, excesso de dia útil, valor faturado | Completo. +11,7pp; 72% estilo de prática; ~50 mil/ano |
| Testes múltiplos (5 famílias A–E) | Completo |
| Inferência de poucos clusters, permutação, placebos | Completo |
| Registro de política (Parto Adequado, RN 368) | Completo, no Apêndice E como falha de desenho |

### Texto e formatação ✅

- Manuscrito completo: 1.200 linhas de `paper.tex`, 6 seções + conclusão, abstract dentro do limite de 250 palavras do JHE.
- Suplemento reorganizado em três apêndices (C descritivo / D robustez / E política).
- Formato Elsevier/JHE aplicado: página de título com afiliações em sobrescrito, autor correspondente marcado, JEL/keywords, declarações não numeradas, `highlights.txt`.
- Modelo teórico no Apêndice A; dados e variáveis no Apêndice B.
- Terminologia padronizada e taxonomia de evidência aplicada em todo o texto.
- Posicionamento vs. Parfitt & Goulart (2026) escrito; Carnaval reconciliado com Melo.

### Infraestrutura ✅

- 13 scripts de análise + 7 de build, com script mestre, ordem documentada e inventário programa→output.
- `renv.lock` + `sessionInfo.txt` para reprodução exata.
- Seeds fixados; outputs versionados no git.
- Seis bugs identificados e corrigidos, todos documentados com impacto quantificado.
- **Dataset completo agora disponível localmente** (42M nascimentos SINASC, 5,1 GB TISS bruto, CNES, IEPS, `main_data.parquet`) — verificado contra os números do paper.

---

## Parte II — O que falta

### 🔴 Bloqueadores de submissão

| # | Item | Trilha | Esforço |
|---|---|---|---|
| **E1** | **Robustez de temperatura** — adquirir temperatura diária municipal e re-estimar a Eq. (3) com controles ForProfit×bin de temperatura | Vinicius + Claude | Alto |
| **R1** | Reprodução end-to-end com o dataset local (resolver o descompasso `dataset/` vs. `build/`) | Claude | Baixo |
| **T1** | Rodada formal de revisão interna dos quatro coautores | Coautores | Médio |
| **D1** | Confirmar os papéis CRediT (hoje um rascunho marcado TODO em `paper.tex:1140`) | Fredie | Baixo |
| **D2** | Verificar as magnitudes de Tita et al. (2009) citadas no back-of-envelope da seção de custo | Fredie | Baixo |
| ~~**D3**~~ | ~~Verificação completa de citações~~ — **feito em 20/ago/2026**. As 50 entradas checadas contra as fontes; nenhuma fabricada, nenhuma citação órfã. Achados em `Literature/verificacao_citacoes.md`: falta `melo2023` (avaliação da política nacional) na seção institucional; título de `johnson2016` errado; `melo2024` e `parfitt2026` com metadados desatualizados; `curriemacleod2016` não citado. **Pendente com Fredie:** aplicar as correções no `.bib` e decidir sobre `melo2023`. | Claude + Fredie | ✅ |
| **D4** | Entradas da ferramenta de declarações da Elsevier (conflito de interesse em Word) | Fredie | Baixo |
| **D5** | Pacote de replicação depositado em repositório confiável | Vinicius + Claude | Médio |

### 🟡 Desejáveis, não bloqueantes

| # | Item | Nota |
|---|---|---|
| O1 | Cover letter para o JHE | Escrever em fevereiro |
| O2 | Preprint SSRN gratuito na submissão | Decisão do Fredie |
| O3 | Sugestão de referees | O JHE aceita; vale preparar 4–5 nomes |
| O4 | Revisão de inglês por falante nativo | Se o orçamento permitir |
| O5 | Checagem de acessibilidade das figuras (daltonismo) | `PAL` já é razoável; vale confirmar |

---

## Parte III — Item E1 em detalhe: a robustez de temperatura

**Por que existe.** Vem do Proof Patrol R1 C4. Parfitt & Goulart (2026, JDE) mostram que ondas de calor afetam desfechos em maternidades brasileiras. Um referee pode perguntar se o gradiente de calendário é um canal climático não modelado — dias de fim de semana e feriados não são climaticamente aleatórios (Carnaval é verão, feriados de junho são inverno).

**Por que o argumento já é forte.** Os EF município×data da Eq. (3) **já absorvem toda a temperatura comum aos dois setores naquele dia local**. O paper já diz isso, textualmente. A ameaça residual é estreita: exigiria que os setores for-profit e público **respondessem diferentemente** à temperatura, de um jeito correlacionado com o calendário. Este é um cinto-e-suspensório, não um conserto.

**Plano de execução.**

1. **Aquisição.** ERA5-Land (Copernicus CDS, resolução 0,1°, temperatura horária a 2m) é preferível ao INMET — cobertura completa e uniforme, sem lacunas de estação. Agregar para média diária e máxima diária por município, ponderando por área da malha municipal do IBGE, 2010–2024. Alternativa mais leve: INMET estações automáticas + pareamento pelo município mais próximo, com o custo de cobertura irregular.
2. **Construção dos bins.** Bins de temperatura ao estilo Deschênes–Greenstone / Barreca (ex.: <10, 10–15, 15–20, 20–25, 25–30, >30 °C), mais precipitação diária se disponível.
3. **Estimação.** Três especificações reportadas lado a lado com a principal, no suplemento:
   - (a) Eq. (3) + ForProfit × bin de temperatura
   - (b) (a) + ForProfit × precipitação
   - (c) Eq. (3) descartando dias acima do percentil 95 local de temperatura
4. **Resultado esperado.** $\gamma_1$ essencialmente inalterado. Se mudar materialmente, isso é um achado — e muda o paper.
5. **Entrega.** Nova tabela no Apêndice D (D.7 ou adjacente) + um parágrafo na seção 4 ou 6A. Novo script `13_temperature.R`, rodando **depois de 07** e reusando `sinasc_daily_muni.parquet`.

**Riscos.** A API do CDS exige registro e tem fila; o download de 15 anos × 5.570 municípios é pesado. Começar a aquisição cedo — é o item de maior lead time do cronograma, e é por isso que ele abre o calendário.

---

## Parte IV — Cronograma

| Mês | Marco | Entregável verificável |
|---|---|---|
| **Ago/2026** | Infraestrutura pronta | Pipeline roda end-to-end com o dataset local; `dataset/` resolvido; ambiente R restaurado |
| **Set/2026** | Temperatura adquirida | Painel município-dia de temperatura 2010–2024 em parquet, validado contra estações INMET em 10 capitais |
| **Out/2026** | Temperatura estimada | `13_temperature.R` roda; tabela de robustez gerada; $\gamma_1$ comparado com o principal |
| **Nov/2026** | Texto integrado | Parágrafo no corpo + tabela no Apêndice D; paper e suplemento compilam sem referência indefinida |
| **Dez/2026** | Manuscrito circulado | Versão congelada enviada aos quatro coautores com prazo e roteiro de leitura |
| **Jan/2027** | Comentários consolidados | Comentários dos quatro recebidos, consolidados em uma lista única e priorizada |
| **Fev/2027** | Revisões incorporadas | Comentários endereçados um a um; CRediT confirmado; declarações prontas; citações verificadas; cover letter escrita |
| **Mar/2027** | **Submissão** | Pacote de replicação depositado; submissão no editorial manager do JHE |

**Folga.** O cronograma tem cerca de um mês de folga embutida (o bloco dez–jan é generoso de propósito, porque depende da agenda de quatro pessoas em recesso). Se a aquisição de temperatura escorregar além de outubro, a decisão a tomar é: submeter em março sem ela e guardá-la para a resposta ao referee, ou empurrar a submissão para abril. **Recomendação: submeter em março de qualquer jeito.** O argumento dos EF município×data já cobre a objeção; a robustez é reforço.

---

## Parte V — Divisão de tarefas

### Vinicius — o dono do empírico

| Tarefa | Quando |
|---|---|
| Decidir ERA5-Land vs. INMET e abrir a conta no Copernicus CDS | Ago |
| Validar o painel de temperatura contra estações conhecidas | Set |
| Definir os cortes de bin e assinar a especificação | Out |
| Ler o resultado e julgar se ele muda o paper | Out |
| Escrever o parágrafo de temperatura no corpo | Nov |
| Coordenar a rodada de revisão interna (prazos, consolidação) | Dez–Jan |
| Preparar o depósito do pacote de replicação | Fev |
| Decidir se um resultado inesperado vira achado ou nota de rodapé | conforme surgir |

### Coautores

**Fredie** (correspondente — dono do editorial)

- Confirmar os papéis CRediT dos quatro autores → **remove o TODO de `paper.tex:1140`** *(set)*
- Verificar as magnitudes de Tita et al. (2009) no back-of-envelope de custo *(set)*
- Preparar as entradas da ferramenta de declarações da Elsevier *(fev)*
- Decidir sobre o preprint SSRN *(fev)*
- Cover letter e submissão *(mar)*

**Pablo e Lucas**

- Leitura crítica da versão congelada, com foco atribuído para não sobrepor *(dez–jan)*
  - **Pablo:** seções 4–5 (estratégia empírica e resultados de honorário) — o alvo é a lógica de identificação e se a taxonomia de evidência se sustenta
  - **Lucas:** seções 6–7 (agenda e custo) + suplemento — o alvo é se os nulos estão reportados honestamente e se os números batem entre corpo e suplemento
- Sugerir nomes de referees *(jan)*

**Todos os quatro**

- Aprovar a versão final antes da submissão *(mar)*

### Claude — o que dá para automatizar nesta pasta

| Tarefa | Quando |
|---|---|
| Resolver o descompasso `dataset/` vs. `build/` e documentar o `DROPBOX_ROOT` correto | Ago |
| Baixar e montar o painel município-dia de temperatura (ERA5-Land ou INMET) | Ago–Set |
| Escrever `13_temperature.R` seguindo as convenções do repositório | Out |
| Re-checar todos os números do paper contra o dataset, um a um | Nov |
| Verificar todas as entradas do `refs.bib` contra as fontes (DOI, ano, volume, páginas) | Nov |
| Rodar o ciclo de compilação e conferir `grep -c "Reference .* undefined"` = 0 | contínuo |
| Consolidar os comentários dos coautores em uma lista priorizada | Jan |
| Montar o pacote de replicação e a checagem final de consistência | Fev |
| Manter `CONTEXTO_PESQUISA.md` e este roadmap atualizados | contínuo |

**Limite do ambiente:** o sandbox tem Python mas **não tem R**. Os scripts `.R` não rodam aqui como estão. Réplicas e verificações são feitas em Python (`pyarrow`/`pandas`/`pyfixest`), ou o R roda na sua máquina. Isso não bloqueia nada, mas vale ter claro na hora de dividir.

---

## Parte VI — Riscos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Aquisição de temperatura atrasa (fila do CDS, volume) | Média | Começar em agosto; INMET como plano B; submeter sem ela se preciso |
| Um coautor não devolve comentários a tempo | Média | Foco atribuído por seção; prazo firme em janeiro; a submissão não espera |
| A robustez de temperatura muda $\gamma_1$ materialmente | Baixa | Se acontecer, é achado — reformular a seção 4, não esconder |
| Reprodução end-to-end revela discrepância numérica | Baixa | Já bati 5 números-manchete contra o dataset e fecham |
| O JHE rejeita sem revisão | Média (é a norma) | Ter Health Economics, JHR e EJHE como próximos alvos, com o formato já pensado |

---

## Parte VII — Regras que não se renegociam

Valem para qualquer pessoa (ou agente) que edite o paper. Detalhamento em `CONTEXTO_PESQUISA.md`, seções 4 e 10.

1. **Eq. (3) é um *differential*, nunca um difference-in-differences.**
2. **"for-profit" (SINASC) ≠ "private-insurance sector" (TISS).** Nunca "private" puro.
3. **Os nulos ficam.** Feriados prolongados e capacidade organizacional vieram fracos — reportar honestamente é o que delimita a alegação. Não enterrar, não reformular como positivo.
4. **Robson e idade gestacional são corroboração, não placebo.** Pré-termo não é não agendável.
5. **Nunca reintroduzir `else → Public`** na classificação de `nat_jur`.
6. **Nunca passar de 6,5in** numa figura de `\textwidth` — adicionar uma linha, não uma coluna.
7. **Compilar nos dois sentidos**, sem limpar os `.aux` no meio.
8. **Não rodar dois scripts de 42M linhas em paralelo.**
9. **Não commitar dados.**
10. **Se mover um exhibit, re-derivar o mapa de `paper.aux`** — nunca renumerar à mão.
