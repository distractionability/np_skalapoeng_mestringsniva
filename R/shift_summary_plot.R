# Summary Plot: Share of pupils with level shifts by year
#
# Facet grid: grade_level ~ subject
# X-axis: year
# Y-axis: share of pupils (%)
# Green dots: shifted up, Red dots: shifted down

library(here)
library(haven)
library(ggplot2)

# Source config and functions
source(here("R", "config.R"), encoding = "UTF-8")
source(here("R", "correction_functions.R"), encoding = "UTF-8")
source(here("R", "mastery_levels.R"), encoding = "UTF-8")

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

# Calculate levels for both old and new scores
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

# Calculate shift percentages by subject, grade, year
shift_summary <- data_analysis[!is.na(level_old) & !is.na(level_new), .(
  n_total = .N,
  pct_up = 100 * sum(level_new > level_old) / .N,
  pct_down = 100 * sum(level_new < level_old) / .N
), by = .(subject, grade_level, year)]

# Reshape for plotting
shift_long <- melt(shift_summary,
                   id.vars = c("subject", "grade_level", "year"),
                   measure.vars = c("pct_up", "pct_down"),
                   variable.name = "direction",
                   value.name = "pct")

shift_long[, direction := fifelse(direction == "pct_up", "Shifted UP", "Shifted DOWN")]

# Order subjects and create nice labels
shift_long[, subject_label := fcase(
  subject == "ENG", "English",
  subject == "MATH", "Mathematics",
  subject == "NOR", "Reading"
)]
shift_long[, subject_label := factor(subject_label, levels = c("English", "Mathematics", "Reading"))]

shift_long[, grade_label := paste0("Grade ", grade_level)]
shift_long[, grade_label := factor(grade_label, levels = c("Grade 5", "Grade 8"))]

# Create plot
cat("Creating plot...\n")

p <- ggplot(shift_long, aes(x = year, y = pct, color = direction)) +
  geom_point(size = 3) +
  geom_line(linewidth = 0.8, alpha = 0.6) +
  facet_grid(grade_label ~ subject_label) +
  scale_color_manual(
    values = c("Shifted UP" = "#4a7c3a", "Shifted DOWN" = "#8c4a4a"),
    name = NULL
  ) +
  scale_x_continuous(breaks = seq(2014, 2021, by = 2)) +
  scale_y_continuous(limits = c(0, NA), labels = function(x) paste0(x, "%")) +
  labs(
    title = "Share of Pupils with Changed Competence Levels",
    subtitle = "After applying SSB score corrections",
    x = "Year",
    y = "Share of pupils"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Save plot
output_path <- here("output", "plots", "shift_summary_facet.png")
ggsave(output_path, p, width = 10, height = 6, dpi = 150)

cat(sprintf("Plot saved to: %s\n", output_path))
