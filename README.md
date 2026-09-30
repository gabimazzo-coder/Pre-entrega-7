# Pre-entrega-7
Práctica para  transformar datos crudos de comportamiento de usuarios en un dataset de entrenamiento (Features) utilizando SQL avanzado. Se aplican funciones de ventana, transformaciones de agregación y filtros complejos sobre un escenario de e-commerce.
# Ingeniería de Características (Features) para Predicción de Churn

Este repositorio contiene la solución SQL para la extracción de variables de comportamiento de clientes basadas en el framework **RFM (Recency, Frequency, Monetary)** ampliado con una métrica de **Tendencia (Trend)**. Estas variables están diseñadas específicamente para alimentar un modelo predictivo de abandono (Churn).

## 📊 Lógica Analítica de las Features

A continuación se detalla el propósito de cada variable construida y su relevancia para predecir el Churn:

### 1. Recency (Recencia)
*   **Definición:** Cantidad de días transcurridos desde la última compra del usuario hasta la fecha de análisis.
*   **Utilidad para Churn:** Es uno de los predictores más fuertes. Cuanto mayor sea el número de días desde la última interacción, mayor es la probabilidad de que el cliente haya abandonado la plataforma. Permite detectar enfriamiento en la relación comercial.

### 2. Frequency (Frecuencia)
*   **Definición:** Número total de pedidos únicos realizados por el usuario en su ciclo de vida.
*   **Utilidad para Churn:** Determina la lealtad y el hábito del cliente. Los usuarios con alta frecuencia tienen un comportamiento arraigado, por lo que un cese repentino de su actividad es una señal de alerta (anomaly drop) más clara que en un usuario esporádico.

### 3. Monetary (Monetario)
*   **Definición:** El gasto total acumulado por el cliente.
*   **Utilidad para Churn:** Ayuda al modelo a segmentar el "valor" del cliente (LTV). Perder un cliente con alto valor monetario tiene un impacto financiero crítico. Permite que el modelo priorice las alertas de churn en cuentas de alto valor.

### 4. Trend (Tendencia de Gasto)
*   **Definición:** La diferencia (Delta) entre el gasto del último mes activo del usuario y su promedio mensual histórico. Se calcula utilizando funciones de ventana analíticas (`OVER` y `PARTITION BY`).
*   **Utilidad para Churn:** Funciona como una **alerta temprana**. El churn rara vez ocurre de un día para otro; usualmente viene precedido por una disminución gradual del gasto. Un Trend negativo indica que el usuario está reduciendo su consumo, lo que permite al modelo predecir el abandono antes de que ocurra la inactividad total.

## 🛠️ Manejo de Valores Nulos

Para garantizar la robustez del modelo de Machine Learning, evitamos los valores `NULL` que podrían corromper el entrenamiento:
*   **Frequency y Monetary:** Se transforman a `0` mediante `COALESCE` para los usuarios sin registros de compra.
*   **Recency:** Para usuarios sin compras históricas, se asigna un valor penalizador por defecto (`999` días), indicando inactividad extrema en lugar de dejar un vacío.
*   **Trend:** Se establece en `0` si el usuario no tiene suficiente historial para calcular una desviación, interpretándose como un comportamiento "neutral".
