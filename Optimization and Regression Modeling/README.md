# Optimization and Regression Modelling

## Repository Overview

This repository contains a collection of advanced optimization and data analysis projects, developed as part of the Optimization and Decision Analytics coursework for the Master on Statistics for Data Science at UC3M.

The projects serve as practical, hands-on applications of mathematical optimization techniques, demonstrating how to model and solve complex problems using Python and the Gurobi Optimizer. The repository is divided into two main areas:

- **Linear Programming (LP):** Explores classic LP problems, including resource allocation and a unique formulation of a regression problem (Mean Absolute Error) as a linear program.
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
- **Constraints:** Resource consumption cannot exceed availability

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
- Introduce binary error variables for over-prediction and under-prediction errors
- Reformulate the absolute value objective as a linear function

**Key Advantage:** This formulation is **more robust to outliers** than OLS regression because it uses absolute deviations instead of squared deviations.

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

Links binary production decisions to continuous quantity variables:
- `production_j ≤ capacity × y_j`
- Ensures production only occurs when the binary variable is activated

### Logical Business Rules

The model enforces: *"If product 3 is produced, then product 1 must also be produced"*
- This is expressed as: `y_3 ≤ y_1`

### Piecewise Linear Profit Functions

Products have declining marginal profits (e.g., first 10 units earn €4/unit, remaining units earn €3/unit):
- Production is split into segments with different profit rates
- Sequential filling logic ensures lower-cost segments are used first
- Segments can only be activated if all previous segments are full

**Implementation & Analysis:** The Gurobi model balances all complex constraints to find the globally optimal production plan.

**Key Findings (from Report.pdf):**

- **Optimal Production Plan:** Produce Products 1 and 2; do not produce Product 3
- **Maximum Profit:** €284 net profit
- **Bottleneck:** Resource 4 operates at 99.9% capacity
- **Managerial Recommendation:** Expanding Resource 4 capacity would be the most effective way to increase profitability

**Files:**
- Problem Statement 2.pdf: The full academic prompt with all problem data and constraints
- Jupyter_resolution_report.ipynb: Complete Gurobi-Python model, solution analysis, and visualization
- Report.pdf: Formal business report with managerial insights and recommendations

---

## Technologies & Libraries

| Technology | Purpose |
|---|---|
| **Python 3.9+** | Core programming language |
| **Gurobi Optimizer** | High-performance commercial LP/MILP solver |
| **Jupyter Notebook** | Interactive code development and analysis |
| **Plotly** | Interactive 3D regression plane visualization |
| **Matplotlib** | Static 2D plots and visualizations |
| **Pandas & NumPy** | Data manipulation and numerical computations |

---

## How to Use

### Clone the repository:

```bash
git clone https://github.com/your-username/Optimization-and-Regression-Modelling.git
cd Optimization-and-Regression-Modelling
```

### Install Dependencies:

This project requires a working Python environment.

The primary dependency is **gurobipy**. Gurobi is a commercial product but offers a **free academic license** for students and researchers. You must have a valid Gurobi license installed on your machine to run the notebooks.

Other packages can be installed via pip:

```bash
pip install jupyterlab pandas numpy plotly matplotlib
```

### Run the Notebooks:

Launch Jupyter:

```bash
jupyter lab
```

Open either `Jupyter_resolution.ipynb` or `Jupyter_resolution_report.ipynb` to explore the models and run the code.

---

## Disclaimer

This repository contains academic project work. The problem statements and data are provided by the course instructors at UC3M.