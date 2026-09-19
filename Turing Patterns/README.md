# Gray-Scott Reaction-Diffusion Simulation

[Portfolio](../README.md) · [Execution guide](../RUNNING.md) · [Notebook](simulation.ipynb)

A numerical laboratory exploring **Turing Patterns** via the Gray-Scott reaction-diffusion model. This project simulates two chemical species interacting on a 2D grid to produce spatial patterns like spots, stripes, and cells.

## How it Works

The model simulates two substances, $A$ and $B$, which diffuse at different rates and react interactively.
The system is governed by the following equations:

$$
\frac{\partial A}{\partial t} = D_A \nabla^2 A - AB^2 + f(1-A)
$$
$$
\frac{\partial B}{\partial t} = D_B \nabla^2 B + AB^2 - (k+f)B
$$

Where:

- **Diffusion:** $D_A, D_B$ (Spread of chemicals across the grid)
- **Reaction:** $AB^2$ (Non-linear feedback loop)
- **Feed/Kill:** $f$ feeds substance A, and $k$ removes substance B.

## Features

- **Vectorized Implementation:** Uses `NumPy` array operations to update all grid cells within each time step.
- **Periodic Boundaries:** The grid wraps around the edges (toroidal topology) to model a periodic domain.
- **Snapshot Animation:** Uses `Matplotlib` to animate saved states after the simulation completes.

## Running and numerical checks

Use the [shared Python environment](../RUNNING.md) and execute [simulation.ipynb](simulation.ipynb) from this directory. The code names the two species `U` and `V`; it generates its initial state locally and runs 10,000 steps on a 200 × 200 grid, saving 21 states including the initial one.

The implementation checks the periodic Laplacian and rejects nonfinite or invalid concentration updates instead of concealing them with clipping. Its successful run applies to the documented grid, time step and parameters; changing them requires checking numerical stability again.
