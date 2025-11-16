# =================================================================================
# This script defines a function, 'findOptimalProjections', that processes a 
# full-resolution image, whitens the color data, and then sequentially
# finds three orthogonal projection directions that maximize
# the bimodality of the projected data, measured by the Fisher Index.
# The process is computationally intensive and leverages parallel programming.
# =================================================================================

# --- 1. Function Definition ---

#' Find Optimal Projections for Image Segmentation
#' This function takes the file path of an image, performs data whitening, and
#' uses a parallelized search to find three orthogonal projection axes that
#' best separate the data into two distinct clusters.
#'
#' @param image_path A string containing the path to the input image.
#' @param nstart_kmeans An integer specifying the 'nstart' parameter for the
#'        kmeans algorithm.
#' @param niter_kmeans An integer specifying the 'iter.max' parameter for the
#'        kmeans algorithm, which is the maximum number of iterations allowed.
#' @return A 3D array of dimensions (height, width, 3). Each of the 3 layers
#'         in the third dimension is a 2D matrix representing the grayscale
#'         image of one of the three optimal projections (IC1, IC2, IC3).

findOptimalProjections = function(image_path, nstart_kmeans = 5, niter_kmeans = 25) {
  
  # --- 1.1: Load Required Libraries ---
  # We ensure all necessary packages are installed and loaded for the function to run.
  # - OpenImageR: For reading and handling image files.
  # - foreach, doParallel: For setting up and executing the parallel computation.
  # - pracma: Provides the 'cross' product function needed for vector algebra.
  if (!require(OpenImageR)) { install.packages("OpenImageR"); library(OpenImageR) }
  if (!require(foreach)) { install.packages("foreach"); library(foreach) }
  if (!require(doParallel)) { install.packages("doParallel"); library(doParallel) }
  if (!require(pracma)) { install.packages("pracma"); library(pracma) }
  
  cat("Step 1: Reading and preparing the full-resolution image...\n")
  
  # --- 1.2: Read Image Data ---
  # The image is loaded into a 3D array.
  Im = readImage(image_path)
  # We store the original dimensions to reconstruct the images later.
  original_dims = dim(Im)
  
  
  # --- 2. Data Preparation: Whitening ---
  # It transforms the data so that it has a zero mean and an identity covariance matrix. This
  # simplifies the problem by removing first and second-order statistics.
  cat("Step 2: Whitening the image data...\n")
  
  # 2.1: Reshape Data into a Matrix
  # We convert the 3D image array into a 2D matrix where each row is a pixel
  # and each column is a color channel (Red, Green, Blue).
  Im_Matrix = matrix(Im, ncol = 3)
  
  # 2.2: Center the Data (Zero Mean)
  # The first step of whitening is to subtract the mean of each column
  # from every element in that column.
  Im_Matrix_Centered = scale(Im_Matrix, center = TRUE, scale = FALSE)
  
  # 2.3: Calculate the Whitening Matrix
  # The whitening transformation is Z = (X - μ) * W, where W is the whitening matrix.
  # W is calculated as W = E * D^(-1/2), where E are the eigenvectors and D are the
  # eigenvalues of the covariance matrix of the centered data.
  covIm_Matrix = cov(Im_Matrix_Centered) # Covariance matrix of centered data
  eigIm_Matrix = eigen(covIm_Matrix)     # Eigendecomposition
  
  # D^(-1/2) is a diagonal matrix with 1/sqrt(eigenvalue) on the diagonal.
  D_inv_sqrt = diag(1 / sqrt(eigIm_Matrix$values))
  # The whitening matrix W rotates and scales the data.
  W = eigIm_Matrix$vectors %*% D_inv_sqrt
  
  # 2.4: Apply Whitening
  # We apply the whitening matrix to our centered data to get the final whitened data, Z.
  Im_Matrix_W = Im_Matrix_Centered %*% W
  # After this step, cov(Im_Matrix_W) should be very close to the 3x3 identity matrix.
  
  
  # --- 3. Search for the First Optimal Projection (IC1) via Parallel Computation ---
  cat("Step 3: Searching for the first optimal projection (IC1) in parallel...\n")
  
  # 3.1: Setup Parallel Backend
  # We create a cluster of worker processes to distribute the computational load.
  # We use one less than the total number of available cores.
  num_cores = detectCores() - 1
  cl = makeCluster(num_cores)
  registerDoParallel(cl)
  on.exit(stopCluster(cl))
  
  # 3.2: Define the Search Space
  # We need to test every possible projection direction in 3D space. These directions
  # can be represented as unit vectors on the surface of a sphere. We generate these
  # vectors using spherical coordinates (theta and phi angles).
  theta_seq = 1:360 # Azimuthal angle
  phi_seq = 1:180   # Polar angle
  coords = expand.grid(theta = theta_seq, phi = phi_seq)
  directions = cbind(
    x = cos(coords$theta * pi/180) * sin(coords$phi * pi/180),
    y = sin(coords$theta * pi/180) * sin(coords$phi * pi/180),
    z = cos(coords$phi * pi/180)
  )
  
  # 3.3: Parallel Search Loop
  # The 'foreach' loop distributes the iterations (one for each direction)
  # across the available CPU cores. '.combine = 'c'' means the results from
  # each core are combined into a single vector.
  n_clusters = 2
  fisher_results_ic1 = foreach(i = 1:nrow(directions), .combine = 'c') %dopar% {
    
    # Select a candidate direction vector.
    dir = directions[i,]
    # Project the 3D whitened data onto this 1D direction.
    proj = Im_Matrix_W %*% dir
    
    # Use kmeans to partition the 1D projected data into two groups.
    # The parameters from the function call are used here.
    clusters = kmeans(proj, centers = n_clusters, iter.max = niter_kmeans, nstart = nstart_kmeans)
    cluster1 = proj[clusters$cluster == 1]
    cluster2 = proj[clusters$cluster == 2]
    
    # Calculate the Fisher Index to quantify the quality of separation (bimodality).
    # FI = (difference between means)^2 / (sum of variances)
    # A high FI indicates that the clusters are far apart and have low variance.
    (mean(cluster1) - mean(cluster2))^2 / (var(cluster1) + var(cluster2) + 1e-10) # 1e-10 prevents division by zero.
  }
  
  # 3.4: Identify the Best Direction for IC1
  # We find the index of the maximum Fisher Index value. This index corresponds
  # to the direction vector that produced the best separation.
  max_idx = which.max(fisher_results_ic1)
  dir_max = directions[max_idx,] # This is our first Independent Component (IC1)
  cat("   - IC1 found:", dir_max, "\n")
  
  
  # --- 4. Search for the Second Optimal Projection (IC2) ---
  # IC2 must be orthogonal (perpendicular) to IC1. Instead of searching the entire
  # sphere again, we only need to search the *circle* of vectors orthogonal to IC1.
  cat("Step 4: Searching for the second optimal projection (IC2)...\n")
  
  # 4.1: Create an Orthonormal Basis for the Plane Perpendicular to IC1
  # We use a method similar to the Gram-Schmidt process to find two basis
  # vectors (v_base1, v_base2) that span the plane orthogonal to dir_max (IC1).
  set.seed(42)
  v_base1 = rnorm(3) # Start with a random vector
  v_base1 = v_base1 - sum(v_base1 * dir_max) * dir_max # Make it orthogonal to dir_max
  v_base1 = v_base1 / sqrt(sum(v_base1^2)) # Normalize it to unit length
  # The cross product gives a third vector orthogonal to both dir_max and v_base1.
  v_base2 = pracma::cross(dir_max, v_base1)
  
  # 4.2: Search the Orthogonal Circle
  # Any vector in the orthogonal plane can be defined as a linear combination of
  # the basis vectors: dir = cos(alpha)*v_base1 + sin(alpha)*v_base2.
  # We iterate through 'alpha' from 1 to 360 degrees to check every direction on this circle.
  alpha_seq = 1:360
  fisher_results_ic2 = numeric(length(alpha_seq))
  
  # This loop is sequential (not parallelized) as it's much faster than the full spherical search.
  for (i in 1:length(alpha_seq)) {
    alpha = alpha_seq[i] * pi / 180
    dir_candidate = cos(alpha) * v_base1 + sin(alpha) * v_base2
    proj_ortho_candidate = Im_Matrix_W %*% dir_candidate
    
    # As before, we cluster and calculate the Fisher Index for this projection.
    clusters = kmeans(proj_ortho_candidate, centers = n_clusters, iter.max = niter_kmeans, nstart = nstart_kmeans)
    cluster1 = proj_ortho_candidate[clusters$cluster == 1]
    cluster2 = proj_ortho_candidate[clusters$cluster == 2]
    fisher_results_ic2[i] = (mean(cluster1) - mean(cluster2))^2 / (var(cluster1) + var(cluster2) + 1e-10)
  }
  
  # 4.3: Identify the Best Direction for IC2
  # Find the angle 'alpha' that resulted in the highest Fisher Index.
  alpha_max_idx = which.max(fisher_results_ic2)
  alpha_optimal_rad = alpha_seq[alpha_max_idx] * pi / 180
  # Construct the final optimal vector for IC2.
  v_optimal = cos(alpha_optimal_rad) * v_base1 + sin(alpha_optimal_rad) * v_base2
  cat("   - IC2 found:", v_optimal, "\n")
  
  
  # --- 5. Determine the Third Orthogonal Component (IC3) ---
  # In a 3D space, once we have two orthogonal unit vectors (IC1 and IC2), the third
  # orthogonal unit vector is uniquely determined by their cross product.
  cat("Step 5: Calculating the third orthogonal projection (IC3)...\n")
  u_optimal = pracma::cross(dir_max, v_optimal)
  # We normalize it to ensure it is a unit vector, although the cross product
  # of two unit vectors is already a unit vector if they are orthogonal.
  u_optimal = u_optimal / sqrt(sum(u_optimal^2))
  cat("   - IC3 found:", u_optimal, "\n")
  
  
  # --- 6. Generate Final Projections and Return Output ---
  # Now that we have our three optimal, orthogonal directions (our new basis),
  # we project the original whitened data onto each of them.
  cat("Step 6: Generating final projection images and returning the array.\n")
  
  # 6.1: Calculate Final Projections
  proj_ic1 = Im_Matrix_W %*% dir_max
  proj_ic2 = Im_Matrix_W %*% v_optimal
  proj_ic3 = Im_Matrix_W %*% u_optimal
  
  # 6.2: Reshape Projections into Images
  # The projection results are 1D vectors. We reshape them back into 2D matrices
  # using the original image dimensions we stored at the beginning.
  image_ic1 = matrix(proj_ic1, nrow = original_dims[1], ncol = original_dims[2])
  image_ic2 = matrix(proj_ic2, nrow = original_dims[1], ncol = original_dims[2])
  image_ic3 = matrix(proj_ic3, nrow = original_dims[1], ncol = original_dims[2])
  
  # 6.3: Combine into a Single 3D Array
  # The final output is a 3-layer array, where each layer is one of the
  # generated grayscale projection images.
  output_array = array(0, dim = c(original_dims[1], original_dims[2], 3))
  output_array[,,1] = image_ic1
  output_array[,,2] = image_ic2
  output_array[,,3] = image_ic3
  
  cat("Function finished successfully!\n")
  return(output_array)
}


# --- II. Usage ---

# To use the function, we run the function with the image used in First_Approach.R ("Melanoma.jpg"),
# but the idea of the function is that it can be used with other images

# 1. Call the function and store the result.
projection_images = findOptimalProjections("Melanoma.jpg")

# 2. Once it finishes, 'projection_images' will be a 3D array.
cat("Dimensions of the output array:", dim(projection_images), "\n")

# 3. Visualize the three resulting projection images.
par(mfrow = c(1, 3), mar = c(1, 1, 3, 1)) # Setup a 1x3 plot grid
image(projection_images[,,1], main = "Projection 1 (IC1)", col = grey.colors(256), xaxt = 'n', yaxt = 'n')
image(projection_images[,,2], main = "Projection 2 (IC2)", col = grey.colors(256), xaxt = 'n', yaxt = 'n')
image(projection_images[,,3], main = "Projection 3 (IC3)", col = grey.colors(256), xaxt = 'n', yaxt = 'n')
par(mfrow = c(1, 1))