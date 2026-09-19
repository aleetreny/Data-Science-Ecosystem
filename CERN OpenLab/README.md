# CERN Technical Application Portfolio

**Candidate:** Alejandro Treny Ortega\
**Focus:** Learning experiments inspired by triggering, simulation and tracking.

These three projects explore computing methods relevant to particle physics. Their evidence comes from the executed notebooks and the stated datasets; no FPGA timing result, event-level tracking performance or quantum advantage is claimed.

| Project | Implementation | Verified scope |
| :--- | :--- | :--- |
| [Extreme-Scale Anomaly Detection](./Extreme-Scale%20Anomaly%20Detection) | TensorFlow autoencoders, 6/8-bit weight quantization and parameter export | Held-out classification of synthetic jet-like point clouds; baseline AUC 0.9620 and quantized-weight AUC 0.9606 |
| [Neural Phase Integration](./Neural%20Phase%20Integration) | PyTorch affine coupling flows and defensive importance sampling | A known four-dimensional Gaussian-mixture integral on a fixed box, with independent evaluation seeds |
| [Quantum GNN Tracking](./Quantum%20GNN%20Tracking) | Classical and simulated quantum edge-pair classifiers | Held-out edges from one TrackML event; no message passing or independent-event evaluation |

The anomaly experiment exports quantized weights and biases, while activations and arithmetic remain floating point. Hardware synthesis and numerical equivalence would be separate work. The integration example includes training and discovery stages, so an estimator variance ratio is not an end-to-end speedup. Tracking splits share detector hits between training and test, making the comparison transductive.

Use the shared [execution instructions](../RUNNING.md) and each project’s README for inputs and limitations. The tested Python environment is 3.12 on macOS arm64. None of these projects requires an external account for its recorded evaluation once the TrackML event files have been obtained.
