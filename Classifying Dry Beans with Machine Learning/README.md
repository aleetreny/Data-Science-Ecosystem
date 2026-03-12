# Classifying Dry Beans with Machine Learning

A comparative study of KNN, SVM, Decision Trees, Random Forests, and Neural Networks on the [UCI Dry Bean Dataset](https://archive.ics.uci.edu/dataset/602/dry+bean+dataset).

**Authors:** Alejandro Treny & Ignacio Ortiz

---

## Overview

This project applies and evaluates four families of supervised classification algorithms on a real-world agricultural dataset. Given 16 morphological measurements extracted from high-resolution images of individual beans, the goal is to identify which of seven dry bean varieties each grain belongs to.

The analysis follows a consistent evaluation protocol across all methods: same train/test split, same preprocessing pipeline, and the same metrics (accuracy, macro F1, per-class precision/recall). Each section also digs into what the model's internal structure reveals about the geometry of the problem — not just how well it performs, but *why*.

---

## Dataset

| Property | Value |
|---|---|
| Source | UCI ML Repository — [ID 602](https://archive.ics.uci.edu/dataset/602/dry+bean+dataset) |
| Reference | Koklu & Ozkan (2020), *Computers and Electronics in Agriculture* |
| Samples | 13,611 bean grains |
| Features | 16 morphological descriptors (size, shape, elongation, composite indices) |
| Classes | 7 (BARBUNYA, BOMBAY, CALI, DERMASON, HOROZ, SEKER, SIRA) |
| Missing values | None |
| Train / Test split | 10,888 / 2,723 (80/20, stratified, `SEED=42`) |

---

## Methods & Results

| Method | Key Hyperparameter | Test Accuracy | Macro F1 | Needs Scaling |
|---|---|---|---|---|
| Decision Tree | `max_depth=10` | 0.9071 | 0.9208 | No |
| Random Forest | `n=200`, OOB=0.9257 | 0.9199 | 0.9321 | No |
| KNN | `k=30` | 0.9207 | 0.9328 | Yes |
| Linear SVM | `C=5` | 0.9232 | 0.9344 | Yes |
| RBF SVM | `C=50`, `gamma=scale` | 0.9262 | 0.9376 | Yes |
| MLP | `256-128-64-32` | **0.9284** | **0.9396** | Yes |

**Key finding:** the ~0.008 accuracy spread across all competitive methods reflects an irreducible SIRA/DERMASON overlap in feature space — the bottleneck is in the data geometry, not the choice of algorithm.

---

## Notebook Structure

```
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
│   └── PCA visualisation (81.9% variance retained)
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
│   ├── OOB score as free validation estimate
│   └── Feature importance: Tree vs. Forest vs. SVM
│
└── 5. Neural Networks (MLP)
    ├── Architecture sweep (5 configurations)
    ├── Training curve with early stopping
    ├── Final confusion matrix
    └── All-methods comparison
```

---

## Requirements

```
python >= 3.9
scikit-learn
numpy
pandas
matplotlib
seaborn
plotly
ucimlrepo
```

Install all dependencies with:

```bash
pip install ucimlrepo scikit-learn matplotlib seaborn plotly
```

The dataset is fetched automatically at runtime via `ucimlrepo`:

```python
from ucimlrepo import fetch_ucirepo
dry_bean = fetch_ucirepo(id=602)
```

---

## Running the Notebook

The notebook is written in [Quarto](https://quarto.org/) (`.qmd`) and uses a Jupyter kernel. To render it:

```bash
# Install Quarto: https://quarto.org/docs/get-started/
quarto render notebook.qmd
```

Or to preview it interactively:

```bash
quarto preview notebook.qmd
```

Make sure your Jupyter environment is named `my_env` (as specified in the YAML header), or update the `jupyter:` field to match your kernel name.

---

## Highlights

- **BOMBAY** is perfectly classified (F1 = 1.000) by every method — it is morphologically the largest variety and occupies a fully isolated region of the feature space.
- **SIRA/DERMASON** is the dominant confusion pair across all methods, accounting for ~50 misclassifications per model regardless of algorithm complexity.
- The **linear SVM coefficient analysis** shows that elongation features (ShapeFactor1, AspectRation, Eccentricity) are more discriminative than raw size — a non-obvious result.
- The **random forest** spreads feature importance far more evenly than the single tree, exposing correlations that tree greedy splitting would otherwise suppress.
- The **MLP** achieves the highest accuracy (0.9284) but offers no interpretability advantage over the RBF SVM (0.9262), making the SVM the better practical choice when explainability matters.
