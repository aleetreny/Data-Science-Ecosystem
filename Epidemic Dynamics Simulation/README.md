# Epidemic Dynamics Simulation

[Portfolio](../README.md) · [Execution guide](../RUNNING.md) · [Notebook](simulation.ipynb)

This project explores a fictional susceptible–zombie–removed system using cellular automata. NumPy arrays and SciPy 2D convolutions update local interactions inside a time-stepping loop.

## Project Overview

The simulation models a city grid where agents interact with their neighbors to determine their state. It explores emergent behaviors in complex systems through two distinct iterations:

* **Model 1 (Baseline):** A homogeneous population with a static virus, modeling the standard SZR (Susceptible, Zombie, Removed) flow.
* **Model 2 (Advanced):** A complex system introducing heterogeneity. It includes Gaussian-distributed population attributes (strength/defense), spatial safe zones (hospitals), and temporal viral mutation.

## Key Features

* **Vectorized Logic:** Uses `scipy.signal.convolve2d` to calculate neighbor interactions for the entire grid simultaneously, avoiding a separate Python loop over individual grid cells.
* **Stochastic Modeling:** Implements probabilistic infection and death rates using NumPy random matrices.
* **SZR Dynamics:** Tracks three states: Susceptible (Humans), Infected (Zombies), and Removed (Dead).
* **Advanced Analytics:** Includes logarithmic scale population charts, radial spatial analysis to measure the "Bunker Effect," and multi-variable scatter plots to analyze survival factors.

## Interpretation limits

The two models are exploratory scenarios, not matched counterfactual experiments: they change several mechanisms simultaneously. Their outcomes should therefore not be interpreted as a causal estimate of the benefit of any single intervention. The notebook uses a seeded generator and independent random draws for infection, combat and decay; rerun it with repeated seeds and one-factor-at-a-time scenarios before comparing policies.

## Technologies Used

* **Python 3.12**
* **NumPy:** For matrix manipulation and vectorization.
* **SciPy:** For 2D convolution operations.
* **Matplotlib:** For data visualization and generating animations.
* **Seaborn:** For statistical data plotting.

## Running

Use the [shared Python environment](../RUNNING.md) and execute [simulation.ipynb](simulation.ipynb) from this directory. Inputs are generated locally. Run all cells in order to reproduce the seeded scenarios, plots and animations.
