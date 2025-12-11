# Visualization of Discrepancy Ranges by Year
#
# Y-axis: Calendar year
# X-axis: Original score (skalapoeng)
# Horizontal segments: green (upgrade), red (downgrade), grey (no change)
# One plot per subject × grade

library(here)
library(haven)
library(ggplot2)

# Source config
source(here("R", "config.R"), encoding = "UTF-8")

# Load data to get realistic score ranges (exclude 2022 - different regime)
cat("Loading data for score ranges...\n")
data_raw <- as.data.table(read_dta(here("data", "npole.dta")))
data_raw <- data_raw[year >= 2014 & year <= 2021]

# Map columns
data_raw[, subject := fcase(
  fag == "LES", "NOR",
  fag == "REG", "MATH",
  fag == "ENG", "ENG"
)]
setnames(data_raw, "trinn", "grade_level")
setnames(data_raw, "skalapoeng", "score")

# Get score ranges per subject/grade/year
score_ranges <- data_raw[year >= 2014 & year <= 2021 & !is.na(score),
                         .(score_min = min(score), score_max = max(score)),
                         by = .(subject, grade_level, year)]

# Function to calculate discrepancy ranges (same logic as before)
get_discrepancy_data <- function(subj, grade, yr) {
  params <- rescaling_params[subject == subj & grade_level == grade & year == yr]
  if (nrow(params) == 0) return(NULL)

  slope <- params$sd_new / params$sd_old
  intercept <- params$mean_new - slope * params$mean_old

  all_cutoffs <- get_cutoffs(subj, grade)
  cutoffs <- all_cutoffs[is.finite(all_cutoffs)]
  transformed_cutoffs <- (cutoffs - intercept) / slope

  results <- list()
  for (i in seq_along(cutoffs)) {
    C <- cutoffs[i]
    Ti <- transformed_cutoffs[i]

    if (abs(Ti - C) < 0.001) next

    if (Ti < C) {
      results[[length(results) + 1]] <- data.table(
        year = yr, xmin = Ti, xmax = C, type = "upgrade"
      )
    } else {
      results[[length(results) + 1]] <- data.table(
        year = yr, xmin = C, xmax = Ti, type = "downgrade"
      )
    }
  }

  if (length(results) == 0) return(NULL)
  rbindlist(results)
}

# Function to create plot for one subject/grade
create_discrepancy_plot <- function(subj, grade) {
  years <- if (subj == "NOR") 2016:2021 else 2014:2021

  # Get discrepancy ranges
  disc_list <- lapply(years, function(yr) get_discrepancy_data(subj, grade, yr))
  disc_data <- rbindlist(disc_list[!sapply(disc_list, is.null)])

  # Get cutoffs for reference lines
  all_cutoffs <- get_cutoffs(subj, grade)
  cutoffs <- all_cutoffs[is.finite(all_cutoffs)]

  # Set x range based on cutoffs with buffer
  # Buffer: extend 5 points beyond outermost cutoffs
  buffer <- 5
  x_min <- min(cutoffs) - buffer
  x_max <- max(cutoffs) + buffer

  # Build grey background segments (focused range per year)
  grey_data <- data.table(
    year = years,
    xmin = x_min,
    xmax = x_max
  )

  # Subject names for title
  subj_names <- c("ENG" = "English", "MATH" = "Mathematics", "NOR" = "Reading")

  # Create plot
  p <- ggplot() +
    # Grey background line for full range
    geom_segment(data = grey_data,
                 aes(x = xmin, xend = xmax, y = year, yend = year),
                 color = "grey70", linewidth = 3, alpha = 0.5) +
    # Colored segments for discrepancies
    geom_segment(data = disc_data,
                 aes(x = xmin, xend = xmax, y = year, yend = year, color = type),
                 linewidth = 3) +
    scale_color_manual(values = c("upgrade" = "#4a7c3a", "downgrade" = "#8c4a4a"),
                       labels = c("upgrade" = "Shifted UP", "downgrade" = "Shifted DOWN"),
                       name = NULL) +
    # Cutoff reference lines
    geom_vline(xintercept = cutoffs, linetype = "dashed", color = "grey40", alpha = 0.6) +
    scale_y_reverse(breaks = years, labels = years) +
    scale_x_continuous(
      breaks = seq(floor(x_min), ceiling(x_max), by = 5),  # Major breaks every 5
      minor_breaks = seq(floor(x_min), ceiling(x_max), by = 1)  # Minor breaks every 1
    ) +
    labs(
      title = sprintf("%s - Grade %d", subj_names[subj], grade),
      subtitle = "Score ranges where competence level assignment changed after correction",
      x = "Original Score (skalapoeng)",
      y = "Year"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10, color = "grey40"),
      legend.position = "bottom",
      panel.grid.major.x = element_line(color = "grey50", linewidth = 0.5),
      panel.grid.minor.x = element_line(color = "grey80", linewidth = 0.25),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      axis.text.x = element_text(size = 9)
    )

  return(p)
}

# Create output directory
dir.create(here("output", "plots", "discrepancy_ranges"), showWarnings = FALSE, recursive = TRUE)

# Generate all 6 plots
cat("Generating plots...\n")

for (subj in c("ENG", "MATH", "NOR")) {
  for (grade in c(5, 8)) {
    cat(sprintf("  %s Grade %d\n", subj, grade))

    p <- create_discrepancy_plot(subj, grade)

    filename <- sprintf("discrepancy_%s_%d.png", subj, grade)
    filepath <- here("output", "plots", "discrepancy_ranges", filename)

    ggsave(filepath, p, width = 10, height = 5, dpi = 150)
  }
}

cat("\nPlots saved to: output/plots/discrepancy_ranges/\n")
