# Project Genesis: Deep Convolutional GAN (DCGAN)

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![PyTorch](https://img.shields.io/badge/PyTorch-2.0%2B-orange)

> **"We are not teaching a machine to analyze; we are teaching it to create."**

## Overview

**Project Genesis** explores the frontier of **Generative Artificial Intelligence**. Unlike traditional classifiers that label data (e.g., "This is a 7"), this project builds an autonomous agent capable of "dreaming" handwritten digits from pure random noise.

Using a **Deep Convolutional Generative Adversarial Network (DCGAN)**, we set up a zero-sum game between two neural networks. The system learns the underlying manifold of the MNIST dataset without explicit geometric rules, eventually producing synthetic images indistinguishable from human handwriting.

## The Concept: Adversarial Learning

The core of this project is a "Minimax Game" between two adversaries:

1.  **The Generator ($G$) - "The Forger":**
    * **Input:** A vector of 100 random numbers (Latent Space $z$).
    * **Goal:** To upsample that noise into a 32x32 pixel image that looks real.
    * **Architecture:** Transposed Convolutions + BatchNorm + ReLU.

2.  **The Discriminator ($D$) - "The Detective":**
    * **Input:** An image (either real from MNIST or fake from $G$).
    * **Goal:** To correctly classify images as Real (1) or Fake (0).
    * **Architecture:** Strided Convolutions + LeakyReLU + Sigmoid.

As training progresses, $D$ gets better at spotting fakes, forcing $G$ to create better fakes. This leads to a **Nash Equilibrium**.

## Technical Implementation

* **Engine:** PyTorch & Torchvision.
* **Dataset:** MNIST (Resized to 32x32 for architectural efficiency).
* **Optimization:**
    * **Loss:** Binary Cross Entropy (BCE).
    * **Optimizer:** Adam ($\alpha=0.0002$, $\beta_1=0.5$).
    * **Weights:** Initialized from a Normal Distribution ($\mu=0, \sigma=0.02$).
* **Hardware Efficiency:** The architecture (Lite-DCGAN) is optimized to train effectively on **standard CPUs** in under 30 minutes, making Generative AI accessible without high-end GPUs.

## Key Results

### 1. Training Dynamics (The Oscillating Loss)
Unlike standard deep learning, GAN loss does not converge to zero. Instead, it oscillates as the two networks fight.
* **D-Loss (Red):** The Detective learning to spot flaws.
* **G-Loss (Blue):** The Forger trying to deceive the Detective.

### 2. Latent Space Interpolation (Morphing)
To prove the model isn't just memorizing images, we performed a linear interpolation between two random points in the latent space ($z$).
* **Result:** We observe a smooth transition where one digit "mutates" into another (e.g., a "1" slowly curving into a "7"). This confirms the model has learned a continuous representation of the data structure.


## Author

**Alejandro Treny Ortega**
