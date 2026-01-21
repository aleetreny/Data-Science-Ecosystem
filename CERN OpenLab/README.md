# CERN OpenLab Summer Student Programme Portfolio

**Candidate:** Alejandro Treny Ortega
**Focus:** Advanced Computing Architectures for the High-Luminosity LHC (HL-LHC)

![Python](https://img.shields.io/badge/Python-3.10%2B-blue) ![PyTorch](https://img.shields.io/badge/PyTorch-Deep_Learning-orange) ![QML](https://img.shields.io/badge/Quantum-PennyLane-purple) ![FPGA](https://img.shields.io/badge/Hardware-Vivado_HLS-green)

## Summary

This repository aggregates three technical projects developed to demonstrate technical competency for the **CERN OpenLab Summer Student Programme**. 

The High-Luminosity LHC (HL-LHC) upgrade presents a dual challenge: a massive increase in data rates (1 Petabyte/s) and a combinatorial explosion in complexity. These projects address three specific bottlenecks of the HL-LHC computing model—**Triggering, Simulation, and Tracking**—by leveraging novel computing paradigms:

1.  **Edge AI / FPGA:** Ultra-low latency anomaly detection.
2.  **Generative AI:** Accelerating phase-space integration via Normalizing Flows.
3.  **Quantum Computing:** Combinatorial optimization for particle tracking.

---

## Project Overview

| Project Scope | Title & Link | Technology Stack | Key Achievement |
| :--- | :--- | :--- | :--- |
| **L1 Trigger** | [**The Silicon Neuron**](./Extreme-Scale%20Anomaly%20Detection) | TensorFlow, Vivado HLS | Achieved **< 1 $\mu s$ latency** using a custom 6-bit quantization engine on FPGA. |
| **Simulation** | [**Neural Importance Sampling**](./Neural%20Phase%20Integration) | PyTorch, Bijective Flows | Reduced statistical error by **orders of magnitude** using Normalizing Flows. |
| **Reconstruction** | [**Hybrid Quantum GNNs**](./Quantum%20GNN%20Tracking) | PyTorch Geometric, PennyLane | Applied **Quantum GNNs** to solve combinatorial tracking in high pile-up ($\mu \approx 200$). |

> *Please navigate to the sub-folders linked above for the full source code (Jupyter Notebooks) and detailed technical documentation for each project.*

---

## Technical Deep Dive

### 1. The Trigger Challenge (Hardware)
**Goal:** Detect New Physics in the Level-1 Trigger within strict microsecond latency budgets.
* **Problem:** Standard deep learning models are too slow/heavy for L1 FPGAs.
* **Solution:** Implemented a Deep Autoencoder with a **custom "straight-through estimator" quantization layer**, compressing the model to 6-bit integers without using external quantization libraries.
* **Impact:** 5.3x memory compression with 81% bandwidth reduction and zero physics performance degradation.

### 2. The Simulation Challenge (Algorithm)
**Goal:** Efficiently calculate scattering cross-sections.
* **Problem:** The "Curse of Dimensionality" makes uniform Monte Carlo integration inefficient for complex matrix elements.
* **Solution:** Utilized **Bijective Normalizing Flows** (Affine Coupling Layers) to learn the exact topology of the multi-modal phase space, creating a perfect proposal distribution for importance sampling.
* **Impact:** Drastic reduction in variance (**~24,500x**) and successful recovery of narrow signal resonances missed by baseline methods.

### 3. The Tracking Challenge (Quantum)
**Goal:** Disentangle particle trajectories in the HL-LHC inner tracker.
* **Problem:** Traditional Kalman Filters scale quadratically; HL-LHC pile-up makes this computationally prohibitive.
* **Solution:** Formulated tracking as a graph classification problem. Implemented a **Hybrid Quantum-Classical Graph Neural Network (QGNN)** to leverage the high-dimensional expressibility of Hilbert space for edge classification.
* **Impact:** Demonstrated the viability of Quantum Machine Learning (NISQ era) for geometric deep learning tasks.

---

## Installation & Reproduction

Each sub-directory contains its own `README.md` and `notebook.ipynb` with specific instructions. However, the general environment requirements across all projects include:

* **Language:** Python 3.10+
* **Core Libraries:** `numpy`, `pandas`, `matplotlib`
* **Deep Learning:** `torch`, `tensorflow`, `torch_geometric`
* **Quantum:** `pennylane`
* **Hardware (Optional):** Xilinx Vivado HLS (for synthesis of Project 1)
