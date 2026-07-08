# HealthEcon

Empirical health-economics research on Brazil's private health-insurance
(*saúde suplementar*) sector, using the **ANS TISS Hospitalar** micro-data on
hospital admissions financed by private health plans (2015–2025).

## Reproducing

1. Set `DROPBOX_ROOT` in [`config/config.R`](config/config.R) — the only path
   that changes per machine. It must point at the data folder containing
   `build/TISS/input/` and `build/TISS/output/`.
2. Run [`config/00_master_build.R`](config/00_master_build.R) to build the
   analytical dataset from the raw TISS parquet files.
3. Run [`config/00_master_analysis.R`](config/00_master_analysis.R) to reproduce
   the results.

Packages install themselves via `pacman::p_load()` — no manual
`install.packages()` needed.

## Layout

```
config/     config.R (paths) · 00_master_build.R · 00_master_analysis.R
build/      00_utils.R · 01_download_tiss.R · (02_clean_tiss.R …)
analysis/   code/ (00_utils.R, analysis scripts) · output/{graphs,tables,maps}
dictionary/ ANS TISS variable dictionaries (.ods)
latex/      paper source
```

**Code and final outputs live in Git; raw and intermediate data live in Dropbox
(never committed).** See [`CLAUDE.md`](CLAUDE.md) for the data infrastructure and
conventions.
