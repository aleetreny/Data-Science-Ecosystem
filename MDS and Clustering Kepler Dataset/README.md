# Kepler KOI: Mixed-Type MDS and Clustering Analysis

This project performs a comprehensive Multidimensional Scaling (MDS) and Clustering analysis on the **Kepler Object of Interest (KOI)** dataset. Using advanced statistical techniques for mixed-type data, the analysis aims to separate true planetary candidates from instrumental noise and astrophysical false positives (like eclipsing binaries).

## Overview

The analysis is divided into two major phases:
1.  **Phase I: MDS Analysis (RelMS):** Construction of a joint metric space that integrates quantitative, binary, and categorical variables while removing inter-group redundancy.
2.  **Phase II: Clustering & Profiling:** Unsupervised discovery of sub-populations within the Kepler data and physical characterization of the resulting clusters.

## Key Methodologies

### 1. Mixed-Type Distance Metrics
To handle the heterogeneous nature of the data, specific distances are applied to different variable types:
* **Quantitative:** Robust Mahalanobis distance (via MCD) to account for covariance between stellar properties (Mass, Radius, Temp).
* **Binary:** Jaccard distance to handle sparse flag data (e.g., False Positive flags).
* **Categorical:** Hamming (Matching) distance for discretized classes (Insolation and Magnitude levels).

### 2. Relationship Metric Space (RelMS)
The project implements the **RelMS** algorithm to:
* Ensure **commensurability** by scaling matrices based on geometric variability ($V_k$).
* Remove **redundancy** between data sources using a cross-product correction term in the Gram matrix construction.
* Apply **Constant Shift** to ensure the resulting distance matrix is Euclidean for MDS projection.

### 3. Clustering Logic
* **Tendency:** Validated via the **Hopkins Statistic** and **VAT (Visual Assessment of Tendency)**.
* **Hierarchy:** Agglomerative clustering using **Ward’s Method** to identify the tree structure.
* **Partitioning:** **PAM (Partitioning Around Medoids)** used for the final 7-cluster solution, determined by Elbow and Silhouette optimization.

## Project Structure

### Phase I: MDS Workflow
* **Data Preparation:** Log-transformation of skewed physical variables and sample reduction ($N=1000$).
* **Metric Construction:** Calculation of $D_1^2$, $D_2^2$, and $D_3^2$ and assembly into the Joint RelMS Metric.
* **Stability Analysis:**
    * **Jackknife:** Procrustes alignment to measure positional uncertainty of objects.
    * **Bootstrap:** Eigenvalue stability to confirm the dominance of MDS dimensions.
* **Interpretation:** Correlation heatmaps and "Snake Plots" (trajectories) to map physical variables onto the MDS dimensions.

### Phase II: Clustering Workflow
* **Optimization:** Comparing $k=2$ (Binary Hypothesis) vs $k=7$ (Granular Reality).
* **Validation:** Adjusted Rand Index (ARI) to compare clusters against official NASA dispositions.
* **Profiling:**
    * **Snake Plots:** Standardized Z-score "DNA" for each cluster.
    * **Radar/Spider Charts:** Multivariate comparison of cluster properties.
    * **Relative Importance Heatmaps:** Percentage deviation from the global mean.

## Final Insights

The analysis reveals that the Kepler dataset is best described by a **7-cluster model**:

* **Signal Clusters:** Identified "Warm Super-Earths" (best candidates) and "Scorched Sub-Neptunes".
* **Noise Clusters:** Successfully isolated "Instrumental Artifacts" and "Eclipsing Binaries" based on physical impossibility (extreme radii) and high error-flag percentages.
* **Methodological Value:** RelMS proved superior to standard Gower by effectively de-noising the geometry, providing a clearer separation between astrophysical signal and noise.

**Data Source:** NASA Exoplanet Archive (Kepler Candidate Columns).
