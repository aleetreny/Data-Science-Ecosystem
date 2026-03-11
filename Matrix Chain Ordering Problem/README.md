# The Matrix Chain Ordering Problem

This repository contains the deliverable for the High-Performance Computing challenge on the **matrix chain ordering problem**. The main artifact is a Quarto report, [notebook.qmd](notebook.qmd), which combines R, RcppArmadillo, benchmarks, plots, discussion, and references.

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

## Reproducible execution with Docker

Docker is the recommended way to run the project if you want the same operating-system layer, R version, Quarto version, compiler toolchain, and OpenMP-capable C++ environment every time.

What the container pins:

- `R 4.5.1`
- Quarto CLI `1.6.42`
- Linux GCC toolchain with OpenMP
- The R packages required by the notebook

What Docker does **not** fully pin:

- Raw benchmark times across machines
- CPU-specific BLAS performance
- Thread scheduling and available core count

So Docker gives you a reproducible **software stack** and render process, but benchmark numbers can still vary somewhat with hardware.

The repository already includes a committed [notebook.html](notebook.html) for convenient viewing on GitHub, while Docker lets you regenerate it from scratch.
It is also the recommended path for the Task 4 parallel benchmarks, because the container explicitly enables OpenMP during compilation.

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

You only need to rebuild the image if you change:

- `Dockerfile`
- the list of R dependencies
- the Quarto version

If you only change the notebook contents, rebuild is still the simplest option, but the environment itself has not changed.

### Optional: control OpenMP threads

The container defaults to `OMP_NUM_THREADS=4`. You can override it at runtime:

```bash
docker run --rm \
  -e OMP_NUM_THREADS=8 \
  -v "$(pwd)/output:/output" \
  matrix-chain-ordering
```

This is useful if you want to explore the parallel Task 4 implementation under different thread counts.

## Local execution

If you prefer to run everything directly on your machine, you need:

- R `>= 4.5.0`
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

If your local compiler is not configured with OpenMP, the notebook still renders and the wavefront DP remains correct, but the parallel section will fall back to sequential execution. Docker avoids that ambiguity.

## Expected takeaway

The central conclusion of the project is stable even when the exact timings vary by machine:

- Choosing a good multiplication order matters far more than switching from R to C++ while keeping a bad order.
- A generic execution engine can preserve that gain without sacrificing flexibility.
- Dynamic programming makes the optimization step cheap enough to automate.
