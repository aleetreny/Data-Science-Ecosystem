# Deep Q-Trading: Algorithmic Speculation via Reinforcement Learning

## Overview

This project explores the application of **Deep Reinforcement Learning (DRL)** to financial markets, specifically Bitcoin (BTC/USD) trading. Unlike traditional algorithmic trading strategies that rely on hard-coded heuristics (e.g., "buy if RSI < 30"), this project trains a DQN policy by interacting with a simplified historical trading environment. Optimality is not established.

Using the **Deep Q-Network (DQN)** architecture, the project explores a
non-stationary cryptocurrency environment. It is a research prototype, not an
investment strategy or evidence of outperformance.

## The Challenge: Non-Stationarity

Financial markets represent a higher order of complexity compared to physical control problems (like Inverted Pendulum or LunarLander).
* **Physics is constant:** Gravity does not change from one episode to the next.
* **Markets are chaotic:** The statistical properties of financial data (mean, variance) shift over time. A strategy that is profitable in a bull market may be disastrous in a bear market.

**Objective:** Evaluate a learned policy on a later chronological BTC/USD interval.

## Methodology

### 1. The Environment
* **Engine:** `Gym-Anytrading` (Custom Wrapper).
* **Action Space:** Discrete `{Short, Long}`.
* **Observation Space:** A rolling window of the last 30 days.
* **Feature Engineering:** The raw price data is augmented with technical indicators to provide context to the neural network:
    * **RSI (Relative Strength Index):** To detect overbought/oversold conditions.
    * **MACD (Moving Average Convergence Divergence):** To identify momentum changes.

### 2. The Model: Deep Q-Network (DQN)
We utilize a value-based method where a Neural Network approximates the Q-Function $Q(s, a)$, predicting the expected future reward of taking action $a$ in state $s$.

* **Architecture:** MLP (Input[270] -> Dense[128] -> Dense[128] -> Output[2]).
* **Optimization:** Adam Optimizer with Huber Loss (Smooth L1).
* **Stabilization Mechanisms:**
    * **Experience Replay Buffer:** Stores 10,000 past transitions to break temporal correlations in training data.
    * **Target Network:** A frozen copy of the weights is used to calculate target Q-values, preventing oscillation during learning.

### 3. Validation Strategy (The "Time-Travel" Test)
The dataset is split chronologically, and feature scaling is fitted on training observations. This addresses look-ahead in preprocessing; it does not guarantee generalization:
* **Training Set (In-Sample):** 2015 – 2020. The agent learns from this historical data.
* **Testing Set (Out-of-Sample):** 2021–2023. The 30-day lookback makes the scored price interval 31 January 2021 through 31 December 2023.

## Results

The executed policy produces **-73.87% net return**, compared with **+27.38%** for buy-and-hold over the same tradable dates. Maximum drawdowns are **84.08%** and **76.63%**, respectively. These results show underperformance on this split, not alpha or reliable regime adaptation.

Both comparisons charge 10 basis points at entry and exit. The DQN additionally pays on position changes; moving directly between short and long entails two transaction sides. An action based on observations through time t applies to the following price return. Wealth and log reward use the same accounting.

Short exposure is modeled as a simplified one-times daily return, not inverse price return. The simulation omits spread, slippage, financing and the cost of daily exposure rebalancing. A single trained seed and one chronological split do not quantify robustness.

## Reproduction

Use the [shared Python environment](../RUNNING.md), then execute [notebook.ipynb](notebook.ipynb) from this directory. The loader uses a local cached BTC-USD series or fetches the fixed 2015–2023 interval with yfinance. RSI and MACD are computed causally from prior prices.

**Author:** Alejandro Treny Ortega
