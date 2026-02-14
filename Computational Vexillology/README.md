# Computational Vexillology

**Decoding National Aesthetics Through Data Science**

What if we could treat national flags not as art, but as high-dimensional data? This project converts 250 sovereign flags into mathematical fingerprints and asks whether the patterns in flag design reflect patterns in the real world, e.g. colonial history, geography, economics, and culture.

## Overview

The analysis proceeds in three stages:

1.  **Feature Extraction** — Each flag is converted into 19 numerical features across five families:

    -   **Color Palette** (8): red, blue, green, yellow, white, black percentages + warmth and coolness scores
    -   **Color Complexity** (3): palette complexity, color contrast (CIEDE2000), aggression index
    -   **Visual Complexity** (3): visual entropy, edge density, spatial entropy
    -   **Geometric Structure** (4): horizontal, vertical, diagonal dominance + symmetry score
    -   **Aspect Ratio** (1): width-to-height ratio

2.  **Structure Discovery** — Pairwise distances (Euclidean + Cosine on hand-crafted features, plus ResNet-50 deep learning embeddings) are fused and projected via UMAP into 2D. HDBSCAN identifies 12 stable clusters of visually similar flags.

3.  **Hypothesis Testing** — Flag clusters and features are correlated with external metadata (GDP, Gini, latitude, life expectancy, temperature, precipitation, sunshine hours) to test hypotheses about what drives flag design.

### Key Findings

-   **Colonial history is the dominant structuring force.** Unsupervised clustering recovers the footprint of the British, French, and Spanish empires with no geographic input.
-   **Wealth simplifies, inequality complicates.** GDP per capita and life expectancy correlate with flag simplicity (ρ ≈ 0.30–0.40). More unequal societies use more colors and higher contrast.
-   **Physical environment is a weak predictor.** Latitude has a moderate effect on warm tones (ρ ≈ −0.30), but forest cover, precipitation, and sunshine hours show null or negligible effects on flag design.

## Project Structure

```         
├── computational_vexillology.qmd   # Full analysis (single document, ~3700 lines)
├── nootebook.qmd                   # Part I: Feature extraction (standalone)
├── analysis.qmd                    # Part II: Distance, clustering, hypotheses (standalone)
├── data/
│   ├── flag_features.csv           # 250 × 21 feature matrix (code, name, 19 features)
│   ├── country_metadata.csv        # REST Countries API data (250 rows)
│   ├── extra_metadata.csv          # Climate + economic indicators (250 rows)
│   ├── flags_svg/                  # 250 SVG flag files (not in repo)
│   └── flags/                      # 250 PNG rasterized flags (not in repo)
└── .gitignore
```

The three `.qmd` files are [Quarto](https://quarto.org) documents that combine prose, code, and interactive Plotly visualizations. `computational_vexillology.qmd` is the complete analysis in a single document; `nootebook.qmd` and `analysis.qmd` are the original two-part versions.

## Reproducibility

### Requirements

-   Python 3.11+
-   [Quarto](https://quarto.org/docs/get-started/) CLI

### Python Dependencies

```         
numpy pandas matplotlib plotly cairosvg Pillow scikit-learn scipy
statsmodels umap-learn hdbscan torch torchvision itables requests
```

### Running

``` bash
# Render the full analysis to HTML
quarto render computational_vexillology.qmd

# Or render the two parts separately
quarto render nootebook.qmd
quarto render analysis.qmd
```

The first render will download 250 SVG flags from [flagcdn.com](https://flagcdn.com/) and call the [REST Countries API](https://restcountries.com/) and [Open-Meteo API](https://open-meteo.com/) for metadata. Subsequent renders use cached CSV files.

> **Note:** The rendered HTML files are self-contained (\~50–150 MB each due to embedded Plotly figures) and are not tracked in this repository. Render locally to view the interactive visualizations.

## Data Sources

| Source | What | License |
|-------------------------|-------------------|----------------------------|
| [flagcdn.com](https://flagcdn.com/) | SVG flag images | Public domain |
| [REST Countries](https://restcountries.com/) | Country metadata (region, subregion, population, area, Gini, lat/lng) | Open |
| [Open-Meteo](https://open-meteo.com/) | Climate data (temperature, precipitation, sunshine) | CC BY 4.0 |
| [World Bank](https://data.worldbank.org/) | GDP per capita, life expectancy, forest cover | CC BY 4.0 |

## Tech Stack

-   **Computer vision:** OpenCV, scikit-image, Pillow, CairoSVG
-   **Deep learning:** PyTorch + torchvision (ResNet-50 V2, pretrained on ImageNet)
-   **Dimensionality reduction:** UMAP
-   **Clustering:** HDBSCAN
-   **Statistics:** SciPy, statsmodels (Spearman, Kruskal-Wallis, chi-squared)
-   **Visualization:** Plotly (interactive), Matplotlib (static)
-   **Tables:** ITables (interactive DataTables)
-   **Document:** Quarto (literate programming)

## Author

**Alejandro Treny**

## License

This project is provided for educational and research purposes. The flag images are sourced from public domain collections. The code and analysis are released under the [MIT License](https://opensource.org/licenses/MIT).