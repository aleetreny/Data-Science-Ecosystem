# Hybrid Quantum Edge Classification for Particle Tracking

[Portfolio](../../README.md) · [Execution guide](../../RUNNING.md) · [Notebook](notebook.ipynb)

![Python](https://img.shields.io/badge/Python-3.12-green) ![Framework](https://img.shields.io/badge/Framework-PyTorch_Geometric_%7C_PennyLane-orange) ![Dataset](https://img.shields.io/badge/Dataset-CERN_TrackML-lightgrey)

## 1. Project Context: The HL-LHC Data Challenge

Dense particle-detector events motivate comparisons of methods for identifying compatible hits. This study uses one simulated TrackML event and a restricted geometric sector.

This project explores **Quantum Machine Learning (QML)** with a hybrid quantum-classical edge classifier. It is a small-scale simulation experiment, not evidence that QML improves particle tracking.

## 2. Methodology

### 2.1 Dataset and Preprocessing

We utilize the **TrackML Particle Tracking Challenge** dataset (Event 1000). To map the problem to a scale suitable for Quantum Simulation (NISQ era), we apply **Geometric Sectorization**:

-   **Region of Interest:** Central Barrel ($|z| < 400$ mm).
-   **Azimuthal Slice:** First Octant ($0 < \phi < \pi/4$).
-   **Physics cut:** Candidate construction uses only detector-hit geometry; simulated particle kinematics are not used as model features.

### 2.2 Graph Construction

The raw point cloud is converted into a directed graph $G=(V, E)$ based on physical constraints:

-   **Nodes** ($V$): Detector hits with features $(r, \phi, z)$.
-   **Edges** ($E$): Directed outward with $10 < \Delta r \leq 200$ mm, $|\Delta \phi / \Delta r| \leq 0.0008$ rad/mm and $|z_0| \leq 150$ mm. These are heuristic geometric cuts, not proof of momentum conservation.
-   **Graph Statistics:** The audited event sector has **5,370 nodes**, **397,982 candidate edges** and **4,150 positive edges** (1.04%). Edges sharing noise particle ID 0 are never labeled positive.

### 2.3 Hybrid Architecture

The model is an experimental **edge-pair classifier** that integrates a
Variational Quantum Circuit (VQC). It does not yet implement message passing,
so it is not presented as a graph neural network benchmark.

1.  **Classical Encoder:** Projects geometric features into a latent space.
2.  **Quantum Circuit:** A 4-qubit parameterized circuit using `StronglyEntanglingLayers` to capture non-linear correlations.
3.  **Normalization and Readout:** Batch normalization and a bounded angle transformation prepare circuit inputs; four Pauli-Z expectation values feed the final classical classifier.

## 3. Results

The notebook trains a classical edge classifier and a hybrid quantum edge
classifier on one TrackML event. It reports an edge-level held-out split,
which prevents scoring the exact optimized edges but is still not an
event-level generalisation metric. Edge batches are split before training-dependent edge normalization. Node normalization still uses the shared event nodes, and the models have different capacities and epoch budgets, so these numbers do not establish quantum advantage.

| Architecture | Held-out edge AUC |
|:-----------------------|:-----------------------|
| Classical edge classifier, 200 epochs | 0.5112 |
| Hybrid quantum edge classifier, 100 epochs | 0.7462 |

![Results Comparison](results_plot.png) *(Left: Binary Cross Entropy Loss. Right: Receiver Operating Characteristic comparing Quantum vs Classical performance)*

### Key Findings

1.  **Scope:** Held-out edges within one event can share nodes and local
    geometry with training edges, so their AUC is not a tracking performance metric.
2.  **Next validation:** Split by independent events and reserve simulation
    truth exclusively for labels.

## 4. Installation and Usage

### Prerequisites

-   Python 3.12 (see the [shared environment](../../RUNNING.md))
-   PyTorch & PyTorch Geometric
-   PennyLane (Quantum Simulator)
-   Pandas, NumPy, Matplotlib

### Execution

1.  Clone the repository.
2.  Ensure the `train_100_events` folder is present in this project directory, or set `TRACKML_DATA_DIR` to its location. You can download the `train_sample.zip` from Kaggle: [TrackML Dataset](https://www.kaggle.com/c/trackml-particle-tracking-challenge/data).
3.  Run all cells in [notebook.ipynb](notebook.ipynb) using the shared environment.
    -   **Step 1:** Loads and sectorizes the TrackML data.
    -   **Step 2:** Constructs the geometric graph.
    -   **Step 3:** Trains the Classical Benchmark.
    -   **Step 4-5:** Trains the Hybrid Quantum Model and compares results.

## 5. Future Roadmap

Possible extensions, each requiring independent evaluation:

-   **High-Dimensional Encoding:** Implement Amplitude Embedding to encode $2^N$ features into $N$ qubits.
-   **Hardware Deployment:** Port inference to IBM Q or IonQ hardware to test noise resilience.
-   **Equivariant Ansatz:** Design quantum circuits that inherently respect the cylindrical symmetry of the detector.

---

**Author:** Alejandro Treny

## Input provenance

Event 1000 hits and truth were recovered from the [author-maintained Qallse example](https://github.com/derlin/hepqpr-qallse/tree/8b43ac3b550b7cded7415fabb3cacf54302918f4/src/hepqpr/qallse/dsmaker/data). The audit records this immutable commit and file hashes. Simulation truth is used for edge labels; it is not included in predictor features.
