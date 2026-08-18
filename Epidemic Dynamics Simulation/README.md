# Epidemic Dynamics Simulation

This project simulates the spread of a theoretical virus using Cellular Automata and Linear Algebra techniques. Instead of traditional agent-based modeling with loops, this simulation utilizes 2D Convolutions and vectorized operations to process population dynamics efficiently in pure Python.

## Project Overview

The simulation models a city grid where agents interact with their neighbors to determine their state. It explores emergent behaviors in complex systems through two distinct iterations:

* **Model 1 (Baseline):** A homogeneous population with a static virus, modeling the standard SZR (Susceptible, Zombie, Removed) flow.
* **Model 2 (Advanced):** A complex system introducing heterogeneity. It includes Gaussian-distributed population attributes (strength/defense), spatial safe zones (hospitals), and temporal viral mutation.

## Key Features

* **Vectorized Logic:** Uses `scipy.signal.convolve2d` to calculate neighbor interactions for the entire grid simultaneously, eliminating the need for slow Python loops.
* **Stochastic Modeling:** Implements probabilistic infection and death rates using NumPy random matrices.
* **SZR Dynamics:** Tracks three states: Susceptible (Humans), Infected (Zombies), and Removed (Dead).
* **Advanced Analytics:** Includes logarithmic scale population charts, radial spatial analysis to measure the "Bunker Effect," and multi-variable scatter plots to analyze survival factors.

## Interpretation limits

The two models are exploratory scenarios, not matched counterfactual experiments: they change several mechanisms simultaneously. Their outcomes should therefore not be interpreted as a causal estimate of the benefit of any single intervention. The notebook now uses one seeded generator and independent random draws for infection, combat and decay; rerun it with repeated seeds and one-factor-at-a-time scenarios before comparing policies.

## Technologies Used

* **Python 3.x**
* **NumPy:** For matrix manipulation and vectorization.
* **SciPy:** For 2D convolution operations.
* **Matplotlib:** For data visualization and generating animations.
* **Seaborn:** For statistical data plotting.
