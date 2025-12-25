# Statistical and Strategic Analysis of Monopoly (Madrid Ed.)

> A study of game probability and economics using Monte Carlo simulations in R.

![R](https://img.shields.io/badge/R-4.0%2B-blue)
![Tidyverse](https://img.shields.io/badge/Main_Lib-Tidyverse-orange)
![Status](https://img.shields.io/badge/Status-Completed-green)

## About the Project

This project uses data science to analyze the underlying mechanics of Monopoly (Classic Madrid Edition).

Using R, I have modeled the physical and economic rules of the game to simulate **2,000,000 rolls**. The goal is not just to calculate probabilities, but to understand capital efficiency and develop a data-driven winning strategy, answering questions such as: Which streets are the most profitable? How many houses should I build to maximize return?

## Key Findings

The data yielded by the simulation reveals clear patterns:

1.  **The Orange Dominance:** Due to the high frequency of exiting Jail, the Orange group (Felipe II, Velázquez, Serrano) is statistically the most visited zone on the board. It offers the best cost-benefit ratio.
2.  **The 3-House Strategy:** ROI analysis indicates that the third house represents the investment "sweet spot." Beyond this point, the marginal return decreases while the risk of illiquidity increases.
3.  **Speed vs. Strength:** Although the Green group collects higher rents, the Orange group causes bankruptcies faster due to its hit frequency. In a competitive match, the speed of return is key.

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
