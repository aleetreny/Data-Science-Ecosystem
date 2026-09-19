# Ejecución reproducible

La auditoría del 19 de septiembre de 2026 utilizó macOS arm64, Python 3.12.14,
R 4.5.3 y Quarto 1.9.38. Las salidas de los notebooks se conservan en los propios
archivos. [AUDIT.md](AUDIT.md) registra cobertura, resultados y límites;
[data-manifest.json](data-manifest.json) identifica los datos utilizados mediante
SHA-256, tamaño y procedencia.

## Python

Desde la raíz del repositorio:

```bash
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements-python.txt -c constraints-python.txt
.venv/bin/python -m ipykernel install --user \
  --name data-science-ecosystem \
  --display-name "Python 3.12 (Data Science Ecosystem)"
.venv/bin/python -m pip check
.venv/bin/python scripts/verify_core_logic.py
.venv/bin/python scripts/verify_data.py
```

`requirements-python.txt` enumera las dependencias principales;
`constraints-python.txt` conserva las versiones instaladas, incluidas las
transitivas. Las restricciones corresponden al entorno probado; no constituyen
una prueba de compatibilidad con todos los sistemas operativos.

Para ejecutar un notebook completo y actualizar sus salidas:

```bash
OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 .venv/bin/jupyter nbconvert \
  --to notebook --execute --inplace \
  --ExecutePreprocessor.kernel_name=data-science-ecosystem \
  --ExecutePreprocessor.timeout=3600 "Deep Q-Trading/notebook.ipynb"
```

JupyterLab o la interfaz Notebook son opcionales; no son necesarios para este
comando. Las ejecuciones completas incluyen entrenamiento real y animaciones.
El clasificador cuántico y la neuroevolución pueden tardar varios minutos.

### NumPy en Apple Silicon

La rueda de NumPy 2.2.6 para macOS 14 con Accelerate produjo avisos numéricos
espurios en productos matriciales durante esta revisión. Se verificó la rueda
oficial `macosx_11_0_arm64` de la misma versión, que usa OpenBLAS. En Python 3.12
arm64, puede seleccionarse explícitamente después de instalar las dependencias:

```bash
.venv/bin/python -m pip download numpy==2.2.6 --only-binary=:all: --no-deps \
  --platform macosx_11_0_arm64 --python-version 312 --implementation cp \
  --abi cp312 --dest /tmp/dse-numpy-wheel
.venv/bin/python -m pip install --force-reinstall --no-deps \
  /tmp/dse-numpy-wheel/numpy-2.2.6-cp312-cp312-macosx_11_0_arm64.whl
.venv/bin/python scripts/verify_core_logic.py
```

El primer grupo de pruebas comprueba productos matriciales conocidos con los
avisos numéricos tratados como errores. No se silenciaron estos avisos para
considerar válidos los análisis. Contexto del proveedor: [incidencia NumPy
28687](https://github.com/numpy/numpy/issues/28687).

## R y Quarto

`requirements-r.tsv` registra las versiones de los paquetes directamente
utilizados por los scripts e informes. Instálalos en un entorno R aislado;
los paquetes que compilan código necesitan un compilador C/C++ y, según sus
dependencias, Fortran. La instalación y la resolución de dependencias transitivas
dependen del gestor de paquetes elegido.

Cada script que lee datos relativos debe iniciarse **dentro de su proyecto**:

```bash
(cd "EDA and Decision Tree" && Rscript analysis.R)
(cd "PCA Kepler Dataset" && Rscript Code.R)
(cd "MDS and Clustering Kepler Dataset" && Rscript Code.r)
(cd "Simulación Montecarlo Monopoly" && Rscript Monopoly.R)
(cd "Independent Component Analysis" && Rscript First_Approach.R)
(cd "Independent Component Analysis" && Rscript Second_Approach.R)
Rscript scripts/verify_r_logic.R
```

La búsqueda de proyecciones evalúa 64.800 direcciones. La segunda versión usa
la imagen completa y dos trabajadores por defecto; permite varias horas de
cálculo. Los ejemplos secuencial y paralelo usan distintas resoluciones y
reinicios de k-means, por lo que no constituyen una medida de aceleración paralela.

Para regenerar los informes, configura Quarto con el R de ese entorno y el
kernel Python registrado. Los PDF requieren TeX; se probaron con TinyTeX.

```bash
(cd "Classifying Dry Beans with Machine Learning" && quarto render notebook.qmd --to html)
(cd "Probabilistic Cancer Classification via RNA-Seq Data" && quarto render notebook.qmd --to html)
(cd "PCA Kepler Dataset" && quarto render Report.qmd --to html)
(cd "PCA Kepler Dataset" && quarto render Report.qmd --to pdf)
(cd "Matrix Chain Ordering Problem" && quarto render notebook.qmd --to html)
(cd "EDA and Decision Tree" && Rscript -e 'rmarkdown::render("report.Rmd", output_file="Student_Performance_Report.pdf")')
(cd "Optimization and Regression Modeling/Mixed Integer Linear Programming" && \
  quarto render Jupyter_resolution_report.ipynb --to pdf \
  --metadata-file report-format.yml --output Report.pdf)
```

Quarto renderiza el PDF MILP a partir de las salidas guardadas: ejecuta primero
el notebook si cambias datos o código. El PDF de PCA utiliza una proyección 2D
en lugar del gráfico 3D interactivo de HTML.

Matrix Chain informa si OpenMP está realmente activo. Para medir la versión
paralela se necesita un compilador con OpenMP y enlazar su runtime. La auditoría
usó `PKG_CXXFLAGS="-O3 -march=native -fopenmp"`, `PKG_LIBS="-fopenmp"`,
`OPENBLAS_NUM_THREADS=1` y `OMP_NUM_THREADS=4` dentro del entorno del compilador.
No se deben presentar mediciones de la alternativa secuencial como pruebas de
OpenMP. El Dockerfile es otra vía de instalación; su imagen no se construyó en
esta auditoría porque Docker no estaba instalado.

## Datos y acceso externo

Los archivos grandes se mantienen fuera de Git. `verify_data.py` comprueba los
que estén presentes e informa de los externos ausentes. Usa `--require-all`
para exigir las 20 instantáneas de la auditoría. Si utilizas variables de entorno
para apuntar a datos fuera del proyecto, compara sus hashes con el manifiesto o
crea enlaces locales en las rutas indicadas.

| Estudio | Datos y ejecución |
|---|---|
| Kepler, PCA y MDS | Cada proyecto incluye su `df_koi.csv`; ambas copias son idénticas. La fecha de la consulta original no está registrada. |
| Student Performance | `student_data.csv` incluido: 395 alumnos, asignatura de matemáticas, [UCI 320](https://archive.ics.uci.edu/dataset/320/student+performance). |
| Dry Beans | Descarga automática desde [UCI 602](https://archive.ics.uci.edu/dataset/602/dry+bean+dataset), o reutiliza `data/dry_beans.csv`. |
| RNA-Seq | `data.csv` y `labels.csv` de [UCI 401](https://archive.ics.uci.edu/dataset/401/gene+expression+cancer+rna+seq), en el proyecto o en `RNA_SEQ_DATA_DIR`. La auditoría recuperó las copias locales originales. |
| Spotify, predicción | `Predict_decades/data/tracks.csv`, o `SPOTIFY_TRACKS_CSV`; [Kaggle, versión 1](https://www.kaggle.com/datasets/yamaerenay/spotify-dataset-19212020-600k-tracks/versions/1). |
| Spotify, evolución | Los tres CSV derivados están incluidos. La ejecución normal no necesita API ni credenciales. El README explica la regeneración desde los textos originales y el enriquecimiento opcional con `MUSIC_REFRESH=1`. |
| Quantum Tracking | Los CSV de hits y truth del evento 1000, en `train_100_events` o `TRACKML_DATA_DIR`; enlaces a archivos de un commit fijo en el manifiesto y el README. |
| GAN | MNIST se descarga mediante torchvision y queda en `data/mnist`. |
| DQN | La serie BTC-USD se reutiliza desde `data/` o se descarga con yfinance. Una descarga futura puede reflejar revisiones del proveedor. |
| Steganography | Las dos fotografías se descargan desde las URL del notebook y se guardan como PNG en `data/`. |
| Proyecciones RGB | `Melanoma.jpg` incluido. No se ha podido verificar su procedencia ni su etiqueta clínica. |
| Resto | Datos sintéticos, parámetros del enunciado o el entorno de simulación indicado en cada notebook. |

Gurobi necesita acceso a una licencia que permita resolver estos modelos. La
licencia restringida disponible durante la auditoría fue suficiente para los
problemas incluidos. Las credenciales de Spotify/Genius solo son necesarias
para el enriquecimiento opcional; no se guardan en el repositorio.
