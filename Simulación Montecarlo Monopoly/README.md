# Statistical and Strategic Analysis of Monopoly (Madrid Ed.)

> A study of game probability and economics using Monte Carlo simulations in R.

![R](https://img.shields.io/badge/R-4.0%2B-blue)
![Tidyverse](https://img.shields.io/badge/Main_Lib-Tidyverse-orange)
![Status](https://img.shields.io/badge/Status-Exploratory-blue)

## About the Project

This project uses data science to analyze the underlying mechanics of Monopoly (Classic Madrid Edition).

Using R, this project simulates **2,000,000 rolls** of a simplified Madrid
edition ruleset, including a jail state. It is an exploratory probability and
cash-flow study rather than a full multiplayer Monopoly simulator.

## Key Findings

The data yielded by the simulation reveals clear patterns:

1.  **Landing frequencies:** The simulation estimates visit frequencies under
    the documented ruleset; results depend on the rules and random seed.
2.  **Marginal payback:** The construction chart compares incremental cost and
    expected incremental rent. It does not establish a universal optimal house
    count because it omits ownership, house supply and opponents.
3.  **Illustrative survival scenario:** The cash-flow scenario uses independent
    landings and fixed development phases, so it is not a proof of a winning
    multiplayer strategy.

## Generated Visualizations

The `Monopoly.R` script generates a series of plots to visualize these findings:

*   **Frequency Heatmap:** Landing probability per tile.
*   **Profitability Curve:** Break-even analysis based on the number of houses (1-4 and Hotel).
*   **Efficiency Matrix:** Investment vs. Expected Return comparison.
*   **Risk Profile:** Classification of properties by Frequency vs. Damage (Impact).
*   **Survival Curve:** Simulation of how many turns opponents survive against each strategy.
*   **Board Skyline:** Visual representation of the economic value of each street.

## Technical Requirements

The project is developed in **R**. You will need the following packages installed:

*   `tidyverse` (for data manipulation and plotting with ggplot2).
*   `parallel` (optional, if you wish to parallelize the simulation).

Quick installation:
```r
install.packages("tidyverse")
```
