---
title: "Threshold Identification Report"
subtitle: "Cutpoints for mestringsnivå classification (2014-2021)"
geometry: margin=0.75in
fontsize: 10pt
---

# Overview

This report documents the cutpoints (thresholds) used to map skalapoeng
(scale scores) to mestringsnivå (mastery levels) in the Norwegian national
tests for the period 2014-2021. The report does three things:

**1. Assesses first-year threshold calibration against Udir documentation.**
According to Udir, thresholds were set in each test series' first year to
achieve specific percentile distributions: 25-50-25% for Grade 5 (three levels)
and 10-20-40-20-10% for Grade 8 (five levels). We calculate what percentile
each threshold actually corresponds to in the first-year score distribution.
Note: The register data from Statistics Norway may not cover the exact sample
used to set the original cutpoints, so small discrepancies are expected.
Overall, the thresholds appear to be set in accordance with the stated methodology.

**2. Identifies the cutpoints actually deployed in each year.**
Using register data on loan from Statistics Norway, we identify the exact
thresholds by finding the score boundaries between adjacent mastery levels.
For each threshold, we find the highest score assigned to the lower level
(lower_max) and the lowest score assigned to the higher level (upper_min).
Since scores have 3-decimal precision, this precisely identifies cutpoints.
Consistent threshold mapping was found for English (both grades) and Mathematics
Grade 5. Mathematics Grade 8 had two regimes (2014 used integer cutpoints,
2015-2021 used half-point cutpoints). Reading Grade 5 had two regimes (threshold
change in 2016), while Reading Grade 8 had three distinct regimes (2014, 2015,
2016-2021) due to an anomalous 2015.

**3. Provides detailed year-by-year threshold tables.**
The final section includes complete tables showing exact threshold values for
each year, along with guidance on how to use these cutpoints to assign
mestringsnivå from skalapoeng scores.

# Methodology

## Threshold Setting Process (per Udir documentation)

According to Udir, thresholds were set in the first test year to achieve
the following percentile distributions:

- **Grade 5**: 25% – 50% – 25% (Levels 1, 2, 3)
- **Grade 8**: 10% – 20% – 40% – 20% – 10% (Levels 1, 2, 3, 4, 5)

Target percentiles for each threshold:

| Grade | Threshold | Lower → Upper | Target Percentile |
|:-----:|:---------:|:-------------:|:-----------------:|
| 5 | 1 | 1 → 2 | 25th |
| 5 | 2 | 2 → 3 | 75th |
|   |   |       |      |
| 8 | 1 | 1 → 2 | 10th |
| 8 | 2 | 2 → 3 | 30th |
| 8 | 3 | 3 → 4 | 70th |
| 8 | 4 | 4 → 5 | 90th |

## Empirical Identification

For each year × subject × grade × threshold, we identify:

1. **lower_max**: Maximum score among students at the lower level
2. **upper_min**: Minimum score among students at the higher level

Classification rule: `score >= threshold → higher level`

\newpage

# Percentile Analysis: First Year (2014)

Comparing target vs. actual percentiles for first year thresholds.

![Threshold Calibration](percentile_calibration.png)

*Figure: Target percentiles (x-axis) vs. actual percentiles (y-axis) for each
threshold in the first year. Points on the dashed 45° line indicate perfect
calibration to the documented targets.*

## Grade 5

| Subject | Nivå- | Nivå+ | Target Percentile | Actual Percentile* | Score at Target | Actual Cutpoint* |
|:------------|:-----:|:-----:|:-----------------:|:------------------:|:---------------:|:----------------:|
| English | 1 | 2 | 25% | 24.8% | 42.55 | 42.5 |
|  | 2 | 3 | 75% | 75.0% | 56.51 | 56.5 |
| Mathematics | 1 | 2 | 25% | 24.6% | 42.61 | 42.5 |
|  | 2 | 3 | 75% | 74.1% | 56.83 | 56.5 |
| Reading | 1 | 2 | 25% | 23.2% | 43.06 | 42.5 |
|  | 2 | 3 | 75% | 73.8% | 56.87 | 56.5 |

*\* Assessed using register data on loan from Statistics Norway.*

## Grade 8

| Subject | Nivå- | Nivå+ | Target Percentile | Actual Percentile* | Score at Target | Actual Cutpoint* |
|:------------|:-----:|:-----:|:-----------------:|:------------------:|:---------------:|:----------------:|
| English | 1 | 2 | 10% | 9.2% | 36.89 | 36.5 |
|  | 2 | 3 | 30% | 28.4% | 44.00 | 43.5 |
|  | 3 | 4 | 70% | 68.6% | 55.96 | 55.5 |
|  | 4 | 5 | 90% | 88.5% | 63.24 | 62.5 |
| Mathematics | 1 | 2 | 10% | 10.3% | 36.88 | 37.0 |
|  | 2 | 3 | 30% | 32.0% | 44.42 | 45.0 |
|  | 3 | 4 | 70% | 68.9% | 55.31 | 55.0 |
|  | 4 | 5 | 90% | 89.8% | 63.11 | 63.0 |
| Reading | 1 | 2 | 10% | 8.7% | 37.23 | 36.5 |
|  | 2 | 3 | 30% | 26.5% | 44.54 | 43.5 |
|  | 3 | 4 | 70% | 67.2% | 55.34 | 54.5 |
|  | 4 | 5 | 90% | 88.9% | 63.13 | 62.5 |

*\* Assessed using register data on loan from Statistics Norway.*

\newpage

# Cutpoint Tables by Subject

*Note: In tables with multiple time periods, values that changed relative to
the previous period are shown in **bold**.*

## Grade 5

### English (Engelsk)

| Nivå- | Nivå+ | 2014-2021 |
|:-----:|:-----:|:---------:|
| 1 | 2 | 42.5 |
| 2 | 3 | 56.5 |

### Mathematics (Regning)

| Nivå- | Nivå+ | 2014-2021 |
|:-----:|:-----:|:---------:|
| 1 | 2 | 42.5 |
| 2 | 3 | 56.5 |

### Reading (Lesing)

| Nivå- | Nivå+| 2014-2015 | 2016-2021 |
|:-----:|:-----:|:---------:|:---------:|
| 1 | 2 | 42.5 | 42.5 |
| 2 | 3 | 56.5 | **57.5** |

## Grade 8

### English (Engelsk)

| Nivå- | Nivå+ | 2014-2021 |
|:-----:|:-----:|:---------:|
| 1 | 2 | 36.5 |
| 2 | 3 | 43.5 |
| 3 | 4 | 55.5 |
| 4 | 5 | 62.5 |

### Mathematics (Regning)

| Nivå- | Nivå+| 2014 | 2015-2021 |
|:-----:|:-----:|:---------:|:---------:|
| 1 | 2 | 37.0 | **36.5** |
| 2 | 3 | 45.0 | **44.5** |
| 3 | 4 | 55.0 | **54.5** |
| 4 | 5 | 63.0 | **62.5** |

### Reading (Lesing)

| Nivå- | Nivå+| 2014 | 2015 | 2016-2021 |
|:-----:|:-----:|:---------:|:---------:|:---------:|
| 1 | 2 | 36.5 | 36.5 | **37.5** |
| 2 | 3 | 43.5 | **44.5** | **43.5** |
| 3 | 4 | 54.5 | 54.5 | 54.5 |
| 4 | 5 | 62.5 | 62.5 | 62.5 |

\newpage

# Detailed Year-by-Year Thresholds

Exact upper_min values. Small variations (42.500 vs 42.501) reflect
measurement precision, not actual threshold differences.

## Grade 5

### English (Engelsk)

| Lower | Upper | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 |
|:-----:|:-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| 1 | 2 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 |
| 2 | 3 | 56.50 | 56.50 | 56.50 | 56.50 | 56.50 | 56.50 | 56.50 | 56.50 |

### Mathematics (Regning)

| Lower | Upper | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 |
|:-----:|:-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| 1 | 2 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 |
| 2 | 3 | 56.50 | 56.50 | 56.50 | 56.50 | 56.50 | 56.50 | 56.50 | 56.50 |

### Reading (Lesing)

| Lower | Upper | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 |
|:-----:|:-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| 1 | 2 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 | 42.50 |
| 2 | 3 | 56.50 | 56.50 | 57.50 | 57.50 | 57.50 | 57.50 | 57.50 | 57.50 |

## Grade 8

### English (Engelsk)

| Lower | Upper | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 |
|:-----:|:-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| 1 | 2 | 36.50 | 36.50 | 36.50 | 36.50 | 36.50 | 36.50 | 36.50 | 36.50 |
| 2 | 3 | 43.50 | 43.50 | 43.50 | 43.50 | 43.50 | 43.50 | 43.50 | 43.50 |
| 3 | 4 | 55.50 | 55.50 | 55.50 | 55.50 | 55.50 | 55.50 | 55.50 | 55.50 |
| 4 | 5 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 |

### Mathematics (Regning)

| Lower | Upper | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 |
|:-----:|:-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| 1 | 2 | 37.00 | 36.50 | 36.50 | 36.50 | 36.50 | 36.50 | 36.50 | 36.50 |
| 2 | 3 | 45.00 | 44.50 | 44.50 | 44.50 | 44.50 | 44.50 | 44.50 | 44.50 |
| 3 | 4 | 55.00 | 54.50 | 54.50 | 54.50 | 54.50 | 54.50 | 54.50 | 54.50 |
| 4 | 5 | 63.00 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 |

### Reading (Lesing)

| Lower | Upper | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 |
|:-----:|:-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|
| 1 | 2 | 36.50 | 36.50 | 37.50 | 37.50 | 37.50 | 37.50 | 37.50 | 37.50 |
| 2 | 3 | 43.50 | 44.50 | 43.50 | 43.50 | 43.50 | 43.50 | 43.50 | 43.50 |
| 3 | 4 | 54.50 | 54.50 | 54.50 | 54.50 | 54.50 | 54.50 | 54.50 | 54.50 |
| 4 | 5 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 | 62.50 |

\newpage

# Key Findings

1. **Score precision**: Skalapoeng values have 3-decimal precision

2. **Clean separation**: All level boundaries have positive gaps

3. **Threshold format**: Most thresholds are at X.5 (e.g., 42.5, 56.5)

4. **Notable threshold changes**:
   - NOR Grade 5 Level 2→3: 56.5 to 57.5 starting 2016
   - NOR Grade 8 Level 1→2: 36.5 to 37.5 starting 2016
   - NOR Grade 8 Level 2→3: 44.5 in 2015, otherwise 43.5
   - MATH Grade 8 2014: Integer thresholds (37, 45, 55, 63)

# How to Use These Thresholds

```
Grade 5 (3 levels):              Grade 8 (5 levels):
  Level 1: score < threshold_1     Level 1: score < threshold_1
  Level 2: t1 <= score < t2        Level 2: t1 <= score < t2
  Level 3: score >= threshold_2    Level 3: t2 <= score < t3
                                   Level 4: t3 <= score < t4
                                   Level 5: score >= threshold_4
```

Published Udir thresholds are integers (43, 57). Empirical thresholds
are 0.5 below (42.5, 56.5) - Udir rounds up for communication.

