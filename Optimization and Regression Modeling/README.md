# Optimization and Regression Modelling

## Repository Overview

This repository contains a collection of advanced optimization and data analysis projects, developed as part of the Optimization and Decision Analytics coursework for the Master on Statistics for Data Science at UC3M.

The projects serve as practical, hands-on applications of mathematical optimization techniques, demonstrating how to model and solve complex problems using Python and the Gurobi Optimizer. The repository is divided into two main areas:

- **Linear Programming (LP):** Explores classic LP problems, including resource allocation and a formulation of a regression problem (Mean Absolute Error) as a linear program.
- **Mixed Integer Linear Programming (MILP):** Tackles a more complex production planning problem involving fixed costs, logical constraints, and piecewise linear profit functions, which require integer and binary variables to model.

## Repository Structure

```
Optimization-and-Regression-Modelling/
├── README.md                 <-- (You are here)
│
├── Linear Programming/
│   ├── Problem Statement 1.pdf   <-- (Academic prompt for the LP & Regression problems)
│   └── Jupyter_resolution.ipynb  <-- (Gurobi-Python model & 3D Plotly visualization)
│
└── Mixed Integer Linear Programming/
    ├── Problem Statement 2.pdf   <-- (Academic prompt for the MILP problem)
    ├── Jupyter_resolution_report.ipynb <-- (Gurobi-Python model, data analysis, & plotting)
    └── Report.pdf                <-- (Formal write-up with managerial insights)
```

---

## Project 1: Linear Programming & MAE Regression

**Folder:** Linear Programming/

This project folder contains the solution to a two-part problem set, both solved using Linear Programming techniques.

### Part 1.1: Optimal Resource Allocation (LP)

**Problem:** A classic linear programming problem focused on maximizing the profit of five distinct economic activities, subject to constraints on two shared resources.

**Model:** The problem is formulated as a standard LP:

- **Objective:** Maximize total revenue from activities
- **Decision Variables:** Production levels for 5 economic activities
- **Constraints:** Resource balances follow the equalities specified in the
  problem statement; this is not a generic capacity-inequality model.

**Implementation:** The Jupyter_resolution.ipynb notebook implements this model in Gurobi. It also performs a detailed sensitivity analysis, examining:

- **Shadow Prices (Dual Variables):** The marginal value of an additional unit of each resource.
- **Reduced Costs:** The cost of forcing a non-basic variable (an activity not in the optimal solution) into the solution.

**Files:**
- Problem Statement 1.pdf: Contains the full problem description (Problem 1).
- Jupyter_resolution.ipynb: Contains the Gurobi-Python code for model creation, optimization, and sensitivity analysis.

### Part 1.2: Regression Modelling as Linear Programming (MAE)

**Problem:** This is the "Regression Modelling" component of the repository. The task is to find the best-fitting linear equation to predict a person's Height based on their Hand Size and Shoe Size.

**Model (The "LP" Twist):** Instead of using a traditional Ordinary Least Squares (OLS) approach (which minimizes the sum of squared errors), this problem is solved using the **Mean Absolute Error (MAE)** criterion.

**Approach:** 
- Minimize the sum of absolute deviations between predicted and actual values
- Introduce non-negative continuous positive/negative deviation variables
- Reformulate the absolute value objective as a linear function

**Key Advantage:** This formulation is less sensitive to large response residuals than squared loss; it does not protect against all high-leverage predictor outliers.

**Implementation:** The Jupyter_resolution.ipynb notebook:
1. Builds the LP model to find optimal regression coefficients
2. Creates an interactive 3D scatter plot using Plotly
3. Visualizes the original data points and the optimal regression plane

**Files:**
- Problem Statement 1.pdf: Contains the data and problem description (Problem 2).
- Jupyter_resolution.ipynb: Contains the Gurobi-Python model for MAE regression and the interactive 3D visualization.

---

## Project 2: Production Planning (MILP)

**Folder:** Mixed Integer Linear Programming/

This project addresses a complex, real-world production planning scenario for a company manufacturing three discrete products. The problem requires a Mixed Integer Linear Programming (MILP) model due to its business rules.

**Problem:** Determine the optimal production quantity for three products to maximize total profit, subject to constraints on four resources, production capacity limits, and complex business rules.

**Model (Key MILP Concepts):**

### Fixed Costs with Binary Variables

A fixed cost is incurred only if a product is manufactured. Binary variables (`y_j ∈ {0,1}`) indicate whether to produce each product:
- If `y_j = 1`: Product j is produced, and fixed cost `f_j` is incurred
- If `y_j = 0`: Product j is not produced, no fixed cost

### Big-M Constraints

Links binary decisions to integer production quantities:
- `y_j ≤ production_j ≤ capacity × y_j`
- Ensures production only occurs when the binary variable is activated

### Logical Business Rules

The model enforces: *"If product 3 is produced, then product 1 must also be produced"*
- This is expressed as: `y_3 ≤ y_1`

### Piecewise Linear Profit Functions

Products have declining marginal profits (e.g., first 10 units earn €4/unit, remaining units earn €3/unit):
- Production is split into segments with different profit rates
- Sequential filling logic ensures higher-profit segments are used first
- Segments can only be activated if all previous segments are full

**Implementation & Analysis:** The Gurobi model balances all complex constraints to find the globally optimal production plan.

**Key Findings (from Report.pdf):**

- **Optimal Production Plan:** Produce 36 units of Product 1 and 60 of Product 2; none of Product 3
- **Maximum Profit:** €284 net profit
- **Near-bottleneck:** Resource 4 uses 1,188 of 1,200 units (99.0%).
- **Managerial Recommendation:** Evaluate integer re-optimizations under
  additional Resource 4 capacity before treating it as a binding bottleneck.

**Files:**
- Problem Statement 2.pdf: The full academic prompt with all problem data and constraints
- Jupyter_resolution_report.ipynb: Complete Gurobi-Python model, solution analysis, and visualization
- Report.pdf: Formal business report with managerial insights and recommendations

---

## Technologies & Libraries

| Technology | Purpose |
|---|---|
| **Python 3.12** | Tested Python environment |
| **Gurobi Optimizer** | High-performance commercial LP/MILP solver |
| **Jupyter Notebook** | Interactive code development and analysis |
| **Plotly** | Interactive 3D regression plane visualization |
| **Matplotlib** | Static 2D plots and visualizations |
| **Pandas & NumPy** | Data manipulation and numerical computations |

---

## How to Use

### Clone the repository:

```bash
git clone https://github.com/aleetreny/Data-Science-Ecosystem.git
cd "Data-Science-Ecosystem/Optimization and Regression Modeling"
```

### Install Dependencies:

This project requires a working Python environment.

Use the shared [Python environment](../RUNNING.md), including **gurobipy**. These small models ran with the installed size-limited Gurobi license; other installations must provide a license that covers the model size and intended use.

### Run the Notebooks:

After creating the shared environment and registering its kernel, execute both notebooks from this directory:

```bash
../.venv/bin/jupyter nbconvert --to notebook --execute --inplace \
  --ExecutePreprocessor.kernel_name=data-science-ecosystem \
  --ExecutePreprocessor.timeout=3600 \
  "Linear Programming/Jupyter_resolution.ipynb" \
  "Mixed Integer Linear Programming/Jupyter_resolution_report.ipynb"
```

You can also open the notebooks in an editor with Jupyter support. A separate JupyterLab or Notebook interface is optional.

The resource-allocation LP has objective `660/13` (about 50.76923). The fitted
absolute-error regression has total absolute error 5.3497 and mean absolute
error 0.8916 over its six observations. Those are in-sample fitting errors.

After executing the MILP notebook, regenerate its report from that same source:

```bash
cd "Mixed Integer Linear Programming"
quarto render Jupyter_resolution_report.ipynb --to pdf \
  --metadata-file report-format.yml --output Report.pdf
```

The PDF needs Quarto and XeLaTeX. The original course problem statements are
preserved as supplied.

---

## Disclaimer

This repository contains academic project work. The problem statements and data are provided by the course instructors at UC3M.
