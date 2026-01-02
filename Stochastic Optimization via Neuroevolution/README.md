# Stochastic Optimization of Control Policies via Neuroevolution

**Author:** Alejandro Treny Ortega

## Overview

This project explores **Neuroevolution** (Genetic Algorithms) as an alternative to standard Reinforcement Learning (DQN, PPO) for solving continuous state-space control problems.

Using the `LunarLander-v3` environment, we demonstrate that a simple Multi-Layer Perceptron (MLP) can be trained to near-perfect performance **without calculating a single gradient (Backpropagation)**. The project is structured as a scientific experiment, creating a narrative that moves from a naive evolutionary approach to a robust, multi-stage optimization pipeline.

**Final Result:** The agent achieved a robust average score of **288.94** (Theoretical max is ~300), with a 0% crash rate on unseen seeds.

---

## The Architecture

We treat the neural network weights as a genome ($\theta$) and optimize them using a population-based genetic algorithm.

* **Controller:** MLP (8 Input $\to$ 64 Hidden $\to$ 4 Output).
* **Activation:** Tanh (Hidden), Linear (Output).
* **Optimization:** Tournament Selection, Uniform Crossover, and Adaptive Gaussian Mutation.

---

## Experimental Pipeline (The 4 Phases)

This project implements a unique 4-phase training pipeline designed to overcome the common pitfall of **Overfitting in Evolutionary Algorithms**.

### Phase 1: Exploration (The Overfitting Trap)
* **Method:** Standard Genetic Algorithm with elitism evaluated on a fixed seed.
* **Outcome:** The agent achieved a high score of **267**, but validation revealed it was a "Paper Tiger" that had merely memorized the training terrain.
* **Reality Check:** The success rate on unseen maps was only **1%**.

### Phase 2: Robust Fine-Tuning
* **Method:** The evaluation metric was switched to **Monte Carlo Smoothing** ($K=3$ runs per agent) to penalize agents that relied on luck.
* **Outcome:** Performance initially collapsed to -1.09 as the "lucky" agents failed, but the population subsequently learned to generalize the underlying physics.
* **Result:** A stable, generalist score of ~128.

### Phase 3: Genetic Recycling (Escaping Local Optima)
* **Method:** To escape the local optimum of Phase 2, we applied **Targeted Gene Recycling**:
    1.  Preserved the elite agent.
    2.  Re-initialized 80% of the population to force diversity.
    3.  Subjected clones of the elite to massive mutation ($\sigma=0.5$).
* **Result:** This "explosive" step discovered a superior solution region, jumping to a score of **272.64**.

### Phase 4: Refined Local Exploitation
* **Method:** **Monoculture Initialization**. The population was filled with clones of the best agent and subjected to ultra-low mutation ($\sigma=0.002$).
* **Result:** This phase optimized fuel consumption and landing softness by fractions of a percent, reaching the final score of **288.94**.

---

## Key Results & Findings

### 1. Performance Comparison
The transition from Phase 1 to Phase 4 highlights the difference between memorization and true learning.

| Metric | Phase 1 (Naive) | Phase 4 (Final) | Improvement |
| :--- | :--- | :--- | :--- |
| **Best Score** | 267.31 (Unstable) | **288.94 (Robust)** | +8% |
| **Success Rate** | 1.0% | **100%** | +9900% |
| **Crash Rate** | 76.0% | **0.0%** | Solved |

### 2. The Geometry of Learning (t-SNE)
We visualized the high-dimensional evolutionary history ($\mathbb{R}^{836} \to \mathbb{R}^2$) using t-SNE. The plot reveals a distinct **"V-Shape" trajectory**:
* **The Detour:** The population did not move in a straight line; it first had to navigate around a region of poor fitness (crashing).
* **The Pivot:** A sharp turn at Generation 75 corresponds to the moment the evolutionary pressure shifted from "survival" (hovering) to "solving" (landing).
* **Convergence:** The trajectory ends in a dense cluster, indicating high genetic specialization.

### 3. Conclusion
We successfully solved a continuous control problem with a sparse reward signal without using Backpropagation. This highlights the potential of Evolutionary Strategies for tasks where the reward function is non-differentiable or sparse, provided that strict **Monte Carlo Validation** is used to prevent environmental overfitting.
