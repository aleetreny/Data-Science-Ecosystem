# Deep Q-Trading: Algorithmic Speculation via Reinforcement Learning

**Author:** Alejandro Treny Ortega

## Overview

This project explores the application of **Deep Reinforcement Learning (DRL)** to financial markets, specifically Bitcoin (BTC/USD) trading. Unlike traditional algorithmic trading strategies that rely on hard-coded heuristics (e.g., "buy if RSI < 30"), this project trains an autonomous agent to discover its own optimal strategy solely through trial and error.

Using the **Deep Q-Network (DQN)** architecture, the agent learns to navigate the non-stationary and adversarial environment of cryptocurrency markets, achieving a performance that significantly outperforms the "Buy & Hold" benchmark on unseen data.

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
* **Testing Set (Out-of-Sample):** 2021 – 2024. The agent is evaluated on this unseen future data, which includes the 2021 Bull Run and the 2022 Crypto Winter.

## Results

The model was evaluated against the standard market benchmark: the **Buy & Hold** strategy (buying BTC on day 1 of the test set and holding until the end).

| Metric | Buy & Hold Strategy | Deep Q-Trading Agent | Difference |
| :--- | :--- | :--- | :--- |
| **Total Profit** | $12,891.04 | **$68,876.06** | **+434.29%** |
| **Activity** | Passive (1 Trade) | Active (52.1% Long / 47.9% Short) | High Frequency |

### Key Findings
1.  **Alpha Generation:** The agent successfully extracted "Alpha" (excess return) from the market volatility. While the market provided a base return of ~$12k, the agent generated an additional ~$56k through active trading.
2.  **Regime Adaptation:** The agent maintained profitability during the 2022 market crash, demonstrating that it learned to profit from downward trends (Shorting) rather than just riding upward momentum.
3.  **Active Management:** The buy/sell ratio (approx. 50/50) indicates the agent did not degenerate into a trivial "Always Buy" policy, but actively managed its exposure.

## Reproducibility

This project enforces strict seeding for scientific reproducibility.
* **Seed:** `2024`
* **Libraries:** `PyTorch`, `Gym-Anytrading`, `Pandas-TA`.

*Note: Due to floating-point arithmetic differences between CPU and GPU architectures, exact profit figures may vary slightly across different hardware, but the general performance trend is consistent.*
