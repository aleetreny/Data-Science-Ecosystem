# Data Science Ecosystem

**Alejandro Treny Ortega · Applied statistics, machine learning and scientific computing**

A portfolio of **22 studies across 18 project directories**, combining coursework and exploratory experiments in Python, R and C++. Each project includes its methods, code and interpretation; the project guides below identify the data and how to reproduce the analysis.

[Execution guide](RUNNING.md) · [Review and results](AUDIT.md) · [Dataset provenance](data-manifest.json)

## Statistical analysis and classification

| Study | Focus | Tools |
| :--- | :--- | :--- |
| [Dry Bean Classification](Classifying%20Dry%20Beans%20with%20Machine%20Learning/README.md) | Six classifiers, training cross-validation and prediction explanations | Python, scikit-learn, Quarto |
| [Student Performance](EDA%20and%20Decision%20Tree/README.md) | Exploratory associations and a decision tree with a majority baseline | R, caret, R Markdown |
| [RNA-Seq Classification](Probabilistic%20Cancer%20Classification%20via%20RNA-Seq%20Data/README.md) | PCA pipelines and four classifiers on a five-class tumor dataset | R, caret, Quarto |
| [Kepler PCA](PCA%20Kepler%20Dataset/README.md) | Standardized principal components and interpretation of astronomical measurements | R, Plotly, Quarto |
| [Kepler MDS and Clustering](MDS%20and%20Clustering%20Kepler%20Dataset/README.md) | Mixed-type distances, multidimensional scaling and cluster diagnostics | R |
| [RGB Projection Pursuit](Independent%20Component%20Analysis/README.md) | Fisher separation, whitening and sequential/parallel orthogonal projections | R, OpenImageR, foreach |
| [Music Evolution](Spotify%20EDA%20and%20Random%20Forest/README.md#music-evolution) | Playlist metadata and lyric-derived summaries from cached snapshots | Python, pandas, TextBlob |
| [Release-Decade Prediction](Spotify%20EDA%20and%20Random%20Forest/README.md#decade-prediction) | Random-forest classification of balanced Spotify audio features | Python, scikit-learn |

## Optimization and learning

| Study | Focus | Tools |
| :--- | :--- | :--- |
| [Linear Programming and Absolute-Error Regression](Optimization%20and%20Regression%20Modeling/README.md#project-1-linear-programming--mae-regression) | Resource balances, duality and regression as a linear program | Python, Gurobi, Plotly |
| [Mixed Integer Production Planning](Optimization%20and%20Regression%20Modeling/README.md#project-2-production-planning-milp) | Fixed costs, production tiers and logical constraints | Python, Gurobi, Quarto |
| [Matrix Chain Ordering](Matrix%20Chain%20Ordering%20Problem/README.md) | Dynamic programming, RPN execution and OpenMP benchmarks | R, RcppArmadillo, C++ |
| [Deep Q-Trading](Deep%20Q-Trading/README.md) | Chronological Bitcoin evaluation with explicit trading costs | Python, PyTorch, Gymnasium |
| [Generative Adversarial Networks](Generative%20Adversarial%20Networks/README.md) | DCGAN training and qualitative evaluation on MNIST | Python, PyTorch |
| [Neuroevolution](Stochastic%20Optimization%20via%20Neuroevolution/README.md) | Genetic optimization of LunarLander policies with separate test seeds | Python, Gymnasium |

## Simulations and image methods

| Study | Focus | Tools |
| :--- | :--- | :--- |
| [Epidemic Dynamics](Epidemic%20Dynamics%20Simulation/README.md) | Stochastic cellular automata and spatial scenario comparisons | Python, NumPy, SciPy |
| [Physarum Simulation](Physarum%20Polycephalum%20Simulation/README.md) | Particle sensing, trail deposition, diffusion and animation | Python, NumPy |
| [Monopoly Monte Carlo](Simulacio%CC%81n%20Montecarlo%20Monopoly/README.md) | Landing frequencies and simplified cash-flow scenarios | R, tidyverse |
| [Gray–Scott Patterns](Turing%20Patterns/README.md) | Reaction–diffusion dynamics on a periodic grid | Python, NumPy, Matplotlib |
| [Visual Steganography](Steganography/README.md) | RGB payload embedding, bit-depth trade-offs and lossless recovery | Python, NumPy, Pillow |

## Particle-physics computing prototypes

These three experiments are collected in the [CERN-inspired portfolio](CERN%20OpenLab/README.md).

| Study | Focus | Tools |
| :--- | :--- | :--- |
| [Anomaly Detection and Quantization](CERN%20OpenLab/Extreme-Scale%20Anomaly%20Detection/README.md) | Autoencoders on synthetic jets and quantized parameter export | Python, TensorFlow |
| [Neural Importance Sampling](CERN%20OpenLab/Neural%20Phase%20Integration/README.md) | Normalizing-flow proposals checked against a known integral | Python, PyTorch |
| [Hybrid Quantum Edge Classification](CERN%20OpenLab/Quantum%20GNN%20Tracking/README.md) | Classical and simulated quantum classifiers on one TrackML event | Python, PyTorch, PennyLane |

## Reproduce the work

Start with [RUNNING.md](RUNNING.md) for the tested Python 3.12, R 4.5.3 and Quarto environments, installation commands and project execution steps. The guide and audit are in Spanish; project READMEs are in English. Download a committed HTML report and open it locally to use its interactive plots.

Small datasets are included; larger inputs are downloaded or supplied separately as described in each project. Gurobi requires a suitable licence. Spotify/Genius credentials are needed only for optional music-data enrichment.

The [19 September 2026 review](AUDIT.md) records the reproduced results, **15 verification groups** and **20 dataset snapshots**, together with the specific limits of each check. Results describe the documented data, splits and simulation assumptions; individual project guides explain what would require further validation.
