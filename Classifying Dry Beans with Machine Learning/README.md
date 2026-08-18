# Classifying Dry Beans with Machine Learning

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
| Samples | 13,611 bean grains |
| Features | 16 morphological descriptors (size, shape, elongation, composite indices) |
| Classes | 7 (BARBUNYA, BOMBAY, CALI, DERMASON, HOROZ, SEKER, SIRA) |
| Missing values | None |
| Train / Test split | 10,888 / 2,723 (80/20, stratified, `SEED=42`) |

------------------------------------------------------------------------

## Methods & Results

| Method        | Selection protocol    | Final test metrics | Needs Scaling |
|---------------|---------------|---------------|---------------|
| Decision Tree | Training-fold CV      | Regenerate notebook | No            |
| Random Forest | Training-fold CV      | Regenerate notebook | No            |
| KNN           | Training-fold CV      | Regenerate notebook | Yes           |
| Linear SVM    | Training-fold CV      | Regenerate notebook | Yes           |
| RBF SVM       | Training-fold CV      | Regenerate notebook | Yes           |
| MLP           | Training-fold CV      | Regenerate notebook | Yes           |

The values in earlier rendered output predate the cross-validated selection protocol and are intentionally not retained as final results. Regenerate the notebook to obtain comparable held-out metrics; confusion patterns should be described as empirical observations, not irreducible error, unless supported by additional analysis.

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
├── 5. Neural Networks (MLP)
│   ├── Architecture sweep (5 configurations)
│   ├── Training curve with early stopping
│   ├── Final confusion matrix
│   └── All-methods comparison
│
└── 6. SHAP: Explaining the Random Forest
    ├── Background: The Shapley Value
    ├── Global Feature Importance
    ├── Per-Class Feature Importance
    ├── Local Explanations: Waterfall Decompositions
    └── SHAP vs. Random Forest Impurity Importance
```

------------------------------------------------------------------------

## Requirements

To run the notebook, you need `python >= 3.9` and the following dependencies:

``` bash
pip install ucimlrepo "scikit-learn>=1.8" numpy pandas matplotlib seaborn plotly torch ipykernel pyyaml nbformat nbclient notebook jupyter ipython
```

The dataset is fetched automatically at runtime via `ucimlrepo`:

``` python
from ucimlrepo import fetch_ucirepo
dry_bean = fetch_ucirepo(id=602)
```

------------------------------------------------------------------------

## Running the Notebook

The notebook is written in [Quarto](https://quarto.org/) (`.qmd`) and uses a Jupyter kernel. To render it:

``` bash
# Install Quarto: [https://quarto.org/docs/get-started/](https://quarto.org/docs/get-started/)
quarto render notebook.qmd
```

Or to preview it interactively:

``` bash
quarto preview notebook.qmd
```

Make sure your Jupyter environment is named `my_env` (as specified in the YAML header), or update the `jupyter:` field to match your kernel name.

------------------------------------------------------------------------

## Virtual environment (recommended)

Since this repository contains the notebook natively, you can easily create a virtual environment and install the required packages manually. Run the following commands from the repository root:

**On Windows (PowerShell):**

``` powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install ucimlrepo "scikit-learn>=1.8" numpy pandas matplotlib seaborn plotly torch ipykernel pyyaml nbformat nbclient notebook jupyter ipython
```

**On macOS / Linux:**

``` bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install ucimlrepo "scikit-learn>=1.8" numpy pandas matplotlib seaborn plotly torch ipykernel pyyaml nbformat nbclient notebook jupyter ipython
```

Note on `torch`:

- `torch` is listed in the dependencies because some analyses include it; if you do not need PyTorch you can remove it from the installation command.

- For GPU-enabled installs on Windows, prefer the official PyTorch install selector at https://pytorch.org/get-started/locally/ to obtain the correct wheel command.

------------------------------------------------------------------------

## Highlights

- **BOMBAY** is perfectly classified (F1 = 1.000) by every method — it is morphologically the largest variety and occupies a fully isolated region of the feature space.
- **SIRA/DERMASON** is the dominant confusion pair across all methods, accounting for \~50 misclassifications per model regardless of algorithm complexity.
- The **linear SVM coefficient analysis** shows that elongation features (ShapeFactor1, AspectRation, Eccentricity) are more discriminative than raw size — a non-obvious result.
- The **random forest** spreads feature importance far more evenly than the single tree, exposing correlations that tree greedy splitting would otherwise suppress.
- The **MLP** achieves the highest accuracy (0.9284) but offers no interpretability advantage over the RBF SVM (0.9262), making the SVM the better practical choice when explainability matters.
- **SHAP Analysis** reveals that the forest's classification strategy is heterogeneous: BOMBAY is identified purely by scale, SEKER by shape regularity composites, and DERMASON by a diffuse collective vote across many elongation and size features.
