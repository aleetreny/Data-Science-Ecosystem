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


# The original data set had 153 variables and 8054 observations. To reduce the complexity 
# and allow for a more interpretable PCA analysis, we select the more interesting 14 variables
# and we conduct a sample reduction.

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
# koi_fpflag_ss    # Stellar-Stochastic Flag [Unit: None] (Scale: Binary - 0 or 1)

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
    kepid,            # Kepler ID (Unique identifier)
    koi_disposition,  # KOI Disposition (Candidate, Confirmed, False Positive)
    koi_fpflag_nt,    # Not Transit-Like (False positive flag)
    koi_fpflag_ss,    # Stellar-Stochastic (False positive flag)
    koi_period,       # Orbital Period (days)
    koi_duration,     # Transit Duration (hours)
    koi_depth,        # Transit Depth (percentage)
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
    # In exoplanet science, a radius of 4 Earth-radii (4 R⊕) is a critical
    # dividing line. It's the approximate boundary separating smaller "Super-Earths"
    # (which are likely rocky or water-worlds) from "Neptune-sized" gas giants.
    #
    # Planets > 4 R⊕ are almost certain to have a significant gas envelope,
    # making them fundamentally different in composition and formation.
    # Using a statistical median here would be physically meaningless, as it
    # would depend only on the dataset's specific distribution, not on the
    # underlying physics of planet formation.
    
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
      insolation < quantile(insolation, 0.33, na.rm = TRUE) ~ "low",
      insolation < quantile(insolation, 0.66, na.rm = TRUE) ~ "medium",
      TRUE ~ "high"
    ),
    
    # --- 4. Statistical Multi-Class Discretization (Terciles) ---
    #
    # We bin 'magnitude' (brightness) into three equal-count groups.
    # Note: Magnitude is an inverse scale; smaller numbers are brighter.
    # Justification: This captures observational bias. 'bright' stars are
    # easier to observe with higher signal-to-noise than 'dim' stars.
    # Separating them allows the model to potentially account for
    # different data quality levels or selection biases.
    
    magnitude_class = case_when(
      magnitude < quantile(magnitude, 0.33, na.rm = TRUE) ~ "bright", # < 33rd percentile is brightest
      magnitude < quantile(magnitude, 0.66, na.rm = TRUE) ~ "medium",
      TRUE ~ "dim"                                      # > 66th percentile is dimmest
    ),

    # --- 5. Domain-Knowledge Binary Grouping of Disposition ---
    # In the previous PCA analysis (Task 1), we observed a significant overlap 
    # between the 'CONFIRMED' and 'CANDIDATE' classes in the principal component space.
    #
    # 1. Statistical Justification: 
    #    The geometric structure of 'CANDIDATE' objects is nearly indistinguishable 
    #    from 'CONFIRMED' planets. This suggests that, in terms of the observed 
    #    variables (Period, Radius, Temperature, etc.), they belong to the same 
    #    cluster of "planet-like" objects.
    #
    # 2. Physical/Domain Justification:
    #    - A 'CANDIDATE' is a signal that passes all tests for being a planet but 
    #      has not yet been validated by follow-up observations.
    #    - A 'FALSE POSITIVE' typically represents instrumental noise or binary star 
    #      systems (non-planetary phenomena).
    #
    # 3. Visualization Justification:
    #    To improve the interpretability of the MDS map, we simplify the 
    #    classification into a binary problem: "Signal (Planet)" vs. "Noise".
    #    This reduces visual clutter and allows us to clearly assess if the 
    #    Joint Metric (RelMS) successfully separates astrophysical objects 
    #    from artifacts/noise.
    #
    # Therefore, we create the variable 'binary_disposition':
    # - Group: 'CONFIRMED' + 'CANDIDATE' -> "Planet"
    # - Group: 'FALSE POSITIVE'          -> "False Positive"
      
    binary_disposition = case_when(
      disposition == "FALSE POSITIVE" ~ "False Positive",
      TRUE ~ "Planet"
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

# "The heatmap reveals strong correlations (e.g., r > 0.7) between several variables.
# Therefore, using simple Euclidean distance would inflate the importance of 
# these redundant features. This justifies the use of Robust Mahalanobis distance, 
# which accounts for this covariance structure."

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


# 1. OBSERVED DISPARITY:
#    We observe a massive scale difference between the distance matrices:
#    - D1 (Quantitative, Robust Mahalanobis): Mean ~ 857, Max ~ 109,578.
#      This distance is unbounded and depends on the covariance structure.
#    - D2 (Binary) and D3 (Categorical): Mean < 1, Max = 1.
#      These are strictly bounded between [0, 1] as they are derived from
#      similarity coefficients.
#
# 2. THE PROBLEM (Why we cannot just add them):
#    If we constructed a joint metric now by simply summing these matrices
#    (e.g., D_total = D1 + D2 + D3), the Quantitative structure (D1) would
#    completely dominate the result (contributing >99.9% of the value).
#    The information contained in the binary and categorical variables would
#    be mathematically invisible (noise).
#
# 3. THE SOLUTION (Justification for RelMS):
#    These results empirically justify the mandatory next step:
#    "Check for commensurability... by imposing equal geometric variability"
#
#    We must rescale each matrix D_k by its geometric variability (V_k)
#    so that all three sources of information contribute equally to the
#    final Mixed-Data Map.


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
  geom_smooth(method = "lm", color = "red", linetype = "dashed", se = FALSE, size = 0.8) +
  
  # Split into panels
  facet_wrap(~ Metric, scales = "free_y") +
  labs(
    title = "Why Robust Mahalanobis? A Geometric Comparison",
    subtitle = "Left: L1 is just a scaled L2. Right: Mahalanobis fundamentally changes the geometry.",
    x = "Euclidean Distance",
    y = "Alternative Distance"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold", size = 12),
    plot.title = element_text(face = "bold")
  )

print(comp_plot)

# 1. THE LINEARITY OF STANDARD METRICS (Left Panel):
#    The plot comparing Euclidean vs. Manhattan (L1) distances reveals a 
#    linear relationship (points cluster tightly around a line). This indicates 
#    that while the absolute scale differs, the relative ordering of distances 
#    remains largely consistent. Both metrics fundamentally ignore the 
#    correlation structure of the data, treating dimensions as orthogonal.
#
# 2. THE GEOMETRIC SHIFT OF MAHALANOBIS (Right Panel):
#    The comparison between Robust Mahalanobis and Euclidean distances shows a 
#    stark, non-linear deviation from the identity line. 
#    - The "fan" or "cloud" shape indicates that many pairs of points that are 
#      distant in Euclidean space are actually closer when covariance is 
#      accounted for (and vice-versa).
#    - This structural change proves that the strong correlations observed in 
#      the heatmap (e.g., Star Radius vs. Mass) were biasing the Euclidean 
#      metric.
#
# 3. CONCLUSION:
#    The robust Mahalanobis distance successfully "corrects" the geometry of 
#    the quantitative space by normalizing for covariance. This correction is 
#    essential for RelMS to ensure that physical redundancy does not overpower 
#    the information from binary and categorical variables.


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
S_Jac <- ifelse(denom_jac == 0, 0, a / denom_jac) 
D2_Jac <- 1 - S_Jac

# --- C. Dice (Sneath-Sokal) ---
# Similarity: 2a / (2a + b + c)
# Distance^2: 1 - S
denom_dice <- (2 * a + b_plus_c)
S_Dice <- ifelse(denom_dice == 0, 0, (2 * a) / denom_dice)
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
  geom_line(size = 1, alpha = 0.8) +
  labs(
    title = "Comparison of Binary Distances (Ordered Profile)",
    subtitle = "Jaccard/Dice (Dashed) are consistently higher than Sokal (Solid Red).",
    x = "Pairs Ordered by Sokal-Michener Distance",
    y = "Squared Distance Value"
  ) +
  scale_color_manual(values = c("Sokal_Michener" = "#E41A1C", "Jaccard" = "#377EB8", "Dice" = "#4DAF4A")) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(line_plot)

# 1. VISUAL STRUCTURE (Heatmaps Comparison):
#    The three heatmaps demonstrate a fundamental difference in how similarity 
#    is perceived. 
#    - The Sokal-Michener matrix (Left) appears significantly "lighter" (lower 
#      distances), indicating that it finds high similarity between many pairs.
#    - The Jaccard matrix (Center) is "darker" (higher distances).
#    - REASON: This occurs because the Kepler dataset is sparse; most objects 
#      lack flags (0). Sokal-Michener counts these shared zeros (0-0) as a 
#      match, artificially inflating similarity between unrelated objects.
#
# 2. DIVERGENCE ANALYSIS:
#    The line plot provides the definitive proof for metric selection. By ordering 
#    pairs based on the Sokal-Michener distance (Solid Red Line), we observe:
#    
#    - The "Ladder" vs. The "Ceiling": While the Red line steps up gradually, 
#      the Jaccard (Blue Dashed) and Dice (Green Dashed) lines often jump 
#      immediately to 1.0 (Maximum Distance).
#    - The "False Similarity" Gap: The wide gaps between the Red line and the 
#      others represent pairs of objects that share NO active traits, but share 
#      many zeros. Sokal-Michener misleadingly classifies them as "close" 
#      (distance < 0.5), whereas Jaccard correctly identifies them as 
#      totally distinct (distance = 1.0).
#
# 3. CONCLUSION:
#    In the context of Exoplanet detection, sharing the *absence* of a flag 
#    (e.g., "Not a False Positive") is the default state and carries little 
#    information. We are interested in clustering objects based on specific, 
#    active traits they share. Therefore, Jaccard is the methodologically 
#    correct choice for the RelMS construction ($D_2$), as it filters out the 
#    noise of shared zeros.



# Categorical: Metric comparison

# Objective: Compare Hamming (SC1) vs Gower's Weighted (SC4) for categorical data.


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
  geom_line(size = 1, alpha = 0.8) +
  labs(
    title = "Comparison of Categorical Metrics (SC1 vs SC4)",
    subtitle = "SC4 (Blue) is always higher/stricter than SC1 (Red) for mismatches.",
    x = "Pairs Ordered by Hamming Distance (SC1)",
    y = "Squared Distance Value"
  ) +
  scale_color_manual(values = c("SC1" = "#E41A1C", "SC4" = "#377EB8")) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(line_plot_cat)

# 1. DISCRETE STRUCTURE (The "Ladder"):
#    The Ordered Profile plot reveals a perfect stepwise structure. This is 
#    expected because we have p=2 categorical variables, limiting the possible 
#    Hamming distances (SC1) to exactly three levels: 0.0 (perfect match), 
#    0.5 (one mismatch), and 1.0 (complete disagreement).
#
# 2. CONFIRMATION OF PENALTY (The 0.5 vs 0.66 Gap):
#    The behavior of the Weighted Gower metric (SC4, Blue Dashed Line) confirms 
#    its theoretical properties. In the intermediate region where pairs share 
#    exactly one attribute (SC1 = 0.5), the SC4 distance jumps to approx 0.66.
#    - Math: 1 - (1 / (1 + 2*1)) = 2/3 ≈ 0.66.
#    - This visually proves that SC4 penalizes partial disagreements more 
#      heavily than the standard linear approach.
#
# 3. CONCLUSION:
#    While SC4 offers a stricter definition of similarity, the standard Hamming 
#    distance (SC1) provides a linear and intuitive representation of 
#    disagreement (linear steps of 0.5). For the construction of the RelMS 
#    Joint Metric, we select SC1 (Hamming) to maintain a balanced contribution 
#    from the categorical variables without artificially inflating the variance 
#    of partial matches.



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

# The results reveal a massive scale disparity: V1 (Quantitative) is orders of 
# magnitude larger (~429) than V2 and V3 (< 1), due to the unbounded nature of 
# Mahalanobis distance. This confirms that the raw matrices are not commensurate; 
# combining them directly would allow quantitative variables to dominate the 
# analysis (>99.9% influence). Therefore, rescaling each matrix by its Vk is 
# mandatory to ensure equal weight in the final Joint Metric, as required by RelMS.

# 6.2 Rescaling to Equal Geometric Variability
# Rescale D^2 by dividing by Vk. 
# This imposes equal weight to all three sources of information.

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
  
  # Numerical stability: treat tiny negative eigenvalues as zero
  # (These can appear due to floating point errors in distance matrices)
  vals <- decomp$values
  vals[vals < 0] <- 0 
  
  # Reconstruct using sqrt of eigenvalues
  # Gk^1/2 computed from singular value decomposition (equivalent for symmetric G)
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

# The "Correction" part (discards redundancy)
# We sum all cross-products where k != l
# Pairs: (1,2), (2,1), (1,3), (3,1), (2,3), (3,2)
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
is_euclidean <- min_lambda > -1e-5

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

#    The summary shows very low explained variance percentages (Dim 1: 0.48%, 
#    Cumulative 2D: 0.87%). This is an expected side effect of applying 
#    Theorem 2 (Constant Shift Correction).
#
#    To force the non-Euclidean distance matrix into a Euclidean space, we added 
#    a large constant (c) to all off-diagonal distances. Mathematically, this 
#    adds variance to ALL dimensions (shifting all eigenvalues up), which 
#    drastically increases the Total Variance (the denominator).
#
#    While the absolute percentages are "diluted," the relative structure is 
#    preserved. Dimension 1 (Eigenvalue ~1044) and Dimension 2 (Eigenvalue ~821) 
#    remain the two most dominant axes of variation.
#
#    The low values do not mean the map is useless; they simply reflect the 
#    high dimensionality introduced to satisfy the Euclidean property. The 
#    2D plot still represents the "best possible" flat projection of this 
#    complex, corrected space.

# 7.5. Visualization: Scree Plot

# Visual check to see how many dimensions we really need.

scree_data <- data.frame(
  Dimension = 1:10, 
  Variance = explained_var[1:10]
)

scree_plot <- ggplot(scree_data, aes(x = Dimension, y = Variance)) +
  geom_line(color = "#2c3e50", size = 1) +
  geom_point(size = 3, color = "#e74c3c") +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title = "MDS Scree Plot (RelMS + Correction)",
    subtitle = "Percentage of Variability Explained per Dimension",
    y = "% Variance Explained"
  ) +
  theme_minimal()

print(scree_plot)

# 7.6. Visualization and Statistical Justification: The MDS Map (Dim 1 vs Dim 2)

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
    
    # B. Confidence Ellipses (Shape of the group)
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

# 3. STATISTICAL VALIDATION FUNCTION
# ------------------------------------------------------------------------------
run_stats <- function(var_name) {
  manova_res <- manova(cbind(Dim1, Dim2) ~ mds_master[[var_name]], data = mds_master)
  manova_p <- summary(manova_res)$stats[1, "Pr(>F)"]
  
  kruskal_res <- kruskal.test(mds_master$Dim1 ~ mds_master[[var_name]])
  kruskal_p <- kruskal_res$p.value
  
  return(data.frame(
    Variable = var_name,
    MANOVA_p = format.pval(manova_p, eps = 1e-10),
    Kruskal_Dim1_p = format.pval(kruskal_p, eps = 1e-10),
    Signif = ifelse(manova_p < 0.05, "***", "ns")
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
cat("\n--- STATISTICAL VALIDATION ---\n")
print(stats_table)

# INTERPRETATION OF RESULTS:
#
# 1. UNIVERSAL SIGNIFICANCE (p < 1e-10):
#    The statistical results are unequivocal. For every single variable tested—
#    whether physical ('hot_star', 'large_planet') or instrumental 
#    ('flag_notransit', 'binary_disposition')—the MANOVA and Kruskal-Wallis 
#    tests yield p-values effectively equal to zero.
#
# 2. RESOLVING THE VISUAL AMBIGUITY:
#    Although the visual inspection showed overlapping "clouds" (due to the 
#    projection of complex data onto 2D), the statistics prove that the 
#    *centroids* and *distributions* of these groups are mathematically distinct.
#    The RelMS metric has successfully constructed a geometry where "Planets" 
#    and "False Positives" reside in statistically different regions of space.
#
# 3. MULTIDIMENSIONAL SENSITIVITY:
#    The fact that physical variables (like 'magnitude_class' or 'hot_star') are 
#    also highly significant confirms that the map is not just separating 
#    Signal from Noise. It is also organizing the data based on astrophysical 
#    properties. The map captures the full complexity of the Kepler Object of 
#    Interest (KOI) definitions.
#
# 4. CONCLUSION:
#    The RelMS methodology has successfully integrated heterogeneous data sources. 
#    It generates a metric space where structural differences between all key 
#    subgroups are statistically significant, validating the use of this map 
#    for subsequent unsupervised clustering.

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
    subtitle = "Which original variables drive the MDS dimensions?",
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


# Based on the Spearman correlation table:
#
# 1. DIMENSION 1 (MDS_Dim1): The "Stellar Evolution & Scale" Axis
#    - Negative Drivers (Left): Strongly driven by 'radius_sun' (-0.48), 
#      'insolation' (-0.44), and 'mass_sun' (-0.43). This direction represents 
#      large, massive, and energetic stars.
#    - Positive Drivers (Right): Driven by 'logg' (+0.46) and 'magnitude' (+0.45).
#      High 'logg' indicates high surface gravity (compact stars), and high 
#      magnitude means dimmer stars.
#    - MEANING: This axis captures the stellar lifecycle and scale. It moves from 
#      massive Giants (Negative) to compact Dwarfs (Positive).
#
# 2. DIMENSION 2 (MDS_Dim2): The "Thermal Environment" Axis
#    - Negative Drivers (Down): Dominated by 'hot_star' (-0.51) and 'teff_K' (-0.51).
#      This is the direction of extreme heat.
#    - Positive Drivers (Up): Associated with 'magnitude' (+0.33) and longer 
#      'period_days' (+0.29). Cooler, dimmer environments allow for longer 
#      stable orbits.
#    - MEANING: This axis separates the "Hot/High-Energy" environments from the 
#      "Cool/Stable" ones.
#
# 3. CRITICAL OBSERVATION ON FLAGS:
#    Notice that the instrumental flags (e.g., 'flag_stellareclipse') appear much 
#    lower in the ranking (correlations < 0.3) compared to physical variables.
#    - CONCLUSION: While the binary flags successfully create *clusters* (separating 
#      Planets from Noise in distinct regions), the *axes* themselves are spanned 
#      primarily by the physical variance of the stars. The map geometry is 
#      physically coherent, embedding the "Planet vs. Noise" classification 
#      within a broader astrophysical context.

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
                       breaks = quantile(plot_data$Value, probs = seq(0, 1, 0.1), na.rm = TRUE),
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
              size = 2, arrow = arrow(length = unit(0.3, "cm"), type = "closed")) +
    
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


# 1. DIMENSION 1: THE "COMPACTNESS" AXIS (Left vs. Right)
#    - Surface Gravity (Top-Right Plot): This is the cleanest trajectory. The line 
#      moves linearly from Left ("Low" gravity) to Right ("High" gravity).
#    - Radius (Bottom-Left Plot): Mirrors the gravity plot. It moves from 
#      Right ("Low" radius) to Left ("High" radius).
#    - MEANING: Dimension 1 is physically defined by the size/density of the object. 
#      The Left side of the map is populated by large, fluffy Giants, while the 
#      Right side is populated by compact, dense Dwarfs.
#
# 2. DIMENSION 2: THE "ENERGY" AXIS (Top vs. Bottom)
#    - Temperature (Top-Left Plot): The trajectory dives downwards. "Low" 
#      temperature stars are at the top, and "High" temperature stars are deep 
#      at the bottom.
#    - Magnitude (Bottom-Right Plot): Moves diagonally upwards. "Low" magnitude 
#      (Bright stars) are lower down, while "High" magnitude (Dim stars) are 
#      at the top.
#    - MEANING: Dimension 2 represents the energy output. The bottom of the map 
#      contains the high-energy, hot, bright stars. The top contains the cooler, 
#      dimmer stars.
#
# 3. NON-LINEARITY:
#    Notice that the "Radius" snake is not perfectly straight; it curves. This 
#    suggests that the relationship between planetary size and the star's 
#    properties is not strictly linear in this projection, capturing the complex 
#    interplay between a planet and its host star's physics.
#
# 4. OVERALL MAP NAVIGATION:
#    - Top-Right Corner: Small, Dim, Cool stars (Red Dwarfs).
#    - Bottom-Left Corner: Large, Hot, Bright stars (Giants).
# 

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
grid.arrange(p1, p2, p3, p4, ncol = 2, top = "Profile Identification: Physical Drivers on MDS Map")

# 1. VISUALIZING THE GRADIENTS:
#    These scatterplots map the continuous variables directly onto the MDS 
#    coordinates, revealing the "texture" of the Kepler Universe.
#
# 2. TEMPERATURE (Top-Left):
#    - Observation: We see a clear vertical gradient. The brightest/yellowest 
#      points (High Temp) are concentrated at the bottom, while darker purple 
#      points (Low Temp) are at the top. 
#    - Confirmation: This visually confirms Dim 2 as the "Thermal Axis".
#
# 3. SURFACE GRAVITY (Top-Right):
#    - Observation: A strong diagonal gradient. High gravity stars (yellow) 
#      cluster to the right, while low gravity giants (dark) are on the left.
#    - Confirmation: This aligns with the "Stellar Evolution" interpretation 
#      of Dim 1.
#
# 4. PLANET RADIUS (Bottom-Left):
#    - Observation: Larger planets (yellow/green) tend to appear on the left 
#      side of the map, associated with the larger/low-gravity stars.
#    - Insight: This shows that the largest detected planets in this sample 
#      are often found around giant stars (or are artifacts associated with them),
#      while Earth-sized planets are distributed more broadly.
# 

# STEP 8: RelMS vs. Generalized Gower -----



# Objective: Prove that RelMS adds value over standard Gower by handling
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
  Method = "RelMS (Redundancy Removed)"
)

# Gower Data
df_gower <- data.frame(
  Dim1 = Y_gower[, 1],
  Dim2 = Y_gower[, 2],
  Type = labels_vec,
  Method = "Generalized Gower (Simple Sum)"
)

# Combine
df_compare <- rbind(df_relms, df_gower)

# 3. Visualization: Side-by-Side Maps
# -----------------------------------
comp_map <- ggplot(df_compare, aes(x = Dim1, y = Dim2, color = Type)) +
  geom_point(alpha = 0.6, size = 1.5) +
  # Add density to see the structure change
  geom_density_2d(alpha = 0.4, size = 0.2) +
  
  scale_color_brewer(palette = "Set1") +
  facet_wrap(~ Method, scales = "free") + # Free scales because units differ
  
  labs(
    title = "Methodological Comparison: Gower vs. RelMS",
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


# 1. STRUCTURAL CLARITY (The "De-noising" Effect):
#    Comparing the two maps reveals a striking difference in geometric structure.
#    - Generalized Gower (Left): The classes are relatively compressed and 
#      intermingled. The "False Positive" points (Red) overlap significantly 
#      with the "Planet" core (Blue) near the origin.
#    - RelMS (Right): The map exhibits a much cleaner separation. The "False 
#      Positive" group is projected distinctively outward (top-left trajectory), 
#      while the "Planet" group forms a tighter, more cohesive cluster.
#
# 2. REDUNDANCY CONFIRMATION:
#    This visual shift confirms that significant inter-group redundancy exists 
#    in the Kepler data (e.g., physical properties are correlated with binary 
#    flags). Gower's simple summation "double-counts" this information, blurring 
#    the distinction between signal and noise.
#
# 3. CONCLUSION:
#    RelMS successfully removes this redundancy via its cross-product correction 
#    term. The resulting map offers a superior representation of the latent 
#    structure, maximizing the geometric distinction between astrophysical 
#    objects and instrumental artifacts. This justifies the use of RelMS coordinates 
#    as the optimal input for the subsequent Clustering analysis.



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
  Planet = which(grp_sub == "Planet"),
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
                       title = "Classical Gower (Messy)",
                       minimum = thresh_gow,
                       cut = thresh_gow + 0.1), qgraph_args))

# --- Plot B: Robust RelMS ---
do.call(qgraph, c(list(input = S_relms, 
                       title = "Robust RelMS (Structured)",
                       minimum = thresh_rel,
                       cut = thresh_rel + 0.1), qgraph_args))

par(mfrow = c(1, 1))


# 1. TOPOLOGICAL COHESION (RelMS - Right):
#    The Robust RelMS network reveals a strong "community structure." 
#    - The Blue nodes (Planets) form tight, interconnected clusters (cliques), 
#      indicating high mutual similarity.
#    - The Red nodes (False Positives) are mostly peripheral or form their own 
#      distinct sub-groups.
#    - Crucially, there are very few "bridge edges" connecting Red and Blue 
#      nodes, confirming that the metric successfully discriminates signal from noise.
#
# 2. TOPOLOGICAL CONFUSION (Gower - Left):
#    The Classical Gower network displays a higher degree of entropy.
#    - We observe numerous strong edges connecting Blue nodes directly to 
#      Red nodes.
#    - This suggests that Gower's metric calculates a "false proximity" between 
#      planets and artifacts, driven by redundant variables that overlap between 
#      the two classes.
#
# 3. CONCLUSION:
#    The network visualization confirms that RelMS provides a superior input 
#    for clustering algorithms. By breaking the spurious links between distinct 
#    classes, RelMS facilitates the detection of natural boundaries in the data.



# STEP 9.5 : Configuration Stability (Jackknife with Procrustes) ------


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

# 2. Jackknife Loop
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
  coord_fixed() + # Keeps circles round
  labs(
    title = "Configuration Stability (Jackknife)",
    subtitle = "Size of circle = Positional Uncertainty of that object.",
    x = "Dim 1", y = "Dim 2",
    color = "Object"
  ) +
  coord_cartesian(xlim = c(-7, 2.5), ylim = c(-2.5, 5)) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p_conf_stability)


#    - The "Planet" cluster (Blue) exhibits very small uncertainty circles, 
#      indicating a highly stable geometric structure. These objects are deeply 
#      anchored by their physical similarities.
#    - The "False Positive" group (Red) shows larger circles, revealing higher 
#      sensitivity to sampling. This confirms that "noise" is inherently more 
#      heterogeneous and less structured than the planetary signal.
#



# 
# STEP 10: EIGENVALUE STABILITY ANALYSIS (Bootstrap) ----- 
# 
# Objective: Check if Dim 1 is consistently dominant over Dim 2.
# Interpretation: Points below the diagonal (y=x) mean Dim 1 > Dim 2 always.
# A distinct gap from the diagonal indicates stable dimensionality.

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
  
  p <- ggplot(data, aes_string(x = x_col, y = y_col)) +
    # Diagonal y=x
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray40") +
    
    # Bootstrap Cloud
    geom_point(alpha = 0.4, color = "#377EB8", size = 1.5) +
    stat_ellipse(level = 0.95, color = "#E41A1C", size = 0.8) +
    
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
             top = "Eigenvalue Stability: Bootstrap Cloud & Centroid (●)")

# 1. VISUAL SEPARATION (The Diagonal Test):
#    In all three panels, the bootstrap clouds (blue points) and their 
#    confidence ellipses (red lines) are situated strictly below the dashed 
#    diagonal line ($y=x$).
#    - Meaning: This visually confirms that the variance explained by the 
#      lower-order dimension is statistically greater than the higher-order 
#      dimension in every resampled scenario.
#
# 2. DIMENSIONAL HIERARCHY:
#    The black centroid dots (●), representing the mean stability of the system, 
#    confirm a robust hierarchy:
#    - Dim 1 vs Dim 2: Distinctly separated. Dim 1 is consistently the dominant axis.
#    - Dim 2 vs Dim 3: Also separated below the diagonal. Dim 2 captures unique 
#      structural information that is distinct from Dim 3.
#
# 3. CONCLUSION:
#    There is no evidence of "eigenvalue crossing" or axis mixing. The 
#    dimensionality of the RelMS map is stable, confirming that the 2D projection 
#    captures the primary structure of the data reliably ($D_1 > D_2 > D_3$).


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
    subtitle = "From naive physics (Left) to robust physics (Center) to full data integration (Right)",
    x = "Dim 1", y = "Dim 2",
    color = "Object"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold", size = 12),
    legend.position = "bottom"
  )

print(p_evolution)

# 1. PANEL 1: NAIVE EUCLIDEAN (Left)
#    - Visual: The map appears as a diffuse, amorphous cloud.
#    - Failure: "Planets" (Blue) and "False Positives" (Red) are heavily mixed 
#      throughout the central region. A simple Euclidean distance fails to 
#      distinguish signal from noise because it is dominated by the variables 
#      with the largest variance (scale effect) and ignores correlations.
#
# 2. PANEL 2: ROBUST MAHALANOBIS (Center)
#    - Visual: A striking geometric transformation occurs. The cloud collapses 
#      into a distinct "V-shape" or fan structure.
#    - Partial Success: This shape represents the underlying stellar physics 
#      (the "Main Sequence" and "Giant Branch" of the Hertzsprung-Russell 
#      diagram). By accounting for covariance, Mahalanobis reveals the physical 
#      reality.
#    - Limitation: However, look at the colors. The Red and Blue points are 
#      still significantly overlapping, especially near the vertex of the "V". 
#      Physics alone cannot fully separate instrumental artifacts from real planets.
#
# 3. PANEL 3: FINAL RelMS (Right)
#    - Visual: The V-shape is preserved but the internal geometry changes.
#    - Evidence-based note: in 2D, RelMS does not necessarily maximize a direct
#      Planet vs False Positive split. A 2D projection can under-represent
#      mixed-type structure that becomes clear in higher dimensions.
#    - Role of RelMS: integrate heterogeneous sources (physics + flags + categorical)
#      into a single geometry designed for downstream structure discovery.
#      In this project, that payoff is validated in the clustering phase using
#      Dim1–Dim5 (k=7), where multiple sub-populations (including noise types)
#      become separable.

# 4. CONCLUSION:
#    - Mahalanobis best preserves the physical distance structure (stellar physics).
#    - RelMS provides a mixed-type geometry whose value is confirmed by the
#      multi-cluster solution and profiling, rather than by a single 2D
#      Planet-vs-FP separation.


# ==============================================================================
# PHASE II: CLUSTERING ANALYSIS
# ==============================================================================


# STEP 12: ASSESSMENT OF CLUSTERING TENDENCY (VAT & HOPKINS) -----


# 1. Prepare Input Data
# ---------------------
# We use the first 5 dimensions of the RelMS MDS coordinates.
# Why? Because they contain the structural signal we found in the previous phase.
clus_data <- Y_coords[, 1:5]

# Ensure it's a dataframe
clus_data <- as.data.frame(clus_data)
colnames(clus_data) <- paste0("Dim", 1:5)

# 2. Hopkins Statistic (The Numerical Test)
# -----------------------------------------
# H values > 0.75 indicate a strong clustering tendency (90% confidence).
set.seed(123)
hopkins_res <- get_clust_tendency(clus_data, n = nrow(clus_data)-1, graph = FALSE)

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
  labs(title = "VAT (Visual Assessment of Tendency)")

print(p_vat)

# 1. NUMERICAL EVIDENCE (Hopkins Statistic):
#    - Result: H = 0.9768.
#    - Thresholds: H = 0.5 indicates random noise. H > 0.75 indicates valid clusters.
#    - Conclusion: The obtained value is extremely close to 1. This provides 
#      statistical certainty that the dataset is NOT uniformly distributed. 
#      There is a very strong grouping structure embedded in the RelMS coordinates.
#
# 2. VISUAL EVIDENCE (VAT Plot):
#    - The Visual Assessment of Tendency (VAT) displays distinct, dark blocks 
#      along the diagonal (red/orange squares). 
#    - If the data were random, the matrix would look like a uniform grey mist.
#    - The presence of these sharp blocks visually confirms that the objects 
#      naturally separate into distinct communities.
#
# 3. VERDICT:
#    Both the statistical and visual tests confirm that the data is suitable 
#    for partitioning. We proceed to Hierarchical Clustering to determine the 
#    number of groups.



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
cat(">> BEST METHOD:", toupper(best_method), "\n")

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


# 1. LINKAGE METHOD SELECTION (Agglomerative Coefficients):
#    - We compared four linkage methods: Average, Single, Complete, and Ward.
#    - Result: Ward's method yielded the highest Agglomerative Coefficient 
#      (AC ~ 0.9967).
#    - Meaning: An AC close to 1 indicates that the clustering structure is 
#      very strong and well-defined. Ward's method is particularly effective 
#      here because it minimizes intra-cluster variance, creating compact, 
#      spherical groups that align well with the "clouds" we observed in the 
#      MDS map.
#
# 2. DENDROGRAM ANALYSIS (Visual Inspection):
#    - The Circular Dendrogram reveals the hierarchical relationship between 
#      the 1000 observations.
#    - Key Observation: Starting from the center (root), the tree immediately 
#      splits into TWO massive, distinct branches (clades).
#    - The height of this first split is very large compared to subsequent 
#      splits, which is a strong visual indicator that the natural number of 
#      groups in this dataset is k=2.
#
# 3. PRELIMINARY HYPOTHESIS:
#    - The structure suggests a fundamental binary division in the Kepler data. 
#    - Based on our previous MDS analysis, these two branches likely correspond 
#      to the "Planet Candidates" (Signal) and the "False Positives" (Noise).

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

# 1. COPHENETIC CORRELATION RESULTS:
#    - Average Linkage: 0.8887 (Highest fidelity to original distances).
#    - Ward's Method: 0.4948 (Lower fidelity).
#
# 2. VISUAL INSPECTION VS. MATH:
#    - Although Average Linkage has the highest cophenetic correlation, its 
#      dendrogram shows signs of "chaining" (inconsistent branching heights).
#    - Ward's Method, despite a lower correlation, produces the most visually 
#      distinct and compact clusters. This is expected behavior: Ward's algorithm 
#      optimizes for *variance reduction* (creating spherical groups) rather 
#      than preserving pairwise distances.
#
# 3. DECISION:
#    - We prioritize *structural separation* over distance fidelity for this 
#      clustering task. Therefore, we select Ward's Method as it clearly 
#      delineates the major sub-populations (Signal vs. Noise) required for 
#      our analysis.
# 


# STEP 15: DETERMINING OPTIMAL CLUSTERS (THE "k" DECISION) ------

# Goal: Use statistics (Elbow & Silhouette) to statistically confirm k.

# We test from k=1 to k=8 using the PAM algorithm (Partitioning Around Medoids)
# PAM is the robust version of K-Means we will use in the next step.

# A. Elbow Method (Total Within Sum of Square)
# --------------------------------------------
# Look for the "knee" where the curve flattens.
p_elbow <- fviz_nbclust(clus_data, pam, method = "wss", k.max = 8) +
  geom_vline(xintercept = 7, linetype = 2, color = "#E41A1C") +
  labs(title = "3a. Elbow Method (WSS)", 
       subtitle = "Optimal k is at the 'knee' bend")

# B. Silhouette Method (Average Width)
# ------------------------------------
# Look for the highest bar.
p_sil_k <- fviz_nbclust(clus_data, pam, method = "silhouette", k.max = 8) +
  labs(title = "3b. Average Silhouette Method", 
       subtitle = "Highest peak indicates optimal k")

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
       subtitle = "Each bar represents a point. Negative bars = Mismatched points.") +
  theme(axis.text.x = element_text(angle = 0))

print(p_sil_indiv)

# Print Summary Stats
# 
# Let's see the average width per cluster
sil_info <- silhouette(pam_check)
cat("\nAverage Silhouette Width per Cluster:\n")
print(summary(sil_info)$clus.avg.widths)
cat("\nGlobal Average:", round(summary(sil_info)$avg.width, 4), "\n")

# 1. ELBOW METHOD (WSS):
#    - Observation: The Total Within Sum of Squares curve drops sharply initially.
#    - Critical Point: While there is a slight bend at k=2, the curve continues 
#      to drop significantly until k=7, where it forms a distinct "valley" or 
#      plateau.
#    - Meaning: Stopping at k=2 would leave too much variance unexplained. The 
#      geometry suggests that 7 centers are needed to efficiently capture the 
#      complexity of the data.
#
# 2. AVERAGE SILHOUETTE METHOD:
#    - Observation: The plot shows a clear global maximum at k=7.
#    - Significance: This is the strongest evidence. It indicates that the 
#      average object is most similar to its own cluster (cohesion) and distinct 
#      from neighbors (separation) when the data is partitioned into 7 groups.
#
# 3. INDIVIDUAL SILHOUETTE PROFILE (Visual Validation):
#    - Structure: The individual plot shows 7 distinct "flags".
#    - Cohesion: Most clusters (especially 1, 2, 3, and 4) exhibit thick blocks 
#      of positive values, indicating well-defined cores.
#    - Border Points: We observe some negative bars (pointing left), particularly 
#      at the tails of Cluster 4, 6 and 7. These represent "ambiguous" objects 
#      located at the boundaries between groups.
#    - Global Score: The average width (red dashed line ~0.33) confirms that 
#      while the structure is complex and has some overlap (typical in astrophysics), 
#      the 7-cluster partition is statistically valid.
#
# 4. CONCLUSION:
#    - We reject the simple binary hypothesis (Planet vs Noise) in favor of a 
#      granular 7-cluster model. This likely captures distinct sub-populations 
#      (e.g., specific noise types like "Eclipsing Binaries" vs "Background" 
#      or distinct planet classes).

 


# STEP 16: Clusters Plotting (k=2 vs k=7) ------

# Goal: Compare the Binary Hypothesis vs the Granular Reality side-by-side.
# We use statistical "confidence ellipses" (type="norm") for a clean look,
# focused on the core 95% of each cluster, with fixed X-axis limits.

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
                         data = clus_data, 
                         geom = "point", 
                         pointsize = 1.2,
                         
                         ellipse.type = "norm", 
                         ellipse.level = 0.95, # Show 95% core
                         ellipse.alpha = 0.15,
                         
                         palette = cols_k2, 
                         ggtheme = theme_minimal(),
                         main = "A. Binary Hypothesis (k=2)") +
  coord_cartesian(xlim = x_lims, ylim = y_lims) + 
  theme(legend.position = "none", plot.title = element_text(hjust = 0.5))

# Right Panel: k=7 (Granular)
p_k7_ell <- fviz_cluster(pam_k7, 
                         data = clus_data, 
                         geom = "point", 
                         pointsize = 1.2,
                         
                         ellipse.type = "norm",
                         ellipse.level = 0.95,
                         ellipse.alpha = 0.15,
                         
                         palette = cols_k7, 
                         ggtheme = theme_minimal(),
                         main = "B. Granular Reality (k=7)") +
  coord_cartesian(xlim = x_lims, ylim = y_lims) + 
  theme(legend.position = "none", plot.title = element_text(hjust = 0.5))

# Combine side-by-side
grid.arrange(p_k2_ell, p_k7_ell, ncol = 2, 
             top = "STRUCTURAL COMPARISON: Confidence Ellipses (95% Core)")


# 1. VISUAL SETUP:
#    - We compare the k=2 model (left) against the k=7 model (right) using 
#      95% confidence ellipses. These shapes outline the dense "core" of each 
#      cluster, providing a cleaner view than convex hulls.
#    - The X-axis is zoomed to the range [-2.5, 7.5] to focus on the main data structure.
#
# 2. BINARY MODEL (k=2) - Left Panel:
#    - Observation: The blue ellipse is massive and highly elongated. It tries 
#      to encompass a huge, diverse area of the map.
#    - Critique: This "one-size-fits-all" approach is inefficient. The ellipse 
#      includes vast empty regions where no stars exist, indicating poor fit 
#      to the actual data geometry.
#
# 3. GRANULAR MODEL (k=7) - Right Panel:
#    - Observation: The single large blue ellipse is replaced by distinct, 
#      smaller, and tighter ellipses (e.g., Purple, Green, Cyan, Orange).
#    - Advantage: These smaller ellipses hug the data points closely. They 
#      respect the "V-shape" structure of the map, with specific clusters 
#      capturing the tips and the central mixing region accurately.
#
# 4. CONCLUSION:
#    The comparison visually confirms the statistical findings (Elbow/Silhouette). 
#    The k=7 model provides a much more faithful representation of the underlying 
#    sub-populations than the overly simplistic k=2 binary split.
# 



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

cat("\n--- PERFORMANCE TABLE (Adjusted Rand Index) ---\n")
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

# 1) THE DOMINANT VARIABLE AT k=2 (Thermal split)
#
# Observation:
# Look at the variable "hot_star". The k=2 model has an ARI of 0.3522
# (the highest value in the entire table), while k=7 drops to 0.21.
#
# Meaning (refined):
# The k=2 split aligns most strongly with stellar temperature (hot_star),
# more than with the Planet vs False Positive label. This suggests that
# the coarsest partition is driven primarily by a thermal contrast, while
# any Planet/Noise separation is present but secondary.
#
# Note:
# The overall "V-shape" in the MDS map reflects multiple physical gradients
# (e.g., stellar scale/evolution on Dim1 and thermal environment on Dim2),
# not temperature alone.
#
# Conclusion:
# The k=2 partition is dominated by a thermal contrast (hot_star), indicating that
# the coarsest split primarily follows the thermal axis of the RelMS map (Dim 2).
# However, the global "V-shape" is not governed by temperature alone: it emerges
# from multiple physical gradients (stellar scale/evolution on Dim 1 and thermal
# environment on Dim 2). Therefore, k=2 is an oversimplification that compresses
# several astrophysical sub-populations into two groups, masking planetary-level
# structure that becomes clearer in the k=7 solution.

# 2) THE SUCCESS OF k=7 IN PHYSICAL DETAIL
#
# Insolation (insolation_class):
# This is where k=7 clearly outperforms. It goes from a negligible ARI
# in k=2 (0.03) to a solid value in k=7 (0.24). This shows that the
# 7-cluster model respects energy levels (Low/Medium/High), separating
# "scorched" planets from more temperate ones.
#
# Size (large_planet):
# k=7 roughly doubles the performance (0.14 vs 0.06). This confirms that
# the 7 clusters have managed to separate Gas Giants from rocky planets,
# something the binary model was mixing together.
#
# Brightness (magnitude_class):
# Again, k=7 is far superior (0.14 vs 0.01), capturing the observational
# bias (bright vs faint stars).

# 3) ERROR FLAGS
#
# Observation:
# ARI values for the flags (flag_notransit, flag_stellareclipse) are low
# in general, but there is a key pattern.
#
# Comparison:
# The k=2 model shows negative values (worse than random) for the flags.
# The k=7 model shows positive values (especially flag_stellareclipse at 0.07).
#
# Meaning:
# Although no cluster is a "pure" error type, the k=7 model is starting
# to geometrically isolate Eclipsing Binaries, while k=2 completely
# dilutes them into the general noise.

# 4) BINARY DISPOSITION (binary_disposition)
#
# Result:
# Both models show low and similar performance (~0.14).
#
# Why this happens:
# This validates the initial hypothesis that the "False Positive" label
# is a catch-all category. It contains very different phenomena
# (binary stars, instrumental noise, software failures) that are not
# geometrically similar. This is why no clustering algorithm can
# perfectly match that label: physical reality is more complex than
# a simple "Yes/No".




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
  mutate(across(where(is.numeric), round, 2)) # Round for better readability

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


# 4. VISUALIZATION B: THE EXOPLANET MAP (Period vs Radius)
# ------------------------------------------------------------------
# This plot shows what type of planets they are (Giants, Earths, etc.)
# and colors by Cluster to see if they group logically.

p_exomap <- ggplot(df_sample, aes(x = period_days, y = radius_earth, color = Cluster)) +
  # Background points (grey) for context
  geom_point(data = df_sample %>% dplyr::select(-Cluster), 
             aes(x = period_days, y = radius_earth), color = "grey85", size = 0.5) +
  # Cluster points
  geom_point(size = 2, alpha = 0.8) +
  # Approximate reference lines (in Log10)
  geom_hline(yintercept = log10(4 + 1), linetype = "dashed", color = "black") + # Super-Earth/Neptune limit
  annotate("text", x = 0, y = 0.75, label = "Rocky/Super-Earths", hjust = 0, size = 3, fontface="italic") +
  annotate("text", x = 0, y = 0.9, label = "Gas Giants", hjust = 0, size = 3, fontface="italic") +
  
  scale_color_brewer(palette = "Set1") +
  facet_wrap(~ Cluster) +
  labs(title = "Exoplanet Classification Map by Cluster",
       subtitle = "Period vs. Radius Relationship (Separated by Group)",
       x = "Orbital Period [log10(days)]",
       y = "Planetary Radius [log10(Earth Radii)]") +
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
  summarise(across(everything(), mean, na.rm = TRUE)) %>% # Calculate Mean Z-Score per Cluster
  pivot_longer(cols = -Cluster, names_to = "Feature", values_to = "Z_Score") %>%
  mutate(Cluster = as.factor(Cluster))

# 2. Plot
p_snake <- ggplot(df_scaled_profile, aes(x = Feature, y = Z_Score, group = Cluster, color = Cluster)) +
  geom_line(size = 1.2, alpha = 0.8) +
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

# INTERPRETATION FOR LABELING:
# - The Horizon (0 Line): This is the "Average Star/Planet".
# - Peaks & Valleys: Look for the most extreme points.
#   Example: If Cluster 1 peaks high on 'radius_earth' but is low on 'period_days',
#   label it "Short-Period Giants" (Hot Jupiters).
# - Crossing Lines: If two lines cross in an 'X' shape, those clusters are
#   opposites (Inverse Correlation).


# 6. RELATIVE IMPORTANCE HEATMAP (% Deviation)

# 1. Calculate Global Means and Cluster Means
global_means <- df_sample %>%
  dplyr::select(radius_earth, period_days, teff_K, insolation, magnitude) %>%
  summarise(across(everything(), mean, na.rm = TRUE))

cluster_means <- df_sample %>%
  dplyr::select(Cluster, radius_earth, period_days, teff_K, insolation, magnitude) %>%
  group_by(Cluster) %>%
  summarise(across(everything(), mean, na.rm = TRUE))

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
    title = "Relative Importance Heatmap",
    subtitle = "Percentage deviation from the Global Mean. Red = Below Avg, Green = Above Avg.",
    x = "Feature",
    y = "Cluster ID",
    fill = "% Deviation"
  ) +
  theme_minimal() +
  theme(panel.grid = element_blank())

print(p_heatmap)

# INTERPRETATION:
# - Dark Green (+): The DEFINING feature of the cluster.
#   If 'insolation' is +50% and everything else is 0%, the label is "High Energy".
# - Dark Red (-): The ABSENT feature.
#   If 'radius_earth' is -30%, the label is "Small/Rocky".
# - Use this chart to write the final "Description" in your report.

# 7. RADAR CHART (Spider Plot)

# 1. Prepare Data: Normalize to 0-1 range (Min-Max Scaling)
# Radar charts require data to be strictly between 0 and 1 (or defined min/max).
data_radar_raw <- df_sample %>%
  dplyr::select(radius_earth, period_days, teff_K, insolation, magnitude)

# Normalize function
min_max_norm <- function(x) { (x - min(x)) / (max(x) - min(x)) }
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

# Allow drawing outside plot region so the legend can sit "outside"
par(xpd = NA)

legend(
  x = "topright",
  inset = c(-0.25, -0.05),  # (right, up) -> negative values push it outside
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

# INTERPRETATION:
# - Spikes: A sharp spike outward means "Dominance" in that variable.
# - Area: A large polygon area means "High Values Everywhere" (e.g., Big, Hot, Bright).
# - Tiny Polygon: Means "Low Values Everywhere" (e.g., Small, Cool, Dim).
# - Shape similarity: Clusters with similar polygon shapes are related, even if one is smaller (same ratios, different scale).



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
  mutate(across(where(is.numeric), round, 2))

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
      Pct_NoTrans > 0.40 | Med_Radius > 25 ~ "Instrumental Noise / Artifacts",
      
      # Cluster 4 fits here (High Eclipse flag + Radius > 20)
      Pct_Eclipse > 0.40 | Med_Radius > 20 ~ "Eclipsing Binaries (False Positives)",
      
      # Cluster 3 fits here (Moderate Eclipse flag + Short Period)
      Pct_Eclipse > 0.30 & Med_Period < 3 ~ "Contact Binaries / Hot Jupiter FPs",

      # --- 2. IDENTIFYING PLANETS (Clean Candidates) ---
      
      # Cluster 2 fits here (Small Radius + Low Insolation relative to others)
      # We call it "Warm" instead of "Habitable" to be scientifically safe (Insol ~23)
      Med_Radius < 2.5 & Med_Insol < 50 ~ "Warm Super-Earths (Best Candidates)",
      
      # Cluster 5 fits here (High Insolation + Radius ~2.5)
      Med_Insol > 1500 ~ "Scorched Sub-Neptunes (Lava Worlds)",
      
      # Clusters 1 and 7 fit here (The standard population)
      TRUE ~ "Hot Super-Earths & Sub-Neptunes"
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
  annotate("text", x = 0, y = log10(4+1)+0.05, label = "Gas Giant Limit (4 Re)", 
           size = 3, color = "gray30", hjust = 0) +
  
  # C. Colors and Scales
  scale_color_brewer(palette = "Dark2") + # High contrast palette
  
  labs(
    title = "Final Classification of Kepler Objects",
    subtitle = "Identified sub-populations based on RelMS Clustering (k=7)",
    x = "Orbital Period [Log10 Days]",
    y = "Planetary Radius [Log10 Earth Radii]",
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
# FINAL INTERPRETATION AND ASTROPHYSICAL INSIGHTS
# ==============================================================================
# 
# 1. SEGREGATION OF NOISE AND ARTIFACTS:
#    The unsupervised clustering (k=7) successfully disentangled non-planetary 
#    signals from the dataset without relying on the official labels:
#    - Instrumental Artifacts (Cluster 6): Defined by physically impossible 
#      radii (>30 Earth Radii) and a high prevalence of 'Not-Transit-Like' flags.
#    - Eclipsing Binaries (Cluster 4): Characterized by stellar-sized radii 
#      (>20 Earth Radii) and a 68% probability of secondary eclipses.
#    - Contact Binaries/FPs (Cluster 3): Detected via short orbital periods 
#      and moderate eclipse probabilities.
#
# 2. TAXONOMY OF PLANETARY CANDIDATES:
#    Among the clean clusters (low error flags), the model revealed a distinct 
#    astrophysical hierarchy based on thermal and physical properties:
#    - Warm Super-Earths (Cluster 2): This is the most scientifically significant 
#      group. It contains small planets (~1.75 Re) with the lowest insolation 
#      levels (23.6x Earth flux), making them the best candidates for 
#      potential habitability studies in this sample.
#    - Scorched Worlds (Cluster 5): A distinct group of sub-Neptunes receiving 
#      extreme energy (>1500x Earth flux), likely representing stripped 
#      planetary cores.
#    - Hot Super-Earths (Clusters 1 & 7): The dominant population, representing 
#      the typical close-in, rocky planets found by the Kepler mission.
#
# 3. METHODOLOGICAL CONCLUSION:
#    The RelMS metric proved superior to standard methods. By integrating 
#    binary quality flags with continuous physical variables, the algorithm 
#    simultaneously cleaned the data (isolating noise) and classified the 
#    planets (separating Warm vs. Scorched), a nuance that a simple binary 
#    model (k=2) failed to capture.
