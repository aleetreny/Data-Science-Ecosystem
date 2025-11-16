# Melanoma Image Segmentation using ICA and Orthogonal Projections

## Overview

This repository contains two complementary R projects that implement **Independent Component Analysis (ICA)** and **orthogonal projections** to segment dermatological images, specifically melanoma lesions from healthy skin. Both projects apply the concept of finding optimal linear subspaces that maximize class separability using the **Fisher Index** as the optimization criterion.

The primary goal is to identify projections in the whitened RGB color space that best distinguish between two classes (melanoma vs. non-melanoma tissue) by maximizing bimodality in the projected data.

---

## Project 1: Sequential Implementation (`First_Approach.R`)

### Description

The first project implements a straightforward, loop-based approach to discover optimal projection directions. It serves as the foundational implementation and is ideal for understanding the core concepts.

### Key Features

- **Image Processing**: Reads and visualizes melanoma images in full resolution
- **Data Whitening**: Transforms RGB data to zero mean with identity covariance matrix using eigendecomposition
- **Sequential Search**: Uses explicit for-loops to exhaustively test 64,800 projection directions on a 3D sphere (360° × 180° in spherical coordinates)
- **Fisher Index Optimization**: Evaluates each projection direction by:
  - Projecting whitened data onto the direction vector
  - Clustering projected 1D data into two groups using k-means
  - Computing the Fisher Index: \(FI = \frac{(\mu_1 - \mu_2)^2}{\sigma_1^2 + \sigma_2^2}\)
- **Orthogonal Component Discovery**: Sequentially finds IC2 (orthogonal to IC1) and IC3 (orthogonal to both IC1 and IC2)
- **Visualization**: Generates histograms, segmentation masks, grayscale projections, and 3D optimization surfaces

### Workflow

1. **Load and Subsample Image**: Reads melanoma image and subsamples (1 out of every 4 pixels) for faster computation
2. **Whiten Data**: Converts RGB channels to a matrix and applies whitening transformation
3. **Find IC1**: Searches entire sphere to find the projection maximizing the Fisher Index
4. **Find IC2**: Searches only the orthogonal circle to find the best perpendicular projection
5. **Find IC3**: Calculates as the cross product of IC1 and IC2
6. **Output**: Binary segmentation masks and grayscale projection images

### Main Functions/Sections

```r
# Core operations:
readImage()              # Load melanoma image
scale()                  # Center data
eigen()                  # Eigendecomposition for whitening
kmeans()                 # Cluster projected data
pracma::cross()          # Calculate orthogonal vectors
```

### Expected Output

- Histograms of each projection showing bimodal distributions
- Binary segmentation maps distinguishing melanoma from skin
- 3D surface plot of the Fisher Index optimization landscape
- Grayscale representations of each orthogonal projection

### Performance Considerations

- **Computation Time**: Approximately 10-30 minutes (depending on hardware)
- **Memory Usage**: Moderate; subsampling reduces pixel count significantly
- **Best Use**: Educational purposes, algorithm understanding, and prototyping

---

## Project 2: Parallel Implementation (`Second_Approach.R`)

### Description

The second project encapsulates the algorithm within a single, reusable function that implements **parallel computing** to dramatically accelerate the optimization process. It processes full-resolution images without subsampling and includes configurable k-means parameters.

### Key Features

- **Parallelized IC1 Search**: Distributes the 64,800 direction tests across multiple CPU cores using `foreach` and `doParallel`
- **Full Resolution Processing**: No subsampling required; operates on complete image data
- **Reusable Function**: Self-contained function with clear parameter interface
- **Automatic Library Management**: Automatically installs and loads required packages
- **Configurable k-means**: Adjustable `nstart` and `niter` parameters (defaults: 5 and 25)
- **Vectorized Output**: Returns a 3D array containing all three orthogonal projections

### Function Signature

```r
findOptimalProjections(image_path, nstart_kmeans = 5, niter_kmeans = 25)
```

**Parameters:**
- `image_path`: String path to the input image (e.g., "Melanoma.jpg")
- `nstart_kmeans`: Number of random initializations for k-means (default: 5)
- `niter_kmeans`: Maximum iterations for k-means algorithm (default: 25)

**Returns:**
- 3D array of dimensions (height, width, 3), where each layer contains the grayscale projection for IC1, IC2, and IC3

### Workflow

1. **Initialize**: Set up parallel backend using all available cores minus one
2. **Load and Prepare**: Read full-resolution image and store original dimensions
3. **Whiten Data**: Apply identical whitening transformation as Project 1
4. **Parallel IC1 Search**: Distribute 64,800 projection evaluations across cores using `%dopar%`
5. **Sequential IC2 Search**: Search orthogonal circle (much faster, remains sequential)
6. **Calculate IC3**: Determine using cross product
7. **Generate Outputs**: Project whitened data onto all three directions and reshape to images
8. **Return**: 3D array containing all projection images

### Main Libraries Used

```r
library(OpenImageR)    # Image I/O and processing
library(foreach)       # Parallel loop framework
library(doParallel)    # Parallel backend registration
library(pracma)        # Cross product for vector algebra
```

### Expected Performance

- **Speedup**: 4-8× faster than sequential version (depending on CPU cores)
- **Computation Time**: 2-5 minutes on typical modern hardware (8-core processor)
- **Memory Usage**: Higher due to parallel cluster creation, but manageable
- **Scalability**: Linear speedup with additional CPU cores (up to practical limits)

### Usage Example

```r
# Load the function
source("Second_Approach.R")

# Process the melanoma image
projections <- findOptimalProjections("Melanoma.jpg", nstart_kmeans = 10, niter_kmeans = 30)

# Visualize the results
par(mfrow = c(1, 3), mar = c(1, 1, 3, 1))
image(projections[,,1], main = "IC1", col = grey.colors(256))
image(projections[,,2], main = "IC2", col = grey.colors(256))
image(projections[,,3], main = "IC3", col = grey.colors(256))
par(mfrow = c(1, 1))
```

---

## Mathematical Background

### Data Whitening

Whitening transforms centered data \(X\) such that the resulting matrix \(Z\) has an identity covariance matrix:

\[Z = (X - \mu) \cdot W\]

where \(W = E \cdot D^{-1/2}\), with \(E\) being the eigenvectors and \(D\) the eigenvalues of \(\text{Cov}(X)\).

### Fisher Index

For a 1D projection \(p = Z \cdot v\) clustered into two groups, the Fisher Index measures class separability:

\[FI = \frac{(\bar{p}_1 - \bar{p}_2)^2}{\sigma_1^2 + \sigma_2^2 + \epsilon}\]

Higher values indicate better separation between clusters.

### Spherical Coordinates

Projection directions in 3D are parameterized using spherical coordinates:

- **Azimuthal angle (θ)**: 0° to 360°
- **Polar angle (φ)**: 0° to 180°
- **Unit vector**: \(v(\theta, \phi) = [\cos(\theta)\sin(\phi), \sin(\theta)\sin(\phi), \cos(\phi)]\)

### Orthogonal Constraints

After finding IC1, IC2 is constrained to lie on the circle orthogonal to IC1:

\[v = \cos(\alpha) \cdot v_1 + \sin(\alpha) \cdot v_2\]

where \(v_1, v_2\) form an orthonormal basis for the plane perpendicular to IC1.

---

## Comparison: Sequential vs. Parallel

| Aspect | Project 1 (Sequential) | Project 2 (Parallel) |
|--------|----------------------|----------------------|
| **Image Processing** | Subsampled | Full resolution |
| **Computation** | for-loops | foreach %dopar% |
| **Speed** | ~15-30 minutes | ~2-5 minutes |
| **Scalability** | Limited | Excellent |
| **Complexity** | Simple, educational | Advanced, production-ready |
| **Parameters** | Hardcoded | Flexible function parameters |
| **Memory Usage** | Lower | Higher (cluster overhead) |
| **Code Length** | ~150 lines | ~200 lines (with comments) |

---

## File Structure

```
.
├── First_Approach.R       # Sequential implementation (educational)
├── Second_Approach.R      # Parallel implementation (production)
├── Melanoma.jpg           # Input dermatological image
└── README.md              # This file
```

---

## Installation & Requirements

### Required R Packages

```r
# Install if not already installed
packages <- c("OpenImageR", "foreach", "doParallel", "pracma", "Rfast", "plotly")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
  }
}

# Load packages
library(OpenImageR)
library(foreach)
library(doParallel)
library(pracma)
library(Rfast)
library(plotly)
```

### System Requirements

- **R Version**: 3.6.0 or higher
- **OS**: Windows, macOS, or Linux
- **Processor**: Multi-core CPU recommended for parallel version
- **RAM**: Minimum 4 GB, 8 GB recommended
- **Disk Space**: ~500 MB for dependencies

---

## How to Use

### Running Project 1 (Sequential)

```r
# Ensure Melanoma.jpg is in your working directory
# or update the readImage() path accordingly

# Source and run the script
source("First_Approach.R")

# The script automatically:
# 1. Loads the melanoma image
# 2. Performs whitening
# 3. Finds optimal projections
# 4. Generates visualizations
```

### Running Project 2 (Parallel)

```r
# Ensure Melanoma.jpg is in your working directory
# or update the image_path parameter accordingly

# Source the function definition
source("Second_Approach.R")

# The script automatically calls the function with the example image.
# To use with a different image or parameters, call:
results <- findOptimalProjections("Melanoma.jpg", nstart_kmeans = 10, niter_kmeans = 30)

# Access individual projections
ic1 <- results[,,1]
ic2 <- results[,,2]
ic3 <- results[,,3]

# Visualize
image(ic1, main = "First Independent Component", col = grey.colors(256))
```

---

## Output Interpretation

### Projection Images

Each of the three orthogonal projections reveals different aspects of the melanoma lesion:

- **IC1**: Typically the strongest discriminator between melanoma and skin
- **IC2**: Captures secondary structural variations orthogonal to IC1
- **IC3**: Orthogonal complement, completes the 3D basis

### Fisher Index Surface

The 3D surface plot (Project 1) shows how the Fisher Index varies across all spherical coordinates, with peaks indicating optimal projection directions.

### Segmentation Masks

Binary masks show the result of k-means clustering on each projection, where pixels are classified as either melanoma or healthy skin.

---

## Algorithm Complexity Analysis

### Computational Complexity

- **IC1 Search**: O(n_directions × n_pixels × n_kmeans_iterations)
  - n_directions = 64,800 (360 × 180)
  - n_pixels ≈ 76,800-307,200 (depending on resolution)
  - n_kmeans_iterations = 40 (default in Project 1)

- **IC2 Search**: O(n_angles × n_pixels × n_kmeans_iterations)
  - n_angles = 360 (only circular search)
  - Much faster than IC1 search

- **IC3 Calculation**: O(1) (cross product only)

### Parallelization Efficiency

With \(p\) cores, the IC1 search speedup is approximately:

\[\text{Speedup} \approx p \times (1 - f)\]

where \(f\) is the fraction of non-parallelizable code (typically 5-10%).

---

## Troubleshooting

### Issue: Image Not Found

**Solution**: Ensure `Melanoma.jpg` is in the current working directory. You can check your working directory with:

```r
getwd()

# Set the correct working directory
setwd("~/path/to/your/project")
```

### Issue: Package Installation Fails

**Solution**: Use alternative installation method or update R:

```r
# Try alternative repository
options(repos=c(CRAN="http://cran.r-project.org"))
install.packages("package_name")

# Or update packages
update.packages()
```

### Issue: Parallel Version Still Running After 10 Minutes

**Solution**: This is normal for full-resolution images. Monitor progress with your system's resource monitor (Task Manager on Windows, Activity Monitor on macOS).

### Issue: Memory Error on Large Images

**Solution**: Use the sequential version with subsampling, or increase available RAM. You can also reduce `nstart_kmeans` to lower memory consumption.

---

## Future Enhancements

1. **GPU Acceleration**: Implement CUDA/OpenCL for even faster computation
2. **Algorithm Variations**: Explore different independence measures (negentropy, kurtosis)
3. **Multi-class Segmentation**: Extend to more than two categories
4. **Cross-validation**: Implement training/testing split for robustness assessment
5. **Visualization Dashboard**: Create interactive Shiny application for real-time parameter tuning

---

## References

- Hyvärinen, A., & Oja, E. (2000). Independent Component Analysis: Algorithms and Applications. *Neural Networks*, 13(4-5), 411-430.
- ISIC Archive: https://www.isic-archive.com/ (Dermatological image dataset source)
- R Documentation: https://www.r-project.org/

---

## Author

**Alejandro Treny Ortega**

UC3M - Master's in Statistics for Data Science

---

## License

This project is provided as-is for educational purposes. Feel free to modify and distribute according to your institution's guidelines.

---

## Notes

- Both projects process the same melanoma image using different computational strategies
- The parallel version is recommended for production use and large-scale applications
- Results can vary slightly due to k-means random initialization; set seeds for reproducibility
- For optimal segmentation quality, consider tuning k-means parameters via the `nstart_kmeans` and `niter_kmeans` arguments
- Ensure the image file is in the same directory as your R scripts, or provide the full path to the image

---

**Last Updated**: November 2025