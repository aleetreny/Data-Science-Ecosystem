# Probabilistic Cancer Classification via RNA-Seq Data

You can view the complete project report directly by opening the [`notebook.html`](notebook.html) file in your browser.

This project focuses on applying **Statistical Learning** techniques for the multiclass classification of different cancer types using gene expression data (**RNA-Seq**). The goal is to develop a model capable of **correctly classifying the origin of tumor tissue** based solely on its gene expression profile.

## Dataset

This project utilizes an extraction of the **TCGA Pan-Cancer (PANCAN)** dataset.

### How to obtain the data

1. Go to the [UCI Machine Learning Repository - Gene Expression Cancer RNA-Seq Dataset](https://archive.ics.uci.edu/dataset/401/gene+expression+cancer+rna+seq).
2. Click on the **Download** button.
3. Extract the downloaded zip file.
4. You will need two specific files:
   - `data.csv`: The gene expression matrix.
   - `labels.csv`: The class labels for each sample.
5. Place these two files (`data.csv` and `labels.csv`) in the root directory of this project.

### Dataset Characteristics

- **Samples:** 801 individuals diagnosed with a type of tumor.
- **Variables:** 20,531 genes.
- **Classes:** 5 distinct tumor types (BRCA, KIRC, COAD, LUAD, PRAD).

## Methodology

To handle the high dimensionality of the data ($p \gg n$), we employ **Dimensionality Reduction** using **Principal Component Analysis (PCA)**. We then implement and compare the following probabilistic models:

1. **Linear Discriminant Analysis (LDA)**
2. **Quadratic Discriminant Analysis (QDA)**
3. **Naive Bayes**
4. **Multinomial Logistic Regression**

## Results

- **LDA** and **QDA** achieved **100% accuracy** on the held-out test set.
- **Multinomial Logistic Regression** achieved **98.7% accuracy**.
- **Naive Bayes** achieved **98.1% accuracy**.

These results demonstrate that the gene expression profiles of these five cancer types are highly distinct and can be accurately classified using probabilistic methods combined with PCA.

## How to Run

This project is structured as a **Quarto** notebook.

1. Ensure you have R installed along with the required packages: `tidyverse`, `caret`, `MASS`, `e1071`, `naivebayes`, `nnet`, `factoextra`, `DT`, `pheatmap`, and `uwot`.
2. Open `notebook.qmd` in RStudio or VS Code (with Quarto extension).
3. Render the notebook to HTML or run the code chunks interactively.
