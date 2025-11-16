
# ---------------------------------------------------------------------------------
# 0. Initial Setup
# ---------------------------------------------------------------------------------

library(OpenImageR)
library(Rfast)
library(plotly)
library(pracma)

# ---------------------------------------------------------------------------------
## 1. Reading, Visualization, and Subsampling
# Subsampling is performed to accelerate initial calculations.
# ---------------------------------------------------------------------------------
Im = readImage("Melanoma.jpg")
dim(Im)

# Subsample the image (takes 1 out of every 4 pixels) to reduce computation time.
Im_R = Im[seq(1, nrow(Im), 4), seq(1, ncol(Im), 4),]
dim(Im_R)

# ---------------------------------------------------------------------------------
## 2. Data Matrix Creation and Whitening
# Whitening is a crucial preprocessing step in ICA. It transforms the data
# to have a zero mean and an identity covariance matrix (I).
# ---------------------------------------------------------------------------------

# a) Transform RGB channels into a matrix (pixels x channels)
R =  as.vector(Im_R[,,1])
G =  as.vector(Im_R[,,2])
B =  as.vector(Im_R[,,3])
Im_R_Matrix = cbind(R,G,B)

# b) Center the matrix by subtracting the mean of each column (channel)
Im_R_Matrix_Centered = scale(Im_R_Matrix, center=TRUE, scale=FALSE)

# c) Calculate the covariance matrix and its eigen-decomposition
covIm_R_Matrix = cov(Im_R_Matrix_Centered)
eigIm_R_Matrix = eigen(covIm_R_Matrix)

# d) Apply the whitening transformation
D_inv_sqrt = diag(1 / sqrt(eigIm_R_Matrix$values))
W = eigIm_R_Matrix$vectors %*% D_inv_sqrt
Im_R_Matrix_W = Im_R_Matrix_Centered %*% W

# Verification: The covariance of the whitened data should be the Identity matrix.
# cov(Im_R_Matrix_W)

# ---------------------------------------------------------------------------------
## 3. Search for the Optimal Projection (Sequential)
# This section searches for the 1D projection that maximizes the Fisher Index,
# indicating the highest degree of class separability.
# ---------------------------------------------------------------------------------
cat("Starting sequential computation for the first component...\n")

n_clusters = 2
theta_seq = 1:360 # Azimuthal angle
phi_seq = 1:180   # Polar angle

# Create a matrix of unit vectors representing all directions on a sphere
coords = expand.grid(theta=theta_seq, phi=phi_seq)
directions = cbind(
  x = cos(coords$theta * pi/180) * sin(coords$phi * pi/180),
  y = sin(coords$theta * pi/180) * sin(coords$phi * pi/180),
  z = cos(coords$phi * pi/180)
)

# Initialize a vector to store the results
Results <- numeric(nrow(directions))

# Sequential loop to find the Fisher Index for each projection
for (i in 1:nrow(directions)) {
  dir = directions[i,]
  proj = Im_R_Matrix_W %*% dir
  
  # Cluster the projected data into two groups
  clusters = kmeans(x = proj, centers = n_clusters, iter.max = 40, nstart = 10)
  cluster1 = proj[clusters$cluster == 1]
  cluster2 = proj[clusters$cluster == 2]
  
  # Calculate the Fisher Index
  Fisher_Index = (mean(cluster1) - mean(cluster2))^2 / (var(cluster1) + var(cluster2) + 1e-10)
  Results[i] <- Fisher_Index
}
cat("Sequential computation finished.\n")

# ---------------------------------------------------------------------------------
## 3.1. Visualization and Segmentation of the Maximum Projection
# ---------------------------------------------------------------------------------
Results_matrix = matrix(Results, nrow=360, ncol=180, byrow=FALSE)

# Find the angles corresponding to the maximum Fisher Index
max_idx = which(Results_matrix == max(Results_matrix), arr.ind=TRUE)
theta_max = max_idx[1]
phi_max = max_idx[2]

# Reconstruct the optimal direction vector (dir_max)
x_max = cos(theta_max*pi/180) * sin(phi_max*pi/180)
y_max = sin(theta_max*pi/180) * sin(phi_max*pi/180)
z_max = cos(phi_max*pi/180)
dir_max = c(x_max, y_max, z_max)
cat("Maximum Projection (IC1) found:", dir_max, "\n")

# Project the data onto the optimal direction and visualize
proj_max = Im_R_Matrix_W %*% dir_max
hist(proj_max, breaks=50, main="Histogram of Maximum Projection (IC1)")

# Segment the image based on the clustering of the optimal projection
clusters_max = kmeans(proj_max, centers=2, iter.max=10, nstart=2)$cluster
segmented_image = matrix(clusters_max, nrow=nrow(Im_R), ncol=ncol(Im_R))
image(segmented_image, col=c("black","white"), main="Segmentation - Maximum Projection (IC1)")

# 3D plot of the Fisher Index optimization surface
plot_ly(x = theta_seq, y = phi_seq, z = ~Results_matrix) %>% add_surface() %>%
  layout(title="Fisher Index Optimization Surface",
         scene = list(xaxis=list(title="Theta"), yaxis=list(title="Phi"), zaxis=list(title="Fisher Index")))

# ---------------------------------------------------------------------------------
## 4. Second Orthogonal Projection (IC2)
# This section searches the circle of vectors orthogonal to 'dir_max' to
# find the one that maximizes the Fisher Index.
# ---------------------------------------------------------------------------------
cat("Starting search for the optimal second component (IC2)...\n")

# 1. Create an orthonormal basis for the plane perpendicular to dir_max.
set.seed(42)
v_base1 = rnorm(3)
v_base1 = v_base1 - sum(v_base1 * dir_max) * dir_max
v_base1 = v_base1 / sqrt(sum(v_base1^2))
v_base2 = pracma::cross(dir_max, v_base1)

# 2. Parameterize the circle and search for the optimal angle (alpha).
alpha_seq <- 1:360
fisher_results_ortho <- numeric(length(alpha_seq))

for (i in 1:length(alpha_seq)) {
  alpha <- alpha_seq[i] * pi / 180
  dir_candidate <- cos(alpha) * v_base1 + sin(alpha) * v_base2
  proj_ortho_candidate <- Im_R_Matrix_W %*% dir_candidate
  
  clusters <- kmeans(proj_ortho_candidate, centers = n_clusters, iter.max = 40, nstart = 10)
  cluster1 <- proj_ortho_candidate[clusters$cluster == 1]
  cluster2 <- proj_ortho_candidate[clusters$cluster == 2]
  
  fisher_results_ortho[i] <- (mean(cluster1) - mean(cluster2))^2 / (var(cluster1) + var(cluster2) + 1e-10)
}

# 3. Find the best vector 'v_optimal' (IC2) and visualize the results.
alpha_max_idx <- which.max(fisher_results_ortho)
alpha_optimal_rad <- alpha_seq[alpha_max_idx] * pi / 180
v_optimal <- cos(alpha_optimal_rad) * v_base1 + sin(alpha_optimal_rad) * v_base2
cat("Optimal second component (IC2) found:", v_optimal, "\n")

proj_ortho_optimal <- Im_R_Matrix_W %*% v_optimal
hist(proj_ortho_optimal, breaks = 50, main = "Histogram of Optimal Orthogonal Projection (IC2)")

# --- Grayscale Visualization of the Second Projection ---
proj_matrix_ortho_grayscale <- matrix(proj_ortho_optimal, nrow = nrow(Im_R), ncol = ncol(Im_R))
image(proj_matrix_ortho_grayscale,
      main = "Optimal Projection (IC2) in Grayscale",
      col = grey.colors(256))

# --- Binary Segmentation of the Second Projection ---
clusters_ortho <- kmeans(proj_ortho_optimal, centers=2, iter.max=10, nstart=2)$cluster
segmented_image_ortho <- matrix(clusters_ortho, nrow = nrow(Im_R), ncol = ncol(Im_R))
image(segmented_image_ortho, col=c("black","white"), main="Segmentation - Optimal Orthogonal Projection (IC2)")

# ---------------------------------------------------------------------------------
## 5. Third Orthogonal Component (IC3)
# IC3 is determined by the cross product of IC1 and IC2, completing the basis.
# ---------------------------------------------------------------------------------
u_optimal <- pracma::cross(dir_max, v_optimal)
u_optimal <- u_optimal / sqrt(sum(u_optimal^2))
cat("Third component (IC3) found:", u_optimal, "\n")

proj_third <- Im_R_Matrix_W %*% u_optimal
hist(proj_third, breaks = 50, main = "Histogram of the Third Projection (IC3)")

# --- Grayscale Visualization of the Third Projection ---
proj_matrix_third_grayscale <- matrix(proj_third, nrow = nrow(Im_R), ncol = ncol(Im_R))
image(proj_matrix_third_grayscale,
      main = "Third Projection in Grayscale",
      col = grey.colors(256))

# --- Binary Segmentation of the Third Projection ---
clusters_third <- kmeans(proj_third, centers=2, iter.max=10, nstart=2)$cluster
segmented_image_third <- matrix(clusters_third, nrow=nrow(Im_R), ncol=ncol(Im_R))
image(segmented_image_third, col=c("black","white"), main="Segmentation - Third Projection (IC3)")