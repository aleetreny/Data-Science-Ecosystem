# Project: Visual Steganography

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![Technique](https://img.shields.io/badge/Technique-LSB_Injection-red)

## Overview

**Ghost Protocol** is a digital steganography tool capable of concealing high-resolution imagery inside innocent-looking "carrier" files. Unlike encryption, which scrambles data but screams "I have a secret," steganography hides the very existence of the secret.

Using the **Least Significant Bit (LSB)** modification technique, this algorithm performs microsurgery on the pixel data of a host image, injecting a payload into the bits that the human eye is biologically incapable of perceiving.

## The Science & Importance

In the cybersecurity landscape, this technique represents a double-edged sword:

1.  **Digital Watermarking (Defensive):** Used by corporations and stock photo agencies to embed invisible copyright signatures inside images. Even if an image is cropped or printed, the statistical noise remains.
2.  **Covert Communication (Offensive):** Used in "Dead Drop" operations where agents communicate by uploading innocent photos of cats or landscapes to public forums, containing hidden schematics or coordinates.
3.  **Malware Delivery:** Advanced persistent threats (APTs) use steganography to hide malicious code inside website icons, bypassing antivirus scanners that only look for executable files.

## Technical Implementation

The tool operates on the binary level of **NumPy** arrays:

* **Carrier Depth:** 8-bit per channel (Standard RGB).
* **Injection Method:** 2-bit Replacement (Stealth Mode).
    * The top 6 bits of the carrier are preserved (99% visual fidelity).
    * The secret image is compressed to 2 bits and grafted onto the carrier's noise floor.
* **Artifacts:** Imperceptible to the naked eye; detectable only via statistical analysis (histogram attacks).
