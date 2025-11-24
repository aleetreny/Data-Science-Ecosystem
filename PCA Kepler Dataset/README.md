# Dimensionality Reduction: Principal Component Analysis of the Kepler KOI Dataset

##  Project Overview

This project applies **Principal Component Analysis (PCA)** to astronomical data from the NASA Kepler Space Telescope. The goal is to explore the hidden structure of exoplanet candidates (Kepler Objects of Interest, or KOI) by reducing high-dimensional data into interpretable underlying components.

Starting with a dataset of over 8,000 observations and 153 variables, we performed a rigorous statistical analysis to:
1.  **Select** relevant stellar and planetary features.
2.  **Validate** the use of PCA via correlation analysis (checking for multicollinearity).
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

Our analysis successfully reduced the dataset from **10 correlated variables** to **4 uncorrelated Principal Components (PCs)**, explaining **over 85% of the total variance**.

Through biplots and factor loading analysis, we identified the physical meaning of these new dimensions:

* **PC1 (Stellar Scale):** Represents the size and temperature of the host star (Correlation between Radius and Temperature).
* **PC2 (Orbital Dynamics):** Represents the distance and period of the planet's orbit.
* **PC3 (Planet Size):** Captures the transit depth and planetary radius.
* **PC4 (Stellar Evolution):** A secondary axis capturing the evolutionary stage of the system.

> **Conclusion:** The analysis proves that stellar properties (host star) and orbital mechanics (planet behavior) are statistically independent phenomena in this dataset.

##  Technologies & Libraries

The analysis was conducted in **R** using **Quarto** for reporting. Key libraries include:

* **Data Manipulation:** `tidyverse`, `dplyr`, `tidyr`
* **Visualization:** `ggplot2`, `plotly` (3D plots), `ggridges`
* **PCA & Stats:** `ggcorrplot`, `GGally`, `broom`, `ggforce`

##  How to Run

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-username/kepler-pca-analysis.git](https://github.com/your-username/kepler-pca-analysis.git)
    ```
2.  **Open the project in RStudio.**
3.  **Install required packages:**
    ```r
    install.packages(c("tidyverse", "ggplot2", "plotly", "ggcorrplot", "GGally", "quarto"))
    ```
4.  **Render the Report:**
    Open `Report.qmd` and click the **Render** button to generate the HTML or PDF analysis.
    *Alternatively, run `Code.R` to execute the analysis line-by-line.*

##  Authors

* **Alejandro Treny Ortega**

---
*Data Source: NASA Exoplanet Archive*
