-- Create the standard View for ML feature extraction
CREATE VIEW analytics.Analytics_Monthly_View AS
WITH monthly_sentiment AS (
    -- Step A: Aggregate Daily News into Monthly Scores by snapping to the 1st of the month
    SELECT 
        DATEFROMPARTS(YEAR(news_date), MONTH(news_date), 1) AS analysis_month,
        source_region,
        AVG(sentiment_score) AS avg_monthly_sentiment
    FROM core.Core_Daily_News
    GROUP BY DATEFROMPARTS(YEAR(news_date), MONTH(news_date), 1), source_region
)
-- Step B: Join to Indicators and Calculate MoM
SELECT 
    ms.analysis_month AS month_date,
    ind.source_agency,
    ind.country,
    ms.avg_monthly_sentiment,
    ind.cpi_value,
    ind.unemployment_rate,
    ind.fed_funds_rate,
    ind.ind_production_value,
    
    -- Derived MoM Calculations (Current Month - Previous Month) using Window Functions
    ind.cpi_value - LAG(ind.cpi_value, 1) OVER (PARTITION BY ind.source_agency ORDER BY ind.month_date) AS cpi_mom,
    ind.ind_production_value - LAG(ind.ind_production_value, 1) OVER (PARTITION BY ind.source_agency ORDER BY ind.month_date) AS ind_production_mom

FROM monthly_sentiment ms
JOIN core.core_macro_indicators_monthly ind 
    ON ms.analysis_month = ind.month_date
    -- Mapping the regional sentiment to the corresponding economic agency
    AND (
        (ms.source_region = 'US' AND ind.source_agency = 'FRED') OR 
        (ms.source_region = 'Global' AND ind.source_agency = 'Eurostat')
    );
GO