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
# REDUNDANT ENCODING: every series distinguished by colour also gets a line type.
# The palette itself is colour-vision safe (dichromat simulation, 2026-09-06:
# the closest pair that ever shares a figure is red/orange at Delta-E 24 under
# tritanopia, well above the ~10 confusion threshold), but red, blue and grey are
# near-isoluminant (relative luminance 0.143 / 0.148 / 0.139), so a photocopy or
# a greyscale printout of a colour-only line chart collapses the series into one.
# Map `linetype` to the SAME variable as `colour` and pass the series names in
# the SAME order as the colour scale: identical breaks and an empty title (see
# theme_paper) make ggplot merge the two guides into a single legend.
# Point-based panels (Figure 2b, Figure 3c) use `shape` for the same purpose.
# ---------------------------------------------------------------------------
LTY <- c("solid", "22", "44", "1343", "73")
lty_for <- function(nms) stats::setNames(LTY[seq_along(nms)], nms)

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

# ---------------------------------------------------------------------------
# FIGURE GEOMETRY — save at the size the figure is PRINTED at.
#
# paper.tex and supplement.tex are 12pt article with 1in margins, so the text
# block is exactly 6.5in wide and every figure is included at \textwidth. A
# figure saved wider than that is scaled DOWN by \includegraphics, and the
# scaling hits the type: a figure saved at 15in and printed at 6.5in renders its
# 10pt axis labels at 4.3pt on the page, which is what made Figures 2 and 3
# unreadable before 2026-07-27. Saving at FIG_WIDTH puts the PDF on the page at
# scale 1, so a point in the figure is a point on the page and the `base` size
# below is literally the size the reader sees. NEVER save a \textwidth figure
# wider than FIG_WIDTH: add a row instead of a column.
# ---------------------------------------------------------------------------
FIG_WIDTH <- 6.5

theme_paper <- function(base = 10) {
  ggplot2::theme_bw(base_size = base) +
    ggplot2::theme(
      legend.position    = "bottom",
      legend.title       = ggplot2::element_blank(),
      legend.text        = ggplot2::element_text(size = base),
      legend.key.width   = ggplot2::unit(0.9, "cm"),
      legend.margin      = ggplot2::margin(t = 0, b = 0),
      legend.box.spacing = ggplot2::unit(5, "pt"),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major   = ggplot2::element_line(colour = "grey92"),
      axis.text          = ggplot2::element_text(size = base - 1),
      axis.title         = ggplot2::element_text(size = base),
      strip.text         = ggplot2::element_text(size = base, face = "bold"),
      strip.background   = ggplot2::element_rect(fill = "grey94", colour = NA),
      plot.title         = ggplot2::element_blank(),
      plot.subtitle      = ggplot2::element_blank(),
      plot.caption       = ggplot2::element_blank(),
      plot.margin        = ggplot2::margin(2, 4, 2, 2)
    )
}

# Save a figure as both PDF and PNG (300 dpi), the repo convention. The default
# width is the printed width (see FIG_WIDTH above); only override it for a figure
# that is included at less than \textwidth, and then pass the printed width.
save_fig <- function(plot, name, width = FIG_WIDTH, height = 4) {
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
# postprocess_tex(): cleans a fixest `etable()` LaTeX file into the project's
# house style (booktabs rules, bold caption, no redundant SE/Signif footer,
# font-size + column spacing for wide tables). Call it right after each etable()
# that writes to `file`; pass the significance legend through etable's own
# `notes =` argument together with `signif.code = NA`. The helpers below
# (bold_caption / standardize_fe / resize_tabular / unescape_refs) are its steps.
# ---------------------------------------------------------------------------

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

# Clean etable's header block into the hand-built house style: drop the
# "Dependent Variables:" / "Model:" row labels, put the column-number row first
# (numbers, then outcome names), and remove the "\emph{Variables}" and
# "\emph{Fit statistics}" section headers. Idempotent.
clean_etable_header <- function(tx) {
  dep <- grep("^\\s*Dependent Variables?:\\s*&", tx)
  mod <- grep("^\\s*Model:\\s*&", tx)
  if (length(dep) == 1L && length(mod) == 1L && mod > dep) {
    tx[dep] <- sub("^\\s*Dependent Variables?:\\s*&", " &", tx[dep])
    modline <- sub("^\\s*Model:\\s*&", " &", tx[mod])
    tx <- append(tx[-mod], modline, after = dep - 1L)  # numbers row on top
  }
  tx[!grepl("^\\s*\\\\emph\\{(Variables|Fit statistics)\\}\\\\\\\\", tx)]
}

postprocess_tex <- function(file, fontsize = "\\small", tabcolsep = 4,
                            addspace = TRUE, resize = TRUE) {
  tx <- readLines(file)
  tx <- bold_caption(tx)
  tx <- standardize_fe(tx)
  tx <- clean_etable_header(tx)
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
  standardize_notes(file)
}

# ---------------------------------------------------------------------------
# standardize_notes(): one note style for every exhibit in both documents.
# A note emitted as a bare "\\[2pt]\footnotesize\textit{Notes:} ..." line, or
# behind a "\par \raggedright", sits directly in the float and inherits its
# \centering, so it prints centred line by line or ragged. This rewrites any of
# those forms into the canonical block
#
#   \begin{minipage}{\linewidth}\footnotesize
#   \textit{Notes:} ...
#   \end{minipage}
#
# a JUSTIFIED block at the FULL width of the text column: the minipage's
# \@parboxrestore cancels the float's \centering, so the note is justified
# instead of centred. Idempotent (a file that already carries a minipage is left
# alone); runs inside postprocess_tex() and inside write_table_tex(). The figure
# notes match it through \fignotes in paper.tex / supplement.tex.
#
# HISTORY, so this is not flipped again by accident. This is the MONASTERIO form
# and it is what the project uses. Until 2026-09-04 the notes were an
# unstandardized mixture, which is exactly what Monasterio flagged on the sibling
# WorldCupHealth paper ("padronizar o alinhamento das notas... tem umas que estao
# desalinhadas, nao justificadas"), and the fix there and here was this full-width
# justified block. On 2026-09-07 it was briefly changed to a narrower centred
# block, because a one-line note at full width sits flush left under a centred
# caption and reads as misaligned, and REVERTED the same day at Fredie's request.
# Do not narrow it, do not wrap it in \centerline, and do not re-add \centering.
# ---------------------------------------------------------------------------
NOTE_OPEN  <- "\\begin{minipage}{\\linewidth}\\footnotesize"
NOTE_CLOSE <- "\\end{minipage}"

standardize_notes <- function(file) {
  if (!file.exists(file)) return(invisible(file))
  tx <- readLines(file, warn = FALSE)
  if (any(grepl("\\begin{minipage}", tx, fixed = TRUE))) return(invisible(file))
  i <- grep("\\textit{Notes:}", tx, fixed = TRUE)
  if (!length(i)) return(invisible(file))
  i <- i[1L]
  j <- grep("^\\s*\\\\end\\{(sideways)?table\\}", tx)
  j <- j[j > i][1L]
  if (is.na(j)) j <- length(tx) + 1L
  blk <- tx[i:(j - 1L)]
  blk[1L] <- sub("\\\\[2pt]", "", blk[1L], fixed = TRUE)   # bare line break
  blk[1L] <- sub("\\footnotesize", "", blk[1L], fixed = TRUE)
  blk[1L] <- trimws(blk[1L], which = "left")
  k <- i - 1L                                              # drop "\par \raggedright"
  while (k >= 1L && grepl("^\\s*(\\\\par\\s*|\\\\raggedright\\s*)*$", tx[k])) k <- k - 1L
  writeLines(c(tx[seq_len(k)], NOTE_OPEN, blk, NOTE_CLOSE,
               tx[j:length(tx)]), file)
  invisible(file)
}

# Write a hand-built table and put its note in the canonical block. Use this
# instead of writeLines() for every .tex table, so a re-run cannot revert the
# note style.
write_table_tex <- function(tx, file) {
  writeLines(tx, file)
  standardize_notes(file)
  invisible(file)
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
