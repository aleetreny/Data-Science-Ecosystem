# Auditoría del repositorio — 19 de septiembre de 2026

Se revisaron los **18 directorios de proyectos**, que contienen **22 estudios** al
contar por separado los tres de CERN, los dos de optimización y los dos de Spotify.
El punto de partida fue `main` en `cf25068`, limpio y sincronizado con GitHub.
El inventario inicial comprendía 125 archivos versionados: 14 notebooks, cuatro
fuentes Quarto, seis scripts R, un R Markdown, documentación, datos y recursos de
los informes. Los dos enunciados PDF se conservaron como fuentes del problema.

La revisión contrastó código, supuestos, datos, resultados, texto y gráficos.
Se corrigieron fallos concretos conservando los métodos y objetivos de cada
proyecto. Los resultados siguientes proceden de ejecuciones reales, con los datos
completos que usa cada análisis y sus parámetros documentados. Las muestras que
forman parte del diseño original —por ejemplo, la selección de hits y el muestreo
para MDS— siguen identificadas como tales.

## Cobertura y resultados

| Estudio | Comprobación y correcciones principales | Resultado observado |
|---|---|---|
| CERN · Extreme-Scale Anomaly Detection | Separación antes del escalado; entrenamiento de fondo; cuantización de pesos y sesgos con gradiente recto y límites representables; tipos por capa en la exportación. Se aclaró que los jets son sintéticos. | Ejecución completa. AUC flotante **0,9619**, cuantizada **0,9606**. La exportación se comprueba numéricamente; no demuestra latencia FPGA. |
| CERN · Neural Phase Integration | Inversa y jacobiano del flujo; escalas acotadas; propuesta mixta con soporte en toda la caja; integral de referencia calculada sobre el dominio real. Se igualaron escalas y normalización de las figuras. | Ejecución completa y cinco semillas de evaluación. Integral de referencia **0,938437**; estimaciones entre **0,934995 y 0,949572**. |
| CERN · Quantum GNN Tracking | Evento 1000 recuperado de una revisión fija; unión de hits/truth por identificador; exclusión de `particle_id=0` como señal positiva; particiones de aristas disjuntas. Se identificó correctamente la referencia clásica como MLP de pares. | Entrenamiento completo sobre el grafo construido: **5.370 nodos y 397.982 aristas**. AUC cuántica **0,5112**, clásica **0,7462**. Es una evaluación transductiva con nodos compartidos. |
| Classifying Dry Beans | 13.611 registros originales; eliminación de 68 duplicados; escalado dentro de cada pliegue; elección de hiperparámetros con CV de entrenamiento; explicaciones Shapley aditivas; corrección de afirmaciones, etiquetas y expresiones del informe; carga única de Plotly compatible con KaTeX. | Los 49 bloques se ejecutan. Test de **2.709** observaciones: árbol **89,44 %**, KNN **91,77 %**, SVM lineal **91,92 %**, bosque **91,99 %**, MLP **92,17 %**, SVM RBF **92,36 %**. |
| Deep Q-Trading | Contabilidad de entrada, mantenimiento, reversión y cierre; costes coherentes; comparación con buy-and-hold en las mismas fechas; drawdown y exposición reales. | Entrenamiento y prueba completos. Retorno neto **−73,87 %**, frente a **+27,38 %** de buy-and-hold; drawdown **−84,08 %** frente a **−76,63 %**. No se presenta como estrategia rentable. |
| EDA and Decision Tree | Datos originales de 395 alumnos; comprobación de correlaciones, partición, métricas, clase positiva y referencia mayoritaria. R Markdown y PDF regenerados. | Test de 118 alumnos: accuracy **59,32 %**, referencia mayoritaria **66,95 %**, sensibilidad a suspensos **15,38 %**. Correlación de Spearman de ausencias con G3: **+0,0177**, prácticamente nula. |
| Epidemic Dynamics Simulation | Transiciones aleatorias, conservación de población, límites de probabilidades y comparación de escenarios en un horizonte común. Revisión de figuras y fotogramas de animación. | Notebook completo y pruebas de conservación superados. Los escenarios siguen siendo simulaciones bajo sus supuestos. |
| Generative Adversarial Networks | MNIST completo; inicialización de BatchNorm; inferencia con `eval()` y sin gradientes; prueba de que generar imágenes no modifica los buffers del modelo. | Entrenamiento real de **5 épocas sobre 60.000 imágenes** y revisión de muestras y animación. No se infiere calidad distributiva de unas pocas imágenes. |
| Independent Component Analysis | Correspondencia píxel/canal RGB, blanqueamiento, dirección del máximo, reconstrucción, orientación y proporción de imagen. Búsquedas de 64.800 direcciones. | Primera versión completa sobre **43.621 píxeles**. Segunda búsqueda completa sobre **694.564 píxeles**, con dos trabajadores; reconstrucción y gráficos verificados por separado según la nota técnica inferior. |
| MDS and Clustering Kepler | Distancias al cuadrado; corrección semidefinida positiva; raíz de Jaccard y vectores nulos; Hopkins; estabilidad con remuestreo; pruebas multivariantes y corrección de multiplicidad. | Ejecución completa de los análisis y 35 gráficos. Los cinco primeros ejes conservan **2,55 %** de la variabilidad corregida; cuatro conservan **2,16 %**. Las agrupaciones se describen como exploratorias. |
| Matrix Chain Ordering Problem | Validación de dimensiones y RPN; aritmética de costes; DP y reconstrucción; comparación exhaustiva de cadenas pequeñas; distinción entre coste escalar, aproximación de hardware y tiempo medido. | Los **69 bloques** se ejecutan con **OpenMP activo y cuatro hilos**. Coincidencia con enumeración exhaustiva para cadenas de 2 a 7 matrices y concordancia numérica de los productos. |
| Optimización · Linear Programming | Restricciones y solución cotejadas con el enunciado; dualidad y regresión por error absoluto contrastadas con HiGHS, independientemente de Gurobi; gráfico externo cotejado y encuadre 3D corregido. | Óptimo **660/13**, en **(40/13, 190/39)**. La regresión cumple la formulación de suma de errores absolutos. |
| Optimización · Mixed Integer Linear Programming | Activación implica producción positiva; costes fijos y tramos secuenciales; restricciones lógicas; escenarios de capacidad resueltos de nuevo. Formulación y PDF alineados con el código. | Óptimo **284**, producción **(36, 60, 0)**. Contraste por enumeración de las **226.981** ternas posibles y cinco escenarios de capacidad. Un recurso muy utilizado no implica por sí solo una expansión rentable. |
| PCA Kepler Dataset | Filas completas alineadas con etiquetas; diez entradas, ocho transformaciones logarítmicas, estandarización; cargas y correlaciones; pruebas Kruskal–Wallis con Holm. | Script y Quarto ejecutados sobre **7.994** filas completas de 8.054. Cuatro componentes retienen **86,65 %**. HTML y PDF regenerados; los grupos derivados de entradas no se presentan como validación independiente. |
| Physarum Polycephalum Simulation | Acumulación de depósitos cuando coinciden partículas, índices periódicos y difusión; revisión de animación real. | Ejecución completa de **400 fotogramas**, tres pasos por fotograma; prueba específica de depósitos coincidentes superada. |
| Probabilistic Cancer Classification via RNA-Seq | Unión de muestras y etiquetas; transformaciones y selección de dimensión dentro del entrenamiento; filtros de variables constantes; pruebas de etiquetas aleatorias; interpretación corregida. | Los **71 bloques** se ejecutan sobre **801 × 20.531** expresiones. Test de 159 muestras: LDA, QDA y logística **100 %**; Naive Bayes **97,48 %**. Control con etiquetas barajadas **28,93 %**, referencia mayoritaria **37,74 %**. No es validación clínica. |
| Simulación Montecarlo Monopoly | Reglas de cárcel, dobles consecutivos, movimiento al salir de cárcel y encadenamiento de cartas; distinción entre tiradas, turnos y pasos económicos. | Simulación de **2.000.000 de tiradas**, escenarios de supervivencia y pruebas deterministas de reglas superados. Cartas con reposición y alquileres simplificados siguen documentados. |
| Spotify · Music evolution | Ejecución normal desde CSV sin credenciales; recuperación local de los textos originales para recalcular métricas; palabras por minuto calculadas con duración en minutos; script de regeneración. | Tres CSV derivados comprobados. El conjunto final contiene **789 canciones**; **420** carecen de género identificado. La muestra de playlists no se presenta como representativa de toda la música. |
| Spotify · Predict decades | Dataset original recuperado, duplicados/etiquetas conflictivas controlados, preparación solo con entrenamiento y referencia aleatoria explícita. | Dataset fuente de **586.672 pistas**; muestra equilibrada de nueve décadas, con **28.865** casos de test. Bosque: **39,85 %** exacto y **73,04 %** dentro de ±1 década; referencias **11,11 %** y **30,86 %**. |
| Steganography | Validación de profundidad, capacidad y dimensiones; manejo de imágenes RGB; guardado y recarga sin pérdida. | Ejecución completa y recuperación de los bits retenidos en PNG para **profundidades 1 a 8**. |
| Stochastic Optimization via Neuroevolution | Aislamiento de semillas de entrenamiento, desarrollo y test; preservación de genotipos y elitismo; evaluación final independiente. | Evolución completa y **100 episodios de test**: recompensa media **−79,37**, IC aproximado del 95 % **[−104,49, −54,25]**. El resultado no se presenta como resolución satisfactoria de LunarLander. |
| Turing Patterns | Laplaciano periódico, paso temporal y estados finitos; eliminación de recortes que ocultaban inestabilidad; revisión de evolución visual. | Ejecución de **10.000 pasos**, con **21 estados guardados**; pruebas del operador y de detección de estados inválidos superadas. |

## Pruebas reutilizables y datos

[RUNNING.md](RUNNING.md) contiene los comandos y las dependencias del entorno
probado: macOS arm64, Python 3.12.14, R 4.5.3 y Quarto 1.9.38. Se conservan versiones
Python directas y transitivas y las versiones de paquetes R directamente usados.

- `scripts/verify_core_logic.py`: **12 grupos** de pruebas de comportamiento y
  artefactos. Incluye invariantes, casos límite, soluciones analíticas, solvers
  independientes, comprobación de precisión y ausencia de errores guardados en
  notebooks.
- `scripts/verify_r_logic.R`: **3 grupos** de pruebas independientes para reglas
  de Monopoly, distancias de MDS y blanqueamiento/reconstrucción RGB. Ejecuta las
  funciones extraídas de los scripts reales.
- `scripts/verify_data.py --require-all`: **20 instantáneas coincidentes, ninguna
  ausente y ningún hash discrepante** en el entorno de auditoría.
- `pip check`: sin conflictos de dependencias en el entorno probado.

[data-manifest.json](data-manifest.json) registra SHA-256, tamaño, procedencia y,
para los CSV, dimensiones. Las fuentes grandes permanecen fuera de Git y las
copias de otros proyectos se usaron como referencia. No se publican letras de
canciones ni credenciales. Los gráficos de README de CERN se extraen de las
salidas ejecutadas, y los informes versionados se actualizan desde sus fuentes.

La revisión visual incluyó las figuras de los análisis, páginas de PDF y
fotogramas iniciales, intermedios y finales de animaciones. En navegador se
comprobaron los informes HTML, sus imágenes, fórmulas, navegación y controles
interactivos disponibles. Los recursos de bibliotecas incluidos por Quarto se
verificaron como dependencias del informe; no se realizó una auditoría interna
de seguridad de cada biblioteca de terceros.

## Límites concretos de la comprobación

**ICA paralelo:** la búsqueda completa terminó y produjo sus tres direcciones.
La ejecución original falló posteriormente al leer el bloque de gráficos porque
el archivo se editó mientras R lo estaba leyendo. Se identificaron de forma
unívoca las direcciones ganadoras en las rejillas originales a partir de su
salida, se reconstruyó el resultado con las instrucciones actuales y se ejecutó
el bloque de gráficos por separado. Se verificaron ortogonalidad, dimensiones,
valores finitos, correspondencia píxel/canal y covarianza blanqueada (residuo
máximo **4,82 × 10⁻¹⁰**). Esto no equivale a afirmar que aquella invocación completa
de `Second_Approach.R` terminó con código cero. Los archivos actuales pasan el
análisis sintáctico y las pruebas de regresión.

**Procedencia:** no se pudo establecer la fuente ni la etiqueta clínica original
de `Melanoma.jpg`. Tampoco consta la fecha exacta de consulta del snapshot de
Kepler. Se conservan los archivos y sus hashes; no se inventa esa información.

**Plataformas y servicios:** no se construyó la imagen Docker porque Docker no
estaba instalado. No se sintetizó ni midió hardware FPGA, ni se ejecutó en un
ordenador cuántico. El enriquecimiento opcional de Spotify/Genius no se consultó
de nuevo: se comprobaron los datos disponibles y su regeneración local. La
licencia Gurobi disponible permitió resolver los modelos incluidos.

**Alcance estadístico:** una ejecución satisfactoria no acredita generalización
fuera de la muestra, causalidad, calibración clínica o rentabilidad futura.
Las estimaciones estocásticas y los tiempos pueden variar entre ejecuciones y
plataformas. Los resultados y pruebas documentados constituyen evidencia
reproducible de esta revisión, no una garantía matemática de ausencia de cualquier
error posible.
