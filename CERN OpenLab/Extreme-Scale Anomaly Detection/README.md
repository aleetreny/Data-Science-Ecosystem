# The Silicon Neuron: Extreme-Scale Anomaly Detection on FPGAs

![Python](https://img.shields.io/badge/python-3.12-blue) ![TensorFlow](https://img.shields.io/badge/tensorflow-2.16%2B-orange) ![Status](https://img.shields.io/badge/status-research_prototype-blue)

> **Context:** A research prototype that explores an autoencoder and low-precision arithmetic on simulated jet data. It is not a validated Level-1 Trigger implementation.

## Executive Summary

LHC bunch crossings occur at up to 40 MHz. The CMS Phase-2 trigger design specifies a Level-1 accept rate up to 750 kHz, a 12.5 microsecond latency budget and an HLT output around 7.5 kHz ([CMS trigger design](https://cds.cern.ch/record/2759072)). These are system design figures, not measurements of this notebook.

This project implements a **Deep Autoencoder** and a custom TensorFlow quantization experiment. The notebook is useful for studying the trade-off between reconstruction quality and reduced precision; FPGA synthesis, resource use, timing and physics performance must be measured independently before making deployment claims.

------------------------------------------------------------------------

## The Physics Challenge

The experiment trains an autoencoder on a synthetic background and uses reconstruction error as an anomaly score. Its inputs and cuts are a teaching example; it does not model a complete detector trigger.

### Simulation (Monte Carlo)

The notebook uses a deliberately simplified simulated sample:
* **Background:** Diffuse synthetic point clouds inspired by jet constituents.
* **Signal:** Synthetic three-prong point clouds; no boson decay or parton-shower generator is used.

![Jet Visualization](jet_viz.png) *(Diffuse synthetic background and structured synthetic signal.)*

------------------------------------------------------------------------

## Technical Architecture

### 1. Data Pipeline

-   **Input:** Raw particle kinematics ($p_T, \eta, \phi$).
-   **Preprocessing:** Top-50 selection by transverse momentum, log transformation of $p_T$, then scaling fitted only on training background. Validation and test events are separated before fitting preprocessing.

### 2. The Model (Autoencoder)

-   **Architecture:** Compressive bottleneck ($150 \to 8$ dimensions).
-   **Objective:** Minimize Mean Squared Error (MSE) on background events.

### 3. Custom Quantization Engine (The Core Innovation)

Standard libraries (like QKeras) often face compatibility issues with modern TensorFlow. I implemented a custom **`QuantizedDense` Layer** from first principles using the **Straight-Through Estimator (STE)**. 
* **Precision:** Six-bit weights/biases in hidden layers and eight-bit weights/biases in the output layer.
* **Range:** Six-bit integer codes are clipped to $[-32,31]$ and divided by 32; the final layer uses $[-128,127]/128$.
* **Scope:** Rounding uses a straight-through gradient estimator. Activations, accumulation and training remain floating point; TensorFlow is required.

### 4. Firmware Export Prototype

The project includes an experimental Python-to-C++ exporter for a `parameters.h` header. Exporting weights is not equivalent to a synthesizable or timing-closed firmware design; the generated header must be compiled and synthesized with the exact target configuration.

------------------------------------------------------------------------

## Validation status

The executed held-out toy-data evaluation gives baseline **AUC 0.9619** and weight-quantized **AUC 0.9606**. The ROC below is the baseline result; the quantized evaluation is printed separately in the notebook. These values do not establish real-physics sensitivity, firmware equivalence, hardware compression or latency.

![Baseline ROC on held-out synthetic events](roc_curve.png)

------------------------------------------------------------------------

## Future Roadmap (CERN)

If integrated into the CERN computing infrastructure, the following steps are proposed: 
1. **Hardware-in-the-Loop:** Compile and synthesize the exported design for a named target, then record timing, DSP/BRAM/LUT use, power and numerical equivalence.
2. **Pruning:** Evaluate pruning and measure its actual resource and accuracy effects.
3. **Graph Neural Networks:** Adapt the quantization engine for GNNs to better capture the non-Euclidean geometry of particle detectors.

------------------------------------------------------------------------

## Author

**Alejandro Treny Ortega**

## Reproduction

Use the shared [Python environment](../../RUNNING.md), then execute [notebook.ipynb](notebook.ipynb) from this folder. Synthetic inputs and model exports are generated locally.
