#  Análisis Estadístico y Estratégico del Monopoly (Ed. Madrid)

> Un estudio de probabilidad y economía del juego utilizando simulaciones de Monte Carlo en R.

![R](https://img.shields.io/badge/R-4.0%2B-blue)
![Tidyverse](https://img.shields.io/badge/Main_Lib-Tidyverse-orange)
![Status](https://img.shields.io/badge/Status-Completado-green)

##  Sobre el Proyecto

Este proyecto utiliza la ciencia de datos para analizar las mecánicas subyacentes del Monopoly (Edición Clásica Madrid).

A través de R, he modelado las reglas físicas y económicas del juego para simular **2.000.000 de tiradas**. El objetivo no es solo calcular probabilidades, sino entender la eficiencia del capital y desarrollar una estrategia ganadora basada en datos objetivos, respondiendo a preguntas como: ¿Qué calles son las más rentables? ¿Cuántas casas debo construir para maximizar el retorno?

##  Conclusiones Principales

Los datos arrojados por la simulación revelan patrones claros:

1.  **El Dominio del Naranja:** Debido a la alta frecuencia de salida desde la Cárcel, el grupo Naranja (Felipe II, Velázquez, Serrano) es estadísticamente la zona más visitada del tablero. Ofrece la mejor relación coste-beneficio.
2.  **La Estrategia de las 3 Casas:** El análisis de ROI indica que la tercera casa representa el punto óptimo de inversión. A partir de ahí, el retorno marginal disminuye y el riesgo de iliquidez aumenta.
3.  **Velocidad vs. Fuerza:** Aunque el grupo Verde cobra alquileres más altos, el Naranja provoca bancarrotas más rápido debido a su frecuencia de impacto. En una partida competitiva, la velocidad de retorno es clave.

##  Visualizaciones Generadas

El script `Monopoly.R` genera una serie de gráficos para visualizar estos hallazgos:

* **Heatmap de Frecuencia:** Probabilidad de caída por casilla.
* **Curva de Rentabilidad:** Análisis de *break-even* según el número de casas (1-4 y Hotel).
* **Matriz de Eficiencia:** Comparativa de Inversión vs. Retorno Esperado.
* **Perfil de Riesgo:** Clasificación de propiedades por Frecuencia vs. Daño (Impacto).
* **Curva de Supervivencia:** Simulación de cuántos turnos aguantan los rivales contra cada estrategia.
* **Skyline del Tablero:** Representación visual del valor económico de cada calle.

##  Requisitos Técnicos

El proyecto está desarrollado en **R**. Necesitarás tener instalados los siguientes paquetes:

* `tidyverse` (para manipulación de datos y gráficos con ggplot2).
* `parallel` (opcional, si deseas paralelizar la simulación).

Instalación rápida:
```r
install.packages("tidyverse")
