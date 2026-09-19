# FULL PCA ANALYSIS WITH MIXED-TYPE VARIABLES -----
# Kepler KOI dataset


library(tidyverse)
library(ggplot2)
library(gridExtra)
library(ggrepel)
library(dplyr)
library(tidyr)
library(ggcorrplot)
library(GGally)
library(ggforce)
library(ggridges)
library(purrr)
library(broom)
library(plotly)
library(htmlwidgets)
library(webshot2)





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


# Use the versioned snapshot so every table, loading and plot is reproducible.
# Refreshing from NASA is intentionally an explicit maintenance operation, not
# an implicit dependency of the analysis.
df_koi <- read_csv("df_koi.csv", show_col_types = FALSE)

# Select and rename the relevant columns
df_selected = df_koi %>%
  select(
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
    koi_kepmag,       # Kepler-band Magnitude (star's brightness)
  ) %>%
  rename(
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
  )



# STEP 2: Create derived variables (binary / multiclass) -----

# These bins are interpretation aids derived from the measured variables.
# They do not add independent information or validate the PCA.

df_selected <- df_selected %>%
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
    
# Brightness groups describe apparent magnitude. They do not adjust the
# analysis for selection effects or measurement uncertainty.
    
    magnitude_class = case_when(
      is.na(magnitude) ~ NA_character_,
      magnitude < quantile(magnitude, 0.33, na.rm = TRUE) ~ "bright", # < 33rd percentile is brightest
      magnitude < quantile(magnitude, 0.66, na.rm = TRUE) ~ "medium",
      TRUE ~ "dim"                                      # > 66th percentile is dimmest
    )
  )



# STEP 3: Select continuous numerical variables and eliminate NAs -----


# We select only the continuous numerical variables for the PCA.
# We exclude:
# - Identifiers (id)
# - Categorical labels (disposition)
# - Binary flags (flag_notransit, flag_stellareclipse)
# - The new binned variables (hot_star, large_planet, etc.)

pca_vars <- c(
  "period_days",
  "duration_hours",
  "depth_ppm",
  "radius_earth",
  "insolation",
  "teff_K",
  "radius_sun",
  "mass_sun",
  "logg",
  "magnitude"
)

# Isolate these variables and remove any NA rows for a clean calculation
# (PCA cannot handle missing values).
pca_rows <- complete.cases(df_selected[, pca_vars])
df_numeric_pca <- df_selected[pca_rows, pca_vars]
stopifnot(all(vapply(df_numeric_pca, function(x) all(is.finite(x)) && sd(x) > 0, logical(1))))


# STEP 4: Calculate the Covariance Matrix (S) of *Unstandardized* Data -----


# We calculate the Covariance matrix (S) from the *raw* numeric data.
# This is the "wrong path" that we are taking *intentionally*
# to demonstrate the problem, as done in the "Birds" example.
S_matrix_raw <- cov(df_numeric_pca)

# --- Print the Full Covariance Matrix (S) ---
# We print the *full* matrix, rounded for slightly better readability.
# It will be hard to read, but it demonstrates the core problem.
print("--- Full Covariance Matrix (S) of Raw Data (Rounded) ---")
print(round(S_matrix_raw, 2))

# **Interpretation:**
# Look at the *diagonal* of this matrix (the variances).
# You will see the *exact same* massive variance numbers
# The off-diagonal elements are the covariances.
#
# In the next step we focus in the S matrix diagonal (variances) ->


# STEP 5: Calculate and Visualize Raw Variances -----


# Calculate the variance for each column
raw_variances <- df_numeric_pca %>%
  summarise(across(everything(), ~ var(.x, na.rm = TRUE)))

# Print the variances to the console.
# You will see massive differences. 'depth_ppm' and 'teff_K' will be
# enormous, while 'score' and 'logg' will be tiny.
print("--- Raw Variances of PCA Variables ---")
print(raw_variances)

# --- Plot the Variances ---

# To plot with ggplot, we must pivot the data to a long format
variances_long <- raw_variances %>%
  pivot_longer(
    cols = everything(),
    names_to = "Variable",
    values_to = "Variance"
  )

# Create the bar plot
# We *must* use a logarithmic Y-axis (scale_y_log10())
# Otherwise, the variables with tiny variances (like 'score')
# would be completely invisible next to 'depth_ppm'.

variance_plot <- ggplot(variances_long, aes(x = reorder(Variable, -Variance), y = Variance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  
  # Use a log scale to visualize the massive differences in magnitude
  scale_y_log10(
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = scales::trans_format("log10", scales::math_format(10^.x))
  ) +
  
  labs(
    title = "Variance Disparity of Raw KOI Variables (Log Scale)",
    subtitle = "This plot demonstrates why standardization changes PCA variable weighting.",
    x = "Variable",
    y = "Variance (on log10 scale)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Display the plot
print(variance_plot)

# The vertical axis is logarithmic. Variances remain nonnegative;
# values between zero and one have negative log10 coordinates.



# STEP 6: Correlation indicators -----


# This script implements the 6 measures (q1-q6) from the
# methodology explained in class to get a [0, 1] score.
#
# A score close to 1 indicates high intercorrelation (good for PCA).
# A score close to 0 indicates low intercorrelation (PCA is less useful).
#

#------ Get the 3 Key Components for the Formulas

# We need 3 things from the Correlation Matrix (R):
# 1. The matrix (R) itself
# 2. Its eigenvalues (lambda_j)
# 3. The diagonal of its inverse (r^jj)

# 1. Calculate the Correlation Matrix (R)
R_matrix <- cor(df_numeric_pca)

# 2. Calculate the eigenvalues (lambda)
# We sort them descending, though it's only critical for min/max
eigenvalues <- sort(eigen(R_matrix)$values, decreasing = TRUE)

# 3. Calculate the diagonal of the inverse of R (r^jj)
# r_jj is the j-th diagonal element of R_inverse
r_jj <- diag(solve(R_matrix))

# 4. Get 'p' (the number of variables)
p <- ncol(R_matrix)

#------ Calculate the 6 Intercorrelation Measures

# --- q1 ---
# (1 - (min(lambda) / max(lambda)))^(p + 2)
# Measures the spread of the eigenvalues.
q1 <- (1 - (min(eigenvalues) / max(eigenvalues)))^(p + 2)

# --- q2 ---
# 1 - (p / sum(1 / lambda))
# Based on the harmonic mean of the eigenvalues.
q2 <- 1 - (p / sum(1 / eigenvalues))

# q3 = 1 - sqrt(det(R)). For a correlation matrix, det(R)=1 means
# zero pairwise correlations; det(R)=0 means linear dependence.
# Neither statement establishes statistical independence.
q3 <- 1 - sqrt(det(R_matrix))

# --- q4 ---
# (max(lambda) / p)^(3/2)
# Based on the size of the first eigenvalue relative to the total.
q4 <- (max(eigenvalues) / p)^(3/2)

# --- q5 ---
# (1 - min(lambda) / p)^5
# Based on the size of the smallest eigenvalue.
q5 <- (1 - min(eigenvalues) / p)^5

# --- q6 ---
# sum( (1 - 1/r^jj) / p )
# Based on the average of the Variance Inflation Factors (VIFs).
# r^jj is the VIF for variable j.
q6 <- sum((1 - 1 / r_jj) / p)

#------ Display the Results 

# Create a named vector or data frame to show the results clearly
intercorr_measures <- data.frame(
  Measure = c("q1", "q2", "q3", "q4", "q5", "q6"),
  Value = c(q1, q2, q3, q4, q5, q6),
  Description = c(
    "Eigenvalue Spread",
    "Harmonic Mean",
    "Determinant (1 - sqrt(|R|))",
    "Max Eigenvalue (PC1)",
    "Min Eigenvalue",
    "Avg. Variance Inflation"
  )
)

print("--- Overall Intercorrelation Measures (q1-q6) ---")
print(intercorr_measures)

#
# These diagnostics use raw-variable correlations. q4 and q5 are not zero at R=I;
# use the spectrum and retained variance rather than interpreting every score identically.

# STEP 7: Create the Heatmap -----


# --- Define the Custom Color Palette ---
# A diverging palette from Purple to Blue.
col_neg <- "#7b3294" 
col_mid <- "white"   
col_pos <- "#005a9c" 

# --- Generate the Plot ---
corr_heatmap_matlab_style <- ggcorrplot(
  R_matrix,
  title = "Correlation Matrix (R) of KOI Variables (Matlab Style)",
  
  # 1. Do NOT reorder variables
  hc.order = FALSE,
  
  # 2. Show the FULL matrix 
  type = "full",
  
  # 3. Show numeric correlation labels
  lab = TRUE,
  lab_size = 2.5,
  
  # 4. Use squares for the heatmap
  method = "square",
  
  # Set the legend limits to be exactly -1 to +1
  legend.title = "Correlation",
  colors = c(col_neg, col_mid, col_pos),
  legend.limit = c(-1, 1)
) +
  
  theme_minimal(base_size = 10) + 
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
    axis.text.y = element_text(size = 9),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 8)
  )

# Display the plot
print(corr_heatmap_matlab_style)


# STEP 8: Multiple correlation scatter plots -----

# The raw data plots are dominated by extreme scales and skewness.
# Variables (like period_days, depth_ppm, insolation) are heavily
# skewed (long right tails), which compresses most data points
# into a small corner of the plot, making them look uncorrelated.

# Apply log10(x + 1) to the eight nonnegative ratio-scale variables,
# for both the scatterplot and PCA. This changes the analysis geometry;
# logg and magnitude are already logarithmic and remain untransformed.

# Apply log10 transformation to correct for positive skewness
df_log <- df_numeric_pca %>%
  mutate(
    period_days = log10(period_days + 1),
    depth_ppm = log10(depth_ppm + 1),
    insolation = log10(insolation + 1),
    radius_earth = log10(radius_earth + 1),
    duration_hours = log10(duration_hours + 1),
    teff_K = log10(teff_K + 1),
    radius_sun = log10(radius_sun + 1),
    mass_sun = log10(mass_sun + 1)
  )


# Create pairs plot (this may take a moment)
pairs_plot_log <- ggpairs(
  df_log,
  diag = list(continuous = wrap("barDiag", fill = "steelblue", bins = 30)),
  lower = list(continuous = wrap("points", size = 0.3, alpha = 0.3)),
  upper = list(continuous = wrap("points", size = 0.3, alpha = 0.3)),
  progress = FALSE
) +
  theme_minimal() +
  theme(axis.text = element_text(size = 5))

print(pairs_plot_log)

# The scatterplot describes relationships after transformation. Correlated
# inputs can be summarized by PCA, but this plot does not establish physical
# causes or make covariance-based PCA invalid. Inspect the retained variance.


# STEP 9: Apply Standardization  -----


# We choose z-score standardization of the transformed variables so each
# input has unit variance. This is a modeling choice that removes units;
# it does not make PCA resistant to outliers or correct measurement error.

# Apply the scaling to the same data used for the correlation diagnostics and
# derived-label descriptions.  The log-transformed table above remains a
# visualisation aid; silently changing the analysis population would make the
# diagnostics and PCA answer different questions.
df_scaled <- as.data.frame(scale(df_log))

# Note that R matrix is equal to the S of the X standardized
# The substraction of the matrix gives the Zero Matriz
S_matrix_tr <- cov(df_scaled)
R_matrix_scaled_input <- cor(df_log)
stopifnot(max(abs(S_matrix_tr - R_matrix_scaled_input)) < 1e-10)

# --- Verification of variances ---
# Let's prove that our standardization worked.
# We calculate the variance of *new* scaled columns.

scaled_variances <- df_scaled %>%
  summarise(across(everything(), ~ var(.x, na.rm = TRUE)))

# This will print a table where every variable now has a variance of 1.
print("--- Variances AFTER Z-Score Standardization ---")
print(scaled_variances)

# The 'df_scaled' dataframe is now the correct and final
# input for the 'prcomp' function.

# Re-calculate R_matrix from standardized data to ensure consistency
R_matrix <- cor(df_scaled)
# Equivalently, run prcomp(df_log, center=TRUE, scale.=TRUE).
# Here centering and scaling are performed explicitly before prcomp.

# STEP 10: Perform the Principal Component Analysis (PCA) -----


# Use the manually standardized data from Step 9
# We turn OFF center and scale, as the data is already centered and scaled.
pca_result <- prcomp(
  df_scaled,
  center = FALSE,
  scale. = FALSE
)

# --- View the PCA Results ---
# The summary() shows the importance of each component.
# - Standard deviation: The square root of the eigenvalue (lambda)
# - Proportion of Variance: How much variance this single component explains
# - Cumulative Proportion: The running total (our main goal)

print("--- PCA Summary ---")
print(summary(pca_result))


# STEP 11: Inspect Component Loadings (The Equations) -----


# 1. Get the full loadings matrix
loadings_matrix <- pca_result$rotation

# Print the loadings for the first few components
# We round them to 3 decimal places for readability.
print(round(loadings_matrix[, 1:4], 3))

# 2. Convert to a tidy data.frame for ggplot
# We'll take the first 4 components
loadings_df <- as.data.frame(loadings_matrix[, 1:4]) %>%
  rownames_to_column(var = "Variable") %>%
  pivot_longer(
    cols = -Variable, 
    names_to = "Component", 
    values_to = "Loading"
  )

# 3. Create the plot
# We use reorder(Variable, Loading) to sort the bars within each plot
loadings_plot <- ggplot(loadings_df, aes(x = reorder(Variable, Loading), y = Loading, fill = Component)) +
  geom_col() + # This is the bar chart
  
  # Flip coordinates so variable names are horizontal and readable
  coord_flip() +
  
  # Create a separate panel for each Component
  facet_wrap(~ Component, scales = "free_y") +
  
  labs(
    title = "PCA Loadings (The 'Equation' Coefficients)",
    subtitle = "Visualizing the contribution of each variable to PC1-PC4",
    x = "Variable",
    y = "Loading Coefficient (Weight)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none", # The fill is redundant with the panel titles
    axis.text.y = element_text(size = 8) # Adjust text size
  )

# Display the plot
print(loadings_plot)

#
# Interpret the coefficients printed above; signs can reverse across SVD implementations.
# Component names are descriptive, not verified physical identities.

# STEP 12: Decide How Many Components to Keep -----

#
# We will use four different methods to determine the optimal
# number of components (k) to retain.
#
# 1. Percentage of Explained Variability
# 2. Kaiser's Criterion
# 3. Jolliffe's Criterion
# 4. Cattell's Scree Graph
#

# --- 12.1: Get the Eigenvalues and Summary Data ---

# We need the eigenvalues (lambda) for the criteria.
# The 'sdev' in pca_result are the standard deviations (sqrt(lambda)).
# We must square them to get the eigenvalues.
eigenvalues <- pca_result$sdev^2
p <- length(eigenvalues) # Number of variables (p=10)

# Get the summary data (proportions)
pca_summary_data <- summary(pca_result)$importance

# --- 12.2: Method 1: Percentage of Explained Variability ---
#
# Rule: Keep enough components to explain 70-90% of the variance.
#
cumulative_variance <- pca_summary_data["Cumulative Proportion", ]

# Find the cutoffs
cutoff_70 <- min(which(cumulative_variance >= 0.70))
cutoff_80 <- min(which(cumulative_variance >= 0.80))
cutoff_90 <- min(which(cumulative_variance >= 0.90))

cat("--- Method 1: Percentage of Variability ---\n")
cat("To explain > 70% variance, keep:", cutoff_70, "components\n")
cat("To explain > 80% variance, keep:", cutoff_80, "components\n")
cat("To explain > 90% variance, keep:", cutoff_90, "components\n")

# --- 12.3: Method 2: Kaiser's Criterion ---
#
# Rule: Keep components whose eigenvalues are > 1.0.
# This works because we used the Correlation Matrix (R), where the
# average eigenvalue is tr(R)/p = p/p = 1.
#
kaiser_cutoff <- sum(eigenvalues > 1.0)

cat("--- Method 2: Kaiser's Criterion ---\n")
cat("Keep components with eigenvalue > 1.0. Keep:", kaiser_cutoff, "components\n")

# Jolliffe's eigenvalue > 0.7 rule is a retention heuristic for standardized
# PCA. There are ten analysis variables; compare this with retained variance.
jolliffe_cutoff <- sum(eigenvalues > 0.7)

cat("--- Method 3: Jolliffe's Criterion ---\n")
cat("Keep components with eigenvalue > 0.7. Keep:", jolliffe_cutoff, "components\n")

# --- 12.5: Method 4: Cattell's Scree Graph (The "Elbow" Plot) ---
#
# Rule: Find the "elbow" or "scree" - the visual break
# between "large" and "small" eigenvalues.
#
# We will create two plots:
# 1. The Scree Plot (Eigenvalues) annotated with Kaiser/Jolliffe cutoffs.
# 2. The Cumulative Variance Plot annotated with the 80% rule.

# Create the tidy data frame for plotting
variance_df <- data.frame(
  Component = 1:p,
  Eigenvalue = eigenvalues,
  Variance = pca_summary_data["Proportion of Variance", ],
  Cumulative = pca_summary_data["Cumulative Proportion", ]
)

# --- Plot 1: Cattell's Scree Plot (Eigenvalues) ---
# This plot shows the eigenvalues on the y-axis.
scree_plot_annotated <- ggplot(variance_df, aes(x = Component, y = Eigenvalue, group = 1)) +
  geom_line(color = "blue", linewidth = 1) +
  geom_point(color = "blue", size = 3) +
  
  # Add Kaiser's cutoff line (lambda = 1)
  geom_hline(yintercept = 1.0, linetype = "dashed", color = "red") +
  annotate("text", x = 1, y = 1.0, label = "Kaiser's Cutoff (lambda = 1.0)", vjust = -0.5, hjust = 0, color = "red") +
  
  # Add Jolliffe's cutoff line (lambda = 0.7)
  geom_hline(yintercept = 0.7, linetype = "dotted", color = "darkgreen") +
  annotate("text", x = 1, y = 0.7, label = "Jolliffe's Cutoff (lambda = 0.7)", vjust = -0.5, hjust = 0, color = "darkgreen") +
  
  labs(
    title = "Scree Plot (Cattell's Criterion)",
    subtitle = "Eigenvalues per Component with Kaiser & Jolliffe Cutoffs",
    x = "Principal Component (1...p)",
    y = "Eigenvalue (lambda)"
  ) +
  scale_x_continuous(breaks = 1:p) + # Ensure integer labels
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

# Display the Scree Plot
print(scree_plot_annotated)


# --- Plot 2: Cumulative Variance Plot (% Variability) ---
cumulative_plot <- ggplot(variance_df, aes(x = Component, y = Variance, group = 1)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.8) +
  geom_line(aes(y = Cumulative), color = "red", linewidth = 1) +
  geom_point(aes(y = Cumulative), color = "red", size = 2) +
  
  # Add the 80% (or your preferred) threshold line
  geom_hline(yintercept = 0.8, linetype = "dashed", color = "black") +
  annotate("text", x = 1, y = 0.8, label = "80% Cutoff", vjust = -0.5, hjust = 0, color = "black") +
  
  labs(
    title = "Cumulative Variance Plot",
    subtitle = "Bars: Individual Variance | Red Line: Cumulative Variance",
    x = "Principal Component",
    y = "Proportion of Variance Explained"
  ) +
  scale_x_continuous(breaks = 1:p) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

# Display the Cumulative Plot
print(cumulative_plot)


# Compare the printed retention criteria; they need not agree. Four components are
# displayed for interpretation, while the 80 percent rule is reported separately.

# STEP 13: Visualize PC Scores (PC1 vs PC2 Scatter Plot) -----

# Color the first two component scores by disposition to describe overlap.
# This is an exploratory plot, not a held-out classification evaluation.

# --- 13.1: Create the Plotting Data Frame ---

# 1. Get the PC scores (the new coordinates) for every observation.
# These are stored in pca_result$x
pca_scores_df <- as.data.frame(pca_result$x)

# 2. Get the labels (e.g., 'disposition') for our data.
#    We MUST ensure we have the exact same rows in the exact
#    same order as the data that went into the PCA.
#
#    The only robust way to do this is to re-create the
#    'na.omit()' step, but this time selecting the
#    labels *before* omitting NAs.

df_labels_clean <- df_selected[pca_rows, ]
stopifnot(nrow(pca_scores_df) == nrow(df_labels_clean))

plot_df <- cbind(
  pca_scores_df,  # The PC1, PC2... coordinates
  df_labels_clean # The corresponding labels
)

# --- 13.2: Create the Scatter Plot ---

# We will use a small point size and transparency (alpha)
# to handle the large number of (overplotted) points.

pc1_v_pc2_plot <- ggplot(plot_df, aes(x = PC1, y = PC2, color = disposition)) +
  
  # Use small, semi-transparent points
  geom_point(alpha = 0.2, size = 0.5) +
  
  # Add 2D density contours to see the "center of mass"
  # for each group, which helps cut through the noise.
  geom_density_2d(alpha = 0.7) +
  
  # Use built-in colorblind-friendly palette
  scale_color_brewer(palette = "Dark2") +
  
  labs(
    title = "PCA Scatter Plot: PC1 vs PC2",
    subtitle = "Colored by KOI Disposition (Points + Density Contours)",
    x = "PC1 (see current loadings for orientation)",
    y = "PC2 - 'Stellar/Orbit Properties'",
    color = "KOI Disposition"
  ) +
  theme_minimal() +
  guides(color = guide_legend(override.aes = list(alpha = 1, size = 2))) + # Make legend opaque
  coord_cartesian(xlim = c(-15,10), ylim = c(-15,10)) # We zoom, in order to see the center of activity


# Display the plot
print(pc1_v_pc2_plot)

# --- 13.3: Create a Faceted Plot (Often Clearer) ---
#
# Sometimes, plotting all groups on top of each other is
# still too messy. A faceted plot shows each group in its
# own panel, making its unique "shape" much clearer.

pc1_v_pc2_faceted <- ggplot(plot_df, aes(x = PC1, y = PC2, color = disposition)) +
  geom_point(alpha = 0.2, size = 0.5) +
  
  # This is the key: split the plot by 'disposition'
  facet_wrap(~ disposition) +
  
  scale_color_brewer(palette = "Dark2") +
  labs(
    title = "PCA Scatter Plot (Faceted)",
    subtitle = "Showing the distinct distributions of each group in PC1/PC2 space",
    x = "PC1 - 'Stellar Scale'",
    y = "PC2 - 'Stellar/Orbit Properties'"
  ) +
  theme_minimal() +
  theme(legend.position = "none") + # Hide redundant legend
  coord_cartesian(xlim = c(-15,10), ylim = c(-15,10)) # We zoom, in order to see the center of activity


# Display the faceted plot
print(pc1_v_pc2_faceted)

# Adding a 3D plot that allows to see PC3's effect on separating the data
# 1. Create the Plot
pca_3d_cloud <- plot_ly(
  data = plot_df,
  x = ~PC1, y = ~PC2, z = ~PC3,
  color = ~disposition, colors = "Dark2",
  type = "scatter3d", mode = "markers",
  marker = list(size = 1.5, opacity = 0.3, line = list(width = 0))
) %>%
  layout(
    title = "PCA Scores by KOI Disposition",
    scene = list(
      camera = list(eye = list(x = 1.65, y = 1.65, z = 1.65)),
      xaxis = list(title = "PC1"),
      yaxis = list(title = "PC2"),
      zaxis = list(title = "PC3")
    ),
    legend = list(title = list(text = "KOI Disposition"))
  )

print(pca_3d_cloud)

# STEP 14: Exploratory Distribution Comparisons (Kruskal-Wallis Test) -----

# Kruskal-Wallis compares rank distributions of component scores across
# disposition groups. A median-shift interpretation needs comparable shapes.
# Small p-values do not measure classification accuracy or useful separation.

# --- 14.1: The Formal "Metric" (Statistical Test) ---
# We will use the 'plot_df' data frame we created in Step 13,
# as it contains both the PC scores and the 'disposition' label.

# Test for PC1
pc1_test <- kruskal.test(PC1 ~ disposition, data = plot_df)
cat("--- Kruskal-Wallis Test for PC1 ---\n")
print(pc1_test)

# Test for PC2
pc2_test <- kruskal.test(PC2 ~ disposition, data = plot_df)
cat("\n--- Kruskal-Wallis Test for PC2 ---\n")
print(pc2_test)

# Test for PC3
pc3_test <- kruskal.test(PC3 ~ disposition, data = plot_df)
cat("\n--- Kruskal-Wallis Test for PC3 ---\n")
print(pc3_test)
cat("Holm-adjusted p-values for the three disposition comparisons:\n")
print(p.adjust(c(PC1=pc1_test$p.value, PC2=pc2_test$p.value, PC3=pc3_test$p.value), method="holm"))



# Read the computed tests above rather than cached statistics. These tests
# are descriptive, conditional on this sample and representation. A p-value
# is not the probability that a finding arose by chance or that a null is true.



# STEP 15: The Loadings Plot (The "Variable-Only" Biplot) -----


# For the correlation circle, multiply each eigenvector coefficient by
# the component standard deviation. Raw rotation entries alone are not
# correlations between standardized variables and component scores.
loadings_df <- as.data.frame(sweep(pca_result$rotation, 2, pca_result$sdev, "*")) %>%
  rownames_to_column(var = "Variable")

# --- 15.2: Create the Plot ---
# We will draw:
#   1. A segment (arrow) from (0,0) to (PC1, PC2)
#   2. A text label for each variable
#   3. A fixed coordinate system (ratio=1) so angles are correct
#   4. A unit circle (common for correlation plots)

loadings_arrow_plot <- ggplot(loadings_df, aes(x = PC1, y = PC2, label = Variable)) +
  
  # Set up the axes and background circle
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray") +
  
  # Add the unit circle (correlation circle)
  geom_circle(aes(x0 = 0, y0 = 0, r = 1.0), color = "gray", alpha = 0.3) +
  
  # Draw the arrows (vectors) from origin to (PC1, PC2)
  geom_segment(
    aes(x = 0, y = 0, xend = PC1, yend = PC2),
    arrow = arrow(length = unit(0.2, "cm")),
    color = "blue"
  ) +
  
  # Add the variable labels, using ggrepel to avoid overlap
  geom_text_repel(
    segment.color = "gray", # Color of the line from point to label
    segment.size = 0.5,
    min.segment.length = 0
  ) +
  
  # THIS IS CRITICAL:
  # It ensures 1 unit on the x-axis is the same size as 1 unit
  # on the y-axis. This makes angles and vector lengths true.
  coord_fixed(ratio = 1) +
  
  labs(
    title = "Variable-PC Correlation Circle",
    subtitle = "Arrows show the direction of original variables in the PCA space",
    x = "PC1 - 'Stellar Scale' ",
    y = "PC2 - 'Stellar/Orbit Properties'"
  ) +
  theme_minimal()

# Display the plot
print(loadings_arrow_plot)

# Arrow endpoints are variable-component correlations. Angles approximate
# variable correlations only to the extent that this plane represents them.
# Perpendicular projected arrows do not demonstrate independence. Axis signs
# may reverse without changing the PCA.



# STEP 16: Faceted Density Plots -----


#
# We will then use `facet_wrap` to create separate panels
# for each of our new variables from Step 2. This will
# visually test if our PCA dimensions (PC1/PC2) have
# successfully separated these groups.
#

# --- 16.1: Test 1 - The 'large_planet' (Domain) Flag ---
# We need to format the label for the plot
plot_df$large_planet_label <- factor(plot_df$large_planet,
                                     levels = c(0, 1),
                                     labels = c("Small/Medium (R <= 4)", "Large (R > 4)"))

faceted_density_planet <- ggplot(plot_df, aes(x = PC1, y = PC2)) +
  
  # Draw the 2D density contours
  geom_density_2d(aes(color = after_stat(level))) +
  
  # Create a separate plot for "Small" vs "Large" planets
  facet_wrap(~ large_planet_label) +
  
  scale_color_viridis_c() +
  labs(
    title = "PCA Interpretation (Test 1): 'large_planet'",
    subtitle = "Does the data cluster *location* shift for large planets?",
    x = "PC1 - 'Stellar Scale'",
    y = "PC2 - 'Stellar/Orbit Properties'"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(faceted_density_planet)


# --- 16.2: Test 2 - The 'insolation_class' (Statistical) Flag ---
#
faceted_density_insolation <- ggplot(plot_df, aes(x = PC1, y = PC2)) +
  
  # Draw the 2D density contours
  geom_density_2d(aes(color = after_stat(level))) +
  
  # Create three panels: "low", "medium", "high"
  facet_wrap(~ insolation_class) +
  
  scale_color_viridis_c() +
  labs(
    title = "PCA Interpretation (Test 2): 'insolation_class'",
    subtitle = "Does the data cluster *location* shift by insolation?",
    x = "PC1 - 'Stellar Scale'",
    y = "PC2 - 'Stellar/Orbit Properties'"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(faceted_density_insolation)

# These faceted densities summarize score distributions for input-derived
# groups. Inspect them alongside the loadings and overlap; a radius or
# insolation association is expected when those inputs also enter the PCA.




# STEP 17: Ridge Plots -----


# --- 17.1: Prepare the Data ---
# We will use the main 'plot_df' which has all scores and labels
plot_df_long_all <- plot_df %>%
  select(
    PC1, PC2, PC3, PC4,
    hot_star, large_planet, insolation_class, magnitude_class
  ) %>%
  mutate(
    hot_star = factor(hot_star, levels = c(0, 1), labels = c("Cool Star", "Hot Star")),
    large_planet = factor(large_planet, levels = c(0, 1), labels = c("Small/Medium", "Large"))
  ) %>%
  pivot_longer(
    cols = c(hot_star, large_planet, insolation_class, magnitude_class),
    names_to = "Variable_Group",
    values_to = "Class_Label"
  ) %>%
  pivot_longer(
    cols = c(PC1, PC2, PC3, PC4),
    names_to = "Component",
    values_to = "Score"
  )

# Ridge plots display temperature-group score distributions. The hot/cool
# threshold is sample-relative and derives from an input to the PCA.
ridge_plot_hot_star <- plot_df_long_all %>%
  filter(Variable_Group == "hot_star") %>%
  ggplot(aes(x = Score, y = Class_Label, fill = Class_Label)) +
  geom_density_ridges(alpha = 0.7) +
  facet_wrap(~ Component, scales = "free_x") +
  scale_fill_brewer(palette = "Set1") +

  # We set a "zoom" from -10 to 10. This is appropriate
  # as it covers the vast majority of the data's density.
  coord_cartesian(xlim = c(-10, 10)) +
  
  labs(
    title = "PCA Interpretation: 'hot_star' (Ridge Plot)",
    subtitle = "Distribution of PC Scores for Hot vs. Cool Stars (Zoomed)",
    x = "PC Score (Zoomed to -10 to 10)",
    y = "Stellar Temperature Group"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(ridge_plot_hot_star)

# Brightness-group densities describe apparent magnitude associations.
# Their shifts depend on component signs and do not establish causation
# or independent validation of the representation.

ridge_plot_magnitude <- plot_df_long_all %>%
  filter(Variable_Group == "magnitude_class") %>%
  mutate(Class_Label = factor(Class_Label, levels = c("bright", "medium", "dim"))) %>%
  ggplot(aes(x = Score, y = Class_Label, fill = Class_Label)) +
  geom_density_ridges(alpha = 0.7) +
  facet_wrap(~ Component, scales = "free_x") +
  scale_fill_viridis_d(option = "C") +
  
  # --- ZOOM IN ---
  coord_cartesian(xlim = c(-10, 10)) +
  
  labs(
    title = "PCA Interpretation: 'magnitude_class' (Ridge Plot)",
    subtitle = "Distribution of PC Scores for Bright, Medium, & Dim Stars (Zoomed)",
    x = "PC Score (Zoomed to -10 to 10)",
    y = "Stellar Magnitude Group"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(ridge_plot_magnitude)

# STEP 18: Final Statistical Proof (All Variables) -----

# This step runs the Kruskal-Wallis test for all 4
# derived variables from Step 2 against the first 4
# principal components.

# --- 18.1: Create all 16 test combinations ---
# We use tidyr::crossing to create a data frame
# with every variable paired with every component.
variables <- c("large_planet", "hot_star", "insolation_class", "magnitude_class")
components <- c("PC1", "PC2", "PC3", "PC4")

all_combinations <- crossing(
  Variable_Group = variables,
  Component = components
)

# --- 18.2: Run the tests for each combination ---
# We use dplyr::rowwise to run the test for each
# row created in the 'all_combinations' data frame.
all_tests_summary <- all_combinations %>%
  rowwise() %>%
  mutate(
    # Create the formula
    formula_str = paste(Component, "~", Variable_Group),
    
    # Run the test and "tidy" it, saving the result in a list-column
    test_result = list(tidy(kruskal.test(as.formula(formula_str), data = plot_df)))
  ) %>%
  ungroup() %>% # Stop the row-wise operation
  unnest(test_result) %>% # Expand the tidy results from the list-column
  select(Variable_Group, Component, p.value) %>%
  mutate(p.value = p.adjust(p.value, method = "holm")) # Keep only the columns we need


# --- 18.3: Format and Print the Summary Table ---
# We will pivot the table for easy reading
final_p_value_table <- all_tests_summary %>%
  # Format p-values in scientific notation
  mutate(p.value = format.pval(p.value, digits = 2, eps = 1e-100)) %>%
  pivot_wider(
    names_from = Component,
    values_from = p.value
  ) %>%
  # Re-order columns
  select(Variable_Group, PC1, PC2, PC3, PC4)

cat("--- FINAL SUMMARY: Kruskal-Wallis p-values (Holm adjusted across 16 tests) ---\n")
print(final_p_value_table)


# Printed adjusted p-values above belong to this execution.

# --- 18.1: Definitive Interpretation of P-Value Table ---
#
# These are descriptive associations, not an external validation of PCA.
#
# 1. With this sample size, small p-values only reject equal score
#    distributions. They do not quantify a useful effect size or prove
#    separability, and the derived labels share input variables with PCA.
#
# 2. PCA produces orthogonal score directions. Orthogonality and zero linear
#    correlation do not establish statistical, causal or physical independence.
#
# 3. The derived variables are useful interpretation aids, but are not held-out
#    labels because they are constructed from PCA input variables.
#
#
# --- 18.2: Final Project Conclusion ---
#
# This analysis is an exploratory PCA of the versioned Kepler snapshot:
#
# 1. We use standardized variables so units and scales do not dominate PCA.
#
# 2. Correlation diagnostics describe linear dependence in the analysis input.
#
# 3. Component interpretations are hypotheses based on loadings, not physical
#    identities.
#
# 4. The component cutoff is a descriptive variance-retention choice.
#
# 5. Visualisations and tests describe this sample; external labels are needed
#    for predictive validation.
#
# 6. Derived labels are not used as independent proof because they reuse the
#    original variables.
#
