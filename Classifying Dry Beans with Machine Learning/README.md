# Classifying Dry Beans with Machine Learning

[Portfolio](../README.md) · [Execution guide](../RUNNING.md) · [Report source](notebook.qmd)

A comparative study of KNN, SVM, Decision Trees, Random Forests, and Neural Networks on the [UCI Dry Bean Dataset](https://archive.ics.uci.edu/dataset/602/dry+bean+dataset).

------------------------------------------------------------------------

## Overview

This project applies and evaluates four families of supervised classification algorithms on a real-world agricultural dataset. Given 16 morphological measurements extracted from high-resolution images of individual beans, the goal is to identify which of seven dry bean varieties each grain belongs to.

The analysis uses one stratified train/test split for final reporting. Hyperparameters and preprocessing are selected inside cross-validation on the training partition, so the test partition is not used to choose a model.

------------------------------------------------------------------------

## Dataset

| Property | Value |
|------------------------------------|------------------------------------|
| Source | UCI ML Repository — [ID 602](https://archive.ics.uci.edu/dataset/602/dry+bean+dataset) |
| Reference | Koklu & Ozkan (2020), *Computers and Electronics in Agriculture* |
| Samples | 13,611 source rows; 13,543 unique records after removing 68 duplicates |
| Features | 16 morphological descriptors (size, shape, elongation, composite indices) |
| Classes | 7 (BARBUNYA, BOMBAY, CALI, DERMASON, HOROZ, SEKER, SIRA) |
| Missing values | None |
| Train / Test split | 10,834 / 2,709 (80/20, stratified, `SEED=42`) |

------------------------------------------------------------------------

## Methods & Results

| Method | Training-CV choice | Test accuracy | Macro F1 |
| :--- | :--- | ---: | ---: |
| Decision Tree | max_depth=8 | 0.894426 | 0.907051 |
| KNN | k=19 | 0.917682 | 0.929226 |
| Linear SVM | C=0.5 | 0.919158 | 0.931035 |
| Random Forest | 300 trees | 0.919897 | 0.931090 |
| MLP | 128–64 hidden units | 0.921742 | 0.9318 |
| RBF SVM | C=10, gamma=scale | 0.923588 | 0.934727 |

These are the regenerated results after removing duplicates and selecting configurations by training cross-validation. Differences on one test split do not establish a stable model ranking or an irreducible error floor. Scaling is used for KNN, SVM and MLP and fitted inside their CV folds.

------------------------------------------------------------------------

## Notebook Structure

``` text
notebook.qmd
│
├── 1. Introduction
│   ├── Dataset description & feature families
│   └── Class distribution
│
├── 2. k-Nearest Neighbors (KNN)
│   ├── Feature scaling motivation
│   ├── Bias-variance sweep (k = 1 … 30)
│   ├── Classification report & confusion matrix
│   └── PCA visualisation (retained variance reported in the notebook)
│
├── 3. Support Vector Machines (SVM)
│   ├── C sweep — linear and RBF kernels
│   ├── Per-class results & support vector analysis
│   ├── Side-by-side confusion matrices
│   └── Feature importance via |coefficient| magnitudes
│
├── 4. Decision Trees & Random Forests
│   ├── max_depth sweep (1 … 20)
│   ├── Tree visualisation (depth-4 readable structure)
│   ├── Random forest ensemble effect
│   ├── OOB diagnostic from training data
│   └── Feature importance: Tree vs. Forest vs. SVM
│
├── 5. Neural Networks (MLP)
│   ├── Architecture sweep (5 configurations)
│   ├── Training curve with early stopping
│   ├── Final confusion matrix
│   └── All-methods comparison
│
└── 6. Permutation Shapley Values: Explaining the Random Forest
    ├── Background: The Shapley Value
    ├── Global Feature Importance
    ├── Per-Class Feature Importance
    ├── Local Explanations: Waterfall Decompositions
    └── SHAP vs. Random Forest Impurity Importance
```

------------------------------------------------------------------------

## Requirements and execution

Use Python 3.12 and the [shared pinned environment](../RUNNING.md). Quarto must use the registered `data-science-ecosystem` Jupyter kernel. From this project directory:

```bash
quarto render notebook.qmd --to html
```

The dataset comes from UCI ID 602 via `ucimlrepo`; an existing `data/dry_beans.csv` cache can be reused. On affected Apple Silicon systems, follow the OpenBLAS-wheel instructions in the shared runtime guide rather than suppressing numerical warnings.

## Interpretation

The notebook reports per-class errors, model-specific feature importances and Monte Carlo permutation Shapley explanations for a fixed explained subset. Their decomposition is checked for every displayed instance and class. The marginal background construction can combine correlated measurements in unrealistic ways, and the small explained subset does not establish population-wide feature importance. These are explanations of fitted predictions, not causal effects or biological mechanisms.
