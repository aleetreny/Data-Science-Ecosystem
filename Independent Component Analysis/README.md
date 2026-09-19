# Image Segmentation with Fisher Projection Pursuit and Orthogonal Projections

[Portfolio](../README.md) · [Execution guide](../RUNNING.md)

Two R implementations explore unsupervised colour partitions in a whitened RGB image. They search for projections that separate two k-means clusters according to a Fisher index, then construct an orthogonal basis.

The folder retains its original name, `Independent Component Analysis`, and the scripts label projections `IC1`, `IC2` and `IC3`. These labels refer to orthogonal projections: the algorithm does not establish statistical independence or provide a clinical melanoma classifier.

## Files and implementations

| File | Purpose |
| :--- | :--- |
| [First_Approach.R](First_Approach.R) | Sequential search, projection histograms, cluster maps and an interactive Fisher-index surface |
| [Second_Approach.R](Second_Approach.R) | Reusable parallel search function and full-resolution projection images |
| [Melanoma.jpg](Melanoma.jpg) | The RGB input used by both examples |

| Setting | Sequential example | Parallel example |
| :--- | :--- | :--- |
| Pixels analyzed | Every fourth row and column: 43,621 pixels | Full image: 694,564 pixels |
| First-direction grid | 64,800 angle pairs | 64,800 angle pairs |
| Second-direction grid | 360 angles in the orthogonal plane | 360 angles in the orthogonal plane |
| k-means restarts during search | 10 | 5 by default |
| k-means iteration limit during search | 40 | 25 by default |
| Worker processes | 1 | 2 by default |

These examples use different image resolutions and k-means settings, so their runtimes are not a controlled parallel-speedup comparison. Full-resolution searches can take hours; each worker needs its own working data. Reduce `workers` to limit memory use and use matching inputs and settings for timing comparisons.

## Method

1. Read the image and preserve the correspondence between each pixel and its RGB channels.
2. Center the three-channel matrix and whiten it using its covariance eigendecomposition.
3. Search a one-degree spherical grid for the direction with the largest observed Fisher index.
4. Search a one-degree circle in the perpendicular plane for the second direction.
5. Obtain the third direction from the normalized cross product and reshape the projected pixels into images.

### Whitening

For pixel matrix $X$, channel means $\mu$ and covariance decomposition $EDE^\top$, the whitened matrix is

$$
Z = (X - \mu)ED^{-1/2}.
$$

Its sample covariance is the identity up to numerical precision. Both scripts reject singular or ill-conditioned RGB covariance before inversion.

### Fisher index and search

For projection $p = Zv$, two-cluster k-means supplies means $\bar p_1,\bar p_2$ and sample variances $s_1^2,s_2^2$. The search evaluates

$$
FI = \frac{(\bar p_1 - \bar p_2)^2}{s_1^2 + s_2^2 + 10^{-10}}.
$$

The spherical directions are $v(\theta,\phi) = (\cos\theta\sin\phi,\sin\theta\sin\phi,\cos\phi)$, with integer degree values $\theta=1,\ldots,360$ and $\phi=1,\ldots,180$. This grid is finite and not uniform in surface area; it includes repeated pole directions and sign-equivalent axes. The selected maximum is over the tested grid and fitted k-means partitions, not all possible continuous directions or partitions.

The second search uses $v(\alpha)=\cos\alpha\,b_1+\sin\alpha\,b_2$, where $b_1,b_2$ span the plane perpendicular to the first direction. Orthogonality after whitening gives uncorrelated projection scores, which does not imply independence or clinically meaningful clusters. A high Fisher index measures separation of the fitted clusters; it is not a formal test of bimodality.

## Running the examples

Use the [shared R environment](../RUNNING.md), tested with R 4.5.3. Required packages are `OpenImageR`, `pracma`, `plotly`, `foreach` and `doParallel`. Start in this project directory with the image present:

```bash
Rscript First_Approach.R
Rscript Second_Approach.R
```

The first script runs its complete example. Running the second with `Rscript` executes its example; sourcing it defines the function without launching the full search.

For a custom RGB image, use this R example:

```r
source("Second_Approach.R")
projections <- findOptimalProjections(
  image_path = "Melanoma.jpg",
  nstart_kmeans = 5,
  niter_kmeans = 25,
  workers = 2L,
  seed = 42L
)

par(mfrow = c(1, 3), mar = c(1, 1, 3, 1))
for (component in 1:3) {
  image(
    t(projections[dim(projections)[1]:1, , component]),
    main = paste("Projection", component),
    col = grey.colors(256), axes = FALSE,
    asp = dim(projections)[1] / dim(projections)[2]
  )
}
par(mfrow = c(1, 1))
```

The returned array has dimensions `(height, width, 3)`. The parallel function derives a seed for each grid direction, making the first search independent of worker scheduling. Package versions and floating-point behavior can still affect results.

## Interpretation and verification

Projection images describe colour contrast. Binary maps in the sequential example come from two-cluster k-means; neither cluster is identified as lesion or skin without annotated masks and external validation. The source and clinical label of `Melanoma.jpg` are unverified; its file hash is recorded in the [data manifest](../data-manifest.json).

The review checked pixel/channel alignment, finite outputs, orthogonality, reconstruction dimensions and whitening. The sequential example completed in full. The parallel full-resolution search completed, but its final reconstruction and plotting stage was recovered and verified separately; the [audit note](../AUDIT.md#límites-concretos-de-la-comprobación) records the exact qualification.

**Author:** Alejandro Treny Ortega · UC3M, Master's in Statistics for Data Science
