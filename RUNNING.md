# Ejecucion reproducible

Las versiones siguientes se probaron en macOS arm64 con Python 3.12 y R 4.5.
Los resultados de las notebooks se conservan dentro de los propios archivos
`.ipynb`; antes de regenerarlos, conserva una copia si quieres comparar una
ejecucion anterior.

## Python

```bash
python3.12 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/pip install -r requirements-python.txt
.venv/bin/python -m ipykernel install --user \
  --name data-science-ecosystem \
  --display-name "Python 3.12 (Data Science Ecosystem)"
.venv/bin/python scripts/verify_core_logic.py
```

Para regenerar una notebook, ejecuta por ejemplo:

```bash
.venv/bin/jupyter nbconvert --to notebook --execute --inplace \
  --ExecutePreprocessor.timeout=3600 "Deep Q-Trading/notebook.ipynb"
```

## R y Quarto

Instala R/Quarto y las dependencias del proyecto en un entorno aislado. Los
scripts requieren, entre otros, `tidyverse`, `caret`, `factoextra`, `smacof`,
`qgraph`, `OpenImageR`, `Rfast`, `naivebayes`, `uwot`, `patchwork` y `webshot2`.
Con el entorno activado se pueden comprobar scripts e informes así:

```bash
Rscript "Simulación Montecarlo Monopoly/Monopoly.R"
Rscript "PCA Kepler Dataset/Code.R"
quarto render "Matrix Chain Ordering Problem/notebook.qmd"
```

## Datos y credenciales que no se versionan

- RNA-Seq utiliza `data.csv` y `labels.csv` del directorio local homonimo.
- Quantum GNN necesita los eventos TrackML, que no forman parte del repositorio.
- Spotify Music Evolution requiere `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`
  y `GENIUS_TOKEN` como variables de entorno. No guardes tokens en notebooks,
  datasets ni commits; rota cualquier token que hubiera quedado expuesto.
- Gurobi necesita una licencia valida en la maquina que ejecute los notebooks de
  optimizacion.

Los ficheros descargados o generados durante ejecucion (pesos, HDF5, caches,
imágenes auxiliares y datasets de entrenamiento) no deben añadirse a Git salvo
que se revisen expresamente como datos fuente con licencia y procedencia claras.
