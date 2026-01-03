# Physarum: Agent-Based Slime Mold Simulation

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![NumPy](https://img.shields.io/badge/NumPy-Vectorized-green)

## Overview

This project simulates the biological behavior of *Physarum polycephalum* (Slime Mold). It is a study in **Emergence**: how complex, organic structures (like transport networks) arise from the interaction of thousands of simple, autonomous agents without a central brain.

Instead of programming the shapes directly, we programmed the *instincts* of individual particles. The macroscopic "organism" you see is a mathematical byproduct of these micro-interactions.

## The Hive Mind Logic

The simulation drives **5,000+ autonomous agents** simultaneously using a sensory-motor loop inspired by real biological mechanisms:

1.  **Chemotaxis (Sensing):** Each agent has three forward-facing sensors (Left, Center, Right). They sample the environment for the "trail map" intensity (pheromones).
2.  **Steering (Decision):** The agent turns towards the strongest sensor signal. If no signal is found, it wanders randomly.
3.  **Deposition (Marking):** As agents move, they deposit a chemical trail into the environment.
4.  **Decay (Forgetting):** The global environment slowly evaporates the trails. This forces the colony to reinforce efficient routes and abandon useless ones.

## Technical Architecture

This is not a standard object-oriented simulation (which would be too slow). The engine is built on **Vectorized NumPy operations**:

* **Zero Loops:** The positions, angles, and sensor readings of all 5,000 agents are calculated in parallel using matrix operations.
* **Toroidal Geometry:** The world wraps around the edges (Pac-Man style), allowing for infinite continuous movement.
* **Robust Rendering:** Includes a custom rendering pipeline capable of generating high-resolution, long-duration GIFs by bypassing browser memory limits via direct file buffering and Base64 injection.

## The Result

Over time, the chaotic noise self-organizes. You will observe:
* **Phase 1 (Chaos):** Random exploration (Brownian motion).
* **Phase 2 (Connection):** Agents find each other's trails and begin to merge.
* **Phase 3 (Optimization):** Thick "highways" form. The system effectively solves the "Shortest Path" problem between random clusters.

## Author

**Alejandro Treny Ortega**

---
*Inspired by the paper: "Characteristics of pattern formation and evolution in approximations of Physarum transport networks" by Jeff Jones.*
