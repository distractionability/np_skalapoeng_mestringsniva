# Score correction functions for national test data
# Implements the rescaling formula from SSB

source(here::here("R", "config.R"))

#' Correct erroneous test scores using SSB rescaling method
#'
#' Applies the formula: theta_new_hat = (sd_new / sd_old) * (theta_old - mean_old) + mean_new
#'
#' @param subject Character: "ENG", "MATH", or "NOR"
#' @param grade_level Integer: 5 or 8
#' @param test_year Integer: Year of test (2014-2021)
#' @param scores Numeric vector of erroneous (delivered) scores
#' @return Numeric vector of corrected scores
#'
correct_scores <- function(subject, grade_level, test_year, scores) {
  # Validate inputs
  if (!subject %in% c("ENG", "MATH", "NOR")) {
    stop("subject must be 'ENG', 'MATH', or 'NOR'")
  }
  if (!grade_level %in% c(5, 8)) {
    stop("grade_level must be 5 or 8")
  }
  if (!test_year %in% 2014:2021) {
    stop("test_year must be between 2014 and 2021")
  }

  # Special case: NOR (Lesing) only available from 2016
  if (subject == "NOR" && test_year < 2016) {
    warning("NOR (reading) tests only available from 2016. Returning NA.")
    return(rep(NA_real_, length(scores)))
  }

  # Look up rescaling parameters
  # Use temporary variables to avoid data.table column name conflicts
  .subj <- subject
  .grade <- as.integer(grade_level)
  .year <- as.integer(test_year)
  params <- rescaling_params[subject == .subj & grade_level == .grade & year == .year]

  if (nrow(params) == 0) {
    stop(sprintf("No rescaling parameters found for %s, grade %d, year %d",
                 subject, grade_level, test_year))
  }

  # Apply rescaling formula
  mean_old <- params$mean_old
  sd_old <- params$sd_old
  mean_new <- params$mean_new
  sd_new <- params$sd_new

  corrected <- (sd_new / sd_old) * (scores - mean_old) + mean_new

  return(corrected)
}

#' Correct scores in a data.table
#'
#' @param dt data.table with columns: score, subject, grade_level, year
#' @return data.table with additional column 'score_corrected'
#'
correct_scores_dt <- function(dt) {
  # Make a copy to avoid modifying original
  result <- copy(dt)

  # Initialize corrected score column
  result[, score_corrected := NA_real_]

  # Get unique combinations
  combos <- unique(result[, .(subject, grade_level, year)])

  for (i in seq_len(nrow(combos))) {
    subj <- combos$subject[i]
    grade <- combos$grade_level[i]
    yr <- combos$year[i]

    # Check if correction is applicable
    if (yr < 2014 || yr > 2021) {
      next
    }
    if (subj == "NOR" && yr < 2016) {
      next
    }

    # Apply correction
    idx <- result$subject == subj & result$grade_level == grade & result$year == yr
    result[idx, score_corrected := correct_scores(subj, grade, yr, score)]
  }

  return(result)
}

#' Get rescaling parameters for a specific test
#'
#' @param subject Character: "ENG", "MATH", or "NOR"
#' @param grade_level Integer: 5 or 8
#' @param test_year Integer: Year of test (2014-2021)
#' @return Named list with mean_old, sd_old, mean_new, sd_new
#'
get_rescaling_params <- function(subject, grade_level, test_year) {
  params <- rescaling_params[.(subject, grade_level, test_year)]

  if (nrow(params) == 0) {
    return(NULL)
  }

  return(list(
    mean_old = params$mean_old,
    sd_old = params$sd_old,
    mean_new = params$mean_new,
    sd_new = params$sd_new
  ))
}
