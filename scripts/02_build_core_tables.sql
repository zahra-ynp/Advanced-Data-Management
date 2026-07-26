-- 1. Create the Daily News Table
CREATE TABLE core.core_daily_news (
    article_id INT IDENTITY(1,1) PRIMARY KEY,
    news_date DATE NOT NULL,
    title VARCHAR(500),
    source_name VARCHAR(100),
    source_region VARCHAR(50),
    sentiment_score FLOAT,
    sentiment_label VARCHAR(50),
    lake_pointer_url VARCHAR(500)
);
GO

-- 2. Create the Monthly Macro Indicators Table
CREATE TABLE core.core_macro_indicators_monthly (
    record_id INT IDENTITY(1,1) PRIMARY KEY,
    month_date DATE NOT NULL,
    source_agency VARCHAR(100) NOT NULL,
    country VARCHAR(100),
    cpi_value FLOAT,
    unemployment_rate FLOAT,
    fed_funds_rate FLOAT,
    ind_production_value FLOAT,
    -- This enforces Composite Alternate Key (AK)
    CONSTRAINT UQ_Macro_Month_Source UNIQUE (month_date, source_agency) 
);
GO