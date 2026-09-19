# The Matrix Chain Ordering Problem

[Portfolio](../README.md) · [Execution guide](../RUNNING.md) · [Report source](notebook.qmd)

This project contains the deliverable for the High-Performance Computing challenge on the **matrix chain ordering problem**. The main artifact is a Quarto report, [notebook.qmd](notebook.qmd), which combines R, RcppArmadillo, benchmarks, plots, discussion, and references.

Quick links:

- Source notebook: [notebook.qmd](notebook.qmd)
- Rendered report: [notebook.html](notebook.html)
- Assignment brief: [assigment.md](assigment.md)

The report covers the four tasks from the assignment:

1. A 5-matrix example where naive left-to-right multiplication is much worse than a good parenthesization.
2. A naive C++ implementation with RcppArmadillo.
3. A generic C++ execution engine driven by an RPN multiplication plan.
4. Automatic optimization with dynamic programming, plus parallel and resource-aware variants.

## Project structure

```text
.
├── README.md
├── .dockerignore
├── .gitignore
├── Dockerfile
├── assigment.md
├── notebook.qmd
└── notebook.html
```

## Docker build recipe

The Dockerfile provides an optional R/Quarto build recipe with OpenMP compiler flags. The audit used the [shared local R environment](../RUNNING.md) with OpenMP active; this container image was not built during that review.

What the container pins:

- `R 4.5.1`
- Quarto CLI `1.6.42`

The compiler, operating-system packages and R dependencies are installed from their repositories at image build time; their versions are not pinned.

What Docker does **not** fully pin:

- Raw benchmark times across machines
- CPU-specific BLAS performance
- Thread scheduling and available core count

Docker provides a common build recipe, not a fully locked software stack. Dependency versions and benchmark numbers can change between builds.

Download the committed [notebook.html](notebook.html) and open it locally to read the interactive report. The commands below build an environment and regenerate that report; check the notebook output to confirm whether OpenMP is active.

### Build the image

```bash
docker build -t matrix-chain-ordering .
```

### Render the report and export the HTML

```bash
mkdir -p output
docker run --rm \
  -v "$(pwd)/output:/output" \
  matrix-chain-ordering
```

The container renders `notebook.qmd` and copies the generated HTML to:

```text
output/notebook.html
```

### Rebuild only when needed

Rebuild the image after changing:

- `Dockerfile`
- the list of R dependencies
- the Quarto version
- the notebook source copied into the image

The image copies the notebook at build time, so rebuild it after changing the source, or bind-mount the project when running it.

### Optional: control OpenMP threads

The container defaults to `OMP_NUM_THREADS=4`. You can request fewer threads at runtime; the notebook caps its parallel comparison at four:

```bash
docker run --rm \
  -e OMP_NUM_THREADS=2 \
  -v "$(pwd)/output:/output" \
  matrix-chain-ordering
```

This is useful if you want to explore the parallel Task 4 implementation under different thread counts.

## Local execution

If you prefer to run everything directly on your machine, you need:

- R (the local audit used `4.5.3`)
- Quarto CLI
- A C++17 compiler
- These R packages:

```r
install.packages(c(
  "Rcpp", "RcppArmadillo",
  "bench",
  "ggplot2", "dplyr", "tidyr", "scales",
  "knitr", "rmarkdown"
))
```

Then render with:

```bash
quarto render notebook.qmd --to html
```

If your local compiler is not configured with OpenMP, the notebook still renders and the wavefront DP remains correct, but the parallel section will fall back to sequential execution. Check the reported OpenMP status before interpreting a timing as a parallel benchmark.

## Expected takeaway

The examples illustrate three points; their exact timing gains depend on matrix dimensions, hardware and numerical libraries:

- Choosing a good multiplication order can save far more work than switching from R to C++ while keeping a bad order.
- A generic execution engine can preserve that gain without sacrificing flexibility.
- Dynamic programming automates the choice of order for the stated cost model.
