# FULL MDS and CLUSTERING ANALYSIS WITH MIXED-TYPE VARIABLES -----
# Kepler KOI dataset


library(tidyverse)
library(cluster)
library(MASS)
library(smacof)
library(ggcorrplot)
library(broom)
library(ggforce)
library(gridExtra)
library(reshape2)
library(ggplot2)
library(qgraph)
library(vegan)
library(factoextra)
library(hopkins)
library(scatterplot3d)
library(patchwork)
library(mclust)
library(fmsb)
library(scales)




# ==============================================================================
# PHASE I: MDS ANALYSIS
# ==============================================================================


# STEP 0: Data set info and variable selection -----


# --- Kepler Object of Interest (KOI) Data set Variables ---

# This data set contains candidate exoplanets identified by the Kepler Space Telescope.
# The variables describe the transit signal, the host star properties, 
# and the derived properties of the planet candidate.
# Source: NASA Exoplanet Archive (Kepler Candidate Columns)


# Select fourteen columns (including identifiers and labels) from the
# 8,054-row snapshot, then sample 1,000 complete cases for mixed-data MDS.

# The selected variables are the following:

# --- Data Scale Definitions ---
#   - Nominal: Unordered categorical labels.
#   - Binary: Categorical data with two states (0 or 1).
#   - Continuous (Ratio): Numerical data where 0 means 'none' or 'nothing'.
#   - Continuous (Logarithmic): Numerical data on a logarithmic scale.

# --- Identifiers and Disposition ---
# kepid            # Kepler ID: Unique target identifier [Unit: None] (Scale: Nominal)
# koi_disposition  # KOI Disposition: The final classification [Unit: None] (Scale: Nominal - 3 levels: CONFIRMED, CANDIDATE, FALSE POSITIVE)

# --- Vetting and False Positive Flags ---
# koi_fpflag_nt    # Not Transit-Like Flag [Unit: None] (Scale: Binary - 0 or 1)
# koi_fpflag_ss    # Stellar Eclipse Flag [Unit: None] (Scale: Binary - 0 or 1)

# --- Transit / Orbital Parameters (Observed) ---
# koi_period       # Orbital Period [Unit: days] (Scale: Continuous (Ratio))
# koi_duration     # Transit Duration [Unit: hours] (Scale: Continuous (Ratio))
# koi_depth        # Transit Depth [Unit: ppm - parts per million] (Scale: Continuous (Ratio))

# --- Derived Planetary Parameters (Relative to Earth) ---
# koi_prad         # Planetary Radius [Unit: Earth radii] (Scale: Continuous (Ratio) - Relative to Earth's radius)
# koi_insol        # Insolation Flux [Unit: Earth flux units] (Scale: Continuous (Ratio) - Relative to Earth's insolation)

# --- Host Star Properties (Relative to our Sun) ---
# koi_steff        # Stellar Effective Temperature [Unit: K - Kelvin] (Scale: Continuous (Ratio) - Absolute scale)
# koi_srad         # Stellar Radius [Unit: Solar radii] (Scale: Continuous (Ratio) - Relative to the Sun's radius)
# koi_smass        # Stellar Mass [Unit: Solar masses] (Scale: Continuous (Ratio) - Relative to the Sun's mass)
# koi_slogg        # Stellar Surface Gravity [Unit: log10(g) in cm/s^2] (Scale: Continuous (Logarithmic))
# koi_kepmag       # Kepler-band Magnitude [Unit: mag - magnitudes] (Scale: Continuous (Logarithmic))


# STEP 1: Load Dataset -----

#url_koi = "https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=select+*+from+q1_q17_dr25_koi&format=csv"

#df_koi = read_csv(url_koi, show_col_types = FALSE)

# It case web goes slow, import data from the local copy
df_koi <- read.csv("df_koi.csv")

# Select and rename the relevant columns
df_selected = df_koi %>%
  dplyr::select(
    kepid,            # Kepler ID (Target-star identifier; multiple KOIs can share it)
    koi_disposition,  # KOI Disposition (Candidate, Confirmed, False Positive)
    koi_fpflag_nt,    # Not Transit-Like (False positive flag)
    koi_fpflag_ss,    # Stellar Eclipse (False positive flag)
    koi_period,       # Orbital Period (days)
    koi_duration,     # Transit Duration (hours)
    koi_depth,        # Transit Depth (ppm)
    koi_prad,         # Planetary Radius (Earth radii)
    koi_insol,        # Insolation Flux (light received by planet)
    koi_steff,        # Stellar Effective Temperature (Kelvin)
    koi_srad,         # Stellar Radius (Solar radii)
    koi_smass,        # Stellar Mass (Solar masses)
    koi_slogg,        # Stellar Surface Gravity (log10(g))
    koi_kepmag        # Kepler-band Magnitude (star's brightness)
  ) %>%
  dplyr::rename(
    id = kepid,
    disposition = koi_disposition,
    flag_notransit = koi_fpflag_nt,
    flag_stellareclipse = koi_fpflag_ss,
    period_days = koi_period,
    duration_hours = koi_duration,
    depth_ppm = koi_depth,
    radius_earth = koi_prad,
    insolation = koi_insol,
    teff_K = koi_steff,
    radius_sun = koi_srad,
    mass_sun = koi_smass,
    logg = koi_slogg,
    magnitude = koi_kepmag
  )%>%
  na.omit() # MDS cannot handle missing values easily




# STEP 2: Create derived variables (binary / multiclass) and log-transform -----



df_clean <- df_selected %>%
  mutate(
    
    # --- 1. Statistical Binary Discretization ---
    #
    # We create a binary flag for stellar temperature based on the median.
    # Justification: This is a standard data-driven approach. It splits the
    # dataset into two roughly equal-sized groups ("hotter-than-average"
    # and "cooler-than-average") to test if this simple binary contrast
    # is a significant factor in the analysis.
    
    hot_star = if_else(teff_K > median(teff_K, na.rm = TRUE), 1, 0),
    
    # --- 2. Domain-Knowledge Binary Discretization (The 'large_planet' threshold) ---
    #
    # We create a binary flag based on a fixed, physical threshold.
    # Justification: This is a deliberate, *astrophysically-informed* choice,
    # not a statistical one (like using the median).
    #
    # A descriptive radius threshold of 4 Earth radii; it does not identify composition.
    large_planet = if_else(radius_earth > 4, 1, 0),
    
    # --- 3. Statistical Multi-Class Discretization (Terciles) ---
    #
    # We bin 'insolation' (energy received) into three equal-count groups
    # using terciles (33rd and 66th percentiles).
    # Justification: This segments the population into 'low', 'medium', and 'high'
    # energy environments. This is a common non-parametric way to explore
    # relationships (like habitability) without assuming a linear response
    # to insolation.
    
    insolation_class = case_when(
      is.na(insolation) ~ NA_character_,
      insolation < quantile(insolation, 0.33, na.rm = TRUE) ~ "low",
      insolation < quantile(insolation, 0.66, na.rm = TRUE) ~ "medium",
      TRUE ~ "high"
    ),
    
# Magnitude groups describe brightness; they do not correct selection bias.
    
    magnitude_class = case_when(
      is.na(magnitude) ~ NA_character_,
      magnitude < quantile(magnitude, 0.33, na.rm = TRUE) ~ "bright", # < 33rd percentile is brightest
      magnitude < quantile(magnitude, 0.66, na.rm = TRUE) ~ "medium",
      TRUE ~ "dim"                                      # > 66th percentile is dimmest
    ),

    # --- 5. Domain-Knowledge Binary Grouping of Disposition ---
    # Combined plotting label only; candidates are not confirmed planets.
    binary_disposition = case_when(
      disposition == "FALSE POSITIVE" ~ "False Positive",
      TRUE ~ "Confirmed/Candidate"
    )
  )

# Log-transform skewed quantitative variables
# (Critical for Mahalanobis distance to work well)
df_clean <- df_clean %>%
  mutate(
    period_days = log10(period_days + 1),
    depth_ppm = log10(depth_ppm + 1),
    insolation = log10(insolation + 1),
    radius_earth = log10(radius_earth + 1),
    duration_hours = log10(duration_hours + 1),
    teff_K = log10(teff_K + 1),
    radius_sun = log10(radius_sun + 1),
    mass_sun = log10(mass_sun + 1)
    # Note: 'logg' and 'magnitude' are already log-scale or normal-ish
  )



# STEP 3: Sample Reduction for MDS -----



# MDS requires calculating an N x N distance matrix. 
# For N=8000, that is 64 million elements, which will crash standard R sessions.
# We will take a robust random sample of N = 1000 for this analysis.

set.seed(42)
df_sample <- df_clean %>% sample_n(1000)




# STEP 4: Matrix Segmentation for RelMS -----



# RelMS requires separating variables by type to apply specific distances 
# (Mahalanobis, Jaccard, Hamming).

# --- Matrix 1: Quantitative Variables (X1) ---
# Used for: Robust Mahalanobis Distance
X1_quant <- df_sample %>%
  dplyr::select(
    period_days, duration_hours, depth_ppm, radius_earth, 
    insolation, teff_K, radius_sun, mass_sun, logg, magnitude
  ) %>%
  as.matrix()

# --- Matrix 2: Binary Variables (X2) ---
# Used for: Jaccard / Sokal-Michener Distance
X2_bin <- df_sample %>%
  dplyr::select(
    flag_notransit, flag_stellareclipse, hot_star, large_planet
  ) %>%
  as.matrix()

# --- Matrix 3: Multi-class Categorical Variables (X3) ---
# Used as categorical variables in Gower dissimilarity.  Keeping factors avoids
# imposing an artificial numerical order on the classes.
X3_cat <- df_sample %>%
  dplyr::select(insolation_class, magnitude_class) %>%
  mutate(across(everything(), as.factor))



# Calculate Pearson Correlation Matrix for Quantitative Variables (X1)
cor_matrix <- cor(X1_quant)

# Visualize with a Heatmap
#    - Red/Blue indicates strong positive/negative correlation.
#    - White indicates independence.
corr_plot <- ggcorrplot(
  cor_matrix,
  method = "square",
  type = "lower",       
  lab = TRUE,            
  lab_size = 3,
  title = "Correlation Matrix of Quantitative Variables (X1)",
  colors = c("#6D9EC1", "white", "#E46726") 
)

print(corr_plot)

# Robust Mahalanobis distance uses estimated covariance to weight the
# quantitative block. This is one modeling choice; correlations alone do
# not establish that it is superior to alternative distances.

# --- Labels/Ground Truth ---
# We keep this separate for visualization, not for distance calculation
labels_vec <- df_sample$binary_disposition





# STEP 5: Calculation of Individual Squared Distance Matrices (D^2) -----




# --- 5.1 Quantitative Distance (D1): Robust Mahalanobis ---
# Formula: d^2(i,j) = (xi - xj)' S_robust^-1 (xi - xj)

# 1. Estimate Robust Covariance (S_robust) using Minimum Covariance Determinant (MCD)
#    This finds the subset of data with the smallest determinant, effectively ignoring outliers.
rob_est <- cov.rob(X1_quant, method = "mcd")
S_robust_inv <- solve(rob_est$cov) # Invert the covariance matrix

# 2. Calculate Pairwise Squared Mahalanobis Distances
#    We define a custom function because standard 'mahalanobis()' computes distance to mean,
#    not distance between pairs.
calc_pairwise_mahal_sq <- function(data_matrix, S_inv) {
  n <- nrow(data_matrix)
  D2 <- matrix(0, nrow = n, ncol = n)
  if (n < 2L) return(D2)
  
  # Nested loop is efficient enough for N=1000
  for (i in 1:(n-1)) {
    for (j in (i+1):n) {
      diff_vec <- data_matrix[i, ] - data_matrix[j, ]
      # Matrix multiplication: t(x) * S^-1 * x
      d2_val <- as.numeric(t(diff_vec) %*% S_inv %*% diff_vec)
      D2[i, j] <- d2_val
      D2[j, i] <- d2_val
    }
  }
  return(D2)
}

D1_quant_sq <- calc_pairwise_mahal_sq(X1_quant, S_robust_inv)

range(D1_quant_sq) 


# --- 2.2 Binary Distance (D2): Jaccard ---
# Jaccard Distance = 1 - (a / (a+b+c))

# The 'dist' function with method="binary" calculates Jaccard distance.
# IMPORTANT: 'dist' returns 'd'. We must square it to get 'd^2' for RelMS.
D2_bin_dist <- dist(X2_bin, method = "binary")
D2_bin_sq <- as.matrix(D2_bin_dist)^2

range(D2_bin_sq)


# --- 2.3 Categorical Distance (D3): Hamming (Matching) ---
# Matching Coeff: s = matches / p. Distance = 1 - s.

# 'daisy' with metric="gower" on factor variables applies the Matching coefficient.
# Again, we must square the result.
D3_cat_dist <- daisy(X3_cat, metric = "gower")
D3_cat_sq <- as.matrix(D3_cat_dist)^2

range(D3_cat_sq)

# Let's verify that D1 (Quantitative) has a much larger scale than D2/D3.
# This confirms why we will need the "Geometric Variability" normalization in the next phase.

mean(D1_quant_sq)
mean(D2_bin_sq)
mean(D3_cat_sq)


# The three distance blocks have different units and scales. Their computed
# summaries motivate normalizing geometric variability before combination.
# Equal block variability is a weighting choice, not equal predictive value.


# STEP 5.5 : Provee the right choice of distances. -----


# Quantitative: Robust Mahalanobis

# Calculate the Distances
dist_mahalanobis <- as.vector(as.dist(sqrt(D1_quant_sq)))

# Calculate standard Euclidean and Manhattan on the same data
dist_euclidean <- as.vector(dist(X1_quant, method = "euclidean"))
dist_manhattan <- as.vector(dist(X1_quant, method = "manhattan"))


# Create a Tidy Dataframe for Plotting

plot_data <- data.frame(
  Euclidean = c(dist_euclidean, dist_euclidean),
  Value = c(dist_manhattan, dist_mahalanobis),
  Metric = rep(c("Manhattan (L1)", "Robust Mahalanobis"), each = length(dist_euclidean))
)

# Generate the Panel Plot

comp_plot <- ggplot(plot_data, aes(x = Euclidean, y = Value)) +
  # Small points to show density
  geom_point(alpha = 0.05, color = "#2c3e50", size = 0.5) +
  
  # Add Identity Line (y=x) or Linear Trend for reference
  geom_smooth(method = "lm", color = "red", linetype = "dashed", se = FALSE, linewidth = 0.8) +
  
  # Split into panels
  facet_wrap(~ Metric, scales = "free_y") +
  labs(
    title = "Why Robust Mahalanobis? A Geometric Comparison",
    subtitle = "Alternative pairwise distances; L1 and L2 are not generally proportional.",
    x = "Euclidean Distance",
    y = "Alternative Distance"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold", size = 12),
    plot.title = element_text(face = "bold")
  )

print(comp_plot)

# The comparison shows how distance rankings and scales change with the
# metric. Euclidean and Manhattan distances need not rank pairs identically;
# Mahalanobis incorporates covariance without establishing physical truth.


# Binary : Similarity Comparison

# Objective: Compare Sokal-Michener, Jaccard, and Dice distances to justify 
# the choice of Jaccard for the RelMS construction.

# 1. PREPARATION: Subset for Visualization
# ------------------------------------------------------------------------------
# We take the first 30 observations to make the heatmaps readable
X2_sub <- X2_bin[1:30, ]
n_sub <- nrow(X2_sub)
p_bin <- ncol(X2_sub)

# 2. CALCULATION OF COEFFICIENTS
# ------------------------------------------------------------------------------
# a = 1-1 matches, d = 0-0 matches, b/c = mismatches

# Matrix multiplication trick to get counts efficiently
a <- X2_sub %*% t(X2_sub)
d <- (1 - X2_sub) %*% t(1 - X2_sub)
# Total dimensions p = a + b + c + d, so (b+c) = p - a - d
b_plus_c <- p_bin - a - d

# --- A. Sokal-Michener (Simple Matching) ---
# Similarity: (a + d) / p
# Distance^2: 1 - S
S_SM <- (a + d) / p_bin
D2_SM <- 1 - S_SM

# --- B. Jaccard ---
# Similarity: a / (a + b + c)
# Distance^2: 1 - S
# Handle division by zero if (a+b+c) = 0 (identical 0-0 vectors)
denom_jac <- (a + b_plus_c)
S_Jac <- ifelse(denom_jac == 0, 1, a / denom_jac)
D2_Jac <- 1 - S_Jac

# --- C. Dice (Sneath-Sokal) ---
# Similarity: 2a / (2a + b + c)
# Distance^2: 1 - S
denom_dice <- (2 * a + b_plus_c)
S_Dice <- ifelse(denom_dice == 0, 1, (2 * a) / denom_dice)
D2_Dice <- 1 - S_Dice

# 3. VISUALIZATION 1: HEATMAPS 
# ------------------------------------------------------------------------------
plot_binary_heatmap <- function(dist_matrix, title) {
  melted_cormat <- melt(as.matrix(dist_matrix))
  ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + 
    geom_tile(color = "white") +
    scale_fill_gradient(low = "white", high = "#377EB8", limit = c(0, 1), name="Dist") +
    scale_y_reverse() + # Flip to match matrix convention
    labs(title = title, x = "", y = "") +
    theme_minimal() + 
    theme(axis.text = element_blank(), panel.grid = element_blank())
}

p1 <- plot_binary_heatmap(D2_SM, "Sokal-Michener (Symmetric)")
p2 <- plot_binary_heatmap(D2_Jac, "Jaccard (Asymmetric)")
p3 <- plot_binary_heatmap(D2_Dice, "Dice (Weighted)")

grid.arrange(p1, p2, p3, ncol = 3)

# 4. VISUALIZATION 2: LINE PLOT COMPARISON
# ------------------------------------------------------------------------------
# We sort the pairs by the Sokal-Michener distance to create a readable "ladder" plot.

# Create the base dataframe
lower_tri <- lower.tri(D2_SM)
pairs_df <- data.frame(
  Sokal_Michener = D2_SM[lower_tri],
  Jaccard = D2_Jac[lower_tri],
  Dice = D2_Dice[lower_tri]
)

# We order by Sokal-Michener so we can see the divergence
pairs_df_sorted <- pairs_df[order(pairs_df$Sokal_Michener), ]
pairs_df_sorted$Ordered_Index <- 1:nrow(pairs_df_sorted)

pairs_long <- melt(pairs_df_sorted, id.vars = "Ordered_Index", 
                   variable.name = "Metric", value.name = "Distance")

line_plot <- ggplot(pairs_long, aes(x = Ordered_Index, y = Distance, color = Metric, linetype = Metric)) +
  geom_line(linewidth = 1, alpha = 0.8) +
  labs(
    title = "Comparison of Binary Distances (Ordered Profile)",
    subtitle = "The distances differ in their treatment of joint absences.",
    x = "Pairs Ordered by Sokal-Michener Distance",
    y = "Dissimilarity (not squared)"
  ) +
  scale_color_manual(values = c("Sokal_Michener" = "#E41A1C", "Jaccard" = "#377EB8", "Dice" = "#4DAF4A")) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(line_plot)

# Sokal-Michener includes shared zeros; Jaccard and Dice emphasize active
# flags. We choose Jaccard for this block and define two all-zero vectors
# as distance zero. This convention does not imply that shared zeros are
# uninformative for every scientific question.



# Categorical: Metric comparison

# Objective: Compare Hamming (SC1) vs penalized matching (SC4) for categorical data.


# 1. PREPARATION: Subset & Calculation
# ------------------------------------------------------------------------------
# We take the same subset of 30 individuals for readability in heatmaps
X3_sub <- X3_cat[1:30, ]
n_sub <- nrow(X3_sub)
p_cat <- ncol(X3_sub) # p = 2 (Insolation, Magnitude)

# Calculate Alpha Matrix (Number of Matches) manually
# alpha_ij = sum(x_ik == x_jk)
calc_alpha <- function(data_mat) {
  n <- nrow(data_mat)
  alpha_mat <- matrix(0, n, n)
  for(i in 1:n) {
    for(j in 1:n) {
      # Count exact matches across the p columns
      alpha_mat[i, j] <- sum(data_mat[i, ] == data_mat[j, ])
    }
  }
  return(alpha_mat)
}

alpha_mat <- calc_alpha(X3_sub)

# --- Metric A: SC1 (Hamming / Simple Matching) ---
# Slide 16: s = alpha / p
S_SC1 <- alpha_mat / p_cat
D2_SC1 <- 1 - S_SC1

# --- Metric B: SC4 (Penalized Mismatches) ---
# Slide 16: s = alpha / (alpha + 2*(p - alpha))
# This gives double weight to mismatches (p - alpha)
mismatches <- p_cat - alpha_mat
denom_sc4 <- alpha_mat + 2 * mismatches
S_SC4 <- ifelse(denom_sc4 == 0, 0, alpha_mat / denom_sc4)
D2_SC4 <- 1 - S_SC4

# 2. VISUALIZATION 1: HEATMAPS
# ------------------------------------------------------------------------------
plot_cat_heatmap <- function(dist_matrix, title) {
  melted_cormat <- melt(as.matrix(dist_matrix))
  ggplot(data = melted_cormat, aes(x=Var1, y=Var2, fill=value)) + 
    geom_tile(color = "white") +
    scale_fill_gradient(low = "white", high = "#377EB8", limit = c(0, 1), name="Dist") +
    scale_y_reverse() +
    labs(title = title, x = "", y = "") +
    theme_minimal() + 
    theme(axis.text = element_blank(), panel.grid = element_blank())
}

p_sc1 <- plot_cat_heatmap(D2_SC1, "SC1: Hamming (Standard)")
p_sc4 <- plot_cat_heatmap(D2_SC4, "SC4: Penalized Mismatches")

grid.arrange(p_sc1, p_sc4, ncol = 2)

# 3. VISUALIZATION 2: ORDERED PROFILE PLOT
# ------------------------------------------------------------------------------
# We sort pairs by SC1 distance to see how SC4 behaves relative to it.

# Extract unique pairs (lower triangle)
lower_tri <- lower.tri(D2_SC1)
pairs_cat_df <- data.frame(
  SC1 = D2_SC1[lower_tri],
  SC4 = D2_SC4[lower_tri]
)

# Sorting by SC1
pairs_cat_df <- pairs_cat_df[order(pairs_cat_df$SC1), ]
pairs_cat_df$Index <- 1:nrow(pairs_cat_df)

# Reshape
pairs_cat_long <- melt(pairs_cat_df, id.vars = "Index", 
                       variable.name = "Metric", value.name = "Distance")

line_plot_cat <- ggplot(pairs_cat_long, aes(x = Index, y = Distance, color = Metric, linetype = Metric)) +
  geom_line(linewidth = 1, alpha = 0.8) +
  labs(
    title = "Comparison of Categorical Metrics (SC1 vs SC4)",
    subtitle = "SC4 equals SC1 for full agreement/disagreement and is larger for partial mismatches.",
    x = "Pairs Ordered by Hamming Distance (SC1)",
    y = "Dissimilarity (not squared)"
  ) +
  scale_color_manual(values = c("SC1" = "#E41A1C", "SC4" = "#377EB8")) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(line_plot_cat)

# With two categorical inputs, normalized Hamming distance has levels
# 0, 0.5 and 1. SC4 uses 1 - a/(a + 2u), where a is the number of matches
# and u the number of mismatches; one match gives 2/3. This is a penalized
# matching coefficient, not a weighted Gower distance. We use Hamming.



# STEP 6: Construction of the Joint Metric (RelMS) -----


# 6.1 Check Commensurability (Geometric Variability)
# Vk = (1 / 2n^2) * sum(delta_ij^2)
# We calculate V for each matrix to see how much "inertia" it has.

calc_geo_var <- function(D_sq) {
  n <- nrow(D_sq)
  # Sum of all elements in the squared distance matrix
  sum_val <- sum(D_sq)
  V <- sum_val / (2 * n^2)
  return(V)
}

# Calculate V for our three matrices
v1 <- calc_geo_var(D1_quant_sq)
v2 <- calc_geo_var(D2_bin_sq)
v3 <- calc_geo_var(D3_cat_sq)

cat("Geometric Variabilities (Pre-scaling):\n")
cat("V1 (Quant - Mahalanobis):", v1, "\n")
cat("V2 (Binary - Jaccard):   ", v2, "\n")
cat("V3 (Cat - Hamming):      ", v3, "\n")

# Divide each squared-distance block by its positive geometric variability.
# The resulting block weights express the chosen normalization, not a
# guarantee that the blocks provide equally useful information.

# 6.2 Rescaling to Equal Geometric Variability
# Rescale D^2 by dividing by Vk. 
# This imposes equal weight to all three sources of information.

stopifnot(all(is.finite(c(v1, v2, v3))), min(v1, v2, v3) > 0)
D1_scaled <- D1_quant_sq / v1
D2_scaled <- D2_bin_sq / v2
D3_scaled <- D3_cat_sq / v3

# Matrices rescaled. Now V_new = 1 for all

# 6.3 Compute Centered Gram Matrices (Gk)

# Gk = -0.5 * H * Dk * H
# First, construct Centering Matrix H = I - (1/n)11'

n <- nrow(D1_scaled)
I <- diag(n)
One <- matrix(1, n, n)
H <- I - (1/n) * One

# Calculate Gram matrices for each source
G1 <- -0.5 * H %*% D1_scaled %*% H
G2 <- -0.5 * H %*% D2_scaled %*% H
G3 <- -0.5 * H %*% D3_scaled %*% H

# 6.4 Matrix Square Roots (Gk^1/2)
# The RelMS formula requires the square root of the Gram matrices.
# We calculate this via Eigendecomposition: G = U * Lambda * U' -> G^1/2 = U * sqrt(Lambda) * U'

get_matrix_sqrt <- function(G) {
  # Spectral decomposition
  decomp <- eigen(G, symmetric = TRUE)
  
  # Use the positive-semidefinite part. Negative eigenvalues can be structural.
  cat("Gram negative-eigenvalue mass:", sum(abs(decomp$values[decomp$values < -1e-8])), "\n")
  vals <- decomp$values
  vals[vals < 0] <- 0 
  
  # Reconstruct using sqrt of eigenvalues
  # Square root of the positive-semidefinite part, using its eigendecomposition.
  G_sqrt <- decomp$vectors %*% diag(sqrt(vals)) %*% t(decomp$vectors)
  return(G_sqrt)
}

G1_sqrt <- get_matrix_sqrt(G1)
G2_sqrt <- get_matrix_sqrt(G2)
G3_sqrt <- get_matrix_sqrt(G3)

# 6.5 Compute Joint RelMS Gram Matrix (G)

# G = Sum(Gk) - (1/m) * Sum_{k!=l} (Gk^1/2 * Gl^1/2)

m <- 3 # Number of matrices

# The "Pythagorean Sum" part (matches Generalized Gower)
sum_G <- G1 + G2 + G3 

# The cross-block term sums products of square-root Gram matrices.
# It modifies the joint geometry; whether this helps a particular task
# must be evaluated rather than assumed from the correction formula.
cross_term <- (G1_sqrt %*% G2_sqrt) + (G2_sqrt %*% G1_sqrt) +
              (G1_sqrt %*% G3_sqrt) + (G3_sqrt %*% G1_sqrt) +
              (G2_sqrt %*% G3_sqrt) + (G3_sqrt %*% G2_sqrt)

# Final Formula
G_relms <- sum_G - (1/m) * cross_term

# 6.6 Recover Joint Squared Distance Matrix (D^2)

# Formula to go back from Gram (G) to Distance (D^2)
# D^2_ij = g_ii + g_jj - 2*g_ij

g_diag <- diag(G_relms)
# Create a matrix where each row is the diagonal (g_ii)
G_ii <- matrix(g_diag, n, n, byrow = FALSE) 
# Create a matrix where each col is the diagonal (g_jj)
G_jj <- matrix(g_diag, n, n, byrow = TRUE)

D2_relms <- G_ii + G_jj - 2 * G_relms

# Numerical cleanup (diagonals must be strictly 0)
diag(D2_relms) <- 0

# 6.7 Generalized Gower (for comparison) ---

# Reference version that sums the Gram matrices without applying
# the correction term (equivalent to a generalized Gower).
G_gower_gen <- sum_G
g_diag_gow <- diag(G_gower_gen)
G_ii_gow <- matrix(g_diag_gow, n, n, byrow = FALSE)
G_jj_gow <- matrix(g_diag_gow, n, n, byrow = TRUE)
D2_gower_gen <- G_ii_gow + G_jj_gow - 2 * G_gower_gen
diag(D2_gower_gen) <- 0




# STEP 7: Multidimensional Scaling (MDS) Execution -----





# 7.1 Initial Gram Matrix Calculation

# We start with the Joint Squared Distance Matrix (D2_relms)
n <- nrow(D2_relms)
I <- diag(n)
One <- matrix(1, n, n)
H <- I - (1/n) * One

# Gram Matrix: G = -0.5 * H * D^2 * H
G_initial <- -0.5 * H %*% D2_relms %*% H

# Eigen-decomposition
decomp <- eigen(G_initial, symmetric = TRUE)
eigenvalues <- decomp$values

# 7.2 Euclidean Property Check & Automatic Correction

# Check for significant negative eigenvalues
min_lambda <- min(eigenvalues)
is_euclidean <- min_lambda > -1e-8
D2_corrected <- D2_relms

if (is_euclidean) {
  cat("Matrix is Euclidean. Proceeding directly...\n")
  G_final <- G_initial
  final_eigenvalues <- eigenvalues
  final_eigenvectors <- decomp$vectors
  
} else {
  cat(">> WARNING: Matrix is Non-Euclidean (Min Eigenvalue:", round(min_lambda, 4), ")\n")
  cat(">> ACTION: Applying Theorem 2 (Constant Shift Correction)...\n")
  
  # Calculate correction constant c >= 2 * |min_lambda|
  c_const <- 2 * abs(min_lambda)
  
  # Apply c to off-diagonal elements of D^2
  # D_new^2 = D_old^2 + c (for i != j)
  D2_corrected <- D2_relms
  D2_corrected[col(D2_corrected) != row(D2_corrected)] <- 
    D2_corrected[col(D2_corrected) != row(D2_corrected)] + c_const
  
  # Re-calculate Gram Matrix
  G_final <- -0.5 * H %*% D2_corrected %*% H
  
  # Re-diagonalize
  decomp_final <- eigen(G_final, symmetric = TRUE)
  final_eigenvalues <- decomp_final$values
  final_eigenvectors <- decomp_final$vectors
  
  # Filter tiny noise (clamp negatives to 0)
  final_eigenvalues[final_eigenvalues < 0] <- 0
  
  cat(">> CORRECTION APPLIED. New Min Eigenvalue:", min(final_eigenvalues), "\n")
}

# 7.3. Compute Principal Coordinates

# Y = U * Lambda^1/2
# We calculate coordinates for all dimensions (though we usually plot just 2)

final_eigenvalues <- pmax(final_eigenvalues, 0)
stopifnot(min(D2_corrected) > -1e-8)
D2_corrected <- pmax(D2_corrected, 0)
Lambda_sqrt <- diag(sqrt(final_eigenvalues))
Y_coords <- final_eigenvectors %*% Lambda_sqrt

# 7.4. Goodness of Fit / Explained Variability

# Pr = (sum(lambda_1..r) / sum(all_lambda)) * 100

total_variance <- sum(final_eigenvalues)
explained_var <- (final_eigenvalues / total_variance) * 100
cum_explained_var <- cumsum(explained_var)

# Summary Table
mds_summary <- data.frame(
  Dim = 1:5,
  Eigenvalue = round(final_eigenvalues[1:5], 4),
  Explained_Var = round(explained_var[1:5], 2),
  Cumulative_Var = round(cum_explained_var[1:5], 2)
)

print(mds_summary)

# The Euclidean correction adds 2c to off-diagonal squared distances,
# shifting the centered spectrum. Read the computed retention percentages:
# two dimensions retain about 1.36% and five retain about 2.55% here.
# The low-dimensional maps therefore discard most corrected variability
# and cannot by themselves establish a reliable class separation.

# 7.5. Visualization: Scree Plot

# Visual check to see how many dimensions we really need.

scree_data <- data.frame(
  Dimension = 1:10, 
  Variance = explained_var[1:10]
)

scree_plot <- ggplot(scree_data, aes(x = Dimension, y = Variance)) +
  geom_line(color = "#2c3e50", linewidth = 1) +
  geom_point(size = 3, color = "#e74c3c") +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title = "MDS Scree Plot (RelMS + Correction)",
    subtitle = "Percentage of Variability Explained per Dimension",
    y = "% Variance Explained"
  ) +
  theme_minimal()

print(scree_plot)

# 7.6. Visualization and Descriptive Associations: The MDS Map (Dim 1 vs Dim 2)

# 1. PREPARATION
# ------------------------------------------------------------------------------

mds_master <- df_sample %>%
  dplyr::select(
    hot_star, large_planet, insolation_class, magnitude_class,
    flag_notransit, flag_stellareclipse, binary_disposition
  ) %>%
  mutate(
    # Recode Binary Variables (0/1 -> Text) for better legends
    hot_star = factor(hot_star, levels = c(0, 1), labels = c("Cool Star", "Hot Star")),
    large_planet = factor(large_planet, levels = c(0, 1), labels = c("Small/Med Planet", "Large Planet")),
    flag_notransit = factor(flag_notransit, levels = c(0, 1), labels = c("Transit-like", "NOT Transit-like")),
    flag_stellareclipse = factor(flag_stellareclipse, levels = c(0, 1), labels = c("No Eclipse", "Stellar Eclipse")),
    insolation_class = as.factor(insolation_class),
    magnitude_class = as.factor(magnitude_class),
    binary_disposition = as.factor(binary_disposition)
  ) %>%
  mutate(
    # Add coordinates
    Dim1 = Y_coords[, 1],
    Dim2 = Y_coords[, 2]
  )

# List of variables
qual_vars <- c("hot_star", "large_planet", "insolation_class", 
               "magnitude_class", "flag_notransit", "flag_stellareclipse", 
               "binary_disposition")

# 2. VISUALIZATION FUNCTION
# ------------------------------------------------------------------------------
create_mds_plot <- function(var_name) {
  
  # Calculate Centroids
  centroids <- mds_master %>%
    group_by(.data[[var_name]]) %>%
    summarise(C1 = mean(Dim1), C2 = mean(Dim2), .groups = 'drop')
  
  # Create the plot
  p <- ggplot(mds_master, aes(x = Dim1, y = Dim2, color = .data[[var_name]])) +
    
    # A. Faded background points (Context)
    geom_point(alpha = 0.15, size = 1.5) + 
    
    # B. Approximate coverage ellipses (shape of the group)
    stat_ellipse(aes(fill = .data[[var_name]]), geom = "polygon", alpha = 0.2, level = 0.95) +
    
    # C. Centroids 
    geom_point(data = centroids, aes(x = C1, y = C2), size = 5, shape = 18, color = "black") + # Border
    geom_point(data = centroids, aes(x = C1, y = C2), size = 3) + # Fill color
    
    # D. Colors and Scales
    scale_color_brewer(palette = "Set1") +
    scale_fill_brewer(palette = "Set1") +
    
    # E. Zoom (Coord Cartesian)
    coord_cartesian(xlim = c(-5, 5), ylim = c(-2.5, 5)) +
    
    # F. Labels & Theme
    labs(
      title = paste("Structure by:", var_name), 
      x = "Dim 1", 
      y = "Dim 2",
      color = "Category",
      fill = "Category"
    ) +
    theme_minimal() +
    theme(
      legend.position = "right",
      plot.title = element_text(face = "bold", size = 12),
      axis.title = element_text(size = 10)
    )
  
  return(p)
}

# 3. DESCRIPTIVE ASSOCIATIONS FUNCTION
# ------------------------------------------------------------------------------
run_stats <- function(var_name) {
  manova_res <- manova(cbind(Dim1, Dim2) ~ mds_master[[var_name]], data = mds_master)
  manova_p <- summary(manova_res)$stats[1, "Pr(>F)"]
  
  kruskal_res <- kruskal.test(mds_master$Dim1 ~ mds_master[[var_name]])
  kruskal_p <- kruskal_res$p.value
  
  return(data.frame(
    Variable = var_name,
    MANOVA_p = manova_p,
    Kruskal_Dim1_p = kruskal_p
  ))
}

# 4. EXECUTION
# ------------------------------------------------------------------------------

# Print plots individually
for (var in qual_vars) {
  p <- create_mds_plot(var)
  print(p)
}

# Print Statistics
stats_table <- do.call(rbind, lapply(qual_vars, run_stats))
adjusted <- p.adjust(c(stats_table$MANOVA_p, stats_table$Kruskal_Dim1_p), method = "holm")
stats_table$MANOVA_Holm <- adjusted[seq_along(qual_vars)]
stats_table$Kruskal_Dim1_Holm <- adjusted[length(qual_vars) + seq_along(qual_vars)]
cat("\n--- DESCRIPTIVE ASSOCIATIONS ---\n")
print(stats_table)

# These associations reuse variables that helped construct the geometry.
# MANOVA also makes distributional assumptions; Kruskal-Wallis compares
# rank distributions on Dim1. Holm adjustments cover all fourteen tests.
# Neither small p-values nor centroids establish classification performance
# or distinguish planets from instrumental artifacts.

# 7.7: Interpretation of Principal Coordinates (Variable Correlations)
# 
# Objective: Understand the meaning of Dim 1 and Dim 2 by correlating them 
# with the original variables.


# 1. Prepare Data for Correlation
# -------------------------------
# We need a matrix with the Original Variables AND the MDS Coordinates
# We select numeric columns + binary columns (converted to numeric) for correlation

# Get numeric versions of everything relevant
df_numeric_for_cor <- df_sample %>%
  dplyr::select(
    # Quantitative
    period_days, duration_hours, depth_ppm, radius_earth, 
    insolation, teff_K, radius_sun, mass_sun, logg, magnitude,
    # Binary (0/1 are valid for correlation)
    hot_star, large_planet, flag_notransit, flag_stellareclipse
  ) %>%
  mutate(across(everything(), as.numeric))

# Add the MDS Coordinates (Dim 1 to Dim 3)
cor_data <- cbind(df_numeric_for_cor, 
                  MDS_Dim1 = Y_coords[, 1], 
                  MDS_Dim2 = Y_coords[, 2], 
                  MDS_Dim3 = Y_coords[, 3])

# 2. Calculate Correlations
# -------------------------
# We calculate the correlation of ALL variables against the 3 MDS Dimensions
full_cor_matrix <- cor(cor_data, method = "spearman") # Robust non-parametric correlation

# Extract only the part we care about: Variables vs Dimensions
# Rows: Original Vars, Cols: MDS Dims
target_cor <- full_cor_matrix[1:ncol(df_numeric_for_cor), 
                              (ncol(df_numeric_for_cor)+1):ncol(full_cor_matrix)]

# 3. Visualization (The Heatmap)
# ------------------------------
# Reshape for ggplot
melted_cor <- melt(target_cor)
colnames(melted_cor) <- c("Variable", "Dimension", "Correlation")

heatmap_plot <- ggplot(melted_cor, aes(x = Dimension, y = Variable, fill = Correlation)) +
  geom_tile(color = "white") +
  
  # Color scale: Blue (Negative) - White - Red (Positive)
  scale_fill_gradient2(low = "#377EB8", mid = "white", high = "#E41A1C", 
                       midpoint = 0, limit = c(-1, 1), name = "Spearman\nCorr") +
  
  labs(
    title = "Principal Coordinates Interpretation",
    subtitle = "Spearman associations between inputs and MDS coordinates",
    x = "", y = ""
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(face = "bold", size = 10),
    axis.text.y = element_text(size = 9),
    panel.grid = element_blank()
  )

print(heatmap_plot)

# Table of Top Drivers for Each Dimension

dim1_drivers <- melted_cor %>%
  dplyr::filter(Dimension == "MDS_Dim1") %>%
  dplyr::arrange(desc(abs(Correlation))) %>%
  dplyr::mutate(Correlation = round(Correlation, 4))

cat("\n--- TOP DRIVERS OF DIMENSION 1 ---\n")
print(head(dim1_drivers, 10))

# 2. Get Drivers for Dimension 2
dim2_drivers <- melted_cor %>%
  dplyr::filter(Dimension == "MDS_Dim2") %>%
  dplyr::arrange(desc(abs(Correlation))) %>%
  dplyr::mutate(Correlation = round(Correlation, 4))

cat("\n--- TOP DRIVERS OF DIMENSION 2 ---\n")
print(head(dim2_drivers, 10))


# Use the computed Spearman coefficients to describe associations of the
# axes with inputs. Axis signs are arbitrary; these correlations do not
# identify stellar evolutionary stages, causal mechanisms or noise removal.

# 
# STEP 7.8: Variable Trajectories 
# 
# Objective: Visualize the non-linear path of key continuous variables through 
# the MDS space. This corresponds to the "influence curves" seen in Theme 4.

plot_snake <- function(var_name, pretty_name) {
  
  # 1. Prepare Data
  # We bind the variable of interest with the MDS coordinates
  plot_data <- data.frame(
    Dim1 = Y_coords[, 1],
    Dim2 = Y_coords[, 2],
    Value = df_sample[[var_name]]
  )
  
  # 2. Binning (The "Vertebrae" of the snake)
  # We split the variable into 10 quantiles (deciles) to trace the path
  plot_data$Bin <- cut(plot_data$Value, 
                       breaks = unique(quantile(plot_data$Value, probs = seq(0, 1, 0.1), na.rm = TRUE)),
                       include.lowest = TRUE, labels = FALSE)
  
  # 3. Calculate Centroids for each Bin
  snake_trace <- plot_data %>%
    group_by(Bin) %>%
    summarise(
      Mean_D1 = mean(Dim1),
      Mean_D2 = mean(Dim2),
      Mean_Val = mean(Value)
    ) %>%
    na.omit()
  
  # 4. Plot
  p <- ggplot() +
    # A. Background Points (Grey context)
    geom_point(data = plot_data, aes(x = Dim1, y = Dim2), color = "grey90", size = 1) +
    
    # B. The Snake (Path connecting centroids)
    geom_path(data = snake_trace, aes(x = Mean_D1, y = Mean_D2, color = Mean_Val), 
              linewidth = 2, arrow = arrow(length = unit(0.3, "cm"), type = "closed")) +
    
    # C. The Points on the Snake
    geom_point(data = snake_trace, aes(x = Mean_D1, y = Mean_D2, color = Mean_Val), size = 4) +
    
    # D. Labels for Start and End
    geom_label(data = head(snake_trace, 1), aes(x = Mean_D1, y = Mean_D2, label = "Low"), 
               vjust = 1.5, size = 3, fontface = "bold") +
    geom_label(data = tail(snake_trace, 1), aes(x = Mean_D1, y = Mean_D2, label = "High"), 
               vjust = -0.5, size = 3, fontface = "bold") +
    
    # Scales & Themes
    scale_color_viridis_c(option = "plasma", name = pretty_name) +
    coord_cartesian(xlim = c(-2.5, 2.5), ylim = c(-2.5, 2.5)) + # Zoom to focus on structure
    labs(
      title = paste("Trajectory:", pretty_name),
      subtitle = "How the variable moves through the MDS space (Low -> High)",
      x = "Dim 1", y = "Dim 2"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
  
  return(p)
}


# 1. Temperature (Teperature drives Dim 2)
p_temp <- plot_snake("teff_K", "Temp (log K)")

# 2. Logg (Gravity drives Dim 1 & 2 diagonal)
p_logg <- plot_snake("logg", "Surface Gravity")

# 3. Earth Radius (Size drives Dim 1)
p_radius <- plot_snake("radius_earth", "Radius (log Earth)")

# 4. Magnitude (Brightness)
p_mag <- plot_snake("magnitude", "Magnitude (Dimness)")

# Arrange in a grid
grid.arrange(p_temp, p_logg, p_radius, p_mag, ncol = 2)


# The paths connect mean coordinates across ordered input bins. They show
# associations in this projection, not stellar trajectories or a verified
# classification of dwarfs, giants or planetary environments.

# 
# STEP 7.9: Profile Identification (Conditional Scatterplots)
# 
# Objective: Color the MDS map by specific variables to visualize the 
# distribution gradients directly.

# 1. Create a Plotting Function to save time
plot_conditional <- function(var_name, pretty_title, palette_option = "viridis") {
  
  # Prepare data
  plot_df <- data.frame(
    Dim1 = Y_coords[, 1],
    Dim2 = Y_coords[, 2],
    Value = df_sample[[var_name]]
  )
  
  # Create Plot
  p <- ggplot(plot_df, aes(x = Dim1, y = Dim2, color = Value)) +
    geom_point(alpha = 0.7, size = 2) +
    
    # Use Viridis scales for clear contrast
    scale_color_viridis_c(option = palette_option, name = "Value") +
    
    # Zoom to the main structure
    coord_cartesian(xlim = c(-5, 5), ylim = c(-2.5, 5)) +
    
    labs(
      title = pretty_title,
      x = "Dim 1", y = "Dim 2"
    ) +
    theme_minimal() +
    theme(legend.position = "right")
  
  return(p)
}

# 2. Generate Plots for Key Drivers
# ---------------------------------

# A. Temperature (The driver of Dim 2)
# Using 'magma' palette for heat intuition
p1 <- plot_conditional("teff_K", "Stellar Temp (Log K)", "magma")

# B. Surface Gravity (The driver of Dim 1 & 2)
# Using 'mako' palette
p2 <- plot_conditional("logg", "Surface Gravity (logg)", "mako")

# C. Planetary Radius (The physical size)
# Using 'viridis'
p3 <- plot_conditional("radius_earth", "Planet Radius (Log Earth)", "viridis")

# D. Orbital Period (Another key dynamic factor)
# Using 'plasma'
p4 <- plot_conditional("period_days", "Orbital Period (Log Days)", "plasma")

# 3. Arrange in a 2x2 Grid
grid.arrange(p1, p2, p3, p4, ncol = 2, top = "MDS Coordinates Coloured by Input Measurements")

# Colors display the observed input values on the same projected geometry.
# Gradients describe associations and must not be read as causal mechanisms
# or validated physical labels.

# STEP 8: RelMS vs. Generalized Gower -----



# Objective: Compare RelMS with the additive construction, including
# inter-group redundancy


# 1. Run MDS on the Gower Matrix (D2_gower_gen)
# ---------------------------------------------
# We already calculated D2_gower_gen in Step 6.7 (The simple sum)

# Gram Matrix for Gower
G_gower_final <- -0.5 * H %*% D2_gower_gen %*% H

# Diagonalize
decomp_gow <- eigen(G_gower_final, symmetric = TRUE)
evals_gow <- decomp_gow$values
evecs_gow <- decomp_gow$vectors

# Check/Fix Euclidean Property (Gower is usually Euclidean, but good to check)
min_l_gow <- min(evals_gow)
if(min_l_gow < -1e-5) {
  # Apply correction if needed
  c_gow <- 2 * abs(min_l_gow)
  D2_gow_corr <- D2_gower_gen
  D2_gow_corr[row(D2_gow_corr) != col(D2_gow_corr)] <- 
    D2_gow_corr[row(D2_gow_corr) != col(D2_gow_corr)] + c_gow
  G_gower_final <- -0.5 * H %*% D2_gow_corr %*% H
  decomp_gow <- eigen(G_gower_final, symmetric = TRUE)
  evals_gow <- decomp_gow$values
  evecs_gow <- decomp_gow$vectors
}
evals_gow[evals_gow < 0] <- 0

# Coordinates
Y_gower <- evecs_gow %*% diag(sqrt(evals_gow))

# 2. Prepare Data for Comparison Plot
# -----------------------------------
# RelMS Data (from your Y_coords calculated previously)
df_relms <- data.frame(
  Dim1 = Y_coords[, 1],
  Dim2 = Y_coords[, 2],
  Type = labels_vec,
  Method = "RelMS-style Cross-term Combination"
)

# Gower Data
df_gower <- data.frame(
  Dim1 = Y_gower[, 1],
  Dim2 = Y_gower[, 2],
  Type = labels_vec,
  Method = "Scaled Squared-distance Sum"
)

# Combine
df_compare <- rbind(df_relms, df_gower)

# 3. Visualization: Side-by-Side Maps
# -----------------------------------
comp_map <- ggplot(df_compare, aes(x = Dim1, y = Dim2, color = Type)) +
  geom_point(alpha = 0.6, size = 1.5) +
  # Add density to see the structure change
  geom_density_2d(alpha = 0.4, linewidth = 0.2) +
  
  scale_color_brewer(palette = "Set1") +
  facet_wrap(~ Method, scales = "free") + # Free scales because units differ
  
  labs(
    title = "Methodological Comparison: Scaled Sum vs. Cross-term Combination",
    subtitle = "Does removing inter-group redundancy change the map structure?",
    x = "Dim 1", y = "Dim 2",
    color = "Object"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold", size = 12),
    legend.position = "bottom"
  )

print(comp_map)


# The additive and cross-block constructions yield different projections.
# Compare their geometry without treating visual class separation as proof
# of de-noising or method superiority. Labels derived from inputs are not
# an independent benchmark, and two-dimensional retention is very low.



# STEP 9: Network Graph Visualization -----

# 1. Select Subset (Keep N=50)
set.seed(123) 
subset_idx <- sample(1:n, 50) 

D2_sub_gower <- D2_gower_gen[subset_idx, subset_idx]
D2_sub_relms <- D2_relms[subset_idx, subset_idx]
grp_sub <- as.factor(labels_vec[subset_idx])

# 2. Similarity Conversion
dist_to_sim <- function(D) {
  D_norm <- D / max(D) 
  Sim <- 1 - D_norm    
  diag(Sim) <- 0
  return(Sim)
}

S_gower <- dist_to_sim(D2_sub_gower)
S_relms <- dist_to_sim(D2_sub_relms)

# 3. CALCULATE DYNAMIC THRESHOLDS (Relaxed)
# We lower the quantile to 0.75 to allow more lines (Top 25% strong connections)
thresh_gow <- quantile(S_gower[lower.tri(S_gower)], 0.75)
thresh_rel <- quantile(S_relms[lower.tri(S_relms)], 0.75)

# 4. Plotting
par(mfrow = c(1, 2)) 

# Colors: Blue=Planet, Red=False Positive
groups_list <- list(
  Planet = which(grp_sub == "Confirmed/Candidate"),
  FalsePositive = which(grp_sub == "False Positive")
)

# Common Qgraph arguments for consistency
qgraph_args <- list(
  layout = "spring",
  groups = groups_list,
  color = c("#377EB8", "#E41A1C"),
  vsize = 4,                # Small node size (fixed)
  labels = 1:50,            # Show Observation Number
  label.cex = 0.7,          # Small text size
  label.scale = FALSE,      # Text doesn't resize with node
  borders = FALSE,
  edge.color = "darkgray",
  legend = FALSE            # No legend
)

# --- Plot A: Classical Gower ---
do.call(qgraph, c(list(input = S_gower, 
                       title = "Scaled Sum",
                       minimum = thresh_gow,
                       cut = thresh_gow + 0.1), qgraph_args))

# --- Plot B: Robust RelMS ---
do.call(qgraph, c(list(input = S_relms, 
                       title = "Cross-term Combination",
                       minimum = thresh_rel,
                       cut = thresh_rel + 0.1), qgraph_args))

par(mfrow = c(1, 1))


# Thresholded networks depend on the chosen edge rule and layout. They are
# illustrations of these distance matrices, not tests of signal recovery
# or evidence that either construction removes false detections.



# STEP 9.5 : Configuration Stability (Repeated Subsampling with Procrustes) ------


# Objective: Visualize how much EACH point moves when data is perturbed.


# 1. Setup
n_iter <- 20         # 20 runs is enough
sample_frac <- 0.9   # Keep 90% of data
n_points <- nrow(Y_coords)

# Vectors to store the mean shift (radius) for each point
displacement_sum <- rep(0, n_points)
count_participation <- rep(0, n_points)

# The Target is our official map (Dim 1 & 2)
target_conf <- Y_coords[, 1:2]

# 2. Repeated Subsampling Loop
set.seed(123)
pb <- txtProgressBar(min = 0, max = n_iter, style = 3)

for (i in 1:n_iter) {
  
  # A. Subsample
  idx <- sample(1:n_points, size = round(n_points * sample_frac), replace = FALSE)
  
  # B. Recalculate MDS on subset
  # We use the corrected squared distances D2_corrected
  D_sub_sq <- D2_corrected[idx, idx]
  # cmdscale needs DISTANCES (sqrt of squared), not squared distances
  mds_sub <- cmdscale(sqrt(D_sub_sq), k = 2)
  
  # C. Procrustes Alignment
  # Rotate mds_sub to match target_conf
  proc_res <- procrustes(target_conf[idx, ], mds_sub, symmetric = FALSE)
  
  # D. Measure displacement (residuals)
  # FIX: Use residuals() function. It returns the distances directly.
  # Do NOT use sqrt() here again.
  shifts <- residuals(proc_res) 
  
  # Accumulate
  displacement_sum[idx] <- displacement_sum[idx] + shifts
  count_participation[idx] <- count_participation[idx] + 1
  
  setTxtProgressBar(pb, i)
}
close(pb)

# 3. Calculate Mean Radius for each point
stopifnot(all(count_participation > 0))
stability_radius <- displacement_sum / count_participation

# Prepare Data
stability_df <- data.frame(
  Dim1 = Y_coords[, 1],
  Dim2 = Y_coords[, 2],
  Radius = stability_radius, # This determines circle size
  Type = labels_vec
)

# 4. Visualization (The Bubble Plot)
p_conf_stability <- ggplot(stability_df, aes(x = Dim1, y = Dim2)) +
  # A. The Uncertainty Circles
  geom_circle(aes(x0 = Dim1, y0 = Dim2, r = Radius, color = Type), 
              alpha = 0.4, linetype = "dotted") +
  
  # B. The Center Points
  geom_point(aes(color = Type), size = 1) +
  
  scale_color_brewer(palette = "Set1") +
  labs(
    title = "Configuration Stability (90% Subsamples)",
    subtitle = "Radius = Mean Procrustes displacement over participating subsamples.",
    x = "Dim 1", y = "Dim 2",
    color = "Object"
  ) +
  coord_fixed(xlim = c(-7, 2.5), ylim = c(-2.5, 5)) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p_conf_stability)


# Resampling circles summarize displacement after Procrustes alignment.
# They reflect this subsampling procedure, not physical uncertainty or
# uncertainty in the source measurements.



# Bootstrap ordered eigenvalues to describe their sampling variability.
# Eigenvalues are sorted within each resample, so being below y=x follows
# from ordering and cannot rule out eigenvector mixing or axis crossing.

# 1. Setup
n_boot <- 50          
n_points <- nrow(D2_corrected)
eigen_store <- data.frame(Run = integer(), D1 = numeric(), D2 = numeric(), D3 = numeric())

# Pre-calculate centering constants
I <- diag(n_points)
One <- matrix(1, n_points, n_points)

# 2. Bootstrap Loop
set.seed(123)
pb <- txtProgressBar(min = 0, max = n_boot, style = 3)

for(i in 1:n_boot) {
  idx <- sample(1:n_points, n_points, replace = TRUE)
  D_sub <- D2_corrected[idx, idx]
  
  # Fast Centering
  r_mean <- rowMeans(D_sub)
  c_mean <- colMeans(D_sub)
  g_mean <- mean(D_sub)
  G <- -0.5 * (sweep(sweep(D_sub, 1, r_mean, "-"), 2, c_mean, "-") + g_mean)
  
  # Eigenvalues (Top 3)
  ev <- eigen(G, symmetric = TRUE, only.values = TRUE)$values
  pos_ev <- ev[ev > 0]
  total_var <- sum(pos_ev)
  
  eigen_store <- rbind(eigen_store, data.frame(
    Run = i,
    D1 = pos_ev[1] / total_var, 
    D2 = pos_ev[2] / total_var,
    D3 = pos_ev[3] / total_var
  ))
  
  setTxtProgressBar(pb, i)
}
close(pb)

# 3. Plotting Function (Centroid Only)
create_stab_plot <- function(data, x_col, y_col, title) {
  
  # Calculate Centroid
  cent_x <- mean(data[[x_col]])
  cent_y <- mean(data[[y_col]])
  
  # Dynamic limits (Based ONLY on the cloud now)
  all_vals <- c(data[[x_col]], data[[y_col]])
  lim_min <- min(all_vals) * 0.98
  lim_max <- max(all_vals) * 1.02
  
  p <- ggplot(data, aes(x = .data[[x_col]], y = .data[[y_col]])) +
    # Diagonal y=x
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray40") +
    
    # Bootstrap Cloud
    geom_point(alpha = 0.4, color = "#377EB8", size = 1.5) +
    stat_ellipse(level = 0.95, color = "#E41A1C", linewidth = 0.8) +
    
    # Centroid Marker (Black Dot)
    annotate("point", x = cent_x, y = cent_y, shape = 16, size = 3, color = "black") + 
    
    # Force Square Ratio
    coord_fixed(ratio = 1, xlim = c(lim_min, lim_max), ylim = c(lim_min, lim_max)) +
    
    labs(title = title, x = paste("Var", x_col), y = paste("Var", y_col)) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 11, face = "bold"),
      panel.border = element_rect(color = "black", fill = NA)
    )
  return(p)
}

# 4. Generate and Combine
p12 <- create_stab_plot(eigen_store, "D1", "D2", "Dim 1 vs Dim 2")
p13 <- create_stab_plot(eigen_store, "D1", "D3", "Dim 1 vs Dim 3")
p23 <- create_stab_plot(eigen_store, "D2", "D3", "Dim 2 vs Dim 3")

grid.arrange(p12, p13, p23, ncol = 3, 
             top = "Eigenvalue Stability: Bootstrap Cloud & Centroid")

# The clouds show variability of ordered eigenvalues across fifty bootstrap
# replicates. Ellipses are fitted coverage contours, not
# confidence regions for their means. Ordering forces lambda1 >= lambda2;
# axis stability requires eigenvector or subspace comparisons.


# STEP 11: Methodological Evolution -----

# Objective: Visual comparison of the map structure across 3 methodologies.


# 1. Generate Coordinates for 3 Methods
# -------------------------------------

# Method A: Naive Euclidean (Raw Data)
# We calculate MDS on simple Euclidean distance of X1
d_euc <- dist(X1_quant, method = "euclidean")
mds_euc <- cmdscale(d_euc, k = 2)

# Method B: Robust Mahalanobis (Physics Only)
# We use the D1_quant_sq we calculated
mds_mah <- cmdscale(as.dist(sqrt(D1_quant_sq)), k = 2)

# Method C: RelMS (Physics + Flags + Cat) - CORRECTED
# This is our final result: Y_coords
mds_relms <- Y_coords[, 1:2]

# 2. Align Maps (Procrustes)
# --------------------------
# To compare them fairly, we rotate A and B to match the orientation of RelMS (C)
# otherwise they might be upside down or rotated 90 degrees.
align_euc <- procrustes(mds_relms, mds_euc)$Yrot
align_mah <- procrustes(mds_relms, mds_mah)$Yrot
align_rel <- mds_relms # The reference

# 3. Prepare Dataframe
# --------------------
df_evolution <- rbind(
  data.frame(D1 = align_euc[,1], D2 = align_euc[,2], Method = "1. Naive Euclidean", Type = labels_vec),
  data.frame(D1 = align_mah[,1], D2 = align_mah[,2], Method = "2. Robust Mahalanobis", Type = labels_vec),
  data.frame(D1 = align_rel[,1], D2 = align_rel[,2], Method = "3. Final RelMS", Type = labels_vec)
)

# 4. Visualization
# ----------------
p_evolution <- ggplot(df_evolution, aes(x = D1, y = D2, color = Type)) +
  geom_point(alpha = 0.5, size = 1) +
  
  # Separate by Method
  facet_wrap(~Method, scales = "free") +
  
  scale_color_brewer(palette = "Set1") +
  labs(
    title = "Evolution of the Map Structure",
    subtitle = "Euclidean, robust Mahalanobis and joint dissimilarities; panel scales differ",
    x = "Dim 1", y = "Dim 2",
    color = "Object"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold", size = 12),
    legend.position = "bottom"
  )

print(p_evolution)

# These panels compare geometries induced by three distance constructions.
# Their shapes do not identify the main sequence or giant branch. The
# low-dimensional RelMS view retains little total variability; neither
# this comparison nor the subsequent k=7 profiles validate noise removal.

# No independent target or benchmark here establishes which metric best
# preserves physical structure. Treat the comparison as exploratory.


# ==============================================================================
# PHASE II: CLUSTERING ANALYSIS
# ==============================================================================


# STEP 12: ASSESSMENT OF CLUSTERING TENDENCY (VAT & HOPKINS) -----


# PAM uses the first five RelMS coordinates, an exploratory truncation
# retaining about 2.55% of corrected variability in this run. Cluster
# results are conditional on that substantial loss of distance information.
clus_data <- Y_coords[, 1:5]

# Ensure it's a dataframe
clus_data <- as.data.frame(clus_data)
colnames(clus_data) <- paste0("Dim", 1:5)

# Hopkins compares observed neighbor distances with a uniform reference
# in the bounding box. High values under this package convention suggest
# nonuniformity; 0.75 is not a calibrated 90% confidence threshold.
set.seed(123)
hopkins_res <- get_clust_tendency(clus_data, n = 100, graph = FALSE)

cat("\nHopkins Statistic:", round(hopkins_res$hopkins_stat, 4), "\n")

# 3. VAT (The Visual Test)
# ------------------------
# We take a random subset of 200 points to make the plot sharp and readable.
# If we used all 1000, it would look blurry.
set.seed(123)
vat_sub_idx <- sample(1:nrow(clus_data), 200)
dist_vat <- dist(clus_data[vat_sub_idx, ])

# This plots the ordered dissimilarity matrix.
p_vat <- fviz_dist(dist_vat, 
                   gradient = list(low = "#00AFBB", mid = "white", high = "#FC4E07"),
                   order = TRUE, show_labels = FALSE) +
  labs(title = "Ordered Pairwise-Distance Heatmap")

print(p_vat)

# Read the computed Hopkins statistic and VAT image as tendency diagnostics.
# Nonuniformity need not imply discrete clusters, and these diagnostics
# neither determine k nor establish statistical certainty.



# STEP 13: HIERARCHICAL CLUSTERING (THE DENDROGRAM) -----

# Goal: Visualize the tree structure and choose the best linkage method.

# 1. Calculate Distance Matrix on the MDS Coordinates
# ---------------------------------------------------
# We are clustering the *positions* in the map (RelMS coordinates).
d_clus <- dist(clus_data, method = "euclidean")

# 2. Compare Linkage Methods 
# ----------------------------------------------------
# We test 4 methods to see which one creates the strongest structure (AC close to 1).

methods_list <- c("average", "single", "complete", "ward")
ac_scores <- numeric(length(methods_list))
names(ac_scores) <- methods_list

pb <- txtProgressBar(min = 0, max = length(methods_list), style = 3)

for(i in 1:length(methods_list)) {
  # Calculate Agglomerative Coefficient for each method
  ac_scores[i] <- agnes(d_clus, method = methods_list[i])$ac
  setTxtProgressBar(pb, i)
}
close(pb)

cat("\nAgglomerative Coefficients:\n")
print(round(ac_scores, 4))

# Interpretation logic:
best_method <- names(which.max(ac_scores))
cat(">> HIGHEST AGGLOMERATIVE COEFFICIENT:", toupper(best_method), "\n")

# 3. Visualization: The Dendrogram
# -----------------------------------------------
# We use Ward
# Note: hclust uses "ward.D2" for the standard Ward method.

if(best_method == "ward") { use_method <- "ward.D2" } else { use_method <- best_method }

hc_res <- hclust(d_clus, method = use_method)

# Plot Circular Dendrogram
# We pre-color for k=2 to visually check if the Planet/Noise split matches the tree
p_dendro <- fviz_dend(hc_res, 
                      k = 2,                 # Pre-cut for 2 groups
                      cex = 0.3,             # Small label size
                      k_colors = c("#E41A1C", "#377EB8"),
                      color_labels_by_k = FALSE, 
                      rect = TRUE,           # Add rectangle around groups
                      type = "circular",     # Circular layout
                      show_labels = FALSE,   # Hide labels for clarity
                      main = paste0("2. Circular Dendrogram (", toupper(best_method), " Linkage)")) +
theme_void() + 
theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 14))

print(p_dendro)


# Agglomerative coefficients and dendrograms describe each linkage on this
# representation. A high coefficient does not identify physical populations
# or imply that the two largest branches correspond to disposition labels.

# 
# STEP 14: METHOD COMPARISON (COPHENETIC CORRELATION) ------
# 
# Goal: Select the linkage method.

# 1. Define methods to test
# Important: "ward.D2" is the standard Ward implementation in R
methods_list <- c("average", "single", "complete", "ward.D2")
names(methods_list) <- c("Average", "Single", "Complete", "Ward")

# 2. Compute Cophenetic Correlation for each
cophenetic_scores <- numeric(length(methods_list))

for(i in 1:length(methods_list)) {
  # Build tree
  hc_temp <- hclust(d_clus, method = methods_list[i])
  # Compute cophenetic distances from tree
  coph_dist <- cophenetic(hc_temp)
  # Correlate with original distances
  cophenetic_scores[i] <- cor(d_clus, coph_dist)
}

names(cophenetic_scores) <- names(methods_list)

cat("\nCophenetic Correlations (Higher is better representation):\n")
print(round(cophenetic_scores, 4))

# 3. Visual Comparison (2x2 Panel)
par(mfrow = c(2, 2)) # Create 2x2 grid

for(m in names(methods_list)) {
  # Re-calculate just for plotting
  if(m == "Ward") { meth <- "ward.D2" } else { meth <- tolower(m) }
  
  hc_temp <- hclust(d_clus, method = meth)
  
  # Plot with the correct correlation in the subtitle
  plot(hc_temp, labels = FALSE, hang = -1, 
       main = paste(m, "Linkage"),
       xlab = "", 
       sub = paste("Cophenetic Corr:", round(cophenetic_scores[m], 4)),
       ylab = "Height")
}

par(mfrow = c(1, 1)) # Reset layout


# Mardia et al., 1989 rule (just to try, normally it gives much more cluster than desired):

n <- nrow(clus_data)
k <- round(sqrt(n/2))    
clusters <- cutree(hc_res, k = k)
print(k) # too many

# Cophenetic correlation measures how well dendrogram merge distances
# represent the original dissimilarities. Ward favors compact groups,
# while average linkage optimizes a different criterion. We use Ward as
# an exploratory choice, without assigning signal/noise meaning to its branches.


# STEP 15: DETERMINING OPTIMAL CLUSTERS (THE "k" DECISION) ------

# Goal: Compare descriptive elbow and silhouette criteria within the tested grid.

# We test from k=1 to k=8 using the PAM algorithm (Partitioning Around Medoids)
# PAM is the robust version of K-Means we will use in the next step.

# A. Elbow Method (Total Within Sum of Square)
# --------------------------------------------
# Look for the "knee" where the curve flattens.
p_elbow <- fviz_nbclust(clus_data, pam, method = "wss", k.max = 8) +

  labs(title = "3a. Elbow Method (WSS)", 
       subtitle = "Descriptive within-cluster dispersion")

# B. Silhouette Method (Average Width)
# ------------------------------------
# Look for the highest bar.
p_sil_k <- fviz_nbclust(clus_data, pam, method = "silhouette", k.max = 8) +
  labs(title = "3b. Average Silhouette Method", 
       subtitle = "Best silhouette in k=2 to 8 grid")

# Combine them side-by-side
grid.arrange(p_elbow, p_sil_k, ncol = 2)


# Run PAM for the chosen k just for validation
k_check <- 7
set.seed(123)
pam_check <- pam(clus_data, k = k_check)

# Plot the "Folded Histogram" (Silhouette Plot)
# 
# - X-axis: Silhouette width (closer to 1 is better)
# - Y-axis: Each individual observation
p_sil_indiv <- fviz_silhouette(pam_check, 
                               palette = "jco", 
                               print.summary = FALSE,
                               ggtheme = theme_minimal()) +
  labs(title = paste("Silhouette Plot for k =", k_check), 
       subtitle = "Each bar represents a point. Negative bars = Closer on average to another cluster.") +
  theme(axis.text.x = element_text(angle = 0))

print(p_sil_indiv)

# Print Summary Stats
# 
# Let's see the average width per cluster
sil_info <- silhouette(pam_check)
cat("\nAverage Silhouette Width per Cluster:\n")
print(summary(sil_info)$clus.avg.widths)
cat("\nGlobal Average:", round(summary(sil_info)$avg.width, 4), "\n")

# Inspect the computed WSS and silhouette profiles. k=7 is an exploratory
# profiling choice, not a proven optimum or a significance test. Negative
# silhouettes flag observations closer to another cluster on average.
# Compare k=2 and k=7 without equating either with astrophysical classes.

 


# STEP 16: Clusters Plotting (k=2 vs k=7) ------

# Compare two exploratory partitions using projected normal 95% coverage
# ellipses. These are not confidence regions for cluster means, and the
# fixed plotting limits omit some observations from view.

# 1. Setup Models & Colors
# ------------------------
set.seed(123)
pam_k2 <- pam(clus_data, k = 2)
pam_k7 <- pam(clus_data, k = 7)

# Palettes
cols_k2 <- c("#E41A1C", "#377EB8") # Red/Blue
cols_k7 <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#00BCD8", "#A65628")

# Specific Limits requested
x_lims <- c(-2.5, 7.5)
y_lims <- c(-3, 3)

# Left Panel: k=2 (Binary)
p_k2_ell <- fviz_cluster(pam_k2, 
                         data = clus_data, stand = FALSE,
                         geom = "point", 
                         pointsize = 1.2,
                         
                         ellipse.type = "norm", 
                         ellipse.level = 0.95, # Show 95% core
                         ellipse.alpha = 0.15,
                         
                         palette = cols_k2, 
                         ggtheme = theme_minimal(),
                         main = "A. Exploratory Partition (k=2)") +
  coord_cartesian(xlim = x_lims, ylim = y_lims) + 
  theme(legend.position = "none", plot.title = element_text(hjust = 0.5))

# Right Panel: k=7 (Granular)
p_k7_ell <- fviz_cluster(pam_k7, 
                         data = clus_data, stand = FALSE,
                         geom = "point", 
                         pointsize = 1.2,
                         
                         ellipse.type = "norm",
                         ellipse.level = 0.95,
                         ellipse.alpha = 0.15,
                         
                         palette = cols_k7, 
                         ggtheme = theme_minimal(),
                         main = "B. Exploratory Detailed Partition (k=7)") +
  coord_cartesian(xlim = x_lims, ylim = y_lims) + 
  theme(legend.position = "none", plot.title = element_text(hjust = 0.5))

# Combine side-by-side
grid.arrange(p_k2_ell, p_k7_ell, ncol = 2, 
             top = "Fitted 95% Data Ellipses (axis percentages refer to the retained 5D space)")


# The cropped projection and ellipses illustrate the two partitions. More
# clusters generally give smaller groups; that alone is not evidence of a
# better model. Assess the numeric diagnostics and retained dimensions.



# STEP 17: EXTERNAL VALIDATION & PROFILING (Custom Variables)

# Goal: Profile the 7 clusters using the variables WE created (Physical & Flags).

# 1. Setup Models
set.seed(123)
pam_k2 <- pam(clus_data, k = 2)
pam_k7 <- pam(clus_data, k = 7)

# 2. Define the Variables to Test
desired_vars <- c("binary_disposition", 
                  "flag_notransit",       # Error Flag 1
                  "flag_stellareclipse",  # Error Flag 2
                  "hot_star",             # Physical 1
                  "large_planet",         # Physical 2
                  "insolation_class",     # Physical 3
                  "magnitude_class")      # Observational 1

# 3. Build Comparison Table (ARI)
# -------------------------------
comp_results <- data.frame(
  Variable = character(), 
  ARI_k2 = numeric(), 
  ARI_k7 = numeric(),
  stringsAsFactors = FALSE
)

for(var in desired_vars) {
  # Safety check: ensure variable exists
  if(var %in% names(df_sample)) {
    
    real_labels <- as.factor(df_sample[[var]])
    
    # Calculate ARI
    ari2 <- adjustedRandIndex(real_labels, pam_k2$clustering)
    ari7 <- adjustedRandIndex(real_labels, pam_k7$clustering)
    
    comp_results <- rbind(comp_results, data.frame(
      Variable = var, 
      ARI_k2 = ari2, 
      ARI_k7 = ari7
    ))
  }
}

# Round for cleaner display
comp_results$ARI_k2 <- round(comp_results$ARI_k2, 4)
comp_results$ARI_k7 <- round(comp_results$ARI_k7, 4)

cat("\n--- DESCRIPTIVE AGREEMENT (ARI; shared input features) ---\n")
print(comp_results)


# 4. Visualization: Cluster Composition for k=7 (The Profiling)
# -------------------------------------------------------------
plot_list <- list()

for(var in comp_results$Variable) { 
  
  # Prepare data
  plot_df <- data.frame(
    Cluster = as.factor(pam_k7$clustering), 
    Category = as.factor(df_sample[[var]])
  )
  
  # Stacked Bar Plot
  p <- ggplot(plot_df, aes(x = Cluster, fill = Category)) +
    geom_bar(position = "fill") + 
    scale_y_continuous(labels = scales::percent) +
    scale_fill_brewer(palette = "Set2") + 
    labs(
      title = paste("By:", var), 
      x = "Cluster", y = ""
    ) +
    theme_minimal() + 
    theme(
      legend.position="top", 
      plot.title=element_text(size=10, face="bold"),
      axis.text.y=element_blank(), # Cleaner look
      legend.key.size = unit(0.3, "cm")
    )
  
  plot_list[[var]] <- p
}

# Display Grid (Adaptive layout)
if(length(plot_list) > 0) {
  grid.arrange(grobs = plot_list, ncol = 3, 
               top = "k=7 PROFILING: Physical & Instrumental Composition")
}

# Interpretation of the ARI Performance Table

# k=2 and k=7 are exploratory comparisons. Agreement against flags and derived
# labels is descriptive because these features also enter the distance.

# STEP 17: CLUSTER PROFILING (Physical Characterization) -----


# 1. Assign clusters to the original dataframe (if not already done)
# ------------------------------------------------------------------
# We assume 'pam_k7' is your final model with 7 clusters
if(!exists("pam_k7")) stop("Please run the pam_k7 model before this step.")
df_sample$Cluster <- as.factor(pam_k7$clustering)

# 2. PHYSICAL DIAGNOSTIC TABLE (The key for interpretation)
# ------------------------------------------------------------------
# We calculate the median of each variable per cluster.
# IMPORTANT: We undo the Log10 transformation (10^x - 1) to read 
# real physical values (Days, Earth Radii, Kelvin), not logarithms.

cluster_summary <- df_sample %>%
  group_by(Cluster) %>%
  summarise(
    Count = n(),
    # Physical Variables (Real Median)
    R_Earth_Med = median(10^radius_earth - 1),    # Planetary Radius (Earth Radii)
    Period_Day_Med = median(10^period_days - 1),  # Orbital Period (Days)
    Teff_K_Med = median(10^teff_K - 1),           # Star Temp (Kelvin)
    Insol_Med = median(10^insolation - 1),        # Insolation (Earth Flux)
    
    # "Quality" Variables (Proportion of Flags)
    # Higher values indicate a higher likelihood of False Positives / Noise
    Bad_Transit_Pct = mean(flag_notransit) * 100,
    Eclipse_Pct = mean(flag_stellareclipse) * 100
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2))) # Round for better readability

cat("\n--- CLUSTER DIAGNOSTIC TABLE (Please copy this output) ---\n")
print(cluster_summary)


# 3. VISUALIZATION A: MULTIVARIATE PROFILING (Boxplots)
# ------------------------------------------------------------------
# Select key variables (keeping Log scale for compact visualization)
vars_plot <- c("radius_earth", "period_days", "teff_K", "insolation")
labels_plot <- c("Radius (Log R_Earth)", "Period (Log Days)", "Star Temp (Log K)", "Insolation (Log Flux)")

df_long <- df_sample %>%
  dplyr::select(Cluster, all_of(vars_plot)) %>%
  pivot_longer(cols = -Cluster, names_to = "Variable", values_to = "Value") %>%
  mutate(Variable = factor(Variable, levels = vars_plot, labels = labels_plot))

p_box <- ggplot(df_long, aes(x = Cluster, y = Value, fill = Cluster)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.5) +
  facet_wrap(~ Variable, scales = "free_y", ncol = 2) +
  scale_fill_brewer(palette = "Set1") +
  labs(title = "Physical Profile of the 7 Clusters", 
       subtitle = "Distribution of key parameters (Logarithmic Scale)") +
  theme_minimal() +
  theme(legend.position = "none")

print(p_box)


# Plot candidate period and radius by cluster. These catalog estimates
# and disposition flags do not determine composition or planet type.

p_exomap <- ggplot(df_sample, aes(x = period_days, y = radius_earth, color = Cluster)) +
  # Background points (grey) for context
  geom_point(data = df_sample %>% dplyr::select(-Cluster), 
             aes(x = period_days, y = radius_earth), color = "grey85", size = 0.5) +
  # Cluster points
  geom_point(size = 2, alpha = 0.8) +
  # Approximate reference lines (in Log10)
  geom_hline(yintercept = log10(4 + 1), linetype = "dashed", color = "black") + # Super-Earth/Neptune limit
  annotate("text", x = 0, y = 0.75, label = "R <= 4 Earth radii", hjust = 0, size = 3, fontface="italic") +
  annotate("text", x = 0, y = 0.9, label = "R > 4 Earth radii", hjust = 0, size = 3, fontface="italic") +
  
  scale_color_brewer(palette = "Set1") +
  facet_wrap(~ Cluster) +
  labs(title = "Exoplanet Classification Map by Cluster",
       subtitle = "Period vs. Radius Relationship (Separated by Group)",
       x = "Orbital Period [log10(days + 1)]",
       y = "Planetary Radius [log10(Earth radii + 1)]") +
  theme_bw() +
  theme(legend.position = "none")

print(p_exomap)

# 5. SNAKE PLOT (Standardized Profile) 

# Define a base palette for clusters (fallback)
my_colors <- cols_k7

# If you have more than 7 clusters, we extend the palette automatically
if(length(unique(df_sample$Cluster)) > length(my_colors)){
  my_colors <- colorRampPalette(my_colors)(length(unique(df_sample$Cluster)))
}

# 1. Standardize the data (Z-Score Normalization)
# Formula: Z = (x - mean) / sd. This centers everything at 0.
df_scaled_profile <- df_sample %>%
  dplyr::select(Cluster, radius_earth, period_days, teff_K, insolation, magnitude, logg) %>%
  mutate(across(-Cluster, scale)) %>%  # Scale all columns except Cluster
  group_by(Cluster) %>%
  summarise(across(everything(), ~ mean(.x, na.rm = TRUE))) %>% # Calculate Mean Z-Score per Cluster
  pivot_longer(cols = -Cluster, names_to = "Feature", values_to = "Z_Score") %>%
  mutate(Cluster = as.factor(Cluster))

# 2. Plot
p_snake <- ggplot(df_scaled_profile, aes(x = Feature, y = Z_Score, group = Cluster, color = Cluster)) +
  geom_line(linewidth = 1.2, alpha = 0.8) +
  geom_point(size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", alpha = 0.6) +
  
  scale_color_manual(values = my_colors) +
  
  labs(title = "Snake Plot: Cluster 'DNA'",
       subtitle = "Comparison against Global Average (0)",
       y = "Standardized Z-Score") +
  theme_light() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
        legend.position = "top")

print(p_snake)

# The zero line is the overall mean on standardized transformed inputs.
# Profiles describe relative cluster means. Crossing lines do not imply
# inverse correlation, and these inputs do not identify Hot Jupiters.


# 6. RELATIVE IMPORTANCE HEATMAP (% Deviation)

# 1. Calculate Global Means and Cluster Means
global_means <- df_sample %>%
  mutate(across(c(radius_earth, period_days, teff_K, insolation), ~ 10^.x - 1)) %>%
  dplyr::select(radius_earth, period_days, teff_K, insolation) %>%
  summarise(across(everything(), ~ mean(.x, na.rm = TRUE)))

cluster_means <- df_sample %>%
  mutate(across(c(radius_earth, period_days, teff_K, insolation), ~ 10^.x - 1)) %>%
  dplyr::select(Cluster, radius_earth, period_days, teff_K, insolation) %>%
  group_by(Cluster) %>%
  summarise(across(everything(), ~ mean(.x, na.rm = TRUE)))

# 2. Calculate % Difference: (ClusterMean - GlobalMean) / GlobalMean
# We iterate to apply the formula respecting the columns
df_relative <- cluster_means %>%
  mutate(across(-Cluster, ~ (. - global_means[[cur_column()]]) / global_means[[cur_column()]])) %>%
  pivot_longer(cols = -Cluster, names_to = "Feature", values_to = "Pct_Diff") %>%
  mutate(Cluster = as.factor(Cluster))

# 3. Plot
p_heatmap <- ggplot(df_relative, aes(x = Feature, y = Cluster, fill = Pct_Diff)) +
  geom_tile(color = "white") +
  
  # Add text labels (e.g., +15%)
  geom_text(aes(label = scales::percent(Pct_Diff, accuracy = 1)), color = "black", size = 3.5) +
  
  # Color Scale: Red (Below Avg) -> White (Avg) -> Green (Above Avg)
  scale_fill_gradient2(low = "#D73027", mid = "white", high = "#1A9850", midpoint = 0, labels = scales::percent) +
  
  labs(
    title = "Relative Physical Means (Original Units)",
    subtitle = "Percentage deviation from the Global Mean. Red = Below Avg, Green = Above Avg.",
    x = "Feature",
    y = "Cluster ID",
    fill = "% Deviation"
  ) +
  theme_minimal() +
  theme(panel.grid = element_blank())

print(p_heatmap)

# Positive and negative cells indicate above- and below-average values,
# respectively. Below average is not absence; radius alone does not identify
# a rocky composition. Inspect the units and physical-scale medians.

# 7. RADAR CHART (Spider Plot)

# 1. Prepare Data: Normalize to 0-1 range (Min-Max Scaling)
# Radar charts require data to be strictly between 0 and 1 (or defined min/max).
data_radar_raw <- df_sample %>%
  dplyr::select(radius_earth, period_days, teff_K, insolation, magnitude)

# Normalize function
min_max_norm <- function(x) {
  if (diff(range(x)) == 0) return(rep(0, length(x)))
  (x - min(x)) / diff(range(x))
}
data_radar_norm <- as.data.frame(lapply(data_radar_raw, min_max_norm))

# Add Cluster IDs back and calculate Mean per Cluster
data_radar_norm$Cluster <- df_sample$Cluster
radar_means <- data_radar_norm %>%
  group_by(Cluster) %>%
  summarise(across(everything(), mean)) %>%
  dplyr::select(-Cluster) # Remove ID for plotting

# 2. Add Max and Min rows (Required by fmsb package: Row 1 = Max(1), Row 2 = Min(0))
radar_final <- rbind(rep(1, ncol(radar_means)), rep(0, ncol(radar_means)), radar_means)

# 3. Plot (Loop to create one small radar per cluster or one big overlay)
# Here we create an overlay for comparison.

# Define colors and transparency
colors_border <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFFF33", "#A65628")
colors_in <- scales::alpha(colors_border, 0.1)

# Plot
# Reset par just in case
par(mfrow = c(1, 1)) 

# Use our custom 'my_colors' vector defined at the start
colors_border <- my_colors[1:nrow(radar_means)] # Select as many colors as clusters
colors_in <- scales::alpha(colors_border, 0.1)  # Make them transparent for filling

radarchart(radar_final, axistype = 1,
    # Custom Polygon colors
    pcol = colors_border, pfcol = colors_in, plwd = 2,
    # Grid styling
    cglcol = "grey", cglty = 1, axislabcol = "grey", caxislabels = seq(0, 1, 0.25), cglwd = 0.8,
    vlcex = 0.8,
    title = "Cluster Profiles: Radar Comparison"
)

# Allow the legend to use the plot margins while keeping it inside the page.
par(xpd = NA)

legend(
  x = "topright",
  inset = c(0.01, 0.01),  # Keep the legend inside the figure device
  legend = paste("Cluster", 1:nrow(radar_means)),
  bty = "n",
  pch = 20,
  col = colors_border,
  text.col = "black",
  cex = 0.8,
  pt.cex = 1.2
)

# Reset clipping
par(xpd = FALSE)

# Radar profiles use the displayed rescaling. Polygon area depends on
# axis order and scaling, and does not summarize total physical size,
# brightness or energy. Compare individual axes rather than polygon area.



# STEP 18: CLUSTER NAMING & INTERPRETATION -----

# 1. GENERATE DIAGNOSTIC TABLE (Un-logging the variables)

# We calculate the median of each variable per cluster.
# IMPORTANT: We undo the Log10 transformation (10^x - 1) to see real physics.

cluster_summary <- df_sample %>%
  group_by(Cluster) %>%
  summarise(
    # Physical Variables (Real Median)
    Med_Radius = median(10^radius_earth - 1),    # Earth Radii
    Med_Period = median(10^period_days - 1),     # Days
    Med_Temp   = median(10^teff_K - 1),          # Kelvin
    Med_Insol  = median(10^insolation - 1),      # Earth Flux
    
    # "Quality" Variables (Average of binary flags)
    # If > 0.5, it means more than 50% of the cluster has this error.
    Pct_Eclipse = mean(flag_stellareclipse),
    Pct_NoTrans = mean(flag_notransit)
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

print("--- CLUSTER DIAGNOSTIC TABLE ---")
print(cluster_summary)


# 2. AUTOMATIC NAMING LOGIC (Astrophysics Rules)

# Instead of hardcoding "Cluster 1 = Giant", we use logic.
# This makes your code robust even if cluster numbers change.

# We join the summary back to the main dataframe to apply labels

df_final <- df_sample %>%
  left_join(cluster_summary, by = "Cluster") %>%
  mutate(
    Cluster_Label = case_when(
      
      # --- 1. IDENTIFYING NOISE (High Flags or Impossible Radii) ---
      # Cluster 6 fits here (High NoTrans + Radius > 25)
      Pct_NoTrans > 0.40 | Med_Radius > 25 ~ "High non-transit flag / very large fitted radius",
      
      # Cluster 4 fits here (High Eclipse flag + Radius > 20)
      Pct_Eclipse > 0.40 | Med_Radius > 20 ~ "High eclipse flag / large fitted radius",
      
      # Cluster 3 fits here (Moderate Eclipse flag + Short Period)
      Pct_Eclipse > 0.30 & Med_Period < 3 ~ "Short periods with elevated eclipse flags",

      # --- 2. IDENTIFYING PLANETS (Clean Candidates) ---
      
      # Cluster 2 fits here (Small Radius + Low Insolation relative to others)
      # We call it "Warm" instead of "Habitable" to be scientifically safe (Insol ~23)
      Med_Radius < 2.5 & Med_Insol < 50 ~ "Smaller radius / lower insolation",
      
      # Cluster 5 fits here (High Insolation + Radius ~2.5)
      Med_Insol > 1500 ~ "High insolation",
      
      # Clusters 1 and 7 fit here (The standard population)
      TRUE ~ "Other radius / insolation profiles"
    )
  )

# Convert to factor
df_final$Cluster_Label <- as.factor(df_final$Cluster_Label)


# 3. FINAL VISUALIZATION: The Exoplanet Classification Map

# We plot Period vs Radius (the standard view in Exoplanet science)
# colored by our new Interpreted Labels.

p_final <- ggplot(df_final, aes(x = period_days, y = radius_earth, color = Cluster_Label)) +
  
  # A. The Points
  geom_point(alpha = 0.7, size = 2) +
  
  # B. Reference Lines (Physical Boundaries)
  # Line at 4 Earth Radii (Gas Giant limit)
  geom_hline(yintercept = log10(4+1), linetype = "dashed", color = "gray30") +
  annotate("text", x = 0, y = log10(4+1)+0.05, label = "Descriptive radius threshold (4 Re)",
           size = 3, color = "gray30", hjust = 0) +
  
  # C. Colors and Scales
  scale_color_brewer(palette = "Dark2") + # High contrast palette
  
  labs(
    title = "Descriptive Cluster Profiles of Kepler Objects",
    subtitle = "Heuristic profiles from fitted properties and flags (k=7)",
    x = "Orbital Period [log10(days + 1)]",
    y = "Planetary Radius [log10(Earth radii + 1)]",
    color = "Object Type"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    legend.text = element_text(size = 9),
    plot.title = element_text(face = "bold", size = 14)
  ) +
  guides(color = guide_legend(nrow = 2)) # Arrange legend in 2 rows

print(p_final)


# 4. GENERATE SUMMARY REPORT

final_stats <- df_final %>%
  group_by(Cluster_Label) %>%
  summarise(
    Count = n(),
    Percentage = paste0(round(n() / nrow(df_final) * 100, 1), "%")
  ) %>%
  arrange(desc(Count))

cat("\n--- FINAL PROJECT CONCLUSIONS ---\n")
print(final_stats)


# ==============================================================================
# INTERPRETATION LIMITS
# The chosen k=7 profiles reuse flags and input-derived labels. They do not
# validate noise removal, composition, habitability or method superiority.
