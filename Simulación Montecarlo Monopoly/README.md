# Statistical and Strategic Analysis of Monopoly (Madrid Ed.)

[Portfolio](../README.md) · [Execution guide](../RUNNING.md) · [R script](Monopoly.R)

> A study of game probability and economics using Monte Carlo simulations in R.

![R](https://img.shields.io/badge/R-4.5.3-blue)
![Tidyverse](https://img.shields.io/badge/Main_Lib-Tidyverse-orange)
![Status](https://img.shields.io/badge/Status-Exploratory-blue)

## About the Project

This project uses data science to analyze the underlying mechanics of Monopoly (Classic Madrid Edition).

Using R, this project simulates **2,000,000 rolls** of a simplified Madrid
edition ruleset, including a jail state. It is an exploratory probability and
cash-flow study rather than a full multiplayer Monopoly simulator.

## Key Findings

The simulations examine:

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
*   **Survival Curve:** Simulation of how many independent landing steps opponents survive against each strategy.
*   **Board Skyline:** Visual representation of the economic value of each street.

## Technical Requirements

Use the [shared R environment](../RUNNING.md), including `tidyverse`. From this project directory, run:

```bash
Rscript Monopoly.R
```

The board parameters are defined in the script; no external dataset is required.

## Simulated rules and economic assumptions

Each observation is the final square after a dice roll and any chained card movement, including failed jail rolls. Doubles on release from jail do not start a new doubles streak. Cards are independent draws with replacement; held cards, optional early jail release, ownership, trades and bankruptcy feedback are omitted. The movement rules follow [Hasbro's classic instructions](https://www.hasbro.com/common/instruct/Monopoly.pdf), with these explicit simplifications.

Rent comparisons assume full colour-group ownership, uniform development and four owned stations. Utilities are excluded because their rent depends on dice and card context. Special card rent multipliers are omitted. Expected rent is per opponent roll, not per full turn; marginal group payback divides total extra investment by total extra expected rent. The survival scenario replaces individual street rents with their conditional mean and samples independent impacts; it is not a game trajectory.
