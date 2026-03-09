FROM rocker/verse:4.5.1

ARG QUARTO_VERSION=1.6.42

ENV DEBIAN_FRONTEND=noninteractive
ENV PKG_CXXFLAGS="-O3 -fopenmp"
ENV PKG_LIBS="-fopenmp"
ENV OMP_NUM_THREADS=4

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    curl \
    libomp-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && apt-get update \
    && apt-get install -y --no-install-recommends "./quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && rm "quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages(c('Rcpp', 'RcppArmadillo', 'bench'), repos = 'https://cloud.r-project.org', Ncpus = 1L); \
pkgs <- c( \
  'Rcpp', 'RcppArmadillo', \
  'bench', \
  'ggplot2', 'dplyr', 'tidyr', 'scales', \
  'knitr', 'rmarkdown' \
); \
missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; \
if (length(missing)) stop('Missing R packages: ', paste(missing, collapse = ', '))"

WORKDIR /project
COPY . /project
RUN mkdir -p /output

CMD ["bash", "-lc", "quarto render notebook.qmd --to html && if [ -d /output ]; then cp notebook.html /output/notebook.html; fi"]
