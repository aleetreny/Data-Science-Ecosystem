# Kepler KOI: Mixed-Type MDS and Clustering Analysis

This exploratory analysis combines numeric, binary and categorical Kepler KOI descriptors, constructs a joint dissimilarity and examines low-dimensional projections and clusters. It does not identify new planets or establish separation of physical signal from noise.

## Data and workflow

The bundled [df_koi.csv](df_koi.csv) contains 8,054 records and 153 source columns. [Code.r](Code.r) selects variables, handles complete cases, transforms skewed measurements and samples 1,000 rows with a fixed seed. The [NASA KOI column reference](https://exoplanetarchive.ipac.caltech.edu/docs/API_kepcandidate_columns.html) defines the inputs; `koi_fpflag_ss` means stellar-eclipse flag and transit depth is measured in ppm.

The script compares distances within three variable blocks:

- Numeric measurements: Euclidean, Manhattan and robust Mahalanobis distances.
- Binary flags: matching, Jaccard and Dice distances; two all-zero flag vectors have distance zero.
- Categorical measurements: matching distance for discretized insolation and magnitude.

A **RelMS-style construction** normalizes block Gram matrices by geometric variability and combines them using the cross-product formula shown in the source. Positive-semidefinite square roots are used for that construction. The code reports negative eigenvalues and applies a constant shift when required to obtain a Euclidean embedding. This particular implementation and correction should not be treated as a proven removal of redundancy or noise.

## Diagnostics and clustering

The corrected MDS coordinates retain only **1.36% of total positive eigenvalue mass in two dimensions** and **2.55% in five** in this execution. Low-dimensional displays therefore represent a small part of the corrected geometry. The constant shift contributes to the spectrum and must be considered when interpreting these percentages.

Repeated 90% subsampling with Procrustes alignment summarizes displacement; the plotted radii are mean resampling deviations, not confidence intervals or a formal leave-one-out jackknife. Bootstrap eigenvalue summaries assess variation under the stated resampling procedure.

The script includes Hopkins diagnostics, an ordinary ordered distance heatmap, hierarchical clustering and PAM comparisons. The heatmap is not a VAT algorithm. The seven-cluster solution is an exploratory choice alongside k=2; neither the elbow nor silhouette plots establish it as uniquely optimal.

ARI comparisons against dispositions and threshold-derived labels are descriptive. Several labels reuse the input variables, so they cannot provide independent validation. Cluster profiles show transformed-variable z-scores or relative physical-scale means, not predictive feature importance. Heuristic labels describe large inferred radius, insolation and flag prevalence; they do not establish planet composition, habitability or an instrumental cause. No measured superiority over Gower is claimed.

## Running

Use the [shared R environment](../RUNNING.md), then run from this directory:

```bash
Rscript Code.r
```

The script generates the figures and prints spectral, clustering and resampling diagnostics. Its covariance estimates, distance conventions and dimensional truncation are explicit modeling choices.
