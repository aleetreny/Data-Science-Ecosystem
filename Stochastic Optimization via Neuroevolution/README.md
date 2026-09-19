# Stochastic Optimization of Control Policies via Neuroevolution

**Author:** Alejandro Treny Ortega

## Overview

This project explores **Neuroevolution** (Genetic Algorithms) as an alternative to standard Reinforcement Learning (DQN, PPO) for solving continuous state-space control problems.

The `LunarLander-v3` experiment optimizes an MLP without backpropagation. It executes a fixed four-phase evolutionary schedule, separates development seeds from final test seeds and reports a 500-step-horizon evaluation. The final policy does **not** solve the task on the held-out seed set.

---

## The Architecture

We treat the neural network weights as a genome ($\theta$) and optimize them using a population-based genetic algorithm.

* **Controller:** MLP (8 Input $\to$ 64 Hidden $\to$ 4 Output).
* **Activation:** Tanh (Hidden), Linear (Output).
* **Optimization:** Tournament Selection, Uniform Crossover, and Adaptive Gaussian Mutation.

---

## Experimental Pipeline (The 4 Phases)

The population size is 100 throughout. Phase 1 uses 100 generations on training seed 1337. Phase 2 uses 30 generations and the same three training seeds for each candidate. Phase 3 runs 20 generations after retaining the elite and introducing random individuals and strongly mutated copies. Phase 4 runs 15 generations from elite clones with mutation standard deviation 0.002.

Common training seeds make candidate comparisons consistent. Development seeds are used for diagnostics, while seeds 30000–30099 are reserved for the final evaluation. All phases use the same 500-step limit. The single-seed Phase 1 best training reward is **277.46**; the final multi-seed training score is about **251.18**. Those scores use different objectives and are not directly comparable improvements.

---

## Exploratory results

The final test over 100 reserved seeds gives:

| Metric | Result |
| :--- | ---: |
| Mean episode reward | -79.37 |
| Approximate 95% interval for mean reward | [-104.49, -54.25] |
| Episodes with reward > 200 | 5% |
| Episodes with reward < -100 | 43% |

Reward thresholds are score categories, not independently inspected landing/crash labels. The interval summarizes evaluation-seed variability for one trained policy; it does not cover variation across independent evolutionary training runs.

The t-SNE plot visualizes saved genomes from the 836-parameter network. It cannot establish a fitness-landscape topology, causal learning stages or a generation at which landing was learned. Frame animations provide qualitative development-seed examples; the final numerical evaluation uses separate seeds.

## Reproduction

Use the [shared Python environment](../RUNNING.md), including `gymnasium[box2d]`, and execute [notebook.ipynb](notebook.ipynb) from this directory. Evaluation renders into notebook animations without opening native game windows.
