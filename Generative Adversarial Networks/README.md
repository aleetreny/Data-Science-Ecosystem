# Project Genesis: Deep Convolutional GAN (DCGAN)

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![PyTorch](https://img.shields.io/badge/PyTorch-2.0%2B-orange)

> **"We are not teaching a machine to analyze; we are teaching it to create."**

## Overview

**Project Genesis** explores the frontier of **Generative Artificial Intelligence**. Unlike traditional classifiers that label data (e.g., "This is a 7"), this project builds an autonomous agent capable of "dreaming" handwritten digits from pure random noise.

Using a **Deep Convolutional Generative Adversarial Network (DCGAN)**, we set up a zero-sum game between two neural networks. The system can produce synthetic MNIST-like images; visual samples alone do not demonstrate indistinguishability, generalization, or convergence to a Nash equilibrium.

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

As training progresses, $D$ and $G$ may improve or destabilize one another. GAN losses and visual outputs must be interpreted as diagnostics rather than a proof of equilibrium.

## Technical Implementation

* **Engine:** PyTorch & Torchvision.
* **Dataset:** MNIST (Resized to 32x32 for architectural efficiency).
* **Optimization:**
    * **Loss:** Binary Cross Entropy (BCE).
    * **Optimizer:** Adam ($\alpha=0.0002$, $\beta_1=0.5$).
    * **Weights:** Initialized from a Normal Distribution ($\mu=0, \sigma=0.02$).
* **Hardware Efficiency:** Runtime depends on hardware and package versions; measure it locally rather than treating a fixed duration as a benchmark.

## Key Results

### 1. Training Dynamics (The Oscillating Loss)
Unlike standard deep learning, GAN loss does not converge to zero. Instead, it oscillates as the two networks fight.
* **D-Loss (Red):** The Detective learning to spot flaws.
* **G-Loss (Blue):** The Forger trying to deceive the Detective.

### 2. Latent Space Interpolation (Morphing)
Latent interpolation is a qualitative diagnostic. A smooth sequence is not, by itself, evidence that the model did not memorize training images.


## Author

**Alejandro Treny Ortega**
