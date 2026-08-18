# Project: Visual Steganography

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![Technique](https://img.shields.io/badge/Technique-LSB_Injection-red)

## Overview

**Ghost Protocol** is an educational digital steganography demonstration that embeds a low-bit-depth image payload in a carrier image. It does not encrypt the payload, authenticate it, or provide robust watermarking.

Using **Least Significant Bit (LSB)** modification, the algorithm alters a host image's pixel data. The alteration may be visually subtle under the demonstration conditions, but it remains detectable and is fragile under recompression, resizing, cropping and other transformations.

## The Science & Importance

In the cybersecurity landscape, this technique represents a double-edged sword:

This notebook is for studying the mechanics and limitations of LSB embedding. It is not a secure channel: use authenticated encryption for confidentiality and a purpose-built robust watermarking method when resistance to image transformations is required.

## Technical Implementation

The tool operates on the binary level of **NumPy** arrays:

* **Carrier Depth:** 8-bit per channel (Standard RGB).
* **Injection Method:** 2-bit Replacement (Stealth Mode).
    * The top 6 bits of the carrier are preserved (99% visual fidelity).
    * The secret image is compressed to 2 bits and grafted onto the carrier's noise floor.
* **Artifacts:** May be visible depending on the images and payload; can also be detected by statistical and learned steganalysis methods.
