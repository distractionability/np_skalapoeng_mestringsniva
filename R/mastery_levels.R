# Mastery level mapping functions
# Maps scores to competence levels based on Udir cutoffs

source(here::here("R", "config.R"))

#' Assign mastery level based on score
#'
#' @param score Numeric score (scalar or vector)
#' @param subject Character: "ENG", "MATH", or "NOR"
#' @param grade_level Integer: 5 or 8
#' @return Integer mastery level (1-3 for grade 5, 1-5 for grade 8)
#'
assign_mastery_level <- function(score, subject, grade_level) {
  cutoffs <- get_cutoffs(subject, grade_level)

  # Use findInterval to assign levels
  # findInterval with cutoffs[-1] returns 0, 1, 2, ... so we add 1 to get 1, 2, 3, ...
  levels <- findInterval(score, cutoffs[-1], left.open = FALSE) + 1L

  # Handle NA scores
  levels[is.na(score)] <- NA_integer_

  return(as.integer(levels))
}

#' Assign mastery levels to a data.table
#'
#' @param dt data.table with columns: score, score_corrected, subject, grade_level
#' @return data.table with additional columns 'level_old' and 'level_new'
#'
assign_mastery_levels_dt <- function(dt) {
  result <- copy(dt)

  # Get unique subject/grade combinations
  combos <- unique(result[, .(subject, grade_level)])

  result[, level_old := NA_integer_]
  result[, level_new := NA_integer_]

  for (i in seq_len(nrow(combos))) {
    subj <- combos$subject[i]
    grade <- combos$grade_level[i]

    idx <- result$subject == subj & result$grade_level == grade

    result[idx, level_old := assign_mastery_level(score, subj, grade)]
    result[idx, level_new := assign_mastery_level(score_corrected, subj, grade)]
  }

  return(result)
}

#' Get mastery level labels
#'
#' @param grade_level Integer: 5 or 8
#' @return Character vector of level labels
#'
get_level_labels <- function(grade_level) {
  if (grade_level == 5) {
    return(c("Nivå 1", "Nivå 2", "Nivå 3"))
  } else if (grade_level == 8) {
    return(c("Nivå 1", "Nivå 2", "Nivå 3", "Nivå 4", "Nivå 5"))
  } else {
    stop("grade_level must be 5 or 8")
  }
}

#' Compute level change statistics
#'
#' @param dt data.table with level_old and level_new columns
#' @return data.table with change statistics
#'
compute_level_changes <- function(dt) {
  result <- dt[!is.na(level_old) & !is.na(level_new), .(
    n = .N,
    n_unchanged = sum(level_old == level_new),
    n_moved_up = sum(level_new > level_old),
    n_moved_down = sum(level_new < level_old),
    pct_unchanged = 100 * mean(level_old == level_new),
    pct_moved_up = 100 * mean(level_new > level_old),
    pct_moved_down = 100 * mean(level_new < level_old),
    pct_wrong = 100 * mean(level_old != level_new)
  ), by = .(subject, grade_level, year)]

  return(result)
}

#' Compute detailed level transition matrix
#'
#' @param dt data.table with level_old, level_new, subject, grade_level, year
#' @return data.table with transition counts and percentages
#'
compute_transition_matrix <- function(dt) {
  # Filter valid observations
  valid_dt <- dt[!is.na(level_old) & !is.na(level_new)]

  # Compute transitions
  transitions <- valid_dt[, .(count = .N), by = .(subject, grade_level, year, level_old, level_new)]

  # Add total per original level
  totals <- valid_dt[, .(total = .N), by = .(subject, grade_level, year, level_old)]
  transitions <- merge(transitions, totals, by = c("subject", "grade_level", "year", "level_old"))

  # Calculate percentages

  transitions[, pct := 100 * count / total]

  # Add direction indicator
  transitions[, direction := fcase(
    level_new > level_old, "up",
    level_new < level_old, "down",
    default = "same"
  )]

  setorder(transitions, subject, grade_level, year, level_old, level_new)

  return(transitions)
}

#' Compute nested summary by original level
#'
#' @param dt data.table with level_old, level_new, subject, grade_level, year
#' @return data.table with nested statistics per original level
#'
compute_nested_summary <- function(dt) {
  valid_dt <- dt[!is.na(level_old) & !is.na(level_new)]

  summary <- valid_dt[, .(
    n_total = .N,
    n_moved_up = sum(level_new > level_old),
    n_moved_down = sum(level_new < level_old),
    n_same = sum(level_new == level_old),
    pct_moved_up = 100 * mean(level_new > level_old),
    pct_moved_down = 100 * mean(level_new < level_old),
    pct_same = 100 * mean(level_new == level_old)
  ), by = .(subject, grade_level, year, level_old)]

  setorder(summary, subject, grade_level, year, level_old)

  return(summary)
}
