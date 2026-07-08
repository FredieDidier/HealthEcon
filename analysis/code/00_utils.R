# =============================================================================
# 00_utils.R — shared helpers for the analysis scripts.
#
# House figure style (journal-clean, no title/subtitle/caption) and colour
# palette, mirroring the HomeOfficePNAD repo.
# =============================================================================

# Colour palette (semantic): private = red, public = blue, secondary = grey/orange.
PAL <- c(red = "#C0392B", blue = "#2471A3", grey = "#616A6B",
         orange = "#E67E22", navy = "#2C3E50")

theme_paper <- function(base = 14) {
  ggplot2::theme_bw(base_size = base) +
    ggplot2::theme(
      legend.position    = "bottom",
      legend.title       = ggplot2::element_blank(),
      legend.text        = ggplot2::element_text(size = base - 2),
      legend.key.width   = ggplot2::unit(1.1, "cm"),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major   = ggplot2::element_line(colour = "grey92"),
      axis.text          = ggplot2::element_text(size = base - 2),
      axis.title         = ggplot2::element_text(size = base - 1),
      strip.text         = ggplot2::element_text(size = base - 1, face = "bold"),
      strip.background   = ggplot2::element_rect(fill = "grey94", colour = NA),
      plot.title         = ggplot2::element_blank(),
      plot.subtitle      = ggplot2::element_blank(),
      plot.caption       = ggplot2::element_blank()
    )
}

# Save a figure as both PDF and PNG (300 dpi), the repo convention.
save_fig <- function(plot, name, width = 8, height = 5) {
  d <- here::here("analysis", "output", "graphs")
  ggplot2::ggsave(file.path(d, paste0(name, ".pdf")), plot, width = width, height = height)
  ggplot2::ggsave(file.path(d, paste0(name, ".png")), plot, width = width, height = height, dpi = 300)
}

# Standard table-note fragments for etable(notes = ...).
SIGNIF_NOTE  <- "\\footnotesize Significance: *** p$<$0.01, ** p$<$0.05, * p$<$0.10."

# ---------------------------------------------------------------------------
#
# postprocess_tex(): cleans a fixest `etable()` LaTeX file into the project's
# house style (booktabs rules, no redundant SE/Signif footer, font-size + column
# spacing for wide tables). Call it right after each etable() that writes to
# `file`; pass the significance legend through etable's own `notes =` argument
# together with `signif.code = NA`.
# =============================================================================

postprocess_tex <- function(file, fontsize = "\\small", tabcolsep = 4, addspace = TRUE) {
  tx <- readLines(file)
  tx <- tx[!grepl("standard-errors in parentheses", tx, fixed = TRUE)]
  tx <- tx[!grepl("Signif. Codes", tx, fixed = TRUE)]  # our own legend is in the note
  tx <- sub("\\begin{table}[htbp]", "\\begin{table}[H]", tx, fixed = TRUE)  # float placement
  tx <- sub("\\tabularnewline \\midrule \\midrule", "\\toprule", tx, fixed = TRUE)
  tx <- sub("^\\s*\\\\midrule \\\\midrule\\s*$", "\\\\bottomrule", tx)
  if (addspace) {
    se <- grepl("^\\s*&.*\\([0-9]", tx)
    if (any(se)) {
      out <- vector("list", length(tx))
      for (k in seq_along(tx)) out[[k]] <- if (se[k]) c(tx[k], "\\addlinespace[2pt]") else tx[k]
      tx <- unlist(out)
    }
  }
  i  <- grep("\\begin{tabular}", tx, fixed = TRUE)[1]
  tx <- append(tx, paste0(fontsize, "\\setlength{\\tabcolsep}{", tabcolsep, "pt}"),
               after = i - 1)
  writeLines(tx, file)
}
