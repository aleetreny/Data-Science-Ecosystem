# Gray-Scott Reaction-Diffusion Simulation

A numerical laboratory exploring **Turing Patterns** via the Gray-Scott reaction-diffusion model. This project simulates two chemical species interacting on a 2D grid to produce complex, emergent biological patterns like spots, stripes, and cells.

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

- **Vectorized Implementation:** Uses `NumPy` array operations instead of slow Python loops for high performance.
- **Periodic Boundaries:** The grid wraps around the edges (toroidal topology) to prevent edge artifacts.
- **Real-time Visualization:** Uses `Matplotlib` to render the evolution of the pattern dynamically.
