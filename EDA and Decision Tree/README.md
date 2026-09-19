# Student Performance Analysis: Exploratory and Predictive Modeling

This project explores associations with final mathematics grades in the UCI Student Performance data and evaluates a decision tree for predicting whether a student passes (G3 >= 10). The observed model performs below the majority-class accuracy baseline and is not a validated early-warning system.

## Files and data

- [student_data.csv](student_data.csv): 395 students and 33 original variables, with no missing cells.
- [analysis.R](analysis.R): exploratory plots, training and test evaluation.
- [report.Rmd](report.Rmd): report source.
- [Student_Performance_Report.pdf](Student_Performance_Report.pdf): regenerated report.

The source is the [UCI Student Performance dataset](https://archive.ics.uci.edu/dataset/320/student+performance), introduced by Cortez and Silva (2008). There are 265 passing and 130 failing students. A single school-cohort dataset does not establish performance in other schools or years.

## Exploratory analysis

Five plots describe parental education, the grade distribution, higher-education aspirations, previous grades and rank correlations. Error bars on grouped means are **one standard error**, not confidence intervals. Associations are unadjusted and observational; zero final grades do not identify dropout without additional records.

Previous grades and past failures show associations with final grade. Absences have Spearman correlation **+0.0177**, so this dataset does not support the previously stated strong negative absence relationship. The figures do not identify intervention effects or causes of student outcomes.

## Decision tree and evaluation

The target is passing versus failing. G1, G2 and G3 are excluded from predictors, leaving **30 original input variables**. A stratified 70/30 split gives 277 training and 118 test observations. Ten-fold training cross-validation chooses `cp` from 34 values between 0.001 and 0.1 by ROC AUC; the selected value is **0.016**.

| Held-out metric | Value |
| :--- | ---: |
| Accuracy | 59.32% |
| Training-majority prediction accuracy on test | 66.95% |
| Accuracy difference from baseline | -7.63 percentage points |
| Balanced accuracy | 48.20% |
| Kappa | -0.0408 |
| Sensitivity for passing | 81.01% |
| Specificity for failing | 15.38% |
| Precision for passing | 65.98% |

The confusion matrix contains 64 correctly predicted passes, 6 correctly predicted failures, 33 failures predicted as passes and 15 passes predicted as failures. Low failure recall limits any proposed use for identifying students who need support. The displayed tree describes this fitted model; its leaf probabilities are not evidence of causal pathways.

## Running

Use the [shared R environment instructions](../RUNNING.md). From this project directory:

```bash
Rscript analysis.R
Rscript -e "rmarkdown::render('report.Rmd', output_file='Student_Performance_Report.pdf')"
```

PDF rendering requires Quarto/Pandoc and XeLaTeX. The scripts use seed 123 for splitting and model fitting; package versions and numerical libraries also affect reproducibility.

## Selected data definitions

| Variable | Meaning |
| :--- | :--- |
| G1, G2, G3 | First-period, second-period and final grades, 0–20 |
| Medu, Fedu | Parental education codes: 0 none, 1 fourth grade, 2 fifth–ninth grade, 3 secondary, 4 higher education |
| studytime | Weekly study categories: 1 under 2 hours, 2 from 2–5, 3 from 5–10, 4 over 10 |
| failures | Coded previous class failures |
| absences | Recorded school absences |
| higher | Whether the student wants higher education |
| Dalc, Walc | Workday/weekend alcohol-consumption codes, 1–5 |

**Author:** Alejandro Treny Ortega
