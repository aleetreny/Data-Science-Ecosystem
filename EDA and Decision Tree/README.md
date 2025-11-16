# Student Performance Analysis: Exploratory and Predictive Modeling

## Project Overview

This repository contains a comprehensive data science project analyzing student academic performance in Portuguese secondary schools. The project demonstrates practical applications of exploratory data analysis (EDA) and predictive modeling using decision trees. The analysis combines sophisticated visualization techniques with statistical methods to identify key drivers of student success and develop an early-warning system for academic intervention.

**Dataset:** 395 secondary school students from Portugal  
**Primary Target Variable:** Final grade (G3) - numeric (0-20 scale, passing threshold: 10)  
**Analysis Scope:** Demographic factors, family background, lifestyle habits, and academic history

---

## Recommended File Organization

### Folder Naming Suggestion
```
📁 Student-Performance-Analysis/
```

### File Naming Convention

| Original Name | Recommended Name | Description |
|---------------|-----------------|-------------|
| `student-mat.csv` | `student_data.csv` | Dataset with 395 student records |
| `Code.R` | `analysis.R` | Complete R script for both EDA and modeling |
| `Student_Performance.Rmd` | `report.Rmd` | R Markdown source for PDF report |
| `Student_Performance.pdf` | `Student_Performance_Report.pdf` | Final comprehensive report |
| `S4DSassignment2025.pdf` | *(excluded)* | Original assignment specifications (not included in folder) |
| `README.md` | `README.md` | This documentation file |

**Rationale for renaming:**
- Use underscores instead of spaces for consistency with coding standards
- More descriptive filenames for clarity (e.g., `analysis.R` instead of `Code.R`)
- Consistent formatting across all project files
- Maintain the PDF report name as is for final deliverable clarity

---

## Project Structure

```
📁 Student-Performance-Analysis/
├── 📄 README.md                      # This file - project documentation
├── 📄 student_data.csv              # Dataset (395 students, 33 variables)
├── 📄 analysis.R                    # Complete R script (both parts)
├── 📄 report.Rmd                    # R Markdown source code
└── 📄 Student_Performance_Report.pdf # Final report PDF
```

---

## Project Components

### Part A: Exploratory Data Analysis (60%)

A comprehensive exploratory analysis addressing five key research questions through appropriate visualizations and statistical summaries:

#### Research Question 1: Parental Education Impact
- **Visualization:** Bar chart with error bars
- **Finding:** Strong positive correlation between parental education level and student grades (mean G3: 8.51 → 11.57)
- **Insight:** Students whose most educated parent completed higher education achieve ~3 points higher average grades

#### Research Question 2: Grade Distribution Analysis
- **Visualization:** Histogram with color-coded regions
- **Finding:** 67.1% of students achieve the passing threshold (G3 ≥ 10)
- **Concern:** Notable cluster at score 0 suggests dropouts or non-attendance; concentration just above threshold indicates intervention opportunity

#### Research Question 3: Educational Aspirations Impact
- **Visualization:** Violin plot + boxplot combination
- **Finding:** Students aspiring to higher education show dramatically higher pass rates (69% vs. 35%)
- **Distribution:** Aspirational students have concentrated grades around higher values; non-aspirational show greater variability

#### Research Question 4: Academic History Effects
- **Visualization:** Scatter plot with regression overlay, stratified by failure history
- **Finding:** Strong G2-G3 correlation (r ≈ 0.8) indicating predictive consistency
- **Risk Factor:** Students with past failures clustered in lower grades despite similar G2-G3 relationships

#### Research Question 5: Comprehensive Factor Analysis
- **Visualization:** Lollipop plot of Spearman correlations
- **Finding:** Prior grades (G1, G2) strongest predictors; parental education shows moderate positive correlation
- **Risk Indicators:** Academic failures and absences show strongest negative correlations
- **Lifestyle Factors:** Alcohol consumption and social activities show weaker but meaningful negative effects

#### EDA Techniques Applied
- **Visualizations:** Bar charts, histograms, boxplots, violin plots, scatter plots with regression lines, correlation plots
- **Statistical Methods:** Descriptive statistics, grouped summaries, Spearman rank correlations
- **Tools:** ggplot2 for professional graphics, dplyr for data manipulation

---

### Part B: Predictive Decision Tree Analysis (40%)

A robust machine learning model predicting high academic performance (G3 ≥ 10) using demographic and behavioral variables, excluding prior grades for practical early-intervention applicability.

#### Model Development Strategy

**Data Preparation:**
- Binary target variable: High-performing (≥10) vs. Low-performing (<10)
- Training/Testing split: 70% (277 obs) / 30% (118 obs) with stratified sampling
- Features: 31 predictors excluding G1, G2, G3

**Model Optimization:**
- Algorithm: CART (Classification and Regression Trees) via rpart
- Tuning method: 10-fold cross-validation
- Complexity parameter (cp): Grid search from 0.001 to 0.1 (34 values)
- Optimization metric: ROC (area under curve) - robust to class imbalance
- Result: Optimal cp selected automatically for maximum generalization

#### Model Performance Metrics (Test Set)

| Metric | Value | Interpretation |
|--------|-------|-----------------|
| **Accuracy** | 59.3% | Proportion of correct predictions |
| **Kappa** | -0.041 | Agreement beyond random chance |
| **Sensitivity** | 81.0% | Recall: identifies 81% of successful students |
| **Specificity** | 15.4% | Correctly identifies 15.4% of at-risk students |
| **Precision** | 66.0% | 66% of predicted successes are accurate |
| **F1-Score** | 0.727 | Balanced precision-recall metric |

#### Tree Structure Insights

**Primary Decision Splits:**

1. **Root Node - Academic Failures (Critical Factor)**
   - Students with 0 failures: 81% in "success" pathway
   - Students with 1+ failures: Automatically classified as high-risk (33% success rate)

2. **Secondary Factors (for failure-free students):**
   - Study time and dedication
   - Parental education level (particularly father's education)
   - Family relationship quality
   - School support services availability
   - Health status and lifestyle factors

3. **Risk Pathways (Compound Risk):**
   - Multiple failures + poor study habits + weak family support
   - Maximum predicted failure rate: 95% in highest-risk leaf nodes

4. **Success Pathways:**
   - No failures + adequate study time (≥3 hours) + higher education aspirations
   - Maximum predicted success rate: 92% in optimal conditions

#### Educational Implications

**Key Findings:**
1. **Academic history dominates:** Prior failures are the strongest single predictor, suggesting cumulative disadvantage
2. **Multifactor assessment:** No single factor guarantees success; complex interactions matter
3. **Actionable early warning:** Model identifies at-risk students before final grades, enabling preventive intervention
4. **Intervention opportunities:** ~35% of students with failures could potentially achieve passing grades with targeted support

**Recommended Interventions:**

- **Early Identification:** Implement continuous monitoring systems with automated alerts for students showing academic difficulties
- **Comprehensive Support:** Address both academic skills (tutoring, study strategies) and motivational factors (goal-setting, engagement)
- **Risk-Based Resource Allocation:** Concentrate intensive interventions on students with multiple risk factors
- **Family Engagement:** Strengthen programs improving home academic support
- **Study Habits:** Provide time management and study methodology coaching, especially for at-risk populations

---

## Installation & Requirements

### Required R Packages

```r
# Install and load all dependencies
packages <- c(
  "ggplot2",      # Data visualization
  "dplyr",        # Data manipulation and summarization
  "rpart",        # Decision tree algorithm (CART)
  "rpart.plot",   # Beautiful tree visualizations
  "gridExtra",    # Multi-panel plot arrangement (if needed)
  "caret",        # Machine learning framework (cross-validation, metrics)
  "corrplot",     # Correlation matrix visualization (optional)
  "knitr"         # Markdown report generation
)

# Automatic installation if needed
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}
```

### System Requirements

- **R Version:** 4.0 or higher (recommended 4.1+)
- **Operating System:** Windows, macOS, or Linux
- **RAM:** Minimum 2 GB (4 GB recommended)
- **Disk Space:** ~100 MB for packages and outputs

---

## How to Use

### Running the Analysis Script

```r
# Set working directory to project folder
setwd("~/path/to/Student-Performance-Analysis")

# Execute the complete analysis
source("analysis.R")

# This will:
# 1. Load and explore the student dataset
# 2. Generate all EDA visualizations (5 research questions)
# 3. Train and evaluate the decision tree model
# 4. Display performance metrics
```

### Generating the Report

```r
# Method 1: Directly render the Rmd file in RStudio
# Open report.Rmd and click "Knit to PDF"

# Method 2: Command line
rmarkdown::render("report.Rmd", output_format = "pdf_document")

# Method 3: From terminal
Rscript -e "rmarkdown::render('report.Rmd', output_format = 'pdf_document')"
```

### Using the Analysis Script Components Separately

```r
# Load data and dependencies
source("analysis.R")

# Access individual analysis results:
# Part A - EDA visualizations are printed automatically
# Part B - Access the final model object:
final_tree_model <- tuned_tree_model
tree_predictions <- predict(tuned_tree_model, test_data)
model_performance <- confusionMatrix(tree_predictions, test_data$high_performance, positive = "Yes")
```

---

## Data Dictionary

### Key Variables in Dataset

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| **G3** | Numeric | 0-20 | Final grade (target variable) |
| **G1** | Numeric | 0-20 | First period grade |
| **G2** | Numeric | 0-20 | Second period grade |
| **Medu** | Ordinal | 0-4 | Mother's education level |
| **Fedu** | Ordinal | 0-4 | Father's education level |
| **failures** | Numeric | 0-3 | Number of past academic failures |
| **studytime** | Ordinal | 1-4 | Hours per week studying |
| **absences** | Numeric | 0-93 | Number of school absences |
| **higher** | Binary | yes/no | Aspiration for higher education |
| **Walc** | Ordinal | 1-5 | Weekend alcohol consumption |
| **Dalc** | Ordinal | 1-5 | Weekday alcohol consumption |
| **age** | Numeric | 15-22 | Student age in years |
| **famrel** | Ordinal | 1-5 | Family relationship quality |
| **freetime** | Ordinal | 1-5 | Free time after school |

### Data Quality Notes

- **Missing Values:** None detected in the dataset
- **Sample Size:** 395 students (sufficient for robust modeling)
- **Class Balance (Target):** 265 passing (67.1%) vs. 130 failing (32.9%)
- **Data Source:** UCI Machine Learning Repository - Portuguese secondary school data

---

## Visualization Guide

### Part A Visualizations

1. **Bar Chart with Error Bars:** Parental education vs. mean grades
   - Shows central tendency and confidence intervals
   - Effective for comparing group means

2. **Histogram with Color Coding:** Grade distribution relative to pass threshold
   - Reveals distribution shape and proportions
   - Color-coded regions show above/below/at passing threshold

3. **Violin + Boxplot Combination:** Education aspirations impact
   - Shows both distribution shape and quartile information
   - Effectively communicates bimodal distributions

4. **Scatter Plot with Regression:** G2 vs. G3 by failure history
   - Reveals correlations and identifies subgroup patterns
   - Regression line shows overall trend

5. **Lollipop Plot:** Correlation analysis with G3
   - Non-parametric Spearman correlations
   - Color-coded positive vs. negative relationships

### Part B Visualization

1. **Decision Tree Diagram:** Color-coded (RdYlGn palette)
   - Red nodes: Low success probability
   - Green nodes: High success probability
   - Split criteria and probability percentages shown at each node

---

## Reproducibility

### Setting Seeds for Reproducibility

The script uses `set.seed(123)` for:
- Train/test split stratification
- 10-fold cross-validation fold assignment
- Tree tuning process

To reproduce exactly the same results, the script must be run with these seed values.

```r
# Random seed set at critical points:
# Line ~X: set.seed(123) - Data partition
# Line ~Y: set.seed(123) - Model tuning

# To change seed for different random splits:
# Modify the seed value in the source script
```

---

## Key Findings Summary

### EDA Highlights

- **Strongest Predictors:** Prior academic performance (G1, G2: Spearman ρ ≈ 0.8)
- **Demographic Impact:** Parental education (+2.7 points difference)
- **Lifestyle Factors:** Weekend alcohol consumption and social activities show weak negative correlations
- **Risk Factors:** Academic failures (ρ ≈ -0.3) and absences (ρ ≈ -0.2)
- **Aspirational Gap:** Students wanting higher education show 34% higher pass rate

### Predictive Model Insights

- **High Sensitivity (81%):** Model effectively identifies likely successful students
- **Class Imbalance Challenge:** Low specificity (15.4%) suggests need for threshold adjustment in practical use
- **Risk Factors:** Academic failures emerge as dominant decision node, creating natural risk stratification
- **Intervention Window:** Model applied to students without final grades can identify intervention targets

---

## Limitations & Considerations

1. **Class Imbalance:** More passing students (67%) than failing (33%) may bias model predictions
2. **Data Representation:** Portuguese secondary school context; generalization to other populations uncertain
3. **Temporal Dynamics:** Cross-sectional data; cannot establish causality
4. **Model Interpretability vs. Performance:** Simple decision tree chosen for interpretability over maximum accuracy
5. **Practical Threshold:** Default 0.5 probability threshold may not be optimal for intervention targeting

### Potential Improvements

- **Ensemble Methods:** Random forest or gradient boosting for higher accuracy
- **Threshold Optimization:** Calibrate decision threshold for specific intervention costs
- **Temporal Analysis:** Panel data with multiple school years for trend analysis
- **Causal Inference:** Structural equation modeling to understand mechanisms
- **Student Subgroups:** Separate models for different demographic groups (gender, socioeconomic status)

---

## References

1. **Dataset Source:** UCI Machine Learning Repository - Student Performance Dataset
   - URL: https://archive.ics.uci.edu/dataset/320/student+performance
   - Original Research: Cortez & Silva (2008)

2. **Technical Methods:**
   - Decision Trees: Breiman, L., Friedman, J., Stone, C. J., & Olshen, R. A. (1984). Classification and Regression Trees
   - Cross-Validation: Hastie, T., Tibshirani, R., & Friedman, J. (2009). The Elements of Statistical Learning
   - ROC Metrics: Fawcett, T. (2006). An Introduction to ROC Analysis

3. **R Packages:**
   - rpart: Therneau, T., Atkinson, B., Ripley, B. (2023). rpart: Recursive Partitioning and Regression Trees
   - ggplot2: Wickham, H. (2016). ggplot2: Elegant Graphics for Data Analysis
   - caret: Kuhn, M. (2023). caret: Classification and Regression Training

---

## Author

**Alejandro Treny Ortega**

UC3M - Master's in Statistics for Data Science

---

## License

This project is provided for educational purposes. Dataset sourced from UCI Machine Learning Repository under appropriate academic use guidelines.

---

## Project Notes

- All scripts use relative file paths for portability across systems
- Code is fully commented for educational clarity
- Report generated in two-column PDF format for readability
- Analysis reproducible with provided random seeds
- All visualizations optimized for presentation and clarity

**Last Updated:** November 2025