-- Configuración de la fecha de análisis (simulando la fecha "actual" del sistema)
WITH constants AS (
    SELECT CAST('2026-10-01' AS DATE) AS analysis_date
),

-- 1. Agregaciones base por usuario y mes (necesarias para calcular el Trend)
user_monthly_spend AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', order_date) AS order_month,
        SUM(COALESCE(total_amount, 0)) AS monthly_amount
    FROM orders
    GROUP BY user_id, DATE_TRUNC('month', order_date)
),

-- 2. Cálculo de métricas históricas y del último mes usando funciones de ventana
trend_calculations AS (
    SELECT 
        user_id,
        order_month,
        monthly_amount,
        -- Promedio histórico de gasto mensual de ese usuario hasta el momento
        AVG(monthly_amount) OVER(PARTITION BY user_id) AS avg_historical_spend,
        -- Identificar si es el último mes disponible en los datos generales
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY order_month DESC) AS rn
    FROM user_monthly_spend
),

-- Filter para obtener solo el último mes de cada usuario y calcular su delta (Trend)
user_trend AS (
    SELECT 
        user_id,
        (monthly_amount - avg_historical_spend) AS spend_trend
    FROM trend_calculations
    WHERE rn = 1
),

-- 3. Cálculo de Recency, Frequency y Monetary base
rfm_base AS (
    SELECT 
        u.user_id,
        -- Recency: Días desde la última compra hasta la fecha de análisis
        MAX(o.order_date) AS last_purchase_date,
        -- Frequency: Cantidad de pedidos únicos
        COUNT(DISTINCT o.order_id) AS frequency,
        -- Monetary: Gasto total acumulado
        SUM(o.total_amount) AS monetary_raw
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id
)

-- 4. Consolidación final y manejo de nulos
SELECT 
    b.user_id,
    -- Manejo de Nulos para Recency: Si nunca compró, se asigna un valor alto de días (ej. 999)
    COALESCE(DATEDIFF('day', b.last_purchase_date, c.analysis_date), 999) AS recency,
    -- Manejo de Nulos para Frequency y Monetary: 0 si no hay actividad
    COALESCE(b.frequency, 0) AS frequency,
    COALESCE(b.monetary_raw, 0) AS monetary,
    -- Manejo de Nulos para Trend: 0 si no hay desvío o no tiene compras anteriores
    ROUND(COALESCE(t.spend_trend, 0), 2) AS trend
FROM rfm_base b
CROSS JOIN constants c
LEFT JOIN user_trend t ON b.user_id = t.user_id;
