# Generate Markdown Report for Score Correction Analysis
#
# Creates a report with transition tables organized by Subject > Grade > Year

library(here)
library(haven)
library(ggplot2)

# Set UTF-8 encoding for Norwegian characters
Sys.setlocale("LC_ALL", "en_US.UTF-8")

# Source existing modules
source(here("R", "config.R"), encoding = "UTF-8")
source(here("R", "correction_functions.R"), encoding = "UTF-8")
source(here("R", "mastery_levels.R"), encoding = "UTF-8")

# Create plots directory
dir.create(here("output", "plots", "transformations"), showWarnings = FALSE, recursive = TRUE)

# Function to create transformation plot
create_transformation_plot <- function(subj, grade, yr) {
  # Get parameters
  params <- rescaling_params[subject == subj & grade_level == grade & year == yr]

  if (nrow(params) == 0) return(NULL)

  slope <- params$sd_new / params$sd_old
  intercept <- params$mean_new - slope * params$mean_old

  # Get cutoffs for this grade (from centralized config)
  all_cutoffs <- get_cutoffs(subj, grade)
  cutoffs <- all_cutoffs[is.finite(all_cutoffs)]  # Remove -Inf and Inf for plotting

  # Build rectangles based on number of levels
  n_levels <- length(cutoffs) + 1
  bounds <- c(15, cutoffs, 85)

  # No change rectangles (diagonal)
  no_change_rects <- data.frame(
    xmin = bounds[1:n_levels],
    xmax = bounds[2:(n_levels+1)],
    ymin = bounds[1:n_levels],
    ymax = bounds[2:(n_levels+1)],
    type = "no_change"
  )

  # Upgrade rectangles (above diagonal)
  upgrade_list <- list()
  for (i in 1:(n_levels-1)) {
    for (j in (i+1):n_levels) {
      upgrade_list[[length(upgrade_list)+1]] <- data.frame(
        xmin = bounds[i], xmax = bounds[i+1],
        ymin = bounds[j], ymax = bounds[j+1],
        type = "upgrade"
      )
    }
  }
  upgrade_rects <- do.call(rbind, upgrade_list)

  # Downgrade rectangles (below diagonal)
  downgrade_list <- list()
  for (i in 2:n_levels) {
    for (j in 1:(i-1)) {
      downgrade_list[[length(downgrade_list)+1]] <- data.frame(
        xmin = bounds[i], xmax = bounds[i+1],
        ymin = bounds[j], ymax = bounds[j+1],
        type = "downgrade"
      )
    }
  }
  downgrade_rects <- do.call(rbind, downgrade_list)

  all_rects <- rbind(no_change_rects, upgrade_rects, downgrade_rects)

  # Determine plot limits
  xlim <- if (grade == 5) c(30, 70) else c(25, 75)
  ylim <- xlim

  # Create plot
  p <- ggplot() +
    geom_rect(data = all_rects,
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = type),
              alpha = 0.4) +
    scale_fill_manual(values = c("no_change" = "grey70",
                                  "upgrade" = "#5a8a4a",
                                  "downgrade" = "#a65c5c"),
                      guide = "none") +
    geom_vline(xintercept = cutoffs, linetype = "dashed", color = "grey30", alpha = 0.7) +
    geom_hline(yintercept = cutoffs, linetype = "dashed", color = "grey30", alpha = 0.7) +
    geom_abline(intercept = 0, slope = 1, linewidth = 1, linetype = "dashed", color = "red", alpha = 0.7) +
    geom_abline(intercept = intercept, slope = slope, linewidth = 1.5, color = "black") +
    labs(
      title = sprintf("%s Grade %d, %d", subj, grade, yr),
      subtitle = sprintf("y = %.3fx + %.2f", slope, intercept),
      x = "Original Score",
      y = "Corrected Score"
    ) +
    coord_fixed(ratio = 1, xlim = xlim, ylim = ylim) +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold", size = 10),
          plot.subtitle = element_text(size = 8))

  # Save plot
  filename <- sprintf("transform_%s_%d_%d.png", subj, grade, yr)
  filepath <- here("output", "plots", "transformations", filename)
  ggsave(filepath, p, width = 5, height = 5, dpi = 150)

  return(filename)
}

cat("Loading and processing data...\n")

# Load data (exclude 2022 - different regime with integer scores)
data_raw <- as.data.table(read_dta(here("data", "npole.dta")))
data_raw <- data_raw[year >= 2014 & year <= 2021]

# Prepare data
data <- copy(data_raw)
data[, subject := fcase(
  fag == "LES", "NOR",
  fag == "REG", "MATH",
  fag == "ENG", "ENG"
)]
setnames(data, "trinn", "grade_level")
setnames(data, "skalapoeng", "score")

# Filter to correction period and apply corrections
data_analysis <- data[year >= 2014 & year <= 2021 & !is.na(score)]
data_analysis <- correct_scores_dt(data_analysis)

# Calculate levels using our cutoffs for BOTH old and new scores (fair comparison)
data_analysis[, level_old := NA_integer_]
data_analysis[, level_new := NA_integer_]

combos <- unique(data_analysis[, .(subject, grade_level)])
for (i in seq_len(nrow(combos))) {
  subj <- combos$subject[i]
  grade <- combos$grade_level[i]
  idx <- data_analysis$subject == subj & data_analysis$grade_level == grade
  data_analysis[idx, level_old := assign_mastery_level(score, subj, grade)]
  data_analysis[idx, level_new := assign_mastery_level(score_corrected, subj, grade)]
}

# Subject names for display
subject_names <- c(
  "ENG" = "English (Engelsk)",
  "MATH" = "Mathematics (Regning)",
  "NOR" = "Reading (Lesing)"
)

# Function to create markdown table from transition matrix
create_md_table <- function(trans_dt, grade) {
  if (nrow(trans_dt) == 0) return("")

  # Determine number of levels
  n_levels <- if (grade == 5) 3 else 5

  # Create wide format
  trans_wide <- dcast(trans_dt, level_old ~ level_new, value.var = "N", fill = 0)

  # Ensure all levels present
  for (lvl in 1:n_levels) {
    if (!(lvl %in% names(trans_wide))) {
      trans_wide[, (as.character(lvl)) := 0L]
    }
  }

  # Reorder columns
  col_order <- c("level_old", as.character(1:n_levels))
  trans_wide <- trans_wide[, ..col_order]

  # Add row totals
  trans_wide[, Total := rowSums(.SD), .SDcols = as.character(1:n_levels)]

  # Build markdown table
  header <- paste0("| Original | ", paste(paste0("Level ", 1:n_levels), collapse = " | "), " | Total |")
  separator <- paste0("|", paste(rep("---:", n_levels + 2), collapse = "|"), "|")

  rows <- sapply(1:nrow(trans_wide), function(i) {
    row_data <- trans_wide[i]
    values <- c(
      paste0("Level ", row_data$level_old),
      format(unlist(row_data[, as.character(1:n_levels), with = FALSE]), big.mark = ","),
      format(row_data$Total, big.mark = ",")
    )
    paste0("| ", paste(values, collapse = " | "), " |")
  })

  paste(c(header, separator, rows), collapse = "\n")
}

# Generate report
report_lines <- c(
  "# Score Correction Impact Report",
  "",
  "## Overview",
  "",
  "This report shows how applying the SSB score corrections affects student competence level classifications.",
  "Each table shows the transition from original levels (rows) to corrected levels (columns).",
  "",
  sprintf("**Analysis period:** 2014-2021"),
  sprintf("**Total observations:** %s", format(nrow(data_analysis), big.mark = ",")),
  "",
  "### Impact Summary",
  "",
  "The figure below shows the share of pupils whose competence level assignment changed after correction,",
  "by subject and grade level over time.",
  "",
  "![Share of pupils with changed levels](plots/shift_summary_facet.png)",
  ""
)

# Process by Subject > Grade > Year
for (subj in c("ENG", "MATH", "NOR")) {
  subj_name <- subject_names[subj]
  report_lines <- c(report_lines, "", paste0("# ", subj_name), "")

  subj_data <- data_analysis[subject == subj]

  for (grade in c(5, 8)) {
    grade_data <- subj_data[grade_level == grade]

    if (nrow(grade_data) == 0) next

    report_lines <- c(report_lines, "", paste0("## Grade ", grade, " (", grade, ". trinn)"), "")

    # Add discrepancy overview plot
    discrepancy_plot <- sprintf("discrepancy_%s_%d.png", subj, grade)
    report_lines <- c(
      report_lines,
      "### Score Ranges with Level Changes",
      "",
      "The figure below shows which score ranges resulted in different competence level assignments after correction.",
      "Green segments indicate scores that were upgraded; red segments indicate downgrades.",
      "",
      sprintf("![Discrepancy ranges](plots/discrepancy_ranges/%s)", discrepancy_plot),
      "",
      "---",
      ""
    )

    years <- sort(unique(grade_data$year))

    for (yr in years) {
      year_data <- grade_data[year == yr & !is.na(level_old) & !is.na(level_new)]

      if (nrow(year_data) == 0) next

      # Calculate statistics
      n_total <- nrow(year_data)
      n_shifted <- sum(year_data$level_old != year_data$level_new)
      n_up <- sum(year_data$level_new > year_data$level_old)
      n_down <- sum(year_data$level_new < year_data$level_old)

      pct_shifted <- round(100 * n_shifted / n_total, 2)
      pct_up <- round(100 * n_up / n_total, 2)
      pct_down <- round(100 * n_down / n_total, 2)

      # Create transition table
      trans <- year_data[, .N, by = .(level_old, level_new)]
      md_table <- create_md_table(trans, grade)

      # Create transformation plot
      plot_filename <- create_transformation_plot(subj, grade, yr)

      # Add to report
      report_lines <- c(
        report_lines,
        paste0("### ", yr),
        "",
        sprintf("![Transformation plot](plots/transformations/%s)", plot_filename),
        "",
        md_table,
        "",
        sprintf("**Total test-takers:** %s", format(n_total, big.mark = ",")),
        sprintf("- **Shifted level:** %s (%s%%)", format(n_shifted, big.mark = ","), pct_shifted),
        sprintf("- **Shifted up:** %s (%s%%)", format(n_up, big.mark = ","), pct_up),
        sprintf("- **Shifted down:** %s (%s%%)", format(n_down, big.mark = ","), pct_down),
        ""
      )
    }
  }
}

# Add summary section
overall_stats <- data_analysis[!is.na(level_old) & !is.na(level_new), .(
  n_total = .N,
  n_shifted = sum(level_old != level_new),
  n_up = sum(level_new > level_old),
  n_down = sum(level_new < level_old)
)]

report_lines <- c(
  report_lines,
  "",
  "# Summary",
  "",
  sprintf("**Total students analyzed:** %s", format(overall_stats$n_total, big.mark = ",")),
  sprintf("- **Total shifted:** %s (%s%%)",
          format(overall_stats$n_shifted, big.mark = ","),
          round(100 * overall_stats$n_shifted / overall_stats$n_total, 2)),
  sprintf("- **Shifted up:** %s (%s%%)",
          format(overall_stats$n_up, big.mark = ","),
          round(100 * overall_stats$n_up / overall_stats$n_total, 2)),
  sprintf("- **Shifted down:** %s (%s%%)",
          format(overall_stats$n_down, big.mark = ","),
          round(100 * overall_stats$n_down / overall_stats$n_total, 2)),
  ""
)

# Write report
output_path <- here("output", "score_correction_report.md")
writeLines(report_lines, output_path)

cat(sprintf("\nMarkdown report saved to: %s\n", output_path))

# Generate PDF using pandoc
pdf_path <- here("output", "score_correction_report.pdf")
header_path <- here("output", "header.tex")

# Check if pandoc is available
pandoc_available <- system("which pandoc", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0

if (pandoc_available) {
  cat("Generating PDF report...\n")

  # Build pandoc command (--resource-path tells pandoc where to find images)
  output_dir <- here("output")
  pandoc_cmd <- sprintf(
    'pandoc "%s" -o "%s" --pdf-engine=pdflatex -H "%s" -V geometry:margin=1in --resource-path="%s"',
    output_path, pdf_path, header_path, output_dir
  )

  # Run pandoc
  result <- system(pandoc_cmd, ignore.stdout = FALSE, ignore.stderr = FALSE)

  if (result == 0) {
    cat(sprintf("PDF report saved to: %s\n", pdf_path))
  } else {
    cat("Warning: PDF generation failed. Check that pdflatex is installed.\n")
    cat("You can manually convert using: pandoc output/score_correction_report.md -o output/score_correction_report.pdf\n")
  }
} else {
  cat("Note: pandoc not found. PDF not generated.\n")
  cat("Install pandoc to enable PDF generation: https://pandoc.org/installing.html\n")
}
