# Threshold Identification Script
#
# Empirically identifies the cutpoints used to map skalapoeng to mestringsnivå
# in the npole data file for the period 2014-2021.

library(here)
library(haven)
library(data.table)
library(ggplot2)

Sys.setlocale("LC_ALL", "en_US.UTF-8")

dir.create(here("output", "threshold_identification"), showWarnings = FALSE,
           recursive = TRUE)

# ============================================================================
# Load and prepare data
# ============================================================================

cat("Loading data...\n")
data <- as.data.table(read_dta(here("data", "npole.dta")))
data <- data[year >= 2014 & year <= 2021 & !is.na(skalapoeng) & skalapoeng >= 10]

setnames(data, c("trinn", "skalapoeng", "mestring", "fag"),
         c("grade", "score", "level", "subject"))
data[, subject := fcase(subject == "LES", "NOR",
                        subject == "REG", "MATH",
                        subject == "ENG", "ENG")]

cat(sprintf("Loaded %s records (2014-2021)\n", format(nrow(data), big.mark = ",")))

# ============================================================================
# Target percentiles from Udir documentation
# ============================================================================

target_percentiles <- data.table(
  grade = c(rep(5, 2), rep(8, 4)),
  threshold_idx = c(1, 2, 1, 2, 3, 4),
  target_pctl = c(25, 75, 10, 30, 70, 90)
)

first_years <- data.table(
  subject = c("ENG", "ENG", "MATH", "MATH", "NOR", "NOR"),
  grade = c(5, 8, 5, 8, 5, 8),
  first_year = c(2014, 2014, 2014, 2014, 2014, 2014)
)

# ============================================================================
# Identify threshold boundaries per year
# ============================================================================

cat("Identifying threshold boundaries...\n")

find_boundaries <- function(dt) {
  results <- list()
  for (yr in 2014:2021) {
    for (subj in c("ENG", "MATH", "NOR")) {
      for (gr in c(5, 8)) {
        subset <- dt[year == yr & subject == subj & grade == gr]
        levels <- sort(unique(subset$level))
        for (i in seq_len(length(levels) - 1)) {
          lower_lvl <- levels[i]
          upper_lvl <- levels[i + 1]
          lower_scores <- subset[level == lower_lvl, score]
          upper_scores <- subset[level == upper_lvl, score]
          if (length(lower_scores) > 0 && length(upper_scores) > 0) {
            results[[length(results) + 1]] <- data.table(
              year = yr, subject = subj, grade = gr, threshold_idx = i,
              lower_level = lower_lvl, upper_level = upper_lvl,
              lower_max = max(lower_scores), upper_min = min(upper_scores)
            )
          }
        }
      }
    }
  }
  rbindlist(results)
}

boundaries <- find_boundaries(data)
boundaries[, threshold := round(upper_min * 2) / 2]
boundaries[abs(upper_min - threshold) > 0.1, threshold := round(upper_min)]

# ============================================================================
# Percentile analysis for first year
# ============================================================================

cat("Calculating percentile analysis...\n")

calculate_percentile_info <- function(dt, subj, gr) {
  first_yr <- first_years[subject == subj & grade == gr, first_year]
  subset <- dt[subject == subj & grade == gr & year == first_yr]
  n_thresholds <- ifelse(gr == 5, 2, 4)
  results <- list()
  for (tidx in seq_len(n_thresholds)) {
    target_pctl <- target_percentiles[grade == gr & threshold_idx == tidx,
                                       target_pctl]
    target_score <- quantile(subset$score, probs = target_pctl / 100, type = 7)
    actual_threshold <- boundaries[subject == subj & grade == gr &
                                     year == first_yr & threshold_idx == tidx,
                                   threshold]
    actual_pctl <- 100 * mean(subset$score < actual_threshold)
    lower_lvl <- boundaries[subject == subj & grade == gr &
                              year == first_yr & threshold_idx == tidx,
                            lower_level]
    upper_lvl <- boundaries[subject == subj & grade == gr &
                              year == first_yr & threshold_idx == tidx,
                            upper_level]
    results[[length(results) + 1]] <- data.table(
      subject = subj, grade = gr, first_year = first_yr,
      threshold_idx = tidx, lower_level = lower_lvl, upper_level = upper_lvl,
      target_pctl = target_pctl,
      target_score = round(as.numeric(target_score), 2),
      actual_threshold = actual_threshold, actual_pctl = round(actual_pctl, 1)
    )
  }
  rbindlist(results)
}

percentile_analysis <- rbindlist(lapply(c("ENG", "MATH", "NOR"), function(subj) {
  rbindlist(lapply(c(5, 8), function(gr) {
    calculate_percentile_info(data, subj, gr)
  }))
}))

# ============================================================================
# Create percentile calibration figure
# ============================================================================

cat("Creating percentile calibration figure...\n")

subject_labels <- c(ENG = "English", MATH = "Mathematics", NOR = "Reading")
percentile_analysis[, subject_label := subject_labels[subject]]

# Create the plot
pctl_plot <- ggplot(percentile_analysis,
                    aes(x = target_pctl, y = actual_pctl, color = subject_label)) +
  # 45-degree reference line (perfect calibration)
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey40") +
  # Vertical lines at target percentiles
  geom_vline(data = target_percentiles,
             aes(xintercept = target_pctl),
             linetype = "dotted", color = "grey60", alpha = 0.7) +
  # Points for actual percentiles
  geom_point(size = 3) +
  # Facet by grade
  facet_wrap(~ paste("Grade", grade), scales = "fixed") +
  # Labels
  labs(
    title = "Threshold Calibration: Target vs. Actual Percentiles",
    subtitle = "First year (2014) - Points on the dashed line indicate perfect calibration",
    x = "Target Percentile",
    y = "Actual Percentile",
    color = "Subject"
  ) +
  scale_x_continuous(breaks = c(10, 25, 30, 50, 70, 75, 90), limits = c(0, 100)) +
  scale_y_continuous(breaks = c(10, 25, 30, 50, 70, 75, 90), limits = c(0, 100)) +
  scale_color_manual(values = c("English" = "#1b9e77", "Mathematics" = "#d95f02",
                                "Reading" = "#7570b3")) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 11)
  ) +
  coord_fixed(ratio = 1)

# Save the figure
fig_path <- here("output", "threshold_identification", "percentile_calibration.png")
ggsave(fig_path, pctl_plot, width = 8, height = 5, dpi = 150)
cat(sprintf("Figure saved: %s\n", fig_path))

# ============================================================================
# Create regime summary - fix year range display
# ============================================================================

format_year_range <- function(years_vec) {
  years <- sort(unique(years_vec))
  if (length(years) == 1) return(as.character(years))
  if (length(years) == 8 && all(years == 2014:2021)) return("2014-2021")

  groups <- list()
  current_group <- years[1]

  for (i in 2:length(years)) {
    if (years[i] == years[i - 1] + 1) {
      current_group <- c(current_group, years[i])
    } else {
      groups[[length(groups) + 1]] <- current_group
      current_group <- years[i]
    }
  }
  groups[[length(groups) + 1]] <- current_group

  formatted <- sapply(groups, function(g) {
    if (length(g) == 1) {
      as.character(g)
    } else if (length(g) == 2) {
      paste(g, collapse = ", ")
    } else {
      sprintf("%d-%d", min(g), max(g))
    }
  })

  paste(formatted, collapse = ", ")
}

threshold_regimes <- boundaries[, .(
  years_list = list(year),
  year_start = min(year),
  year_end = max(year),
  n_years = .N
), by = .(subject, grade, threshold_idx, lower_level, upper_level, threshold)]

threshold_regimes[, year_range := sapply(years_list, format_year_range)]

setorder(threshold_regimes, subject, grade, threshold_idx, year_start)

# ============================================================================
# Generate Markdown report
# ============================================================================

cat("Generating report...\n")

# Short names for tables to avoid line breaks
subject_names_short <- c(ENG = "English", MATH = "Mathematics", NOR = "Reading")
# Full names with Norwegian for section headers
subject_names_full <- c(ENG = "English (Engelsk)", MATH = "Mathematics (Regning)",
                        NOR = "Reading (Lesing)")

report <- c(
  "---",
  'title: "Threshold Identification Report"',
  'subtitle: "Cutpoints for mestringsnivå classification (2014-2021)"',
  "geometry: margin=0.75in",
  "fontsize: 10pt",
  "---",
  "",
  "# Overview",
  "",
  "This report documents the cutpoints (thresholds) used to map skalapoeng",
  "(scale scores) to mestringsnivå (mastery levels) in the Norwegian national",
  "tests for the period 2014-2021. The report does three things:",
  "",
  "**1. Assesses first-year threshold calibration against Udir documentation.**",
  "According to Udir, thresholds were set in each test series' first year to",
  "achieve specific percentile distributions: 25-50-25% for Grade 5 (three levels)",
  "and 10-20-40-20-10% for Grade 8 (five levels). We calculate what percentile",
  "each threshold actually corresponds to in the first-year score distribution.",
  "Note: The register data from Statistics Norway may not cover the exact sample",
  "used to set the original cutpoints, so small discrepancies are expected.",
  "Overall, the thresholds appear to be set in accordance with the stated methodology.",
  "",
  "**2. Identifies the cutpoints actually deployed in each year.**",
  "Using register data on loan from Statistics Norway, we identify the exact",
  "thresholds by finding the score boundaries between adjacent mastery levels.",
  "For each threshold, we find the highest score assigned to the lower level",
  "(lower_max) and the lowest score assigned to the higher level (upper_min).",
  "Since scores have 3-decimal precision, this precisely identifies cutpoints.",
  "Consistent threshold mapping was found for English (both grades) and Mathematics",
  "Grade 5. Mathematics Grade 8 had two regimes (2014 used integer cutpoints,",
  "2015-2021 used half-point cutpoints). Reading Grade 5 had two regimes (threshold",
  "change in 2016), while Reading Grade 8 had three distinct regimes (2014, 2015,",
  "2016-2021) due to an anomalous 2015.",
  "",
  "**3. Provides detailed year-by-year threshold tables.**",
  "The final section includes complete tables showing exact threshold values for",
  "each year, along with guidance on how to use these cutpoints to assign",
  "mestringsnivå from skalapoeng scores.",
  "",
  "# Methodology",
  "",
  "## Threshold Setting Process (per Udir documentation)",
  "",
  "According to Udir, thresholds were set in the first test year to achieve",
  "the following percentile distributions:",
  "",
  "- **Grade 5**: 25% – 50% – 25% (Levels 1, 2, 3)",
  "- **Grade 8**: 10% – 20% – 40% – 20% – 10% (Levels 1, 2, 3, 4, 5)",
  "",
  "Target percentiles for each threshold:",
  "",
  "| Grade | Threshold | Lower → Upper | Target Percentile |",
  "|:-----:|:---------:|:-------------:|:-----------------:|",
  "| 5 | 1 | 1 → 2 | 25th |",
  "| 5 | 2 | 2 → 3 | 75th |",
  "|   |   |       |      |",
  "| 8 | 1 | 1 → 2 | 10th |",
  "| 8 | 2 | 2 → 3 | 30th |",
  "| 8 | 3 | 3 → 4 | 70th |",
  "| 8 | 4 | 4 → 5 | 90th |",
  "",
  "## Empirical Identification",
  "",
  "For each year × subject × grade × threshold, we identify:",
  "",
  "1. **lower_max**: Maximum score among students at the lower level",
  "2. **upper_min**: Minimum score among students at the higher level",
  "",
  "Classification rule: `score >= threshold → higher level`",
  "",
  "\\newpage",
  "",
  "# Percentile Analysis: First Year (2014)",
  "",
  "Comparing target vs. actual percentiles for first year thresholds.",
  "",
  "![Threshold Calibration](percentile_calibration.png)",
  "",
  "*Figure: Target percentiles (x-axis) vs. actual percentiles (y-axis) for each",
  "threshold in the first year. Points on the dashed 45° line indicate perfect",
  "calibration to the documented targets.*",
  ""
)

# Add percentile analysis tables - combined for each grade
for (gr in c(5, 8)) {
  report <- c(report, sprintf("## Grade %d", gr), "")

  report <- c(report,
    "| Subject | Nivå- | Nivå+ | Target Percentile | Actual Percentile* | Score at Target | Actual Cutpoint* |",
    "|:------------|:-----:|:-----:|:-----------------:|:------------------:|:---------------:|:----------------:|"
  )

  for (subj in c("ENG", "MATH", "NOR")) {
    pctl_data <- percentile_analysis[subject == subj & grade == gr]

    for (i in seq_len(nrow(pctl_data))) {
      row <- pctl_data[i]
      subj_label <- ifelse(i == 1, subject_names_short[subj], "")
      report <- c(report,
        sprintf("| %s | %d | %d | %d%% | %.1f%% | %.2f | %.1f |",
                subj_label, row$lower_level, row$upper_level,
                row$target_pctl, row$actual_pctl,
                row$target_score, row$actual_threshold)
      )
    }
  }

  # Add footnote after each table
  report <- c(report, "",
    "*\\* Assessed using register data on loan from Statistics Norway.*",
    ""
  )
}

report <- c(report, "\\newpage", "", "# Cutpoint Tables by Subject", "",
  "*Note: In tables with multiple time periods, values that changed relative to",
  "the previous period are shown in **bold**.*",
  ""
)

# Helper function to get threshold value for a specific year
get_threshold_for_year <- function(bounds_dt, subj, gr, tidx, yr) {
  val <- bounds_dt[subject == subj & grade == gr & threshold_idx == tidx & year == yr, threshold]
  if (length(val) > 0) val else NA
}

# Generate cutpoint tables with regime columns
for (gr in c(5, 8)) {
  report <- c(report, sprintf("## Grade %d", gr), "")

  for (subj in c("ENG", "MATH", "NOR")) {
    subj_data <- threshold_regimes[subject == subj & grade == gr]
    subj_bounds <- boundaries[subject == subj & grade == gr]
    n_thresholds <- ifelse(gr == 5, 2, 4)

    report <- c(report, sprintf("### %s", subject_names_full[subj]), "")

    single_regime <- nrow(subj_data) == n_thresholds && all(subj_data$n_years == 8)

    if (single_regime) {
      # All thresholds stable across all years - simple table
      report <- c(report,
        "| Nivå- | Nivå+ | 2014-2021 |",
        "|:-----:|:-----:|:---------:|"
      )

      for (tidx in seq_len(n_thresholds)) {
        row <- subj_data[threshold_idx == tidx]
        report <- c(report,
          sprintf("| %d | %d | %.1f |",
                  row$lower_level[1], row$upper_level[1], row$threshold[1])
        )
      }
    } else {
      # Multi-regime: find years where ANY threshold changed
      # Get threshold values for each year
      year_values <- list()
      for (yr in 2014:2021) {
        vals <- sapply(seq_len(n_thresholds), function(tidx) {
          get_threshold_for_year(subj_bounds, subj, gr, tidx, yr)
        })
        year_values[[as.character(yr)]] <- vals
      }

      # Find breakpoints where values change
      breakpoint_years <- c(2014)  # Always start with first year
      for (yr in 2015:2021) {
        prev_vals <- year_values[[as.character(yr - 1)]]
        curr_vals <- year_values[[as.character(yr)]]
        if (any(abs(curr_vals - prev_vals) > 0.01, na.rm = TRUE)) {
          breakpoint_years <- c(breakpoint_years, yr)
        }
      }

      # Create period labels from breakpoints
      period_labels <- character()
      period_start_years <- integer()
      for (i in seq_along(breakpoint_years)) {
        start_yr <- breakpoint_years[i]
        if (i < length(breakpoint_years)) {
          end_yr <- breakpoint_years[i + 1] - 1
        } else {
          end_yr <- 2021
        }

        if (start_yr == end_yr) {
          period_labels <- c(period_labels, as.character(start_yr))
        } else {
          period_labels <- c(period_labels, sprintf("%d-%d", start_yr, end_yr))
        }
        period_start_years <- c(period_start_years, start_yr)
      }

      # Build header
      header <- paste(c("| Nivå- | Nivå+",
                        sapply(period_labels, function(p) sprintf("| %s ", p)),
                        "|"), collapse = "")
      sep <- paste(c("|:-----:|:-----:",
                     rep("|:---------:", length(period_labels)),
                     "|"), collapse = "")

      report <- c(report, header, sep)

      # For each threshold, get value for each period
      for (tidx in seq_len(n_thresholds)) {
        lower_lvl <- subj_data[threshold_idx == tidx, lower_level][1]
        upper_lvl <- subj_data[threshold_idx == tidx, upper_level][1]

        prev_val <- NULL
        vals <- sapply(seq_along(period_start_years), function(i) {
          yr <- period_start_years[i]
          val <- get_threshold_for_year(subj_bounds, subj, gr, tidx, yr)

          # Format: bold if changed from previous
          if (is.na(val)) {
            formatted <- "-"
          } else if (is.null(prev_val) || i == 1) {
            formatted <- sprintf("%.1f", val)
          } else if (abs(val - prev_val) > 0.01) {
            formatted <- sprintf("**%.1f**", val)
          } else {
            formatted <- sprintf("%.1f", val)
          }

          prev_val <<- val
          formatted
        })

        row_str <- sprintf("| %d | %d | %s |", lower_lvl, upper_lvl,
                           paste(vals, collapse = " | "))
        report <- c(report, row_str)
      }
    }

    report <- c(report, "")
  }
}

# Detailed year-by-year
report <- c(report, "\\newpage", "",
  "# Detailed Year-by-Year Thresholds", "",
  "Exact upper_min values. Small variations (42.500 vs 42.501) reflect",
  "measurement precision, not actual threshold differences.", ""
)

for (gr in c(5, 8)) {
  report <- c(report, sprintf("## Grade %d", gr), "")

  for (subj in c("ENG", "MATH", "NOR")) {
    report <- c(report, sprintf("### %s", subject_names_full[subj]), "")

    subj_bounds <- boundaries[subject == subj & grade == gr]
    n_thresholds <- ifelse(gr == 5, 2, 4)

    header <- "| Lower | Upper | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 |"
    sep <- "|:-----:|:-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|"

    report <- c(report, header, sep)

    for (tidx in seq_len(n_thresholds)) {
      thresh_data <- subj_bounds[threshold_idx == tidx]
      lower_lvl <- thresh_data$lower_level[1]
      upper_lvl <- thresh_data$upper_level[1]

      vals <- sapply(2014:2021, function(yr) {
        val <- thresh_data[year == yr, upper_min]
        if (length(val) > 0) sprintf("%.2f", val) else "-"
      })

      report <- c(report,
        sprintf("| %d | %d | %s |", lower_lvl, upper_lvl, paste(vals, collapse = " | "))
      )
    }

    report <- c(report, "")
  }
}

# Key findings
report <- c(report, "\\newpage", "", "# Key Findings", "",
  "1. **Score precision**: Skalapoeng values have 3-decimal precision",
  "",
  "2. **Clean separation**: All level boundaries have positive gaps",
  "",
  "3. **Threshold format**: Most thresholds are at X.5 (e.g., 42.5, 56.5)",
  "",
  "4. **Notable threshold changes**:",
  "   - NOR Grade 5 Level 2→3: 56.5 to 57.5 starting 2016",
  "   - NOR Grade 8 Level 1→2: 36.5 to 37.5 starting 2016",
  "   - NOR Grade 8 Level 2→3: 44.5 in 2015, otherwise 43.5",
  "   - MATH Grade 8 2014: Integer thresholds (37, 45, 55, 63)",
  "",
  "# How to Use These Thresholds",
  "",
  "```",
  "Grade 5 (3 levels):              Grade 8 (5 levels):",
  "  Level 1: score < threshold_1     Level 1: score < threshold_1",
  "  Level 2: t1 <= score < t2        Level 2: t1 <= score < t2",
  "  Level 3: score >= threshold_2    Level 3: t2 <= score < t3",
  "                                   Level 4: t3 <= score < t4",
  "                                   Level 5: score >= threshold_4",
  "```",
  "",
  "Published Udir thresholds are integers (43, 57). Empirical thresholds",
  "are 0.5 below (42.5, 56.5) - Udir rounds up for communication.",
  ""
)

# Write markdown
md_path <- here("output", "threshold_identification", "threshold_report.md")
writeLines(report, md_path)
cat(sprintf("Markdown saved: %s\n", md_path))

# Generate PDF with pandoc
pandoc_available <- system("which pandoc", ignore.stdout = TRUE,
                           ignore.stderr = TRUE) == 0

if (pandoc_available) {
  cat("Generating PDF...\n")

  pdf_path <- here("output", "threshold_identification", "threshold_report.pdf")
  resource_path <- here("output", "threshold_identification")

  cmd <- sprintf(
    'pandoc "%s" -o "%s" --pdf-engine=pdflatex -V geometry:margin=0.75in --resource-path="%s"',
    md_path, pdf_path, resource_path
  )

  result <- system(cmd, ignore.stdout = FALSE, ignore.stderr = FALSE)

  if (result == 0) {
    cat(sprintf("PDF saved: %s\n", pdf_path))
  } else {
    cat("PDF generation failed.\n")
  }
}

# Save data
fwrite(boundaries,
       here("output", "threshold_identification", "boundaries_raw.csv"))
fwrite(threshold_regimes,
       here("output", "threshold_identification", "threshold_regimes.csv"))
fwrite(percentile_analysis,
       here("output", "threshold_identification", "percentile_analysis.csv"))

cat("\nThreshold identification complete.\n")
