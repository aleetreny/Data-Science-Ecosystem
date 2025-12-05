# Spotify Audio Analytics: Evolution & Prediction

## Overview
This repository contains a comprehensive Data Science study on the evolution of music over the last century using Spotify's audio features. The project is divided into two main components: an **Exploratory Data Analysis (EDA)** on how music production has changed, and a **Machine Learning** system capable of predicting a song's release decade based solely on its audio signal.

## Repository Structure

The project is organized into two main directories:

```text
Spotify EDA and Random Forest/
│
├── music_evolution/              # Project 1: Exploratory Data Analysis
│   ├── music_evolution.ipynb     # Main analysis notebook
│   ├── dataset_final_completed.csv
│   ├── dataset_fixed.csv
│   └── dataset_music.csv
│
├── predict_decades/              # Project 2: Machine Learning Classification
│   ├── predict_decades.ipynb     # ML Training and Evaluation notebook
│
└── README.md
```

-----

## Project 1: Music Evolution (EDA)

**Location:** `/music_evolution`

### Objective

To visualize and understand the historical trends in music production and composition from the 1950s to the 2020s.

### Key Analysis

This notebook explores questions such as:

  * **The Loudness War:** Visualizing the steady increase in volume mastering over the decades.
  * **Technological Shifts:** Tracking the decline of `acousticness` and the rise of `energy` and electronic elements.
  * **Rhythmic Changes:** How `danceability` and `tempo` have fluctuated through different musical eras.
  * **Song Duration:** Analyzing the rise of long cuts in the 70s/80s and the return to shorter formats in the streaming era.

-----

## Project 2: Decade Prediction (Machine Learning)

**Location:** `/predict_decades`

### Objective

To build a classification model that predicts the release decade of a track using only technical audio features (no lyrics or metadata).

### Methodology

1.  **Data Preprocessing:**
      * Cleaning outliers (duration filtering).
      * Addressing Class Imbalance (Undersampling to approx 17k songs per decade).
      * Filtering data from 1940 to 2020.
2.  **Model:** Random Forest Classifier.
3.  **Feature Engineering:** Utilizing audio metrics like `loudness`, `acousticness`, `valence`, and `speechiness`.

### Results

  * **Exact Accuracy:** approx 40 percent (vs approx 11 percent random chance).
  * **Adjacent Accuracy:** approx 73 percent.
      * *Note: Adjacent Accuracy counts a prediction as correct if it falls within the exact decade or the immediate neighboring decades (±10 years), reflecting the continuous nature of musical evolution.*

### Key Insights

The model identified **`acousticness`** and **`loudness`** as the most critical features for determining a song's era, confirming that production technology is a stronger temporal marker than musical key or mode.

-----

## Tech Stack & Requirements

The projects are built using **Python** and the following data science libraries:

  * **Pandas:** Data manipulation and cleaning.
  * **NumPy:** Numerical operations.
  * **Matplotlib / Seaborn:** Advanced data visualization.
  * **Scikit learn:** Machine Learning (Random Forest, Splitting, Metrics).

## How to Run

1.  Clone this repository.
2.  Navigate to the desired folder (`music_evolution` or `predict_decades`).
3.  Ensure the `.csv` datasets listed in the structure above are present in the folder.
4.  Launch Jupyter Notebook:
    ```bash
    jupyter notebook
    ```
5.  Open the `.ipynb` file and run all cells.

-----

*Author: Alejandro Treny Ortega*  
*Data Source: Spotify API*
