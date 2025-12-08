# Calculate Discrepancy Ranges for Score Corrections
#
# Identifies the exact score ranges where students would have been
# assigned a different competence level after correction.
#
# For each cutoff C, we find the "transformed cutoff" T:
#   T = (C - intercept) / slope
# where:
#   slope = sd_new / sd_old
#   intercept = mean_new - slope * mean_old
#
# Discrepancy ranges occur between C and T for each cutoff.

library(here)

# Source config to get rescaling_params and mastery_cutoffs
source(here("R", "config.R"), encoding = "UTF-8")

# Function to calculate discrepancy ranges for a single subject/grade/year
calculate_discrepancy_ranges <- function(subj, grade, yr) {
  # Get transformation parameters
  params <- rescaling_params[subject == subj & grade_level == grade & year == yr]

  if (nrow(params) == 0) return(NULL)

  slope <- params$sd_new / params$sd_old
  intercept <- params$mean_new - slope * params$mean_old

  # Get cutoffs (excluding -Inf and Inf)
  all_cutoffs <- get_cutoffs(subj, grade)
  cutoffs <- all_cutoffs[is.finite(all_cutoffs)]

  # Calculate transformed cutoffs
  # T = (C - intercept) / slope
  transformed_cutoffs <- (cutoffs - intercept) / slope

  # Build results
  results <- list()

  for (i in seq_along(cutoffs)) {
    C <- cutoffs[i]
    Ti <- transformed_cutoffs[i]

    # Determine if upgrade or downgrade
    if (abs(Ti - C) < 0.001) {
      # No discrepancy at this cutoff
      next
    }

    if (Ti < C) {
      # Upgrade: scores in [Ti, C) were level i, now level i+1
      results[[length(results) + 1]] <- data.table(
        subject = subj,
        year = yr,
        range_lower = round(Ti, 2),
        range_upper = round(C, 2),
        original_level = i,
        corrected_level = i + 1
      )
    } else {
      # Downgrade: scores in [C, Ti) were level i+1, now level i
      results[[length(results) + 1]] <- data.table(
        subject = subj,
        year = yr,
        range_lower = round(C, 2),
        range_upper = round(Ti, 2),
        original_level = i + 1,
        corrected_level = i
      )
    }
  }

  if (length(results) == 0) return(NULL)

  rbindlist(results)
}

# Calculate for all combinations
cat("Calculating discrepancy ranges...\n\n")

# Grade 5
grade5_results <- list()
for (subj in c("ENG", "MATH", "NOR")) {
  years <- if (subj == "NOR") 2016:2021 else 2014:2021
  for (yr in years) {
    res <- calculate_discrepancy_ranges(subj, 5, yr)
    if (!is.null(res)) {
      grade5_results[[length(grade5_results) + 1]] <- res
    }
  }
}
grade5_table <- rbindlist(grade5_results)
setorder(grade5_table, subject, year)

# Grade 8
grade8_results <- list()
for (subj in c("ENG", "MATH", "NOR")) {
  years <- if (subj == "NOR") 2016:2021 else 2014:2021
  for (yr in years) {
    res <- calculate_discrepancy_ranges(subj, 8, yr)
    if (!is.null(res)) {
      grade8_results[[length(grade8_results) + 1]] <- res
    }
  }
}
grade8_table <- rbindlist(grade8_results)
setorder(grade8_table, subject, year)

# Format range as string [a, b]
format_range <- function(lower, upper) {
  sprintf("[%.2f, %.2f]", lower, upper)
}

grade5_table[, score_range := format_range(range_lower, range_upper)]
grade8_table[, score_range := format_range(range_lower, range_upper)]

# Select and order columns for output
grade5_output <- grade5_table[, .(Subject = subject, Year = year,
                                   `Score Range` = score_range,
                                   `Original Level` = original_level,
                                   `Corrected Level` = corrected_level)]

grade8_output <- grade8_table[, .(Subject = subject, Year = year,
                                   `Score Range` = score_range,
                                   `Original Level` = original_level,
                                   `Corrected Level` = corrected_level)]

# Print tables
cat("=======================================================\n")
cat("GRADE 5 - Discrepancy Ranges\n")
cat("=======================================================\n\n")
print(grade5_output, row.names = FALSE)

cat("\n\n=======================================================\n")
cat("GRADE 8 - Discrepancy Ranges\n")
cat("=======================================================\n\n")
print(grade8_output, row.names = FALSE)

# Save to CSV
output_dir <- here("output")
fwrite(grade5_output, file.path(output_dir, "discrepancy_ranges_grade5.csv"))
fwrite(grade8_output, file.path(output_dir, "discrepancy_ranges_grade8.csv"))

cat(sprintf("\n\nSaved to:\n  %s\n  %s\n",
            file.path(output_dir, "discrepancy_ranges_grade5.csv"),
            file.path(output_dir, "discrepancy_ranges_grade8.csv")))

# Return results for further use
invisible(list(grade5 = grade5_table, grade8 = grade8_table))
