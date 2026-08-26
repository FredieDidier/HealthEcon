# Triagem — o que vale baixar das referências citadas

Critério: relevância para os blocos de argumento do *Born on Schedule* (honorários,
gradiente de calendário Eq. 2/3, pré-parto vs. intraparto, nulo de feriados
prolongados, nulo de capacidade organizacional, Kitagawa, Robson) e para o item
aberto **E1** (robustez de temperatura).

---

## Tier A — essenciais. **Baixados nesta rodada** ✅

| Ref | Por que | Arquivo |
|-----|---------|---------|
| `bachner2024` | Leitos vazios → cesárea. É o espelho austríaco do nosso nulo de capacidade organizacional: eles **acham** efeito, nós não. Precisa ser confrontado explicitamente. | `2024_Bachner-Halla-Pruckner_...IZA-DP16981.txt` |
| `melo2024` | Carnaval, Brasil. Já usado para reconciliar o nulo de feriados prolongados. | `2024_Melo-Menezes-Filho_...WP.txt` |
| `spinola2025` | Brasil, bridge weekdays, público×privado. Comparação mais direta com o nosso resultado de bridge (p≈0,68). | `2025_Spinola-Rocha_...EJHE.txt` |
| `bensnes2026` | Congestionamento → **menos** intervenção. Mesmo sinal do nosso nulo de capacidade. | `2026_Bensnes_...SSB-DP963.txt` |

## Tier A — essenciais, **não obtidos** (paywall)

| Ref | Por que importa | Onde conseguir |
|-----|-----------------|----------------|
| **`melo2023`** (ausente do `.bib`) | Avalia a política nacional que a nossa seção institucional descreve sem citar. Lacuna a corrigir. | *Health Economics* 32(2):501-517, DOI 10.1002/hec.4630 |
| `parfitt2026` | "Closest contemporaneous study" **e** base do item E1. Abstract completo já está no relatório de verificação. | *JDE* 181(C), DOI 10.1016/j.jdeveco.2026.103725 |
| `costaramon2018` | Hora do dia → cesárea. O mecanismo-irmão do nosso gradiente. | *JHE* 59:46-59 |
| `brown1996` | "Physician demand for leisure" é literalmente o mecanismo do paper. | *JHE* 15(2):233-242 |

## Tier B — vale se der (mecanismo de staffing/capacidade)

`facchini2022` (JEBO 197:370-394 — tentei, paywall) · `maibom2021` (JHE 75:102399)

Junto com `bachner2024` e `bensnes2026`, formam o quarteto de "capacidade →
intervenção". Como reportamos **nulo** nessa margem (regra 3: os nulos ficam), é
o bloco onde um parecerista vai apertar mais. Ter os quatro em mãos permite
argumentar que a nossa margem de capacidade (redundância organizacional) é
diferente da margem de lotação de curto prazo que eles estudam.

## Tier C — baixar só se a revisão interna pedir

`jacobson2021` · `fabbri2016` · `spetz2001` · `gans2009` · `gans2012` ·
`dickertconlin1999` · `cohen1983` · `epstein2009` · `grant2009` · `alexander2020`

Literatura de calendário e incentivos já bem representada pelo que temos. São
citações de posicionamento, não de mecanismo disputado.

## Tier D — **não vale baixar**

- **Métodos:** `cameron2008`, `webb2023`, `sun2021`, `benjamini1995`, `holm1979`,
  `kitagawa1955`. São fórmulas padrão já implementadas no código; o PDF não
  acrescenta nada.
- **Descritivos médicos:** `tita2009`, `sandall2018`, `boerma2018`, `betran2021`,
  `who2015cesarean`. Citações factuais de uma linha (taxa de referência da OMS,
  epidemiologia global).
- **Contexto conhecido:** `mcguire2000`, `dranove1988`, `lo2003`, `molitor2018`,
  `cutler2019`, `finkelstein2016`, `borra2019`.

---

## Lacuna prospectiva — item E1 ainda não tem referência metodológica

O `ROADMAP.md` (Parte III, passo 2) prevê bins de temperatura "ao estilo
Deschênes–Greenstone / Barreca", mas **nenhum dos dois está no `refs.bib`**.
Quando o `13_temperature.R` rodar e a tabela do Apêndice D for escrita, vão
faltar as citações metodológicas. Candidatas:

- Deschênes & Greenstone (2011), *AEJ: Applied* 3(4):152-185 — "Climate Change,
  Mortality, and Adaptation"
- Barreca, Clay, Deschênes, Greenstone & Shapiro (2016), *JPE* 124(1):105-159 —
  "Adapting to Climate Change: The Remarkable Decline in the US
  Temperature-Mortality Relationship"

Vale adicioná-las ao `.bib` junto com a rodada de temperatura, não depois.
