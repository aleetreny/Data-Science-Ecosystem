# Visual Steganography

[Portfolio](../README.md) · [Execution guide](../RUNNING.md) · [Notebook](notebook.ipynb)

![Python](https://img.shields.io/badge/Python-3.12-blue)
![Technique](https://img.shields.io/badge/Technique-LSB_Injection-red)

## Overview

**Ghost Protocol** is an educational digital steganography demonstration that embeds a low-bit-depth image payload in a carrier image. It does not encrypt the payload, authenticate it, or provide robust watermarking.

Using **Least Significant Bit (LSB)** modification, the algorithm alters a host image's pixel data. The alteration may be visually subtle under the demonstration conditions, but it remains detectable and is fragile under recompression, resizing, cropping and other transformations.

## Technical Implementation

The tool operates on the binary level of **NumPy** arrays:

* **Carrier Depth:** 8-bit per channel (Standard RGB).
* **Injection Method:** Configurable 1–8 bits per channel; the demonstration uses 2.
    * At 2-bit depth, the top 6 carrier bits are preserved and each 8-bit channel changes by at most 3.
    * Each secret colour channel is quantized to 2 bits and grafted onto the carrier's noise floor.
* **Artifacts:** May be visible depending on the images and payload; can also be detected by statistical and learned steganalysis methods.

## Running and verification

Use the [shared Python environment](../RUNNING.md) and execute [notebook.ipynb](notebook.ipynb). The loader reuses local PNG inputs or downloads the two example photographs into `data/`.

Carrier and payload must be nonempty `uint8` RGB arrays of the same shape. Save the combined image as PNG to preserve its bits. The verification suite checks embedding and extraction at every depth from 1 to 8, including a save/reload round trip. Recovery preserves the retained payload bits; discarded lower bits cannot be reconstructed.
