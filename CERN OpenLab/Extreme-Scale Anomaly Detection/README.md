# The Silicon Neuron: Extreme-Scale Anomaly Detection on FPGAs

![Python](https://img.shields.io/badge/python-3.10%2B-blue) ![TensorFlow](https://img.shields.io/badge/tensorflow-2.16%2B-orange) ![Status](https://img.shields.io/badge/status-research_prototype-blue)

> **Context:** A research prototype that explores an autoencoder and low-precision arithmetic on simulated jet data. It is not a validated Level-1 Trigger implementation.

## Executive Summary

The HL-LHC upgrade will increase collision rates to **40 MHz**, generating over **1 Petabyte of data per second**. Standard hardware triggers rely on hard-coded physics rules, potentially discarding evidence of unforeseen physics (Dark Matter, Long-Lived Particles).

This project implements a **Deep Autoencoder** and a custom TensorFlow quantization experiment. The notebook is useful for studying the trade-off between reconstruction quality and reduced precision; FPGA synthesis, resource use, timing and physics performance must be measured independently before making deployment claims.

------------------------------------------------------------------------

## The Physics Challenge

At the LHC, we cannot save every collision. We must filter 40,000,000 events down to \~1,000 per second. 
* **The Bottleneck:** The Level-1 Trigger (FPGA-based) has $< 1 \mu s$ to decide whether to keep an event.
* **The Strategy:** Train an unsupervised Autoencoder on Standard Model background (QCD jets). Events with high reconstruction error are flagged as "Anomalies."

### Simulation (Monte Carlo)

The notebook uses a deliberately simplified simulated sample:
* **Background:** QCD Dijets modeled with diffuse radiation patterns.
* **Signal:** Boosted $W'$ bosons decaying into collimated 3-prong substructures.

![Jet Visualization](jet_viz.png) *(Left: Diffuse QCD Background. Right: Structured Signal Anomaly)*

------------------------------------------------------------------------

## Technical Architecture

### 1. Data Pipeline

-   **Input:** Raw particle kinematics ($p_T, \eta, \phi$).
-   **Preprocessing:** Top-50 particle selection, Log-normalization, and Standard Scaling ($z$-score).

### 2. The Model (Autoencoder)

-   **Architecture:** Compressive bottleneck ($150 \to 8$ dimensions).
-   **Objective:** Minimize Mean Squared Error (MSE) on background events.

### 3. Custom Quantization Engine (The Core Innovation)

Standard libraries (like QKeras) often face compatibility issues with modern TensorFlow. I implemented a custom **`QuantizedDense` Layer** from first principles using the **Straight-Through Estimator (STE)**. 
* **Precision:** 6-bit Fixed Point (`ap_fixed<6,1>`).
* **Range:** $[-32, 31]$ integer mapping.
* **Constraint:** Zero-dependency implementation.

### 4. Firmware Export Prototype

The project includes an experimental Python-to-C++ exporter for a `parameters.h` header. Exporting weights is not equivalent to a synthesizable or timing-closed firmware design; the generated header must be compiled and synthesized with the exact target configuration.

------------------------------------------------------------------------

## Validation status

The figures in this repository are exploratory notebook outputs, not reproducible hardware benchmarks. In particular, the original comparison did not include a synthesis report, a target FPGA, fixed-point equivalence tests, a held-out physics sample, or uncertainty estimates. The only claims this repository supports are that the notebook defines a quantized-model experiment and an export prototype.

![ROC Curve](roc_curve.png) *(Archived exploratory plot. It must be regenerated on a held-out sample and paired with synthesis results before it is used as a performance claim.)*

------------------------------------------------------------------------

## Future Roadmap (CERN)

If integrated into the CERN computing infrastructure, the following steps are proposed: 
1. **Hardware-in-the-Loop:** Compile and synthesize the exported design for a named target, then record timing, DSP/BRAM/LUT use, power and numerical equivalence.
2. **Pruning:** Implement unstructured pruning to reduce DSP usage by an estimated 40%.
3. **Graph Neural Networks:** Adapt the quantization engine for GNNs to better capture the non-Euclidean geometry of particle detectors.

------------------------------------------------------------------------

## Author

**Alejandro Treny Ortega**
