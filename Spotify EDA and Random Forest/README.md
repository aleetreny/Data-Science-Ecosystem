# Spotify Audio Analytics: Evolution & Prediction

## Overview
This repository contains two exploratory projects: an EDA based on playlist,
metadata and derived lyric features, and a decade-classification notebook based
on a separately acquired Spotify/Kaggle dataset. It does not currently extract
or analyse Spotify audio features in the EDA notebook.

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

  * Playlist decade labels, album year and remaster/reissue discrepancies.
  * Metadata such as duration, popularity, explicit status and genre.
  * Derived lexical and sentiment metrics. Raw lyrics are deliberately not
    redistributed; API credentials are read from environment variables.

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
3.  Set `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET` and `GENIUS_TOKEN` in the
    environment only when API enrichment is required. Do not save credentials
    in a notebook or dataset. The decade-prediction source CSV is not bundled;
    obtain and version it separately before executing that notebook.
4.  Launch Jupyter Notebook:
    ```bash
    jupyter notebook
    ```
5.  Open the `.ipynb` file and run all cells.

-----

*Author: Alejandro Treny Ortega*  
*Data Source: Spotify API*
