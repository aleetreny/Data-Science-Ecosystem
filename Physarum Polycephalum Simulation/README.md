# Physarum: Agent-Based Slime Mold Simulation

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![NumPy](https://img.shields.io/badge/NumPy-Vectorized-green)

## Overview

This project uses a simplified particle model inspired by *Physarum polycephalum* (Slime Mold). It is a study in **Emergence**: how complex, organic structures (like transport networks) arise from the interaction of thousands of simple, autonomous agents without a central brain.

Instead of programming the shapes directly, we programmed the *instincts* of individual particles. The macroscopic "organism" you see is a mathematical byproduct of these micro-interactions.

## The Hive Mind Logic

The simulation drives **5,000 autonomous agents** simultaneously using a sensory-motor loop inspired by real biological mechanisms:

1.  **Chemotaxis (Sensing):** Each agent has three forward-facing sensors (Left, Center, Right). They sample the environment for the "trail map" intensity (pheromones).
2.  **Steering (Decision):** The agent turns towards the strongest sensor signal. If no signal is found, it wanders randomly.
3.  **Deposition (Marking):** As agents move, they deposit a chemical trail into the environment.
4.  **Decay (Forgetting):** The global environment slowly evaporates the trails. Revisited trails persist longer; no route-efficiency objective is evaluated.

## Technical Architecture

The engine uses **Vectorized NumPy operations**:

* **Vectorized Agent Updates:** The positions, angles, and sensor readings of all 5,000 agents are calculated with array operations inside the time-stepping loop.
* **Toroidal Geometry:** The world wraps around the edges (Pac-Man style), allowing for infinite continuous movement.
* **Robust Rendering:** Writes 400 frames to a GIF and embeds it in the notebook. All frames are held in memory; Base64 adds size and does not bypass browser memory limits.

## The Result

Over time, the chaotic noise self-organizes. You will observe:
* **Phase 1 (Chaos):** Random steering and forward motion.
* **Phase 2 (Connection):** Agents find each other's trails and begin to merge.
* **Phase 3 (Pattern Formation):** Dense trails can form. The simulation does not calculate or verify shortest paths.

## Author

**Alejandro Treny Ortega**

---
*Inspired by the paper: "Characteristics of pattern formation and evolution in approximations of Physarum transport networks" by Jeff Jones.*
