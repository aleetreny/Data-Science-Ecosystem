# Hybrid Quantum Graph Neural Networks for Particle Tracking

![Python](https://img.shields.io/badge/Python-3.10%2B-green) ![Framework](https://img.shields.io/badge/Framework-PyTorch_Geometric_%7C_PennyLane-orange) ![Dataset](https://img.shields.io/badge/Dataset-CERN_TrackML-lightgrey)

## 1. Project Context: The HL-LHC Data Challenge

The High-Luminosity Large Hadron Collider (HL-LHC) will operate with an average pile-up of $<\mu> \approx 200$, generating approximately 10,000 charged particles per bunch crossing. This density creates a combinatorial explosion in trajectory reconstruction, where traditional algorithms like the Kalman Filter scale quadratically or worse.

This project investigates **Quantum Machine Learning (QML)** as a potential solution. We implement a **Hybrid Quantum-Classical Graph Neural Network (QGNN)** that treats particle tracking as an edge-classification task, leveraging the high-dimensional expressibility of quantum circuits to identify true particle trajectories within a noisy detector environment.

## 2. Methodology

### 2.1 Dataset and Preprocessing

We utilize the **TrackML Particle Tracking Challenge** dataset (Event 1000). To map the problem to a scale suitable for Quantum Simulation (NISQ era), we apply **Geometric Sectorization**:

-   **Region of Interest:** Central Barrel ($|z| < 400$ mm).
-   **Azimuthal Slice:** First Octant ($0 < \phi < \pi/4$).
-   **Physics Cut:** Hard scattering events ($p_T > 1.0$ GeV).

### 2.2 Graph Construction

The raw point cloud is converted into a directed graph $G=(V, E)$ based on physical constraints:

-   **Nodes (**$V$): Detector hits with features $(r, \phi, z)$.
-   **Edges (**$E$): Constructed between hits that satisfy momentum conservation and vertex compatibility (e.g., $\Delta \phi / \Delta r < 0.0006$).
-   **Graph Statistics:** The resulting graphs typically contain \~800 nodes and \~10,000 edges with a signal purity of \~11%.

### 2.3 Hybrid Architecture

The model integrates a **Variational Quantum Circuit (VQC)** into a classical Interaction Network (GNN).

1.  **Classical Encoder:** Projects geometric features into a latent space.
2.  **Quantum Kernel:** A 4-qubit parameterized circuit using `StronglyEntanglingLayers` to capture non-linear correlations.
3.  **Optimization:** Implements **Batch Normalization** to stabilize quantum gradients and a **Multi-Qubit Readout** strategy to mitigate the information bottleneck.

## 3. Results

We trained both a purely Classical GNN and the Hybrid Quantum GNN on the sectorized real data.

| Architecture | AUC Score | Training Dynamics |
|:-----------------------|:-----------------------|:-----------------------|
| **Classical Interaction GNN** | **0.7501** | Stable convergence. |
| **Hybrid Quantum GNN** | **0.6426** | Rapid initial learning, high volatility. |

![Results Comparison](results_plot.png) *(Left: Binary Cross Entropy Loss. Right: Receiver Operating Characteristic comparing Quantum vs Classical performance)*

### Key Findings

1.  **Proof of Learning:** The Quantum model achieved an AUC of 0.64, significantly outperforming random guessing (0.50). This validates that geometric tracking features can be effectively mapped to and processed in the Hilbert space.
2.  **The NISQ Gap:** The performance difference demonstrates the trade-off between quantum expressibility and the difficulties of optimizing parameterized quantum circuits (Barren Plateaus) compared to mature classical baselines.

## 4. Installation and Usage

### Prerequisites

-   Python 3.10+
-   PyTorch & PyTorch Geometric
-   PennyLane (Quantum Simulator)
-   Pandas, NumPy, Matplotlib

### Execution

1.  Clone the repository.
2.  Ensure the `train_100_events` folder is present in the root directory. You can download the `train_sample.zip` from Kaggle: [TrackML Dataset](https://www.kaggle.com/c/trackml-particle-tracking-challenge/data).
3.  Run the Jupyter Notebook `quantum_tracking.ipynb`.
    -   **Step 1:** Loads and sectorizes the TrackML data.
    -   **Step 2:** Constructs the geometric graph.
    -   **Step 3:** Trains the Classical Benchmark.
    -   **Step 4-5:** Trains the Hybrid Quantum Model and compares results.

## 5. Future Roadmap

To achieve quantum advantage in future iterations:

-   **High-Dimensional Encoding:** Implement Amplitude Embedding to encode $2^N$ features into $N$ qubits.
-   **Hardware Deployment:** Port inference to IBM Q or IonQ hardware to test noise resilience.
-   **Equivariant Ansatz:** Design quantum circuits that inherently respect the cylindrical symmetry of the detector.

---

**Author:** Alejandro Treny 
