# =============================================================================
# 00_utils.R — shared helpers for the analysis scripts.
#
# House figure style (journal-clean, no title/subtitle/caption) and colour
# palette, mirroring the HomeOfficePNAD repo.
# =============================================================================

# Colour palette (semantic): for-profit = red, public = blue, secondary = grey/orange.
PAL <- c(red = "#C0392B", blue = "#2471A3", grey = "#616A6B",
         orange = "#E67E22", navy = "#2C3E50")

# ---------------------------------------------------------------------------
# NAMING CONVENTION for the two "private" populations, which are overlapping but
# not identical. Keep them lexically distinct everywhere in exhibits and prose:
#
#   SINASC  -> ownership of the birth ESTABLISHMENT (natureza juridica 2xxx).
#              Call it "for-profit" (vs "nonprofit", "public"). SINASC has no
#              payer flag, so it is NOT the private-insurance sector.
#   TISS    -> claims financed by PRIVATE INSURANCE, private by construction.
#              Call it the "private-insurance sector".
#
# Never write "private" bare as the name of the SINASC group, and never write
# "private for-profit", which conflates the payer and the ownership definitions.
# The `sector` column of the SINASC files stores the raw levels Private /
# Nonprofit / Public; relabel for display with sector_display().
# ---------------------------------------------------------------------------
SECTOR_LEVELS  <- c("Private", "Nonprofit", "Public")
SECTOR_DISPLAY <- c(Private = "For-profit", Nonprofit = "Nonprofit", Public = "Public")

sector_display <- function(x, levels = SECTOR_LEVELS) {
  levels <- intersect(levels, unique(as.character(x)))
  factor(unname(SECTOR_DISPLAY[as.character(x)]),
         levels = unname(SECTOR_DISPLAY[levels]))
}

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
SIGNIF_NOTE  <- "\\footnotesize Significance levels: *** p$<$0.01, ** p$<$0.05, * p$<$0.10."

# ---------------------------------------------------------------------------
# Helpers for hand-built multi-panel LaTeX tables (etable cannot stack panels).
# tex_coef() formats one coefficient as the pair (estimate with stars, SE);
# tex_row() lays a coefficient across a list of models, returning the two LaTeX
# lines. Models that do not contain `key` contribute empty cells.
# ---------------------------------------------------------------------------
tex_coef <- function(b, se, p, mult = 100, dig = 3) {
  if (length(b) == 0L || is.na(b)) return(c("", ""))
  stars <- if (p < 0.01) "$^{***}$" else if (p < 0.05) "$^{**}$" else
           if (p < 0.10) "$^{*}$" else ""
  c(paste0(formatC(mult * b, format = "f", digits = dig), stars),
    paste0("(", formatC(mult * se, format = "f", digits = dig), ")"))
}

tex_row <- function(label, models, key, mult = 100, dig = 3) {
  cells <- lapply(models, function(m) {
    if (is.null(m) || !key %in% rownames(fixest::coeftable(m))) return(c("", ""))
    ct <- fixest::coeftable(m)[key, ]
    tex_coef(ct[[1]], ct[[2]], ct[[4]], mult, dig)
  })
  c(paste0(label, " & ", paste(sapply(cells, `[`, 1), collapse = " & "), " \\\\"),
    paste0(" & ",        paste(sapply(cells, `[`, 2), collapse = " & "), " \\\\"),
    "\\addlinespace[2pt]")
}

# Row of observation counts across a list of models.
tex_nobs <- function(models, label = "Observations") {
  paste0(label, " & ", paste(sapply(models, function(m)
    formatC(stats::nobs(m), big.mark = ",", format = "d")), collapse = " & "), " \\\\")
}

# ---------------------------------------------------------------------------
#
# postprocess_tex(): cleans a fixest `etable()` LaTeX file into the project's
# house style (booktabs rules, no redundant SE/Signif footer, font-size + column
# spacing for wide tables). Call it right after each etable() that writes to
# `file`; pass the significance legend through etable's own `notes =` argument
# together with `signif.code = NA`.
# =============================================================================

# Bold the title inside a \caption, matching the figure house style. Handles the
# etable form \caption{\label{..} Title} and the plain \caption{Title}; idempotent
# (skips a caption that already contains \textbf).
bold_caption <- function(tx) {
  i <- grep("\\\\caption\\{", tx)
  for (k in i) {
    if (grepl("\\\\textbf", tx[k])) next
    if (grepl("\\\\caption\\{\\\\label\\{", tx[k])) {
      tx[k] <- sub("(\\\\caption\\{\\\\label\\{[^}]*\\}\\s*)(.*)\\}\\s*$",
                   "\\1\\\\textbf{\\2}}", tx[k])
    } else {
      tx[k] <- sub("\\\\caption\\{(.*)\\}\\s*$", "\\\\caption{\\\\textbf{\\1}}", tx[k])
    }
  }
  tx
}

# Standardize the fixed-effects block to the spelled-out row style used by the
# hand-built body tables ("Municipality fixed effects & Yes ...") instead of
# etable's default "\emph{Fixed-effects}" section header with bare dimension
# names. Removes the header line and appends " fixed effects" to each dimension
# row between it and the next rule. Idempotent (a row that already ends in
# "fixed effects" is left alone). Keeps the \emph{Variables} and
# \emph{Fit statistics} headers, which are self-consistent within the table.
standardize_fe <- function(tx) {
  out <- character(0); fe <- FALSE
  for (line in tx) {
    if (grepl("\\\\emph\\{Fixed-effects\\}", line)) { fe <- TRUE; next }
    if (fe) {
      if (grepl("\\\\midrule|\\\\bottomrule|\\\\end\\{tabular\\}", line)) {
        fe <- FALSE
      } else if (grepl("&", line) && !grepl("fixed effects", line)) {
        line <- sub("^(\\s*)([^&]*[^&\\s])(\\s*)&", "\\1\\2 fixed effects &", line, perl = TRUE)
      }
    }
    out <- c(out, line)
  }
  out
}

postprocess_tex <- function(file, fontsize = "\\small", tabcolsep = 4,
                            addspace = TRUE, resize = TRUE) {
  tx <- readLines(file)
  tx <- bold_caption(tx)
  tx <- standardize_fe(tx)
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
  tx <- resize_tabular(tx, resize, fontsize, tabcolsep)
  writeLines(tx, file)
}

# etable() escapes underscores everywhere in `notes`, including inside \ref{} and
# \eqref{}, which silently breaks any cross-reference to a label that contains one
# (e.g. tab:pooled_did). Call right after postprocess_tex() on any table whose note
# cites such a label.
unescape_refs <- function(file) {
  tx <- readLines(file)
  tx <- gsub("(\\\\(?:eq)?ref\\{[^}]*)\\\\_", "\\1_", tx)
  while (any(grepl("\\\\(eq)?ref\\{[^}]*\\\\_", tx)))       # labels with several "_"
    tx <- gsub("(\\\\(?:eq)?ref\\{[^}]*)\\\\_", "\\1_", tx)
  writeLines(tx, file)
}

# Wrap the tabular in a SHRINK-ONLY \resizebox so wide tables fit the text width
# but narrow tables keep their natural size (no ugly stretching). Also injects
# the font-size + column-spacing setting just before the tabular. Idempotent:
# does nothing if the file is already wrapped.
resize_tabular <- function(tx, resize = TRUE, fontsize = "\\small", tabcolsep = 4) {
  if (any(grepl("resizebox", tx, fixed = TRUE))) return(tx)
  i <- grep("\\begin{tabular}", tx, fixed = TRUE)[1]
  j <- grep("\\end{tabular}", tx, fixed = TRUE)
  j <- j[j >= i][1]
  if (is.na(i) || is.na(j)) return(tx)
  open <- paste0(fontsize, "\\setlength{\\tabcolsep}{", tabcolsep, "pt}")
  if (resize) open <- paste0(open,
    "\\resizebox{\\ifdim\\width>\\linewidth \\linewidth\\else\\width\\fi}{!}{%")
  tx <- append(tx, open, after = i - 1)      # before \begin{tabular} (index unshifted... use i)
  jj <- grep("\\end{tabular}", tx, fixed = TRUE); jj <- jj[jj > i][1]
  if (resize) tx <- append(tx, "}", after = jj)   # close \resizebox after \end{tabular}
  tx
}
