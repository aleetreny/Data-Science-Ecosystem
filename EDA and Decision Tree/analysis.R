# ============================================================================
# Student Performance Data Analysis
# ============================================================================

# Load required libraries
required_packages <- c(
  "ggplot2",
  "dplyr",
  "rpart",
  "rpart.plot",
  "gridExtra",
  "corrplot",
  "tibble",
  "knitr",
  "caret"
)

for (pkg in required_packages) {
  if (!pkg %in% installed.packages()[, "Package"]) {
    cat(paste("Missing package:", pkg, "Installing!\n"))
    install.packages(pkg, dependencies = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("\nDone! All libraries are loaded.\n")
library(ggplot2)
library(dplyr)
library(rpart)
library(rpart.plot)
library(gridExtra)
library(corrplot)
library(tibble)
library(knitr)
library(caret)

# ============================================================================
# PART A: EXPLORATORY DATA ANALYSIS
# ============================================================================

# Load the dataset
student_data <- read.csv("student_data.csv", sep = ";", header = TRUE)

# Display dataset structure
str(student_data)
summary(student_data)

# Check for missing values
sum(is.na(student_data))

# ============================================================================
# Question 1: How does the maximum parental education level influence mean final grade (G3)?
# Visualization: Bar Chart
# ============================================================================

# Create a combined parental education variable
student_data$max_parent_edu <- pmax(student_data$Medu, student_data$Fedu)

# Calculate mean final grade by maximum parental education
parent_edu_summary <- student_data %>%
  group_by(max_parent_edu) %>%
  summarise(
    mean_G3 = mean(G3),
    count = n(),
    sd_G3 = sd(G3)
  )

p1 <- ggplot(parent_edu_summary,
             aes(x = factor(max_parent_edu), y = mean_G3, fill = factor(max_parent_edu))) +
  geom_col(color = "black", width = 0.7) +
  geom_errorbar(aes(ymin = mean_G3 - sd_G3/sqrt(count),
                    ymax = mean_G3 + sd_G3/sqrt(count)),
                width = 0.18) +
  geom_text(aes(y = mean_G3 + sd_G3/sqrt(count) + 0.35,
                label = sprintf("%.2f", mean_G3)),
            vjust = 0, size = 3.5) +
  labs(
    title = "Impact of Maximum Parental Education\non Student Final Grade",
    subtitle = NULL,
    x = "Maximum Parental Education Level",
    y = "Mean Final Grade (G3)"
  ) +
  scale_x_discrete(labels = c("4th grade", "5-9th grade", "Secondary", "Higher education")) +
  scale_fill_brewer(palette = "Blues") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  coord_cartesian(clip = "off") +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    plot.subtitle = element_text(size = 8, face = "italic", hjust = 0.5),
    axis.title.x = element_text(face = "bold", margin = margin(t = 10, unit = "pt")),
    axis.title.y = element_text(face = "bold"),
    legend.position = "none"
  )

print(p1)


# ============================================================================
# Question 2: What is the distribution of final grades (G3) relative to the passing threshold (10)?
# Visualization: Histogram
# ============================================================================

df_di <- transform(student_data, pass_margin = G3 - 10)

subtxt <- with(df_di, sprintf(
  "Below: %d (%.1f%%) | Exactly 10: %d (%.1f%%) | Above: %d (%.1f%%)",
  sum(pass_margin < 0), 100*mean(pass_margin < 0),
  sum(pass_margin == 0), 100*mean(pass_margin == 0),
  sum(pass_margin > 0), 100*mean(pass_margin > 0)
))

p2 <- ggplot(df_di, aes(pass_margin)) +
  geom_histogram(
    aes(fill = after_stat(ifelse(x < 0, "Below pass",
                                 ifelse(x == 0, "Exactly 10", "Above pass")))),
    binwidth = 1, boundary = -0.5, color = "white", alpha = 0.95
  ) +
  scale_fill_manual(
    limits = c("Below pass","Exactly 10","Above pass"),
    values = c("Below pass"="#e15759","Exactly 10"="#9e9e9e","Above pass"="#4e79a7"),
    name = NULL
  ) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  labs(title = "Histogram: Distance to Pass Threshold (G3 − 10)",
       subtitle = subtxt, x = "Points above/below pass", y = "Count") +
  scale_x_continuous(breaks = seq(floor(min(df_di$pass_margin)), ceiling(max(df_di$pass_margin)), 2)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.06))) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
        plot.subtitle = element_text(size = 8, face = "italic", hjust = 0.5),
        axis.title.x = element_text(face = "bold", margin = margin(t = 10, unit = "pt")),
        axis.title.y = element_text(face = "bold"),
        legend.position = "top")

print(p2)


# ============================================================================
# Question 3: How does a student's aspiration for higher education relate to their final grade (G3) distribution?
# Visualization: Boxplot
# ============================================================================

df_hi <- transform(student_data, higher = factor(higher, c("no","yes"), c("No","Yes")))
subtxt <- {
  f <- function(g) sprintf("%s: N=%d | pass=%d%%", g,
                           sum(df_hi$higher==g), round(100*mean(df_hi$G3[df_hi$higher==g] >= 10)))
  paste(f("Yes"), f("No"), sep = "\n")
}
df_w <- df_hi %>% group_by(higher) %>%
  mutate(w_lo = boxplot.stats(G3)$stats[1], w_hi = boxplot.stats(G3)$stats[5]) %>% ungroup()

p3 <- ggplot(df_hi, aes(higher, G3, fill = higher)) +
  geom_violin(data = subset(df_w, G3 >= w_lo & G3 <= w_hi),
              trim = TRUE, scale = "width", alpha = 0.35, color = NA, width = 0.9, adjust = 0.8) +
  geom_boxplot(width = 0.18, alpha = 1, outlier.shape = NA) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white", color = "black") +
  geom_hline(yintercept = 10, linetype = "dashed") +
  scale_fill_manual(values = c("No"="#ee6d6a","Yes"="#9dbbe0"), guide = "none") +
  labs(title = "Final Grades by Higher-Education Aspiration", subtitle = subtxt,
       x = "Wants higher education", y = "Final grade (G3)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
        plot.subtitle = element_text(size = 8, hjust = 0.5),
        axis.title.x = element_text(face = "bold", margin = margin(t = 10, unit = "pt")),
        axis.title.y = element_text(face = "bold"),
  )

print(p3)


# ============================================================================
# Question 4: How does a history of academic failures (1+ failures) affect the relationship between G2 and G3?
# Visualization: Scatter Plot with regression line
# ============================================================================

subtxt_q4 <- "Low Risk (0 Failures): 312 (79.0%) | High Risk (1+ Failures): 83 (21.0%)"

p4 <- student_data %>%
  dplyr::mutate(
    Failure_Group = factor(
      ifelse(failures > 0, "1+ Past Failures", "0 Past Failures"), 
      levels = c("0 Past Failures", "1+ Past Failures")
    )
  ) %>%
  ggplot(aes(x = G2, y = G3, color = Failure_Group)) +
  geom_point(alpha = 1.0, size = 1.5) +
  geom_smooth(aes(group = 1), 
              method = "lm", 
              se = TRUE,              
              linewidth = 1.2,        
              color = "black",        
              fill = "gray70",        
              alpha = 0.15) +         
  labs(
    title = "Final Grade (G3) vs. Previous Grade (G2)\nImpact of Academic Failures",
    subtitle = subtxt_q4,
    x = "Second Period Grade (G2)",
    y = "Final Grade (G3)",
    color = "Academic History"
  ) +
  scale_color_manual(values = c("0 Past Failures" = "#4daf4a", "1+ Past Failures" = "#e41a1c")) + 
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    plot.subtitle = element_text(size = 8, face = "italic", hjust = 0.5),
    axis.title.x = element_text(face = "bold", margin = margin(t = 10, unit = "pt")),
    axis.title.y = element_text(face = "bold"),
    legend.position = "bottom"
  )

print(p4)

# ===========================================================================
# QUESTION 5 (General Summary Technique)
# Which numerical/ordinal factors have the strongest correlation 
# with the final grade (G3)?
# Visualization: Targeted Correlation Plot (Lollipop Plot)
# ===========================================================================

# 1. Select ALL numeric or ordinal variables
# (We omit pure categorical ones like Mjob, Fjob, etc.)
numeric_ordinal_data <- student_data %>%
  select(age, Medu, Fedu, traveltime, studytime, failures,
         famrel, freetime, goout, Dalc, Walc, health, absences,
         G1, G2, G3)

# 2. Calculate the Spearman correlation matrix
cor_matrix_spearman_all <- cor(numeric_ordinal_data, method = "spearman")

# 3. Isolate the correlation of ALL variables against G3
cor_with_g3 <- as.data.frame(cor_matrix_spearman_all[, "G3"])
colnames(cor_with_g3) <- "correlation"

# 4. Convert row names (the variables) into a column
cor_with_g3 <- rownames_to_column(cor_with_g3, var = "variable")

# 5. Filter out G3's correlation with itself (which is 1 and not useful)
cor_with_g3_filtered <- cor_with_g3 %>%
  filter(variable != "G3") %>%
  # Create a column for coloring (positive/negative)
  mutate(type = ifelse(correlation > 0, "Positive", "Negative"))

# 6. We use reorder(variable, correlation) to sort the bars
# from lowest to highest.
ggplot(cor_with_g3_filtered, aes(x = correlation, y = reorder(variable, correlation), color = type)) +
  geom_segment(aes(x = 0, yend = variable, xend = correlation, yend = reorder(variable, correlation)),
               linewidth = 1.2) +
  geom_point(size = 4) +
  
  scale_color_manual(values = c("Negative" = "#E63946", "Positive" = "#457B9D")) +
  
  scale_x_continuous(breaks = seq(-0.4, 1.0, by = 0.2), 
                     limits = c(-0.5, 1.1)) +
  
  labs(title = "Spearman Correlation of Factors with Final Grade (G3)",
       subtitle = "General summary of numerical and ordinal variables",
       x = "Spearman Correlation Coefficient (rho)",
       y = "Variable") +
  theme_minimal() +
  theme(legend.position = "none",
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(),
        plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
        plot.subtitle = element_text(size = 8, face = "italic", hjust = 0.5),
        axis.title.x = element_text(face = "bold", margin = margin(t = 10, unit = "pt")),
        axis.title.y = element_blank())

# ============================================================================
# PART B: DECISION TREE (Tuning & Evaluation)
# ============================================================================

# ============================================================================
# 1. Data Preparation
# ============================================================================

# Create the binary target variable
student_data$high_performance <- factor(
  ifelse(student_data$G3 >= 10, "Yes", "No"),
  # Set 'Yes' as the positive class for metric calculation
  levels = c("Yes", "No")
)

# Partition data into training (70%) and testing (30%) sets
set.seed(123)
train_indices <- createDataPartition(student_data$high_performance, p = 0.7, list = FALSE)
train_data <- student_data[train_indices, ]
test_data <- student_data[-train_indices, ]

# Define predictors (excluding grades and the target itself)
predictors <- setdiff(names(student_data), c("G1", "G2", "G3", "high_performance", "max_parent_edu"))
formula <- as.formula(paste("high_performance ~", paste(predictors, collapse = " + ")))

# ============================================================================
# 2. Class Distribution Check
# ============================================================================

print("Training Set Class Distribution:")
print(prop.table(table(train_data$high_performance)))

# ============================================================================
# 3. Model Training
# ============================================================================

# Define trainControl: 10-fold Cross-Validation
# Use twoClassSummary to enable 'ROC' as the performance metric
train_control <- trainControl(
  method = "cv",
  number = 10,
  summaryFunction = twoClassSummary,
  classProbs = TRUE,
  savePredictions = "final"
)

# Define a tuning grid for the complexity parameter ('cp')
# This grid tests 34 different values from simple (0.1) to complex (0.001)
tune_grid <- expand.grid(cp = seq(0.001, 0.1, by = 0.003))

# Train the model
# This will test all 'cp' values using 10-fold CV
# to find the optimal model based on the 'ROC' metric.
cat("Tuning model... This may take a few seconds.\n")

set.seed(123) # For reproducible tuning
tuned_tree_model <- train(
  formula,
  data = train_data,
  method = "rpart",
  trControl = train_control,
  metric = "ROC",           # Optimize for "ROC" (robust to class imbalance)
  tuneGrid = tune_grid
)

cat("Tuning complete.\n")

# Review tuning results (optional, but good practice)
print(tuned_tree_model)
plot(tuned_tree_model) # Plot shows how ROC changes with complexity (cp)

# ============================================================================
# 4. Tree Visualization
# ============================================================================

# The 'finalModel' object is the tree automatically pruned
# to the optimal 'cp' value found during cross-validation.
final_tree <- tuned_tree_model$finalModel

rpart.plot(final_tree, main = "Decision Tree: Predicting High Performance (G3 ≥ 10)",
           extra = 104, box.palette = "RdYlGn", branch.lty = 3,
           shadow.col = "gray85", nn = TRUE, split.yshift = -1, split.yspace = 2)

# ============================================================================
# 5. Model Evaluation
# ============================================================================

# Use confusionMatrix for a comprehensive report
predictions <- predict(tuned_tree_model, test_data)

# Set 'positive = "Yes"' to ensure metrics like Sensitivity
# and Precision are calculated for the "Yes" class.
matrix_report <- confusionMatrix(
  data = predictions,
  reference = test_data$high_performance,
  positive = "Yes"
)

# Print the full text-based report
print("--- Full Confusion Matrix Report (Test Set) ---")
print(matrix_report)

# ============================================================================
# 6. Performance Table
# ============================================================================

# Extract key metrics into a data.frame for a clean report table.
metrics_table <- data.frame(
  Metric = c("Accuracy", 
             "Kappa", 
             "Sensitivity (Recall)", 
             "Specificity", 
             "Precision (PPV)", 
             "F1-Score"),
  Value = c(
    matrix_report$overall["Accuracy"],
    matrix_report$overall["Kappa"],
    matrix_report$byClass["Sensitivity"],
    matrix_report$byClass["Specificity"],
    matrix_report$byClass["Pos Pred Value"],
    matrix_report$byClass["F1"]
  )
)

# Print the clean table using kable()
print("--- Summary Performance Metrics Table ---")
kable(metrics_table, 
      digits = 4, 
      caption = "Key Model Performance Metrics (Test Set)")
