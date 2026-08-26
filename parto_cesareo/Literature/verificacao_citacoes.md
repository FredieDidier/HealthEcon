# Verificação das referências — `scripts_github/latex/paper.tex` (versão atual)

Data da verificação: 20/08/2026
Arquivos checados: `paper.tex`, `appendix.tex`, `sup_appendix.tex`, `model.tex`, `supplement.tex`, `refs.bib`

**Resumo:** 49 chaves citadas, 50 entradas no `.bib`. Nenhuma citação órfã (o
documento compila). Nenhuma referência fabricada — todas as 50 entradas
correspondem a trabalhos reais. Encontrados **6 problemas**, sendo 1 relevante
(referência ausente) e 3 de metadados desatualizados.

---

## 🔴 Problema 1 — Referência ausente sobre a própria política que o paper discute

A seção institucional (linhas ~410-430) descreve a RN 368/2015 e o *Parto
Adequado*, e o apêndice traz duas figuras sobre eles (`fig:pa_hospital`,
`fig:rn368`) — **sem nenhuma citação acadêmica**. A única fonte é o dado bruto
da ANS (`data_parto_adequado`).

Existe uma avaliação publicada exatamente dessa política:

> Melo, Carolina & Menezes-Filho, Naercio (2023). "The effects of a national
> policy to reduce c-sections in Brazil." *Health Economics* 32(2):501-517.
> DOI: 10.1002/hec.4630
> — encontra redução de 1,6 p.p. na taxa de cesárea, +0,07 semanas de gestação
> e +10 g de peso ao nascer.

São os mesmos autores do `melo2024` já citado. Um parecerista de periódico de
economia da saúde quase certamente apontaria essa ausência.

---

## 🟠 Problema 2 — Título incorreto em `johnson2016`

```
atual:   Physicians treating physicians: Information asymmetry and incentives in childbirth
correto: Physicians Treating Physicians: Information and Incentives in Childbirth
```

A palavra "asymmetry" não consta do título publicado (AEJ: Economic Policy
8(1):115-141, DOI 10.1257/pol.20140160). Demais campos estão corretos.

---

## 🟡 Problema 3 — `melo2024` marcado como *early view*, mas já saiu em volume

```
atual:   journal={Health Economics}, year={2024}, note={Early view, doi:10.1002/hec.4858}
correto: Health Economics 33(9):2013--2058, 2024
```

## 🟡 Problema 4 — `spinola2025` sem volume/páginas

Publicado no *European Journal of Health Economics*, DOI 10.1007/s10198-025-01835-x.
Vale conferir se já saiu em volume paginado antes da submissão.

## 🟡 Problema 5 — `curriemacleod2016` no `.bib` mas nunca citado

Currie, MacLeod & Van Parys (2016), *JHE* 47:64-80, "Provider practice style and
patient health outcomes: The case of heart attacks". Ou incorporar na discussão
de *practice styles* (junto de `molitor2018`, `cutler2019`, `epstein2009`), ou
remover.

## ✅ Problema 6 — RESOLVIDO: afirmação sobre `melo2024` está correta

Nota de rodapé (linha ~339): *"\citet{melo2024} classify hospitals using the
allocation of obstetric beds across public and private care"*. **Confirmado
contra o texto do paper** (versão WP baixada, seção de dados): eles definem três
tipos de unidade — privada (100% dos leitos obstétricos no sistema privado),
pública (100% no SUS) e mista — exatamente pela alocação de leitos obstétricos.
A descrição no nosso paper está fiel. Nenhuma correção necessária.

## 🟡 Problema 7 — `parfitt2026`: metadados incompletos e sobrenome do coautor a confirmar

Faltam DOI e o campo de páginas. A referência completa é:

```
Journal of Development Economics, vol. 181(C), 2026. DOI: 10.1016/j.jdeveco.2026.103725
```

**Divergência de nome:** o RePEc/Elsevier (metadados do editor) lista
**"Goulart, Nicolas"** — igual ao nosso `.bib`. Já o site pessoal do Rafael
Parfitt lista o mesmo artigo como *"Joint with Nicolas Moura"*. Como o registro
publicado é o do editor, manter `Goulart`; mas vale um e-mail ao autor antes da
submissão, já que citamos o paper cinco vezes e o chamamos de estudo
contemporâneo mais próximo.

**Escopo do paper (útil para o item E1):** 25 milhões de nascimentos em
hospitais **públicos**, 2008–2019. Calor extremo → menor probabilidade de parto
conduzido por médico, mais partos por enfermagem, **queda** na taxa de cesárea;
entre partos com médico, mais cesáreas pré-parto. Sem efeito em Apgar. Isso
confirma a descrição de setor na nossa nota de rodapé.

---

## ✅ Verificadas e corretas (44 entradas)

**Incentivos do médico e demanda induzida**
`gruber1996physician` (RAND 27(1):99-123) · `gruber1999physician` (JHE 18(4):473-490) ·
`dranove1988` (Econ. Inquiry 26(2):281-298) · `grant2009` (JHE 28(1):244-250) ·
`clemens2014` (AER 104(4):1320-1349) · `alexander2020` (JPE 128(11):4046-4096) ·
`mcguire2000` (Handbook chapter) · `lo2003` (SSM 57(1):91-96)

**Lazer do médico e manipulação do calendário de partos**
`cohen1983` (JRSS-C 32(3):228-235) · `brown1996` (JHE 15(2):233-242) ·
`spetz2001` (Medical Care 39(6):536-550) · `dickertconlin1999` (JPE 107(1):161-177) ·
`gans2009` (JPubE 93(1-2):246-263) · `gans2012` (Economic Record 88(281):182-194) ·
`fabbri2016` (Health Policy 120(7):780-789) · `jacobson2021` (JOLE 39(S2)) ·
`costaramon2018` (JHE 59:46-59)

**Capacidade, lotação e staffing**
`maibom2021` (JHE 75:102399) · `facchini2022` (JEBO 197:370-394) ·
`bachner2024` (IZA DP 16981 — não publicado; entrada `@techreport` correta) ·
`bensnes2026` (Health Economics 35(2):175-211, DOI 10.1002/hec.70048)

**Practice styles e variação geográfica**
`epstein2009` (JHE 28(6):1126-1140) · `finkelstein2016` (QJE 131(4):1681-1726) ·
`molitor2018` (AEJ:EP 10(1):326-356) · `cutler2019` (AEJ:EP 11(1):192-221)

**Cesárea e desfechos de saúde**
`card2023` (AEJ:EP 15(2):42-81) · `currie2008` (QJE 123(2):795-830) ·
`borra2019` (JEEA 17(1):30-78) · `tita2009` (NEJM 360(2):111-120) ·
`sandall2018` (Lancet 392(10155):1349-1357) · `boerma2018` (Lancet 392(10155):1341-1348) ·
`betran2021` (BMJ Global Health 6(6):e005671) · `who2015cesarean` (WHO/RHR/15.02)

**Brasil**
`spinola2025` (EJHE) · `melo2024` (Health Economics) · `parfitt2026` (JDE vol. 181)

**Métodos**
`cameron2008` (REStat 90(3):414-427) · `webb2023` (CJE 56(3):839-858) ·
`sun2021` (J. Econometrics 225(2):175-199) · `benjamini1995` (JRSS-B 57(1):289-300) ·
`holm1979` (Scand. J. Statistics 6(2):65-70) · `kitagawa1955` (JASA 50(272):1168-1194)

**Fontes de dados** (`@misc`): `data_sinasc`, `data_ans_tiss`, `data_cnes`,
`data_ieps`, `data_basedosdados`, `data_parto_adequado` — sem problemas de formato.

---

## Sobreposição com a pasta `Literature`

Já baixados e citados no paper: `gruber1996physician`, `gruber1999physician`,
`currie2008`, `clemens2014`, `johnson2016`, `card2023`, `costaramon2018`.

Baixados mas **não** citados — candidatos a incorporar:

| Paper | Por que encaixa |
|-------|-----------------|
| Almond, Doyle, Kowalski & Williams (2010), *QJE* | RD em peso ao nascer; referência de retornos marginais |
| Costa-Ramón et al. (2022), *JHR* | Efeitos de longo prazo — extensão natural dos desfechos |
| "A demand-smoothing incentive for cesarean deliveries" (2021), *JHE* 75:102411 | Suavização de demanda: mecanismo irmão do gradiente de calendário |

## Correções sugeridas no `refs.bib`

```bibtex
@article{johnson2016,
  title={Physicians treating physicians: Information and incentives in childbirth},
  author={Johnson, Erin M and Rehavi, M Marit},
  journal={American Economic Journal: Economic Policy},
  volume={8}, number={1}, pages={115--141}, year={2016}
}

@article{melo2024,
  title={The effect of birth timing manipulation around carnival on birth indicators in Brazil},
  author={Melo, Carolina and Menezes-Filho, Naercio},
  journal={Health Economics}, volume={33}, number={9}, pages={2013--2058}, year={2024}
}

@article{melo2023,
  title={The effects of a national policy to reduce c-sections in Brazil},
  author={Melo, Carolina and Menezes-Filho, Naercio},
  journal={Health Economics}, volume={32}, number={2}, pages={501--517}, year={2023}
}
```
