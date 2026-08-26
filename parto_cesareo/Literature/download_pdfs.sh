#!/usr/bin/env bash
# Baixa os PDFs originais dos papers de economia sobre parto cesáreo.
# Rodar NA SUA MÁQUINA (o ambiente do Claude bloqueia acesso direto à rede).
#
#   chmod +x download_pdfs.sh && ./download_pdfs.sh
#
# Papers em periódicos com paywall (Frakes AER, Costa-Ramón 2018 JHE) exigem
# acesso institucional e não estão neste script.

set -u
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36"
OUT="$(cd "$(dirname "$0")" && pwd)/pdf"
mkdir -p "$OUT"

get() {
  local url="$1" name="$2"
  if [ -f "$OUT/$name" ]; then echo "SKIP  $name (já existe)"; return; fi
  curl -sL -A "$UA" --max-time 120 -o "$OUT/$name" "$url"
  if [ "$(file -b --mime-type "$OUT/$name")" = "application/pdf" ]; then
    echo "OK    $name ($(du -h "$OUT/$name" | cut -f1))"
  else
    echo "FALHA $name  <- $url"; rm -f "$OUT/$name"
  fi
}

echo "Salvando em: $OUT"
echo

# --- Incentivos financeiros e demanda induzida ---
get "https://www.nber.org/system/files/working_papers/w4933/w4933.pdf" \
    "1996_Gruber-Owings_Physician-Financial-Incentives-Cesarean.pdf"
get "https://www.nber.org/system/files/working_papers/w6744/w6744.pdf" \
    "1999_Gruber-Kim-Mayzlin_Physician-Fees-Procedure-Intensity.pdf"
get "https://www.nber.org/system/files/working_papers/w19242/w19242.pdf" \
    "2016_Johnson-Rehavi_Physicians-Treating-Physicians.pdf"
get "https://econweb.ucsd.edu/~j1clemens/pdfs/ClemensGottlieb_PhysicianIncentives.pdf" \
    "2014_Clemens-Gottlieb_Physician-Financial-Incentives.pdf"
get "https://docs.iza.org/dp12297.pdf" \
    "2021_de-Elejalde-Giolito_Demand-Smoothing-Incentive-Cesarean.pdf"

# --- Efeitos causais da cesárea sobre saúde ---
get "https://www.nber.org/system/files/working_papers/w25986/w25986.pdf" \
    "2023_Card-Fenizia-Silver_Health-Impacts-Hospital-Delivery-Practices.pdf"
get "https://jhr.uwpress.org/content/wpjhr/57/6/2048.full.pdf" \
    "2022_Costa-Ramon-et-al_Long-Run-Effects-of-Cesarean-Sections.pdf"
get "https://www.nber.org/system/files/working_papers/w14522/w14522.pdf" \
    "2010_Almond-Doyle-Kowalski-Williams_Marginal-Returns-Medical-Care.pdf"
get "https://www.diva-portal.org/smash/get/diva2:1738710/FULLTEXT01.pdf" \
    "2022_Kotsadam-et-al_Cesarean-High-Risk-Births.pdf"

# --- Litígio e regulação ---
get "https://www.nber.org/system/files/working_papers/w12478/w12478.pdf" \
    "2008_Currie-MacLeod_First-Do-No-Harm.pdf"

echo
echo "Paywall — baixar via acesso institucional:"
echo "  Frakes (2013) AER 103(1):257-276   https://doi.org/10.1257/aer.103.1.257"
echo "  Costa-Ramón et al. (2018) JHE 59   https://doi.org/10.1016/j.jhealeco.2018.03.004"
echo
echo "Obs: o WP 6744 (Gruber-Kim-Mayzlin) é um scan sem camada de texto."
echo "     Para tornar pesquisável:  ocrmypdf in.pdf out.pdf"
