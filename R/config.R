# Configuration file for national test score correction analysis
# Uses data.table, ggplot2, and here for path management

# Function to install packages if not available
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Installing package '%s'...", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

# Required packages
install_if_missing("data.table")
install_if_missing("ggplot2")
install_if_missing("here")

library(data.table)
library(ggplot2)
library(here)

# Rescaling parameters from SSB Table 1
# Read from CSV file to ensure accuracy with source data
# Formula: theta_new_hat = (sd_new / sd_old) * (theta_old - mean_old) + mean_new

# Path to the rescaling parameters CSV file
rescaling_csv_path <- here("data", "rescaling_parameters.csv")

# Read and parse the CSV file
# The file has header rows we need to skip, uses semicolon delimiter, and comma for decimals
# Use col.names to handle duplicate column names in source file
rescaling_raw <- fread(
  rescaling_csv_path,
  skip = 3,  # Skip header rows (including the column names row - we'll provide our own)
  sep = ";",
  dec = ",",  # Norwegian decimal format
  header = FALSE,
  encoding = "UTF-8",
  col.names = c("school_year", "test_code", "mean_old", "sd_old", "mean_new", "sd_new")
)

# Remove any empty rows (e.g., trailing empty lines)
rescaling_params <- rescaling_raw[!is.na(test_code) & test_code != ""]

# Parse test_code into subject and grade_level
rescaling_params[, subject := fcase(
  grepl("Engelsk", test_code), "ENG",
  grepl("Regning", test_code), "MATH",
  grepl("Lesing", test_code), "NOR"
)]

rescaling_params[, grade_level := as.integer(gsub(".*([58])\\..*", "\\1", test_code))]

# Extract year (first year of school year)
rescaling_params[, year := as.integer(substr(school_year, 1, 4))]

# Set key for fast lookup
setkey(rescaling_params, subject, grade_level, year)

# Mastery level cutoffs - empirically identified from first year (2014)
# Based on threshold identification analysis using SSB register data
# Classification rule: score >= threshold -> higher level
# 5. trinn: 3 levels (25-50-25 target distribution)
# 8. trinn: 5 levels (10-20-40-20-10 target distribution)

mastery_cutoffs <- list(
  # Grade 5 cutoffs (3 levels) - all subjects used same thresholds in 2014
  grade5 = list(
    MATH = c(-Inf, 42.5, 56.5, Inf),  # Level 1: <42.5, Level 2: 42.5-56.5, Level 3: >=56.5
    NOR  = c(-Inf, 42.5, 56.5, Inf),  # Level 1: <42.5, Level 2: 42.5-56.5, Level 3: >=56.5
    ENG  = c(-Inf, 42.5, 56.5, Inf)   # Level 1: <42.5, Level 2: 42.5-56.5, Level 3: >=56.5
  ),
  # Grade 8 cutoffs (5 levels) - 2014 empirical values
  grade8 = list(
    MATH = c(-Inf, 37.0, 45.0, 55.0, 63.0, Inf),  # 2014 used integer cutpoints
    NOR  = c(-Inf, 36.5, 43.5, 54.5, 62.5, Inf),  # Levels 1-5
    ENG  = c(-Inf, 36.5, 43.5, 55.5, 62.5, Inf)   # Levels 1-5
  )
)

# Function to get cutoffs for a given subject and grade
get_cutoffs <- function(subject, grade_level) {
  grade_key <- paste0("grade", grade_level)
  if (!grade_key %in% names(mastery_cutoffs)) {
    stop("Invalid grade_level. Must be 5 or 8.")
  }
  if (!subject %in% names(mastery_cutoffs[[grade_key]])) {
    stop("Invalid subject. Must be MATH, NOR, or ENG.")
  }
  return(mastery_cutoffs[[grade_key]][[subject]])
}
