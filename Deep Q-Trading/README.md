# Deep Q-Trading: Algorithmic Speculation via Reinforcement Learning

## Overview

This project explores the application of **Deep Reinforcement Learning (DRL)** to financial markets, specifically Bitcoin (BTC/USD) trading. Unlike traditional algorithmic trading strategies that rely on hard-coded heuristics (e.g., "buy if RSI < 30"), this project trains an autonomous agent to discover its own optimal strategy solely through trial and error.

Using the **Deep Q-Network (DQN)** architecture, the project explores a
non-stationary cryptocurrency environment. It is a research prototype, not an
investment strategy or evidence of outperformance.

## The Challenge: Non-Stationarity

Financial markets represent a higher order of complexity compared to physical control problems (like Inverted Pendulum or LunarLander).
* **Physics is constant:** Gravity does not change from one episode to the next.
* **Markets are chaotic:** The statistical properties of financial data (mean, variance) shift over time. A strategy that is profitable in a bull market may be disastrous in a bear market.

**Objective:** To train an agent capable of generalizing profitable patterns across different market regimes (Bull, Bear, and Sideways trends).

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
To strictly prevent overfitting (look-ahead bias), the dataset is split chronologically:
* **Training Set (In-Sample):** 2015 – 2020. The agent learns from this historical data.
* **Testing Set (Out-of-Sample):** 2021 through the final downloaded bar. The
  exact end date is recorded by the notebook at runtime rather than inferred
  from the calendar year.

## Results

The historical notebook output compared environment reward with a price change.
Those are different quantities in `gym-anytrading`, so its dollar figures and
percentage uplift are not a valid strategy comparison. A valid evaluation must
use final portfolio value/return in the same units for agent and buy-and-hold,
with transaction costs, slippage, drawdown and walk-forward splits.

### Key Findings
1.  **Prototype behaviour:** Action frequencies only show that the trained policy
    selected both actions in this environment; they do not establish profitable
    shorting.
2.  **Evaluation requirement:** Claims of alpha or regime adaptation require
    identical net-return accounting and repeated, chronologically separated
    walk-forward tests.
3.  **Risk requirement:** Report costs, slippage, maximum drawdown and
    uncertainty across seeds before drawing financial conclusions.

*Note: Due to floating-point arithmetic differences between CPU and GPU architectures, exact profit figures may vary slightly across different hardware, but the general performance trend is consistent.*

**Author:** Alejandro Treny Ortega
