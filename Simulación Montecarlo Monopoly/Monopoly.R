# ==============================================================================
# PROYECTO: ANÁLISIS ESTADÍSTICO Y ECONÓMICO DE MONOPOLY (ED. MADRID)
# FASE 1: DEFINICIÓN DE PARÁMETROS Y ESTRUCTURA DE DATOS
# ==============================================================================

library(tidyverse)

# ------------------------------------------------------------------------------
# 1. DEFINICIÓN DE VECTORES DE DATOS
# ------------------------------------------------------------------------------
# Se definen las propiedades del tablero mediante vectores individuales para facilitar
# la lectura y modificación de precios según las reglas oficiales.

# Índices y Nombres (Edición Clásica Madrid)
# El ID 1 corresponde a la Salida. El ID 11 es la visita de Cárcel. El ID 31 es "Ir a la Cárcel".
id <- 1:40
nombre <- c(
  "Salida", "Ronda de Valencia", "Caja de Comunidad", "Plaza Lavapiés", "Impuesto Capital", "Estación de Goya", "Gta. Cuatro Caminos", "Suerte", "Av. Reina Victoria", "Calle Bravo Murillo",
  "Cárcel", "Glorieta de Bilbao", "Cía de Electricidad", "Calle Alberto Aguilera", "Calle Fuencarral", "Estación de las Delicias", "Av. Felipe II", "Caja de Comunidad", "Calle Velázquez", "Calle Serrano",
  "Parking Gratuito", "Av. de América", "Suerte", "Calle María de Molina", "Calle Cea Bermúdez", "Estación del Mediodía", "Av. Reyes Católicos", "Calle Bailén", "Canal de Isabel II", "Plaza de España",
  "Ir a la Cárcel", "Puerta del Sol", "Calle Alcalá", "Caja de Comunidad", "Gran Vía", "Estación del Norte", "Suerte", "Paseo de la Castellana", "Impuesto de Lujo", "Paseo del Prado"
)

# Grupos de Color (Categorización)
# Se utiliza NA para casillas no comprables (Impuestos, Suerte, Caja, Esquinas).
# Las Estaciones se agrupan como "Negro" y los Servicios como "Blanco" para análisis comparativo.
grupo <- c(
  NA, "Marron", NA, "Marron", NA, "Negro", "Azul_Claro", NA, "Azul_Claro", "Azul_Claro",
  NA, "Rosa", "Blanco", "Rosa", "Rosa", "Negro", "Naranja", NA, "Naranja", "Naranja",
  NA, "Rojo", NA, "Rojo", "Rojo", "Negro", "Amarillo", "Amarillo", "Blanco", "Amarillo",
  NA, "Verde", "Verde", NA, "Verde", "Negro", NA, "Azul_Oscuro", NA, "Azul_Oscuro"
)

# Tamaño del Grupo (Monopolio)
# Indica cuántas propiedades son necesarias para completar el grupo y poder edificar.
tamano_grupo <- c(
  0, 2, 0, 2, 0, 4, 3, 0, 3, 3,
  0, 3, 2, 3, 3, 4, 3, 0, 3, 3,
  0, 3, 0, 3, 3, 4, 3, 3, 2, 3,
  0, 3, 3, 0, 3, 4, 0, 2, 0, 2
)

# Costes de Inversión
# precio_compra: Coste de adquisición del título de propiedad.
# precio_edificar: Coste unitario por cada casa o por la conversión a Hotel.
# Nota: El precio de edificar varía según el lateral del tablero (50, 100, 150, 200).
precio_compra <- c(
  0, 60, 0, 60, 0, 200, 100, 0, 100, 120,
  0, 140, 150, 140, 160, 200, 180, 0, 180, 200,
  0, 220, 0, 220, 240, 200, 260, 260, 150, 280,
  0, 300, 300, 0, 320, 200, 0, 350, 0, 400
)

precio_edificar <- c(
  0, 50, 0, 50, 0, 0, 50, 0, 50, 50,
  0, 100, 0, 100, 100, 0, 100, 0, 100, 100,
  0, 150, 0, 150, 150, 0, 150, 150, 0, 150,
  0, 200, 200, 0, 200, 0, 0, 200, 0, 200
)

# ------------------------------------------------------------------------------
# 2. DEFINICIÓN DE ALQUILERES (MATRIZ DE RENTABILIDAD)
# ------------------------------------------------------------------------------
# Se definen los alquileres para diferentes estados de desarrollo.
# NOTA METODOLÓGICA PARA ESTACIONES:
# Las estaciones no tienen casas. Para permitir la comparación directa en el dataframe,
# se mapean sus alquileres escalados a las columnas de casas de la siguiente forma:
# - alq_base    = Alquiler con 1 estación
# - alq_1_casa  = Alquiler con 2 estaciones
# - alq_2_casas = Alquiler con 3 estaciones
# - alq_3_casas = Alquiler con 4 estaciones

alq_base <- c(
  0, 2, 0, 4, 0, 25, 6, 0, 6, 8,
  0, 10, 0, 10, 12, 25, 14, 0, 14, 16,
  0, 18, 0, 18, 20, 25, 22, 22, 0, 24,
  0, 26, 26, 0, 28, 25, 0, 35, 0, 50
)

alq_1_casa <- c(
  0, 10, 0, 20, 0, 50, 30, 0, 30, 40,      # Estación -> 50 (Valor por tener 2)
  0, 50, 0, 50, 60, 50, 70, 0, 70, 80,
  0, 90, 0, 90, 100, 50, 110, 110, 0, 120,
  0, 130, 130, 0, 150, 50, 0, 175, 0, 200
)

alq_2_casas <- c(
  0, 30, 0, 60, 0, 100, 90, 0, 90, 100,    # Estación -> 100 (Valor por tener 3)
  0, 150, 0, 150, 180, 100, 200, 0, 200, 220,
  0, 250, 0, 250, 300, 100, 330, 330, 0, 360,
  0, 390, 390, 0, 450, 100, 0, 500, 0, 600
)

alq_3_casas <- c(
  0, 90, 0, 180, 0, 200, 270, 0, 270, 300, # Estación -> 200 (Valor por tener 4)
  0, 450, 0, 450, 500, 200, 550, 0, 550, 600,
  0, 700, 0, 700, 750, 200, 800, 800, 0, 850,
  0, 900, 900, 0, 1000, 200, 0, 1100, 0, 1400
)

alq_4_casas <- c(
  0, 160, 0, 320, 0, 0, 400, 0, 400, 450,
  0, 625, 0, 625, 700, 0, 750, 0, 750, 800,
  0, 875, 0, 875, 925, 0, 975, 975, 0, 1025,
  0, 1100, 1100, 0, 1200, 0, 0, 1300, 0, 1700
)

alq_hotel <- c(
  0, 250, 0, 450, 0, 0, 550, 0, 550, 600,
  0, 750, 0, 750, 900, 0, 950, 0, 950, 1000,
  0, 1050, 0, 1050, 1100, 0, 1150, 1150, 0, 1200,
  0, 1275, 1275, 0, 1400, 0, 0, 1500, 0, 2000
)

# ------------------------------------------------------------------------------
# 3. CONSTRUCCIÓN Y ENRIQUECIMIENTO DEL DATAFRAME MAESTRO
# ------------------------------------------------------------------------------

tablero <- data.frame(
  id, nombre, grupo, tamano_grupo,
  precio_compra, precio_edificar,
  alq_base, alq_1_casa, alq_2_casas, alq_3_casas, alq_4_casas, alq_hotel
) %>%
  mutate(
    # Variable lógica para facilitar filtrado de casillas comprables
    es_comprable = !is.na(grupo),

    # Cálculo automático del valor de hipoteca (Regla oficial: 50% del precio de compra)
    valor_hipoteca = precio_compra / 2,

    # Cálculo del alquiler por Monopolio (sin edificar)
    # Regla: Si se posee todo el grupo de color sin casas, la renta base se duplica.
    # Excepción: Estaciones y Servicios no siguen la regla del doble, siguen su propia tabla.
    alq_monopolio = ifelse(grupo %in% c("Negro", "Blanco"), alq_base, alq_base * 2),

    # Factorización del Grupo para asegurar orden cronológico en visualizaciones futuras
    # (Evita orden alfabético por defecto de R)
    grupo = factor(grupo, levels = c(
      "Marron", "Azul_Claro", "Rosa", "Naranja",
      "Rojo", "Amarillo", "Verde", "Azul_Oscuro",
      "Negro", "Blanco"
    ))
  )

# ------------------------------------------------------------------------------
# 4. VERIFICACIÓN DE DATOS
# ------------------------------------------------------------------------------
# Visualización de las primeras filas para confirmar estructura correcta.
head(tablero)


# ==============================================================================
# FASE 2: MOTOR DE SIMULACIÓN ESTOCÁSTICA
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. LÓGICA DE TARJETAS Y MOVIMIENTO RELATIVO
# ------------------------------------------------------------------------------

# Función auxiliar para movimiento hacia el siguiente destino (Estaciones/Servicios)
encontrar_siguiente <- function(actual, destinos) {
  siguientes <- destinos[destinos > actual]
  if (length(siguientes) > 0) return(min(siguientes))
  return(min(destinos))
}

# Lógica de Cartas 'Suerte'
# Gestiona las 10 cartas que implican desplazamiento de la ficha.
procesar_suerte <- function(pos_actual) {
  carta <- sample(1:16, 1)

  # IDs de referencia en el tablero
  estaciones <- c(6, 16, 26, 36)
  servicios <- c(13, 29)

  if (carta == 1) return(1)   # Salida
  if (carta == 2) return(25)  # Calle Cea Bermúdez
  if (carta == 3) return(12)  # Glorieta de Bilbao
  if (carta == 4) return(encontrar_siguiente(pos_actual, servicios))
  if (carta == 5 || carta == 6) return(encontrar_siguiente(pos_actual, estaciones))
  if (carta == 7) return(6)   # Estación de Goya
  if (carta == 8) return(40)  # Paseo del Prado
  if (carta == 9) return(11)  # Ir a la Cárcel (Físico: 11)

  if (carta == 10) { # Retrocede 3 casillas
    nueva <- pos_actual - 3
    if (nueva < 1) nueva <- nueva + 40
    return(nueva)
  }

  return(pos_actual)
}

# Lógica de Cartas 'Caja de Comunidad'
procesar_caja <- function(pos_actual) {
  carta <- sample(1:16, 1)
  if (carta == 1) return(1)   # Salida
  if (carta == 2) return(11)  # Ir a la Cárcel
  return(pos_actual)
}

# ------------------------------------------------------------------------------
# 2. ALGORITMO DE SIMULACIÓN (CADENAS DE MARKOV MONTE CARLO)
# ------------------------------------------------------------------------------

simular_monopoly <- function(n_turnos) {

  posicion <- 1
  conteo_dobles <- 0
  historial <- numeric(40) # Vector para el recuento absoluto de caídas

  for (i in 1:n_turnos) {

    # Lanzamiento de dados
    d1 <- sample(1:6, 1)
    d2 <- sample(1:6, 1)
    suma <- d1 + d2
    es_doble <- (d1 == d2)

    # Regla de velocidad (3 dobles consecutivos)
    if (es_doble) {
      conteo_dobles <- conteo_dobles + 1
    } else {
      conteo_dobles <- 0
    }

    if (conteo_dobles == 3) {
      posicion <- 11 # Encarcelamiento inmediato
      conteo_dobles <- 0
      historial[posicion] <- historial[posicion] + 1
      next
    }

    # Movimiento estándar
    posicion <- posicion + suma
    if (posicion > 40) posicion <- posicion - 40

    # Resolución recursiva de casilla (Efecto dominó de cartas)
    ficha_estable <- FALSE
    while (!ficha_estable) {
      ficha_estable <- TRUE

      # Casilla 31: Ir a la Cárcel
      if (posicion == 31) {
        posicion <- 11
        ficha_estable <- TRUE
      }
      # Casillas de Suerte (8, 23, 37)
      else if (posicion %in% c(8, 23, 37)) {
        nueva_pos <- procesar_suerte(posicion)
        if (nueva_pos != posicion) {
          posicion <- nueva_pos
          ficha_estable <- FALSE
        }
      }
      # Casillas de Caja de Comunidad (3, 18, 34)
      else if (posicion %in% c(3, 18, 34)) {
        nueva_pos <- procesar_caja(posicion)
        if (nueva_pos != posicion) {
          posicion <- nueva_pos
          ficha_estable <- FALSE
        }
      }
    }

    # Registro del evento
    historial[posicion] <- historial[posicion] + 1
  }

  return(historial)
}

# ------------------------------------------------------------------------------
# 3. EJECUCIÓN Y PROCESAMIENTO DE DATOS
# ------------------------------------------------------------------------------

# Parámetros de ejecución
N_TURNOS <- 2000000
set.seed(42) # Semilla fijada para reproducibilidad exacta

# Ejecución de la simulación
visitas_raw <- simular_monopoly(N_TURNOS)

# Integración en el dataframe maestro
# Se incluye 'conteo' (número absoluto de caídas) y 'probabilidad' (porcentaje)
tablero_resultados <- tablero %>%
  mutate(
    conteo = visitas_raw,
    probabilidad = (visitas_raw / N_TURNOS) * 100
  ) %>%
  arrange(desc(probabilidad))

# Muestra de validación con las 10 casillas más frecuentes
print(head(tablero_resultados %>% select(nombre, grupo, conteo, probabilidad), 10))



# ==============================================================================
# FASE 3: ANÁLISIS ECONÓMICO Y VISUALIZACIÓN
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CÁLCULO DE MÉTRICAS FINANCIERAS (ROI Y ESPERANZA MATEMÁTICA)
# ------------------------------------------------------------------------------

# Para determinar la rentabilidad real, no basta con el precio de alquiler.
# Se debe ponderar el alquiler por la frecuencia de visita.
# Métrica Clave: "Valor Esperado por Turno" (Expected Value per Turn - EV)
# Fórmula: EV = Alquiler * (Probabilidad / 100)

analisis_financiero <- tablero_resultados %>%
  filter(es_comprable) %>% # Descartamos casillas no comprables (Impuestos, etc)
  mutate(
    # ESCENARIO: ESTRATEGIA DE 3 CASAS (Punto óptimo de inversión en Monopoly)
    # Nota: Para estaciones, la columna 'alq_3_casas' representa tener las 4 estaciones.

    # 1. Coste Total de la Inversión (Compra del terreno + 3 Edificaciones)
    inversion_total = precio_compra + (3 * precio_edificar),

    # 2. Retorno Esperado por cada tirada de un oponente
    retorno_esperado_turno = alq_3_casas * (probabilidad / 100),

    # 3. Ratio de Eficiencia (ROI)
    # Interpretación: Porcentaje de la inversión recuperada en cada turno promedio.
    # Un valor más alto indica una recuperación de capital más rápida.
    ratio_eficiencia = (retorno_esperado_turno / inversion_total) * 100
  )

# ------------------------------------------------------------------------------
# 2. AGRUPACIÓN POR COLOR (ANÁLISIS DE CARTERA)
# ------------------------------------------------------------------------------
# En Monopoly, la unidad estratégica mínima es el grupo de color, no la calle individual.

ranking_colores <- analisis_financiero %>%
  group_by(grupo) %>%
  summarise(
    # Coste para adquirir y desarrollar el monopolio completo
    coste_grupo_completo = sum(inversion_total),

    # Dinero total que se espera ganar por turno con el grupo completo
    retorno_grupo_esperado = sum(retorno_esperado_turno),

    # Probabilidad acumulada de que un rival caiga en CUALQUIER casilla del grupo
    probabilidad_grupo = sum(probabilidad),

    # Eficiencia global del color
    eficiencia_global = (retorno_grupo_esperado / coste_grupo_completo) * 100
  ) %>%
  arrange(desc(eficiencia_global)) %>%
  # Filtramos Servicios (Blanco) si su valor es 0 o no relevante para estrategia de casas
  filter(retorno_grupo_esperado > 0)

# Visualización de tabla de resultados financieros
print(ranking_colores)

# ------------------------------------------------------------------------------
# 3. VISUALIZACIÓN 1: PROBABILIDAD DE VISITA (EL MAPA DE CALOR)
# ------------------------------------------------------------------------------
# Gráfico que muestra dónde caen los jugadores con mayor frecuencia.

g1 <- ggplot(analisis_financiero, aes(x = reorder(nombre, probabilidad), y = probabilidad, fill = grupo)) +
  geom_col(color = "black", alpha = 0.8) +
  coord_flip() +
  scale_fill_manual(values = c(
    "Marron" = "#8B4513", "Azul_Claro" = "#87CEEB", "Rosa" = "#FF69B4",
    "Naranja" = "#FFA500", "Rojo" = "#FF0000", "Amarillo" = "#FFFF00",
    "Verde" = "#008000", "Azul_Oscuro" = "#00008B", "Negro" = "#333333",
    "Blanco" = "#A0A0A0"
  )) +
  labs(
    title = "Frecuencia de Visita por Propiedad (Simulación Monte Carlo)",
    subtitle = "Probabilidad calculada tras 2.000.000 de tiradas",
    x = NULL,
    y = "Probabilidad de Caída (%)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(g1)

# ------------------------------------------------------------------------------
# 4. VISUALIZACIÓN 2: EFICIENCIA ECONÓMICA (EL ROI)
# ------------------------------------------------------------------------------
# Gráfico que cruza coste vs. beneficio. Muestra la "velocidad" de recuperación de dinero.

g2 <- ggplot(ranking_colores, aes(x = reorder(grupo, eficiencia_global), y = eficiencia_global, fill = grupo)) +
  geom_col(color = "black", width = 0.7) +
  geom_text(aes(label = round(eficiencia_global, 2)), hjust = -0.2, size = 3.5) +
  scale_fill_manual(values = c(
    "Marron" = "#8B4513", "Azul_Claro" = "#87CEEB", "Rosa" = "#FF69B4",
    "Naranja" = "#FFA500", "Rojo" = "#FF0000", "Amarillo" = "#FFFF00",
    "Verde" = "#008000", "Azul_Oscuro" = "#00008B", "Negro" = "#333333",
    "Blanco" = "#A0A0A0"
  )) +
  coord_flip() +
  labs(
    title = "Retorno de Inversión (ROI) por Grupo de Color",
    subtitle = "Eficiencia basada en estrategia de 3 Casas (o 4 Estaciones)",
    x = "Grupo de Propiedades",
    y = "Índice de Eficiencia (% recuperado por turno)",
    caption = "Nota: El grupo Naranja maximiza el ROI debido a su posición estratégica post-Cárcel."
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(g2)


# ------------------------------------------------------------------------------
# 5. VISUALIZACIÓN 3: LA CURVA DE ESTRATEGIA INMOBILIARIA
# ------------------------------------------------------------------------------

# 1. PREPARACIÓN DE DATOS
datos_casas <- tablero_resultados %>%
  filter(es_comprable, !grupo %in% c("Negro", "Blanco")) %>%
  select(nombre, grupo, precio_compra, precio_edificar, probabilidad,
         alq_base, alq_1_casa, alq_2_casas, alq_3_casas, alq_4_casas, alq_hotel) %>%
  pivot_longer(
    cols = starts_with("alq_"),
    names_to = "nivel_casa",
    values_to = "alquiler"
  ) %>%
  mutate(
    num_casas = case_when(
      nivel_casa == "alq_base" ~ 0,
      nivel_casa == "alq_1_casa" ~ 1,
      nivel_casa == "alq_2_casas" ~ 2,
      nivel_casa == "alq_3_casas" ~ 3,
      nivel_casa == "alq_4_casas" ~ 4,
      nivel_casa == "alq_hotel" ~ 5
    ),
    inversion_acumulada = precio_compra + (num_casas * precio_edificar),
    retorno_esperado = alquiler * (probabilidad / 100),
    turnos_recuperacion = ifelse(retorno_esperado > 0, inversion_acumulada / retorno_esperado, NA)
  )

# Agrupamos por color
resumen_estrategia <- datos_casas %>%
  group_by(grupo, num_casas) %>%
  summarise(
    turnos_promedio = mean(turnos_recuperacion, na.rm = TRUE),
    .groups = "drop"
  )

# 2. VISUALIZACIÓN OPTIMIZADA (FACET WRAP)
# Separamos cada color para ver su curva individualmente sin solapamientos.

g3 <- ggplot(resumen_estrategia, aes(x = num_casas, y = turnos_promedio, group = grupo)) +
  # Usamos geom_ribbon o area para resaltar la "zona de coste" bajo la curva
  geom_area(aes(fill = grupo), alpha = 0.4) +
  geom_line(aes(color = grupo), linewidth = 1.2) +
  geom_point(aes(color = grupo), size = 2) +

  # Separación por paneles
  facet_wrap(~grupo, nrow = 2) +

  # Colores oficiales
  scale_fill_manual(values = c(
    "Marron" = "#8B4513", "Azul_Claro" = "#87CEEB", "Rosa" = "#FF69B4",
    "Naranja" = "#FFA500", "Rojo" = "#FF0000", "Amarillo" = "#DBDB00",
    "Verde" = "#008000", "Azul_Oscuro" = "#00008B"
  )) +
  scale_color_manual(values = c(
    "Marron" = "#8B4513", "Azul_Claro" = "#87CEEB", "Rosa" = "#FF69B4",
    "Naranja" = "#FFA500", "Rojo" = "#FF0000", "Amarillo" = "#DBDB00",
    "Verde" = "#008000", "Azul_Oscuro" = "#00008B"
  )) +

  # Ajustes de Ejes
  scale_x_continuous(breaks = 0:5, labels = c("0", "1", "2", "3", "4", "H")) +
  # Limitamos el eje Y para eliminar el ruido de las casillas vacías (que tienen valores muy altos)
  # y centrarnos en la decisión de construcción (0 a 150 turnos es lo interesante)
  coord_cartesian(ylim = c(0, 150)) +

  labs(
    title = "Curva de Rentabilidad: El 'Punto Dulce' de las 3 Casas",
    subtitle = "Turnos para recuperar inversión. Cuanto más baja la curva, más rápido ganas dinero.",
    x = "Nivel de Edificación (H = Hotel)",
    y = "Turnos Promedio (Break-Even)",
    caption = "Nota: Observa cómo la mayoría de curvas tocan fondo en la 3ª casa."
  ) +
  theme_minimal() +
  theme(
    legend.position = "none", 
    strip.text = element_text(face = "bold", size = 10), 
    panel.spacing = unit(1, "lines")
  )

print(g3)

# ==============================================================================
# FASE 4: ANÁLISIS ESTRATÉGICO AVANZADO (RIESGO VS RECOMPENSA)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. ANÁLISIS DE EFICIENCIA DE CAPITAL
# ------------------------------------------------------------------------------
# Objetivo: Identificar propiedades con bajo coste de entrada y alto retorno.
# Se asume el escenario estándar de competición: Objetivo de 3 CASAS.

analisis_cuadrante <- tablero_resultados %>%
  filter(es_comprable, !grupo %in% c("Negro", "Blanco")) %>% # Solo calles de color
  group_by(grupo) %>%
  summarise(
    # Eje X: Capital Total Necesario (Comprar todas las calles del grupo + Poner 3 casas en cada una)
    capital_total_3casas = sum(precio_compra + (3 * precio_edificar)),

    # Eje Y: Retorno Esperado Total del Grupo (Suma de los Ev de cada calle)
    retorno_esperado_total = sum(alq_3_casas * (probabilidad / 100)),

    # Etiqueta para el gráfico
    nombre_grupo = first(grupo)
  )

# Visualización 4: Scatter Plot (Inversión vs Retorno)
# Buscamos grupos en el cuadrante superior izquierdo (Bajo coste, Alto retorno).

g4 <- ggplot(analisis_cuadrante, aes(x = capital_total_3casas, y = retorno_esperado_total)) +
  # Líneas de referencia (Promedios)
  geom_vline(xintercept = mean(analisis_cuadrante$capital_total_3casas), linetype = "dashed", color = "grey") +
  geom_hline(yintercept = mean(analisis_cuadrante$retorno_esperado_total), linetype = "dashed", color = "grey") +

  # Puntos principales
  geom_point(aes(color = grupo), size = 6, alpha = 0.8) +

  # Etiquetas de texto
  geom_text(aes(label = grupo), vjust = -1.2, fontface = "bold", size = 3.5) +

  scale_color_manual(values = c(
    "Marron" = "#8B4513", "Azul_Claro" = "#87CEEB", "Rosa" = "#FF69B4",
    "Naranja" = "#FFA500", "Rojo" = "#FF0000", "Amarillo" = "#DBDB00",
    "Verde" = "#008000", "Azul_Oscuro" = "#00008B"
  )) +

  scale_x_continuous(
    labels = scales::dollar_format(prefix = "€", suffix = ""),
    expand = expansion(mult = c(0.1, 0.2))
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.1, 0.2))
  ) +

  labs(
    title = "Matriz de Eficiencia de Capital",
    subtitle = "Comparativa: Coste de Desarrollo (3 casas) vs. Retorno Esperado",
    x = "Capital Total Necesario",
    y = "Retorno Esperado por Turno (Ev)",
    caption = "Estrategia Óptima: Grupos en la zona superior izquierda."
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(g4)


# ------------------------------------------------------------------------------
# 2. PERFIL DE RIESGO REALISTA ("AMETRALLADORA VS FRANCOTIRADOR")
# ------------------------------------------------------------------------------
# Objetivo: Clasificar grupos según su frecuencia de impacto y severidad en el
# escenario estándar de competición (3 Casas).

analisis_dano <- tablero_resultados %>%
  filter(es_comprable, !grupo %in% c("Negro", "Blanco")) %>%
  group_by(grupo) %>%
  summarise(
    probabilidad_media = mean(probabilidad),
    dano_promedio_3casas = mean(alq_3_casas)
  )

# Visualización 5: Frecuencia vs Severidad (3 Casas)

g5 <- ggplot(analisis_dano, aes(x = probabilidad_media, y = dano_promedio_3casas)) +
  geom_point(aes(color = grupo), size = 6) +

  # Etiquetas de texto
  geom_text(aes(label = grupo), vjust = 1.8, size = 3.5, fontface = "bold") +

  scale_color_manual(values = c(
    "Marron" = "#8B4513", "Azul_Claro" = "#87CEEB", "Rosa" = "#FF69B4",
    "Naranja" = "#FFA500", "Rojo" = "#FF0000", "Amarillo" = "#DBDB00",
    "Verde" = "#008000", "Azul_Oscuro" = "#00008B"
  )) +

  # Formato de Ejes
  scale_y_continuous(
    labels = scales::dollar_format(prefix = "€", suffix = ""),
    expand = expansion(mult = c(0.2, 0.1))
  ) +
  scale_x_continuous(
    expand = expansion(mult = c(0.1, 0.15))
  ) +

  labs(
    title = "Perfil de Letalidad: La 'Zona de Muerte'",
    subtitle = "Frecuencia de visita vs. Daño con 3 Casas (El estándar competitivo)",
    x = "Probabilidad de Visita (%)",
    y = "Daño por Impacto (Alquiler 3 Casas)",
    caption = "Naranja/Rojo: Daño alto y frecuente. Azul Oscuro: Daño extremo pero raro."
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(g5)

# ------------------------------------------------------------------------------
# 3. SUPERVIVENCIA DE 1000 RIVALES FICTICIOS
# ------------------------------------------------------------------------------

simular_supervivencia_dinamica <- function(n_rivales, n_turnos_max) {

  resultados <- data.frame()
  colores <- c("Naranja", "Verde", "Azul_Oscuro")

  for (color in colores) {

    # 1. Obtenemos TODOS los datos de daño del grupo
    datos_grupo <- tablero_resultados %>% filter(grupo == color)
    prob_impacto <- sum(datos_grupo$probabilidad) / 100

    # Pre-calculamos el daño promedio para cada nivel de casas
    dano_base   <- mean(datos_grupo$alq_monopolio) # Base duplicada por tener color
    dano_1_casa <- mean(datos_grupo$alq_1_casa)
    dano_2_casa <- mean(datos_grupo$alq_2_casas)
    dano_3_casa <- mean(datos_grupo$alq_3_casas)

    turnos_muerte <- numeric(n_rivales)

    for (i in 1:n_rivales) {
      vida <- 1500
      turno <- 0
      esta_vivo <- TRUE

      while (esta_vivo && turno < n_turnos_max) {
        turno <- turno + 1
        dano_actual <- 0

        # Definimos las Fases de la Partida
        if (turno <= 20) {
          dano_actual <- dano_base       # Fase 1: Solo terrenos
        } else if (turno <= 30) {
          dano_actual <- dano_1_casa     # Fase 2: Primera inversión
        } else if (turno <= 40) {
          dano_actual <- dano_2_casa     # Fase 3: Refuerzo
        } else {
          dano_actual <- dano_3_casa     # Fase 4: Zona de Muerte (3 Casas)
        }

        # Lógica de impacto
        if (rbinom(1, 1, prob_impacto) == 1) {
          vida <- vida - dano_actual
        }

        if (vida <= 0) esta_vivo <- FALSE
      }
      turnos_muerte[i] <- turno
    }

    # Procesamos curva de supervivencia
    curva <- data.frame(turno = 1:n_turnos_max) %>%
      rowwise() %>%
      mutate(
        vivos = sum(turnos_muerte > turno),
        porcentaje_vivos = (vivos / n_rivales) * 100,
        grupo = color
      )
    resultados <- rbind(resultados, curva)
  }
  return(resultados)
}

# Ejecutamos la simulación dinámica
datos_dinamicos <- simular_supervivencia_dinamica(n_rivales = 3000, n_turnos_max = 120)


# VISUALIZACION GRÁFICO 6: "EVOLUCIÓN LETAL"
# Añadimos marcas verticales para que se vea cuándo sube el nivel de casas

g6 <- ggplot(datos_dinamicos, aes(x = turno, y = porcentaje_vivos, color = grupo)) +

  geom_step(linewidth = 1.5) +

  # Añadimos lineas de fases
  geom_vline(xintercept = 20, linetype = "dotted", color = "grey", alpha=0.8) +
  geom_vline(xintercept = 40, linetype = "dotted", color = "grey", alpha=0.8) +

  # Anotaciones de las fases
  annotate("text", x = 10, y = 10, label = "Fase\nAcumulación", size = 3, color = "grey50") +
  annotate("text", x = 30, y = 10, label = "Fase\nConstrucción", size = 3, color = "grey50") +
  annotate("text", x = 50, y = 10, label = "Fase Letal\n(3 Casas)", size = 3, color = "grey50", fontface="bold") +

  scale_color_manual(values = c(
    "Naranja" = "#FFA500",
    "Verde" = "#008000",
    "Azul_Oscuro" = "#00008B"
  )) +

  labs(
    title = "Curva de Supervivencia Dinámica (Escalado Realista)",
    subtitle = "% de 1000 Rivales vivos a medida que la partida avanza y se construyen casas",
    x = "Turnos de Juego",
    y = "% de Supervivencia",
    caption = "Observa cómo la pendiente se vuelve agresiva a partir del Turno 40 (Fase Letal)."
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(g6)


# ------------------------------------------------------------------------------
# 4. SKYLINE DEL TABLERO
# ------------------------------------------------------------------------------

# Objetivo: Ver visualmente "dónde está el dinero" a lo largo del recorrido.
# Usamos el Valor Esperado (Probabilidad x Dinero).

datos_skyline <- tablero_resultados %>%
  filter(es_comprable) %>% # Solo propiedades
  mutate(
    # Altura del edificio = Cuánto dinero aporta esta casilla al juego
    # Usamos 3 Casas como estándar
    valor_generado = (alq_3_casas * probabilidad) / 100,
    
    # Para ordenar el gráfico del 1 al 40 (recorrido real)
    id_ordenado = as.numeric(id)
  )

# VISUALIZACIÓN: EL SKYLINE
g7 <- ggplot(datos_skyline, aes(x = id_ordenado, y = valor_generado, fill = grupo)) +
  
  # Dibujamos las "torres"
  geom_col(width = 0.8, color = "white") +
  
  # Colores oficiales
  scale_fill_manual(values = c(
    "Marron" = "#8B4513", "Azul_Claro" = "#87CEEB", "Rosa" = "#FF69B4", 
    "Naranja" = "#FFA500", "Rojo" = "#FF0000", "Amarillo" = "#DBDB00", 
    "Verde" = "#008000", "Azul_Oscuro" = "#00008B", 
    "Negro" = "#333333", "Blanco" = "#A0A0A0"
  )) +
  
  # Etiquetas en las torres más altas
  geom_text(data = datos_skyline %>% filter(valor_generado > 25), 
            aes(label = nombre, y = valor_generado), 
            vjust = 0.2, size = 3, fontface = "bold", angle = 90, hjust = -0.2) +
  
  # Dividimos el tablero en sus 4 lados (Sur, Oeste, Norte, Este) para ubicarnos
  geom_vline(xintercept = c(10.5, 20.5, 30.5), linetype = "dotted", color = "grey50") +
  annotate("text", x = 5, y = 45, label = "Lado 1\n(Barato)", size = 3, color = "grey40") +
  annotate("text", x = 15, y = 45, label = "Lado 2\n(Estratégico)", size = 3, color = "grey40") +
  annotate("text", x = 25, y = 45, label = "Lado 3\n(Caro)", size = 3, color = "grey40") +
  annotate("text", x = 35, y = 45, label = "Lado 4\n(Lujo)", size = 3, color = "grey40") +
  
  # Ajustes de ejes
  scale_y_continuous(expand = expansion(mult = c(0, 0.3))) + # Margen arriba para etiquetas
  scale_x_continuous(breaks = c(1, 10, 20, 30, 40), labels = c("Salida", "Cárcel", "Parking", "Ir a Cárcel", "Final")) +
  
  labs(
    title = "El Skyline del Tablero: ¿Dónde se genera el dinero?",
    subtitle = "Altura de la barra = Rentabilidad Real (Frecuencia x Alquiler 3 casas)",
    x = "Recorrido del Tablero (De la Salida al Final)",
    y = "Valor Generado por Turno (€)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(face = "bold")
  )

print(g7)

