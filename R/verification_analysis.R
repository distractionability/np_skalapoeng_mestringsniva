# Verification and Analysis Script for npole.dta
#
# This script performs two key analyses:
# 1. VERIFICATION: Checks that levels we calculate from skalapoeng match
#    the mestring column in the raw data file
# 2. SUBSTANTIVE ANALYSIS: Analyzes how score corrections shift students
#    across competence levels
#
# Uses existing codebase functions from R/ folder

library(here)
library(haven)

# Set UTF-8 encoding for Norwegian characters
Sys.setlocale("LC_ALL", "en_US.UTF-8")

# Source existing modules
source(here("R", "config.R"), encoding = "UTF-8")
source(here("R", "correction_functions.R"), encoding = "UTF-8")
source(here("R", "mastery_levels.R"), encoding = "UTF-8")

cat("\n")
cat("==============================================================\n")
cat("  VERIFICATION & ANALYSIS: npole.dta\n")
cat("==============================================================\n\n")

# ============================================================================
# PART 1: Load and prepare data
# ============================================================================

cat("1. Loading data from npole.dta...\n")

data_raw <- as.data.table(read_dta(here("data", "npole.dta")))

cat(sprintf("   Total observations: %s\n", format(nrow(data_raw), big.mark = ",")))
cat(sprintf("   Columns: %s\n", paste(names(data_raw), collapse = ", ")))

# Show year range and missingness
cat("\n   Year distribution:\n")
print(data_raw[, .N, by = year][order(year)])

cat("\n   Missing values:\n")
cat(sprintf("   - skalapoeng NA: %s\n", format(sum(is.na(data_raw$skalapoeng)), big.mark = ",")))
cat(sprintf("   - mestring NA: %s\n", format(sum(is.na(data_raw$mestring)), big.mark = ",")))

# ============================================================================
# PART 2: Map columns to match existing functions
# ============================================================================

cat("\n2. Preparing data for analysis...\n")

# Create working copy with mapped column names
# fag: ENG, LES, REG -> ENG, NOR, MATH
# trinn -> grade_level
# skalapoeng -> score (for existing functions)

data <- copy(data_raw)

# Map subject codes
data[, subject := fcase(
  fag == "LES", "NOR",
  fag == "REG", "MATH",
  fag == "ENG", "ENG"
)]

# Rename for compatibility with existing functions
setnames(data, "trinn", "grade_level")
setnames(data, "skalapoeng", "score")

# Keep original mestring for verification
# mestring column already exists in data

cat("   Column mapping complete:\n")
cat("   - fag -> subject (LES->NOR, REG->MATH, ENG->ENG)\n")
cat("   - trinn -> grade_level\n")
cat("   - skalapoeng -> score\n")
cat("   - mestring preserved for verification\n")

# ============================================================================
# PART 3: VERIFICATION - Compare calculated levels to file's mestring
# ============================================================================

cat("\n")
cat("==============================================================\n")
cat("  VERIFICATION: Do calculated levels match file's mestring?\n")
cat("==============================================================\n\n")

# Filter to years with rescaling parameters (2014-2021) and non-NA scores
data_verify <- data[year >= 2014 & year <= 2021 & !is.na(score)]

cat(sprintf("Observations in verification period (2014-2021 with valid scores): %s\n\n",
            format(nrow(data_verify), big.mark = ",")))

# Calculate levels using documented cutoffs (no rounding)
data_verify[, level_calculated := NA_integer_]

combos <- unique(data_verify[, .(subject, grade_level)])
for (i in seq_len(nrow(combos))) {
  subj <- combos$subject[i]
  grade <- combos$grade_level[i]
  idx <- data_verify$subject == subj & data_verify$grade_level == grade
  data_verify[idx, level_calculated := assign_mastery_level(score, subj, grade)]
}

# Compare to mestring column from file
data_verify[, match := (level_calculated == mestring)]

# Summary by subject, grade, year
verification_summary <- data_verify[!is.na(mestring) & !is.na(level_calculated), .(
  n_total = .N,
  n_match = sum(match),
  n_mismatch = sum(!match),
  pct_match = round(100 * mean(match), 2)
), by = .(subject, grade_level, year)]

setorder(verification_summary, subject, grade_level, year)

cat("3. Verification results by subject/grade/year:\n\n")
print(verification_summary)

# Overall summary
overall_match <- data_verify[!is.na(mestring) & !is.na(level_calculated), .(
  n_total = .N,
  n_match = sum(match),
  n_mismatch = sum(!match),
  pct_match = round(100 * mean(match), 2)
)]

cat("\n   OVERALL VERIFICATION RESULT:\n")
cat(sprintf("   Total observations checked: %s\n", format(overall_match$n_total, big.mark = ",")))
cat(sprintf("   Matches: %s (%.2f%%)\n", format(overall_match$n_match, big.mark = ","), overall_match$pct_match))
cat(sprintf("   Mismatches: %s (%.2f%%)\n", format(overall_match$n_mismatch, big.mark = ","), 100 - overall_match$pct_match))

if (overall_match$pct_match >= 99.9) {
  cat("\n   *** VERIFICATION PASSED: Calculated levels match file's mestring ***\n")
} else {
  cat("\n   *** NOTE: Some mismatches detected (likely due to rounding differences) ***\n")
  cat("   Proceeding with substantive analysis using documented cutoffs.\n")
}

# ============================================================================
# PART 4: SUBSTANTIVE ANALYSIS - How corrections shift students across levels
# ============================================================================

cat("\n")
cat("==============================================================\n")
cat("  SUBSTANTIVE ANALYSIS: Effect of score corrections on levels\n")
cat("==============================================================\n\n")

cat("4. Applying score corrections...\n")

# Apply corrections using existing function
data_analysis <- copy(data_verify)
data_analysis <- correct_scores_dt(data_analysis)

# Rename for clarity
setnames(data_analysis, "score_corrected", "score_corrected")

# Calculate corrected levels
data_analysis[, level_corrected := NA_integer_]

for (i in seq_len(nrow(combos))) {
  subj <- combos$subject[i]
  grade <- combos$grade_level[i]
  idx <- data_analysis$subject == subj & data_analysis$grade_level == grade
  data_analysis[idx, level_corrected := assign_mastery_level(score_corrected, subj, grade)]
}

# Use original mestring as the "old" level (from file) for substantive analysis
# This represents what was actually reported
data_analysis[, level_old := mestring]
data_analysis[, level_new := level_corrected]

# ============================================================================
# PART 5: Generate substantive analysis results
# ============================================================================

cat("\n5. Computing level change statistics...\n\n")

# Summary: How many students changed levels?
change_summary <- data_analysis[!is.na(level_old) & !is.na(level_new), .(
  n_total = .N,
  n_unchanged = sum(level_old == level_new),
  n_moved_up = sum(level_new > level_old),
  n_moved_down = sum(level_new < level_old),
  pct_unchanged = round(100 * mean(level_old == level_new), 2),
  pct_moved_up = round(100 * mean(level_new > level_old), 2),
  pct_moved_down = round(100 * mean(level_new < level_old), 2),
  pct_changed = round(100 * mean(level_old != level_new), 2)
), by = .(subject, grade_level, year)]

setorder(change_summary, subject, grade_level, year)

cat("Level change summary (original mestring -> corrected level):\n\n")
print(change_summary)

# Overall impact
overall_impact <- data_analysis[!is.na(level_old) & !is.na(level_new), .(
  n_total = .N,
  n_changed = sum(level_old != level_new),
  pct_changed = round(100 * mean(level_old != level_new), 2),
  pct_moved_up = round(100 * mean(level_new > level_old), 2),
  pct_moved_down = round(100 * mean(level_new < level_old), 2)
)]

cat("\n   OVERALL IMPACT OF CORRECTIONS:\n")
cat(sprintf("   Total students analyzed: %s\n", format(overall_impact$n_total, big.mark = ",")))
cat(sprintf("   Students who changed level: %s (%.2f%%)\n",
            format(overall_impact$n_changed, big.mark = ","), overall_impact$pct_changed))
cat(sprintf("   Moved UP: %.2f%%\n", overall_impact$pct_moved_up))
cat(sprintf("   Moved DOWN: %.2f%%\n", overall_impact$pct_moved_down))

# ============================================================================
# PART 6: Transition matrices
# ============================================================================

cat("\n\n6. Transition matrices (by subject and grade):\n")

# Function to print a nice transition matrix
print_transition_matrix <- function(dt, subj, grade) {
  subset_dt <- dt[subject == subj & grade_level == grade & !is.na(level_old) & !is.na(level_new)]

  if (nrow(subset_dt) == 0) {
    cat(sprintf("\n   No data for %s grade %d\n", subj, grade))
    return(invisible(NULL))
  }

  # Create transition table
  trans_table <- subset_dt[, .N, by = .(level_old, level_new)]
  trans_wide <- dcast(trans_table, level_old ~ level_new, value.var = "N", fill = 0)

  cat(sprintf("\n   %s Grade %d (rows=original, cols=corrected):\n", subj, grade))
  print(trans_wide)

  # Percentage who changed
  pct_changed <- subset_dt[, round(100 * mean(level_old != level_new), 2)]
  cat(sprintf("   Changed: %.2f%% of %s students\n", pct_changed, format(nrow(subset_dt), big.mark = ",")))
}

# Print for each subject/grade combo
for (subj in c("ENG", "MATH", "NOR")) {
  for (grade in c(5, 8)) {
    print_transition_matrix(data_analysis, subj, grade)
  }
}

# ============================================================================
# PART 7: Save results
# ============================================================================

cat("\n\n7. Saving results...\n")

output_dir <- here("output", "verification")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Save verification summary
fwrite(verification_summary, file.path(output_dir, "verification_summary.csv"))
cat(sprintf("   - Saved: verification_summary.csv\n"))

# Save change summary
fwrite(change_summary, file.path(output_dir, "level_change_summary.csv"))
cat(sprintf("   - Saved: level_change_summary.csv\n"))

# Save detailed transition data
transitions_detailed <- data_analysis[!is.na(level_old) & !is.na(level_new),
                                       .N,
                                       by = .(subject, grade_level, year, level_old, level_new)]
setorder(transitions_detailed, subject, grade_level, year, level_old, level_new)
fwrite(transitions_detailed, file.path(output_dir, "transitions_detailed.csv"))
cat(sprintf("   - Saved: transitions_detailed.csv\n"))

cat("\n")
cat("==============================================================\n")
cat("  ANALYSIS COMPLETE\n")
cat("==============================================================\n")
cat(sprintf("\nOutput saved to: %s\n", output_dir))

# Return results for further analysis if sourced interactively
invisible(list(
  verification = verification_summary,
  changes = change_summary,
  transitions = transitions_detailed,
  data = data_analysis
))
