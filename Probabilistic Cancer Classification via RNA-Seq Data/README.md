# Probabilistic Cancer Classification via RNA-Seq Data

Open the complete [HTML report](index.html), generated from [notebook.qmd](notebook.qmd).

This exploratory study classifies five tumor labels from gene expression in the
UCI TCGA Pan-Cancer snapshot: 801 samples, 20,531 genes, and the BRCA, KIRC,
COAD, LUAD and PRAD classes. It evaluates this dataset, not clinical diagnosis
or performance on an independent patient cohort.

## Data and execution

Download the [UCI Gene Expression Cancer RNA-Seq dataset](https://archive.ics.uci.edu/dataset/401/gene+expression+cancer+rna+seq).
Extract the ZIP and its nested archive until `data.csv` and `labels.csv` are
available. Put both beside the notebook, or set `RNA_SEQ_DATA_DIR` to their
directory. The loader checks unique sample identifiers, matching sample sets
and finite measurements before joining labels by identifier.

Use the shared [R/Quarto environment](../RUNNING.md), including `tidyverse`,
`caret`, `MASS`, `e1071`, `naivebayes`, `nnet`, `factoextra`, `DT`, `pheatmap`,
`uwot` and `patchwork`. From this directory run:

```bash
quarto render notebook.qmd --to html
```

## Evaluation

The seeded stratified split contains 642 training and 159 test samples.
Exploratory feature comparisons use training samples only. Ten-fold training
cross-validation selects the number of principal components separately for
each model, fitting scaling and PCA inside every fold. The chosen pipelines
are then refitted on all training samples and evaluated on the held-out test.

| Model | Selected PCs | Test accuracy |
|---|---:|---:|
| Linear discriminant analysis | 100 | 100.00% |
| Quadratic discriminant analysis | 10 | 100.00% |
| Multinomial logistic regression | 50 | 100.00% |
| Gaussian naive Bayes | 50 | 97.48% |

The notebook checks covariance feasibility, logistic convergence and absence
of sample-ID or exact feature-vector overlap. A fixed 50-PC label-shuffling
control scores 28.93%, compared with a 37.74% majority baseline. These checks
can expose simple pipeline errors; they do not exclude unrecorded batch,
cohort or biological dependencies. The high test accuracies apply to this
single partition. Repeated external-cohort evaluation would be needed for a
broader performance claim.
