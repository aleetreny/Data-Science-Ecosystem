# Dimensionality Reduction: Principal Component Analysis of the Kepler KOI Dataset

##  Project Overview

This project applies **Principal Component Analysis (PCA)** to astronomical data from the NASA Kepler Space Telescope. The goal is to explore the hidden structure of exoplanet candidates (Kepler Objects of Interest, or KOI) by reducing high-dimensional data into interpretable underlying components.

Starting with a dataset of over 8,000 observations and 153 variables, we performed a rigorous statistical analysis to:
1.  **Select** relevant stellar and planetary features.
2.  **Describe** correlation structure before PCA.
3.  **Reduce** dimensionality while retaining the majority of the variance.
4.  **Interpret** the new components in the context of astrophysics.

##  Repository Structure

This repository contains three key files:

| File | Description |
| :--- | :--- |
| **`Report.qmd`** | The **primary narrative document**. A Quarto file that generates a fully formatted HTML/PDF report containing the methodology, code, visualizations, and final conclusions. |
| **`Code.R`** | The **raw R script** containing the complete analysis pipeline. It includes data cleaning, correlation matrices, PCA calculation, and advanced plotting (2D Biplots, 3D interactive plots). |
| **`df_koi.csv`** | The **dataset**. A subset of the NASA Exoplanet Archive containing the Kepler KOI data used for this analysis. |

##  Key Findings

The source contains **8,054 KOI records and 153 columns**. Ten selected numeric variables have **7,994 complete rows**. Eight are transformed with `log10(x+1)`; surface gravity and magnitude retain their existing logarithmic scales. Both the script and report standardize this same transformed matrix.

The first four components retain **86.651%** of standardized variance. PC1 emphasizes stellar radius, mass and surface gravity; PC2 combines period, duration and insolation; PC3 contrasts transit depth and inferred radius with other inputs; PC4 has a strong stellar-temperature loading. These are descriptions of coefficients, not isolated physical mechanisms. Component signs are arbitrary, and uncorrelated PCA scores do not imply statistical independence of the original phenomena.

The correlation circle uses eigenvectors multiplied by component standard deviations. Comparisons against threshold-derived labels are descriptive because those labels reuse input variables. Sixteen Wilcoxon comparisons report Holm-adjusted p-values; they are not independent validation of astrophysical classes.

##  Technologies & Libraries

The analysis was conducted in **R** using **Quarto** for reporting. Key libraries include:

* **Data Manipulation:** `tidyverse`, `dplyr`, `tidyr`
* **Visualization:** `ggplot2`, `plotly` (3D plots), `ggridges`
* **PCA & Stats:** `ggcorrplot`, `GGally`, `broom`, `ggforce`

##  How to Run

Use the [shared R/Quarto environment](../RUNNING.md). From this project directory:

```bash
Rscript Code.R
quarto render Report.qmd --to html
```

The HTML report contains interactive plots. A PDF render uses static fallbacks. Source column meanings follow the [NASA Exoplanet Archive KOI documentation](https://exoplanetarchive.ipac.caltech.edu/docs/API_kepcandidate_columns.html): transit depth is in ppm, `kepid` identifies the target star, and `koi_fpflag_ss` is the stellar-eclipse flag.

##  Authors

* **Alejandro Treny Ortega**

---
*Data Source: NASA Exoplanet Archive*
